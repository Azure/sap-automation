#!/bin/bash
# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

#-------------------------------------------------------------------------------#
#                                                                               #
# Initialize colors and debug handling                                          #
#                                                                               #
#-------------------------------------------------------------------------------#
# 'set' command documentation:
#		https://www.gnu.org/software/bash/manual/html_node/The-Set-Builtin.html
#
# error codes include those from /usr/include/sysexits.h
#---------------------------------------+---------------------------------------#
# region
# colors for terminal
bold_red_underscore="\e[1;4;31m"                                                #    CRIT_COLOR
           bold_red="\e[1;31m"                                                  #   ERROR_COLOR
              green="\e[1;32m"                                                  # SUCCESS_COLOR
             yellow="\e[1;33m"                                                  # WARNING_COLOR
               blue="\e[1;34m"                                                  #   DEBUG_COLOR
            magenta="\e[1;35m"                                                  #   TRACE_COLOR
               cyan="\e[1;36m"                                                  #    INFO_COLOR
              reset="\e[0m"                                                     #   RESET_COLOR

echo -e "\n${cyan}Entering script:  ${BASH_SOURCE[0]}${reset}\n"
export PS4='+$(basename "${BASH_SOURCE[0]}"):${LINENO}: '                       # Debug prompt format

# SYSTEM_DEBUG is set by Azure DevOps when the "Enable system diagnostics" option is turned on for the pipeline run.
# DEBUG is an optional environment variable that can be set to "True" to enable debug mode when running the script outside of Azure DevOps.
if  [[ ${SYSTEM_DEBUG:-False} = True ]] || \
    [[ ${DEBUG:-False}        = True ]]; then
      echo -e "${cyan}--- Enabling debug mode ---${reset}"
      set -x                                                                    # Enable debug mode
      export DEBUG=True
      echo "Environment variables:"
      printenv | sort
else
      export DEBUG=False
fi

set -o errexit                                                                  # Same as -e; Exit immediately if a command exits with a non-zero status.
set -o nounset                                                                  # Same as -u; Treat unset variables as an error when substituting.
set -o pipefail																																	# Exit with the exit status of the last command in the pipeline that returned a non-zero return value.
#-------------------------------------------------------------------------------#
# endregion


#-------------------------------------------------------------------------------#
#                                                                               #
# Helpers                                                                       #
#                                                                               #
#-------------------------------------------------------------------------------#
# Example: path_to_script/grand_parent_dir/parent_dir/script_dir/script
#---------------------------------------+---------------------------------------#
# region
full_script_path="$(      realpath ${BASH_SOURCE[0]})"                          # Get the full path of the current script
script_directory="$(      dirname  ${full_script_path})"                        # Get the directory of the current script
parent_directory="$(      dirname  ${script_directory})"                        # Get the parent directory of the script directory
grand_parent_directory="$(dirname  ${parent_directory})"                        # Get the grandparent directory of the script directory

SCRIPT_NAME="$(basename "$0")"

# External helper functions
# call stack has full script name when using source
source "${script_directory}/deploy_utils.sh"
source "${script_directory}/helpers/script_helpers.sh"
#-------------------------------------------------------------------------------#
# endregion


if [ -v ARM_SUBSCRIPTION_ID ]; then
	subscription="$ARM_SUBSCRIPTION_ID"
fi


function setSecretValue {
	local keyvault=$1
	local subscription=$2
	local secret_name=$3
	local value=$4
	local type=$5
	if az keyvault secret set --name "${secret_name}" --vault-name "${keyvault}" --subscription "${subscription}" --value "${value}" --expires "$(date -d '+1 year' -u +%Y-%m-%dT%H:%M:%SZ)" --output none --content-type "${type}" ; then
		return_value=$?
	else
		return_value=$?
		if [ 1 = "${return_value}" ]; then
			az keyvault secret recover --name "${secret_name}" --vault-name "${keyvault}" --subscription "${subscription}"
			sleep 10
			az keyvault secret set --name "${secret_name}" --vault-name "${keyvault}" --subscription "${subscription}" --value "${value}" --expires "$(date -d '+1 year' -u +%Y-%m-%dT%H:%M:%SZ)"  --output none --content-type "${type}"
			return_value=$?
		else
			echo "Failed to set secret ${secret_name} in keyvault ${keyvault}"
		fi
	fi
	return $return_value

}

