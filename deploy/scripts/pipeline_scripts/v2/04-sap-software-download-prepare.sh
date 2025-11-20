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
	echo "##vso[build.updatebuildnumber]Prepare for software download"
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

if [ "$PLATFORM" == "devops" ]; then
	if [ "${SYSTEM_DEBUG:-False}" = True ]; then
		set -x
		DEBUG=True
		echo "Environment variables:"
		printenv | sort
	fi
	export DEBUG
	AZURE_DEVOPS_EXT_PAT=$SYSTEM_ACCESSTOKEN
	export AZURE_DEVOPS_EXT_PAT
elif [ "$PLATFORM" == "github" ]; then
	echo "Configuring for GitHub Actions"
fi

cd "$CONFIG_REPO_PATH" || exit

ENVIRONMENT=$(echo "${CONTROL_PLANE_NAME}" | awk -F'-' '{print $1}' | xargs)
LOCATION=$(echo "${CONTROL_PLANE_NAME}" | awk -F'-' '{print $2}' | xargs)
NETWORK=$(echo "${CONTROL_PLANE_NAME}" | awk -F'-' '{print $3}' | xargs)

automation_config_directory="${CONFIG_REPO_PATH}/.sap_deployment_automation"
environment_file_name=$(get_configuration_file "$automation_config_directory" "$ENVIRONMENT" "$LOCATION" "$NETWORK")

# Print the execution environment details
print_header
echo ""

# Platform-specific configuration
if [ "$PLATFORM" == "devops" ]; then
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
	echo "Configuring for GitHub Actions"
	export VARIABLE_GROUP_ID="${CONTROL_PLANE_NAME}"
	git config --global --add safe.directory "$CONFIG_REPO_PATH"
	platform_flag="--github"
else
	platform_flag=""
fi

echo -e "$green--- Validations ---$reset"
if [ "$PLATFORM" == "devops" ]; then
	if [ ! -f "${environment_file_name}" ]; then
		echo -e "$bold_red--- ${environment_file_name} was not found ---$reset"
		echo "##vso[task.logissue type=error]File ${environment_file_name} was not found."
		exit 2
	fi
	if [ -z "$ARM_SUBSCRIPTION_ID" ]; then
		echo "##vso[task.logissue type=error]Variable ARM_SUBSCRIPTION_ID was not defined."
		exit 2
	fi

	if [ "azure pipelines" == $THIS_AGENT ]; then
		echo "##vso[task.logissue type=error]Please use a self hosted agent for this playbook. Define it in the SDAF-$(environment_code) variable group"
		exit 2
	fi

	if [ "your S User" == "$SUSERNAME" ]; then
		echo "##vso[task.logissue type=error]Please define the S-Username variable."
		exit 2
	fi

	if [ "your S user password" == "$SPASSWORD" ]; then
		echo "##vso[task.logissue type=error]Please define the S-Password variable."
		exit 2
	fi
elif [ "$PLATFORM" == "github" ]; then
	if [ ! -f "${environment_file_name}" ]; then
		echo "::error title=Missing File::File '${environment_file_name}' was not found"
		exit 2
	fi
	if [ -z "$ARM_SUBSCRIPTION_ID" ]; then
		echo "::error title=Missing Variable::Variable 'ARM_SUBSCRIPTION_ID' was not defined."
		exit 2
	fi

	if [ -z "$SUSERNAME" ]; then
		echo "::error title=Missing Variable ::Please define the S-Username variable."
		exit 2
	fi

	if [ -z "$SPASSWORD" ]; then
		echo "::error title=Missing Secret::Please define the S-Password secret."
		exit 2
	fi
fi

echo -e "$green--- az login ---$reset"

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

echo " ##vso[task.setvariable variable=KV_NAME;isOutput=true]$DEPLOYER_KEYVAULT"

echo "Keyvault: $DEPLOYER_KEYVAULT"


echo -e "$green--- BoM $BOM ---$reset"
echo "Downloading BoM defined in $BOM"

echo -e "$green--- Set S-Username and S-Password in the key_vault if not yet there ---$reset"

SUsername_from_Keyvault=$(az keyvault secret list --vault-name "$DEPLOYER_KEYVAULT" --subscription "$ARM_SUBSCRIPTION_ID" --query "[].{Name:name} | [? contains(Name,'S-Username')] | [0]" -o tsv)
if [ "$SUsername_from_Keyvault" == "$SUSERNAME" ]; then
  echo -e "$green--- $SUsername present in keyvault. In case of download errors check that user and password are correct ---$reset"
else
  echo -e "$green--- Setting the S username in key vault ---$reset"
  az keyvault secret set --name "S-Username" --vault-name "$DEPLOYER_KEYVAULT" --value="$SUSERNAME" --subscription "$ARM_SUBSCRIPTION_ID" --expires "$(date -d '+1 year' -u +%Y-%m-%dT%H:%M:%SZ)" --output none
fi

SPassword_from_Keyvault=$(az keyvault secret list --vault-name "$DEPLOYER_KEYVAULT" --subscription "$ARM_SUBSCRIPTION_ID" --query "[].{Name:name} | [? contains(Name,'S-Password')] | [0]" -o tsv)
if [ "$SPASSWORD" == "$SPassword_from_Keyvault" ]; then
  echo -e "$green--- Password present in keyvault. In case of download errors check that user and password are correct ---$reset"
else
  echo -e "$green--- Setting the S user name password in key vault ---$reset"
  az keyvault secret set --name "S-Password" --vault-name "$DEPLOYER_KEYVAULT" --value "$SPASSWORD" --subscription "$ARM_SUBSCRIPTION_ID" --expires "$(date -d '+1 year' -u +%Y-%m-%dT%H:%M:%SZ)" --output none
fi

if [ "$PLATFORM" == "devops" ]; then
	echo "##vso[task.setvariable variable=SUSERNAME;isOutput=true]$SUSERNAME"
	echo "##vso[task.setvariable variable=SPASSWORD;isOutput=true]$SPASSWORD"
	echo "##vso[task.setvariable variable=BOM_NAME;isOutput=true]$BOM"
elif [ "$PLATFORM" == "github" ]; then
	start_group "Download SAP Bill of Materials"

	az account set --subscription "$ARM_SUBSCRIPTION_ID" --output none
	return_code=0

	sample_path=${SAMPLE_REPO_PATH}/SAP
	command="ansible-playbook \
		-e download_directory=${GITHUB_WORKSPACE} \
		-e s_user=${SUSERNAME} \
		-e BOM_directory=${sample_path} \
		-e bom_base_name='${BOM}' \
		-e deployer_kv_name=${DEPLOYER_KEYVAULT} \
		-e check_storage_account=${re_download} \
		-e orchestration_ansible_user=root \
		${EXTRA_PARAMETERS} \
		${SAP_AUTOMATION_REPO_PATH}/deploy/ansible/playbook_bom_downloader.yaml"
	echo "Executing [$command]"
	eval $command
	return_code=$?

	end_group
	exit $return_code
fi

echo -e "$green--- Done ---$reset"
exit 0
