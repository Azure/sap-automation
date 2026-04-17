#!/bin/bash
# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

# Ensure that the exit status of a pipeline command is non-zero if any
# stage of the pipefile has a non-zero exit status.
set -o pipefail

#colors for terminal
bold_red="\e[1;31m"
cyan="\e[1;36m"
green="\e[1;32m"
reset_formatting="\e[0m"

#External helper functions
#. "$(dirname "${BASH_SOURCE[0]}")/deploy_utils.sh"
full_script_path="$(realpath "${BASH_SOURCE[0]}")"
script_directory="$(dirname "${full_script_path}")"

banner_title="Installer"

#call stack has full script name when using source
source "${script_directory}/deploy_utils.sh"

#helper files
source "${script_directory}/helpers/script_helpers.sh"

detect_platform

function missing {
    printf -v val %-.40s "$1"
    echo ""
    echo ""
    echo "#########################################################################################"
    echo "#                                                                                       #"
    echo "#   Missing environment variables: ${val}!!!              #"
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

INPUT_ARGUMENTS=$(getopt -n installer -o p:t:o:d:l:s:ahif --longoptions type:,parameterfile:,storageaccountname:,deployer_tfstate_key:,landscape_tfstate_key:,state_subscription:,control_plane_name:,ado,auto-approve,force,help -- "$@")
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
        banner_title="Install $2"
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
    -p | --parameterfile)
        parameterfile="$2"
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

if [ "${DEBUG:-false}" == true ]; then
    echo -e "${cyan}Enabling debug mode$reset_formatting"
    set -x
    set -o errexit
fi

echo "Parameter file:                      $parameterfile"
echo "Current directory:                   $(pwd)"
echo "Terraform state subscription_id:     ${STATE_SUBSCRIPTION}"
echo "Terraform state storageaccount name: ${REMOTE_STATE_SA}"

landscape_tfstate_key_exists=false

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
    banner_title="Install Deployer"
    deployer_tfstate_key=${key}.terraform.tfstate
    ARM_SUBSCRIPTION_ID=$STATE_SUBSCRIPTION
    export ARM_SUBSCRIPTION_ID

fi

network_logical_name=""

if [ "${deployment_system}" == sap_system ]; then
    banner_title="Install SAP System Infrastructure"
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
    load_config_vars "${system_environment_file_name}" "keyvault"
    TF_VAR_spn_keyvault_id=$(az resource list --name "${keyvault}" --subscription "${STATE_SUBSCRIPTION}" --resource-type Microsoft.KeyVault/vaults --query "[].id | [0]" -o tsv)
    export TF_VAR_spn_keyvault_id

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

new_deployment=0

az account set --subscription "${terraform_storage_account_subscription_id}"

if [ ! -f .terraform/terraform.tfstate ]; then
    print_banner "$banner_title" "New deployment" "info"

    if terraform -chdir="${terraform_module_directory}" init -upgrade -input=false \
        --backend-config "subscription_id=${terraform_storage_account_subscription_id}" \
        --backend-config "resource_group_name=${terraform_storage_account_resource_group_name}" \
        --backend-config "storage_account_name=${terraform_storage_account_name}" \
        --backend-config "container_name=tfstate" \
        --backend-config "key=${key}.terraform.tfstate"; then
        return_value=$?
    else
        return_value=$?
        print_banner "$banner_title" "Terraform init failed." "error"
        unset TF_DATA_DIR
        exit "$return_value"
    fi

