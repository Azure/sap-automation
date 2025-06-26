#!/bin/bash
# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

echo "##vso[build.updatebuildnumber]Deploying the control plane defined in $DEPLOYER_FOLDERNAME $LIBRARY_FOLDERNAME"
green="\e[1;32m"
reset="\e[0m"
bold_red="\e[1;31m"
cyan="\e[1;36m"

#External helper functions
full_script_path="$(realpath "${BASH_SOURCE[0]}")"
script_directory="$(dirname "${full_script_path}")"
parent_directory="$(dirname "$script_directory")"
grand_parent_directory="$(dirname "$parent_directory")"

#call stack has full script name when using source
source "${parent_directory}/helper.sh"
source "${grand_parent_directory}/deploy_utils.sh"

DEBUG=false
if [ "$SYSTEM_DEBUG" = True ]; then
	set -x
	DEBUG=true
	echo "Environment variables:"
	printenv | sort
fi

export DEBUG
set -eu

# Print the execution environment details
print_header
echo ""

# Configure DevOps
configure_devops

if ! get_variable_group_id "$VARIABLE_GROUP" "VARIABLE_GROUP_ID"; then
	echo -e "$bold_red--- Variable group $VARIABLE_GROUP not found ---$reset"
	echo "##vso[task.logissue type=error]Variable group $VARIABLE_GROUP not found."
	exit 2
fi
export VARIABLE_GROUP_ID

file_deployer_tfstate_key=$DEPLOYER_FOLDERNAME.tfstate
deployer_tfstate_key="$DEPLOYER_FOLDERNAME.terraform.tfstate"

if [ -z "${TF_VAR_ansible_core_version}" ]; then
	TF_VAR_ansible_core_version=2.16
	export TF_VAR_ansible_core_version
fi

cd "$CONFIG_REPO_PATH" || exit
mkdir -p .sap_deployment_automation

ENVIRONMENT=$(echo "$DEPLOYER_FOLDERNAME" | awk -F'-' '{print $1}' | xargs)
LOCATION=$(echo "$DEPLOYER_FOLDERNAME" | awk -F'-' '{print $2}' | xargs)
CONTROL_PLANE_NAME=$(basename "${DEPLOYER_FOLDERNAME}" | cut -d'-' -f1-3)

deployer_environment_file_name="$CONFIG_REPO_PATH/.sap_deployment_automation/${CONTROL_PLANE_NAME}"
deployer_tfvars_file_name="${CONFIG_REPO_PATH}/DEPLOYER/$DEPLOYER_FOLDERNAME/$DEPLOYER_TFVARS_FILENAME"
library_tfvars_file_name="${CONFIG_REPO_PATH}/LIBRARY/$LIBRARY_FOLDERNAME/$LIBRARY_TFVARS_FILENAME"

if [ ! -f "$deployer_tfvars_file_name" ]; then
	echo -e "$bold_red--- File $deployer_tfvars_file_name was not found ---$reset"
	echo "##vso[task.logissue type=error]File DEPLOYER/$DEPLOYER_FOLDERNAME/$DEPLOYER_TFVARS_FILENAME was not found."
	exit 2
fi

if [ ! -f "$library_tfvars_file_name" ]; then
	echo -e "$bold_red--- File $library_tfvars_file_name  was not found ---$reset"
	echo "##vso[task.logissue type=error]File LIBRARY/$LIBRARY_FOLDERNAME/$LIBRARY_TFVARS_FILENAME was not found."
	exit 2
fi

echo "Configuration file:                  $deployer_environment_file_name"
echo "Environment:                         $ENVIRONMENT"
echo "Location:                            $LOCATION"

if [ "$FORCE_RESET" == "True" ]; then
	echo "##vso[task.logissue type=warning]Forcing a re-install"
	echo -e "$bold_red--- Resetting the environment file ---$reset"
	step=0
