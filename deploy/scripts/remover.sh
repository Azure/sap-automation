#!/bin/bash

# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

#error codes include those from /usr/include/sysexits.h

#colors for terminal
bold_red="\e[1;31m"
green="\e[1;32m"
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

if [ "$DEBUG" = True ]; then
	set -x
	set -o errexit
fi

SCRIPT_NAME="$(basename "$0")"

echo "Entering: ${SCRIPT_NAME}"

banner_title="Remover"

detect_platform

#process inputs - may need to check the option i for auto approve as it is not used
INPUT_ARGUMENTS=$(getopt -n remover -o p:o:t:s:d:l:ahi --longoptions type:,parameterfile:,storageaccountname:,state_subscription:,deployer_tfstate_key:,landscape_tfstate_key:,control_plane_name:,ado,auto-approve,help -- "$@")
VALID_ARGUMENTS=$?

if [ "$VALID_ARGUMENTS" != "0" ]; then
	showhelp_remover
fi

called_from_ado=0
eval set -- "$INPUT_ARGUMENTS"
while :; do
	case "$1" in
	-p | --parameterfile)
		parameterfile="$2"
		shift 2
		;;
	--control_plane_name)
		CONTROL_PLANE_NAME="$2"
		CONTROL_PLANE_NAME=$(echo "${CONTROL_PLANE_NAME}" | tr "[:lower:]" "[:upper:]")
		TF_VAR_control_plane_name="$CONTROL_PLANE_NAME"
		TF_VAR_deployer_tfstate_key="${CONTROL_PLANE_NAME}-INFRASTRUCTURE.terraform.tfstate"
		
		export TF_VAR_deployer_tfstate_key
		export TF_VAR_control_plane_name
		shift 2
		;;
	-o | --storageaccountname)
		REMOTE_STATE_SA="$2"
		export REMOTE_STATE_SA
		getAndStoreTerraformStateStorageAccountDetails "${REMOTE_STATE_SA}" ""
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
			CONTROL_PLANE_NAME=$(echo "$deployer_tfstate_key" | cut -d'-' -f1-3)
			CONTROL_PLANE_NAME=$(echo "${CONTROL_PLANE_NAME}" | tr "[:lower:]" "[:upper:]")
			TF_VAR_control_plane_name="$CONTROL_PLANE_NAME"
			TF_VAR_deployer_tfstate_key="${deployer_tfstate_key}"
			export TF_VAR_control_plane_name
			export TF_VAR_deployer_tfstate_key
			shift 2
		;;
	-l | --landscape_tfstate_key)
		landscape_tfstate_key="$2"
		WORKLOAD_ZONE_NAME=$(echo "$landscape_tfstate_key" | cut -d"-" -f1-3)
		TF_VAR_workload_zone_name="$WORKLOAD_ZONE_NAME"
		export TF_VAR_workload_zone_name
		TF_VAR_landscape_tfstate_key="${landscape_tfstate_key}"
		export TF_VAR_landscape_tfstate_key

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
		showhelp_remover
		exit 3
		;;
	--)
		shift
		break
		;;
	esac
done

#variables
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
    print_banner "$banner_title" "Please run the remover script from the folder containing the parameter file" "error"
	exit 3
fi

if [ ! -f "${parameterfile}" ]; then
	printf -v val %-35.35s "$parameterfile"
	print_banner "$banner_title" "Parameter file does not exist: ${val}" "error"
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
region=""
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
export TF_VAR_Agent_IP=$this_ip
echo "Agent IP:                            $this_ip"

automation_config_directory="$CONFIG_REPO_PATH/.sap_deployment_automation"
generic_environment_file_name="${automation_config_directory}"/config

