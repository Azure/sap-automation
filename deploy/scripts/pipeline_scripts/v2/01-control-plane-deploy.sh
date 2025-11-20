#!/bin/bash
# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

# Source the shared platform configuration
SCRIPT_DIR="$(dirname "${BASH_SOURCE[0]}")"
source "${SCRIPT_DIR}/shared_platform_config.sh"
source "${SCRIPT_DIR}/shared_functions.sh"
source "${SCRIPT_DIR}/set-colors.sh"

SCRIPT_NAME="$(basename "$0")"

# Set platform-specific output
if [ "$PLATFORM" == "devops" ]; then
	echo "##vso[build.updatebuildnumber]Deploying the control plane defined in ${DEPLOYER_FOLDERNAME} ${LIBRARY_FOLDERNAME}"
	DEBUG=false
	if [ "${SYSTEM_DEBUG:-False}" == True ]; then
		set -x
		DEBUG=True
		TF_LOG=DEBUG
		export TF_LOG

		echo "Environment variables:"
		printenv | sort
	fi
fi

export DEBUG

# External helper functions

full_script_path="$(realpath "${BASH_SOURCE[0]}")"
script_directory="$(dirname "${full_script_path}")"
parent_directory="$(dirname "$script_directory")"
grand_parent_directory="$(dirname "$parent_directory")"

# Source helper scripts
source "${parent_directory}/helper.sh"
source "${grand_parent_directory}/deploy_utils.sh"

# Print the execution environment details
print_header
echo ""

ENVIRONMENT=$(echo "${CONTROL_PLANE_NAME}" | awk -F'-' '{print $1}' | xargs)
LOCATION=$(echo "${CONTROL_PLANE_NAME}" | awk -F'-' '{print $2}' | xargs)
NETWORK=$(echo "${CONTROL_PLANE_NAME}" | awk -F'-' '{print $3}' | xargs)

if [ "$PLATFORM" == "github" ]; then
	DEPLOYER_FOLDERNAME="${CONTROL_PLANE_NAME}-INFRASTRUCTURE"
	LIBRARY_FOLDERNAME="${ENVIRONMENT}-${LOCATION}-SAP_LIBRARY"
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

if [ -z "$CONTROL_PLANE_NAME" ]; then
	CONTROL_PLANE_NAME=$(echo "$DEPLOYER_FOLDERNAME" | cut -d'-' -f1-3)
	export CONTROL_PLANE_NAME
fi

if [ -f "${deployer_environment_file_name}" ]; then
	step=$(grep -m1 "^step=" "${deployer_environment_file_name}" | awk -F'=' '{print $2}' | xargs)
	echo "Step:                                ${step:-0}"
fi

terraform_storage_account_name=""
terraform_storage_account_resource_group_name=$DEPLOYER_FOLDERNAME

# Print the execution environment details
print_header

if [ "$PLATFORM" == "devops" ]; then
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
	# No specific variable group setup for GitHub Actions
	# Values will be stored in GitHub Environment variables
	echo "Configuring for GitHub Actions"
	export VARIABLE_GROUP_ID="${CONTROL_PLANE_NAME}"
	git config --global --add safe.directory "$CONFIG_REPO_PATH"

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

banner_title="Deploy Control Plane"
print_banner "$banner_title" "Starting $SCRIPT_NAME" "info"

terraform_storage_account_name=""
terraform_storage_account_resource_group_name=$LIBRARY_FOLDERNAME

msi_flag=""

# Check if running on deployer
if [[ ! -f /etc/profile.d/deploy_server.sh ]]; then
	configureNonDeployer "${tf_version:-1.13.3}"
fi
echo -e "$green--- az login ---$reset"
# Set logon variables
if [ "$USE_MSI" == "true" ]; then
	unset ARM_CLIENT_SECRET
	ARM_USE_MSI=true
	export ARM_USE_MSI
fi

if [ "$PLATFORM" == "devops" ]; then
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

	LogonToAzure "${USE_MSI:-false}"
	return_code=$?
	if [ 0 != $return_code ]; then
		echo -e "$bold_red--- Login failed ---$reset"
		echo "##vso[task.logissue type=error]az login failed."
		exit $return_code
	fi
fi

