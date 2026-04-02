#!/bin/bash
# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

green="\e[1;32m"

bold_red_underscore="\e[1;4;31m"
reset_formatting="\e[0m"

# Ensure that the exit status of a pipeline command is non-zero if any
# stage of the pipefile has a non-zero exit status.
set -o pipefail

#External helper functions
#. "$(dirname "${BASH_SOURCE[0]}")/deploy_utils.sh"
full_script_path="$(realpath "${BASH_SOURCE[0]}")"
script_directory="$(dirname "${full_script_path}")"

# Fail on any error, undefined variable, or pipeline failure
set -euo pipefail

# Enable debug mode if DEBUG is set to 'true'
if [[ "${DEBUG:-false}" == 'true' ]]; then
	# Enable debugging
	set -x
	# Exit on error
	set -o errexit
	echo "Environment variables:"
	printenv | sort
fi

# Constants
script_directory="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
readonly script_directory

SCRIPT_NAME="$(basename "$0")"
banner_title="Remover"

if [[ -f /etc/profile.d/deploy_server.sh ]]; then
	path=$(grep -m 1 "export PATH=" /etc/profile.d/deploy_server.sh | awk -F'=' '{print $2}' | xargs)
	export PATH=$path
fi

############################################################################################
# This function sources the provided helper scripts and checks if they exist.              #
# If a script is not found, it prints an error message and exits with a non-zero status.   #
# Arguments:                                                                               #
#   1. Array of helper script paths                                                        #
# Returns:                                                                                 #
#   0 on success, non-zero on failure                                                      #
# Usage:                     																				                       #
#   source_helper_scripts <helper_script1> <helper_script2> ...                            #
# Example:                   																				                       #
#   source_helper_scripts "script1.sh" "script2.sh"            														 #
############################################################################################

function source_helper_scripts() {
	local -a helper_scripts=("$@")
	for script in "${helper_scripts[@]}"; do
		if [[ -f "$script" ]]; then
			# shellcheck source=/dev/null
			source "$script"
		else
			echo "Helper script not found: $script"
			exit 1
		fi
	done
}


############################################################################################
# This function reads the SDAF environment variables.                                      #
# Arguments:                                                                               #
#   None                                                                                   #
# Returns:                                                                                 #
#   0 on success, non-zero on failure                                                      #
# Usage:                     																				                       #
#   remover_check_environment_variables                                                #
# Example:                   																				                       #
#   remover_check_environment_variables                                                #
############################################################################################

function remover_check_environment_variables() {
    if [ -v SDAF_CONTROL_PLANE_NAME ]; then
        CONTROL_PLANE_NAME="$SDAF_CONTROL_PLANE_NAME"
        TF_VAR_control_plane_name="$CONTROL_PLANE_NAME"
        TF_VAR_deployer_tfstate_key="${CONTROL_PLANE_NAME}-INFRASTRUCTURE.terraform.tfstate"
        export TF_VAR_control_plane_name
        export TF_VAR_deployer_tfstate_key
    fi

    if [ -v SDAF_WORKLOAD_ZONE_NAME ]; then
        WORKLOAD_ZONE_NAME="$SDAF_WORKLOAD_ZONE_NAME"
        TF_VAR_workload_zone_name="$WORKLOAD_ZONE_NAME"
        TF_VAR_landscape_tfstate_key="${WORKLOAD_ZONE_NAME}-INFRASTRUCTURE.terraform.tfstate"
        export TF_VAR_workload_zone_name
        export TF_VAR_landscape_tfstate_key
    fi

    if [ -v SDAF_APPLICATION_CONFIGURATION_NAME ]; then
        APPLICATION_CONFIGURATION_NAME="$SDAF_APPLICATION_CONFIGURATION_NAME"
        TF_VAR_application_configuration_id=$(az graph query -q "Resources | join kind=leftouter (ResourceContainers | where type=='microsoft.resources/subscriptions' | project subscription=name, subscriptionId) on subscriptionId | where name == '$APPLICATION_CONFIGURATION_NAME' | project id, name, subscription" --query data[0].id --output tsv)
        export TF_VAR_application_configuration_id
    fi

    if [ -v SDAF_TERRAFORM_STORAGE_ACCOUNT_NAME ]; then
        TERRAFORM_STORAGE_ACCOUNT_NAME="$SDAF_TERRAFORM_STORAGE_ACCOUNT_NAME"
        export TERRAFORM_STORAGE_ACCOUNT_NAME
		terraform_storage_account_name="$SDAF_TERRAFORM_STORAGE_ACCOUNT_NAME"
        getAndStoreTerraformStateStorageAccountDetails "${TERRAFORM_STORAGE_ACCOUNT_NAME}" ""
    fi

    return 0
}


