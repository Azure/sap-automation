#!/bin/bash
# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

# Ensure that the exit status of a pipeline command is non-zero if any
# stage of the pipefile has a non-zero exit status.
set -o pipefail

#colors for terminal
cyan="\e[1;36m"
reset_formatting="\e[0m"

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

terraform_storage_account_name=""

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
	approve=""
	subscription=$ARM_SUBSCRIPTION_ID
	only_deployer=0
	approve=""
	deployer_parameter_file=""
	library_parameter_file=""

	local input_opts
	input_opts=$(getopt -n deploy_control_plane_v2 -o c:d:l:s:c:p:t:a:k:ifohrvmg --longoptions control_plane_name:,deployer_parameter_file:,library_parameter_file:,subscription:,spn_id:,spn_secret:,tenant_id:,terraform_storage_account_name:,vault:,auto-approve,force,only_deployer,help,recover,ado,msi,github -- "$@")
	VALID_ARGUMENTS=$?

	if [ "$VALID_ARGUMENTS" != "0" ]; then
		control_plane_show_help_v2
	fi

	eval set -- "$input_opts"
	while true; do
		case "$1" in
		-c | --control_plane_name)
			CONTROL_PLANE_NAME="$2"
			TF_VAR_control_plane_name="$CONTROL_PLANE_NAME"
			export TF_VAR_control_plane_name
			shift 2
			;;
		-d | --deployer_parameter_file)
			deployer_parameter_file="$2"
			shift 2
			;;
		-k | --vault)
			keyvault="$2"
			shift 2
			;;
		-l | --library_parameter_file)
			library_parameter_file="$2"
			shift 2
			;;
		-o | --only_deployer)
			only_deployer=1
			shift
			;;
		-s | --subscription)
			subscription="$2"
			TF_VAR_subscription_id="$subscription"
			export TF_VAR_subscription_id
			ARM_SUBSCRIPTION_ID="$subscription"
			export ARM_SUBSCRIPTION_ID
			shift 2
			;;
		-t | --terraform_storage_account_name)
			terraform_storage_account_name="$2"
			shift 2
			;;
		-f | --force)
			force=1
			shift
			;;
		-g | --github)
			devops_flag="--devops"
			shift
			;;
		-h | --help)
			control_plane_show_help_v2
			exit 3
			;;
		-i | --auto-approve)
			approve="--auto-approve"
			shift
			;;
		-m | --msi)
			USE_MSI=true
			export USE_MSI
			shift
			;;
		-v | --ado)
			devops_flag="--devops"
			shift
			;;
		-r | --recover)
			shift
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
		control_plane_missing_v2 'library parameter file' "$SCRIPT_NAME"
		exit 2 #No such file or directory
	fi
	if [ ! -f "${deployer_parameter_file}" ]; then
		control_plane_missing_v2 'deployer parameter file' "$SCRIPT_NAME"
		exit 2 #No such file or directory
	fi

	if [ "$devops_flag" == "--devops" ] || [ "$approve" == "--auto-approve" ]; then
		echo "Approve:                             Automatically"
		autoApproveParameter="--auto-approve"
	else
		autoApproveParameter=""
	fi
	key=$(basename "${deployer_parameter_file}" | cut -d. -f1)
	deployer_tfstate_key="${key}.terraform.tfstate"
	deployer_dirname=$(dirname "${deployer_parameter_file}")
	deployer_parameter_file_name=$(basename "${deployer_parameter_file}")

	key=$(basename "${library_parameter_file}" | cut -d. -f1)
	library_tfstate_key="${key}.terraform.tfstate"
	library_dirname=$(dirname "${library_parameter_file}")
	library_parameter_file_name=$(basename "${library_parameter_file}")

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
	CONFIG_DIR="${CONFIG_REPO_PATH}/.sap_deployment_automation"

	# Convert the region to the correct code
	get_region_code "$region"

}

############################################################################################
# Function to install the Deployer and its supporting infrastructure.                      #
# Can be run from a Microsoft hosted agent or a self-hosted agent.                         #
# Arguments:                                                                               #
#   None                                                                                   #
# Returns:                                                                                 #
#   0 on success, non-zero on failure                                                      #
# Usage:                                                                                   #
#   bootstrap_deployer                                                                     #
############################################################################################

function bootstrap_deployer() {
	##########################################################################################
	#                                                                                        #
	#                                      STEP 0                                            #
	#                                                                                        #
	#                           Bootstrapping the deployer                                   #
	#                                                                                        #
	##########################################################################################

	local local_return_code=0
	load_config_vars "${deployer_environment_file_name}" "step"
	if [ -z "$step" ]; then
		step=0
		save_config_var "step" "${deployer_environment_file_name}"
	fi

	if [ 0 -eq $step ]; then
		print_banner "Bootstrap Deployer " "Bootstrapping the deployer..." "info"
		allParameters=$(printf " --parameter_file %s %s" "${deployer_parameter_file_name}" "${autoApproveParameter}")

		cd "${deployer_dirname}" || exit

		echo "Calling install_deployer_v2.sh:         $allParameters"

		if "${SAP_AUTOMATION_REPO_PATH}/deploy/scripts/install_deployer_v2.sh" --parameter_file "${deployer_parameter_file_name}" "$autoApproveParameter"; then
			local_return_code=$?
			print_banner "Bootstrap Deployer " "Bootstrapping the deployer succeeded" "success"
			step=1
			save_config_var "step" "${deployer_environment_file_name}"
		else
			local_return_code=$?
			echo "Return code from install_deployer_v2: ${local_return_code}"
			print_banner "Bootstrap Deployer " "Bootstrapping the deployer failed" "error" "Return code: ${local_return_code}"
		fi
	fi

	load_config_vars "${deployer_environment_file_name}" "DEPLOYER_KEYVAULT" "APPLICATION_CONFIGURATION_ID" "APPLICATION_CONFIGURATION_NAME"
	echo "Key vault:                           ${DEPLOYER_KEYVAULT}"
	export DEPLOYER_KEYVAULT

	if [ -v APPLICATION_CONFIGURATION_NAME ]; then
		echo "Application configuration name:      ${APPLICATION_CONFIGURATION_NAME}"
	fi

	if [ "$devops_flag" == "--devops" ]; then
		echo "##vso[task.setprogress value=20;]Progress Indicator"
	fi
	cd "$root_dirname" || exit
	return $local_return_code
}

