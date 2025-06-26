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

print_banner "$banner_title" "Starting $SCRIPT_NAME" "info"

WORKLOAD_ZONE_NAME=$(echo "$WORKLOAD_ZONE_FOLDERNAME" | cut -d'-' -f1-3)

echo "##vso[build.updatebuildnumber]Deploying the SAP Workload zone defined in $WORKLOAD_ZONE_FOLDERNAME"

tfvarsFile="LANDSCAPE/$WORKLOAD_ZONE_FOLDERNAME/$WORKLOAD_ZONE_TFVARS_FILENAME"

echo -e "$cyan tfvarsFile: $tfvarsFile $reset"
echo -e "$green--- Checkout $BUILD_SOURCEBRANCHNAME ---$reset"

cd "${CONFIG_REPO_PATH}" || exit
mkdir -p .sap_deployment_automation
git checkout -q "$BUILD_SOURCEBRANCHNAME"

if [ ! -f "$CONFIG_REPO_PATH/LANDSCAPE/$WORKLOAD_ZONE_FOLDERNAME/$WORKLOAD_ZONE_TFVARS_FILENAME" ]; then
	echo -e "$bold_red--- $WORKLOAD_ZONE_TFVARS_FILENAME was not found ---$reset"
	echo "##vso[task.logissue type=error]File $WORKLOAD_ZONE_TFVARS_FILENAME was not found."
	exit 2
fi

# Check if running on deployer
if [[ ! -f /etc/profile.d/deploy_server.sh ]]; then
	configureNonDeployer "$(tf_version)"
	echo -e "$green--- az login ---$reset"
	if ! LogonToAzure false; then
		print_banner "$banner_title" "Login to Azure failed" "error"
		echo "##vso[task.logissue type=error]az login failed."
		exit 2
	fi
else
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

if ! get_variable_group_id "$VARIABLE_GROUP" "VARIABLE_GROUP_ID"; then
	echo -e "$bold_red--- Variable group $VARIABLE_GROUP not found ---$reset"
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

deployer_environment_file_name="$CONFIG_REPO_PATH/.sap_deployment_automation/$CONTROL_PLANE_NAME"
workload_environment_file_name="$CONFIG_REPO_PATH/.sap_deployment_automation/$WORKLOAD_ZONE_NAME"

if [ -z "$APPLICATION_CONFIGURATION_ID" ]; then
	APPLICATION_CONFIGURATION_ID=$(getVariableFromVariableGroup "${PARENT_VARIABLE_GROUP_ID}" "APPLICATION_CONFIGURATION_ID" "${deployer_environment_file_name}" "APPLICATION_CONFIGURATION_ID")
	APPLICATION_CONFIGURATION_NAME=$(echo "$APPLICATION_CONFIGURATION_ID" | cut -d '/' -f 9)
	if saveVariableInVariableGroup "${VARIABLE_GROUP_ID}" "APPLICATION_CONFIGURATION_ID" "$APPLICATION_CONFIGURATION_ID"; then
		echo "Variable APPLICATION_CONFIGURATION_ID was added to the $VARIABLE_GROUP variable group."
	else
		echo "##vso[task.logissue type=error]Variable APPLICATION_CONFIGURATION_ID was not added to the $VARIABLE_GROUP variable group."
		echo "Variable APPLICATION_CONFIGURATION_ID was not added to the $VARIABLE_GROUP variable group."
	fi
	if saveVariableInVariableGroup "${VARIABLE_GROUP_ID}" "APPLICATION_CONFIGURATION_NAME" "$APPLICATION_CONFIGURATION_NAME"; then
		echo "Variable APPLICATION_CONFIGURATION_NAME was added to the $VARIABLE_GROUP variable group."
	else
		echo "##vso[task.logissue type=error]Variable APPLICATION_CONFIGURATION_NAME was not added to the $VARIABLE_GROUP variable group."
		echo "Variable APPLICATION_CONFIGURATION_NAME was not added to the $VARIABLE_GROUP variable group."
	fi
fi


az account set --subscription "$ARM_SUBSCRIPTION_ID"

dos2unix -q tfvarsFile

ENVIRONMENT=$(grep -m1 "^environment" "$tfvarsFile" | awk -F'=' '{print $2}' | tr -d ' \t\n\r\f"')
LOCATION=$(grep -m1 "^location" "$tfvarsFile" | awk -F'=' '{print $2}' | tr '[:upper:]' '[:lower:]' | tr -d ' \t\n\r\f"')
NETWORK=$(grep -m1 "^network_logical_name" "$tfvarsFile" | awk -F'=' '{print $2}' | tr -d ' \t\n\r\f"')

