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
	echo "##vso[build.updatebuildnumber]Deploying the SAP System defined in $SAP_SYSTEM_FOLDERNAME"
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

WORKLOAD_ZONE_NAME=$(echo "$SAP_SYSTEM_FOLDERNAME" | cut -d'-' -f1-3)
workload_environment_file_name="$CONFIG_REPO_PATH/.sap_deployment_automation/$WORKLOAD_ZONE_NAME"

# Print the execution environment details
print_header
echo ""

# Platform-specific configuration
if [ "$PLATFORM" == "devops" ]; then
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

banner_title="Deploy SAP System"

print_banner "$banner_title" "Starting $SCRIPT_NAME" "info"

tfvarsFile="SYSTEM/$SAP_SYSTEM_FOLDERNAME/$SAP_SYSTEM_TFVARS_FILENAME"

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

if [ ! -f "$CONFIG_REPO_PATH/$tfvarsFile" ]; then
	print_banner "$banner_title" "$SAP_SYSTEM_TFVARS_FILENAME was not found" "error"
	if [ "$PLATFORM" == "devops" ]; then
		echo "##vso[task.logissue type=error]File $SAP_SYSTEM_TFVARS_FILENAME was not found."
		exit 2
	elif [ "$PLATFORM" == "github" ]; then
		echo "File $SAP_SYSTEM_TFVARS_FILENAME was not found."
		exit 2
	fi
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
if [ ! -v APPLICATION_CONFIGURATION_ID ]; then
	APPLICATION_CONFIGURATION_ID=$(az graph query -q "Resources | join kind=leftouter (ResourceContainers | where type=='microsoft.resources/subscriptions' | project subscription=name, subscriptionId) on subscriptionId | where name == '$APPLICATION_CONFIGURATION_NAME' | project id, name, subscription" --query data[0].id --output tsv)
	export APPLICATION_CONFIGURATION_ID
fi

APPLICATION_CONFIGURATION_SUBSCRIPTION_ID=$(echo "$APPLICATION_CONFIGURATION_ID" | cut -d '/' -f 3)
export APPLICATION_CONFIGURATION_SUBSCRIPTION_ID

az account set --subscription "$ARM_SUBSCRIPTION_ID"

ENVIRONMENT=$(grep -m1 "^environment" "$tfvarsFile" | awk -F'=' '{print $2}' | tr -d ' \t\n\r\f"')
LOCATION=$(grep -m1 "^location" "$tfvarsFile" | awk -F'=' '{print $2}' | tr '[:upper:]' '[:lower:]' | tr -d ' \t\n\r\f"')
NETWORK=$(grep -m1 "^network_logical_name" "$tfvarsFile" | awk -F'=' '{print $2}' | tr -d ' \t\n\r\f"')
SID=$(grep -m1 "^sid" "$tfvarsFile" | awk -F'=' '{print $2}' | tr -d ' \t\n\r\f"')

ENVIRONMENT_IN_FILENAME=$(echo $SAP_SYSTEM_FOLDERNAME | awk -F'-' '{print $1}')
LOCATION_CODE_IN_FILENAME=$(echo $SAP_SYSTEM_FOLDERNAME | awk -F'-' '{print $2}')
LOCATION_IN_FILENAME=$(get_region_from_code "$LOCATION_CODE_IN_FILENAME" || true)
NETWORK_IN_FILENAME=$(echo $SAP_SYSTEM_FOLDERNAME | awk -F'-' '{print $3}')
SID_IN_FILENAME=$(echo $SAP_SYSTEM_FOLDERNAME | awk -F'-' '{print $4}')

WORKLOAD_ZONE_NAME=$(echo "$SAP_SYSTEM_FOLDERNAME" | cut -d'-' -f1-3)
landscape_tfstate_key="${WORKLOAD_ZONE_NAME}-INFRASTRUCTURE.terraform.tfstate"
export landscape_tfstate_key
workload_environment_file_name="$CONFIG_REPO_PATH/.sap_deployment_automation/$WORKLOAD_ZONE_NAME"

deployer_tfstate_key=$CONTROL_PLANE_NAME.terraform.tfstate
export deployer_tfstate_key

echo ""
echo -e "${green}Deployment details:"
echo -e "-------------------------------------------------------------------------------$reset"

echo "CONTROL_PLANE_NAME:                  $CONTROL_PLANE_NAME"
echo "WORKLOAD_ZONE_NAME:                  $WORKLOAD_ZONE_NAME"
echo "Workload Zone Environment File:      $workload_environment_file_name"

echo "Environment:                         $ENVIRONMENT"
echo "Environment(filename):               $ENVIRONMENT_IN_FILENAME"
echo "Location:                            $LOCATION"
echo "Location(filename):                  $LOCATION_IN_FILENAME"
echo "Network:                             $NETWORK"
echo "Network(filename):                   $NETWORK_IN_FILENAME"
echo "SID:                                 $SID"
echo "SID(filename):                       $SID_IN_FILENAME"

