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
parent_directory="$(dirname "$script_directory")"
grand_parent_directory="$(dirname "$parent_directory")"

#call stack has full script name when using source
source "${parent_directory}/helper.sh"
source "${grand_parent_directory}/deploy_utils.sh"

DEBUG=False

if [ "$SYSTEM_DEBUG" = True ]; then
	set -x
	set -eu
	DEBUG=True
fi

export DEBUG

# Check if running on deployer
if [[ ! -f /etc/profile.d/deploy_server.sh ]]; then

	configureNonDeployer "$TF_VERSION"

	ARM_CLIENT_ID="$servicePrincipalId"
	export ARM_CLIENT_ID
	TF_VAR_spn_id=$ARM_CLIENT_ID
	export TF_VAR_spn_id

	if printenv servicePrincipalKey; then
		unset ARM_OIDC_TOKEN
		ARM_CLIENT_SECRET="$servicePrincipalKey"
		export ARM_CLIENT_SECRET

	else
		ARM_OIDC_TOKEN="$idToken"
		export ARM_OIDC_TOKEN
		ARM_USE_OIDC=true
		export ARM_USE_OIDC
		unset ARM_CLIENT_SECRET
	fi

	ARM_TENANT_ID="$tenantId"
	export ARM_TENANT_ID

	ARM_USE_AZUREAD=true
	export ARM_USE_AZUREAD
else
	path=$(grep -m 1 "export PATH=" /etc/profile.d/deploy_server.sh | awk -F'=' '{print $2}' | xargs)
	export PATH=$PATH:$path
	if [ "$USE_MSI" == "true" ]; then
		TF_VAR_use_spn=false
		export TF_VAR_use_spn
		ARM_USE_MSI=true
		export ARM_USE_MSI
		echo "Deployment using:                    Managed Identity"
	else
		TF_VAR_use_spn=true
		export TF_VAR_use_spn
		ARM_USE_MSI=false
		export ARM_USE_MSI
		echo "Deployment using:                    Service Principal"
	fi
	ARM_CLIENT_ID=$(grep -m 1 "export ARM_CLIENT_ID=" /etc/profile.d/deploy_server.sh | awk -F'=' '{print $2}' | xargs)
	export ARM_CLIENT_ID
fi

if printenv OBJECT_ID; then
	if is_valid_guid "$OBJECT_ID"; then
		TF_VAR_spn_id="$OBJECT_ID"
		export TF_VAR_spn_id
	fi
fi
# Print the execution environment details
print_header

# Configure DevOps
configure_devops

CONTROL_PLANE_NAME=$(echo "$DEPLOYER_FOLDERNAME" | cut -d'-' -f1-3)
export "CONTROL_PLANE_NAME"
VARIABLE_GROUP="SDAF-${CONTROL_PLANE_NAME}"

if ! get_variable_group_id "$VARIABLE_GROUP" "VARIABLE_GROUP_ID"; then
	echo -e "$bold_red--- Variable group $VARIABLE_GROUP not found ---$reset"
	echo "##vso[task.logissue type=error]Variable group $VARIABLE_GROUP not found."
	exit 2
fi
export VARIABLE_GROUP_ID

# Ensure that the exit status of a pipeline command is non-zero if any
# stage of the pipefile has a non-zero exit status.
set -o pipefail

cd "$CONFIG_REPO_PATH" || exit

deployerTFvarsFile="${CONFIG_REPO_PATH}/DEPLOYER/$DEPLOYER_FOLDERNAME/$DEPLOYER_TFVARS_FILENAME"
libraryTFvarsFile="${CONFIG_REPO_PATH}/LIBRARY/$LIBRARY_FOLDERNAME/$LIBRARY_TFVARS_FILENAME"
deployer_tfstate_key="$DEPLOYER_FOLDERNAME.terraform.tfstate"

echo ""
echo -e "$cyan Starting the removal of the deployer and its associated infrastructure $reset"
echo ""

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

CONTROL_PLANE_NAME=$(echo "$DEPLOYER_FOLDERNAME" | cut -d'-' -f1-3)
export "CONTROL_PLANE_NAME"

deployer_environment_file_name="${CONFIG_REPO_PATH}/.sap_deployment_automation/$CONTROL_PLANE_NAME"

echo -e "$green--- Information ---$reset"

echo ""
echo "Control Plane Name:                  ${CONTROL_PLANE_NAME}"
echo "Environment file:                    $deployer_environment_file_name"

