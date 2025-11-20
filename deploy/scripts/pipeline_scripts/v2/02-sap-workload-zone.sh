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
	echo "##vso[build.updatebuildnumber]Deploying the SAP Workload zone defined in $WORKLOAD_ZONE_FOLDERNAME"
fi

# External helper functions
#. "$(dirname "${BASH_SOURCE[0]}")/deploy_utils.sh"
full_script_path="$(realpath "${BASH_SOURCE[0]}")"
script_directory="$(dirname "${full_script_path}")"
parent_directory="$(dirname "$script_directory")"
grand_parent_directory="$(dirname "$parent_directory")"
#call stack has full script name when using source
# shellcheck disable=SC1091
source "${grand_parent_directory}/deploy_utils.sh"
source "${parent_directory}/helper.sh"

SCRIPT_NAME="$(basename "$0")"

tfvarsFile="$CONFIG_REPO_PATH/LANDSCAPE/$WORKLOAD_ZONE_NAME-INFRASTRUCTURE/${WORKLOAD_ZONE_NAME}-INFRASTRUCTURE.tfvars"

ENVIRONMENT=$(grep -m1 "^environment" "$tfvarsFile" | awk -F'=' '{print $2}' | tr -d ' \t\n\r\f"')
LOCATION=$(grep -m1 "^location" "$tfvarsFile" | awk -F'=' '{print $2}' | tr '[:upper:]' '[:lower:]' | tr -d ' \t\n\r\f"')
NETWORK=$(grep -m1 "^network_logical_name" "$tfvarsFile" | awk -F'=' '{print $2}' | tr -d ' \t\n\r\f"')

ENVIRONMENT_IN_FILENAME=$(echo "$WORKLOAD_ZONE_NAME" | awk -F'-' '{print $1}')
LOCATION_CODE_IN_FILENAME=$(echo "$WORKLOAD_ZONE_NAME" | awk -F'-' '{print $2}')
LOCATION_IN_FILENAME=$(get_region_from_code "$LOCATION_CODE_IN_FILENAME" || true)
NETWORK_IN_FILENAME=$(echo "$WORKLOAD_ZONE_NAME" | awk -F'-' '{print $3}')

automation_config_directory="$CONFIG_REPO_PATH/.sap_deployment_automation/"
workload_environment_file_name=$(get_configuration_file "${automation_config_directory}" "${ENVIRONMENT_IN_FILENAME}" "${LOCATION_CODE_IN_FILENAME}" "${NETWORK_IN_FILENAME}")
SYSTEM_CONFIGURATION_FILE="$workload_environment_file_name"
export SYSTEM_CONFIGURATION_FILE

separator="-"
if [[ "$CONTROL_PLANE_NAME" == *"$separator"* ]]; then
	DEPLOYER_ENVIRONMENT_IN_FILENAME=$(echo $CONTROL_PLANE_NAME | awk -F'-' '{print $1}')
	DEPLOYER_LOCATION_CODE_IN_FILENAME=$(echo $CONTROL_PLANE_NAME | awk -F'-' '{print $2}')
	DEPLOYER_NETWORK_IN_FILENAME=$(echo $CONTROL_PLANE_NAME | awk -F'-' '{print $3}')
	deployer_environment_file_name=$(get_configuration_file "${automation_config_directory}" "${DEPLOYER_ENVIRONMENT_IN_FILENAME}" "${DEPLOYER_LOCATION_CODE_IN_FILENAME}" "${DEPLOYER_NETWORK_IN_FILENAME}")
else
	deployer_environment_file_name=$(get_configuration_file "${automation_config_directory}" "${DEPLOYER_ENVIRONMENT}" "${LOCATION_CODE_IN_FILENAME}" "")
fi

if [ ! -f "${deployer_environment_file_name}" ]; then
	echo -e "$bold_red--- $deployer_environment_file_name was not found ---$reset"
	echo "##vso[task.logissue type=error]Control plane configuration file $deployer_environment_file_name was not found."
	exit 2
else
	echo "Deployer Environment File:           $deployer_environment_file_name"
fi

echo "Workload Zone Environment File:      $workload_environment_file_name"
touch "$workload_environment_file_name"

# Print the execution environment details
print_header
echo ""

