#!/bin/bash
# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

# Source the shared platform configuration
SCRIPT_DIR="$(dirname "${BASH_SOURCE[0]}")"
source "${SCRIPT_DIR}/shared_platform_config.sh"
source "${SCRIPT_DIR}/shared_functions.sh"
source "${SCRIPT_DIR}/set-colors.sh"

SCRIPT_NAME="$(basename "$0")"
banner_title="SAP Quality Assurance"

full_script_path="$(realpath "${BASH_SOURCE[0]}")"
script_directory="$(dirname "${full_script_path}")"
parent_directory="$(dirname "$script_directory")"
grand_parent_directory="$(dirname "$parent_directory")"

# shellcheck disable=SC1091
source "${grand_parent_directory}/deploy_utils.sh"
# shellcheck disable=SC1091
source "${parent_directory}/helper.sh"

print_header
echo ""

ENVIRONMENT=$(echo "$SAP_SYSTEM_CONFIGURATION_NAME" | awk -F'-' '{print $1}' | xargs)
LOCATION=$(echo "$SAP_SYSTEM_CONFIGURATION_NAME" | awk -F'-' '{print $2}' | xargs)
NETWORK=$(echo "$SAP_SYSTEM_CONFIGURATION_NAME" | awk -F'-' '{print $3}' | xargs)
SID=$(echo "$SAP_SYSTEM_CONFIGURATION_NAME" | awk -F'-' '{print $4}' | xargs)
workload_prefix=$(echo "$SAP_SYSTEM_CONFIGURATION_NAME" | cut -d'-' -f1-3)
WORKLOAD_ZONE_NAME="$workload_prefix"
export WORKLOAD_ZONE_NAME

if [ "$PLATFORM" == "devops" ]; then
	DEBUG=false

	if [ "${SYSTEM_DEBUG:-False}" = True ]; then
		set -x
		DEBUG=True
		echo "Environment variables:"
		printenv | sort
	fi
	export DEBUG
	set -eu

	configure_devops

	if ! get_variable_group_id "$VARIABLE_GROUP" "VARIABLE_GROUP_ID"; then
		exit_error "Variable group $VARIABLE_GROUP not found." 2
	fi
	export VARIABLE_GROUP_ID

	az devops configure --defaults "organization=$SYSTEM_COLLECTIONURI" "project=$SYSTEM_TEAMPROJECTID" --output none --only-show-errors
elif [ "$PLATFORM" == "github" ]; then
	echo "Configuring for GitHub Actions"
	export VARIABLE_GROUP_ID="${WORKLOAD_ZONE_NAME}"
	git config --global --add safe.directory "$CONFIG_REPO_PATH"
	set -eu
fi

print_banner "$banner_title" "Starting $SCRIPT_NAME" "info"

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
		exit_error "az login failed." $return_code
	fi
fi

cd "$CONFIG_REPO_PATH" || exit

echo -e "$green--- Validations ---$reset"

if [ -z "$ARM_SUBSCRIPTION_ID" ]; then
	exit_error "Variable ARM_SUBSCRIPTION_ID was not defined." 2
fi

if [ "$PLATFORM" == "devops" ] && [ "azure pipelines" == "$THIS_AGENT" ]; then
	exit_error "Please use a self hosted agent for this pipeline. Define it in the SDAF-$ENVIRONMENT variable group" 2
fi

if [ "SAPFunctionalTests" == "${TEST_TYPE:-}" ] && [ -z "${SAP_FUNCTIONAL_TEST_TYPE:-}" ]; then
	exit_error "SAP_FUNCTIONAL_TEST_TYPE must be set when TEST_TYPE is SAPFunctionalTests." 2
fi

az account set --subscription "$ARM_SUBSCRIPTION_ID" --output none

cd "$CONFIG_REPO_PATH/SYSTEM/${SAP_SYSTEM_CONFIGURATION_NAME}"

mkdir -p artifacts

echo -e "$green--- Get key vault and control plane details ---$reset"

if [ ! -v APPLICATION_CONFIGURATION_ID ]; then
	APPLICATION_CONFIGURATION_ID=$(az graph query -q "Resources | join kind=leftouter (ResourceContainers | where type=='microsoft.resources/subscriptions' | project subscription=name, subscriptionId) on subscriptionId | where name == '$APPLICATION_CONFIGURATION_NAME' | project id, name, subscription" --query data[0].id --output tsv)
	export APPLICATION_CONFIGURATION_ID
