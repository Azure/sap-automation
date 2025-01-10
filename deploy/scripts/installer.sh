#!/bin/bash
# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

# Ensure that the exit status of a pipeline command is non-zero if any
# stage of the pipefile has a non-zero exit status.
set -o pipefail

#colors for terminal
bold_red_underscore="\e[1;4;31m"
bold_red="\e[1;31m"
cyan="\e[1;36m"
green="\e[1;32m"
reset_formatting="\e[0m"

#External helper functions
#. "$(dirname "${BASH_SOURCE[0]}")/deploy_utils.sh"
full_script_path="$(realpath "${BASH_SOURCE[0]}")"
script_directory="$(dirname "${full_script_path}")"

#call stack has full scriptname when using source
source "${script_directory}/deploy_utils.sh"

#helper files
source "${script_directory}/helpers/script_helpers.sh"

function showhelp {
	echo ""
	echo "#########################################################################################"
	echo "#                                                                                       #"
	echo "#                                                                                       #"
	echo "#   This file contains the logic to deploy the different systems                        #"
	echo "#   The script experts the following exports:                                           #"
	echo "#                                                                                       #"
	echo "#   ARM_SUBSCRIPTION_ID to specify which subscription to deploy to                      #"
	echo "#   SAP_AUTOMATION_REPO_PATH the path to the folder containing the cloned sap-automation#"
	echo "#   CONFIG_REPO_PATH (path to the configuration repo folder (sap-config)                #"
	echo "#                                                                                       #"
	echo "#   The script will persist the parameters needed between the executions in the         #"
	echo "#   [CONFIG_REPO_PATH]/.sap_deployment_automation folder                                #"
	echo "#                                                                                       #"
	echo "#                                                                                       #"
	echo "#   Usage: installer.sh                                                                 #"
	echo "#    -p or --parameterfile           parameter file                                     #"
	echo "#    -t or --type                         type of system to remove                      #"
	echo "#                                         valid options:                                #"
	echo "#                                           sap_deployer                                #"
	echo "#                                           sap_library                                 #"
	echo "#                                           sap_landscape                               #"
	echo "#                                           sap_system                                  #"
	echo "#                                                                                       #"
	echo "#   Optional parameters                                                                 #"
	echo "#                                                                                       #"
	echo "#    -o or --storageaccountname      Storage account name for state file                #"
	echo "#    -d or --deployer_tfstate_key    Deployer terraform state file name                 #"
	echo "#    -l or --landscape_tfstate_key     Workload zone terraform state file name          #"
	echo "#    -s or --state_subscription      Subscription for tfstate storage account           #"
	echo "#    -i or --auto-approve            Silent install                                     #"
	echo "#    -h or --help                    Show help                                          #"
	echo "#                                                                                       #"
	echo "#   Example:                                                                            #"
	echo "#                                                                                       #"
	echo "#   [REPO-ROOT]deploy/scripts/installer.sh \                                            #"
	echo "#      --parameterfile DEV-WEEU-SAP01-X00 \                                             #"
	echo "#      --type sap_system                                                                #"
	echo "#      --auto-approve                                                                   #"
	echo "#                                                                                       #"
	echo "#########################################################################################"
}

function missing {
	printf -v val %-.40s "$1"
	echo ""
	echo ""
	echo "#########################################################################################"
	echo "#                                                                                       #"
	echo "#   Missing environment variables: ${option}!!!              #"
	echo "#                                                                                       #"
	echo "#   Please export the folloing variables:                                               #"
	echo "#      SAP_AUTOMATION_REPO_PATH (path to the automation repo folder (sap-automation))   #"
	echo "#      CONFIG_REPO_PATH (path to the configuration repo folder (sap-config))            #"
	echo "#      ARM_SUBSCRIPTION_ID (subscription containing the state file storage account)     #"
	echo "#      REMOTE_STATE_RG (resource group name for storage account containing state files) #"
	echo "#      REMOTE_STATE_SA (storage account for state file)                                 #"
	echo "#                                                                                       #"
	echo "#########################################################################################"
	return 0
}

force=0

INPUT_ARGUMENTS=$(getopt -n installer -o p:t:o:d:l:s:ahif --longoptions type:,parameterfile:,storageaccountname:,deployer_tfstate_key:,landscape_tfstate_key:,state_subscription:,ado,auto-approve,force,help -- "$@")
VALID_ARGUMENTS=$?

if [ "$VALID_ARGUMENTS" != "0" ]; then
	showhelp
	exit 3
fi
called_from_ado=0
eval set -- "$INPUT_ARGUMENTS"
while :; do
	case "$1" in
	-t | --type)
		deployment_system="$2"
		shift 2
		;;
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
	-d | --deployer_tfstate_key)
		deployer_tfstate_key="$2"
		shift 2
		;;
	-l | --landscape_tfstate_key)
		landscape_tfstate_key="$2"
		shift 2
		;;
	-a | --ado)
		called_from_ado=1
		approve="--auto-approve"
		TF_IN_AUTOMATION=true
		export TF_IN_AUTOMATION
		shift
		;;
	-f | --force)
		force=1
		shift
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

if [ "$DEBUG" = True ]; then
	echo -e "${cyan}Enabling debug mode$reset_formatting"
	set -x
	set -o errexit
fi

echo "Parameter file:                      $parameterfile"
echo "Current directory:                   $(pwd)"
echo "Terraform state subscription_id:     ${STATE_SUBSCRIPTION}"
echo "Terraform state storage account name:${REMOTE_STATE_SA}"

landscape_tfstate_key_exists=false

parameterfile_name=$(basename "${parameterfile}")
param_dirname=$(dirname "${parameterfile}")

if [ "${param_dirname}" != '.' ]; then
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

	echo "Parameter file does not exist: ${val}" >"${system_config_information}".err

	exit 2 #No such file or directory
fi

if [ -z "${deployment_system}" ]; then
	printf -v val %-40.40s "$deployment_system"
	echo "#########################################################################################"
	echo "#                                                                                       #"
	echo -e "#  $bold_red Incorrect system deployment type specified: ${val}$reset_formatting#"
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
	echo "Missing exports" >"${system_config_information}".err
	exit $return_code
fi

# Check that Terraform and Azure CLI is installed
validate_dependencies
return_code=$?
if [ 0 != $return_code ]; then
	echo "Missing software" >"${system_config_information}".err
	exit $return_code
fi

# Check that parameter files have environment and location defined
validate_key_parameters "$parameterfile_name"
return_code=$?
if [ 0 != $return_code ]; then
	echo "Missing parameters in $parameterfile_name" >"${system_config_information}".err
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

network_logical_name=""

if [ "${deployment_system}" == sap_system ]; then
	load_config_vars "$parameterfile_name" "network_logical_name"
	network_logical_name=$(echo "${network_logical_name}" | tr "[:lower:]" "[:upper:]")
fi

#Persisting the parameters across executions

automation_config_directory=$CONFIG_REPO_PATH/.sap_deployment_automation/
generic_config_information="${automation_config_directory}"config
system_config_information="${automation_config_directory}${environment}${region_code}${network_logical_name}"

echo "Configuration file:                  $system_config_information"
echo "Deployment region:                   $region"
echo "Deployment region code:              $region_code"

if [ 1 == $called_from_ado ]; then
	this_ip=$(curl -s ipinfo.io/ip) >/dev/null 2>&1
	export TF_VAR_Agent_IP=$this_ip
	echo "Agent IP:                            $this_ip"
fi

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

parallelism=10

#Provide a way to limit the number of parallell tasks for Terraform
if [[ -n "$TF_PARALLELLISM" ]]; then
	parallelism=$TF_PARALLELLISM
fi

