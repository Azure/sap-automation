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
	echo "##vso[build.updatebuildnumber]Setting the deployment credentials for the Key Vault defined in $ZONE"
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

banner_title="Store Secrets in Key Vault"
SCRIPT_NAME="$(basename "$0")"
print_banner "$banner_title" "Starting $SCRIPT_NAME" "info"

return_code=0

cd "${CONFIG_REPO_PATH}" || exit
echo -e "$green--- Pushing the changes to the repository ---$reset"
# Pull changes if there are other deployment jobs
# Pull changes if there are other deployment jobs
if [ "$PLATFORM" == "devops" ]; then
	git pull -q origin "$BUILD_SOURCEBRANCHNAME"
	git checkout -q "$BUILD_SOURCEBRANCHNAME"
elif [ "$PLATFORM" == "github" ]; then
	git pull -q origin "$GITHUB_REF_NAME"
fi

echo -e "$green--- Validations ---$reset"
if [ "$USE_MSI" != "true" ]; then
	print_banner "$banner_title" "Using Service Principals for deployment" "info"

	if ! printenv ARM_SUBSCRIPTION_ID; then
		echo "##vso[task.logissue type=error]Variable ARM_SUBSCRIPTION_ID was not defined in the $VARIABLE_GROUP variable group."
		exit 2
	fi

	if ! printenv ARM_CLIENT_ID; then
		echo "##vso[task.logissue type=error]Variable ARM_CLIENT_ID was not defined in the $VARIABLE_GROUP variable group."
		exit 2
	fi

	if ! printenv ARM_CLIENT_SECRET; then
		echo "##vso[task.logissue type=error]Variable ARM_CLIENT_SECRET was not defined in the $VARIABLE_GROUP variable group."
		exit 2
	fi

	if ! printenv ARM_TENANT_ID; then
		echo "##vso[task.logissue type=error]Variable ARM_TENANT_ID was not defined in the $VARIABLE_GROUP variable group."
		exit 2
	fi
else
	print_banner "$banner_title" "Using Managed Identities for deployment" "info"
fi

# Print the execution environment details
print_header

if [ "$PLATFORM" == "devops" ]; then
	# Configure DevOps
	configure_devops

	if ! get_variable_group_id "$VARIABLE_GROUP" "VARIABLE_GROUP_ID"; then
		echo -e "$bold_red--- Variable group $VARIABLE_GROUP not found ---$reset"
		echo "##vso[task.logissue type=error]Variable group $VARIABLE_GROUP not found."
		exit 2
	fi
	export VARIABLE_GROUP_ID

fi
az account set --subscription "$ARM_SUBSCRIPTION_ID"

echo -e "$green--- Read parameter values ---$reset"

deployer_tfstate_key=$CONTROL_PLANE_NAME.terraform.tfstate
export deployer_tfstate_key

if [ ! -v APPLICATION_CONFIGURATION_ID ]; then
	APPLICATION_CONFIGURATION_ID=$(az graph query -q "Resources | join kind=leftouter (ResourceContainers | where type=='microsoft.resources/subscriptions' | project subscription=name, subscriptionId) on subscriptionId | where name == '$APPLICATION_CONFIGURATION_NAME' | project id, name, subscription" --query data[0].id --output tsv)
	export APPLICATION_CONFIGURATION_ID
fi

if is_valid_id "$APPLICATION_CONFIGURATION_ID" "/providers/Microsoft.AppConfiguration/configurationStores/"; then

	key_vault_id=$(getVariableFromApplicationConfiguration "$APPLICATION_CONFIGURATION_ID" "${CONTROL_PLANE_NAME}_KeyVaultResourceId" "${CONTROL_PLANE_NAME}")
	if [ -z "$key_vault_id" ]; then
		echo "##vso[task.logissue type=warning]Key '${CONTROL_PLANE_NAME}_KeyVaultResourceId' was not found in the application configuration ( '$APPLICATION_CONFIGURATION_NAME' )."
	fi
else
	load_config_vars "${workload_environment_file_name}" "keyvault"
	key_vault="$keyvault"
	key_vault_id=$(az resource list --name "${keyvault}" --subscription "$ARM_SUBSCRIPTION_ID" --resource-type Microsoft.KeyVault/vaults --query "[].id | [0]" -o tsv)

fi

keyvault_subscription_id=$(echo "$key_vault_id" | cut -d '/' -f 3)
key_vault=$(echo "$key_vault_id" | cut -d '/' -f 9)

if [ -z "$key_vault" ]; then
	echo "##vso[task.logissue type=error]Key vault name (${CONTROL_PLANE_NAME}_KeyVaultName) was not found in the application configuration ( '$application_configuration_name')."
	exit 2
fi

# Enable case-insensitive matching
shopt -s nocasematch

if [ "$USE_MSI" != "True" ]; then
	set_secrets_args=("--prefix" "$ZONE" "--key_vault" "${key_vault}" "--keyvault_subscription" "$keyvault_subscription_id" "--subscription" "$ARM_SUBSCRIPTION_ID" "--client_id" "$ARM_CLIENT_ID" "--client_secret" "$ARM_CLIENT_SECRET" "--client_tenant_id" "$ARM_TENANT_ID" --ado)

	if [ "$PLATFORM" == "github" ] && [ -n "${GH_PAT:-}" ]; then
		set_secrets_args=("--prefix" "$ZONE" "--key_vault" "${key_vault}" "--keyvault_subscription" "$keyvault_subscription_id" "--subscription" "$ARM_SUBSCRIPTION_ID" "--client_id" "$ARM_CLIENT_ID" "--client_secret" "$ARM_CLIENT_SECRET" "--client_tenant_id" "$ARM_TENANT_ID" "--gh_pat" "$GH_PAT"  --ado)
	fi

	if "$SAP_AUTOMATION_REPO_PATH/deploy/scripts/set_secrets_v2.sh" "${set_secrets_args[@]}"; then
		return_code=$?
	else
		return_code=$?
		print_banner "$banner_title - Set secrets" "Set_secrets failed" "error"
		exit $return_code
	fi
else
	set_secrets_args=("--prefix" "$ZONE" "--key_vault" "${key_vault}" "--keyvault_subscription" "$keyvault_subscription_id" "--subscription" "$ARM_SUBSCRIPTION_ID" "--client_id" "$ARM_CLIENT_ID" "--client_tenant_id" "$ARM_TENANT_ID" --msi  --ado)

	if [ "$PLATFORM" == "github" ] && [ -n "${GH_PAT:-}" ]; then
		set_secrets_args=("--prefix" "$ZONE" "--key_vault" "${key_vault}" "--keyvault_subscription" "$keyvault_subscription_id" "--subscription" "$ARM_SUBSCRIPTION_ID" "--client_id" "$ARM_CLIENT_ID" "--client_tenant_id" "$ARM_TENANT_ID" "--gh_pat" "$GH_PAT" --msi  --ado)
	fi


	if "$SAP_AUTOMATION_REPO_PATH/deploy/scripts/set_secrets_v2.sh" "${set_secrets_args[@]}"; then
		return_code=$?
	else
		return_code=$?
		print_banner "$banner_title - Set secrets" "Set_secrets failed" "error"
		exit $return_code
	fi
fi

# Disable case-insensitive matching to restore default behavior
shopt -u nocasematch

print_banner "$banner_title" "Exiting $SCRIPT_NAME" "info"

exit $return_code
