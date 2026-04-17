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
        banner_title="Remove $2"
		shift 2
		;;
	-d | --deployer_tfstate_key)
        deployer_tfstate_key="$2"
        CONTROL_PLANE_NAME=$(basename "$deployer_tfstate_key" | cut -d'-' -f1-3)
        CONTROL_PLANE_NAME=$(echo "${CONTROL_PLANE_NAME}" | tr "[:lower:]" "[:upper:]")
        TF_VAR_control_plane_name="$CONTROL_PLANE_NAME"
        export TF_VAR_control_plane_name
        TF_VAR_deployer_tfstate_key="${deployer_tfstate_key}"
        export TF_VAR_deployer_tfstate_key
        shift 2
        ;;
    -l | --landscape_tfstate_key)
        landscape_tfstate_key="$2"
        WORKLOAD_ZONE_NAME=$(echo "$landscape_tfstate_key" | cut -d"-" -f1-3)
        TF_VAR_workload_zone_name="$WORKLOAD_ZONE_NAME"
        TF_VAR_landscape_tfstate_key="${landscape_tfstate_key}"
        export TF_VAR_landscape_tfstate_key
        export TF_VAR_workload_zone_name
        shift 2
        ;;
-i | --auto-approve)
		approve="--auto-approve"
		shift
		;;
	-a | --ado)
		called_from_ado=1
        TF_IN_AUTOMATION=true
        export TF_IN_AUTOMATION
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


if [ "${DEBUG:-false}" == true ]; then
    echo -e "${cyan}Enabling debug mode$reset_formatting"
    set -x
    set -o errexit
fi

echo "Parameter file:                      $parameterfile"
echo "Current directory:                   $(pwd)"
echo "Terraform state subscription_id:     ${STATE_SUBSCRIPTION}"
echo "Terraform state storageaccount name: ${REMOTE_STATE_SA}"

parameterfile_name=$(basename "${parameterfile}")
param_dirname=$(dirname "${parameterfile}")

if [ -n "${CONTROL_PLANE_NAME}" ]; then
    if [ -z "${deployer_tfstate_key}" ]; then
        deployer_tfstate_key="${CONTROL_PLANE_NAME}-INFRASTRUCTURE.terraform.tfstate"
    fi
fi

if [ "${param_dirname}" != '.' ]; then
    print_banner "Installer" "Please run this command from the folder containing the parameter file" "error"
    exit 3
fi

if [ ! -f "${parameterfile}" ]; then
    printf -v val %-35.35s "$parameterfile"
    print_banner "Installer" "Parameter file does not exist: ${val}" "error"
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

if [ "${deployment_system}" == sap_system ] || [ "${deployment_system}" == sap_landscape ]; then
    WORKLOAD_ZONE_NAME=$(echo "$parameterfile_name" | cut -d'-' -f1-3)
    if [ -n "$WORKLOAD_ZONE_NAME" ]; then
        landscape_tfstate_key="${WORKLOAD_ZONE_NAME}-INFRASTRUCTURE.terraform.tfstate"
        TF_VAR_workload_zone_name="$WORKLOAD_ZONE_NAME"
        TF_VAR_landscape_tfstate_key="${landscape_tfstate_key}"
        export TF_VAR_landscape_tfstate_key
        export TF_VAR_workload_zone_name
    fi
fi

# Check that the exports ARM_SUBSCRIPTION_ID and SAP_AUTOMATION_REPO_PATH are defined
validate_exports
return_code=$?
if [ 0 != $return_code ]; then
    echo "Missing exports" >"${system_environment_file_name}".err
    exit $return_code
fi

# Check that Terraform and Azure CLI is installed
validate_dependencies
return_code=$?
if [ 0 != $return_code ]; then
    echo "Missing software" >"${system_environment_file_name}".err
    exit $return_code
fi

# Check that parameter files have environment and location defined
validate_key_parameters "$parameterfile_name"
return_code=$?
if [ 0 != $return_code ]; then
    echo "Missing parameters in $parameterfile_name" >"${system_environment_file_name}".err
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

if [ "${deployment_system}" == sap_deployer ]; then
    banner_title="Remove Deployer"
    deployer_tfstate_key=${key}.terraform.tfstate
    ARM_SUBSCRIPTION_ID=$STATE_SUBSCRIPTION
    export ARM_SUBSCRIPTION_ID

fi

network_logical_name=""

if [ "${deployment_system}" == sap_system ]; then
    banner_title="Remove SAP System Infrastructure"
    load_config_vars "$parameterfile_name" "network_logical_name"
    network_logical_name=$(echo "${network_logical_name}" | tr "[:lower:]" "[:upper:]")