else
    new_deployment=1

    if local_backend=$(grep "\"type\": \"local\"" .terraform/terraform.tfstate); then
        if [ -n "$local_backend" ]; then

            terraform_module_directory="${SAP_AUTOMATION_REPO_PATH}/deploy/terraform/bootstrap/${deployment_system}"/

            if terraform -chdir="${terraform_module_directory}" init -migrate-state -upgrade --backend-config "path=${param_dirname}/terraform.tfstate"; then
                return_value=$?
                print_banner "$banner_title" "Terraform local init succeeded" "success"
            else
                return_value=10
                print_banner "$banner_title" "Terraform local init failed" "error" "Terraform init return code: $return_value"
                unset TF_DATA_DIR
                exit "$return_value"
            fi
            print_banner "$banner_title" "Migrating the state to Azure" "info"

        fi

        terraform_module_directory="${SAP_AUTOMATION_REPO_PATH}/deploy/terraform/run/${deployment_system}"/

        if terraform -chdir="${terraform_module_directory}" init -force-copy -upgrade -migrate-state \
            --backend-config "subscription_id=${terraform_storage_account_subscription_id}" \
            --backend-config "resource_group_name=${terraform_storage_account_resource_group_name}" \
            --backend-config "storage_account_name=${terraform_storage_account_name}" \
            --backend-config "container_name=tfstate" \
            --backend-config "key=${key}.terraform.tfstate"; then
            return_value=$?
            print_banner "$banner_title" "Terraform init succeeded." "success"
        else
            return_value=10
            print_banner "$banner_title" "Terraform init failed" "error" "Terraform init return code: $return_value"
            exit "$return_value"
        fi
    else
        echo "Terraform state:                     remote"
        print_banner "$banner_title" "The system has already been deployed and the state file is in Azure" "info"

        if terraform -chdir="${terraform_module_directory}" init -upgrade -force-copy -migrate-state \
            --backend-config "subscription_id=${terraform_storage_account_subscription_id}" \
            --backend-config "resource_group_name=${terraform_storage_account_resource_group_name}" \
            --backend-config "storage_account_name=${terraform_storage_account_name}" \
            --backend-config "container_name=tfstate" \
            --backend-config "key=${key}.terraform.tfstate"; then
            return_value=$?
            print_banner "$banner_title" "Terraform init succeeded." "success"
        else
            return_value=10
            print_banner "$banner_title" "Terraform init failed." "error" "Terraform init return code: $return_value"
            exit "$return_value"
        fi
    fi
fi

if [ 1 -eq "$new_deployment" ]; then
    if terraform -chdir="${terraform_module_directory}" output | grep "No outputs"; then
        print_banner "$banner_title" "New deployment" "info"
        new_deployment=1
    else
        print_banner "$banner_title" "Existing deployment was detected" "info"
        new_deployment=0
    fi
fi

