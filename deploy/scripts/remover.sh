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

if [ "$DEBUG" = true ]; then
	set -x
	set -o errexit
fi

#Internal helper functions
function showhelp {

	echo ""
	echo "#########################################################################################"
	echo "#                                                                                       #"
	echo -e "#                 $bold_red_underscore !Warning!: This script will remove deployed systems $reset_formatting                 #"
	echo "#                                                                                       #"
	echo "#   This file contains the logic to remove the different systems                        #"
	echo "#   The script expects the following exports:                                           #"
	echo "#                                                                                       #"
	echo "#      SAP_AUTOMATION_REPO_PATH (path to the repo folder (sap-automation))              #"
	echo "#      ARM_SUBSCRIPTION_ID (subscription containing the state file storage account)     #"
	echo "#      REMOTE_STATE_RG (resource group name for storage account containing state files) #"
	echo "#      REMOTE_STATE_SA (storage account for state file)                                 #"
	echo "#                                                                                       #"
	echo "#   The script will persist the parameters needed between the executions in the         #"
	echo "#   [CONFIG_REPO_PATH]/.sap_deployment_automation folder.                               #"
	echo "#                                                                                       #"
	echo "#                                                                                       #"
	echo "#   Usage: remover.sh                                                                   #"
	echo "#    -p or --parameterfile           parameter file                                     #"
	echo "#    -t or --type                    type of system to remove                           #"
	echo "#                                         valid options:                                #"
	echo "#                                           sap_deployer                                #"
	echo "#                                           sap_library                                 #"
	echo "#                                           sap_landscape                               #"
	echo "#                                           sap_system                                  #"
	echo "#    -h or --help                    Show help                                          #"
	echo "#                                                                                       #"
	echo "#   Optional parameters                                                                 #"
	echo "#                                                                                       #"
	echo "#    -o or --storageaccountname      Storage account name for state file                #"
	echo "#    -s or --state_subscription      Subscription for tfstate storage account           #"
	echo "#                                                                                       #"
	echo "#   Example:                                                                            #"
	echo "#                                                                                       #"
	echo "#   [REPO-ROOT]deploy/scripts/remover.sh \                                              #"
	echo "#      --parameterfile DEV-WEEU-SAP01-X00.tfvars \                                      #"
	echo "#      --type sap_system                                                                #"
	echo "#                                                                                       #"
	echo "#########################################################################################"
}

#process inputs - may need to check the option i for auto approve as it is not used
INPUT_ARGUMENTS=$(getopt -n remover -o p:o:t:s:d:l:ahi --longoptions type:,parameterfile:,storageaccountname:,state_subscription:,deployer_tfstate_key:,landscape_tfstate_key:,ado,auto-approve,help -- "$@")
VALID_ARGUMENTS=$?

if [ "$VALID_ARGUMENTS" != "0" ]; then
	showhelp
fi

called_from_ado=0
eval set -- "$INPUT_ARGUMENTS"
while :; do
	case "$1" in
	-p | --parameterfile)
		parameterfile="$2"
		shift 2
		;;
	-o | --storageaccountname)
		REMOTE_STATE_SA="$2"
		shift 2
		;;
	-s | --state_subscription)
		STATE_SUBSCRIPTION="$2"
		shift 2
		;;
	-t | --type)
		deployment_system="$2"
		shift 2
		;;
	-d | --deployer_tfstate_key)
		deployer_tfstate_key="$2"
		CONTROL_PLANE_NAME=$(echo "$deployer_tfstate_key" | cut -d"-" -f1-3)
		TF_VAR_control_plane_name="$CONTROL_PLANE_NAME"
		export TF_VAR_control_plane_name
		shift 2
		;;
	-l | --landscape_tfstate_key)
		landscape_tfstate_key="$2"
		WORKLOAD_ZONE_NAME=$(echo "$landscape_tfstate_key" | cut -d"-" -f1-3)
		TF_VAR_workload_zone_name="$WORKLOAD_ZONE_NAME"
		export TF_VAR_workload_zone_name
		shift 2
		;;
	-i | --auto-approve)
		approve="--auto-approve"
		shift
		;;
	-a | --ado)
		called_from_ado=1
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

