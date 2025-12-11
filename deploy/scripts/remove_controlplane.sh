#!/bin/bash

# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

#error codes include those from /usr/include/sysexits.h

#colors for terminal
bold_red_underscore="\e[1;4;31m"
bold_red="\e[1;31m"
cyan="\e[1;36m"
reset_formatting="\e[0m"

#External helper functions
#. "$(dirname "${BASH_SOURCE[0]}")/deploy_utils.sh"
full_script_path="$(realpath "${BASH_SOURCE[0]}")"
script_directory="$(dirname "${full_script_path}")"

#call stack has full script name when using source
source "${script_directory}/deploy_utils.sh"

#helper files
source "${script_directory}/helpers/script_helpers.sh"

keep_agent=0

if [ "$DEBUG" = True ]; then
	echo -e "${cyan}Enabling debug mode$reset_formatting"
	set -x
	set -o errexit
fi

################################################################################################
#                                                                                              #
#   This file contains the logic to deploy the environment to support SAP workloads.           #
#                                                                                              #
#   The script is intended to be run from a parent folder to the folders containing            #
#   the json parameter files for the deployer, the library and the environment.                #
#                                                                                              #
#   The script will persist the parameters needed between the executions in the                #
#   [CONFIG_REPO_PATH]/.sap_deployment_automation folder                                                        #
#                                                                                              #
#   The script experts the following exports:                                                  #
#   ARM_SUBSCRIPTION_ID to specify which subscription to deploy to                             #
#   SAP_AUTOMATION_REPO_PATH the path to the folder containing the cloned sap-automation                 #
#                                                                                              #
################################################################################################

function showhelp {
	echo ""
	echo "##################################################################################################################"
	echo "#                                                                                                                #"
	echo "#                                                                                                                #"
	echo "#   This file contains the logic to remove the deployer and library from an Azure region                         #"
	echo "#                                                                                                                #"
	echo "#   The script experts the following exports:                                                                    #"
	echo "#                                                                                                                #"
	echo "#     SAP_AUTOMATION_REPO_PATH the path to the folder containing the cloned sap-automation                       #"
	echo "#                                                                                                                #"
	echo "#   The script is to be run from a parent folder to the folders containing the json parameter files for          #"
	echo "#    the deployer and the library and the environment.                                                           #"
	echo "#                                                                                                                #"
	echo "#   The script will persist the parameters needed between the executions in the                                  #"
	echo "#   [CONFIG_REPO_PATH]/.sap_deployment_automation folder                                                         #"
	echo "#                                                                                                                #"
	echo "#                                                                                                                #"
	echo "#   Usage: remove_region.sh                                                                                      #"
	echo "#      -d or --deployer_parameter_file       deployer parameter file                                             #"
	echo "#      -l or --library_parameter_file        library parameter file                                              #"
	echo "#                                                                                                                #"
	echo "#                                                                                                                #"
	echo "#   Example:                                                                                                     #"
	echo "#                                                                                                                #"
	echo "#   SAP_AUTOMATION_REPO_PATH/scripts/remove_controlplane.sh \                                                    #"
	echo "#      --deployer_parameter_file DEPLOYER/PROD-WEEU-DEP00-INFRASTRUCTURE/PROD-WEEU-DEP00-INFRASTRUCTURE.tfvars \ #"
	echo "#      --library_parameter_file LIBRARY/PROD-WEEU-SAP_LIBRARY/PROD-WEEU-SAP_LIBRARY.tfvars \                     #"
	echo "#                                                                                                                #"
	echo "##################################################################################################################"
}

function missing {
	printf -v val '%-40s' "$missing_value"
	echo ""
	echo "#########################################################################################"
	echo "#                                                                                       #"
	echo "#   Missing : ${val}                                  #"
	echo "#                                                                                       #"
	echo "#   Usage: remove_region.sh                                                             #"
	echo "#      -d or --deployer_parameter_file       deployer parameter file                    #"
	echo "#      -l or --library_parameter_file        library parameter file                     #"
	echo "#                                                                                       #"
	echo "#########################################################################################"

}

force=0
ado=0
INPUT_ARGUMENTS=$(getopt -n remove_control_plane -o d:l:s:b:r:ihag --longoptions deployer_parameter_file:,library_parameter_file:,subscription:,resource_group:,storage_account:,auto-approve,ado,help,keep_agent -- "$@")
VALID_ARGUMENTS=$?

