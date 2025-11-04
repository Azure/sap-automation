#!/bin/bash
# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

green="\e[1;32m"
reset="\e[0m"
bold_red="\e[1;31m"

# External helper functions
#. "$(dirname "${BASH_SOURCE[0]}")/deploy_utils.sh"
full_script_path="$(realpath "${BASH_SOURCE[0]}")"
script_directory="$(dirname "${full_script_path}")"
parent_directory="$(dirname "$script_directory")"
grand_parent_directory="$(dirname "$parent_directory")"

SCRIPT_NAME="$(basename "$0")"
banner_title="Prepare Control Plane"

#call stack has full script name when using source
# shellcheck disable=SC1091
source "${grand_parent_directory}/deploy_utils.sh"

#call stack has full script name when using source
source "${parent_directory}/helper.sh"

echo "##vso[build.updatebuildnumber]Setting the deployment credentials for the SAP Workload zone defined in $ZONE"
print_banner "$banner_title" "Starting $SCRIPT_NAME" "info"

DEBUG=False

if [ "$SYSTEM_DEBUG" = True ]; then
	set -x
	DEBUG=True
	echo "Environment variables:"
	printenv | sort

fi
export DEBUG
set -eu

# Print the execution environment details
print_header

# Configure DevOps
configure_devops

# Check if running on deployer
if [[ ! -f /etc/profile.d/deploy_server.sh ]]; then
	configureNonDeployer "${tf_version:-1.13.3}"
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

if [ -v servicePrincipalId ]; then
	ARM_CLIENT_ID="$servicePrincipalId"
	export ARM_CLIENT_ID
	TF_VAR_spn_id=$ARM_CLIENT_ID
	export TF_VAR_spn_id
fi

if [ -v servicePrincipalKey ]; then
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

if [ -v tenantId ]; then
	ARM_TENANT_ID="$tenantId"
	export ARM_TENANT_ID
fi

if az account show --query name; then
	echo -e "$green--- Already logged in to Azure ---$reset"
	az account show --query user --output yaml
else

	LogonToAzure $USE_MSI
	return_code=$?
	if [ 0 != $return_code ]; then
		echo -e "$bold_red--- Login failed ---$reset"
		echo "##vso[task.logissue type=error]az login failed."
		exit $return_code
	fi
fi

variableGroupName="$VARIABLE_GROUP_CONTROL_PLANE"

if ! get_variable_group_id "$variableGroupName" "VARIABLE_GROUP_ID"; then
	echo -e "$cyan--- Variable group $variableGroupName not found ---$reset"
	variableGroupName="$VARIABLE_GROUP"

	if ! get_variable_group_id "$variableGroupName" "VARIABLE_GROUP_ID"; then
		echo -e "$bold_red--- Variable group $variableGroupName not found ---$reset"
		echo "##vso[task.logissue type=error]Variable group $variableGroupName not found."
		exit 2
	fi
fi
export VARIABLE_GROUP_ID

# file_deployer_tfstate_key=$DEPLOYER_FOLDERNAME.tfstate
# deployer_tfstate_key="$DEPLOYER_FOLDERNAME.terraform.tfstate"

if [ -z "${TF_VAR_ansible_core_version}" ]; then
	TF_VAR_ansible_core_version=2.16
	export TF_VAR_ansible_core_version
fi

cd "$CONFIG_REPO_PATH" || exit
mkdir -p .sap_deployment_automation

ENVIRONMENT=$(echo "$DEPLOYER_FOLDERNAME" | awk -F'-' '{print $1}' | xargs)
LOCATION=$(echo "$DEPLOYER_FOLDERNAME" | awk -F'-' '{print $2}' | xargs)
NETWORK=$(echo "$DEPLOYER_FOLDERNAME" | awk -F'-' '{print $3}' | xargs)
CONTROL_PLANE_NAME=$(basename "${DEPLOYER_FOLDERNAME}" | cut -d'-' -f1-3)