if [[ -f /etc/profile.d/deploy_server.sh ]]; then
	path=$(grep -m 1 "export PATH=" /etc/profile.d/deploy_server.sh | awk -F'=' '{print $2}' | xargs)
	export PATH=$PATH:$path
fi

if [ -z "$ARM_SUBSCRIPTION_ID" ]; then
	echo "##vso[task.logissue type=error]Variable ARM_SUBSCRIPTION_ID was not defined."
	exit 2
fi

az account set --subscription "$ARM_SUBSCRIPTION_ID"

key_vault_id=$(getVariableFromApplicationConfiguration "$APPLICATION_CONFIGURATION_ID" "${CONTROL_PLANE_NAME}_KeyVaultResourceId" "$CONTROL_PLANE_NAME")

if [ -n "${key_vault_id}" ]; then
	if [ "azure pipelines" = "$THIS_AGENT" ]; then
		key_vault_resource_group=$(echo "$key_vault_id" | cut -d'/' -f5)
		key_vault=$(echo "$key_vault_id" | cut -d'/' -f9)

		az keyvault update --name "$key_vault" --resource-group "$key_vault_resource_group" --public-network-access Enabled --output none --only-show-errors
		this_ip=$(curl -s ipinfo.io/ip) >/dev/null 2>&1
		echo "Adding the IP to the keyvault firewall rule and sleep for 30 seconds"
		az keyvault network-rule add --name "${key_vault}" --ip-address "${this_ip}" --only-show-errors --output none
		sleep 30
	fi
fi

if is_valid_id "$APPLICATION_CONFIGURATION_ID" "/providers/Microsoft.AppConfiguration/configurationStores/"; then

	app_config_name=$(echo "$APPLICATION_CONFIGURATION_ID" | cut -d'/' -f9)
	app_config_resource_group=$(echo "$APPLICATION_CONFIGURATION_ID" | cut -d'/' -f5)
	az appconfig update --name "$app_config_name" --resource-group "$app_config_resource_group" --enable-public-network true --output none --only-show-errors
	sleep 30
fi
cd "$CONFIG_REPO_PATH" || exit
echo -e "$green--- Running the remove_deployer script that destroys deployer VM ---$reset"

