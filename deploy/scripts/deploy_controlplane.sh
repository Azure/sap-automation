#!/bin/bash
# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

################################################################################################
#                                                                                              #
#   This file contains the logic to deploy the environment to support SAP workloads.           #
#                                                                                              #
#   The script is intended to be run from a parent folder to the folders containing            #
#   the json parameter files for the deployer, the library and the environment.                #
#                                                                                              #
#   The script will persist the parameters needed between the executions in the                #
#   $CONFIG_REPO_PATH/.sap_deployment_automation folder                                        #
#                                                                                              #
#   The script experts the following exports:                                                  #
#   ARM_SUBSCRIPTION_ID to specify which subscription to deploy to                             #
#   SAP_AUTOMATION_REPO_PATH the path to the folder containing the cloned sap-automation       #
#   CONFIG_REPO_PATH the path to the folder containing the configuration for sap               #
#                                                                                              #
################################################################################################

#-------------------------------------------------------------------------------#
#                                                                               #
# Initialize colors and debug handling                                          #
#                                                                               #
#-------------------------------------------------------------------------------#
# 'set' command documentation:
#		https://www.gnu.org/software/bash/manual/html_node/The-Set-Builtin.html
#
# error codes include those from /usr/include/sysexits.h
#---------------------------------------+---------------------------------------#
# region
# colors for terminal
bold_red_underscore="\e[1;4;31m"                                                #    CRIT_COLOR
           bold_red="\e[1;31m"                                                  #   ERROR_COLOR
              green="\e[1;32m"                                                  # SUCCESS_COLOR
             yellow="\e[1;33m"                                                  # WARNING_COLOR
               blue="\e[1;34m"                                                  #   DEBUG_COLOR
            magenta="\e[1;35m"                                                  #   TRACE_COLOR
               cyan="\e[1;36m"                                                  #    INFO_COLOR
              reset="\e[0m"                                                     #   RESET_COLOR

echo -e "\n${cyan}Entering script:  ${BASH_SOURCE[0]}${reset}\n"
export PS4='+$(basename "${BASH_SOURCE[0]}"):${LINENO}: '                       # Debug prompt format

# SYSTEM_DEBUG is set by Azure DevOps when the "Enable system diagnostics" option is turned on for the pipeline run.
# DEBUG is an optional environment variable that can be set to "True" to enable debug mode when running the script outside of Azure DevOps.
if  [[ ${SYSTEM_DEBUG:-False} = True ]] || \
    [[ ${DEBUG:-False}        = True ]]; then
      echo -e "${cyan}--- Enabling debug mode ---${reset}"
      set -x                                                                    # Enable debug mode
      export DEBUG=True
      echo "Environment variables:"
      printenv | sort
else
      export DEBUG=False
fi

set -o errexit                                                                  # Same as -e; Exit immediately if a command exits with a non-zero status.
set -o nounset                                                                  # Same as -u; Treat unset variables as an error when substituting.
set -o pipefail                                                                 # Return the exit status of the last command in the pipe that failed.
#-------------------------------------------------------------------------------#
# endregion


#-------------------------------------------------------------------------------#
#                                                                               #
# Helpers                                                                       #
#                                                                               #
#-------------------------------------------------------------------------------#
# Example: path_to_script/grand_parent_dir/parent_dir/script_dir/script
#---------------------------------------+---------------------------------------#
# region
full_script_path="$(      realpath ${BASH_SOURCE[0]})"                          # Get the full path of the current script
script_directory="$(      dirname  ${full_script_path})"                        # Get the directory of the current script
parent_directory="$(      dirname  ${script_directory})"                        # Get the parent directory of the script directory
grand_parent_directory="$(dirname  ${parent_directory})"                        # Get the grandparent directory of the script directory

SCRIPT_NAME="$(basename "$0")"

# External helper functions
# call stack has full script name when using source
source "${script_directory}/deploy_utils.sh"
source "${script_directory}/helpers/script_helpers.sh"
#-------------------------------------------------------------------------------#
# endregion


if [[ -f /etc/profile.d/deploy_server.sh ]]; then
    path=$(grep -m 1 "export PATH=" /etc/profile.d/deploy_server.sh | awk -F'=' '{print $2}' | xargs)
    export PATH=$path
fi


force=0
step=0
recover=0
ado_flag="none"
deploy_using_msi_only=0

if [ -v ARM_TENANT_ID ]; then
    tenant_id="$ARM_TENANT_ID"
fi

if [ -v ARM_CLIENT_ID ]; then
    client_id="$ARM_CLIENT_ID"
fi

if [ -v ARM_SUBSCRIPTION_ID ]; then
    subscription="$ARM_SUBSCRIPTION_ID"
fi

detect_platform

INPUT_ARGUMENTS=$(getopt -n deploy_controlplane -o d:l:s:c:p:t:a:k:ifohrvm --longoptions deployer_parameter_file:,library_parameter_file:,subscription:,spn_id:,spn_secret:,tenant_id:,storageaccountname:,vault:,auto-approve,force,only_deployer,help,recover,ado,msi -- "$@")
VALID_ARGUMENTS=$?

if [ "$VALID_ARGUMENTS" != "0" ]; then
    control_plane_showhelp
fi

