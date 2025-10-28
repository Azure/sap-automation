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

echo "##vso[build.updatebuildnumber]Removing the SAP System defined in $SAP_SYSTEM_FOLDERNAME"

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

if ! get_variable_group_id "$VARIABLE_GROUP" "VARIABLE_GROUP_ID" ;
then
	echo -e "$bold_red--- Variable group $VARIABLE_GROUP not found ---$reset"
	echo "##vso[task.logissue type=error]Variable group $VARIABLE_GROUP not found."
	exit 2
fi
export VARIABLE_GROUP_ID

print_banner "$banner_title" "Starting $SCRIPT_NAME" "info"

tfvarsFile="SYSTEM/$SAP_SYSTEM_FOLDERNAME/$SAP_SYSTEM_TFVARS_FILENAME"

cd "${CONFIG_REPO_PATH}" || exit
mkdir -p .sap_deployment_automation
git checkout -q "$BUILD_SOURCEBRANCHNAME"

if [ ! -f "$CONFIG_REPO_PATH/$tfvarsFile" ]; then
	print_banner "$banner_title" "$SAP_SYSTEM_TFVARS_FILENAME was not found" "error"
	echo "##vso[task.logissue type=error]File $SAP_SYSTEM_TFVARS_FILENAME was not found."
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
SID=$(grep -m1 "^sid" "$tfvarsFile" | awk -F'=' '{print $2}' | tr -d ' \t\n\r\f"')

ENVIRONMENT_IN_FILENAME=$(echo $SAP_SYSTEM_FOLDERNAME | awk -F'-' '{print $1}')
LOCATION_CODE_IN_FILENAME=$(echo $SAP_SYSTEM_FOLDERNAME | awk -F'-' '{print $2}')
LOCATION_IN_FILENAME=$(get_region_from_code "$LOCATION_CODE_IN_FILENAME" || true)
NETWORK_IN_FILENAME=$(echo $SAP_SYSTEM_FOLDERNAME | awk -F'-' '{print $3}')
SID_IN_FILENAME=$(echo $SAP_SYSTEM_FOLDERNAME | awk -F'-' '{print $4}')

WORKLOAD_ZONE_NAME=$(echo "$SAP_SYSTEM_FOLDERNAME" | cut -d'-' -f1-3)
landscape_tfstate_key="${WORKLOAD_ZONE_NAME}-INFRASTRUCTURE.terraform.tfstate"
export landscape_tfstate_key

automation_config_directory=$CONFIG_REPO_PATH/.sap_deployment_automation/
if [ "v1" == "${SDAFWZ_CALLER_VERSION:-v2}" ] && [ -f "${automation_config_directory}${ENVIRONMENT}${LOCATION_CODE_IN_FILENAME}" ]; then
	workload_environment_file_name="${automation_config_directory}${ENVIRONMENT}${LOCATION_CODE_IN_FILENAME}"
else
	workload_environment_file_name="${automation_config_directory}${ENVIRONMENT}${LOCATION_CODE_IN_FILENAME}${NETWORK}"
fi


deployer_tfstate_key=$(getVariableFromVariableGroup "${VARIABLE_GROUP_ID}" "Deployer_State_FileName" "${workload_environment_file_name}" "deployer_tfstate_key")
export deployer_tfstate_key
CONTROL_PLANE_NAME=$(echo "$deployer_tfstate_key" | cut -d'-' -f1-3)

terraform_storage_account_name=$(getVariableFromVariableGroup "${VARIABLE_GROUP_ID}" "Terraform_Remote_Storage_Account_Name" "${workload_environment_file_name}" "REMOTE_STATE_SA")
tfstate_resource_id=$(az graph query -q "Resources | join kind=leftouter (ResourceContainers | where type=='microsoft.resources/subscriptions' | project subscription=name, subscriptionId) on subscriptionId | where name == '$terraform_storage_account_name' | project id, name, subscription" --query data[0].id --output tsv)

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
	echo "##vso[task.logissue type=error]The environment setting in $SAP_SYSTEM_TFVARS_FILENAME '$ENVIRONMENT' does not match the $SAP_SYSTEM_TFVARS_FILENAME file name '$ENVIRONMENT_IN_FILENAME'. Filename should have the pattern [ENVIRONMENT]-[REGION_CODE]-[NETWORK_LOGICAL_NAME]-INFRASTRUCTURE"
	exit 2
fi

if [ "$LOCATION" != "$LOCATION_IN_FILENAME" ]; then
	echo "##vso[task.logissue type=error]The location setting in $SAP_SYSTEM_TFVARS_FILENAME '$LOCATION' does not match the $SAP_SYSTEM_TFVARS_FILENAME file name '$LOCATION_IN_FILENAME'. Filename should have the pattern [ENVIRONMENT]-[REGION_CODE]-[NETWORK_LOGICAL_NAME]-INFRASTRUCTURE"
	exit 2
fi

if [ "$NETWORK" != "$NETWORK_IN_FILENAME" ]; then
	echo "##vso[task.logissue type=error]The network_logical_name setting in $SAP_SYSTEM_TFVARS_FILENAME '$NETWORK' does not match the $SAP_SYSTEM_TFVARS_FILENAME file name '$NETWORK_IN_FILENAME-. Filename should have the pattern [ENVIRONMENT]-[REGION_CODE]-[NETWORK_LOGICAL_NAME]-INFRASTRUCTURE"
	exit 2