# Platform-specific configuration
if [ "$PLATFORM" == "devops" ]; then

	echo "##vso[build.updatebuildnumber]Deploying the SAP Workload zone defined in $WORKLOAD_ZONE_FOLDERNAME"

	# Configure DevOps
	configure_devops

	platform_flag="--ado"

	if ! get_variable_group_id "$VARIABLE_GROUP" "VARIABLE_GROUP_ID"; then
		echo -e "$bold_red--- Variable group $VARIABLE_GROUP not found ---$reset_formatting"
		echo "##vso[task.logissue type=error]Variable group $VARIABLE_GROUP not found."
		exit 2
	fi
	export VARIABLE_GROUP_ID
	if saveVariableInVariableGroup "${VARIABLE_GROUP_ID}" "CONTROL_PLANE_NAME" "$CONTROL_PLANE_NAME"; then
		echo "Variable CONTROL_PLANE_NAME was added to the $VARIABLE_GROUP variable group."
	else
		echo "##vso[task.logissue type=error]Variable CONTROL_PLANE_NAME was not added to the $VARIABLE_GROUP variable group."
		echo "Variable CONTROL_PLANE_NAME was not added to the $VARIABLE_GROUP variable group."
	fi

	if ! get_variable_group_id "$PARENT_VARIABLE_GROUP" "PARENT_VARIABLE_GROUP_ID"; then
		echo -e "$bold_red--- Variable group $PARENT_VARIABLE_GROUP not found ---$reset"
		echo "##vso[task.logissue type=error]Variable group $PARENT_VARIABLE_GROUP not found."
		exit 2
	fi
	export PARENT_VARIABLE_GROUP_ID
	TERRAFORM_REMOTE_STORAGE_SUBSCRIPTION=$(getVariableFromVariableGroup "${PARENT_VARIABLE_GROUP_ID}" "TERRAFORM_REMOTE_STORAGE_SUBSCRIPTION" "${deployer_environment_file_name}" "REMOTE_STATE_SA")
	if saveVariableInVariableGroup "${VARIABLE_GROUP_ID}" "TERRAFORM_REMOTE_STORAGE_SUBSCRIPTION" "$TERRAFORM_REMOTE_STORAGE_SUBSCRIPTION"; then
		echo "Variable TERRAFORM_REMOTE_STORAGE_SUBSCRIPTION was added to the $VARIABLE_GROUP variable group."
	else
		echo "##vso[task.logissue type=error]Variable TERRAFORM_REMOTE_STORAGE_SUBSCRIPTION was not added to the $VARIABLE_GROUP variable group."
		echo "Variable TERRAFORM_REMOTE_STORAGE_SUBSCRIPTION was not added to the $VARIABLE_GROUP variable group."
	fi

	TERRAFORM_REMOTE_STORAGE_ACCOUNT_NAME=$(getVariableFromVariableGroup "${PARENT_VARIABLE_GROUP_ID}" "TERRAFORM_REMOTE_STORAGE_ACCOUNT_NAME" "${deployer_environment_file_name}" "ARM_SUBSCRIPTION_ID")
	if saveVariableInVariableGroup "${VARIABLE_GROUP_ID}" "TERRAFORM_REMOTE_STORAGE_ACCOUNT_NAME" "$TERRAFORM_REMOTE_STORAGE_ACCOUNT_NAME"; then
		echo "Variable TERRAFORM_REMOTE_STORAGE_ACCOUNT_NAME was added to the $VARIABLE_GROUP variable group."
	else
		echo "##vso[task.logissue type=error]Variable TERRAFORM_REMOTE_STORAGE_ACCOUNT_NAME was not added to the $VARIABLE_GROUP variable group."
		echo "Variable TERRAFORM_REMOTE_STORAGE_ACCOUNT_NAME was not added to the $VARIABLE_GROUP variable group."
	fi

elif [ "$PLATFORM" == "github" ]; then
	# No specific variable group setup for GitHub Actions
	# Values will be stored in GitHub Environment variables
	echo "Configuring for GitHub Actions"
	export VARIABLE_GROUP_ID="${WORKLOAD_ZONE_NAME}"
	git config --global --add safe.directory "$CONFIG_REPO_PATH"
	platform_flag="--github"
else
	platform_flag=""