if [ "$ENVIRONMENT" != "$ENVIRONMENT_IN_FILENAME" ]; then
	if [ "$PLATFORM" == "devops" ]; then
		echo "##vso[task.logissue type=error]The environment setting in $SAP_SYSTEM_TFVARS_FILENAME '$ENVIRONMENT' does not match the $SAP_SYSTEM_TFVARS_FILENAME file name '$ENVIRONMENT_IN_FILENAME'. Filename should have the pattern [ENVIRONMENT]-[REGION_CODE]-[NETWORK_LOGICAL_NAME]-INFRASTRUCTURE"
	elif [ "$PLATFORM" == "github" ]; then
		echo "::error title=Environment Mismatch::The environment setting in $SAP_SYSTEM_TFVARS_FILENAME '$ENVIRONMENT' does not match the $SAP_SYSTEM_TFVARS_FILENAME file name '$ENVIRONMENT_IN_FILENAME'. Filename should have the pattern [ENVIRONMENT]-[REGION_CODE]-[NETWORK_LOGICAL_NAME]-INFRASTRUCTURE"
	fi
	exit 2
fi

if [ "$LOCATION" != "$LOCATION_IN_FILENAME" ]; then
	if [ "$PLATFORM" == "devops" ]; then
		echo "##vso[task.logissue type=error]The location setting in $SAP_SYSTEM_TFVARS_FILENAME '$LOCATION' does not match the $SAP_SYSTEM_TFVARS_FILENAME file name '$LOCATION_IN_FILENAME'. Filename should have the pattern [ENVIRONMENT]-[REGION_CODE]-[NETWORK_LOGICAL_NAME]-INFRASTRUCTURE"
	elif [ "$PLATFORM" == "github" ]; then
		echo "::error title=Location Mismatch::The location setting in $SAP_SYSTEM_TFVARS_FILENAME '$LOCATION' does not match the $SAP_SYSTEM_TFVARS_FILENAME file name '$LOCATION_IN_FILENAME'. Filename should have the pattern [ENVIRONMENT]-[REGION_CODE]-[NETWORK_LOGICAL_NAME]-INFRASTRUCTURE"
	fi
	exit 2
fi

if [ "$NETWORK" != "$NETWORK_IN_FILENAME" ]; then
	if [ "$PLATFORM" == "devops" ]; then
		echo "##vso[task.logissue type=error]The network_logical_name setting in $SAP_SYSTEM_TFVARS_FILENAME '$NETWORK' does not match the $SAP_SYSTEM_TFVARS_FILENAME file name '$NETWORK_IN_FILENAME'. Filename should have the pattern [ENVIRONMENT]-[REGION_CODE]-[NETWORK_LOGICAL_NAME]-INFRASTRUCTURE"
	elif [ "$PLATFORM" == "github" ]; then
		echo "::error title=Network Name Mismatch::The network_logical_name setting in $SAP_SYSTEM_TFVARS_FILENAME '$NETWORK' does not match the $SAP_SYSTEM_TFVARS_FILENAME file name '$NETWORK_IN_FILENAME'. Filename should have the pattern [ENVIRONMENT]-[REGION_CODE]-[NETWORK_LOGICAL_NAME]-INFRASTRUCTURE"
	fi
	exit 2
fi

if [ "$SID" != "$SID_IN_FILENAME" ]; then
	if [ "$PLATFORM" == "devops" ]; then
		echo "##vso[task.logissue type=error]The sid setting in $SAP_SYSTEM_TFVARS_FILENAME '$SID' does not match the $SAP_SYSTEM_TFVARS_FILENAME file name '$SID_IN_FILENAME'. Filename should have the pattern [ENVIRONMENT]-[REGION_CODE]-[NETWORK_LOGICAL_NAME]-[SID]"
	elif [ "$PLATFORM" == "github" ]; then
		echo "::error title=SID Mismatch::The sid setting in $SAP_SYSTEM_TFVARS_FILENAME '$SID' does not match the $SAP_SYSTEM_TFVARS_FILENAME file name '$SID_IN_FILENAME'. Filename should have the pattern [ENVIRONMENT]-[REGION_CODE]-[NETWORK_LOGICAL_NAME]-[SID]"
	fi
	exit 2
fi