else
	if [ -f "${deployer_environment_file_name}" ]; then
		step=$(grep -m1 "^step=" "${deployer_environment_file_name}" | awk -F'=' '{print $2}' | xargs)
	else
		step=0
	fi
fi

echo "Step:                                $step"

if [ 0 != "${step}" ]; then
	echo "##vso[task.logissue type=warning]Already prepared"
	exit 0
fi

git checkout -q "$BUILD_SOURCEBRANCHNAME"

az account set --subscription "$ARM_SUBSCRIPTION_ID"
echo "Deployer subscription:               $ARM_SUBSCRIPTION_ID"

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

TF_VAR_spn_id=$(getVariableFromVariableGroup "${VARIABLE_GROUP_ID}" "ARM_OBJECT_ID" "${deployer_environment_file_name}" "ARM_OBJECT_ID")
if [ -n "$TF_VAR_spn_id" ]; then

	if is_valid_guid $TF_VAR_spn_id; then
		export TF_VAR_spn_id
		echo "Service Principal Object id:         $TF_VAR_spn_id"
	fi
fi
# Reset the account if sourcing was done
if printenv ARM_SUBSCRIPTION_ID; then
	az account set --subscription "$ARM_SUBSCRIPTION_ID"
	echo "Deployer subscription:               $ARM_SUBSCRIPTION_ID"
fi

echo -e "$green--- Convert config files to UX format ---$reset"
dos2unix -q "$deployer_tfvars_file_name"
dos2unix -q "$library_tfvars_file_name"

if is_valid_id "$APPLICATION_CONFIGURATION_ID" "/providers/Microsoft.AppConfiguration/configurationStores/"; then

	TF_VAR_management_subscription_id=$(getVariableFromApplicationConfiguration "$APPLICATION_CONFIGURATION_ID" "${CONTROL_PLANE_NAME}_SubscriptionId" "${CONTROL_PLANE_NAME}")
	export TF_VAR_management_subscription_id

fi

if [ "$FORCE_RESET" == True ]; then
	echo "##vso[task.logissue type=warning]Forcing a re-install"
	echo "Running on:            $THIS_AGENT"
	sed -i 's/step=1/step=0/' "$deployer_environment_file_name"
	sed -i 's/step=2/step=0/' "$deployer_environment_file_name"
	sed -i 's/step=3/step=0/' "$deployer_environment_file_name"

	tfstate_resource_id=$(getVariableFromApplicationConfiguration "$APPLICATION_CONFIGURATION_ID" "${CONTROL_PLANE_NAME}_TerraformRemoteStateStorageAccountId" "${CONTROL_PLANE_NAME}")
	if [ -z "$tfstate_resource_id" ]; then
		echo "##vso[task.logissue type=warning]Key '${CONTROL_PLANE_NAME}_TerraformRemoteStateStorageAccountId' was not found in the application configuration ( '$application_configuration_name' )."
	fi

	TERRAFORM_REMOTE_STORAGE_ACCOUNT_NAME=$(echo "$tfstate_resource_id" | cut -d'/' -f9)
	TERRAFORM_REMOTE_STORAGE_RESOURCE_GROUP_NAME=$(echo "$tfstate_resource_id" | cut -d'/' -f5)

	if [ -n "${TERRAFORM_REMOTE_STORAGE_ACCOUNT_NAME}" ]; then
		echo "Terraform Remote State Account:      ${TERRAFORM_REMOTE_STORAGE_ACCOUNT_NAME}"
	fi

	if [ -n "${TERRAFORM_REMOTE_STORAGE_RESOURCE_GROUP_NAME}" ]; then
		echo "Terraform Remote State RG Name:      ${TERRAFORM_REMOTE_STORAGE_RESOURCE_GROUP_NAME}"
	fi

	if [ -n "${tfstate_resource_id}" ]; then
		this_ip=$(curl -s ipinfo.io/ip) >/dev/null 2>&1
		az storage account network-rule add --account-name "$TERRAFORM_REMOTE_STORAGE_ACCOUNT_NAME" --resource-group "$TERRAFORM_REMOTE_STORAGE_RESOURCE_GROUP_NAME" --ip-address "${this_ip}" --only-show-errors --output none
	fi

	REINSTALL_ACCOUNTNAME=$TERRAFORM_REMOTE_STORAGE_ACCOUNT_NAME
	export REINSTALL_ACCOUNTNAME
	REINSTALL_SUBSCRIPTION=$ARM_SUBSCRIPTION_ID
	export REINSTALL_SUBSCRIPTION
	REINSTALL_RESOURCE_GROUP=$TERRAFORM_REMOTE_STORAGE_RESOURCE_GROUP_NAME
	export REINSTALL_RESOURCE_GROUP