if [ 1 -eq $new_deployment ]; then
    deployed_using_version=$(terraform -chdir="${terraform_module_directory}" output -no-color -raw automation_version | tr -d \")
    if [ -z "${deployed_using_version}" ]; then
        print_banner "$banner_title" "The environment was deployed using an older version of the Terraform templates" "error" "Please inspect the output of Terraform plan carefully!"

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
        TF_VAR_terraform_template_version="${deployed_using_version}"
        export TF_VAR_terraform_template_version

        print_banner "$banner_title" "Deployed using the Terraform templates version: $deployed_using_version" "info"

    fi
fi

print_banner "$banner_title" "Running Terraform Plan" "cyan"
# Declare an array
allParameters=(-var-file "${var_file}")
if [ -f terraform.tfvars ]; then
    allParameters+=(-var-file ${param_dirname}/terraform.tfvars)
fi

if [ "$PLATFORM" != "cli" ]; then
    allParameters+=(-input=false)
fi

if [ 1 -eq "$new_deployment" ]; then
    allParameters+=(-var deployment=new)
fi

allImportParameters=(-var-file "${var_file}")
if [ -f terraform.tfvars ]; then
    allImportParameters+=(-var-file ${param_dirname}/terraform.tfvars)
fi
if [ -f terraform.tfvars ]; then
    allImportParameters+=(-var-file ${param_dirname}/terraform.tfvars)
fi

if [ -f plan_output.log ]; then
    rm plan_output.log
fi

apply_needed=0

if terraform -chdir="$terraform_module_directory" plan -detailed-exitcode "${allParameters[@]}" | tee plan_output.log; then
    return_value=${PIPESTATUS[0]}
else
    return_value=${PIPESTATUS[0]}
fi

if [ 0 == "$return_value" ]; then
    print_banner "${banner_title}" "Terraform plan succeeded ($return_value), no changes to apply" "success"
    return_value=0
elif [ 2 == "$return_value" ]; then
    print_banner "${banner_title}" "Terraform plan succeeded ($return_value), changes to apply" "info"
    apply_needed=1

    return_value=0
else
    print_banner "${banner_title}" "Terraform plan failed ($return_value)" "error"
    unset TF_DATA_DIR
    exit "$return_value"
fi

state_path="SYSTEM"
if [ 1 != "$return_value" ]; then

    if [ "${deployment_system}" == sap_deployer ]; then
        state_path="DEPLOYER"

        if ! terraform -chdir="${terraform_module_directory}" output | grep "No outputs"; then

            deployer_public_ip_address=$(terraform -chdir="${terraform_module_directory}" output deployer_public_ip_address | tr -d \")
            if [ -n "${deployer_public_ip_address}" ]; then
                save_config_var "deployer_public_ip_address" "${system_environment_file_name}"
            fi

            APP_SERVICE_NAME=$(terraform -chdir="${terraform_module_directory}" output -no-color -raw webapp_url_base | tr -d \")
            if [ -n "${APP_SERVICE_NAME}" ]; then
                save_config_var "APP_SERVICE_NAME" "${system_environment_file_name}"
                export APP_SERVICE_NAME
            fi

            DEPLOYER_SSHKEY_SECRET_NAME=$(terraform -chdir="${terraform_module_directory}" output -no-color -raw deployer_sshkey | tr -d \")
            if [ -n "${DEPLOYER_SSHKEY_SECRET_NAME}" ]; then
                save_config_var "DEPLOYER_SSHKEY_SECRET_NAME" "${system_environment_file_name}"
                export DEPLOYER_SSHKEY_SECRET_NAME
            fi

            DEPLOYER_USERNAME=$(terraform -chdir="${terraform_module_directory}" output -no-color -raw deployer_username | tr -d \")
            if [ -n "${DEPLOYER_USERNAME}" ]; then
                save_config_var "DEPLOYER_USERNAME" "${system_environment_file_name}"
                export DEPLOYER_USERNAME
            fi

            HAS_WEBAPP=$(terraform -chdir="${terraform_module_directory}" output -no-color -raw app_service_deployment | tr -d \")
            if [ -n "${HAS_WEBAPP}" ]; then
                save_config_var "HAS_WEBAPP" "${system_environment_file_name}"
                export HAS_WEBAPP
            fi

            keyvault=$(terraform -chdir="${terraform_module_directory}" output -no-color -raw deployer_kv_user_name | tr -d \")
            if [ -n "$keyvault" ]; then
                save_config_var "keyvault" "${system_environment_file_name}"
            fi
        fi
    elif [ "${deployment_system}" == sap_landscape ]; then
        state_path="LANDSCAPE"
        if [ $landscape_tfstate_key_exists == false ]; then
            save_config_vars "${system_environment_file_name}" \
                landscape_tfstate_key
        fi
    elif [ "${deployment_system}" == sap_library ]; then
        if [ -z "${REMOTE_STATE_SA}" ]; then
            print_banner "$banner_title" "The SAP Library storage account is not defined" "error"
            if [ 1 == $called_from_ado ]; then
                echo "##vso[task.logissue type=error]The SAP Library storage account is not defined"
            fi

            exit 1
        fi
        state_path="LIBRARY"
        if ! terraform -chdir="${terraform_module_directory}" output | grep "No outputs"; then
            tfstate_resource_id=$(terraform -chdir="${terraform_module_directory}" output tfstate_resource_id | tr -d \")
            STATE_SUBSCRIPTION=$(echo "$tfstate_resource_id" | cut -d/ -f3 | tr -d \" | xargs)

            az account set --sub "${STATE_SUBSCRIPTION}"

            REMOTE_STATE_SA=$(terraform -chdir="${terraform_module_directory}" output -no-color -raw remote_state_storage_account_name | tr -d \")

            getAndStoreTerraformStateStorageAccountDetails "${REMOTE_STATE_SA}" "${system_environment_file_name}"

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

fi

container_exists=$(az storage container exists --subscription "${STATE_SUBSCRIPTION}" --account-name "${REMOTE_STATE_SA}" --name tfvars --only-show-errors --query exists)
if [ "${container_exists}" == "false" ]; then
    az storage container create --subscription "${STATE_SUBSCRIPTION}" --account-name "${REMOTE_STATE_SA}" --name tfvars --only-show-errors
fi

az storage blob upload --file "${parameterfile}" --container-name tfvars/LANDSCAPE/"${key}" --name "${parameterfile_name}" --subscription "${STATE_SUBSCRIPTION}" --account-name "${REMOTE_STATE_SA}" --no-progress --overwrite --only-show-errors --output none

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

if [ "${TEST_ONLY:-false}" == "true" ]; then
    print_banner "$banner_title" "Running plan only. No deployment performed." "info"

    if [ $fatal_errors == 1 ]; then
        print_banner "$banner_title" "!!! Risk for Data loss !!!" "error" "Please inspect the output of Terraform plan carefully"
        exit 10
    fi
    exit 0
fi
if [ $fatal_errors == 1 ]; then
    apply_needed=0
    print_banner "$banner_title" "!!! Risk for Data loss !!!" "error" "Please inspect the output of Terraform plan carefully"
    if [ 1 == "$called_from_ado" ]; then
        unset TF_DATA_DIR
        echo "Risk for data loss, Please inspect the output of Terraform plan carefully. Run manually from deployer" >"${system_environment_file_name}".err
        if [ 1 == $called_from_ado ]; then
            echo ##vso[task.logissue type=error]Risk for data loss, Please inspect the output of Terraform plan carefully. Run manually from deployer
        fi
        exit 1
    else
        read -r -p "Do you want to continue with the deployment Y/N? " ans
        answer=${ans^^}
        if [ "$answer" == "Y" ]; then
            apply_needed=1
        else
            unset TF_DATA_DIR
            echo "Deployment cancelled by user. Please inspect the output of Terraform plan carefully."
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

    print_banner "$banner_title" "Running Terraform apply" "info"

    if [ "$PLATFORM" != "cli" ] || [ "$approve" == "--auto-approve" ]; then
        allParameters+=(-json)
        allParameters+=(-auto-approve)
        allParameters+=(-no-color)
        allParameters+=(-compact-warnings)
        applyOutputfile="apply_output.json"
    else
        applyOutputfile="apply_output.log"
    fi

    if [ -f apply_output.json ]; then
        rm apply_output.json
    fi

    if terraform -chdir="${terraform_module_directory}" apply -parallelism="${parallelism}" "${allParameters[@]}" | tee "${applyOutputfile}"; then
        return_value=${PIPESTATUS[0]}
    else
        return_value=${PIPESTATUS[0]}
    fi

    if [ "$return_value" -eq 1 ]; then
        print_banner "$banner_title" "Terraform apply failed" "error" "Terraform apply return code: $return_value"
    elif [ "$return_value" -eq 2 ]; then
        # return code 2 is ok
        print_banner "$banner_title" "Terraform apply succeeded" "success" "Terraform apply return code: $return_value"
        if [ -f apply_output.json ]; then
            rm apply_output.json
        fi
        return_value=0
    else
        print_banner "$banner_title" "Terraform apply succeeded" "success" "Terraform apply return code: $return_value"
        if [ -f apply_output.json ]; then
            rm apply_output.json
        fi
        return_value=0
    fi

    if [ -f apply_output.json ]; then
        errors_occurred=$(jq 'select(."@level" == "error") | length' apply_output.json)

        if [[ -n $errors_occurred ]]; then
            return_value=10

            for i in {1..10}; do
                print_banner "Terraform apply" "Errors detected in apply output" "warning" "Attempt $i of 10 to import existing resources and re-run apply"
                if [ -f apply_output.json ]; then
                    if ImportAndReRunApply "apply_output.json" "${terraform_module_directory}" "${allImportParameters[*]}" "${allParameters[*]}"; then
                        return_value=0
                    else
                        return_value=$?
                    fi
                else
                    break
                fi
            done
        fi
    fi
fi
if [ -f apply_output.json ]; then
    rm apply_output.json
fi

if [ 1 == "$return_value" ]; then
    print_banner "$banner_title" "Errors during the apply phase" "error"
    unset TF_DATA_DIR
    exit "$return_value"
fi

if [ "${deployment_system}" == sap_deployer ]; then

    webapp_id=$(terraform -chdir="${terraform_module_directory}" output -no-color -raw webapp_id | tr -d \")
    if [ -n "$webapp_id" ]; then
        save_config_var "webapp_id" "${system_environment_file_name}"
    fi

    APP_CONFIG_DEPLOYMENT=$(terraform -chdir="${terraform_module_directory}" output -no-color -raw app_config_deployment | tr -d \")
    if [ -n "${APP_CONFIG_DEPLOYMENT}" ]; then
        save_config_var "APP_CONFIG_DEPLOYMENT" "${system_environment_file_name}"
        export APP_CONFIG_DEPLOYMENT
    fi

    APPLICATION_CONFIGURATION_NAME=$(terraform -chdir="${terraform_module_directory}" output -no-color -raw application_configuration_name | tr -d \")
    if [ -n "${APPLICATION_CONFIGURATION_NAME}" ]; then
        save_config_var "APPLICATION_CONFIGURATION_NAME" "${system_environment_file_name}"
        export APPLICATION_CONFIGURATION_NAME
    fi

    APP_SERVICE_NAME=$(terraform -chdir="${terraform_module_directory}" output -no-color -raw webapp_url_base | tr -d \")
    if [ -n "${APP_SERVICE_NAME}" ]; then
        printf -v val %-.30s "$APP_SERVICE_NAME"
        print_banner "$banner_title" "Application Service: $val" "info"
        save_config_var "APP_SERVICE_NAME" "${system_environment_file_name}"
        export APP_SERVICE_NAME
    fi

    APP_SERVICE_DEPLOYMENT=$(terraform -chdir="${terraform_module_directory}" output -no-color -raw app_service_deployment | tr -d \")
    if [ -n "${APP_SERVICE_DEPLOYMENT}" ]; then
        save_config_var "APP_SERVICE_DEPLOYMENT" "${system_environment_file_name}"
        export APP_SERVICE_DEPLOYMENT
    fi

    DEPLOYER_SSHKEY_SECRET_NAME=$(terraform -chdir="${terraform_module_directory}" output -no-color -raw deployer_sshkey | tr -d \")
    if [ -n "${DEPLOYER_SSHKEY_SECRET_NAME}" ]; then
        save_config_var "DEPLOYER_SSHKEY_SECRET_NAME" "${system_environment_file_name}"
        export DEPLOYER_SSHKEY_SECRET_NAME
    fi

    DEPLOYER_USERNAME=$(terraform -chdir="${terraform_module_directory}" output -no-color -raw deployer_username | tr -d \")
    if [ -n "${DEPLOYER_USERNAME}" ]; then
        save_config_var "DEPLOYER_USERNAME" "${system_environment_file_name}"
        export DEPLOYER_USERNAME
    fi

    deployer_random_id=$(terraform -chdir="${terraform_module_directory}" output -no-color -raw random_id | tr -d \")
    if [ -n "${deployer_random_id}" ]; then
        save_config_var "deployer_random_id" "${system_environment_file_name}"
        custom_random_id="${deployer_random_id}"
        sed -i -e "" -e /"custom_random_id"/d "${parameterfile}"
        printf "custom_random_id=\"%s\"\n" "${custom_random_id}" >>"${var_file}"
    fi

    # shellcheck disable=SC2034
    deployer_public_ip_address=$(terraform -chdir="${terraform_module_directory}" output -no-color -raw deployer_public_ip_address | tr -d \")
    save_config_var "deployer_public_ip_address" "${system_environment_file_name}"
    keyvault=$(terraform -chdir="${terraform_module_directory}" output -no-color -raw deployer_kv_user_name | tr -d \")
    if valid_kv_name "$keyvault"; then
        save_config_var "keyvault" "${system_environment_file_name}"
        print_banner "Installer" "The Control plane keyvault: ${keyvault}" "info"
    else
        printf -v val %-40.40s "$keyvault"
        print_banner "Installer" "The provided keyvault is not valid: ${keyvault}" "error"
    fi

fi

if [ "${deployment_system}" == sap_landscape ]; then

    if ! terraform -chdir="${terraform_module_directory}" output | grep "No outputs"; then
        workloadkeyvault=$(terraform -chdir="${terraform_module_directory}" output -no-color -raw workloadzone_kv_name | tr -d \")
        if [ -n "${workloadkeyvault}" ]; then
            save_config_var "workloadkeyvault" "${system_environment_file_name}"
        fi
        workload_zone_random_id=$(terraform -chdir="${terraform_module_directory}" output -no-color -raw random_id | tr -d \")
        if [ -n "${workload_zone_random_id}" ]; then
            save_config_var "workload_zone_random_id" "${system_environment_file_name}"
            custom_random_id="${workload_zone_random_id:0:3}"
            sed -i -e /"custom_random_id"/d "${parameterfile}"
            printf "\n# The parameter 'custom_random_id' can be used to control the random 3 digits at the end of the storage accounts and key vaults\ncustom_random_id = \"%s\"\n" "${custom_random_id}" >>"${var_file}"

        fi
    fi

fi

if [ "${deployment_system}" == sap_library ]; then
    REMOTE_STATE_SA=$(terraform -chdir="${terraform_module_directory}" output -no-color -raw remote_state_storage_account_name | tr -d \")

    library_random_id=$(terraform -chdir="${terraform_module_directory}" output -no-color -raw random_id | tr -d \")
    if [ -n "${library_random_id}" ]; then
        save_config_var "library_random_id" "${system_environment_file_name}"
        custom_random_id="${library_random_id:0:3}"
        sed -i -e /"custom_random_id"/d "${parameterfile}"
        printf "\n# The parameter 'custom_random_id' can be used to control the random 3 digits at the end of the storage accounts and key vaults\ncustom_random_id = \"%s\"\n" "${custom_random_id}" >>"${var_file}"

    fi

    getAndStoreTerraformStateStorageAccountDetails "${REMOTE_STATE_SA}" "${system_environment_file_name}"

fi

if [ -f "${system_environment_file_name}".err ]; then
    cat "${system_environment_file_name}".err
    rm "${system_environment_file_name}".err
fi

unset TF_DATA_DIR

#################################################################################
#                                                                               #
#                           Copy tfvars to storage account                      #
#                                                                               #
#################################################################################


if [ "${deployment_system}" == sap_landscape ]; then
    az storage blob upload --file "${system_environment_file_name}" --container-name "tfvars/.sap_deployment_automation" --name "${environment}${region_code}${network_logical_name}" \
        --subscription "${STATE_SUBSCRIPTION}" --account-name "${REMOTE_STATE_SA}" --no-progress --overwrite --only-show-errors --output none
fi

if [ "${deployment_system}" == sap_library ]; then
    az storage blob upload --file "${system_environment_file_name}" --container-name "tfvars/.sap_deployment_automation" --name "${environment}${region_code}${network_logical_name}" \
        --subscription "${STATE_SUBSCRIPTION}" --account-name "${REMOTE_STATE_SA}" --no-progress --overwrite --only-show-errors --output none

    az storage blob upload --file "${parameterfile}" --container-name tfvars/"${state_path}"/"${key}" --name "${parameterfile_name}" \
        --subscription "${STATE_SUBSCRIPTION}" --account-name "${REMOTE_STATE_SA}" --no-progress --overwrite --only-show-errors --output none

    if [ -f "$(dirname "${parameterfile}")/.terraform/terraform.tfstate" ]; then
        az storage blob upload --file "$(dirname "${parameterfile}")/.terraform/terraform.tfstate" --container-name tfvars/"${state_path}"/"${key}/.terraform" --name "${parameterfile_name}" \
            --subscription "${STATE_SUBSCRIPTION}" --account-name "${REMOTE_STATE_SA}" --no-progress --overwrite --only-show-errors --output none
    fi

fi

if [ "${deployment_system}" == sap_deployer ]; then
    az storage blob upload --file "${system_environment_file_name}" --container-name "tfvars/.sap_deployment_automation" --name "${environment}${region_code}${network_logical_name}" \
        --subscription "${STATE_SUBSCRIPTION}" --account-name "${REMOTE_STATE_SA}" --no-progress --overwrite --only-show-errors --output none

    az storage blob upload --file "${parameterfile}" --container-name tfvars/"${state_path}"/"${key}" --name "${parameterfile_name}" \
        --subscription "${STATE_SUBSCRIPTION}" --account-name "${REMOTE_STATE_SA}" --no-progress --overwrite --only-show-errors --output none

    if [ -f "$(dirname "${parameterfile}")/.terraform/terraform.tfstate" ]; then
        az storage blob upload --file "$(dirname "${parameterfile}")/.terraform/terraform.tfstate" --container-name tfvars/"${state_path}"/"${key}/.terraform" --name "${parameterfile_name}" \
            --subscription "${STATE_SUBSCRIPTION}" --account-name "${REMOTE_STATE_SA}" --no-progress --overwrite --only-show-errors --output none
    fi

fi

print_banner "$banner_title" "Deployment finished with return code: $return_value" "info"

exit "$return_value"
