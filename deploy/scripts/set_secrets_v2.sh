#!/bin/bash
# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

#error codes include those from /usr/include/sysexits.h

#External helper functions
#. "$(dirname "${BASH_SOURCE[0]}")/deploy_utils.sh"
full_script_path="$(realpath "${BASH_SOURCE[0]}")"
script_directory="$(dirname "${full_script_path}")"
SCRIPT_NAME="$(basename "$0")"

if printenv DEBUG; then
	if [ $DEBUG = True ]; then
		set -x
		DEBUG=True
		echo "prefix variables:"
		printenv | sort
	fi
fi
export DEBUG
set -eu

deploy_using_msi_only=0
keyvault=""

###############################################################################
# Function to set a secret in Azure Key Vault                                 #
# Arguments:                                                                  #
#   1. Key Vault name                                                         #
#   2. Subscription ID                                                        #
#   3. Secret name                                                            #
#   4. Secret value                                                           #
#   5. Secret type                                                            #
# Returns:             																			                  #
#   0 on success, non-zero on failure                                         #
# Usage:                                                                      #
#   setSecretValue <keyvault> <subscription> <secret_name> <value> <type>     #
###############################################################################
function setSecretValue {
	local keyvault=$1
	local subscription=$2
	local secret_name=$3
	local value=$4
	local type=$5
	local local_return_code=0
	current_value=$(az keyvault secret show --name "${secret_name}" --vault-name "${keyvault}" --subscription "${subscription}" --query value --output tsv)
	if [ "${value}" != "${current_value}" ]; then
		if az keyvault secret set --name "${secret_name}" --vault-name "${keyvault}" --subscription "${subscription}" --value "${value}" --expires "$(date -d '+1 year' -u +%Y-%m-%dT%H:%M:%SZ)" --output none --content-type "${type}"; then
			local_return_code=$?
		else
			local_return_code=$?
			if [ 1 = "${local_return_code}" ]; then
				az keyvault secret recover --name "${secret_name}" --vault-name "${keyvault}" --subscription "${subscription}"
				sleep 10
				az keyvault secret set --name "${secret_name}" --vault-name "${keyvault}" --subscription "${subscription}" --value "${value}" --expires "$(date -d '+1 year' -u +%Y-%m-%dT%H:%M:%SZ)" --output none --content-type "${type}"
				local_return_code=$?
			else
				echo "Failed to set secret ${secret_name} in keyvault ${keyvault}"
			fi
		fi
	fi
	return $local_return_code

}