fi

#Persisting the parameters across executions

automation_config_directory="$CONFIG_REPO_PATH/.sap_deployment_automation"
generic_environment_file_name="${automation_config_directory}/config"

if [ -n "$landscape_tfstate_key" ]; then
    environment=$(basename "$landscape_tfstate_key" | awk -F'-' '{print $1}' | xargs)
    region_code=$(basename "$landscape_tfstate_key" | awk -F'-' '{print $2}' | xargs)
    network_logical_name=$(basename "$landscape_tfstate_key" | awk -F'-' '{print $3}' | xargs)
else
    environment=$(echo "$key" | awk -F'-' '{print $1}' | xargs)
    region_code=$(echo "$key" | awk -F'-' '{print $2}' | xargs)
    network_logical_name=$(echo "$key" | awk -F'-' '{print $3}' | xargs)
fi

if [ -v SYSTEM_CONFIGURATION_FILE ]; then
    system_environment_file_name=$SYSTEM_CONFIGURATION_FILE
else
    system_environment_file_name=$(get_configuration_file "$automation_config_directory" "$environment" "$region_code" "$network_logical_name")
fi

this_ip=$(curl -s ipinfo.io/ip) >/dev/null 2>&1
export TF_VAR_Agent_IP=$this_ip
echo "Agent IP:                            $this_ip"

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

if [[ -z $STATE_SUBSCRIPTION ]]; then
    load_config_vars "${system_environment_file_name}" "STATE_SUBSCRIPTION"
else

    if is_valid_guid "$STATE_SUBSCRIPTION"; then
        save_config_var "STATE_SUBSCRIPTION" "${system_environment_file_name}"
    else
        printf -v val %-40.40s "$STATE_SUBSCRIPTION"
        print_banner "Installer" "The provided state_subscription is not valid: ${val}" "error"
        exit 65
    fi

fi

param_dirname=$(pwd)
export TF_DATA_DIR="${param_dirname}/.terraform"

init "${automation_config_directory}" "${generic_environment_file_name}" "${system_environment_file_name}"

if [[ -z $REMOTE_STATE_SA ]]; then
    load_config_vars "${system_environment_file_name}" "REMOTE_STATE_SA"
else
    save_config_vars "${system_environment_file_name}" REMOTE_STATE_SA
fi

if [ ! -v tfstate_resource_id ]; then
    if [ -n "${REMOTE_STATE_SA}" ]; then
        getAndStoreTerraformStateStorageAccountDetails "${REMOTE_STATE_SA}" "${system_environment_file_name}"
    fi

fi

var_file="${param_dirname}"/"${parameterfile}"

if [[ -z $deployer_tfstate_key ]]; then
    load_config_vars "${system_environment_file_name}" "deployer_tfstate_key"
else
    save_config_var "deployer_tfstate_key" "${system_environment_file_name}"
fi

if [ "${deployment_system}" != sap_deployer ]; then
    if [ -z "${deployer_tfstate_key}" ]; then
        if [ 1 != $called_from_ado ]; then
            read -r -p "Deployer terraform statefile name: " deployer_tfstate_key

            save_config_var "deployer_tfstate_key" "${system_environment_file_name}"
        else
            print_banner "Installer" "Deployer terraform statefile name is missing" "error"
            unset TF_DATA_DIR
            exit 2
        fi
    fi
else
	keyvault=""
    load_config_vars "${system_environment_file_name}" "keyvault"
	if [ -n "${keyvault}" ]; then
    	TF_VAR_spn_keyvault_id=$(az resource list --name "${keyvault}" --subscription "${STATE_SUBSCRIPTION}" --resource-type Microsoft.KeyVault/vaults --query "[].id | [0]" -o tsv)
    	export TF_VAR_spn_keyvault_id
	fi

    echo "Deployer Keyvault ID:                $TF_VAR_spn_keyvault_id"

    export ARM_SUBSCRIPTION_ID=$STATE_SUBSCRIPTION

fi

echo "Configuration file:                  $system_environment_file_name"
echo "Deployment region:                   $region"
echo "Deployment region code:              $region_code"
echo "Parallelism count:                   $parallelism"
echo "Deployer state file name:            ${deployer_tfstate_key}"
echo "Target subscription:                 $ARM_SUBSCRIPTION_ID"

TF_VAR_deployer_tfstate_key="${deployer_tfstate_key}"
export TF_VAR_deployer_tfstate_key

useSAS=$(az storage account show --name "${REMOTE_STATE_SA}" --query allowSharedKeyAccess --subscription "${STATE_SUBSCRIPTION}" --out tsv)

