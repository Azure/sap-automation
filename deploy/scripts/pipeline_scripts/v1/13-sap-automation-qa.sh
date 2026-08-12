#!/bin/bash
# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

green="\e[1;32m"
reset="\e[0m"
bold_red="\e[1;31m"

#External helper functions
full_script_path="$(realpath "${BASH_SOURCE[0]}")"
script_directory="$(dirname "${full_script_path}")"
parent_directory="$(dirname "$script_directory")"
grand_parent_directory="$(dirname "$parent_directory")"

banner_title="SAP Quality Assurance"

#call stack has full script name when using source
# shellcheck disable=SC1091
source "${grand_parent_directory}/deploy_utils.sh"

#call stack has full script name when using source
# shellcheck disable=SC1091
source "${parent_directory}/helper.sh"

DEBUG=false

if [ "${SYSTEM_DEBUG:-false}" = true ]; then
	set -x
	DEBUG=true
	echo "Environment variables:"
	printenv | sort
fi
export DEBUG
set -eu

# Print the execution environment details
print_header

# Configure DevOps
configure_devops

# Set logon variables
if [ "$USE_MSI" == "true" ]; then
	unset ARM_CLIENT_SECRET
	ARM_USE_MSI=true
	export ARM_USE_MSI
fi

if [[ ! -f /etc/profile.d/deploy_server.sh ]]; then
	configureNonDeployer "${tf_version:-1.12.2}"
fi

if az account show --query name; then
	echo -e "$green--- Already logged in to Azure ---$reset"
else
	echo -e "$green--- az login ---$reset"
	LogonToAzure "$USE_MSI"
	return_code=$?
	if [ 0 != $return_code ]; then
		echo -e "$bold_red--- Login failed ---$reset"
		echo "##vso[task.logissue type=error]az login failed."
		exit $return_code
	fi
fi

if ! get_variable_group_id "$VARIABLE_GROUP" "VARIABLE_GROUP_ID"; then
	echo -e "$bold_red--- Variable group $VARIABLE_GROUP not found ---$reset"
	echo "##vso[task.logissue type=error]Variable group $VARIABLE_GROUP not found."
	exit 2
fi
export VARIABLE_GROUP_ID

ENVIRONMENT=$(echo "$SAP_SYSTEM_CONFIGURATION_NAME" | awk -F'-' '{print $1}' | xargs)
LOCATION=$(echo "$SAP_SYSTEM_CONFIGURATION_NAME" | awk -F'-' '{print $2}' | xargs)
NETWORK=$(echo "$SAP_SYSTEM_CONFIGURATION_NAME" | awk -F'-' '{print $3}' | xargs)
SID=$(echo "$SAP_SYSTEM_CONFIGURATION_NAME" | awk -F'-' '{print $4}' | xargs)

cd "$CONFIG_REPO_PATH" || exit

automation_config_directory="$CONFIG_REPO_PATH/.sap_deployment_automation/"
if [ "v1" == "${SDAFWZ_CALLER_VERSION:-v2}" ] && [ -f "${automation_config_directory}${ENVIRONMENT}${LOCATION}" ]; then
	workload_environment_file_name="${automation_config_directory}${ENVIRONMENT}${LOCATION}"
else
	workload_environment_file_name="${automation_config_directory}${ENVIRONMENT}${LOCATION}${NETWORK}"
fi

az devops configure --defaults "organization=$SYSTEM_COLLECTIONURI" "project=$SYSTEM_TEAMPROJECTID" --output none --only-show-errors

echo -e "$green--- Validations ---$reset"
if [ ! -f "${workload_environment_file_name}" ]; then
	echo -e "$bold_red--- ${workload_environment_file_name} was not found ---$reset"
	echo "##vso[task.logissue type=error]File ${workload_environment_file_name} was not found."
	exit 2
fi

if [ -z "$ARM_SUBSCRIPTION_ID" ]; then
	echo "##vso[task.logissue type=error]Variable ARM_SUBSCRIPTION_ID was not defined."
	exit 2
