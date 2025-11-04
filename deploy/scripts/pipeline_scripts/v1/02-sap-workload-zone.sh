#!/bin/bash
# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

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

SCRIPT_NAME="$(basename "$0")"

banner_title="Deploy Workload Zone"

#call stack has full script name when using source
# shellcheck disable=SC1091
source "${grand_parent_directory}/deploy_utils.sh"

#call stack has full script name when using source
source "${parent_directory}/helper.sh"

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

print_banner "$banner_title" "Starting $SCRIPT_NAME" "info"

tfvarsFile="LANDSCAPE/$WORKLOAD_ZONE_FOLDERNAME/$WORKLOAD_ZONE_TFVARS_FILENAME"

echo -e "$cyan tfvarsFile: $tfvarsFile $reset"
echo -e "$green--- Checkout $BUILD_SOURCEBRANCHNAME ---$reset"

cd "${CONFIG_REPO_PATH}" || exit
mkdir -p .sap_deployment_automation
git checkout -q "$BUILD_SOURCEBRANCHNAME"

if [ ! -f "$CONFIG_REPO_PATH/LANDSCAPE/$WORKLOAD_ZONE_FOLDERNAME/$WORKLOAD_ZONE_TFVARS_FILENAME" ]; then
	print_banner "$banner_title" "File ${WORKLOAD_ZONE_TFVARS_FILENAME} was not found" "error"
	echo "##vso[task.logissue type=error]File $WORKLOAD_ZONE_TFVARS_FILENAME was not found."
	exit 2
fi

if ! get_variable_group_id "$VARIABLE_GROUP" "VARIABLE_GROUP_ID"; then
	if ! get_variable_group_id "$VARIABLE_GROUP_CONTROL_PLANE" "VARIABLE_GROUP_ID"; then
		echo -e "$bold_red--- Variable group $VARIABLE_GROUP not found ---$reset"
		echo "##vso[task.logissue type=error]Variable group $VARIABLE_GROUP not found."
		exit 2
	fi
fi
export VARIABLE_GROUP_ID

# Set logon variables
if [ "$USE_MSI" == "true" ]; then
	unset ARM_CLIENT_SECRET
	ARM_USE_MSI=true
	export ARM_USE_MSI
else
	ARM_USE_MSI=false
	export ARM_USE_MSI
fi

if [ -v SYSTEM_ACCESSTOKEN ]; then
	export TF_VAR_PAT="$SYSTEM_ACCESSTOKEN"
fi

# Check if running on deployer
if [[ ! -f /etc/profile.d/deploy_server.sh ]]; then
	configureNonDeployer "${tf_version:-1.13.3}"
fi

echo -e "$green--- az login ---$reset"
LogonToAzure $USE_MSI
return_code=$?
if [ 0 != $return_code ]; then
	echo -e "$bold_red--- Login failed ---$reset"
	echo "##vso[task.logissue type=error]az login failed."
	exit $return_code
fi

TF_VAR_subscription_id=$ARM_SUBSCRIPTION_ID
export TF_VAR_subscription_id

if ! get_variable_group_id "$PARENT_VARIABLE_GROUP" "PARENT_VARIABLE_GROUP_ID"; then
	echo -e "$bold_red--- Variable group $PARENT_VARIABLE_GROUP not found ---$reset"
	echo "##vso[task.logissue type=error]Variable group $PARENT_VARIABLE_GROUP not found."
	exit 2
fi
export PARENT_VARIABLE_GROUP_ID

az account set --subscription "$ARM_SUBSCRIPTION_ID"

# dos2unix -q tfvarsFile

ENVIRONMENT=$(grep -m1 "^environment" "$tfvarsFile" | awk -F'=' '{print $2}' | tr -d ' \t\n\r\f"')
LOCATION=$(grep -m1 "^location" "$tfvarsFile" | awk -F'=' '{print $2}' | tr '[:upper:]' '[:lower:]' | tr -d ' \t\n\r\f"')
NETWORK=$(grep -m1 "^network_logical_name" "$tfvarsFile" | awk -F'=' '{print $2}' | tr -d ' \t\n\r\f"')

ENVIRONMENT_IN_FILENAME=$(echo $WORKLOAD_ZONE_FOLDERNAME | awk -F'-' '{print $1}')
LOCATION_CODE_IN_FILENAME=$(echo $WORKLOAD_ZONE_FOLDERNAME | awk -F'-' '{print $2}')
LOCATION_IN_FILENAME=$(get_region_from_code "$LOCATION_CODE_IN_FILENAME" || true)
NETWORK_IN_FILENAME=$(echo $WORKLOAD_ZONE_FOLDERNAME | awk -F'-' '{print $3}')

automation_config_directory="$CONFIG_REPO_PATH/.sap_deployment_automation/"
workload_environment_file_name=$(get_configuration_file "${automation_config_directory}" "${ENVIRONMENT_IN_FILENAME}" "${LOCATION_CODE_IN_FILENAME}" "${NETWORK_IN_FILENAME}")
SYSTEM_CONFIGURATION_FILE="$workload_environment_file_name"
export SYSTEM_CONFIGURATION_FILE

