#!/bin/bash

# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

#error codes include those from /usr/include/sysexits.h

#colors for terminal

bold_red="\e[1;31m"
cyan="\e[1;36m"
reset_formatting="\e[0m"

#External helper functions
#. "$(dirname "${BASH_SOURCE[0]}")/deploy_utils.sh"
full_script_path="$(realpath "${BASH_SOURCE[0]}")"
script_directory="$(dirname "${full_script_path}")"

#call stack has full scriptname when using source
# shellcheck disable=SC1091
source "${script_directory}/deploy_utils.sh"

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
	echo "#      --vault prodweeuusrabc  \                                                        #"
	echo "#      --subscription xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx \                            #"
	echo "#      --spn_id yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy \                                  #"
	echo "#      --spn_secret ************************ \                                          #"
	echo "#      --tenant_id zzzzzzzz-zzzz-zzzz-zzzz-zzzzzzzzzzzz \                               #"
	echo "#                                                                                       #"
	echo "#########################################################################################"
}

deploy_using_msi_only=0

INPUT_ARGUMENTS=$(getopt -n set_secrets -o e:r:v:s:c:p:t:b:hwm --longoptions environment:,region:,vault:,subscription:,spn_id:,spn_secret:,tenant_id:,keyvault_subscription:,workload,help,msi -- "$@")
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

if [ "$DEBUG" = True ]; then
	set -x
fi

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

# if ! valid_environment "${environment}"; then
#     echo "The 'environment' must be at most 5 characters long, composed of uppercase letters and numbers!"
#     showhelp
#     exit 65	#/* data format error */
# fi

# if ! valid_region_code "${region_code}"; then
#    echo "The 'region' must be a non-empty string composed of 4 uppercase letters!"
#    showhelp
#    exit 65	#/* data format error */
# fi

automation_config_directory=$CONFIG_REPO_PATH/.sap_deployment_automation
environment_config_information="${automation_config_directory}/${environment}${region_code}"
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

if [ "$workload" != 1 ]; then
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
	else
		printf -v val %-40.40s "$keyvault"
		echo "#########################################################################################"
		echo "#                                                                                       #"
		echo -e "#       The provided keyvault is not valid:$bold_red ${val} $reset_formatting  #"
		echo "#                                                                                       #"
		echo "#########################################################################################"
		echo "The provided keyvault is not valid " "${val}" >secret.err
		return_code=65
		exit $return_code
	fi
fi
if [ -z "${keyvault}" ]; then
	echo "Missing keyvault"
	echo "No keyvault specified" >secret.err
	showhelp
	return_code=65 #/* data format error */
	echo $return_code
	exit $return_code
fi

if [ 0 = "${deploy_using_msi_only:-}" ]; then
	if [ -z "${client_id}" ]; then
		load_config_vars "${environment_config_information}" "client_id"
		if [ -z "$client_id" ]; then
			read -r -p "SPN App ID: " client_id
		fi
	else
		if is_valid_guid "${client_id}"; then
			echo ""
		else
			printf -v val %-40.40s "$client_id"
			echo "#########################################################################################"
			echo "#                                                                                       #"
			echo -e "#       The provided client_id is not valid:$bold_red ${val} $reset_formatting  #"
			echo "#                                                                                       #"
			echo "#########################################################################################"
			return_code=65
			echo "The provided client_id is not valid " "${val}" >secret.err
			exit $return_code
		fi
	fi

	if [ -z "$client_secret" ]; then
		#do not output the secret to screen
		read -rs -p "        -> Kindly provide SPN Password: " client_secret
		echo "********"
	fi

	if [ -z "${tenant_id}" ]; then
		load_config_vars "${environment_config_information}" "tenant_id"
		if [ -z "${tenant_id}" ]; then
			read -r -p "SPN Tenant ID: " tenant_id
		fi
	else
		if is_valid_guid "${tenant_id}"; then
			echo ""
		else
			printf -v val %-40.40s "$tenant_id"
			echo "#########################################################################################"
			echo "#                                                                                       #"
			echo -e "#       The provided tenant_id is not valid:$bold_red ${val} $reset_formatting  #"
			echo "#                                                                                       #"
			echo "#########################################################################################"
			return_code=65
			echo "The provided tenant_id is not valid " "${val}" >secret.err
			exit $return_code
		fi
	fi
	if [ -z "${client_id}" ]; then
		echo "Missing client_id"
		echo "No client_id specified" >secret.err
		showhelp
		return_code=65 #/* data format error */
		echo $return_code
		exit $return_code
	fi

	if [ -z "$client_secret" ]; then
		echo "Missing client_secret"
		echo "No client_secret specified" >secret.err
		showhelp
		return_code=65 #/* data format error */
		echo $return_code
		exit $return_code
	fi

	if [ -z "${tenant_id}" ]; then
		echo "Missing tenant_id"
		echo "No tenant_id specified" >secret.err
		showhelp
		return_code=65 #/* data format error */
		echo $return_code
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
		echo "#########################################################################################"
		echo "#                                                                                       #"
		echo -e "#     The provided subscription is not valid:$bold_red ${val} $reset_formatting #"
		echo "#                                                                                       #"
		echo "#########################################################################################"
		return_code=65 #/* data format error */
		echo "The provided subscription is not valid " "${val}" >secret.err
		exit $return_code
	fi