fi

if [ "azure pipelines" == "$THIS_AGENT" ]; then
	echo "##vso[task.logissue type=error]Please use a self hosted agent for this pipeline. Define it in the SDAF-$ENVIRONMENT variable group"
	exit 2
fi

if [ "SAPFunctionalTests" == "${TEST_TYPE:-}" ] && [ -z "${SAP_FUNCTIONAL_TEST_TYPE:-}" ]; then
	echo "##vso[task.logissue type=error]SAP_FUNCTIONAL_TEST_TYPE must be set when TEST_TYPE is SAPFunctionalTests."
	exit 2
fi

az account set --subscription "$ARM_SUBSCRIPTION_ID" --output none

cd "$CONFIG_REPO_PATH/SYSTEM/${SAP_SYSTEM_CONFIGURATION_NAME}"

mkdir -p artifacts

echo -e "$green--- Get key vault and control plane details ---$reset"

workload_key_vault=$(getVariableFromVariableGroup "${VARIABLE_GROUP_ID}" "KEYVAULT" "${workload_environment_file_name}" "workloadkeyvault")
workload_prefix=$(echo "$SAP_SYSTEM_CONFIGURATION_NAME" | cut -d'-' -f1-3)
terraform_storage_account=$(getVariableFromVariableGroup "${VARIABLE_GROUP_ID}" "TERRAFORM_STATE_STORAGE_ACCOUNT" "${workload_environment_file_name}" "REMOTE_STATE_SA" || true)
tf_state_id=$(az graph query -q "Resources | join kind=leftouter (ResourceContainers | where type=='microsoft.resources/subscriptions' | project subscription=name, subscriptionId) on subscriptionId | where name == '$terraform_storage_account' | project id, name, subscription" --query data[0].id --output tsv)
control_plane_subscription=$(echo "$tf_state_id" | cut -d '/' -f 3)

if [ -z "$control_plane_subscription" ]; then
	echo -e "$bold_red--- Control plane subscription could not be resolved ---$reset"
	echo "##vso[task.logissue type=error]Unable to resolve the control plane subscription from storage account '$terraform_storage_account'."
	exit 2
fi

echo "##vso[build.updatebuildnumber]Quality assurance ${SAP_SYSTEM_CONFIGURATION_NAME}"

echo "Environment:                         $ENVIRONMENT"
echo "Location:                            $LOCATION"
echo "Virtual network logical name:        $NETWORK"
echo "SID:                                 ${SID}"
echo "Folder:                              $CONFIG_REPO_PATH/SYSTEM/${SAP_SYSTEM_CONFIGURATION_NAME}"
echo "Hosts file:                          ${SID}_hosts.yaml"
echo "Configuration file:                  $workload_environment_file_name"
echo "Workload Key Vault:                  ${workload_key_vault}"
echo "Control Plane Subscription:          ${control_plane_subscription}"
echo "Workload Prefix:                     ${workload_prefix}"
echo "Test type:                           ${TEST_TYPE:-}"
echo "SAP functional test type:            ${SAP_FUNCTIONAL_TEST_TYPE:-(not applicable)}"
echo "Test groups:                         ${TEST_GROUPS:-(all)}"
echo "Test cases:                          ${TEST_CASES:-(all)}"
echo "Offline mode:                        ${OFFLINE_MODE:-false}"

# The downstream runner splices these free-form values into a command string
# that it executes with eval, so anything other than ansible extra variables
# would be interpreted by the shell, and a bare path would be taken by
# ansible-playbook as an additional playbook to run. Only a sequence of
# -e key=value arguments is accepted. This is validated after the unexpanded
# Azure DevOps token has been discarded below, because that token legitimately
# contains parentheses.
qa_extra_parameters_pattern='^([[:space:]]*-e[[:space:]]+[A-Za-z_][A-Za-z0-9_]*=[A-Za-z0-9_.,:/@+-]*)*[[:space:]]*$'

