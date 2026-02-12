#!/usr/bin/env bash
# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

# This script contains shared functions that work across platforms (GitHub and Azure DevOps)

initialize_platform_variables() {
	# Set default for THIS_AGENT to avoid the "unbound variable" error
	if [ "${PLATFORM}" == "github" ]; then
		# For GitHub Actions
		export THIS_AGENT=${RUNNER_NAME:-"GitHub Actions Runner"}
	elif [ "${PLATFORM}" == "devops" ]; then
		# For Azure DevOps, normally provided by the platform
		export THIS_AGENT=${AGENT_NAME:-"Azure DevOps Agent"}
	else
		# Default value for CLI or other environments
		export THIS_AGENT=${THIS_AGENT:-"CLI"}
	fi
}

# Create a collapsible group in GitHub Actions logs or a styled header in other platforms
start_group() {
	local title="$1"

	if [ "${PLATFORM}" == "github" ]; then
		# GitHub Actions specific syntax for collapsible groups
		echo "::group::${title}"
	else
		# For Azure DevOps or CLI, use colored formatting
		local cyan="\e[1;36m"
		local reset_formatting="\e[0m"
		local separator="-------------------------------------------------------------------------------"
		echo ""
		echo -e "${cyan}${separator}${reset_formatting}"
		echo -e "${cyan}${title}${reset_formatting}"
		echo -e "${cyan}${separator}${reset_formatting}"
	fi
}

# End a collapsible group in GitHub Actions logs (no action needed for other platforms)
end_group() {
	if [ "${PLATFORM}" == "github" ]; then
		echo "::endgroup::"
	fi
}

# Safe variable getter - avoids "unbound variable" errors by providing defaults
safe_get_var() {
	local var_name="$1"
	local default_value="${2:-}"

	# Return variable value if set, otherwise return default
	echo "${!var_name:-$default_value}"
}

# Call initialization when this file is loaded
initialize_platform_variables

# Flag to prevent duplicate loading
export SHARED_FUNCTIONS_LOADED="true"

function get_platform() {
	if [[ -n "${GITHUB_ACTIONS+x}" ]]; then
		echo "github"
		return
	fi

	if [[ -n "${SYSTEM_TEAMPROJECT+x}" ]] && [[ -n "${AGENT_NAME+x}" ]] && [[ -n "${AGENT_MACHINE+x}" ]] && [[ -n "${AGENT_ID+x}" ]]; then
		echo "devops"
		return
	fi

	echo "unknown"
}

function load_platform_functions() {
	script_directory="$(dirname "${BASH_SOURCE[0]}")"

	platform=$(get_platform)
	case "$platform" in
	"github") source "${script_directory}/platform/github_functions.sh" ;;
	"devops") source "${script_directory}/platform/devops_functions.sh" ;;
	*) echo "Unsupported platform - cannot determine if running in GitHub Actions or Azure DevOps"
	exit 1 ;;
	esac
}

function get_value_with_key() {
	key=$1
	label=${2:-$ZONE}

	if [[ $key == "" ]]; then
		exit_error "Cannot get value with an empty key" 1
	fi

	if [[ -n "${APPLICATION_CONFIGURATION_NAME+x}" ]]; then
		value=$(__appconfig_get_value_with_key $key $label)
	else
		value=$(__get_value_with_key $key)
	fi

	echo $value
}

function set_value_with_key() {
	key=$1
	value=$2

	if [[ $key == "" ]]; then
		exit_error "Cannot set value with an empty key" 1
	fi

	if [[ -n "${APPLICATION_CONFIGURATION_NAME+x}" ]]; then
		__appconfig_set_value_with_key $key $value
	else
		__set_value_with_key $key $value
	fi
}

