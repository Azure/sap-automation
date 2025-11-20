#!/bin/bash
# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

# Source the shared platform configuration
SCRIPT_DIR="$(dirname "${BASH_SOURCE[0]}")"
source "${SCRIPT_DIR}/shared_platform_config.sh"
source "${SCRIPT_DIR}/shared_functions.sh"
source "${SCRIPT_DIR}/set-colors.sh"

# Set platform-specific output
if [ "$PLATFORM" == "devops" ]; then
	echo "##vso[build.updatebuildnumber]Deploying the control plane defined in $DEPLOYER_FOLDERNAME "
fi

#External helper functions
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

# Platform-specific configuration
if [ "$PLATFORM" == "devops" ]; then
	# Configure DevOps
	configure_devops

	if ! get_variable_group_id "$VARIABLE_GROUP" "VARIABLE_GROUP_ID"; then
		echo -e "$bold_red--- Variable group $VARIABLE_GROUP not found ---$reset_formatting"
		echo "##vso[task.logissue type=error]Variable group $VARIABLE_GROUP not found."
		exit 2
	fi
	export VARIABLE_GROUP_ID
elif [ "$PLATFORM" == "github" ]; then
	# No specific variable group setup for GitHub Actions
	# Values will be stored in GitHub Environment variables
	echo "Configuring for GitHub Actions"
	export VARIABLE_GROUP_ID="${CONTROL_PLANE_NAME}"
	git config --global --add safe.directory "$CONFIG_REPO_PATH"
fi

if [ ! -v TF_VAR_ansible_core_version ]; then
	TF_VAR_ansible_core_version=2.16
	export TF_VAR_ansible_core_version
fi

cd "$CONFIG_REPO_PATH" || exit
mkdir -p .sap_deployment_automation

ENVIRONMENT=$(echo "${CONTROL_PLANE_NAME}" | awk -F'-' '{print $1}' | xargs)
LOCATION=$(echo "${CONTROL_PLANE_NAME}" | awk -F'-' '{print $2}' | xargs)
NETWORK=$(echo "${CONTROL_PLANE_NAME}" | awk -F'-' '{print $3}' | xargs)
CONFIG_DIR="${CONFIG_REPO_PATH}/.sap_deployment_automation"

automation_config_directory="${CONFIG_DIR}"

deployer_environment_file_name=$(get_configuration_file "$automation_config_directory" "$ENVIRONMENT" "$LOCATION" "$NETWORK")

DEPLOYER_FOLDERNAME="${CONTROL_PLANE_NAME}-INFRASTRUCTURE"
DEPLOYER_TFVARS_FILENAME="${CONTROL_PLANE_NAME}-INFRASTRUCTURE.tfvars"
prefix=$(echo "$CONTROL_PLANE_NAME" | cut -d '-' -f1-2)

LIBRARY_FOLDERNAME="$prefix-SAP_LIBRARY"

echo "Configuration file:                  $deployer_environment_file_name"
echo "Environment:                         $ENVIRONMENT"
echo "Location:                            $LOCATION"

if [ -f "${deployer_environment_file_name}" ]; then
	step=$(grep -m1 "^step=" "${deployer_environment_file_name}" | awk -F'=' '{print $2}' | xargs)
else
	step=0
fi

echo "Step:                                $step"

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
	configureNonDeployer "${tf_version:-1.13.3}"

	if [ "$PLATFORM" == "devops" ]; then
		ARM_CLIENT_ID="${servicePrincipalId:-$ARM_CLIENT_ID}"
		export ARM_CLIENT_ID
		TF_VAR_spn_id=$ARM_CLIENT_ID
		export TF_VAR_spn_id

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

	if [ -v tenantId ]; then
		# If tenantId is set, use it
		ARM_TENANT_ID="${tenantId}"
	else
		# Otherwise, use the default ARM_TENANT_ID
		ARM_TENANT_ID=$(az account show --query tenantId -o tsv)
	fi
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
	if [ -n "${ARM_CLIENT_ID}" ]; then
		if [ "$PLATFORM" == "github" ]; then
			saveVariableInVariableGroup "${VARIABLE_GROUP_ID}" "ARM_CLIENT_ID" "$ARM_CLIENT_ID"
		fi
	fi
