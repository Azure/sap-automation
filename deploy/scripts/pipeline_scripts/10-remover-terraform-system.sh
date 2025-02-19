#!/bin/bash
# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.
echo "##vso[build.updatebuildnumber]Removing the SAP System defined in $SAP_SYSTEM_FOLDERNAME"

green="\e[1;32m"
reset="\e[0m"
bold_red="\e[1;31m"
cyan="\e[1;36m"

# External helper functions
#. "$(dirname "${BASH_SOURCE[0]}")/deploy_utils.sh"
full_script_path="$(realpath "${BASH_SOURCE[0]}")"
script_directory="$(dirname "${full_script_path}")"

#call stack has full scriptname when using source
source "${script_directory}/helper.sh"

DEBUG=False

if [ "$SYSTEM_DEBUG" = True ]; then
  set -x
  DEBUG=True
fi
export DEBUG
set -eu

tfvarsFile="SYSTEM/$SAP_SYSTEM_FOLDERNAME/$SAP_SYSTEM_TFVARS_FILENAME"

echo -e "$green--- Checkout $BUILD_SOURCEBRANCHNAME ---$reset"

cd "${CONFIG_REPO_PATH}" || exit
git checkout -q "$BUILD_SOURCEBRANCHNAME"

if [ ! -f "$CONFIG_REPO_PATH/SYSTEM/$SAP_SYSTEM_FOLDERNAME/$SAP_SYSTEM_TFVARS_FILENAME" ]; then
  echo -e "$bold_red--- $SAP_SYSTEM_TFVARS_FILENAME was not found ---$reset"
  echo "##vso[task.logissue type=error]File $SAP_SYSTEM_TFVARS_FILENAME was not found."
  exit 2
fi

echo -e "$green--- Validations ---$reset"
if [ "$USE_MSI" != "true" ]; then

  if [ -z "$WL_ARM_SUBSCRIPTION_ID" ]; then
    echo "##vso[task.logissue type=error]Variable ARM_SUBSCRIPTION_ID was not defined in the $(variable_group) variable group."
    exit 2
  fi

  if [ "$WL_ARM_SUBSCRIPTION_ID" == '$$(ARM_SUBSCRIPTION_ID)' ]; then
    echo "##vso[task.logissue type=error]Variable ARM_SUBSCRIPTION_ID was not defined in the $(variable_group) variable group."
    exit 2
  fi

  if [ -z "$WL_ARM_CLIENT_ID" ]; then
    echo "##vso[task.logissue type=error]Variable ARM_CLIENT_ID was not defined in the $(variable_group) variable group."
    exit 2
  fi

  if [ "$WL_ARM_CLIENT_ID" == '$$(ARM_CLIENT_ID)' ]; then
    echo "##vso[task.logissue type=error]Variable ARM_CLIENT_ID was not defined in the $(variable_group) variable group."
    exit 2
  fi

  if [ -z "$WL_ARM_CLIENT_SECRET" ]; then
    echo "##vso[task.logissue type=error]Variable ARM_CLIENT_SECRET was not defined in the $(variable_group) variable group."
    exit 2
  fi

  if [ "$WL_ARM_CLIENT_SECRET" == '$$(ARM_CLIENT_SECRET)' ]; then
    echo "##vso[task.logissue type=error]Variable ARM_CLIENT_SECRET was not defined in the $(variable_group) variable group."
    exit 2
  fi

  if [ -z "$WL_ARM_TENANT_ID" ]; then
    echo "##vso[task.logissue type=error]Variable ARM_TENANT_ID was not defined in the $(variable_group) variable group."
    exit 2
  fi

  if [ "$WL_ARM_TENANT_ID" == '$$(ARM_TENANT_ID)' ]; then
    echo "##vso[task.logissue type=error]Variable ARM_TENANT_ID was not defined in the $(variable_group) variable group."
    exit 2
  fi

  if [ -z "$CP_ARM_SUBSCRIPTION_ID" ]; then
    echo "##vso[task.logissue type=error]Variable CP_ARM_SUBSCRIPTION_ID was not defined in the $(parent_variable_group) variable group."
    exit 2
  fi
fi

