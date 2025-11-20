#!/bin/bash
# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

#External helper functions
full_script_path="$(realpath "${BASH_SOURCE[0]}")"
script_directory="$(dirname "${full_script_path}")"
parent_directory="$(dirname "$script_directory")"
grand_parent_directory="$(dirname "$parent_directory")"

# Source the shared platform configuration
source "${script_directory}/shared_platform_config.sh"
source "${script_directory}/shared_functions.sh"
source "${script_directory}/set-colors.sh"
source "${grand_parent_directory}/deploy_utils.sh"

source "${parent_directory}/helper.sh"

# Set platform-specific output
if [ "$PLATFORM" == "devops" ]; then
	echo "##vso[build.updatebuildnumber]Deploying the control plane defined in ${DEPLOYER_FOLDERNAME}"
	DEBUG=false
	if [ "${SYSTEM_DEBUG:-False}" == True ]; then
		set -x
		DEBUG=true
		echo "Environment variables:"
		printenv | sort
	fi
fi

export DEBUG
set -eu

# Print the execution environment details
print_header
echo ""

ENVIRONMENT=$(echo "${CONTROL_PLANE_NAME}" | awk -F'-' '{print $1}' | xargs)
LOCATION=$(echo "${CONTROL_PLANE_NAME}" | awk -F'-' '{print $2}' | xargs)
NETWORK=$(echo "${CONTROL_PLANE_NAME}" | awk -F'-' '{print $3}' | xargs)

if [ "$PLATFORM" == "github" ]; then
	DEPLOYER_FOLDERNAME="${CONTROL_PLANE_NAME}-INFRASTRUCTURE"
	DEPLOYER_TFVARS_FILENAME="${CONTROL_PLANE_NAME}-INFRASTRUCTURE.tfvars"
	LIBRARY_FOLDERNAME="${ENVIRONMENT}-${LOCATION}-SAP_LIBRARY"
	LIBRARY_TFVARS_FILENAME="${ENVIRONMENT}-${LOCATION}-SAP_LIBRARY.tfvars"
fi

automation_config_directory="${CONFIG_REPO_PATH}/.sap_deployment_automation"

deployer_environment_file_name=$(get_configuration_file "$automation_config_directory" "$ENVIRONMENT" "$LOCATION" "$NETWORK")

deployer_tfvars_file_name="${CONFIG_REPO_PATH}/DEPLOYER/$DEPLOYER_FOLDERNAME/$DEPLOYER_FOLDERNAME.tfvars"
library_tfvars_file_name="${CONFIG_REPO_PATH}/LIBRARY/$LIBRARY_FOLDERNAME/$LIBRARY_FOLDERNAME.tfvars"

if [ ! -f "$deployer_tfvars_file_name" ]; then
	echo -e "$bold_red--- File $deployer_tfvars_file_name was not found ---$reset"
	if [ "$PLATFORM" == "devops" ]; then
		echo "##vso[task.logissue type=error]File {$deployer_tfvars_file_name} was not found."
	fi
	exit 2

fi

if [ ! -f "$library_tfvars_file_name" ]; then
	echo -e "$bold_red--- File $library_tfvars_file_name  was not found ---$reset"
	if [ "$PLATFORM" == "devops" ]; then
		echo "##vso[task.logissue type=error]File LIBRARY/$LIBRARY_FOLDERNAME/$LIBRARY_TFVARS_FILENAME was not found."
	fi
	exit 2

fi

# Platform-specific configuration
if [ "$PLATFORM" == "devops" ]; then

	echo "##vso[build.updatebuildnumber]Deploying the control plane defined in $DEPLOYER_FOLDERNAME $LIBRARY_FOLDERNAME"

	# Configure DevOps
	configure_devops

	if ! get_variable_group_id "$VARIABLE_GROUP" "VARIABLE_GROUP_ID"; then
		echo -e "$bold_red--- Variable group $VARIABLE_GROUP not found ---$reset_formatting"
		echo "##vso[task.logissue type=error]Variable group $VARIABLE_GROUP not found."
		exit 2
	fi
	export VARIABLE_GROUP_ID

	TF_VAR_DevOpsInfrastructure_object_id=$(getVariableFromVariableGroup "${VARIABLE_GROUP_ID}" "DEVOPS_OBJECT_ID" "${deployer_environment_file_name}" "DevOpsInfrastructureObjectId")
	if [ -n "$TF_VAR_DevOpsInfrastructure_object_id" ]; then
		echo "DevOps Infrastructure Object ID:      ${TF_VAR_DevOpsInfrastructure_object_id}"
		export TF_VAR_DevOpsInfrastructure_object_id
	else
		echo "##vso[task.logissue type=warning]DevOps Infrastructure Object ID not found. Please ensure the DEVOPS_OBJECT_ID variable is defined, if managed devops pools are used."
	fi

