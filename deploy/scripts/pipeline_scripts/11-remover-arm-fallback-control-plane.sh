#!/bin/bash

# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

green="\e[1;32m"
reset="\e[0m"
echo -e "$green--- Configure devops CLI extension ---$reset"
az config set extension.use_dynamic_install=yes_without_prompt --only-show-errors --output none

deployerTFvarsFile="${CONFIG_REPO_PATH}/DEPLOYER/$DEPLOYER_FOLDERNAME/$DEPLOYER_TFVARS_FILENAME"
libraryTFvarsFile="${CONFIG_REPO_PATH}/LIBRARY/$LIBRARY_FOLDERNAME/$LIBRARY_TFVARS_FILENAME"


if [ "$SYSTEM_DEBUG" = True ]; then
  set -x
  debug=true
  export debug
fi

if [  "${#PAT}" -gt 0 ]; then
  echo "Using PAT for authentication"
  AZURE_DEVOPS_EXT_PAT=$PAT
else
  echo "Using SYSTEM_ACCESSTOKEN for authentication"
  AZURE_DEVOPS_EXT_PAT=$SYSTEM_ACCESSTOKEN
fi

export AZURE_DEVOPS_EXT_PAT

az devops configure --defaults organization="$SYSTEM_COLLECTIONURI" project="$SYSTEM_TEAMPROJECT" --output none

return_code=0

ENVIRONMENT=$(echo "$DEPLOYER_FOLDERNAME" | awk -F'-' '{print $1}' | xargs)
echo "Environment:                           $ENVIRONMENT"

LOCATION=$(echo "$DEPLOYER_FOLDERNAME" | awk -F'-' '{print $2}' | xargs)
echo
echo "Location:                              $LOCATION"

NETWORK=$(echo "$DEPLOYER_FOLDERNAME" | awk -F'-' '{print $3}' | xargs)
echo "Network:                               $NETWORK"

VARIABLE_GROUP_ID=$(az pipelines variable-group list --query "[?name=='$PARENT_VARIABLE_GROUP'].id | [0]")

echo "Variable group:                        $VARIABLE_GROUP_ID"
variable_value=$(az pipelines variable-group variable list --group-id "${VARIABLE_GROUP_ID}" --query "CP_ARM_SUBSCRIPTION_ID.value" --out tsv)
if [ -z "$variable_value" ]; then
  subscription=$ARM_SUBSCRIPTION_ID
else
  subscription=$variable_value
fi
echo "Subscription:                          $subscription"

