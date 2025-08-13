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
if [[ "${DEBUG:-false}" == 'true' ]]; then
	# Enable debugging
	set -x
	echo "Environment variables:"
	printenv | sort
fi

# Constants
script_directory="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
readonly script_directory

SCRIPT_NAME="$(basename "$0")"

################################################################################
# Function to display a help message for the deployer installation script.     #
# Arguments:                                                                   #
#   None                                                                       #
# Returns:                                                                     #
#   None                                                                       #
# Usage:                                                                       #
#   show_deployer_help                                                         #
################################################################################
function show_deployer_help {
	echo ""
	echo "#########################################################################################"
	echo "#                                                                                       #"
	echo "#                                                                                       #"
	echo "#   This file contains the logic to deploy the deployer.                                #"
	echo "#   The script experts the following exports:                                           #"
	echo "#                                                                                       #"
	echo "#     ARM_SUBSCRIPTION_ID to specify which subscription to deploy to                    #"
	echo "#     SAP_AUTOMATION_REPO_PATH the path to the folder containing the cloned sap-automation        #"
	echo "#                                                                                       #"
	echo "#   The script will persist the parameters needed between the executions in the         #"
	echo "#   [CONFIG_REPO_PATH]/.sap_deployment_automation folder                                #"
	echo "#                                                                                       #"
	echo "#                                                                                       #"
	echo "#   Usage: install_deployer.sh                                                          #"
	echo "#    -p deployer parameter file                                                         #"
	echo "#                                                                                       #"
	echo "#    -i interactive true/false setting the value to false will not prompt before apply  #"
	echo "#    -h Show help                                                                       #"
	echo "#                                                                                       #"
	echo "#   Example:                                                                            #"
	echo "#                                                                                       #"
	echo "#   [REPO-ROOT]deploy/scripts/install_deployer.sh \                                     #"
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
	input_opts=$(getopt -n install_deployer_v2 -o p:c:ih --longoptions parameter_file:,control_plane_name:,auto-approve,help -- "$@")
	is_input_opts_valid=$?

	if [[ "${is_input_opts_valid}" != "0" ]]; then
		show_deployer_help
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
			export CONTROL_PLANE_NAME
			shift 2
			;;
		-i | --auto-approve)
			approve="--auto-approve"
			shift
			;;
		-h | --help)
			show_deployer_help
			return 3
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

	if ! printenv CONTROL_PLANE_NAME; then
		CONTROL_PLANE_NAME=$(echo "${parameter_file_name}" | cut -d '-' -f 1-3)
		export CONTROL_PLANE_NAME
	fi

	echo "Control Plane name:                  $CONTROL_PLANE_NAME"
	echo "Current directory:                   $(pwd)"

	param_dirname=$(dirname "${parameter_file_name}")
	export TF_DATA_DIR="${param_dirname}"/.terraform

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

	return 0
}