############################################################################################
# Function to parse all the command line arguments passed to the script.                   #
# Arguments:                                                                               #
#   None                                                                                   #
# Returns:                                                                                 #
#   0 on success, non-zero on failure                                                      #
# Usage:                                                                                   #
#   parse_arguments                                                                        #
############################################################################################

function parse_arguments() {
	local input_opts
	approve=""
	input_opts=$(getopt -n remover_v2 -o p:t:o:d:l:s:n:c:w:ahig --longoptions type:,parameter_file:,storage_accountname:,deployer_tfstate_key:,landscape_tfstate_key:,state_subscription:,application_configuration_name:,control_plane_name:,workload_zone_name:,ado,auto-approve,help,github -- "$@")
	is_input_opts_valid=$?

	if [[ "${is_input_opts_valid}" != "0" ]]; then
		showhelp
		return 1
	fi

	eval set -- "$input_opts"
	while true; do
		case "$1" in
		-a | --ado)
			PLATFORM="ado"
			approve="--auto-approve"
			TF_IN_AUTOMATION=true
			export TF_IN_AUTOMATION
			shift
			;;
		-g | --github)
			PLATFORM="github"
			approve="--auto-approve"
			TF_IN_AUTOMATION=true
			export TF_IN_AUTOMATION
			shift
			;;
		-d | --deployer_tfstate_key)
			deployer_tfstate_key="$2"
			CONTROL_PLANE_NAME=$(echo "$deployer_tfstate_key" | cut -d'-' -f1-3)
			CONTROL_PLANE_NAME=$(echo "${CONTROL_PLANE_NAME}" | tr "[:lower:]" "[:upper:]")
			TF_VAR_control_plane_name="$CONTROL_PLANE_NAME"
			TF_VAR_deployer_tfstate_key="${deployer_tfstate_key}"
			export TF_VAR_control_plane_name
			export TF_VAR_deployer_tfstate_key
			shift 2
			;;
		-c | --control_plane_name)
			CONTROL_PLANE_NAME="$2"
			CONTROL_PLANE_NAME=$(echo "${CONTROL_PLANE_NAME}" | tr "[:lower:]" "[:upper:]")
			TF_VAR_control_plane_name="$CONTROL_PLANE_NAME"
			TF_VAR_deployer_tfstate_key="${CONTROL_PLANE_NAME}-INFRASTRUCTURE.terraform.tfstate"
			
			export TF_VAR_deployer_tfstate_key
			export TF_VAR_control_plane_name
			shift 2
			;;
		-n | --application_configuration_name)
			APPLICATION_CONFIGURATION_NAME="$2"
			if [ ! -v APPLICATION_CONFIGURATION_ID ]; then
				APPLICATION_CONFIGURATION_ID=$(az graph query -q "Resources | join kind=leftouter (ResourceContainers | where type=='microsoft.resources/subscriptions' | project subscription=name, subscriptionId) on subscriptionId | where name == '$APPLICATION_CONFIGURATION_NAME' | project id, name, subscription" --query data[0].id --output tsv)
				export APPLICATION_CONFIGURATION_ID
			fi
			TF_VAR_application_configuration_id=$APPLICATION_CONFIGURATION_ID
			export TF_VAR_application_configuration_id
			shift 2
			;;
		-l | --landscape_tfstate_key)
			landscape_tfstate_key="$2"
			WORKLOAD_ZONE_NAME=$(echo "$landscape_tfstate_key" | cut -d"-" -f1-3)
			TF_VAR_workload_zone_name="$WORKLOAD_ZONE_NAME"
			export TF_VAR_workload_zone_name
			TF_VAR_landscape_tfstate_key="${landscape_tfstate_key}"
			export TF_VAR_landscape_tfstate_key
			shift 2
			;;
		-o | --storage_accountname)
			terraform_storage_account_name="$2"
			export terraform_storage_account_name
			getAndStoreTerraformStateStorageAccountDetails "${terraform_storage_account_name}" ""

			shift 2
			;;
		-p | --parameter_file)
			parameterFilename="$2"
			shift 2
			;;
		-s | --state_subscription)
			terraform_storage_account_subscription_id="$2"
			export terraform_storage_account_subscription_id
			shift 2
			;;
		-t | --type)
			deployment_system="$2"
			shift 2
			;;
		-w | --workload_zone_name)
			WORKLOAD_ZONE_NAME="$2"
			TF_VAR_workload_zone_name="$WORKLOAD_ZONE_NAME"
			export TF_VAR_workload_zone_name
			TF_VAR_landscape_tfstate_key="${WORKLOAD_ZONE_NAME}-INFRASTRUCTURE.terraform.tfstate"
			export TF_VAR_landscape_tfstate_key

			shift 2
			;;
		-i | --auto-approve)
			approve="--auto-approve"
			shift
			;;
		-h | --help)
			show_help_remover_v2
			return 3
			;;
		--)
			shift
			break
			;;
		esac
	done

	# Validate required parameters
	parameter_file_name=$(basename "${parameterFilename}")
	parameter_file_dirname=$(dirname "${parameterFilename}")

	key=$(echo "${parameter_file_name}" | cut -d. -f1)

	if [ "${parameter_file_dirname}" != '.' ]; then
		print_banner "$banner_title - $deployment_system" "Please run this command from the folder containing the parameter file" "error"
	fi

	if [ ! -f "${parameter_file_name}" ]; then
		print_banner "$banner_title - $deployment_system" "Parameter file does not exist: ${parameterFilename}" "error"
	fi

	[[ -z "${CONTROL_PLANE_NAME:-}" ]] && {
		print_banner "$banner_title - $deployment_system" "control_plane_name is required" "error"
		return 1
	}

	[[ -z "$deployment_system" ]] && {
		print_banner "$banner_title - $deployment_system" "type is required" "error"
		return 1
	}

	if [ -z "$CONTROL_PLANE_NAME" ] && [ -n "$deployer_tfstate_key" ]; then
		CONTROL_PLANE_NAME=$(echo "$deployer_tfstate_key" | cut -d'-' -f1-3)
	fi

	if [ -n "$CONTROL_PLANE_NAME" ]; then
		deployer_tfstate_key="${CONTROL_PLANE_NAME}-INFRASTRUCTURE.terraform.tfstate"
	fi

	if [ "${deployment_system}" == sap_system ] || [ "${deployment_system}" == sap_landscape ]; then
		WORKLOAD_ZONE_NAME=$(echo "$parameter_file_name" | cut -d'-' -f1-3)
		if [ -n "$WORKLOAD_ZONE_NAME" ]; then
			landscape_tfstate_key="${WORKLOAD_ZONE_NAME}-INFRASTRUCTURE.terraform.tfstate"
		else
			WORKLOAD_ZONE_NAME=$(echo "$landscape_tfstate_key" | cut -d'-' -f1-3)
		fi
		TF_VAR_workload_zone_name="$WORKLOAD_ZONE_NAME"
		export TF_VAR_workload_zone_name

	fi

	if [ "${deployment_system}" == sap_system ]; then
		if [ -z "${landscape_tfstate_key}" ]; then
			if [ "$PLATFORM" == "cli" ]; then
				read -r -p "Workload terraform statefile name: " landscape_tfstate_key
				save_config_var "landscape_tfstate_key" "${system_environment_file_name}"
			else
				print_banner "$banner_title - $deployment_system" "Workload terraform statefile name is required" "error"
				unset TF_DATA_DIR
				return 2
			fi
		else
			TF_VAR_landscape_tfstate_key="${landscape_tfstate_key}"
			export TF_VAR_landscape_tfstate_key
		fi
	fi

	if [ -v ARM_SUBSCRIPTION_ID ]; then
		TF_VAR_subscription_id="$ARM_SUBSCRIPTION_ID"
		export TF_VAR_subscription_id
	fi

	if [ "${deployment_system}" != sap_deployer ]; then
		if [ -v APPLICATION_CONFIGURATION_ID ]; then
			TF_VAR_APPLICATION_CONFIGURATION_ID=$APPLICATION_CONFIGURATION_ID
			export TF_VAR_APPLICATION_CONFIGURATION_ID
		fi
		if [ -z "${deployer_tfstate_key}" ]; then
			if [ "$PLATFORM" == "cli" ]; then
				read -r -p "Deployer terraform state file name: " deployer_tfstate_key
				save_config_var "deployer_tfstate_key" "${system_environment_file_name}"
			else
				print_banner "$banner_title - $deployment_system" "Deployer terraform state file name is required" "error"
				unset TF_DATA_DIR
				return 2
			fi
		fi
	fi

	if [ -n "${deployer_tfstate_key}" ]; then
		TF_VAR_deployer_tfstate_key="${deployer_tfstate_key}"
		export TF_VAR_deployer_tfstate_key
	fi

	# Check that the exports ARM_SUBSCRIPTION_ID and SAP_AUTOMATION_REPO_PATH are defined
	if ! validate_exports; then
		return $?
	fi

	# Check that Terraform and Azure CLI is installed
	if ! validate_dependencies; then
		return $?
	fi

	# Check that parameter files have environment and location defined
	if ! validate_key_parameters "$parameterFilename"; then
		return $?
	fi
	CONFIG_DIR="${CONFIG_REPO_PATH}/.sap_deployment_automation"
	if [ -n "$landscape_tfstate_key" ]; then
		environment=$(echo "$landscape_tfstate_key" | awk -F'-' '{print $1}' | xargs)
		region_code=$(echo "$landscape_tfstate_key" | awk -F'-' '{print $2}' | xargs)
		network_logical_name=$(echo "$landscape_tfstate_key" | awk -F'-' '{print $3}' | xargs)
	else
		environment=$(echo "$deployer_tfstate_key" | awk -F'-' '{print $1}' | xargs)
		region_code=$(echo "$deployer_tfstate_key" | awk -F'-' '{print $2}' | xargs)
		network_logical_name=$(echo "$deployer_tfstate_key" | awk -F'-' '{print $3}' | xargs)
	fi

	automation_config_directory="${CONFIG_DIR}"

	system_environment_file_name=$(get_configuration_file "${automation_config_directory}" "${environment}" "${region_code}" "${network_logical_name}")
	region=$(echo "${region}" | tr "[:upper:]" "[:lower:]")
	if valid_region_name "${region}"; then
		# Convert the region to the correct code
		get_region_code "${region}"
	else
		echo "Invalid region: $region"
		return 2
	fi
	return 0
}

