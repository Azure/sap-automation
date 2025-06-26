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

echo -e "$green--- az login ---$reset"
# Check if running on deployer
if [ ! -f /etc/profile.d/deploy_server.sh ]; then
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

command="ansible-playbook -e download_directory=$AGENT_TEMP_DIRECTORY \
-e s_user=$SUSERNAME -e BOM_directory=${sample_path} \
-e bom_base_name=$BOM_NAME \
-e deployer_kv_name=$KV_NAME \
-e check_storage_account=$CHECK_STORAGE_ACCOUNT \
 $EXTRA_PARAMETERS $SAP_AUTOMATION_REPO_PATH/deploy/ansible/playbook_bom_downloader.yaml"

echo "##[section]Executing [$command]..."
echo "##[group]- output"
eval $command
return_code=$?
echo "##[endgroup]"
exit $return_code
