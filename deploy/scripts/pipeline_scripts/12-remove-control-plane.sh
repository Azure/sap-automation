#!/bin/bash

# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

echo "##vso[build.updatebuildnumber]Removing the control plane defined in $DEPLOYER_FOLDERNAME $LIBRARY_FOLDERNAME"
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
	set -eu
	DEBUG=True
fi

export DEBUG
# Ensure that the exit status of a pipeline command is non-zero if any
# stage of the pipefile has a non-zero exit status.
set -o pipefail

deployerTFvarsFile="${CONFIG_REPO_PATH}/DEPLOYER/$DEPLOYER_FOLDERNAME/$DEPLOYER_TFVARS_FILENAME"
libraryTFvarsFile="${CONFIG_REPO_PATH}/LIBRARY/$LIBRARY_FOLDERNAME/$LIBRARY_TFVARS_FILENAME"
deployer_tfstate_key="$DEPLOYER_FOLDERNAME.terraform.tfstate"

echo -e "$green--- File Validations ---$reset"

if [ ! -f "$deployerTFvarsFile" ]; then
	echo -e "$bold_red--- File ${deployerTFvarsFile} was not found ---$reset"
	echo "##vso[task.logissue type=error]File DEPLOYER/$DEPLOYER_FOLDERNAME/$DEPLOYER_TFVARS_FILENAME was not found."
	exit 2
fi

if [ ! -f "${libraryTFvarsFile}" ]; then
	echo -e "$bold_red--- File ${libraryTFvarsFile}  was not found ---$reset"
	echo "##vso[task.logissue type=error]File LIBRARY/$LIBRARY_FOLDERNAME/$LIBRARY_TFVARS_FILENAME was not found."
	exit 2
fi

TF_VAR_deployer_tfstate_key="$deployer_tfstate_key"
export TF_VAR_deployer_tfstate_key

echo -e "$green--- Environment information ---$reset"
ENVIRONMENT=$(grep -m1 "^environment" "$deployerTFvarsFile" | awk -F'=' '{print $2}' | tr -d ' \t\n\r\f"' || true)
LOCATION=$(grep -m1 "^location" "$deployerTFvarsFile" | awk -F'=' '{print $2}' | tr '[:upper:]' '[:lower:]' | tr -d ' \t\n\r\f"' || true)

deployer_environment_file_name="${CONFIG_REPO_PATH}/.sap_deployment_automation/${ENVIRONMENT}$LOCATION"

# shellcheck disable=SC2005
ENVIRONMENT_IN_FILENAME=$(echo $DEPLOYER_FOLDERNAME | awk -F'-' '{print $1}')

LOCATION_CODE_IN_FILENAME=$(echo $DEPLOYER_FOLDERNAME | awk -F'-' '{print $2}')
LOCATION_IN_FILENAME=$(get_region_from_code "$LOCATION_CODE_IN_FILENAME" || true)

echo "Environment:                         ${ENVIRONMENT}"
echo "Location:                            ${LOCATION}"
echo "Environment(filename):               $ENVIRONMENT_IN_FILENAME"
echo "Location(filename):                  $LOCATION_IN_FILENAME"
echo ""
echo "Agent:                               $THIS_AGENT"
echo "Organization:                        $SYSTEM_COLLECTIONURI"
echo "Project:                             $SYSTEM_TEAMPROJECT"

if [ "$ENVIRONMENT" != "$ENVIRONMENT_IN_FILENAME" ]; then
	echo "##vso[task.logissue type=error]The environment setting in $deployerTFvarsFile $ENVIRONMENT does not match the $DEPLOYER_FOLDERNAME file name $ENVIRONMENT_IN_FILENAME. Filename should have the pattern [ENVIRONMENT]-[REGION_CODE]-[NETWORK_LOGICAL_NAME]-INFRASTRUCTURE"
	exit 2
fi

if [ "$LOCATION" != "$LOCATION_IN_FILENAME" ]; then
	echo "##vso[task.logissue type=error]The location setting in $deployerTFvarsFile $LOCATION does not match the $DEPLOYER_FOLDERNAME file name $LOCATION_IN_FILENAME. Filename should have the pattern [ENVIRONMENT]-[REGION_CODE]-[NETWORK_LOGICAL_NAME]-INFRASTRUCTURE"
	exit 2
fi

deployer_environment_file_name="$CONFIG_REPO_PATH/.sap_deployment_automation/$ENVIRONMENT$LOCATION_CODE_IN_FILENAME"
echo "Environment file:                    $deployer_environment_file_name"

REMOTE_STATE_SA=""
REMOTE_STATE_RG=$LIBRARY_FOLDERNAME

echo -e "$green--- Configure devops CLI extension ---$reset"

echo "Using SYSTEM_ACCESSTOKEN for authentication"
AZURE_DEVOPS_EXT_PAT=$SYSTEM_ACCESSTOKEN

