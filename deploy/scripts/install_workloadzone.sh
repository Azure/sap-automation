#!/bin/bash
# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

# Ensure that the exit status of a pipeline command is non-zero if any
# stage of the pipefile has a non-zero exit status.
set -o pipefail

# set -x

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
# shellcheck disable=SC1091
source "${script_directory}/deploy_utils.sh"

#helper files
# shellcheck disable=SC1091
source "${script_directory}/helpers/script_helpers.sh"

if [ "$DEBUG" = True ]; then
	set -x
	set -o errexit
fi

force=0
called_from_ado=0
deploy_using_msi_only=0

INPUT_ARGUMENTS=$(getopt -n install_workloadzone -o p:d:e:k:o:s:c:n:t:v:aifhm --longoptions parameterfile:,deployer_tfstate_key:,deployer_environment:,subscription:,spn_id:,spn_secret:,tenant_id:,state_subscription:,keyvault:,storageaccountname:,ado,auto-approve,force,help,msi -- "$@")
VALID_ARGUMENTS=$?
if [ "$VALID_ARGUMENTS" != "0" ]; then
	showhelp
fi

eval set -- "$INPUT_ARGUMENTS"
while :; do
	case "$1" in
	-a | --ado)
		called_from_ado=1
		shift
		;;
	-c | --spn_id)
		client_id="$2"
		shift 2
		;;
	-d | --deployer_tfstate_key)
		deployer_tfstate_key="$2"
		shift 2
		;;
	-e | --deployer_environment)
		deployer_environment="$2"
		shift 2
		;;
	-f | --force)
		force=1
		shift
		;;
	-i | --auto-approve)
		approve="--auto-approve"
		shift
		;;
	-k | --state_subscription)
		STATE_SUBSCRIPTION="$2"
		shift 2
		;;
	-m | --msi)
		deploy_using_msi_only=1
		shift
		;;
	-n | --spn_secret)
		spn_secret="$2"
		shift 2
		;;
	-o | --storageaccountname)
		REMOTE_STATE_SA="$2"
		shift 2
		;;
	-p | --parameterfile)
		parameterfile="$2"
		shift 2
		;;
	-s | --subscription)
		subscription="$2"
		shift 2
		;;
	-t | --tenant_id)
		tenant_id="$2"
		shift 2
		;;
	-v | --keyvault)
		keyvault="$2"
		shift 2
		;;

	-h | --help)
		workload_zone_showhelp
		exit 3
		;;
	--)
		shift
		break
		;;
	esac
done
tfstate_resource_id=""
tfstate_parameter=""

deployer_tfstate_key_parameter=""
landscape_tfstate_key=""
landscape_tfstate_key_parameter=""

deployment_system="sap_landscape"

this_ip=$(curl -s ipinfo.io/ip) >/dev/null 2>&1

deployer_environment=$(echo "${deployer_environment}" | tr "[:lower:]" "[:upper:]")

echo "Deployer environment:                $deployer_environment"

if [ 1 == $called_from_ado ]; then
	this_ip=$(curl -s ipinfo.io/ip) >/dev/null 2>&1
	export TF_VAR_Agent_IP=$this_ip
	echo "Agent IP:                            $this_ip"

fi

workload_file_parametername=$(basename "${parameterfile}")

param_dirname=$(dirname "${parameterfile}")

if [ "$param_dirname" != '.' ]; then
	echo ""
	echo "#########################################################################################"
	echo "#                                                                                       #"
	echo -e "#  $bold_red Please run this command from the folder containing the parameter file$reset_formatting               #"
	echo "#                                                                                       #"
	echo "#########################################################################################"
	exit 3
fi

if [ ! -f "${workload_file_parametername}" ]; then
	printf -v val %-40.40s "$workload_file_parametername"
	echo ""
	echo "#########################################################################################"
	echo "#                                                                                       #"
	echo -e "#                 $bold_red_underscore Parameter file does not exist: ${val}$reset_formatting #"
	echo "#                                                                                       #"
	echo "#########################################################################################"
	exit 3
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
validate_key_parameters "$workload_file_parametername"
return_code=$?
if [ 0 != $return_code ]; then
	exit $return_code
fi

# Convert the region to the correct code
get_region_code "$region"

if [ "${region_code}" == 'UNKN' ]; then
	LOCATION_CODE_IN_FILENAME=$(echo "$workload_file_parametername" | awk -F'-' '{print $2}')
	region_code=$(echo "${LOCATION_CODE_IN_FILENAME}" | tr "[:lower:]" "[:upper:]" | xargs)
fi

echo "Region code:                         ${region_code}"

load_config_vars "$workload_file_parametername" "network_logical_name"
network_logical_name=$(echo "$workload_file_parametername" | awk -F'-' '{print $3}')

if [ -z "${network_logical_name}" ]; then
	echo "#########################################################################################"
	echo "#                                                                                       #"
	echo -e "#                         $bold_red  Incorrect parameter file. $reset_formatting                                  #"
	echo "#                                                                                       #"
	echo "#             The file must contain the network_logical_name attribute!!                #"
	echo "#                                                                                       #"
	echo "#########################################################################################"
	echo ""
	return 64 #script usage wrong
fi

key=$(echo "${workload_file_parametername}" | cut -d. -f1)
landscape_tfstate_key=${key}.terraform.tfstate

if [ -f terraform.tfvars ]; then
	extra_vars="-var-file=${param_dirname}/terraform.tfvars"
else
	unset extra_vars
fi

#Persisting the parameters across executions

automation_config_directory=$CONFIG_REPO_PATH/.sap_deployment_automation
generic_config_information="${automation_config_directory}"/config

if [ "$deployer_environment" != "$environment" ]; then
	if [ -f "${automation_config_directory}/${environment}${region_code}" ]; then
		# Add support for having multiple vnets in the same environment and zone - rename exiting file to support seamless transition
		if [ -f "${automation_config_directory}/${environment}${region_code}${network_logical_name}" ]; then
			mv "${automation_config_directory}/${environment}${region_code}" "${automation_config_directory}/${environment}${region_code}${network_logical_name}"
		fi
	fi
