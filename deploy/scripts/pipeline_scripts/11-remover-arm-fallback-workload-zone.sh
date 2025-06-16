#!/bin/bash
# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

green="\e[1;32m"
reset="\e[0m"
echo -e "$green--- Configure devops CLI extension ---$reset"
az config set extension.use_dynamic_install=yes_without_prompt --only-show-errors --output none

if [ "$SYSTEM_DEBUG" = True ]; then
  set -x
  debug=true
  export debug
fi

if [ "${#PAT}" -gt 0 ]; then
  echo "Using PAT for authentication"
  AZURE_DEVOPS_EXT_PAT=$PAT
else
  echo "Using SYSTEM_ACCESSTOKEN for authentication"
  AZURE_DEVOPS_EXT_PAT=$SYSTEM_ACCESSTOKEN
fi

export AZURE_DEVOPS_EXT_PAT

az devops configure --defaults organization="$SYSTEM_COLLECTIONURI" project="$SYSTEM_TEAMPROJECT" --output none

return_code=0

echo -e "$green--- Adding deployment automation configuration to devops repository ---$reset"
ENVIRONMENT=$(echo "$WORKLOAD_ZONE_FOLDERNAME" | awk -F'-' '{print $1}' | xargs)
echo "Environment:                           $ENVIRONMENT"

LOCATION=$(echo "$WORKLOAD_ZONE_FOLDERNAME" | awk -F'-' '{print $2}' | xargs)
echo
echo "Location:                              $LOCATION"

NETWORK=$(echo "$WORKLOAD_ZONE_FOLDERNAME" | awk -F'-' '{print $3}' | xargs)
echo "Network:                               $NETWORK"

cd "$CONFIG_REPO_PATH" || exit
git config --global user.email "$BUILD_REQUESTEDFOREMAIL"
git config --global user.name "$BUILD_REQUESTEDFOR"
git commit -m "Added updates from devops deployment $BUILD_BUILDNUMBER [skip ci]"

git checkout -q "$BUILD_SOURCEBRANCHNAME"
git clean -d -f -X


echo "##vso[build.updatebuildnumber]Removing workload zone $WORKLOAD_ZONE_FOLDERNAME"
changed=0

if [ -d "LANDSCAPE/$WORKLOAD_ZONE_FOLDERNAME/.terraform" ]; then
  git rm -r -f --ignore-unmatch "LANDSCAPE/$WORKLOAD_ZONE_FOLDERNAME/.terraform"
  changed=1
fi
if [ -f ".sap_deployment_automation/${ENVIRONMENT}${LOCATION}${NETWORK}" ]; then
  git rm --ignore-unmatch -f ".sap_deployment_automation/${ENVIRONMENT}${LOCATION}${NETWORK}"
  changed=1
fi
if [ -f ".sap_deployment_automation/${ENVIRONMENT}${LOCATION}${NETWORK}.md" ]; then
  git rm --ignore-unmatch -f ".sap_deployment_automation/${ENVIRONMENT}${LOCATION}${NETWORK}.md"
  changed=1
fi

if [ 1 == $changed ]; then
  git commit -m "Removal of Workload zone $BUILD_BUILDNUMBER [skip ci]"
  if git -c http.extraheader="AUTHORIZATION: bearer $SYSTEM_ACCESSTOKEN" push; then
    echo "Removal of Workload zone $BUILD_BUILDNUMBER pushed to devops repository"
  else
    echo "Failed to push changes to devops repository"
    return_code=1
  fi
fi
echo -e "$green--- Configure devops CLI extension ---$reset"
az config set extension.use_dynamic_install=yes_without_prompt

VARIABLE_GROUP_ID=$(az pipelines variable-group list --query "[?name=='$VARIABLE_GROUP'].id | [0]")

prefix="${ENVIRONMENT}${LOCATION}${NETWORK}"

echo "Variable Group:                        $VARIABLE_GROUP_ID"

if [ -n "$VARIABLE_GROUP_ID" ]; then
  echo "Deleting variables"
  if [ -n "$(Terraform_Remote_Storage_Account_Name)" ]; then
    az pipelines variable-group variable delete --group-id "${VARIABLE_GROUP_ID}" --name Terraform_Remote_Storage_Account_Name --yes --only-show-errors
  fi

  if [ -n "$(Terraform_Remote_Storage_Subscription)" ]; then
    az pipelines variable-group variable delete --group-id "${VARIABLE_GROUP_ID}" --name Terraform_Remote_Storage_Subscription --yes --only-show-errors >/dev/null 2>&1
  fi

  if [ -n "$(Deployer_State_FileName)" ]; then
    az pipelines variable-group variable delete --group-id "${VARIABLE_GROUP_ID}" --name Deployer_State_FileName --yes --only-show-errors >/dev/null 2>&1
  fi

  if [ -n "$(DEPLOYER_KEYVAULT)" ]; then
    az pipelines variable-group variable delete --group-id "${VARIABLE_GROUP_ID}" --name DEPLOYER_KEYVAULT --yes --only-show-errors >/dev/null 2>&1
  fi

  az_var=$(az pipelines variable-group variable list --group-id "${VARIABLE_GROUP_ID}" --query "${prefix}Workload_Key_Vault.value")
  if [ -n "${az_var}" ]; then
    az pipelines variable-group variable delete --group-id "${VARIABLE_GROUP_ID}" --name "${prefix}Workload_Key_Vault" --yes --only-show-errors
  fi

  az_var=$(az pipelines variable-group variable list --group-id "${VARIABLE_GROUP_ID}" --query "${prefix}Workload_Zone_State_FileName.value")
  if [ -n "${az_var}" ]; then
    az pipelines variable-group variable delete --group-id "${VARIABLE_GROUP_ID}" --name "${prefix}Workload_Zone_State_FileName" --yes --only-show-errors
  fi

  az_var=$(az pipelines variable-group variable list --group-id "${VARIABLE_GROUP_ID}" --query "${prefix}Workload_Secret_Prefix.value")
  if [ -n "${az_var}" ]; then
    az pipelines variable-group variable delete --group-id "${VARIABLE_GROUP_ID}" --name "${prefix}Workload_Secret_Prefix" --yes --only-show-errors
  fi
fi

exit $return_code
