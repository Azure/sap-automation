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

SCRIPT_NAME="$(basename "$0")"

echo "Entering: ${SCRIPT_NAME}"

#Internal helper functions
function showhelp {
	echo ""
	echo "#########################################################################################"
	echo "#                                                                                       #"
	echo "#                                                                                       #"
	echo "#   This file contains the logic to deploy the deployer.                                #"
	echo "#   The script experts the following exports:                                           #"
	echo "#                                                                                       #"
	echo "#     ARM_SUBSCRIPTION_ID      to specify which subscription to deploy to               #"
	echo "#     SAP_AUTOMATION_REPO_PATH the path to the folder containing                        #"
	echo "#                              the cloned sap-automation                                #"
	echo "#                                                                                       #"
	echo "#   The script will persist the parameters needed between the executions in the         #"
	echo "#   [CONFIG_REPO_PATH]/.sap_deployment_automation folder                                #"
	echo "#                                                                                       #"
	echo "#                                                                                       #"
	echo "#   Usage: install_library.sh                                                           #"
	echo "#    -p or --parameterfile                    library parameter file                    #"
	echo "#    -v or --keyvault                         Name of key vault containing credentiols  #"
	echo "#    -s or --deployer_statefile_foldername    relative path to deployer folder          #"
	echo "#    -i or --auto-approve                     if set will not prompt before apply       #"
	echo "#    -h Show help                                                                       #"
	echo "#                                                                                       #"
	echo "#   Example:                                                                            #"
	echo "#                                                                                       #"
	echo "#   [REPO-ROOT]deploy/scripts/install_library.sh \                                      #"
	echo "#      -p PROD-WEEU-SAP_LIBRARY.json \                                                  #"
	echo "#      -d ../../DEPLOYER/PROD-WEEU-DEP00-INFRASTRUCTURE/ \                              #"
	echo "#      -i true                                                                          #"
	echo "#                                                                                       #"
	echo "#########################################################################################"
}

#process inputs - may need to check the option i for auto approve as it is not used
INPUT_ARGUMENTS=$(getopt -n install_library -o p:d:v:ih --longoptions parameterfile:,deployer_statefile_foldername:,keyvault:,auto-approve,help -- "$@")
VALID_ARGUMENTS=$?

if [ "$VALID_ARGUMENTS" != "0" ]; then
	showhelp

fi

eval set -- "$INPUT_ARGUMENTS"
while :; do
	case "$1" in
	-p | --parameterfile)
		parameterfile_name="$2"
		shift 2
		;;
	-d | --deployer_statefile_foldername)
		deployer_statefile_foldername="$2"
		shift 2
		;;
	-i | --auto-approve)
		approve="--auto-approve"
		shift
		;;
	-h | --help)
		showhelp
		exit 3
		;;
	-v | --keyvault)
		keyvault="$2"
		shift 2
		;;
	--)
		shift
		break
		;;
	esac
done

deployment_system=sap_library
use_deployer=true

if [ "$DEBUG" = true ]; then
	set -x
	set -o errexit
fi

if [ ! -f "${parameterfile_name}" ]; then
	printf -v val %-40.40s "$parameterfile_name"
	echo ""
	echo "#########################################################################################"
	echo "#                                                                                       #"
	echo "#               Parameter file does not exist: ${val} #"
	echo "#                                                                                       #"
	echo "#########################################################################################"
	exit 65
fi

param_dirname=$(dirname "${parameterfile_name}")
export TF_DATA_DIR="${param_dirname}"/.terraform

if [ "$param_dirname" != '.' ]; then
	echo ""
	echo "#########################################################################################"
	echo "#                                                                                       #"
	echo "#   Please run this command from the folder containing the parameter file               #"
	echo "#                                                                                       #"
	echo "#########################################################################################"
	exit 3
fi

# Check that parameter files have environment and location defined
validate_key_parameters "$parameterfile_name"
return_code=$?
if [ 0 != $return_code ]; then
	echo "Missing parameters in $parameterfile_name"
	exit $return_code
fi

region=$(echo "${region}" | tr "[:upper:]" "[:lower:]")
if valid_region_name "${region}"; then
	# Convert the region to the correct code
	get_region_code "${region}"