resourceGroupName=$(az group list --subscription "$subscription" --query "[?name=='$LIBRARY_FOLDERNAME'].name | [0]")
if [ ${#resourceGroupName} != 0 ]; then
  echo "Deleting resource group:               $LIBRARY_FOLDERNAME"
  echo "##vso[task.setprogress value=0;]Progress Indicator"

  # shellcheck disable=SC2046
  az group delete --subscription "$subscription" --name $LIBRARY_FOLDERNAME --yes --only-show-errors
  return_code=$?
  echo "##vso[task.setprogress value=30;]Progress Indicator"
else
  echo "Resource group $LIBRARY_FOLDERNAME does not exist."
fi

resourceGroupName=$(az group list --subscription "$subscription" --query "[?name=='$DEPLOYER_FOLDERNAME'].name  | [0]")
if [ ${#resourceGroupName} != 0 ]; then
  echo "Deleting resource group:               $DEPLOYER_FOLDERNAME"
  echo "##vso[task.setprogress value=60;]Progress Indicator"
  az group delete --subscription "$subscription" --name "$DEPLOYER_FOLDERNAME" --yes --only-show-errors
  return_code=$?
else
  echo "Resource group $DEPLOYER_FOLDERNAME does not exist"
fi

echo -e "$green--- Removing deployment automation configuration from devops repository ---$reset"

echo "##vso[task.setprogress value=90;]Progress Indicator"

if [ 0 == $return_code ]; then
  cd "$CONFIG_REPO_PATH" || exit
  git checkout -q $BUILD_SOURCEBRANCHNAME
  git pull
  changed=0

  echo "##vso[build.updatebuildnumber]Removing control plane $DEPLOYER_FOLDERNAME $LIBRARY_FOLDERNAME"
	if [ -f "LIBRARY/$LIBRARY_FOLDERNAME/$libraryTFvarsFile" ]; then
		sed -i /"custom_random_id"/d "LIBRARY/$LIBRARY_FOLDERNAME/$libraryTFvarsFile"
		git add -f "LIBRARY/$LIBRARY_FOLDERNAME/$libraryTFvarsFile"
		changed=1
	fi

	if [ -f "DEPLOYER/$DEPLOYER_FOLDERNAME/$deployerTFvarsFile" ]; then
		sed -i /"custom_random_id"/d "DEPLOYER/$DEPLOYER_FOLDERNAME/$deployerTFvarsFile"
		git add -f "DEPLOYER/$DEPLOYER_FOLDERNAME/$deployerTFvarsFile"
		changed=1
	fi

  if [ -d "DEPLOYER/$DEPLOYER_FOLDERNAME/.terraform" ]; then
    git rm -q -r --ignore-unmatch "DEPLOYER/$DEPLOYER_FOLDERNAME/.terraform"
    changed=1
  fi

  if [ -f "DEPLOYER/$DEPLOYER_FOLDERNAME/state.zip" ]; then
    git rm -q --ignore-unmatch "DEPLOYER/$DEPLOYER_FOLDERNAME/state.zip"
    changed=1
  fi

  if [ -d "LIBRARY/$LIBRARY_FOLDERNAME/.terraform" ]; then
    git rm -q -r --ignore-unmatch "LIBRARY/$LIBRARY_FOLDERNAME/.terraform"
    changed=1
  fi

  if [ -f "LIBRARY/$LIBRARY_FOLDERNAME/state.zip" ]; then
    git rm -q --ignore-unmatch "LIBRARY/$LIBRARY_FOLDERNAME/state.zip"
    changed=1
  fi

  if [ -f ".sap_deployment_automation/${ENVIRONMENT}${LOCATION}" ]; then
    git rm -q --ignore-unmatch ".sap_deployment_automation/${ENVIRONMENT}${LOCATION}"
    changed=1
  fi
  if [ -f ".sap_deployment_automation/${ENVIRONMENT}${LOCATION}.md" ]; then
    git rm -q --ignore-unmatch ".sap_deployment_automation/${ENVIRONMENT}${LOCATION}.md"
    changed=1
  fi

  if [ -f "LIBRARY/$LIBRARY_FOLDERNAME/backend-config.tfvars" ]; then
    git rm -q --ignore-unmatch "LIBRARY/$LIBRARY_FOLDERNAME/backend-config.tfvars"
    changed=1
  fi

  if [ 1 == $changed ]; then
    git config --global user.email "$BUILD_REQUESTEDFOREMAIL"
    git config --global user.name "$BUILD_REQUESTEDFOR"
    git commit -m "Added updates from devops deployment $BUILD_BUILDNUMBER [skip ci]"
    if git -c http.extraheader="AUTHORIZATION: bearer $SYSTEM_ACCESSTOKEN" push --set-upstream origin "$BUILD_SOURCEBRANCHNAME" --force-with-lease; then
      echo "##vso[task.logissue type=warning]Changes pushed to $BUILD_SOURCEBRANCHNAME"
    else
      echo "##vso[task.logissue type=error]Failed to push changes to $BUILD_SOURCEBRANCHNAME"
    fi
    echo -e "$green--- Deleting variables ---$reset"
    if [ ${#VARIABLE_GROUP_ID} != 0 ]; then
      echo "Deleting variables"

      variable_value=$(az pipelines variable-group variable list --group-id "${VARIABLE_GROUP_ID}" --query "Terraform_Remote_Storage_Account_Name.value" --out tsv)
      if [ ${#variable_value} != 0 ]; then
        az pipelines variable-group variable delete --group-id "${VARIABLE_GROUP_ID}" --name Terraform_Remote_Storage_Account_Name --yes --only-show-errors
      fi

      variable_value=$(az pipelines variable-group variable list --group-id "${VARIABLE_GROUP_ID}" --query "Terraform_Remote_Storage_Resource_Group_Name.value" --out tsv)
      if [ ${#variable_value} != 0 ]; then
        az pipelines variable-group variable delete --group-id "${VARIABLE_GROUP_ID}" --name Terraform_Remote_Storage_Resource_Group_Name --yes --only-show-errors
      fi

      variable_value=$(az pipelines variable-group variable list --group-id "${VARIABLE_GROUP_ID}" --query "Terraform_Remote_Storage_Subscription.value" --out tsv)
      if [ ${#variable_value} != 0 ]; then
        az pipelines variable-group variable delete --group-id "${VARIABLE_GROUP_ID}" --name Terraform_Remote_Storage_Subscription --yes --only-show-errors
      fi

      variable_value=$(az pipelines variable-group variable list --group-id "${VARIABLE_GROUP_ID}" --query "Deployer_State_FileName.value" --out tsv)
      if [ ${#variable_value} != 0 ]; then
        az pipelines variable-group variable delete --group-id "${VARIABLE_GROUP_ID}" --name Deployer_State_FileName --yes --only-show-errors
      fi

      variable_value=$(az pipelines variable-group variable list --group-id "${VARIABLE_GROUP_ID}" --query "Deployer_Key_Vault.value" --out tsv)
      if [ ${#variable_value} != 0 ]; then
        az pipelines variable-group variable delete --group-id "${VARIABLE_GROUP_ID}" --name Deployer_Key_Vault --yes --only-show-errors
      fi

      variable_value=$(az pipelines variable-group variable list --group-id "${VARIABLE_GROUP_ID}" --query "WEBAPP_URL_BASE.value" --out tsv)
      if [ ${#variable_value} != 0 ]; then
        az pipelines variable-group variable delete --group-id "${VARIABLE_GROUP_ID}" --name WEBAPP_URL_BASE --yes --only-show-errors
      fi

      variable_value=$(az pipelines variable-group variable list --group-id "${VARIABLE_GROUP_ID}" --query "WEBAPP_IDENTITY.value" --out tsv)
      if [ ${#variable_value} != 0 ]; then
        az pipelines variable-group variable delete --group-id "${VARIABLE_GROUP_ID}" --name WEBAPP_IDENTITY --yes --only-show-errors
      fi

      variable_value=$(az pipelines variable-group variable list --group-id "${VARIABLE_GROUP_ID}" --query "WEBAPP_ID.value" --out tsv)
      if [ ${#variable_value} != 0 ]; then
        az pipelines variable-group variable delete --group-id "${VARIABLE_GROUP_ID}" --name WEBAPP_ID --yes --only-show-errors
      fi

      variable_value=$(az pipelines variable-group variable list --group-id "${VARIABLE_GROUP_ID}" --query "INSTALLATION_MEDIA_ACCOUNT.value" --out tsv)
      if [ ${#variable_value} != 0 ]; then
        az pipelines variable-group variable delete --group-id "${VARIABLE_GROUP_ID}" --name INSTALLATION_MEDIA_ACCOUNT --yes --only-show-errors
      fi

      variable_value=$(az pipelines variable-group variable list --group-id "${VARIABLE_GROUP_ID}" --query "DEPLOYER_RANDOM_ID.value" --out tsv)
      if [ ${#variable_value} != 0 ]; then
        az pipelines variable-group variable delete --group-id "${VARIABLE_GROUP_ID}" --name DEPLOYER_RANDOM_ID --yes --only-show-errors
      fi

      variable_value=$(az pipelines variable-group variable list --group-id "${VARIABLE_GROUP_ID}" --query "LIBRARY_RANDOM_ID.value" --out tsv)
      if [ ${#variable_value} != 0 ]; then
        az pipelines variable-group variable delete --group-id "${VARIABLE_GROUP_ID}" --name LIBRARY_RANDOM_ID --yes --only-show-errors
      fi

    fi

  fi
fi

echo "##vso[task.setprogress value=100;]Progress Indicator"

exit $return_code