separator="-"
if [[ "$DEPLOYER_ENVIRONMENT" == *"$separator"* ]]; then
	DEPLOYER_ENVIRONMENT_IN_FILENAME=$(echo $DEPLOYER_ENVIRONMENT | awk -F'-' '{print $1}')
	DEPLOYER_LOCATION_CODE_IN_FILENAME=$(echo $DEPLOYER_ENVIRONMENT | awk -F'-' '{print $2}')
	DEPLOYER_NETWORK_IN_FILENAME=$(echo $DEPLOYER_ENVIRONMENT | awk -F'-' '{print $3}')
	CONTROL_PLANE_NAME="$DEPLOYER_ENVIRONMENT-$DEPLOYER_LOCATION_CODE_IN_FILENAME-$DEPLOYER_NETWORK_IN_FILENAME"
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

deployer_tfstate_key=$(getVariableFromVariableGroup "${PARENT_VARIABLE_GROUP_ID}" "DEPLOYER_STATE_FILENAME" "${deployer_environment_file_name}" "deployer_tfstate_key")
if [ -z "$deployer_tfstate_key" ]; then
	deployer_tfstate_key=$(getVariableFromVariableGroup "${PARENT_VARIABLE_GROUP_ID}" "Deployer_State_FileName" "${deployer_environment_file_name}" "deployer_tfstate_key")
	if [ -z "$deployer_tfstate_key" ]; then

		echo -e "$bold_red--- DEPLOYER_STATE_FILENAME not found in variable group $PARENT_VARIABLE_GROUP ---$reset"
		echo "##vso[task.logissue type=error]DEPLOYER_STATE_FILENAME not found in variable group $PARENT_VARIABLE_GROUP."
		exit 2
	else
		# Delete the old variable

		saveVariableInVariableGroup "${VARIABLE_GROUP_ID}" "Deployer_State_FileName" ""
	fi
fi
export deployer_tfstate_key
saveVariableInVariableGroup "${VARIABLE_GROUP_ID}" "DEPLOYER_STATE_FILENAME" "$deployer_tfstate_key"
CONTROL_PLANE_NAME=$(echo "$deployer_tfstate_key" | cut -d'-' -f1-3)

DEPLOYER_KEYVAULT=$(getVariableFromVariableGroup "${PARENT_VARIABLE_GROUP_ID}" "DEPLOYER_KEYVAULT" "${deployer_environment_file_name}" "deployer_keyvault")
export DEPLOYER_KEYVAULT
saveVariableInVariableGroup "${VARIABLE_GROUP_ID}" "DEPLOYER_KEYVAULT" "$DEPLOYER_KEYVAULT"

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

# dos2unix -q "${workload_environment_file_name}"

load_config_vars "${deployer_environment_file_name}" "tfstate_resource_id" "subscription"

TF_VAR_spn_keyvault_id=$(az graph query -q "Resources | join kind=leftouter (ResourceContainers | where type=='microsoft.resources/subscriptions' | project subscription=name, subscriptionId) on subscriptionId | where name == '$DEPLOYER_KEYVAULT' | project id, name, subscription" --query data[0].id --output tsv)

export TF_VAR_spn_keyvault_id
TF_VAR_management_subscription_id=$(echo "$TF_VAR_spn_keyvault_id" | cut -d '/' -f 3)
export TF_VAR_management_subscription_id

terraform_storage_account_name=$(getVariableFromVariableGroup "${VARIABLE_GROUP_ID}" "TERRAFORM_REMOTE_STORAGE_ACCOUNT_NAME" "${deployer_environment_file_name}" "REMOTE_STATE_SA")
if [ -z "$terraform_storage_account_name" ]; then
	terraform_storage_account_name=$(getVariableFromVariableGroup "${VARIABLE_GROUP_ID}" "TERRAFORM_STATE_STORAGE_ACCOUNT" "${deployer_environment_file_name}" "REMOTE_STATE_SA")
	if [ -z "$terraform_storage_account_name" ]; then
		terraform_storage_account_name=$(getVariableFromVariableGroup "${VARIABLE_GROUP_ID}" "Terraform_Remote_Storage_Account_Name" "${deployer_environment_file_name}" "REMOTE_STATE_SA")
	fi
fi

tfstate_resource_id=$(az graph query -q "Resources | join kind=leftouter (ResourceContainers | where type=='microsoft.resources/subscriptions' | project subscription=name, subscriptionId) on subscriptionId | where name == '$terraform_storage_account_name' and type=='microsoft.storage/storageaccounts' | project id, name, subscription" --query data[0].id --output tsv)

TF_VAR_tfstate_resource_id="$tfstate_resource_id"
export TF_VAR_tfstate_resource_id

if [ -z "$tfstate_resource_id" ]; then
	echo "##vso[task.logissue type=error]Terraform state storage account resource id was not defined in ${deployer_environment_file_name})."
	exit 2
fi

