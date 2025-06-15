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

#call stack has full scriptname when using source
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

#process inputs - may need to check the option i for auto approve as it is not used
INPUT_ARGUMENTS=$(getopt -n install_deployer -o p:ih --longoptions parameterfile:,auto-approve,help -- "$@")
VALID_ARGUMENTS=$?

if [ "$VALID_ARGUMENTS" != "0" ]; then
	showhelp
	exit 3
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
		exit 3
		;;
	--)
		shift
		break
		;;
	esac
done

deployment_system=sap_deployer

param_dirname=$(dirname "${parameterfile}")
export TF_DATA_DIR="${param_dirname}/.terraform"

echo "Parameter file:                      ${parameterfile}"

if [ ! -f "${parameterfile}" ]; then
	printf -v val %-40.40s "$parameterfile"
	echo ""
	echo "#########################################################################################"
	echo "#                                                                                       #"
	echo "#               Parameter file does not exist: ${val} #"
	echo "#                                                                                       #"
	echo "#########################################################################################"
	exit 2 #No such file or directory
fi

if [ "$param_dirname" != '.' ]; then
	echo ""
	echo "#########################################################################################"
	echo "#                                                                                       #"
	echo "#   Please run this command from the folder containing the parameter file               #"
	echo "#                                                                                       #"
	echo "#########################################################################################"
	exit 3
fi

if [ "$DEBUG" = True ]; then
	set -x
	set -o errexit
fi

# Check that parameter files have environment and location defined
validate_key_parameters "$parameterfile"
return_code=$?
if [ 0 != $return_code ]; then
	exit $return_code
fi

region=$(echo "${region}" | tr "[:upper:]" "[:lower:]")
# Convert the region to the correct code
get_region_code "$region"

key=$(echo "${parameterfile}" | cut -d. -f1)

#Persisting the parameters across executions
automation_config_directory=$CONFIG_REPO_PATH/.sap_deployment_automation/
generic_config_information="${automation_config_directory}"config
deployer_config_information="${automation_config_directory}""${environment}""${region_code}"

param_dirname=$(pwd)

init "${automation_config_directory}" "${generic_config_information}" "${deployer_config_information}"

var_file="${param_dirname}"/"${parameterfile}"
# Check that the exports ARM_SUBSCRIPTION_ID and SAP_AUTOMATION_REPO_PATH are defined
validate_exports
return_code=$?
if [ 0 != $return_code ]; then
	exit $return_code
fi

echo "Configuration file:                  $parameterfile"
echo "Deployment region:                   $region"
echo "Deployment region code:              $region_code"

terraform_module_directory="${SAP_AUTOMATION_REPO_PATH}"/deploy/terraform/bootstrap/"${deployment_system}"/
export TF_DATA_DIR="${param_dirname}"/.terraform

this_ip=$(curl -s ipinfo.io/ip) >/dev/null 2>&1
export TF_VAR_Agent_IP=$this_ip
echo "Agent IP:                            $this_ip"

# Check that Terraform and Azure CLI is installed
validate_dependencies
return_code=$?
if [ 0 != $return_code ]; then
	exit $return_code
fi

extra_vars=""
reinstalled=0

if [ -f terraform.tfvars ]; then
	extra_vars=" -var-file=${param_dirname}/terraform.tfvars "
fi

allParameters=$(printf " -var-file=%s %s" "${var_file}" "${extra_vars}")
allImportParameters=$(printf " -var-file=%s %s " "${var_file}" "${extra_vars}")