fi

if [ "$SID" != "$SID_IN_FILENAME" ]; then
	echo "##vso[task.logissue type=error]The sid setting in $SAP_SYSTEM_TFVARS_FILENAME '$SID' does not match the $SAP_SYSTEM_TFVARS_FILENAME file name '$SID_IN_FILENAME-. Filename should have the pattern [ENVIRONMENT]-[REGION_CODE]-[NETWORK_LOGICAL_NAME]-[SID]"
	exit 2
fi

if [ -z "$DEPLOYER_KEYVAULT" ]; then
	echo "##vso[task.logissue type=error]Key vault was not defined in ${workload_environment_file_name})."
	exit 2
fi

if [ -z "$tfstate_resource_id" ]; then
	echo "##vso[task.logissue type=error]Terraform state storage account resource id was not found in ${workload_environment_file_name})."
	exit 2
fi


terraform_storage_account_resource_group_name=$(echo "$tfstate_resource_id" | cut -d '/' -f 5)
terraform_storage_account_subscription_id=$(echo "$tfstate_resource_id" | cut -d '/' -f 3)

export terraform_storage_account_name
export terraform_storage_account_resource_group_name
export terraform_storage_account_subscription_id
TF_VAR_tfstate_resource_id=${tfstate_resource_id}
export TF_VAR_tfstate_resource_id

echo ""
echo -e "${green}Terraform parameter information:"
echo -e "-------------------------------------------------------------------------------$reset"

echo "System TFvars:                       $SAP_SYSTEM_TFVARS_FILENAME"
echo "Deployer statefile:                  $deployer_tfstate_key"
echo "Workload statefile:                  $landscape_tfstate_key"
echo "Deployer Key vault:                  $DEPLOYER_KEYVAULT"
echo "Statefile subscription:              $terraform_storage_account_subscription_id"
echo "Statefile storage account:           $terraform_storage_account_name"
echo ""
echo "Target subscription:                 $ARM_SUBSCRIPTION_ID"

cd "$CONFIG_REPO_PATH/SYSTEM/$SAP_SYSTEM_FOLDERNAME" || exit

cd "$CONFIG_REPO_PATH/SYSTEM/$SAP_SYSTEM_FOLDERNAME" || exit
if ${SAP_AUTOMATION_REPO_PATH}/deploy/scripts/remover.sh \
	--parameterfile "$SAP_SYSTEM_TFVARS_FILENAME" \
	--landscape_tfstate_key "$landscape_tfstate_key" \
	--type sap_system \
	--state_subscription "${terraform_storage_account_subscription_id}" \
	--storageaccountname "${terraform_storage_account_name}" \
	--deployer_tfstate_key "${deployer_tfstate_key}" \
	--auto-approve; then
	return_code=$?
	print_banner "$banner_title" "The removal of $SAP_SYSTEM_TFVARS_FILENAME succeeded" "success" "Return code: ${return_code}"
else
	return_code=$?
	print_banner "$banner_title" "The removal of $SAP_SYSTEM_TFVARS_FILENAME failed" "error" "Return code: ${return_code}"
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

		if [ -f "$SAP_SYSTEM_TFVARS_FILENAME" ]; then
			git add "$SAP_SYSTEM_TFVARS_FILENAME"
			changed=1
		fi

		if [ -f "sap-parameters.yaml" ]; then
			git rm --ignore-unmatch -q "sap-parameters.yaml"
			changed=1
		fi

		if [ -f "${SID}_hosts.yaml" ]; then
			git rm --ignore-unmatch -q "${SID}_hosts.yaml"
			changed=1
		fi

		if [ -f "${SID}.md" ]; then
			git rm --ignore-unmatch -q "${SID}.md"
			changed=1
		fi

		if [ -f "${SID}_inventory.md" ]; then
			git rm --ignore-unmatch -q "${SID}_inventory.md"
			changed=1
		fi

		if [ -f "${SID}_virtual_machines.json" ]; then
			git rm --ignore-unmatch -q "${SID}_virtual_machines.json"
			changed=1
		fi

		if [ -d "logs" ]; then
			git rm -q -r --ignore-unmatch "logs"
			changed=1
		fi

		if [ 1 == $changed ]; then
			git config --global user.email "$BUILD_REQUESTEDFOREMAIL"
			git config --global user.name "$BUILD_REQUESTEDFOR"

			if git commit -m "Infrastructure for $SAP_SYSTEM_TFVARS_FILENAME removed. [skip ci]"; then
				if git -c http.extraheader="AUTHORIZATION: bearer $SYSTEM_ACCESSTOKEN" push --set-upstream origin "$BUILD_SOURCEBRANCHNAME" --force-with-lease; then
					echo "##vso[task.logissue type=warning]Removal of $SAP_SYSTEM_TFVARS_FILENAME updated in $BUILD_BUILDNUMBER"
				else
					echo "##vso[task.logissue type=error]Failed to push changes to $BUILD_SOURCEBRANCHNAME"
				fi
			fi
		fi
	fi
fi
exit $return_code
