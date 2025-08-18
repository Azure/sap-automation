#!/bin/bash
# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

#colors for terminal
bold_red="\e[1;31m"
green="\e[1;32m"
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
	input_opts=$(getopt -n remover_v2 -o p:t:o:d:l:s:n:c:w:ahif --longoptions type:,parameter_file:,storage_accountname:,deployer_tfstate_key:,landscape_tfstate_key:,state_subscription:,application_configuration_name:,control_plane_name:,workload_zone_name:,ado,auto-approve,force,help -- "$@")
	is_input_opts_valid=$?

	if [[ "${is_input_opts_valid}" != "0" ]]; then
		showhelp
		return 1
	fi

	eval set -- "$input_opts"
	while true; do
		case "$1" in
		-a | --ado)
			called_from_ado=1
			approve="--auto-approve"
			TF_IN_AUTOMATION=true
			export TF_IN_AUTOMATION
			shift
			;;
		-d | --deployer_tfstate_key)
			deployer_tfstate_key="$2"
			shift 2
			;;
		-c | --control_plane_name)
			CONTROL_PLANE_NAME="$2"
			shift 2
			;;
		-n | --application_configuration_name)
			APPLICATION_CONFIGURATION_NAME="$2"
			APPLICATION_CONFIGURATION_ID=$(az graph query -q "Resources | join kind=leftouter (ResourceContainers | where type=='microsoft.resources/subscriptions' | project subscription=name, subscriptionId) on subscriptionId | where name == '$APPLICATION_CONFIGURATION_NAME' | project id, name, subscription" --query data[0].id --output tsv)
			export APPLICATION_CONFIGURATION_ID
			export APPLICATION_CONFIGURATION_NAME
			TF_VAR_application_configuration_id=$APPLICATION_CONFIGURATION_ID
			export TF_VAR_application_configuration_id
			shift 2
			;;
		-l | --landscape_tfstate_key)
			landscape_tfstate_key="$2"
			shift 2
			;;
		-o | --storage_accountname)
			terraform_storage_account_name="$2"
			shift 2
			;;
		-p | --parameter_file)
			parameterFilename="$2"
			shift 2
			;;
		-s | --state_subscription)
			terraform_storage_account_subscription_id="$2"
			shift 2
			;;
		-t | --type)
			deployment_system="$2"
			shift 2
			;;
		-w | --workload_zone_name)
			WORKLOAD_ZONE_NAME="$2"
			shift 2
			;;
		-f | --force)
			force=1
			shift
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

	[[ -z "$CONTROL_PLANE_NAME" ]] && {
		print_banner "$banner_title - $deployment_system" "control_plane_name is required" "error"
		return 1
	}

	[[ -z "$deployment_system" ]] && {
		print_banner "$banner_title - $deployment_system" "type is required" "error"
		return 1
	}

	if [ -z $CONTROL_PLANE_NAME ] && [ -n "$deployer_tfstate_key" ]; then
		CONTROL_PLANE_NAME=$(echo $deployer_tfstate_key | cut -d'-' -f1-3)
	fi

	if [ -n "$CONTROL_PLANE_NAME" ]; then
		deployer_tfstate_key="${CONTROL_PLANE_NAME}-INFRASTRUCTURE.terraform.tfstate"
	fi

	if [ "${deployment_system}" == sap_system ] || [ "${deployment_system}" == sap_landscape ]; then
		WORKLOAD_ZONE_NAME=$(echo $parameter_file_name | cut -d'-' -f1-3)
		if [ -n "$WORKLOAD_ZONE_NAME" ]; then
			landscape_tfstate_key="${WORKLOAD_ZONE_NAME}-INFRASTRUCTURE.terraform.tfstate"
		else
			WORKLOAD_ZONE_NAME=$(echo $landscape_tfstate_key | cut -d'-' -f1-3)

			if [ -z $WORKLOAD_ZONE_NAME ] && [ -n "$landscape_tfstate_key" ]; then
				WORKLOAD_ZONE_NAME=$(echo $landscape_tfstate_key | cut -d'-' -f1-3)
			fi
		fi
	fi

	if [ "${deployment_system}" == sap_system ]; then
		if [ -z "${landscape_tfstate_key}" ]; then
			if [ 1 != $called_from_ado ]; then
				read -r -p "Workload terraform statefile name: " landscape_tfstate_key
				save_config_var "landscape_tfstate_key" "${system_config_information}"
			else
				print_banner "$banner_title - $deployment_system" "Workload terraform statefile name is required" "error"
				unset TF_DATA_DIR
				return 2
			fi
		else
			TF_VAR_landscape_tfstate_key="${landscape_tfstate_key}"
			export TF_VAR_landscape_tfstate_key
			landscape_tfstate_key_exists=true
		fi
	fi

	if [ "${deployment_system}" != sap_deployer ]; then
		TF_VAR_APPLICATION_CONFIGURATION_ID=$APPLICATION_CONFIGURATION_ID
		export TF_VAR_APPLICATION_CONFIGURATION_ID
		if [ -z "${deployer_tfstate_key}" ]; then
			if [ 1 != $called_from_ado ]; then
				read -r -p "Deployer terraform state file name: " deployer_tfstate_key
				save_config_var "deployer_tfstate_key" "${system_config_information}"
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

	if [ $deployment_system == sap_system ] || [ $deployment_system == sap_landscape ]; then
		system_config_information="${CONFIG_DIR}/${WORKLOAD_ZONE_NAME}"
		network_logical_name=$(echo $WORKLOAD_ZONE_NAME | cut -d'-' -f3)
	else
		system_config_information="${CONFIG_DIR}/${CONTROL_PLANE_NAME}"
		management_network_logical_name=$(echo $CONTROL_PLANE_NAME | cut -d'-' -f3)
	fi
	region=$(echo "${region}" | tr "[:upper:]" "[:lower:]")
	if valid_region_name "${region}"; then
		# Convert the region to the correct code
		get_region_code "${region}"
	else
		echo "Invalid region: $region"
		return 2
	fi
	if checkforEnvVar "TEST_ONLY"; then
		TEST_ONLY="${TEST_ONLY}"
	else
		TEST_ONLY="false"
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

	if [ -n "$APPLICATION_CONFIGURATION_ID" ]; then
		app_config_name=$(echo "$APPLICATION_CONFIGURATION_ID" | cut -d'/' -f9)
		app_config_subscription=$(echo "$APPLICATION_CONFIGURATION_ID" | cut -d'/' -f3)

		if is_valid_id "$APPLICATION_CONFIGURATION_ID" "/providers/Microsoft.AppConfiguration/configurationStores/"; then
			print_banner "Installer" "Retrieving parameters from Azure App Configuration" "info" "$app_config_name ($app_config_subscription)"

			tfstate_resource_id=$(getVariableFromApplicationConfiguration "$APPLICATION_CONFIGURATION_ID" "${CONTROL_PLANE_NAME}_TerraformRemoteStateStorageAccountId" "$CONTROL_PLANE_NAME")
			TF_VAR_tfstate_resource_id=$tfstate_resource_id

			TF_VAR_deployer_kv_user_arm_id=$(getVariableFromApplicationConfiguration "$APPLICATION_CONFIGURATION_ID" "${CONTROL_PLANE_NAME}_KeyVaultResourceId" "$CONTROL_PLANE_NAME")
			TF_VAR_spn_keyvault_id="${TF_VAR_deployer_kv_user_arm_id}"

			management_subscription_id=$(getVariableFromApplicationConfiguration "$APPLICATION_CONFIGURATION_ID" "${CONTROL_PLANE_NAME}_SubscriptionId" "${CONTROL_PLANE_NAME}")
			TF_VAR_management_subscription_id=${management_subscription_id}

			keyvault=$(getVariableFromApplicationConfiguration "$APPLICATION_CONFIGURATION_ID" "${CONTROL_PLANE_NAME}_KeyVaultName" "${CONTROL_PLANE_NAME}")

			terraform_storage_account_name=$(echo $tfstate_resource_id | cut -d'/' -f9)
			terraform_storage_account_resource_group_name=$(echo $tfstate_resource_id | cut -d'/' -f5)
			terraform_storage_account_subscription_id=$(echo $tfstate_resource_id | cut -d'/' -f3)

			export TF_VAR_management_subscription_id
			export TF_VAR_spn_keyvault_id
			export TF_VAR_tfstate_resource_id
			export keyvault
			export terraform_storage_account_name
			export terraform_storage_account_resource_group_name
			export terraform_storage_account_subscription_id
		fi
	fi

	if [ -z "$terraform_storage_account_name" ]; then
		if [ -f "${param_dirname}/.terraform/terraform.tfstate" ]; then
			remote_backend=$(grep "\"type\": \"azurerm\"" .terraform/terraform.tfstate || true)
			if [ -n "${remote_backend}" ]; then

				terraform_storage_account_subscription_id=$(grep -m1 "subscription_id" "${param_dirname}/.terraform/terraform.tfstate" | cut -d ':' -f2 | tr -d '", \r' | xargs || true)
				terraform_storage_account_name=$(grep -m1 "storage_account_name" "${param_dirname}/.terraform/terraform.tfstate" | cut -d ':' -f2 | tr -d ' ",\r' | xargs || true)
				terraform_storage_account_resource_group_name=$(grep -m1 "resource_group_name" "${param_dirname}/.terraform/terraform.tfstate" | cut -d ':' -f2 | tr -d ' ",\r' | xargs || true)
				tfstate_resource_id=$(az storage account show --name "${terraform_storage_account_name}" --query id --subscription "${terraform_storage_account_subscription_id}" --resource-group "${terraform_storage_account_resource_group_name}" --out tsv)
				export TF_VAR_tfstate_resource_id

			fi
		else
			load_config_vars "${system_config_information}" \
				tfstate_resource_id DEPLOYER_KEYVAULT

			TF_VAR_spn_keyvault_id=$(az keyvault show --name "${DEPLOYER_KEYVAULT}" --query id --subscription "${ARM_SUBSCRIPTION_ID}" --out tsv)
			export TF_VAR_spn_keyvault_id

			export TF_VAR_tfstate_resource_id
			terraform_storage_account_name=$(echo $tfstate_resource_id | cut -d'/' -f9)
			terraform_storage_account_resource_group_name=$(echo $tfstate_resource_id | cut -d'/' -f5)
			terraform_storage_account_subscription_id=$(echo $tfstate_resource_id | cut -d'/' -f3)

			export terraform_storage_account_resource_group_name
			export terraform_storage_account_name
			export terraform_storage_account_subscription_id

		fi
	else
		if [ -z "$tfstate_resource_id" ]; then
			tfstate_resource_id=$(az storage account show --name "${terraform_storage_account_name}" --query id --out tsv)
			export tfstate_resource_id
			TF_VAR_tfstate_resource_id=$tfstate_resource_id
			export TF_VAR_tfstate_resource_id

			terraform_storage_account_name=$(echo $tfstate_resource_id | cut -d'/' -f9)
			terraform_storage_account_resource_group_name=$(echo $tfstate_resource_id | cut -d'/' -f5)
			terraform_storage_account_subscription_id=$(echo $tfstate_resource_id | cut -d'/' -f3)

			export terraform_storage_account_resource_group_name
			export terraform_storage_account_name
			export terraform_storage_account_subscription_id
		fi

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
	landscape_tfstate_key=""
	called_from_ado=0
	extra_vars=""
	WORKLOAD_ZONE_NAME=""

	# Define an array of helper scripts
	helper_scripts=(
		"${script_directory}/helpers/script_helpers.sh"
		"${script_directory}/deploy_utils.sh"
	)

	# Call the function with the array
	source_helper_scripts "${helper_scripts[@]}"

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

	parallelism=5

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

	echo "Configuration file:                  $system_config_information"
	echo "Deployment region:                   $region"
	echo "Deployment region code:              $region_code"
	echo "Target subscription:                 $ARM_SUBSCRIPTION_ID"

	if [ "${DEBUG:-false}" = true ]; then
		print_banner "$banner_title - $deployment_system" "Enabling debug mode" "info"
		set -x
		set -o errexit
	fi

	if [ 1 == $called_from_ado ]; then
		this_ip=$(curl -s ipinfo.io/ip) >/dev/null 2>&1
		export TF_VAR_Agent_IP=$this_ip
		echo "Agent IP:                            $this_ip"
	fi

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
	export TF_DATA_DIR="${param_dirname}/.terraform"

	TF_VAR_subscription_id="$ARM_SUBSCRIPTION_ID"
	export TF_VAR_subscription_id

	#§init "${CONFIG_DIR}" "${generic_config_information}" "${system_config_information}"

	var_file="${param_dirname}"/"${parameterFilename}"

	if [ -f terraform.tfvars ]; then
		extra_vars="-var-file=${param_dirname}/terraform.tfvars"
	else
		extra_vars=""
	fi

	current_subscription_id=$(az account show --query id -o tsv)

	if [[ -n "$terraform_storage_account_subscription_id" ]] && [[ "$terraform_storage_account_subscription_id" != "$current_subscription_id" ]]; then
		print_banner "$banner_title - $deployment_system" "Changing the subscription to: $terraform_storage_account_subscription_id" "info"
		az account set --sub "${terraform_storage_account_subscription_id}"

		return_code=$?
		if [ 0 != $return_code ]; then
			print_banner "$banner_title - $deployment_system" "The deployment account (MSI or SPN) does not have access to: $terraform_storage_account_subscription_id" "error"
			exit $return_code
		fi

		az account set --sub "${current_subscription_id}"

	fi

	if [ "${deployment_system}" != sap_deployer ]; then
		echo "Deployer Keyvault ID:                $TF_VAR_spn_keyvault_id"

	fi

	useSAS=$(az storage account show --name "${terraform_storage_account_name}" --query allowSharedKeyAccess --subscription "${terraform_storage_account_subscription_id}" --out tsv)

	if [ "$useSAS" = "true" ]; then
		echo "Storage Account Authentication:      Key"
		export ARM_USE_AZUREAD=false
	else
		echo "Storage Account Authentication:      Entra ID"
		export ARM_USE_AZUREAD=true
	fi

	#setting the user environment variables
	set_executing_user_environment_variables "none"

	terraform_module_directory="$SAP_AUTOMATION_REPO_PATH/deploy/terraform/run/${deployment_system}"
	cd "${param_dirname}" || exit

	if [ ! -d "${terraform_module_directory}" ]; then

		printf -v val %-40.40s "$deployment_system"
		print_banner "$banner_title - $deployment_system" "Incorrect system deployment type specified: ${val}$" "error"
		exit 1
	fi

	terraform --version
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

	cd "${param_dirname}" || exit
	if [ ! -f .terraform/terraform.tfstate ]; then

		terraform_module_directory="${SAP_AUTOMATION_REPO_PATH}/deploy/terraform/run/${deployment_system}"/

		if terraform -chdir="${terraform_module_directory}" init -force-copy \
			--backend-config "subscription_id=${terraform_storage_account_subscription_id}" \
			--backend-config "resource_group_name=${terraform_storage_account_resource_group_name}" \
			--backend-config "storage_account_name=${terraform_storage_account_name}" \
			--backend-config "container_name=tfstate" \
			--backend-config "key=${key}.terraform.tfstate"; then
			return_value=$?
			print_banner "$banner_title - $deployment_system" "Terraform init succeeded." "success"

		else
			return_value=$?
			print_banner "$banner_title - $deployment_system" "Terraform init failed" "error"
			return $return_value
		fi
	else
		echo "Terraform state:                     remote"
		print_banner "$banner_title - $deployment_system" "The system has already been deployed and the state file is in Azure" "info"

		if ! terraform -chdir="${terraform_module_directory}" init -force-copy -upgrade=true \
			--backend-config "subscription_id=${terraform_storage_account_subscription_id}" \
			--backend-config "resource_group_name=${terraform_storage_account_resource_group_name}" \
			--backend-config "storage_account_name=${terraform_storage_account_name}" \
			--backend-config "container_name=tfstate" \
			--backend-config "key=${key}.terraform.tfstate"; then
			return_value=$?
			print_banner "$banner_title - $deployment_system" "Terraform init failed." "error"
			return $return_value
		else
			return_value=$?
			print_banner "$banner_title - $deployment_system" "Terraform init succeeded." "success"
		fi
	fi

	print_banner "$banner_title - $deployment_system" "Running Terraform destroy" "info"

	if [ "$deployment_system" == "sap_deployer" ]; then
		terraform -chdir="${terraform_module_directory}" destroy -var-file="${var_file}"

	elif [ "$deployment_system" == "sap_library" ]; then
		terraform_bootstrap_directory="${SAP_AUTOMATION_REPO_PATH}/deploy/terraform/bootstrap/${deployment_system}/"
		terraform -chdir="${terraform_bootstrap_directory}" init -upgrade=true -force-copy

		terraform -chdir="${terraform_bootstrap_directory}" refresh -var-file="${var_file}"

		terraform -chdir="${terraform_bootstrap_directory}" destroy -var-file="${var_file}" "${approve}" -var use_deployer=false
	elif [ "$deployment_system" == "sap_landscape" ]; then

		allParameters=$(printf " -var-file=%s %s " "${var_file}" "${extra_vars}")

		if [ -n "${approve}" ]; then
			# shellcheck disable=SC2086
			if terraform -chdir="${terraform_module_directory}" destroy $allParameters "$approve" -no-color -json -parallelism="$parallelism" | tee -a destroy_output.json; then
				return_value=$?
				print_banner "$banner_title - $deployment_system" "Terraform destroy succeeded" "success"
			else
				return_value=$?
				print_banner "$banner_title - $deployment_system" "Terraform destroy failed" "error"
			fi
			if [ -f destroy_output.json ]; then
				errors_occurred=$(jq 'select(."@level" == "error") | length' destroy_output.json)
				if [[ -n $errors_occurred ]]; then
					return_value=10
				fi
			fi

		else
			# shellcheck disable=SC2086
			if terraform -chdir="${terraform_module_directory}" destroy $allParameters -parallelism="$parallelism"; then
				print_banner "$banner_title - $deployment_system" "Terraform destroy succeeded" "success"
				return_value=$?
			else
				return_value=$?
				print_banner "$banner_title - $deployment_system" "Terraform destroy failed" "error"
			fi
		fi
	else

		allParameters=$(printf " -var-file=%s %s" "${var_file}" "${extra_vars}")
		fileName="destroy_output.json"

		if [ -n "${approve}" ]; then
			# shellcheck disable=SC2086
			if terraform -chdir="${terraform_module_directory}" destroy $allParameters "$approve" -no-color -json -parallelism="$parallelism" | tee "$fileName"; then
				return_value=${PIPESTATUS[0]}
				print_banner "$banner_title - $deployment_system" "Terraform destroy succeeded" "success"
			else
				return_value=${PIPESTATUS[0]}
				print_banner "$banner_title - $deployment_system" "Terraform destroy failed" "error"
			fi
		else
			# shellcheck disable=SC2086
			if terraform -chdir="${terraform_module_directory}" destroy $allParameters -parallelism="$parallelism"; then
				return_value=$?
				print_banner "$banner_title - $deployment_system" "Terraform destroy succeeded" "success"
			else
				return_value=$?
				print_banner "$banner_title - $deployment_system" "Terraform destroy failed" "error"
			fi
		fi

		if [ -f "$fileName" ]; then
			errors_occurred=$(jq 'select(."@level" == "error") | length' "$fileName")

			if [[ -n $errors_occurred ]]; then

				retry_errors_temp=$(jq 'select(."@level" == "error") | {summary: .diagnostic.summary} | select(.summary | contains("You can only retry the Delete operation"))' "$fileName")
				if [[ -n "${retry_errors_temp}" ]]; then
					rm "$fileName"
					sleep 30
					# shellcheck disable=SC2086
					if terraform -chdir="${terraform_module_directory}" destroy $allParameters "$approve" -no-color -json -parallelism="$parallelism" | tee "$fileName"; then
						return_value=${PIPESTATUS[0]}
						print_banner "$banner_title - $deployment_system" "Terraform destroy succeeded" "success"
					else
						return_value=${PIPESTATUS[0]}
						print_banner "$banner_title - $deployment_system" "Terraform destroy failed" "error"
					fi
					errors_occurred=$(jq 'select(."@level" == "error") | length' "$fileName")
				fi
			fi

			if [[ -n $errors_occurred ]]; then

				print_banner "$banner_title - $deployment_system" "Errors during the destroy phase" "success"
				echo ""
				echo "#########################################################################################"
				echo "#                                                                                       #"
				echo -e "#                      $bold_red_underscore!!! Errors during the destroy phase !!!$reset_formatting                          #"
				echo "#                                                                                       #"
				echo "#########################################################################################"
				echo ""

				return_value=2
				all_errors=$(jq 'select(."@level" == "error") | {summary: .diagnostic.summary, detail: .diagnostic.detail}' destroy_output.json)
				if [[ -n ${all_errors} ]]; then
					readarray -t errors_strings < <(echo ${all_errors} | jq -c '.')
					for errors_string in "${errors_strings[@]}"; do
						string_to_report=$(jq -c -r '.detail ' <<<"$errors_string")
						if [[ -z ${string_to_report} ]]; then
							string_to_report=$(jq -c -r '.summary ' <<<"$errors_string")
						fi

						report=$(echo $string_to_report | grep -m1 "Message=" "${var_file}" | cut -d'=' -f2- | tr -d ' ' | tr -d '"')
						if [[ -n ${report} ]]; then
							echo -e "#                          $bold_red_underscore  $report $reset_formatting"
							echo "##vso[task.logissue type=error]${report}"
						else
							echo -e "#                          $bold_red_underscore  $string_to_report $reset_formatting"
							echo "##vso[task.logissue type=error]${string_to_report}"
						fi

					done

				fi

			fi

		fi

		if [ -f destroy_output.json ]; then
			rm destroy_output.json
		fi

	fi

	if [ -f "${system_config_information}" ]; then
		if [ "${deployment_system}" == sap_deployer ]; then
			sed -i /deployer_tfstate_key/d "${system_config_information}"
		fi

		if [ "${deployment_system}" == sap_landscape ]; then
			rm "${system_config_information}"

		fi

		if [ "${deployment_system}" == sap_library ]; then
			sed -i /REMOTE_STATE_RG/d "${system_config_information}"
			sed -i /REMOTE_STATE_SA/d "${system_config_information}"
			sed -i /tfstate_resource_id/d "${system_config_information}"
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