###############################################################################
# Function to show the help                                                   #
# Returns:                                                                    #
#   0 on success, non-zero on failure                                         #
# Usage:                                                                      #
#   show_help                                                                 #
###############################################################################
function show_help {
	echo ""
	echo "#########################################################################################"
	echo "#                                                                                       #"
	echo "#                                                                                       #"
	echo "#   This file contains the logic to add the SPN secrets to the keyvault.                #"
	echo "#                                                                                       #"
	echo "#                                                                                       #"
	echo "#   Usage: set_secrets_v2.sh                                                            #"
	echo "#      -p or --prefix                          prefix                                   #"
	echo "#      -v or --key_vault                       Azure keyvault name                      #"
	echo "#      -s or --subscription                    subscription                             #"
	echo "#      -n or --application_configuration_name  Application configuration name           #"
	echo "#      -c or --spn_id                          SPN application id                       #"
	echo "#      -p or --spn_secret                      SPN password                             #"
	echo "#      -t or --tenant_id                       SPN Tenant id                            #"
	echo "#      -h or --help                            Show help                                #"
	echo "#                                                                                       #"
	echo "#   Example:                                                                            #"
	echo "#                                                                                       #"
	echo "#   [REPO-ROOT]deploy/scripts/set_secret_v2.sh \                                        #"
	echo "#      --prefix PROD-WEEU-SAP02  \                                                      #"
	echo "#      --vault prodweeuusrabc  \                                                        #"
	echo "#      --subscription xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx \                            #"
	echo "#      --spn_id yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy \                                  #"
	echo "#      --spn_secret ************************ \                                          #"
	echo "#      --tenant_id zzzzzzzz-zzzz-zzzz-zzzz-zzzzzzzzzzzz \                               #"
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
	input_opts=$(getopt -n set_secrets_v2 -o v:s:i:p:t:b:n:c:hwma --longoptions control_plane_name:,prefix:,key_vault:,subscription:,client_id:,client_secret:,client_tenant_id:,application_configuration_name:,keyvault_subscription:,workload,help,msi,ado -- "$@")
	is_input_opts_valid=$?

	if [[ "${is_input_opts_valid}" != "0" ]]; then
		show_help
		exit 1
	fi

	eval set -- "$input_opts"
	while true; do
		case "$1" in
		-p | --prefix)
			prefix="$2"
			shift 2
			;;
		-v | --key_vault)
			keyvault="$2"
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
			shift 2
			;;
		-b | --subscription)
			subscription="$2"
			shift 2
			;;
		-i | --client_id)
			client_id="$2"
			shift 2
			;;
		-s | --client_secret)
			client_secret="$2"
			shift 2
			;;
		-t | --client_tenant_id)
			tenant_id="$2"
			shift 2
			;;
		-k | --keyvault_subscription)
			STATE_SUBSCRIPTION="$2"
			shift 2
			;;
		-w | --workload)
			workload=1
			shift
			;;
		-m | --msi)
			deploy_using_msi_only=1
			shift
			;;
		-a | --ado)
			shift
			;;
		-h | --help)
			show_help
			exit 3

			;;
		--)
			shift
			break
			;;
		esac
	done

	banner_title="Set Secrets"

	[[ -z "$prefix" ]] && {
		print_banner "$banner_title" "prefix is required" "error"
		return 10
	}

	[[ -z "$subscription" ]] && {
		print_banner "$banner_title" "subscription is required" "error"
		return 10
	}

	if [ 0 -eq "$deploy_using_msi_only" ]; then

		if [ -z "$client_id" ]; then
			print_banner "$banner_title" "client_id is required" "error"
			return 10
		else
			if ! is_valid_guid "${client_id}"; then
				print_banner "$banner_title" "client_id is required" "error"
				return 10
			fi
		fi

		[[ -z "$client_secret" ]] && {
			print_banner "$banner_title" "client_secret is required" "error"
			return 10
		}

		if [ -z "$tenant_id" ]; then
			print_banner "$banner_title" "correct tenant_id is required" "error"
			return 10
		else
			if ! is_valid_guid "${tenant_id}"; then
				print_banner "$banner_title" "correct tenant_id is required" "error"
				return 10
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
	if checkforEnvVar APPLICATION_CONFIGURATION_ID; then
		if [ -n "$APPLICATION_CONFIGURATION_ID" ]; then
			app_config_name=$(echo "$APPLICATION_CONFIGURATION_ID" | cut -d'/' -f9)
			app_config_subscription=$(echo "$APPLICATION_CONFIGURATION_ID" | cut -d'/' -f3)

			if is_valid_id "$APPLICATION_CONFIGURATION_ID" "/providers/Microsoft.AppConfiguration/configurationStores/"; then

				print_banner "$banner_title" "Retrieving parameters from Azure App Configuration" "info" "$app_config_name ($app_config_subscription)"

				keyvault=$(getVariableFromApplicationConfiguration "$APPLICATION_CONFIGURATION_ID" "${CONTROL_PLANE_NAME}_KeyVaultName" "${CONTROL_PLANE_NAME}")
				print_banner "$banner_title" "Key vault: $keyvault" "info" "${CONTROL_PLANE_NAME}_KeyVaultName ${prefix}"

				keyvault_id=$(getVariableFromApplicationConfiguration "$APPLICATION_CONFIGURATION_ID" "${CONTROL_PLANE_NAME}_KeyVaultResourceId" "$CONTROL_PLANE_NAME")
				STATE_SUBSCRIPTION=$(echo "$keyvault_id" | cut -d'/' -f3)

				export keyvault
			fi
		fi
		[[ -z "$keyvault" ]] && {
			print_banner "$banner_title" "key_vault is required" "error"
			return 10
		}
	fi

	return 0

}