if is_valid_id "$APPLICATION_CONFIGURATION_ID" "/providers/Microsoft.AppConfiguration/configurationStores/"; then
  ZONE="${CONTROL_PLANE_NAME}"
	export ZONE
	tfstate_resource_id=$(get_value_with_key "${CONTROL_PLANE_NAME}_TerraformRemoteStateStorageAccountId")
	key_vault_id=$(get_value_with_key "${CONTROL_PLANE_NAME}_KeyVaultResourceId")
	key_vault=$(echo "$key_vault_id" | cut -d '/' -f 9)

	workload_key_vault=$(getVariableFromApplicationConfiguration "$APPLICATION_CONFIGURATION_ID" "${WORKLOAD_ZONE_NAME}_KeyVaultName" "${WORKLOAD_ZONE_NAME}")

	management_subscription_id=$(get_value_with_key "${CONTROL_PLANE_NAME}_SubscriptionId")
	TF_VAR_management_subscription_id=${management_subscription_id}
	export TF_VAR_management_subscription_id
else
	if [ "$PLATFORM" == "devops" ]; then
		echo "##vso[task.logissue type=warning]Variable APPLICATION_CONFIGURATION_ID was not defined."
	else
		echo "::warning title=Application Configuration ID Not Defined::Variable APPLICATION_CONFIGURATION_ID was not defined."
	fi
	load_config_vars "${workload_environment_file_name}" "keyvault"
	key_vault="$keyvault"
	load_config_vars "${workload_environment_file_name}" "tfstate_resource_id"
	key_vault_id=$(az resource list --name "${keyvault}" --subscription "$ARM_SUBSCRIPTION_ID" --resource-type Microsoft.KeyVault/vaults --query "[].id | [0]" -o tsv)
fi

if [ -z "$key_vault" ]; then
	if [ "$PLATFORM" == "devops" ]; then
		echo "##vso[task.logissue type=error]Key vault name (${CONTROL_PLANE_NAME}_KeyVaultName) was not found in the application configuration ( '$APPLICATION_CONFIGURATION_NAME' nor was it defined in ${workload_environment_file_name})."
	elif [ "$PLATFORM" == "github" ]; then
		echo "##vso[task.logissue type=error]Key vault name (${CONTROL_PLANE_NAME}_KeyVaultName) was not found in the application configuration ( '$APPLICATION_CONFIGURATION_NAME' nor was it defined in ${workload_environment_file_name})."
	fi
fi

if [ -z "$tfstate_resource_id" ]; then
	if [ "$PLATFORM" == "devops" ]; then
		echo "##vso[task.logissue type=error]Terraform state storage account resource id ('${CONTROL_PLANE_NAME}_TerraformRemoteStateStorageAccountId') was not found in the application configuration ( '$APPLICATION_CONFIGURATION_NAME' nor was it defined in ${workload_environment_file_name})."
	elif [ "$PLATFORM" == "github" ]; then
		echo "##vso[task.logissue type=error]Terraform state storage account resource id ('${CONTROL_PLANE_NAME}_TerraformRemoteStateStorageAccountId') was not found in the application configuration ( '$APPLICATION_CONFIGURATION_NAME' nor was it defined in ${workload_environment_file_name})."
	fi
	exit 2
fi

export TF_VAR_spn_keyvault_id=${key_vault_id}

terraform_storage_account_name=$(echo "$tfstate_resource_id" | cut -d '/' -f 9)
terraform_storage_account_resource_group_name=$(echo "$tfstate_resource_id" | cut -d '/' -f 5)
terraform_storage_account_subscription_id=$(echo "$tfstate_resource_id" | cut -d '/' -f 3)

export terraform_storage_account_name
export terraform_storage_account_resource_group_name
export terraform_storage_account_subscription_id
export tfstate_resource_id

export workload_key_vault

echo ""
echo -e "${green}Terraform parameter information:"
echo -e "-------------------------------------------------------------------------------$reset"

echo "System TFvars:                       $SAP_SYSTEM_TFVARS_FILENAME"
echo "Deployer statefile:                  $deployer_tfstate_key"
echo "Workload statefile:                  $landscape_tfstate_key"
echo "Deployer Key vault:                  $key_vault"
echo "Workload Key vault:                  ${workload_key_vault}"
echo "Statefile subscription:              $terraform_storage_account_subscription_id"
echo "Statefile storage account:           $terraform_storage_account_name"
echo ""
echo "Target subscription:                 $ARM_SUBSCRIPTION_ID"

cd "$CONFIG_REPO_PATH/SYSTEM/$SAP_SYSTEM_FOLDERNAME" || exit
if "$SAP_AUTOMATION_REPO_PATH/deploy/scripts/installer_v2.sh" --parameter_file $SAP_SYSTEM_TFVARS_FILENAME --type sap_system \
	--control_plane_name "${CONTROL_PLANE_NAME}" --application_configuration_name "${APPLICATION_CONFIGURATION_NAME}" \
	--workload_zone_name "${WORKLOAD_ZONE_NAME}" \
	"$platform_flag" --auto-approve; then
	return_code=$?
	print_banner "$banner_title" "Deployment of $SAP_SYSTEM_FOLDERNAME completed successfully" "success"