else
	echo "Invalid region: $region"
	exit 2
fi
key=$(echo "${parameterfile_name}" | cut -d. -f1)
deployer_tf_state="${key}.terraform.tfstate"

if [ -z "${environment}" ]; then
	echo "#########################################################################################"
	echo "#                                                                                       #"
	echo "#                           Incorrect parameter file.                                   #"
	echo "#                                                                                       #"
	echo "#              The file needs to contain the environment attribute!!                    #"
	echo "#                                                                                       #"
	echo "#########################################################################################"
	echo ""
	exit 64
fi

if [ -z "${region}" ]; then
	echo "#########################################################################################"
	echo "#                                                                                       #"
	echo "#                           Incorrect parameter file.                                   #"
	echo "#                                                                                       #"
	echo "#       The file needs to contain the infrastructure.region attribute!!                 #"
	echo "#                                                                                       #"
	echo "#########################################################################################"
	echo ""
	exit 64
fi

# Convert the region to the correct code
region=$(echo "${region}" | tr "[:upper:]" "[:lower:]")
get_region_code "$region"

if [ true == "$use_deployer" ]; then
	if [ ! -d "${deployer_statefile_foldername}" ]; then
		printf -v val %-40.40s "$deployer_statefile_foldername"
		echo ""
		echo "#########################################################################################"
		echo "#                                                                                       #"
		echo "#                    Directory does not exist:  ${deployer_statefile_foldername} #"
		echo "#                                                                                       #"
		echo "#########################################################################################"
		exit
	fi
fi

#Persisting the parameters across executions
automation_config_directory=$CONFIG_REPO_PATH/.sap_deployment_automation/
generic_config_information="${automation_config_directory}"config
library_config_information="${automation_config_directory}${environment}${region_code}"

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

init "${automation_config_directory}" "${generic_config_information}" "${library_config_information}"

export TF_DATA_DIR="${param_dirname}"/.terraform
var_file="${param_dirname}"/"${parameterfile_name}"

if [ -z "${SAP_AUTOMATION_REPO_PATH}" ]; then
	echo ""
	echo "#########################################################################################"
	echo "#                                                                                       #"
	echo "#   Missing environment variables (SAP_AUTOMATION_REPO_PATH)!!!                         #"
	echo "#                                                                                       #"
	echo "#   Please export the following variables:                                              #"
	echo "#      SAP_AUTOMATION_REPO_PATH (path to the repo folder (sap-automation))              #"
	echo "#      ARM_SUBSCRIPTION_ID (subscription containing the state file storage account)     #"
	echo "#                                                                                       #"
	echo "#########################################################################################"
	unset TF_DATA_DIR
	exit 4
fi

if [ -z "$ARM_SUBSCRIPTION_ID" ]; then
	echo ""
	echo "#########################################################################################"
	echo "#                                                                                       #"
	echo "#   Missing environment variables (ARM_SUBSCRIPTION_ID)!!!                              #"
	echo "#                                                                                       #"
	echo "#   Please export the following variables:                                              #"
	echo "#      SAP_AUTOMATION_REPO_PATH (path to the repo folder (sap-automation))              #"
	echo "#      ARM_SUBSCRIPTION_ID (subscription containing the state file storage account)     #"
	echo "#                                                                                       #"
	echo "#########################################################################################"
	unset TF_DATA_DIR
	exit 3
fi

terraform_module_directory="${SAP_AUTOMATION_REPO_PATH}"/deploy/terraform/bootstrap/"${deployment_system}"/

if [ ! -d "${terraform_module_directory}" ]; then
	echo "#########################################################################################"
	echo "#                                                                                       #"
	echo "#   Incorrect system deployment type specified :" ${deployment_system} "            #"
	echo "#                                                                                       #"
	echo "#   Valid options are:                                                                  #"
	echo "#      sap_library                                                                      #"
	echo "#                                                                                       #"
	echo "#########################################################################################"
	echo ""
	unset TF_DATA_DIR
	exit 64
fi

if [ -f ./backend-config.tfvars ]; then
	echo "#########################################################################################"
	echo "#                                                                                       #"
	echo "#                        The bootstrapping has already been done!                       #"
	echo "#                                                                                       #"
	echo "#########################################################################################"