elif [ "$PLATFORM" == "github" ]; then
	echo "Configuring for GitHub Actions"
	export VARIABLE_GROUP_ID="${CONTROL_PLANE_NAME}"
	git config --global --add safe.directory "$CONFIG_REPO_PATH"
fi

file_deployer_tfstate_key=$DEPLOYER_FOLDERNAME.tfstate
deployer_tfstate_key="$DEPLOYER_FOLDERNAME.terraform.tfstate"

if [ ! -v TF_VAR_ansible_core_version ]; then
	TF_VAR_ansible_core_version=2.16
	export TF_VAR_ansible_core_version
fi

cd "$CONFIG_REPO_PATH" || exit
mkdir -p .sap_deployment_automation

echo "Configuration file:                  $deployer_environment_file_name"
echo "Control Plane Name:                  $CONTROL_PLANE_NAME"
echo "Environment:                         $ENVIRONMENT"
echo "Location:                            $LOCATION"
echo "Deployer Folder Name:                $DEPLOYER_FOLDERNAME"
echo "Deployer TFVars Filename:            $DEPLOYER_FOLDERNAME.tfvars"
echo "Library Folder Name:                 $LIBRARY_FOLDERNAME"
echo "Library TFVars Filename:             $LIBRARY_FOLDERNAME.tfvars"
step=0
# Handle force reset across platforms
if [ "${FORCE_RESET:-false}" == "true" ] || [ "${FORCE_RESET:-False}" == "True" ]; then
	if [ "$PLATFORM" == "devops" ]; then
		echo "##vso[task.logissue type=warning]Forcing a re-install"
	fi
	echo -e "$bold_red--- Resetting the environment file ---$reset_formatting"
	step=0
else
	if [ -f "${deployer_environment_file_name}" ]; then
		step=$(grep -m1 "^step=" "${deployer_environment_file_name}" | awk -F'=' '{print $2}' | xargs || true)
	else
		step=0
	fi
fi

echo "Step:                                $step"

if [ 0 -ne ${step:-0} ]; then
	if [ "$PLATFORM" == "devops" ]; then
		echo "##vso[task.logissue type=warning]Already prepared"
	else
		echo "WARNING: Already prepared"
	fi
fi

# Git checkout for the correct branch
if [ "$PLATFORM" == "devops" ]; then
	git checkout -q "$BUILD_SOURCEBRANCHNAME"
elif [ "$PLATFORM" == "github" ]; then
	git checkout -q "$GITHUB_REF_NAME"
fi

# Set Azure subscription
az account set --subscription "$ARM_SUBSCRIPTION_ID"
echo "Deployer subscription:               $ARM_SUBSCRIPTION_ID"

# Check if running on deployer
if [[ ! -f /etc/profile.d/deploy_server.sh ]]; then
	configureNonDeployer "$TF_VERSION"

	ARM_CLIENT_ID="${servicePrincipalId:-$ARM_CLIENT_ID}"
	export ARM_CLIENT_ID
	TF_VAR_spn_id=$ARM_CLIENT_ID
	export TF_VAR_spn_id

	if [ "$PLATFORM" == "devops" ]; then
		# Azure DevOps specific authentication logic
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
	elif [ "$PLATFORM" == "github" ]; then
		# GitHub Actions uses standard ARM_CLIENT_SECRET
		echo "Using standard Azure authentication for GitHub Actions"
	fi
	ARM_TENANT_ID="${tenantId:-$ARM_TENANT_ID}"

	if [ -z "${ARM_TENANT_ID:-}" ]; then
		ARM_TENANT_ID=$(az account show --query tenantId -o tsv)
	fi
	export ARM_TENANT_ID

	ARM_USE_AZUREAD=true
	export ARM_USE_AZUREAD
else
	path=$(grep -m 1 "export PATH=" /etc/profile.d/deploy_server.sh | awk -F'=' '{print $2}' | xargs)
	export PATH=$PATH:$path
	if [ "${USE_MSI:-false}" == "true" ]; then
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
	if [ -n "${ARM_CLIENT_ID}" ]; then
		if [ "$PLATFORM" == "github" ]; then
			saveVariableInVariableGroup "${VARIABLE_GROUP_ID}" "ARM_CLIENT_ID" "$ARM_CLIENT_ID"
		fi
	fi