eval set -- "$INPUT_ARGUMENTS"
while :; do
    case "$1" in
    -a | --storageaccountname)
        REMOTE_STATE_SA="$2"
        export REMOTE_STATE_SA
        getAndStoreTerraformStateStorageAccountDetails "${REMOTE_STATE_SA}" ""
        shift 2
        ;;
    -c | --spn_id)
        client_id="$2"
        shift 2
        ;;
    -d | --deployer_parameter_file)
        deployer_parameter_file="$2"
        shift 2
        ;;
    -k | --vault)
        keyvault="$2"
        shift 2
        ;;
    -l | --library_parameter_file)
        library_parameter_file="$2"
        shift 2
        ;;
    -p | --spn_secret)
        client_secret="$2"
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
    -f | --force)
        force=1
        shift
        ;;
    -i | --auto-approve)
        approve="--auto-approve"
        shift
        ;;
    -m | --msi)
        deploy_using_msi_only=1
        shift
        ;;
    -o | --only_deployer)
        only_deployer=1
        shift
        ;;
    -r | --recover)
        recover=1
        shift
        ;;
    -v | --ado)
        ado_flag="--ado"
        shift
        ;;
    -h | --help)
        control_plane_showhelp
        exit 3
        ;;
    --)
        shift
        break
        ;;
    esac
done


echo "ADO flag:                            ${ado_flag}"

if [ "$PLATFORM" != "cli" ] || [ "$approve" == "--auto-approve" ]; then
    echo "Approve:                             Automatically"
fi

key=$(basename "${deployer_parameter_file}" | cut -d. -f1)
if [ -v TF_VAR_deployer_tfstate_key ]; then
		deployer_tf_state="$TF_VAR_deployer_tfstate_key"
else
	deployer_tf_state="${key}.terraform.tfstate"
fi

echo "Deployer State File:                 ${deployer_tf_state}"
echo "Deployer Subscription:               ${subscription}"

key=$(basename "${library_parameter_file}" | cut -d. -f1)
library_tf_state="${key}.terraform.tfstate"

echo "Deployer State File:                 ${deployer_tf_state}"
echo "Library State File:                  ${library_tf_state}"

this_ip=$(curl -s ipinfo.io/ip) >/dev/null 2>&1
root_dirname=$(pwd)

if [ ! -f /etc/profile.d/deploy_server.sh ]; then
    export TF_VAR_Agent_IP=$this_ip
fi

if [ ! -f "$deployer_parameter_file" ]; then
    control_plane_missing 'deployer parameter file'
    exit 2 #No such file or directory
fi

if [ ! -f "$library_parameter_file" ]; then
    control_plane_missing 'library parameter file'
    exit 2 #No such file or directory
fi

# Check that Terraform and Azure CLI is installed
validate_dependencies
return_code=$?
if [ 0 != $return_code ]; then
    echo "validate_dependencies returned $return_code"
    exit $return_code
fi

# Check that parameter files have environment and location defined
region=""
region_code=""
environment=""

validate_key_parameters "$deployer_parameter_file"
if [ 0 != $return_code ]; then
    echo "Errors in parameter file" >"${deployer_environment_file_name}".err
    exit $return_code
fi

# Convert the region to the correct code
get_region_code "$region"

echo "Region code:                         ${region_code}"

automation_config_directory="$CONFIG_REPO_PATH/.sap_deployment_automation"
generic_environment_file_name="${automation_config_directory}"/config

deployer_dirname=$(dirname "${deployer_parameter_file}")
deployer_file_parametername=$(basename "${deployer_parameter_file}")

library_dirname=$(dirname "${library_parameter_file}")
library_file_parametername=$(basename "${library_parameter_file}")

if [ -n "$deployer_tf_state" ]; then
    ENVIRONMENT=$(echo "$deployer_tf_state" | awk -F'-' '{print $1}' | xargs)
    LOCATION=$(echo "$deployer_tf_state" | awk -F'-' '{print $2}' | xargs)
    NETWORK=$(echo "$deployer_tf_state" | awk -F'-' '{print $3}' | xargs)
else
    ENVIRONMENT=$(echo "$deployer_file_parametername" | awk -F'-' '{print $1}' | xargs)
    LOCATION=$(echo "$deployer_file_parametername" | awk -F'-' '{print $2}' | xargs)
    NETWORK=$(echo "$deployer_file_parametername" | awk -F'-' '{print $3}' | xargs)
fi

CONTROL_PLANE_NAME="${ENVIRONMENT}-${LOCATION}-${NETWORK}"
TF_VAR_control_plane_name="${CONTROL_PLANE_NAME}"
export TF_VAR_control_plane_name

if [ -z "$ENVIRONMENT" ] || [ -z "$LOCATION" ] || [ -z "$NETWORK" ]; then
    echo "Could not extract environment, location or network from parameter file name"
    echo "Expected format <environment>-<location>-<network>-INFRASTRUCTURE.tfvars"
    exit 2
fi

deployer_environment_file_name=$(get_configuration_file "$automation_config_directory" "$ENVIRONMENT" "$LOCATION" "$NETWORK")

if [ $force == 1 ]; then
    if [ -f "${deployer_environment_file_name}" ]; then
        rm "${deployer_environment_file_name}"
    fi
fi

