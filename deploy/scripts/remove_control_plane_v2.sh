#!/bin/bash
# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

################################################################################################
#                                                                                              #
#   This file contains the logic to deploy the environment to support SAP workloads.           #
#                                                                                              #
#   The script is intended to be run from a parent folder to the folders containing            #
#   the json parameter files for the deployer, the library and the environment.                #
#                                                                                              #
#   The script will persist the parameters needed between the executions in the                #
#   [CONFIG_REPO_PATH]/.sap_deployment_automation folder                                                        #
#                                                                                              #
#   The script experts the following exports:                                                  #
#   ARM_SUBSCRIPTION_ID to specify which subscription to deploy to                             #
#   SAP_AUTOMATION_REPO_PATH the path to the folder containing the cloned sap-automation                 #
#                                                                                              #
################################################################################################

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

SCRIPT_NAME="$(basename "$0")"

if [[ -f /etc/profile.d/deploy_server.sh ]]; then
	path=$(grep -m 1 "export PATH=" /etc/profile.d/deploy_server.sh | awk -F'=' '{print $2}' | xargs)
	export PATH=$path
fi

banner_title="Remove Control Plane"

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

function check_environment_variables() {
    if [ -v SDAF_CONTROL_PLANE_NAME ]; then
        CONTROL_PLANE_NAME="$SDAF_CONTROL_PLANE_NAME"
        TF_VAR_control_plane_name="$CONTROL_PLANE_NAME"
        TF_VAR_deployer_tfstate_key="${CONTROL_PLANE_NAME}-INFRASTRUCTURE.terraform.tfstate"
        export TF_VAR_control_plane_name
        export TF_VAR_deployer_tfstate_key
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

    if [ -v SDAF_KEYVAULT_NAME ]; then
        KEYVAULT_NAME="$SDAF_KEYVAULT_NAME"
        export KEYVAULT_NAME
		keyvault_name="$SDAF_KEYVAULT_NAME"
		DEPLOYER_KEYVAULT="$SDAF_KEYVAULT_NAME"
		export DEPLOYER_KEYVAULT
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
	input_opts=$(getopt -n remove_control_plane_v2 -o c:d:l:s:b:r:ihag --longoptions control_plane_name:,deployer_parameter_file:,library_parameter_file:,subscription:,resource_group:,storage_account:,auto-approve,ado,help,keep_agent -- "$@")
	VALID_ARGUMENTS=$?

	if [ "$VALID_ARGUMENTS" != "0" ]; then
		remove_control_plane_show_help_v2
	fi

	approve=""
	deployer_parameter_file=""
	library_parameter_file=""
	keep_agent=0
	approve_parameter=""
	eval set -- "$input_opts"
	while true; do
		case "$1" in
		-c | --control_plane_name)
			CONTROL_PLANE_NAME="$2"
			shift 2
			;;
		-d | --deployer_parameter_file)
			deployer_parameter_file="$2"
			shift 2
			;;
		-l | --library_parameter_file)
			library_parameter_file="$2"
			shift 2
			;;
		-s | --subscription)
			terraform_storage_account_subscription_id="$2"
			shift 2
			;;
		-b | --storage_account)
			terraform_storage_account_name="$2"
			shift 2
			;;
		-r | --resource_group)
			terraform_storage_account_resource_group_name="$2"
			shift 2
			;;
		-a | --ado)
			approve_parameter="--auto-approve;ado=1"
			shift
			;;
		-g | --keep_agent)
			keep_agent=1
			shift
			;;
		-i | --auto-approve)
			approve_parameter="--auto-approve"
			shift
			;;
		-h | --help)
			remove_control_plane_show_help_v2
			exit 3
			;;
		--)
			shift
			break
			;;
		esac
	done
	current_directory=$(pwd)
	if [ -z "${deployer_parameter_file}" ]; then
		deployer_parameter_file="$current_directory/DEPLOYER/$CONTROL_PLANE_NAME-INFRASTRUCTURE/$CONTROL_PLANE_NAME-INFRASTRUCTURE.tfvars"
		echo "Deployer parameter file:             ${deployer_parameter_file}"
	fi
	if [ -z "${library_parameter_file}" ]; then
		prefix=$(echo "$CONTROL_PLANE_NAME" | cut -d '-' -f1-2)
		library_parameter_file="$current_directory/LIBRARY/$prefix-SAP_LIBRARY/$prefix-SAP_LIBRARY.tfvars"
		echo "Library parameter file:              ${library_parameter_file}"
	fi

	if [ ! -f "${library_parameter_file}" ]; then
		control_plane_missing_v2 'library parameter file' $SCRIPT_NAME
		exit 2 #No such file or directory
	fi
	if [ ! -f "${deployer_parameter_file}" ]; then
		control_plane_missing_v2 'deployer parameter file' $SCRIPT_NAME
		exit 2 #No such file or directory
	fi

	if [ "$PLATFORM" != "cli" ] || [ "$approve_parameter" == "--auto-approve" ]; then
		echo "Approve:                             Automatically"
		autoApproveParameter="--auto-approve"
	else
		autoApproveParameter=""
	fi

	key=$(basename "${deployer_parameter_file}" | cut -d. -f1)
	deployer_tfstate_key="${key}.terraform.tfstate"
	deployer_dirname=$(dirname "${deployer_parameter_file}")

	key=$(basename "${library_parameter_file}" | cut -d. -f1)
	library_tfstate_key="${key}.terraform.tfstate"
	library_dirname=$(dirname "${library_parameter_file}")

	if ! printenv CONTROL_PLANE_NAME; then
		CONTROL_PLANE_NAME=$(basename "${deployer_parameter_file}" | cut -d'-' -f1-3)
		export CONTROL_PLANE_NAME
	fi

	# Check that parameter files have environment and location defined
	if ! validate_key_parameters "$deployer_parameter_file"; then
		return_code=$?
		exit $return_code
	fi

	# Check that the exports ARM_SUBSCRIPTION_ID and SAP_AUTOMATION_REPO_PATH are defined
	validate_exports
	return_code=$?
	if [ 0 != $return_code ]; then
		exit $return_code
	fi
	TF_VAR_subscription_id="${terraform_storage_account_subscription_id:-$ARM_SUBSCRIPTION_ID}"
	export TF_VAR_subscription_id

	# Convert the region to the correct code
	get_region_code "$region"

	export TF_IN_AUTOMATION="true"
	# Terraform Plugins
	if checkIfCloudShell; then
		mkdir -p "${HOME}/.terraform.d/plugin-cache"
		export TF_PLUGIN_CACHE_DIR="${HOME}/.terraform.d/plugin-cache"
	else
		if [ ! -d /opt/terraform/.terraform.d/plugin-cache ]; then
			mkdir -p /opt/terraform/.terraform.d/plugin-cache
		fi
		export TF_PLUGIN_CACHE_DIR=/opt/terraform/.terraform.d/plugin-cache
	fi

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

	getAndStoreTerraformStateStorageAccountDetailsFromDisk "${deployer_environment_file_name}"

	if [ -v APPLICATION_CONFIGURATION_ID ]; then
		app_config_name=$(echo "$APPLICATION_CONFIGURATION_ID" | cut -d'/' -f9)
		app_config_subscription=$(echo "$APPLICATION_CONFIGURATION_ID" | cut -d'/' -f3)

		if is_valid_id "$APPLICATION_CONFIGURATION_ID" "/providers/Microsoft.AppConfiguration/configurationStores/"; then
			print_banner "$banner_title" "Retrieving parameters from Azure App Configuration" "info" "$app_config_name ($app_config_subscription)"

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
			load_config_vars "${deployer_environment_file_name}" \
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

