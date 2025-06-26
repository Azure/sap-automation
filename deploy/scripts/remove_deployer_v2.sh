#!/bin/bash
# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

#colors for terminal
bold_red="\e[1;31m"
cyan="\e[1;36m"
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
	# Exit on error
	set -euox pipefail
	echo "Environment variables:"
	printenv | sort
fi

# Constants
script_directory="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
readonly script_directory

SCRIPT_NAME="$(basename "$0")"

if [[ -f /etc/profile.d/deploy_server.sh ]]; then
	path=$(grep -m 1 "export PATH=" /etc/profile.d/deploy_server.sh | awk -F'=' '{print $2}' | xargs)
	export PATH=$path
fi

#####################################################################################
# Function to display a help message for the script.                                #
# Arguments:                                                                        #
#   None                                                                            #
# Returns:                                                                          #
#   None                                                                            #
# Usage:                                                                            #
#   show_deployer_help                                                              #
#####################################################################################
function show_deployer_help {
	echo ""
	echo "#########################################################################################"
	echo "#                                                                                       #"
	echo "#                                                                                       #"
	echo "#   This file contains the logic to remove the deployer.                                #"
	echo "#   The script experts the following exports:                                           #"
	echo "#                                                                                       #"
	echo "#     ARM_SUBSCRIPTION_ID to specify which subscription to deploy to                    #"
	echo "#     DEPLOYMENT_REPO_PATH the path to the folder containing the cloned sap-automation  #"
	echo "#                                                                                       #"
	echo "#   The script will persist the parameters needed between the executions in the         #"
	echo "#   ~/.sap_deployment_automation folder                                                 #"
	echo "#                                                                                       #"
	echo "#                                                                                       #"
	echo "#   Usage: remove_deployer_v2.sh                                                        #"
	echo "#    -p deployer parameter file                                                         #"
	echo "#                                                                                       #"
	echo "#    -i interactive true/false setting the value to false will not prompt before apply  #"
	echo "#    -h Show help                                                                       #"
	echo "#                                                                                       #"
	echo "#   Example:                                                                            #"
	echo "#                                                                                       #"
	echo "#   [REPO-ROOT]deploy/scripts/remove_deployer.sh \                                      #"
	echo "#      -p PROD-WEEU-DEP00-INFRASTRUCTURE.json \                                         #"
	echo "#      -i true                                                                          #"
	echo "#                                                                                       #"
	echo "#########################################################################################"
}

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
	local return_code=0
	#process inputs - may need to check the option i for auto approve as it is not used
	input_opts=$(getopt -n remove_deployer_v2 -o p:ih --longoptions parameter_file:,auto-approve,help -- "$@")
	is_input_opts_valid=$?

	if [[ "${is_input_opts_valid}" != "0" ]]; then
		show_deployer_help
		return 1
	fi

	eval set -- "$input_opts"
	while true; do
		case "$1" in -p | --parameter_file)
			parameterFilename="$2"
			shift 2
			;;
		-i | --auto-approve)
			approve="--auto-approve"
			shift
			;;
		-h | --help)
			show_deployer_help
			exit 3
			shift
			;;
		--)
			shift
			break
			;;
		esac
	done

	# Validate required parameters
	parameterfile_name=$(basename "${parameterFilename}")
	parameterfile_dirname=$(dirname "${parameterFilename}")

	if [ "${parameterfile_dirname}" != '.' ]; then
		print_banner "Remover" "Please run this command from the folder containing the parameter file" "error"
	fi

	if [ ! -f "${parameterfile_name}" ]; then
		print_banner "Remover" "Parameter file does not exist: ${parameterFilename}" "error"
	fi

	# Check that parameter files have environment and location defined
	if ! validate_key_parameters "$parameterFilename"; then
		return $?
	fi

	region=$(echo "${region}" | tr "[:upper:]" "[:lower:]")
	# Convert the region to the correct code
	get_region_code $region

	# Check that the exports ARM_SUBSCRIPTION_ID and SAP_AUTOMATION_REPO_PATH are defined
	if ! validate_exports; then
		return $?
	fi

	if checkforEnvVar "TEST_ONLY"; then
		TEST_ONLY="${TEST_ONLY}"
	else
		TEST_ONLY="false"
	fi

}