if [ -f "${deployer_dirname}/.terraform/terraform.tfstate" ]; then
    azure_backend=$(grep "\"type\": \"azurerm\"" "${deployer_dirname}/.terraform/terraform.tfstate" || true)
    if [ -n "$azure_backend" ]; then
        echo "Terraform state:                     remote"
        step=3
        save_config_vars "${deployer_environment_file_name}" "step"
        echo "key=${deployer_tf_state}"

        STATE_SUBSCRIPTION=$(grep -m1 "subscription_id" "${deployer_dirname}/.terraform/terraform.tfstate" | cut -d ':' -f2 | tr -d '", \r' | xargs || true)
        ARM_SUBSCRIPTION_ID=$STATE_SUBSCRIPTION
        TF_VAR_subscription_id=$STATE_SUBSCRIPTION

        export ARM_SUBSCRIPTION_ID
        export TF_VAR_subscription_id

        REMOTE_STATE_SA=$(grep -m1 "storage_account_name" "${deployer_dirname}/.terraform/terraform.tfstate" | cut -d ':' -f2 | tr -d ' ",\r' | xargs || true)
        REMOTE_STATE_RG=$(grep -m1 "resource_group_name"  "${deployer_dirname}/.terraform/terraform.tfstate" | cut -d ':' -f2 | tr -d ' ",\r' | xargs || true)
        getAndStoreTerraformStateStorageAccountDetails "${REMOTE_STATE_SA}" "${deployer_environment_file_name}"

        terraform_module_directory="${SAP_AUTOMATION_REPO_PATH}/deploy/terraform/run/sap_deployer/"

        if terraform -chdir="${terraform_module_directory}" init -upgrade -reconfigure \
            --backend-config "subscription_id=$STATE_SUBSCRIPTION"                     \
            --backend-config "resource_group_name=$REMOTE_STATE_RG"                    \
            --backend-config "storage_account_name=$REMOTE_STATE_SA"                   \
            --backend-config "container_name=tfstate"                                  \
            --backend-config "key=${deployer_tf_state}"; then

            keyvault=$(terraform -chdir="${terraform_module_directory}" output -no-color -raw deployer_kv_user_name | tr -d \")
            if valid_kv_name "$keyvault"; then

                echo "Key vault:                           ${keyvault}"

                DEPLOYER_KEYVAULT="${keyvault}"
                keyvault_id=$(az graph query -q "Resources | join kind=leftouter (ResourceContainers | where type=='microsoft.resources/subscriptions' | project subscription=name, subscriptionId) on subscriptionId | where name == '$keyvault' | project id, name, subscription" --query data[0].id --output tsv)
                if [ -n "$keyvault_id" ]; then
                    TF_VAR_deployer_kv_user_arm_id=$keyvault_id
                    export TF_VAR_deployer_kv_user_arm_id
                    ARM_SUBSCRIPTION_ID=$(echo "${keyvault_id}" | cut -d/ -f3 | tr -d \" | xargs)
                    export ARM_SUBSCRIPTION_ID

                    step=1
                else
                    step=0
                fi
                step=3
                save_config_vars "${deployer_environment_file_name}" "DEPLOYER_KEYVAULT" "keyvault" "STATE_SUBSCRIPTION" "REMOTE_STATE_SA" "REMOTE_STATE_RG" "ARM_SUBSCRIPTION_ID"
            fi

        fi
    else
        echo "Terraform state:                     local"
        terraform_module_directory="$SAP_AUTOMATION_REPO_PATH"/deploy/terraform/bootstrap/sap_deployer/
        if terraform -chdir="${terraform_module_directory}" init -upgrade --backend-config "path=${deployer_dirname}/terraform.tfstate"; then
            keyvault=$(terraform -chdir="${terraform_module_directory}" output -no-color -raw deployer_kv_user_name | tr -d \")
            if valid_kv_name "$keyvault"; then
                DEPLOYER_KEYVAULT="${keyvault}"
                keyvault_id=$(az graph query -q "Resources | join kind=leftouter (ResourceContainers | where type=='microsoft.resources/subscriptions' | project subscription=name, subscriptionId) on subscriptionId | where name == '$keyvault' | project id, name, subscription" --query data[0].id --output tsv)
                if [ -n "$keyvault_id" ]; then
                    TF_VAR_deployer_kv_user_arm_id=$keyvault_id
                    export TF_VAR_deployer_kv_user_arm_id
                    ARM_SUBSCRIPTION_ID=$(echo "${keyvault_id}" | cut -d/ -f3 | tr -d \" | xargs)
                    export ARM_SUBSCRIPTION_ID

                    step=1
                else
                    step=0
                fi
            fi
            save_config_vars "${deployer_environment_file_name}" "DEPLOYER_KEYVAULT" "keyvault" "step"
        fi
    fi
fi

init "${automation_config_directory}" "${generic_environment_file_name}" "${deployer_environment_file_name}"

save_config_var "deployer_tf_state" "${deployer_environment_file_name}"

if [ -z "${keyvault}" ]; then
    load_config_vars "${deployer_environment_file_name}" "keyvault"
fi

# Check that the exports ARM_SUBSCRIPTION_ID and SAP_AUTOMATION_REPO_PATH are defined
validate_exports
return_code=$?
if [ 0 != $return_code ]; then
    echo "Missing exports" >"${deployer_environment_file_name}".err
    exit $return_code
fi
# Check that webapp exports are defined, if deploying webapp
if [ -n "${TF_VAR_use_webapp:-false}" ]; then
    if [ "${TF_VAR_use_webapp}" == "true" ]; then
        validate_webapp_exports
        return_code=$?
        if [ 0 != $return_code ]; then
            exit $return_code
        fi
    fi
fi

if [ -v ARM_USE_MSI ]; then
    if [[ "${ARM_USE_MSI:-false}" == "true" ]]; then
        deploy_using_msi_only=1
    fi
fi

# relative_deployer_path=$(dirname $(realpath ${deployer_parameter_file}))

relative_path="${deployer_dirname}"
export TF_DATA_DIR="${relative_path}"/.terraform
# export TF_DATA_DIR

print_banner "Control Plane deployment" "Starting the control plane deployment" "info"

noAccess=$(az account show --query name | grep "N/A(tenant level account)" || true)

if [ -n "$noAccess" ]; then
    print_banner "Control Plane deployment" "The provided credentials do not have access to the subscription" "error"

    az account show --output table

    exit 65
fi
az account list --query "[].{Name:name,Id:id}" --output table
#setting the user environment variables
if [ -n "${subscription}" ]; then
    if is_valid_guid "$subscription"; then
        echo ""
    else
        print_banner "Control Plane deployment" "The provided subscription is not valid: $subscription" "error"
        exit 65
    fi

    print_banner "Control Plane deployment" "Using subscription: $subscription" "info"

    if [ 0 = "${deploy_using_msi_only:-}" ]; then
        echo "Identity to use:                     Service Principal"
        TF_VAR_use_spn=true
        export TF_VAR_use_spn

        #set_executing_user_environment_variables "${client_secret}"
    else
        echo "Identity to use:                     Managed Identity"
        TF_VAR_use_spn=false
        export TF_VAR_use_spn
        #set_executing_user_environment_variables "none"
    fi

    if [ $recover == 1 ]; then
        if [ -n "$REMOTE_STATE_SA" ]; then
            getAndStoreTerraformStateStorageAccountDetails "${REMOTE_STATE_SA}" "${deployer_environment_file_name}"
            #Support running deploy_controlplane on new host when the resources are already deployed
            step=3
            save_config_var "step" "${deployer_environment_file_name}"
        fi
    fi

    #Persist the parameters
    if [ -n "$subscription" ]; then
        save_config_var "subscription" "${deployer_environment_file_name}"
        export STATE_SUBSCRIPTION=$subscription
        save_config_var "STATE_SUBSCRIPTION" "${deployer_environment_file_name}"
        export ARM_SUBSCRIPTION_ID=$subscription
        save_config_var "ARM_SUBSCRIPTION_ID" "${deployer_environment_file_name}"
    fi

    if [ -n "$client_id" ]; then
        save_config_var "client_id" "${deployer_environment_file_name}"
    fi

    if [ -n "$tenant_id" ]; then
        save_config_var "tenant_id" "${deployer_environment_file_name}"
    fi
fi

current_directory=$(pwd)

print_banner "Control Plane deployment" "Bootstrapping the deployer" "info"

load_config_vars "${deployer_environment_file_name}" "step"
if [ -z "${step}" ]; then
    step=0
fi
echo "Step:                                $step"

##########################################################################################
#                                                                                        #
#                                     Step 0                                             #
#                           Bootstrapping the deployer                                   #
#                                                                                        #
#                                                                                        #
##########################################################################################

if [ 0 == "$step" ]; then

    # Declare an array
    allParameters=(--parameterfile "${deployer_file_parametername}")
    if [ "$PLATFORM" != "cli" ] || [ "$approve" == "--auto-approve" ]; then
        allParameters+=(--auto-approve)
    fi

    cd "${deployer_dirname}" || exit

    # Ensure subscription_id is populated in the parameter file.
    # The boilerplate tfvars ships with either a commented-out placeholder
    # (#subscription_id = "") or a dummy GUID placeholder; replace both with
    # the actual subscription so Terraform does not prompt / fail.
    if [ -n "${subscription}" ]; then
        sed -i.bak "s|#subscription_id *= *\"\"|subscription_id = \"${subscription}\"|" "${deployer_file_parametername}"
        sed -i.bak "s|subscription_id *= *\"xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx\"|subscription_id = \"${subscription}\"|" "${deployer_file_parametername}"
    fi

    echo "Calling install_deployer.sh:         ${allParameters[*]}"
    echo "Deployer State File:                 ${deployer_tf_state}"

    if "${SAP_AUTOMATION_REPO_PATH}/deploy/scripts/install_deployer.sh" "${allParameters[@]}"; then
        return_code=$?
    else
        return_code=$?
        print_banner "Control Plane deployment" "Bootstrapping of the deployer failed with return code ${return_code}" "error"
        step=0
        save_config_var "step" "${deployer_environment_file_name}"
        exit 10
    fi
    return_code=$?

    echo "Return code from install_deployer:   ${return_code}"
    if [ 0 != $return_code ]; then
        print_banner "Control Plane deployment" "Bootstrapping of the deployer failed with return code ${return_code}" "error"
        step=0
        save_config_var "step" "${deployer_environment_file_name}"
        exit 10
    else
        print_banner "Control Plane deployment" "Bootstrapping of the deployer succeeded" "success"
        step=1
        save_config_var "step" "${deployer_environment_file_name}"

        load_config_vars "${deployer_environment_file_name}" "step"
        echo "Step:                                $step"

        if [ 1 = "${only_deployer:-}" ]; then
            exit 0
        fi
    fi

    load_config_vars "${deployer_environment_file_name}" "DEPLOYER_SSHKEY_SECRET_NAME" "DEPLOYER_KEYVAULT" "deployer_public_ip_address"
    echo "Key vault:             ${DEPLOYER_KEYVAULT}"
    keyvault="${DEPLOYER_KEYVAULT}"

    if [ -z "$DEPLOYER_KEYVAULT" ]; then
        print_banner "Control Plane deployment" "Bootstrapping of the deployer failed with return code ${return_code}" "error"
        exit 10
    fi
    if [ "$FORCE_RESET" = True ]; then
        step=0
        save_config_var "step" "${deployer_environment_file_name}"
        exit 0
    else
        export step=1
    fi
    save_config_var "step" "${deployer_environment_file_name}"

    cd "$root_dirname" || exit

    if [ "$PLATFORM" != "cli" ]; then
        echo "##vso[task.setprogress value=20;]Progress Indicator"
    fi
else
    print_banner "Control Plane deployment" "Deployer is already bootstrapped, skipping to the next step" "info"
    load_config_vars "${deployer_environment_file_name}" "DEPLOYER_SSHKEY_SECRET_NAME" "DEPLOYER_KEYVAULT" "deployer_public_ip_address"
    if [ "$PLATFORM" != "cli" ]; then
        echo "##vso[task.setprogress value=20;]Progress Indicator"
    fi
fi

cd "$root_dirname" || exit

##########################################################################################
#                                                                                        #
#                                     Step 1                                             #
#                           Validating Key Vault Access                                  #
#                                                                                        #
#                                                                                        #
##########################################################################################

print_banner "Control Plane deployment" "Validating Key Vault Access" "info"
echo "Step:                                $step"

TF_DATA_DIR="${deployer_dirname}"/.terraform
export TF_DATA_DIR

cd "${deployer_dirname}" || exit
if [ 0 != "$step" ]; then

    if [ 1 -eq $step ] || [ 3 -eq $step ]; then
        # If the keyvault is not set, check the terraform state file
        if [ -z "$DEPLOYER_KEYVAULT" ]; then
            key=$(echo "${deployer_file_parametername}" | cut -d. -f1)
            if [ -f ./.terraform/terraform.tfstate ]; then
                azure_backend=$(grep "\"type\": \"azurerm\"" .terraform/terraform.tfstate || true)
                if [ -n "$azure_backend" ]; then
                    echo "Terraform state:                     remote"

                    terraform_module_directory="$SAP_AUTOMATION_REPO_PATH"/deploy/terraform/run/sap_deployer/
                    STATE_SUBSCRIPTION=$(grep -m1 "subscription_id"      ".terraform/terraform.tfstate" | cut -d ':' -f2 | tr -d '", \r' | xargs || true)
                    REMOTE_STATE_SA=$(   grep -m1 "storage_account_name" ".terraform/terraform.tfstate" | cut -d ':' -f2 | tr -d ' ",\r' | xargs || true)
                    REMOTE_STATE_RG=$(   grep -m1 "resource_group_name"  ".terraform/terraform.tfstate" | cut -d ':' -f2 | tr -d ' ",\r' | xargs || true)
                    if terraform -chdir="${terraform_module_directory}" init -upgrade \
                        --backend-config "subscription_id=$STATE_SUBSCRIPTION"        \
                        --backend-config "resource_group_name=$REMOTE_STATE_RG"       \
                        --backend-config "storage_account_name=$REMOTE_STATE_SA"      \
                        --backend-config "container_name=tfstate"                     \
                        --backend-config "key=${key}.terraform.tfstate"; then

                        keyvault=$(terraform -chdir="${terraform_module_directory}" output deployer_kv_user_name | tr -d \")
                        DEPLOYER_KEYVAULT="${keyvault}"
                        save_config_vars "${deployer_environment_file_name}" "DEPLOYER_KEYVAULT" "keyvault" "STATE_SUBSCRIPTION" "REMOTE_STATE_SA" "REMOTE_STATE_RG"
                    fi
                else
                    echo "Terraform state:                     local"
                fi
            fi
        else
            echo "Key vault:                           ${DEPLOYER_KEYVAULT}"
            keyvault="${DEPLOYER_KEYVAULT}"
        fi

        if [ -z "$keyvault" ]; then
            if [ $ado_flag != "--ado" ]; then
                read -r -p "Deployer keyvault name: " keyvault
            else
                exit 10
            fi
        fi

        if [ 1 -eq $step ]; then

            allParameters=(--vault "$keyvault")
            allParameters+=(--environment "$environment")
            allParameters+=(--region "$region_code")
            allParameters+=(--network_code "$NETWORK")
            allParameters+=(--keyvault_subscription "${subscription:-$ARM_SUBSCRIPTION_ID}")
            allParameters+=(--subscription "${subscription:-$ARM_SUBSCRIPTION_ID}")
            allParameters+=(--tenant_id "${tenant_id:-$ARM_TENANT_ID}")
            allParameters+=(--spn_id "${client_id:-$ARM_CLIENT_ID}")
            # ss
            if [ "$deploy_using_msi_only" -eq 0 ]; then
                allParameters+=(--spn_secret "${client_secret:-$ARM_CLIENT_SECRET}")
            else
                allParameters+=(--msi)
            fi

            if "${SAP_AUTOMATION_REPO_PATH}/deploy/scripts/set_secrets.sh" "${allParameters[@]}"; then
                print_banner "Control Plane deployment" "Secrets have been set successfully" "success"
            else
                print_banner "Control Plane deployment" "Failed to set secrets" "error"
                exit 10
            fi
        fi

    fi
else
    if [ -z "$keyvault" ]; then
        load_config_vars "${deployer_environment_file_name}" "keyvault"
    fi
fi
if [ -n "${keyvault}" ] && [ 0 != "$step" ]; then

    echo "Checking for keyvault:               ${keyvault}"
    keyvault_id=$(az graph query -q "Resources | join kind=leftouter (ResourceContainers | where type=='microsoft.resources/subscriptions' | project subscription=name, subscriptionId) on subscriptionId | where name == '$keyvault' | project id, name, subscription" --query data[0].id --output tsv)
    ARM_SUBSCRIPTION_ID=$(echo "${keyvault_id}" | cut -d/ -f3 | tr -d \" | xargs)
    export ARM_SUBSCRIPTION_ID

    if [ -z "${keyvault_id}" ]; then
        print_banner "Control Plane deployment" "Detected a failed deployment" "error"
        exit 10
    else
        TF_VAR_deployer_kv_user_arm_id="${keyvault_id}"
        export TF_VAR_deployer_kv_user_arm_id
    fi
else
    if [ $ado_flag != "--ado" ]; then
        read -r -p "Deployer keyvault name: " keyvault
        save_config_var "keyvault" "${deployer_environment_file_name}"
    else
        step=0
        save_config_var "step" "${deployer_environment_file_name}"
        exit 10
    fi

fi

unset TF_DATA_DIR

cd "$root_dirname" || exit

az account set --subscription "$ARM_SUBSCRIPTION_ID"

if validate_key_vault "$keyvault" "$ARM_SUBSCRIPTION_ID"; then
    echo "Key vault:                           ${keyvault}"
    save_config_var "keyvault" "${deployer_environment_file_name}"
    if [ 1 -eq $step ]; then
        export step=2
        save_config_var "step" "${deployer_environment_file_name}"
    fi

else
    return_code=$?
    print_banner "Control Plane deployment" "Failed to access the key vault ${keyvault}" "error"

fi

##########################################################################################
#                                                                                        #
#                                      STEP 2                                            #
#                           Bootstrapping the library                                    #
#                                                                                        #
#                                                                                        #
##########################################################################################

if [ 2 -eq $step ]; then
    print_banner "Control Plane deployment" "Bootstrapping the library" "info"
    allParameters=(--parameterfile "${library_file_parametername}")
    allParameters+=(--deployer_statefile_foldername "${deployer_dirname}")
    allParameters+=(--keyvault "${keyvault}")
    if [ "$PLATFORM" != "cli" ] || [ "$approve" == "--auto-approve" ]; then
        allParameters+=(--auto-approve)
    fi

    relative_path="${library_dirname}"
    export TF_DATA_DIR="${relative_path}/.terraform"
    # relative_path="${deployer_dirname}"

    cd "${library_dirname}" || exit
    terraform_module_directory="${SAP_AUTOMATION_REPO_PATH}"/deploy/terraform/bootstrap/sap_library/

    if [ $force == 1 ]; then
        rm -Rf .terraform terraform.tfstate*
    fi

    echo "Calling install_library.sh:          ${allParameters[*]}"

    if "${SAP_AUTOMATION_REPO_PATH}/deploy/scripts/install_library.sh" "${allParameters[@]}"; then

        step=3
        save_config_var "step" "${deployer_environment_file_name}"
        print_banner "Control Plane deployment" "Bootstrapping of the SAP Library succeeded" "success"
    else
        print_banner "Control Plane deployment" "Bootstrapping of the SAP Library failed" "error"
        step=2
        save_config_var "step" "${deployer_environment_file_name}"
        exit 20

    fi

    REMOTE_STATE_RG=$(terraform -chdir="${terraform_module_directory}" output -no-color -raw sapbits_sa_resource_group_name | tr -d \")
    REMOTE_STATE_SA=$(terraform -chdir="${terraform_module_directory}" output -no-color -raw remote_state_storage_account_name | tr -d \")
    STATE_SUBSCRIPTION=$(terraform -chdir="${terraform_module_directory}" output -no-color -raw created_resource_group_subscription_id | tr -d \")
    tfstate_resource_id=$(terraform -chdir="${terraform_module_directory}" output -no-color -raw tfstate_resource_id | tr -d \")

    if [ "${ado_flag}" != "--ado" ]; then
        az storage account network-rule add -g "${REMOTE_STATE_RG}" --account-name "${REMOTE_STATE_SA}" --ip-address "${this_ip}" --output none
    fi

    TF_VAR_sa_connection_string=$(terraform -chdir="${terraform_module_directory}" output -no-color -raw sa_connection_string | tr -d \")
    export TF_VAR_sa_connection_string

    if [ -n "${tfstate_resource_id}" ]; then
        TF_VAR_tfstate_resource_id="${tfstate_resource_id}"
    else
        tfstate_resource_id=$(az resource list --name "$REMOTE_STATE_SA" --subscription "$STATE_SUBSCRIPTION" --resource-type Microsoft.Storage/storageAccounts --query "[].id | [0]" -o tsv)
        TF_VAR_tfstate_resource_id=$tfstate_resource_id
    fi
    export TF_VAR_tfstate_resource_id
		save_config_vars "${deployer_environment_file_name}" "REMOTE_STATE_SA" "STATE_SUBSCRIPTION" "REMOTE_STATE_RG" "tfstate_resource_id"

    cd "${current_directory}" || exit
    save_config_var "step" "${deployer_environment_file_name}"
    if [ "$PLATFORM" != "cli" ]; then
        echo "##vso[task.setprogress value=60;]Progress Indicator"
    fi

else
    print_banner "Control Plane deployment" "SAP Library is already bootstrapped, skipping to the next step" "info"
    if [ "$PLATFORM" != "cli" ]; then
        echo "##vso[task.setprogress value=60;]Progress Indicator"
    fi

fi

unset TF_DATA_DIR
cd "$root_dirname" || exit
if [ "$PLATFORM" != "cli" ]; then
    echo "##vso[task.setprogress value=80;]Progress Indicator"
fi

##########################################################################################
#                                                                                        #
#                                      STEP 3                                            #
#                           Migrating the state file for the deployer                    #
#                                                                                        #
#                                                                                        #
##########################################################################################
if [ 3 -eq "$step" ]; then
    print_banner "Control Plane deployment" "Migrating the deployer state" "info"

    cd "${deployer_dirname}" || exit

    if [ -f .terraform/terraform.tfstate ]; then
        STATE_SUBSCRIPTION=$(grep -m1 "subscription_id" ".terraform/terraform.tfstate" | cut -d ':' -f2 | tr -d '", \r' | xargs || true)
        REMOTE_STATE_SA=$(grep -m1 "storage_account_name" ".terraform/terraform.tfstate" | cut -d ':' -f2 | tr -d ' ",\r' | xargs || true)
        REMOTE_STATE_RG=$(grep -m1 "resource_group_name" ".terraform/terraform.tfstate" | cut -d ':' -f2 | tr -d ' ",\r' | xargs || true)
    fi

    if [[ -z $REMOTE_STATE_SA ]]; then
        load_config_vars "${deployer_environment_file_name}" "REMOTE_STATE_SA"
    fi

    if [[ -z $STATE_SUBSCRIPTION ]]; then
        load_config_vars "${deployer_environment_file_name}" "STATE_SUBSCRIPTION"
    fi

    if [[ -z $ARM_SUBSCRIPTION_ID ]]; then
        load_config_vars "${deployer_environment_file_name}" "ARM_SUBSCRIPTION_ID"
    fi

    if [ -z "${REMOTE_STATE_SA}" ]; then
        export step=2
        save_config_var "step" "${deployer_environment_file_name}"
        if [ "$PLATFORM" != "cli" ]; then
            echo "##vso[task.setprogress value=40;]Progress Indicator"
        fi
        echo ""
        print_banner "Control Plane deployment" "Could not find the SAP Library, please re-run!" "error"
        exit 11

    fi

    TF_VAR_subscription_id="${STATE_SUBSCRIPTION}"
    export TF_VAR_subscription_id

    allParameters=(--parameterfile "${deployer_file_parametername}")
    allParameters+=(--storageaccountname "${REMOTE_STATE_SA}")
    allParameters+=(--state_subscription "${STATE_SUBSCRIPTION}")
    allParameters+=(--type "sap_deployer")
    if [ "$PLATFORM" != "cli" ] || [ "$approve" == "--auto-approve" ]; then
        allParameters+=(--auto-approve)
    fi

    echo "Calling installer.sh with:           ${allParameters[*]}"

    if "${SAP_AUTOMATION_REPO_PATH}/deploy/scripts/installer.sh" "${allParameters[@]}"; then
        print_banner "Control Plane deployment" "Migrating the Deployer state succeeded" "success"
        step=4
        save_config_var "step" "${deployer_environment_file_name}"
        return_code=0
    else
        print_banner "Control Plane deployment" "Migrating the Deployer state failed" "error"
        step=3
        save_config_var "step" "${deployer_environment_file_name}"
        exit 30
    fi

    cd "${current_directory}" || exit
    export step=4
    save_config_var "step" "${deployer_environment_file_name}"

fi

unset TF_DATA_DIR
cd "$root_dirname" || exit

load_config_vars "${deployer_environment_file_name}" "keyvault" "deployer_public_ip_address" "REMOTE_STATE_SA"

##########################################################################################
#                                                                                        #
#                                      STEP 4                                            #
#                           Migrating the state file for the library                     #
#                                                                                        #
#                                                                                        #
##########################################################################################

if [ 4 -eq $step ]; then
    print_banner "Control Plane deployment" "Migrating the library state" "info"

    terraform_module_directory="$SAP_AUTOMATION_REPO_PATH"/deploy/terraform/run/sap_library/

    cd "${library_dirname}" || exit
    if [ -f .terraform/terraform.tfstate ]; then
        # If the library state file exists, we will use it to get the remote state storage account and
        # resource group name
        if [ -z "$REMOTE_STATE_SA" ]; then
            REMOTE_STATE_SA=$(grep -m1 "storage_account_name" ".terraform/terraform.tfstate" | cut -d ':' -f2 | tr -d ' ",\r' | xargs || true)
        else
            load_config_vars "${deployer_environment_file_name}" "REMOTE_STATE_SA"
        fi
        if [ -z "$REMOTE_STATE_RG" ]; then
            REMOTE_STATE_RG=$(grep -m1 "resource_group_name" ".terraform/terraform.tfstate" | cut -d ':' -f2 | tr -d ' ",\r' | xargs || true)
        else
            load_config_vars "${deployer_environment_file_name}" "REMOTE_STATE_RG"
        fi
        if [ -z "$STATE_SUBSCRIPTION" ]; then
            # If the state subscription is not set, we will use the one from the deployer state file
            # This is needed to support running deploy_controlplane on new host when the resources are already deployed
            STATE_SUBSCRIPTION=$(grep -m1 "subscription_id" ".terraform/terraform.tfstate" | cut -d ':' -f2 | tr -d '", \r' | xargs || true)
        else
            load_config_vars "${deployer_environment_file_name}" "STATE_SUBSCRIPTION"
        fi
    fi
    allParameters=(--parameterfile "${library_file_parametername}")
    allParameters+=(--storageaccountname "${REMOTE_STATE_SA}")
    allParameters+=(--state_subscription "${STATE_SUBSCRIPTION}")
    allParameters+=(--deployer_tfstate_key "${deployer_tf_state}")
    allParameters+=(--type sap_library)

    if [ "$PLATFORM" != "cli" ] || [ "$approve" == "--auto-approve" ]; then
        allParameters+=(--auto-approve)
    fi

    echo "Calling installer.sh with: ${allParameters[*]}"

    if "${SAP_AUTOMATION_REPO_PATH}/deploy/scripts/installer.sh" "${allParameters[@]}"; then
        return_code=$?
        print_banner "Control Plane deployment" "Migrating the SAP Library state succeeded" "success"
        step=5
        save_config_var "step" "${deployer_environment_file_name}"
    else
        print_banner "Control Plane deployment" "Migrating the SAP Library state failed" "error"

        step=4
        save_config_var "step" "${deployer_environment_file_name}"
        exit 40
    fi

    cd "$root_dirname" || exit

    step=5
    save_config_var "step" "${deployer_environment_file_name}"
fi

printf -v kvname '%-40s' "${keyvault}"
printf -v dep_ip '%-40s' "${deployer_public_ip_address:-NO_PUBLIC_IP}"
printf -v storage_account '%-40s' "${REMOTE_STATE_SA}"
echo ""
echo "#########################################################################################"
echo "#                                                                                       #"
echo -e "# ${cyan}Please save these values:${reset}                                                           #"
echo "#     - Key Vault:       ${kvname}                       #"
echo "#     - Deployer IP:     ${dep_ip}                       #"
echo "#     - Storage Account: ${storage_account}                       #"
echo "#                                                                                       #"
echo "#########################################################################################"

now=$(date)
cat <<EOF >"${deployer_environment_file_name}".md
# Control Plane Deployment #

Date : "${now}"

## Configuration details ##

| Item                    | Name                 |
| ----------------------- | -------------------- |
| Control Plane Name      | $CONTROL_PLANE_NAME  |
| Location                | $region              |
| Keyvault Name           | ${kvname}            |
| Deployer IP             | ${dep_ip}            |
| Terraform state         | ${storage_account}   |

EOF

cat "${deployer_environment_file_name}".md

deployer_keyvault="${keyvault}"
export deployer_keyvault

terraform_state_storage_account="${REMOTE_STATE_SA}"
export terraform_state_storage_account

load_config_vars "${deployer_environment_file_name}" "deployer_public_ip_address" "DEPLOYER_SSHKEY_SECRET_NAME" "DEPLOYER_USERNAME"

if [ 5 -eq $step ]; then
    if [ -n "${deployer_public_ip_address:-}" ] && [ -n "${DEPLOYER_SSHKEY_SECRET_NAME}" ]; then

        cd "${current_directory}" || exit

        print_banner "Control Plane deployment" "Copying the parameterfiles" "info"

        printf "%s\n" "Collecting secrets from KV"

        temp_file=$(mktemp)
        ppk=$(az keyvault secret show --vault-name "${keyvault}" --name "${DEPLOYER_SSHKEY_SECRET_NAME}" --query value --output tsv)
        echo "${ppk}" >"${temp_file}"
        chmod 600 "${temp_file}"

        remote_deployer_dir="/home/${DEPLOYER_USERNAME:-azureadm}/Azure_SAP_Automated_Deployment/WORKSPACES/DEPLOYER/$(basename "$deployer_parameter_file" .tfvars)"
        echo "Remote deployer directory:            ${remote_deployer_dir}"
        remote_library_dir="/home/${DEPLOYER_USERNAME:-azureadm}/Azure_SAP_Automated_Deployment/WORKSPACES/LIBRARY/$(basename "$library_parameter_file" .tfvars)"
        echo "Remote library directory:             ${remote_library_dir}"
        remote_config_dir="/home/${DEPLOYER_USERNAME:-azureadm}/Azure_SAP_Automated_Deployment/WORKSPACES/.sap_deployment_automation"
        echo "Remote config directory:              ${remote_config_dir}"

        ssh -i "${temp_file}" -o StrictHostKeyChecking=no -o ConnectTimeout=10 "${DEPLOYER_USERNAME:-azureadm}"@"${deployer_public_ip_address}" "mkdir -p ${remote_deployer_dir}/.terraform"

        scp -i "${temp_file}" -q -o StrictHostKeyChecking=no -o ConnectTimeout=120 -p "$deployer_parameter_file" "${DEPLOYER_USERNAME:-azureadm}"@"${deployer_public_ip_address}":"${remote_deployer_dir}/$(basename "$deployer_parameter_file")"
        scp -i "${temp_file}" -q -o StrictHostKeyChecking=no -o ConnectTimeout=120 -p "$(dirname "$deployer_parameter_file")"/.terraform/terraform.tfstate "${DEPLOYER_USERNAME:-azureadm}"@"${deployer_public_ip_address}":"${remote_deployer_dir}"/.terraform/terraform.tfstate
        scp -i "${temp_file}" -q -o StrictHostKeyChecking=no -o ConnectTimeout=120 -p "$(dirname "$deployer_parameter_file")"/terraform.tfstate "${DEPLOYER_USERNAME:-azureadm}"@"${deployer_public_ip_address}":"${remote_deployer_dir}"/terraform.tfstate

        ssh -i "${temp_file}"    -o StrictHostKeyChecking=no -o ConnectTimeout=10 "${DEPLOYER_USERNAME:-azureadm}"@"${deployer_public_ip_address}" " mkdir -p ${remote_library_dir}/.terraform"
        scp -i "${temp_file}" -q -o StrictHostKeyChecking=no -o ConnectTimeout=120 -p "$library_parameter_file" "${DEPLOYER_USERNAME:-azureadm}"@"${deployer_public_ip_address}":"${remote_library_dir}/$(basename "$library_parameter_file")"
        scp -i "${temp_file}" -q -o StrictHostKeyChecking=no -o ConnectTimeout=120 -p "$(dirname "$library_parameter_file")"/terraform.tfstate "${DEPLOYER_USERNAME:-azureadm}"@"${deployer_public_ip_address}":"${remote_library_dir}/terraform.tfstate"
        scp -i "${temp_file}" -q -o StrictHostKeyChecking=no -o ConnectTimeout=120 -p "$(dirname "$library_parameter_file")"/.terraform/terraform.tfstate "${DEPLOYER_USERNAME:-azureadm}"@"${deployer_public_ip_address}":"${remote_library_dir}/.terraform/terraform.tfstate"

        ssh -i "${temp_file}"    -o StrictHostKeyChecking=no -o ConnectTimeout=10 "${DEPLOYER_USERNAME:-azureadm}"@"${deployer_public_ip_address}" "mkdir -p ${remote_config_dir}"
        scp -i "${temp_file}" -q -o StrictHostKeyChecking=no -o ConnectTimeout=120 -p "${deployer_environment_file_name}" "${DEPLOYER_USERNAME:-azureadm}"@"${deployer_public_ip_address}":"${remote_config_dir}/$(basename "$deployer_environment_file_name")"
        rm "${temp_file}"
    fi
fi

step=3
save_config_var "step" "${deployer_environment_file_name}"
if [ "$PLATFORM" != "cli" ]; then
    echo "##vso[task.setprogress value=100;]Progress Indicator"
fi

unset TF_DATA_DIR

#----------------------------------- EXIT --------------------------------------#
echo -e "\n${cyan}Exiting script:  ${BASH_SOURCE[0]}${reset}"
echo -e   "${cyan}   Return code:  ${return_code}${reset}"
exit $return_code
