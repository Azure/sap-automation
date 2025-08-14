#!/bin/bash
# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

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
if [[ "${DEBUG:-false}" = true ]]; then
	# Enable debugging
	set -x
	# Exit on error
	set -o errexit
	echo "Environment variables:"
	printenv | sort
else
	# Disable debugging
	DEBUG=false
fi

# Constants
script_directory="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
readonly script_directory

SCRIPT_NAME="$(basename "$0")"
banner_title="Bootstrap Library"

CONFIG_REPO_PATH="${script_directory}/.."
CONFIG_DIR="${CONFIG_REPO_PATH}/.sap_deployment_automation"
readonly CONFIG_DIR

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
# Function to display a help message for the library installation script.                  #
# Arguments:                                                                               #
#   1. Parameter file name                                                                 #
# Returns:                                                                                 #
#   0 on success, non-zero on failure                                                      #
# Usage:                                                                                   #
#   show_library_help                                                                      #
############################################################################################
function show_library_help {
	echo ""
	echo "#########################################################################################"
	echo "#                                                                                       #"
	echo "#                                                                                       #"
	echo "#   This file contains the logic to deploy the deployer.                                #"
	echo "#   The script experts the following exports:                                           #"
	echo "#                                                                                       #"
	echo "#     ARM_SUBSCRIPTION_ID      to specify which subscription to deploy to               #"
	echo "#     SAP_AUTOMATION_REPO_PATH the path to the folder containing                        #"
	echo "#                              the cloned sap-automation                                #"
	echo "#                                                                                       #"
	echo "#   The script will persist the parameters needed between the executions in the         #"
	echo "#   [CONFIG_REPO_PATH]/.sap_deployment_automation folder                                #"
	echo "#                                                                                       #"
	echo "#                                                                                       #"
	echo "#   Usage: install_library_v2.sh                                                        #"
	echo "#    -p or --parameterfile                    library parameter file                    #"
	echo "#    -v or --keyvault                         Name of key vault containing credentiols  #"
	echo "#    -s or --deployer_statefile_foldername    relative path to deployer folder          #"
	echo "#    -i or --auto-approve                     if set will not prompt before apply       #"
	echo "#    -h Show help                                                                       #"
	echo "#                                                                                       #"
	echo "#   Example:                                                                            #"
	echo "#                                                                                       #"
	echo "#   [REPO-ROOT]deploy/scripts/install_library.sh \                                      #"
	echo "#      -p PROD-WEEU-SAP_LIBRARY.json \                                                  #"
	echo "#      -d ../../DEPLOYER/PROD-WEEU-DEP00-INFRASTRUCTURE/ \                              #"
	echo "#      -i true                                                                          #"
	echo "#                                                                                       #"
	echo "#########################################################################################"
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
	input_opts=$(getopt -n install_library_v2 -o c:n:p:d:v:ih --longoptions control_plane_name:,application_configuration_name:,parameter_file:,deployer_statefile_foldername:,keyvault:,auto-approve,help -- "$@")
	is_input_opts_valid=$?

	if [[ "${is_input_opts_valid}" != "0" ]]; then
		show_library_help
		exit 1
	fi

	eval set -- "$input_opts"
	while true; do
		case "$1" in
		-p | --parameter_file)
			parameter_file_name="$2"
			shift 2
			;;
		-c | --control_plane_name)
			CONTROL_PLANE_NAME="$2"
			TF_VAR_control_plane_name="$CONTROL_PLANE_NAME"
			export TF_VAR_control_plane_name
			shift 2
			;;
		-d | --deployer_statefile_foldername)
			deployer_statefile_foldername="$2"
			shift 2
			;;
		-i | --auto-approve)
			approve="--auto-approve"
			shift
			;;
		-n | --application_configuration_name)
			APPLICATION_CONFIGURATION_NAME="$2"
			export APPLICATION_CONFIGURATION_NAME
			shift 2
			;;
		-h | --help)
			showhelp
			exit 3
			;;
		-v | --keyvault)
			keyvault="$2"
			shift 2
			;;
		--)
			shift
			break
			;;
		esac
	done
	if [ ! -f "${parameter_file_name}" ]; then

		printf -v val %-40.40s "$parameter_file_name"
		print_banner "$banner_title" "Parameter file does not exist: $parameter_file_name" "error"
		return 2 #No such file or directory
	fi

	param_dirname=$(dirname "${parameter_file_name}")
	export TF_DATA_DIR="${param_dirname}"/.terraform
	if [ "$param_dirname" != '.' ]; then
		print_banner "$banner_title" "Parameter file is not in the current directory: $parameter_file_name" "error"
		return 3
	fi

	# Check that parameter files have environment and location defined
	if ! validate_key_parameters "$parameter_file_name"; then
		return $?
	fi

	# Check that the exports ARM_SUBSCRIPTION_ID and SAP_AUTOMATION_REPO_PATH are defined
	if ! validate_exports; then
		return $?
	fi

	region=$(echo "${region}" | tr "[:upper:]" "[:lower:]")
	# Convert the region to the correct code
	get_region_code "$region"

	# Check that Terraform and Azure CLI is installed
	if ! validate_dependencies; then
		return $?
	fi

	if [ ! -v APPLICATION_CONFIGURATION_ID ]; then
		APPLICATION_CONFIGURATION_ID=$(az graph query -q "Resources | join kind=leftouter (ResourceContainers | where type=='microsoft.resources/subscriptions' | project subscription=name, subscriptionId) on subscriptionId | where name == '$APPLICATION_CONFIGURATION_NAME' | project id, name, subscription" --query data[0].id --output tsv)
		export APPLICATION_CONFIGURATION_ID
	fi
	TF_VAR_application_configuration_id="${APPLICATION_CONFIGURATION_ID}"
	export TF_VAR_application_configuration_id

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

	if [ -n "$APPLICATION_CONFIGURATION_ID" ]; then
		app_config_name=$(echo "$APPLICATION_CONFIGURATION_ID" | cut -d'/' -f9)
		app_config_subscription=$(echo "$APPLICATION_CONFIGURATION_ID" | cut -d'/' -f3)

		if is_valid_id "$APPLICATION_CONFIGURATION_ID" "/providers/Microsoft.AppConfiguration/configurationStores/"; then
			print_banner "Installer" "Retrieving parameters from Azure App Configuration" "info" "$app_config_name ($app_config_subscription)"

			TF_VAR_deployer_kv_user_arm_id=$(getVariableFromApplicationConfiguration "$APPLICATION_CONFIGURATION_ID" "${CONTROL_PLANE_NAME}_KeyVaultResourceId" "$CONTROL_PLANE_NAME")
			TF_VAR_spn_keyvault_id="${TF_VAR_deployer_kv_user_arm_id}"

			DEPLOYER_KEYVAULT=$(getVariableFromApplicationConfiguration "$APPLICATION_CONFIGURATION_ID" "${CONTROL_PLANE_NAME}_KeyVaultName" "${CONTROL_PLANE_NAME}")

			management_subscription_id=$(getVariableFromApplicationConfiguration "$APPLICATION_CONFIGURATION_ID" "${CONTROL_PLANE_NAME}_SubscriptionId" "${CONTROL_PLANE_NAME}")
			TF_VAR_management_subscription_id=${management_subscription_id}

			export TF_VAR_deployer_kv_user_arm_id
			export TF_VAR_management_subscription_id
			export TF_VAR_spn_keyvault_id
			export DEPLOYER_KEYVAULT

		fi

	fi

}