echo "Parallelism count:                   $parallelism"

param_dirname=$(pwd)
export TF_DATA_DIR="${param_dirname}/.terraform"

init "${automation_config_directory}" "${generic_config_information}" "${system_config_information}"

tfstate_resource_id=$(az resource list --name "$REMOTE_STATE_SA" --subscription "$STATE_SUBSCRIPTION" --resource-type Microsoft.Storage/storageAccounts --query "[].id | [0]" -o tsv)
TF_VAR_tfstate_resource_id=$tfstate_resource_id
export TF_VAR_tfstate_resource_id

var_file="${param_dirname}"/"${parameterfile}"

if [ -f terraform.tfvars ]; then
	extra_vars="-var-file=${param_dirname}/terraform.tfvars"
else
	unset extra_vars
fi

if [ "${deployment_system}" == sap_deployer ]; then
	deployer_tfstate_key=${key}.terraform.tfstate
	ARM_SUBSCRIPTION_ID=$STATE_SUBSCRIPTION
	export ARM_SUBSCRIPTION_ID
fi
if [[ -z $STATE_SUBSCRIPTION ]]; then
	STATE_SUBSCRIPTION=$ARM_SUBSCRIPTION_ID
fi

if [[ -n $STATE_SUBSCRIPTION ]]; then
	echo ""
	echo "#########################################################################################"
	echo "#                                                                                       #"
	echo -e "#       $cyan Changing the subscription to: $STATE_SUBSCRIPTION $reset_formatting            #"
	echo "#                                                                                       #"
	echo "#########################################################################################"
	echo ""
	az account set --sub "${STATE_SUBSCRIPTION}"

	return_code=$?
	if [ 0 != $return_code ]; then

		echo "#########################################################################################"
		echo "#                                                                                       #"
		echo -e "#         $bold_red  The deployment account (MSI or SPN) does not have access to $reset_formatting                #"
		echo -e "#                      $bold_red ${STATE_SUBSCRIPTION} $reset_formatting                           #"
		echo "#                                                                                       #"
		echo "#########################################################################################"

		echo "##vso[task.logissue type=error]The deployment account (MSI or SPN) does not have access to ${STATE_SUBSCRIPTION}"
		exit $return_code
	fi

	account_set=1
fi

if [[ -z $REMOTE_STATE_SA ]]; then
	load_config_vars "${system_config_information}" "REMOTE_STATE_SA"
	load_config_vars "${system_config_information}" "REMOTE_STATE_RG"
	load_config_vars "${system_config_information}" "tfstate_resource_id"
	load_config_vars "${system_config_information}" "STATE_SUBSCRIPTION"
	load_config_vars "${system_config_information}" "ARM_SUBSCRIPTION_ID"
else
	save_config_vars "${system_config_information}" REMOTE_STATE_SA
fi

deployer_tfstate_key_parameter=""

if [[ -z $deployer_tfstate_key ]]; then
	load_config_vars "${system_config_information}" "deployer_tfstate_key"
else
	echo "Deployer state file name:            ${deployer_tfstate_key}"
	echo "Target subscription:                 $ARM_SUBSCRIPTION_ID"
	TF_VAR_deployer_tfstate_key="${deployer_tfstate_key}"
	export TF_VAR_deployer_tfstate_key
fi

export TF_VAR_deployer_tfstate_key="${deployer_tfstate_key}"

if [ "${deployment_system}" != sap_deployer ]; then
	if [ -z "${deployer_tfstate_key}" ]; then
		if [ 1 != $called_from_ado ]; then
			read -r -p "Deployer terraform statefile name: " deployer_tfstate_key

			save_config_var "deployer_tfstate_key" "${system_config_information}"
		else
			echo ""
			echo "#########################################################################################"
			echo "#                                                                                       #"
			echo -e "#                          $bold_red_underscore!Deployer state file name is missing!$reset_formatting                        #"
			echo "#                                                                                       #"
			echo "#########################################################################################"
			echo ""

			echo "Deployer terraform statefile name is missing" >"${system_config_information}".err
			unset TF_DATA_DIR
			exit 2
		fi
	else

		echo "Deployer state file name:            ${deployer_tfstate_key}"
	fi
else
	load_config_vars "${system_config_information}" "keyvault"
	TF_VAR_deployer_kv_user_arm_id=$(az resource list --name "${keyvault}" --subscription "${STATE_SUBSCRIPTION}" --resource-type Microsoft.KeyVault/vaults --query "[].id | [0]" -o tsv)
	export TF_VAR_spn_keyvault_id="${TF_VAR_deployer_kv_user_arm_id}"

	echo "Deployer Keyvault ID:                $TF_VAR_deployer_kv_user_arm_id"
	deployer_parameter="  -var subscription_id=${STATE_SUBSCRIPTION} "

	export ARM_SUBSCRIPTION_ID=$STATE_SUBSCRIPTION

fi

useSAS=$(az storage account show --name "${REMOTE_STATE_SA}" --query allowSharedKeyAccess --subscription "${STATE_SUBSCRIPTION}" --out tsv)

if [ "$useSAS" = "true" ]; then
	echo "Storage Account Authentication:      Key"
	export ARM_USE_AZUREAD=false
else
	echo "Storage Account Authentication:      Entra ID"
	export ARM_USE_AZUREAD=true
fi

landscape_tfstate_key_parameter=''

if [[ -z $landscape_tfstate_key ]]; then
	load_config_vars "${system_config_information}" "landscape_tfstate_key"
else
	echo "Workload zone state file:            ${landscape_tfstate_key}"
	save_config_vars "${system_config_information}" landscape_tfstate_key
fi

if [ "${deployment_system}" == sap_system ]; then
	if [ -z "${landscape_tfstate_key}" ]; then
		if [ 1 != $called_from_ado ]; then
			read -r -p "Workload terraform statefile name: " landscape_tfstate_key

			save_config_var "landscape_tfstate_key" "${system_config_information}"

		else
			echo ""
			echo "#########################################################################################"
			echo "#                                                                                       #"
			echo -e "#                     $bold_red Workload zone terraform statefile name is missing $reset_formatting               #"
			echo "#                                                                                       #"
			echo "#########################################################################################"
			echo ""

			echo "Workload zone terraform statefile name is missing"

			unset TF_DATA_DIR
			exit 2
		fi
	fi
fi

if [[ -z $STATE_SUBSCRIPTION ]]; then
	load_config_vars "${system_config_information}" "STATE_SUBSCRIPTION"
else

	if is_valid_guid "$STATE_SUBSCRIPTION"; then
		save_config_var "STATE_SUBSCRIPTION" "${system_config_information}"
	else
		printf -v val %-40.40s "$STATE_SUBSCRIPTION"
		echo "#########################################################################################"
		echo "#                                                                                       #"
		echo -e "# The provided state_subscription is not valid:$bold_red ${val}$reset_formatting#"
		echo "#                                                                                       #"
		echo "#########################################################################################"
		echo "The provided subscription for Terraform remote state is not valid:${val}" >"${system_config_information}".err
		exit 65
	fi

fi

#setting the user environment variables
set_executing_user_environment_variables "none"

if [[ -n ${subscription} ]]; then
	if is_valid_guid "${subscription}"; then
		echo "Valid subscription format"
	else
		printf -v val %-40.40s "$subscription"
		echo "#########################################################################################"
		echo "#                                                                                       #"
		echo -e "#   The provided subscription is not valid:$bold_red ${val} $reset_formatting#   "
		echo "#                                                                                       #"
		echo "#########################################################################################"
		echo "The provided subscription is not valid:${val}" >"${system_config_information}".err
		exit 65
	fi
	export ARM_SUBSCRIPTION_ID="${subscription}"
