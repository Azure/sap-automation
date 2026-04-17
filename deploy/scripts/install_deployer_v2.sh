#!/bin/bash
# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

# Ensure that the exit status of a pipeline command is non-zero if any
# stage of the pipefile has a non-zero exit status.

################################################################################
# Function to display a help message for the deployer installation script.     #
# Arguments:                                                                   #
#   None                                                                       #
# Returns:                                                                     #
#   None                                                                       #
# Usage:                                                                       #
#   show_deployer_help                                                         #
################################################################################
function show_deployer_help {
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

function install_deployer_source_helper_scripts() {
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
# Function to parse all the command line arguments passed to the script.                   #
# Arguments:                                                                               #
#   None                                                                                   #
# Returns:                                                                                 #
#   0 on success, non-zero on failure                                                      #
# Usage:                                                                                   #
#   parse_arguments                                                                        #
############################################################################################

function install_deployer_parse_arguments() {
    local input_opts
    input_opts=$(getopt -n install_deployer_v2 -o p:c:ih --longoptions parameter_file:,control_plane_name:,auto-approve,help -- "$@")
    is_input_opts_valid=$?

    if [[ "${is_input_opts_valid}" != "0" ]]; then
        show_deployer_help
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
            export CONTROL_PLANE_NAME
            shift 2
            ;;
        -i | --auto-approve)
            approve="--auto-approve"
            shift
            ;;
        -h | --help)
            show_deployer_help
            return 3
            ;;
        --)
            shift
            break
            ;;
        esac
    done

    if [ ! -f "${parameter_file_name}" ]; then

        printf -v val %-40.40s "$parameter_file_name"
        print_banner "$banner_title" "Parameter file does not exist: $parameter_file_name" "error"
        return 2 #No such file or directory
    fi

    if ! printenv CONTROL_PLANE_NAME; then
        CONTROL_PLANE_NAME=$(echo "${parameter_file_name}" | cut -d '-' -f 1-3)
        export CONTROL_PLANE_NAME
    fi

    echo "Control Plane name:                  $CONTROL_PLANE_NAME"
    echo "Current directory:                   $(pwd)"

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
# Function to install the deployer.                                                        #
# Arguments:                                                                               #
#   None                                                                                   #
# Returns:                                                                                 #
#   0 on success, non-zero on failure                                                      #
# Usage:                                                                                   #
#   install_deployer                                                                       #
############################################################################################
function install_deployer() {
    local green="\033[0;32m"
    approve=""

    # Define an array of helper scripts
    helper_scripts=(
        "${script_directory}/helpers/script_helpers.sh"
        "${script_directory}/deploy_utils.sh"
    )

    banner_title="Bootstrap Deployer"

    # Call the function with the array
    install_deployer_source_helper_scripts "${helper_scripts[@]}"

    print_banner "$banner_title" "Entering $SCRIPT_NAME" "info"
    detect_platform

    # Parse command line arguments
    if ! install_deployer_parse_arguments "$@"; then
        print_banner "$banner_title" "Validating parameters failed" "error"
        return $?
    fi
    param_dirname=$(dirname "${parameter_file_name}")
    export TF_DATA_DIR="${param_dirname}/.terraform"

    print_banner "$banner_title" "Deploying the deployer" "info"

    #Persisting the parameters across executions
    automation_config_directory="$CONFIG_REPO_PATH/.sap_deployment_automation"
    generic_environment_file_name="${automation_config_directory}"/config
    ENVIRONMENT=$(basename "$parameter_file_name" | awk -F'-' '{print $1}' | xargs)
    LOCATION=$(basename "$parameter_file_name" | awk -F'-' '{print $2}' | xargs)
    NETWORK=$(basename "$parameter_file_name" | awk -F'-' '{print $3}' | xargs)

    deployer_environment_file_name=$(get_configuration_file "$automation_config_directory" "$ENVIRONMENT" "$LOCATION" "$NETWORK")

    if [ ! -f "$deployer_environment_file_name" ]; then
        if [ -f "${automation_config_directory}/${ENVIRONMENT}${LOCATION}" ]; then
            echo "Move existing configuration file"
            sudo mv "${automation_config_directory}/${ENVIRONMENT}${LOCATION}" "${deployer_environment_file_name}"
        fi
    fi

    param_dirname=$(pwd)

    init "${automation_config_directory}" "${generic_environment_file_name}" "${deployer_environment_file_name}"

    echo ""
    echo -e "${green}Deployment information:"
    echo -e "-------------------------------------------------------------------------------$reset_formatting"

    echo "Configuration file:                  $parameter_file_name"
    echo "Control Plane name:                  $CONTROL_PLANE_NAME"

    terraform_module_directory="${SAP_AUTOMATION_REPO_PATH}/deploy/terraform/bootstrap/sap_deployer/"
    export TF_DATA_DIR="${param_dirname}"/.terraform
    cd "${param_dirname}" || exit

    this_ip=$(curl -s ipinfo.io/ip) >/dev/null 2>&1
    if [ -n "$this_ip" ]; then
        export TF_VAR_Agent_IP="${this_ip:-}"
        echo "Agent IP:                            ${this_ip:-}"
    fi

    # Declare an array
    allParameters=(-var-file "${parameter_file_name}")
    if [ -f terraform.tfvars ]; then
        allParameters+=(-var-file "${param_dirname}/terraform.tfvars")
    fi

    if [ "$PLATFORM" != "cli" ]; then
        allParameters+=('-input=false')
    fi

    allImportParameters=(-var-file "${parameter_file_name}")
    if [ -f terraform.tfvars ]; then
        allImportParameters+=(-var-file "${param_dirname}/terraform.tfvars")
    fi

    if [ -f .terraform/terraform.tfstate ]; then
        azure_backend=$(grep "\"type\": \"azurerm\"" .terraform/terraform.tfstate || true)
        if [ -n "$azure_backend" ]; then
            print_banner "$banner_title" "State already migrated to Azure" "warning"
            if terraform -chdir="${terraform_module_directory}" init -upgrade -migrate-state -force-copy -backend-config "path=${param_dirname}/terraform.tfstate"; then
                return_value=$?
                print_banner "$banner_title" "Terraform init succeeded. State migrated" "success"

                moduleID="module.sap_deployer.azurerm_app_configuration_key.deployer_state_file_name"
                if terraform -chdir="${terraform_module_directory}" state list -id="${moduleID}"; then
                    if terraform -chdir="${terraform_module_directory}" state rm "${moduleID}"; then
                        echo "Setting 'deployer_state_file_name' removed from state"
                    fi
                fi

                moduleID="module.sap_deployer.azurerm_app_configuration_key.deployer_keyvault_name"
                if terraform -chdir="${terraform_module_directory}" state list -id="${moduleID}"; then
                    if terraform -chdir="${terraform_module_directory}" state rm "${moduleID}"; then
                        echo "Setting 'deployer_keyvault_name' removed from state"
                    fi
                fi

                moduleID="module.sap_deployer.azurerm_app_configuration_key.deployer_keyvault_id"
                if terraform -chdir="${terraform_module_directory}" state list -id="${moduleID}"; then
                    if terraform -chdir="${terraform_module_directory}" state rm "${moduleID}"; then
                        echo "Setting 'deployer_keyvault_id' removed from state"
                    fi
                fi
                moduleID="module.sap_deployer.azurerm_app_configuration_key.deployer_resourcegroup_name"
                if terraform -chdir="${terraform_module_directory}" state list -id="${moduleID}"; then
                    if terraform -chdir="${terraform_module_directory}" state rm "${moduleID}"; then
                        echo "Setting 'deployer_resourcegroup_name' removed from state"
                    fi
                fi
                moduleID="module.sap_deployer.azurerm_app_configuration_key.deployer_subscription_id"
                if terraform -chdir="${terraform_module_directory}" state list -id="${moduleID}"; then
                    if terraform -chdir="${terraform_module_directory}" state rm "${moduleID}"; then
                        echo "Setting 'deployer_subscription_id' removed from state"
                    fi
                fi

                moduleID="module.sap_deployer.azurerm_app_configuration_key.deployer_network_id"
                if terraform -chdir="${terraform_module_directory}" state list -id="${moduleID}"; then
                    if terraform -chdir="${terraform_module_directory}" state rm "${moduleID}"; then
                        echo "Setting 'deployer_network_id' removed from state"
                    fi
                fi

                moduleID="module.sap_deployer.azurerm_app_configuration_key.deployer_msi_id"
                if terraform -chdir="${terraform_module_directory}" state list -id="${moduleID}"; then
                    if terraform -chdir="${terraform_module_directory}" state rm "${moduleID}"; then
                        echo "Setting 'deployer_msi_id' removed from state"
                    fi
                fi

                moduleID="module.sap_deployer.azurerm_app_configuration_key.deployer_subnet_id"
                if terraform -chdir="${terraform_module_directory}" state list -id="${moduleID}"; then
                    if terraform -chdir="${terraform_module_directory}" state rm "${moduleID}"; then
                        echo "Setting 'deployer_subnet_id' removed from state"
                    fi
                fi

            else
                return_value=$?
                print_banner "$banner_title" "Terraform init failed. State not migrated." "error"
                unset TF_DATA_DIR
                return $return_value
            fi

        else
            print_banner "$banner_title" "State is not using Azure backend, Running terraform init" "info"
            if terraform -chdir="${terraform_module_directory}" init -upgrade -reconfigure -backend-config "path=${param_dirname}/terraform.tfstate"; then
                return_value=$?
                print_banner "$banner_title" "Terraform init succeeded." "success" "System name $(basename "$param_dirname")"
            else
                return_value=$?
                print_banner "$banner_title" "Terraform init failed." "error" "System name $(basename "$param_dirname")"
                unset TF_DATA_DIR
                return $return_value
            fi
            echo "Parameters:                          ${allParameters[*]}"
            terraform -chdir="${terraform_module_directory}" refresh "${allParameters[@]}"
        fi
    else
        print_banner "$banner_title" "Running terraform init" "info"
        if terraform -chdir="${terraform_module_directory}" init -upgrade -reconfigure -backend-config "path=${param_dirname}/terraform.tfstate"; then
            return_value=$?
            print_banner "$banner_title" "Terraform init succeeded." "success" "System name $(basename "$param_dirname")"
        else
            return_value=$?
            print_banner "$banner_title" "Terraform init failed." "error" "System name $(basename "$param_dirname")"
            unset TF_DATA_DIR
            return $return_value
        fi
    fi

    print_banner "$banner_title" "Running Terraform plan" "info"

    #########################################################################################"
    #                                                                                       #
    #                             Running Terraform plan                                    #
    #                                                                                       #
    #########################################################################################

    return_value=0

    echo "Terraform plan command: terraform -chdir=${terraform_module_directory} plan -detailed-exitcode ${allParameters[*]}"

    if terraform -chdir="$terraform_module_directory" plan -detailed-exitcode "${allParameters[@]}"; then
        return_value=$?
    else
        return_value=$?
    fi

    echo "Terraform plan return code: $return_value"
    if [ 0 == "$return_value" ]; then
        print_banner "${banner_title}" "Terraform plan succeeded ($return_value), no changes to apply" "success" "System name $(basename "$param_dirname")"
        return_value=0
    elif [ 2 == "$return_value" ]; then
        print_banner "${banner_title}" "Terraform plan succeeded ($return_value), changes to apply" "info" "System name $(basename "$param_dirname")"
        return_value=2
    else
        print_banner "${banner_title}" "Terraform plan failed ($return_value)" "error" "System name $(basename "$param_dirname")"
        if [ -f plan_output.log ]; then
            cat plan_output.log
            rm plan_output.log
        fi
        unset TF_DATA_DIR
        exit "$return_value"
    fi

    if [ -f plan_output.log ]; then
        rm plan_output.log
    fi

    if [ "${TEST_ONLY:-false}" == "true" ]; then
        print_banner "$banner_title" "Running plan only. No deployment performed." "info"
        exit 10
    fi

    if [ 2 == "$return_value" ]; then
        print_banner "$banner_title" "Running Terraform apply" "info"

        #########################################################################################
        #                                                                                       #
        #                             Running Terraform apply                                   #
        #                                                                                       #
        #########################################################################################
        parallelism=10

        #Provide a way to limit the number of parallel tasks for Terraform
        if checkforEnvVar "TF_PARALLELLISM"; then
            parallelism=$TF_PARALLELLISM
        fi

        if [ -f apply_output.json ]; then
            rm apply_output.json
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

        if terraform -chdir="${terraform_module_directory}" apply -parallelism="${parallelism}" "${allParameters[@]}" | tee "${applyOutputfile}"; then
            return_value=${PIPESTATUS[0]}
        else
            return_value=${PIPESTATUS[0]}
        fi

        if [ "$return_value" -eq 1 ]; then
            print_banner "$banner_title" "Terraform apply failed" "error" "Terraform apply return code: $return_value" "System name $(basename "$param_dirname")"
        elif [ "$return_value" -eq 2 ]; then
            # return code 2 is ok
            print_banner "$banner_title" "Terraform apply succeeded" "success" "Terraform apply return code: $return_value" "System name $(basename "$param_dirname")"
            return_value=0
        else
            print_banner "$banner_title" "Terraform apply succeeded" "success" "Terraform apply return code: $return_value" "System name $(basename "$param_dirname")"
            return_value=0
        fi

        if [ -f apply_output.json ]; then
            errors_occurred=$(jq 'select(."@level" == "error") | length' apply_output.json)

            if [[ -n $errors_occurred ]]; then
                return_value=10

                for i in {1..5}; do
                    print_banner "Terraform apply" "Errors detected in apply output" "warning" "Attempt $i of 5 to import existing resources."
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

        if [ -f apply_output.json ]; then
            rm apply_output.json
        fi
    fi

    DEPLOYER_KEYVAULT=$(terraform -chdir="${terraform_module_directory}" output -no-color -raw deployer_kv_user_name | tr -d \")
    if [ -n "${DEPLOYER_KEYVAULT}" ]; then
        export DEPLOYER_KEYVAULT
        printf -v val %-.20s "$DEPLOYER_KEYVAULT"
        print_banner "$banner_title" "Keyvault to use for deployment credentials: $val" "info"
        save_config_var "DEPLOYER_KEYVAULT" "${deployer_environment_file_name}"
    fi

    APPLICATION_CONFIGURATION_NAME=$(terraform -chdir="${terraform_module_directory}" output -no-color -raw application_configuration_name | tr -d \")
    if [ -n "${APPLICATION_CONFIGURATION_NAME}" ]; then
        save_config_var "APPLICATION_CONFIGURATION_NAME" "${deployer_environment_file_name}"
        export APPLICATION_CONFIGURATION_NAME
        printf -v val %-.20s "$APPLICATION_CONFIGURATION_NAME"
        print_banner "$banner_title" "Application Configuration: $val" "info"
        echo "APPLICATION_CONFIGURATION_NAME:         $APPLICATION_CONFIGURATION_NAME"
    fi

    APPLICATION_CONFIGURATION_DEPLOYMENT=$(terraform -chdir="${terraform_module_directory}" output -no-color -raw app_config_deployment | tr -d \")
    if [ -n "${APPLICATION_CONFIGURATION_DEPLOYMENT}" ]; then
        save_config_var "APPLICATION_CONFIGURATION_DEPLOYMENT" "${deployer_environment_file_name}"
        export APPLICATION_CONFIGURATION_DEPLOYMENT
        echo "APPLICATION_CONFIGURATION_DEPLOYMENT:   $APPLICATION_CONFIGURATION_DEPLOYMENT"
    fi

    APP_SERVICE_NAME=$(terraform -chdir="${terraform_module_directory}" output -no-color -raw webapp_url_base | tr -d \")
    if [ -n "${APP_SERVICE_NAME}" ]; then
        printf -v val %-.20s "$APP_SERVICE_NAME"
        print_banner "$banner_title" "Application Configuration: $val" "info"
        save_config_var "APP_SERVICE_NAME" "${deployer_environment_file_name}"
        export APP_SERVICE_NAME
    fi

    APP_SERVICE_DEPLOYMENT=$(terraform -chdir="${terraform_module_directory}" output -no-color -raw app_service_deployment | tr -d \")
    if [ -n "${APP_SERVICE_DEPLOYMENT}" ]; then
        save_config_var "APP_SERVICE_DEPLOYMENT" "${deployer_environment_file_name}"
        export APP_SERVICE_DEPLOYMENT
    fi

    deployer_random_id=$(terraform -chdir="${terraform_module_directory}" output -no-color -raw random_id | tr -d \")
    if [ -n "${deployer_random_id}" ]; then
        custom_random_id="${deployer_random_id:0:3}"
        sed -i -e /"custom_random_id"/d "${parameter_file_name}"
        printf "\n# The parameter 'custom_random_id' can be used to control the random 3 digits at the end of the storage accounts and key vaults\ncustom_random_id = \"%s\"\n" "${custom_random_id}" >>"${parameter_file_name}"

    fi

    unset TF_DATA_DIR

    print_banner "$banner_title" "Exiting $SCRIPT_NAME" "info"
    step=1
    save_config_var "step" "${deployer_environment_file_name}"
    export step

    return "$return_value"
}

###############################################################################
# Main script execution                                                       #
# This script is designed to be run directly, not sourced.                    #
# It will execute the install_deployer function and handle the exit codes.      #
###############################################################################
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # Only run if script is executed directly, not when sourced
    set -o pipefail
    #colors for terminal
    reset_formatting="\e[0m"

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
        set -o errexit
        echo "Environment variables:"
        printenv | sort
    fi

    # Constants
    script_directory="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
    readonly script_directory

    SCRIPT_NAME="$(basename "$0")"

    if install_deployer "$@"; then
        exit 0
    else
        exit $?
    fi
fi