if [ -f "DEPLOYER/$DEPLOYER_FOLDERNAME/state.zip" ]; then
	pass=${SYSTEM_COLLECTIONID//-/}
	unzip -qq -o -P "${pass}" "DEPLOYER/$DEPLOYER_FOLDERNAME/state.zip" -d "DEPLOYER/$DEPLOYER_FOLDERNAME"
fi

echo -e "$green--- Running the remove region script that destroys deployer VM and SAP library ---$reset"

cd "$CONFIG_REPO_PATH/DEPLOYER/$DEPLOYER_FOLDERNAME" || exit

if "$SAP_AUTOMATION_REPO_PATH/deploy/scripts/remove_deployer_v2.sh" --auto-approve \
	--parameter_file "$DEPLOYER_TFVARS_FILENAME"; then
	return_code=$?
	echo "Control Plane $DEPLOYER_FOLDERNAME removal step 2 completed."
	echo "##vso[task.logissue type=warning]Control Plane $DEPLOYER_FOLDERNAME removal step 2 completed."
else
	return_code=$?
	echo "Control Plane $DEPLOYER_FOLDERNAME removal step 2 failed."
fi

echo "Return code from remove_deployer: $return_code."

echo -e "$green--- Remove Control Plane Part 2 ---$reset"
git checkout -q "$BUILD_SOURCEBRANCHNAME"
git pull -q

if [ 0 == $return_code ]; then
	cd "$CONFIG_REPO_PATH" || exit
	changed=0

	if [ -f "DEPLOYER/$DEPLOYER_FOLDERNAME/$deployerTFvarsFile" ]; then
		sed -i /"custom_random_id"/d "DEPLOYER/$DEPLOYER_FOLDERNAME/$deployerTFvarsFile"
		git add -f "DEPLOYER/$DEPLOYER_FOLDERNAME/$deployerTFvarsFile"
		changed=1
	fi

	if [ -f "DEPLOYER/$DEPLOYER_FOLDERNAME/.terraform/terraform.tfstate" ]; then
		git rm -q -f --ignore-unmatch "DEPLOYER/$DEPLOYER_FOLDERNAME/.terraform/terraform.tfstate"
		changed=1
	fi

	if [ -d "DEPLOYER/$DEPLOYER_FOLDERNAME/.terraform" ]; then
		git rm -q -r --ignore-unmatch "DEPLOYER/$DEPLOYER_FOLDERNAME/.terraform"
		changed=1
	fi

	if [ -f "DEPLOYER/$DEPLOYER_FOLDERNAME/state.zip" ]; then
		git rm -q -f --ignore-unmatch "DEPLOYER/$DEPLOYER_FOLDERNAME/state.zip"
		changed=1
	fi

	environment=$(echo "$CONTROL_PLANE_NAME" | cut -d"-" -f1)
	region_code=$(echo "$CONTROL_PLANE_NAME" | cut -d"-" -f2)

	if [ -f ".sap_deployment_automation/${environment}${region_code}" ]; then
		rm ".sap_deployment_automation/${environment}${region_code}"
		git rm -q --ignore-unmatch ".sap_deployment_automation/${environment}${region_code}"
		changed=1
	fi

	if [ -f ".sap_deployment_automation/${CONTROL_PLANE_NAME}" ]; then
		rm ".sap_deployment_automation/${CONTROL_PLANE_NAME}"
		git rm -q --ignore-unmatch ".sap_deployment_automation/${CONTROL_PLANE_NAME}"
		changed=1
	fi

	if [ -f ".sap_deployment_automation/${CONTROL_PLANE_NAME}.md" ]; then
		rm ".sap_deployment_automation/${CONTROL_PLANE_NAME}.md"
		git rm -q --ignore-unmatch ".sap_deployment_automation/${CONTROL_PLANE_NAME}.md"
		changed=1
	fi

	if [ 1 == $changed ]; then
		git config --global user.email "$BUILD_REQUESTEDFOREMAIL"
		git config --global user.name "$BUILD_REQUESTEDFOR"
		if git commit -m "Control Plane $DEPLOYER_FOLDERNAME removal step 2[skip ci]"; then
			if git -c http.extraheader="AUTHORIZATION: bearer $SYSTEM_ACCESSTOKEN" push --set-upstream origin "$BUILD_SOURCEBRANCHNAME" --force-with-lease; then
				return_code=$?
				echo "##vso[task.logissue type=warning]Control Plane $DEPLOYER_FOLDERNAME removal step 2 updated in $BUILD_SOURCEBRANCHNAME"
			else
				return_code=$?
				echo "##vso[task.logissue type=error]Failed to push changes to $BUILD_SOURCEBRANCHNAME"
			fi
		fi
	fi
	echo -e "$green--- Deleting variables ---$reset"
	if [ -n "$VARIABLE_GROUP_ID" ]; then
		echo "Deleting variables"

		remove_variable "$VARIABLE_GROUP_ID" "APPLICATION_CONFIGURATION_ID"
		remove_variable "$VARIABLE_GROUP_ID" "HAS_APPSERVICE_DEPLOYED"
		remove_variable "$VARIABLE_GROUP_ID" "APPSERVICE_NAME"
		remove_variable "$VARIABLE_GROUP_ID" "Terraform_Remote_Storage_Account_Name"
		remove_variable "$VARIABLE_GROUP_ID" "Terraform_Remote_Storage_Resource_Group_Name"
		remove_variable "$VARIABLE_GROUP_ID" "Terraform_Remote_Storage_Subscription"
		remove_variable "$VARIABLE_GROUP_ID" "Deployer_State_FileName"
		remove_variable "$VARIABLE_GROUP_ID" "Deployer_Key_Vault"
		remove_variable "$VARIABLE_GROUP_ID" "WEBAPP_URL_BASE"
		remove_variable "$VARIABLE_GROUP_ID" "WEBAPP_IDENTITY"
		remove_variable "$VARIABLE_GROUP_ID" "WEBAPP_ID"
		remove_variable "$VARIABLE_GROUP_ID" "WEBAPP_RESOURCE_GROUP"
		remove_variable "$VARIABLE_GROUP_ID" "INSTALLATION_MEDIA_ACCOUNT"
		remove_variable "$VARIABLE_GROUP_ID" "DEPLOYER_RANDOM_ID"
		remove_variable "$VARIABLE_GROUP_ID" "LIBRARY_RANDOM_ID"

	fi

fi

exit $return_code