#variables
tfstate_resource_id=""
tfstate_parameter=""

deployer_tfstate_key_parameter=""
landscape_tfstate_key_parameter=""

# unused variables
#show_help=false
#deployer_tfstate_key_exists=false
#landscape_tfstate_key_exists=false
echo "parameterfile:                       $parameterfile"

working_directory=$(pwd)

parameterfile_path=$(realpath "${parameterfile}")
parameterfile_name=$(basename "${parameterfile_path}")
parameterfile_dirname=$(dirname "${parameterfile_path}")

#Provide a way to limit the number of parallel tasks for Terraform
if [[ -n "$TF_PARALLELLISM" ]]; then
	parallelism="$TF_PARALLELLISM"
else
	parallelism=3
fi

if [ "${parameterfile_dirname}" != "${working_directory}" ]; then
	echo ""
	echo "#########################################################################################"
	echo "#                                                                                       #"
	echo -e "#  $bold_red Please run this command from the folder containing the parameter file $reset_formatting              #"
	echo "#                                                                                       #"
	echo "#########################################################################################"
	exit 3
fi

if [ ! -f "${parameterfile}" ]; then
	printf -v val %-35.35s "$parameterfile"
	echo ""
	echo "#########################################################################################"
	echo "#                                                                                       #"
	echo -e "#                 $bold_red  Parameter file does not exist: ${val} $reset_formatting #"
	echo "#                                                                                       #"
	echo "#########################################################################################"
	exit 2 #No such file or directory
fi

if [ -z "${deployment_system}" ]; then
	printf -v val %-40.40s "$deployment_system"
	echo "#########################################################################################"
	echo "#                                                                                       #"
	echo -e "# $bold_red Incorrect system deployment type specified: ${val} $reset_formatting #"
	echo "#                                                                                       #"
	echo "#     Valid options are:                                                                #"
	echo "#       sap_deployer                                                                    #"
	echo "#       sap_library                                                                     #"
	echo "#       sap_landscape                                                                   #"
	echo "#       sap_system                                                                      #"
	echo "#                                                                                       #"
	echo "#########################################################################################"
	echo ""
	exit 64 #script usage wrong
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
validate_key_parameters "$parameterfile_name"
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

this_ip=$(curl -s ipinfo.io/ip) >/dev/null 2>&1

this_ip=$(curl -s ipinfo.io/ip) >/dev/null 2>&1
export TF_VAR_Agent_IP=$this_ip
echo "Agent IP:                            $this_ip"

automation_config_directory=$CONFIG_REPO_PATH/.sap_deployment_automation
generic_config_information="${automation_config_directory}"/config

system_config_information="${automation_config_directory}/${environment}${region_code}"

if [ "${deployment_system}" == sap_landscape ]; then
	load_config_vars "$parameterfile_name" "network_logical_name"
	network_logical_name=$(echo "${network_logical_name}" | tr "[:lower:]" "[:upper:]" | tr -d ' \r\n')

	system_config_information="${automation_config_directory}/${environment}${region_code}${network_logical_name}"
fi

if [ "${deployment_system}" == sap_system ]; then
	load_config_vars "$parameterfile_name" "network_logical_name"
	network_logical_name=$(echo "${network_logical_name}" | tr "[:lower:]" "[:upper:]" | tr -d ' \r\n')

	system_config_information="${automation_config_directory}/${environment}${region_code}${network_logical_name}"
fi

load_config_vars "${system_config_information}" "STATE_SUBSCRIPTION"