if [ "$VALID_ARGUMENTS" != "0" ]; then
	showhelp
fi
echo "$INPUT_ARGUMENTS"
eval set -- "$INPUT_ARGUMENTS"
while :; do
	case "$1" in
	-d | --deployer_parameter_file)
		deployer_parameter_file="$2"
		shift 2
		;;
	-l | --library_parameter_file)
		library_parameter_file="$2"
		shift 2
		;;
	-s | --subscription)
		subscription="$2"
		shift 2
		;;
	-b | --storage_account)
		storage_account="$2"
		shift 2
		;;
	-r | --resource_group)
		resource_group="$2"
		shift 2
		;;
	-a | --ado)
		approve_parameter="--auto-approve;ado=1"
		shift
		;;
	-g | --keep_agent)
		keep_agent=1
		shift
		;;
	-i | --auto-approve)
		approve_parameter="--auto-approve"
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

if [ -z "$deployer_parameter_file" ]; then
	missing_value='deployer parameter file'
	missing
	exit 2
fi

if [ -z "$library_parameter_file" ]; then
	missing_value='library parameter file'
	missing
	exit 2
fi

# Check that the exports ARM_SUBSCRIPTION_ID and SAP_AUTOMATION_REPO_PATH are defined
validate_exports
return_code=$?
if [ 0 != $return_code ]; then
	exit $return_code
fi

# Check that Terraform and Azure CLI is installed
validate_dependencies
return_code=$?
if [ 0 != $return_code ]; then
	exit $return_code
fi

# Check that parameter files have environment and location defined
validate_key_parameters "$deployer_parameter_file"
return_code=$?
if [ 0 != $return_code ]; then
	exit $return_code
fi

if valid_region_name "${region}"; then
	# Convert the region to the correct code
	get_region_code "${region}"
else
	echo "Invalid region: $region"
	exit 2
fi

automation_config_directory="$CONFIG_REPO_PATH/.sap_deployment_automation/"
generic_environment_file_name="${automation_config_directory}"/config
CONTROL_PLANE_NAME=$(echo "$deployer_parameter_file" | cut -d'-' -f1-3)
deployer_tfstate_key="${CONTROL_PLANE_NAME}-INFRASTRUCTURE.terraform.tfstate"
export deployer_tfstate_key
environment=$(echo "$deployer_tfstate_key" | awk -F'-' '{print $1}' | xargs)
region_code=$(echo "$deployer_tfstate_key" | awk -F'-' '{print $2}' | xargs)
network_logical_name=$(echo "$deployer_tfstate_key" | awk -F'-' '{print $3}' | xargs)

deployer_environment_file_name=$(get_configuration_file "$automation_config_directory" "$environment" "$region_code" "$network_logical_name")
SYSTEM_CONFIGURATION_FILE="${deployer_environment_file_name}"
export SYSTEM_CONFIGURATION_FILE

load_config_vars "${deployer_environment_file_name}" "step"
if [ 1 -eq $step ]; then
	exit 0
fi

if [ 0 -eq $step ]; then
	exit 0
fi

if [ -z "$deployer_environment_file_name" ]; then
	rm "$deployer_environment_file_name"
fi

root_dirname=$(pwd)

init "${automation_config_directory}" "${generic_environment_file_name}" "${deployer_environment_file_name}"

this_ip=$(curl -s ipinfo.io/ip) >/dev/null 2>&1

export TF_IN_AUTOMATION="true"
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

echo "Deployer environment:                  $environment"

this_ip=$(curl -s ipinfo.io/ip) >/dev/null 2>&1
export TF_VAR_Agent_IP=$this_ip
echo "Agent IP:                              $this_ip"

if [ -n "${subscription}" ]; then
	export ARM_SUBSCRIPTION_ID=$subscription
else
	subscription=$ARM_SUBSCRIPTION_ID
fi

deployer_dirname=$(dirname "${deployer_parameter_file}")
deployer_tfvars_filename=$(basename "${deployer_parameter_file}")

library_dirname=$(dirname "${library_parameter_file}")
library_tfvars_filename=$(basename "${library_parameter_file}")

relative_path="${root_dirname}"/"${deployer_dirname}"
export TF_DATA_DIR="${relative_path}"/.terraform

current_directory=$(pwd)

#we know that we have a valid az session so let us set the environment variables
set_executing_user_environment_variables "none"