if [ "${deployment_system}" == "sap_system" ] || [ "${deployment_system}" == "sap_landscape" ]; then
	WORKLOAD_ZONE_NAME=$(echo "$parameterfile" | cut -d'-' -f1-3)
	TF_VAR_workload_zone_name="$WORKLOAD_ZONE_NAME"
	export TF_VAR_workload_zone_name

	landscape_tfstate_key="${WORKLOAD_ZONE_NAME}-INFRASTRUCTURE.terraform.tfstate"
	TF_VAR_landscape_tfstate_key="${landscape_tfstate_key}"
	export TF_VAR_landscape_tfstate_key
	export landscape_tfstate_key

	environment=$(echo "$WORKLOAD_ZONE_NAME" | awk -F'-' '{print $1}' | xargs)
	region_code=$(echo "$WORKLOAD_ZONE_NAME" | awk -F'-' '{print $2}' | xargs)
	network_logical_name=$(echo "$WORKLOAD_ZONE_NAME" | awk -F'-' '{print $3}' | xargs)

elif [ "${deployment_system}" == "sap_deployer" ]; then
	CONTROL_PLANE_NAME=$(echo "$parameterfile" | cut -d'-' -f1-3)
	deployer_tfstate_key="${CONTROL_PLANE_NAME}-INFRASTRUCTURE.terraform.tfstate"
	export deployer_tfstate_key
	environment=$(echo "$CONTROL_PLANE_NAME" | awk -F'-' '{print $1}' | xargs)
	region_code=$(echo "$CONTROL_PLANE_NAME" | awk -F'-' '{print $2}' | xargs)
	network_logical_name=$(echo "$CONTROL_PLANE_NAME" | awk -F'-' '{print $3}' | xargs)
	TF_VAR_deployer_tfstate_key="${deployer_tfstate_key}"
	export TF_VAR_deployer_tfstate_key

elif [ "${deployment_system}" == "sap_library" ]; then
	environment=$(echo "$CONTROL_PLANE_NAME" | awk -F'-' '{print $1}' | xargs)
	region_code=$(echo "$CONTROL_PLANE_NAME" | awk -F'-' '{print $2}' | xargs)
	network_logical_name=$(echo "$CONTROL_PLANE_NAME" | awk -F'-' '{print $3}' | xargs)
fi

if [ -v SYSTEM_CONFIGURATION_FILE ]; then
	system_environment_file_name=$SYSTEM_CONFIGURATION_FILE
else
	system_environment_file_name=$(get_configuration_file "$automation_config_directory" "$environment" "$region_code" "$network_logical_name")
fi

load_config_vars "${system_environment_file_name}" "STATE_SUBSCRIPTION" "deployer_tfstate_key" "keyvault" "REMOTE_STATE_SA" "REMOTE_STATE_RG" "tfstate_resource_id"
TF_VAR_deployer_kv_user_arm_id=$(az graph query -q "Resources | join kind=leftouter (ResourceContainers | where type=='microsoft.resources/subscriptions' | project subscription=name, subscriptionId) on subscriptionId | where name == '$keyvault' | project id, name, subscription" --query data[0].id --output tsv)
export TF_VAR_deployer_kv_user_arm_id

export TF_VAR_spn_keyvault_id="${TF_VAR_deployer_kv_user_arm_id}"

echo "Configuration file:                  $system_environment_file_name"
echo "Deployment region:                   $region"
echo "Deployment region code:              $region_code"
echo "Working_directory:                   $working_directory"

key=$(echo "${parameterfile_name}" | cut -d. -f1)

echo ""
echo -e "${green}Terraform details:"
echo -e "-------------------------------------------------------------------------${reset_formatting}"
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

init "${automation_config_directory}" "${generic_environment_file_name}" "${system_environment_file_name}"
var_file="${parameterfile_dirname}"/"${parameterfile}"
if [ -z "$REMOTE_STATE_SA" ]; then
	load_config_vars "${system_environment_file_name}" "REMOTE_STATE_SA" "REMOTE_STATE_RG" "tfstate_resource_id" "STATE_SUBSCRIPTION"
fi
getAndStoreTerraformStateStorageAccountDetails "${REMOTE_STATE_SA}" "${system_environment_file_name}"

if [ "${deployment_system}" != sap_deployer ]; then
	echo "Deployer State File:                 ${deployer_tfstate_key}"
