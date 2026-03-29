#!/bin/bash
# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

# Ensure that the exit status of a pipeline command is non-zero if any
# stage of the pipefile has a non-zero exit status.
set -o pipefail

# set -x

#colors for terminal

bold_red="\e[1;31m"
cyan="\e[1;36m"
reset_formatting="\e[0m"

#External helper functions
#. "$(dirname "${BASH_SOURCE[0]}")/deploy_utils.sh"
full_script_path="$(realpath "${BASH_SOURCE[0]}")"
script_directory="$(dirname "${full_script_path}")"
parent_caller="${BASH_SOURCE[${#BASH_SOURCE[@]} - 1]}"
parent_caller_directory="$(dirname $(realpath "${parent_caller}"))"

#call stack has full script name when using source
# shellcheck disable=SC1091
source "${script_directory}/deploy_utils.sh"

#helper files
# shellcheck disable=SC1091
source "${script_directory}/helpers/script_helpers.sh"

if [ "$DEBUG" = "true" ]; then
    set -x
    set -o errexit
fi

detect_platform

banner_title="Install workload zone"

force=0
called_from_ado=0
deploy_using_msi_only=0

INPUT_ARGUMENTS=$(getopt -n install_workloadzone -o p:d:e:k:o:s:c:n:t:v:aifhm --longoptions parameterfile:,deployer_tfstate_key:,deployer_environment:,subscription:,spn_id:,spn_secret:,tenant_id:,state_subscription:,keyvault:,storageaccountname:,control_plane_name:,ado,auto-approve,force,help,msi -- "$@")
VALID_ARGUMENTS=$?
if [ "$VALID_ARGUMENTS" != "0" ]; then
    workload_zone_showhelp
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
        CONTROL_PLANE_NAME=$(basename "$deployer_tfstate_key" | cut -d'-' -f1-3)
        CONTROL_PLANE_NAME=$(echo "${CONTROL_PLANE_NAME}" | tr "[:lower:]" "[:upper:]")
        TF_VAR_control_plane_name="$CONTROL_PLANE_NAME"
        export TF_VAR_control_plane_name
        TF_VAR_deployer_tfstate_key="${deployer_tfstate_key}"
        export TF_VAR_deployer_tfstate_key
        shift 2
        ;;
    -e | --deployer_environment)
        deployer_environment="$2"
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
        client_secret="$2"
        shift 2
        ;;
    -o | --storageaccountname)
        REMOTE_STATE_SA="$2"
        export REMOTE_STATE_SA
        getAndStoreTerraformStateStorageAccountDetails "${REMOTE_STATE_SA}" ""
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

deployment_system="sap_landscape"

this_ip=$(curl -s ipinfo.io/ip) >/dev/null 2>&1

deployer_environment=$(echo "${deployer_environment}" | tr "[:lower:]" "[:upper:]")

echo "Deployer environment:                $deployer_environment"
echo "Control plane name:                  $CONTROL_PLANE_NAME"

this_ip=$(curl -s ipinfo.io/ip) >/dev/null 2>&1
export TF_VAR_Agent_IP=$this_ip
echo "Agent IP:                            $this_ip"

subscription=$(echo "${subscription:-$ARM_SUBSCRIPTION_ID}" | tr "[:upper:]" "[:lower:]")

workload_file_parametername=$(basename "${parameterfile}")

param_dirname=$(dirname "${parameterfile}")

if [ "$param_dirname" != '.' ]; then
    print_banner "${banner_title}" "Please run the installer from the folder containing the parameter file" "error"
    exit 3
fi

if [ ! -f "${workload_file_parametername}" ]; then
    printf -v val %-40.40s "$workload_file_parametername"
    echo ""
    print_banner "${banner_title}" "Parameter file does not exist: ${val}" "error"
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
environment=""
region_code=""
region=""

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
    print_banner "Install Workload zone" "Could not extract network logical name from parameter file name" "error"
    return 64 #script usage wrong
fi