fi

workload_key_vault=""
workload_key_vault_subscription=""

if is_valid_id "$APPLICATION_CONFIGURATION_ID" "/providers/Microsoft.AppConfiguration/configurationStores/"; then
	key_vault_id=$(getVariableFromApplicationConfiguration "$APPLICATION_CONFIGURATION_ID" "${WORKLOAD_ZONE_NAME}_KeyVaultResourceId" "${WORKLOAD_ZONE_NAME}")
	workload_key_vault=$(echo "$key_vault_id" | cut -d'/' -f9)
	workload_key_vault_subscription=$(echo "$key_vault_id" | cut -d'/' -f3)
fi

if [ -z "$workload_key_vault" ]; then
	if [ -v KEYVAULT ]; then
		workload_key_vault=$KEYVAULT
		# The execution stage runs v2/05-run-ansible.sh, which resolves the key vault
		# exclusively from Application Configuration and ignores VAULT_NAME. This
		# fallback therefore only carries the preparation stage.
		print_banner "$banner_title" "Key Vault resolved from the KEYVAULT variable" "warning" \
			"Add '${WORKLOAD_ZONE_NAME}_KeyVaultResourceId' to Application Configuration; the execution stage requires it."
	else
		exit_error "Key Vault name is not defined." 2
	fi
fi

if [ -z "${TERRAFORM_STATE_STORAGE_ACCOUNT:-}" ]; then
	exit_error "Variable TERRAFORM_STATE_STORAGE_ACCOUNT was not defined." 2
fi

tf_state_id=$(az graph query -q "Resources | join kind=leftouter (ResourceContainers | where type=='microsoft.resources/subscriptions' | project subscription=name, subscriptionId) on subscriptionId | where name == '$TERRAFORM_STATE_STORAGE_ACCOUNT' | project id, name, subscription" --query data[0].id --output tsv)
control_plane_subscription=$(echo "$tf_state_id" | cut -d '/' -f 3)

if [ -z "$control_plane_subscription" ]; then
	exit_error "Unable to resolve the control plane subscription from storage account '$TERRAFORM_STATE_STORAGE_ACCOUNT'." 2
fi

if [ "$PLATFORM" == "devops" ]; then
	echo "##vso[build.updatebuildnumber]Quality assurance ${SAP_SYSTEM_CONFIGURATION_NAME}"
fi

echo "Environment:                         $ENVIRONMENT"
echo "Location:                            $LOCATION"
echo "Virtual network logical name:        $NETWORK"
echo "SID:                                 ${SID}"
echo "Workload Zone Name:                  ${WORKLOAD_ZONE_NAME}"
echo "Folder:                              $CONFIG_REPO_PATH/SYSTEM/${SAP_SYSTEM_CONFIGURATION_NAME}"
echo "Hosts file:                          ${SID}_hosts.yaml"
echo "Workload Key Vault:                  ${workload_key_vault}"
echo "Control Plane Subscription:          ${control_plane_subscription}"
echo "Test type:                           ${TEST_TYPE:-}"
echo "SAP functional test type:            ${SAP_FUNCTIONAL_TEST_TYPE:-(not applicable)}"
echo "Test groups:                         ${TEST_GROUPS:-(all)}"
echo "Test cases:                          ${TEST_CASES:-(all)}"
echo "Offline mode:                        ${OFFLINE_MODE:-false}"

if [ "${EXTRA_PARAMETERS:-''}" = '$(EXTRA_PARAMETERS)' ]; then
	new_parameters="$PIPELINE_EXTRA_PARAMETERS"
else
	log_warning "Extra parameters were provided - '${EXTRA_PARAMETERS:-''}'"
	new_parameters="${EXTRA_PARAMETERS:-''} $PIPELINE_EXTRA_PARAMETERS"
fi

QA_DIRECTORY="${QA_DIRECTORY:-/opt/microsoft/sap_automation_qa}"

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
		exit_error "Unsupported SAP functional test type '${SAP_FUNCTIONAL_TEST_TYPE:-}'." 2
		;;
	esac
fi

echo "Quality assurance playbook:          ${qa_playbook}.yml"