fi

if [ ! -v APPLICATION_CONFIGURATION_ID ]; then
	APPLICATION_CONFIGURATION_ID=$(az graph query -q "Resources | join kind=leftouter (ResourceContainers | where type=='microsoft.resources/subscriptions' | project subscription=name, subscriptionId) on subscriptionId | where name == '$APPLICATION_CONFIGURATION_NAME' | project id, name, subscription" --query data[0].id --output tsv)
	export APPLICATION_CONFIGURATION_ID
fi

banner_title="Deploy Workload Zone"

print_banner "$banner_title" "Starting $SCRIPT_NAME" "info"

echo -e "$cyan tfvarsFile: $tfvarsFile $reset"

cd "${CONFIG_REPO_PATH}" || exit
mkdir -p .sap_deployment_automation
# Platform-specific git checkout
if [ "$PLATFORM" == "devops" ]; then
	echo -e "$green--- Checkout $BUILD_SOURCEBRANCHNAME ---$reset_formatting"
	git checkout -q "$BUILD_SOURCEBRANCHNAME"
elif [ "$PLATFORM" == "github" ]; then
	echo -e "$green--- Checkout $GITHUB_REF_NAME ---$reset_formatting"
	git checkout -q "$GITHUB_REF_NAME"
fi

if [ ! -f "$tfvarsFile" ]; then
	echo -e "$bold_red--- $$WORKLOAD_ZONE_NAME-INFRASTRUCTURE/${WORKLOAD_ZONE_NAME}-INFRASTRUCTURE.tfvars was not found ---$reset"
	if [ "$PLATFORM" == "devops" ]; then
		echo "##vso[task.logissue type=error]File $WORKLOAD_ZONE_NAME-INFRASTRUCTURE/${WORKLOAD_ZONE_NAME}-INFRASTRUCTURE.tfvars was not found."
	fi

	exit 2
fi

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

APPLICATION_CONFIGURATION_SUBSCRIPTION_ID=$(echo "$APPLICATION_CONFIGURATION_ID" | cut -d '/' -f 3)
export APPLICATION_CONFIGURATION_SUBSCRIPTION_ID

az account set --subscription "$ARM_SUBSCRIPTION_ID"

deployer_tfstate_key="${CONTROL_PLANE_NAME}.terraform.tfstate"
export deployer_tfstate_key

landscape_tfstate_key="${WORKLOAD_ZONE_NAME}-INFRASTRUCTURE.terraform.tfstate"
export landscape_tfstate_key

# Validate folder name components match tfvars file settings
if [ "$ENVIRONMENT" != "$ENVIRONMENT_IN_FILENAME" ]; then
	print_banner "$banner_title" "Environment mismatch" "error" "The environment setting in the tfvars file is not a part of the ${WORKLOAD_ZONE_NAME}-INFRASTRUCTURE.tfvars file name" "Filename should have the pattern [ENVIRONMENT]-[REGION_CODE]-[NETWORK_LOGICAL_NAME]-INFRASTRUCTURE"
	if [ "$PLATFORM" == "devops" ]; then
		echo "##vso[task.logissue type=error]The environment setting in ${WORKLOAD_ZONE_NAME}-INFRASTRUCTURE.tfvars '$ENVIRONMENT' does not match the ${WORKLOAD_ZONE_NAME}-INFRASTRUCTURE.tfvars file name '$ENVIRONMENT_IN_FILENAME'. Filename should have the pattern [ENVIRONMENT]-[REGION_CODE]-[NETWORK_LOGICAL_NAME]-INFRASTRUCTURE"
	fi
	exit 2
fi

if [ "$LOCATION" != "$LOCATION_IN_FILENAME" ]; then
	print_banner "$banner_title" "Location mismatch" "error" "The 'location' setting in the tfvars file is not represented in the ${WORKLOAD_ZONE_NAME}-INFRASTRUCTURE.tfvars file name" "Filename should have the pattern [ENVIRONMENT]-[REGION_CODE]-[NETWORK_LOGICAL_NAME]-INFRASTRUCTURE"
	if [ "$PLATFORM" == "devops" ]; then
		echo "##vso[task.logissue type=error]The location setting in ${WORKLOAD_ZONE_NAME}-INFRASTRUCTURE.tfvars '$LOCATION' does not match the ${WORKLOAD_ZONE_NAME}-INFRASTRUCTURE.tfvars file name '$LOCATION_IN_FILENAME'. Filename should have the pattern [ENVIRONMENT]-[REGION_CODE]-[NETWORK_LOGICAL_NAME]-INFRASTRUCTURE"
	fi
	exit 2