terraform_storage_account_resource_group_name=$(echo "$tfstate_resource_id" | cut -d '/' -f 5)
terraform_storage_account_subscription_id=$(echo "$tfstate_resource_id" | cut -d '/' -f 3)
saveVariableInVariableGroup "${VARIABLE_GROUP_ID}" "TERRAFORM_REMOTE_STORAGE_SUBSCRIPTION" "$terraform_storage_account_subscription_id"

export terraform_storage_account_name
export terraform_storage_account_resource_group_name
export terraform_storage_account_subscription_id
export tfstate_resource_id

if [ -z "$tfstate_resource_id" ]; then
	tfstate_resource_id=$(az resource list --name "${terraform_storage_account_name}" --subscription "$terraform_storage_account_subscription_id" --resource-type Microsoft.Storage/storageAccounts --query "[].id | [0]" -o tsv)
	export tfstate_resource_id
fi
saveVariableInVariableGroup "${VARIABLE_GROUP_ID}" "TERRAFORM_REMOTE_STORAGE_ACCOUNT_NAME" "$terraform_storage_account_name"

print_banner "$banner_title" "Starting the deployment" "info"
cd "$CONFIG_REPO_PATH/LANDSCAPE/$WORKLOAD_ZONE_FOLDERNAME" || exit
if "$SAP_AUTOMATION_REPO_PATH/deploy/scripts/installer.sh" --parameterfile "$WORKLOAD_ZONE_TFVARS_FILENAME" \
	--type sap_landscape \
	--deployer_tfstate_key "${deployer_tfstate_key}" --storageaccountname "${terraform_storage_account_name}" \
	--state_subscription "${terraform_storage_account_subscription_id}" --auto-approve --ado; then
	return_code=$?
	echo "##vso[task.logissue type=warning]Workload zone deployment completed successfully."
else
	return_code=$?
	echo "##vso[task.logissue type=error]Workload zone deployment failed."
	exit 1
fi

echo "Return code from deployment:         ${return_code}"

if [ -f "${workload_environment_file_name}" ]; then
	KEYVAULT=$(grep -m1 "^workloadkeyvault=" "${workload_environment_file_name}" | awk -F'=' '{print $2}' | xargs || true)
	echo "Key Vault:                  ${KEYVAULT}"

	echo -e "$green--- Adding variables to the variable group: $VARIABLE_GROUP ---$reset"
	if [ -n "$KEYVAULT" ]; then
		saveVariableInVariableGroup "${VARIABLE_GROUP_ID}" "KEYVAULT" "$KEYVAULT"
	fi

fi

if [ -n "$terraform_storage_account_name" ]; then
	echo -e "$green--- Adding variables to the variable group: $VARIABLE_GROUP ---$reset"
	saveVariableInVariableGroup "${VARIABLE_GROUP_ID}" "TERRAFORM_REMOTE_STORAGE_ACCOUNT_NAME" "$terraform_storage_account_name"
fi

set +o errexit

echo -e "$green--- Pushing the changes to the repository ---$reset"
# Pull changes if there are other deployment jobs
git pull -q origin "$BUILD_SOURCEBRANCHNAME"

added=0

if [ -f .terraform/terraform.tfstate ]; then
	git add -f .terraform/terraform.tfstate
	added=1
fi

if [ -f "${workload_environment_file_name}" ]; then
	git add "${workload_environment_file_name}"
	added=1

	if [ -f "$automation_config_directory/${ENVIRONMENT_IN_FILENAME}/${LOCATION_CODE_IN_FILENAME}" ]; then
		rm "$automation_config_directory/${ENVIRONMENT_IN_FILENAME}/${LOCATION_CODE_IN_FILENAME}"
		git rm --ignore-unmatch -q "$automation_config_directory/${ENVIRONMENT_IN_FILENAME}/${LOCATION_CODE_IN_FILENAME}"
	fi

fi

if [ -f "$WORKLOAD_ZONE_TFVARS_FILENAME" ]; then
	git add "$WORKLOAD_ZONE_TFVARS_FILENAME"
	added=1

fi

if [ 1 == $added ]; then
	git config --global user.email "$BUILD_REQUESTEDFOREMAIL"
	git config --global user.name "$BUILD_REQUESTEDFOR"
	git commit -m "Added updates from SAP workload zone deployment of $WORKLOAD_ZONE_FOLDERNAME for $BUILD_BUILDNUMBER [skip ci]"

	if git -c http.extraheader="AUTHORIZATION: bearer SYSTEM_ACCESSTOKEN" push --set-upstream origin "$BUILD_SOURCEBRANCHNAME" --force-with-lease; then
		echo "##vso[task.logissue type=warning]Changes from SAP deployment of $WORKLOAD_ZONE_FOLDERNAME pushed to $BUILD_SOURCEBRANCHNAME"
	else
		echo "##vso[task.logissue type=error]Failed to push changes to $BUILD_SOURCEBRANCHNAME"
	fi
fi

print_banner "$banner_title" "Exiting $SCRIPT_NAME" "info"

exit $return_code