fi

load_config_vars "${system_config_information}" "STATE_SUBSCRIPTION"
load_config_vars "${system_config_information}" "REMOTE_STATE_RG"
load_config_vars "${system_config_information}" "tfstate_resource_id"

if [[ -z ${REMOTE_STATE_SA} ]]; then
	if [ 1 != $called_from_ado ]; then
		read -r -p "Terraform state storage account name: " REMOTE_STATE_SA

		getAndStoreTerraformStateStorageAccountDetails "${REMOTE_STATE_SA}" "${system_config_information}"
		load_config_vars "${system_config_information}" "STATE_SUBSCRIPTION"
		load_config_vars "${system_config_information}" "REMOTE_STATE_RG"
		load_config_vars "${system_config_information}" "tfstate_resource_id"
	fi
fi

if [ -z "${REMOTE_STATE_SA}" ]; then
	missing "REMOTE_STATE_SA"
	exit 1
fi

if [[ -z ${REMOTE_STATE_RG} ]]; then
	getAndStoreTerraformStateStorageAccountDetails "${REMOTE_STATE_SA}" "${system_config_information}"
	load_config_vars "${system_config_information}" "STATE_SUBSCRIPTION"
	load_config_vars "${system_config_information}" "REMOTE_STATE_RG"
	load_config_vars "${system_config_information}" "tfstate_resource_id"
fi

if [[ -z ${tfstate_resource_id} ]]; then
	getAndStoreTerraformStateStorageAccountDetails "${REMOTE_STATE_SA}" "${system_config_information}"
	load_config_vars "${system_config_information}" "STATE_SUBSCRIPTION"
	load_config_vars "${system_config_information}" "REMOTE_STATE_RG"
	load_config_vars "${system_config_information}" "tfstate_resource_id"

fi

if [ -n "${tfstate_resource_id}" ]; then
	TF_VAR_tfstate_resource_id="${tfstate_resource_id}"
	export TF_VAR_tfstate_resource_id
fi

if [ -n "${landscape_tfstate_key}" ]; then
	TF_VAR_landscape_tfstate_key="${landscape_tfstate_key}"
	export TF_VAR_landscape_tfstate_key
fi

if [ -n "${deployer_tfstate_key}" ]; then
	TF_VAR_deployer_tfstate_key="${deployer_tfstate_key}"
	export TF_VAR_deployer_tfstate_key
fi

terraform_module_directory="$SAP_AUTOMATION_REPO_PATH/deploy/terraform/run/${deployment_system}"
cd "${param_dirname}" || exit

if [ ! -d "${terraform_module_directory}" ]; then
	printf -v val %-40.40s "$deployment_system"
	echo "#########################################################################################"
	echo "#                                                                                       #"
	echo -e "#   $bold_red Incorrect system deployment type specified: ${val}$reset_formatting#"
	echo "#                                                                                       #"
	echo "#     Valid options are:                                                                #"
	echo "#       sap_deployer                                                                    #"
	echo "#       sap_library                                                                     #"
	echo "#       sap_landscape                                                                   #"
	echo "#       sap_system                                                                      #"
	echo "#                                                                                       #"
	echo "#########################################################################################"
	echo ""
	exit 1
fi

# This is used to tell Terraform if this is a new deployment or an update
deployment_parameter=""
# This is used to tell Terraform the version information from the state file
version_parameter=""

export TF_DATA_DIR="${param_dirname}/.terraform"

terraform --version
echo ""
echo "Terraform details"
echo "-------------------------------------------------------------------------"
echo "Subscription:                        ${STATE_SUBSCRIPTION}"
echo "Storage Account:                     ${REMOTE_STATE_SA}"
echo "Resource Group:                      ${REMOTE_STATE_RG}"
echo "State file:                          ${key}.terraform.tfstate"
echo "Target subscription:                 ${ARM_SUBSCRIPTION_ID}"
echo "Deployer state file:                 ${deployer_tfstate_key}"
echo "Workload zone state file:            ${landscape_tfstate_key}"
echo "Terraform state resource ID:         ${tfstate_resource_id}"
echo "Current directory:                   $(pwd)"
echo ""

TF_VAR_subscription_id="$ARM_SUBSCRIPTION_ID"
export TF_VAR_subscription_id

check_output=0

terraform_module_directory="${SAP_AUTOMATION_REPO_PATH}/deploy/terraform/run/${deployment_system}"/
export TF_DATA_DIR="${param_dirname}/.terraform"

new_deployment=0

if [ ! -f .terraform/terraform.tfstate ]; then
	echo ""
	echo -e "${cyan}New deployment${reset_formatting}"
	echo ""
	deployment_parameter=" -var deployment=new "
	check_output=0

	if ! terraform -chdir="${terraform_module_directory}" init -upgrade=true -input=false \
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
		return_value=$?
		echo ""
		echo -e "${cyan}Terraform init:                        succeeded$reset_formatting"
		echo ""
	fi

else
	new_deployment=1
	check_output=1

	local_backend=$(grep "\"type\": \"local\"" .terraform/terraform.tfstate || true)
	if [ -n "$local_backend" ]; then
		echo ""
		echo "#########################################################################################"
		echo "#                                                                                       #"
		echo -e "#                              ${cyan}Migrating the state to Azure${reset_formatting}                             #"
		echo "#                                                                                       #"
		echo "#########################################################################################"
		echo ""

		terraform_module_directory="${SAP_AUTOMATION_REPO_PATH}/deploy/terraform/bootstrap/${deployment_system}"/

		if ! terraform -chdir="${terraform_module_directory}" init -force-copy --backend-config "path=${param_dirname}/terraform.tfstate"; then
			return_value=$?
			echo ""
			echo -e "${bold_red}Terraform local init:                  failed$reset_formatting"
			echo ""
			exit $return_value
		else
			return_value=$?
			echo ""
			echo -e "${cyan}Terraform local init:                  succeeded$reset_formatting"
			echo ""
			# terraform -chdir="${terraform_module_directory}" state list
		fi

		terraform_module_directory="${SAP_AUTOMATION_REPO_PATH}/deploy/terraform/run/${deployment_system}"/

		if terraform -chdir="${terraform_module_directory}" init -force-copy \
			--backend-config "subscription_id=${STATE_SUBSCRIPTION}" \
			--backend-config "resource_group_name=${REMOTE_STATE_RG}" \
			--backend-config "storage_account_name=${REMOTE_STATE_SA}" \
			--backend-config "container_name=tfstate" \
			--backend-config "key=${key}.terraform.tfstate"; then
			return_value=$?
			echo ""
			echo -e "${cyan}Terraform init:                        succeeded$reset_formatting"
			echo ""

			allParameters=$(printf " -var-file=%s %s %s " "${var_file}" "${extra_vars}" "${deployer_parameter}")

			# terraform -chdir="${terraform_module_directory}" state list
		else
			return_value=$?
			echo ""
			echo -e "${bold_red}Terraform init:                        failed$reset_formatting"
			echo ""
			exit $return_value
		fi

	else
		echo "Terraform state:                     remote"

		echo ""
		echo "#########################################################################################"
		echo "#                                                                                       #"
		echo -e "#            $cyan The system has already been deployed and the statefile is in Azure $reset_formatting       #"
		echo "#                                                                                       #"
		echo "#########################################################################################"
		echo ""

		check_output=1
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
			exit $return_value
		else
			return_value=$?
			echo ""
			echo -e "${cyan}Terraform init:                        succeeded$reset_formatting"
			echo ""
		fi
	fi
fi