fi

workload_config_information="${automation_config_directory}/${environment}${region_code}${network_logical_name}"
touch "${workload_config_information}"
deployer_config_information="${automation_config_directory}/${deployer_environment}${region_code}"
save_config_vars "${workload_config_information}" \
	STATE_SUBSCRIPTION REMOTE_STATE_SA subscription

if [ "${force}" == 1 ]; then
	if [ -f "${workload_config_information}" ]; then
		rm "${workload_config_information}"
	fi
	rm -Rf .terraform terraform.tfstate*
fi

echo ""
echo "Configuration file:                  $workload_config_information"
echo "Deployment region:                   $region"
echo "Deployment region code:              $region_code"
echo "Deployment environment:              $deployer_environment"
echo "Deployer Keyvault:                   $keyvault"
echo "Deployer Subscription:               $STATE_SUBSCRIPTION"
echo "Remote state storage account:        $REMOTE_STATE_SA"
echo "Target Subscription:                 $subscription"

if [[ -n $STATE_SUBSCRIPTION ]]; then
	if is_valid_guid "$STATE_SUBSCRIPTION"; then

		save_config_vars "${workload_config_information}" \
			STATE_SUBSCRIPTION

		echo ""
		echo "#########################################################################################"
		echo "#                                                                                       #"
		echo -e "#       $cyan Changing the subscription to: $STATE_SUBSCRIPTION $reset_formatting            #"
		echo "#                                                                                       #"
		echo "#########################################################################################"
		echo ""
		az account set --sub "${STATE_SUBSCRIPTION}"

	else
		printf -v val %-40.40s "$STATE_SUBSCRIPTION"
		echo "#########################################################################################"
		echo "#                                                                                       #"
		echo -e "#The provided state_subscription is not valid:$bold_red ${val} $reset_formatting#"
		echo "#                                                                                       #"
		echo "#########################################################################################"
		echo "The provided subscription for the terraform storage is not valid: ${val}" >"${workload_config_information}".err
		exit 65
	fi

fi

if [ -n "$REMOTE_STATE_SA" ]; then
	getAndStoreTerraformStateStorageAccountDetails "${REMOTE_STATE_SA}" "${workload_config_information}"
fi

if [ -n "$keyvault" ]; then
	if valid_kv_name "$keyvault"; then
		save_config_var "keyvault" "${workload_config_information}"
	else
		printf -v val %-40.40s "$keyvault"
		echo "#########################################################################################"
		echo "#                                                                                       #"
		echo -e "#       The provided keyvault is not valid:$bold_red ${val} $reset_formatting  #"
		echo "#                                                                                       #"
		echo "#########################################################################################"

		echo "The provided keyvault is not valid: ${val}" >"${workload_config_information}".err
		exit 65
	fi

fi

if [ ! -f "${workload_config_information}" ]; then
	# Ask for deployer environment name and try to read the deployer state file and resource group details from the configuration file
	if [ -z "$deployer_environment" ]; then
		read -r -p "Deployer environment name: " deployer_environment
	fi

	deployer_config_information="${automation_config_directory}"/"${deployer_environment}""${region_code}"
	if [ -f "$deployer_config_information" ]; then
		if [ -z "${keyvault}" ]; then
			load_config_vars "${deployer_config_information}" "keyvault"
		fi

		load_config_vars "${deployer_config_information}" "REMOTE_STATE_RG"
		if [ -z "${REMOTE_STATE_SA}" ]; then
			load_config_vars "${deployer_config_information}" "REMOTE_STATE_SA"
		fi
		load_config_vars "${deployer_config_information}" "tfstate_resource_id"
		load_config_vars "${deployer_config_information}" "deployer_tfstate_key"

		save_config_vars "${workload_config_information}" \
			keyvault \
			subscription \
			deployer_tfstate_key \
			tfstate_resource_id \
			REMOTE_STATE_SA \
			REMOTE_STATE_RG
	fi
fi

if [ -z "$tfstate_resource_id" ]; then
	echo "No tfstate_resource_id"
	if [ -n "$deployer_environment" ]; then
		deployer_config_information="${automation_config_directory}"/"${deployer_environment}""${region_code}"
		echo "Deployer config file:                $deployer_config_information"
		if [ -f "$deployer_config_information" ]; then
			load_config_vars "${deployer_config_information}" "keyvault"
			load_config_vars "${deployer_config_information}" "REMOTE_STATE_RG"
			load_config_vars "${deployer_config_information}" "REMOTE_STATE_SA"
			load_config_vars "${deployer_config_information}" "tfstate_resource_id"
			load_config_vars "${deployer_config_information}" "deployer_tfstate_key"

			save_config_vars "${workload_config_information}" \
				tfstate_resource_id

			save_config_vars "${workload_config_information}" \
				keyvault \
				subscription \
				deployer_tfstate_key \
				REMOTE_STATE_SA \
				REMOTE_STATE_RG
		fi
	fi
else

	echo "Terraform Storage Account Id:        $tfstate_resource_id"

	save_config_vars "${workload_config_information}" \
		tfstate_resource_id
fi

echo ""
init "${automation_config_directory}" "${generic_config_information}" "${workload_config_information}"

param_dirname=$(pwd)
var_file="${param_dirname}"/"${parameterfile}"
export TF_DATA_DIR="${param_dirname}/.terraform"

extra_vars=""

if [ -f terraform.tfvars ]; then
	extra_vars=" -var-file=${param_dirname}/terraform.tfvars "
fi

if [ -n "$subscription" ]; then
	if is_valid_guid "$subscription"; then
		echo ""
		export ARM_SUBSCRIPTION_ID="${subscription}"
	else
		printf -v val %-40.40s "$subscription"
		echo "#########################################################################################"
		echo "#                                                                                       #"
		echo -e "#   The provided subscription is not valid:$bold_red ${val} $reset_formatting#   "
		echo "#                                                                                       #"
		echo "#########################################################################################"

		echo "The provided subscription is not valid: ${val}" >"${workload_config_information}".err

		exit 65
	fi
