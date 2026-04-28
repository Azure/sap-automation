#!/bin/bash
# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

banner_title="Installer"

###############################################################################
# Function to show an error message and exit with a non-zero status           #
# Arguments:                                                                  #
#   None                                                                      #
# Returns:                                                                    #
#   0 if all required environment variables are set                           #
#   1 if any required environment variable is not set                         #
# Usage: 																																		  #
#   missing																											              #
###############################################################################

function missing {
    printf -v val %-.40s "$1"
    echo ""
    echo ""
    echo "#########################################################################################"
    echo "#                                                                                       #"
    echo "#   Missing environment variables: ${val}!!!              #"
    echo "#                                                                                       #"
    echo "#   Please export the following variables:                                              #"
    echo "#      SAP_AUTOMATION_REPO_PATH (path to the automation repo folder (sap-automation))   #"
    echo "#      CONFIG_REPO_PATH (path to the configuration repo folder (sap-config))            #"
    echo "#      ARM_SUBSCRIPTION_ID (subscription containing the state file storage account)     #"
    echo "#                                                                                       #"
    echo "#########################################################################################"
    return 0
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

function installer_source_helper_scripts() {
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
# This function reads the SDAF environment variables.                                      #
# Arguments:                                                                               #
#   None                                                                                   #
# Returns:                                                                                 #
#   0 on success, non-zero on failure                                                      #
# Usage:                     																				                       #
#   installer_check_environment_variables                                                #
# Example:                   																				                       #
#   installer_check_environment_variables                                                #
############################################################################################


function installer_check_environment_variables() {
    if [ -v SDAF_CONTROL_PLANE_NAME ]; then
        CONTROL_PLANE_NAME="$SDAF_CONTROL_PLANE_NAME"
        TF_VAR_control_plane_name="$CONTROL_PLANE_NAME"
        TF_VAR_deployer_tfstate_key="${CONTROL_PLANE_NAME}-INFRASTRUCTURE.terraform.tfstate"
        export TF_VAR_control_plane_name
        export TF_VAR_deployer_tfstate_key
    fi

    if [ -v SDAF_WORKLOAD_ZONE_NAME ]; then
        WORKLOAD_ZONE_NAME="$SDAF_WORKLOAD_ZONE_NAME"
        TF_VAR_workload_zone_name="$WORKLOAD_ZONE_NAME"
        TF_VAR_landscape_tfstate_key="${WORKLOAD_ZONE_NAME}-INFRASTRUCTURE.terraform.tfstate"
        export TF_VAR_workload_zone_name
        export TF_VAR_landscape_tfstate_key
    fi

    if [ -v SDAF_APPLICATION_CONFIGURATION_NAME ]; then
        APPLICATION_CONFIGURATION_NAME="$SDAF_APPLICATION_CONFIGURATION_NAME"
    fi

    if [ -v SDAF_TERRAFORM_STORAGE_ACCOUNT_NAME ]; then
        TERRAFORM_STORAGE_ACCOUNT_NAME="$SDAF_TERRAFORM_STORAGE_ACCOUNT_NAME"
        export TERRAFORM_STORAGE_ACCOUNT_NAME
        getAndStoreTerraformStateStorageAccountDetails "${TERRAFORM_STORAGE_ACCOUNT_NAME}" ""
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

function installer_parse_arguments() {
    local input_opts
    input_opts=$(getopt -n installer_v2 -o p:t:o:d:l:s:n:c:w:ahifg --longoptions type:,parameter_file:,storage_accountname:,deployer_tfstate_key:,landscape_tfstate_key:,state_subscription:,application_configuration_name:,control_plane_name:,workload_zone_name:,ado,auto-approve,force,help,github,devops -- "$@")
    is_input_opts_valid=$?

    if [[ "${is_input_opts_valid}" != "0" ]]; then
        show_help_installer_v2
        return 1
    fi

    eval set -- "$input_opts"
    while true; do
        case "$1" in
		-a | --ado)
			approve="--auto-approve"
			TF_IN_AUTOMATION=true
			export TF_IN_AUTOMATION
			shift
			;;
		-g | --github)
			approve="--auto-approve"
			TF_IN_AUTOMATION=true
			export TF_IN_AUTOMATION
			shift
			;;
		-d | --deployer_tfstate_key)
			TF_VAR_deployer_tfstate_key="$2"
			CONTROL_PLANE_NAME=$(echo "$TF_VAR_deployer_tfstate_key" | cut -d'-' -f1-3 | tr "[:lower:]" "[:upper:]")
            TF_VAR_control_plane_name="$CONTROL_PLANE_NAME"
			export TF_VAR_control_plane_name
			export TF_VAR_deployer_tfstate_key
			shift 2
			;;
		-c | --control_plane_name)
			CONTROL_PLANE_NAME="$2"
			CONTROL_PLANE_NAME=$(echo "${CONTROL_PLANE_NAME}" | tr "[:lower:]" "[:upper:]")
			TF_VAR_control_plane_name="$CONTROL_PLANE_NAME"
			TF_VAR_deployer_tfstate_key="${CONTROL_PLANE_NAME}-INFRASTRUCTURE.terraform.tfstate"

			export TF_VAR_deployer_tfstate_key
			export TF_VAR_control_plane_name
			shift 2
			;;
		-n | --application_configuration_name)
			APPLICATION_CONFIGURATION_NAME="$2"
			if [ ! -v APPLICATION_CONFIGURATION_ID ]; then
				APPLICATION_CONFIGURATION_ID=$(az graph query -q "Resources | join kind=leftouter (ResourceContainers | where type=='microsoft.resources/subscriptions' | project subscription=name, subscriptionId) on subscriptionId | where name == '$APPLICATION_CONFIGURATION_NAME' | project id, name, subscription" --query data[0].id --output tsv)
				export APPLICATION_CONFIGURATION_ID
			fi
			shift 2
			;;
		-l | --landscape_tfstate_key)
			TF_VAR_landscape_tfstate_key="$2"
			WORKLOAD_ZONE_NAME=$(echo "$TF_VAR_landscape_tfstate_key" | cut -d"-" -f1-3)
			TF_VAR_workload_zone_name="$WORKLOAD_ZONE_NAME"
			export TF_VAR_workload_zone_name
			shift 2
			;;
		-o | --storage_accountname)
			terraform_storage_account_name="$2"
			export terraform_storage_account_name
			getAndStoreTerraformStateStorageAccountDetails "${terraform_storage_account_name}" ""

			shift 2
			;;
		-p | --parameter_file)
			parameterFilename="$2"
			shift 2
			;;
		-s | --state_subscription)
			terraform_storage_account_subscription_id="$2"
			export terraform_storage_account_subscription_id
			shift 2
			;;
		-t | --type)
			deployment_system="$2"
			shift 2
			;;
		-w | --workload_zone_name)
			WORKLOAD_ZONE_NAME="$2"
			TF_VAR_workload_zone_name="$WORKLOAD_ZONE_NAME"
			export TF_VAR_workload_zone_name
			TF_VAR_landscape_tfstate_key="${WORKLOAD_ZONE_NAME}-INFRASTRUCTURE.terraform.tfstate"
			export TF_VAR_landscape_tfstate_key

			shift 2
			;;
		-i | --auto-approve)
			approve="--auto-approve"
			shift
			;;
		-h | --help)
			show_help_installer_v2
			return 3
			;;
        --)
            shift
            break
            ;;
        esac
    done

    automation_config_directory="${CONFIG_REPO_PATH}/.sap_deployment_automation"

    # Validate required parameters

    parameterfile_name=$(basename "${parameterFilename}")
    param_dirname=$(dirname "${parameterFilename}")

    if [ "${param_dirname}" != '.' ]; then
        print_banner "$banner_title" "Please run this command from the folder containing the parameter file" "error"
    fi

    if [ ! -f "${parameterfile_name}" ]; then
        print_banner "$banner_title" "Parameter file does not exist: ${parameterFilename}" "error"
    fi

    if [ "${deployment_system}" == sap_system ] || [ "${deployment_system}" == sap_landscape ]; then
        WORKLOAD_ZONE_NAME=$(echo "$parameterfile_name" | cut -d'-' -f1-3)

        TF_VAR_landscape_tfstate_key="${WORKLOAD_ZONE_NAME}-INFRASTRUCTURE.terraform.tfstate"
        TF_VAR_workload_zone_name="$WORKLOAD_ZONE_NAME"

        export TF_VAR_landscape_tfstate_key
        export TF_VAR_workload_zone_name
    fi

    [[ -z "$CONTROL_PLANE_NAME" ]] && {
        print_banner "$banner_title" "control_plane_name is required" "error"
        return 1
    }

    if [ -n "$CONTROL_PLANE_NAME" ]; then
        DEPLOYER_ENVIRONMENT=$(echo "$CONTROL_PLANE_NAME" | cut -d"-" -f1)
        DEPLOYER_LOCATION=$(echo "$CONTROL_PLANE_NAME" | cut -d"-" -f2)
        DEPLOYER_NETWORK=$(echo "$CONTROL_PLANE_NAME" | cut -d"-" -f3)
        deployer_configuration_file=$(get_configuration_file "$automation_config_directory" "$DEPLOYER_ENVIRONMENT" "$DEPLOYER_LOCATION" "$DEPLOYER_NETWORK")
        echo "Loading deployer configuration from ${deployer_configuration_file}"
        load_config_vars "${deployer_configuration_file}" \
            tfstate_resource_id DEPLOYER_KEYVAULT REMOTE_STATE_SA REMOTE_STATE_RG keyvault APP_CONFIG_DEPLOYMENT APPLICATION_CONFIGURATION_NAME APPLICATION_CONFIGURATION_ID

        TF_VAR_spn_keyvault_id=$(az graph query -q "Resources | join kind=leftouter (ResourceContainers | where type=='microsoft.resources/subscriptions' | project subscription=name, subscriptionId) on subscriptionId | where name == '$DEPLOYER_KEYVAULT' | project id, name, subscription" --query data[0].id --output tsv)
        export TF_VAR_spn_keyvault_id
        keyvault=$DEPLOYER_KEYVAULT
        TF_VAR_tfstate_resource_id="${tfstate_resource_id}"

        export TF_VAR_tfstate_resource_id
        terraform_storage_account_name=$(echo "$tfstate_resource_id" | cut -d'/' -f9)
        terraform_storage_account_resource_group_name=$(echo "$tfstate_resource_id" | cut -d'/' -f5)
        terraform_storage_account_subscription_id=$(echo "$tfstate_resource_id" | cut -d'/' -f3)

    fi

    [[ -z "$deployment_system" ]] && {
        print_banner "$banner_title" "type is required" "error"
        return 1
    }

    if [ -z "$CONTROL_PLANE_NAME" ] && [ -n "$deployer_tfstate_key" ]; then
        CONTROL_PLANE_NAME=$(echo "$deployer_tfstate_key" | cut -d'-' -f1-3)
    fi

    if [ -n "$CONTROL_PLANE_NAME" ]; then
        TF_VAR_deployer_tfstate_key="${CONTROL_PLANE_NAME}-INFRASTRUCTURE.terraform.tfstate"
        export TF_VAR_deployer_tfstate_key
    fi

    if [ "${deployment_system}" == sap_system ]; then
        if [ -z "${TF_VAR_landscape_tfstate_key}" ]; then
            if [ 1 != $called_from_ado ]; then
                read -r -p "Workload terraform statefile name: " TF_VAR_landscape_tfstate_key
                export TF_VAR_landscape_tfstate_key
            else
                print_banner "$banner_title" "Workload terraform statefile name is required" "error"
                unset TF_DATA_DIR
                return 2
            fi
        fi
    fi

    if [ "${deployment_system}" != sap_deployer ]; then
        if [ -n "$APPLICATION_CONFIGURATION_NAME" ] && [ -z "$APPLICATION_CONFIGURATION_ID" ]; then

            APPLICATION_CONFIGURATION_ID=$(az graph query -q "Resources | join kind=leftouter (ResourceContainers | where type=='microsoft.resources/subscriptions' | project subscription=name, subscriptionId) on subscriptionId | where name == '$APPLICATION_CONFIGURATION_NAME' | project id, name, subscription" --query data[0].id --output tsv)
            if [ -n "$APPLICATION_CONFIGURATION_ID" ]; then
                TF_VAR_application_configuration_id=$APPLICATION_CONFIGURATION_ID
                export TF_VAR_application_configuration_id
            else
                print_banner "$banner_title" "Unable to resolve application configuration id for ${APPLICATION_CONFIGURATION_NAME}" "error"
                unset TF_DATA_DIR
                return 2
            fi
        fi
        if [ -z "${TF_VAR_deployer_tfstate_key}" ]; then
            if [ 1 != $called_from_ado ]; then
                read -r -p "Deployer terraform state file name: " TF_VAR_deployer_tfstate_key
                export TF_VAR_deployer_tfstate_key
            else
                print_banner "$banner_title" "Deployer terraform state file name is required" "error"
                unset TF_DATA_DIR
                return 2
            fi
        fi
    else
        unset SDAF_APPLICATION_CONFIGURATION_NAME

    fi

    # Check that the exports ARM_SUBSCRIPTION_ID and SAP_AUTOMATION_REPO_PATH are defined
    if ! validate_exports; then
        return $?
    fi

    # Check that Terraform and Azure CLI is installed
    if ! validate_dependencies; then
        return $?
    fi

    # Check that parameter files have environment and location defined
    if ! validate_key_parameters "$parameterFilename"; then
        return $?
    fi
    if [ -n "${WORKLOAD_ZONE_NAME:-}" ]; then
        environment=$(echo "$WORKLOAD_ZONE_NAME" | awk -F'-' '{print $1}' | xargs)
        region_code=$(echo "$WORKLOAD_ZONE_NAME" | awk -F'-' '{print $2}' | xargs)
        network_logical_name=$(echo "$WORKLOAD_ZONE_NAME" | awk -F'-' '{print $3}' | xargs)
    else
        environment=$(echo "$CONTROL_PLANE_NAME" | awk -F'-' '{print $1}' | xargs)
        region_code=$(echo "$CONTROL_PLANE_NAME" | awk -F'-' '{print $2}' | xargs)
        network_logical_name=$(echo "$CONTROL_PLANE_NAME" | awk -F'-' '{print $3}' | xargs)
    fi

    system_environment_file_name=$(get_configuration_file "${automation_config_directory}" "${environment}" "${region_code}" "${network_logical_name}")
    echo "System environment file name:        ${system_environment_file_name}"
    touch "${system_environment_file_name}"

    region=$(echo "${region}" | tr "[:upper:]" "[:lower:]")
    if valid_region_name "${region}"; then
        # Convert the region to the correct code
        get_region_code "${region}"
    else
        echo "Invalid region: $region"
        return 2
    fi

    if ! checkforEnvVar "TEST_ONLY"; then
        TEST_ONLY="false"
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

