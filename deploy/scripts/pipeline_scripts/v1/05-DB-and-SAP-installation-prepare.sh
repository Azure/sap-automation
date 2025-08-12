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

SCRIPT_NAME="$(basename "$0")"

banner_title="Software installation"

#call stack has full script name when using source
# shellcheck disable=SC1091
source "${grand_parent_directory}/deploy_utils.sh"

#call stack has full script name when using source
source "${parent_directory}/helper.sh"

DEBUG=false

if [ "$SYSTEM_DEBUG" = true ]; then
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
if [ $USE_MSI == "true" ]; then
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
	# Check if running on deployer
	echo -e "$green--- az login ---$reset"
	LogonToAzure $USE_MSI
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

LOCATION=$(echo "${SAP_SYSTEM_CONFIGURATION_NAME}" | awk -F'-' '{print $2}' | xargs)

NETWORK=$(echo "${SAP_SYSTEM_CONFIGURATION_NAME}" | awk -F'-' '{print $3}' | xargs)

SID=$(echo "${SAP_SYSTEM_CONFIGURATION_NAME}" | awk -F'-' '{print $4}' | xargs)

cd "$CONFIG_REPO_PATH" || exit

automation_config_directory=$CONFIG_REPO_PATH/.sap_deployment_automation/
if [ "v1" == "${SDAFWZ_CALLER_VERSION:-v2}" ]; then
	workload_environment_file_name="${automation_config_directory}${ENVIRONMENT}${LOCATION}"
elif [ "v2" == "${SDAFWZ_CALLER_VERSION:-v2}" ]; then
	workload_environment_file_name="${automation_config_directory}${ENVIRONMENT}${LOCATION}${NETWORK}"
fi

parameters_filename="$CONFIG_REPO_PATH/SYSTEM/${SAP_SYSTEM_CONFIGURATION_NAME}/sap-parameters.yaml"

az devops configure --defaults organization=$SYSTEM_COLLECTIONURI project=$SYSTEM_TEAMPROJECTID --output none --only-show-errors

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
	echo "##vso[task.logissue type=error]Please use a self hosted agent for this playbook. Define it in the SDAF-$ENVIRONMENT variable group"
	exit 2
fi

az account set --subscription "$ARM_SUBSCRIPTION_ID" --output none

echo -e "$green--- Get key_vault name ---$reset"

key_vault=$(getVariableFromVariableGroup "${VARIABLE_GROUP_ID}" "KEYVAULT" "${workload_environment_file_name}" "workloadkeyvault")

echo "##vso[build.updatebuildnumber]Deploying ${SAP_SYSTEM_CONFIGURATION_NAME} using BoM ${BOM_BASE_NAME}"

echo "##vso[task.setvariable variable=SID;isOutput=true]${SID}"
echo "##vso[task.setvariable variable=SAP_PARAMETERS;isOutput=true]sap-parameters.yaml"
echo "##vso[task.setvariable variable=FOLDER;isOutput=true]$CONFIG_REPO_PATH/SYSTEM/$SAP_SYSTEM_CONFIGURATION_NAME"
echo "##vso[task.setvariable variable=HOSTS;isOutput=true]${SID}_hosts.yaml"
echo "##vso[task.setvariable variable=KV_NAME;isOutput=true]$key_vault"

echo "Environment:                         $ENVIRONMENT"
echo "Location:                            $LOCATION"
echo "Virtual network logical name:        $NETWORK"
echo "Keyvault:                            $key_vault"
echo "SAP Application BoM:                 $BOM_BASE_NAME"

echo "SID:                                 ${SID}"
echo "Folder:                              $CONFIG_REPO_PATH/SYSTEM/${SAP_SYSTEM_CONFIGURATION_NAME}"
echo "Hosts file:                          ${SID}_hosts.yaml"
echo "sap_parameters_file:                 $parameters_filename"
echo "Configuration file:                  $workload_environment_file_name"

cd "$CONFIG_REPO_PATH/SYSTEM/${SAP_SYSTEM_CONFIGURATION_NAME}"

echo -e "$green--- Add BOM Base Name and SAP FQDN to sap-parameters.yaml ---$reset"
sed -i 's|bom_base_name:.*|bom_base_name:                 '"$BOM_BASE_NAME"'|' sap-parameters.yaml

mkdir -p artifacts

workload_key_vault=$(getVariableFromVariableGroup "${VARIABLE_GROUP_ID}" "KEYVAULT" "${workload_environment_file_name}" "workloadkeyvault" || true)
workload_prefix=$(echo "$SAP_SYSTEM_CONFIGURATION_NAME" | cut -d'-' -f1-3)
terraform_storage_account=$(getVariableFromVariableGroup "${VARIABLE_GROUP_ID}" "TERRAFORM_STATE_STORAGE_ACCOUNT" "${workload_environment_file_name}" "REMOTE_STATE_SA" || true)
tf_state_id=$(az graph query -q "Resources | join kind=leftouter (ResourceContainers | where type=='microsoft.resources/subscriptions' | project subscription=name, subscriptionId) on subscriptionId | where name == '$terraform_storage_account' | project id, name, subscription" --query data[0].id --output tsv)
control_plane_subscription=$(echo "$tf_state_id" | cut -d '/' -f 3)


echo "SID:                                 ${SID}"
echo "Folder:                              $HOME/SYSTEM/${SAP_SYSTEM_CONFIGURATION_NAME}"
echo "Workload Key Vault:                  ${workload_key_vault}"

echo "Control Plane Subscription:          ${control_plane_subscription}"
echo "Workload Prefix:                     ${workload_prefix}"

if [ $EXTRA_PARAMETERS = '$(EXTRA_PARAMETERS)' ]; then
	new_parameters=$PIPELINE_EXTRA_PARAMETERS
else
	echo "##vso[task.logissue type=warning]Extra parameters were provided - '$EXTRA_PARAMETERS'"
	new_parameters="$EXTRA_PARAMETERS $PIPELINE_EXTRA_PARAMETERS"
fi

echo "##vso[task.setvariable variable=SSH_KEY_NAME;isOutput=true]${workload_prefix}-sid-sshkey"
echo "##vso[task.setvariable variable=VAULT_NAME;isOutput=true]$workload_key_vault"
echo "##vso[task.setvariable variable=PASSWORD_KEY_NAME;isOutput=true]${workload_prefix}-sid-password"
echo "##vso[task.setvariable variable=USERNAME_KEY_NAME;isOutput=true]${workload_prefix}-sid-username"
echo "##vso[task.setvariable variable=NEW_PARAMETERS;isOutput=true]${new_parameters}"
echo "##vso[task.setvariable variable=ARM_SUBSCRIPTION_ID;isOutput=true]${control_plane_subscription}"

az keyvault secret show --name "${workload_prefix}-sid-sshkey" --vault-name "$workload_key_vault" --subscription "$control_plane_subscription" --query value -o tsv >"artifacts/${SAP_SYSTEM_CONFIGURATION_NAME}_sshkey"
cp sap-parameters.yaml artifacts/.
cp "${SID}_hosts.yaml" artifacts/.

2> >(while read line; do (echo >&2 "STDERROR: $line"); done)

echo -e "$green--- Done ---$reset"
exit 0