else
	sed -i /REMOTE_STATE_RG/d "${library_config_information}"
	sed -i /REMOTE_STATE_SA/d "${library_config_information}"
	sed -i /tfstate_resource_id/d "${library_config_information}"
fi

TF_VAR_subscription_id="$ARM_SUBSCRIPTION_ID"
export TF_VAR_subscription_id

if [ -n "${keyvault}" ]; then
	TF_VAR_deployer_kv_user_arm_id=$(az resource list --name "${keyvault}" --subscription "$ARM_SUBSCRIPTION_ID" --resource-type Microsoft.KeyVault/vaults --query "[].id | [0]" -o tsv)
	export TF_VAR_spn_keyvault_id="${TF_VAR_deployer_kv_user_arm_id}"
fi

if [ ! -d ./.terraform/ ]; then
	echo "#########################################################################################"
	echo "#                                                                                       #"
	echo "#                                   New deployment                                      #"
	echo "#                                                                                       #"
	echo "#########################################################################################"
	terraform -chdir="${terraform_module_directory}" init -upgrade=true -backend-config "path=${param_dirname}/terraform.tfstate"
	sed -i /REMOTE_STATE_RG/d "${library_config_information}"
	sed -i /REMOTE_STATE_SA/d "${library_config_information}"
	sed -i /tfstate_resource_id/d "${library_config_information}"

else
	if [ -f ./.terraform/terraform.tfstate ]; then
		azure_backend=$(grep "\"type\": \"azurerm\"" .terraform/terraform.tfstate || true)
		if [ -n "$azure_backend" ]; then
			echo "#########################################################################################"
			echo "#                                                                                       #"
			echo "#                     The state is already migrated to Azure!!!                         #"
			echo "#                                                                                       #"
			echo "#########################################################################################"

			REINSTALL_SUBSCRIPTION=$(grep -m1 "subscription_id" "${param_dirname}/.terraform/terraform.tfstate" | cut -d ':' -f2 | tr -d '", \r' | xargs || true)
			REINSTALL_ACCOUNTNAME=$(grep -m1 "storage_account_name" "${param_dirname}/.terraform/terraform.tfstate" | cut -d ':' -f2 | tr -d ' ",\r' | xargs || true)
			REINSTALL_RESOURCE_GROUP=$(grep -m1 "resource_group_name" "${param_dirname}/.terraform/terraform.tfstate" | cut -d ':' -f2 | tr -d ' ",\r' | xargs || true)

			tfstate_resource_id=$(az resource list --name "$REINSTALL_ACCOUNTNAME" --subscription "$REINSTALL_SUBSCRIPTION" --resource-type Microsoft.Storage/storageAccounts --query "[].id | [0]" -o tsv)
			if [ -n "${tfstate_resource_id}" ]; then
				echo "Reinitializing against remote state"
				this_ip=$(curl -s ipinfo.io/ip) >/dev/null 2>&1
				az storage account network-rule add --account-name "$REINSTALL_ACCOUNTNAME" --resource-group "$REINSTALL_RESOURCE_GROUP" --ip-address "${this_ip}" --only-show-errors --output none
				echo "Sleeping for 30 seconds to allow the network rule to take effect"
				sleep 30
				export TF_VAR_tfstate_resource_id=$tfstate_resource_id

				terraform_module_directory="${SAP_AUTOMATION_REPO_PATH}/deploy/terraform/run/sap_library"/

				if terraform -chdir="${terraform_module_directory}" init \
					--backend-config "subscription_id=$REINSTALL_SUBSCRIPTION" \
					--backend-config "resource_group_name=$REINSTALL_RESOURCE_GROUP" \
					--backend-config "storage_account_name=$REINSTALL_ACCOUNTNAME" \
					--backend-config "container_name=tfstate" \
					--backend-config "key=${key}.terraform.tfstate"; then
					print_banner "$banner_title" "Terraform init succeeded." "success"

					terraform -chdir="${terraform_module_directory}" refresh -var-file="${var_file}" -input=false \
						-var deployer_tfstate_key="${deployer_tf_state}"
				else
					print_banner "$banner_title" "Terraform init failed." "error" "Terraform init return code: $return_value"
					exit 10
				fi
			else
				if terraform -chdir="${terraform_module_directory}" init -reconfigure --backend-config "path=${param_dirname}/terraform.tfstate"; then
					print_banner "$banner_title" "Terraform init succeeded." "success"
					terraform -chdir="${terraform_module_directory}" refresh -var-file="${var_file}"
				else
					print_banner "$banner_title" "Terraform init failed." "error" "Terraform init return code: $return_value"
					exit 10
				fi
			fi
		else
			if terraform -chdir="${terraform_module_directory}" init -upgrade=true -backend-config "path=${param_dirname}/terraform.tfstate"; then
				print_banner "$banner_title" "Terraform init succeeded." "success"
			else
				print_banner "$banner_title" "Terraform init failed." "error" "Terraform init return code: $return_value"
				exit 10
			fi

		fi

	else
		if terraform -chdir="${terraform_module_directory}" init -upgrade=true -backend-config "path=${param_dirname}/terraform.tfstate"; then
			echo ""
			print_banner "$banner_title" "Terraform init succeeded." "success"
			echo ""
		else
			print_banner "$banner_title" "Terraform init failed." "error" "Terraform init return code: $return_value"
			exit 10
		fi
	fi