fi

if [ "$NETWORK" != "$NETWORK_IN_FILENAME" ]; then
	print_banner "$banner_title" "Naming mismatch" "error" "The 'network_logical_name' setting in the tfvars file is not a part of the $WORKLOAD_ZONE_TFVARS_FILENAME file name" "Filename should have the pattern [ENVIRONMENT]-[REGION_CODE]-[NETWORK_LOGICAL_NAME]-INFRASTRUCTURE"
	if [ "$PLATFORM" == "devops" ]; then
		echo "##vso[task.logissue type=error]The network_logical_name setting in $WORKLOAD_ZONE_TFVARS_FILENAME '$NETWORK' does not match the $WORKLOAD_ZONE_TFVARS_FILENAME file name '$NETWORK_IN_FILENAME-. Filename should have the pattern [ENVIRONMENT]-[REGION_CODE]-[NETWORK_LOGICAL_NAME]-INFRASTRUCTURE"
	fi
	exit 2
fi

if is_valid_id "$APPLICATION_CONFIGURATION_ID" "/providers/Microsoft.AppConfiguration/configurationStores/"; then
	application_configuration_name=$(echo "$APPLICATION_CONFIGURATION_ID" | cut -d '/' -f 9)

	TF_VAR_management_subscription_id=$(getVariableFromApplicationConfiguration "$APPLICATION_CONFIGURATION_ID" "${CONTROL_PLANE_NAME}_SubscriptionId" "${CONTROL_PLANE_NAME}")
	export TF_VAR_management_subscription_id

	tfstate_resource_id=$(getVariableFromApplicationConfiguration "$APPLICATION_CONFIGURATION_ID" "${CONTROL_PLANE_NAME}_TerraformRemoteStateStorageAccountId" "${CONTROL_PLANE_NAME}")
else
	if [ "$PLATFORM" == "devops" ]; then
		echo "##vso[task.logissue type=warning]Variable APPLICATION_CONFIGURATION_ID was not defined."
	elif [ "$PLATFORM" == "github" ]; then
		echo "Variable APPLICATION_CONFIGURATION_ID was not defined."
	fi
	load_config_vars "${workload_environment_file_name}" "tfstate_resource_id"
	load_config_vars "${deployer_environment_file_name}" "subscription"
	TF_VAR_management_subscription_id="$subscription"
	export TF_VAR_management_subscription_id

fi

if [ -z "$tfstate_resource_id" ]; then
	if [ "$PLATFORM" == "devops" ]; then
		echo "##vso[task.logissue type=error]Terraform state storage account resource id ('${CONTROL_PLANE_NAME}_TerraformRemoteStateStorageAccountId') was not found in the application configuration ( '$application_configuration_name' nor was it defined in ${workload_environment_file_name})."
	elif [ "$PLATFORM" == "github" ]; then
		echo "Terraform state storage account resource id ('${CONTROL_PLANE_NAME}_TerraformRemoteStateStorageAccountId') was not found in the application configuration ( '$application_configuration_name' nor was it defined in ${workload_environment_file_name})."
	fi
	exit 2
fi

terraform_storage_account_name=$(echo "$tfstate_resource_id" | cut -d '/' -f 9)
terraform_storage_account_resource_group_name=$(echo "$tfstate_resource_id" | cut -d '/' -f 5)
terraform_storage_account_subscription_id=$(echo "$tfstate_resource_id" | cut -d '/' -f 3)

export terraform_storage_account_name
export terraform_storage_account_resource_group_name
export terraform_storage_account_subscription_id
export tfstate_resource_id

cd "$CONFIG_REPO_PATH/LANDSCAPE/${WORKLOAD_ZONE_NAME}-INFRASTRUCTURE" || exit
print_banner "$banner_title" "Starting the deployment" "info"

