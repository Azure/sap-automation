#!/bin/bash
# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

green="\e[1;32m"
reset="\e[0m"
bold_red="\e[1;31m"
#External helper functions
source "sap-automation/deploy/pipelines/helper.sh"

DEBUG=False

if [ "$SYSTEM_DEBUG" = True ]; then
	set -x
	DEBUG=True
	echo "Environment variables:"
	printenv | sort

fi
export DEBUG
set -eu

echo -e "$green--- Configure devops CLI extension ---$reset"
az config set extension.use_dynamic_install=yes_without_prompt --output none --only-show-errors
AZURE_DEVOPS_EXT_PAT=$SYSTEM_ACCESSTOKEN
export AZURE_DEVOPS_EXT_PAT

ENVIRONMENT=$(echo "$SAP_SYSTEM_CONFIGURATION_NAME" | awk -F'-' '{print $1}' | xargs)

LOCATION=$(echo "${SAP_SYSTEM_CONFIGURATION_NAME}" | awk -F'-' '{print $2}' | xargs)

NETWORK=$(echo "${SAP_SYSTEM_CONFIGURATION_NAME}" | awk -F'-' '{print $3}' | xargs)

SID=$(echo "${SAP_SYSTEM_CONFIGURATION_NAME}" | awk -F'-' '{print $4}' | xargs)

cd "$CONFIG_REPO_PATH" || exit

environment_file_name=".sap_deployment_automation/$ENVIRONMENT$LOCATION$NETWORK"
parameters_filename="$CONFIG_REPO_PATH/SYSTEM/${SAP_SYSTEM_CONFIGURATION_NAME}/sap-parameters.yaml"

az devops configure --defaults organization=$SYSTEM_COLLECTIONURI project='$SYSTEM_TEAMPROJECT' --output none --only-show-errors

echo -e "$green--- Validations ---$reset"
if [ ! -f "${environment_file_name}" ]; then
	echo -e "$bold_red--- ${environment_file_name} was not found ---$reset"
	echo "##vso[task.logissue type=error]File ${environment_file_name} was not found."
	exit 2
fi

if [ -z "$AZURE_SUBSCRIPTION_ID" ]; then
	echo "##vso[task.logissue type=error]Variable AZURE_SUBSCRIPTION_ID was not defined."
	exit 2
fi

if [ "azure pipelines" == "$THIS_AGENT" ]; then
	echo "##vso[task.logissue type=error]Please use a self hosted agent for this playbook. Define it in the SDAF-$ENVIRONMENT variable group"
	exit 2
fi

echo -e "$green--- az login ---$reset"
# Check if running on deployer
if [[ ! -f /etc/profile.d/deploy_server.sh ]]; then
	configureNonDeployer "$(tf_version)"
	echo -e "$green--- az login ---$reset"
	LogonToAzure false
else
	LogonToAzure "$USE_MSI"
fi
return_code=$?
if [ 0 != $return_code ]; then
	echo -e "$bold_red--- Login failed ---$reset"
	echo "##vso[task.logissue type=error]az login failed."
	exit $return_code
fi

az account set --subscription "$AZURE_SUBSCRIPTION_ID" --output none

echo -e "$green--- Get key_vault name ---$reset"
VARIABLE_GROUP_ID=$(az pipelines variable-group list --query "[?name=='$VARIABLE_GROUP'].id | [0]")
export VARIABLE_GROUP_ID
printf -v val '%-15s' "$VARIABLE_GROUP_ID id:"
echo "$val                      $VARIABLE_GROUP_ID"
if [ -z "${VARIABLE_GROUP_ID}" ]; then
	echo "##vso[task.logissue type=error]Variable group $VARIABLE_GROUP could not be found."
	exit 2
fi

key_vault=$(getVariableFromVariableGroup "${VARIABLE_GROUP_ID}" "Deployer_Key_Vault" "${environment_file_name}" "keyvault")

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
echo "Configuration file:                  $environment_file_name"

echo -e "$green--- Get Files from the DevOps Repository ---$reset"
cd "$CONFIG_REPO_PATH/SYSTEM/${SAP_SYSTEM_CONFIGURATION_NAME}"

echo -e "$green--- Add BOM Base Name and SAP FQDN to sap-parameters.yaml ---$reset"
sed -i 's|bom_base_name:.*|bom_base_name:                 '"$BOM_BASE_NAME"'|' sap-parameters.yaml

echo -e "$green--- Get connection details ---$reset"
mkdir -p artifacts

prefix="${ENVIRONMENT}${LOCATION}${NETWORK}"

workload_key_vault=$(getVariableFromVariableGroup "${VARIABLE_GROUP_ID}" "${prefix}Workload_Key_Vault" "${environment_file_name}" "workloadkeyvault" || true)
workload_prefix=$(getVariableFromVariableGroup "${VARIABLE_GROUP_ID}" "${prefix}Workload_Secret_Prefix" "${environment_file_name}" "workload_zone_prefix" || true)
control_plane_subscription=$(getVariableFromVariableGroup "${VARIABLE_GROUP_ID}" "Terraform_Remote_Storage_Subscription" "${environment_file_name}" "STATE_SUBSCRIPTION" || true)

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
echo "##vso[task.setvariable variable=CP_SUBSCRIPTION;isOutput=true]${control_plane_subscription}"

az keyvault secret show --name "${workload_prefix}-sid-sshkey" --vault-name "$workload_key_vault" --subscription "$control_plane_subscription" --query value -o tsv >"artifacts/${SAP_SYSTEM_CONFIGURATION_NAME}_sshkey"
cp sap-parameters.yaml artifacts/.
cp "${SID}_hosts.yaml" artifacts/.

2> >(while read line; do (echo >&2 "STDERROR: $line"); done)

echo -e "$green--- Done ---$reset"
exit 0