fi

# Get SPN ID differently per platform
if [ "$PLATFORM" == "devops" ]; then
	echo "0"
	TF_VAR_spn_id=$(getVariableFromVariableGroup "${VARIABLE_GROUP_ID}" "ARM_OBJECT_ID" "${deployer_environment_file_name}" "ARM_OBJECT_ID")
elif [ "$PLATFORM" == "github" ]; then
	# Use value from env or from GitHub environment
	TF_VAR_spn_id=${ARM_OBJECT_ID:-$TF_VAR_spn_id}
fi
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

if is_valid_id "${APPLICATION_CONFIGURATION_ID:-}" "/providers/Microsoft.AppConfiguration/configurationStores/"; then
	TF_VAR_management_subscription_id=$ARM_SUBSCRIPTION_ID
	export TF_VAR_management_subscription_id
else
	unset APPLICATION_CONFIGURATION_NAME
fi

# Force reset handling across platforms
if [ "${FORCE_RESET:-false}" == "true" ] || [ "${FORCE_RESET:-False}" == "True" ]; then
	if [ "$PLATFORM" == "devops" ]; then
		echo "##vso[task.logissue type=warning]Forcing a re-install"
	else
		echo -e "$bold_red--- Resetting the environment file ---$reset"
	fi
	echo "Running on:            $THIS_AGENT"
	sed -i 's/step=1/step=0/' "$deployer_environment_file_name"
	sed -i 's/step=2/step=0/' "$deployer_environment_file_name"
	sed -i 's/step=3/step=0/' "$deployer_environment_file_name"

	tfstate_resource_id=$(get_value_with_key "${CONTROL_PLANE_NAME}_TerraformRemoteStateStorageAccountId" "${CONTROL_PLANE_NAME}")
	if [ -z "$tfstate_resource_id" ]; then
		if [ "$PLATFORM" == "devops" ]; then
			echo "##vso[task.logissue type=warning]Key '${CONTROL_PLANE_NAME}_TerraformRemoteStateStorageAccountId' was not found in the application configuration ( '$application_configuration_name' )."
		else
			echo "WARNING: Key '${CONTROL_PLANE_NAME}_TerraformRemoteStateStorageAccountId' was not found in the application configuration."
		fi
	fi

	TERRAFORM_REMOTE_STORAGE_ACCOUNT_NAME=$(echo "$tfstate_resource_id" | cut -d'/' -f9)
	TERRAFORM_REMOTE_STORAGE_RESOURCE_GROUP_NAME=$(echo "$tfstate_resource_id" | cut -d'/' -f5)

	if [ -n "${TERRAFORM_REMOTE_STORAGE_ACCOUNT_NAME}" ]; then
		echo "Terraform Remote State Account:       ${TERRAFORM_REMOTE_STORAGE_ACCOUNT_NAME}"
	fi

	if [ -n "${TERRAFORM_REMOTE_STORAGE_RESOURCE_GROUP_NAME}" ]; then
		echo "Terraform Remote State RG Name:       ${TERRAFORM_REMOTE_STORAGE_RESOURCE_GROUP_NAME}"
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

echo -e "$green--- Variables ---$reset_formatting"

# Handle state.zip differently per platform