load_config_vars "${system_config_information}" "keyvault"
TF_VAR_deployer_kv_user_arm_id=$(az graph query -q "Resources | join kind=leftouter (ResourceContainers | where type=='microsoft.resources/subscriptions' | project subscription=name, subscriptionId) on subscriptionId | where name == '$keyvault' | project id, name, subscription" --query data[0].id --output tsv)
export TF_VAR_deployer_kv_user_arm_id

export TF_VAR_spn_keyvault_id="${TF_VAR_deployer_kv_user_arm_id}"

echo "Configuration file:                  $system_config_information"
echo "Deployment region:                   $region"
echo "Deployment region code:              $region_code"
echo "Working_directory:                   $working_directory"

key=$(echo "${parameterfile_name}" | cut -d. -f1)

if [ -f terraform.tfvars ]; then
	extra_vars="-var-file=${param_dirname}/terraform.tfvars"
else
	unset extra_vars
fi

echo ""
echo "Terraform details"
echo "-------------------------------------------------------------------------"
echo "Subscription:                        ${STATE_SUBSCRIPTION}"
echo "Storage Account:                     ${REMOTE_STATE_SA}"
echo "Resource Group:                      ${REMOTE_STATE_RG}"
echo "State file:                          ${key}.terraform.tfstate"
echo "Target subscription:                 ${ARM_SUBSCRIPTION_ID}"
echo "Deployer State file:                 ${deployer_tfstate_key}"
echo "Landscape State file:                ${landscape_tfstate_key}"

export TF_VAR_subscription_id="${ARM_SUBSCRIPTION_ID}"
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

init "${automation_config_directory}" "${generic_config_information}" "${system_config_information}"
var_file="${parameterfile_dirname}"/"${parameterfile}"
if [ -z "$REMOTE_STATE_SA" ]; then
	load_config_vars "${system_config_information}" "REMOTE_STATE_SA"
	load_config_vars "${system_config_information}" "REMOTE_STATE_RG"
	load_config_vars "${system_config_information}" "tfstate_resource_id"
	load_config_vars "${system_config_information}" "STATE_SUBSCRIPTION"
else
	save_config_vars "${system_config_information}" REMOTE_STATE_SA
	getAndStoreTerraformStateStorageAccountDetails "${REMOTE_STATE_SA}" "${system_config_information}"
	load_config_vars "${system_config_information}" "STATE_SUBSCRIPTION"
	load_config_vars "${system_config_information}" "REMOTE_STATE_RG"
	load_config_vars "${system_config_information}" "tfstate_resource_id"
fi

load_config_vars "${system_config_information}" "deployer_tfstate_key"
load_config_vars "${system_config_information}" "landscape_tfstate_key"
load_config_vars "${system_config_information}" "ARM_SUBSCRIPTION_ID"

deployer_tfstate_key_parameter=''
if [ "${deployment_system}" != sap_deployer ]; then
	deployer_tfstate_key_parameter=" -var deployer_tfstate_key=${deployer_tfstate_key} "
	echo "Deployer State File:                 ${deployer_tfstate_key}"
fi

landscape_tfstate_key_parameter=''
if [ "${deployment_system}" == sap_system ]; then
	landscape_tfstate_key_parameter=" -var landscape_tfstate_key=${landscape_tfstate_key} "
	echo "Landscape State File:                ${landscape_tfstate_key}"
fi

tfstate_parameter=" -var tfstate_resource_id=${tfstate_resource_id} "

#setting the user environment variables
# set_executing_user_environment_variables "none"

if [ -n "${STATE_SUBSCRIPTION}" ]; then
	az account set --sub "${STATE_SUBSCRIPTION}"
fi

export TF_DATA_DIR="${parameterfile_dirname}"/.terraform

terraform_module_directory="${SAP_AUTOMATION_REPO_PATH}"/deploy/terraform/run/"${deployment_system}"/