validate_extra_parameters() {
	local value="$1"

	if ! [[ "$value" =~ $qa_extra_parameters_pattern ]]; then
		echo -e "$bold_red--- Rejected extra parameters ---$reset"
		echo "##vso[task.logissue type=error]The extra parameters must be a sequence of '-e key=value' arguments. Quoting, shell metacharacters and positional arguments such as playbook paths are not accepted."
		exit 2
	fi
}

if [ "$EXTRA_PARAMETERS" = '$(EXTRA_PARAMETERS)' ]; then
	new_parameters="$PIPELINE_EXTRA_PARAMETERS"
else
	echo "##vso[task.logissue type=warning]Extra parameters were provided - '$EXTRA_PARAMETERS'"
	new_parameters="$EXTRA_PARAMETERS $PIPELINE_EXTRA_PARAMETERS"
fi

validate_extra_parameters "$new_parameters"

QA_DIRECTORY="${QA_DIRECTORY:-/opt/microsoft/sap_automation_qa}"
QA_COLLECTIONS_PATH="${QA_COLLECTIONS_PATH:-/opt/microsoft/sap_automation_qa_collections}"

if [ "ConfigurationChecks" == "${TEST_TYPE:-}" ]; then
	qa_playbook="playbook_00_configuration_checks"
elif [ "true" == "${OFFLINE_MODE:-false}" ] &&
	{ [ "DatabaseHighAvailability" == "${SAP_FUNCTIONAL_TEST_TYPE:-}" ] ||
		[ "CentralServicesHighAvailability" == "${SAP_FUNCTIONAL_TEST_TYPE:-}" ]; }; then
	qa_playbook="playbook_01_ha_offline_tests"
else
	case "${SAP_FUNCTIONAL_TEST_TYPE:-}" in
	DatabaseHighAvailability) qa_playbook="playbook_00_ha_db_functional_tests" ;;
	CentralServicesHighAvailability) qa_playbook="playbook_00_ha_scs_functional_tests" ;;
	AzureBackupDatabase) qa_playbook="playbook_00_backup_db_functional_tests" ;;
	*)
		echo -e "$bold_red--- Unsupported SAP functional test type '${SAP_FUNCTIONAL_TEST_TYPE:-}' ---$reset"
		echo "##vso[task.logissue type=error]Unsupported SAP functional test type '${SAP_FUNCTIONAL_TEST_TYPE:-}'."
		exit 2
		;;
	esac
fi

echo "Quality assurance playbook:          ${qa_playbook}.yml"

qa_parameters="-e sap_automation_qa_test_type=${TEST_TYPE:-SAPFunctionalTests}"
qa_parameters="$qa_parameters -e sap_automation_qa_directory=${QA_DIRECTORY}"
qa_parameters="$qa_parameters -e sap_automation_qa_system_directory=$CONFIG_REPO_PATH/SYSTEM/$SAP_SYSTEM_CONFIGURATION_NAME"

qa_parameters="$qa_parameters -e sap_automation_qa_offline_mode=${OFFLINE_MODE:-false}"

if [ -n "${SAP_FUNCTIONAL_TEST_TYPE:-}" ]; then
	qa_parameters="$qa_parameters -e SAP_FUNCTIONAL_TEST_TYPE=${SAP_FUNCTIONAL_TEST_TYPE}"
fi
if [ -n "${TEST_GROUPS:-}" ]; then
	qa_parameters="$qa_parameters -e sap_automation_qa_test_groups=${TEST_GROUPS}"
fi
if [ -n "${TEST_CASES:-}" ]; then
	qa_parameters="$qa_parameters -e sap_automation_qa_test_cases=${TEST_CASES}"
fi

# The setup playbook runs privileged git and pip operations, so it is given
# only the parameters this script constructs. Free-form queue time parameters
# reach the unprivileged execution playbook alone, otherwise anyone able to
# queue the pipeline could override the framework repository or directory and
# have their own code run as root on the agent.
setup_parameters="$qa_parameters"