fi

if [ "${deployment_system}" == sap_system ]; then
	echo "Landscape State File:                ${landscape_tfstate_key}"
fi

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
		STATE_SUBSCRIPTION=$(grep -m1 "subscription_id" ".terraform/terraform.tfstate" | cut -d ':' -f2 | tr -d '", \r' | xargs || true)
		REMOTE_STATE_SA=$(grep -m1 "storage_account_name" ".terraform/terraform.tfstate" | cut -d ':' -f2 | tr -d ' ",\r' | xargs || true)
		REMOTE_STATE_RG=$(grep -m1 "resource_group_name" ".terraform/terraform.tfstate" | cut -d ':' -f2 | tr -d ' ",\r' | xargs || true)

		getAndStoreTerraformStateStorageAccountDetails "${REMOTE_STATE_SA}" "${system_environment_file_name}"
		if terraform -chdir="${terraform_module_directory}" init -upgrade=true; then
			print_banner "$banner_title" "Terraform init succeeded" "success"
		else
			print_banner "$banner_title" "Terraform init failed" "error"
			exit 1
		fi
	else

		if terraform -chdir="${terraform_module_directory}" init -reconfigure \
			--backend-config "subscription_id=${STATE_SUBSCRIPTION}" \
			--backend-config "resource_group_name=${REMOTE_STATE_RG}" \
			--backend-config "storage_account_name=${REMOTE_STATE_SA}" \
			--backend-config "container_name=tfstate" \
			--backend-config "key=${key}.terraform.tfstate"; then
			print_banner "$banner_title" "Terraform init succeeded" "success"
		else
			print_banner "$banner_title" "Terraform init failed" "error"
			exit 1
		fi
		getAndStoreTerraformStateStorageAccountDetails "${REMOTE_STATE_SA}" "${system_environment_file_name}"
	fi
else
	if terraform -chdir="${terraform_module_directory}" init -reconfigure \
		--backend-config "subscription_id=${STATE_SUBSCRIPTION}" \
		--backend-config "resource_group_name=${REMOTE_STATE_RG}" \
		--backend-config "storage_account_name=${REMOTE_STATE_SA}" \
		--backend-config "container_name=tfstate" \
		--backend-config "key=${key}.terraform.tfstate"; then
		print_banner "$banner_title" "Terraform init succeeded" "success"
	else
		print_banner "$banner_title" "Terraform init failed" "error"
		exit 1
	fi
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