key=$(echo "${workload_file_parametername}" | cut -d. -f1)

#Persisting the parameters across executions

automation_config_directory="$CONFIG_REPO_PATH/.sap_deployment_automation"
generic_environment_file_name="${automation_config_directory}"/config

if [ "${ARM_USE_MSI:-false}" = "true" ]; then
    deploy_using_msi_only=1
fi

ENVIRONMENT=$(basename "$workload_file_parametername" | awk -F'-' '{print $1}' | xargs)
LOCATION_CODE=$(basename "$workload_file_parametername" | awk -F'-' '{print $2}' | xargs)
NETWORK=$(basename "$workload_file_parametername" | awk -F'-' '{print $3}' | xargs)
if [ -z "$ENVIRONMENT" ] || [ -z "$LOCATION_CODE" ] || [ -z "$NETWORK" ]; then
    echo "Could not extract environment, location or network from parameter file name"
    echo "Expected format <environment>-<location>-<network>-INFRASTRUCTURE.tfvars"
    exit 2
fi

workload_environment_file_name=$(get_configuration_file "${automation_config_directory}" "${ENVIRONMENT}" "${LOCATION_CODE}" "${NETWORK}")

touch "${workload_environment_file_name}"
if [ -n "$CONTROL_PLANE_NAME" ]; then
    DEPLOYER_ENVIRONMENT=$(echo "$CONTROL_PLANE_NAME" | cut -d"-" -f1)
    DEPLOYER_LOCATION=$(echo "$CONTROL_PLANE_NAME" | cut -d"-" -f2)
    DEPLOYER_NETWORK=$(echo "$CONTROL_PLANE_NAME" | cut -d"-" -f3)
else
    DEPLOYER_ENVIRONMENT=$(echo "${deployerTerraformStatefileName}" | awk -F'-' '{print $1}' | xargs)
    DEPLOYER_LOCATION=$(basename "${deployerTerraformStatefileName}" | awk -F'-' '{print $2}' | xargs)
    DEPLOYER_NETWORK=$(basename "${deployerTerraformStatefileName}" | awk -F'-' '{print $3}' | xargs)
fi
if [ -z "$DEPLOYER_ENVIRONMENT" ] || [ -z "$DEPLOYER_LOCATION" ] || [ -z "$DEPLOYER_NETWORK" ]; then
    echo "Could not extract control plane environment, location or network from parameter file name"
    echo "Expected format <environment>-<location>-<network>-INFRASTRUCTURE.tfvars"
    exit 2
fi

deployer_environment_file_name=$(get_configuration_file "${automation_config_directory}" "${DEPLOYER_ENVIRONMENT}" "${DEPLOYER_LOCATION}" "${DEPLOYER_NETWORK}")

if [ "${force}" == 1 ]; then
    if [ -f "${workload_environment_file_name}" ]; then
        rm "${workload_environment_file_name}"
    fi
    rm -Rf .terraform terraform.tfstate*
fi

if [ ! -f "${deployer_environment_file_name}" ]; then
    print_banner "Install workload zone" "Deployer environment file not found: " "error" "$(basename "${deployer_environment_file_name}")"
    if [ ! -v REMOTE_STATE_SA ]; then
        if [ 1 != $called_from_ado ]; then

            read -r -p "Remote state storage account name: " REMOTE_STATE_SA
            getAndStoreTerraformStateStorageAccountDetails "${REMOTE_STATE_SA}" "${workload_environment_file_name}"

        fi
    fi