cd "$CONFIG_REPO_PATH" || exit

TF_VAR_subscription_id=$ARM_SUBSCRIPTION_ID
export TF_VAR_subscription_id
if [ -z "${TF_VAR_ansible_core_version:-}" ]; then
	export TF_VAR_ansible_core_version=2.16
fi

az account set --subscription "$ARM_SUBSCRIPTION_ID"
echo "Deployer subscription:               $ARM_SUBSCRIPTION_ID"

if [ ! -v APPLICATION_CONFIGURATION_ID ]; then
	APPLICATION_CONFIGURATION_ID=$(az graph query -q "Resources | join kind=leftouter (ResourceContainers | where type=='microsoft.resources/subscriptions' | project subscription=name, subscriptionId) on subscriptionId | where name == '$APPLICATION_CONFIGURATION_NAME' | project id, name, subscription" --query data[0].id --output tsv)
	export APPLICATION_CONFIGURATION_ID
fi

APPLICATION_CONFIGURATION_SUBSCRIPTION_ID=$(echo "$APPLICATION_CONFIGURATION_ID" | cut -d '/' -f 3)
export APPLICATION_CONFIGURATION_SUBSCRIPTION_ID

if [ -v DEPLOYER_KEYVAULT ]; then
	key_vault_id=$(az graph query -q "Resources | join kind=leftouter (ResourceContainers | where type=='microsoft.resources/subscriptions' | project subscription=name, subscriptionId) on subscriptionId | where name == '$DEPLOYER_KEYVAULT' | project id, name, subscription" --query data[0].id --output tsv)
fi

if [ -z "$key_vault_id" ]; then
	if [ "$PLATFORM" == "devops" ]; then
		echo "##vso[task.logissue type=error]Key '${CONTROL_PLANE_NAME}_KeyVaultResourceId' was not found in the application configuration ( '$APPLICATION_CONFIGURATION_NAME' )."
	else
		echo "ERROR: Key '${CONTROL_PLANE_NAME}_KeyVaultResourceId' was not found in the application configuration."
	fi
fi

TF_VAR_deployer_kv_user_arm_id=${key_vault_id}
export TF_VAR_deployer_kv_user_arm_id

tfstate_resource_id=$(get_value_with_key "${CONTROL_PLANE_NAME}_TerraformRemoteStateStorageAccountId")
if [ -z "$tfstate_resource_id" ]; then
	if [ -v TERRAFORM_REMOTE_STORAGE_ACCOUNT_NAME ]; then
		tfstate_resource_id=$(az graph query -q "Resources | join kind=leftouter (ResourceContainers | where type=='microsoft.resources/subscriptions' | project subscription=name, subscriptionId) on subscriptionId | where name == '${TERRAFORM_REMOTE_STORAGE_ACCOUNT_NAME}' | project id, name, subscription" --query data[0].id --output tsv)
	fi
fi

echo ""
echo -e "${green}Terraform parameter information:"
echo -e "-------------------------------------------------------------------------------$reset_formatting"

echo "Control Plane Name:                  $CONTROL_PLANE_NAME"
echo ""
echo "Deployer Folder:                     $DEPLOYER_FOLDERNAME"
echo "Deployer tfVars:                     $DEPLOYER_FOLDERNAME.tfvars"
echo "Library Folder:                      $LIBRARY_FOLDERNAME"
echo "Library tfVars:                      $LIBRARY_FOLDERNAME"

if [ -n "${DEPLOYER_KEYVAULT}" ]; then
	echo "Deployer Key Vault:                  ${DEPLOYER_KEYVAULT}"
	keyvault_parameter=" --keyvault ${DEPLOYER_KEYVAULT} "
else
	echo "Deployer Key Vault:                  undefined"
	exit 2
fi

terraform_storage_account_subscription_id=$ARM_SUBSCRIPTION_ID

echo "Terraform state subscription:        $terraform_storage_account_subscription_id"