if [ ! -d "${terraform_module_directory}" ]; then
	printf -v val %-40.40s "$deployment_system"
	echo "#########################################################################################"
	echo "#                                                                                       #"
	echo -e "#  $bold_red Incorrect system deployment type specified: ${val} $reset_formatting#"
	echo "#                                                                                       #"
	echo "#     Valid options are:                                                                #"
	echo "#       sap_deployer                                                                    #"
	echo "#       sap_library                                                                     #"
	echo "#       sap_landscape                                                                   #"
	echo "#       sap_system                                                                      #"
	echo "#                                                                                       #"
	echo "#########################################################################################"
	echo ""
	exit 66 #cannot open input file/folder
fi

#ok_to_proceed=false
#new_deployment=false

if [ -f backend.tf ]; then
	rm backend.tf
fi

if [ -n "${REMOTE_STATE_SA}" ]; then
	useSAS=$(az storage account show --name "${REMOTE_STATE_SA}" --query allowSharedKeyAccess --subscription "${STATE_SUBSCRIPTION}" --out tsv)

	if [ "$useSAS" = "true" ]; then
		echo "Storage Account Authentication:      Key"
		export ARM_USE_AZUREAD=false
	else
		echo "Storage Account Authentication:      Entra ID"
		export ARM_USE_AZUREAD=true
	fi
fi

cd "${param_dirname}" || exit
pwd
echo ""
echo "#########################################################################################"
echo "#                                                                                       #"
echo -e "#                            $cyan Running Terraform init $reset_formatting                                   #"
echo "#                                                                                       #"
echo "#########################################################################################"
echo ""

if [ -f .terraform/terraform.tfstate ]; then

	azure_backend=$(grep "\"type\": \"azurerm\"" .terraform/terraform.tfstate || true)
	if [ -n "${azure_backend}" ]; then
		if terraform -chdir="${terraform_module_directory}" init -upgrade=true; then
			echo ""
			echo -e "${cyan}Terraform init:                        succeeded$reset_formatting"
			echo ""
		else
			echo ""
			echo -e "${bold_red}Terraform init:                        failed$reset_formatting"
			echo ""
			exit 1
		fi
	else
		STATE_SUBSCRIPTION=$(grep -m1 "subscription_id" "${param_dirname}/.terraform/terraform.tfstate" | cut -d ':' -f2 | tr -d '", \r' | xargs || true)
		REMOTE_STATE_SA=$(grep -m1 "storage_account_name" "${param_dirname}/.terraform/terraform.tfstate" | cut -d ':' -f2 | tr -d ' ",\r' | xargs || true)
		REMOTE_STATE_RG=$(grep -m1 "resource_group_name" "${param_dirname}/.terraform/terraform.tfstate" | cut -d ':' -f2 | tr -d ' ",\r' | xargs || true)

		if terraform -chdir="${terraform_module_directory}" init -reconfigure \
			--backend-config "subscription_id=${STATE_SUBSCRIPTION}" \
			--backend-config "resource_group_name=${REMOTE_STATE_RG}" \
			--backend-config "storage_account_name=${REMOTE_STATE_SA}" \
			--backend-config "container_name=tfstate" \
			--backend-config "key=${key}.terraform.tfstate"; then
			echo ""
			echo -e "${cyan}Terraform init:                        succeeded$reset_formatting"
			echo ""
		else
			echo ""
			echo -e "${bold_red}Terraform init:                        failed$reset_formatting"
			echo ""
			exit 1
		fi
	fi
else
	if terraform -chdir="${terraform_module_directory}" init -reconfigure \
		--backend-config "subscription_id=${STATE_SUBSCRIPTION}" \
		--backend-config "resource_group_name=${REMOTE_STATE_RG}" \
		--backend-config "storage_account_name=${REMOTE_STATE_SA}" \
		--backend-config "container_name=tfstate" \
		--backend-config "key=${key}.terraform.tfstate"; then
		echo ""
		echo -e "${cyan}Terraform init:                        succeeded$reset_formatting"
		echo ""
	else
		echo ""
		echo -e "${bold_red}Terraform init:                        failed$reset_formatting"
		echo ""
		exit 1
	fi
fi