function installer_retrieve_parameters() {

    TF_VAR_control_plane_name="${CONTROL_PLANE_NAME}"
    export TF_VAR_control_plane_name
    if [ "${deployment_system}" != sap_deployer ]; then
        if [ ! -v APPLICATION_CONFIGURATION_ID ]; then
            if [ -n "$APPLICATION_CONFIGURATION_NAME" ]; then
                APPLICATION_CONFIGURATION_ID=$(az graph query -q "Resources | join kind=leftouter (ResourceContainers | where type=='microsoft.resources/subscriptions' | project subscription=name, subscriptionId) on subscriptionId | where name == '$APPLICATION_CONFIGURATION_NAME' | project id, name, subscription" --query data[0].id --output tsv)
                export APPLICATION_CONFIGURATION_ID
            fi
        fi

        if [ -n "$APPLICATION_CONFIGURATION_ID" ]; then
            app_config_subscription=$(echo "$APPLICATION_CONFIGURATION_ID" | cut -d'/' -f3)

            if is_valid_id "$APPLICATION_CONFIGURATION_ID" "/providers/Microsoft.AppConfiguration/configurationStores/"; then
                print_banner "$banner_title" "Retrieving parameters from Azure App Configuration" "info" "$APPLICATION_CONFIGURATION_NAME ($app_config_subscription)"
                TF_VAR_spn_keyvault_id=$(getVariableFromApplicationConfiguration "$APPLICATION_CONFIGURATION_ID" "${CONTROL_PLANE_NAME}_KeyVaultResourceId" "$CONTROL_PLANE_NAME")
                keyvault=$(echo "$TF_VAR_spn_keyvault_id" | cut -d'/' -f9)

                management_subscription_id=$(getVariableFromApplicationConfiguration "$APPLICATION_CONFIGURATION_ID" "${CONTROL_PLANE_NAME}_SubscriptionId" "${CONTROL_PLANE_NAME}")
                TF_VAR_management_subscription_id=${management_subscription_id}
                export TF_VAR_management_subscription_id
                export TF_VAR_spn_keyvault_id
                export keyvault

                if [ -z "$tfstate_resource_id" ]; then
                    tfstate_resource_id=$(getVariableFromApplicationConfiguration "$APPLICATION_CONFIGURATION_ID" "${CONTROL_PLANE_NAME}_TerraformRemoteStateStorageAccountId" "$CONTROL_PLANE_NAME")
                    terraform_storage_account_name=$(echo "$tfstate_resource_id" | cut -d'/' -f9)
                    terraform_storage_account_resource_group_name=$(echo "$tfstate_resource_id" | cut -d'/' -f5)
                    terraform_storage_account_subscription_id=$(echo "$tfstate_resource_id" | cut -d'/' -f3)
                else
                    terraform_storage_account_name=$(echo "$tfstate_resource_id" | cut -d'/' -f9)
                    terraform_storage_account_resource_group_name=$(echo "$tfstate_resource_id" | cut -d'/' -f5)
                    terraform_storage_account_subscription_id=$(echo "$tfstate_resource_id" | cut -d'/' -f3)
                fi
                TF_VAR_tfstate_resource_id=$tfstate_resource_id

                export TF_VAR_tfstate_resource_id
                export terraform_storage_account_name
                export terraform_storage_account_resource_group_name
                export terraform_storage_account_subscription_id
            fi
        fi

        if [ -z "$terraform_storage_account_name" ]; then
            if [ -f "${param_dirname}/.terraform/terraform.tfstate" ]; then
                remote_backend=$(grep "\"type\": \"azurerm\"" .terraform/terraform.tfstate || true)
                if [ -n "${remote_backend}" ]; then

                    terraform_storage_account_subscription_id=$(grep -m1 "subscription_id" "${param_dirname}/.terraform/terraform.tfstate" | cut -d ':' -f2 | tr -d '", \r' | xargs || true)
                    terraform_storage_account_name=$(grep -m1 "storage_account_name" "${param_dirname}/.terraform/terraform.tfstate" | cut -d ':' -f2 | tr -d ' ",\r' | xargs || true)
                    terraform_storage_account_resource_group_name=$(grep -m1 "resource_group_name" "${param_dirname}/.terraform/terraform.tfstate" | cut -d ':' -f2 | tr -d ' ",\r' | xargs || true)
                    tfstate_resource_id=$(az storage account show --name "${terraform_storage_account_name}" --query id --subscription "${terraform_storage_account_subscription_id}" --resource-group "${terraform_storage_account_resource_group_name}" --out tsv)
                    export TF_VAR_tfstate_resource_id

                fi
            else
                load_config_vars "${system_environment_file_name}" \
                    tfstate_resource_id DEPLOYER_KEYVAULT

                if valid_kv_name "$DEPLOYER_KEYVAULT"; then

                    TF_VAR_spn_keyvault_id=$(az graph query -q "Resources | join kind=leftouter (ResourceContainers | where type=='microsoft.resources/subscriptions' | project subscription=name, subscriptionId) on subscriptionId | where name == '$DEPLOYER_KEYVAULT' | project id, name, subscription" --query data[0].id --output tsv)
                    export TF_VAR_spn_keyvault_id
                fi

                terraform_storage_account_name=$(echo "$tfstate_resource_id" | cut -d'/' -f9)
                terraform_storage_account_resource_group_name=$(echo "$tfstate_resource_id" | cut -d'/' -f5)
                terraform_storage_account_subscription_id=$(echo "$tfstate_resource_id" | cut -d'/' -f3)

                export terraform_storage_account_resource_group_name
                export terraform_storage_account_name
                export terraform_storage_account_subscription_id
                export TF_VAR_tfstate_resource_id

            fi
        else
            if [ -z "$tfstate_resource_id" ]; then
                tfstate_resource_id=$(az graph query -q "Resources | join kind=leftouter (ResourceContainers | where type=='microsoft.resources/subscriptions' | project subscription=name, subscriptionId) on subscriptionId | where name == '$terraform_storage_account_name' | project id, name, subscription" --query data[0].id --output tsv)
                TF_VAR_tfstate_resource_id=$tfstate_resource_id
                terraform_storage_account_name=$(echo "$tfstate_resource_id" | cut -d'/' -f9)
                terraform_storage_account_resource_group_name=$(echo "$tfstate_resource_id" | cut -d'/' -f5)
                terraform_storage_account_subscription_id=$(echo "$tfstate_resource_id" | cut -d'/' -f3)

                export TF_VAR_tfstate_resource_id
                export tfstate_resource_id
                export terraform_storage_account_resource_group_name
                export terraform_storage_account_name
                export terraform_storage_account_subscription_id
            fi

        fi
    fi

    this_ip=$(curl -s ipinfo.io/ip) >/dev/null 2>&1
    export TF_VAR_Agent_IP=$this_ip
    echo "Agent IP:                            $this_ip"

}