fi

if [ "${USE_MSI:-false}" != "true" ]; then

	# Get SPN ID differently per platform
	if [ "$PLATFORM" == "devops" ]; then
		TF_VAR_spn_id=$(getVariableFromVariableGroup "${VARIABLE_GROUP_ID}" "ARM_OBJECT_ID" "${deployer_environment_file_name}" "ARM_OBJECT_ID")
	elif [ "$PLATFORM" == "github" ]; then
		# Use value from env or from GitHub environment
		TF_VAR_spn_id=${ARM_OBJECT_ID:-$TF_VAR_spn_id}
	fi

	if is_valid_guid "$TF_VAR_spn_id"; then
		export TF_VAR_spn_id
		echo "Service Principal Object id:         $TF_VAR_spn_id"
	fi
fi

# Reset the account if sourcing was done
if [ -v ARM_SUBSCRIPTION_ID ]; then
	az account set --subscription "$ARM_SUBSCRIPTION_ID"
	echo "Deployer subscription:               $ARM_SUBSCRIPTION_ID"
fi

TF_VAR_management_subscription_id=$ARM_SUBSCRIPTION_ID
export TF_VAR_management_subscription_id

TF_VAR_subscription_id=$ARM_SUBSCRIPTION_ID
export TF_VAR_subscription_id

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

start_group "Finalize the control plane removal"
cd "${CONFIG_REPO_PATH}/DEPLOYER/$DEPLOYER_FOLDERNAME" || exit
# Remove the control plane

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

end_group

start_group "Update the repository"

echo -e "$green--- Remove Control Plane Part 2 ---$reset"

cd "$CONFIG_REPO_PATH" || exit

# Pull changes if there are other deployment jobs
if [ "$PLATFORM" == "devops" ]; then
	git pull -q origin "$BUILD_SOURCEBRANCHNAME"
	git checkout -q "$BUILD_SOURCEBRANCHNAME"
elif [ "$PLATFORM" == "github" ]; then
	git pull -q origin "$GITHUB_REF_NAME"
fi

changed=0
environment=$(echo "$CONTROL_PLANE_NAME" | cut -d"-" -f1)
region_code=$(echo "$CONTROL_PLANE_NAME" | cut -d"-" -f2)

if [ -f ".sap_deployment_automation/${environment}${region_code}" ]; then
	rm ".sap_deployment_automation/${environment}${region_code}"
	git rm -q --ignore-unmatch ".sap_deployment_automation/${environment}${region_code}"
	changed=1
fi

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

if [ 0 == $return_code ]; then
	if [ -f "DEPLOYER/$DEPLOYER_FOLDERNAME/state.zip" ]; then
		git rm -q -f --ignore-unmatch "DEPLOYER/$DEPLOYER_FOLDERNAME/state.zip"
		changed=1
	fi
	if [ -f "DEPLOYER/$DEPLOYER_FOLDERNAME/state.gpg" ]; then
		git rm -q -f --ignore-unmatch "DEPLOYER/$DEPLOYER_FOLDERNAME/state.gpg"
		changed=1
	fi
	if [ -f "LIBRARY/$LIBRARY_FOLDERNAME/state.zip" ]; then
		if [ 0 == $return_code ]; then
			echo "Removing the library state zip file"
			git rm -q --ignore-unmatch -f "LIBRARY/$LIBRARY_FOLDERNAME/state.zip"
			changed=1
		fi
	fi
	if [ -f "LIBRARY/$LIBRARY_FOLDERNAME/state.gpg" ]; then
		if [ 0 == $return_code ]; then
			echo "Removing the library state gpg file"
			git rm -q --ignore-unmatch -f "LIBRARY/$LIBRARY_FOLDERNAME/state.gpg"
			changed=1
		fi
	fi

	if [ -d "LIBRARY/$LIBRARY_FOLDERNAME/terraform.tfstate" ]; then
		git rm -q -r --ignore-unmatch "LIBRARY/$LIBRARY_FOLDERNAME/terraform.tfstate"
		changed=1
	fi

	if [ -f "LIBRARY/$LIBRARY_FOLDERNAME/state.zip" ]; then
		git rm -q -f --ignore-unmatch "LIBRARY/$LIBRARY_FOLDERNAME/state.zip"
		changed=1
	fi

	if [ -d "LIBRARY/$LIBRARY_FOLDERNAME/.terraform" ]; then
		git rm -q -r --ignore-unmatch "LIBRARY/$LIBRARY_FOLDERNAME/.terraform"
		changed=1
	fi