fi

echo "#########################################################################################"
echo "#                                                                                       #"
echo "#                              Setting the secrets                                      #"
echo "#                                                                                       #"
echo "#########################################################################################"
echo ""

echo "Key vault:                           ${keyvault}"
echo "Subscription:                        ${STATE_SUBSCRIPTION}"

save_config_vars "${environment_config_information}" \
	keyvault \
	environment \
	subscription \
	client_id \
	tenant_id \
	STATE_SUBSCRIPTION

secret_name="${environment}"-subscription-id

# az keyvault secret show --name "${secret_name}" --vault-name "${keyvault}" --subscription "${STATE_SUBSCRIPTION}" >stdout.az 2>&1
# result=$(grep "ERROR: The user, group or application" stdout.az)

# if [ -n "${result}" ]; then
#     upn=$(az account show | grep name | grep @ | cut -d: -f2 | cut -d, -f1 -o tsv | xargs)
#     az keyvault set-policy -n "${keyvault}" --secret-permissions get list recover restore set --upn "${upn}"
# fi
if setSecretValue "${keyvault}" "${STATE_SUBSCRIPTION}" "${secret_name}" "${subscription}" "configuration"; then
	echo "Secret ${secret_name} set in keyvault ${keyvault}"
else
	echo "Failed to set secret ${secret_name} in keyvault ${keyvault}"
	exit 20
fi

if [ 0 = "${deploy_using_msi_only:-}" ]; then

	#turn off output, we do not want to show the details being uploaded to keyvault
	secret_name="${environment}"-client-id
	if setSecretValue "${keyvault}" "${STATE_SUBSCRIPTION}" "${secret_name}" "${client_id}" "configuration"; then
		echo "Secret ${secret_name} set in keyvault ${keyvault}"
	else
		echo "Failed to set secret ${secret_name} in keyvault ${keyvault}"
		exit 20
	fi

	secret_name="${environment}"-tenant-id
	if setSecretValue "${keyvault}" "${STATE_SUBSCRIPTION}" "${secret_name}" "${tenant_id}" "configuration"; then
		echo "Secret ${secret_name} set in keyvault ${keyvault}"
	else
		echo "Failed to set secret ${secret_name} in keyvault ${keyvault}"
		exit 20
	fi
	secret_name="${environment}"-client-secret
	if setSecretValue "${keyvault}" "${STATE_SUBSCRIPTION}" "${secret_name}" "${client_secret}" "secret"; then
		echo "Secret ${secret_name} set in keyvault ${keyvault}"
	else
		echo "Failed to set secret ${secret_name} in keyvault ${keyvault}"
		exit 20
	fi
fi
exit $return_code