automation_config_directory="$CONFIG_REPO_PATH/.sap_deployment_automation/"
deployer_environment_file_name=$(get_configuration_file "${automation_config_directory}" "${ENVIRONMENT}" "${LOCATION}" "${NETWORK}")
SYSTEM_CONFIGURATION_FILE="$deployer_environment_file_name"
export SYSTEM_CONFIGURATION_FILE

deployer_tfvars_file_name="${CONFIG_REPO_PATH}/DEPLOYER/$DEPLOYER_FOLDERNAME/$DEPLOYER_FOLDERNAME.tfvars"
library_tfvars_file_name="${CONFIG_REPO_PATH}/LIBRARY/$LIBRARY_FOLDERNAME/$LIBRARY_FOLDERNAME.tfvars"

if [ ! -f "$deployer_tfvars_file_name" ]; then
	echo -e "$bold_red--- File $deployer_tfvars_file_name was not found ---$reset"
	echo "##vso[task.logissue type=error]File DEPLOYER/$DEPLOYER_FOLDERNAME/$DEPLOYER_FOLDERNAME.tfvars was not found."
	exit 2
fi

if [ ! -f "$library_tfvars_file_name" ]; then
	echo -e "$bold_red--- File $library_tfvars_file_name  was not found ---$reset"
	echo "##vso[task.logissue type=error]File LIBRARY/$LIBRARY_FOLDERNAME/$LIBRARY_FOLDERNAME.tfvars was not found."
	exit 2
fi

if [ ! -f "${deployer_environment_file_name}" ]; then
	if [ -f ".sap_deployment_automation/${ENVIRONMENT}${LOCATION}" ]; then
		cp ".sap_deployment_automation/${ENVIRONMENT}${LOCATION}" ".sap_deployment_automation/${CONTROL_PLANE_NAME}"
	fi
fi
echo ""
echo -e "${green}Parameter information:"
echo -e "-------------------------------------------------------------------------------$reset"

echo "Control Plane Name:                  $CONTROL_PLANE_NAME"
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

echo "Deployer subscription:               $ARM_SUBSCRIPTION_ID"

TF_VAR_spn_id=$(getVariableFromVariableGroup "${VARIABLE_GROUP_ID}" "ARM_OBJECT_ID" "${deployer_environment_file_name}" "ARM_OBJECT_ID")
if [ -n "$TF_VAR_spn_id" ]; then
	if is_valid_guid "$TF_VAR_spn_id"; then
		export TF_VAR_spn_id
		echo "Service Principal Object id:         $TF_VAR_spn_id"
	fi
fi

# Reset the account if sourcing was done
if printenv ARM_SUBSCRIPTION_ID; then
	az account set --subscription "$ARM_SUBSCRIPTION_ID"
	echo "Deployer subscription:               $ARM_SUBSCRIPTION_ID"
	TF_subscription_id="$ARM_SUBSCRIPTION_ID"
	export TF_subscription_id

fi

# echo -e "$green--- Convert config files to UX format ---$reset"
# dos2unix -q "$deployer_tfvars_file_name"
# dos2unix -q "$library_tfvars_file_name"