qa_parameters="-e sap_automation_qa_test_type=${TEST_TYPE:-SAPFunctionalTests}"
qa_parameters="$qa_parameters -e sap_automation_qa_directory=${QA_DIRECTORY}"
qa_parameters="$qa_parameters -e sap_automation_qa_system_directory=$CONFIG_REPO_PATH/SYSTEM/$SAP_SYSTEM_CONFIGURATION_NAME"

if [ -n "${SAP_FUNCTIONAL_TEST_TYPE:-}" ]; then
	qa_parameters="$qa_parameters -e SAP_FUNCTIONAL_TEST_TYPE=${SAP_FUNCTIONAL_TEST_TYPE}"
fi
if [ -n "${TEST_GROUPS:-}" ]; then
	qa_parameters="$qa_parameters -e sap_automation_qa_test_groups=${TEST_GROUPS}"
fi
if [ -n "${TEST_CASES:-}" ]; then
	qa_parameters="$qa_parameters -e sap_automation_qa_test_cases=${TEST_CASES}"
fi

setup_parameters="$new_parameters $qa_parameters"

if [ "true" == "${USE_MSI:-false}" ] && [ -n "${ARM_CLIENT_ID:-}" ]; then
	identity_parameters="-e user_assigned_identity_client_id=${ARM_CLIENT_ID}"
else
	identity_parameters=""
fi

execution_parameters="$new_parameters $identity_parameters"
execution_parameters="$execution_parameters -e _workspace_directory=$CONFIG_REPO_PATH/SYSTEM/$SAP_SYSTEM_CONFIGURATION_NAME"
execution_parameters="$execution_parameters -e @$CONFIG_REPO_PATH/SYSTEM/$SAP_SYSTEM_CONFIGURATION_NAME/artifacts/qa_test_selection.json"

qa_log_path="$CONFIG_REPO_PATH/SYSTEM/$SAP_SYSTEM_CONFIGURATION_NAME/logs/execution_$(date +%Y%m%d_%H%M%S).log"

set_output_variable "SID" "${SID}"
set_output_variable "SAP_PARAMETERS" "sap-parameters.yaml"
set_output_variable "FOLDER" "$CONFIG_REPO_PATH/SYSTEM/$SAP_SYSTEM_CONFIGURATION_NAME"
set_output_variable "HOSTS" "${SID}_hosts.yaml"
set_output_variable "SSH_KEY_NAME" "${workload_prefix}-sid-sshkey"
set_output_variable "VAULT_NAME" "$workload_key_vault"
set_output_variable "PASSWORD_KEY_NAME" "${workload_prefix}-sid-password"
set_output_variable "USERNAME_KEY_NAME" "${workload_prefix}-sid-username"
set_output_variable "NEW_PARAMETERS" "${setup_parameters}"
set_output_variable "QA_PARAMETERS" "${execution_parameters}"
set_output_variable "QA_PLAYBOOK_PATH" "${QA_DIRECTORY}/src/${qa_playbook}.yml"
set_output_variable "QA_ANSIBLE_CONFIG" "${QA_DIRECTORY}/src/ansible.cfg"
set_output_variable "QA_LIBRARY" "${QA_DIRECTORY}/src/modules"
set_output_variable "QA_MODULE_UTILS" "${QA_DIRECTORY}/src/module_utils"
set_output_variable "QA_COLLECTIONS" "${QA_DIRECTORY}/.ansible/collections"
set_output_variable "QA_LOG_PATH" "${qa_log_path}"
set_output_variable "CP_SUBSCRIPTION" "${control_plane_subscription}"
set_output_variable "WORKLOAD_ZONE_NAME" "${WORKLOAD_ZONE_NAME}"
set_output_variable "ARM_SUBSCRIPTION_ID" "${control_plane_subscription}"

az keyvault secret show --name "${workload_prefix}-sid-sshkey" --vault-name "$workload_key_vault" --subscription "${workload_key_vault_subscription:-$control_plane_subscription}" --query value -o tsv >"artifacts/${SAP_SYSTEM_CONFIGURATION_NAME}_sshkey"
chmod 600 "artifacts/${SAP_SYSTEM_CONFIGURATION_NAME}_sshkey"
cp sap-parameters.yaml artifacts/.
cp "${SID}_hosts.yaml" artifacts/.

echo -e "$green--- Done ---$reset"
print_banner "$banner_title" "Exiting $SCRIPT_NAME" "info"
exit 0