created_resource_group_id=$(terraform -chdir="${terraform_module_directory}" output -no-color -raw created_resource_group_id | tr -d \")
created_resource_group_id_length="${#created_resource_group_id}"
created_resource_group_subscription_id=$(terraform -chdir="${terraform_module_directory}" output -no-color -raw created_resource_group_subscription_id | tr -d \")
created_resource_group_subscription_id_length="${#created_resource_group_subscription_id}"

if [ "${created_resource_group_id_length}" -eq 0 ] && [ "${created_resource_group_subscription_id_length}" -eq 0 ]; then
	resource_group_exist=$(az group exists --name "${created_resource_group_id}" --subscription "${created_resource_group_subscription_id}")
else
	resource_group_exist=true
fi

allRemovalParameters=(-var-file "${parameterfile_path}")
if [ -f terraform.tfvars ]; then
	allRemovalParameters+=(-var-file terraform.tfvars)
fi

if [ "$PLATFORM" != "cli" ] || [ "$approve" == "--auto-approve" ]; then
	allRemovalParameters+=(--auto-approve)
fi

if [ "$resource_group_exist" ]; then
	print_banner "$banner_title" "Resource group exists, proceeding with destroy" "info"

	if [ "$deployment_system" == "sap_deployer" ]; then
		terraform -chdir="${terraform_bootstrap_directory}" refresh "${allRemovalParameters[@]}" 

		print_banner "$banner_title" "Processing $deployment_system removal as defined in:" "info" "$parameterfile_name"
		terraform -chdir="${terraform_module_directory}" destroy -refresh=false "${allRemovalParameters[@]}" 

	elif [ "$deployment_system" == "sap_library" ]; then
		print_banner "$banner_title" "Processing $deployment_system removal as defined in:" "info" "$parameterfile_name"

		terraform_bootstrap_directory="${SAP_AUTOMATION_REPO_PATH}/deploy/terraform/bootstrap/${deployment_system}/"
		if [ ! -d "${terraform_bootstrap_directory}" ]; then

			printf -v val %-40.40s "$terraform_bootstrap_directory"
			print_banner "$banner_title" "Unable to find bootstrap directory: ${val}" "error"
			exit 66 #cannot open input file/folder
		fi

		terraform -chdir="${terraform_bootstrap_directory}" init -upgrade=true -force-copy

		terraform -chdir="${terraform_bootstrap_directory}" refresh "${allRemovalParameters[@]}" 

		terraform -chdir="${terraform_bootstrap_directory}" destroy -refresh=false "${allRemovalParameters[@]}" -var use_deployer=false 
	elif [ "$deployment_system" == "sap_landscape" ]; then

		print_banner "$banner_title" "Processing $deployment_system removal as defined in $parameterfile_name" "info"
		echo "Calling destroy with:           ${allRemovalParameters[*]}"

		if [ -n "${approve}" ]; then
			# shellcheck disable=SC2086
			if terraform -chdir="${terraform_module_directory}" destroy "${allRemovalParameters[@]}" "$approve" -no-color -json -parallelism="$parallelism" | tee destroy_output.json; then
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
			if terraform -chdir="${terraform_module_directory}" destroy "${allRemovalParameters[@]}" -parallelism="$parallelism"; then
				return_value=$?
			else
				return_value=$?
			fi
		fi
		if [ 0 -eq "$return_value" ]; then
				print_banner "$banner_title" "Terraform destroy succeeded" "success"
		else
				print_banner "$banner_title" "Terraform destroy failed" "error"
			exit 1
		fi

	else

		echo -e "#$cyan processing $deployment_system removal as defined in $parameterfile_name $reset_formatting"
		echo "Calling destroy with:           ${allRemovalParameters[*]}"

		if [ -n "${approve}" ]; then
			# shellcheck disable=SC2086
			if terraform -chdir="${terraform_module_directory}" destroy "${allRemovalParameters[@]}" "$approve" -no-color -json -parallelism="$parallelism" | tee -a destroy_output.json; then
				return_value=$?
				print_banner "$banner_title" "Terraform destroy succeeded" "success"
			else
				return_value=$?
				print_banner "$banner_title" "Terraform destroy failed" "error"
				exit 1
			fi
		else
			# shellcheck disable=SC2086
			if terraform -chdir="${terraform_module_directory}" destroy "${allRemovalParameters[@]}" -parallelism="$parallelism"; then
				return_value=$?
				print_banner "$banner_title" "Terraform destroy succeeded" "success"
			else
				return_value=$?
				print_banner "$banner_title" "Terraform destroy failed" "error"
				exit 1
			fi
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

						report=$(echo "$string_to_report" | grep -m1 "Message=" "${var_file}" | cut -d'=' -f2- | tr -d ' ' | tr -d '"')
						if [[ -n ${report} ]]; then
							print_banner "$banner_title" "$report" "error"
							echo "##vso[task.logissue type=error]${report}"
						else
							print_banner "$banner_title" "$string_to_report" "error"
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
	sed -i /deployer_tfstate_key/d "${system_environment_file_name}"
fi

if [ "${deployment_system}" == sap_landscape ]; then
	rm "${system_environment_file_name}"
fi

if [ "${deployment_system}" == sap_library ]; then
	sed -i /REMOTE_STATE_RG/d "${system_environment_file_name}"
	sed -i /REMOTE_STATE_SA/d "${system_environment_file_name}"
	sed -i /tfstate_resource_id/d "${system_environment_file_name}"
fi

unset TF_DATA_DIR

exit "$return_value"