fi

echo ""
echo "#########################################################################################"
echo "#                                                                                       #"
echo "#                             Running Terraform plan                                    #"
echo "#                                                                                       #"
echo "#########################################################################################"
echo ""

if [ -f terraform.tfvars ]; then
	extra_vars=" -var-file=${param_dirname}/terraform.tfvars "
else
	unset extra_vars
fi
install_library_return_value=0

if [ -n "${deployer_statefile_foldername}" ]; then
	echo "Deployer folder specified:           ${deployer_statefile_foldername}"
	terraform -chdir="${terraform_module_directory}" plan -no-color -detailed-exitcode \
		-var-file="${var_file}" -input=false \
		-var deployer_statefile_foldername="${deployer_statefile_foldername}" | tee -a plan_output.log
	install_library_return_value=${PIPESTATUS[0]}
	if [ $install_library_return_value -eq 1 ]; then
		print_banner "$banner_title" "Error when running plan" "error" "Terraform plan return code: $return_value"

		unset TF_DATA_DIR
		exit $install_library_return_value

	else
		print_banner "$banner_title" "Terraform plan succeeded." "success" "Terraform plan return code: $return_value"
	fi
	allParameters=$(printf " -var-file=%s -var deployer_statefile_foldername=%s %s " "${var_file}" "${deployer_statefile_foldername}" "${extra_vars}")
	allImportParameters=$(printf " -var-file=%s -var deployer_statefile_foldername=%s %s " "${var_file}" "${deployer_statefile_foldername}" "${extra_vars}")

else
	terraform -chdir="${terraform_module_directory}" plan -no-color -detailed-exitcode \
		-var-file="${var_file}" -input=false | tee plan_output.log
	install_library_return_value=${PIPESTATUS[0]}
	if [ $install_library_return_value -eq 1 ]; then

		print_banner "$banner_title" "Error when running plan" "error" "Terraform plan return code: $return_value"

		unset TF_DATA_DIR
		exit $install_library_return_value
	else
		print_banner "$banner_title" "Terraform plan succeeded." "success" "Terraform plan return code: $return_value"

		unset TF_DATA_DIR
		exit $install_library_return_value
	fi

	allParameters=$(printf " -var-file=%s %s" "${var_file}" "${extra_vars}")
	allImportParameters=$(printf " -var-file=%s %s" "${var_file}" "${extra_vars}")
fi

parallelism=10

#Provide a way to limit the number of parallell tasks for Terraform
if [[ -n "$TF_PARALLELLISM" ]]; then
	parallelism=$TF_PARALLELLISM
fi

echo "Parallelism count:                   $parallelism"

install_library_return_value=0

echo ""
echo "#########################################################################################"
echo "#                                                                                       #"
echo "#                             Running Terraform apply                                   #"
echo "#                                                                                       #"
echo "#########################################################################################"
echo ""

if [ -n "${approve}" ]; then
	# shellcheck disable=SC2086
	terraform -chdir="${terraform_module_directory}" apply -parallelism="${parallelism}" -no-color -compact-warnings -json -input=false $allParameters --auto-approve | tee apply_output.json
	install_library_return_value=${PIPESTATUS[0]}