else
    load_config_vars "${deployer_environment_file_name}" "tfstate_resource_id" "keyvault" "deployer_tfstate_key" "STATE_SUBSCRIPTION"
    if [ -n "$deployerTerraformStatefileName" ]; then
        deployer_tfstate_key="${deployerTerraformStatefileName}"
    fi
    if [ -n "$tfstate_resource_id" ]; then
        STATE_SUBSCRIPTION=$(echo "${tfstate_resource_id}" | cut -d / -f3)
        REMOTE_STATE_SA=$(echo "${tfstate_resource_id}" | cut -d / -f9)
        REMOTE_STATE_RG=$(echo "${tfstate_resource_id}" | cut -d / -f5)
        DEPLOYER_KEYVAULT="${keyvault}"
        save_config_vars "${workload_environment_file_name}" \
            STATE_SUBSCRIPTION REMOTE_STATE_SA REMOTE_STATE_RG deployer_tfstate_key tfstate_resource_id keyvault DEPLOYER_KEYVAULT

        TF_VAR_tfstate_resource_id=$tfstate_resource_id
        export TF_VAR_tfstate_resource_id
    fi
fi
if [[ -n $deployer_tfstate_key ]]; then
    save_config_vars "${workload_environment_file_name}" deployer_tfstate_key
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

    deployer_Statefile_Size_String=$(az storage blob list --container-name tfstate --account-name "${REMOTE_STATE_SA}" --auth-mode login --query "[?name=='$deployer_tfstate_key'].properties.contentLength" --output tsv)
    deployer_Statefile_Size=$(("$deployer_Statefile_Size_String"))

    if [ "$deployer_Statefile_Size" -lt 50000 ]; then
        print_banner "${banner_title}" "Deployer terraform state file ('$deployer_tfstate_key') is empty" "error"
        unset TF_DATA_DIR

        az storage blob list --container-name tfstate --account-name "${REMOTE_STATE_SA}" --auth-mode login --query "[].{name:name,size:properties.contentLength,lease:lease.status}" --output table
        exit 2
    fi
fi

echo ""
echo "Configuration file:                  $workload_environment_file_name"
echo "Control plane configuration file:    $deployer_environment_file_name"
echo "Deployment region:                   $region"
echo "Deployment region code:              $region_code"
echo "Deployment environment:              $deployer_environment"
echo "Deployer Keyvault:                   $keyvault"
echo "Deployer Subscription:               $STATE_SUBSCRIPTION"
echo "Remote state storage account:        $REMOTE_STATE_SA"
echo "Target Subscription:                 $subscription"

if [ -n "$keyvault" ]; then
    if valid_kv_name "$keyvault"; then
        save_config_var "keyvault" "${workload_environment_file_name}"
    else
        printf -v val %-40.40s "$keyvault"
        print_banner "${banner_title}" "The provided keyvault is not valid: ${val}" "error"
        exit 65
    fi

fi

if [ ! -f "${workload_environment_file_name}" ]; then
    # Ask for deployer environment name and try to read the deployer state file and resource group details from the configuration file
    if [ -z "$deployer_environment" ]; then
        read -r -p "Deployer environment name: " deployer_environment
    fi

    save_config_vars "${workload_environment_file_name}" \
        keyvault \
        subscription \
        deployer_tf_state \
        tfstate_resource_id \
        REMOTE_STATE_SA \
        REMOTE_STATE_RG
fi

if [ -z "$tfstate_resource_id" ]; then
    echo "No tfstate_resource_id"
    if [ -f "$deployer_environment_file_name" ]; then
        load_config_vars "${deployer_environment_file_name}" "keyvault" "REMOTE_STATE_RG" "REMOTE_STATE_SA" "tfstate_resource_id" "deployer_tf_state"

        save_config_vars "${workload_environment_file_name}" \
            tfstate_resource_id \
            keyvault \
            subscription \
            deployer_tf_state \
            REMOTE_STATE_SA \
            REMOTE_STATE_RG
    fi
else

    echo "Terraform Storage Account Id:        $tfstate_resource_id"

    save_config_vars "${workload_environment_file_name}" \
        tfstate_resource_id
fi

echo ""
init "${automation_config_directory}" "${generic_environment_file_name}" "${workload_environment_file_name}"

param_dirname=$(pwd)
var_file="${param_dirname}"/"${parameterfile}"
export TF_DATA_DIR="${param_dirname}/.terraform"