else
	return_code=$?
	print_banner "$banner_title" "Deployment of $SAP_SYSTEM_FOLDERNAME failed" "error"
	echo -e "$bold_red--- Deployment failed ---$reset_formatting"
	if [ "$PLATFORM" == "devops" ]; then
		echo "##vso[task.logissue type=error]Deployment failed."
	else
		echo "ERROR: Deployment failed."
	fi
fi
echo "Return code from deployment:         ${return_code}"
if [ 0 != $return_code ]; then
	if [ "$PLATFORM" == "devops" ]; then
		echo "##vso[task.logissue type=error]Return code from installer $return_code."
	fi
fi

set +o errexit

echo -e "$green--- Add & update files in the DevOps Repository ---$reset"
cd "$CONFIG_REPO_PATH" || exit
if [ "$PLATFORM" == "devops" ]; then
	git pull -q origin "$BUILD_SOURCEBRANCHNAME"
	git checkout -q "$BUILD_SOURCEBRANCHNAME"
elif [ "$PLATFORM" == "github" ]; then
	git pull -q origin "$GITHUB_REF_NAME"
fi

# Pull changes if there are other deployment jobs

cd "${CONFIG_REPO_PATH}/SYSTEM/$SAP_SYSTEM_FOLDERNAME" || exit

echo -e "$green--- Add & update files in the DevOps Repository ---$reset"

if [ -f stdout.az ]; then
	rm stdout.az
fi

added=0

if [ -f .terraform/terraform.tfstate ]; then
	git add -f .terraform/terraform.tfstate
	added=1
fi

if [ -f sap-parameters.yaml ]; then
	git add sap-parameters.yaml
	added=1
else
	return_code=1
fi

if [ -f "${SID}_hosts.yaml" ]; then
	git add -f "${SID}_hosts.yaml"
	added=1
fi

if [ -f "${SID}.md" ]; then
	git add "${CONFIG_REPO_PATH}/SYSTEM/$SAP_SYSTEM_FOLDERNAME/${SID}.md"
	# echo "##vso[task.uploadsummary]./${SID}.md)"
	added=1
fi

if [ -f "${SID}_inventory.md" ]; then
	git add "${SID}_inventory.md"
	added=1
fi

if [ -f "${SID}_resource_names.json" ]; then
	git add "${SID}_resource_names.json"
	added=1
fi

if [ -f "$SAP_SYSTEM_TFVARS_FILENAME" ]; then
	git add "$SAP_SYSTEM_TFVARS_FILENAME"
	added=1
fi

if [ -f "${SID}_virtual_machines.json" ]; then
	git add "${SID}_virtual_machines.json"
	added=1
fi


# Commit changes based on platform
if [ 1 = $added ]; then
	if [ "$PLATFORM" == "devops" ]; then
		git config --global user.email "$BUILD_REQUESTEDFOREMAIL"
		git config --global user.name "$BUILD_REQUESTEDFOR"
		commit_message="Added updates from SAP System Infrastructure Deployment of $SAP_SYSTEM_FOLDERNAME [skip ci]"
	elif [ "$PLATFORM" == "github" ]; then
		git config --global user.email "github-actions@github.com"
		git config --global user.name "GitHub Actions"
		commit_message="Added updates from SAP System Infrastructure Deployment of $SAP_SYSTEM_FOLDERNAME [skip ci]"
	else
		git config --global user.email "local@example.com"
		git config --global user.name "Local User"
		commit_message="Added updates from SAP System Infrastructure Deployment of $SAP_SYSTEM_FOLDERNAME [skip ci]"
	fi

	if [ "$DEBUG" = True ]; then
		git status --verbose
		if git commit --message --verbose "$commit_message"; then
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

print_banner "$banner_title" "Exiting $SCRIPT_NAME" "info"

# file_name=${SID}_inventory.md
# if [ -f ${SID}_inventory.md ]; then
#   az devops configure --defaults organization=$SYSTEM_COLLECTIONURI project=$SYSTEM_TEAMPROJECTID --output none

#   # ToDo: Fix this later
#   # WIKI_NAME_FOUND=$(az devops wiki list --query "[?name=='SDAF'].name | [0]")
#   # echo "${WIKI_NAME_FOUND}"
#   # if [ -n "${WIKI_NAME_FOUND}" ]; then
#   #   eTag=$(az devops wiki page show --path "${file_name}" --wiki SDAF --query eTag )
#   #   if [ -n "$eTag" ]; then
#   #     az devops wiki page update --path "${file_name}" --wiki SDAF --file-path ./"${file_name}" --only-show-errors --version $eTag --output none
#   #   else
#   #     az devops wiki page create --path "${file_name}" --wiki SDAF --file-path ./"${file_name}" --output none --only-show-errors
#   #   fi
#   # fi
# fi

exit $return_code