function showhelp {
	echo ""
	echo "#########################################################################################"
	echo "#                                                                                       #"
	echo "#                                                                                       #"
	echo "#   This file contains the logic to add the SPN secrets to the keyvault.                #"
	echo "#                                                                                       #"
	echo "#                                                                                       #"
	echo "#   Usage: set_secret.sh                                                                #"
	echo "#      -e or --environment                   environment name                           #"
	echo "#      -r or --region                        region name                                #"
	echo "#      -n or --network_code                  network code                                #"
	echo "#      -v or --vault                         Azure keyvault name                        #"
	echo "#      -s or --subscription                  subscription                               #"
	echo "#      -c or --spn_id                        SPN application id                         #"
	echo "#      -p or --spn_secret                    SPN password                               #"
	echo "#      -t or --tenant_id                     SPN Tenant id                              #"
	echo "#      -h or --help                          Show help                                  #"
	echo "#                                                                                       #"
	echo "#   Example:                                                                            #"
	echo "#                                                                                       #"
	echo "#   [REPO-ROOT]deploy/scripts/set_secret.sh \                                           #"
	echo "#      --environment PROD  \                                                            #"
	echo "#      --region weeu  \                                                                 #"
	echo "#      --network_code SAP01  \                                                          #"
	echo "#      --vault prodweeuusrabc  \                                                        #"
	echo "#      --subscription xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx \                            #"
	echo "#      --msi                                                                            #"
	echo "#                                                                                       #"
	echo "#                                                                                       #"
	echo "#   [REPO-ROOT]deploy/scripts/set_secret.sh \                                           #"
	echo "#      --environment PROD  \                                                            #"
	echo "#      --region weeu  \                                                                 #"
	echo "#      --network_code SAP01  \                                                          #"
	echo "#      --vault prodweeuusrabc  \                                                        #"
	echo "#      --subscription xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx \                            #"
	echo "#      --spn_id yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy \                                  #"
	echo "#      --spn_secret ************************ \                                          #"
	echo "#      --tenant_id zzzzzzzz-zzzz-zzzz-zzzz-zzzzzzzzzzzz                                 #"
	echo "#                                                                                       #"
	echo "#########################################################################################"
}

deploy_using_msi_only=0
network_code=""

INPUT_ARGUMENTS=$(getopt -n set_secrets -o e:r:v:s:c:p:t:b:n:hwma --longoptions environment:,region:,vault:,subscription:,spn_id:,spn_secret:,tenant_id:,keyvault_subscription:,network_code:,workload,help,msi,ado -- "$@")
VALID_ARGUMENTS=$?

if [ "$VALID_ARGUMENTS" != "0" ]; then
	showhelp
fi

eval set -- "$INPUT_ARGUMENTS"
while :; do
	case "$1" in
	-e | --environment)
		environment="$2"
		shift 2
		;;
	-r | --region)
		region_code="$2"
		shift 2
		;;
	-n | --network_code)
		network_code="$2"
		shift 2
		;;
	-v | --vault)
		keyvault="$2"
		shift 2
		;;
	-s | --subscription)
		subscription="$2"
		shift 2
		;;
	-c | --spn_id)
		client_id="$2"
		shift 2
		;;
	-p | --spn_secret)
		client_secret="$2"
		shift 2
		;;
	-t | --tenant_id)
		tenant_id="$2"
		shift 2
		;;
	-b | --keyvault_subscription)
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
	-h | --help)
		showhelp
		exit 3

		;;
	--)
		shift
		break
		;;
	esac
done

while [ -z "${environment}" ]; do
	read -r -p "Environment name: " environment
done

while [ -z "${region_code}" ]; do
	read -r -p "Region name: " region
done

if [ -z "${region_code}" ]; then
	# Convert the region to the correct code
	get_region_code "$region"
fi


automation_config_directory="$CONFIG_REPO_PATH/.sap_deployment_automation"
environment_config_information="${automation_config_directory}/${environment}${region_code}${network_code}"
ZONE_NAME="${environment}-${region_code}-${network_code}"

return_code=0

if [ -f secret.err ]; then
	rm secret.err
fi

if [ ! -d "${automation_config_directory}" ]; then
	# No configuration directory exists
	mkdir "${automation_config_directory}"
else
	touch "${environment_config_information}"
fi

if [ -z "$subscription" ]; then
	load_config_vars "${environment_config_information}" "subscription"
fi

if [ "${workload:-0}" != 1 ]; then
	load_config_vars "${environment_config_information}" "STATE_SUBSCRIPTION"
	if [ "$STATE_SUBSCRIPTION" ]; then
		subscription=${STATE_SUBSCRIPTION}
	fi
fi

if [ -z "$keyvault" ]; then
	load_config_vars "${environment_config_information}" "keyvault"
	if [ -z "$keyvault" ]; then
		read -r -p "Keyvault name: " keyvault
	fi
	if valid_kv_name "$keyvault"; then
		echo "Valid keyvault name format specified"
		DEPLOYER_KEYVAULT="$keyvault"
		export DEPLOYER_KEYVAULT
		save_config_vars "${environment_config_information}" "keyvault" "DEPLOYER_KEYVAULT"
	else
		printf -v val %-40.40s "$keyvault"
		print_banner "Set secrets" "The provided keyvault is not valid: ${val}" "error"
		return_code=65
		exit $return_code
	fi