if [ "$useSAS" = "true" ]; then
    echo "Storage Account Authentication:      Key"
    AZURE_STORAGE_AUTH_MODE=key
    export AZURE_STORAGE_AUTH_MODE
    export ARM_USE_AZUREAD=false
else
    echo "Storage Account Authentication:      Entra ID"
    AZURE_STORAGE_AUTH_MODE=login
    export AZURE_STORAGE_AUTH_MODE
    export ARM_USE_AZUREAD=true
fi

if [[ -z $landscape_tfstate_key ]]; then
    load_config_vars "${system_environment_file_name}" "landscape_tfstate_key"
else
    echo "Workload zone state file:            ${landscape_tfstate_key}"
    save_config_vars "${system_environment_file_name}" landscape_tfstate_key
fi

if [ "${deployment_system}" == sap_system ]; then
    if [ -z "${landscape_tfstate_key}" ]; then
        if [ 1 != $called_from_ado ]; then
            read -r -p "Workload terraform statefile name: " landscape_tfstate_key

            save_config_var "landscape_tfstate_key" "${system_environment_file_name}"

        else
            print_banner "Installer" "Workload zone terraform statefile name is missing" "error"
            unset TF_DATA_DIR
            exit 2
        fi
    fi
fi

if [ "${deployment_system}" == sap_system ]; then

    if [[ -n $landscape_tfstate_key ]]; then
        workloadZone_State_file_Size_String=$(az storage blob list --container-name tfstate --account-name "${REMOTE_STATE_SA}" --subscription "${STATE_SUBSCRIPTION}" --query "[?name=='$landscape_tfstate_key'].properties.contentLength" --output tsv)

        workloadZone_State_file_Size=$(("$workloadZone_State_file_Size_String"))

        if [ "$workloadZone_State_file_Size" -lt 50000 ]; then
            print_banner "Installer" "Workload zone terraform state file ('$landscape_tfstate_key') is empty" "error"
            az storage blob list --container-name tfstate --account-name "${REMOTE_STATE_SA}" --subscription "${STATE_SUBSCRIPTION}" --query "[].{name:name,size:properties.contentLength,lease:lease.status}" --output table
        fi
    fi

    if [[ -n $deployer_tfstate_key ]]; then

        deployer_Statefile_Size_String=$(az storage blob list --container-name tfstate --account-name "${REMOTE_STATE_SA}" --subscription "${STATE_SUBSCRIPTION}" --query "[?name=='$deployer_tfstate_key'].properties.contentLength" --output tsv)

        deployer_Statefile_Size=$(("$deployer_Statefile_Size_String"))

        if [ "$deployer_Statefile_Size" -lt 50000 ]; then
            print_banner "Installer" "Deployer terraform state file ('$deployer_tfstate_key') is empty" "error"

            az storage blob list --container-name tfstate --account-name "${REMOTE_STATE_SA}" --subscription "${STATE_SUBSCRIPTION}" --query "[].{name:name,size:properties.contentLength,lease:lease.status}" --output table
        fi
    fi
fi

if [ "${deployment_system}" == sap_landscape ]; then

    if [[ -n $deployer_tfstate_key ]]; then

        deployer_Statefile_Size_String=$(az storage blob list --container-name tfstate --account-name "${REMOTE_STATE_SA}" --subscription "${STATE_SUBSCRIPTION}" --query "[?name=='$deployer_tfstate_key'].properties.contentLength" --output tsv)

        deployer_Statefile_Size=$(("$deployer_Statefile_Size_String"))

        if [ "$deployer_Statefile_Size" -lt 50000 ]; then
            print_banner "Installer" "Deployer terraform state file ('$deployer_tfstate_key') is empty" "error"

            az storage blob list --container-name tfstate --account-name "${REMOTE_STATE_SA}" --subscription "${STATE_SUBSCRIPTION}" --query "[].{name:name,size:properties.contentLength,lease:lease.status}" --output table
        fi
    fi
fi

#setting the user environment variables
# Obsolete now that Terraform handles the authentication without depending on environment variables
#set_executing_user_environment_variables "none"

if [[ -n ${subscription} ]]; then
    if is_valid_guid "${subscription}"; then
        echo "Valid subscription format"
    else
        printf -v val %-40.40s "$subscription"
        print_banner "Installer" "The provided subscription is not valid: ${val}" "error"
        exit 65
    fi
    export ARM_SUBSCRIPTION_ID="${subscription}"
fi