function get_secret_with_key() {
	key=$1

	if [[ $key == "" ]]; then
		exit_error "Cannot get secret with an empty key" 1
	fi

	if [[ -n "${APPLICATION_CONFIGURATION_NAME+x}" ]]; then
		value=$(__appconfig_get_secret_with_key $key)
	else
		value=$(__get_secret_with_key $key)
	fi

	echo $value
}

function set_secret_with_key() {
	key=$1
	value=$2

	if [[ $key == "" ]]; then
		exit_error "Cannot set secret with an empty key" 1
	fi

	if [[ -n "${APPLICATION_CONFIGURATION_NAME+x}" ]]; then
		__appconfig_set_secret_with_key $key $value
	else
		__set_secret_with_key $key $value
	fi
}

function __appconfig_get_value_with_key() {
	key=$1

	var=$(az appconfig kv show -n ${APPLICATION_CONFIGURATION_NAME} --key ${key} --label ${VARIABLE_GROUP_ID} --query value --output tsv 2>/dev/null || echo "")

	echo $var
}

function __appconfig_set_value_with_key() {
	key=$1
	value=$2

	echo "Saving value for key in ${APPLICATION_CONFIGURATION_NAME}: ${key}"
	var=$(az appconfig kv set -n ${APPLICATION_CONFIGURATION_NAME} --key ${key} --label ${VARIABLE_GROUP_ID} --value ${value} --content-type text/plain --yes)

	echo $var
}

function __appconfig_get_secret_with_key() {
	key=$1

	var=$(az appconfig kv show -n ${APPLICATION_CONFIGURATION_NAME} --key ${key} --label ${VARIABLE_GROUP_ID} --query value --secret --output tsv 2>/dev/null || echo "")

	echo $var
}

function __appconfig_set_secret_with_key() {
	key=$1
	value=$2

	echo "Saving secret value for key in ${APPLICATION_CONFIGURATION_NAME}: ${key}"
	var=$(az appconfig kv set -n ${APPLICATION_CONFIGURATION_NAME} --key ${key} --label ${VARIABLE_GROUP_ID} --value ${value} --content-type text/plain --yes --secret)

	echo $var
}

function config_value_with_key() {
	key=$1
	config_file_name=${2:-$deployer_environment_file_name}

	if [[ $key == "" ]]; then
		exit_error "The argument cannot be empty, please supply a key to get the value of" 1
	fi

	echo $(cat ${config_file_name} | grep "${key}=" -m1 | awk -F'=' '{print $2}' | xargs)
}

function set_config_key_with_value() {
	key=$1
	value=$2
	config_file_name=${3:-$deployer_environment_file_name}

	if [[ $key == "" ]]; then
		exit_error "The argument cannot be empty, please supply a key to set the value of" 1
	fi

	if grep -q "^$key=" "$config_file_name"; then
		sed -i "s/^$key=.*/$key=$value/" "$config_file_name"
	else
		echo "$key=$value" >>"$config_file_name"
	fi
}