############################################################################################
# Function to validate the Key Vault access.                                               #
# Arguments:                                                                               #
#   None                                                                                   #
# Returns:                                                                                 #
#   0 on success, non-zero on failure                                                      #
# Usage:                                                                                   #
#   validate_keyvault_access                                                               #
############################################################################################

function validate_keyvault_access {

	##########################################################################################
	#                                                                                        #
	#                                     Step 1                                             #
	#                           Validating Key Vault Access                                  #
	#                                                                                        #
	#                                                                                        #
	##########################################################################################

	TF_DATA_DIR="${deployer_dirname}"/.terraform
	export TF_DATA_DIR

	if ! printenv DEPLOYER_KEYVAULT; then

		if is_valid_id "${APPLICATION_CONFIGURATION_ID:-}" "/providers/Microsoft.AppConfiguration/configurationStores/"; then
			DEPLOYER_KEYVAULT=$(getVariableFromApplicationConfiguration "$APPLICATION_CONFIGURATION_ID" "${CONTROL_PLANE_NAME}_KeyVaultName" "${CONTROL_PLANE_NAME}")
		else
			if [ -f ./.terraform/terraform.tfstate ]; then
				azure_backend=$(grep "\"type\": \"azurerm\"" .terraform/terraform.tfstate || true)
				if [ -n "$azure_backend" ]; then
					echo "Terraform state:                     remote"

					terraform_module_directory="$SAP_AUTOMATION_REPO_PATH"/deploy/terraform/run/sap_deployer/
					terraform -chdir="${terraform_module_directory}" init -upgrade=true

					keyvault=$(terraform -chdir="${terraform_module_directory}" output deployer_kv_user_name | tr -d \")
					save_config_var "keyvault" "${deployer_environment_file_name}"
				else
					echo "Terraform state:                     local"
					terraform_module_directory="$SAP_AUTOMATION_REPO_PATH"/deploy/terraform/bootstrap/sap_deployer/
					terraform -chdir="${terraform_module_directory}" init -upgrade=true

					keyvault=$(terraform -chdir="${terraform_module_directory}" output deployer_kv_user_name | tr -d \")
					save_config_var "keyvault" "${deployer_environment_file_name}"
				fi
			else
				if [ $devops_flag != "--devops" ]; then
					read -r -p "Deployer keyvault name: " DEPLOYER_KEYVAULT
					save_config_var "DEPLOYER_KEYVAULT" "${deployer_environment_file_name}"
				else
					step=0
					save_config_var "step" "${deployer_environment_file_name}"
					exit 10
				fi
			fi
		fi
	fi

	if [ -n "${DEPLOYER_KEYVAULT}" ] && [ 0 != "$step" ]; then

		if validate_key_vault "$DEPLOYER_KEYVAULT" "$ARM_SUBSCRIPTION_ID"; then
			echo "Key vault:                           ${DEPLOYER_KEYVAULT}"
			save_config_var "DEPLOYER_KEYVAULT" "${deployer_environment_file_name}"
			TF_VAR_deployer_kv_user_arm_id=$(az keyvault show --name="$DEPLOYER_KEYVAULT" --subscription "${subscription}" --query id --output tsv)
			export TF_VAR_deployer_kv_user_arm_id

		else
			return_code=$?
			print_banner "Key Vault" "Key vault not found" "error"
		fi

	fi
	step=2
	save_config_var "step" "${deployer_environment_file_name}"

	cd "${deployer_dirname}" || exit

	unset TF_DATA_DIR

	cd "$root_dirname" || exit

	az account set --subscription "$ARM_SUBSCRIPTION_ID"
	return $return_code
}

############################################################################################
# Function to install the SAP Library and its supporting infrastructure.                   #
# Storage accounts for installation media and Terraform state files are created.           #
# (Optionally)                                                                             #
#   Private DNS zones                                                                      #
# Must be run from a self-hosted agent.                                                    #
# Arguments:                                                                               #
#   None                                                                                   #
# Returns:                                                                                 #
#   0 on success, non-zero on failure                                                      #
# Usage:                                                                                   #
#   bootstrap_library                                                                      #
############################################################################################

function bootstrap_library {
	##########################################################################################
	#                                                                                        #
	#                                      STEP 2                                            #
	#                           Bootstrapping the library                                    #
	#                                                                                        #
	#                                                                                        #
	##########################################################################################
	local banner_title="Bootstrap Library"
	load_config_vars "${deployer_environment_file_name}" "DEPLOYER_KEYVAULT" "APPLICATION_CONFIGURATION_ID" "APPLICATION_CONFIGURATION_NAME"

	if [ 2 -eq $step ]; then
		print_banner "$banner_title" "Bootstrapping the library..." "info"
		if is_valid_id "$APPLICATION_CONFIGURATION_ID" "/providers/Microsoft.AppConfiguration/configurationStores/"; then
			TF_VAR_application_configuration_id=$APPLICATION_CONFIGURATION_ID
			export TF_VAR_application_configuration_id
		fi

		relative_path="${library_dirname}"
		export TF_DATA_DIR="${relative_path}/.terraform"
		relative_path="${deployer_dirname}"

		cd "${library_dirname}" || exit
		terraform_module_directory="${SAP_AUTOMATION_REPO_PATH}"/deploy/terraform/bootstrap/sap_library/

		echo "Calling install_library_v2.sh with: --parameter_file ${library_parameter_file_name} --deployer_statefile_foldername ${relative_path} ${autoApproveParameter} --control_plane_name ${CONTROL_PLANE_NAME} --application_configuration_name ${APPLICATION_CONFIGURATION_NAME:-}"

		if "${SAP_AUTOMATION_REPO_PATH}/deploy/scripts/install_library_v2.sh" \
			--parameter_file "${library_parameter_file_name}" \
			--deployer_statefile_foldername "${relative_path}" \
			--control_plane_name "${CONTROL_PLANE_NAME}" --application_configuration_name "${APPLICATION_CONFIGURATION_NAME:-}" \
			"$autoApproveParameter"; then
			step=3
			save_config_var "step" "${deployer_environment_file_name}"
			print_banner "$banner_title" "Bootstrapping the library succeeded." "success"
			unset TF_VAR_application_configuration_id
		else
			print_banner "$banner_title" "Bootstrapping the library failed." "error"
			step=2
			save_config_var "step" "${deployer_environment_file_name}"
			unset TF_VAR_application_configuration_id
			exit 20
		fi

		terraform_storage_account_name=$(terraform -chdir="${terraform_module_directory}" output -no-color -raw remote_state_storage_account_name | tr -d \")
		terraform_storage_account_subscription_id=$(terraform -chdir="${terraform_module_directory}" output -no-color -raw created_resource_group_subscription_id | tr -d \")

		if [ "${devops_flag}" != "--devops" ]; then
			this_ip=$(curl -s ipinfo.io/ip) >/dev/null 2>&1
			az storage account network-rule add --account-name "${terraform_storage_account_name}" --subscription "$terraform_storage_account_subscription_id" --ip-address "${this_ip}" --output none
		fi

		TF_VAR_sa_connection_string=$(terraform -chdir="${terraform_module_directory}" output -no-color -raw sa_connection_string | tr -d \")
		export TF_VAR_sa_connection_string

		tfstate_resource_id=$(az resource list --name "$terraform_storage_account_name" --subscription "$terraform_storage_account_subscription_id" --resource-type Microsoft.Storage/storageAccounts --query "[].id | [0]" -o tsv)
		TF_VAR_tfstate_resource_id=$tfstate_resource_id
		export TF_VAR_tfstate_resource_id
		save_config_var "tfstate_resource_id" "${deployer_environment_file_name}"

		cd "${current_directory}" || exit
		save_config_var "step" "${deployer_environment_file_name}"
		if [ "$devops_flag" == "--devops" ]; then
			echo "##vso[task.setprogress value=60;]Progress Indicator"
		fi
	else
		print_banner "$banner_title" "Library is already bootstrapped." "info"
		if [ $devops_flag == "--devops" ]; then
			echo "##vso[task.setprogress value=60;]Progress Indicator"
		fi
	fi

	unset TF_DATA_DIR
	cd "$root_dirname" || exit
	if [ $devops_flag == "--devops" ]; then
		echo "##vso[task.setprogress value=80;]Progress Indicator"
	fi
}

#############################################################################################
# Function to migrate the state file for the deployer.                                      #
# Arguments:                                                                                #
#   None                                                                                    #
# Returns:                                                                                  #
#   0 on success, non-zero on failure                                                       #
# Usage:                                                                                    #
#   migrate_library_state                                                                   #
#############################################################################################

function migrate_deployer_state() {
	##########################################################################################
	#                                                                                        #
	#                                      STEP 3                                            #
	#                           Migrating the state file for the deployer                    #
	#                                                                                        #
	#                                                                                        #
	##########################################################################################
	local banner_title="Deployer"
	print_banner "$banner_title" "Migrating the deployer state..." "info"

	cd "${deployer_dirname}" || exit
	if is_valid_id "$APPLICATION_CONFIGURATION_ID" "/providers/Microsoft.AppConfiguration/configurationStores/"; then
		print_banner "$banner_title" "Sourcing parameters from: $APPLICATION_CONFIGURATION_NAME" "info"

		tfstate_resource_id=$(getVariableFromApplicationConfiguration "$APPLICATION_CONFIGURATION_ID" "${CONTROL_PLANE_NAME}_TerraformRemoteStateStorageAccountId" "${CONTROL_PLANE_NAME}")
		TF_VAR_tfstate_resource_id=$tfstate_resource_id
		export TF_VAR_tfstate_resource_id

		terraform_storage_account_name=$(echo "$tfstate_resource_id" | cut -d '/' -f 9)
		terraform_storage_account_subscription_id=$(echo "$tfstate_resource_id" | cut -d '/' -f 3)
		terraform_storage_account_resource_group_name=$(echo "$tfstate_resource_id" | cut -d '/' -f 5)
		ARM_SUBSCRIPTION_ID=$terraform_storage_account_subscription_id
		export ARM_SUBSCRIPTION_ID
		TF_VAR_subscription_id=$tfstate_resource_id
		export TF_VAR_subscription_id
		TF_VAR_tfstate_resource_id=$tfstate_resource_id
		export TF_VAR_tfstate_resource_id
		terraform_storage_account_name=$(echo "$tfstate_resource_id" | cut -d '/' -f 9)
	fi

	if [ -z "$terraform_storage_account_name" ]; then
		print_banner "$banner_title" "Sourcing parameters from: " "info" "$(basename ${deployer_environment_file_name})"
		load_config_vars "${deployer_environment_file_name}" "tfstate_resource_id"
		TF_VAR_tfstate_resource_id=$tfstate_resource_id
		export TF_VAR_tfstate_resource_id
		terraform_storage_account_name=$(echo "$tfstate_resource_id" | cut -d '/' -f 9)
		export terraform_storage_account_name
		terraform_storage_account_resource_group_name=$(echo "$tfstate_resource_id" | cut -d'/' -f5)
		export terraform_storage_account_resource_group_name

		terraform_storage_account_subscription_id=$(echo "$tfstate_resource_id" | cut -d'/' -f3)
		export terraform_storage_account_subscription_id
	fi
	if [ -z "${terraform_storage_account_name}" ]; then
		export step=2
		save_config_var "step" "${deployer_environment_file_name}"
		echo " ##vso[task.setprogress value=40;]Progress Indicator"
		print_banner "$banner_title" "Could not find the SAP Library, please re-run!" "error"
		exit 11
	fi

	echo ""
	echo "Calling installer_v2.sh with: --type sap_deployer --parameter_file ${deployer_parameter_file_name} --control_plane_name ${CONTROL_PLANE_NAME} --application_configuration_name ${APPLICATION_CONFIGURATION_NAME:-}"
	echo ""

	if "$SAP_AUTOMATION_REPO_PATH/deploy/scripts/installer_v2.sh" --parameter_file "$deployer_parameter_file_name" --type sap_deployer \
		--control_plane_name "${CONTROL_PLANE_NAME}" --application_configuration_name "${APPLICATION_CONFIGURATION_NAME}" \
		$devops_flag "${autoApproveParameter}"; then
		print_banner "$banner_title" "Migrating the Deployer state succeeded." "success"

	else
		echo ""
		step=3
		save_config_var "step" "${deployer_environment_file_name}"
		print_banner "$banner_title" "Migrating the Deployer state failed." "error"
		exit 30
	fi

	cd "$root_dirname" || exit
	export step=4
	save_config_var "step" "${deployer_environment_file_name}"

	unset TF_DATA_DIR
	cd "$root_dirname" || exit

}

#############################################################################################
# Function to migrate the state file for the SAP library.                                   #
# Arguments:                                                                                #
#   None                                                                                    #
# Returns:                                                                                  #
#   0 on success, non-zero on failure                                                       #
# Usage:                                                                                    #
#   migrate_library_state                                                                   #
#############################################################################################

function migrate_library_state() {
	##########################################################################################
	#                                                                                        #
	#                                      STEP 4                                            #
	#                           Migrating the state file for the library                     #
	#                                                                                        #
	#                                                                                        #
	##########################################################################################
	local banner_title="Library"

	print_banner "$banner_title" "Migrating the library state..." "info"

	terraform_module_directory="$SAP_AUTOMATION_REPO_PATH"/deploy/terraform/run/sap_library/
	cd "${library_dirname}" || exit

	if [ -z "$terraform_storage_account_name" ]; then
		if is_valid_id "$APPLICATION_CONFIGURATION_ID:-" "/providers/Microsoft.AppConfiguration/configurationStores/"; then
			TF_VAR_application_configuration_id=$APPLICATION_CONFIGURATION_ID
			export TF_VAR_application_configuration_id

			tfstate_resource_id=$(getVariableFromApplicationConfiguration "$APPLICATION_CONFIGURATION_ID" "${CONTROL_PLANE_NAME}_TerraformRemoteStateStorageAccountId" "${CONTROL_PLANE_NAME}")
			TF_VAR_tfstate_resource_id=$tfstate_resource_id
			export TF_VAR_tfstate_resource_id

			terraform_storage_account_name=$(echo "$tfstate_resource_id" | cut -d '/' -f 9)
			terraform_storage_account_subscription_id=$(echo "$tfstate_resource_id" | cut -d '/' -f 3)
			terraform_storage_account_resource_group_name=$(echo "$tfstate_resource_id" | cut -d '/' -f 5)
			ARM_SUBSCRIPTION_ID=$terraform_storage_account_subscription_id
			TF_VAR_tfstate_resource_id=$tfstate_resource_id
			export TF_VAR_tfstate_resource_id
			terraform_storage_account_name=$(echo "$tfstate_resource_id" | cut -d '/' -f 9)
			save_config_vars "${deployer_environment_file_name}" "tfstate_resource_id"
		fi
		if [ -z "$terraform_storage_account_name" ]; then

			if [ -f .terraform/terraform.tfstate ]; then
				azure_backend=$(grep "\"type\": \"azurerm\"" .terraform/terraform.tfstate || true)
				if [ -n "$azure_backend" ]; then
					print_banner "$banner_title" "The state is already migrated to Azure!!!" "info"

					terraform_storage_account_subscription_id=$(grep -m1 "subscription_id" ".terraform/terraform.tfstate" | cut -d ':' -f2 | tr -d '", \r' | xargs || true)
					terraform_storage_account_name=$(grep -m1 "storage_account_name" ".terraform/terraform.tfstate" | cut -d ':' -f2 | tr -d ' ",\r' | xargs || true)
					terraform_storage_account_resource_group_name=$(grep -m1 "resource_group_name" ".terraform/terraform.tfstate" | cut -d ':' -f2 | tr -d ' ",\r' | xargs || true)
					tfstate_resource_id=$(az storage account show --name "${terraform_storage_account_name}" --query id --subscription "${terraform_storage_account_subscription_id}" --resource-group "${terraform_storage_account_resource_group_name}" --out tsv)
					TF_VAR_tfstate_resource_id=$tfstate_resource_id
					export TF_VAR_tfstate_resource_id
					export terraform_storage_account_name
					export terraform_storage_account_resource_group_name
					export terraform_storage_account_subscription_id
					save_config_vars "${deployer_environment_file_name}" "tfstate_resource_id"

				fi
			else

				print_banner "$banner_title" "Sourcing parameters from ${deployer_environment_file_name}" "info"
				load_config_vars "${deployer_environment_file_name}" "tfstate_resource_id"
				TF_VAR_tfstate_resource_id=$tfstate_resource_id
				export TF_VAR_tfstate_resource_id
				terraform_storage_account_name=$(echo "$tfstate_resource_id" | cut -d '/' -f 9)
				terraform_storage_account_resource_group_name=$(echo "$tfstate_resource_id" | cut -d'/' -f5)
				terraform_storage_account_subscription_id=$(echo "$tfstate_resource_id" | cut -d'/' -f3)
				export terraform_storage_account_name
				export terraform_storage_account_resource_group_name
				export terraform_storage_account_subscription_id
			fi
		fi
	fi
	if [ -z "${terraform_storage_account_name}" ]; then
		export step=2
		save_config_var "step" "${deployer_environment_file_name}"
		if [ $devops_flag == "--devops" ]; then
			echo "##vso[task.setprogress value=40;]Progress Indicator"
		fi
		print_banner "$banner_title" "Could not find the SAP Library, please re-run!" "error"
		exit 11
	fi

	echo ""
	echo "Calling installer_v2.sh with: --type sap_library --parameter_file ${library_parameter_file_name} --control_plane_name ${CONTROL_PLANE_NAME} --application_configuration_name ${APPLICATION_CONFIGURATION_NAME:-}"
	echo ""
	if  "$SAP_AUTOMATION_REPO_PATH/deploy/scripts/installer_v2.sh" --type sap_library --parameter_file "${library_parameter_file_name}" \
		--control_plane_name "${CONTROL_PLANE_NAME}" --application_configuration_name "${APPLICATION_CONFIGURATION_NAME:-}" \
		$devops_flag "${autoApproveParameter}"; then
		return_code=$?
		print_banner "$banner_title" "Migrating the Library state succeeded." "success"

	else
		print_banner "$banner_title" "Migrating the Library state failed." "error"
		step=4
		save_config_var "step" "${deployer_environment_file_name}"
		return 40
	fi

	cd "$root_dirname" || exit

	step=5
	save_config_var "step" "${deployer_environment_file_name}"
}

############################################################################################
# Function to copy the parameter files to the deployer.                                    #
# Arguments:                                                                               #
#   None                                                                                   #
# Returns:                                                                                 #
#   0 on success, non-zero on failure                                                      #
# Usage:                                                                                   #
#   copy_files_to_public_deployer                                                          #
############################################################################################

function copy_files_to_public_deployer() {
	if [ "${devops_flag}" == "none" ]; then
		cd "${current_directory}" || exit

		load_config_vars "${deployer_environment_file_name}" "sshsecret"
		load_config_vars "${deployer_environment_file_name}" "keyvault"
		load_config_vars "${deployer_environment_file_name}" "deployer_public_ip_address"
		if [ ! -f /etc/profile.d/deploy_server.sh ]; then
			# Only run this when not on deployer
			print_banner "Copy-Files" "Copying the parameter files..." "info"

			if [ -n "${sshsecret}" ]; then
				step=3
				save_config_var "step" "${deployer_environment_file_name}"
				printf "%s\n" "Collecting secrets from KV"
				temp_file=$(mktemp)
				ppk=$(az keyvault secret show --vault-name "${keyvault}" --name "${sshsecret}" | jq -r .value)
				echo "${ppk}" >"${temp_file}"
				chmod 600 "${temp_file}"

				remote_deployer_dir="/home/azureadm/Azure_SAP_Automated_Deployment/WORKSPACES/"$(dirname "$deployer_parameter_file")
				remote_library_dir="/home/azureadm/Azure_SAP_Automated_Deployment/WORKSPACES/"$(dirname "$library_parameter_file")
				remote_config_dir="$CONFIG_REPO_PATH/.sap_deployment_automation"

				ssh -i "${temp_file}" -o StrictHostKeyChecking=no -o ConnectTimeout=10 azureadm@"${deployer_public_ip_address}" "mkdir -p ${remote_deployer_dir}"/.terraform 2>/dev/null
				scp -i "${temp_file}" -q -o StrictHostKeyChecking=no -o ConnectTimeout=120 -p "$deployer_parameter_file" azureadm@"${deployer_public_ip_address}":"${remote_deployer_dir}"/. 2>/dev/null
				scp -i "${temp_file}" -q -o StrictHostKeyChecking=no -o ConnectTimeout=120 -p "$(dirname "$deployer_parameter_file")"/.terraform/terraform.tfstate azureadm@"${deployer_public_ip_address}":"${remote_deployer_dir}"/.terraform/terraform.tfstate 2>/dev/null
				scp -i "${temp_file}" -q -o StrictHostKeyChecking=no -o ConnectTimeout=120 -p "$(dirname "$deployer_parameter_file")"/terraform.tfstate azureadm@"${deployer_public_ip_address}":"${remote_deployer_dir}"/terraform.tfstate 2>/dev/null

				ssh -i "${temp_file}" -o StrictHostKeyChecking=no -o ConnectTimeout=10 azureadm@"${deployer_public_ip_address}" " mkdir -p ${remote_library_dir}"/.terraform 2>/dev/null
				scp -i "${temp_file}" -q -o StrictHostKeyChecking=no -o ConnectTimeout=120 -p "$(dirname "$deployer_parameter_file")"/.terraform/terraform.tfstate azureadm@"${deployer_public_ip_address}":"${remote_deployer_dir}"/. 2>/dev/null
				scp -i "${temp_file}" -q -o StrictHostKeyChecking=no -o ConnectTimeout=120 -p "$library_parameter_file" azureadm@"${deployer_public_ip_address}":"$remote_library_dir"/. 2>/dev/null

				ssh -i "${temp_file}" -o StrictHostKeyChecking=no -o ConnectTimeout=10 azureadm@"${deployer_public_ip_address}" "mkdir -p ${remote_config_dir}" 2>/dev/null
				scp -i "${temp_file}" -q -o StrictHostKeyChecking=no -o ConnectTimeout=120 -p "${deployer_environment_file_name}" azureadm@"${deployer_public_ip_address}":"${remote_config_dir}"/. 2>/dev/null
				rm "${temp_file}"
			fi
		fi

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

	if ! is_valid_id "${APPLICATION_CONFIGURATION_ID:-}" "/providers/Microsoft.AppConfiguration/configurationStores/"; then
		load_config_vars "${deployer_environment_file_name}" "APPLICATION_CONFIGURATION_ID"
	fi

	if is_valid_id "${APPLICATION_CONFIGURATION_ID:-}" "/providers/Microsoft.AppConfiguration/configurationStores/"; then
		application_configuration_name=$(echo "${APPLICATION_CONFIGURATION_ID}" | cut -d'/' -f9)
		key_vault_id=$(getVariableFromApplicationConfiguration "$APPLICATION_CONFIGURATION_ID" "${CONTROL_PLANE_NAME}_KeyVaultResourceId" "${CONTROL_PLANE_NAME}")
		if [ -z "$key_vault_id" ]; then
			if [ $devops_flag == "--devops" ]; then
				echo "##vso[task.logissue type=error]Key '${CONTROL_PLANE_NAME}_KeyVaultResourceId' was not found in the application configuration ( '$application_configuration_name' )."
			fi
		fi

		ARM_SUBSCRIPTION_ID=$(getVariableFromApplicationConfiguration "$APPLICATION_CONFIGURATION_ID" "${CONTROL_PLANE_NAME}_SubscriptionId" "${CONTROL_PLANE_NAME}")
		export ARM_SUBSCRIPTION_ID
		TF_VAR_subscription_id=$ARM_SUBSCRIPTION_ID
		export TF_VAR_subscription_id

		tfstate_resource_id=$(getVariableFromApplicationConfiguration "$APPLICATION_CONFIGURATION_ID" "${CONTROL_PLANE_NAME}_TerraformRemoteStateStorageAccountId" "${CONTROL_PLANE_NAME}")
		export tfstate_resource_id
		tfstate_resource_id=$(getVariableFromApplicationConfiguration "$APPLICATION_CONFIGURATION_ID" "${CONTROL_PLANE_NAME}_TerraformRemoteStateStorageAccountId" "$CONTROL_PLANE_NAME")
		TF_VAR_tfstate_resource_id=$tfstate_resource_id
		export TF_VAR_tfstate_resource_id

		terraform_storage_account_name=$(echo "$tfstate_resource_id" | cut -d'/' -f9)
		export terraform_storage_account_name

		terraform_storage_account_resource_group_name=$(echo "$tfstate_resource_id" | cut -d'/' -f5)
		export terraform_storage_account_resource_group_name

		terraform_storage_account_subscription_id=$(echo "$tfstate_resource_id" | cut -d'/' -f3)
		TF_VAR_deployer_kv_user_arm_id=$(getVariableFromApplicationConfiguration "$APPLICATION_CONFIGURATION_ID" "${CONTROL_PLANE_NAME}_KeyVaultResourceId" "$CONTROL_PLANE_NAME")
		export TF_VAR_spn_keyvault_id="${TF_VAR_deployer_kv_user_arm_id}"

		keyvault=$(getVariableFromApplicationConfiguration "$APPLICATION_CONFIGURATION_ID" "${CONTROL_PLANE_NAME}_KeyVaultName" "${CONTROL_PLANE_NAME}")
		export keyvault

		app_service_id=$(getVariableFromApplicationConfiguration "$APPLICATION_CONFIGURATION_ID" "${CONTROL_PLANE_NAME}_AppServiceId" "${CONTROL_PLANE_NAME}")
		export app_service_id

		export terraform_storage_account_subscription_id
	else
		if [ -f "${deployer_dirname}/.terraform/terraform.tfstate" ]; then
			local_backend=$(grep "\"type\": \"azurerm\"" .terraform/terraform.tfstate || true)
			if [ -n "${local_backend}" ]; then

				terraform_storage_account_subscription_id=$(grep -m1 "subscription_id" "${deployer_dirname}/.terraform/terraform.tfstate" | cut -d ':' -f2 | tr -d '", \r' | xargs || true)
				terraform_storage_account_name=$(grep -m1 "storage_account_name" "${deployer_dirname}/.terraform/terraform.tfstate" | cut -d ':' -f2 | tr -d ' ",\r' | xargs || true)
				terraform_storage_account_resource_group_name=$(grep -m1 "resource_group_name" "${deployer_dirname}/.terraform/terraform.tfstate" | cut -d ':' -f2 | tr -d ' ",\r' | xargs || true)
				tfstate_resource_id=$(az storage account show --name "${terraform_storage_account_name}" --query id --subscription "${terraform_storage_account_subscription_id}" --resource-group "${terraform_storage_account_resource_group_name}" --out tsv)
			fi
		else
			load_config_vars "${deployer_environment_file_name}" \
				tfstate_resource_id DEPLOYER_KEYVAULT

			TF_VAR_spn_keyvault_id=$(az keyvault show --name "${DEPLOYER_KEYVAULT}" --query id --subscription "${ARM_SUBSCRIPTION_ID}" --out tsv)
			export TF_VAR_spn_keyvault_id

			export TF_VAR_tfstate_resource_id
			terraform_storage_account_name=$(echo "$tfstate_resource_id" | cut -d'/' -f9)
			export terraform_storage_account_name

			terraform_storage_account_resource_group_name=$(echo "$tfstate_resource_id" | cut -d'/' -f5)
			export terraform_storage_account_resource_group_name

			terraform_storage_account_subscription_id=$(echo "$tfstate_resource_id" | cut -d'/' -f3)
			export terraform_storage_account_subscription_id
		fi
	fi

}

############################################################################################
# Function to execute the deployment steps.                                                #
# Step 1: Bootstrap the deployer                                                           #
# Step 1: Validate key vault access                                                        #
# Step 2: Bootstrap the library                                                            #
# Step 3: Migrate the deployer state                                                       #
# Step 4: Migrate the library state                                                        #
# Step 5: Copy files to the public deployer                                                #
#                                                                                          #
# Arguments:                                                                               #
#   step: The current step number                                                          #
# Returns:                                                                                 #
#   0 on success, non-zero on failure                                                      #
# Usage:                                                                                   #
#  execute_deployment_steps <step>                                                         #
############################################################################################

function execute_deployment_steps() {
	local step=$1
	return_value=0
	echo "Step:                                $step"

	if [ 1 -eq "${step}" ]; then
		if ! validate_keyvault_access; then
			return_value=$?
			print_banner "Key vault" "Validating key vault access failed" "error"
			return $return_value
		else
			step=2
			save_config_var "step" "${deployer_environment_file_name}"
		fi
	fi

	if [ 2 -eq "${step}" ]; then
		if ! bootstrap_library; then
			return_value=$?
			print_banner "Bootstrap Library" "Bootstrapping the SAP Library failed" "error"
			return $return_value
		else
			step=3
			save_config_var "step" "${deployer_environment_file_name}"
		fi
	fi

	if [ 3 -eq "${step}" ]; then
		if ! migrate_deployer_state; then
			return_value=$?
			print_banner "Deployer" "Migration of deployer state failed" "error"
			return $return_value
		else
			step=4
			save_config_var "step" "${deployer_environment_file_name}"
		fi
	fi
	if [ 4 -eq "${step}" ]; then
		if ! migrate_library_state; then
			return_value=$?
			step=4
			save_config_var "step" "${deployer_environment_file_name}"
			return 40
		else
			step=5
			save_config_var "step" "${deployer_environment_file_name}"
		fi
	fi
	if [ 5 -eq "${step}" ]; then
		if [ "${devops_flag}" != 	"--devops" ]; then
			if ! copy_files_to_public_deployer; then
				return_value=$?
				print_banner "Copy" "Copying files failed" "error"
				return $return_value
			else
				step=3
				save_config_var "step" "${deployer_environment_file_name}"
			fi
		fi
	else
		step=3
		save_config_var "step" "${deployer_environment_file_name}"
	fi
	return 0
}

#############################################################################################
# Function to deploy the control plane.                                                     #
# Arguments:                                                                                #
#   None                                                                                    #
# Returns:                                                                                  #
#   0 on success, non-zero on failure                                                       #
# Usage:                                                                                    #
#   deploy_control_plane                                                                    #
#############################################################################################
function deploy_control_plane() {
	force=0
	step=0
	devops_flag="none"
	autoApproveParameter=""
	return_value=0

	# Define an array of helper scripts
	helper_scripts=(
		"${script_directory}/helpers/script_helpers.sh"
		"${script_directory}/deploy_utils.sh"
	)

	# Call the function with the array
	source_helper_scripts "${helper_scripts[@]}"

	print_banner "Control Plane Deployment" "Entering $SCRIPT_NAME" "info"

	# Parse command line arguments
	if ! parse_arguments "$@"; then
		print_banner "$banner_title" "Validating parameters failed" "error"
		return $?
	fi

	echo "ADO flag:                            ${devops_flag}"
	ARM_SUBSCRIPTION_ID=${subscription}
	export ARM_SUBSCRIPTION_ID

	root_dirname=$(pwd)

	# Check that Terraform and Azure CLI is installed
	validate_dependencies
	return_code=$?
	if [ 0 != $return_code ]; then
		echo "validate_dependencies returned $return_code"
		return $return_code
	fi

	environment=$(echo "$CONTROL_PLANE_NAME" | cut -d"-" -f1)
	region_code=$(echo "$CONTROL_PLANE_NAME" | cut -d"-" -f2)
	network=$(echo "$CONTROL_PLANE_NAME" | cut -d"-" -f3)
	echo ""

	echo "Control Plane Name:                  $CONTROL_PLANE_NAME"
	echo "Environment:                         $environment"
	echo "Region code:                         ${region_code}"
	echo "Network code:                        ${network}"
	echo "Deployer State File:                 ${deployer_tfstate_key}"
	echo "Library State File:                  ${library_tfstate_key}"
	echo "Deployer Subscription:               ${subscription}"

	generic_environment_file_name="${CONFIG_DIR}"/config
	automation_config_directory="${CONFIG_DIR}"

	deployer_environment_file_name=$(get_configuration_file "$automation_config_directory" "$environment" "$region_code" "$network")

	if [ $force == 1 ]; then
		if [ -f "${deployer_environment_file_name}" ]; then
			rm "${deployer_environment_file_name}"
		fi
	fi

	init "${CONFIG_DIR}" "${generic_environment_file_name}" "${deployer_environment_file_name}"

	relative_path="${deployer_dirname}"
	TF_DATA_DIR="${relative_path}"/.terraform
	export TF_DATA_DIR

	load_config_vars "${deployer_environment_file_name}" "step"
	if [ -z "${step}" ]; then
		step=0
	fi
	echo "Step:                                $step"
	current_directory=$(pwd)

	print_banner "Control Plane Deployment" "Starting the control plane deployment..." "info"

	noAccess=$(az account show --query name | grep "N/A(tenant level account)" || true)

	if [ -n "$noAccess" ]; then
		print_banner "Control Plane Deployment" "The provided credentials do not have access to the subscription" "error"
		az account show --output table

		return 65
	fi
	az account list --query "[].{Name:name,Id:id}" --output table

	if ! printenv USE_MSI; then
		USE_MSI=true
	fi

	if [ "$USE_MSI" != "true" ]; then
		echo "Identity to use:                     Service Principal"
		TF_VAR_use_spn=true
		export TF_VAR_use_spn
		# if ! printenv ARM_USE_OIDC; then
		# 	set_executing_user_environment_variables "$ARM_CLIENT_SECRET"
		# fi
	else
		echo "Identity to use:                     Managed Identity"
		TF_VAR_use_spn=false
		export TF_VAR_use_spn
		# set_executing_user_environment_variables "none"
	fi

	if bootstrap_deployer; then
		return_value=0
		if [ 1 -eq $only_deployer ]; then
			printf -v key_vault_name '%-40s' "${DEPLOYER_KEYVAULT}"
			printf -v app_config_name '%-40s' "$APPLICATION_CONFIGURATION_NAME"
			printf -v ctrl_plane_name '%-40s' "$CONTROL_PLANE_NAME"

			echo ""
			echo "###############################################################################"
			echo "#                                                                             #"
			echo -e "# $cyan Please save these values: $reset_formatting                                                 #"
			echo "#     - Key Vault:          ${key_vault_name}           #"
			echo "#     - App Config:         ${app_config_name}          #"
			echo "#     - Control Plane Name: ${ctrl_plane_name}          #"
			echo "#                                                                             #"
			echo "###############################################################################"
			return 0
		fi
	else
		return_value=$?
		if [ 0 -ne "$return_value" ]; then
			print_banner "Bootstrap Deployer " "Bootstrapping the deployer failed!!" "error" "Return code: $return_value"
			return 10
		fi
	fi

	if [ 2 -le $step ]; then
		if ! retrieve_parameters; then
			print_banner "Retrieve Parameters" "Retrieving parameters failed" "warning"
		fi
	fi

	if ! execute_deployment_steps $step; then
		return_value=$?
		print_banner "Control Plane Deployment" "Executing deployment steps failed" "error"
	fi

	printf -v key_vault_name '%-40s' "${DEPLOYER_KEYVAULT}"
	printf -v storage_account '%-40s' "${terraform_storage_account_name}"
	printf -v app_config_name '%-40s' "$APPLICATION_CONFIGURATION_NAME"
	printf -v ctrl_plane_name '%-40s' "$CONTROL_PLANE_NAME"

	echo ""
	echo "###############################################################################"
	echo "#                                                                             #"
	echo -e "# $cyan Please save these values: $reset_formatting                                                 #"
	echo "#     - Key Vault:          ${key_vault_name}           #"
	echo "#     - Storage Account:    ${storage_account}          #"
	echo "#     - App Config:         ${app_config_name}          #"
	echo "#     - Control Plane Name: ${ctrl_plane_name}          #"
	echo "#                                                                             #"
	echo "###############################################################################"

	now=$(date)
	cat <<EOF >"${deployer_environment_file_name}".md
# Control Plane Deployment #

Date : "${now}"

## Configuration details ##

| Item                    | Name                 |
| ----------------------- | -------------------- |
| Environment             | $environment         |
| Location                | $region              |
| Keyvault Name           | ${DEPLOYER_KEYVAULT} |
| Terraform state         | ${storage_account}   |
| App Config              | $APPLICATION_CONFIGURATION_NAME}   |
| Control Plane Name      | $CONTROL_PLANE_NAME}   |

EOF

	deployer_keyvault="${DEPLOYER_KEYVAULT}"
	export deployer_keyvault

	terraform_state_storage_account="${terraform_storage_account_name}"
	export terraform_state_storage_account

	step=3
	save_config_var "step" "${deployer_environment_file_name}"
	if [ "$devops_flag" == "--devops" ]; then
		echo "##vso[task.setprogress value=100;]Progress Indicator"
	fi
	unset TF_DATA_DIR
	print_banner "Control Plane Deployment" "Exiting $SCRIPT_NAME" "info"

	return $return_value
}

################################################################################
# Main script execution                                                        #
# This script is designed to be run directly, not sourced.                     #
# It will execute the deploy_control_plane function and handle the exit codes. #
################################################################################
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
	# Only run if script is executed directly, not when sourced
	if deploy_control_plane "$@"; then
		exit 0
	else
		exit $?
	fi
fi