fi
if [ -f "$deployer_environment_file_name" ]; then
	rm "$deployer_environment_file_name"
	git rm -q --ignore-unmatch "$deployer_environment_file_name"
	changed=1
fi

if [ -f ".sap_deployment_automation/${CONTROL_PLANE_NAME}.md" ]; then
	rm ".sap_deployment_automation/${CONTROL_PLANE_NAME}.md"
	git rm -q --ignore-unmatch ".sap_deployment_automation/${CONTROL_PLANE_NAME}.md"
	changed=1
fi

# Commit changes based on platform
if [ 1 == $changed ]; then
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
	fi
fi
end_group
if [ "$PLATFORM" == "devops" ]; then
	echo -e "$green--- Deleting variables ---$reset"
	if [ -n "$VARIABLE_GROUP_ID" ]; then
		echo "Deleting variables"

		remove_variable "$VARIABLE_GROUP_ID" "APPLICATION_CONFIGURATION_DEPLOYMENT"
		remove_variable "$VARIABLE_GROUP_ID" "APPLICATION_CONFIGURATION_ID"
		remove_variable "$VARIABLE_GROUP_ID" "APPLICATION_CONFIGURATION_NAME"
		remove_variable "$VARIABLE_GROUP_ID" "APPSERVICE_NAME"
		remove_variable "$VARIABLE_GROUP_ID" "APP_SERVICE_DEPLOYMENT"
		remove_variable "$VARIABLE_GROUP_ID" "APP_SERVICE_NAME"
		remove_variable "$VARIABLE_GROUP_ID" "CONTROL_PLANE_ENVIRONMENT"
		remove_variable "$VARIABLE_GROUP_ID" "CONTROL_PLANE_LOCATION"
		remove_variable "$VARIABLE_GROUP_ID" "DEPLOYER_KEYVAULT"
		remove_variable "$VARIABLE_GROUP_ID" "DEPLOYER_RANDOM_ID"
		remove_variable "$VARIABLE_GROUP_ID" "Deployer_Key_Vault"
		remove_variable "$VARIABLE_GROUP_ID" "Deployer_State_FileName"
		remove_variable "$VARIABLE_GROUP_ID" "HAS_APPSERVICE_DEPLOYED"
		remove_variable "$VARIABLE_GROUP_ID" "INSTALLATION_MEDIA_ACCOUNT"
		remove_variable "$VARIABLE_GROUP_ID" "LIBRARY_RANDOM_ID"
		remove_variable "$VARIABLE_GROUP_ID" "TERRAFORM_REMOTE_STORAGE_ACCOUNT_NAME"
		remove_variable "$VARIABLE_GROUP_ID" "TERRAFORM_REMOTE_STORAGE_SUBSCRIPTION"
		remove_variable "$VARIABLE_GROUP_ID" "Terraform_Remote_Storage_Account_Name"
		remove_variable "$VARIABLE_GROUP_ID" "Terraform_Remote_Storage_Resource_Group_Name"
		remove_variable "$VARIABLE_GROUP_ID" "Terraform_Remote_Storage_Subscription"
		remove_variable "$VARIABLE_GROUP_ID" "WEBAPP_ID"
		remove_variable "$VARIABLE_GROUP_ID" "WEBAPP_IDENTITY"
		remove_variable "$VARIABLE_GROUP_ID" "WEBAPP_RESOURCE_GROUP"
	fi
fi

exit $return_code
