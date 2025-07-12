#!/bin/bash
# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

green="\e[1;32m"
reset="\e[0m"
bold_red="\e[1;31m"

# External helper functions
full_script_path="$(realpath "${BASH_SOURCE[0]}")"
script_directory="$(dirname "${full_script_path}")"
parent_directory="$(dirname "$script_directory")"
grand_parent_directory="$(dirname "$parent_directory")"

SCRIPT_NAME="$(basename "$0")"

banner_title="Prepare for software download"
#call stack has full script name when using source
# shellcheck disable=SC1091
source "${grand_parent_directory}/deploy_utils.sh"

#call stack has full script name when using source
source "${parent_directory}/helper.sh"


DEBUG=False

if [ "$SYSTEM_DEBUG" = True ]; then
  set -x
  DEBUG=True
	echo "Environment variables:"
	printenv | sort

fi
export DEBUG
set -eu

AZURE_DEVOPS_EXT_PAT=$SYSTEM_ACCESSTOKEN
export AZURE_DEVOPS_EXT_PAT

cd "$CONFIG_REPO_PATH" || exit

environment_file_name=".sap_deployment_automation/$CONTROL_PLANE_NAME"

# Print the execution environment details
print_header

# Configure DevOps
configure_devops

if ! get_variable_group_id "$VARIABLE_GROUP" "VARIABLE_GROUP_ID" ;
then
	echo -e "$bold_red--- Variable group $VARIABLE_GROUP not found ---$reset"
	echo "##vso[task.logissue type=error]Variable group $VARIABLE_GROUP not found."
	exit 2
fi
export VARIABLE_GROUP_ID


echo -e "$green--- Validations ---$reset"
if [ ! -f "${environment_file_name}" ]; then
  echo -e "$bold_red--- ${environment_file_name} was not found ---$reset"
  echo "##vso[task.logissue type=error]File ${environment_file_name} was not found."
  exit 2
fi
if [ -z "$ARM_SUBSCRIPTION_ID" ]; then
  echo "##vso[task.logissue type=error]Variable ARM_SUBSCRIPTION_ID was not defined."
  exit 2
fi

if [ "azure pipelines" == $THIS_AGENT ]; then
  echo "##vso[task.logissue type=error]Please use a self hosted agent for this playbook. Define it in the SDAF-$(environment_code) variable group"
  exit 2
fi

if [ "your S User" == "$SUSERNAME" ]; then
  echo "##vso[task.logissue type=error]Please define the S-Username variable."
  exit 2
fi

if [ "your S user password" == "$SPASSWORD" ]; then
  echo "##vso[task.logissue type=error]Please define the S-Password variable."
  exit 2
fi

echo -e "$green--- az login ---$reset"
# Check if running on deployer
if [[ ! -f /etc/profile.d/deploy_server.sh ]]; then
  configureNonDeployer "$(tf_version)"
    echo -e "$green--- az login ---$reset"
  LogonToAzure false
fi
return_code=$?
if [ 0 != $return_code ]; then
  echo -e "$bold_red--- Login failed ---$reset"
  echo "##vso[task.logissue type=error]az login failed."
  exit $return_code
fi

az account set --subscription "$ARM_SUBSCRIPTION_ID" --output none

key_vault=$(getVariableFromVariableGroup "${VARIABLE_GROUP_ID}" "Deployer_Key_Vault" "${environment_file_name}" "keyvault")

echo "Keyvault: $key_vault"
echo " ##vso[task.setvariable variable=KV_NAME;isOutput=true]$key_vault"

echo -e "$green--- BoM $BOM ---$reset"
echo "##vso[build.updatebuildnumber]Downloading BoM defined in $BOM"

echo -e "$green--- Set S-Username and S-Password in the key_vault if not yet there ---$reset"

SUsername_from_Keyvault=$(az keyvault secret list --vault-name "${key_vault}" --subscription "$ARM_SUBSCRIPTION_ID" --query "[].{Name:name} | [? contains(Name,'S-Username')] | [0]" -o tsv)
if [ "$SUsername_from_Keyvault" == "$SUSERNAME" ]; then
  echo -e "$green--- $SUsername present in keyvault. In case of download errors check that user and password are correct ---$reset"
else
  echo -e "$green--- Setting the S username in key vault ---$reset"
  az keyvault secret set --name "S-Username" --vault-name "$key_vault" --value="$SUSERNAME" --subscription "$ARM_SUBSCRIPTION_ID" --expires "$(date -d '+1 year' -u +%Y-%m-%dT%H:%M:%SZ)" --output none
fi

SPassword_from_Keyvault=$(az keyvault secret list --vault-name "${key_vault}" --subscription "$ARM_SUBSCRIPTION_ID" --query "[].{Name:name} | [? contains(Name,'S-Password')] | [0]" -o tsv)
if [ "$SPASSWORD" == "$SPassword_from_Keyvault" ]; then
  echo -e "$green--- Password present in keyvault. In case of download errors check that user and password are correct ---$reset"
else
  echo -e "$green--- Setting the S user name password in key vault ---$reset"
  az keyvault secret set --name "S-Password" --vault-name "$key_vault" --value "$SPASSWORD" --subscription "$ARM_SUBSCRIPTION_ID" --expires "$(date -d '+1 year' -u +%Y-%m-%dT%H:%M:%SZ)" --output none

fi

echo "##vso[task.setvariable variable=SUSERNAME;isOutput=true]$SUSERNAME"
echo "##vso[task.setvariable variable=SPASSWORD;isOutput=true]$SPASSWORD"
echo "##vso[task.setvariable variable=BOM_NAME;isOutput=true]$BOM"

echo -e "$green--- Done ---$reset"
exit 0