if "$SAP_AUTOMATION_REPO_PATH/deploy/scripts/installer_v2.sh" --parameter_file "${WORKLOAD_ZONE_NAME}-INFRASTRUCTURE.tfvars" \
	--type sap_landscape --control_plane_name "${CONTROL_PLANE_NAME}" --application_configuration_name "${APPLICATION_CONFIGURATION_NAME}" \
	"${platform_flag}" --storage_accountname "${terraform_storage_account_name}" --auto-approve; then
	return_code=$?
	print_banner "$banner_title" "Deployment of $WORKLOAD_ZONE_NAME succeeded" "success"
else
	return_code=$?
	print_banner "$banner_title" "Deployment of $WORKLOAD_ZONE_NAME failed" "error"

	if [ "$PLATFORM" == "devops" ]; then
		echo "##vso[task.logissue type=error]Terraform apply failed."
	else
		echo "ERROR: Terraform apply failed."
	fi
fi
echo "Return code from deployment:         ${return_code}"

if [ -f "${workload_environment_file_name}" ]; then
	KEYVAULT=$(grep -m1 "^workloadkeyvault=" "${workload_environment_file_name}" | awk -F'=' '{print $2}' | xargs || true)
	echo "Key Vault:                  ${KEYVAULT}"

	if [ "$PLATFORM" == "devops" ]; then

		if [ -n "$KEYVAULT" ]; then
			echo -e "$green--- Adding variables to the variable group: $VARIABLE_GROUP ---$reset"
			saveVariableInVariableGroup "${VARIABLE_GROUP_ID}" "KEYVAULT" "$KEYVAULT"
		fi
	fi

fi

set +o errexit

echo -e "$green--- Pushing the changes to the repository ---$reset"
# Pull changes if there are other deployment jobs
# Pull changes if there are other deployment jobs
if [ "$PLATFORM" == "devops" ]; then
	git pull -q origin "$BUILD_SOURCEBRANCHNAME"
	git checkout -q "$BUILD_SOURCEBRANCHNAME"
elif [ "$PLATFORM" == "github" ]; then
	git pull -q origin "$GITHUB_REF_NAME"
fi

added=0

if [ -f .terraform/terraform.tfstate ]; then
	git add -f .terraform/terraform.tfstate
	added=1
fi

if [ -f "${workload_environment_file_name}" ]; then
	git add "${workload_environment_file_name}"
	added=1
fi

if [ -f "$tfvarsFile" ]; then
	git add "$tfvarsFile"
	added=1
fi

# Commit changes based on platform
if [ 1 = $added ]; then
	if [ "$PLATFORM" == "devops" ]; then
		git config --global user.email "$BUILD_REQUESTEDFOREMAIL"
		git config --global user.name "$BUILD_REQUESTEDFOR"
		commit_message="Added updates from Workload Zone Deployment for $WORKLOAD_ZONE_NAME $BUILD_BUILDNUMBER [skip ci]"
	elif [ "$PLATFORM" == "github" ]; then
		git config --global user.email "github-actions@github.com"
		git config --global user.name "GitHub Actions"
		commit_message="Added updates from Workload Zone Deployment for $WORKLOAD_ZONE_NAME [skip ci]"
	else
		git config --global user.email "local@example.com"
		git config --global user.name "Local User"
		commit_message="Added updates from Workload Zone Deployment for $WORKLOAD_ZONE_NAME [skip ci]"
	fi

	if [ "${DEBUG:-False}" = "True" ]; then
		git status --verbose
		if git commit -m "$commit_message"; then
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
		if git commit -m "$commit_message"; then
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

# Add summary if available
if [ -f "$CONFIG_REPO_PATH/.sap_deployment_automation/${WORKLOAD_ZONE_NAME}.md" ]; then
	if [ "$PLATFORM" == "devops" ]; then
		echo "##vso[task.uploadsummary]$CONFIG_REPO_PATH/.sap_deployment_automation/${WORKLOAD_ZONE_NAME}.md"
	elif [ "$PLATFORM" == "github" ]; then
		cat "$CONFIG_REPO_PATH/.sap_deployment_automation/${WORKLOAD_ZONE_NAME}.md" >>$GITHUB_STEP_SUMMARY
	fi
fi

print_banner "$banner_title" "Exiting $SCRIPT_NAME" "info"

exit $return_code