fi
if [ 0 = "${deploy_using_msi_only:-}" ]; then
	if [ -n "$client_id" ]; then
		if is_valid_guid "$client_id"; then
			echo ""
		else
			printf -v val %-40.40s "$client_id"
			echo "#########################################################################################"
			echo "#                                                                                       #"
			echo -e "#         The provided spn_id is not valid:$bold_red ${val} $reset_formatting   #"
			echo "#                                                                                       #"
			echo "#########################################################################################"
			exit 65
		fi
	fi

	if [ -n "$tenant_id" ]; then
		if is_valid_guid "$tenant_id"; then
			echo ""
		else
			printf -v val %-40.40s "$tenant_id"
			echo "#########################################################################################"
			echo "#                                                                                       #"
			echo -e "#       The provided tenant_id is not valid:$bold_red ${val} $reset_formatting  #"
			echo "#                                                                                       #"
			echo "#########################################################################################"
			exit 65
		fi

	fi
fi

#setting the user environment variables
if [ -n "${spn_secret}" ]; then
	set_executing_user_environment_variables "${spn_secret}"
else
	set_executing_user_environment_variables "none"
fi

if [[ -z ${REMOTE_STATE_SA} ]]; then
	load_config_vars "${workload_config_information}" "REMOTE_STATE_SA"
fi

load_config_vars "${workload_config_information}" "REMOTE_STATE_RG"
load_config_vars "${workload_config_information}" "tfstate_resource_id"

if [[ -z ${STATE_SUBSCRIPTION} ]]; then
	load_config_vars "${workload_config_information}" "STATE_SUBSCRIPTION"
fi

if [[ -z ${subscription} ]]; then
	load_config_vars "${workload_config_information}" "subscription"
fi

if [[ -z ${deployer_tfstate_key} ]]; then
	load_config_vars "${workload_config_information}" "deployer_tfstate_key"
fi

if [ -n "$tfstate_resource_id" ]; then
	REMOTE_STATE_RG=$(echo "$tfstate_resource_id" | cut -d / -f5)
	REMOTE_STATE_SA=$(echo "$tfstate_resource_id" | cut -d / -f9)
	STATE_SUBSCRIPTION=$(echo "$tfstate_resource_id" | cut -d / -f3)

	save_config_vars "${workload_config_information}" \
		REMOTE_STATE_SA \
		REMOTE_STATE_RG \
		STATE_SUBSCRIPTION
else
	getAndStoreTerraformStateStorageAccountDetails "${REMOTE_STATE_SA}" "${workload_config_information}"
fi

if [ -z "$subscription" ]; then
	subscription="${STATE_SUBSCRIPTION}"
fi

if [ -z "$REMOTE_STATE_SA" ]; then
	if [ -z "$REMOTE_STATE_RG" ]; then
		load_config_vars "${workload_config_information}" "tfstate_resource_id"
		if [ -n "${tfstate_resource_id}" ]; then
			REMOTE_STATE_RG=$(echo "$tfstate_resource_id" | cut -d / -f5)
			REMOTE_STATE_SA=$(echo "$tfstate_resource_id" | cut -d / -f9)
			STATE_SUBSCRIPTION=$(echo "$tfstate_resource_id" | cut -d / -f3)
		fi
	fi

	tfstate_parameter=" -var tfstate_resource_id=${tfstate_resource_id}"
	export TF_VAR_tfstate_resource_id=${tfstate_resource_id}
else
	if [ -z "$REMOTE_STATE_RG" ]; then
		getAndStoreTerraformStateStorageAccountDetails "${REMOTE_STATE_SA}" "${workload_config_information}"
		load_config_vars "${workload_config_information}" "STATE_SUBSCRIPTION"
		load_config_vars "${workload_config_information}" "REMOTE_STATE_RG"
		load_config_vars "${workload_config_information}" "tfstate_resource_id"
	fi
fi

useSAS=$(az storage account show --name "${REMOTE_STATE_SA}" --query allowSharedKeyAccess --subscription "${STATE_SUBSCRIPTION}" --out tsv)

if [ "$useSAS" = "true" ]; then
	echo "Storage Account authentication:       key"
	export ARM_USE_AZUREAD=false
else
	echo "Storage Account authentication:       Entra ID"
	export ARM_USE_AZUREAD=true
fi

if [ 1 = "${deploy_using_msi_only:-}" ]; then
	if [ -n "${keyvault}" ]; then
		echo "Setting the secrets"

		echo "Calling set_secrets with:             --workload --environment ${environment} --region ${region_code} --vault ${keyvault} \
    --keyvault_subscription ${STATE_SUBSCRIPTION} --subscription ${ARM_SUBSCRIPTION_ID} --msi"

		"${SAP_AUTOMATION_REPO_PATH}"/deploy/scripts/set_secrets.sh --workload --environment "${environment}" --region "${region_code}" \
			--vault "${keyvault}" --keyvault_subscription "${STATE_SUBSCRIPTION}" --subscription "${ARM_SUBSCRIPTION_ID}" --msi

		if [ -f secret.err ]; then
			error_message=$(cat secret.err)
			echo "##vso[task.logissue type=error]${error_message}"
			rm secret.err
			exit 65
		fi
	fi