if [ 1 -eq "$check_output" ]; then
	if terraform -chdir="${terraform_module_directory}" output | grep "No outputs"; then
		echo "#########################################################################################"
		echo "#                                                                                       #"
		echo -e "#                                 $cyan  New deployment $reset_formatting                                      #"
		echo "#                                                                                       #"
		echo "#########################################################################################"

		deployment_parameter=" -var deployment=new "
		new_deployment=0
		check_output=0

	else
		echo ""
		echo "#########################################################################################"
		echo "#                                                                                       #"
		echo -e "#                          $cyan Existing deployment was detected$reset_formatting                            #"
		echo "#                                                                                       #"
		echo "#########################################################################################"
		echo ""

		deployment_parameter=""
		new_deployment=0
		check_output=true
	fi
fi

if [ 1 -eq $new_deployment ]; then
	deployed_using_version=$(terraform -chdir="${terraform_module_directory}" output -no-color -raw automation_version | tr -d \" || true)
	if [ -z "${deployed_using_version}" ]; then
		echo ""
		echo "#########################################################################################"
		echo "#                                                                                       #"
		echo -e "#   $bold_red The environment was deployed using an older version of the Terraform templates$reset_formatting     #"
		echo "#                                                                                       #"
		echo "#                               !!! Risk for Data loss !!!                              #"
		echo "#                                                                                       #"
		echo "#        Please inspect the output of Terraform plan carefully before proceeding        #"
		echo "#                                                                                       #"
		echo "#########################################################################################"

		if [ 1 == $called_from_ado ]; then
			unset TF_DATA_DIR
			exit 1
		fi
		read -r -p "Do you want to continue Y/N? " ans
		answer=${ans^^}
		if [ "$answer" != 'Y' ]; then
			unset TF_DATA_DIR
			exit 1
		fi
	else
		version_parameter="-var terraform_template_version=${deployed_using_version}"

		printf -v val %-.20s "$deployed_using_version"
		echo ""
		echo "#########################################################################################"
		echo "#                                                                                       #"
		echo -e "#              $cyan Deployed using the Terraform templates version: $val $reset_formatting               #"
		echo "#                                                                                       #"
		echo "#########################################################################################"
		echo ""
		version_compare "${deployed_using_version}" "3.13.2.0"
		older_version=$?
		if [ 2 == $older_version ]; then
			echo ""
			echo "#########################################################################################"
			echo "#                                                                                       #"
			echo -e "#           $bold_red  Deployed using an older version $reset_formatting                                          #"
			echo "#                                                                                       #"
			echo "#########################################################################################"
			echo ""
			echo "##vso[task.logissue type=warning]Deployed using an older version ${deployed_using_version}. Performing state management operations"

			# Remediating the Storage Accounts and File Shares
			if [ "${deployment_system}" == sap_library ]; then
				moduleID='module.sap_library.azurerm_storage_account.storage_sapbits[0]'
				storage_account_name=$(terraform -chdir="${terraform_module_directory}" output -no-color -raw sapbits_storage_account_name)
				storage_account_rg_name=$(terraform -chdir="${terraform_module_directory}" output -no-color -raw sapbits_sa_resource_group_name)
				STORAGE_ACCOUNT_ID=$(az storage account show --name "${storage_account_name}" --resource-group "${storage_account_rg_name}" --query "id" --output tsv)
				export STORAGE_ACCOUNT_ID

				ReplaceResourceInStateFile "${moduleID}" "${terraform_module_directory}" "providers/Microsoft.Storage/storageAccounts"

				resourceGroupName=$(az resource show --ids "${STORAGE_ACCOUNT_ID}" --query "resourceGroup" --output tsv)
				resourceType=$(az resource show --ids "${STORAGE_ACCOUNT_ID}" --query "type" --output tsv)
				resourceName=$(az resource show --ids "${STORAGE_ACCOUNT_ID}" --query "name" --output tsv)

				az resource lock create --lock-type CanNotDelete -n "SAP Media account delete lock" --resource-group "${resourceGroupName}" --resource "${resourceName}" --resource-type "${resourceType}" --output none
				unset STORAGE_ACCOUNT_ID

				moduleID='module.sap_library.azurerm_storage_container.storagecontainer_sapbits[0]'
				ReplaceResourceInStateFile "${moduleID}" "${terraform_module_directory}" "resource_manager_id"

				moduleID='module.sap_library.azurerm_storage_account.storage_tfstate[0]'

				STORAGE_ACCOUNT_ID=$(terraform -chdir="${terraform_module_directory}" output -no-color -raw tfstate_resource_id)
				export STORAGE_ACCOUNT_ID

				ReplaceResourceInStateFile "${moduleID}" "${terraform_module_directory}" "providers/Microsoft.Storage/storageAccounts"

				resourceGroupName=$(az resource show --ids "${STORAGE_ACCOUNT_ID}" --query "resourceGroup" --output tsv)
				resourceType=$(az resource show --ids "${STORAGE_ACCOUNT_ID}" --query "type" --output tsv)
				resourceName=$(az resource show --ids "${STORAGE_ACCOUNT_ID}" --query "name" --output tsv)
				az resource lock create --lock-type CanNotDelete -n "Terraform state account delete lock" --resource-group "${resourceGroupName}" --resource "${resourceName}" --resource-type "${resourceType}" --output none
				unset STORAGE_ACCOUNT_ID

				moduleID='module.sap_library.azurerm_storage_container.storagecontainer_tfstate[0]'
				ReplaceResourceInStateFile "${moduleID}" "${terraform_module_directory}" "resource_manager_id"

				moduleID='module.sap_library.azurerm_storage_container.storagecontainer_tfvars[0]'
				ReplaceResourceInStateFile "${moduleID}" "${terraform_module_directory}" "resource_manager_id"

			fi

			if [ "${deployment_system}" == sap_deployer ]; then

				moduleID='module.sap_deployer.azurerm_storage_account.deployer[0]'
				if terraform -chdir="${terraform_module_directory}" state rm ${moduleID}; then
					echo "Removed the diagnostics storage account state object"
				fi
			fi

			if [ "${deployment_system}" == sap_system ]; then

				moduleID='module.common_infrastructure.azurerm_storage_account.sapmnt[0]'
				if terraform -chdir="${terraform_module_directory}" state rm ${moduleID}; then
					echo "Removed the transport private DNS record"
				fi

				moduleID='module.common_infrastructure.azurerm_storage_share.sapmnt[0]'
				if terraform -chdir="${terraform_module_directory}" state rm ${moduleID}; then
					echo "Removed the transport private DNS record"
				fi

				moduleID='module.hdb_node.azurerm_storage_account.hanashared[0]'
				if terraform -chdir="${terraform_module_directory}" state rm ${moduleID}; then
					echo "Removed the transport private DNS record"
				fi
				moduleID='module.hdb_node.azurerm_storage_share.hanashared[0]'
				if terraform -chdir="${terraform_module_directory}" state rm ${moduleID}; then
					echo "Removed the transport private DNS record"
				fi

				moduleID='module.hdb_node.azurerm_storage_account.hanashared[1]'
				if terraform -chdir="${terraform_module_directory}" state rm ${moduleID}; then
					echo "Removed the transport private DNS record"
				fi
				moduleID='module.hdb_node.azurerm_storage_share.hanashared[1]'
				if terraform -chdir="${terraform_module_directory}" state rm ${moduleID}; then
					echo "Removed the transport private DNS record"
				fi

			fi

		fi
	fi
fi

echo ""
echo "#########################################################################################"
echo "#                                                                                       #"
echo -e "#                            $cyan Running Terraform plan $reset_formatting                                   #"
echo "#                                                                                       #"
echo "#########################################################################################"
echo ""

if [ -f plan_output.log ]; then
	rm plan_output.log
fi

allParameters=$(printf " -var-file=%s %s %s %s %s" "${var_file}" "${extra_vars}" "${deployment_parameter}" "${version_parameter}" "${deployer_parameter}")

# shellcheck disable=SC2086
if ! terraform -chdir="$terraform_module_directory" plan $allParameters -input=false -detailed-exitcode -compact-warnings -no-color | tee -a plan_output.log; then
	return_value=$?
	echo "Terraform Plan return code:          $return_value"

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
		exit $return_value
	fi
else
	return_value=$?
	echo "Terraform Plan return code:          $return_value"

	echo ""
	echo -e "${cyan}Terraform plan:                        succeeded$reset_formatting"
	echo ""

fi

apply_needed=1

state_path="SYSTEM"
if [ 1 != $return_value ]; then

	if [ "${deployment_system}" == sap_deployer ]; then
		state_path="DEPLOYER"

		if ! terraform -chdir="${terraform_module_directory}" output | grep "No outputs"; then

			deployer_public_ip_address=$(terraform -chdir="${terraform_module_directory}" output deployer_public_ip_address | tr -d \")
			save_config_var "deployer_public_ip_address" "${system_config_information}"

			keyvault=$(terraform -chdir="${terraform_module_directory}" output -no-color -raw deployer_kv_user_name | tr -d \")
			if [ -n "$keyvault" ]; then
				save_config_var "keyvault" "${system_config_information}"
			fi
			if [ 1 == $called_from_ado ]; then

				if [[ "$TF_VAR_use_webapp" == "true" && $IS_PIPELINE_DEPLOYMENT = "true" ]]; then
					webapp_url_base=$(terraform -chdir="${terraform_module_directory}" output -no-color -raw webapp_url_base | tr -d \")

					if [ -n "$webapp_url_base" ]; then
						az_var=$(az pipelines variable-group variable list --group-id "${VARIABLE_GROUP_ID}" --query "WEBAPP_URL_BASE.value")
						if [ -z "${az_var}" ]; then
							az pipelines variable-group variable create --group-id "${VARIABLE_GROUP_ID}" --name WEBAPP_URL_BASE --value "$webapp_url_base" --output none --only-show-errors
						else
							az pipelines variable-group variable update --group-id "${VARIABLE_GROUP_ID}" --name WEBAPP_URL_BASE --value "$webapp_url_base" --output none --only-show-errors
						fi
					fi

					webapp_id=$(terraform -chdir="${terraform_module_directory}" output -no-color -raw webapp_id | tr -d \")
					if [ -n "$webapp_id" ]; then
						az_var=$(az pipelines variable-group variable list --group-id "${VARIABLE_GROUP_ID}" --query "WEBAPP_ID.value")
						if [ -z "${az_var}" ]; then
							az pipelines variable-group variable create --group-id "${VARIABLE_GROUP_ID}" --name WEBAPP_ID --value "$webapp_id" --output none --only-show-errors
						else
							az pipelines variable-group variable update --group-id "${VARIABLE_GROUP_ID}" --name WEBAPP_ID --value "$webapp_id" --output none --only-show-errors
						fi
					fi

					msi_object_id=$(terraform -chdir="${terraform_module_directory}" output -no-color -raw deployer_user_assigned_identity | tr -d \")

					if [ -n "$msi_object_id" ]; then
						az_var=$(az pipelines variable-group variable list --group-id "${VARIABLE_GROUP_ID}" --query "MSI_ID.value")
						if [ -z "${az_var}" ]; then
							az pipelines variable-group variable create --group-id "${VARIABLE_GROUP_ID}" --name MSI_ID --value "$msi_object_id" --output none --only-show-errors
						else
							az pipelines variable-group variable update --group-id "${VARIABLE_GROUP_ID}" --name MSI_ID --value "$msi_object_id" --output none --only-show-errors
						fi
					fi

				fi
			fi

		fi

	fi

	if [ "${deployment_system}" == sap_landscape ]; then
		state_path="LANDSCAPE"
		if [ $landscape_tfstate_key_exists == false ]; then
			save_config_vars "${system_config_information}" \
				landscape_tfstate_key
		fi
	fi

	if [ "${deployment_system}" == sap_library ]; then
		state_path="LIBRARY"
		if ! terraform -chdir="${terraform_module_directory}" output | grep "No outputs"; then
			tfstate_resource_id=$(terraform -chdir="${terraform_module_directory}" output tfstate_resource_id | tr -d \")
			STATE_SUBSCRIPTION=$(echo "$tfstate_resource_id" | cut -d/ -f3 | tr -d \" | xargs)

			az account set --sub "${STATE_SUBSCRIPTION}"

			REMOTE_STATE_SA=$(terraform -chdir="${terraform_module_directory}" output -no-color -raw remote_state_storage_account_name | tr -d \")

			getAndStoreTerraformStateStorageAccountDetails "${REMOTE_STATE_SA}" "${system_config_information}"

			if [ 1 == "$called_from_ado" ]; then
				SAPBITS=$(terraform -chdir="${terraform_module_directory}" output -no-color -raw sapbits_storage_account_name | tr -d \")
				if [ -n "${SAPBITS}" ]; then
					az_var=$(az pipelines variable-group variable list --group-id "${VARIABLE_GROUP_ID}" --query "INSTALLATION_MEDIA_ACCOUNT.value")
					if [ -z "${az_var}" ]; then
						az pipelines variable-group variable create --group-id "${VARIABLE_GROUP_ID}" --name INSTALLATION_MEDIA_ACCOUNT --value "$SAPBITS" --output none --only-show-errors
					else
						az pipelines variable-group variable update --group-id "${VARIABLE_GROUP_ID}" --name INSTALLATION_MEDIA_ACCOUNT --value "$SAPBITS" --output none --only-show-errors
					fi
				fi
			fi
		fi
	fi

	apply_needed=1

fi

useSAS=$(az storage account show --name "${REMOTE_STATE_SA}" --query allowSharedKeyAccess --subscription "${STATE_SUBSCRIPTION}" --out tsv)

if [ "$useSAS" = "true" ]; then
	echo "Storage Account authentication:      key"
	export ARM_USE_AZUREAD=false
else
	echo "Storage Account authentication:      Entra ID"
	export ARM_USE_AZUREAD=true
fi

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
	az storage blob upload --file "${parameterfile}" --container-name tfvars/LANDSCAPE/"${key}" --name "${parameterfile_name}" --subscription "${STATE_SUBSCRIPTION}" --account-name "${REMOTE_STATE_SA}" --no-progress --overwrite --only-show-errors --output none
else
	az storage blob upload --file "${parameterfile}" --container-name tfvars/LANDSCAPE/"${key}" --name "${parameterfile_name}" --subscription "${STATE_SUBSCRIPTION}" --account-name "${REMOTE_STATE_SA}" --no-progress --overwrite --auth-mode login --only-show-errors --output none
fi

fatal_errors=0

# SAP Library
if ! testIfResourceWouldBeRecreated "module.sap_library.azurerm_storage_account.storage_sapbits" "plan_output.log" "SAP Library Storage Account"; then
	fatal_errors=1
fi

# SAP Library sapbits
if ! testIfResourceWouldBeRecreated "module.sap_library.azurerm_storage_container.storagecontainer_sapbits" "plan_output.log" "SAP Library Storage Account container"; then
	fatal_errors=1
fi

# Terraform State Library
if ! testIfResourceWouldBeRecreated "module.sap_library.azurerm_storage_account.storage_tfstate" "plan_output.log" "Terraform State Storage Account"; then
	fatal_errors=1
fi

# Terraform state container
if ! testIfResourceWouldBeRecreated "module.sap_library.azurerm_storage_container.storagecontainer_tfstate" "plan_output.log" "Terraform State Storage Account"; then
	fatal_errors=1
fi

# HANA VM
if ! testIfResourceWouldBeRecreated "module.hdb_node.azurerm_linux_virtual_machine.vm_dbnode" "plan_output.log" "Database server(s)"; then
	fatal_errors=1
fi

# HANA VM disks
if ! testIfResourceWouldBeRecreated "module.hdb_node.azurerm_managed_disk.data_disk" "plan_output.log" "Database server disk(s)"; then
	fatal_errors=1
fi

# AnyDB server
if ! testIfResourceWouldBeRecreated "module.anydb_node.azurerm_windows_virtual_machine.dbserver" "plan_output.log" "Database server(s)"; then
	fatal_errors=1
fi

if ! testIfResourceWouldBeRecreated "module.anydb_node.azurerm_linux_virtual_machine.dbserver" "plan_output.log" "Database server(s)"; then
	fatal_errors=1
fi

# AnyDB disks
if ! testIfResourceWouldBeRecreated "module.anydb_node.azurerm_managed_disk.disks" "plan_output.log" "Database server disk(s)"; then
	fatal_errors=1
fi

# App server
if ! testIfResourceWouldBeRecreated "module.app_tier.azurerm_windows_virtual_machine.app" "plan_output.log" "Application server(s)"; then
	fatal_errors=1
fi

if ! testIfResourceWouldBeRecreated "module.app_tier.azurerm_linux_virtual_machine.app" "plan_output.log" "Application server(s)"; then
	fatal_errors=1
fi

# App server disks
if ! testIfResourceWouldBeRecreated "module.app_tier.azurerm_managed_disk.app" "plan_output.log" "Application server disk(s)"; then
	fatal_errors=1
fi

# SCS server
if ! testIfResourceWouldBeRecreated "module.app_tier.azurerm_windows_virtual_machine.scs" "plan_output.log" "SCS server(s)"; then
	fatal_errors=1
fi

if ! testIfResourceWouldBeRecreated "module.app_tier.azurerm_linux_virtual_machine.scs" "plan_output.log" "SCS server(s)"; then
	fatal_errors=1
fi

# SCS server disks
if ! testIfResourceWouldBeRecreated "module.app_tier.azurerm_managed_disk.scs" "plan_output.log" "SCS server disk(s)"; then
	fatal_errors=1
fi

# Web server
if ! testIfResourceWouldBeRecreated "module.app_tier.azurerm_windows_virtual_machine.web" "plan_output.log" "Web server(s)"; then
	fatal_errors=1
fi

if ! testIfResourceWouldBeRecreated "module.app_tier.azurerm_linux_virtual_machine.web" "plan_output.log" "Web server(s)"; then
	fatal_errors=1
fi

# Web dispatcher server disks
if ! testIfResourceWouldBeRecreated "module.app_tier.azurerm_managed_disk.web" "plan_output.log" "Web server disk(s)"; then
	fatal_errors=1
fi

echo "TEST_ONLY:  $TEST_ONLY"
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

	if [ $fatal_errors == 1 ]; then
		apply_needed=0
		echo ""
		echo "#########################################################################################"
		echo "#                                                                                       #"
		echo -e "#                               $bold_red_underscore!!! Risk for Data loss !!!$reset_formatting                              #"
		echo "#                                                                                       #"
		echo "#        Please inspect the output of Terraform plan carefully before proceeding        #"
		echo "#                                                                                       #"
		echo "#########################################################################################"
		echo ""
		exit 10
	fi
	exit 0
fi

if [ $fatal_errors == 1 ]; then
	apply_needed=0
	echo ""
	echo "#########################################################################################"
	echo "#                                                                                       #"
	echo -e "#                               $bold_red_underscore!!! Risk for Data loss !!!$reset_formatting                              #"
	echo "#                                                                                       #"
	echo "#        Please inspect the output of Terraform plan carefully before proceeding        #"
	echo "#                                                                                       #"
	echo "#########################################################################################"
	echo ""
	if [ 1 == "$called_from_ado" ]; then
		unset TF_DATA_DIR
		echo "Risk for data loss, Please inspect the output of Terraform plan carefully. Run manually from deployer" >"${system_config_information}".err
		echo ##vso[task.logissue type=error]Risk for data loss, Please inspect the output of Terraform plan carefully. Run manually from deployer
		exit 1
	fi

	if [ 1 == $force ]; then
		apply_needed=1
	else
		read -r -p "Do you want to continue with the deployment Y/N? " ans
		answer=${ans^^}
		if [ "$answer" == 'Y' ]; then
			apply_needed=true
		else
			unset TF_DATA_DIR
			exit 1
		fi
	fi

fi

if [ 1 == $apply_needed ]; then

	if [ -f error.log ]; then
		rm error.log
	fi
	if [ -f plan_output.log ]; then
		rm plan_output.log
	fi

	echo ""
	echo "#########################################################################################"
	echo "#                                                                                       #"
	echo -e "#                            $cyan Running Terraform apply $reset_formatting                                  #"
	echo "#                                                                                       #"
	echo "#########################################################################################"
	echo ""

	      allParameters=$(printf " -var-file=%s %s %s %s %s " "${var_file}" "${extra_vars}" "${deployment_parameter}" "${version_parameter}" "${approve}")
	allImportParameters=$(printf " -var-file=%s %s %s %s " "${var_file}" "${extra_vars}" "${deployment_parameter}" "${version_parameter}")

	if [ -n "${approve}" ]; then
		# shellcheck disable=SC2086
		if ! terraform -chdir="${terraform_module_directory}" apply -parallelism="${parallelism}" -no-color -compact-warnings -json -input=false $allParameters | tee -a apply_output.json; then
			return_value=$?
		else
			echo ""
			echo -e "${cyan}Terraform apply:                       succeeded$reset_formatting"
			echo ""
			return_value=0
		fi

	else
		# shellcheck disable=SC2086
		if ! terraform -chdir="${terraform_module_directory}" apply -parallelism="${parallelism}" -input=false $allParameters | tee -a apply_output.json; then
			return_value=$?
		else
			return_value=0
		fi
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
				echo -e "${cyan}Retrying Terraform apply:$reset_formatting"

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
fi
if [ -f apply_output.json ]; then
	rm apply_output.json
fi

if [ 1 == $return_value ]; then
	echo ""
	echo "#########################################################################################"
	echo "#                                                                                       #"
	echo -e "#                       $bold_red_underscore!!! Errors during the apply phase !!!$reset_formatting                           #"
	echo "#                                                                                       #"
	echo "#########################################################################################"
	echo ""
	unset TF_DATA_DIR
	exit $return_value
fi

if [ "${deployment_system}" == sap_deployer ]; then

	# terraform -chdir="${terraform_module_directory}"  output
	if ! terraform -chdir="${terraform_module_directory}" output | grep "No outputs"; then

		deployer_random_id=$(terraform -chdir="${terraform_module_directory}" output -no-color -raw random_id | tr -d \")
		if [ -n "${deployer_random_id}" ]; then
			save_config_var "deployer_random_id" "${system_config_information}"
			custom_random_id="${deployer_random_id:0:3}"
			sed -i -e /"custom_random_id"/d "${parameterfile}"
			printf "# The parameter 'custom_random_id' can be used to control the random 3 digits at the end of the storage accounts and key vaults\ncustom_random_id=\"%s\"\n" "${custom_random_id}" >>"${var_file}"
		fi
	fi

	deployer_random_id=$(terraform -chdir="${terraform_module_directory}" output -no-color -raw random_id | tr -d \")
	if [ -n "${deployer_random_id}" ]; then
		save_config_var "deployer_random_id" "${system_config_information}"
		custom_random_id="${deployer_random_id}"
		sed -i -e "" -e /"custom_random_id"/d "${parameterfile}"
		printf "custom_random_id=\"%s\"\n" "${custom_random_id}" >>"${var_file}"

	fi

	deployer_public_ip_address=$(terraform -chdir="${terraform_module_directory}" output -no-color -raw deployer_public_ip_address | tr -d \")
	keyvault=$(terraform -chdir="${terraform_module_directory}" output -no-color -raw deployer_kv_user_name | tr -d \")

	created_resource_group_name=$(terraform -chdir="${terraform_module_directory}" output -no-color -raw created_resource_group_name | tr -d \")
	echo ""
	echo ""
	echo "#########################################################################################"
	echo "#                                                                                       #"
	echo -e "#                        $cyan  Capturing telemetry  $reset_formatting                                        #"
	echo "#                                                                                       #"
	echo "#########################################################################################"
	echo ""
	echo ""

	full_script_path="$(realpath "${BASH_SOURCE[0]}")"
	script_directory="$(dirname "${full_script_path}")"
	az deployment group create --resource-group "${created_resource_group_name}" --name "ControlPlane_Deployer_${created_resource_group_name}" \
		--template-file "${script_directory}/templates/empty-deployment.json" --output none
	return_value=0
	if [ 1 == $called_from_ado ]; then

		if [ -n "${deployer_random_id}" ]; then
			az_var=$(az pipelines variable-group variable list --group-id "${VARIABLE_GROUP_ID}" --query "DEPLOYER_RANDOM_ID.value")
			if [ -z "${az_var}" ]; then
				az pipelines variable-group variable create --group-id "${VARIABLE_GROUP_ID}" --name DEPLOYER_RANDOM_ID --value "${deployer_random_id}" --output none --only-show-errors
			else
				az pipelines variable-group variable update --group-id "${VARIABLE_GROUP_ID}" --name DEPLOYER_RANDOM_ID --value "${deployer_random_id}" --output none --only-show-errors
			fi
		fi

		if [ -n "${created_resource_group_name}" ]; then
			az_var=$(az pipelines variable-group variable list --group-id "${VARIABLE_GROUP_ID}" --query "WEBAPP_RESOURCE_GROUP.value")
			if [ -z "${az_var}" ]; then
				az pipelines variable-group variable create --group-id "${VARIABLE_GROUP_ID}" --name WEBAPP_RESOURCE_GROUP --value "$created_resource_group_name" --output none --only-show-errors
			else
				az pipelines variable-group variable update --group-id "${VARIABLE_GROUP_ID}" --name WEBAPP_RESOURCE_GROUP --value "$created_resource_group_name" --output none --only-show-errors
			fi
		fi

		if [[ "${TF_VAR_use_webapp}" == "true" && $IS_PIPELINE_DEPLOYMENT = "true" ]]; then
			webapp_url_base=$(terraform -chdir="${terraform_module_directory}" output -no-color -raw webapp_url_base | tr -d \")
			if [ -n "${webapp_url_base}" ]; then
				az_var=$(az pipelines variable-group variable list --group-id "${VARIABLE_GROUP_ID}" --query "WEBAPP_URL_BASE.value")
				if [ -z "${az_var}" ]; then
					az pipelines variable-group variable create --group-id "${VARIABLE_GROUP_ID}" --name WEBAPP_URL_BASE --value "$webapp_url_base" --output none --only-show-errors
				else
					az pipelines variable-group variable update --group-id "${VARIABLE_GROUP_ID}" --name WEBAPP_URL_BASE --value "$webapp_url_base" --output none --only-show-errors
				fi
			fi

			webapp_identity=$(terraform -chdir="${terraform_module_directory}" output -no-color -raw webapp_identity | tr -d \")
			if [ -n "${webapp_identity}" ]; then
				az_var=$(az pipelines variable-group variable list --group-id "${VARIABLE_GROUP_ID}" --query "WEBAPP_IDENTITY.value")
				if [ -z "${az_var}" ]; then
					az pipelines variable-group variable create --group-id "${VARIABLE_GROUP_ID}" --name WEBAPP_IDENTITY --value "$webapp_identity" --output none --only-show-errors
				else
					az pipelines variable-group variable update --group-id "${VARIABLE_GROUP_ID}" --name WEBAPP_IDENTITY --value "$webapp_identity" --output none --only-show-errors
				fi
			fi

			webapp_id=$(terraform -chdir="${terraform_module_directory}" output -no-color -raw webapp_id | tr -d \")
			if [ -n "${webapp_id}" ]; then
				az_var=$(az pipelines variable-group variable list --group-id "${VARIABLE_GROUP_ID}" --query "WEBAPP_ID.value")
				if [ -z "${az_var}" ]; then
					az pipelines variable-group variable create --group-id "${VARIABLE_GROUP_ID}" --name WEBAPP_ID --value "$webapp_id" --output none --only-show-errors
				else
					az pipelines variable-group variable update --group-id "${VARIABLE_GROUP_ID}" --name WEBAPP_ID --value "$webapp_id" --output none --only-show-errors
				fi
			fi
		fi
	fi

fi

if valid_kv_name "$keyvault"; then
	save_config_var "keyvault" "${system_config_information}"
else
	printf -v val %-40.40s "$keyvault"
	echo "#########################################################################################"
	echo "#                                                                                       #"
	echo -e "#       The provided keyvault is not valid:$bold_red ${val} $reset_formatting  #"
	echo "#                                                                                       #"
	echo "#########################################################################################"
	echo "The provided keyvault is not valid " "${val}" >secret.err
fi

save_config_var "deployer_public_ip_address" "${system_config_information}"

if [ "${deployment_system}" == sap_system ]; then

	rg_name=$(terraform -chdir="${terraform_module_directory}" output -no-color -raw created_resource_group_name | tr -d \")

	echo ""
	echo ""
	echo "#########################################################################################"
	echo "#                                                                                       #"
	echo -e "#                        $cyan  Capturing telemetry  $reset_formatting                                        #"
	echo "#                                                                                       #"
	echo "#########################################################################################"
	echo ""
	echo ""
	full_script_path="$(realpath "${BASH_SOURCE[0]}")"
	script_directory="$(dirname "${full_script_path}")"
	az deployment group create --resource-group "${rg_name}" --name "SAP_${rg_name}" --subscription "$ARM_SUBSCRIPTION_ID" \
		--template-file "${script_directory}/templates/empty-deployment.json" --output none

fi

if [ "${deployment_system}" == sap_landscape ]; then
	save_config_vars "${system_config_information}" \
		landscape_tfstate_key

	rg_name=$(terraform -chdir="${terraform_module_directory}" output -no-color -raw created_resource_group_name | tr -d \")
	echo ""
	echo ""
	echo "#########################################################################################"
	echo "#                                                                                       #"
	echo -e "#                        $cyan  Capturing telemetry  $reset_formatting                                        #"
	echo "#                                                                                       #"
	echo "#########################################################################################"
	echo ""
	echo ""
	full_script_path="$(realpath "${BASH_SOURCE[0]}")"
	script_directory="$(dirname "${full_script_path}")"
	az deployment group create --resource-group "${rg_name}" --name "SAP-WORKLOAD-ZONE_${rg_name}" --subscription "$ARM_SUBSCRIPTION_ID" \
		--template-file "${script_directory}/templates/empty-deployment.json" --output none
fi

if [ "${deployment_system}" == sap_library ]; then
	REMOTE_STATE_SA=$(terraform -chdir="${terraform_module_directory}" output -no-color -raw remote_state_storage_account_name | tr -d \")
	sapbits_storage_account_name=$(terraform -chdir="${terraform_module_directory}" output -no-color -raw sapbits_storage_account_name | tr -d \")

	library_random_id=$(terraform -chdir="${terraform_module_directory}" output -no-color -raw random_id | tr -d \")
	if [ -n "${library_random_id}" ]; then
		save_config_var "library_random_id" "${system_config_information}"
		custom_random_id="${library_random_id:0:3}"
		sed -i -e /"custom_random_id"/d "${parameterfile}"
		printf "# The parameter 'custom_random_id' can be used to control the random 3 digits at the end of the storage accounts and key vaults\ncustom_random_id=\"%s\"\n" "${custom_random_id}" >>"${var_file}"

	fi
	if [ 1 == $called_from_ado ]; then

		if [ -n "${sapbits_storage_account_name}" ]; then
			az_var=$(az pipelines variable-group variable list --group-id "${VARIABLE_GROUP_ID}" --query "INSTALLATION_MEDIA_ACCOUNT.value")
			if [ -z "${az_var}" ]; then
				az pipelines variable-group variable create --group-id "${VARIABLE_GROUP_ID}" --name INSTALLATION_MEDIA_ACCOUNT --value "${sapbits_storage_account_name}" --output none --only-show-errors
			else
				az pipelines variable-group variable update --group-id "${VARIABLE_GROUP_ID}" --name INSTALLATION_MEDIA_ACCOUNT --value "${sapbits_storage_account_name}" --output none --only-show-errors
			fi
		fi
		if [ -n "${library_random_id}" ]; then
			az_var=$(az pipelines variable-group variable list --group-id "${VARIABLE_GROUP_ID}" --query "LIBRARY_RANDOM_ID.value")
			if [ -z "${az_var}" ]; then
				az pipelines variable-group variable create --group-id "${VARIABLE_GROUP_ID}" --name LIBRARY_RANDOM_ID --value "${library_random_id}" --output none --only-show-errors
			else
				az pipelines variable-group variable update --group-id "${VARIABLE_GROUP_ID}" --name LIBRARY_RANDOM_ID --value "${library_random_id}" --output none --only-show-errors
			fi
		fi

	fi

	getAndStoreTerraformStateStorageAccountDetails "${REMOTE_STATE_SA}" "${system_config_information}"
	rg_name=$(terraform -chdir="${terraform_module_directory}" output -no-color -raw created_resource_group_name | tr -d \")

	echo ""
	echo ""
	echo "#########################################################################################"
	echo "#                                                                                       #"
	echo -e "#                        $cyan  Capturing telemetry  $reset_formatting                                        #"
	echo "#                                                                                       #"
	echo "#########################################################################################"
	echo ""
	echo ""

	full_script_path="$(realpath "${BASH_SOURCE[0]}")"
	script_directory="$(dirname "${full_script_path}")"
	az deployment group create --resource-group "${rg_name}" --name "SAP-LIBRARY_${rg_name}" --template-file "${script_directory}/templates/empty-deployment.json" --output none

fi

if [ -f "${system_config_information}".err ]; then
	cat "${system_config_information}".err
	rm "${system_config_information}".err
fi

unset TF_DATA_DIR

#################################################################################
#                                                                               #
#                           Copy tfvars to storage account                      #
#                                                                               #
#################################################################################

useSAS=$(az storage account show --name "${REMOTE_STATE_SA}" --query allowSharedKeyAccess --subscription "${STATE_SUBSCRIPTION}" --out tsv)

if [ "$useSAS" = "true" ]; then
	echo "Storage Account authentication:      key"
	az storage blob upload --file "${parameterfile}" --container-name tfvars/"${state_path}"/"${key}" --name "${parameterfile_name}" \
		--subscription "${STATE_SUBSCRIPTION}" --account-name "${REMOTE_STATE_SA}" --no-progress --overwrite --only-show-errors --output none
else
	echo "Storage Account authentication:      Entra ID"
	az storage blob upload --file "${parameterfile}" --container-name tfvars/"${state_path}"/"${key}" --name "${parameterfile_name}" \
		--subscription "${STATE_SUBSCRIPTION}" --account-name "${REMOTE_STATE_SA}" --auth-mode login --no-progress --overwrite --only-show-errors --output none
fi

if [ -f sap-parameters.yaml ]; then
	if [ "${deployment_system}" == sap_system ]; then
		echo "Uploading the yaml files from ${param_dirname} to the storage account"
		if [ "$useSAS" = "true" ]; then
			az storage blob upload --file sap-parameters.yaml --container-name tfvars/"${state_path}"/"${key}" --name sap-parameters.yaml \
				--subscription "${STATE_SUBSCRIPTION}" --account-name "${REMOTE_STATE_SA}" --no-progress --overwrite --only-show-errors --output none
		else
			az storage blob upload --file sap-parameters.yaml --container-name tfvars/"${state_path}"/"${key}" --name sap-parameters.yaml \
				--subscription "${STATE_SUBSCRIPTION}" --account-name "${REMOTE_STATE_SA}" --auth-mode login --no-progress --overwrite --only-show-errors --output none
		fi

		hosts_file=$(ls *_hosts.yaml)
		if [ "$useSAS" = "true" ]; then
			az storage blob upload --file "${hosts_file}" --container-name tfvars/"${state_path}"/"${key}" --name "${hosts_file}" \
				--subscription "${STATE_SUBSCRIPTION}" --account-name "${REMOTE_STATE_SA}" --no-progress --overwrite --only-show-errors --output none
		else
			az storage blob upload --file "${hosts_file}" --container-name tfvars/"${state_path}"/"${key}" --name "${hosts_file}" \
				--subscription "${STATE_SUBSCRIPTION}" --account-name "${REMOTE_STATE_SA}" --auth-mode login --no-progress --overwrite --only-show-errors --output none
		fi
	fi
fi

if [ "${deployment_system}" == sap_landscape ]; then
	if [ "$useSAS" = "true" ]; then
		az storage blob upload --file "${system_config_information}" --container-name tfvars/.sap_deployment_automation --name "${environment}${region_code}${network_logical_name}" \
			--subscription "${STATE_SUBSCRIPTION}" --account-name "${REMOTE_STATE_SA}" --no-progress --overwrite --only-show-errors --output none
	else
		az storage blob upload --file "${system_config_information}" --container-name tfvars/.sap_deployment_automation --name "${environment}${region_code}${network_logical_name}" \
			--subscription "${STATE_SUBSCRIPTION}" --account-name "${REMOTE_STATE_SA}" --auth-mode login --no-progress --overwrite --only-show-errors --output none
	fi
fi
if [ "${deployment_system}" == sap_library ]; then
	deployer_config_information="${automation_config_directory}"/"${environment}""${region_code}"
	if [ "$useSAS" = "true" ]; then
		az storage blob upload --file "${deployer_config_information}" --container-name tfvars/.sap_deployment_automation --name "${environment}${region_code}" \
			--subscription "${STATE_SUBSCRIPTION}" --account-name "${REMOTE_STATE_SA}" --no-progress --overwrite --only-show-errors --output none
	else
		az storage blob upload --file "${deployer_config_information}" --container-name tfvars/.sap_deployment_automation --name "${environment}${region_code}" \
			--subscription "${STATE_SUBSCRIPTION}" --account-name "${REMOTE_STATE_SA}" --auth-mode login --no-progress --overwrite --only-show-errors --output none
	fi
fi

echo ""
echo "#########################################################################################"
echo "#                                                                                       #"
echo -e "#                        $green Deployment completed $reset_formatting                                         #"
echo "#                                                                                       #"
echo "#########################################################################################"
echo ""

exit 0
