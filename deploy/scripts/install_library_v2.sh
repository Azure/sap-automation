#!/bin/bash
# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

############################################################################################
# This function sources the provided helper scripts and checks if they exist.              #
# If a script is not found, it prints an error message and exits with a non-zero status.   #
# Arguments:                                                                               #
#   1. Array of helper script paths                                                        #
# Returns:                                                                                 #
#   0 on success, non-zero on failure                                                      #
# Usage:                     																				                       #
#   source_helper_scripts <helper_script1> <helper_script2> ...                            #
# Example:                   																				                       #
#   source_helper_scripts "script1.sh" "script2.sh"            														 #
############################################################################################

function install_library_source_helper_scripts() {
    local -a helper_scripts=("$@")
    for script in "${helper_scripts[@]}"; do
        if [[ -f "$script" ]]; then
            # shellcheck source=/dev/null
            source "$script"
        else
            echo "Helper script not found: $script"
            exit 1
        fi
    done
}

############################################################################################
# Function to display a help message for the library installation script.                  #
# Arguments:                                                                               #
#   1. Parameter file name                                                                 #
# Returns:                                                                                 #
#   0 on success, non-zero on failure                                                      #
# Usage:                                                                                   #
#   show_library_help                                                                      #
############################################################################################
function show_library_help {
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
    echo "#   Usage: install_library_v2.sh                                                        #"
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


############################################################################################
# This function reads the SDAF environment variables.                                      #
# Arguments:                                                                               #
#   None                                                                                   #
# Returns:                                                                                 #
#   0 on success, non-zero on failure                                                      #
# Usage:                     																				                       #
#   install_library_check_environment_variables                                                #
# Example:                   																				                       #
#   install_library_check_environment_variables                                                #
############################################################################################

function install_library_check_environment_variables() {
    if [ -v SDAF_CONTROL_PLANE_NAME ]; then
        CONTROL_PLANE_NAME="$SDAF_CONTROL_PLANE_NAME"
        TF_VAR_control_plane_name="$CONTROL_PLANE_NAME"
        TF_VAR_deployer_tfstate_key="${CONTROL_PLANE_NAME}-INFRASTRUCTURE.terraform.tfstate"
        export TF_VAR_control_plane_name
        export TF_VAR_deployer_tfstate_key
    fi

    if [ -v SDAF_APPLICATION_CONFIGURATION_NAME ]; then
        APPLICATION_CONFIGURATION_NAME="$SDAF_APPLICATION_CONFIGURATION_NAME"
        TF_VAR_application_configuration_id=$(az graph query -q "Resources | join kind=leftouter (ResourceContainers | where type=='microsoft.resources/subscriptions' | project subscription=name, subscriptionId) on subscriptionId | where name == '$APPLICATION_CONFIGURATION_NAME' | project id, name, subscription" --query data[0].id --output tsv)
        export TF_VAR_application_configuration_id
    fi

    return 0
}


############################################################################################
# Function to parse all the command line arguments passed to the script.                   #
# Arguments:                                                                               #
#   None                                                                                   #
# Returns:                                                                                 #
#   0 on success, non-zero on failure                                                      #
# Usage:                                                                                   #
#   parse_arguments                                                                        #
############################################################################################

function install_library_parse_arguments() {
    local input_opts
    input_opts=$(getopt -n install_library_v2 -o c:n:p:d:v:ih --longoptions control_plane_name:,application_configuration_name:,parameter_file:,deployer_statefile_foldername:,keyvault:,auto-approve,help -- "$@")
    is_input_opts_valid=$?

    if [[ "${is_input_opts_valid}" != "0" ]]; then
        show_library_help
        exit 1
    fi

    eval set -- "$input_opts"
    while true; do
        case "$1" in
        -p | --parameter_file)
            parameter_file_name="$2"
            shift 2
            ;;
        -c | --control_plane_name)
            CONTROL_PLANE_NAME="$2"
            TF_VAR_control_plane_name="$CONTROL_PLANE_NAME"
            export TF_VAR_control_plane_name
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
        -n | --application_configuration_name)
            APPLICATION_CONFIGURATION_NAME="$2"
            APPLICATION_CONFIGURATION_ID=$(az graph query -q "Resources | join kind=leftouter (ResourceContainers | where type=='microsoft.resources/subscriptions' | project subscription=name, subscriptionId) on subscriptionId | where name == '$APPLICATION_CONFIGURATION_NAME' | project id, name, subscription" --query data[0].id --output tsv)
            export APPLICATION_CONFIGURATION_ID
            export APPLICATION_CONFIGURATION_NAME
            TF_VAR_application_configuration_id="${APPLICATION_CONFIGURATION_ID}"
            export TF_VAR_application_configuration_id
            shift 2
            ;;
        -h | --help)
            showhelp
            exit 3
            ;;
        -v | --keyvault)
            keyvault="$2"
            keyvault_id=$(az graph query -q "Resources | join kind=leftouter (ResourceContainers | where type=='microsoft.resources/subscriptions' | project subscription=name, subscriptionId) on subscriptionId | where name == '$keyvault' | project id, name, subscription" --query data[0].id --output tsv)
            TF_VAR_spn_keyvault_id="$keyvault_id"
            export TF_VAR_spn_keyvault_id

            shift 2
            ;;
        --)
            shift
            break
            ;;
        esac
    done
    if [ ! -f "${parameter_file_name}" ]; then
        print_banner "$banner_title" "Parameter file does not exist: $parameter_file_name" "error"
        return 2 #No such file or directory
    fi

    param_dirname=$(dirname "${parameter_file_name}")
    export TF_DATA_DIR="${param_dirname}"/.terraform

    # Check that parameter files have environment and location defined
    if ! validate_key_parameters "$parameter_file_name"; then
        return $?
    fi

    # Check that the exports ARM_SUBSCRIPTION_ID and SAP_AUTOMATION_REPO_PATH are defined
    if ! validate_exports; then
        return $?
    fi

    region=$(echo "${region}" | tr "[:upper:]" "[:lower:]")
    # Convert the region to the correct code
    get_region_code "$region"

    # Check that Terraform and Azure CLI is installed
    if ! validate_dependencies; then
        return $?
    fi

    return 0

}