else
	if [ -n "${keyvault}" ]; then
		echo "Setting the secrets"

		save_config_var "client_id" "${workload_config_information}"
		save_config_var "tenant_id" "${workload_config_information}"

		if [ -n "$spn_secret" ]; then
			fixed_allParameters=$(printf " --workload --environment %s --region %s --vault %s  --subscription %s --spn_secret ***** --keyvault_subscription %s --spn_id %s --tenant_id %s " "${environment}" "${region_code}" "${keyvault}" "${ARM_SUBSCRIPTION_ID}" "${STATE_SUBSCRIPTION}" "${client_id}" "${tenant_id}")

			echo "Calling set_secrets with:             ${fixed_allParameters}"

			"${SAP_AUTOMATION_REPO_PATH}/deploy/scripts/set_secrets.sh" --workload --environment "${environment}" --region "${region_code}" --vault "${keyvault}" --subscription "$ARM_SUBSCRIPTION_ID" --keyvault_subscription "${STATE_SUBSCRIPTION}" --spn_id "${client_id}" --tenant_id "${tenant_id}" --spn_secret "${spn_secret}"

			if [ -f secret.err ]; then
				error_message=$(cat secret.err)
				echo "##vso[task.logissue type=error]${error_message}"

				exit 65
			fi
		else
			read -r -p "Do you want to specify the Workload SPN Details Y/N? " ans
			answer=${ans^^}
			if [ "${answer}" == 'Y' ]; then
				allParameters=$(printf " --workload --environment %s --region %s --vault %s --subscription %s  --spn_id %s " "${environment}" "${region_code}" "${keyvault}" "${STATE_SUBSCRIPTION}" "${client_id}")

				"${SAP_AUTOMATION_REPO_PATH}/deploy/scripts/set_secrets.sh ${allParameters}"
				if [ $? -eq 255 ]; then
					exit $?
				fi
			fi
		fi

		if [ -f kv.log ]; then
			rm kv.log
		fi
	fi
fi

if [ -z "${deployer_tfstate_key}" ]; then
	load_config_vars "${workload_config_information}" "deployer_tfstate_key"
	if [ -n "${deployer_tfstate_key}" ]; then
		# Deployer state was specified in $CONFIG_REPO_PATH/.sap_deployment_automation library config
		deployer_tfstate_key_parameter=" -var deployer_tfstate_key=${deployer_tfstate_key}"
		export TF_VAR_deployer_tfstate_key_parameter=${deployer_tfstate_key}

	fi
else
	deployer_tfstate_key_parameter=" -var deployer_tfstate_key=${deployer_tfstate_key}"
	export TF_VAR_deployer_tfstate_key_parameter=${deployer_tfstate_key}
	save_config_vars "${workload_config_information}" deployer_tfstate_key
fi

if [ -z "${REMOTE_STATE_SA}" ]; then
	read -r -p "Terraform state storage account name: " REMOTE_STATE_SA
	getAndStoreTerraformStateStorageAccountDetails "${REMOTE_STATE_SA}" "${workload_config_information}"
	load_config_vars "${workload_config_information}" "STATE_SUBSCRIPTION"
	load_config_vars "${workload_config_information}" "REMOTE_STATE_RG"
	load_config_vars "${workload_config_information}" "tfstate_resource_id"

	tfstate_parameter=" -var tfstate_resource_id=${tfstate_resource_id}"
	export TF_VAR_tfstate_resource_id=${tfstate_resource_id}

	if [ -n "${STATE_SUBSCRIPTION}" ]; then
		if [ "$account_set" == 0 ]; then
			az account set --sub "${STATE_SUBSCRIPTION}"
			account_set=1
		fi
	fi
fi

if [ -z "${REMOTE_STATE_RG}" ]; then
	if [ -n "${REMOTE_STATE_SA}" ]; then
		getAndStoreTerraformStateStorageAccountDetails "${REMOTE_STATE_SA}" "${workload_config_information}"
		load_config_vars "${workload_config_information}" "STATE_SUBSCRIPTION"
		load_config_vars "${workload_config_information}" "REMOTE_STATE_RG"
		load_config_vars "${workload_config_information}" "tfstate_resource_id"

		tfstate_parameter=" -var tfstate_resource_id=${tfstate_resource_id}"
	else
		option="REMOTE_STATE_RG"
		read -r -p "Remote state resource group name: " REMOTE_STATE_RG
		save_config_vars "${workload_config_information}" REMOTE_STATE_RG
	fi
fi

if [ -n "${tfstate_resource_id}" ]; then
	tfstate_parameter=" -var tfstate_resource_id=${tfstate_resource_id}"
	export TF_VAR_tfstate_resource_id=${tfstate_resource_id}
else
	getAndStoreTerraformStateStorageAccountDetails "${REMOTE_STATE_SA}" "${workload_config_information}"
	load_config_vars "${workload_config_information}" "tfstate_resource_id"
	tfstate_parameter=" -var tfstate_resource_id=${tfstate_resource_id}"
	export TF_VAR_tfstate_resource_id=${tfstate_resource_id}
fi

terraform_module_directory="$(realpath "${SAP_AUTOMATION_REPO_PATH}"/deploy/terraform/run/"${deployment_system}")"

if [ ! -d "${terraform_module_directory}" ]; then
	printf -v val %-40.40s "$deployment_system"
	echo "#########################################################################################"
	echo "#                                                                                       #"
	echo -e "#  $bold_red Incorrect system deployment type specified: ${val}$reset_formatting#"
	echo "#                                                                                       #"
	echo "#     Valid options are:                                                                #"
	echo "#       sap_landscape                                                                   #"
	echo "#                                                                                       #"
	echo "#########################################################################################"
	echo ""
	exit 1
fi

apply_needed=false

#Plugins
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

echo ""
echo "Terraform details"
echo "-------------------------------------------------------------------------"
echo "Subscription:                        ${STATE_SUBSCRIPTION}"
echo "Storage Account:                     ${REMOTE_STATE_SA}"
echo "Resource Group:                      ${REMOTE_STATE_RG}"
echo "State file:                          ${key}.terraform.tfstate"
echo "Target subscription:                 $ARM_SUBSCRIPTION_ID"

TF_VAR_subscription_id="$ARM_SUBSCRIPTION_ID"
export TF_VAR_subscription_id

if [ ! -d .terraform/ ]; then
	if ! terraform -chdir="${terraform_module_directory}" init -upgrade=true \
		--backend-config "subscription_id=${STATE_SUBSCRIPTION}" \
		--backend-config "resource_group_name=${REMOTE_STATE_RG}" \
		--backend-config "storage_account_name=${REMOTE_STATE_SA}" \
		--backend-config "container_name=tfstate" \
		--backend-config "key=${key}.terraform.tfstate"; then
		return_value=$?
		echo ""
		echo -e "${bold_red}Terraform init:                        failed$reset_formatting"
		echo ""
	else
		return_value=0
		echo ""
		echo -e "${cyan}Terraform init:                        succeeded$reset_formatting"
		echo ""
	fi