export AZURE_DEVOPS_EXT_PAT

az config set extension.use_dynamic_install=yes_without_prompt --only-show-errors
az extension add --name azure-devops --output none --only-show-errors
az devops configure --defaults organization="$SYSTEM_COLLECTIONURI" project="$SYSTEM_TEAMPROJECT" --output none --only-show-errors

if [[ -f /etc/profile.d/deploy_server.sh ]]; then
	path=$(grep -m 1 "export PATH=" /etc/profile.d/deploy_server.sh | awk -F'=' '{print $2}' | xargs)
	export PATH=$PATH:$path
fi

echo -e "$green--- Information ---$reset"
VARIABLE_GROUP_ID=$(az pipelines variable-group list --query "[?name=='$PARENT_VARIABLE_GROUP'].id | [0]")

if [ -z "${VARIABLE_GROUP_ID}" ]; then
	echo "##vso[task.logissue type=error]Variable group $PARENT_VARIABLE_GROUP could not be found."
	exit 2
fi

if [ -z "$ARM_SUBSCRIPTION_ID" ]; then
	echo "##vso[task.logissue type=error]Variable ARM_SUBSCRIPTION_ID was not defined."
	exit 2
fi

echo -e "$green--- Validations ---$reset"
if [ "$USE_MSI" != "true" ]; then

	if [ -v ARM_CLIENT_ID ]; then
		echo "##vso[task.logissue type=error]Variable ARM_CLIENT_ID was not defined in the $(variable_group) variable group."
		exit 2
	fi

	if [ "$ARM_CLIENT_ID" == '$$(ARM_CLIENT_ID)' ]; then
		echo "##vso[task.logissue type=error]Variable ARM_CLIENT_ID was not defined in the $(variable_group) variable group."
		exit 2
	fi

	if [ -v ARM_CLIENT_SECRET ]; then
		echo "##vso[task.logissue type=error]Variable ARM_CLIENT_SECRET was not defined in the $(variable_group) variable group."
		exit 2
	fi

	if [ "$ARM_CLIENT_SECRET" == '$$(ARM_CLIENT_SECRET)' ]; then
		echo "##vso[task.logissue type=error]Variable ARM_CLIENT_SECRET was not defined in the $(variable_group) variable group."
		exit 2
	fi

	if [ -v ARM_TENANT_ID ]; then
		echo "##vso[task.logissue type=error]Variable ARM_TENANT_ID was not defined in the $(variable_group) variable group."
		exit 2
	fi

	if [ "$ARM_TENANT_ID" == '$$(ARM_TENANT_ID)' ]; then
		echo "##vso[task.logissue type=error]Variable ARM_TENANT_ID was not defined in the $(variable_group) variable group."
		exit 2
	fi

fi

# Check if running on deployer
if [[ ! -f /etc/profile.d/deploy_server.sh ]]; then
	configureNonDeployer "$TF_VERSION" || true
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

az account set --subscription "$ARM_SUBSCRIPTION_ID"

key_vault=$(getVariableFromVariableGroup "${VARIABLE_GROUP_ID}" "DEPLOYER_KEYVAULT" "${deployer_environment_file_name}" "keyvault" || true)
export key_vault

STATE_SUBSCRIPTION=$ARM_SUBSCRIPTION_ID
export STATE_SUBSCRIPTION

REMOTE_STATE_SA=$(getVariableFromVariableGroup "${VARIABLE_GROUP_ID}" "Terraform_Remote_Storage_Account_Name" "${deployer_environment_file_name}" "REMOTE_STATE_SA" || true)
export REMOTE_STATE_SA

REMOTE_STATE_RG=$(getVariableFromVariableGroup "${VARIABLE_GROUP_ID}" "Terraform_Remote_Storage_Resource_Group_Name" "${deployer_environment_file_name}" "REMOTE_STATE_SA" || true)
export REMOTE_STATE_RG

echo "Terraform state subscription:        $STATE_SUBSCRIPTION"
echo "Terraform state rg name:             $REMOTE_STATE_RG"
echo "Terraform state account:             $REMOTE_STATE_SA"
echo "Deployer Key Vault:                  ${key_vault}"