############################################################################################
# Function to persist the files to the storage account. The function copies the .tfvars    #
# files, the terraform.tfstate files, the <SID>hosts file and the sap-parameters.yaml file #
# Arguments:                                                                               #
#   None                                                                                   #
# Returns:                                                                                 #
#   0 on success, non-zero on failure                                                      #
# Usage:                                                                                   #
#   persist_files                                                                          #
############################################################################################

function persist_files() {

    print_banner "$banner_title" "Backup tfvars to storage account" "info"

    useSAS=$(az storage account show --name "${terraform_storage_account_name}" --query allowSharedKeyAccess --subscription "${terraform_storage_account_subscription_id}" --resource-group "${terraform_storage_account_resource_group_name}" --out tsv)

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


    if [ "${deployment_system}" == sap_library ]; then

        container_exists=$(az storage container exists --subscription "${terraform_storage_account_subscription_id}" --account-name "${terraform_storage_account_name}" --name tfvars --only-show-errors --query exists)
        if [ "${container_exists}" == "false" ]; then
            az storage container create --subscription "${terraform_storage_account_subscription_id}" --account-name "${terraform_storage_account_name}" --name tfvars --only-show-errors
        fi

        az storage blob upload --file "${system_environment_file_name}" --container-name tfvars/.sap_deployment_automation --name "${CONTROL_PLANE_NAME}" \
            --subscription "${terraform_storage_account_subscription_id}" --account-name "${terraform_storage_account_name}" --no-progress --overwrite --only-show-errors --output none

        az storage blob upload --file "${parameterFilename}" --container-name tfvars/"${state_path}"/"${key}" --name "${parameterFilename}" \
            --subscription "${terraform_storage_account_subscription_id}" --account-name "${terraform_storage_account_name}" --no-progress --overwrite --only-show-errors --output none

        if [ -f .terraform/terraform.tfstate ]; then
            az storage blob upload --file .terraform/terraform.tfstate --container-name "tfvars/${state_path}/${key}/.terraform" --name terraform.tfstate \
                --subscription "${terraform_storage_account_subscription_id}" --account-name "${terraform_storage_account_name}" --no-progress --overwrite --only-show-errors --output none
        fi
    fi

    if [ "${deployment_system}" == sap_deployer ]; then

        container_exists=$(az storage container exists --subscription "${terraform_storage_account_subscription_id}" --account-name "${terraform_storage_account_name}" --name tfvars --only-show-errors --query exists)
        if [ "${container_exists}" == "false" ]; then
            az storage container create --subscription "${terraform_storage_account_subscription_id}" --account-name "${terraform_storage_account_name}" --name tfvars --only-show-errors
        fi

        az storage blob upload --file "${system_environment_file_name}" --container-name tfvars/.sap_deployment_automation --name "${CONTROL_PLANE_NAME}" \
            --subscription "${terraform_storage_account_subscription_id}" --account-name "${terraform_storage_account_name}" --no-progress --overwrite --only-show-errors --output none

        az storage blob upload --file "${parameterFilename}" --container-name tfvars/"${state_path}"/"${key}" --name "${parameterFilename}" \
            --subscription "${terraform_storage_account_subscription_id}" --account-name "${terraform_storage_account_name}" --no-progress --overwrite --only-show-errors --output none

        if [ -f .terraform/terraform.tfstate ]; then
            az storage blob upload --file .terraform/terraform.tfstate --container-name "tfvars/${state_path}/${key}/.terraform" --name terraform.tfstate \
                --subscription "${terraform_storage_account_subscription_id}" --account-name "${terraform_storage_account_name}" --no-progress --overwrite --only-show-errors --output none
        fi
    fi


}
#############################################################################################
# Function to run the installer script.                                                     #
# Arguments:                                                                                #
#   None                                                                                    #
# Returns:                                                                                  #
#   0 on success, non-zero on failure                                                       #
# Usage:                                                                                    #
#   sdaf_installer                                                                          #
#############################################################################################