DEPLOYER_KEYVAULT=$(getVariableFromVariableGroup "${VARIABLE_GROUP_ID}" "DEPLOYER_KEYVAULT" "${deployer_environment_file_name}" "DEPLOYER_KEYVAULT")
if [ -n "$DEPLOYER_KEYVAULT" ]; then
	echo "Deployer Key Vault:                  ${DEPLOYER_KEYVAULT}"
	key_vault_id=$(az resource list --name "${DEPLOYER_KEYVAULT}" --resource-type Microsoft.KeyVault/vaults --query "[].id | [0]" --subscription "$ARM_SUBSCRIPTION_ID" --output tsv)

	if [ -z "${DEPLOYER_KEYVAULT}" ]; then
		echo "##vso[task.logissue type=error]Key Vault $DEPLOYER_KEYVAULT could not be found, trying to recover"
		DEPLOYER_KEYVAULT=$(az keyvault list-deleted --query "[?name=='${DEPLOYER_KEYVAULT}'].name | [0]" --subscription "$ARM_SUBSCRIPTION_ID" --output tsv)
		if [ -n "$DEPLOYER_KEYVAULT" ]; then
			echo "Deployer Key Vault:                  ${DEPLOYER_KEYVAULT} is deleted, recovering"
			az keyvault recover --name "${DEPLOYER_KEYVAULT}" --subscription "$ARM_SUBSCRIPTION_ID" --output none
			key_vault_id=$(az resource list --name "${DEPLOYER_KEYVAULT}" --resource-type Microsoft.KeyVault/vaults --query "[].id | [0]" --subscription "$ARM_SUBSCRIPTION_ID" --output tsv)
			if [ -n "${key_vault_id}" ]; then
				export TF_VAR_deployer_kv_user_arm_id=${key_vault_id}
				this_ip=$(curl -s ipinfo.io/ip) >/dev/null 2>&1
				az keyvault network-rule add --name "${DEPLOYER_KEYVAULT}" --ip-address "${this_ip}" --subscription "$ARM_SUBSCRIPTION_ID" --only-show-errors --output none
			fi
		fi
	else
		export TF_VAR_deployer_kv_user_arm_id=${key_vault_id}
		this_ip=$(curl -s ipinfo.io/ip) >/dev/null 2>&1
		az keyvault network-rule add --name "${DEPLOYER_KEYVAULT}" --ip-address "${this_ip}" --subscription "$ARM_SUBSCRIPTION_ID" --only-show-errors --output none

	fi
else
	echo "Deployer Key Vault:                  undefined"
fi

if [ "$FORCE_RESET" == True ]; then
	echo "##vso[task.logissue type=warning]Forcing a re-install"
	echo "Running on:            $THIS_AGENT"
	sed -i 's/step=1/step=0/' "$deployer_environment_file_name"
	sed -i 's/step=2/step=0/' "$deployer_environment_file_name"
	sed -i 's/step=3/step=0/' "$deployer_environment_file_name"

	TERRAFORM_REMOTE_STORAGE_ACCOUNT_NAME=$(getVariableFromVariableGroup "${VARIABLE_GROUP_ID}" "TERRAFORM_REMOTE_STORAGE_ACCOUNT_NAME" "${deployer_environment_file_name}" "REMOTE_STATE_SA")
	TERRAFORM_REMOTE_STORAGE_RESOURCE_GROUP_NAME=$(getVariableFromVariableGroup "${VARIABLE_GROUP_ID}" "TERRAFORM_REMOTE_STORAGE_RESOURCE_GROUP_NAME" "${deployer_environment_file_name}" "REMOTE_STATE_RG")

	if [ -n "${TERRAFORM_REMOTE_STORAGE_ACCOUNT_NAME}" ]; then
		echo "Terraform Remote State Account:      ${TERRAFORM_REMOTE_STORAGE_ACCOUNT_NAME}"
	fi

	if [ -n "${TERRAFORM_REMOTE_STORAGE_RESOURCE_GROUP_NAME}" ]; then
		echo "Terraform Remote State RG Name:      ${TERRAFORM_REMOTE_STORAGE_RESOURCE_GROUP_NAME}"
	fi

	if [ -n "${TERRAFORM_REMOTE_STORAGE_ACCOUNT_NAME}" ] && [ -n "${TERRAFORM_REMOTE_STORAGE_RESOURCE_GROUP_NAME}" ]; then
		tfstate_resource_id=$(az resource list --name "$TERRAFORM_REMOTE_STORAGE_ACCOUNT_NAME" --subscription "$ARM_SUBSCRIPTION_ID" --resource-type Microsoft.Storage/storageAccounts --query "[].id | [0]" -o tsv)
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
if [ "$USE_MSI" == "true" ]; then
	msi_flag=" --msi "
	TF_VAR_use_spn=false
	export TF_VAR_use_spn
	echo "Deployer using:                      Managed Identity"

else
	TF_VAR_use_spn=true
	export TF_VAR_use_spn
	echo "Deployer using:                      Service Principal"