ENVIRONMENT_IN_FILENAME=$(echo $WORKLOAD_ZONE_FOLDERNAME | awk -F'-' '{print $1}')
LOCATION_CODE_IN_FILENAME=$(echo $WORKLOAD_ZONE_FOLDERNAME | awk -F'-' '{print $2}')
LOCATION_IN_FILENAME=$(get_region_from_code "$LOCATION_CODE_IN_FILENAME" || true)
NETWORK_IN_FILENAME=$(echo $WORKLOAD_ZONE_FOLDERNAME | awk -F'-' '{print $3}')

deployer_tfstate_key=$CONTROL_PLANE_NAME.terraform.tfstate
export deployer_tfstate_key

landscape_tfstate_key="${WORKLOAD_ZONE_NAME}-INFRASTRUCTURE.terraform.tfstate"
export landscape_tfstate_key

echo -e "${green}Deployment details:"
echo -e "-------------------------------------------------------------------------${reset}"

echo "CONTROL_PLANE_NAME:                  $CONTROL_PLANE_NAME"
echo "Control plane environment file:      $deployer_environment_file_name"
echo "WORKLOAD_ZONE_NAME:                  $WORKLOAD_ZONE_NAME"
echo "Workload Zone Environment file:      $workload_environment_file_name"
echo "Workload zone TFvars:                $WORKLOAD_ZONE_TFVARS_FILENAME"
if [ -n "$APPLICATION_CONFIGURATION_NAME" ]; then
	echo "APPLICATION_CONFIGURATION_NAME:      $APPLICATION_CONFIGURATION_NAME"
fi
echo ""

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

if is_valid_id "$APPLICATION_CONFIGURATION_ID" "/providers/Microsoft.AppConfiguration/configurationStores/"; then
	application_configuration_name=$(echo "$APPLICATION_CONFIGURATION_ID" | cut -d '/' -f 9)

	TF_VAR_management_subscription_id=$(getVariableFromApplicationConfiguration "$APPLICATION_CONFIGURATION_ID" "${CONTROL_PLANE_NAME}_SubscriptionId" "${CONTROL_PLANE_NAME}")
	export TF_VAR_management_subscription_id

	tfstate_resource_id=$(getVariableFromApplicationConfiguration "$APPLICATION_CONFIGURATION_ID" "${CONTROL_PLANE_NAME}_TerraformRemoteStateStorageAccountId" "${CONTROL_PLANE_NAME}")
	if [ -z "$tfstate_resource_id" ]; then
		echo "##vso[task.logissue type=warning]Key '${CONTROL_PLANE_NAME}_TerraformRemoteStateStorageAccountId' was not found in the application configuration ( '$application_configuration_name' )."
	fi
else
	echo "##vso[task.logissue type=warning]Variable APPLICATION_CONFIGURATION_ID was not defined."
	load_config_vars "${workload_environment_file_name}" "tfstate_resource_id"
	load_config_vars "${deployer_environment_file_name}" "subscription"
	TF_VAR_management_subscription_id="$subscription"
	export TF_VAR_management_subscription_id

fi

if [ -z "$tfstate_resource_id" ]; then
	echo "##vso[task.logissue type=error]Terraform state storage account resource id ('${CONTROL_PLANE_NAME}_TerraformRemoteStateStorageAccountId') was not found in the application configuration ( '$application_configuration_name' nor was it defined in ${workload_environment_file_name})."
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
print_banner "$banner_title" "Starting the deployment" "info"

if "$SAP_AUTOMATION_REPO_PATH/deploy/scripts/installer_v2.sh" --parameter_file "$WORKLOAD_ZONE_TFVARS_FILENAME" --type sap_landscape \
	--control_plane_name "${CONTROL_PLANE_NAME}" --application_configuration_name "${APPLICATION_CONFIGURATION_NAME}" \
	--ado --auto-approve; then
	return_code=$?
	print_banner "$banner_title" "Deployment of $WORKLOAD_ZONE_NAME succeeded" "success"
else
	return_code=$?
	print_banner "$banner_title" "Deployment of $WORKLOAD_ZONE_NAME failed" "error"

	echo "##vso[task.logissue type=error]Terraform apply failed."
fi
echo "Return code from deployment:         ${return_code}"

set +o errexit

echo -e "$green--- Pushing the changes to the repository ---$reset"
# Pull changes if there are other deployment jobs
git pull -q origin "$BUILD_SOURCEBRANCHNAME"

added=0

if [ -f .terraform/terraform.tfstate ]; then
	git add -f .terraform/terraform.tfstate
	added=1
fi

if [ -f ".sap_deployment_automation/${WORKLOAD_ZONE_NAME}" ]; then
	git add ".sap_deployment_automation/${WORKLOAD_ZONE_NAME}"
	added=1
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