############################################################################################
# This function reads the parameters from the Azure Application Configuration and sets     #
# the environment variables.                                                               #
# Arguments:                                                                               #
#   None                                                                                   #
# Returns:                                                                                 #
#   0 on success, non-zero on failure                                                      #
# Usage:                     																				                       #
#   retrieve_parameters                                                                    #
############################################################################################

function retrieve_parameters() {

	TF_VAR_control_plane_name="${CONTROL_PLANE_NAME}"
	export TF_VAR_control_plane_name
	if [ ! -v APPLICATION_CONFIGURATION_ID ]; then
		if [ -n "${APPLICATION_CONFIGURATION_NAME:-}" ]; then
			APPLICATION_CONFIGURATION_ID=$(az graph query -q "Resources | join kind=leftouter (ResourceContainers | where type=='microsoft.resources/subscriptions' | project subscription=name, subscriptionId) on subscriptionId | where name == '$APPLICATION_CONFIGURATION_NAME' | project id, name, subscription" --query data[0].id --output tsv)
			export APPLICATION_CONFIGURATION_ID
		fi
	fi
	
	getAndStoreTerraformStateStorageAccountDetailsFromDisk "${system_environment_file_name}"

	if [ -v APPLICATION_CONFIGURATION_ID ]; then
		app_config_name=$(echo "$APPLICATION_CONFIGURATION_ID" | cut -d'/' -f9)
		app_config_subscription=$(echo "$APPLICATION_CONFIGURATION_ID" | cut -d'/' -f3)

		if is_valid_id "$APPLICATION_CONFIGURATION_ID" "/providers/Microsoft.AppConfiguration/configurationStores/"; then
			print_banner "Installer" "Retrieving parameters from Azure App Configuration" "info" "$app_config_name ($app_config_subscription)"

			if [ -z "${terraform_storage_account_name:-}" ]; then
				tfstate_resource_id=$(getVariableFromApplicationConfiguration "$APPLICATION_CONFIGURATION_ID" "${CONTROL_PLANE_NAME}_TerraformRemoteStateStorageAccountId" "$CONTROL_PLANE_NAME")
				TF_VAR_tfstate_resource_id=$tfstate_resource_id
				terraform_storage_account_name=$(echo "$tfstate_resource_id" | cut -d'/' -f9)
				terraform_storage_account_resource_group_name=$(echo "$tfstate_resource_id" | cut -d'/' -f5)
				terraform_storage_account_subscription_id=$(echo "$tfstate_resource_id" | cut -d'/' -f3)
				export TF_VAR_tfstate_resource_id
				export terraform_storage_account_name
				export terraform_storage_account_resource_group_name
				export terraform_storage_account_subscription_id
			fi

			TF_VAR_deployer_kv_user_arm_id=$(getVariableFromApplicationConfiguration "$APPLICATION_CONFIGURATION_ID" "${CONTROL_PLANE_NAME}_KeyVaultResourceId" "$CONTROL_PLANE_NAME")
			if [ -n "$TF_VAR_deployer_kv_user_arm_id" ]; then
				TF_VAR_spn_keyvault_id="${TF_VAR_deployer_kv_user_arm_id}"
				export TF_VAR_spn_keyvault_id
			fi
	

			TF_VAR_management_subscription_id=$(getVariableFromApplicationConfiguration "$APPLICATION_CONFIGURATION_ID" "${CONTROL_PLANE_NAME}_SubscriptionId" "${CONTROL_PLANE_NAME}")
			export TF_VAR_management_subscription_id

			keyvault=$(getVariableFromApplicationConfiguration "$APPLICATION_CONFIGURATION_ID" "${CONTROL_PLANE_NAME}_KeyVaultName" "${CONTROL_PLANE_NAME}")
			export keyvault
		fi
	else
		if [ -z "${terraform_storage_account_name:-}" ]; then
			load_config_vars "${system_environment_file_name}" \
				tfstate_resource_id

			if [ -n "$tfstate_resource_id" ]; then
				TF_VAR_tfstate_resource_id=$tfstate_resource_id
				terraform_storage_account_name=$(echo "$tfstate_resource_id" | cut -d'/' -f9)
				terraform_storage_account_resource_group_name=$(echo "$tfstate_resource_id" | cut -d'/' -f5)
				terraform_storage_account_subscription_id=$(echo "$tfstate_resource_id" | cut -d'/' -f3)

				export TF_VAR_tfstate_resource_id
				export terraform_storage_account_resource_group_name
				export terraform_storage_account_name
				export terraform_storage_account_subscription_id
			fi
		fi

	fi

	if [ "${USE_MSI:-ARM_USE_MSI}" == "true" ]; then
		unset ARM_CLIENT_SECRET
		ARM_USE_MSI=true
		export ARM_USE_MSI

	fi

}