if [ -n "$subscription" ]; then
    if is_valid_guid "$subscription"; then
        echo ""
        export ARM_SUBSCRIPTION_ID="${subscription}"
    else
        printf -v val %-40.40s "$subscription"
        print_banner "${banner_title}" "The provided subscription is not valid: ${val}" "error"

        exit 65
    fi
fi
if [ 0 = "${deploy_using_msi_only:-}" ]; then
    if [ -n "$client_id" ]; then
        if is_valid_guid "$client_id"; then
            echo ""
        else
            printf -v val %-40.40s "$client_id"
            print_banner "${banner_title}" "The provided spn_id is not valid: ${val}" "error"
            exit 65
        fi
    fi

    if [ -n "$tenant_id" ]; then
        if is_valid_guid "$tenant_id"; then
            echo ""
        else
            printf -v val %-40.40s "$tenant_id"
            print_banner "${banner_title}" "The provided tenant_id is not valid: ${val}" "error"
            exit 65
        fi

    fi
fi

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

allParameters=(--vault "$keyvault")
allParameters+=(--keyvault_subscription "${STATE_SUBSCRIPTION}")
allParameters+=(--environment "$environment")
allParameters+=(--region "$region_code")
allParameters+=(--network_code "$NETWORK")
allParameters+=(--subscription "${subscription:-$ARM_SUBSCRIPTION_ID}")
allParameters+=(--tenant_id "${tenant_id:-$ARM_TENANT_ID}")
allParameters+=(--spn_id "${client_id:-$ARM_CLIENT_ID}")

if [ "$deploy_using_msi_only" -eq 0 ]; then
    allParameters+=(--spn_secret "${client_secret:-$ARM_CLIENT_SECRET}")
else
    allParameters+=(--msi)
fi

if "${SAP_AUTOMATION_REPO_PATH}/deploy/scripts/set_secrets.sh" "${allParameters[@]}"; then
    print_banner "Workload Zone deployment" "Secrets have been set successfully" "success"
else
    print_banner "Workload Zone deployment" "Failed to set secrets" "error"
    exit 10
fi
DEPLOYER_KEYVAULT="${keyvault}"
export DEPLOYER_KEYVAULT
save_config_vars "${workload_environment_file_name}" \
    keyvault DEPLOYER_KEYVAULT

if [ -z "${REMOTE_STATE_SA}" ]; then
    read -r -p "Terraform state storage account name: " REMOTE_STATE_SA
    getAndStoreTerraformStateStorageAccountDetails "${REMOTE_STATE_SA}" "${workload_environment_file_name}"

    if [ -n "${STATE_SUBSCRIPTION}" ]; then
        if [ "$account_set" == 0 ]; then
            az account set --sub "${STATE_SUBSCRIPTION}"
            account_set=1
        fi
    fi
else
    getAndStoreTerraformStateStorageAccountDetails "${REMOTE_STATE_SA}" "${workload_environment_file_name}"
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

tfstate_resource_id=$(az graph query -q "Resources | join kind=leftouter (ResourceContainers | where type=='microsoft.resources/subscriptions' | project subscription=name, subscriptionId) on subscriptionId | where name == '$REMOTE_STATE_SA' | project id, name, subscription" --query data[0].id --output tsv)
TF_VAR_tfstate_resource_id=$tfstate_resource_id
export TF_VAR_tfstate_resource_id

TF_VAR_subscription_id="$ARM_SUBSCRIPTION_ID"
export TF_VAR_subscription_id

if [ ! -f .terraform/terraform.tfstate ]; then
    if terraform -chdir="${terraform_module_directory}" init -upgrade=true \
        --backend-config "subscription_id=${STATE_SUBSCRIPTION}" \
        --backend-config "resource_group_name=${REMOTE_STATE_RG}" \
        --backend-config "storage_account_name=${REMOTE_STATE_SA}" \
        --backend-config "container_name=tfstate" \
        --backend-config "key=${key}.terraform.tfstate"; then
        return_value=$?
        print_banner "Install workload zone" "Successfully initialized Terraform with the provided backend configuration." "info"
    else
        return_value=$?
        print_banner "Install workload zone" "Failed to initialize Terraform with the provided backend configuration." "error" "Please check the details and your permissions to access the storage account."
    fi