# Deployer

cd "${deployer_dirname}" || exit

param_dirname=$(pwd)

relative_path="${current_directory}"/"${deployer_dirname}"

terraform_module_directory="${SAP_AUTOMATION_REPO_PATH}"/deploy/terraform/run/sap_deployer/
export TF_DATA_DIR="${param_dirname}/.terraform"

if [ -z "${storage_account}" ]; then
	load_config_vars "${deployer_environment_file_name}" "STATE_SUBSCRIPTION"
	load_config_vars "${deployer_environment_file_name}" "REMOTE_STATE_SA"
	load_config_vars "${deployer_environment_file_name}" "REMOTE_STATE_RG"
	load_config_vars "${deployer_environment_file_name}" "tfstate_resource_id"

	if [ -n "${STATE_SUBSCRIPTION}" ]; then
		subscription="${STATE_SUBSCRIPTION}"
		az account set --sub "${STATE_SUBSCRIPTION}"
	fi

	if [ -n "${REMOTE_STATE_SA}" ]; then
		storage_account="${REMOTE_STATE_SA}"
	fi

	if [ -n "${REMOTE_STATE_RG}" ]; then
		resource_group="${REMOTE_STATE_RG}"
	fi
fi

key=$(echo "${deployer_tfvars_filename}" | cut -d. -f1)

useSAS=$(az storage account show --name "${REMOTE_STATE_SA}" --query allowSharedKeyAccess --subscription "${STATE_SUBSCRIPTION}" --out tsv)

if [ "$useSAS" = "true" ]; then
	echo "Storage Account Authentication:        Key"
	export ARM_USE_AZUREAD=false
else
	echo "Storage Account Authentication:        Entra ID"
	export ARM_USE_AZUREAD=true
fi

TF_VAR_subscription_id="${STATE_SUBSCRIPTION}"
export TF_VAR_subscription_id

# Reinitialize
echo ""
echo "#########################################################################################"
echo "#                                                                                       #"
echo "#                          Running Terraform init (deployer)                            #"
echo "#                                                                                       #"
echo "#########################################################################################"
echo ""
echo "#  subscription_id=${subscription}"
echo "#  backend-config resource_group_name=${resource_group}"
echo "#  storage_account_name=${storage_account}"
echo "#  container_name=tfstate"
echo "#  key=${key}.terraform.tfstate"

if [ -f init_error.log ]; then
	rm init_error.log
fi

terraform_module_directory="${SAP_AUTOMATION_REPO_PATH}"/deploy/terraform/bootstrap/sap_deployer/

if [ -f .terraform/terraform.tfstate ]; then
	azure_backend=$(grep "\"type\": \"azurerm\"" .terraform/terraform.tfstate || true)
	if [ -n "$azure_backend" ]; then
		echo "Terraform state:                     remote"
		if terraform -chdir="${terraform_module_directory}" init -migrate-state -upgrade -force-copy --backend-config "path=${param_dirname}/terraform.tfstate"; then
			return_value=$?
			print_banner "Remove Control Plane " "Terraform init succeeded (deployer - local)" "success"
		else
			return_value=$?
			print_banner "Remove Control Plane " "Terraform init failed (deployer - local)" "error"
		fi

	else
		echo "Terraform state:                     local"
		if terraform -chdir="${terraform_module_directory}" init -upgrade --backend-config "path=${param_dirname}/terraform.tfstate"; then
			return_value=$?
			print_banner "Remove Control Plane " "Terraform init succeeded (deployer - local)" "success"
		else
			return_value=$?
			print_banner "Remove Control Plane " "Terraform init failed (deployer - local)" "error"
		fi

	fi
else
	echo "Terraform state:                     unknown"
	if terraform -chdir="${terraform_module_directory}" init -reconfigure -upgrade --backend-config "path=${param_dirname}/terraform.tfstate"; then
		return_value=$?
		print_banner "Remove Control Plane " "Terraform init succeeded (deployer - local)" "success"
	else
		return_value=$?
		print_banner "Remove Control Plane " "Terraform init failed (deployer - local)" "error"
	fi
fi

deployer_statefile_foldername_path=$(dirname "${deployer_parameter_file}")
if [ 0 != $return_value ]; then
	unset TF_DATA_DIR
	exit 10
fi

print_banner "Remove Control Plane " "Running Terraform init (library - local)" "info"