if [ -n "$tfstate_resource_id" ]; then
	terraform_storage_account_name=$(echo "$tfstate_resource_id" | cut -d '/' -f 9)
	terraform_storage_account_resource_group_name=$(echo "$tfstate_resource_id" | cut -d '/' -f 5)
	terraform_storage_account_subscription_id=$(echo "$tfstate_resource_id" | cut -d '/' -f 3)
	echo "Terraform storage account:           $terraform_storage_account_name"
	storage_account_parameter=" --terraform_storage_account_name ${terraform_storage_account_name} "

	export terraform_storage_account_name
	export terraform_storage_account_resource_group_name
	export terraform_storage_account_subscription_id
	export tfstate_resource_id

else
	echo "Terraform storage account:            undefined"
fi

start_group "Decrypting state files"

cd "${CONFIG_REPO_PATH}" || exit
mkdir -p .sap_deployment_automation

# Pull latest changes from appropriate branch
if [ "$PLATFORM" == "devops" ]; then
	git pull -q origin "$BUILD_SOURCEBRANCHNAME"
elif [ "$PLATFORM" == "github" ]; then
	git pull -q origin "$GITHUB_REF_NAME"
fi

if [ "$PLATFORM" == "devops" ]; then
	pass=${SYSTEM_COLLECTIONID//-/}
	if [ -f "${CONFIG_REPO_PATH}/DEPLOYER/$DEPLOYER_FOLDERNAME/state.zip" ]; then
		echo "Unzipping the deployer state file"
		unzip -o -qq -P "${pass}" "${CONFIG_REPO_PATH}/DEPLOYER/$DEPLOYER_FOLDERNAME/state.zip" -d "${CONFIG_REPO_PATH}/DEPLOYER/$DEPLOYER_FOLDERNAME"
	fi

	if [ -f "${CONFIG_REPO_PATH}/LIBRARY/$LIBRARY_FOLDERNAME/state.zip" ]; then
		echo "Unzipping the library state file"
		unzip -o -qq -P "${pass}" "${CONFIG_REPO_PATH}/LIBRARY/$LIBRARY_FOLDERNAME/state.zip" -d "${CONFIG_REPO_PATH}/LIBRARY/$LIBRARY_FOLDERNAME"
	fi

elif [ "$PLATFORM" == "github" ]; then
	pass=${GITHUB_REPOSITORY//-/}
	# Import PGP key if it exists, otherwise generate it
	if [ -f "${CONFIG_REPO_PATH}/private.pgp" ]; then
		echo "Importing PGP key"
		set +e
		gpg --list-keys sap-azure-deployer@example.com
		return_code=$?
		set -e

		if [ ${return_code} != 0 ]; then
			echo "${pass}" | gpg --batch --passphrase-fd 0 --import "${CONFIG_REPO_PATH}/private.pgp"
		fi
		if [ -f "${CONFIG_REPO_PATH}/DEPLOYER/${DEPLOYER_FOLDERNAME}/state.gpg" ]; then
			echo "Decrypting state file"
			echo "${pass}" |
				gpg --batch \
					--passphrase-fd 0 \
					--output "${CONFIG_REPO_PATH}/DEPLOYER/${DEPLOYER_FOLDERNAME}/terraform.tfstate" \
					--decrypt "${CONFIG_REPO_PATH}/DEPLOYER/${DEPLOYER_FOLDERNAME}/state.gpg"
		fi
		if [ -f "${CONFIG_REPO_PATH}/LIBRARY/$LIBRARY_FOLDERNAME/state.gpg" ]; then
			echo "Decrypting state file"
			echo "${pass}" |
				gpg --batch \
					--passphrase-fd 0 \
					--output "${CONFIG_REPO_PATH}/LIBRARY/$LIBRARY_FOLDERNAME/terraform.tfstate" \
					--decrypt "${CONFIG_REPO_PATH}/LIBRARY/$LIBRARY_FOLDERNAME/state.gpg"
		fi
	else
		exit_error "Private PGP key not found." 3
	fi
fi

end_group

if [ "${HAS_APPSERVICE_DEPLOYED:-false}" = "true" ]; then
	echo "Deploy Web Application:               true"

	if [ ! -v APP_REGISTRATION_APP_ID ]; then
		if [ "$PLATFORM" == "devops" ]; then
			echo "##vso[task.logissue type=error]Variable APP_REGISTRATION_APP_ID was not defined."
		elif [ "$PLATFORM" == "github" ]; then
			echo "Variable APP_REGISTRATION_APP_ID was not defined."
		fi
		exit 2
	fi
	echo "App Registration ID:                  $APP_REGISTRATION_APP_ID"
	TF_VAR_app_registration_app_id=$APP_REGISTRATION_APP_ID
	export TF_VAR_app_registration_app_id

else
	echo "Deploy Web Application:               false"
fi

export TF_LOG_PATH="${CONFIG_REPO_PATH}/.sap_deployment_automation/terraform.log"

print_banner "$banner_title" "Calling deploy_control_plane_v2" "info"

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
	platform_flag=" --ado"
elif [ "$PLATFORM" == "github" ]; then
	platform_flag=" --github"
else
	platform_flag=""
fi

cd "$CONFIG_REPO_PATH" || exit
start_group "Deploying control plane"

if
	"${SAP_AUTOMATION_REPO_PATH}/deploy/scripts/deploy_control_plane_v2.sh" \
		--control_plane_name "$CONTROL_PLANE_NAME" \
		--auto-approve ${msi_flag} $platform_flag
then
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

end_group

if [ "$PLATFORM" == "devops" ]; then
	echo -e "$green--- Adding variables to the variable group: $VARIABLE_GROUP ---$reset"
	if [ -n "$DEPLOYER_KEYVAULT" ]; then
		if saveVariableInVariableGroup "${VARIABLE_GROUP_ID}" "DEPLOYER_KEYVAULT" "$DEPLOYER_KEYVAULT"; then
			echo "Saved DEPLOYER_KEYVAULT in variable group."
		else
			echo "##vso[task.logissue type=warning]Failed to save DEPLOYER_KEYVAULT in variable group."
		fi
	fi
fi

ARM_CLIENT_ID=$(grep -m1 "^ARM_CLIENT_ID=" "${deployer_environment_file_name}" | awk -F'=' '{print $2}' | xargs || true)
if [ -n "${ARM_CLIENT_ID}" ]; then
	if [ "$PLATFORM" == "devops" ]; then
		saveVariableInVariableGroup "${VARIABLE_GROUP_ID}" "ARM_CLIENT_ID" "$ARM_CLIENT_ID"
	fi
fi
export ARM_CLIENT_ID

ARM_OBJECT_ID=$(grep -m1 "^ARM_OBJECT_ID=" "${deployer_environment_file_name}" | awk -F'=' '{print $2}' | xargs || true)
if [ -n "${ARM_OBJECT_ID}" ]; then
	if [ "$PLATFORM" == "devops" ]; then
		saveVariableInVariableGroup "${VARIABLE_GROUP_ID}" "ARM_OBJECT_ID" "$ARM_OBJECT_ID"
	fi
fi

export ARM_OBJECT_ID

APPLICATION_CONFIGURATION_NAME=$(grep -m1 "^APPLICATION_CONFIGURATION_NAME" "${deployer_environment_file_name}" | awk -F'=' '{print $2}' | xargs || true)
if [ -n "${APPLICATION_CONFIGURATION_NAME}" ]; then
	export APPLICATION_CONFIGURATION_NAME
	echo "APPLICATION_CONFIGURATION_NAME:      ${APPLICATION_CONFIGURATION_NAME}"
	if [ "$PLATFORM" == "devops" ]; then
		saveVariableInVariableGroup "${VARIABLE_GROUP_ID}" "APPLICATION_CONFIGURATION_NAME" "$APPLICATION_CONFIGURATION_NAME"
	fi
fi

APPLICATION_CONFIGURATION_DEPLOYMENT=$(grep -m1 "^APPLICATION_CONFIGURATION_DEPLOYMENT" "${deployer_environment_file_name}" | awk -F'=' '{print $2}' | xargs || true)
if [ -n "${APPLICATION_CONFIGURATION_DEPLOYMENT}" ]; then
	export APPLICATION_CONFIGURATION_DEPLOYMENT
	echo "APPLICATION_CONFIGURATION_DEPLOYMENT:  ${APPLICATION_CONFIGURATION_DEPLOYMENT}"
	if [ "$PLATFORM" == "devops" ]; then
		saveVariableInVariableGroup "${VARIABLE_GROUP_ID}" "APPLICATION_CONFIGURATION_DEPLOYMENT" "$APPLICATION_CONFIGURATION_DEPLOYMENT"
	fi
fi

APP_SERVICE_NAME=$(grep -m1 "^APP_SERVICE_NAME" "${deployer_environment_file_name}" | awk -F'=' '{print $2}' | xargs || true)
if [ -n "${APP_SERVICE_NAME}" ]; then
	export APP_SERVICE_NAME
	echo "APP_SERVICE_NAME:      ${APP_SERVICE_NAME}"
	if [ "$PLATFORM" == "devops" ]; then
		saveVariableInVariableGroup "${VARIABLE_GROUP_ID}" "APP_SERVICE_NAME" "$APP_SERVICE_NAME"
	fi
fi

APP_SERVICE_DEPLOYMENT=$(grep -m1 "^HAS_WEBAPP" "${deployer_environment_file_name}" | awk -F'=' '{print $2}' | xargs || true)
if [ -n "${APP_SERVICE_DEPLOYMENT}" ]; then
	export APP_SERVICE_DEPLOYMENT
	echo "APP_SERVICE_DEPLOYMENT:      ${APP_SERVICE_DEPLOYMENT}"
	if [ "$PLATFORM" == "devops" ]; then
		saveVariableInVariableGroup "${VARIABLE_GROUP_ID}" "APP_SERVICE_DEPLOYMENT" "$APP_SERVICE_DEPLOYMENT"
	fi
fi
if [ "$PLATFORM" == "devops" ]; then
	saveVariableInVariableGroup "${VARIABLE_GROUP_ID}" "CONTROL_PLANE_ENVIRONMENT" "$ENVIRONMENT"
	saveVariableInVariableGroup "${VARIABLE_GROUP_ID}" "CONTROL_PLANE_LOCATION" "$LOCATION"
	saveVariableInVariableGroup "${VARIABLE_GROUP_ID}" "CONTROL_PLANE_NAME" "$CONTROL_PLANE_NAME"
fi

echo "Environment:                         $ENVIRONMENT"
echo "Location:                            $LOCATION"

start_group "Update the repository"

echo -e "$green--- Pushing the changes to the repository ---$reset_formatting"
added=0
cd "${CONFIG_REPO_PATH}" || exit

# Pull latest changes from appropriate branch
if [ "$PLATFORM" == "devops" ]; then
	git pull -q origin "$BUILD_SOURCEBRANCHNAME"
elif [ "$PLATFORM" == "github" ]; then
	git pull -q origin "$GITHUB_REF_NAME"
fi

echo -e "$green--- Update repo ---$reset_formatting"
if [ -f ".sap_deployment_automation/$CONTROL_PLANE_NAME" ]; then
	git add ".sap_deployment_automation/$CONTROL_PLANE_NAME"
	added=1
fi

if [ -f ".sap_deployment_automation/${CONTROL_PLANE_NAME}.md" ]; then
	git add ".sap_deployment_automation/${CONTROL_PLANE_NAME}.md"
	added=1
fi

if [ -f "${deployer_tfvars_file_name}" ]; then
	git add -f "${deployer_tfvars_file_name}"
	added=1
fi

if [ -f "DEPLOYER/$DEPLOYER_FOLDERNAME/.terraform/terraform.tfstate" ]; then
	git add -f "DEPLOYER/$DEPLOYER_FOLDERNAME/.terraform/terraform.tfstate"
	added=1

	# || true suppresses the exitcode of grep. To not trigger the strict exit on error
	local_backend=$(grep "\"type\": \"local\"" "DEPLOYER/$DEPLOYER_FOLDERNAME/.terraform/terraform.tfstate" || true)

	if [ -n "$local_backend" ]; then
		echo "Deployer Terraform state:              local"

		if [ -f "DEPLOYER/$DEPLOYER_FOLDERNAME/terraform.tfstate" ]; then
			echo "Compressing the deployer state file"
			if [ "$PLATFORM" == "devops" ]; then
				sudo apt-get -qq install zip

				pass=${SYSTEM_COLLECTIONID//-/}
				zip -q -j -P "${pass}" "DEPLOYER/$DEPLOYER_FOLDERNAME/state" "DEPLOYER/$DEPLOYER_FOLDERNAME/terraform.tfstate"
				git add -f "DEPLOYER/$DEPLOYER_FOLDERNAME/state.zip"
				rm "DEPLOYER/$DEPLOYER_FOLDERNAME/terraform.tfstate"
			elif [ "$PLATFORM" == "github" ]; then
				rm DEPLOYER/$DEPLOYER_FOLDERNAME/state.gpg >/dev/null 2>&1 || true

				echo "Encrypting state file"
				gpg --batch \
					--output DEPLOYER/$DEPLOYER_FOLDERNAME/state.gpg \
					--encrypt \
					--disable-dirmngr --recipient sap-azure-deployer@example.com \
					--trust-model always \
					DEPLOYER/$DEPLOYER_FOLDERNAME/terraform.tfstate
				git add -f DEPLOYER/$DEPLOYER_FOLDERNAME/state.gpg
			else
				pass="localpassword"
			fi

			added=1
		fi
	else
		echo "Deployer Terraform state:              remote"
		if [ -f "DEPLOYER/$DEPLOYER_FOLDERNAME/terraform.tfstate" ]; then
			git rm -q --ignore-unmatch -f "DEPLOYER/$DEPLOYER_FOLDERNAME/terraform.tfstate"
			echo "Removed the deployer state file"
			added=1
		fi
		if [ -f "DEPLOYER/$DEPLOYER_FOLDERNAME/state.zip" ]; then
			if [ 0 -eq "$return_code" ]; then
				echo "Removing the deployer state zip file"
				git rm -q --ignore-unmatch -f "DEPLOYER/$DEPLOYER_FOLDERNAME/state.zip"
				added=1
			fi
		fi
		if [ -f "DEPLOYER/$DEPLOYER_FOLDERNAME/state.gpg" ]; then
			if [ 0 == $return_code ]; then
				echo "Removing the deployer state gpg file"
				git rm -q --ignore-unmatch -f "DEPLOYER/$DEPLOYER_FOLDERNAME/state.gpg"
				added=1
			fi
		fi
	fi
fi

if [ -f "${library_tfvars_file_name}" ]; then
	git add -f "${library_tfvars_file_name}"
	added=1
fi

if [ -f "LIBRARY/$LIBRARY_FOLDERNAME/.terraform/terraform.tfstate" ]; then
	TERRAFORM_REMOTE_STORAGE_ACCOUNT_NAME=$(grep -m1 "storage_account_name" "LIBRARY/$LIBRARY_FOLDERNAME/.terraform/terraform.tfstate" | cut -d ':' -f2 | tr -d ' ",\r' | xargs || true)

	git add -f "LIBRARY/$LIBRARY_FOLDERNAME/.terraform/terraform.tfstate"
	added=1
	# || true suppresses the exitcode of grep. To not trigger the strict exit on error
	local_backend=$(grep "\"type\": \"local\"" "LIBRARY/$LIBRARY_FOLDERNAME/.terraform/terraform.tfstate" || true)
	if [ -n "$local_backend" ]; then
		echo "Library Terraform state:               local"
		if [ -f "LIBRARY/$LIBRARY_FOLDERNAME/terraform.tfstate" ]; then
			if [ "$PLATFORM" == "devops" ]; then
				sudo apt-get -qq install zip

				echo "Compressing the library state file"
				pass=${SYSTEM_COLLECTIONID//-/}
				zip -q -j -P "${pass}" "LIBRARY/$LIBRARY_FOLDERNAME/state" "LIBRARY/$LIBRARY_FOLDERNAME/terraform.tfstate"
				git add -f "LIBRARY/$LIBRARY_FOLDERNAME/state.zip"
				rm "LIBRARY/$LIBRARY_FOLDERNAME/terraform.tfstate"
			elif [ "$PLATFORM" == "github" ]; then
				rm LIBRARY/$LIBRARY_FOLDERNAME/state.gpg >/dev/null 2>&1 || true
				echo "Encrypting state file"
				gpg --batch \
					--output LIBRARY/$LIBRARY_FOLDERNAME/state.gpg \
					--encrypt \
					--disable-dirmngr --recipient sap-azure-deployer@example.com \
					--trust-model always \
					LIBRARY/$LIBRARY_FOLDERNAME/terraform.tfstate
				git add -f LIBRARY/$LIBRARY_FOLDERNAME/state.gpg
			else
				pass="localpassword"
			fi
			added=1
		fi
	else
		echo "Library Terraform state:               remote"
		if [ -f "LIBRARY/$LIBRARY_FOLDERNAME/terraform.tfstate" ]; then
			if [ 0 -eq "$return_code" ]; then
				echo "Removing the library state file"
				git rm -q -f --ignore-unmatch "LIBRARY/$LIBRARY_FOLDERNAME/terraform.tfstate"
				added=1
			fi
		fi
		if [ -f "LIBRARY/$LIBRARY_FOLDERNAME/state.zip" ]; then
			echo "Removing the library state zip file"
			git rm -q --ignore-unmatch -f "LIBRARY/$LIBRARY_FOLDERNAME/state.zip"
			added=1
		fi
		if [ -f "LIBRARY/$LIBRARY_FOLDERNAME/state.gpg" ]; then
			echo "Removing the library state gpg file"
			git rm -q --ignore-unmatch -f "LIBRARY/$LIBRARY_FOLDERNAME/state.gpg"
			added=1
		fi
	fi
else
	TERRAFORM_REMOTE_STORAGE_ACCOUNT_NAME=""
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
		git config --global user.email "$BUILD_REQUESTEDFOREMAIL"
		git config --global user.name "$BUILD_REQUESTEDFOR"
		commit_message="Added updates from Control Plane Deployment for $DEPLOYER_FOLDERNAME $LIBRARY_FOLDERNAME $BUILD_BUILDNUMBER [skip ci]"
	elif [ "$PLATFORM" == "github" ]; then
		git config --global user.email "github-actions@github.com"
		git config --global user.name "GitHub Actions"
		commit_message="Added updates from Control Plane Deployment for $DEPLOYER_FOLDERNAME $LIBRARY_FOLDERNAME [skip ci]"
	else
		git config --global user.email "local@example.com"
		git config --global user.name "Local User"
		commit_message="Added updates from Control Plane Deployment for $DEPLOYER_FOLDERNAME $LIBRARY_FOLDERNAME [skip ci]"
	fi

	if [ $DEBUG = True ]; then
		git status --verbose
		if git commit -m "$commit_message" || true; then
			if [ "$PLATFORM" == "devops" ]; then
				if ! git -c http.extraheader="AUTHORIZATION: bearer $SYSTEM_ACCESSTOKEN" push --set-upstream origin "$BUILD_SOURCEBRANCHNAME" --force-with-lease; then
					echo "Failed to push changes to the repository."
				fi
			elif [ "$PLATFORM" == "github" ]; then
				if ! git push --set-upstream origin "$GITHUB_REF_NAME" --force-with-lease; then
					echo "Failed to push changes to the repository."
				fi
			fi
		fi
	else
		if git commit -m "Added updates from Control Plane Deployment for $DEPLOYER_FOLDERNAME $LIBRARY_FOLDERNAME [skip ci]"; then
			if [ "$PLATFORM" == "devops" ]; then
				if ! git -c http.extraheader="AUTHORIZATION: bearer $SYSTEM_ACCESSTOKEN" push --set-upstream origin "$BUILD_SOURCEBRANCHNAME" --force-with-lease; then
					echo "Failed to push changes to the repository."
				fi
			elif [ "$PLATFORM" == "github" ]; then
				if ! git push --set-upstream origin "$GITHUB_REF_NAME" --force-with-lease; then
					echo "Failed to push changes to the repository."
				fi
			fi
		fi
	fi
fi
end_group
start_group "Adding variables"
# Add variables to storage based on platform
echo -e "$green--- Adding variables to storage ---$reset_formatting"
if [ 0 -eq "$return_code" ]; then
	WEBAPP_ID=$(getVariableFromApplicationConfiguration "$APPLICATION_CONFIGURATION_ID" "${CONTROL_PLANE_NAME}_AppServiceId" "${CONTROL_PLANE_NAME}")
	if [ -n "$WEBAPP_ID" ]; then
		WEBAPP_URL_BASE=$(echo "$WEBAPP_ID" | cut -d '/' -f 9)
	fi
	if [ "$PLATFORM" == "devops" ]; then
		echo -e "$green--- Adding variables to the variable group: $VARIABLE_GROUP ---$reset_formatting"
		if saveVariableInVariableGroup "${VARIABLE_GROUP_ID}" "CONTROL_PLANE_NAME" "$CONTROL_PLANE_NAME"; then
			echo "Variable CONTROL_PLANE_NAME was added to the $VARIABLE_GROUP variable group."
		else
			echo "##vso[task.logissue type=error]Variable CONTROL_PLANE_NAME was not added to the $VARIABLE_GROUP variable group."
			echo "Variable CONTROL_PLANE_NAME was not added to the $VARIABLE_GROUP variable group."
		fi
		if saveVariableInVariableGroup "${VARIABLE_GROUP_ID}" "TERRAFORM_REMOTE_STORAGE_ACCOUNT_NAME" "$TERRAFORM_REMOTE_STORAGE_ACCOUNT_NAME"; then
			echo "Variable TERRAFORM_REMOTE_STORAGE_ACCOUNT_NAME was added to the $VARIABLE_GROUP variable group."
		else
			echo "##vso[task.logissue type=error]Variable TERRAFORM_REMOTE_STORAGE_ACCOUNT_NAME was not added to the $VARIABLE_GROUP variable group."
			echo "Variable TERRAFORM_REMOTE_STORAGE_ACCOUNT_NAME was not added to the $VARIABLE_GROUP variable group."
		fi
		if saveVariableInVariableGroup "${VARIABLE_GROUP_ID}" "WEBAPP_ID" "$WEBAPP_ID"; then
			echo "Variable WEBAPP_ID was added to the $VARIABLE_GROUP variable group."
		else
			echo "##vso[task.logissue type=error]Variable WEBAPP_ID was not added to the $VARIABLE_GROUP variable group."
			echo "Variable WEBAPP_ID was not added to the $VARIABLE_GROUP variable group."
		fi

		if [ -n "$WEBAPP_ID" ]; then
			WEBAPP_URL_BASE=$(echo "$WEBAPP_ID" | cut -d '/' -f 9)
			if saveVariableInVariableGroup "${VARIABLE_GROUP_ID}" "WEBAPP_URL_BASE" "$WEBAPP_URL_BASE"; then
				echo "Variable WEBAPP_URL_BASE was added to the $VARIABLE_GROUP variable group."
			else
				echo "##vso[task.logissue type=error]Variable WEBAPP_URL_BASE was not added to the $VARIABLE_GROUP variable group."
				echo "Variable WEBAPP_URL_BASE was not added to the $VARIABLE_GROUP variable group."
			fi
		fi
	elif [ "$PLATFORM" == "github" ]; then
		# Set output variables for GitHub Actions
		echo "Setting output variable for GitHub Actions"
		set_output_variable "control_plane_name" "$CONTROL_PLANE_NAME"
		set_output_variable "deployer_keyvault" "$DEPLOYER_KEYVAULT"
		set_value_with_key "TERRAFORM_REMOTE_STORAGE_ACCOUNT_NAME" "${TERRAFORM_REMOTE_STORAGE_ACCOUNT_NAME}" "env"
		if [ -n "$WEBAPP_ID" ]; then
			set_value_with_key "WEBAPP_ID" "${WEBAPP_ID}" "env"
			WEBAPP_URL_BASE=$(echo "$WEBAPP_ID" | cut -d '/' -f 9)
			set_value_with_key "WEBAPP_URL_BASE" "${WEBAPP_URL_BASE}" "env"
		fi
	fi
fi
end_group
# Platform-specific summary handling
if [ -f "$CONFIG_REPO_PATH/.sap_deployment_automation/${CONTROL_PLANE_NAME}.md" ]; then
	if [ "$PLATFORM" == "devops" ]; then
		echo "##vso[task.uploadsummary]$CONFIG_REPO_PATH/.sap_deployment_automation/${CONTROL_PLANE_NAME}.md"
	elif [ "$PLATFORM" == "github" ]; then
		cat "$CONFIG_REPO_PATH/.sap_deployment_automation/${CONTROL_PLANE_NAME}.md" >>$GITHUB_STEP_SUMMARY
	fi
fi

print_banner "$banner_title" "Exiting $SCRIPT_NAME" "info"

exit $return_code
