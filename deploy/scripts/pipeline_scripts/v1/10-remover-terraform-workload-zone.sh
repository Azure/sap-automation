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

az account set --subscription "$ARM_SUBSCRIPTION_ID"

ENVIRONMENT=$(grep -m1 "^environment" "$tfvarsFile" | awk -F'=' '{print $2}' | tr -d ' \t\n\r\f"')
LOCATION=$(grep -m1 "^location" "$tfvarsFile" | awk -F'=' '{print $2}' | tr '[:upper:]' '[:lower:]' | tr -d ' \t\n\r\f"')
NETWORK=$(grep -m1 "^network_logical_name" "$tfvarsFile" | awk -F'=' '{print $2}' | tr -d ' \t\n\r\f"')

ENVIRONMENT_IN_FILENAME=$(echo $WORKLOAD_ZONE_FOLDERNAME | awk -F'-' '{print $1}')
LOCATION_CODE_IN_FILENAME=$(echo $WORKLOAD_ZONE_FOLDERNAME | awk -F'-' '{print $2}')
LOCATION_IN_FILENAME=$(get_region_from_code "$LOCATION_CODE_IN_FILENAME" || true)
NETWORK_IN_FILENAME=$(echo $WORKLOAD_ZONE_FOLDERNAME | awk -F'-' '{print $3}')

WORKLOAD_ZONE_NAME=$(echo "$WORKLOAD_ZONE_FOLDERNAME" | cut -d'-' -f1-3)
landscape_tfstate_key="${WORKLOAD_ZONE_NAME}-INFRASTRUCTURE.terraform.tfstate"
export landscape_tfstate_key
workload_environment_file_name="$CONFIG_REPO_PATH/.sap_deployment_automation/$WORKLOAD_ZONE_NAME"
control_plane_environment_file_name="$CONFIG_REPO_PATH/.sap_deployment_automation/$CONTROL_PLANE_NAME"

deployer_tfstate_key=$CONTROL_PLANE_NAME.terraform.tfstate
export deployer_tfstate_key

echo ""
echo -e "${green}Deployment details:"
echo -e "-------------------------------------------------------------------------------$reset"

echo "CONTROL_PLANE_NAME:                  $CONTROL_PLANE_NAME"
echo "WORKLOAD_ZONE_NAME:                  $WORKLOAD_ZONE_NAME"
echo "Workload Zone Environment File:      $workload_environment_file_name"
echo "Control Plane Environment File:      $control_plane_environment_file_name"

echo "Environment:                         $ENVIRONMENT"
echo "Environment(filename):               $ENVIRONMENT_IN_FILENAME"
echo "Location:                            $LOCATION"
echo "Location(filename):                  $LOCATION_IN_FILENAME"
echo "Network:                             $NETWORK"
echo "Network(filename):                   $NETWORK_IN_FILENAME"

if [ "$ENVIRONMENT" != "$ENVIRONMENT_IN_FILENAME" ]; then
	echo "##vso[task.logissue type=error]The environment setting in $WORKLOAD_ZONE_TFVARS_FILENAME '$ENVIRONMENT' does not match the $WORKLOAD_ZONE_TFVARS_FILENAME file name '$ENVIRONMENT_IN_FILENAME'. Filename should have the pattern [ENVIRONMENT]-[REGION_CODE]-[NETWORK_LOGICAL_NAME]-INFRASTRUCTURE"
	exit 2
fi

if [ "$LOCATION" != "$LOCATION_IN_FILENAME" ]; then
	echo "##vso[task.logissue type=error]The location setting in $WORKLOAD_ZONE_TFVARS_FILENAME '$LOCATION' does not match the $WORKLOAD_ZONE_TFVARS_FILENAME file name '$LOCATION_IN_FILENAME'. Filename should have the pattern [ENVIRONMENT]-[REGION_CODE]-[NETWORK_LOGICAL_NAME]-INFRASTRUCTURE"
	exit 2
fi

if [ "$NETWORK" != "$NETWORK_IN_FILENAME" ]; then
	echo "##vso[task.logissue type=error]The network_logical_name setting in $WORKLOAD_ZONE_TFVARS_FILENAME '$NETWORK' does not match the $WORKLOAD_ZONE_TFVARS_FILENAME file name '$NETWORK_IN_FILENAME-. Filename should have the pattern [ENVIRONMENT]-[REGION_CODE]-[NETWORK_LOGICAL_NAME]-INFRASTRUCTURE"
	exit 2
fi