fi

echo -e "$green--- Variables ---$reset"

if [ -f "${CONFIG_REPO_PATH}/DEPLOYER/$DEPLOYER_FOLDERNAME/state.zip" ]; then
	# shellcheck disable=SC2001
	# shellcheck disable=SC2005
	pass=${SYSTEM_COLLECTIONID//-/}
	echo "Unzipping state.zip"
	unzip -qq -o -P "${pass}" "${CONFIG_REPO_PATH}/DEPLOYER/$DEPLOYER_FOLDERNAME/state.zip" -d "${CONFIG_REPO_PATH}/DEPLOYER/$DEPLOYER_FOLDERNAME"
fi

export TF_LOG_PATH=$CONFIG_REPO_PATH/.sap_deployment_automation/terraform.log
set +eu

msi_flag=""
if [ "${USE_MSI:-false}" == "true" ]; then
	msi_flag=" --msi "
	TF_VAR_use_spn=false
	export TF_VAR_use_spn
	echo "Deployer using:                      Managed Identity"

else
	TF_VAR_use_spn=true
	export TF_VAR_use_spn
	echo "Deployer using:                      Service Principal"
fi

if [ "$DEBUG" == True ]; then
	echo "ARM Environment variables:"
	printenv | grep ARM_
fi
echo -e "$green--- Control Plane deployment---$reset"

if "${SAP_AUTOMATION_REPO_PATH}/deploy/scripts/deploy_control_plane_v2.sh" --deployer_parameter_file "${deployer_tfvars_file_name}" \
	--library_parameter_file "${library_tfvars_file_name}" \
	--subscription "$ARM_SUBSCRIPTION_ID" \
	--auto-approve --ado "$msi_flag" --only_deployer; then
	return_code=$?
	echo "##vso[task.logissue type=warning]Return code from deploy_control_plane_v2 $return_code."
	echo "Return code from deploy_control_plane_v2 $return_code."
else
	return_code=$?
	echo "##vso[task.logissue type=error]Return code from deploy_control_plane_v2 $return_code."
	echo "Return code from deploy_control_plane_v2 $return_code."
fi
echo ""
echo -e "${cyan}deploy_control_plane_v2 returned:        $return_code${reset}"
echo ""

set -eu

if [ -f "${deployer_environment_file_name}" ]; then

	file_deployer_tfstate_key=$(grep -m1 "^deployer_tfstate_key" "${deployer_environment_file_name}" | awk -F'=' '{print $2}' | xargs || true)
	if [ -z "$file_deployer_tfstate_key" ]; then
		deployer_tfstate_key=$file_deployer_tfstate_key
		export deployer_tfstate_key
	fi
	echo "Deployer State File:                 $deployer_tfstate_key"

	file_key_vault=$(grep -m1 "^keyvault=" "${deployer_environment_file_name}" | awk -F'=' '{print $2}' | xargs || true)
	echo "Deployer Key Vault:                  ${file_key_vault}"

	file_REMOTE_STATE_SA=$(grep -m1 "^REMOTE_STATE_SA" "${deployer_environment_file_name}" | awk -F'=' '{print $2}' | xargs || true)
	if [ -n "${file_REMOTE_STATE_SA}" ]; then
		echo "Terraform Remote State Account:       ${file_REMOTE_STATE_SA}"
	fi

	file_REMOTE_STATE_RG=$(grep -m1 "^REMOTE_STATE_RG" "${deployer_environment_file_name}" | awk -F'=' '{print $2}' | xargs || true)
	if [ -n "${file_REMOTE_STATE_SA}" ]; then
		echo "Terraform Remote State RG Name:       ${file_REMOTE_STATE_RG}"
	fi
fi
echo -e "$green--- Adding deployment automation configuration to devops repository ---$reset"
added=0
cd "$CONFIG_REPO_PATH" || exit

# Pull changes
git pull -q origin "$BUILD_SOURCEBRANCHNAME"

echo -e "$green--- Update repo ---$reset"

if [ -f ".sap_deployment_automation/${CONTROL_PLANE_NAME}" ]; then
	git add ".sap_deployment_automation/${CONTROL_PLANE_NAME}"
	added=1
fi

if [ -f "DEPLOYER/$DEPLOYER_FOLDERNAME/deployer_tfvars_file_name" ]; then
	git add -f "DEPLOYER/$DEPLOYER_FOLDERNAME/deployer_tfvars_file_name"
	added=1
fi

if [ -f "DEPLOYER/$DEPLOYER_FOLDERNAME/.terraform/terraform.tfstate" ]; then
	git add -f "DEPLOYER/$DEPLOYER_FOLDERNAME/.terraform/terraform.tfstate"
	added=1
fi

if [ -f "DEPLOYER/$DEPLOYER_FOLDERNAME/terraform.tfstate" ]; then
	sudo apt-get install zip -y
	pass=${SYSTEM_COLLECTIONID//-/}
	zip -q -j -P "${pass}" "DEPLOYER/$DEPLOYER_FOLDERNAME/state" "DEPLOYER/$DEPLOYER_FOLDERNAME/terraform.tfstate"
	git add -f "DEPLOYER/$DEPLOYER_FOLDERNAME/state.zip"
	added=1
fi

if [ 1 = $added ]; then
	git config --global user.email "$BUILD_REQUESTEDFOREMAIL"
	git config --global user.name "$BUILD_REQUESTEDFOR"
	git commit -m "Added updates from Control Plane Deployment for $DEPLOYER_FOLDERNAME $LIBRARY_FOLDERNAME $BUILD_BUILDNUMBER [skip ci]"
	if ! git -c http.extraheader="AUTHORIZATION: bearer $SYSTEM_ACCESSTOKEN" push --set-upstream origin "$BUILD_SOURCEBRANCHNAME" --force-with-lease; then
		echo "##vso[task.logissue type=error]Failed to push changes to the repository."
	fi
fi

if [ -f "$CONFIG_REPO_PATH/.sap_deployment_automation/${ENVIRONMENT}${LOCATION}.md" ]; then
	echo "##vso[task.uploadsummary]$CONFIG_REPO_PATH/.sap_deployment_automation/${ENVIRONMENT}${LOCATION}.md"
fi
echo -e "$green--- Adding variables to the variable group: $VARIABLE_GROUP ---$reset"
if [ 0 = $return_code ]; then
	saveVariableInVariableGroup "${VARIABLE_GROUP_ID}" "APPLICATION_CONFIGURATION_NAME" "$APPLICATION_CONFIGURATION_NAME"
	saveVariableInVariableGroup "${VARIABLE_GROUP_ID}" "CONTROL_PLANE_NAME" "$CONTROL_PLANE_NAME"
	saveVariableInVariableGroup "${VARIABLE_GROUP_ID}" "DEPLOYER_KEYVAULT" "$DEPLOYER_KEYVAULT"
fi
exit $return_code