else
	# shellcheck disable=SC2086
	terraform -chdir="${terraform_module_directory}" apply -parallelism="${parallelism}" -input=false $allParameters
	install_library_return_value=$?
fi

if [ $install_library_return_value -eq 1 ]; then

	print_banner "$banner_title" "Terraform apply failed" "error" "Terraform apply return code: $return_value"

else
	# return code 2 is ok
	print_banner "$banner_title" "Terraform apply succeeded" "success" "Terraform apply return code: $return_value"
	install_library_return_value=0
	if [ -f apply_output.json ]; then
		rm apply_output.json
	fi
fi

if [ -f apply_output.json ]; then
	errors_occurred=$(jq 'select(."@level" == "error") | length' apply_output.json)

	if [[ -n $errors_occurred ]]; then

		if [ -n "${approve}" ]; then

			# shellcheck disable=SC2086
			if ImportAndReRunApply "apply_output.json" "${terraform_module_directory}" $allImportParameters $allParameters; then
				install_library_return_value=0
			else
				install_library_return_value=$?
			fi
			if [ -f apply_output.json ]; then
				# shellcheck disable=SC2086
				if ImportAndReRunApply "apply_output.json" "${terraform_module_directory}" $allImportParameters $allParameters; then
					install_library_return_value=0
				else
					install_library_return_value=$?
				fi
			fi
			if [ -f apply_output.json ]; then
				# shellcheck disable=SC2086
				if ImportAndReRunApply "apply_output.json" "${terraform_module_directory}" $allImportParameters $allParameters; then
					install_library_return_value=0
				else
					install_library_return_value=$?
				fi
			fi
			if [ -f apply_output.json ]; then
				# shellcheck disable=SC2086
				if ImportAndReRunApply "apply_output.json" "${terraform_module_directory}" $allImportParameters $allParameters; then
					install_library_return_value=0
				else
					install_library_return_value=$?
				fi
			fi
			if [ -f apply_output.json ]; then
				# shellcheck disable=SC2086
				if ImportAndReRunApply "apply_output.json" "${terraform_module_directory}" $allImportParameters $allParameters; then
					install_library_return_value=0
				else
					install_library_return_value=$?
				fi
			fi
		else
			install_library_return_value=10
		fi
	fi

fi
if [ -f apply_output.json ]; then
	rm apply_output.json
fi

if [ 1 == $install_library_return_value ]; then
	print_banner "$banner_title" "Terraform apply failed" "error" "Terraform apply return code: $return_value"
	unset TF_DATA_DIR
	exit "$install_library_return_value"
fi

if [ "$DEBUG" = true ]; then
	terraform -chdir="${terraform_module_directory}" output
fi

if ! terraform -chdir="${terraform_module_directory}" output | grep "No outputs"; then

	tfstate_resource_id=$(terraform -chdir="${terraform_module_directory}" output -no-color -raw tfstate_resource_id | tr -d \")
	STATE_SUBSCRIPTION=$(echo "$tfstate_resource_id" | cut -d/ -f3 | tr -d \" | xargs)

	az account set --sub "$STATE_SUBSCRIPTION"

	REMOTE_STATE_SA=$(terraform -chdir="${terraform_module_directory}" output -no-color -raw remote_state_storage_account_name | tr -d \")
	export REMOTE_STATE_SA

	getAndStoreTerraformStateStorageAccountDetails "${REMOTE_STATE_SA}" "${library_config_information}"

	library_random_id=$(terraform -chdir="${terraform_module_directory}" output -no-color -raw random_id | tr -d \")
	if [ -n "${library_random_id}" ]; then
		save_config_var "library_random_id" "${library_config_information}"
		custom_random_id="${library_random_id:0:3}"
		sed -i -e /"custom_random_id"/d "${var_file}"
		printf "# The parameter 'custom_random_id' can be used to control the random 3 digits at the end of the storage accounts and key vaults\ncustom_random_id=\"%s\"\n" "${custom_random_id}" >>"${var_file}"

	fi
else
	install_library_return_value=20
fi

echo "Exiting: ${SCRIPT_NAME}"

exit "$install_library_return_value"