############################################################################################
# This function reads the parameters from the Azure Application Configuration and sets     #
# the environment variables.                                                               #
# Arguments:                                                                               #
#   None                                                                                   #
# Returns:                                                                                 #
#   0 on success, non-zero on failure                                                      #
# Usage:                     																				                       #
#   retrieve_parameters                                                                    #
############################################################################################

function install_library_retrieve_parameters() {

    TF_VAR_control_plane_name="${CONTROL_PLANE_NAME}"
    export TF_VAR_control_plane_name

    if [ -n "${APPLICATION_CONFIGURATION_ID:-}" ]; then
        app_config_name=$(echo "$APPLICATION_CONFIGURATION_ID" | cut -d'/' -f9)
        app_config_subscription=$(echo "$APPLICATION_CONFIGURATION_ID" | cut -d'/' -f3)

        if is_valid_id "$APPLICATION_CONFIGURATION_ID" "/providers/Microsoft.AppConfiguration/configurationStores/"; then
            print_banner "Installer" "Retrieving parameters from Azure App Configuration" "info" "$app_config_name ($app_config_subscription)"

            TF_VAR_spn_keyvault_id=$(getVariableFromApplicationConfiguration "$APPLICATION_CONFIGURATION_ID" "${CONTROL_PLANE_NAME}_KeyVaultResourceId" "$CONTROL_PLANE_NAME")

            management_subscription_id=$(getVariableFromApplicationConfiguration "$APPLICATION_CONFIGURATION_ID" "${CONTROL_PLANE_NAME}_SubscriptionId" "${CONTROL_PLANE_NAME}")
            TF_VAR_management_subscription_id=${management_subscription_id}

            export TF_VAR_management_subscription_id
            export TF_VAR_spn_keyvault_id

        fi

    fi

}