else
	check_output=1
	local_backend=$(grep "\"type\": \"local\"" .terraform/terraform.tfstate || true)
	if [ -n "${local_backend}" ]; then

		if ! terraform -chdir="${terraform_module_directory}" init -upgrade=true -force-copy \
			--backend-config "subscription_id=${STATE_SUBSCRIPTION}" \
			--backend-config "resource_group_name=${REMOTE_STATE_RG}" \
			--backend-config "storage_account_name=${REMOTE_STATE_SA}" \
			--backend-config "container_name=tfstate" \
			--backend-config "key=${key}.terraform.tfstate"; then
			return_value=$?
			echo ""
			echo -e "${bold_red}Terraform init:                        failed$reset_formatting"
			echo ""
		else
			return_value=0
			echo ""
			echo -e "${cyan}Terraform init:                        succeeded$reset_formatting"
			echo ""
		fi
	else
		if ! terraform -chdir="${terraform_module_directory}" init -upgrade=true; then
			return_value=$?
			echo ""
			echo -e "${bold_red}Terraform init:                        failed$reset_formatting"
			echo ""
		else
			return_value=0
			echo ""
			echo -e "${cyan}Terraform init:                        succeeded$reset_formatting"
			echo ""
		fi

	fi
fi

if [ 0 != $return_value ]; then
	echo "#########################################################################################"
	echo "#                                                                                       #"
	echo -e "#                            $bold_red_underscore!!! Error when Initializing !!!$reset_formatting                            #"
	echo "#                                                                                       #"
	echo "#########################################################################################"
	echo ""
	echo "Terraform initialization failed"
	exit $return_value
fi
if ! terraform -chdir="${terraform_module_directory}" output | grep "No outputs"; then
	check_output=1
else
	check_output=0
fi

save_config_var "REMOTE_STATE_SA" "${workload_config_information}"
save_config_var "subscription" "${workload_config_information}"
save_config_var "STATE_SUBSCRIPTION" "${workload_config_information}"
save_config_var "tfstate_resource_id" "${workload_config_information}"

allParameters=$(printf " -var-file=%s %s %s %s " "${var_file}" "${extra_vars}" "${tfstate_parameter}" "${deployer_tfstate_key_parameter}")