# Set logon variables
ARM_CLIENT_ID="$WL_ARM_CLIENT_ID"
export ARM_CLIENT_ID
ARM_CLIENT_SECRET="$WL_ARM_CLIENT_SECRET"
export ARM_CLIENT_SECRET
ARM_TENANT_ID=$WL_ARM_TENANT_ID
export ARM_TENANT_ID
ARM_SUBSCRIPTION_ID=$WL_ARM_SUBSCRIPTION_ID
export ARM_SUBSCRIPTION_ID

# Check if running on deployer
if [[ ! -f /etc/profile.d/deploy_server.sh ]]; then
  configureNonDeployer "$(tf_version)" || true
  echo -e "$green--- az login ---$reset"
  LogonToAzure false || true
else
  LogonToAzure "$USE_MSI" || true
fi
return_code=$?
if [ 0 != $return_code ]; then
  echo -e "$bold_red--- Login failed ---$reset"
  echo "##vso[task.logissue type=error]az login failed."
  exit $return_code
fi

ARM_SUBSCRIPTION_ID=$WL_ARM_SUBSCRIPTION_ID
export ARM_SUBSCRIPTION_ID
az account set --subscription "$ARM_SUBSCRIPTION_ID"

echo -e "$green--- Read deployment details ---$reset"
dos2unix -q tfvarsFile

ENVIRONMENT=$(grep -m1 "^environment" "$tfvarsFile" | awk -F'=' '{print $2}' | tr -d ' \t\n\r\f"')
LOCATION=$(grep -m1 "^location" "$tfvarsFile" | awk -F'=' '{print $2}' | tr '[:upper:]' '[:lower:]' | tr -d ' \t\n\r\f"')
NETWORK=$(grep -m1 "^network_logical_name" "$tfvarsFile" | awk -F'=' '{print $2}' | tr -d ' \t\n\r\f"')
SID=$(grep -m1 "^sid" "$tfvarsFile" | awk -F'=' '{print $2}' | tr -d ' \t\n\r\f"')

ENVIRONMENT_IN_FILENAME=$(echo "$SAP_SYSTEM_FOLDERNAME" | awk -F'-' '{print $1}')

LOCATION_CODE_IN_FILENAME=$(echo "$SAP_SYSTEM_FOLDERNAME" | awk -F'-' '{print $2}')
LOCATION_IN_FILENAME=$(get_region_from_code "$LOCATION_CODE_IN_FILENAME" || true)

NETWORK_IN_FILENAME=$(echo "$SAP_SYSTEM_FOLDERNAME" | awk -F'-' '{print $3}')

SID_IN_FILENAME=$(echo "$SAP_SYSTEM_FOLDERNAME" | awk -F'-' '{print $4}')

echo "System TFvars:                       $SAP_SYSTEM_TFVARS_FILENAME"
echo "Environment:                         $ENVIRONMENT"
echo "Location:                            $LOCATION"
echo "Network:                             $NETWORK"
echo "SID:                                 $SID"

echo "Environment(filename):               $ENVIRONMENT_IN_FILENAME"
echo "Location(filename):                  $LOCATION_IN_FILENAME"
echo "Network(filename):                   $NETWORK_IN_FILENAME"
echo "SID(filename):                       $SID_IN_FILENAME"

echo ""
echo "Agent pool:                          $THIS_AGENT"
echo "Organization:                        $SYSTEM_COLLECTIONURI"
echo "Project:                             $SYSTEM_TEAMPROJECT"
echo ""
echo "Azure CLI version:"
echo "-------------------------------------------------"
az --version

if [ "$ENVIRONMENT" != "$ENVIRONMENT_IN_FILENAME" ]; then
  echo "##vso[task.logissue type=error]The environment setting in $SAP_SYSTEM_TFVARS_FILENAME '$ENVIRONMENT' does not match the $SAP_SYSTEM_TFVARS_FILENAME file name '$ENVIRONMENT_IN_FILENAME'. Filename should have the pattern [ENVIRONMENT]-[REGION_CODE]-[NETWORK_LOGICAL_NAME]-INFRASTRUCTURE"
  exit 2
fi

if [ "$LOCATION" != "$LOCATION_IN_FILENAME" ]; then
  echo "##vso[task.logissue type=error]The location setting in $SAP_SYSTEM_TFVARS_FILENAME '$LOCATION' does not match the $SAP_SYSTEM_TFVARS_FILENAME file name '$LOCATION_IN_FILENAME'. Filename should have the pattern [ENVIRONMENT]-[REGION_CODE]-[NETWORK_LOGICAL_NAME]-INFRASTRUCTURE"
  exit 2