fi
if [ -z "${keyvault}" ]; then
	print_banner "Set secrets" "Missing keyvault" "error" "No keyvault specified"
	showhelp
	return_code=65 #/* data format error */
	exit $return_code
fi

if [ $deploy_using_msi_only = 0 ]; then

	if [ -z "${client_id:-$ARM_CLIENT_ID}" ]; then
		load_config_vars "${environment_config_information}" "client_id"
		if [ -z "$client_id" ]; then
			read -r -p "SPN App ID: " client_id
		fi
	else
		if is_valid_guid "${client_id}"; then
			echo ""
		else
			printf -v val %-40.40s "$client_id"
			print_banner "Set secrets" "The provided client_id is not valid: ${val}" "error"
			return_code=65
			exit $return_code
		fi
	fi

	if [ -z "${tenant_id:-$ARM_TENANT_ID}" ]; then
		load_config_vars "${environment_config_information}" "tenant_id"
		if [ -z "${tenant_id}" ]; then
			read -r -p "SPN Tenant ID: " tenant_id
		fi
	else
		if is_valid_guid "${tenant_id}"; then
			echo ""
		else
			printf -v val %-40.40s "$tenant_id"
			print_banner "Set secrets" "The provided tenant_id is not valid: ${val}" "error"
			return_code=65
			exit $return_code
		fi
	fi
fi


if [ 0 = "${deploy_using_msi_only:-}" ]; then

	if [ -z "$client_secret" ]; then
		#do not output the secret to screen
		read -rs -p "        -> Kindly provide SPN Password: " client_secret
		echo "********"
	fi


	if [ -z "$client_secret" ]; then
		print_banner "Set secrets" "Missing client_secret" "error" "No client_secret specified"
		showhelp
		return_code=65 #/* data format error */
		exit $return_code
	fi

fi
if [ -z "${subscription}" ]; then
	read -r -p "SPN Subscription: " subscription
else
	if is_valid_guid "${subscription}"; then
		echo ""
	else
		printf -v val %-40.40s "${subscription}"
		print_banner "Set secrets" "The provided subscription is not valid: ${val}" "error"
		return_code=65 #/* data format error */
		exit $return_code
	fi
fi

print_banner "Set secrets" "Setting secrets for environment ${ZONE_NAME}" "info" "in keyvault ${keyvault}"

echo -e "Key vault:                           ${keyvault}"
echo -e "Subscription:                        ${STATE_SUBSCRIPTION}\n"

secret_name="${ZONE_NAME}"-subscription-id

if setSecretValue "${keyvault}" "${STATE_SUBSCRIPTION}" "${secret_name}" "${subscription}" "configuration"; then
	echo -e "${green}Secret ${secret_name} set in keyvault ${keyvault}${reset}"
else
	echo -e "${bold_red}Failed to set secret ${secret_name} in keyvault ${keyvault}${reset}"
	exit 20
fi

#turn off output, we do not want to show the details being uploaded to keyvault
secret_name="${ZONE_NAME}"-client-id
if setSecretValue "${keyvault}" "${STATE_SUBSCRIPTION}" "${secret_name}" "${client_id}" "configuration"; then
	echo -e "${green}Secret ${secret_name} set in keyvault ${keyvault}${reset}"
else
	echo -e "${bold_red}Failed to set secret ${secret_name} in keyvault ${keyvault}${reset}"
	exit 20
fi

secret_name="${ZONE_NAME}"-tenant-id
if setSecretValue "${keyvault}" "${STATE_SUBSCRIPTION}" "${secret_name}" "${tenant_id}" "configuration"; then
	echo -e "${green}Secret ${secret_name} set in keyvault ${keyvault}${reset}"
else
	echo -e "${bold_red}Failed to set secret ${secret_name} in keyvault ${keyvault}${reset}"
	exit 20
fi

if [ 0 = "${deploy_using_msi_only:-}" ]; then

	secret_name="${ZONE_NAME}"-client-secret
	if setSecretValue "${keyvault}" "${STATE_SUBSCRIPTION}" "${secret_name}" "${client_secret}" "secret"; then
		echo -e "${green}Secret ${secret_name} set in keyvault ${keyvault}${reset}"
	else
		echo -e "${bold_red}Failed to set secret ${secret_name} in keyvault ${keyvault}${reset}"
		exit 20
	fi
fi


#----------------------------------- EXIT --------------------------------------#
echo -e "\n${cyan}Exiting script:  ${BASH_SOURCE[0]}${reset}"
echo -e   "${cyan}   Return code:  ${return_code}${reset}"
exit $return_code