if [ "true" == "${USE_MSI:-false}" ] && [ -n "${ARM_CLIENT_ID:-}" ]; then
	identity_parameters="-e user_assigned_identity_client_id=${ARM_CLIENT_ID}"
else
	identity_parameters=""
fi

execution_parameters="$new_parameters $identity_parameters"
execution_parameters="$execution_parameters -e _workspace_directory=$CONFIG_REPO_PATH/SYSTEM/$SAP_SYSTEM_CONFIGURATION_NAME"
execution_parameters="$execution_parameters -e @$CONFIG_REPO_PATH/SYSTEM/$SAP_SYSTEM_CONFIGURATION_NAME/artifacts/qa_test_selection.json"

qa_log_path="$CONFIG_REPO_PATH/SYSTEM/$SAP_SYSTEM_CONFIGURATION_NAME/logs/execution_$(date +%Y%m%d_%H%M%S).log"

echo "##vso[task.setvariable variable=SID;isOutput=true]${SID}"
echo "##vso[task.setvariable variable=SAP_PARAMETERS;isOutput=true]sap-parameters.yaml"
echo "##vso[task.setvariable variable=FOLDER;isOutput=true]$CONFIG_REPO_PATH/SYSTEM/$SAP_SYSTEM_CONFIGURATION_NAME"
echo "##vso[task.setvariable variable=HOSTS;isOutput=true]${SID}_hosts.yaml"
echo "##vso[task.setvariable variable=SSH_KEY_NAME;isOutput=true]${workload_prefix}-sid-sshkey"
echo "##vso[task.setvariable variable=VAULT_NAME;isOutput=true]$workload_key_vault"
echo "##vso[task.setvariable variable=PASSWORD_KEY_NAME;isOutput=true]${workload_prefix}-sid-password"
echo "##vso[task.setvariable variable=USERNAME_KEY_NAME;isOutput=true]${workload_prefix}-sid-username"
echo "##vso[task.setvariable variable=NEW_PARAMETERS;isOutput=true]${setup_parameters}"
echo "##vso[task.setvariable variable=QA_PARAMETERS;isOutput=true]${execution_parameters}"
echo "##vso[task.setvariable variable=QA_PLAYBOOK_PATH;isOutput=true]${QA_DIRECTORY}/src/${qa_playbook}.yml"
echo "##vso[task.setvariable variable=QA_ANSIBLE_CONFIG;isOutput=true]${QA_DIRECTORY}/src/ansible.cfg"
echo "##vso[task.setvariable variable=QA_LIBRARY;isOutput=true]${QA_DIRECTORY}/src/modules"
echo "##vso[task.setvariable variable=QA_MODULE_UTILS;isOutput=true]${QA_DIRECTORY}/src/module_utils"
echo "##vso[task.setvariable variable=QA_COLLECTIONS;isOutput=true]${QA_COLLECTIONS_PATH}"
echo "##vso[task.setvariable variable=QA_LOG_PATH;isOutput=true]${qa_log_path}"
echo "##vso[task.setvariable variable=WORKLOAD_ZONE_NAME;isOutput=true]${workload_prefix}"
echo "##vso[task.setvariable variable=ARM_SUBSCRIPTION_ID;isOutput=true]${control_plane_subscription}"

workload_key_vault_id=$(az graph query -q "Resources | join kind=leftouter (ResourceContainers | where type=='microsoft.resources/subscriptions' | project subscription=name, subscriptionId) on subscriptionId | where name == '$workload_key_vault' | project id, name, subscription" --query data[0].id --output tsv)
workload_key_vault_subscription=$(echo "$workload_key_vault_id" | cut -d '/' -f 3)

if [ -z "$workload_key_vault_subscription" ]; then
	echo "##[warning]Key Vault subscription not found for vault '$workload_key_vault'; falling back to the control plane subscription."
	workload_key_vault_subscription=$control_plane_subscription
fi

cp sap-parameters.yaml artifacts/.
cp "${SID}_hosts.yaml" artifacts/.

echo -e "$green--- Done ---$reset"
exit 0
