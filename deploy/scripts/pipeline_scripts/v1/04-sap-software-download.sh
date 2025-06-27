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

banner_title="Software download"

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

cd "$CONFIG_REPO_PATH" || exit

sample_path="$SAMPLE_REPO_PATH/SAP"

if [ "$USE_MSI" != "true" ]; then
  if [ -z "$ARM_CLIENT_ID" ]; then
    echo "##vso[task.logissue type=error]Variable ARM_CLIENT_ID was not defined."
    exit 2
  fi

  if [ -z "$ARM_CLIENT_SECRET" ]; then
    echo "##vso[task.logissue type=error]Variable ARM_CLIENT_SECRET was not defined."
    exit 2
  fi

  if [ -z "$ARM_TENANT_ID" ]; then
    echo "##vso[task.logissue type=error]Variable ARM_TENANT_ID was not defined."
    exit 2
  fi
fi

# Set logon variables
if [ $USE_MSI == "true" ]; then
	unset ARM_CLIENT_SECRET
	ARM_USE_MSI=true
	export ARM_USE_MSI
fi
if az account show --query name; then
	echo -e "$green--- Already logged in to Azure ---$reset"
else
	# Check if running on deployer
	if [[ ! -f /etc/profile.d/deploy_server.sh ]]; then
		configureNonDeployer "${tf_version:-1.12.2}"
		echo -e "$green--- az login ---$reset"
		LogonToAzure $USE_MSI
	else
		LogonToAzure $USE_MSI
	fi
	return_code=$?
	if [ 0 != $return_code ]; then
		echo -e "$bold_red--- Login failed ---$reset"
		echo "##vso[task.logissue type=error]az login failed."
		exit $return_code
	fi
fi
az account set --subscription "$ARM_SUBSCRIPTION_ID" --output none

command="ansible-playbook -e download_directory=$AGENT_TEMP_DIRECTORY \
-e s_user=$SUSERNAME -e BOM_directory=${sample_path} \
-e bom_base_name=$BOM_NAME \
-e deployer_kv_name=$DEPLOYER_KEYVAULT \
-e check_storage_account=$CHECK_STORAGE_ACCOUNT \
-e orchestration_ansible_user=$USER \
 $EXTRA_PARAMETERS $SAP_AUTOMATION_REPO_PATH/deploy/ansible/playbook_bom_downloader.yaml"

echo "##[section]Executing [$command]..."
echo "##[group]- output"
eval $command
return_code=$?
echo "##[endgroup]"
exit $return_code