if ! terraform -chdir="${terraform_module_directory}" output | grep "No outputs"; then
	keyvault_id=$(terraform -chdir="${terraform_module_directory}" output -no-color -raw deployer_kv_user_arm_id | tr -d \")
	TF_VAR_spn_keyvault_id="${keyvault_id}"
	export TF_VAR_spn_keyvault_id
fi

cd "${current_directory}" || exit

key=$(echo "${library_tfvars_filename}" | cut -d. -f1)
cd "${library_dirname}" || exit
param_dirname=$(pwd)

#Library

terraform_module_directory="${SAP_AUTOMATION_REPO_PATH}"/deploy/terraform/bootstrap/sap_library/
export TF_DATA_DIR="${param_dirname}/.terraform"

#Reinitialize

if [ -f .terraform/terraform.tfstate ]; then
	azure_backend=$(grep "\"type\": \"azurerm\"" .terraform/terraform.tfstate || true)
	if [ -n "$azure_backend" ]; then
		echo "Terraform state:                     remote"
		if terraform -chdir="${terraform_module_directory}" init -upgrade -force-copy -migrate-state --backend-config "path=${param_dirname}/terraform.tfstate"; then
			return_value=$?
			print_banner "Remove Control Plane " "Terraform init succeeded (library - local)" "success"
		else
			return_value=$?
			print_banner "Remove Control Plane " "Terraform init failed (library - local)" "error"
			unset TF_DATA_DIR
			exit 20
		fi
	else
		echo "Terraform state:                     local"
		if terraform -chdir="${terraform_module_directory}" init -upgrade -reconfigure --backend-config "path=${param_dirname}/terraform.tfstate"; then
			return_value=$?
			print_banner "Remove Control Plane " "Terraform init succeeded (library - local)" "success"
		else
			return_value=$?
			print_banner "Remove Control Plane " "Terraform init failed (library - local)" "error"
			unset TF_DATA_DIR
			exit 20
		fi
	fi
else
	echo "Terraform state:                     unknown"
	if terraform -chdir="${terraform_module_directory}" init -upgrade -reconfigure --backend-config "path=${param_dirname}/terraform.tfstate"; then
		return_value=$?
		print_banner "Remove Control Plane " "Terraform init succeeded (library - local)" "success"
	else
		return_value=$?
		print_banner "Remove Control Plane " "Terraform init failed (library - local)" "error"
		unset TF_DATA_DIR
		exit 20
	fi
fi

extra_vars=""

if [ -f terraform.tfvars ]; then
	extra_vars=" -var-file=${param_dirname}/terraform.tfvars "
fi

var_file="${param_dirname}"/"${library_tfvars_filename}"

export TF_DATA_DIR="${param_dirname}/.terraform"
export TF_use_spn=false

print_banner "Remove Control Plane " "Running Terraform destroy (library)" "info"

if terraform -chdir="${terraform_module_directory}" destroy -input=false -var-file="${library_parameter_file}" -var deployer_statefile_foldername="${deployer_statefile_foldername_path}" "${approve_parameter}"; then
	return_value=$?
	print_banner "Remove Control Plane " "Terraform destroy (library) succeeded" "success"
else
	return_value=$?
	print_banner "Remove Control Plane " "Terraform destroy (library) failed" "error"
	unset TF_DATA_DIR
	exit 20
fi

echo ""
echo "#########################################################################################"
echo "#                                                                                       #"
echo "#                                       Reset settings                                  #"
echo "#                                                                                       #"
echo "#########################################################################################"
echo ""

STATE_SUBSCRIPTION=''
REMOTE_STATE_SA=''
REMOTE_STATE_RG=''
save_config_vars "${deployer_environment_file_name}" \
	tfstate_resource_id \
	REMOTE_STATE_SA \
	REMOTE_STATE_RG \
	STATE_SUBSCRIPTION

cd "${current_directory}" || exit
step=1
save_config_var "step" "${deployer_environment_file_name}"

if [ 1 -eq $keep_agent ]; then

	cd "${deployer_dirname}" || exit
	param_dirname=$(pwd)

	terraform_module_directory="${SAP_AUTOMATION_REPO_PATH}"/deploy/terraform/bootstrap/sap_deployer/
	export TF_DATA_DIR="${param_dirname}/.terraform"

	if terraform -chdir="${terraform_module_directory}" init  --backend-config "path=${param_dirname}/terraform.tfstate"; then
		return_value=$?
		print_banner "Remove Control Plane " "Terraform init succeeded (deployer - local)" "success"
	else
		return_value=$?
		print_banner "Remove Control Plane " "Terraform init failed (deployer - local)" "error"
	fi

	if [ -z "$keyvault" ]; then
		load_config_vars "${deployer_environment_file_name}" "keyvault"
		if valid_kv_name "$keyvault"; then
			az keyvault network-rule add --ip-address "$TF_VAR_Agent_IP" --name "$keyvault" --output none
			az keyvault update --name "$keyvault" --public-network-access Enabled --output none
		fi

	fi

	if terraform -chdir="${terraform_module_directory}" apply -input=false -var-file="${deployer_parameter_file}" "${approve_parameter}"; then
		return_value=$?
		print_banner "Remove Control Plane " "Terraform apply (deployer) succeeded" "success"
	else
		print_banner "Remove Control Plane " "Terraform apply (deployer) failed" "error"
	fi
	echo "Keeping the Azure DevOps agent"

	cd "${deployer_dirname}" || exit

	param_dirname=$(pwd)

else
	cd "${deployer_dirname}" || exit

	param_dirname=$(pwd)

	if [ -z "$keyvault" ]; then
		load_config_vars "${deployer_environment_file_name}" "keyvault"
		if valid_kv_name "$keyvault"; then
			az keyvault network-rule add --ip-address "$TF_VAR_Agent_IP" --name "$keyvault"
		fi

	fi

	terraform_module_directory="${SAP_AUTOMATION_REPO_PATH}"/deploy/terraform/bootstrap/sap_deployer/
	export TF_DATA_DIR="${param_dirname}/.terraform"

	extra_vars=""

	if [ -f terraform.tfvars ]; then
		extra_vars=" -var-file=${param_dirname}/terraform.tfvars "
	fi

	echo ""
	echo "#########################################################################################"
	echo "#                                                                                       #"
	echo "#                     Running Terraform destroy (deployer)                              #"
	echo "#                                                                                       #"
	echo "#########################################################################################"
	echo ""

	if terraform -chdir="${terraform_module_directory}" destroy -var-file="${deployer_parameter_file}" "${approve_parameter}"; then
		return_value=$?
		echo ""
		echo -e "${cyan}Terraform destroy:                      succeeded$reset_formatting"
		echo ""
		if [ -f "${param_dirname}/terraform.tfstate" ]; then
			rm "${param_dirname}/terraform.tfstate"
		fi
		if [ -f "${param_dirname}/terraform.tfstate.backup" ]; then
			rm "${param_dirname}/terraform.tfstate.backup"
		fi
		if [ -f "${param_dirname}/.terraform/terraform.tfstate" ]; then
			rm "${param_dirname}/.terraform/terraform.tfstate"
		fi
	else
		return_value=$?
		echo ""
		echo -e "${bold_red}Terraform destroy:                      failed$reset_formatting"
		echo ""
	fi

	step=0
	save_config_var "step" "${deployer_environment_file_name}"
	if [ 0 != $return_value ]; then
		keyvault=''
		deployer_tfstate_key=''
		DEPLOYER_KEYVAULT=''
		APPLICATION_CONFIGURATION_NAME=''
		APPLICATION_CONFIGURATION_DEPLOYMENT=''
		APP_SERVICE_DEPLOYMENT=''
		APP_SERVICE_NAME=''

		save_config_var "$keyvault" "${deployer_environment_file_name}"
		save_config_var "$deployer_tfstate_key" "${deployer_environment_file_name}"
		save_config_var "$DEPLOYER_KEYVAULT" "${deployer_environment_file_name}"
		save_config_var "$APPLICATION_CONFIGURATION_NAME" "${deployer_environment_file_name}"
		save_config_var "$APPLICATION_CONFIGURATION_DEPLOYMENT" "${deployer_environment_file_name}"
		save_config_var "$APP_SERVICE_DEPLOYMENT" "${deployer_environment_file_name}"
		save_config_var "$APP_SERVICE_NAME" "${deployer_environment_file_name}"
		if [ -f "${deployer_environment_file_name}" ]; then
			rm "${deployer_environment_file_name}"
		fi
	fi
fi

cd "${current_directory}" || exit

unset TF_DATA_DIR
exit $return_value