if [ ! -d ./.terraform/ ]; then
	echo "#########################################################################################"
	echo "#                                                                                       #"
	echo "#                                   New deployment                                      #"
	echo "#                                                                                       #"
	echo "#########################################################################################"
	terraform -chdir="${terraform_module_directory}" init -upgrade=true -backend-config "path=${param_dirname}/terraform.tfstate"
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

				terraform_module_directory="${SAP_AUTOMATION_REPO_PATH}/deploy/terraform/run/sap_deployer"/

				if terraform -chdir="${terraform_module_directory}" init -upgrade=true \
					--backend-config "subscription_id=$REINSTALL_SUBSCRIPTION" \
					--backend-config "resource_group_name=$REINSTALL_RESOURCE_GROUP" \
					--backend-config "storage_account_name=$REINSTALL_ACCOUNTNAME" \
					--backend-config "container_name=tfstate" \
					--backend-config "key=${key}.terraform.tfstate"; then
					echo ""
					echo -e "${cyan}Terraform init:                        succeeded$reset_formatting"
					echo ""
					terraform -chdir="${terraform_module_directory}" refresh -var-file="${var_file}"
					keyvault_id=$(terraform -chdir="${terraform_module_directory}" output deployer_kv_user_arm_id | tr -d \")
					echo "$keyvault_id"
					keyvault=$(echo "$keyvault_id" | cut -d / -f9)
					keyvault_resource_group=$(echo "$keyvault_id" | cut -d / -f5)
					keyvault_subscription=$(echo "$keyvault_id" | cut -d / -f3)

					export TF_VAR_recover=true

					az keyvault update --name "$keyvault" --resource-group "$keyvault_resource_group" --subscription "$keyvault_subscription" --public-network-access Enabled --only-show-errors --output none
					echo "Sleeping for 30 seconds to allow the key vault network rule to take effect"
					sleep 30
				else
					echo -e "${bold_red}Terraform init:                        succeeded$reset_formatting"
					exit 10
				fi
			else
				if terraform -chdir="${terraform_module_directory}" init -upgrade=true -reconfigure --backend-config "path=${param_dirname}/terraform.tfstate"; then
					echo ""
					echo -e "${cyan}Terraform init:                        succeeded$reset_formatting"
					echo ""
					terraform -chdir="${terraform_module_directory}" refresh -var-file="${var_file}"
				else
					echo -e "${bold_red}Terraform init:                        succeeded$reset_formatting"
					exit 10
				fi
			fi
		else
			if terraform -chdir="${terraform_module_directory}" init -upgrade=true -backend-config "path=${param_dirname}/terraform.tfstate"; then
				echo ""
				echo -e "${cyan}Terraform init:                        succeeded$reset_formatting"
				echo ""
			else
				echo ""
				echo -e "${bold_red}Terraform init:                        failed$reset_formatting"
				echo ""
				exit 10
			fi
		fi

	else
		echo "#########################################################################################"
		echo "#                                                                                       #"
		echo "#                                   New deployment                                      #"
		echo "#                                                                                       #"
		echo "#########################################################################################"
		terraform -chdir="${terraform_module_directory}" init -upgrade=true -backend-config "path=${param_dirname}/terraform.tfstate"
	fi
	echo "Parameters:                          $allParameters"
	terraform -chdir="${terraform_module_directory}" refresh $allParameters
fi
return_value=$?
if [ 1 == $return_value ]; then
	echo ""
	echo "#########################################################################################"
	echo "#                                                                                       #"
	echo -e "#                             $bold_red_underscore Errors during the init phase $reset_formatting                              #"
	echo "#                                                                                       #"
	echo "#########################################################################################"
	echo ""
	unset TF_DATA_DIR
	exit $return_value
fi

echo ""
echo "#########################################################################################"
echo "#                                                                                       #"
echo "#                             Running Terraform plan                                    #"
echo "#                                                                                       #"
echo "#########################################################################################"
echo ""

# shellcheck disable=SC2086

if terraform -chdir="$terraform_module_directory" plan -detailed-exitcode -input=false $allParameters | tee plan_output.log; then
	return_value=${PIPESTATUS[0]}
else
	return_value=${PIPESTATUS[0]}
fi
echo "Terraform plan return code:          $return_value"
if [ 0 == $return_value ]; then
	echo ""
	echo -e "${cyan}Terraform plan:                      succeeded$reset_formatting"
	echo ""
	return_value=0
elif [ 2 == $return_value ]; then
	echo ""
	echo -e "${cyan}Terraform plan:                      succeeded$reset_formatting"
	echo ""
	return_value=0
else
	echo ""
	echo -e "${bold_red}Terraform plan:                      failed$reset_formatting"
	echo ""
	exit $return_value
fi

if [ 1 == $return_value ]; then
	echo ""
	echo "#########################################################################################"
	echo "#                                                                                       #"
	echo -e "#                             $bold_red_underscore Errors during the plan phase $reset_formatting                              #"
	echo "#                                                                                       #"
	echo "#########################################################################################"
	echo ""
	if [ -f plan_output.log ]; then
		cat plan_output.log
		rm plan_output.log
	fi
	unset TF_DATA_DIR
	exit $return_value
fi

if [ -f plan_output.log ]; then
	rm plan_output.log
fi

echo ""
echo "#########################################################################################"
echo "#                                                                                       #"
echo "#                             Running Terraform apply                                   #"
echo "#                                                                                       #"
echo "#########################################################################################"
echo ""

parallelism=10

#Provide a way to limit the number of parallell tasks for Terraform
if [[ -n "${TF_PARALLELLISM}" ]]; then
	parallelism=$TF_PARALLELLISM
fi

if [ -f apply_output.json ]; then
	rm apply_output.json
fi

return_value=0

if [ -n "${approve}" ]; then
	# shellcheck disable=SC2086
	if terraform -chdir="${terraform_module_directory}" apply -parallelism="${parallelism}" \
		$allParameters -no-color -compact-warnings -json -input=false --auto-approve | tee apply_output.json; then
		return_value=${PIPESTATUS[0]}
	else
		return_value=${PIPESTATUS[0]}
	fi
	if [ $return_value -eq 1 ]; then
		echo ""
		echo -e "${bold_red}Terraform apply:                     failed ($return_value)$reset_formatting"
		echo ""
	else
		# return code 2 is ok
		echo ""
		echo -e "${cyan} Terraform apply:                    succeeded ($return_value)$reset_formatting"
		echo ""
		return_value=0
	fi
else
	# shellcheck disable=SC2086
	if terraform -chdir="${terraform_module_directory}" apply -parallelism="${parallelism}" $allParameters; then
		return_value=${PIPESTATUS[0]}
	else
		return_value=${PIPESTATUS[0]}
	fi
	if [ $return_value -eq 1 ]; then
		echo ""
		echo -e "${bold_red}Terraform apply:                     failed ($return_value)$reset_formatting"
		echo ""
		exit 10
	else
		# return code 2 is ok
		echo ""
		echo -e "${cyan}Terraform apply:                     succeeded ($return_value)$reset_formatting"
		echo ""
		return_value=0
	fi
fi

if [ -f apply_output.json ]; then
	errors_occurred=$(jq 'select(."@level" == "error") | length' apply_output.json)

	if [[ -n $errors_occurred ]]; then
		return_value=10
		if [ -n "${approve}" ]; then

			# shellcheck disable=SC2086
			if ! ImportAndReRunApply "apply_output.json" "${terraform_module_directory}" $allImportParameters $allParameters; then
				return_value=$?
			fi
			if [ -f apply_output.json ]; then
				# shellcheck disable=SC2086
				if ! ImportAndReRunApply "apply_output.json" "${terraform_module_directory}" $allImportParameters $allParameters; then
					return_value=$?
				fi
			fi
			if [ -f apply_output.json ]; then
				# shellcheck disable=SC2086
				if ! ImportAndReRunApply "apply_output.json" "${terraform_module_directory}" $allImportParameters $allParameters; then
					return_value=$?
				fi
			fi
			if [ -f apply_output.json ]; then
				# shellcheck disable=SC2086
				if ! ImportAndReRunApply "apply_output.json" "${terraform_module_directory}" $allImportParameters $allParameters; then
					return_value=$?
				fi
			fi
			if [ -f apply_output.json ]; then
				# shellcheck disable=SC2086
				if ! ImportAndReRunApply "apply_output.json" "${terraform_module_directory}" $allImportParameters $allParameters; then
					return_value=$?
				fi
			fi
		else
			return_value=10
		fi
	fi
fi

echo "Terraform Apply return code:         $return_value"

if [ 0 != $return_value ]; then
	echo "#########################################################################################"
	echo "#                                                                                       #"
	echo -e "#                      $bold_red_underscore !!! Error when Creating the deployer !!! $reset_formatting                       #"
	echo "#                                                                                       #"
	echo "#########################################################################################"
	echo ""
	exit $return_value
fi

if ! terraform -chdir="${terraform_module_directory}" output | grep "No outputs"; then

	keyvault=$(terraform -chdir="${terraform_module_directory}" output deployer_kv_user_name | tr -d \")
	temp=$(echo "${keyvault}" | grep "Warning")
	if [ -z "${temp}" ]; then
		temp=$(echo "${keyvault}" | grep "Backend reinitialization required")
		if [ -z "${temp}" ]; then
			touch "${deployer_config_information}"
			printf -v val %-.20s "$keyvault"

			echo ""
			echo "#########################################################################################"
			echo "#                                                                                       #"
			echo -e "#                Keyvault to use for SPN details:$cyan $val $reset_formatting                 #"
			echo "#                                                                                       #"
			echo "#########################################################################################"
			echo ""

			save_config_var "keyvault" "${deployer_config_information}"
			TF_VAR_deployer_kv_user_arm_id=$(az resource list --name "${keyvault}" --subscription "$ARM_SUBSCRIPTION_ID" --resource-type Microsoft.KeyVault/vaults --query "[].id | [0]" -o tsv)
			export TF_VAR_deployer_kv_user_arm_id
			return_value=0
		else
			return_value=2
		fi
	fi

	sshsecret=$(terraform -chdir="${terraform_module_directory}" output -no-color -raw deployer_sshkey_secret_name | tr -d \")
	if [ -n "${sshsecret}" ]; then
		save_config_var "sshsecret" "${deployer_config_information}"
	fi

	deployer_public_ip_address=$(terraform -chdir="${terraform_module_directory}" output -no-color -raw deployer_public_ip_address | tr -d \")
	if [ -n "${deployer_public_ip_address}" ]; then
		save_config_var "deployer_public_ip_address" "${deployer_config_information}"
	fi

	deployer_random_id=$(terraform -chdir="${terraform_module_directory}" output -no-color -raw random_id | tr -d \")
	if [ -n "${deployer_random_id}" ]; then
		save_config_var "deployer_random_id" "${deployer_config_information}"
		custom_random_id="${deployer_random_id:0:3}"
		sed -i -e /"custom_random_id"/d "${var_file}"
		printf "# The parameter 'custom_random_id' can be used to control the random 3 digits at the end of the storage accounts and key vaults\ncustom_random_id=\"%s\"\n" "${custom_random_id}" >>"${var_file}"

	fi
fi

unset TF_DATA_DIR

echo "Exiting: ${SCRIPT_NAME}"

exit $return_value
