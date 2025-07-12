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

SCRIPT_NAME="$(basename "$0")"

banner_title="Remove SAP System"

#call stack has full script name when using source
# shellcheck disable=SC1091
source "${grand_parent_directory}/deploy_utils.sh"

#call stack has full script name when using source
source "${parent_directory}/helper.sh"

echo "##vso[build.updatebuildnumber]Removing workload zone defined in  defined in $WORKLOAD_ZONE_FOLDERNAME"

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

if ! get_variable_group_id "$VARIABLE_GROUP" "VARIABLE_GROUP_ID"; then
	echo -e "$bold_red--- Variable group $VARIABLE_GROUP not found ---$reset"
	echo "##vso[task.logissue type=error]Variable group $VARIABLE_GROUP not found."
	exit 2
fi
export VARIABLE_GROUP_ID

print_banner "$banner_title" "Starting $SCRIPT_NAME" "info"

tfvarsFile="LANDSCAPE/$WORKLOAD_ZONE_FOLDERNAME/$WORKLOAD_ZONE_TFVARS_FILENAME"

cd "${CONFIG_REPO_PATH}" || exit
mkdir -p .sap_deployment_automation
git checkout -q "$BUILD_SOURCEBRANCHNAME"

if [ ! -f "$CONFIG_REPO_PATH/$tfvarsFile" ]; then
	print_banner "$banner_title" "$WORKLOAD_ZONE_TFVARS_FILENAME was not found" "error"
	echo "##vso[task.logissue type=error]File $WORKLOAD_ZONE_TFVARS_FILENAME was not found."
	exit 2
fi

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
	LogonToAzure $USE_MSI
	return_code=$?
	if [ 0 != $return_code ]; then
		echo -e "$bold_red--- Login failed ---$reset"
		echo "##vso[task.logissue type=error]az login failed."
		exit $return_code
	fi
else
	LogonToAzure $USE_MSI
fi

TF_VAR_subscription_id=$ARM_SUBSCRIPTION_ID
export TF_VAR_subscription_id
az account set --subscription "$ARM_SUBSCRIPTION_ID"

ENVIRONMENT=$(grep -m1 "^environment" "$tfvarsFile" | awk -F'=' '{print $2}' | tr -d ' \t\n\r\f"')
LOCATION=$(grep -m1 "^location" "$tfvarsFile" | awk -F'=' '{print $2}' | tr '[:upper:]' '[:lower:]' | tr -d ' \t\n\r\f"')
NETWORK=$(grep -m1 "^network_logical_name" "$tfvarsFile" | awk -F'=' '{print $2}' | tr -d ' \t\n\r\f"')

ENVIRONMENT_IN_FILENAME=$(echo $WORKLOAD_ZONE_FOLDERNAME | awk -F'-' '{print $1}')
LOCATION_CODE_IN_FILENAME=$(echo $WORKLOAD_ZONE_FOLDERNAME | awk -F'-' '{print $2}')
LOCATION_IN_FILENAME=$(get_region_from_code "$LOCATION_CODE_IN_FILENAME" || true)
NETWORK_IN_FILENAME=$(echo $WORKLOAD_ZONE_FOLDERNAME | awk -F'-' '{print $3}')

deployer_environment_file_name="$CONFIG_REPO_PATH/.sap_deployment_automation/$DEPLOYER_ENVIRONMENT$LOCATION_CODE_IN_FILENAME"
echo "Deployer Environment File:           $deployer_environment_file_name"
if [ ! -f "${deployer_environment_file_name}" ]; then
	echo -e "$bold_red--- $DEPLOYER_ENVIRONMENT$ENVIRONMENT was not found ---$reset"
	echo "##vso[task.logissue type=error]Control plane configuration file $DEPLOYER_ENVIRONMENT$LOCATION_CODE_IN_FILENAME was not found."
	exit 2
fi

automation_config_directory=$CONFIG_REPO_PATH/.sap_deployment_automation/
if [ "v1" == "${SDAFWZ_CALLER_VERSION:-v2}" ]; then
	workload_environment_file_name="${automation_config_directory}${ENVIRONMENT}${LOCATION_CODE_IN_FILENAME}"
elif [ "v2" == "${SDAFWZ_CALLER_VERSION:-v2}" ]; then
	workload_environment_file_name="${automation_config_directory}${ENVIRONMENT}${LOCATION_CODE_IN_FILENAME}${NETWORK}"
fi

echo "Workload Zone Environment File:      $workload_environment_file_name"
touch "$workload_environment_file_name"

deployer_tfstate_key=$(getVariableFromVariableGroup "${VARIABLE_GROUP_ID}" "Deployer_State_FileName" "${deployer_environment_file_name}" "deployer_tfstate_key")
export deployer_tfstate_key

DEPLOYER_KEYVAULT=$(getVariableFromVariableGroup "${VARIABLE_GROUP_ID}" "DEPLOYER_KEYVAULT" "${deployer_environment_file_name}" "deployer_keyvault")
export DEPLOYER_KEYVAULT