############################################################################################
# Function to remove the deployer.                                                         #
# Arguments:                                                                               #
#   None                                                                                   #
# Returns:                                                                                 #
#   0 on success, non-zero on failure                                                      #
# Usage:                                                                                   #
#   sdaf_remove_deployer                                                                   #
############################################################################################
function sdaf_remove_deployer() {
	deployment_system=sap_deployer

	# Define an array of helper scripts
	helper_scripts=(
		"${script_directory}/helpers/script_helpers.sh"
		"${script_directory}/deploy_utils.sh"
	)

	# Call the function with the array
	source_helper_scripts "${helper_scripts[@]}"

	# Parse command line arguments
	parse_arguments "$@"
	key=$(echo "${parameterfile_name}" | cut -d. -f1)

	CONTROL_PLANE_NAME=$(echo "$key" | cut -d'-' -f1-3)
	export "CONTROL_PLANE_NAME"
	CONFIG_DIR="${CONFIG_REPO_PATH}/.sap_deployment_automation"

	#Persisting the parameters across executions
	deployer_config_information="${CONFIG_DIR}/$CONTROL_PLANE_NAME"

	load_config_vars "${deployer_config_information}" "step"

	param_dirname=$(pwd)

	var_file="${param_dirname}/${parameterFilename}"

	terraform_module_directory="${SAP_AUTOMATION_REPO_PATH}"/deploy/terraform/bootstrap/"${deployment_system}"/

	export TF_DATA_DIR="${param_dirname}"/.terraform

	# Check that Terraform and Azure CLI is installed
	validate_dependencies
	return_code=$?
	if [ 0 != $return_code ]; then
		return $return_code
	fi

	current_directory=$(pwd)

	terraform -chdir="${terraform_module_directory}" init -reconfigure -backend-config "path=${current_directory}/terraform.tfstate"
	extra_vars=""

	# if terraform -chdir="${terraform_module_directory}" state list; then

	# 	moduleID="module.sap_deployer.azurerm_app_configuration_key.deployer_state_file_name"
	# 	if terraform -chdir="${terraform_module_directory}" state list -id="${moduleID}"; then
	# 		if terraform -chdir="${terraform_module_directory}" state rm "${moduleID}"; then
	# 			echo "Setting 'deployer_state_file_name' removed from state"
	# 		fi
	# 	fi

	# 	moduleID="module.sap_deployer.azurerm_app_configuration_key.deployer_keyvault_name"
	# 	if terraform -chdir="${terraform_module_directory}" state list -id="${moduleID}"; then
	# 		if terraform -chdir="${terraform_module_directory}" state rm "${moduleID}"; then
	# 			echo "Setting 'deployer_keyvault_name' removed from state"
	# 		fi
	# 	fi

	# 	moduleID="module.sap_deployer.azurerm_app_configuration_key.deployer_keyvault_id"
	# 	if terraform -chdir="${terraform_module_directory}" state list -id="${moduleID}"; then
	# 		if terraform -chdir="${terraform_module_directory}" state rm "${moduleID}"; then
	# 			echo "Setting 'deployer_keyvault_id' removed from state"
	# 		fi
	# 	fi
	# 	moduleID="module.sap_deployer.azurerm_app_configuration_key.deployer_resourcegroup_name"
	# 	if terraform -chdir="${terraform_module_directory}" state list -id="${moduleID}"; then
	# 		if terraform -chdir="${terraform_module_directory}" state rm "${moduleID}"; then
	# 			echo "Setting 'deployer_resourcegroup_name' removed from state"
	# 		fi
	# 	fi
	# 	moduleID="module.sap_deployer.azurerm_app_configuration_key.deployer_subscription_id"
	# 	if terraform -chdir="${terraform_module_directory}" state list -id="${moduleID}"; then
	# 		if terraform -chdir="${terraform_module_directory}" state rm "${moduleID}"; then
	# 			echo "Setting 'deployer_subscription_id' removed from state"
	# 		fi
	# 	fi

	# 	moduleID="module.sap_deployer.azurerm_app_configuration_key.web_application_resource_id"
	# 	if terraform -chdir="${terraform_module_directory}" state list -id="${moduleID}"; then
	# 		if terraform -chdir="${terraform_module_directory}" state rm "${moduleID}"; then
	# 			echo "Setting 'web_application_resource_id' removed from state"
	# 		fi
	# 	fi

	# 	moduleID="module.sap_deployer.azurerm_app_configuration_key.deployer_msi_id"
	# 	if terraform -chdir="${terraform_module_directory}" state list -id="${moduleID}"; then
	# 		if terraform -chdir="${terraform_module_directory}" state rm "${moduleID}"; then
	# 			echo "Setting 'deployer_msi_id' removed from state"
	# 		fi
	# 	fi
	# 	moduleID="module.sap_deployer.azurerm_app_configuration_key.web_application_identity_id"
	# 	if terraform -chdir="${terraform_module_directory}" state list -id="${moduleID}"; then
	# 		if terraform -chdir="${terraform_module_directory}" state rm "${moduleID}"; then
	# 			echo "Setting 'deployer_msi_id' removed from state"
	# 		fi
	# 	fi

	# fi
	if [ -f terraform.tfvars ]; then
		extra_vars=" -var-file=${param_dirname}/terraform.tfvars "
	fi

	print_banner "Remove deployer" "Running Terraform destroy" "info"

	parallelism=10

	#Provide a way to limit the number of parallel tasks for Terraform
	#Provide a way to limit the number of parallel tasks for Terraform
	if checkforEnvVar "TF_PARALLELLISM"; then
		parallelism=$TF_PARALLELLISM
	fi

	if terraform -chdir="${terraform_module_directory}" destroy "${approve}" -lock=false -parallelism="${parallelism}" -json -var-file="${var_file}" "$extra_vars" | tee destroy_output.json; then
		return_value=${PIPESTATUS[0]}
		print_banner "Remover" "Terraform destroy succeeded" "success"
	else
		return_value=${PIPESTATUS[0]}
		print_banner "Remover" "Terraform destroy failed" "error"
	fi

	if [ -f destroy_output.json ]; then
		errors_occurred=$(jq 'select(."@level" == "error") | length' destroy_output.json)

		if [[ -n $errors_occurred ]]; then
			print_banner "Remove deployer" "Errors occurred during the destroy phase" "error"

			return_value=10
			all_errors=$(jq 'select(."@level" == "error") | {summary: .diagnostic.summary, detail: .diagnostic.detail}' destroy_output.json)
			if [[ -n ${all_errors} ]]; then
				readarray -t errors_strings < <(echo ${all_errors} | jq -c '.')
				for errors_string in "${errors_strings[@]}"; do
					string_to_report=$(jq -c -r '.detail ' <<<"$errors_string")
					if [[ -z ${string_to_report} ]]; then
						string_to_report=$(jq -c -r '.summary ' <<<"$errors_string")
					fi

					echo -e "#                          $bold_red_underscore  $string_to_report $reset_formatting"
					echo "##vso[task.logissue type=error]${string_to_report}"

				done

			fi
		fi
	fi

	if [ -f destroy_output.json ]; then
		rm destroy_output.json
	fi

	if [ 0 == $return_value ]; then
		print_banner "Remove deployer" "Deployer removed successfully" "success"
		step=0
		save_config_var "step" "${deployer_config_information}"
	fi

	unset TF_DATA_DIR

	echo "Return from remove_deployer.sh"
	return $return_value
}

################################################################################
# Main script execution                                                        #
# This script is designed to be run directly, not sourced.                     #
# It will execute the sdaf_remove_deployer function and handle the exit codes. #
################################################################################
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
	# Only run if script is executed directly, not when sourced
	if sdaf_remove_deployer "$@"; then
		exit 0
	else
		exit $?
	fi
fi