if [ -f "${CONFIG_REPO_PATH}/LIBRARY/$LIBRARY_FOLDERNAME/state.zip" ]; then
	pass=${SYSTEM_COLLECTIONID//-/}
	unzip -qq -o -P "${pass}" "${CONFIG_REPO_PATH}/LIBRARY/$LIBRARY_FOLDERNAME/state.zip" -d "${CONFIG_REPO_PATH}/LIBRARY/$LIBRARY_FOLDERNAME"
	sudo rm -f "${CONFIG_REPO_PATH}/LIBRARY/$LIBRARY_FOLDERNAME/state.zip"
fi

if [ -f "${CONFIG_REPO_PATH}/DEPLOYER/$DEPLOYER_FOLDERNAME/state.zip" ]; then
	pass=${SYSTEM_COLLECTIONID//-/}
	unzip -qq -o -P "${pass}" "${CONFIG_REPO_PATH}/DEPLOYER/$DEPLOYER_FOLDERNAME/state.zip" -d "${CONFIG_REPO_PATH}/DEPLOYER/$DEPLOYER_FOLDERNAME"
	sudo rm -f "${CONFIG_REPO_PATH}/DEPLOYER/$DEPLOYER_FOLDERNAME/state.zip"
fi

echo -e "$green--- Running the remove region script that destroys deployer VM and SAP library ---$reset"

if "$SAP_AUTOMATION_REPO_PATH/deploy/scripts/remove_controlplane.sh" \
	--deployer_parameter_file "$deployerTFvarsFile" \
	--library_parameter_file "$libraryTFvarsFile" \
	--storage_account "$REMOTE_STATE_SA" \
	--subscription "${STATE_SUBSCRIPTION}" \
	--resource_group "$REMOTE_STATE_RG" \
	--ado --auto-approve --keep_agent; then
	return_code=$?
	echo "Control Plane $DEPLOYER_FOLDERNAME removal step 1 completed."
	echo "##vso[task.logissue type=warning]Control Plane $DEPLOYER_FOLDERNAME removal step 1 completed."
else
	return_code=$?
	echo "Control Plane $DEPLOYER_FOLDERNAME removal step 1 failed."
fi

echo "Return code from remove_controlplane: $return_code."

echo -e "$green--- Remove Control Plane Part 1 ---$reset"
cd "$CONFIG_REPO_PATH" || exit
git checkout -q "$BUILD_SOURCEBRANCHNAME"

changed=0
if [ -f "$deployer_environment_file_name" ]; then
	git add "$deployer_environment_file_name"
	changed=1
fi

if [ -f "LIBRARY/$LIBRARY_FOLDERNAME/$libraryTFvarsFile" ]; then
	sed -i /"custom_random_id"/d "LIBRARY/$LIBRARY_FOLDERNAME/$libraryTFvarsFile"
	git add -f "LIBRARY/$LIBRARY_FOLDERNAME/$libraryTFvarsFile"
	changed=1
fi

if [ -f "DEPLOYER/$DEPLOYER_FOLDERNAME/.terraform/terraform.tfstate" ]; then
	git add -f "DEPLOYER/$DEPLOYER_FOLDERNAME/.terraform/terraform.tfstate"
	changed=1
fi

if [ -f "DEPLOYER/$DEPLOYER_FOLDERNAME/terraform.tfstate" ]; then
	echo "Compressing the state file."
	sudo apt-get -qq install zip
	pass=${SYSTEM_COLLECTIONID//-/}

	if zip -q -j -P "${pass}" "DEPLOYER/$DEPLOYER_FOLDERNAME/state" "DEPLOYER/$DEPLOYER_FOLDERNAME/terraform.tfstate"; then
		git add -f "DEPLOYER/$DEPLOYER_FOLDERNAME/state.zip"
		changed=1
	fi
fi

if [ -d "LIBRARY/$LIBRARY_FOLDERNAME/.terraform" ]; then
	git rm -q -r --ignore-unmatch "LIBRARY/$LIBRARY_FOLDERNAME/.terraform"
	changed=1
fi

if [ -d "LIBRARY/$LIBRARY_FOLDERNAME/terraform.tfstate" ]; then
	git rm -q -r --ignore-unmatch "LIBRARY/$LIBRARY_FOLDERNAME/terraform.tfstate"
	changed=1
fi

if [ -f "LIBRARY/$LIBRARY_FOLDERNAME/state.zip" ]; then
	git rm -q -f --ignore-unmatch "LIBRARY/$LIBRARY_FOLDERNAME/state.zip"
	changed=1
fi

if [ -f "LIBRARY/$LIBRARY_FOLDERNAME/backend-config.tfvars" ]; then
	git rm -q --ignore-unmatch "LIBRARY/$LIBRARY_FOLDERNAME/backend-config.tfvars"
	changed=1
fi

if [ 1 == $changed ]; then
	git config --global user.email "$BUILD_REQUESTEDFOREMAIL"
	git config --global user.name "$BUILD_REQUESTEDFOR"

	if git commit -m "Control Plane $DEPLOYER_FOLDERNAME removal step 1[skip ci]"; then

		if git -c http.extraheader="AUTHORIZATION: bearer $SYSTEM_ACCESSTOKEN" push --set-upstream origin "$BUILD_SOURCEBRANCHNAME" --force-with-lease; then
			echo "##vso[task.logissue type=warning]Control Plane $DEPLOYER_FOLDERNAME removal step 2 updated in $BUILD_SOURCEBRANCHNAME"
		else
			echo "##vso[task.logissue type=error]Failed to push changes to $BUILD_SOURCEBRANCHNAME"
		fi
	fi

fi

exit $return_code