landscape_tfstate_key=$WORKLOAD_ZONE_FOLDERNAME.terraform.tfstate
export landscape_tfstate_key

echo -e "${green}Deployment details:"
echo -e "-------------------------------------------------------------------------${reset}"

echo "Control plane environment file:      $deployer_environment_file_name"
echo "Workload Zone Environment file:      $workload_environment_file_name"
echo "Workload zone TFvars:                $WORKLOAD_ZONE_TFVARS_FILENAME"
echo ""

echo "Environment:                         $ENVIRONMENT"
echo "Environment in file:                 $ENVIRONMENT_IN_FILENAME"
echo "Location:                            $LOCATION"
echo "Location in file:                    $LOCATION_IN_FILENAME"
echo "Network:                             $NETWORK"
echo "Network in file:                     $NETWORK_IN_FILENAME"

if [ "$ENVIRONMENT" != "$ENVIRONMENT_IN_FILENAME" ]; then
	print_banner "$banner_title" "Environment mismatch" "error" "The environment setting in the tfvars file is not a part of the $WORKLOAD_ZONE_TFVARS_FILENAME file name" "Filename should have the pattern [ENVIRONMENT]-[REGION_CODE]-[NETWORK_LOGICAL_NAME]-INFRASTRUCTURE"
	echo "##vso[task.logissue type=error]The environment setting in $WORKLOAD_ZONE_TFVARS_FILENAME '$ENVIRONMENT' does not match the $WORKLOAD_ZONE_TFVARS_FILENAME file name '$ENVIRONMENT_IN_FILENAME'. Filename should have the pattern [ENVIRONMENT]-[REGION_CODE]-[NETWORK_LOGICAL_NAME]-INFRASTRUCTURE"
	exit 2
fi

if [ "$LOCATION" != "$LOCATION_IN_FILENAME" ]; then
	print_banner "$banner_title" "Location mismatch" "error" "The 'location' setting in the tfvars file is not represented in the $WORKLOAD_ZONE_TFVARS_FILENAME file name" "Filename should have the pattern [ENVIRONMENT]-[REGION_CODE]-[NETWORK_LOGICAL_NAME]-INFRASTRUCTURE"
	echo "##vso[task.logissue type=error]The location setting in $WORKLOAD_ZONE_TFVARS_FILENAME '$LOCATION' does not match the $WORKLOAD_ZONE_TFVARS_FILENAME file name '$LOCATION_IN_FILENAME'. Filename should have the pattern [ENVIRONMENT]-[REGION_CODE]-[NETWORK_LOGICAL_NAME]-INFRASTRUCTURE"
	exit 2
fi

if [ "$NETWORK" != "$NETWORK_IN_FILENAME" ]; then
	print_banner "$banner_title" "Naming mismatch" "error" "The 'network_logical_name' setting in the tfvars file is not a part of the $WORKLOAD_ZONE_TFVARS_FILENAME file name" "Filename should have the pattern [ENVIRONMENT]-[REGION_CODE]-[NETWORK_LOGICAL_NAME]-INFRASTRUCTURE"
	echo "##vso[task.logissue type=error]The network_logical_name setting in $WORKLOAD_ZONE_TFVARS_FILENAME '$NETWORK' does not match the $WORKLOAD_ZONE_TFVARS_FILENAME file name '$NETWORK_IN_FILENAME-. Filename should have the pattern [ENVIRONMENT]-[REGION_CODE]-[NETWORK_LOGICAL_NAME]-INFRASTRUCTURE"
	exit 2
fi

dos2unix -q "${workload_environment_file_name}"

load_config_vars "${deployer_environment_file_name}" "tfstate_resource_id" "subscription"
tfstate_resource_id=$(az graph query -q "Resources | join kind=leftouter (ResourceContainers | where type=='microsoft.resources/subscriptions' | project subscription=name, subscriptionId) on subscriptionId | where name == '$TERRAFORM_STATE_STORAGE_ACCOUNT' | project id, name, subscription" --query data[0].id --output tsv)

TF_VAR_spn_keyvault_id=$(az graph query -q "Resources | join kind=leftouter (ResourceContainers | where type=='microsoft.resources/subscriptions' | project subscription=name, subscriptionId) on subscriptionId | where name == '$DEPLOYER_KEYVAULT' | project id, name, subscription" --query data[0].id --output tsv)

export TF_VAR_spn_keyvault_id
TF_VAR_management_subscription_id=$(echo "$TF_VAR_spn_keyvault_id" | cut -d '/' -f 3)
export TF_VAR_management_subscription_id

TF_VAR_tfstate_resource_id="$tfstate_resource_id"
export TF_VAR_tfstate_resource_id