tfstate_resource_id=$(az storage account show --name "${REMOTE_STATE_SA}" --query id --subscription "${STATE_SUBSCRIPTION}" --out tsv)
export TF_VAR_tfstate_resource_id="${tfstate_resource_id}"

created_resource_group_id=$(terraform -chdir="${terraform_module_directory}" output -no-color -raw created_resource_group_id | tr -d \")
created_resource_group_id_length="${#created_resource_group_id}"
created_resource_group_subscription_id=$(terraform -chdir="${terraform_module_directory}" output -no-color -raw created_resource_group_subscription_id | tr -d \")
created_resource_group_subscription_id_length="${#created_resource_group_subscription_id}"

if [ "${created_resource_group_id_length}" -eq 0 ] && [ "${created_resource_group_subscription_id_length}" -eq 0 ]; then
	resource_group_exist=$(az group exists --name "${created_resource_group_id}" --subscription "${created_resource_group_subscription_id}")
else
	resource_group_exist=true
fi

if [ "$resource_group_exist" ]; then
	echo ""
	echo "#########################################################################################"
	echo "#                                                                                       #"
	echo -e "#                            $cyan Running Terraform destroy$reset_formatting                                 #"
	echo "#                                                                                       #"
	echo "#########################################################################################"
	echo ""

	if [ "$deployment_system" == "sap_deployer" ]; then
		terraform -chdir="${terraform_bootstrap_directory}" refresh -var-file="${var_file}" \
			"$deployer_tfstate_key_parameter"

		echo -e "#$cyan processing $deployment_system removal as defined in $parameterfile_name $reset_formatting"
		terraform -chdir="${terraform_module_directory}" destroy -refresh=false -var-file="${var_file}" \
			"$deployer_tfstate_key_parameter"

	elif [ "$deployment_system" == "sap_library" ]; then
		echo -e "#$cyan processing $deployment_system removal as defined in $parameterfile_name $reset_formatting"

		terraform_bootstrap_directory="${SAP_AUTOMATION_REPO_PATH}/deploy/terraform/bootstrap/${deployment_system}/"
		if [ ! -d "${terraform_bootstrap_directory}" ]; then
			printf -v val %-40.40s "$terraform_bootstrap_directory"
			echo "#########################################################################################"
			echo "#                                                                                       #"
			echo -e "#  $bold_red Unable to find bootstrap directory: ${val}$reset_formatting#"
			echo "#                                                                                       #"
			echo "#########################################################################################"
			echo ""
			exit 66 #cannot open input file/folder
		fi
		terraform -chdir="${terraform_bootstrap_directory}" init -upgrade=true -force-copy

		terraform -chdir="${terraform_bootstrap_directory}" refresh -var-file="${var_file}" \
			"$deployer_tfstate_key_parameter"

		terraform -chdir="${terraform_bootstrap_directory}" destroy -refresh=false -var-file="${var_file}" "${approve}" -var use_deployer=false \
			"$deployer_tfstate_key_parameter"
	elif [ "$deployment_system" == "sap_landscape" ]; then

		echo -e "#$cyan processing $deployment_system removal as defined in $parameterfile_name $reset_formatting"
		echo "Calling destroy with:          -var-file=${var_file} $approve $tfstate_parameter deployer_tfstate_key_parameter"

		allParameters=$(printf " -var-file=%s %s %s  %s " "${var_file}" "${extra_vars}" "${tfstate_parameter}" "${deployer_tfstate_key_parameter}")

		# moduleID="module.sap_landscape.azurerm_key_vault_secret.sid_ppk"
		# if terraform -chdir="${terraform_module_directory}" state list -id="${moduleID}"; then
		# 	if terraform -chdir="${terraform_module_directory}" state rm "${moduleID}"; then
		# 		echo "Secret 'sid_ppk' removed from state"
		# 	fi
		# fi

		# moduleID="module.sap_landscape.azurerm_key_vault_secret.sid_pk"
		# if terraform -chdir="${terraform_module_directory}" state list -id="${moduleID}"; then
		# 	if terraform -chdir="${terraform_module_directory}" state rm "${moduleID}"; then
		# 		echo "Secret 'sid_pk' removed from state"
		# 	fi
		# fi

		# if terraform -chdir="${terraform_module_directory}" state list -id="${moduleID}"; then
		# 	moduleID="module.sap_landscape.azurerm_key_vault_secret.sid_username"
		# 	if terraform -chdir="${terraform_module_directory}" state rm "${moduleID}"; then
		# 		echo "Secret 'sid_username' removed from state"
		# 	fi
		# fi

		# moduleID="module.sap_landscape.azurerm_key_vault_secret.sid_password"
		# if terraform -chdir="${terraform_module_directory}" state list -id="${moduleID}"; then
		# 	if terraform -chdir="${terraform_module_directory}" state rm "${moduleID}"; then
		# 		echo "Secret 'sid_password' removed from state"
		# 	fi
		# fi

		# moduleID="module.sap_landscape.azurerm_key_vault_secret.witness_access_key"
		# if terraform -chdir="${terraform_module_directory}" state list -id="${moduleID}"; then
		# 	if terraform -chdir="${terraform_module_directory}" state rm "${moduleID}"; then
		# 		echo "Secret 'witness_access_key' removed from state"
		# 	fi
		# fi

		# moduleID="module.sap_landscape.azurerm_key_vault_secret.deployer_keyvault_user_name"
		# if terraform -chdir="${terraform_module_directory}" state list -id="${moduleID}"; then
		# 	if terraform -chdir="${terraform_module_directory}" state rm "${moduleID}"; then
		# 		echo "Secret 'deployer_keyvault_user_name' removed from state"
		# 	fi
		# fi

		# moduleID="module.sap_landscape.azurerm_key_vault_secret.witness_name"
		# if terraform -chdir="${terraform_module_directory}" state list -id="${moduleID}"; then
		# 	if terraform -chdir="${terraform_module_directory}" state rm "${moduleID}"; then
		# 		echo "Secret 'witness_name' removed from state"
		# 	fi
		# fi

		# moduleID="module.sap_landscape.azurerm_key_vault_secret.cp_subscription_id"
		# if terraform -chdir="${terraform_module_directory}" state list -id="${moduleID}"; then
		# 	if terraform -chdir="${terraform_module_directory}" state rm "${moduleID}"; then
		# 		echo "Secret 'cp_subscription_id' removed from state"
		# 	fi
		# fi
		# moduleID="module.sap_landscape.data.azurerm_key_vault_secret.cp_subscription_id"
		# if terraform -chdir="${terraform_module_directory}" state list -id="${moduleID}"; then
		# 	if terraform -chdir="${terraform_module_directory}" state rm "${moduleID}"; then
		# 		echo "Secret 'data.cp_subscription_id' removed from state"
		# 	fi
		# fi
		if [ -n "${approve}" ]; then
			# shellcheck disable=SC2086
			if terraform -chdir="${terraform_module_directory}" destroy $allParameters "$approve" -no-color -json -parallelism="$parallelism" | tee -a destroy_output.json; then
				return_value=$?
			else
				return_value=${PIPESTATUS[0]}
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
				return_value=$?
			else
				return_value=$?
			fi
		fi
		if [ 0 -eq $return_value ]; then
			echo ""
			echo -e "${cyan}Terraform destroy:                     succeeded$reset_formatting"
			echo ""
		else
			echo ""
			echo -e "${bold_red}Terraform destroy:                     failed$reset_formatting"
			echo ""
			exit 1
		fi

	else

		echo -e "#$cyan processing $deployment_system removal as defined in $parameterfile_name $reset_formatting"
		echo "Calling destroy with:          -var-file=${var_file} $approve $tfstate_parameter $landscape_tfstate_key_parameter $deployer_tfstate_key_parameter"

		allParameters=$(printf " -var-file=%s %s %s %s %s " "${var_file}" "${extra_vars}" "${tfstate_parameter}" "${landscape_tfstate_key_parameter}" "${deployer_tfstate_key_parameter}")

		if [ -n "${approve}" ]; then
			# shellcheck disable=SC2086
			if terraform -chdir="${terraform_module_directory}" destroy $allParameters "$approve" -no-color -json -parallelism="$parallelism" | tee -a destroy_output.json; then
				return_value=$?
				echo ""
				echo -e "${cyan}Terraform destroy:                     succeeded$reset_formatting"
				echo ""
			else
				return_value=$?
				echo ""
				echo -e "${bold_red}Terraform destroy:                     failed$reset_formatting"
				echo ""
				exit 1
			fi
		else
			# shellcheck disable=SC2086
			if terraform -chdir="${terraform_module_directory}" destroy $allParameters -parallelism="$parallelism"; then
				return_value=$?
				echo ""
				echo -e "${cyan}Terraform destroy:                     succeeded$reset_formatting"
				echo ""
			else
				return_value=$?
				echo ""
				echo -e "${bold_red}Terraform destroy:                     failed$reset_formatting"
				echo ""
				exit 1
			fi
		fi

		if [ -f destroy_output.json ]; then
			errors_occurred=$(jq 'select(."@level" == "error") | length' destroy_output.json)

			if [[ -n $errors_occurred ]]; then
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

else
	return_value=0
fi

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

# if [ "${deployment_system}" == sap_system ]; then

#     echo "#########################################################################################"
#     echo "#                                                                                       #"
#     echo -e "#                            $cyan Clean up load balancer IP $reset_formatting        #"
#     echo "#                                                                                       #"
#     echo "#########################################################################################"

#     database_loadbalancer_public_ip_address=$(terraform -chdir="${terraform_module_directory}" output -no-color database_loadbalancer_ip | tr -d "\n"  | tr -d "("  | tr -d ")" | tr -d " ")
#     database_loadbalancer_public_ip_address=$(echo ${database_loadbalancer_public_ip_address/tolist/})
#     database_loadbalancer_public_ip_address=$(echo ${database_loadbalancer_public_ip_address/,]/]})
#     echo "Database Load Balancer IP: $database_loadbalancer_public_ip_address"

#     load_config_vars "${parameterfile_name}" "database_loadbalancer_ips"
#     database_loadbalancer_ips=$(echo ${database_loadbalancer_ips} | xargs)

#     if [[ "${database_loadbalancer_public_ip_address}" != "${database_loadbalancer_ips}" ]];
#     then
#       database_loadbalancer_ips=${database_loadbalancer_public_ip_address}
#       save_config_var "database_loadbalancer_ips" "${parameterfile_name}"
#     fi

#     scs_loadbalancer_public_ip_address=$(terraform -chdir="${terraform_module_directory}" output -no-color scs_loadbalancer_ips | tr -d "\n"  | tr -d "("  | tr -d ")" | tr -d " ")
#     scs_loadbalancer_public_ip_address=$(echo ${scs_loadbalancer_public_ip_address/tolist/})
#     scs_loadbalancer_public_ip_address=$(echo ${scs_loadbalancer_public_ip_address/,]/]})
#     echo "SCS Load Balancer IP: $scs_loadbalancer_public_ip_address"

#     load_config_vars "${parameterfile_name}" "scs_server_loadbalancer_ips"
#     scs_server_loadbalancer_ips=$(echo ${scs_server_loadbalancer_ips} | xargs)

#     if [[ "${scs_loadbalancer_public_ip_address}" != "${scs_server_loadbalancer_ips}" ]];
#     then
#       scs_server_loadbalancer_ips=${scs_loadbalancer_public_ip_address}
#       save_config_var "scs_server_loadbalancer_ips" "${parameterfile_name}"
#     fi
# fi

unset TF_DATA_DIR

exit "$return_value"
