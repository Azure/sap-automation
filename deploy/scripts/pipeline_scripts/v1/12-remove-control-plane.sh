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

#call stack has full script name when using source
source "${parent_directory}/helper.sh"
source "${grand_parent_directory}/deploy_utils.sh"
SCRIPT_NAME="$(basename "$0")"

banner_title="Remove Control Plane"

DEBUG=False

if [ "$SYSTEM_DEBUG" = True ]; then
	set -x
	set -o errexit
	DEBUG=True
	echo "Environment variables:"
	printenv | sort

fi

export DEBUG
set -eu
# Ensure that the exit status of a pipeline command is non-zero if any
# stage of the pipefile has a non-zero exit status.
set -o pipefail

echo "##vso[build.updatebuildnumber]Removing the control plane defined in $DEPLOYER_FOLDERNAME $LIBRARY_FOLDERNAME"

print_banner "$banner_title" "Entering $SCRIPT_NAME" "info"

# Set logon variables
if [ "$USE_MSI" != "true" ]; then

	ARM_TENANT_ID=$(az account show --query tenantId --output tsv)
	export ARM_TENANT_ID
	ARM_SUBSCRIPTION_ID=$(az account show --query id --output tsv)
	export ARM_SUBSCRIPTION_ID
else
	unset ARM_CLIENT_SECRET
	ARM_USE_MSI=true
	export ARM_USE_MSI
fi

if [ -v SYSTEM_ACCESSTOKEN ]; then
	export TF_VAR_PAT="$SYSTEM_ACCESSTOKEN"
fi

# Check if running on deployer
if [[ ! -f /etc/profile.d/deploy_server.sh ]]; then
	configureNonDeployer "${tf_version:-1.12.2}"
	echo -e "$green--- az login ---$reset"
fi
LogonToAzure $USE_MSI
return_code=$?
if [ 0 != $return_code ]; then
	echo -e "$bold_red--- Login failed ---$reset"
	echo "##vso[task.logissue type=error]az login failed."
	exit $return_code
fi

TF_VAR_subscription_id=$ARM_SUBSCRIPTION_ID
export TF_VAR_subscription_id

if printenv ARM_OBJECT_ID; then
	if is_valid_guid "$ARM_OBJECT_ID"; then
		TF_VAR_spn_id="$ARM_OBJECT_ID"
		export TF_VAR_spn_id
	fi
fi
# Print the execution environment details
print_header

# Configure DevOps
configure_devops

ENVIRONMENT_IN_FILENAME=$(echo $DEPLOYER_FOLDERNAME | awk -F'-' '{print $1}')
LOCATION_CODE_IN_FILENAME=$(echo $DEPLOYER_FOLDERNAME | awk -F'-' '{print $2}')

CONTROL_PLANE_NAME="${ENVIRONMENT_IN_FILENAME}${LOCATION_CODE_IN_FILENAME}"
export CONTROL_PLANE_NAME

VARIABLE_GROUP="SDAF-${ENVIRONMENT_IN_FILENAME}"
deployerTFvarsFile="${CONFIG_REPO_PATH}/DEPLOYER/$DEPLOYER_FOLDERNAME/$DEPLOYER_TFVARS_FILENAME"
libraryTFvarsFile="${CONFIG_REPO_PATH}/LIBRARY/$LIBRARY_FOLDERNAME/$LIBRARY_TFVARS_FILENAME"
deployer_tfstate_key="$DEPLOYER_FOLDERNAME.terraform.tfstate"
deployer_environment_file_name="${CONFIG_REPO_PATH}/.sap_deployment_automation/$CONTROL_PLANE_NAME"

if ! get_variable_group_id "$VARIABLE_GROUP" "VARIABLE_GROUP_ID"; then
	echo -e "$bold_red--- Variable group $VARIABLE_GROUP not found ---$reset"
	echo "##vso[task.logissue type=error]Variable group $VARIABLE_GROUP not found."
	exit 2
else
	DEPLOYER_KEYVAULT=$(getVariableFromVariableGroup "${VARIABLE_GROUP_ID}" "DEPLOYER_KEYVAULT" "${deployer_environment_file_name}" "DEPLOYER_KEYVAULT")

	TF_VAR_spn_keyvault_id=$(az keyvault show --name "$DEPLOYER_KEYVAULT" --subscription "$ARM_SUBSCRIPTION_ID" --query id -o tsv)
	export TF_VAR_spn_keyvault_id