if [ 1 == $check_output ]; then
	if terraform -chdir="${terraform_module_directory}" output | grep "No outputs"; then

		check_output=0
		apply_needed=1
		echo "#########################################################################################"
		echo "#                                                                                       #"
		echo -e "#                                  $cyan New deployment $reset_formatting                                     #"
		echo "#                                                                                       #"
		echo "#########################################################################################"
	else
		echo ""
		echo "#########################################################################################"
		echo "#                                                                                       #"
		echo -e "#                          $cyan Existing deployment was detected $reset_formatting                           #"
		echo "#                                                                                       #"
		echo "#########################################################################################"
		echo ""

		workloadkeyvault=$(terraform -chdir="${terraform_module_directory}" output -no-color -raw workloadzone_kv_name | tr -d \")
		if valid_kv_name "$workloadkeyvault"; then
			save_config_var "workloadkeyvault" "${workload_config_information}"
		fi

		deployed_using_version=$(terraform -chdir="${terraform_module_directory}" output -no-color -raw automation_version)
		if [ -z "${deployed_using_version}" ]; then
			echo ""
			echo "#########################################################################################"
			echo "#                                                                                       #"
			echo -e "#   $bold_red The environment was deployed using an older version of the Terrafrom templates $reset_formatting    #"
			echo "#                                                                                       #"
			echo "#                               !!! Risk for Data loss !!!                              #"
			echo "#                                                                                       #"
			echo "#        Please inspect the output of Terraform plan carefully before proceeding        #"
			echo "#                                                                                       #"
			echo "#########################################################################################"
			if [ 1 == $called_from_ado ]; then
				unset TF_DATA_DIR
				echo "The environment was deployed using an older version of the Terraform templates, Risk for data loss" >"${workload_config_information}".err

				exit 1
			fi

			read -r -p "Do you want to continue Y/N? " ans
			answer=${ans^^}
			if [ "$answer" == 'Y' ]; then
				apply_needed=1
			else
				unset TF_DATA_DIR
				exit 1
			fi
		else
			printf -v val %-.20s "$deployed_using_version"
			echo ""
			echo "#########################################################################################"
			echo "#                                                                                       #"
			echo -e "#             $cyan Deployed using the Terraform templates version: $val $reset_formatting               #"
			echo "#                                                                                       #"
			echo "#########################################################################################"
			echo ""
			#Add version logic here
		fi
	fi
fi

export TF_VAR_tfstate_resource_id="${tfstate_resource_id}"
export TF_VAR_subscription="${subscription}"
export TF_VAR_management_subscription="${STATE_SUBSCRIPTION}"

if [ 1 == $check_output ]; then
	deployed_using_version=$(terraform -chdir="${terraform_module_directory}" output -no-color -raw automation_version)
	if [ -n "${deployed_using_version}" ]; then
		printf -v val %-.20s "$deployed_using_version"
		echo ""
		echo "#########################################################################################"
		echo "#                                                                                       #"
		echo -e "#             $cyan Deployed using the Terraform templates version: $val $reset_formatting               #"
		echo "#                                                                                       #"
		echo "#########################################################################################"
		echo ""

		version_compare "${deployed_using_version}" "3.13.2.0"
		older_version=$?

		if [ 2 == $older_version ]; then

			if terraform -chdir="${terraform_module_directory}" state rm module.sap_landscape.azurerm_private_dns_a_record.transport[0]; then
				echo "Removed the transport private DNS record"
			fi
			if terraform -chdir="${terraform_module_directory}" state rm module.sap_landscape.azurerm_private_dns_a_record.install[0]; then
				echo "Removed the transport private DNS record"
			fi
			if terraform -chdir="${terraform_module_directory}" state rm module.sap_landscape.azurerm_private_dns_a_record.keyvault[0]; then
				echo "Removed the transport private DNS record"
			fi

			echo ""
			echo "#########################################################################################"
			echo "#                                                                                       #"
			echo -e "#           $bold_red  Deployed using an older version $reset_formatting                                          #"
			echo "#                                                                                       #"
			echo "#########################################################################################"
			echo ""

			# Remediating the Storage Accounts and File Shares

			moduleID='module.sap_landscape.azurerm_storage_account.storage_bootdiag[0]'
			storage_account_name=$(terraform -chdir="${terraform_module_directory}" output -no-color -raw storageaccount_name)
			storage_account_rg_name=$(terraform -chdir="${terraform_module_directory}" output -no-color -raw storageaccount_rg_name)
			STORAGE_ACCOUNT_ID=$(az storage account show --subscription "${subscription}" --name "${storage_account_name}" --resource-group "${storage_account_rg_name}" --query "id" --output tsv)
			export STORAGE_ACCOUNT_ID

			ReplaceResourceInStateFile "${moduleID}" "${terraform_module_directory}" "providers/Microsoft.Storage/storageAccounts"

			moduleID='module.sap_landscape.azurerm_storage_account.witness_storage[0]'
			storage_account_name=$(terraform -chdir="${terraform_module_directory}" output -no-color -raw witness_storage_account)
			STORAGE_ACCOUNT_ID=$(az storage account show --subscription "${subscription}" --name "${storage_account_name}" --resource-group "${storage_account_rg_name}" --query "id" --output tsv)
			export STORAGE_ACCOUNT_ID
			ReplaceResourceInStateFile "${moduleID}" "${terraform_module_directory}" "providers/Microsoft.Storage/storageAccounts"

			moduleID='module.sap_landscape.azurerm_storage_account.transport[0]'
			STORAGE_ACCOUNT_ID=$(terraform -chdir="${terraform_module_directory}" output -raw transport_storage_account_id | xargs | cut -d "=" -f2 | xargs)
			export STORAGE_ACCOUNT_ID
			ReplaceResourceInStateFile "${moduleID}" "${terraform_module_directory}" "providers/Microsoft.Storage/storageAccounts"

			moduleID='module.sap_landscape.azurerm_storage_account.install[0]'
			storage_account_name=$(terraform -chdir="${terraform_module_directory}" output -raw install_path | xargs | cut -d "/" -f2 | xargs)
			STORAGE_ACCOUNT_ID=$(az storage account show --subscription "${subscription}" --name "${storage_account_name}" --query "id" --output tsv)
			export STORAGE_ACCOUNT_ID

			resourceGroupName=$(az resource show --subscription "${subscription}" --ids "${STORAGE_ACCOUNT_ID}" --query "resourceGroup" --output tsv)
			resourceType=$(az resource show --subscription "${subscription}" --ids "${STORAGE_ACCOUNT_ID}" --query "type" --output tsv)
			az resource lock create --lock-type CanNotDelete -n "SAP Installation Media account delete lock" --subscription "${subscription}" \
				--resource-group "${resourceGroupName}" --resource "${storage_account_name}" --resource-type "${resourceType}"

			ReplaceResourceInStateFile "${moduleID}" "${terraform_module_directory}" "id"
			unset STORAGE_ACCOUNT_ID

			moduleID='module.sap_landscape.azurerm_storage_share.transport[0]'
			ReplaceResourceInStateFile "${moduleID}" "${terraform_module_directory}" "resource_manager_id"

			moduleID='module.sap_landscape.azurerm_storage_share.install[0]'
			ReplaceResourceInStateFile "${moduleID}" "${terraform_module_directory}" "resource_manager_id"

			moduleID='module.sap_landscape.azurerm_storage_share.install_smb[0]'
			ReplaceResourceInStateFile "${moduleID}" "${terraform_module_directory}" "resource_manager_id"

		fi
	fi
fi

echo ""
echo "#########################################################################################"
echo "#                                                                                       #"
echo -e "#                           $cyan  Running Terraform plan $reset_formatting                                   #"
echo "#                                                                                       #"
echo "#########################################################################################"
echo ""

allParameters=$(printf " -var-file=%s %s %s %s " "${var_file}" "${extra_vars}" "${tfstate_parameter}" "${deployer_tfstate_key_parameter}")

# shellcheck disable=SC2086
if ! terraform -chdir="$terraform_module_directory" plan -detailed-exitcode $allParameters -input=false | tee -a plan_output.log; then
	return_value=$?
	if [ $return_value -eq 1 ]; then
		echo ""
		echo -e "${bold_red}Terraform plan:                        failed$reset_formatting"
		echo ""
		echo "#########################################################################################"
		echo "#                                                                                       #"
		echo -e "#                           $bold_red_underscore !!! Error when running plan !!! $reset_formatting                           #"
		echo "#                                                                                       #"
		echo "#########################################################################################"
		echo ""
		if [ -f plan_output.log ]; then
			rm plan_output.log
		fi
		exit $return_value
	fi
else
	return_value=$?
	echo ""
	echo -e "${cyan}Terraform plan:                        succeeded$reset_formatting"
	echo ""
fi

if [ $check_output == 0 ]; then
	if [ -f plan_output.log ]; then
		rm plan_output.log
	fi
	return_code=2
fi

echo "Terraform Plan return code:          $return_value"
apply_needed=1

if [ "${TEST_ONLY}" == "True" ]; then
	echo ""
	echo "#########################################################################################"
	echo "#                                                                                       #"
	echo -e "#                                 $cyan Running plan only. $reset_formatting                                  #"
	echo "#                                                                                       #"
	echo "#                                  No deployment performed.                             #"
	echo "#                                                                                       #"
	echo "#########################################################################################"
	echo ""
	if [ -f plan_output.log ]; then
		rm plan_output.log
	fi
	exit 0
fi

if [ -f plan_output.log ]; then
	cat plan_output.log
	LASTERROR=$(grep -m1 'Error: ' plan_output.log || true)

	if [ -n "${LASTERROR}" ]; then
		if [ 1 == $called_from_ado ]; then
			echo "##vso[task.logissue type=error]$LASTERROR"
		fi

		return_value=1
	fi
	if [ 1 != $return_value ]; then
		test=$(grep -m1 "replaced" plan_output.log | grep kv_user || true)
		if [ -n "${test}" ]; then
			echo ""
			echo "#########################################################################################"
			echo "#                                                                                       #"
			echo -e "#                              $bold_red !!! Risk for Data loss !!! $reset_formatting                             #"
			echo "#                                                                                       #"
			echo "#        Please inspect the output of Terraform plan carefully before proceeding        #"
			echo "#                                                                                       #"
			echo "#########################################################################################"
			echo ""
			if [ 1 == $called_from_ado ]; then
				unset TF_DATA_DIR
				exit 11
			fi
			read -n 1 -r -s -p $'Press enter to continue...\n'

			cat plan_output.log
			read -r -p "Do you want to continue with the deployment Y/N? " ans
			answer=${ans^^}
			if [ "${answer}" == 'Y' ]; then
				apply_needed=1
			else
				unset TF_DATA_DIR

				exit 0
			fi
		else
			apply_needed=1
		fi
	fi
fi

if [ 0 == $return_value ]; then
	if ! terraform -chdir="${terraform_module_directory}" output | grep "No outputs"; then
		workloadkeyvault=$(terraform -chdir="${terraform_module_directory}" output -no-color -raw workloadzone_kv_name | tr -d \")
		if valid_kv_name "$workloadkeyvault"; then
			save_config_var "workloadkeyvault" "${workload_config_information}"
		fi
		save_config_vars "landscape_tfstate_key" "${workload_config_information}"

	fi
fi

if [ 1 == $apply_needed ]; then
	echo ""
	echo "#########################################################################################"
	echo "#                                                                                       #"
	echo -e "#                            $cyan Running Terraform apply $reset_formatting                                  #"
	echo "#                                                                                       #"
	echo "#########################################################################################"
	echo ""

	parallelism=10

	#Provide a way to limit the number of parallell tasks for Terraform
	if [[ -n "${TF_PARALLELLISM}" ]]; then
		parallelism=$TF_PARALLELLISM
	fi

	allParameters=$(printf " -var-file=%s %s %s %s" "${var_file}" "${extra_vars}" "${tfstate_parameter}" "${deployer_tfstate_key_parameter}")
	allImportParameters=$(printf " -var-file=%s %s %s %s" "${var_file}" "${extra_vars}" "${tfstate_parameter}" "${deployer_tfstate_key_parameter}")

	# shellcheck disable=SC2086

	if [ -n "${approve}" ]; then
		# Using if so that no zero return codes don't fail -o errexit
		if ! terraform -chdir="${terraform_module_directory}" apply "${approve}" -parallelism="${parallelism}" -no-color -json $allParameters -input=false | tee -a apply_output.json; then
			return_value=$?
			if [ $return_value -eq 1 ]; then
				echo ""
				echo -e "${bold_red}Terraform apply:                       failed$reset_formatting"
				echo ""
				exit $return_value
			else
				# return code 2 is ok
				echo ""
				echo -e "${cyan}Terraform apply:                     succeeded$reset_formatting"
				echo ""
				return_value=0
			fi
		else
			echo ""
			echo -e "${cyan}Terraform apply:                     succeeded$reset_formatting"
			echo ""
			return_value=0
		fi
	else
		# Using if so that no zero return codes don't fail -o errexit
		if ! terraform -chdir="${terraform_module_directory}" apply -parallelism="${parallelism}" $allParameters -input=false; then
			return_value=$?
		else
			return_value=0
		fi

		if [ $return_value -eq 1 ]; then
			echo ""
			echo -e "${bold_red}Terraform apply:                       failed$reset_formatting"
			echo ""
			exit $return_value
		elif [ $return_value -eq 2 ]; then
			# return code 2 is ok
			echo ""
			echo -e "${cyan}Terraform apply:                     succeeded$reset_formatting"
			echo ""
			return_value=0
		else
			echo ""
			echo -e "${cyan}Terraform apply:                     succeeded$reset_formatting"
			echo ""
			return_value=0
		fi

	fi

fi

if [ -f apply_output.json ]; then
	errors_occurred=$(jq 'select(."@level" == "error") | length' apply_output.json)

	if [[ -n $errors_occurred ]]; then
		return_value=10
		if [ -n "${approve}" ]; then
			echo -e "${cyan}Retrying Terraform apply:$reset_formatting"

			# shellcheck disable=SC2086
			if ! ImportAndReRunApply "apply_output.json" "${terraform_module_directory}" "$allImportParameters" "$allParameters" $parallelism; then
				return_value=$?
			fi

			sleep 10

			if [ -f apply_output.json ]; then
				echo -e "${cyan}Retrying Terraform apply:$reset_formatting"
				# shellcheck disable=SC2086
				if ! ImportAndReRunApply "apply_output.json" "${terraform_module_directory}" "$allImportParameters" "$allParameters" $parallelism; then
					return_value=$?
				fi
			fi

			if [ -f apply_output.json ]; then
				# shellcheck disable=SC2086
				if ! ImportAndReRunApply "apply_output.json" "${terraform_module_directory}" "$allImportParameters" "$allParameters" $parallelism; then
					return_value=$?
				fi

			fi

			if [ -f apply_output.json ]; then
				# shellcheck disable=SC2086
				if ! ImportAndReRunApply "apply_output.json" "${terraform_module_directory}" "$allImportParameters" "$allParameters" $parallelism; then
					return_value=$?
				fi
			fi

			if [ -f apply_output.json ]; then
				# shellcheck disable=SC2086
				if ! ImportAndReRunApply "apply_output.json" "${terraform_module_directory}" "$allImportParameters" "$allParameters" $parallelism; then
					return_value=$?
				fi
			fi

			if [ -f apply_output.json ]; then
				# shellcheck disable=SC2086
				if ! ImportAndReRunApply "apply_output.json" "${terraform_module_directory}" "$allImportParameters" "$allParameters" $parallelism; then
					return_value=$?
				fi
			fi

			if [ -f apply_output.json ]; then
				# shellcheck disable=SC2086
				if ! ImportAndReRunApply "apply_output.json" "${terraform_module_directory}" "$allImportParameters" "$allParameters" $parallelism; then
					return_value=$?
				fi
			fi

		else
			return_value=10
		fi

	fi
fi

if [ -f apply_output.json ]; then
	rm apply_output.json
fi

save_config_var "landscape_tfstate_key" "${workload_config_information}"

if ! terraform -chdir="${terraform_module_directory}" output | grep "No outputs"; then

	workload_zone_prefix=$(terraform -chdir="${terraform_module_directory}" output -no-color -raw workload_zone_prefix | tr -d \")
	save_config_var "workload_zone_prefix" "${workload_config_information}"
	save_config_vars "landscape_tfstate_key" "${workload_config_information}"
	workload_keyvault=$(terraform -chdir="${terraform_module_directory}" output -no-color -raw workloadzone_kv_name | tr -d \")

	workload_random_id=$(terraform -chdir="${terraform_module_directory}" output -no-color -raw random_id | tr -d \")
	if [ -n "${workload_random_id}" ]; then
		save_config_var "workload_random_id" "${workload_config_information}"
		custom_random_id="${workload_random_id:0:3}"
		sed -i -e /"custom_random_id"/d "${parameterfile}"
		printf "# The parameter 'custom_random_id' can be used to control the random 3 digits at the end of the storage accounts and key vaults\ncustom_random_id=\"%s\"\n" "${custom_random_id}" >>"${var_file}"
	fi

	resourceGroupName=$(terraform -chdir="${terraform_module_directory}" output -no-color -raw created_resource_group_name | tr -d \")

	temp=$(echo "${workload_keyvault}" | grep "Warning" || true)
	if [ -z "${temp}" ]; then
		temp=$(echo "${workload_keyvault}" | grep "Backend reinitialization required" || true)
		if [ -z "${temp}" ]; then

			printf -v val %-.20s "$workload_keyvault"

			echo ""
			echo "#########################################################################################"
			echo "#                                                                                       #"
			echo -e "#                Keyvault to use for System details:$cyan $val $reset_formatting               #"
			echo "#                                                                                       #"
			echo "#########################################################################################"
			echo ""
			workloadkeyvault="$workload_keyvault"
			save_config_var "workloadkeyvault" "${workload_config_information}"
		fi
	fi
fi

if [ 0 != $return_value ]; then
	unset TF_DATA_DIR
	exit $return_value
fi

echo ""
echo "#########################################################################################"
echo "#                                                                                       #"
echo -e "#                            $cyan Creating deployment     $reset_formatting                                  #"
echo "#                                                                                       #"
echo "#########################################################################################"
echo ""

full_script_path="$(realpath "${BASH_SOURCE[0]}")"
script_directory="$(dirname "${full_script_path}")"

if [ -n "${resourceGroupName}" ]; then
	az deployment group create --resource-group "${resourceGroupName}" --name "SAP-WORKLOAD-ZONE_${resourceGroupName}" --subscription "$ARM_SUBSCRIPTION_ID" \
		--template-file "${script_directory}/templates/empty-deployment.json" --output none --only-show-errors --no-wait
fi

now=$(date)
cat <<EOF >"${workload_zone_prefix}".md
# Workload Zone Deployment #

Date : "${now}"

## Configuration details ##

| Item                    | Name                 |
| ----------------------- | -------------------- |
| Environment             | $environment         |
| Location                | $region              |
| Keyvault Name           | ${workloadkeyvault}  |

EOF

printf -v kvname '%-40s' "${workloadkeyvault}"
echo ""
echo "#########################################################################################"
echo "#                                                                                       #"
echo -e "# $cyan Please save these values: $reset_formatting                                                           #"
echo "#     - Key Vault: ${kvname}                             #"
echo "#                                                                                       #"
echo "#########################################################################################"

if [ -f "${workload_config_information}".err ]; then
	cat "${workload_config_information}".err
fi

unset TF_DATA_DIR

#################################################################################
#                                                                               #
#                           Copy tfvars to storage account                      #
#                                                                               #
#                                                                               #
#################################################################################

if [ "$useSAS" = "true" ]; then
	container_exists=$(az storage container exists --subscription "${STATE_SUBSCRIPTION}" --account-name "${REMOTE_STATE_SA}" --name tfvars --only-show-errors --query exists)
else
	container_exists=$(az storage container exists --subscription "${STATE_SUBSCRIPTION}" --account-name "${REMOTE_STATE_SA}" --name tfvars --only-show-errors --query exists --auth-mode login)
fi

if [ "${container_exists}" == "false" ]; then
	if [ "$useSAS" = "true" ]; then
		az storage container create --subscription "${STATE_SUBSCRIPTION}" --account-name "${REMOTE_STATE_SA}" --name tfvars --only-show-errors
	else
		az storage container create --subscription "${STATE_SUBSCRIPTION}" --account-name "${REMOTE_STATE_SA}" --name tfvars --auth-mode login --only-show-errors
	fi
fi

if [ "$useSAS" = "true" ]; then
	az storage blob upload --file "${parameterfile}" --container-name tfvars/LANDSCAPE/"${key}" --name "${parameterfile_name}" \
		--subscription "${STATE_SUBSCRIPTION}" --account-name "${REMOTE_STATE_SA}" --no-progress --overwrite --only-show-errors --output none
else
	az storage blob upload --file "${parameterfile}" --container-name tfvars/LANDSCAPE/"${key}" --name "${parameterfile_name}" \
		--subscription "${STATE_SUBSCRIPTION}" --account-name "${REMOTE_STATE_SA}" --no-progress --overwrite --auth-mode login --only-show-errors --output none
fi

exit $return_value