if is_valid_id "$APPLICATION_CONFIGURATION_ID" "/providers/Microsoft.AppConfiguration/configurationStores/"; then
	application_configuration_name=$(echo "$APPLICATION_CONFIGURATION_ID" | cut -d '/' -f 9)
	DEPLOYER_KEYVAULT=$(getVariableFromApplicationConfiguration "$APPLICATION_CONFIGURATION_ID" "${CONTROL_PLANE_NAME}_KeyVaultName" "${CONTROL_PLANE_NAME}")
	key_vault_id=$(getVariableFromApplicationConfiguration "$APPLICATION_CONFIGURATION_ID" "${CONTROL_PLANE_NAME}_KeyVaultResourceId" "${CONTROL_PLANE_NAME}")
	if [ -z "$key_vault_id" ]; then
		echo "##vso[task.logissue type=warning]Key '${CONTROL_PLANE_NAME}_KeyVaultResourceId' was not found in the application configuration ( '$application_configuration_name' )."
	fi
	tfstate_resource_id=$(getVariableFromApplicationConfiguration "$APPLICATION_CONFIGURATION_ID" "${CONTROL_PLANE_NAME}_TerraformRemoteStateStorageAccountId" "${CONTROL_PLANE_NAME}")
	if [ -z "$tfstate_resource_id" ]; then
		echo "##vso[task.logissue type=warning]Key '${CONTROL_PLANE_NAME}_TerraformRemoteStateStorageAccountId' was not found in the application configuration ( '$application_configuration_name' )."
	fi
	workload_key_vault=$(getVariableFromApplicationConfiguration "$APPLICATION_CONFIGURATION_ID" "${WORKLOAD_ZONE_NAME}_KeyVaultName" "${WORKLOAD_ZONE_NAME}")

	management_subscription_id=$(getVariableFromApplicationConfiguration "$APPLICATION_CONFIGURATION_ID" "${CONTROL_PLANE_NAME}_SubscriptionId" "${CONTROL_PLANE_NAME}")
	TF_VAR_management_subscription_id=${management_subscription_id}
	export TF_VAR_management_subscription_id
else
	print_banner "$banner_title" "APPLICATION_CONFIGURATION_ID was not found" "info"
	echo "##vso[task.logissue type=warning]Variable APPLICATION_CONFIGURATION_ID was not defined."
	load_config_vars "${control_plane_environment_file_name}" "DEPLOYER_KEYVAULT" "tfstate_resource_id"
	key_vault_id=$(az resource list --name "${DEPLOYER_KEYVAULT}" --subscription "$ARM_SUBSCRIPTION_ID" --resource-type Microsoft.KeyVault/vaults --query "[].id | [0]" -o tsv)
fi

if [ -z "$DEPLOYER_KEYVAULT" ]; then
	echo "##vso[task.logissue type=error]Key vault name (${CONTROL_PLANE_NAME}_KeyVaultName) was not found in the application configuration ( '$application_configuration_name' nor was it defined in ${workload_environment_file_name})."
	exit 2
fi

if [ -z "$tfstate_resource_id" ]; then
	echo "##vso[task.logissue type=error]Terraform state storage account resource id ('${CONTROL_PLANE_NAME}_TerraformRemoteStateStorageAccountId') was not found in the application configuration ( '$application_configuration_name' nor was it defined in ${workload_environment_file_name})."
	exit 2
fi

export TF_VAR_spn_keyvault_id=${key_vault_id}

terraform_storage_account_name=$(echo "$tfstate_resource_id" | cut -d '/' -f 9)
terraform_storage_account_resource_group_name=$(echo "$tfstate_resource_id" | cut -d '/' -f 5)
terraform_storage_account_subscription_id=$(echo "$tfstate_resource_id" | cut -d '/' -f 3)

export terraform_storage_account_name
export terraform_storage_account_resource_group_name
export terraform_storage_account_subscription_id
TF_VAR_tfstate_resource_id=${tfstate_resource_id}
export TF_VAR_tfstate_resource_id

export workload_key_vault

echo ""
echo -e "${green}Terraform parameter information:"
echo -e "-------------------------------------------------------------------------------$reset"

echo "System TFvars:                       $WORKLOAD_ZONE_TFVARS_FILENAME"
echo "Deployer statefile:                  $deployer_tfstate_key"
echo "Workload statefile:                  $landscape_tfstate_key"
echo "Deployer Key vault:                  $DEPLOYER_KEYVAULT"
echo "Statefile subscription:              $terraform_storage_account_subscription_id"
echo "Statefile storage account:           $terraform_storage_account_name"
echo ""
echo "Target subscription:                 $ARM_SUBSCRIPTION_ID"

cd "$CONFIG_REPO_PATH/LANDSCAPE/$WORKLOAD_ZONE_FOLDERNAME" || exit

cd "$CONFIG_REPO_PATH/LANDSCAPE/$WORKLOAD_ZONE_FOLDERNAME" || exit
if "$SAP_AUTOMATION_REPO_PATH/deploy/scripts/remover_v2.sh" --parameter_file "$WORKLOAD_ZONE_TFVARS_FILENAME" --type sap_landscape \
	--control_plane_name "${CONTROL_PLANE_NAME}" --application_configuration_name "${APPLICATION_CONFIGURATION_NAME}" \
	--workload_zone_name "${WORKLOAD_ZONE_NAME}" \
	--ado --auto-approve; then
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

		variable_value=$(az pipelines variable-group variable list --group-id "${VARIABLE_GROUP_ID}" --query "CONTROL_PLANE_NAME.value" --out tsv)
		if [ ${#variable_value} != 0 ]; then
			az pipelines variable-group variable delete --group-id "${VARIABLE_GROUP_ID}" --name CONTROL_PLANE_NAME --yes --only-show-errors
		fi

		variable_value=$(az pipelines variable-group variable list --group-id "${VARIABLE_GROUP_ID}" --query "APPLICATION_CONFIGURATION_ID.value" --out tsv)
		if [ ${#variable_value} != 0 ]; then
			az pipelines variable-group variable delete --group-id "${VARIABLE_GROUP_ID}" --name APPLICATION_CONFIGURATION_ID --yes --only-show-errors
		fi
	fi
fi
exit $return_code
