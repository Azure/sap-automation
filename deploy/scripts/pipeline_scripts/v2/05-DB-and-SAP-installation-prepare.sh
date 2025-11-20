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
	echo "##vso[build.updatebuildnumber]Deploying ${SAP_SYSTEM_CONFIGURATION_NAME} using BoM ${BOM_BASE_NAME}"
fi
banner_title="SAP Configuration and Installation Preparation"
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

# Print the execution environment details
print_header
echo ""

# Platform-specific configuration
if [ "$PLATFORM" == "devops" ]; then
	DEBUG=false

	if [ "${SYSTEM_DEBUG:-False}" = True ]; then
		set -x
		DEBUG=True
		echo "Environment variables:"
		printenv | sort

	fi
	export DEBUG
	set -eu
	# Configure DevOps
	configure_devops

	platform_flag="--ado"

	if ! get_variable_group_id "$VARIABLE_GROUP" "VARIABLE_GROUP_ID"; then
		echo -e "$bold_red--- Variable group $VARIABLE_GROUP not found ---$reset"
		echo "##vso[task.logissue type=error]Variable group $VARIABLE_GROUP not found."
		exit 2
	fi
	export VARIABLE_GROUP_ID
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

WORKLOAD_ZONE_NAME=$(basename "${SAP_SYSTEM_CONFIGURATION_NAME}" | cut -d'-' -f1-3)
SID=$(basename "${SAP_SYSTEM_CONFIGURATION_NAME}" | cut -d'-' -f4)

print_banner "$banner_title" "Starting $SCRIPT_NAME" "info"

if is_valid_id "$APPLICATION_CONFIGURATION_ID" "/providers/Microsoft.AppConfiguration/configurationStores/"; then

	key_vault_id=$(getVariableFromApplicationConfiguration "$APPLICATION_CONFIGURATION_ID" "${WORKLOAD_ZONE_NAME}_KeyVaultResourceId" "${WORKLOAD_ZONE_NAME}")
	key_vault=$(echo "$key_vault_id" | cut -d'/' -f9)
	key_vault_subscription_id=$(echo "$key_vault_id" | cut -d'/' -f3)

	tfstate_resource_id=$(getVariableFromApplicationConfiguration "$APPLICATION_CONFIGURATION_ID" "${CONTROL_PLANE_NAME}_TerraformRemoteStateStorageAccountId" "${CONTROL_PLANE_NAME}")
	tfstate_subscription_id=$(echo "$tfstate_resource_id" | cut -d'/' -f3)
fi

cd "$CONFIG_REPO_PATH" || exit

parameters_filename="$CONFIG_REPO_PATH/SYSTEM/${SAP_SYSTEM_CONFIGURATION_NAME}/sap-parameters.yaml"

echo -e "$green--- Validations ---$reset"

if [ -z "$ARM_SUBSCRIPTION_ID" ]; then
	echo "##vso[task.logissue type=error]Variable ARM_SUBSCRIPTION_ID was not defined."
	exit 2
fi

if [ "azure pipelines" == "$THIS_AGENT" ]; then
	echo "##vso[task.logissue type=error]Please use a self hosted agent for this playbook. Define it in the SDAF-$ENVIRONMENT variable group"
	exit 2
fi

# Check if running on deployer
if [[ ! -f /etc/profile.d/deploy_server.sh ]]; then
	configureNonDeployer "${tf_version:-1.13.3}"
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

	LogonToAzure "${USE_MSI:-true}"
	return_code=$?
	if [ 0 != $return_code ]; then
		echo -e "$bold_red--- Login failed ---$reset"
		echo "##vso[task.logissue type=error]az login failed."
		exit $return_code
	fi
fi

az account set --subscription "$APPLICATION_CONFIGURATION_SUBSCRIPTION_ID" --output none --only-show-errors

echo "SID:                                 ${SID}"
echo "Workload Zone Name:                  $WORKLOAD_ZONE_NAME"
echo "Keyvault:                            $key_vault"
echo "SAP Application BoM:                 $BOM_BASE_NAME"

echo "Folder:                              $CONFIG_REPO_PATH/SYSTEM/${SAP_SYSTEM_CONFIGURATION_NAME}"
echo "Hosts file:                          ${SID}_hosts.yaml"
echo "sap_parameters_file:                 $parameters_filename"

cd "$CONFIG_REPO_PATH/SYSTEM/${SAP_SYSTEM_CONFIGURATION_NAME}"

echo -e "$green--- Add BOM Base Name and SAP FQDN to sap-parameters.yaml ---$reset"
sed -i 's|bom_base_name:.*|bom_base_name:                 '"$BOM_BASE_NAME"'|' sap-parameters.yaml

mkdir -p artifacts

echo "Workload Key Vault:                  ${key_vault}"

if [ ${EXTRA_PARAMETERS:-''} = '$(EXTRA_PARAMETERS)' ]; then
	new_parameters=$PIPELINE_EXTRA_PARAMETERS
else
	if [ "$PLATFORM" == "devops" ]; then
		echo "##vso[task.logissue type=warning]Extra parameters were provided - ${EXTRA_PARAMETERS:-''}"
	fi
	new_parameters="${EXTRA_PARAMETERS:-''} $PIPELINE_EXTRA_PARAMETERS"
fi

az account set --subscription "$tfstate_subscription_id" --output none --only-show-errors

echo "##vso[task.setvariable variable=FOLDER;isOutput=true]$CONFIG_REPO_PATH/SYSTEM/$SAP_SYSTEM_CONFIGURATION_NAME"
echo "##vso[task.setvariable variable=HOSTS;isOutput=true]${SID}_hosts.yaml"
echo "##vso[task.setvariable variable=NEW_PARAMETERS;isOutput=true]${new_parameters}"
echo "##vso[task.setvariable variable=PASSWORD_KEY_NAME;isOutput=true]${WORKLOAD_ZONE_NAME}-sid-password"
echo "##vso[task.setvariable variable=SAP_PARAMETERS;isOutput=true]sap-parameters.yaml"
echo "##vso[task.setvariable variable=SID;isOutput=true]${SID}"
echo "##vso[task.setvariable variable=SSH_KEY_NAME;isOutput=true]${WORKLOAD_ZONE_NAME}-sid-sshkey"
echo "##vso[task.setvariable variable=USERNAME_KEY_NAME;isOutput=true]${WORKLOAD_ZONE_NAME}-sid-username"

az keyvault secret show --name "${WORKLOAD_ZONE_NAME}-sid-sshkey" --vault-name "$key_vault" --subscription "$key_vault_subscription_id" --query value -o tsv >"artifacts/${SAP_SYSTEM_CONFIGURATION_NAME}_sshkey"
cp sap-parameters.yaml artifacts/.
cp "${SID}_hosts.yaml" artifacts/.
chmod 600 artifacts/${SAP_SYSTEM_CONFIGURATION_NAME}_sshkey

2> >(while read line; do (echo >&2 "STDERROR: $line"); done)

echo -e "$green--- Done ---$reset"
print_banner "$banner_title" "Exiting $SCRIPT_NAME" "info"
exit 0