############################################################################################
# Function to remove a SDAF component.                                                     #
# Arguments:                                                                               #
#   None                                                                                   #
# Returns:                                                                                 #
#   0 on success, non-zero on failure                                                      #
# Usage:                                                                                   #
#   sdaf_remover                                                                           #
############################################################################################
function sdaf_remover() {

	# Define an array of helper scripts
	helper_scripts=(
		"${script_directory}/helpers/script_helpers.sh"
		"${script_directory}/deploy_utils.sh"
	)

	# Call the function with the array
	source_helper_scripts "${helper_scripts[@]}"
	detect_platform

	remover_check_environment_variables

	# Parse command line arguments
	if ! parse_arguments "$@"; then
		print_banner "$banner_title" "Validating parameters failed" "error"
		return $?
	fi

	print_banner "$banner_title" "Removal starter." "info" "Entering $SCRIPT_NAME"

	if ! retrieve_parameters; then
		print_banner "$banner_title" "Retrieving parameters failed" "error"
		return $?
	fi

	parallelism=10

	param_dirname=$(pwd)
	export TF_DATA_DIR="${param_dirname}/.terraform"

	TF_VAR_subscription_id="$ARM_SUBSCRIPTION_ID"
	export TF_VAR_subscription_id

	#Provide a way to limit the number of parallel tasks for Terraform
	if checkforEnvVar "TF_PARALLELLISM"; then
		parallelism=$TF_PARALLELLISM
	fi
	echo ""
	echo -e "${green}Deployment information:"
	echo -e "-------------------------------------------------------------------------------$reset_formatting"

	echo "Parameter file:                      $parameterFilename"
	echo "Current directory:                   $(pwd)"
	echo "Control Plane name:                  ${CONTROL_PLANE_NAME}"
	if [ -n "${WORKLOAD_ZONE_NAME}" ]; then
		echo "Workload zone name:                  ${WORKLOAD_ZONE_NAME}"
	fi

	echo "Configuration file:                  $system_environment_file_name"
	echo "Deployment region:                   $region"
	echo "Deployment region code:              $region_code"
	echo "Target subscription:                 $ARM_SUBSCRIPTION_ID"

	if [ "${DEBUG:-false}" = true ]; then
		print_banner "$banner_title - $deployment_system" "Enabling debug mode" "info"
		set -x
		set -o errexit
	fi

	this_ip=$(curl -s ipinfo.io/ip) >/dev/null 2>&1
	export TF_VAR_Agent_IP=$this_ip
	echo "Agent IP:                            $this_ip"

	# Terraform Plugins
	if checkIfCloudShell; then
		mkdir -p "${HOME}/.terraform.d/plugin-cache"
		export TF_PLUGIN_CACHE_DIR="${HOME}/.terraform.d/plugin-cache"
	else
		if [ ! -d /opt/terraform/.terraform.d/plugin-cache ]; then
			sudo mkdir -p /opt/terraform/.terraform.d/plugin-cache
			sudo chown -R "$USER" /opt/terraform
		fi
		export TF_PLUGIN_CACHE_DIR=/opt/terraform/.terraform.d/plugin-cache
	fi

	var_file="${param_dirname}"/"${parameterFilename}"

	#setting the user environment variables

	terraform_module_directory="$SAP_AUTOMATION_REPO_PATH/deploy/terraform/run/${deployment_system}"
	cd "${param_dirname}" || exit

	if [ ! -d "${terraform_module_directory}" ]; then

		printf -v val %-40.40s "$deployment_system"
		print_banner "$banner_title - $deployment_system" "Incorrect system deployment type specified: ${val}$" "error"
		exit 1
	fi

	echo ""
	echo -e "${green}Terraform details:"
	echo -e "-------------------------------------------------------------------------------$reset_formatting"
	echo "Subscription:                        ${terraform_storage_account_subscription_id}"
	echo "Storage Account:                     ${terraform_storage_account_name}"
	echo "Resource Group:                      ${terraform_storage_account_resource_group_name}"
	echo "State file:                          ${key}.terraform.tfstate"
	echo "Target subscription:                 ${ARM_SUBSCRIPTION_ID}"
	echo "Deployer state file:                 ${deployer_tfstate_key}"
	echo "Workload zone state file:            ${landscape_tfstate_key}"
	echo "Current directory:                   $(pwd)"
	echo "Parallelism count:                   $parallelism"
	echo ""

	TF_VAR_subscription_id="$ARM_SUBSCRIPTION_ID"
	export TF_VAR_subscription_id

	terraform_module_directory="${SAP_AUTOMATION_REPO_PATH}/deploy/terraform/run/${deployment_system}"/
	export TF_DATA_DIR="${param_dirname}/.terraform"

	var_file="${param_dirname}"/"${parameter_file_name}"

	backendParameters=(--backend-config "subscription_id=${terraform_storage_account_subscription_id}")
	backendParameters+=(--backend-config "resource_group_name=${terraform_storage_account_resource_group_name}")
	backendParameters+=(--backend-config "storage_account_name=${terraform_storage_account_name}")
	backendParameters+=(--backend-config "container_name=tfstate")
	backendParameters+=(--backend-config "key=${key}.terraform.tfstate")

	TF_VAR_tfstate_resource_id=$(az graph query -q "Resources | join kind=leftouter (ResourceContainers | where type=='microsoft.resources/subscriptions' | project subscription=name, subscriptionId) on subscriptionId | where name == '$terraform_storage_account_name' | project id, name, subscription" --query data[0].id --output tsv)
	export TF_VAR_tfstate_resource_id

    useSAS=$(az storage account show --name "${terraform_storage_account_name}" --query allowSharedKeyAccess --subscription "${terraform_storage_account_subscription_id}" --out tsv)

    if [ "$useSAS" = "true" ]; then
        echo "Storage Account Authentication:      Key"
        AZURE_STORAGE_AUTH_MODE=key
        export AZURE_STORAGE_AUTH_MODE
        export ARM_USE_AZUREAD=false
    else
        echo "Storage Account Authentication:      Entra ID"
        AZURE_STORAGE_AUTH_MODE=login
        export AZURE_STORAGE_AUTH_MODE
        export ARM_USE_AZUREAD=true
    fi



	cd "${param_dirname}" || exit
	if [ -f .terraform/terraform.tfstate ]; then

		echo "Terraform state:                     remote"
		print_banner "$banner_title - $deployment_system" "The system has already been deployed and the state file is in Azure" "info" "System name $(basename "$param_dirname")"

		if terraform -chdir="${terraform_module_directory}" init -upgrade=true -migrate-state "${backendParameters[@]}"; then
			print_banner "$banner_title - $deployment_system" "Terraform init succeeded." "success" "System name $(basename "$param_dirname")"
			return_value=$?
		else
			return_value=$?
			print_banner "$banner_title - $deployment_system" "Terraform init failed." "error" "System name $(basename "$param_dirname")"
			return $return_value
		fi
	else
		if terraform -chdir="${terraform_module_directory}" init -upgrade=true -migrate-state "${backendParameters[@]}"; then
			return_value=$?
			print_banner "$banner_title - $deployment_system" "Terraform init succeeded." "success" "System name $(basename "$param_dirname")"
		else
			return_value=$?
			print_banner "$banner_title - $deployment_system" "Terraform init failed" "error" "System name $(basename "$param_dirname")"
			return 100
		fi
	fi

	print_banner "$banner_title - $deployment_system" "Running Terraform destroy" "info"
    allParameters=(-var-file "${var_file}")
    if [ -f terraform.tfvars ]; then
        allParameters+=(-var-file "${param_dirname}/terraform.tfvars")
    fi

    if [ "$PLATFORM" != "cli" ]; then
        allParameters+=(-input=false)
    fi

	if [ "$PLATFORM" != "cli" ] || [ "$approve" == "--auto-approve" ]; then
		allParameters+=(-json)
		allParameters+=(-auto-approve)
		allParameters+=(-no-color)
		allParameters+=(-compact-warnings)
		deleteOutputfile="delete_output.json"
	else
		deleteOutputfile="delete_output.log"
	fi

	if [ -f "$deleteOutputfile" ]; then
		rm "$deleteOutputfile"
	fi

	if [ "$deployment_system" == "sap_deployer" ]; then
		terraform_bootstrap_directory="${SAP_AUTOMATION_REPO_PATH}/deploy/terraform/bootstrap/${deployment_system}/"
		terraform -chdir="${terraform_bootstrap_directory}" init -upgrade=true -force-copy

		terraform -chdir="${terraform_bootstrap_directory}" refresh "${allParameters[@]}"
		terraform -chdir="${terraform_module_directory}" destroy "${allParameters[@]}"

	elif [ "$deployment_system" == "sap_library" ]; then
		terraform_bootstrap_directory="${SAP_AUTOMATION_REPO_PATH}/deploy/terraform/bootstrap/${deployment_system}/"
		terraform -chdir="${terraform_bootstrap_directory}" init -upgrade=true -force-copy

		terraform -chdir="${terraform_bootstrap_directory}" refresh "${allParameters[@]}"

		terraform -chdir="${terraform_bootstrap_directory}" destroy "${allParameters[@]}" -var use_deployer=false
	else
		if terraform -chdir="${terraform_module_directory}" destroy "${allParameters[@]}" -parallelism="$parallelism" | tee "$deleteOutputfile"; then
			return_value=$?
			print_banner "$banner_title - $deployment_system" "Terraform destroy succeeded" "success" "System name $(basename "$param_dirname")"
		else
			return_value=$?
			print_banner "$banner_title - $deployment_system" "Terraform destroy failed ($return_value)" "error" "System name $(basename "$param_dirname")"
		fi

		if [ -f delete_output.json ]; then
			
			errors_occurred=$(jq 'select(."@level" == "error") | length' delete_output.json	)
			if [[ -n $errors_occurred ]]; then
				return_value=10

				print_banner "$banner_title - $deployment_system" "Errors during the destroy phase" "error" "System name $(basename "$param_dirname")"

				return_value=2
				all_errors=$(jq 'select(."@level" == "error") | {summary: .diagnostic.summary, detail: .diagnostic.detail}' delete_output.json)
				if [[ -n ${all_errors} ]]; then
					readarray -t errors_strings < <(echo "${all_errors}" | jq -c '.')
					for errors_string in "${errors_strings[@]}"; do
						string_to_report=$(jq -c -r '.detail ' <<<"$errors_string")
						if [[ -z ${string_to_report} ]]; then
							string_to_report=$(jq -c -r '.summary ' <<<"$errors_string")
						fi

						report=$(echo "$string_to_report" | grep -m1 "Message=" "${var_file}" | cut -d'=' -f2- | tr -d ' ' | tr -d '"')
						if [[ -n ${report} ]]; then
							echo -e "#                          $bold_red_underscore  $report $reset_formatting"
							if [ "$PLATFORM" == "devops" ]; then
								echo "##vso[task.logissue type=error]${report}"
							fi
						else
							echo -e "#                          $bold_red_underscore  $string_to_report $reset_formatting"
							if [ "$PLATFORM" == "devops" ]; then
								echo "##vso[task.logissue type=error]${string_to_report}"
							fi
						fi

					done

				fi

			fi
		fi

		if [ -f "$deleteOutputfile" ]; then
			rm "$deleteOutputfile"
		fi

	fi

	if [ -f "${system_environment_file_name}" ]; then
		if [ "${deployment_system}" == sap_landscape ]; then
			rm "${system_environment_file_name}"

		fi
		if [ "${deployment_system}" == sap_library ]; then
			sed -i /REMOTE_STATE_RG/d "${system_environment_file_name}"
			sed -i /REMOTE_STATE_SA/d "${system_environment_file_name}"
			sed -i /tfstate_resource_id/d "${system_environment_file_name}"
			sed -i /STATE_SUBSCRIPTION/d "${system_environment_file_name}"
		fi
	fi

    if [ "$return_value" -eq 0 ]; then

		if [ -d ".terraform" ]; then
			rm -rf ".terraform"
		fi
	fi

	unset TF_DATA_DIR
	print_banner "$banner_title" "Removal completed." "info" "Exiting $SCRIPT_NAME"

	exit "$return_value"
}

###############################################################################
# Main script execution                                                       #
# This script is designed to be run directly, not sourced.                    #
# It will execute the sdaf_remover function and handle the exit codes.        #
###############################################################################

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
	# Only run if script is executed directly, not when sourced
	if sdaf_remover "$@"; then
		echo "Script executed successfully."
		exit 0
	else
		echo "Script failed with exit code $?"
		exit 10
	fi
fi