function region_with_region_map() {
	LOCATION_CODE=$1

	if [[ $LOCATION_CODE == "" ]]; then
		exit_error "The argument cannot be empty, please supply a region code" 1
	fi

	case $LOCATION_CODE in
	"AUCE") LOCATION_IN_FILENAME="australiacentral" ;;
	"AUC2") LOCATION_IN_FILENAME="australiacentral2" ;;
	"AUEA") LOCATION_IN_FILENAME="australiaeast" ;;
	"AUSE") LOCATION_IN_FILENAME="australiasoutheast" ;;
	"BRSO") LOCATION_IN_FILENAME="brazilsouth" ;;
	"BRSE") LOCATION_IN_FILENAME="brazilsoutheast" ;;
	"BRUS") LOCATION_IN_FILENAME="brazilus" ;;
	"CACE") LOCATION_IN_FILENAME="canadacentral" ;;
	"CAEA") LOCATION_IN_FILENAME="canadaeast" ;;
	"CEIN") LOCATION_IN_FILENAME="centralindia" ;;
	"CEUS") LOCATION_IN_FILENAME="centralus" ;;
	"CEUA") LOCATION_IN_FILENAME="centraluseuap" ;;
	"EAAS") LOCATION_IN_FILENAME="eastasia" ;;
	"EAUS") LOCATION_IN_FILENAME="eastus" ;;
	"EUSA") LOCATION_IN_FILENAME="eastus2euap" ;;
	"EUS2") LOCATION_IN_FILENAME="eastus2" ;;
	"EUSG") LOCATION_IN_FILENAME="eastusstg" ;;
	"FRCE") LOCATION_IN_FILENAME="francecentral" ;;
	"FRSO") LOCATION_IN_FILENAME="francesouth" ;;
	"GENO") LOCATION_IN_FILENAME="germanynorth" ;;
	"GEWE") LOCATION_IN_FILENAME="germanywest" ;;
	"GEWC") LOCATION_IN_FILENAME="germanywestcentral" ;;
	"INCE") LOCATION_IN_FILENAME="indonesiacentral" ;;
	"ISCE") LOCATION_IN_FILENAME="israelcentral" ;;
	"ITNO") LOCATION_IN_FILENAME="italynorth" ;;
	"JAEA") LOCATION_IN_FILENAME="japaneast" ;;
	"JAWE") LOCATION_IN_FILENAME="japanwest" ;;
	"JINC") LOCATION_IN_FILENAME="jioindiacentral" ;;
	"JINW") LOCATION_IN_FILENAME="jioindiawest" ;;
	"KOCE") LOCATION_IN_FILENAME="koreacentral" ;;
	"KOSO") LOCATION_IN_FILENAME="koreasouth" ;;
	"NCUS") LOCATION_IN_FILENAME="northcentralus" ;;
	"NOEU") LOCATION_IN_FILENAME="northeurope" ;;
	"NOEA") LOCATION_IN_FILENAME="norwayeast" ;;
	"NOWE") LOCATION_IN_FILENAME="norwaywest" ;;
	"NZNO") LOCATION_IN_FILENAME="newzealandnorth" ;;
	"PLCE") LOCATION_IN_FILENAME="polandcentral" ;;
	"QACE") LOCATION_IN_FILENAME="qatarcentral" ;;
	"SANO") LOCATION_IN_FILENAME="southafricanorth" ;;
	"SAWE") LOCATION_IN_FILENAME="southafricawest" ;;
	"SCUS") LOCATION_IN_FILENAME="southcentralus" ;;
	"SCUG") LOCATION_IN_FILENAME="southcentralusstg" ;;
	"SOEA") LOCATION_IN_FILENAME="southeastasia" ;;
	"SOIN") LOCATION_IN_FILENAME="southindia" ;;
	"SECE") LOCATION_IN_FILENAME="swedencentral" ;;
	"SWNO") LOCATION_IN_FILENAME="switzerlandnorth" ;;
	"SWWE") LOCATION_IN_FILENAME="switzerlandwest" ;;
	"UACE") LOCATION_IN_FILENAME="uaecentral" ;;
	"UANO") LOCATION_IN_FILENAME="uaenorth" ;;
	"UKSO") LOCATION_IN_FILENAME="uksouth" ;;
	"UKWE") LOCATION_IN_FILENAME="ukwest" ;;
	"WCUS") LOCATION_IN_FILENAME="westcentralus" ;;
	"WEEU") LOCATION_IN_FILENAME="westeurope" ;;
	"WEIN") LOCATION_IN_FILENAME="westindia" ;;
	"WEUS") LOCATION_IN_FILENAME="westus" ;;
	"WUS2") LOCATION_IN_FILENAME="westus2" ;;
	"WUS3") LOCATION_IN_FILENAME="westus3" ;;
	*) LOCATION_IN_FILENAME="westeurope" ;;
	esac

	echo $LOCATION_IN_FILENAME
}