fi
export VARIABLE_GROUP_ID

TF_VAR_deployer_tfstate_key="$deployer_tfstate_key"
export TF_VAR_deployer_tfstate_key

if [ ! -f "$deployerTFvarsFile" ]; then
	print_banner "$banner_title" "$deployerTFvarsFile was not found" "error"
	echo "##vso[task.logissue type=error]File DEPLOYER/$DEPLOYER_FOLDERNAME/$DEPLOYER_TFVARS_FILENAME was not found."
	exit 2
fi

if [ ! -f "${libraryTFvarsFile}" ]; then
	print_banner "$banner_title" "$libraryTFvarsFile was not found" "error"
	echo "##vso[task.logissue type=error]File LIBRARY/$LIBRARY_FOLDERNAME/$LIBRARY_TFVARS_FILENAME was not found."
	exit 2
fi

if [ -z "$ARM_SUBSCRIPTION_ID" ]; then
	echo "##vso[task.logissue type=error]Variable ARM_SUBSCRIPTION_ID was not defined."
	exit 2
fi

az account set --subscription "$ARM_SUBSCRIPTION_ID"

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

echo -e "$green--- Running the remove remove_controlplane that destroys SAP library ---$reset"

if "$SAP_AUTOMATION_REPO_PATH/deploy/scripts/remove_controlplane.sh" \
	--deployer_parameter_file "$deployerTFvarsFile" \
	--library_parameter_file "$libraryTFvarsFile" \
	--storage_account "$REMOTE_STATE_SA" \
	--subscription "${STATE_SUBSCRIPTION}" \
	--resource_group "$REMOTE_STATE_RG" \
	--ado --auto-approve --keep_agent; then
	return_code=$?
	print_banner "$banner_title" "Control Plane $DEPLOYER_FOLDERNAME removal step 1 completed" "success"

	echo "##vso[task.logissue type=warning]Control Plane $DEPLOYER_FOLDERNAME removal step 1 completed."
else
	return_code=$?
	print_banner "$banner_title" "Control Plane $DEPLOYER_FOLDERNAME removal step 1 failed" "error"
fi

echo "Return code from remove_controlplane.sh: $return_code."

echo -e "$green--- Remove Control Plane Part 1 ---$reset"
cd "$CONFIG_REPO_PATH" || exit
git checkout -q "$BUILD_SOURCEBRANCHNAME"

changed=0
if [ -f "$deployer_environment_file_name" ]; then
	git add "$deployer_environment_file_name"
	changed=1
fi

if [ -f "LIBRARY/$LIBRARY_FOLDERNAME/$libraryTFvarsFile" ]; then
	echo "Resetting library TFvars file: $libraryTFvarsFile"
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

if [ 0 -eq $return_code ]; then
	if [ -d "LIBRARY/$LIBRARY_FOLDERNAME/.terraform" ]; then
		git rm -q -f --ignore-unmatch "LIBRARY/$LIBRARY_FOLDERNAME/.terraform/terraform.tfstate"
		git rm -q -r --ignore-unmatch "LIBRARY/$LIBRARY_FOLDERNAME/.terraform"
		changed=1
		if [ -f "LIBRARY/$LIBRARY_FOLDERNAME/.terraform/terraform.tfstate" ]; then
			rm "LIBRARY/$LIBRARY_FOLDERNAME/.terraform/terraform.tfstate"
		fi

	fi

	if [ -d "LIBRARY/$LIBRARY_FOLDERNAME/terraform.tfstate" ]; then
		git rm -q -r --ignore-unmatch "LIBRARY/$LIBRARY_FOLDERNAME/terraform.tfstate"
		changed=1
	fi

	if [ -f "LIBRARY/$LIBRARY_FOLDERNAME/state.zip" ]; then
		git rm -q -f --ignore-unmatch "LIBRARY/$LIBRARY_FOLDERNAME/state.zip"
		changed=1
		rm "LIBRARY/$LIBRARY_FOLDERNAME/state.zip"
	fi

	if [ -f "LIBRARY/$LIBRARY_FOLDERNAME/backend-config.tfvars" ]; then
		git rm -q --ignore-unmatch "LIBRARY/$LIBRARY_FOLDERNAME/backend-config.tfvars"
		changed=1
	fi
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
print_banner "$banner_title" "Exiting $SCRIPT_NAME" "info"

exit $return_code