function set_all_secrets() {
	deploy_using_msi_only=0

	# Define an array of helper scripts
	helper_scripts=(
		"${script_directory}/helpers/script_helpers.sh"
		"${script_directory}/deploy_utils.sh"
	)

	banner_title="Set Secrets"

	# Call the function with the array
	source_helper_scripts "${helper_scripts[@]}"

	print_banner "$banner_title" "Starting script $SCRIPT_NAME" "info"

	# Parse command line arguments
	if parse_arguments "$@"; then
		return_code=0
	else
		print_banner "$banner_title " "Validating parameters failed" "error"
		return $?
	fi

	retrieve_parameters
	return_code=0

	print_banner "$banner_title " "Setting the secrets" "info"
	echo ""

	echo "Key vault:                           ${keyvault}"
	echo "Subscription:                        ${STATE_SUBSCRIPTION}"

	secret_name="${prefix}"-subscription-id

	# az keyvault secret show --name "${secret_name}" --vault-name "${keyvault}" --subscription "${STATE_SUBSCRIPTION}" >stdout.az 2>&1
	# result=$(grep "ERROR: The user, group or application" stdout.az)

	# if [ -n "${result}" ]; then
	#     upn=$(az account show | grep name | grep @ | cut -d: -f2 | cut -d, -f1 -o tsv | xargs)
	#     az keyvault set-policy -n "${keyvault}" --secret-permissions get list recover restore set --upn "${upn}"
	# fi
	if setSecretValue "${keyvault}" "${STATE_SUBSCRIPTION}" "${secret_name}" "${subscription}" "configuration"; then
		print_banner "$banner_title" "Secret ${secret_name} set in keyvault ${keyvault}" "success"
	else
		print_banner "$banner_title" "Failed to set secret ${secret_name} in keyvault ${keyvault}" "error"
		return 20
	fi

	if [ 0 = "${deploy_using_msi_only:-}" ]; then

		#turn off output, we do not want to show the details being uploaded to keyvault
		secret_name="${prefix}"-client-id
		if setSecretValue "${keyvault}" "${STATE_SUBSCRIPTION}" "${secret_name}" "${client_id}" "configuration"; then
			print_banner "$banner_title" "Secret ${secret_name} set in keyvault ${keyvault}" "success"
		else
			print_banner "$banner_title" "Failed to set secret ${secret_name} in keyvault ${keyvault}" "error"
			return 20
		fi

		secret_name="${prefix}"-tenant-id
		if setSecretValue "${keyvault}" "${STATE_SUBSCRIPTION}" "${secret_name}" "${tenant_id}" "configuration"; then
			print_banner "$banner_title" "Secret ${secret_name} set in keyvault ${keyvault}" "success"
		else
			print_banner "$banner_title" "Failed to set secret ${secret_name} in keyvault ${keyvault}" "error"
			return 20
		fi

		secret_name="${prefix}"-client-secret
		if setSecretValue "${keyvault}" "${STATE_SUBSCRIPTION}" "${secret_name}" "${client_secret}" "secret"; then
			print_banner "$banner_title" "Secret ${secret_name} set in keyvault ${keyvault}" "success"
		else
			print_banner "$banner_title" "Failed to set secret ${secret_name} in keyvault ${keyvault}" "error"
			return 20
		fi
	fi
	return $return_code
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
	# Only run if script is executed directly, not when sourced
	set_all_secrets "$@"
	exit $?
fi
