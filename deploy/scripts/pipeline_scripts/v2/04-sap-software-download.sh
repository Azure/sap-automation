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
	echo "##vso[build.updatebuildnumber]Downloading the software defined in $BOM_NAME"
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

DEBUG=false

if [ "${SYSTEM_DEBUG:-False}" = True ]; then
  set -x
  DEBUG=True
	echo "Environment variables:"
	printenv | sort

fi
export DEBUG
set -eu

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


cd "$CONFIG_REPO_PATH" || exit

sample_path="$SAMPLE_REPO_PATH/SAP"

if [ "$PLATFORM" == "devops" ]; then
	echo -e "$green--- Checkout $BUILD_SOURCEBRANCHNAME ---$reset_formatting"
	git checkout -q "$BUILD_SOURCEBRANCHNAME"
elif [ "$PLATFORM" == "github" ]; then
	echo -e "$green--- Checkout $GITHUB_REF_NAME ---$reset_formatting"
	git checkout -q "$GITHUB_REF_NAME"
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

sapbits_location_base_path=$(getVariableFromApplicationConfiguration "$APPLICATION_CONFIGURATION_ID" "${CONTROL_PLANE_NAME}_SAPMediaPath" "${CONTROL_PLANE_NAME}")


command="ansible-playbook -e download_directory=$AGENT_TEMP_DIRECTORY \
-e BOM_directory=${sample_path} \
-e bom_base_name=$BOM_NAME \
-e deployer_kv_name=$DEPLOYER_KEYVAULT \
-e check_storage_account=$CHECK_STORAGE_ACCOUNT \
-e orchestration_ansible_user=$USER \
-e sapbits_location_base_path=$sapbits_location_base_path \
 $EXTRA_PARAMETERS $SAP_AUTOMATION_REPO_PATH/deploy/ansible/playbook_bom_downloader.yaml"

echo "##[section]Executing [$command]..."
echo "##[group]- output"
eval $command
return_code=$?
echo "##[endgroup]"
exit $return_code