function sdaf_installer() {
    called_from_ado=0
    local green="\e[0;32m"
    local reset="\e[0m"
    # colors for terminal
    local bold_red_underscore="\e[1;4;31m"                                      #    CRIT_COLOR
    local            bold_red="\e[1;31m"                                        #   ERROR_COLOR
    local               green="\e[1;32m"                                        # SUCCESS_COLOR
    local              yellow="\e[1;33m"                                        # WARNING_COLOR
    local                blue="\e[1;34m"                                        #   DEBUG_COLOR
    local             magenta="\e[1;35m"                                        #   TRACE_COLOR
    local                cyan="\e[1;36m"                                        #    INFO_COLOR
    local               reset="\e[0m"                                           #   RESET_COLOR

    # Define an array of helper scripts
    helper_scripts=(
        "$SAP_AUTOMATION_REPO_PATH/deploy/scripts/helpers/script_helpers.sh"
        "$SAP_AUTOMATION_REPO_PATH/deploy/scripts/deploy_utils.sh"
    )

    # Call the function with the array
    installer_source_helper_scripts "${helper_scripts[@]}"
    detect_platform

    installer_check_environment_variables

    # Parse command line arguments
    if ! installer_parse_arguments "$@"; then

        if [ "${stop_execution:-0}" -eq 1 ]; then
            echo "Help requested, exiting."
            return 0
        else
            echo "Error parsing arguments, exiting with status 1."
            return 1
        fi

    fi

    param_dirname=$(dirname $(realpath "${parameterFilename}"))
    TF_DATA_DIR="${param_dirname}/.terraform"
    export TF_DATA_DIR

    var_file="${param_dirname}"/"${parameterFilename}"

	if [ -f "${param_dirname}/.terraform/terraform.tfstate" ]; then
		remote_backend=$(grep "\"type\": \"azurerm\"" "${param_dirname}/.terraform/terraform.tfstate" || true)
		if [ -n "${remote_backend}" ]; then

			terraform_storage_account_subscription_id=$(grep -m1 "subscription_id" "${param_dirname}/.terraform/terraform.tfstate" | cut -d ':' -f2 | tr -d '", \r' | xargs || true)
			terraform_storage_account_name=$(grep -m1 "storage_account_name" "${param_dirname}/.terraform/terraform.tfstate" | cut -d ':' -f2 | tr -d ' ",\r' | xargs || true)
			terraform_storage_account_resource_group_name=$(grep -m1 "resource_group_name" "${param_dirname}/.terraform/terraform.tfstate" | cut -d ':' -f2 | tr -d ' ",\r' | xargs || true)
			tfstate_resource_id=$(az storage account show --name "${terraform_storage_account_name}" --query id --subscription "${terraform_storage_account_subscription_id}" --resource-group "${terraform_storage_account_resource_group_name}" --out tsv)
			TF_VAR_tfstate_resource_id="$tfstate_resource_id"
			TF_VAR_management_subscription_id="$terraform_storage_account_subscription_id"
			export TF_VAR_tfstate_resource_id
			export TF_VAR_management_subscription_id
		fi
	fi

    if ! installer_retrieve_parameters; then
        return $?
    fi

    # Provide a way to limit the number of parallel tasks for Terraform
    parallelism=${TFE_PARALLELISM:-10}                                          # Default to 10 if TFE_PARALLELISM is not set

    TF_PLUGIN_CACHE_MAY_BREAK_DEPENDENCY_LOCK_FILE=1
    export TF_PLUGIN_CACHE_MAY_BREAK_DEPENDENCY_LOCK_FILE

    banner_title="Installer - $deployment_system"

    echo ""
    echo -e "${green}Deployment information:"
    echo -e "-------------------------------------------------------------------------------$reset"
    echo "Parameter file:                      $parameterFilename"
    echo "Current directory:                   $(pwd)"
    echo "Control Plane name:                  ${CONTROL_PLANE_NAME}"
    echo "Control Plane state file name:       ${TF_VAR_deployer_tfstate_key}"
    if [ -n "${WORKLOAD_ZONE_NAME:-}" ]; then
        echo "Workload zone name:                  ${WORKLOAD_ZONE_NAME}"
        TF_VAR_landscape_tfstate_key="${WORKLOAD_ZONE_NAME}-INFRASTRUCTURE.terraform.tfstate"
        echo "Workload state file name:            ${TF_VAR_landscape_tfstate_key}"
        export TF_VAR_landscape_tfstate_key
    fi
    key=$(echo "${parameterfile_name}" | cut -d. -f1)

    if [ -n "${APPLICATION_CONFIGURATION_NAME:-}" ]; then
        echo "Application configuration name:      ${APPLICATION_CONFIGURATION_NAME:-Undefined}"
    fi
    echo "Configuration file:                  $system_environment_file_name"
    echo "Deployment region:                   $region"
    echo "Deployment region code:              $region_code"
    echo "Target subscription:                 $ARM_SUBSCRIPTION_ID"

    if [ "${DEBUG:-false}" = true ]; then
        print_banner "Installer - $deployment_system" "Enabling debug mode" "info"
        echo "Azure login info:"
        az account show --query user --output table
        TF_LOG=DEBUG
        export TF_LOG
        echo ""
        printenv | grep ARM_
        printenv | grep TF_VAR_
    fi

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
        if [ -f "/etc/profile.d/deploy_server.sh" ]; then
            if [ ! -d /opt/terraform/.terraform.d/plugin-cache ]; then
                sudo mkdir -p /opt/terraform/.terraform.d/plugin-cache
                sudo chown -R "$USER" /opt/terraform/.terraform.d
            else
                sudo chown -R "$USER" /opt/terraform/.terraform.d
            fi
            export TF_PLUGIN_CACHE_DIR=/opt/terraform/.terraform.d/plugin-cache
        fi
    fi

    terraform_module_directory="$SAP_AUTOMATION_REPO_PATH/deploy/terraform/run/${deployment_system}"
    cd "${param_dirname}" || exit

    if [ ! -d "${terraform_module_directory}" ]; then

        printf -v val %-40.40s "$deployment_system"
        print_banner "$banner_title" "Incorrect system deployment type specified: ${val}$" "error" "System name $(basename "$param_dirname")"
        exit 1
    fi

    export TF_DATA_DIR="${param_dirname}/.terraform"

    echo ""
    echo -e "${green}Terraform details:"
    echo -e "-------------------------------------------------------------------------${reset}"
    echo "Statefile subscription:              ${terraform_storage_account_subscription_id}"
    echo "Statefile storage account:           ${terraform_storage_account_name}"
    echo "Statefile resource group:            ${terraform_storage_account_resource_group_name}"
    echo "State file:                          ${key}.terraform.tfstate"
    echo "Target subscription:                 ${ARM_SUBSCRIPTION_ID}"
    echo "Deployer state file:                 ${TF_VAR_deployer_tfstate_key}"
    echo "Workload zone state file:            ${TF_VAR_landscape_tfstate_key:-Undefined}"
    echo "Control plane keyvault:              ${keyvault}"
    echo ""
    echo "Current directory:                   $(pwd)"
    echo "Parallelism count:                   $parallelism"
    echo ""

    echo "Target subscription:                 ${ARM_SUBSCRIPTION_ID}"
    useSAS=$(az storage account show --name "${terraform_storage_account_name}" --query allowSharedKeyAccess --subscription "${terraform_storage_account_subscription_id}" --out tsv)

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

    if [ "${deployment_system}" == sap_system ]; then

        if [[ -n $TF_VAR_landscape_tfstate_key ]]; then
            workloadZone_State_file_Size_String=$(az storage blob list --container-name tfstate --account-name "${terraform_storage_account_name}" --subscription "${terraform_storage_account_subscription_id}" --query "[?name=='$TF_VAR_landscape_tfstate_key'].properties.contentLength" --output tsv)

            workloadZone_State_file_Size=$(("$workloadZone_State_file_Size_String"))

            if [ "$workloadZone_State_file_Size" -lt 5000 ]; then
                print_banner "$banner_title" "Workload zone terraform state file is empty" "error" "State file name: ${TF_VAR_landscape_tfstate_key}"
                az storage blob list --container-name tfstate --account-name "${terraform_storage_account_name}" --subscription "${terraform_storage_account_subscription_id}" --query "[].{name:name,size:properties.contentLength,lease:lease.status}" --output table
            fi
        fi

        if [[ -n $TF_VAR_deployer_tfstate_key ]]; then

            deployer_Statefile_Size_String=$(az storage blob list --container-name tfstate --account-name "${terraform_storage_account_name}" --subscription "${terraform_storage_account_subscription_id}" --query "[?name=='$TF_VAR_deployer_tfstate_key'].properties.contentLength" --output tsv)

            deployer_Statefile_Size=$(("$deployer_Statefile_Size_String"))

            if [ "$deployer_Statefile_Size" -lt 5000 ]; then
                print_banner "$banner_title" "Deployer terraform state file is empty" "error" "State file name: ${TF_VAR_deployer_tfstate_key}"

                az storage blob list --container-name tfstate --account-name "${terraform_storage_account_name}" --subscription "${terraform_storage_account_subscription_id}" --query "[].{name:name,size:properties.contentLength,lease:lease.status}" --output table
            fi
        fi
    fi

    if [ "${deployment_system}" == sap_landscape ]; then

        if [[ -n $TF_VAR_deployer_tfstate_key ]]; then

            deployer_Statefile_Size_String=$(az storage blob list --container-name tfstate --account-name "${terraform_storage_account_name}" --subscription "${terraform_storage_account_subscription_id}" --query "[?name=='$TF_VAR_deployer_tfstate_key'].properties.contentLength" --output tsv)

            deployer_Statefile_Size=$(("$deployer_Statefile_Size_String"))

            if [ "$deployer_Statefile_Size" -lt 5000 ]; then
                print_banner "$banner_title" "Deployer terraform state file is empty" "error" "State file name: ${TF_VAR_deployer_tfstate_key}"

                az storage blob list --container-name tfstate --account-name "${terraform_storage_account_name}" --subscription "${terraform_storage_account_subscription_id}" --query "[].{name:name,size:properties.contentLength,lease:lease.status}" --output table
            fi
        fi
    fi

    TF_VAR_subscription_id="$ARM_SUBSCRIPTION_ID"
    export TF_VAR_subscription_id

    terraform_module_directory="${SAP_AUTOMATION_REPO_PATH}/deploy/terraform/run/${deployment_system}"/
    export TF_DATA_DIR="${param_dirname}/.terraform"

    new_deployment=0

    az account set --subscription "$ARM_SUBSCRIPTION_ID"

    if [ ! -f .terraform/terraform.tfstate ]; then
        print_banner "$banner_title" "New deployment" "info" "System name $(basename "$param_dirname")"
        tfstate_resource_id=$(az storage account show --name "${terraform_storage_account_name}" --query id --subscription "${terraform_storage_account_subscription_id}" --resource-group "${terraform_storage_account_resource_group_name}" --out tsv)
        TF_VAR_tfstate_resource_id="$tfstate_resource_id"
        export TF_VAR_tfstate_resource_id

        save_config_vars "${system_environment_file_name}" "REMOTE_STATE_SA" "REMOTE_STATE_RG" "tfstate_resource_id"

        if terraform -chdir="${terraform_module_directory}" init -upgrade -input=false \
            --backend-config "subscription_id=${ARM_SUBSCRIPTION_ID}" \
            --backend-config "resource_group_name=${terraform_storage_account_resource_group_name}" \
            --backend-config "storage_account_name=${terraform_storage_account_name}" \
            --backend-config "container_name=tfstate" \
            --backend-config "key=${key}.terraform.tfstate"; then
            print_banner "$banner_title" "Terraform init succeeded." "success" "System name $(basename "$param_dirname")"
        else
            return_value=$?
            print_banner "$banner_title" "Terraform init failed." "error" "System name $(basename "$param_dirname")"
            return $return_value
        fi

    else
        new_deployment=1

        if local_backend=$(grep "\"type\": \"local\"" .terraform/terraform.tfstate); then
            if [ -n "$local_backend" ]; then
                print_banner "$banner_title" "Migrating the state to Azure" "info" "System name $(basename "$param_dirname")"

                terraform_module_directory="${SAP_AUTOMATION_REPO_PATH}/deploy/terraform/bootstrap/${deployment_system}"/

                if terraform -chdir="${terraform_module_directory}" init -migrate-state --backend-config "path=${param_dirname}/terraform.tfstate"; then
                    return_value=$?
                    print_banner "$banner_title" "Terraform local init succeeded" "success" "System name $(basename "$param_dirname")"
                else
                    return_value=10
                    print_banner "$banner_title" "Terraform local init failed ($return_value)" "error" "System name $(basename "$param_dirname")"
                    exit $return_value
                fi
            fi

            terraform_module_directory="${SAP_AUTOMATION_REPO_PATH}/deploy/terraform/run/${deployment_system}"/

            if terraform -chdir="${terraform_module_directory}" init -force-copy \
                --backend-config "subscription_id=${terraform_storage_account_subscription_id}" \
                --backend-config "resource_group_name=${terraform_storage_account_resource_group_name}" \
                --backend-config "storage_account_name=${terraform_storage_account_name}" \
                --backend-config "container_name=tfstate" \
                --backend-config "key=${key}.terraform.tfstate"; then
                print_banner "$banner_title" "Terraform init succeeded." "success" "System name $(basename "$param_dirname")"

            else
                return_value=$?
                print_banner "$banner_title" "Terraform init failed ($return_value)" "error" "System name $(basename "$param_dirname")"
                return_value=10
                return $return_value
            fi
        else
            echo "Terraform state:                     remote"
            new_deployment=0
            tfstate_resource_id=$(az storage account show --name "${terraform_storage_account_name}" --query id --subscription "${terraform_storage_account_subscription_id}" --resource-group "${terraform_storage_account_resource_group_name}" --out tsv)
            TF_VAR_tfstate_resource_id="$tfstate_resource_id"
            export TF_VAR_tfstate_resource_id
            print_banner "$banner_title" "The system has already been deployed and the state file is in Azure" "info" "System name $(basename "$param_dirname")"

            if terraform -chdir="${terraform_module_directory}" init -upgrade -force-copy -migrate-state \
                --backend-config "subscription_id=${terraform_storage_account_subscription_id}" \
                --backend-config "resource_group_name=${terraform_storage_account_resource_group_name}" \
                --backend-config "storage_account_name=${terraform_storage_account_name}" \
                --backend-config "container_name=tfstate" \
                --backend-config "key=${key}.terraform.tfstate"; then
                return_value=$?
                print_banner "$banner_title" "Terraform init succeeded." "success" "System name $(basename "$param_dirname")"
            else
                return_value=10
                print_banner "$banner_title" "Terraform init failed ($return_value)" "error" "System name $(basename "$param_dirname")"
                return $return_value
            fi
        fi
    fi

    print_banner "$banner_title" "Running Terraform Plan" "info" "System name $(basename "$param_dirname")"
    # Declare an array
    allParameters=(-var-file "${var_file}")
    if [ -f terraform.tfvars ]; then
        allParameters+=(-var-file "${param_dirname}/terraform.tfvars")
    fi

    if [ "$PLATFORM" != "cli" ]; then
        allParameters+=(-input=false)
    fi

    if [ 1 -eq "$new_deployment" ]; then
        allParameters+=(-var deployment=new)
    fi

    allImportParameters=(-var-file "${var_file}")
    if [ -f terraform.tfvars ]; then
        allImportParameters+=(-var-file "${param_dirname}/terraform.tfvars")
    fi
    if [ -f terraform.tfvars ]; then
        allImportParameters+=(-var-file "${param_dirname}/terraform.tfvars")
    fi

    if [ -f plan_output.log ]; then
        rm plan_output.log
    fi

    apply_needed=0

    echo "Terraform plan command: terraform -chdir=${terraform_module_directory} plan -detailed-exitcode ${allParameters[*]}"

    if terraform -chdir="$terraform_module_directory" plan -detailed-exitcode "${allParameters[@]}" | tee plan_output.log; then
        return_value=${PIPESTATUS[0]}
    else
        return_value=${PIPESTATUS[0]}
    fi

    if [ 0 == "$return_value" ]; then
        print_banner "${banner_title}" "Terraform plan succeeded ($return_value), no changes to apply" "success" "System name $(basename "$param_dirname")"
        return_value=0
    elif [ 2 == "$return_value" ]; then
        print_banner "${banner_title}" "Terraform plan succeeded ($return_value), changes to apply" "info" "System name $(basename "$param_dirname")"
        apply_needed=1
        return_value=0
    else
        print_banner "${banner_title}" "Terraform plan failed ($return_value)" "error" "System name $(basename "$param_dirname")"
        if [ -f plan_output.log ]; then
            cat plan_output.log
            rm plan_output.log
        fi
        unset TF_DATA_DIR
        return "$return_value"
    fi
    state_path="SYSTEM"

    fatal_errors=0

    if [ "${deployment_system}" == "sap_deployer" ]; then
        state_path="DEPLOYER"
        echo "Checking for resources that would be recreated in the deployer system. This can lead to data loss if not intended. Please review carefully."

        if ! terraform -chdir="${terraform_module_directory}" output | grep "No outputs"; then
            DEPLOYER_KEYVAULT=$(terraform -chdir="${terraform_module_directory}" output -no-color -raw deployer_kv_user_name | tr -d \")
            if [ -n "$DEPLOYER_KEYVAULT" ]; then
                save_config_var "DEPLOYER_KEYVAULT" "${system_environment_file_name}"
            fi
        fi
    elif [ "${deployment_system}" == "sap_library" ]; then
        state_path="LIBRARY"
        echo "Checking for resources that would be recreated in the SAP Library. This can lead to data loss if not intended. Please review carefully."

        if ! terraform -chdir="${terraform_module_directory}" output | grep "No outputs"; then
            tfstate_resource_id=$(terraform -chdir="${terraform_module_directory}" output tfstate_resource_id | tr -d \")
            save_config_vars "${system_environment_file_name}" \
                tfstate_resource_id
        fi

        # Define an array resources
        resources=(
            "module.sap_library.azurerm_storage_account.storage_sapbits~SAP Library Storage Account"
            "module.sap_library.azurerm_storage_container.storagecontainer_sapbits~SAP Library Storage Account container"
            "module.sap_library.azurerm_storage_account.storage_tfstate~Terraform State Storage Account"
            "module.sap_library.azurerm_storage_container.storagecontainer_sapbits~Terraform State Storage Account container"
        )

        # Call the function with the array
        for resource in "${resources[@]}"; do
            moduleId=$(echo "$resource" | cut -d'~' -f1)
            description=$(echo "$resource" | cut -d'~' -f2)
            if ! testIfResourceWouldBeRecreated "$moduleId" "plan_output.log" "$description"; then
                fatal_errors=1
            fi
        done
    elif [ "${deployment_system}" == "sap_landscape" ]; then
        echo "Checking for resources that would be recreated in the landscape. This can lead to data loss if not intended. Please review carefully."
        state_path="LANDSCAPE"
        # Define an array resources
        resources=(
            "module.sap_landscape.azurerm_key_vault.kv_user~Workload zone key vault"
        )

        # Call the function with the array
        for resource in "${resources[@]}"; do
            moduleId=$(echo "$resource" | cut -d'~' -f1)
            description=$(echo "$resource" | cut -d'~' -f2)
            if ! testIfResourceWouldBeRecreated "$moduleId" "plan_output.log" "$description"; then
                fatal_errors=1
            fi
        done
    else
        state_path="SYSTEM"
        echo "Checking for resources that would be recreated in the system. This can lead to data loss if not intended. Please review carefully."

        # Define an array resources
        resources=(
            "module.hdb_node.azurerm_linux_virtual_machine.vm_dbnode~Database server(s)"
            "module.hdb_node.azurerm_managed_disk.data_disk~Database server disk(s)"
            "module.anydb_node.azurerm_windows_virtual_machine.dbserver~Database server(s)"
            "module.anydb_node.azurerm_linux_virtual_machine.dbserver~Database server(s)"
            "module.anydb_node.azurerm_managed_disk.disks~Database server disk(s)"
            "module.app_tier.azurerm_windows_virtual_machine.app~Application server(s)"
            "module.app_tier.azurerm_linux_virtual_machine.app~Application server(s)"
            "module.app_tier.azurerm_managed_disk.app~Application server disk(s)"
            "module.app_tier.azurerm_windows_virtual_machine.scs~SCS server(s)"
            "module.app_tier.azurerm_linux_virtual_machine.scs~SCS server(s)"
            "module.app_tier.azurerm_managed_disk.scs~SCS server disk(s)"
            "module.app_tier.azurerm_windows_virtual_machine.web~Web server(s)"
            "module.app_tier.azurerm_linux_virtual_machine.web~Web server(s)"
            "module.app_tier.azurerm_managed_disk.web~Web server disk(s)"
        )

        # Call the function with the array
        for resource in "${resources[@]}"; do
            moduleId=$(echo "$resource" | cut -d'~' -f1)
            description=$(echo "$resource" | cut -d'~' -f2)
            if ! testIfResourceWouldBeRecreated "$moduleId" "plan_output.log" "$description"; then
                fatal_errors=1
            fi
        done
    fi

    if [ "${TEST_ONLY}" == "true" ]; then
        print_banner "$banner_title" "Running plan only. No deployment performed." "info" "System name $(basename "$param_dirname")"

        if [ $fatal_errors == 1 ]; then
            print_banner "$banner_title" "!!! Risk for Data loss !!!" "error" "Please inspect the output of Terraform plan carefully"
            return 10
        fi
        return 0
    fi

    if [ $fatal_errors == 1 ]; then
        apply_needed=0
        print_banner "$banner_title" "!!! Risk for Data loss !!!" "error" "Please inspect the output of Terraform plan carefully"
        if [ 1 == "$called_from_ado" ]; then
            unset TF_DATA_DIR
            echo ##vso[task.logissue type=error]Risk for data loss, Please inspect the output of Terraform plan carefully. Run manually from deployer
            return 10
        fi

        if [ "$PLATFORM" == "cli" ]; then
            read -r -p "Do you want to continue with the deployment Y/N? " ans
            answer=${ans^^}
            if [ "$answer" == "Y" ]; then
                apply_needed=1
            else
                unset TF_DATA_DIR
                echo "Deployment cancelled by user. Please inspect the output of Terraform plan carefully."
                return 10
            fi
        fi

    fi

    if [ 1 == $apply_needed ]; then
        print_banner "$banner_title" "Running Terraform apply" "info" "System name $(basename "$param_dirname")"
        if [ "$PLATFORM" != "cli" ] || [ "$approve" == "--auto-approve" ]; then
            allParameters+=(-json)
            allParameters+=(--auto-approve)
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
            print_banner "$banner_title" "Terraform apply failed ($return_value)" "error" "System name $(basename "$param_dirname")"
        elif [ "$return_value" -eq 2 ]; then
            # return code 2 is ok
            print_banner "$banner_title" "Terraform apply succeeded ($return_value)" "success" "System name $(basename "$param_dirname")"
            if [ -f apply_output.json ]; then
                rm apply_output.json
            fi
            return_value=0
        else
            print_banner "$banner_title" "Terraform apply succeeded ($return_value)" "success" "System name $(basename "$param_dirname")"
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
                    print_banner "Terraform apply" "Errors detected in apply output" "warning" "Attempt $i of 10 to import existing resources"
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

    persist_files

    if [ "${DEBUG:-false}" == true ]; then
        echo "Terraform state file:"
        terraform -chdir="${terraform_module_directory}" output -json
    fi

    if [ 0 -ne "$return_value" ]; then
        print_banner "$banner_title" "Errors during the apply phase" "error" "System name $(basename "$param_dirname")"
        unset TF_DATA_DIR
        return "$return_value"
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

        deployer_random_id=$(terraform -chdir="${terraform_module_directory}" output -no-color -raw random_id | tr -d \")
        if [ -n "${deployer_random_id}" ]; then
            save_config_var "deployer_random_id" "${system_environment_file_name}"
            custom_random_id="${deployer_random_id}"
            sed -i -e "" -e /"custom_random_id"/d "${var_file}"
            # printf "custom_random_id=\"%s\"\n" "${custom_random_id}" >>"${var_file}"
            printf "\n# The parameter 'custom_random_id' can be used to control the random 3 digits at the end of the storage accounts and key vaults\ncustom_random_id = \"%s\"\n" "${custom_random_id}" >>"${var_file}"
        fi

        # shellcheck disable=SC2034
        deployer_public_ip_address=$(terraform -chdir="${terraform_module_directory}" output -no-color -raw deployer_public_ip_address | tr -d \")
        save_config_var "deployer_public_ip_address" "${system_environment_file_name}"
        keyvault=$(terraform -chdir="${terraform_module_directory}" output -no-color -raw deployer_kv_user_name | tr -d \")
        if valid_kv_name "$keyvault"; then
            save_config_var "keyvault" "${system_environment_file_name}"
            print_banner "$banner_title" "The Control plane keyvault: ${keyvault}" "info"
        else
            print_banner "$banner_title" "The provided keyvault is not valid: ${keyvault}" "error"
        fi
    fi

    if [ "${deployment_system}" == sap_landscape ]; then

        workloadkeyvault=$(terraform -chdir="${terraform_module_directory}" output -no-color -raw workloadzone_kv_name | tr -d \")
        if [ -n "${workloadkeyvault}" ]; then
            save_config_var "workloadkeyvault" "${system_environment_file_name}"
        fi
        workload_zone_random_id=$(terraform -chdir="${terraform_module_directory}" output -no-color -raw random_id | tr -d \")
        if [ -n "${workload_zone_random_id}" ]; then
            save_config_var "workload_zone_random_id" "${system_environment_file_name}"
            custom_random_id="${workload_zone_random_id:0:3}"
            sed -i -e /"custom_random_id"/d "${var_file}"
            printf "\n# The parameter 'custom_random_id' can be used to control the random 3 digits at the end of the storage accounts and key vaults\ncustom_random_id = \"%s\"\n" "${custom_random_id}" >>"${var_file}"

        fi

        now=$(date)
        cat <<EOF >"${WORKLOAD_ZONE_NAME}".md

Workload zone $WORKLOAD_ZONE_NAME was successfully deployed.

Deployed on: "${now}"

**Deployment details**

Workload zone name: $WORKLOAD_ZONE_NAME
Keyvault name:      ${workloadkeyvault}

EOF

    fi

    if [ "${deployment_system}" == sap_library ]; then
        terraform_storage_account_name=$(terraform -chdir="${terraform_module_directory}" output -no-color -raw remote_state_storage_account_name | tr -d \")

        library_random_id=$(terraform -chdir="${terraform_module_directory}" output -no-color -raw random_id | tr -d \")
        if [ -n "${library_random_id}" ]; then
            save_config_var "library_random_id" "${system_environment_file_name}"
            custom_random_id="${library_random_id:0:3}"
            sed -i -e /"custom_random_id"/d "${var_file}"
            printf "\n# The parameter 'custom_random_id' can be used to control the random 3 digits at the end of the storage accounts and key vaults\ncustom_random_id = \"%s\"\n" "${custom_random_id}" >>"${var_file}"

        fi

        getAndStoreTerraformStateStorageAccountDetails "${terraform_storage_account_name}" "${system_environment_file_name}"

    fi

    if [ "${deployment_system}" == sap_system ]; then

        SAP_SID=$(grep -m1 "sap_sid" sap-parameters.yaml | cut -d ':' -f2 | tr -d '", \r' | xargs || true)
        DB_PLATFORM=$(grep -m1 "platform" sap-parameters.yaml | cut -d ':' -f2 | tr -d '", \r' | xargs || true)
        SCS_HIGH_AVAILABILITY=$(grep -m1 "scs_high_availability" sap-parameters.yaml | cut -d ':' -f2 | tr -d '", \r' | xargs || true)
        DB_HIGH_AVAILABILITY=$(grep -m1 "database_high_availability" sap-parameters.yaml | cut -d ':' -f2 | tr -d '", \r' | xargs || true)

        now=$(date)
        cat <<EOF >"${SID}".md

Deployed on: "${now}"

**Configuration details**
| Resource | Name |
| -------------------------------------- | ----------------------- |
| SID                                    | $SAP_SID                |
| Platform                               | $DB_PLATFORM            |
| SCS High Availability                  | $SCS_HIGH_AVAILABILITY  |
| Database High Availability             | $DB_HIGH_AVAILABILITY   |


EOF

    fi
    if [ -f ./exports.sh ]; then
        source ./exports.sh
    fi

    unset TF_DATA_DIR
    print_banner "$banner_title" "Deployment completed." "info" "Exiting $SCRIPT_NAME"

    return "$return_value"
}

###############################################################################
# Main script execution                                                       #
# This script is designed to be run directly, not sourced.                    #
# It will execute the sdaf_installer function and handle the exit codes.      #
###############################################################################

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # Only run if script is executed directly, not when sourced
    # Ensure that the exit status of a pipeline command is non-zero if any
    # stage of the pipefile has a non-zero exit status.
    set -o pipefail

    #External helper functions
    #. "$(dirname "${BASH_SOURCE[0]}")/deploy_utils.sh"

    script_directory="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
    SCRIPT_NAME="$(basename "$0")"

    # Fail on any error, undefined variable, or pipeline failure

    # Enable debug mode if DEBUG is set to 'True'
    if [[ "${DEBUG:-false}" == 'true' ]]; then
        # Enable debugging
        # Exit on error
        set -euox pipefail
        echo "Environment variables:"
        printenv | sort
    fi

    if [[ -f /etc/profile.d/deploy_server.sh ]]; then
        path=$(grep -m 1 "export PATH=" /etc/profile.d/deploy_server.sh | awk -F'=' '{print $2}' | xargs)
        export PATH=$path
    fi
    if sdaf_installer "$@"; then
		    return_value=$?
        echo "Script executed successfully."
        exit $return_value
    else
		    return_value=$?
        echo "Script failed with exit code $?"
        exit $?
    fi

fi