############################################################################################
# Function to install the SAP Library.                                                     #
# Arguments:                                                                               #
#   None                                                                                   #
# Returns:                                                                                 #
#   0 on success, non-zero on failure                                                      #
# Usage:                                                                                   #
#   install_library                                                                        #
############################################################################################

function install_library() {
    local green="\033[0;32m"
    local reset="\033[0m"
    deployment_system=sap_library
    use_deployer=true

    SCRIPT_NAME="$(basename "$0")"

    # Define an array of helper scripts
    helper_scripts=(
        "${script_directory}/helpers/script_helpers.sh"
        "${script_directory}/deploy_utils.sh"
    )

    # Call the function with the array
    install_library_source_helper_scripts "${helper_scripts[@]}"

    print_banner "$banner_title" "Starting the script: $SCRIPT_NAME" "info"
    detect_platform

    install_library_check_environment_variables

    # Parse command line arguments
    if ! install_library_parse_arguments "$@"; then
        print_banner "$banner_title" "Validating parameters failed" "error"
        return $?
    fi

    install_library_retrieve_parameters

    param_dirname=$(dirname "${parameter_file_name}")
    cd "${param_dirname}" || exit 1
    echo "Parameter file directory:             ${param_dirname}"
    export TF_DATA_DIR="${param_dirname}/.terraform"

    if [ true == "$use_deployer" ]; then
        if [ ! -d "${deployer_statefile_foldername}" ]; then

            print_banner "$banner_title" "Deployer folder does not exist: $deployer_statefile_foldername" "error"
            return 2 #No such file or directory
        fi
    fi

    #Persisting the parameters across executions
    automation_config_directory="$CONFIG_REPO_PATH/.sap_deployment_automation"
    generic_environment_file_name="${automation_config_directory}"/config

    ENVIRONMENT=$(echo "$CONTROL_PLANE_NAME" | awk -F'-' '{print $1}' | xargs)
    LOCATION=$(echo "$CONTROL_PLANE_NAME" | awk -F'-' '{print $2}' | xargs)
    NETWORK=$(echo "$CONTROL_PLANE_NAME" | awk -F'-' '{print $3}' | xargs)
    TF_VAR_control_plane_name="$CONTROL_PLANE_NAME"
    export TF_VAR_control_plane_name

    automation_config_directory="$CONFIG_REPO_PATH/.sap_deployment_automation"

    library_environment_file_name=$(get_configuration_file "$automation_config_directory" "$ENVIRONMENT" "$LOCATION" "$NETWORK")

    TF_VAR_control_plane_name="$CONTROL_PLANE_NAME"
    export TF_VAR_control_plane_name

    # Terraform Plugins
    if checkIfCloudShell; then
        mkdir -p "${HOME}/.terraform.d/plugin-cache"
        export TF_PLUGIN_CACHE_DIR="${HOME}/.terraform.d/plugin-cache"
    else
        if [ ! -d /opt/terraform/.terraform.d/plugin-cache ]; then
            sudo mkdir -p /opt/terraform/.terraform.d/plugin-cache
            sudo chown -R "$USER" /opt/terraform/.terraform.d
        else
            sudo chown -R "$USER" /opt/terraform/.terraform.d
        fi
        export TF_PLUGIN_CACHE_DIR=/opt/terraform/.terraform.d/plugin-cache
    fi

    param_dirname=$(pwd)

    init "${automation_config_directory}" "${generic_environment_file_name}" "${library_environment_file_name}"

    export TF_DATA_DIR="${param_dirname}"/.terraform

    terraform_module_directory="${SAP_AUTOMATION_REPO_PATH}/deploy/terraform/bootstrap/sap_library"/

    if [ ! -d "${terraform_module_directory}" ]; then
        print_banner "$banner_title" "Terraform module directory does not exist: $terraform_module_directory" "error"
        unset TF_DATA_DIR
        return 64
    fi

    echo ""
    echo -e "${green}Deployment information:"
    echo -e "-------------------------------------------------------------------------------$reset"

    echo "Configuration file:                  $parameter_file_name"
    echo "Control Plane name:                  $CONTROL_PLANE_NAME"

    TF_VAR_subscription_id="$ARM_SUBSCRIPTION_ID"
    export TF_VAR_subscription_id
    parallelism=10

    #Provide a way to limit the number of parallel tasks for Terraform
    if checkforEnvVar "TF_PARALLELLISM"; then
        parallelism=$TF_PARALLELLISM
    fi
    echo "Parallelism count:                   $parallelism"
    key=$(basename "${parameter_file_name}" | cut -d. -f1)

    if [ -n "${DEPLOYER_KEYVAULT:-}" ]; then
        TF_VAR_deployer_kv_user_arm_id=$(az resource list --name "${DEPLOYER_KEYVAULT}" --subscription "$ARM_SUBSCRIPTION_ID" --resource-type Microsoft.KeyVault/vaults --query "[].id | [0]" -o tsv)
        export TF_VAR_spn_keyvault_id="${TF_VAR_deployer_kv_user_arm_id}"
    fi

    # Declare an array
    allParameters=(-var-file "${parameter_file_name}")
    if [ -f terraform.tfvars ]; then
        allParameters+=(-var-file terraform.tfvars)
    fi

    if [ -n "${deployer_statefile_foldername}" ]; then
        echo "Deployer folder specified:           ${deployer_statefile_foldername}"
        allParameters+=(-var "deployer_statefile_foldername=${deployer_statefile_foldername}")
    fi

    if [ "$PLATFORM" != "cli" ]; then
        allParameters+=(-input=false)
    fi

    if [ ! -d ./.terraform/ ]; then
        print_banner "$banner_title" "New Deployment" "info"
        terraform -chdir="${terraform_module_directory}" init -upgrade -backend-config "path=${param_dirname}/terraform.tfstate"
        sed -i /REMOTE_STATE_RG/d "${library_environment_file_name}"
        sed -i /REMOTE_STATE_SA/d "${library_environment_file_name}"
        sed -i /tfstate_resource_id/d "${library_environment_file_name}"

    else
        if [ -f ./.terraform/terraform.tfstate ]; then
            azure_backend=$(grep "\"type\": \"azurerm\"" .terraform/terraform.tfstate || true)
            if [ -n "$azure_backend" ]; then
                print_banner "$banner_title" "The state is already migrated to Azure!!!" "info"

                REINSTALL_SUBSCRIPTION=$(grep -m1 "subscription_id" "${param_dirname}/.terraform/terraform.tfstate" | cut -d ':' -f2 | tr -d '", \r' | xargs || true)
                REINSTALL_ACCOUNTNAME=$(grep -m1 "storage_account_name" "${param_dirname}/.terraform/terraform.tfstate" | cut -d ':' -f2 | tr -d ' ",\r' | xargs || true)
                REINSTALL_RESOURCE_GROUP=$(grep -m1 "resource_group_name" "${param_dirname}/.terraform/terraform.tfstate" | cut -d ':' -f2 | tr -d ' ",\r' | xargs || true)

                tfstate_resource_id=$(az resource list --name "$REINSTALL_ACCOUNTNAME" --subscription "$REINSTALL_SUBSCRIPTION" --resource-type Microsoft.Storage/storageAccounts --query "[].id | [0]" -o tsv)
                if [ -n "${tfstate_resource_id}" ]; then
                    print_banner "$banner_title" "Reinitializing against remote state" "info"
                    this_ip=$(curl -s ipinfo.io/ip) >/dev/null 2>&1
                    az storage account network-rule add --account-name "$REINSTALL_ACCOUNTNAME" --resource-group "$REINSTALL_RESOURCE_GROUP" --ip-address "${this_ip}" --only-show-errors --output none
                    echo ""
                    echo "Sleeping for 30 seconds to allow the network rule to take effect"
                    echo ""
                    sleep 30
                    export TF_VAR_tfstate_resource_id=$tfstate_resource_id

                    terraform_module_directory="${SAP_AUTOMATION_REPO_PATH}/deploy/terraform/run/sap_library"/

                    if terraform -chdir="${terraform_module_directory}" init \
                        --backend-config "subscription_id=$REINSTALL_SUBSCRIPTION" \
                        --backend-config "resource_group_name=$REINSTALL_RESOURCE_GROUP" \
                        --backend-config "storage_account_name=$REINSTALL_ACCOUNTNAME" \
                        --backend-config "container_name=tfstate" \
                        --backend-config "key=${key}.terraform.tfstate"; then
                        print_banner "$banner_title" "Terraform init succeeded" "success" "System name $(basename "$param_dirname")"

                        terraform -chdir="${terraform_module_directory}" refresh "${allParameters[@]}"
                    else
                        print_banner "$banner_title" "Terraform init against remote state failed" "error" "System name $(basename "$param_dirname")"
                        return 10
                    fi
                else
                    if terraform -chdir="${terraform_module_directory}" init -reconfigure --backend-config "path=${param_dirname}/terraform.tfstate"; then
                        print_banner "$banner_title" "Terraform init succeeded" "success" "System name $(basename "$param_dirname")"
                    else
                        print_banner "$banner_title" "Terraform init failed" "error" "System name $(basename "$param_dirname")"
                        return 10
                    fi
                fi
            else
                if terraform -chdir="${terraform_module_directory}" init -upgrade -backend-config "path=${param_dirname}/terraform.tfstate"; then
                    print_banner "$banner_title" "Terraform init succeeded" "success" "System name $(basename "$param_dirname")"
                else
                    print_banner "$banner_title" "Terraform init failed" "error" "System name $(basename "$param_dirname")"
                    return 10
                fi

            fi

        else
            if terraform -chdir="${terraform_module_directory}" init -upgrade -backend-config "path=${param_dirname}/terraform.tfstate"; then
                print_banner "$banner_title" "Terraform init succeeded" "success" "System name $(basename "$param_dirname")"
            else
                print_banner "$banner_title" "Terraform init failed" "error" "System name $(basename "$param_dirname")"
                return 10
            fi
        fi
    fi

    print_banner "$banner_title" "Running Terraform plan" "info"

    allImportParameters=(-var-file "${parameter_file_name}")
    if [ -f terraform.tfvars ]; then
        allImportParameters+=(-var-file terraform.tfvars)
    fi
    if [ -n "${deployer_statefile_foldername}" ]; then
        allImportParameters+=(-var "deployer_statefile_foldername=${deployer_statefile_foldername}")
    fi

    install_library_return_value=0

    echo "Terraform plan command: terraform -chdir=${terraform_module_directory} plan -detailed-exitcode ${allParameters[*]}"

    if terraform -chdir="$terraform_module_directory" plan -detailed-exitcode "${allParameters[@]}"; then
        install_library_return_value=$?
    else
        install_library_return_value=$?
    fi

    echo "Terraform plan return code: $install_library_return_value"
    if [ 0 == "$install_library_return_value" ]; then
        print_banner "${banner_title}" "Terraform plan succeeded ($install_library_return_value), no changes to apply" "success" "System name $(basename "$param_dirname")"
        install_library_return_value=0
    elif [ 2 == "$install_library_return_value" ]; then
        print_banner "${banner_title}" "Terraform plan succeeded ($install_library_return_value), changes to apply" "info" "System name $(basename "$param_dirname")"
      else
        print_banner "${banner_title}" "Terraform plan failed ($install_library_return_value)" "error" "System name $(basename "$param_dirname")"
        if [ -f plan_output.log ]; then
            cat plan_output.log
            rm plan_output.log
        fi
        unset TF_DATA_DIR
        exit "$install_library_return_value"
    fi

    if [ -f plan_output.log ]; then
        rm plan_output.log
    fi

    return_value=0

    if [ "${TEST_ONLY:-false}" == "true" ]; then
        print_banner "$banner_title" "Running plan only. No deployment performed." "info"
        exit 10
    fi
    if [ 2 == "$install_library_return_value" ]; then
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

        if terraform -chdir="${terraform_module_directory}" apply -parallelism="${parallelism}" "${allParameters[@]}" | tee "${applyOutputfile}"; then
            install_library_return_value=${PIPESTATUS[0]}
        else
            install_library_return_value=${PIPESTATUS[0]}
        fi

        if [ "$install_library_return_value" -eq 1 ]; then
            print_banner "$banner_title" "Terraform apply failed" "error" "Terraform apply return code: $install_library_return_value" "System name $(basename "$param_dirname")"
        else
            # return code 2 is ok
            print_banner "${banner_title}" "Terraform apply succeeded ($install_library_return_value)" "info" "System name $(basename "$param_dirname")"
            install_library_return_value=0
        fi

        if [ -f apply_output.json ]; then
            errors_occurred=$(jq 'select(."@level" == "error") | length' apply_output.json)

            if [[ -n $errors_occurred ]]; then
                install_library_return_value=10

                for i in {1..5}; do
                    print_banner "Terraform apply" "Errors detected in apply output" "warning" "Attempt $i of 5 to import existing resources."
                    if [ -f apply_output.json ]; then
                        if ImportAndReRunApply "apply_output.json" "${terraform_module_directory}" "${allImportParameters[*]}" "${allParameters[*]}"; then
                            install_library_return_value=0
                        else
                            install_library_return_value=$?
                        fi
                    else
                        break
                    fi
                done
            fi
        fi
        if [ -f apply_output.json ]; then
            rm apply_output.json
        fi

        if [ 1 == "$install_library_return_value" ]; then
            print_banner "$banner_title" "Errors during the apply phase" "error"
            unset TF_DATA_DIR
            return "$install_library_return_value"
        fi

        if [ "${DEBUG:-false}" = true ]; then
            terraform -chdir="${terraform_module_directory}" output
        fi

        tfstate_resource_id=$(terraform -chdir="${terraform_module_directory}" output -no-color -raw tfstate_resource_id | tr -d \")
        export tfstate_resource_id
        save_config_var "tfstate_resource_id" "${library_environment_file_name}"

        library_random_id=$(terraform -chdir="${terraform_module_directory}" output -no-color -raw random_id | tr -d \")
        if [ -n "${library_random_id}" ]; then
            save_config_var "library_random_id" "${library_environment_file_name}"
            custom_random_id="${library_random_id:0:3}"
            sed -i -e /"custom_random_id"/d "${parameter_file_name}"
            printf "\n# The parameter 'custom_random_id' can be used to control the random 3 digits at the end of the storage accounts and key vaults\ncustom_random_id = \"%s\"\n" "${custom_random_id}" >>"${parameter_file_name}"

        fi
    fi

    step=3
    save_config_var "step" "${library_environment_file_name}"

    return "$install_library_return_value"
}

###############################################################################
# Main script execution                                                       #
# This script is designed to be run directly, not sourced.                    #
# It will execute the install_library function and handle the exit codes.     #
###############################################################################
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # Only run if
    # Ensure that the exit status of a pipeline command is non-zero if any
    # stage of the pipefile has a non-zero exit status.
    set -o pipefail

    #External helper functions
    #. "$(dirname "${BASH_SOURCE[0]}")/deploy_utils.sh"
    full_script_path="$(realpath "${BASH_SOURCE[0]}")"
    script_directory="$(dirname "${full_script_path}")"

    # Fail on any error, undefined variable, or pipeline failure
    set -euo pipefail

    # Enable debug mode if DEBUG is set to 'true'
    if [[ "${DEBUG:-false}" == 'true' ]]; then
        # Enable debugging
        set -x
        # Exit on error
        DEBUG=true
        set -o errexit
        echo "Environment variables:"
        printenv | sort
    else
        # Disable debugging
        DEBUG=false
    fi

    # Constants
    script_directory="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
    readonly script_directory

    banner_title="Bootstrap Library"

    CONFIG_REPO_PATH="${script_directory}/.."
    if install_library "$@"; then
        exit 0
    else
        exit $?
    fi
fi