#############################################################################################
# Function to remove the control plane.                                                     #
# Arguments:                                                                                #
#   None                                                                                    #
# Returns:                                                                                  #
#   0 on success, non-zero on failure                                                       #
# Usage:                                                                                    #
#   remove_control_plane                                                                    #
#############################################################################################
function remove_control_plane() {
	step=0
	ado_flag="none"
	local green="\e[1;32m"
	local reset="\e[0m"

	# Define an array of helper scripts
	helper_scripts=(
		"${script_directory}/helpers/script_helpers.sh"
		"${script_directory}/deploy_utils.sh"
	)

	# Call the function with the array
	source_helper_scripts "${helper_scripts[@]}"
	detect_platform

	check_environment_variables


	# Parse command line arguments
	parse_arguments "$@"

	CONFIG_DIR="${CONFIG_REPO_PATH}/.sap_deployment_automation"

	ENVIRONMENT=$(echo "${CONTROL_PLANE_NAME}" | awk -F'-' '{print $1}' | xargs)
	LOCATION=$(echo "${CONTROL_PLANE_NAME}" | awk -F'-' '{print $2}' | xargs)
	NETWORK=$(echo "${CONTROL_PLANE_NAME}" | awk -F'-' '{print $3}' | xargs)

	automation_config_directory="${CONFIG_REPO_PATH}/.sap_deployment_automation"

	deployer_environment_file_name=$(get_configuration_file "$automation_config_directory" "$ENVIRONMENT" "$LOCATION" "$NETWORK")

	if [ ! -v APPLICATION_CONFIGURATION_NAME ]; then
    	load_config_vars "${deployer_environment_file_name}" "APPLICATION_CONFIGURATION_NAME"
	fi

	if [ ! -v APPLICATION_CONFIGURATION_ID ]; then
		if [ -n "${APPLICATION_CONFIGURATION_NAME:-}" ]; then
			APPLICATION_CONFIGURATION_ID=$(az graph query -q "Resources | join kind=leftouter (ResourceContainers | where type=='microsoft.resources/subscriptions' | project subscription=name, subscriptionId) on subscriptionId | where name == '$APPLICATION_CONFIGURATION_NAME' | project id, name, subscription" --query data[0].id --output tsv)
			export APPLICATION_CONFIGURATION_ID
		fi
	fi

	# Check that Terraform and Azure CLI is installed
	validate_dependencies
	return_code=$?
	if [ 0 != $return_code ]; then
		echo "validate_dependencies returned $return_code"
		exit $return_code
	fi

	retrieve_parameters

	echo ""
	echo -e "${green}Terraform parameter information:"
	echo -e "-------------------------------------------------------------------------------$reset"
	echo ""
	echo "Control Plane Name:                  $CONTROL_PLANE_NAME"
	echo "Region code:                         ${region_code}"
	echo "Deployer State File:                 ${deployer_tfstate_key}"
	echo "Library State File:                  ${library_tfstate_key}"
	echo "Deployer Subscription:               $ARM_SUBSCRIPTION_ID"
	echo "ADO flag:                            ${ado_flag}"

	key=$(echo "${deployer_parameter_file}" | cut -d. -f1)

	current_directory=$(pwd)

	#we know that we have a valid az session so let us set the environment variables
    if [ "${ARM_USE_MSI:-false}" == "true" ]; then
        USE_MSI=true
        echo "Identity to use:                     Managed Identity"
        TF_VAR_use_spn=false
        export TF_VAR_use_spn
    else
        USE_MSI=false
        echo "Identity to use:                     Service Principal"
        TF_VAR_use_spn=true
        export TF_VAR_use_spn
        # set_executing_user_environment_variables "none"
    fi


	# Deployer

	cd "${deployer_dirname}" || exit

	if [ -f .terraform/terraform.tfstate ] ; then
		azure_backend=$(grep "\"type\": \"azurerm\"" .terraform/terraform.tfstate || true)
		if [ -n "${azure_backend}" ]; then
			step=3
			save_config_vars "${deployer_environment_file_name}" "step"
		else
			step=1
			save_config_vars "${deployer_environment_file_name}" "step"
		fi
	fi

	if [ ! -f "$deployer_environment_file_name" ]; then
		if [ -f "${CONFIG_DIR}/${environment}${region_code}" ]; then
			echo "Copying existing configuration file"
			sudo mv "${CONFIG_DIR}/${environment}${region_code}" "${deployer_environment_file_name}"
		fi
	fi

	load_config_vars "${deployer_environment_file_name}" "step"

	if [ 0 -eq $step ]; then
		exit 0
	fi

	this_ip=$(curl -s ipinfo.io/ip) >/dev/null 2>&1
	export TF_VAR_Agent_IP=$this_ip
	echo "Agent IP:                              $this_ip"

	terraform_module_directory="${SAP_AUTOMATION_REPO_PATH}"/deploy/terraform/run/sap_deployer/
	export TF_DATA_DIR="${deployer_dirname}/.terraform"

	# Reinitialize
	print_banner "$banner_title - Deployer" "Running Terraform init (deployer)" "info"

	if [ -f init_error.log ]; then
		rm init_error.log
	fi

	if [ -f "${deployer_dirname}/.terraform/terraform.tfstate" ]; then
		azure_backend=$(grep "\"type\": \"azurerm\"" "${deployer_dirname}/.terraform/terraform.tfstate" || true)
		if [ -n "$azure_backend" ]; then
			echo "Terraform state:                     remote"
			terraform_module_directory="${SAP_AUTOMATION_REPO_PATH}/deploy/terraform/run/sap_deployer"
			terraform_storage_account_subscription_id=$(grep -m1 "subscription_id" "${deployer_dirname}/.terraform/terraform.tfstate" | cut -d ':' -f2 | tr -d '", \r' | xargs || true)
			terraform_storage_account_name=$(grep -m1 "storage_account_name" "${deployer_dirname}/.terraform/terraform.tfstate" | cut -d ':' -f2 | tr -d ' ",\r' | xargs || true)
			terraform_storage_account_resource_group_name=$(grep -m1 "resource_group_name" "${deployer_dirname}/.terraform/terraform.tfstate" | cut -d ':' -f2 | tr -d ' ",\r' | xargs || true)
			tfstate_resource_id=$(az storage account show --name "${terraform_storage_account_name}" --query id --subscription "${terraform_storage_account_subscription_id}" --resource-group "${terraform_storage_account_resource_group_name}" --out tsv)
			export TF_VAR_tfstate_resource_id
			key=$(basename "${deployer_parameter_file}" | cut -d. -f1)
			if terraform -chdir="${terraform_module_directory}" init -upgrade -input=false \
				--backend-config "subscription_id=${terraform_storage_account_subscription_id}" \
				--backend-config "resource_group_name=${terraform_storage_account_resource_group_name}" \
				--backend-config "storage_account_name=${terraform_storage_account_name}" \
				--backend-config "container_name=tfstate" \
				--backend-config "key=${key}.terraform.tfstate"; then
				print_banner "$banner_title" "Terraform init succeeded." "success"

				terraform -chdir="${terraform_module_directory}" refresh -var-file="${deployer_parameter_file}" -input=false
				
				DEPLOYER_KEYVAULT=$(terraform -chdir="${terraform_module_directory}" output -no-color -raw deployer_kv_user_name | tr -d \")
				if valid_kv_name "${DEPLOYER_KEYVAULT}" ; then
					export DEPLOYER_KEYVAULT
				else
					DEPLOYER_KEYVAULT=""	
				fi

				APPLICATION_CONFIGURATION_NAME=$(terraform -chdir="${terraform_module_directory}" output -no-color -raw application_configuration_name | tr -d \")
				if valid_kv_name "${APPLICATION_CONFIGURATION_NAME}" ; then
					export APPLICATION_CONFIGURATION_NAME
					TF_VAR_application_configuration_name="${APPLICATION_CONFIGURATION_NAME}"
					export TF_VAR_application_configuration_name
				else
					APPLICATION_CONFIGURATION_NAME=""
				fi		
				APPLICATION_CONFIGURATION_ID=$(terraform -chdir="${terraform_module_directory}" output -no-color -raw application_configuration_id | tr -d \")
				if [ -n "${APPLICATION_CONFIGURATION_ID}" ]; then
					export APPLICATION_CONFIGURATION_ID
					TF_VAR_application_configuration_id="${APPLICATION_CONFIGURATION_ID}"
					export TF_VAR_application_configuration_id
				else
					APPLICATION_CONFIGURATION_ID=""
				fi		
				vnet_mgmt_id=$(terraform -chdir="${terraform_module_directory}" output -no-color -raw vnet_mgmt_id | tr -d \")
				if [ -n "${vnet_mgmt_id}" ]; then
					export vnet_mgmt_id
					TF_VAR_management_network_id="${vnet_mgmt_id}"
					export TF_VAR_management_network_id
				else
					vnet_mgmt_id=""
				fi		
			else
				return_value=$?
				print_banner "$banner_title" "Terraform init failed." "error"
			fi

			terraform_module_directory="${SAP_AUTOMATION_REPO_PATH}/deploy/terraform/bootstrap/sap_deployer"

			if terraform -chdir="${terraform_module_directory}" init -migrate-state -upgrade -force-copy --backend-config "path=${deployer_dirname}/terraform.tfstate"; then
				return_value=$?
				print_banner "$banner_title - Deployer" "Terraform init succeeded (deployer - local)" "success"

			else
				return_value=$?
				print_banner "$banner_title - Deployer" "Terraform init failed (deployer - local)" "error"
			fi

		else
			echo "Terraform state:                     local"
			terraform_module_directory="${SAP_AUTOMATION_REPO_PATH}/deploy/terraform/bootstrap/sap_deployer"
			if terraform -chdir="${terraform_module_directory}" init -upgrade --backend-config "path=${deployer_dirname}/terraform.tfstate"; then
				return_value=$?
				print_banner "$banner_title - Deployer" "Terraform init succeeded (deployer - local)" "success"
				DEPLOYER_KEYVAULT=$(terraform -chdir="${terraform_module_directory}" output -no-color -raw deployer_kv_user_name | tr -d \")
				if valid_kv_name "${DEPLOYER_KEYVAULT}" ; then
					export DEPLOYER_KEYVAULT
				fi

				APPLICATION_CONFIGURATION_NAME=$(terraform -chdir="${terraform_module_directory}" output -no-color -raw application_configuration_name | tr -d \")
				if valid_kv_name "${APPLICATION_CONFIGURATION_NAME}" ; then
					TF_VAR_application_configuration_name="${APPLICATION_CONFIGURATION_NAME}"
					export TF_VAR_application_configuration_name
				fi		
				APPLICATION_CONFIGURATION_ID=$(terraform -chdir="${terraform_module_directory}" output -no-color -raw application_configuration_id | tr -d \")
				if [ -n "${APPLICATION_CONFIGURATION_ID}" ]; then
					TF_VAR_application_configuration_id="${APPLICATION_CONFIGURATION_ID}"
					export TF_VAR_application_configuration_id
				fi		
				vnet_mgmt_id=$(terraform -chdir="${terraform_module_directory}" output -no-color -raw vnet_mgmt_id | tr -d \")
				if [ -n "${vnet_mgmt_id}" ]; then
					TF_VAR_management_network_id="${vnet_mgmt_id}"
					export TF_VAR_management_network_id
				fi		

			else
				return_value=$?
				print_banner "$banner_title - Deployer" "Terraform init failed (deployer - local)" "error"
			fi

		fi
	else
		echo "Terraform state:                     unknown"
		if terraform -chdir="${terraform_module_directory}" init -reconfigure -upgrade --backend-config "path=${deployer_dirname}/terraform.tfstate"; then
			return_value=$?
			print_banner "$banner_title - Deployer" "Terraform init succeeded (deployer - local)" "success"
			DEPLOYER_KEYVAULT=$(terraform -chdir="${terraform_module_directory}" output -no-color -raw deployer_kv_user_name | tr -d \")
			if valid_kv_name "${DEPLOYER_KEYVAULT}" ; then
				export DEPLOYER_KEYVAULT
			fi
		else
			return_value=$?
			print_banner "$banner_title - Deployer" "Terraform init failed (deployer - local)" "error"
		fi
	fi

	if valid_kv_name "${DEPLOYER_KEYVAULT}" ; then
		az keyvault network-rule add --ip-address "$TF_VAR_Agent_IP" --name "$DEPLOYER_KEYVAULT" --output none
		az keyvault update --name "$DEPLOYER_KEYVAULT" --public-network-access Enabled --output none
	fi
	if valid_kv_name "${APPLICATION_CONFIGURATION_NAME}" ; then
		az appconfig update --name "$APPLICATION_CONFIGURATION_NAME" --enable-public-network --output none
	fi

	sleep 30


	echo ""
	echo -e "${green}Terraform details:"
	echo -e "-------------------------------------------------------------------------${reset}"
	echo "Subscription:                        ${terraform_storage_account_subscription_id:-undefined}"
	echo "Storage Account:                     ${terraform_storage_account_name:-undefined}"
	echo "Resource Group:                      ${terraform_storage_account_resource_group_name:-undefined}"
	echo "State file:                          ${key}.terraform.tfstate"

	diagnostics_account_id=$(terraform -chdir="${terraform_module_directory}" output diagnostics_account_id | tr -d \")
	if [ -n "${diagnostics_account_id}" ]; then
		diagnostics_account_name=$(echo "${diagnostics_account_id}" | cut -d'/' -f9)
		diagnostics_account_resource_group_name=$(echo "${diagnostics_account_id}" | cut -d'/' -f5)
		diagnostics_account_subscription_id=$(echo "${diagnostics_account_id}" | cut -d'/' -f3)
		az storage account update --name "$diagnostics_account_name" --resource-group "$diagnostics_account_resource_group_name" --subscription "$diagnostics_account_subscription_id" --allow-shared-key-access --output none
	fi

	print_banner "$banner_title - Library" "Running Terraform init (library - local)" "info"

	deployer_statefile_foldername_path="${deployer_dirname}"
	export TF_VAR_deployer_statefile_foldername="${deployer_statefile_foldername_path}"

	if [ ! -v TF_VAR_spn_keyvault_id ]; then
		if ! terraform -chdir="${terraform_module_directory}" output | grep "No outputs"; then
			keyvault_id=$(terraform -chdir="${terraform_module_directory}" output -no-color -raw deployer_kv_user_arm_id | tr -d \")
			TF_VAR_spn_keyvault_id="${keyvault_id}"
			export TF_VAR_spn_keyvault_id
		fi
	fi

	cd "${current_directory}" || exit

	key=$(echo "${library_parameter_file}" | cut -d. -f1)
	cd "${library_dirname}" || exit

	#Library

	terraform_module_directory="${SAP_AUTOMATION_REPO_PATH}"/deploy/terraform/bootstrap/sap_library/
	export TF_DATA_DIR="${library_dirname}/.terraform"

	if [ -f "${library_dirname}/.terraform/terraform.tfstate" ]; then
		azure_backend=$(grep "\"type\": \"azurerm\"" "${library_dirname}/.terraform/terraform.tfstate" || true)
		if [ -n "$azure_backend" ]; then
			echo "Terraform state:                     remote"
			terraform_storage_account_subscription_id=$(grep -m1 "subscription_id" "${library_dirname}/.terraform/terraform.tfstate" | cut -d ':' -f2 | tr -d '", \r' | xargs || true)
			terraform_storage_account_name=$(grep -m1 "storage_account_name" "${library_dirname}/.terraform/terraform.tfstate" | cut -d ':' -f2 | tr -d ' ",\r' | xargs || true)
			terraform_storage_account_resource_group_name=$(grep -m1 "resource_group_name" "${library_dirname}/.terraform/terraform.tfstate" | cut -d ':' -f2 | tr -d ' ",\r' | xargs || true)
			tfstate_resource_id=$(az storage account show --name "${terraform_storage_account_name}" --query id --subscription "${terraform_storage_account_subscription_id}" --resource-group "${terraform_storage_account_resource_group_name}" --out tsv)
			export TF_VAR_tfstate_resource_id

			if terraform -chdir="${terraform_module_directory}" init -upgrade -force-copy -migrate-state --backend-config "path=${library_dirname}/terraform.tfstate"; then
				return_value=$?
				print_banner "$banner_title - Library" "Terraform init succeeded (library - local)" "success"
			else
				return_value=$?
				print_banner "$banner_title - Library" "Terraform init failed (library - local)" "error"
			fi
		else
			echo "Terraform state:                     local"
			if terraform -chdir="${terraform_module_directory}" init -upgrade  --backend-config "path=${library_dirname}/terraform.tfstate"; then
				return_value=$?
				print_banner "$banner_title - Library" "Terraform init succeeded (library - local)" "success"
			else
				return_value=$?
				print_banner "$banner_title - Library" "Terraform init failed (library - local)" "error"
			fi

		fi
	else
		echo "Terraform state:                     unknown"
		if terraform -chdir="${terraform_module_directory}" init -upgrade -reconfigure --backend-config "path=${library_dirname}/terraform.tfstate"; then
			return_value=$?
			print_banner "$banner_title - Library" "Terraform init succeeded (library - local)" "success" "System name $(basename "$library_dirname")"
		else
			return_value=$?
			print_banner "$banner_title - Library" "Terraform init failed (library - local)" "error" "System name $(basename "$library_dirname")"
		fi
	fi

	if [ 0 != $return_code ]; then
		unset TF_DATA_DIR
		return 20
	fi
	export TF_DATA_DIR="${library_dirname}/.terraform"

	allRemovalParameters=(-var-file "${library_parameter_file}")
	if [ -f terraform.tfvars ]; then
		allRemovalParameters+=(-var-file terraform.tfvars)
	fi

	allRemovalParameters+=(-var use_deployer=false)

	if [ "$PLATFORM" != "cli" ] || [ "$approve" == "--auto-approve" ]; then
		allRemovalParameters+=(--auto-approve)
	fi
	if [ "$PLATFORM" != "cli" ] ; then
		allRemovalParameters+=(-input=false)
	fi

	use_spn="false"
	if checkforEnvVar TF_VAR_use_spn; then
		use_spn=$(echo $TF_VAR_use_spn | tr "[:upper:]" "[:lower:]")
		allRemovalParameters+=(-var "use_spn=$use_spn")
	else
		allRemovalParameters+=(-var "use_spn=false")
	fi

	print_banner "$banner_title - Library" "Running Terraform destroy (library)" "info"

	if terraform -chdir="$terraform_module_directory" destroy "${allRemovalParameters[@]}" | tee destroy_output.log; then
		return_value=$?
		print_banner "$banner_title - Library" "Terraform destroy (library) succeeded" "success"  "System name $(basename "$library_dirname")"

		if [ -f "${library_dirname}/terraform.tfstate" ]; then
			rm "${library_dirname}/terraform.tfstate"
		fi
		if [ -f "${library_dirname}/terraform.tfstate.backup" ]; then
			rm "${library_dirname}/terraform.tfstate.backup"
		fi
		if [ -f "${library_dirname}/.terraform/terraform.tfstate" ]; then
			rm "${library_dirname}/.terraform/terraform.tfstate"
		fi
		if [ -d "${library_dirname}/.terraform" ]; then
			rm -rf "${library_dirname}/.terraform"
		fi
		# shellcheck disable=SC2034
		REMOTE_STATE_RG=''
		REMOTE_STATE_SA=''
		STATE_SUBSCRIPTION=''
		# shellcheck disable=SC2034
		tfstate_resource_id=''
		# shellcheck disable=SC2034
		library_random_id=''

		save_config_vars "${deployer_environment_file_name}" \
			library_random_id \
			REMOTE_STATE_RG \
			REMOTE_STATE_SA \
			STATE_SUBSCRIPTION \
			tfstate_resource_id
	else
		return_value=$?
		print_banner "$banner_title - Library" "Terraform destroy (library) failed" "error" "System name $(basename "$library_dirname")"
		unset TF_DATA_DIR
		return 20
	fi

	cd "${current_directory}" || exit
	
	if [ 1 -eq $keep_agent ]; then

		cd "${deployer_dirname}" || exit
	
		terraform_module_directory="${SAP_AUTOMATION_REPO_PATH}"/deploy/terraform/bootstrap/sap_deployer/
		export TF_DATA_DIR="${deployer_dirname}/.terraform"

		if terraform -chdir="${terraform_module_directory}" init --backend-config "path=${deployer_dirname}/terraform.tfstate"; then
			return_value=$?
			print_banner "$banner_title - Deployer" "Terraform init succeeded (deployer - local)" "success"
		else
			return_value=$?
			print_banner "$banner_title - Deployer" "Terraform init failed (deployer - local)" "error" "System name $(basename "$deployer_dirname")"
		fi

		if terraform -chdir="${terraform_module_directory}" apply -input=false -var-file="${deployer_parameter_file}" "${approve_parameter}"; then
			return_value=$?
			print_banner "$banner_title - Deployer" "Terraform apply (deployer) succeeded" "success" "System name $(basename "$deployer_dirname")"
		else
			return_value=0
			print_banner "$banner_title - Deployer" "Terraform apply (deployer) failed" "error" "System name $(basename "$deployer_dirname")"
		fi

		print_banner "$banner_title - Deployer" "Keeping the Azure DevOps agent" "info"
		step=1
		save_config_var "step" "${deployer_environment_file_name}"
		cd "${deployer_dirname}" || exit


	else
		cd "${deployer_dirname}" || exit

		terraform_module_directory="${SAP_AUTOMATION_REPO_PATH}"/deploy/terraform/bootstrap/sap_deployer/
		export TF_DATA_DIR="${deployer_dirname}/.terraform"

		sleep 15

		allRemovalParameters=(-var-file "${deployer_parameter_file}")
		if [ -f terraform.tfvars ]; then
			allRemovalParameters+=(-var-file terraform.tfvars)
		fi

		if [ "$PLATFORM" != "cli" ] || [ "$approve" == "--auto-approve" ]; then
			allRemovalParameters+=(--auto-approve)
		fi
		if [ "$PLATFORM" != "cli" ] ; then
			allRemovalParameters+=(-input=false)
		fi

		print_banner "$banner_title - Deployer" "Running Terraform destroy (deployer)" "info"
		if terraform -chdir="$terraform_module_directory" destroy "${allRemovalParameters[@]}" | tee destroy_output.log; then
			return_value=$?
			print_banner "$banner_title - Deployer" "Terraform destroy (deployer) succeeded" "success" "System name $(basename "$deployer_dirname")"

			if [ -f "${deployer_dirname}/terraform.tfstate" ]; then
				rm "${deployer_dirname}/terraform.tfstate"
			fi
			if [ -f "${deployer_dirname}/terraform.tfstate.backup" ]; then
				rm "${deployer_dirname}/terraform.tfstate.backup"
			fi
			if [ -f "${deployer_dirname}/.terraform/terraform.tfstate" ]; then
				rm "${deployer_dirname}/.terraform/terraform.tfstate"
			fi
			if [ -d "${deployer_dirname}/.terraform" ]; then
				rm -rf "${deployer_dirname}/.terraform"
			fi

			# shellcheck disable=SC2034
			APPLICATION_CONFIGURATION_ID=''
			# shellcheck disable=SC2034
			APPLICATION_CONFIGURATION_DEPLOYMENT=''
			# shellcheck disable=SC2034
			APPLICATION_CONFIGURATION_NAME=''
			# shellcheck disable=SC2034
			APP_CONFIG_DEPLOYMENT=''
			# shellcheck disable=SC2034
			APP_SERVICE_DEPLOYMENT=''
			# shellcheck disable=SC2034
			APP_SERVICE_NAME=''
			# shellcheck disable=SC2034
			DEPLOYER_KEYVAULT=''
			# shellcheck disable=SC2034
			DEPLOYER_SSHKEY_SECRET_NAME=''
			# shellcheck disable=SC2034
			DEPLOYER_USERNAME=''
			# shellcheck disable=SC2034
			deployer_random_id=''
			# shellcheck disable=SC2034
			deployer_tfstate_key=''
			# shellcheck disable=SC2034
			deployer_public_ip_address=''
			# shellcheck disable=SC2034
			keyvault=''

			save_config_vars "${deployer_environment_file_name}" \
				APPLICATION_CONFIGURATION_ID \
				APPLICATION_CONFIGURATION_DEPLOYMENT \
				APPLICATION_CONFIGURATION_NAME \
				APP_CONFIG_DEPLOYMENT \
				APP_SERVICE_DEPLOYMENT \
				APP_SERVICE_NAME \
				DEPLOYER_KEYVAULT \
				DEPLOYER_SSHKEY_SECRET_NAME \
				DEPLOYER_USERNAME \
				deployer_public_ip_address \
				deployer_random_id \
				deployer_tfstate_key \
				keyvault


		else
			return_value=$?
			print_banner "$banner_title - Deployer" "Terraform destroy (deployer) failed" "error" "System name $(basename "$deployer_dirname")"
			return 20
		fi
		step=0
		save_config_var "step" "${deployer_environment_file_name}"
	fi

	cd "${current_directory}" || exit

	unset TF_DATA_DIR
	exit $return_value
}

################################################################################
# Main script execution                                                        #
# This script is designed to be run directly, not sourced.                     #
# It will execute the remove_control_plane function and handle the exit codes. #
################################################################################
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
	# Only run if script is executed directly, not when sourced
	if remove_control_plane "$@"; then
		exit 0
	else
		exit $?
	fi
fi