else
    if terraform -chdir="${terraform_module_directory}" init -upgrade=true; then
        return_value=$?
        print_banner "Install workload zone" "Successfully initialized Terraform with the provided backend configuration." "info"
    else
        return_value=$?
        print_banner "Install workload zone" "Failed to initialize Terraform with the provided backend configuration." "error" "Please check the details and your permissions to access the storage account."
    fi

fi

if [ 0 != $return_value ]; then
    exit $return_value
fi
if terraform -chdir="${terraform_module_directory}" output | grep "No outputs"; then
    check_output=0
else
    check_output=1
fi

save_config_vars "${workload_environment_file_name}" "REMOTE_STATE_SA" "tfstate_resource_id" "subscription" "STATE_SUBSCRIPTION"

if [ 1 == $check_output ]; then
    if terraform -chdir="${terraform_module_directory}" output | grep "No outputs"; then

        check_output=0
        apply_needed=1
        print_banner "Install workload zone" "No existing deployment was detected, a new deployment will be performed" "info"
    else
        print_banner "Install workload zone" "Existing deployment detected" "warning"

        workloadkeyvault=$(terraform -chdir="${terraform_module_directory}" output -no-color -raw workloadzone_kv_name | tr -d \")
        if valid_kv_name "$workloadkeyvault"; then
            save_config_var "workloadkeyvault" "${workload_environment_file_name}"
        fi

        deployed_using_version=$(terraform -chdir="${terraform_module_directory}" output -no-color -raw automation_version)
        if [ -z "$deployed_using_version" ]; then
            echo ""
            echo "#########################################################################################"
            echo "#                                                                                       #"
            echo -e "#   $bold_red The environment was deployed using an older version of the Terraform templates $reset_formatting    #"
            echo "#                                                                                       #"
            echo "#                               !!! Risk for Data loss !!!                              #"
            echo "#                                                                                       #"
            echo "#        Please inspect the output of Terraform plan carefully before proceeding        #"
            echo "#                                                                                       #"
            echo "#########################################################################################"
            if [ 1 == $called_from_ado ]; then
                unset TF_DATA_DIR
                echo "The environment was deployed using an older version of the Terraform templates, Risk for data loss" >"${workload_environment_file_name}".err

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
            print_banner "Install workload zone" "Deployed using Terraform templates version: ${val}" "info"
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
        print_banner "Install workload zone" "Deployed using Terraform templates version: ${val}" "info"

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
            print_banner "Install workload zone" "Deployed using an older version" "warning"

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

print_banner "Install workload zone" "Running Terraform plan to detect changes to be applied" "info"
# Declare an array
allParameters=(-var-file "${var_file}")
if [ -f terraform.tfvars ]; then
    allParameters+=(-var-file ${param_dirname}/terraform.tfvars)
fi

if [ "$PLATFORM" != "cli" ]; then
    allParameters+=(-input=false)
fi

allImportParameters=(-var-file "${var_file}")
if [ -f terraform.tfvars ]; then
    allImportParameters+=(-var-file ${param_dirname}/terraform.tfvars)
fi
if [ -f terraform.tfvars ]; then
    allImportParameters+=(-var-file ${param_dirname}/terraform.tfvars)
fi

# shellcheck disable=SC2086
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
    if [ -f plan_output.log ]; then
        cat plan_output.log
        rm plan_output.log
    fi
    unset TF_DATA_DIR
    exit "$return_value"
fi

if [ "${TEST_ONLY}" == "True" ]; then
    print_banner "Install workload zone" "Running in test mode, no changes will be applied" "warning"
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
    if [ 1 != "$return_value" ]; then
        test=$(grep -m1 "replaced" plan_output.log | grep kv_user || true)
        if [ -n "${test}" ]; then
            print_banner "Install workload zone" "Terraform plan detected changes, which will cause resources to be replaced" "error" "Please inspect the output of Terraform plan carefully before proceeding."
            if [ 1 == "$called_from_ado" ]; then
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
            save_config_var "workloadkeyvault" "${workload_environment_file_name}"
        fi
        save_config_vars "landscape_tfstate_key" "${workload_environment_file_name}"

    fi
fi

if [ 1 == $apply_needed ]; then
    print_banner "Install workload zone" "Applying Terraform changes" "info"

    parallelism=10

    #Provide a way to limit the number of parallell tasks for Terraform
    if [[ -n "${TF_PARALLELLISM}" ]]; then
        parallelism=$TF_PARALLELLISM
    fi

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

save_config_var "landscape_tfstate_key" "${workload_environment_file_name}"

if ! terraform -chdir="${terraform_module_directory}" output | grep "No outputs"; then

    workload_zone_prefix=$(terraform -chdir="${terraform_module_directory}" output -no-color -raw workload_zone_prefix | tr -d \")
    save_config_var "workload_zone_prefix" "${workload_environment_file_name}"
    save_config_vars "landscape_tfstate_key" "${workload_environment_file_name}"
    workload_keyvault=$(terraform -chdir="${terraform_module_directory}" output -no-color -raw workloadzone_kv_name | tr -d \")

    workload_random_id=$(terraform -chdir="${terraform_module_directory}" output -no-color -raw random_id | tr -d \")
    if [ -n "${workload_random_id}" ]; then
        save_config_var "workload_random_id" "${workload_environment_file_name}"
        custom_random_id="${workload_random_id:0:3}"
        sed -i -e /"custom_random_id"/d "${parameterfile}"
        printf "\n# The parameter 'custom_random_id' can be used to control the random 3 digits at the end of the storage accounts and key vaults\ncustom_random_id = \"%s\"\n" "${custom_random_id}" >>"${var_file}"
    fi

    resourceGroupName=$(terraform -chdir="${terraform_module_directory}" output -no-color -raw created_resource_group_name | tr -d \")

    temp=$(echo "${workload_keyvault}" | grep "Warning" || true)
    if [ -z "${temp}" ]; then
        temp=$(echo "${workload_keyvault}" | grep "Backend reinitialization required" || true)
        if [ -z "${temp}" ]; then

            printf -v val %-.20s "$workload_keyvault"
            print_banner "Install workload zone" "Keyvault to use for System credentials: $val" "info"

            workloadkeyvault="$workload_keyvault"
            save_config_var "workloadkeyvault" "${workload_environment_file_name}"
        fi
    fi
fi

if [ 0 != "$return_value" ]; then
    unset TF_DATA_DIR
    exit "$return_value"
fi

echo ""
print_banner "Install workload zone" "Creating deployment" "info"
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

if [ -f "${workload_environment_file_name}".err ]; then
    cat "${workload_environment_file_name}".err
fi

unset TF_DATA_DIR

#################################################################################
#                                                                               #
#                           Copy tfvars to storage account                      #
#                                                                               #
#                                                                               #
#################################################################################
state_path="LANDSCAPE"
az storage blob upload --file "${parameterfile}" --container-name "tfvars/${state_path}/${key}" --name "$(basename "${parameterfile}")" \
    --subscription "${STATE_SUBSCRIPTION}" --account-name "${REMOTE_STATE_SA}" --no-progress --overwrite --only-show-errors --output none

if [ -f "$(dirname "${parameterfile}")/.terraform/terraform.tfstate" ]; then
    az storage blob upload --file "$(dirname "${parameterfile}")/.terraform/terraform.tfstate" --container-name "tfvars/${state_path}/${key}/.terraform" --name "terraform.tfstate" \
        --subscription "${STATE_SUBSCRIPTION}" --account-name "${REMOTE_STATE_SA}" --no-progress --overwrite --only-show-errors --output none
fi

exit "$return_value"