if [[ -z ${REMOTE_STATE_SA} ]]; then
    if [ 1 != $called_from_ado ]; then
        read -r -p "Terraform state storage account name: " REMOTE_STATE_SA

        getAndStoreTerraformStateStorageAccountDetails "${REMOTE_STATE_SA}" "${system_environment_file_name}"
        load_config_vars "${system_environment_file_name}" "STATE_SUBSCRIPTION" "REMOTE_STATE_RG" "tfstate_resource_id"
    fi
fi

if [ -z "${REMOTE_STATE_SA}" ]; then
    missing "REMOTE_STATE_SA"
    exit 1
fi

if [[ -z ${REMOTE_STATE_RG} ]]; then
    getAndStoreTerraformStateStorageAccountDetails "${REMOTE_STATE_SA}" "${system_environment_file_name}"
    load_config_vars "${system_environment_file_name}" "STATE_SUBSCRIPTION" "REMOTE_STATE_RG" "tfstate_resource_id"
fi

if [[ -z ${tfstate_resource_id} ]]; then
    getAndStoreTerraformStateStorageAccountDetails "${REMOTE_STATE_SA}" "${system_environment_file_name}"
    load_config_vars "${system_environment_file_name}" "STATE_SUBSCRIPTION" "REMOTE_STATE_RG" "tfstate_resource_id"

fi

if [ -n "${tfstate_resource_id}" ]; then
    TF_VAR_tfstate_resource_id="${tfstate_resource_id}"
    export TF_VAR_tfstate_resource_id
fi

if [ -n "${landscape_tfstate_key}" ]; then
    TF_VAR_landscape_tfstate_key="${landscape_tfstate_key}"
    export TF_VAR_landscape_tfstate_key
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

export TF_DATA_DIR="${param_dirname}/.terraform"

terraform --version
echo ""
echo -e "${green}Terraform details:"
echo -e "-------------------------------------------------------------------------${reset_formatting}"
echo "Subscription:                        ${STATE_SUBSCRIPTION}"
echo "Storage Account:                     ${REMOTE_STATE_SA}"
echo "Resource Group:                      ${REMOTE_STATE_RG}"
echo "State file:                          ${key}.terraform.tfstate"
echo "Target subscription:                 ${ARM_SUBSCRIPTION_ID}"
echo "Deployer state file:                 ${deployer_tfstate_key}"
echo "Workload zone state file:            ${landscape_tfstate_key}"
echo "Terraform state resource id:         ${tfstate_resource_id}"
echo "Current directory:                   $(pwd)"
echo ""
TF_VAR_subscription_id="$ARM_SUBSCRIPTION_ID"
export TF_VAR_subscription_id

terraform_storage_account_name=$(echo "$tfstate_resource_id" | cut -d '/' -f 9 | tr -d '\r')
terraform_storage_account_subscription_id=$(echo "$tfstate_resource_id" | cut -d '/' -f 3 | tr -d '\r')
terraform_storage_account_resource_group_name=$(echo "$tfstate_resource_id" | cut -d '/' -f 5 | tr -d '\r')

if [ "${terraform_storage_account_name}" != "${REMOTE_STATE_SA}" ]; then
    tfstate_resource_id=$(az graph query -q "Resources | join kind=leftouter (ResourceContainers | where type=='microsoft.resources/subscriptions' | project subscription=name, subscriptionId) on subscriptionId | where name == '$REMOTE_STATE_SA' | project id, name, subscription" --query data[0].id --output tsv)
    terraform_storage_account_name=$(echo "$tfstate_resource_id" | cut -d '/' -f 9 | tr -d '\r')
    terraform_storage_account_subscription_id=$(echo "$tfstate_resource_id" | cut -d '/' -f 3 | tr -d '\r')
    terraform_storage_account_resource_group_name=$(echo "$tfstate_resource_id" | cut -d '/' -f 5 | tr -d '\r')
fi

terraform_module_directory="${SAP_AUTOMATION_REPO_PATH}/deploy/terraform/run/${deployment_system}"/
export TF_DATA_DIR="${param_dirname}/.terraform"

if [ "${DEBUG:-false}" == true ]; then
    printenv | grep ARM
    printenv | grep TF_VAR
fi

#Provide a way to limit the number of parallel tasks for Terraform
if [[ -n "$TF_PARALLELLISM" ]]; then
	parallelism="$TF_PARALLELLISM"
else
	parallelism=3
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
		if terraform -chdir="${terraform_module_directory}" init -upgrade; then
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
	if terraform -chdir="${terraform_module_directory}" init -upgrade -reconfigure \
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
var_file="${param_dirname}"/"${parameterfile}"
allRemovalParameters=(-var-file "${var_file}")
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

		terraform -chdir="${terraform_bootstrap_directory}" init -upgrade -force-copy

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