if [ "$PLATFORM" == "devops" ]; then
	pass=${SYSTEM_COLLECTIONID//-/}
elif [ "$PLATFORM" == "github" ]; then
	pass=${GITHUB_REPOSITORY//-/}
	# Import PGP key if it exists, otherwise generate it
	if [ -f ${CONFIG_REPO_PATH}/private.pgp ]; then
		echo "Importing PGP key"
		set +e
		gpg --list-keys sap-azure-deployer@example.com
		return_code=$?
		set -e

		if [ ${return_code} != 0 ]; then
			echo ${pass} | gpg --batch --passphrase-fd 0 --import ${CONFIG_REPO_PATH}/private.pgp
		fi
	else
		echo "Generating PGP key"
		echo ${pass} | ${SAP_AUTOMATION_REPO_PATH}/deploy/scripts/pipeline_scripts/v2/generate-pgp-key.sh
		gpg --output ${CONFIG_REPO_PATH}/private.pgp --armor --export-secret-key sap-azure-deployer@example.com
		git add ${CONFIG_REPO_PATH}/private.pgp
		commit_changes "Adding PGP key for encryption of state file" true
	fi
else
	pass="localpassword"
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
echo -e "$green--- Control Plane deployment---$reset_formatting"

# Platform-specific flags
if [ "$PLATFORM" == "devops" ]; then
	platform_flag="--ado"
elif [ "$PLATFORM" == "github" ]; then
	# Set required environment variables for GitHub
	export USER=${GITHUB_ACTOR:-githubuser}
	export DEPLOYER_KEYVAULT=${DEPLOYER_KEYVAULT:-""}
	platform_flag="--github"

	TF_VAR_github_server_url=${GITHUB_SERVER_URL}
	export TF_VAR_github_server_url

	TF_VAR_github_api_url=${GITHUB_API_URL}
	export TF_VAR_github_api_url

	TF_VAR_github_repository=${GITHUB_REPOSITORY}
	export TF_VAR_github_repository

	TF_VAR_devops_platform="github"
	export TF_VAR_devops_platform
else
	platform_flag=""
fi

end_group

git pull -q

cd "${CONFIG_REPO_PATH}" || exit

start_group "Decrypting state files"

if [ -f ${CONFIG_REPO_PATH}/DEPLOYER/${DEPLOYER_FOLDERNAME}/state.gpg ]; then
	echo "Decrypting state file"
	echo ${pass} |
		gpg --batch \
			--passphrase-fd 0 \
			--output ${CONFIG_REPO_PATH}/DEPLOYER/${DEPLOYER_FOLDERNAME}/terraform.tfstate \
			--decrypt ${CONFIG_REPO_PATH}/DEPLOYER/${DEPLOYER_FOLDERNAME}/state.gpg
fi

if [ -f "${CONFIG_REPO_PATH}/DEPLOYER/$DEPLOYER_FOLDERNAME/state.zip" ]; then
	echo "Unzipping the deployer state file"
	unzip -o -qq -P "${pass}" "${CONFIG_REPO_PATH}/DEPLOYER/$DEPLOYER_FOLDERNAME/state.zip" -d "${CONFIG_REPO_PATH}/DEPLOYER/$DEPLOYER_FOLDERNAME"
fi

end_group

start_group "Deploy the control plane"
# Deploy the control plane

if "${SAP_AUTOMATION_REPO_PATH}/deploy/scripts/deploy_control_plane_v2.sh" --control_plane_name "${CONTROL_PLANE_NAME}" \
	--subscription "$ARM_SUBSCRIPTION_ID" \
	--auto-approve ${platform_flag} ${msi_flag} --only_deployer; then
	return_code=$?
	if [ "$PLATFORM" == "devops" ]; then
		echo "##vso[task.logissue type=warning]Return code from deploy_control_plane_v2 $return_code."
	fi
	echo "Return code from deploy_control_plane_v2 $return_code."
else
	return_code=$?
	if [ "$PLATFORM" == "devops" ]; then
		echo "##vso[task.logissue type=error]Return code from deploy_control_plane_v2 $return_code."
	fi
	echo "Return code from deploy_control_plane_v2 $return_code."
fi
echo ""
echo -e "${cyan}deploy_control_plane_v2 returned:        $return_code${reset_formatting}"
echo ""

set -eu

if [ -f "${deployer_environment_file_name}" ]; then

	ARM_CLIENT_ID=$(grep -m1 "^ARM_CLIENT_ID=" "${deployer_environment_file_name}" | awk -F'=' '{print $2}' | xargs || true)
	export ARM_CLIENT_ID

	ARM_OBJECT_ID=$(grep -m1 "^ARM_OBJECT_ID=" "${deployer_environment_file_name}" | awk -F'=' '{print $2}' | xargs || true)
	export ARM_OBJECT_ID

	DevOpsInfrastructureObjectId=$(grep -m1 "^DevOpsInfrastructureObjectId" "${deployer_environment_file_name}" | awk -F'=' '{print $2}' | xargs || true)
	if [ -n "$DevOpsInfrastructureObjectId" ]; then
		export DevOpsInfrastructureObjectId
	fi

	file_deployer_tfstate_key=$(grep -m1 "^deployer_tfstate_key" "${deployer_environment_file_name}" | awk -F'=' '{print $2}' | xargs || true)
	if [ -n "$file_deployer_tfstate_key" ]; then
		deployer_tfstate_key=$file_deployer_tfstate_key
		export deployer_tfstate_key
	fi
	echo "Deployer State File:                 ${deployer_tfstate_key}"

	DEPLOYER_KEYVAULT=$(grep -m1 "^DEPLOYER_KEYVAULT=" "${deployer_environment_file_name}" | awk -F'=' '{print $2}' | xargs || true)
	echo "Deployer Key Vault:                  ${DEPLOYER_KEYVAULT}"

	file_REMOTE_STATE_SA=$(grep -m1 "^REMOTE_STATE_SA" "${deployer_environment_file_name}" | awk -F'=' '{print $2}' | xargs || true)
	if [ -n "${file_REMOTE_STATE_SA}" ]; then
		echo "Terraform Remote State Account:       ${file_REMOTE_STATE_SA}"
	fi

	file_REMOTE_STATE_RG=$(grep -m1 "^REMOTE_STATE_RG" "${deployer_environment_file_name}" | awk -F'=' '{print $2}' | xargs || true)
	if [ -n "${file_REMOTE_STATE_SA}" ]; then
		echo "Terraform Remote State RG Name:       ${file_REMOTE_STATE_RG}"
	fi

	APPLICATION_CONFIGURATION_NAME=$(grep -m1 "^APPLICATION_CONFIGURATION_NAME" "${deployer_environment_file_name}" | awk -F'=' '{print $2}' | xargs || true)
	if [ -n "${APPLICATION_CONFIGURATION_NAME}" ]; then
		export APPLICATION_CONFIGURATION_NAME
		echo "Application Configuration Name:      ${APPLICATION_CONFIGURATION_NAME}"
	fi

	APP_SERVICE_NAME=$(grep -m1 "^APP_SERVICE_NAME" "${deployer_environment_file_name}" | awk -F'=' '{print $2}' | xargs || true)
	if [ -n "${APP_SERVICE_NAME}" ]; then
		export APP_SERVICE_NAME
		echo "AppService Name:                     ${APP_SERVICE_NAME}"
	fi

	APP_SERVICE_DEPLOYMENT=$(grep -m1 "^HAS_WEBAPP" "${deployer_environment_file_name}" | awk -F'=' '{print $2}' | xargs || true)
	if [ -n "${APP_SERVICE_DEPLOYMENT}" ]; then
		export APP_SERVICE_DEPLOYMENT
	fi

	DEPLOYER_MSI_CLIENT_ID=$(grep -m1 "^DEPLOYER_MSI_CLIENT_ID=" "${deployer_environment_file_name}" | awk -F'=' '{print $2}' | xargs || true)
	echo "DEPLOYER_MSI_CLIENT_ID:              ${DEPLOYER_MSI_CLIENT_ID:-}"
	# Set output variables for GitHub Actions
	if [ "$PLATFORM" == "github" ]; then
		set_output_variable "deployer_keyvault" "${DEPLOYER_KEYVAULT}"
		set_output_variable "this_agent" "self-hosted"
		set_output_variable "app_config_name" "${APPLICATION_CONFIGURATION_NAME}"
		set_output_variable "msi_id" "${DEPLOYER_MSI_CLIENT_ID}"
	fi
fi

echo -e "$green--- Adding deployment automation configuration to repository ---$reset_formatting"
added=0
cd "$CONFIG_REPO_PATH" || exit

# Pull latest changes
if [ "$PLATFORM" == "devops" ]; then
	git pull -q origin "$BUILD_SOURCEBRANCHNAME"
elif [ "$PLATFORM" == "github" ]; then
	git pull -q origin "$GITHUB_REF_NAME"
fi

echo -e "$green--- Update repo ---$reset_formatting"

if [ -f "${deployer_environment_file_name}" ]; then
	git add "${deployer_environment_file_name}"
	added=1
fi

if [ -f "{$deployer_tfvars_file_name}" ]; then
	git add -f "{$deployer_tfvars_file_name}"
	added=1
fi

if [ -f DEPLOYER/${DEPLOYER_FOLDERNAME}/.terraform/terraform.tfstate ]; then
	git add -f "DEPLOYER/${DEPLOYER_FOLDERNAME}/.terraform/terraform.tfstate"
	added=1
fi

if [ -f "DEPLOYER/$DEPLOYER_FOLDERNAME/terraform.tfstate" ]; then
	if [ "$PLATFORM" == "devops" ]; then
		sudo apt-get install zip -y
		pass=${SYSTEM_COLLECTIONID//-/}
		zip -q -j -P "${pass}" "DEPLOYER/$DEPLOYER_FOLDERNAME/state" "DEPLOYER/$DEPLOYER_FOLDERNAME/terraform.tfstate"
		git add -f "DEPLOYER/$DEPLOYER_FOLDERNAME/state.zip"
	elif [ "$PLATFORM" == "github" ]; then
		rm DEPLOYER/${DEPLOYER_FOLDERNAME}/state.gpg >/dev/null 2>&1 || true
		echo "Encrypting state file"
		gpg --batch \
			--output DEPLOYER/${DEPLOYER_FOLDERNAME}/state.gpg \
			--encrypt \
			--disable-dirmngr --recipient sap-azure-deployer@example.com \
			--trust-model always \
			DEPLOYER/${DEPLOYER_FOLDERNAME}/terraform.tfstate
		git add -f DEPLOYER/${DEPLOYER_FOLDERNAME}/state.gpg
	else
		pass="localpassword"
	fi
	added=1
fi

if [ -f .sap_deployment_automation/terraform.log ]; then
	rm .sap_deployment_automation/terraform.log
fi

if [ -f LICENSE.txt ]; then
	rm LICENSE.txt
fi

# Commit changes based on platform
if [ 1 = $added ]; then
	if [ "$PLATFORM" == "devops" ]; then
		set +e
		git diff --cached --quiet
		git_diff_return_code=$?
		set -e
		if [ 1 == $git_diff_return_code ]; then
			git config --global user.email "$BUILD_REQUESTEDFOREMAIL"
			git config --global user.name "$BUILD_REQUESTEDFOR"
			git commit -m "Added updates from Control Plane Deployment for $DEPLOYER_FOLDERNAME $BUILD_BUILDNUMBER [skip ci]"
			if ! git -c http.extraheader="AUTHORIZATION: bearer $SYSTEM_ACCESSTOKEN" push --set-upstream origin "$BUILD_SOURCEBRANCHNAME" --force-with-lease; then
				echo "##vso[task.logissue type=error]Failed to push changes to the repository."
			fi
		fi
	elif [ "$PLATFORM" == "github" ]; then
		set +e
		git diff --cached --quiet
		git_diff_return_code=$?
		set -e
		if [ 1 == $git_diff_return_code ]; then
			commit_changes "Added updates for deployment."
		fi

		if [ -f ".sap_deployment_automation/$CONTROL_PLANE_NAME.md" ]; then
			upload_summary ".sap_deployment_automation/$CONTROL_PLANE_NAME.md"
		fi
	fi
fi

if [ "$PLATFORM" == "devops" ]; then
	if [ -f "$CONFIG_REPO_PATH/.sap_deployment_automation/${ENVIRONMENT}${LOCATION}.md" ]; then
		echo "##vso[task.uploadsummary]$CONFIG_REPO_PATH/.sap_deployment_automation/${ENVIRONMENT}${LOCATION}.md"
	fi
	echo -e "$green--- Adding variables to the variable group: $VARIABLE_GROUP ---$reset"
	if [ 0 -eq "$return_code" ]; then
		saveVariableInVariableGroup "${VARIABLE_GROUP_ID}" "APPLICATION_CONFIGURATION_NAME" "$APPLICATION_CONFIGURATION_NAME"
		saveVariableInVariableGroup "${VARIABLE_GROUP_ID}" "CONTROL_PLANE_NAME" "$CONTROL_PLANE_NAME"
		saveVariableInVariableGroup "${VARIABLE_GROUP_ID}" "DEPLOYER_KEYVAULT" "$DEPLOYER_KEYVAULT"
	fi
elif [ "$PLATFORM" == "github" ]; then
	if [ -f "$CONFIG_REPO_PATH/.sap_deployment_automation/${ENVIRONMENT}${LOCATION}.md" ]; then
		echo "##[group]Upload summary"
		upload_summary "$CONFIG_REPO_PATH/.sap_deployment_automation/${ENVIRONMENT}${LOCATION}.md"
		echo "##[endgroup]"
	fi
	if [ 0 -eq "$return_code" ]; then
		set_value_with_key "APPLICATION_CONFIGURATION_NAME" "${APPLICATION_CONFIGURATION_NAME}" "env"
		set_value_with_key "CONTROL_PLANE_NAME" "${CONTROL_PLANE_NAME}" "env"
		set_value_with_key "DEPLOYER_KEYVAULT" "${DEPLOYER_KEYVAULT}" "env"
	fi
fi
end_group
echo "Exit code:                             $return_code"
exit $return_code