if [ -z "$tfstate_resource_id" ]; then
	echo "##vso[task.logissue type=error]Terraform state storage account resource id ('${CONTROL_PLANE_NAME}_TerraformRemoteStateStorageAccountId') was not found in the application configuration ( '$application_configuration_name' nor was it defined in ${deployer_environment_file_name})."
	exit 2
fi

terraform_storage_account_name=$(echo "$tfstate_resource_id" | cut -d '/' -f 9)
terraform_storage_account_resource_group_name=$(echo "$tfstate_resource_id" | cut -d '/' -f 5)
terraform_storage_account_subscription_id=$(echo "$tfstate_resource_id" | cut -d '/' -f 3)

export terraform_storage_account_name
export terraform_storage_account_resource_group_name
export terraform_storage_account_subscription_id
export tfstate_resource_id

if [ -z "$tfstate_resource_id" ]; then
	tfstate_resource_id=$(az resource list --name "${terraform_storage_account_name}" --subscription "$terraform_storage_account_subscription_id" --resource-type Microsoft.Storage/storageAccounts --query "[].id | [0]" -o tsv)
	export tfstate_resource_id
fi

cd "$CONFIG_REPO_PATH/LANDSCAPE/$WORKLOAD_ZONE_FOLDERNAME" || exit

if ${SAP_AUTOMATION_REPO_PATH}/deploy/scripts/remover.sh \
	--parameterfile "$WORKLOAD_ZONE_TFVARS_FILENAME" \
	--type sap_landscape \
	--state_subscription "${terraform_storage_account_subscription_id}" \
	--storageaccountname "${terraform_storage_account_name}" \
	--deployer_tfstate_key "${deployer_tfstate_key}" \
	--auto-approve; then
	return_code=$?
	print_banner "$banner_title" "The removal of $WORKLOAD_ZONE_TFVARS_FILENAME succeeded" "success" "Return code: ${return_code}"
else
	return_code=$?
	print_banner "$banner_title" "The removal of $WORKLOAD_ZONE_TFVARS_FILENAME failed" "error" "Return code: ${return_code}"
fi

echo
if [ 0 != $return_code ]; then
	echo "##vso[task.logissue type=error]Return code from remover $return_code."
else
	if [ 0 == $return_code ]; then
		# Pull changes
		git checkout -q "$BUILD_SOURCEBRANCHNAME"
		git pull origin "$BUILD_SOURCEBRANCHNAME"

		git clean -d -f -X

		if [ -f ".terraform/terraform.tfstate" ]; then
			git rm --ignore-unmatch -q --ignore-unmatch ".terraform/terraform.tfstate"
			changed=1
		fi

		if [ -d ".terraform" ]; then
			git rm -q -r --ignore-unmatch ".terraform"
			changed=1
		fi

		if [ -d .terraform ]; then
			rm -r .terraform
		fi

		if [ -f "$WORKLOAD_ZONE_TFVARS_FILENAME" ]; then
			git add "$WORKLOAD_ZONE_TFVARS_FILENAME"
			changed=1
		fi

		if [ 1 == $changed ]; then
			git config --global user.email "$BUILD_REQUESTEDFOREMAIL"
			git config --global user.name "$BUILD_REQUESTEDFOR"

			if git commit -m "Infrastructure for $WORKLOAD_ZONE_TFVARS_FILENAME removed. [skip ci]"; then
				if git -c http.extraheader="AUTHORIZATION: bearer $SYSTEM_ACCESSTOKEN" push --set-upstream origin "$BUILD_SOURCEBRANCHNAME" --force-with-lease; then
					echo "##vso[task.logissue type=warning]Removal of $WORKLOAD_ZONE_TFVARS_FILENAME updated in $BUILD_BUILDNUMBER"
				else
					echo "##vso[task.logissue type=error]Failed to push changes to $BUILD_SOURCEBRANCHNAME"
				fi
			fi
		fi
	fi
	echo -e "$green--- Deleting variables ---$reset"
	if [ -n "$VARIABLE_GROUP_ID" ]; then
		print_banner "Remove workload zone" "Deleting variables" "info"

		remove_variable "$VARIABLE_GROUP_ID" "DEPLOYER_KEYVAULT"

		remove_variable "$VARIABLE_GROUP_ID" "APPSERVICE_NAME"
		remove_variable "$VARIABLE_GROUP_ID" "Terraform_Remote_Storage_Account_Name"
		remove_variable "$VARIABLE_GROUP_ID" "Terraform_Remote_Storage_Resource_Group_Name"
		remove_variable "$VARIABLE_GROUP_ID" "Terraform_Remote_Storage_Subscription"
		remove_variable "$VARIABLE_GROUP_ID" "DEPLOYER_STATE_FILENAME"
		remove_variable "$VARIABLE_GROUP_ID" "Deployer_Key_Vault"
		remove_variable "$VARIABLE_GROUP_ID" "TERRAFORM_STATE_STORAGE_ACCOUNT"
		remove_variable "$VARIABLE_GROUP_ID" "KEYVAULT"
	fi
fi
exit $return_code