fi

if [ "$NETWORK" != "$NETWORK_IN_FILENAME" ]; then
  echo "##vso[task.logissue type=error]The network_logical_name setting in $SAP_SYSTEM_TFVARS_FILENAME '$NETWORK' does not match the $SAP_SYSTEM_TFVARS_FILENAME file name '$NETWORK_IN_FILENAME-. Filename should have the pattern [ENVIRONMENT]-[REGION_CODE]-[NETWORK_LOGICAL_NAME]-INFRASTRUCTURE"
  exit 2
fi

if [ "$SID" != "$SID_IN_FILENAME" ]; then
  echo "##vso[task.logissue type=error]The sid setting in $SAP_SYSTEM_TFVARS_FILENAME '$SID' does not match the $SAP_SYSTEM_TFVARS_FILENAME file name '$SID_IN_FILENAME-. Filename should have the pattern [ENVIRONMENT]-[REGION_CODE]-[NETWORK_LOGICAL_NAME]-[SID]"
  exit 2
fi

workload_environment_file_name="$CONFIG_REPO_PATH/.sap_deployment_automation/${ENVIRONMENT}${LOCATION_CODE_IN_FILENAME}${NETWORK}"
echo "Workload Zone Environment File:      $workload_environment_file_name"

echo -e "$green--- Configure devops CLI extension ---$reset"
az config set extension.use_dynamic_install=yes_without_prompt --output none --only-show-errors

az extension add --name azure-devops --output none --only-show-errors

az devops configure --defaults organization="$SYSTEM_COLLECTIONURI" project='$SYSTEM_TEAMPROJECT'

VARIABLE_GROUP_ID=$(az pipelines variable-group list --query "[?name=='$VARIABLE_GROUP'].id | [0]")
export VARIABLE_GROUP_ID
if [ -z "${VARIABLE_GROUP_ID}" ]; then
  echo "##vso[task.logissue type=error]Variable group $VARIABLE_GROUP could not be found."
  exit 2
fi

printf -v tempval '%s id:' "$VARIABLE_GROUP"
printf -v val '%-20s' "${tempval}"
echo "$val                 $VARIABLE_GROUP_ID"

echo -e "$green--- Read parameter values ---$reset"

dos2unix -q "${workload_environment_file_name}"

prefix="${ENVIRONMENT}${LOCATION_CODE_IN_FILENAME}${NETWORK}"

deployer_tfstate_key=$(getVariableFromVariableGroup "${VARIABLE_GROUP_ID}" "Deployer_State_FileName" "${workload_environment_file_name}" "deployer_tfstate_key" || true)
export deployer_tfstate_key

key_vault=$(getVariableFromVariableGroup "${VARIABLE_GROUP_ID}" "Deployer_Key_Vault" "${workload_environment_file_name}" "keyvault" || true)
export key_vault

REMOTE_STATE_SA=$(getVariableFromVariableGroup "${VARIABLE_GROUP_ID}" "Terraform_Remote_Storage_Account_Name" "${workload_environment_file_name}" "REMOTE_STATE_SA" || true)
export REMOTE_STATE_SA

STATE_SUBSCRIPTION=$(getVariableFromVariableGroup "${VARIABLE_GROUP_ID}" "Terraform_Remote_Storage_Subscription" "${workload_environment_file_name}" "STATE_SUBSCRIPTION" || true)
export STATE_SUBSCRIPTION

workload_key_vault=$(getVariableFromVariableGroup "${VARIABLE_GROUP_ID}" "${prefix}Workload_Key_Vault" "${workload_environment_file_name}" "workloadkeyvault" || true)
export workload_key_vault

landscape_tfstate_key=$(getVariableFromVariableGroup "${VARIABLE_GROUP_ID}" "${prefix}Workload_Zone_State_FileName" "${workload_environment_file_name}" "deployer_tfstate_key" || true)
export landscape_tfstate_key

echo "Deployer statefile:                  $deployer_tfstate_key"
echo "Workload statefile:                  $landscape_tfstate_key"
echo "Deployer Key vault:                  $key_vault"
echo "Workload Key vault:                  ${workload_key_vault}"
echo "Target subscription                  $WL_ARM_SUBSCRIPTION_ID"