############################################################################################
# Function to install the SAP Library.                                                     #
# Arguments:                                                                               #
#   None                                                                                   #
# Returns:                                                                                 #
#   0 on success, non-zero on failure                                                      #
# Usage:                                                                                   #
#   install_library                                                                        #
############################################################################################

function install_library() {
	local green="\033[0;32m"
	local reset="\033[0m"
	deployment_system=sap_library
	use_deployer=true
	approve=""
	# Define an array of helper scripts
	helper_scripts=(
		"${script_directory}/helpers/script_helpers.sh"
		"${script_directory}/deploy_utils.sh"
	)

	# Call the function with the array
	source_helper_scripts "${helper_scripts[@]}"

	print_banner "$banner_title" "Starting the script: $SCRIPT_NAME" "info"

	# Parse command line arguments
	if ! parse_arguments "$@"; then
		print_banner "$banner_title" "Validating parameters failed" "error"
		return $?
	fi

	retrieve_parameters

	param_dirname=$(dirname "${parameter_file_name}")
	export TF_DATA_DIR="${param_dirname}/.terraform"

	if [ true == "$use_deployer" ]; then
		if [ ! -d "${deployer_statefile_foldername}" ]; then

			print_banner "$banner_title" "Deployer folder does not exist: $deployer_statefile_foldername" "error"
			return 2 #No such file or directory
		fi
	fi

	#Persisting the parameters across executions
	automation_config_directory=$CONFIG_REPO_PATH/.sap_deployment_automation/
	generic_config_information="${automation_config_directory}"config
	library_config_information="${automation_config_directory}$CONTROL_PLANE_NAME"

	TF_VAR_control_plane_name="$CONTROL_PLANE_NAME"
	export TF_VAR_control_plane_name

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

	param_dirname=$(pwd)

	init "${automation_config_directory}" "${generic_config_information}" "${library_config_information}"

	export TF_DATA_DIR="${param_dirname}"/.terraform
	var_file="${param_dirname}"/"${parameter_file_name}"

	terraform_module_directory="${SAP_AUTOMATION_REPO_PATH}"/deploy/terraform/bootstrap/"${deployment_system}"/

	if [ ! -d "${terraform_module_directory}" ]; then
		print_banner "$banner_title" "Terraform module directory does not exist: $terraform_module_directory" "error"
		unset TF_DATA_DIR
		return 64
	fi

	echo ""
	echo -e "${green}Deployment information:"
	echo -e "-------------------------------------------------------------------------------$reset"

	echo "Configuration file:                  $parameter_file_name"
	echo "Control Plane name:                  $CONTROL_PLANE_NAME"

	TF_VAR_subscription_id="$ARM_SUBSCRIPTION_ID"
	export TF_VAR_subscription_id
	extra_vars=""
	parallelism=10

	#Provide a way to limit the number of parallel tasks for Terraform
	if checkforEnvVar "TF_PARALLELLISM"; then
		parallelism=$TF_PARALLELLISM
	fi
	echo "Parallelism count:                   $parallelism"

	if [ "{$ARM_USE_MSI:-false}" = true ]; then
		unset ARM_CLIENT_SECRET
	fi

	extra_vars=""
	if [ -f terraform.tfvars ]; then
		extra_vars=" -var-file=${param_dirname}/terraform.tfvars "
	fi

	if [ -n "${DEPLOYER_KEYVAULT}" ]; then
		TF_VAR_deployer_kv_user_arm_id=$(az resource list --name "${DEPLOYER_KEYVAULT}" --subscription "$ARM_SUBSCRIPTION_ID" --resource-type Microsoft.KeyVault/vaults --query "[].id | [0]" -o tsv)
		export TF_VAR_spn_keyvault_id="${TF_VAR_deployer_kv_user_arm_id}"
	fi

	if [ ! -d ./.terraform/ ]; then
		print_banner "$banner_title" "New Deployment" "info"
		terraform -chdir="${terraform_module_directory}" init -upgrade=true -backend-config "path=${param_dirname}/terraform.tfstate"
		sed -i /REMOTE_STATE_RG/d "${library_config_information}"
		sed -i /REMOTE_STATE_SA/d "${library_config_information}"
		sed -i /tfstate_resource_id/d "${library_config_information}"

	else
		if [ -f ./.terraform/terraform.tfstate ]; then
			azure_backend=$(grep "\"type\": \"azurerm\"" .terraform/terraform.tfstate || true)
			if [ -n "$azure_backend" ]; then
				print_banner "$banner_title" "The state is already migrated to Azure!!!" "info"

				REINSTALL_SUBSCRIPTION=$(grep -m1 "subscription_id" "${param_dirname}/.terraform/terraform.tfstate" | cut -d ':' -f2 | tr -d '", \r' | xargs || true)
				REINSTALL_ACCOUNTNAME=$(grep -m1 "storage_account_name" "${param_dirname}/.terraform/terraform.tfstate" | cut -d ':' -f2 | tr -d ' ",\r' | xargs || true)
				REINSTALL_RESOURCE_GROUP=$(grep -m1 "resource_group_name" "${param_dirname}/.terraform/terraform.tfstate" | cut -d ':' -f2 | tr -d ' ",\r' | xargs || true)

				tfstate_resource_id=$(az resource list --name "$REINSTALL_ACCOUNTNAME" --subscription "$REINSTALL_SUBSCRIPTION" --resource-type Microsoft.Storage/storageAccounts --query "[].id | [0]" -o tsv)
				if [ -n "${tfstate_resource_id}" ]; then
					print_banner "$banner_title" "Reinitializing against remote state" "info"
					this_ip=$(curl -s ipinfo.io/ip) >/dev/null 2>&1
					az storage account network-rule add --account-name "$REINSTALL_ACCOUNTNAME" --resource-group "$REINSTALL_RESOURCE_GROUP" --ip-address "${this_ip}" --only-show-errors --output none
					echo ""
					echo "Sleeping for 30 seconds to allow the network rule to take effect"
					echo ""
					sleep 30
					export TF_VAR_tfstate_resource_id=$tfstate_resource_id

					key=$(basename "${parameter_file_name}" | cut -d. -f1)

					terraform_module_directory="${SAP_AUTOMATION_REPO_PATH}/deploy/terraform/run/sap_library"/

					if terraform -chdir="${terraform_module_directory}" init \
						--backend-config "subscription_id=$REINSTALL_SUBSCRIPTION" \
						--backend-config "resource_group_name=$REINSTALL_RESOURCE_GROUP" \
						--backend-config "storage_account_name=$REINSTALL_ACCOUNTNAME" \
						--backend-config "container_name=tfstate" \
						--backend-config "key=${key}.terraform.tfstate"; then
						print_banner "$banner_title" "Terraform init succeeded" "success"

						terraform -chdir="${terraform_module_directory}" refresh -var-file="${var_file}" -input=false \
							-var deployer_statefile_foldername="${deployer_statefile_foldername}"
					else
						print_banner "$banner_title" "Terraform init against remote state failed" "error"
						return 10
					fi
				else
					if terraform -chdir="${terraform_module_directory}" init -reconfigure --backend-config "path=${param_dirname}/terraform.tfstate"; then
						print_banner "$banner_title" "Terraform init succeeded" "success"
					else
						print_banner "$banner_title" "Terraform init failed" "error"
						return 10
					fi
				fi
			else
				if terraform -chdir="${terraform_module_directory}" init -upgrade=true -backend-config "path=${param_dirname}/terraform.tfstate"; then
					print_banner "$banner_title" "Terraform init succeeded" "success"
				else
					print_banner "$banner_title" "Terraform init failed" "error"
					return 10
				fi

			fi

		else
			if terraform -chdir="${terraform_module_directory}" init -upgrade=true -backend-config "path=${param_dirname}/terraform.tfstate"; then
				print_banner "$banner_title" "Terraform init succeeded" "success"
			else
				print_banner "$banner_title" "Terraform init failed" "error"
				return 10
			fi
		fi
	fi

	print_banner "$banner_title" "Running Terraform plan" "info"

	return_value=0

	if [ -n "${deployer_statefile_foldername}" ]; then
		echo "Deployer folder specified:           ${deployer_statefile_foldername}"
		terraform -chdir="${terraform_module_directory}" plan -no-color -detailed-exitcode \
			-var-file="${var_file}" -input=false \
			-var deployer_statefile_foldername="${deployer_statefile_foldername}" | tee plan_output.log
		return_value=${PIPESTATUS[0]}
		if [ $return_value -eq 1 ]; then
			print_banner "$banner_title" "Terraform plan failed" "error"
			unset TF_DATA_DIR
			return $return_value

		else
			print_banner "$banner_title" "Terraform plan succeeded" "success"
		fi
		allParameters=$(printf " -var-file=%s -var deployer_statefile_foldername=%s %s " "${var_file}" "${deployer_statefile_foldername}" "${extra_vars}")
		allImportParameters=$(printf " -var-file=%s -var deployer_statefile_foldername=%s %s " "${var_file}" "${deployer_statefile_foldername}" "${extra_vars}")

	else
		terraform -chdir="${terraform_module_directory}" plan -no-color -detailed-exitcode \
			-var-file="${var_file}" -input=false | tee -a plan_output.log
		return_value=${PIPESTATUS[0]}
		if [ $return_value -eq 1 ]; then
			print_banner "$banner_title" "Terraform plan failed" "error"
			unset TF_DATA_DIR
			return $return_value
		else
			print_banner "$banner_title" "Terraform plan succeeded" "success"
		fi
		allParameters=$(printf " -var-file=%s %s" "${var_file}" "${extra_vars}")
		allImportParameters=$(printf " -var-file=%s %s" "${var_file}" "${extra_vars}")
	fi

	return_value=0

	if [ "${TEST_ONLY:-false}" == "true" ]; then
		print_banner "$banner_title" "Running plan only. No deployment performed." "info"
		exit 100
	fi
	print_banner "$banner_title" "Running Terraform apply" "info"

	if [ -n "${approve}" ]; then
		# shellcheck disable=SC2086
		terraform -chdir="${terraform_module_directory}" apply -parallelism="${parallelism}" -no-color -compact-warnings -json -input=false $allParameters --auto-approve | tee apply_output.json
		return_value=${PIPESTATUS[0]}

	else
		# shellcheck disable=SC2086
		terraform -chdir="${terraform_module_directory}" apply -parallelism="${parallelism}" -input=false $allParameters
		return_value=$?
	fi

	if [ $return_value -eq 1 ]; then
		print_banner "$banner_title" "Terraform apply failed" "error"
	else
		# return code 2 is ok
		print_banner "$banner_title" "Terraform apply succeeded" "success"
		return_value=0
	fi

	if [ -f apply_output.json ]; then
		errors_occurred=$(jq 'select(."@level" == "error") | length' apply_output.json)

		if [[ -n $errors_occurred ]]; then
			# shellcheck disable=SC2086
			if ! ImportAndReRunApply "apply_output.json" "${terraform_module_directory}" "$allImportParameters" "$allParameters" $parallelism; then
				return_value=$?
			else
				return_value=0
			fi

			if [ -f apply_output.json ]; then
				# shellcheck disable=SC2086
				if ! ImportAndReRunApply "apply_output.json" "${terraform_module_directory}" "$allImportParameters" "$allParameters" $parallelism; then
					return_value=$?
				else
					return_value=0
				fi
			fi

			if [ -f apply_output.json ]; then
				# shellcheck disable=SC2086
				if ! ImportAndReRunApply "apply_output.json" "${terraform_module_directory}" "$allImportParameters" "$allParameters" $parallelism; then
					return_value=$?
				else
					return_value=0
				fi
			fi

			if [ -f apply_output.json ]; then
				# shellcheck disable=SC2086
				if ! ImportAndReRunApply "apply_output.json" "${terraform_module_directory}" "$allImportParameters" "$allParameters" $parallelism; then
					return_value=$?
				else
					return_value=0
				fi
			fi

			if [ -f apply_output.json ]; then
				# shellcheck disable=SC2086
				if ! ImportAndReRunApply "apply_output.json" "${terraform_module_directory}" "$allImportParameters" "$allParameters" $parallelism; then
					return_value=$?
				else
					return_value=0
				fi
			fi
		fi
	fi
	if [ -f apply_output.json ]; then
		rm apply_output.json
	fi

	if [ 1 == $return_value ]; then
		print_banner "$banner_title" "Errors during the apply phase" "error"
		unset TF_DATA_DIR
		return $return_value
	fi

	if [ "$DEBUG" = true ]; then
		terraform -chdir="${terraform_module_directory}" output
	fi

	tfstate_resource_id=$(terraform -chdir="${terraform_module_directory}" output -no-color -raw tfstate_resource_id | tr -d \")
	export tfstate_resource_id
	save_config_var "tfstate_resource_id" "${library_config_information}"

	library_random_id=$(terraform -chdir="${terraform_module_directory}" output -no-color -raw random_id | tr -d \")
	if [ -n "${library_random_id}" ]; then
		save_config_var "library_random_id" "${library_config_information}"
		custom_random_id="${library_random_id:0:3}"
		sed -i -e /"custom_random_id"/d "${var_file}"
		printf "# The parameter 'custom_random_id' can be used to control the random 3 digits at the end of the storage accounts and key vaults\ncustom_random_id=\"%s\"\n" "${custom_random_id}" >>"${var_file}"

	fi

	return $return_value
}

###############################################################################
# Main script execution                                                       #
# This script is designed to be run directly, not sourced.                    #
# It will execute the install_library function and handle the exit codes.     #
###############################################################################
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
	# Only run if
	if install_library "$@"; then
		exit 0
	else
		exit $?
	fi
fi