fi

cd "${CONFIG_REPO_PATH}/DEPLOYER/$DEPLOYER_FOLDERNAME" || exit
echo "Current directory:                $(pwd)"

if "${SAP_AUTOMATION_REPO_PATH}/deploy/scripts/install_deployer.sh" --parameterfile "${DEPLOYER_FOLDERNAME}.tfvars" --auto-approve; then
	return_code=$?
	echo "##vso[task.logissue type=warning]Return code from install_deployer.sh $return_code."
	step=1
	save_config_var "step" "${deployer_environment_file_name}"
else
	return_code=$?
	echo "##vso[task.logissue type=error]Return code from install_deployer.sh $return_code."
	step=0
	save_config_var "step" "${deployer_environment_file_name}"

fi

set -eu

if [ -f "${deployer_environment_file_name}" ]; then

	# check if DEPLOYER_KEYVAULT is already available as an export
	if checkforEnvVar "DEPLOYER_KEYVAULT"; then
		echo "Deployer Key Vault:                  ${DEPLOYER_KEYVAULT}"
	else
		# if not, try to read it from the environment file
		DEPLOYER_KEYVAULT=$(grep -m1 "^DEPLOYER_KEYVAULT=" "${deployer_environment_file_name}" | awk -F'=' '{print $2}' | xargs || true)
		# if the variable is not set, fallback to old variable name
		if [ -z "${DEPLOYER_KEYVAULT}" ]; then
			DEPLOYER_KEYVAULT=$(grep -m1 "^keyvault=" "${deployer_environment_file_name}" | awk -F'=' '{print $2}' | xargs || true)
		fi
		echo "Deployer Key Vault:                  ${DEPLOYER_KEYVAULT}"
	fi

	# if DEPLOYER_KEYVAULT is still not set, exit with an error
	if [ -z "${DEPLOYER_KEYVAULT}" ]; then
		echo "##vso[task.logissue type=error]Deployer Key Vault is not defined in the environment file."
		exit 1
	fi

	echo -e "$green--- Adding variables to the variable group: $VARIABLE_GROUP ---$reset"
	if [ -n "$DEPLOYER_KEYVAULT" ]; then
		if saveVariableInVariableGroup "${VARIABLE_GROUP_ID}" "DEPLOYER_KEYVAULT" "$DEPLOYER_KEYVAULT"; then
			echo "Saved DEPLOYER_KEYVAULT in variable group."
		else
			echo "##vso[task.logissue type=warning]Failed to save DEPLOYER_KEYVAULT in variable group."
		fi
	fi

fi
echo -e "$green--- Adding deployment automation configuration to devops repository ---$reset"
added=0
cd "$CONFIG_REPO_PATH" || exit

# Pull changes
git pull -q origin "$BUILD_SOURCEBRANCHNAME"

echo -e "$green--- Update repo ---$reset"

if [ -f "${deployer_environment_file_name}" ]; then
	git add "${deployer_environment_file_name}"
	added=1
fi

if [ -f ".sap_deployment_automation/${ENVIRONMENT}${LOCATION}" ]; then
	git add ".sap_deployment_automation/${ENVIRONMENT}${LOCATION}"
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
	if git commit -m "Added updates from Control Plane Deployment for $DEPLOYER_FOLDERNAME $LIBRARY_FOLDERNAME $BUILD_BUILDNUMBER [skip ci]"; then
		if ! git -c http.extraheader="AUTHORIZATION: bearer $SYSTEM_ACCESSTOKEN" push --set-upstream origin "$BUILD_SOURCEBRANCHNAME" --force-with-lease; then
			echo "##vso[task.logissue type=error]Failed to push changes to the repository."
		fi
	fi
fi

if [ -f "$CONFIG_REPO_PATH/.sap_deployment_automation/${ENVIRONMENT}${LOCATION}.md" ]; then
	echo "##vso[task.uploadsummary]$CONFIG_REPO_PATH/.sap_deployment_automation/${ENVIRONMENT}${LOCATION}.md"
fi
exit $return_code