echo "Terraform state file subscription:   $STATE_SUBSCRIPTION"
echo "Terraform state file storage account:$REMOTE_STATE_SA"

tfstate_resource_id=$(az resource list --name "${REMOTE_STATE_SA}" --subscription "$STATE_SUBSCRIPTION" --resource-type Microsoft.Storage/storageAccounts --query "[].id | [0]" -o tsv)
export tfstate_resource_id

echo -e "$green--- Run the remover script that destroys the SAP system ---$reset"

cd "$CONFIG_REPO_PATH/SYSTEM/$SAP_SYSTEM_FOLDERNAME" || exit

${SAP_AUTOMATION_REPO_PATH}/deploy/scripts/remover.sh \
  --parameterfile $SAP_SYSTEM_TFVARS_FILENAME \
  --type sap_system \
  --state_subscription "${STATE_SUBSCRIPTION}" \
  --storageaccountname "${REMOTE_STATE_SA}" \
  --deployer_tfstate_key "${deployer_tfstate_key}" \
  --landscape_tfstate_key "${landscape_tfstate_key}" \
  --auto-approve

return_code=$?
echo -e "$green--- Pull latest from DevOps Repository ---$reset"
git checkout -q "$BUILD_SOURCEBRANCHNAME"
git pull

#stop the pipeline after you have reset the whitelisting on your resources
echo "Return code from remover.sh:         $return_code."
if [ 0 != $return_code ]; then
  echo "##vso[task.logissue type=error]Return code from remover.sh $return_code."
  exit $return_code
fi

echo -e "$green--- Add & update files in the DevOps Repository ---$reset"
cd "$CONFIG_REPO_PATH" || exit

changed=0

cd "${CONFIG_REPO_PATH}/SYSTEM/$SAP_SYSTEM_FOLDERNAME" || exit

if [ 0 == $return_code ]; then
  if [ -d .terraform ]; then
    rm -r .terraform
  fi
  # Pull changes
  git checkout -q "$BUILD_SOURCEBRANCHNAME"
  git pull origin "$BUILD_SOURCEBRANCHNAME"

  git clean -d -f -X

  if [ -f ".terraform/terraform.tfstate" ]; then
    git rm --ignore-unmatch -q --ignore-unmatch ".terraform/terraform.tfstate"
    changed=1
  fi

  if [ -d ".terraform" ]; then
    git rm -q -r --ignore-unmatch ".terraform"
    changed=1
  fi

  if [ -f "$SAP_SYSTEM_TFVARS_FILENAME" ]; then
    git add "$SAP_SYSTEM_TFVARS_FILENAME"
    changed=1
  fi

  if [ -f "sap-parameters.yaml" ]; then
    git rm --ignore-unmatch -q "sap-parameters.yaml"
    changed=1
  fi

  if [ -f "${SID}_hosts.yaml" ]; then
    git rm --ignore-unmatch -q "${SID}_hosts.yaml"
    changed=1
  fi

  if [ -f "${SID}.md" ]; then
    git rm --ignore-unmatch -q "${SID}.md"
    changed=1
  fi

  if [ -f "${SID}_inventory.md" ]; then
    git rm --ignore-unmatch -q "${SID}_inventory.md"
    changed=1
  fi

  if [ -f "${SID}_virtual_machines.json" ]; then
    git rm --ignore-unmatch -q "${SID}_virtual_machines.json"
    changed=1
  fi

  if [ -d "logs" ]; then
    git rm -q -r --ignore-unmatch "logs"
    changed=1
  fi

  if [ 1 == $changed ]; then
    git config --global user.email "$BUILD_REQUESTEDFOREMAIL"
    git config --global user.name "$BUILD_REQUESTEDFOR"

    if git commit -m "Infrastructure for $SAP_SYSTEM_TFVARS_FILENAME removed. [skip ci]"; then
      if git -c http.extraheader="AUTHORIZATION: bearer $SYSTEM_ACCESSTOKEN" push --set-upstream origin "$BUILD_SOURCEBRANCHNAME" --force-with-lease; then
        echo "##vso[task.logissue type=warning]Removal of $SAP_SYSTEM_TFVARS_FILENAME updated in $BUILD_BUILDNUMBER"
      else
        echo "##vso[task.logissue type=error]Failed to push changes to $BUILD_SOURCEBRANCHNAME"
      fi
    fi
  fi
fi

exit $return_code
