#!/bin/bash

# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

#error codes include those from /usr/include/sysexits.h

#colors for terminal
bold_red_underscore="\e[1;4;31m"
reset_formatting="\e[0m"

#External helper functions
#. "$(dirname "${BASH_SOURCE[0]}")/deploy_utils.sh"
full_script_path="$(realpath "${BASH_SOURCE[0]}")"
script_directory="$(dirname "${full_script_path}")"

#call stack has full script name when using source
source "${script_directory}/deploy_utils.sh"

#helper files
source "${script_directory}/helpers/script_helpers.sh"
detect_platform

banner_title="Remove Deployer"

#Internal helper functions
function showhelp {
	echo ""
	echo "#########################################################################################"
	echo "#                                                                                       #"
	echo "#                                                                                       #"
	echo "#   This file contains the logic to remove the deployer.                                #"
	echo "#   The script experts the following exports:                                           #"
	echo "#                                                                                       #"
	echo "#     ARM_SUBSCRIPTION_ID to specify which subscription to deploy to                    #"
	echo "#     SAP_AUTOMATION_REPO_PATH the path to the folder containing sap-automation repo    #"
	echo "#                                                                                       #"
	echo "#   The script will persist the parameters needed between the executions in the         #"
	echo "#   ~/.sap_deployment_automation folder                                                 #"
	echo "#                                                                                       #"
	echo "#                                                                                       #"
	echo "#   Usage: remove_deployer.sh                                                           #"
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

#process inputs - may need to check the option i for auto approve as it is not used
INPUT_ARGUMENTS=$(getopt -n remove_deployer -o p:ih --longoptions parameterfile:,auto-approve,help -- "$@")
VALID_ARGUMENTS=$?

if [ "$VALID_ARGUMENTS" != "0" ]; then
	showhelp

fi

eval set -- "$INPUT_ARGUMENTS"
while :; do
	case "$1" in
	-p | --parameterfile)
		parameterfile="$2"
		shift 2
		;;
	-i | --auto-approve)
		approve="--auto-approve"
		shift
		;;
	-h | --help)
		showhelp
		shift
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
	set -o errexit
fi

deployment_system=sap_deployer

param_dirname=$(dirname "${parameterfile}")

echo "Parameter file:                       ${parameterfile}"

if [ ! -f "${parameterfile}" ]; then
	printf -v val '%-40.40s' "$parameterfile"
	print_banner "$banner_title" "Parameter file not found: ${val}" "info"
	exit 2 #No such file or directory
fi

if [ "$param_dirname" != '.' ]; then
	print_banner "$banner_title" "Please run this command from the folder containing the parameter file" "info"
	exit 3
fi

# Check that parameter files have environment and location defined
environment=""
region_code=""
validate_key_parameters "$parameterfile"
return_code=$?
if [ 0 != $return_code ]; then
	exit $return_code
fi

region=$(echo "${region}" | tr "[:upper:]" "[:lower:]")
# Convert the region to the correct code
get_region_code "$region"

#Persisting the parameters across executions
automation_config_directory=~/.sap_deployment_automation/
generic_environment_file_name="${automation_config_directory}/config"
deployer_environment_file_name="${automation_config_directory}${environment}${region_code}"

load_config_vars "${deployer_environment_file_name}" "step"

param_dirname=$(pwd)

init "${automation_config_directory}" "${generic_environment_file_name}" "${deployer_environment_file_name}"

var_file="${param_dirname}"/"${parameterfile}"
# Check that the exports ARM_SUBSCRIPTION_ID and SAP_AUTOMATION_REPO_PATH are defined
validate_exports
return_code=$?
if [ 0 != $return_code ]; then
	exit $return_code
fi

terraform_module_directory="${SAP_AUTOMATION_REPO_PATH}"/deploy/terraform/bootstrap/"${deployment_system}"/

export TF_DATA_DIR="${param_dirname}"/.terraform

# Check that Terraform and Azure CLI is installed
validate_dependencies
return_code=$?
if [ 0 != $return_code ]; then
	exit $return_code
fi

current_directory=$(pwd)

terraform -chdir="${terraform_module_directory}" init -reconfigure -backend-config "path=${current_directory}/terraform.tfstate"
extra_vars=""

if [ -f terraform.tfvars ]; then
	extra_vars=" -var-file=${param_dirname}/terraform.tfvars "
fi

print_banner "$banner_title" "Running Terraform destroy" "info"

parallelism=10

#Provide a way to limit the number of parallel tasks for Terraform
if [[ -n "$TF_PARALLELLISM" ]]; then
	parallelism="$TF_PARALLELLISM"
fi

if terraform -chdir="${terraform_module_directory}" destroy "${approve}" -lock=false -refresh=false -parallelism="${parallelism}" -json -var-file="${var_file}" "$extra_vars" | tee destroy_output.json; then
	return_value=${PIPESTATUS[0]}
	print_banner "$banner_title" "Terraform destroy succeeded" "success"
else
	return_value=${PIPESTATUS[0]}
	print_banner "$banner_title" "Terraform destroy failed" "error"
fi

if [ -f destroy_output.json ]; then
	errors_occurred=$(jq 'select(."@level" == "error") | length' destroy_output.json)

	if [[ -n $errors_occurred ]]; then
		print_banner "$banner_title" "Errors during the destroy phase" "error"

		return_value=2
		all_errors=$(jq 'select(."@level" == "error") | {summary: .diagnostic.summary, detail: .diagnostic.detail}' destroy_output.json)
		if [[ -n ${all_errors} ]]; then
			readarray -t errors_strings < <(echo "${all_errors}" | jq -c '.')
			for errors_string in "${errors_strings[@]}"; do
				string_to_report=$(jq -c -r '.detail ' <<<"$errors_string")
				if [[ -z ${string_to_report} ]]; then
					string_to_report=$(jq -c -r '.summary ' <<<"$errors_string")
				fi

				echo -e "$bold_red_underscore  $string_to_report $reset_formatting"
				echo "##vso[task.logissue type=error]${string_to_report}"

			done

		fi
	fi
fi

if [ -f destroy_output.json ]; then
	rm destroy_output.json
fi

if [ 0 == "$return_value" ]; then
	print_banner "$banner_title" "Deployer removed successfully" "success"
	step=0
	export step
	save_config_var "step" "${deployer_environment_file_name}"
fi

unset TF_DATA_DIR

echo "Return from remove_deployer.sh"
exit "$return_value"