############################################################################################
# Function to install the deployer.                                                        #
# Arguments:                                                                               #
#   None                                                                                   #
# Returns:                                                                                 #
#   0 on success, non-zero on failure                                                      #
# Usage:                                                                                   #
#   install_deployer                                                                       #
############################################################################################
function install_deployer() {
	deployment_system=sap_deployer
	local green="\033[0;32m"
	local reset="\033[0m"
	approve=""

	# Define an array of helper scripts
	helper_scripts=(
		"${script_directory}/helpers/script_helpers.sh"
		"${script_directory}/deploy_utils.sh"
	)

	banner_title="Bootstrap Deployer"

	# Call the function with the array
	source_helper_scripts "${helper_scripts[@]}"

	print_banner "$banner_title" "Entering $SCRIPT_NAME" "info"

	# Parse command line arguments
	if ! parse_arguments "$@"; then
		print_banner "$banner_title" "Validating parameters failed" "error"
		return $?
	fi
	param_dirname=$(dirname "${parameter_file_name}")
	export TF_DATA_DIR="${param_dirname}/.terraform"

	print_banner "$banner_title" "Deploying the deployer" "info"

	#Persisting the parameters across executions
	automation_config_directory=$CONFIG_REPO_PATH/.sap_deployment_automation/
	generic_config_information="${automation_config_directory}"config
	deployer_config_information="${automation_config_directory}/$CONTROL_PLANE_NAME"
	CONFIG_DIR="${CONFIG_REPO_PATH}/.sap_deployment_automation"

	if [ ! -f "$deployer_config_information" ]; then
		if [ -f "${CONFIG_DIR}/${environment}${region_code}" ]; then
			echo "Move existing configuration file"
			sudo mv "${CONFIG_DIR}/${environment}${region_code}" "${deployer_config_information}"
		fi
	fi

	param_dirname=$(pwd)

	init "${automation_config_directory}" "${generic_config_information}" "${deployer_config_information}"

	var_file="${param_dirname}/${parameter_file_name}"

	echo ""
	echo -e "${green}Deployment information:"
	echo -e "-------------------------------------------------------------------------------$reset"

	echo "Configuration file:                  $parameter_file_name"
	echo "Control Plane name:                  $CONTROL_PLANE_NAME"

	terraform_module_directory="${SAP_AUTOMATION_REPO_PATH}"/deploy/terraform/bootstrap/"${deployment_system}"/
	export TF_DATA_DIR="${param_dirname}"/.terraform

	this_ip=$(curl -s ipinfo.io/ip) >/dev/null 2>&1
	export TF_VAR_Agent_IP=$this_ip
	echo "Agent IP:                            $this_ip"

	extra_vars=""

	if [ -f terraform.tfvars ]; then
		extra_vars=" -var-file=${param_dirname}/terraform.tfvars "
	fi

	allParameters=$(printf " -var-file=%s %s" "${var_file}" "${extra_vars}")
	allImportParameters=$(printf " -var-file=%s %s " "${var_file}" "${extra_vars}")

	if [ ! -d .terraform/ ]; then
		print_banner "$banner_title" "New deployment" "info"
		terraform -chdir="${terraform_module_directory}" init -upgrade=true -backend-config "path=${param_dirname}/terraform.tfstate"
		return_value=$?
	else
		if [ -f .terraform/terraform.tfstate ]; then
			azure_backend=$(grep "\"type\": \"azurerm\"" .terraform/terraform.tfstate || true)
			if [ -n "$azure_backend" ]; then
				print_banner "$banner_title" "State already migrated to Azure" "warning"

				if terraform -chdir="${terraform_module_directory}" init -upgrade=true -migrate-state -force-copy -backend-config "path=${param_dirname}/terraform.tfstate"; then
					return_value=$?
					print_banner "$banner_title" "Terraform init succeeded." "success"
				else
					return_value=$?
					print_banner "$banner_title" "Terraform init failed." "error"
					unset TF_DATA_DIR
					return $return_value
				fi

			else
				print_banner "$banner_title" "Running terraform init" "info"
				if terraform -chdir="${terraform_module_directory}" init -upgrade=true -migrate-state -backend-config "path=${param_dirname}/terraform.tfstate"; then
					return_value=$?
					print_banner "$banner_title" "Terraform init succeeded." "success"
				else
					return_value=$?
					print_banner "$banner_title" "Terraform init failed." "error"
					unset TF_DATA_DIR
					return $return_value
				fi
			fi
		fi
		echo "Parameters:                          $allParameters"
		terraform -chdir="${terraform_module_directory}" refresh $allParameters
	fi

	print_banner "$banner_title" "Running Terraform plan" "info"

	#########################################################################################"
	#                                                                                       #
	#                             Running Terraform plan                                    #
	#                                                                                       #
	#########################################################################################

	# shellcheck disable=SC2086

	if terraform -chdir="$terraform_module_directory" plan -detailed-exitcode -input=false $allParameters | tee plan_output.log; then
		return_value=${PIPESTATUS[0]}
	else
		return_value=${PIPESTATUS[0]}
	fi

	if [ 1 == "$return_value" ]; then
		print_banner "$banner_title" "Terraform plan failed" "error"
		if [ -f plan_output.log ]; then
			cat plan_output.log
			rm plan_output.log
		fi
		unset TF_DATA_DIR
		return $return_value
	fi

	if [ -f plan_output.log ]; then
		rm plan_output.log
	fi

	if [ "${TEST_ONLY:-false}" == "true" ]; then
		print_banner "$banner_title" "Running plan only. No deployment performed." "info"
		exit 10
	fi

	#########################################################################################
	#                                                                                       #
	#                             Running Terraform apply                                   #
	#                                                                                       #"
	#########################################################################################

	if [ 2 == $return_value ]; then
		print_banner "$banner_title" "Running Terraform apply" "info"
		parallelism=10

		#Provide a way to limit the number of parallel tasks for Terraform
		if checkforEnvVar "TF_PARALLELLISM"; then
			parallelism=$TF_PARALLELLISM
		fi

		if [ -f apply_output.json ]; then
			rm apply_output.json
		fi

		if [ -n "${approve}" ]; then
			# shellcheck disable=SC2086
			if terraform -chdir="${terraform_module_directory}" apply -parallelism="${parallelism}" \
				$allParameters -no-color -compact-warnings -json -input=false --auto-approve | tee apply_output.json; then
				return_value=${PIPESTATUS[0]}
				print_banner "$banner_title" "Terraform apply succeeded" "success" "Terraform apply return code: $return_value"
			else
				return_value=${PIPESTATUS[0]}
				print_banner "$banner_title" "Terraform apply failed." "error" "Terraform apply return code: $return_value"
			fi
		else
			# shellcheck disable=SC2086
			if terraform -chdir="${terraform_module_directory}" apply -parallelism="${parallelism}" $allParameters; then
				return_value=$?
				print_banner "$banner_title" "Terraform apply succeeded" "success" "Terraform apply return code: $return_value"
			else
				return_value=$?
				print_banner "$banner_title" "Terraform apply failed." "error" "Terraform apply return code: $return_value"
			fi
		fi

		if [ -f apply_output.json ]; then
			errors_occurred=$(jq 'select(."@level" == "error") | length' apply_output.json)

			if [[ -n $errors_occurred ]]; then
				return_value=0
				# shellcheck disable=SC2086
				if ImportAndReRunApply "apply_output.json" "${terraform_module_directory}" $allImportParameters $allParameters; then
					return_value=0
				else
					return_value=$?
				fi
				if [ -f apply_output.json ]; then
					# shellcheck disable=SC2086
					if ImportAndReRunApply "apply_output.json" "${terraform_module_directory}" $allImportParameters $allParameters; then
						return_value=0
					else
						return_value=$?
					fi
				fi
				if [ -f apply_output.json ]; then
					# shellcheck disable=SC2086
					if ImportAndReRunApply "apply_output.json" "${terraform_module_directory}" $allImportParameters $allParameters; then
						return_value=0
					else
						return_value=$?
					fi
				fi
				if [ -f apply_output.json ]; then
					# shellcheck disable=SC2086
					if ImportAndReRunApply "apply_output.json" "${terraform_module_directory}" $allImportParameters $allParameters; then
						return_value=0
					else
						return_value=$?
					fi
				fi
				if [ -f apply_output.json ]; then
					# shellcheck disable=SC2086
					if ImportAndReRunApply "apply_output.json" "${terraform_module_directory}" $allImportParameters $allParameters; then
						return_value=0
					else
						return_value=$?
					fi
				fi
				if [ -f apply_output.json ]; then
					# shellcheck disable=SC2086
					if ImportAndReRunApply "apply_output.json" "${terraform_module_directory}" $allImportParameters $allParameters; then
						return_value=0
					else
						return_value=$?
					fi
				fi
			fi
		fi

		echo "Terraform Apply return code:         $return_value"

		if [ 0 != $return_value ]; then
			print_banner "$banner_title" "!!! Error when creating the deployer !!!." "error"
			return 10
		fi
	fi

	DEPLOYER_KEYVAULT=$(terraform -chdir="${terraform_module_directory}" output -no-color -raw deployer_kv_user_name | tr -d \")
	if [ -n "${DEPLOYER_KEYVAULT}" ]; then
		printf -v val %-.20s "$DEPLOYER_KEYVAULT"
		print_banner "$banner_title" "Keyvault to use for deployment credentials: $val" "info"

		save_config_var "DEPLOYER_KEYVAULT" "${deployer_config_information}"
		export DEPLOYER_KEYVAULT
	fi

	APPLICATION_CONFIGURATION_ID=$(terraform -chdir="${terraform_module_directory}" output -no-color -raw application_configuration_id | tr -d \")
	if [ -n "${APPLICATION_CONFIGURATION_ID}" ]; then
		save_config_var "APPLICATION_CONFIGURATION_ID" "${deployer_config_information}"
		export APPLICATION_CONFIGURATION_ID
	fi

	APPLICATION_CONFIGURATION_NAME=$(echo "${APPLICATION_CONFIGURATION_ID}" | cut -d '/' -f 9)
	if [ -n "${APPLICATION_CONFIGURATION_NAME}" ]; then
		save_config_var "APPLICATION_CONFIGURATION_NAME" "${deployer_config_information}"
		export APPLICATION_CONFIGURATION_NAME
	fi

	APP_SERVICE_NAME=$(terraform -chdir="${terraform_module_directory}" output -no-color -raw webapp_url_base | tr -d \")
	if [ -n "${APP_SERVICE_NAME}" ]; then
		printf -v val %-.20s "$DEPLOYER_KEYVAULT"
		print_banner "$banner_title" "Application Configuration: $val" "info"
		save_config_var "APP_SERVICE_NAME" "${deployer_config_information}"
		export APP_SERVICE_NAME
	fi

	APPLICATION_CONFIGURATION_DEPLOYMENT=$(terraform -chdir="${terraform_module_directory}" output -no-color -raw app_config_deployment | tr -d \")
	if [ -n "${APPLICATION_CONFIGURATION_DEPLOYMENT}" ]; then
		save_config_var "APPLICATION_CONFIGURATION_DEPLOYMENT" "${deployer_config_information}"
		export APPLICATION_CONFIGURATION_DEPLOYMENT
		echo "APPLICATION_CONFIGURATION_DEPLOYMENT:  $APPLICATION_CONFIGURATION_DEPLOYMENT"
	fi

	ARM_CLIENT_ID=$(terraform -chdir="${terraform_module_directory}" output -no-color -raw deployer_client_id | tr -d \")
	if [ -n "${ARM_CLIENT_ID}" ]; then
		save_config_var "ARM_CLIENT_ID" "${deployer_config_information}"
		export ARM_CLIENT_ID
	fi

	ARM_OBJECT_ID=$(terraform -chdir="${terraform_module_directory}" output -no-color -raw deployer_user_assigned_identity | tr -d \")
	if [ -n "${ARM_OBJECT_ID}" ]; then
		save_config_var "ARM_OBJECT_ID" "${deployer_config_information}"
		export ARM_OBJECT_ID
	fi

	DevOpsInfrastructureObjectId=$(terraform -chdir="${terraform_module_directory}" output -no-color -raw DevOpsInfrastructureObjectId | tr -d \")
	if [ -n "${DevOpsInfrastructureObjectId}" ]; then
		save_config_var "DevOpsInfrastructureObjectId" "${deployer_config_information}"
		export DevOpsInfrastructureObjectId
	fi

	HAS_WEBAPP=$(terraform -chdir="${terraform_module_directory}" output -no-color -raw app_service_deployment | tr -d \")
	if [ -n "${HAS_WEBAPP}" ]; then
		save_config_var "HAS_WEBAPP" "${deployer_config_information}"
		export HAS_WEBAPP
	fi

	deployer_random_id=$(terraform -chdir="${terraform_module_directory}" output -no-color -raw random_id | tr -d \")
	if [ -n "${deployer_random_id}" ]; then
		custom_random_id="${deployer_random_id:0:3}"
		sed -i -e /"custom_random_id"/d "${var_file}"
		printf "# The parameter 'custom_random_id' can be used to control the random 3 digits at the end of the storage accounts and key vaults\ncustom_random_id=\"%s\"\n" "${custom_random_id}" >>"${var_file}"

	fi

	unset TF_DATA_DIR

	print_banner "$banner_title" "Exiting $SCRIPT_NAME" "info"

	return $return_value
}

###############################################################################
# Main script execution                                                       #
# This script is designed to be run directly, not sourced.                    #
# It will execute the install_deployer function and handle the exit codes.      #
###############################################################################
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
	# Only run if script is executed directly, not when sourced

	if install_deployer "$@"; then
		exit 0
	else
		exit $?
	fi
fi
