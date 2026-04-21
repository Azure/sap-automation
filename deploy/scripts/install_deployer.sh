#!/bin/bash
# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

#error codes include those from /usr/include/sysexits.h

#colors for terminal
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

SCRIPT_NAME="$(basename "$0")"

echo "Entering: ${SCRIPT_NAME}"
banner_title="Install Deployer"

detect_platform

#Internal helper functions
function showhelp {
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

#process inputs - may need to check the option i for auto approve as it is not used

INPUT_ARGUMENTS=$(getopt -n install_deployer -o p:ih --longoptions parameterfile:,auto-approve,help -- "$@")
VALID_ARGUMENTS=$?

if [ "$VALID_ARGUMENTS" != "0" ]; then
    showhelp
    exit 3
fi

eval set -- "$INPUT_ARGUMENTS"
while :; do
    case "$1" in
    -p | --parameterfile)
        parameterfile="$2"
        shift 2
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

deployment_system=sap_deployer

param_dirname=$(dirname "${parameterfile}")
param_filename=$(basename "${parameterfile}")
export TF_DATA_DIR="${param_dirname}/.terraform"

echo "Parameter file:                      ${parameterfile}"

if [ ! -f "${parameterfile}" ]; then
    printf -v val %-40.40s "$parameterfile"
    echo ""
    echo "#########################################################################################"
    echo "#                                                                                       #"
    echo "#               Parameter file does not exist: ${val} #"
    echo "#                                                                                       #"
    echo "#########################################################################################"
    exit 2 #No such file or directory
fi

if [ "$param_dirname" != '.' ]; then
    echo ""
    echo "#########################################################################################"
    echo "#                                                                                       #"
    echo "#   Please run this command from the folder containing the parameter file               #"
    echo "#                                                                                       #"
    echo "#########################################################################################"
    exit 3
fi

if [ "${DEBUG:-false}" == true ]; then
    echo -e "${cyan}Enabling debug mode$reset_formatting"
    set -x
    set -o errexit
fi
# Check that parameter files have environment and location defined
validate_key_parameters "$parameterfile"
return_code=$?
if [ 0 != $return_code ]; then
    exit $return_code
fi

region=$(echo "${region}" | tr "[:upper:]" "[:lower:]")
# Convert the region to the correct code
region_code=""
get_region_code "$region"

key=$(echo "${parameterfile}" | cut -d. -f1)

#Persisting the parameters across executions
automation_config_directory="$CONFIG_REPO_PATH/.sap_deployment_automation"
generic_environment_file_name="${automation_config_directory}config"

ENVIRONMENT=$(echo "$key" | awk -F'-' '{print $1}' | xargs)
LOCATION=$(echo "$key" | awk -F'-' '{print $2}' | xargs)
NETWORK=$(echo "$key" | awk -F'-' '{print $3}' | xargs)

deployer_environment_file_name=$(get_configuration_file "$automation_config_directory" "$ENVIRONMENT" "$LOCATION" "$NETWORK")

deployer_plan_directory="${automation_config_directory}/plan/"
deployer_plan_name="${deployer_plan_directory}${param_filename}.tfplan"

param_dirname=$(pwd)

init "${automation_config_directory}" "${generic_environment_file_name}" "${deployer_environment_file_name}"

# check if the deployer plan directory exists, if not create it
if [ ! -d "${deployer_plan_directory}" ]; then
    mkdir -p "${deployer_plan_directory}"
    touch "${deployer_plan_name}"
else
    if [ ! -f "${deployer_plan_name}" ]; then
        touch "${deployer_plan_name}"
    fi
fi

var_file="${param_dirname}"/"${parameterfile}"
# Check that the exports ARM_SUBSCRIPTION_ID and SAP_AUTOMATION_REPO_PATH are defined
validate_exports
return_code=$?
if [ 0 != $return_code ]; then
    exit $return_code
fi

echo "Configuration file:                  $parameterfile"
echo "Deployment region:                   $region"
echo "Deployment region code:              $region_code"
echo "Deployment configuration file:       $deployer_environment_file_name"

terraform_module_directory="${SAP_AUTOMATION_REPO_PATH}"/deploy/terraform/bootstrap/"${deployment_system}"/
export TF_DATA_DIR="${param_dirname}"/.terraform

this_ip=$(curl -s ipinfo.io/ip) >/dev/null 2>&1
export TF_VAR_Agent_IP=$this_ip
echo "Agent IP:                            $this_ip"

# Check that Terraform and Azure CLI is installed
validate_dependencies
return_code=$?
if [ 0 != $return_code ]; then
    exit $return_code
fi

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

if [ ! -d ./.terraform/ ]; then
    print_banner "New deployment" "info"
    terraform -chdir="${terraform_module_directory}" init -upgrade -backend-config "path=${param_dirname}/terraform.tfstate"
else
    if [ -f ./.terraform/terraform.tfstate ]; then
        azure_backend=$(grep "\"type\": \"azurerm\"" .terraform/terraform.tfstate || true)
        if [ -n "$azure_backend" ]; then

            print_banner "The state is already migrated to Azure!!!" "info"

            REINSTALL_SUBSCRIPTION=$(grep -m1 "subscription_id" "${param_dirname}/.terraform/terraform.tfstate" | cut -d ':' -f2 | tr -d '", \r' | xargs || true)
            REINSTALL_ACCOUNTNAME=$(grep -m1 "storage_account_name" "${param_dirname}/.terraform/terraform.tfstate" | cut -d ':' -f2 | tr -d ' ",\r' | xargs || true)
            REINSTALL_RESOURCE_GROUP=$(grep -m1 "resource_group_name" "${param_dirname}/.terraform/terraform.tfstate" | cut -d ':' -f2 | tr -d ' ",\r' | xargs || true)

            tfstate_resource_id=$(az resource list --name "$REINSTALL_ACCOUNTNAME" --subscription "$REINSTALL_SUBSCRIPTION" --resource-type Microsoft.Storage/storageAccounts --query "[].id | [0]" -o tsv)
            if [ -n "${tfstate_resource_id}" ]; then
                echo "Reinitializing against remote state"
                this_ip=$(curl -s ipinfo.io/ip) >/dev/null 2>&1
                az storage account network-rule add --account-name "$REINSTALL_ACCOUNTNAME" --resource-group "$REINSTALL_RESOURCE_GROUP" --ip-address "${this_ip}" --only-show-errors --output none
                echo "Sleeping for 30 seconds to allow the network rule to take effect"
                sleep 30
                export TF_VAR_tfstate_resource_id=$tfstate_resource_id

                terraform_module_directory="${SAP_AUTOMATION_REPO_PATH}/deploy/terraform/run/sap_deployer"/

                if terraform -chdir="${terraform_module_directory}" init -upgrade -migrate-state \
                    --backend-config "subscription_id=$REINSTALL_SUBSCRIPTION" \
                    --backend-config "resource_group_name=$REINSTALL_RESOURCE_GROUP" \
                    --backend-config "storage_account_name=$REINSTALL_ACCOUNTNAME" \
                    --backend-config "container_name=tfstate" \
                    --backend-config "key=${key}.terraform.tfstate"; then
                    echo ""
                    echo -e "${cyan}Terraform init:                        succeeded$reset_formatting"
                    echo ""
                    terraform -chdir="${terraform_module_directory}" refresh -var-file="${var_file}"
                    keyvault_id=$(terraform -chdir="${terraform_module_directory}" output deployer_kv_user_arm_id | tr -d \")
                    echo "$keyvault_id"
                    keyvault=$(echo "$keyvault_id" | cut -d / -f9)
                    keyvault_resource_group=$(echo "$keyvault_id" | cut -d / -f5)
                    keyvault_subscription=$(echo "$keyvault_id" | cut -d / -f3)

                    export TF_VAR_recover=true

                    az keyvault update --name "$keyvault" --resource-group "$keyvault_resource_group" --subscription "$keyvault_subscription" --public-network-access Enabled --only-show-errors --output none
                    echo "Sleeping for 30 seconds to allow the key vault network rule to take effect"
                    sleep 30
                else
                    print_banner "${banner_title}" "Terraform init: succeeded" "success"
                    exit 10
                fi
            else
                if terraform -chdir="${terraform_module_directory}" init -upgrade -reconfigure --backend-config "path=${param_dirname}/terraform.tfstate"; then
                    print_banner "${banner_title}" "Terraform init: succeeded" "success"
                    terraform -chdir="${terraform_module_directory}" refresh -var-file="${var_file}"
                else
                    print_banner "${banner_title}" "Terraform init: failed" "error"
                    exit 10
                fi
            fi
        else
            if terraform -chdir="${terraform_module_directory}" init -migrate-state -upgrade -backend-config "path=${param_dirname}/terraform.tfstate"; then
                print_banner "${banner_title}" "Terraform init: succeeded" "success"
            else
                echo ""
                print_banner "${banner_title}" "Terraform init: failed" "error"
                exit 10
            fi
        fi

    else
        print_banner "${banner_title}" "New deployment" "info"
        terraform -chdir="${terraform_module_directory}" init -upgrade -backend-config "path=${param_dirname}/terraform.tfstate"
    fi
    echo "Parameters:                          ${allParameters[*]}"
    terraform -chdir="${terraform_module_directory}" refresh "${allParameters[@]}"
fi

install_deployer_return_value=$?

if [ 1 == $install_deployer_return_value ]; then
    print_banner "${banner_title}" "Error when running terraform init" "error"

    unset TF_DATA_DIR
    exit $install_deployer_return_value
fi

print_banner "${banner_title}" "Running Terraform plan" "info" "System name $(basename "$param_dirname")"

# shellcheck disable=SC2086

if terraform -chdir="$terraform_module_directory" plan -detailed-exitcode "${allParameters[@]}" | tee plan_output.log; then
    install_deployer_return_value=${PIPESTATUS[0]}
else
    install_deployer_return_value=${PIPESTATUS[0]}
fi

if [ 0 == "$install_deployer_return_value" ]; then
    print_banner "${banner_title}" "Terraform plan succeeded ($install_deployer_return_value), no changes to apply" "success"
    install_deployer_return_value=0
elif [ 2 == "$install_deployer_return_value" ]; then
    print_banner "${banner_title}" "Terraform plan succeeded ($install_deployer_return_value), changes to apply" "info"
    install_deployer_return_value=0
else
    print_banner "${banner_title}" "Terraform plan failed ($install_deployer_return_value)" "error"
    if [ -f plan_output.log ]; then
        cat plan_output.log
        rm plan_output.log
    fi
    unset TF_DATA_DIR
    exit "$install_deployer_return_value"
fi

if [ -f plan_output.log ]; then
    rm plan_output.log
fi

print_banner "${banner_title}" "Running Terraform apply" "info" "System name $(basename "$param_dirname")"
if [ "$PLATFORM" != "cli" ] || [ "$approve" == "--auto-approve" ]; then
    allParameters+=(-json)
    allParameters+=(-auto-approve)
    allParameters+=(-no-color)
    allParameters+=(-compact-warnings)
    applyOutputfile="apply_output.json"
else
    applyOutputfile="apply_output.log"
fi

parallelism=10

#Provide a way to limit the number of parallell tasks for Terraform
if [[ -n "${TF_PARALLELLISM}" ]]; then
    parallelism=$TF_PARALLELLISM
fi

if [ -f apply_output.json ]; then
    rm apply_output.json
fi

install_deployer_return_value=0

if terraform -chdir="${terraform_module_directory}" apply -parallelism="${parallelism}" "${allParameters[@]}" | tee "${applyOutputfile}"; then
    install_deployer_return_value=${PIPESTATUS[0]}
else
    install_deployer_return_value=${PIPESTATUS[0]}
fi

if [ "$install_deployer_return_value" -eq 1 ]; then
    print_banner "${banner_title}" "Error when running terraform apply" "error" "System name $(basename "$param_dirname")"
else
    # return code 2 is ok
    print_banner "${banner_title}" "Terraform apply succeeded ($install_deployer_return_value)" "info"
    # remove the plan file as it is not needed anymore
    if [ -f "$deployer_plan_name" ]; then
        echo "Removing the plan file: $deployer_plan_name"
        rm -f "$deployer_plan_name"
    fi
    # shellcheck disable=SC2086
    install_deployer_return_value=0
fi

if [ -f apply_output.json ]; then
    errors_occurred=$(jq 'select(."@level" == "error") | length' apply_output.json)

    if [[ -n $errors_occurred ]]; then
        install_deployer_return_value=10

        for i in {1..5}; do
            print_banner "Terraform apply" "Errors detected in apply output" "warning" "Attempt $i of 5 to import existing resources and re-run apply"
            if [ -f apply_output.json ]; then
                if ImportAndReRunApply "apply_output.json" "${terraform_module_directory}" "${allImportParameters[*]}" "${allParameters[*]}"; then
                    install_deployer_return_value=0
                else
                    install_deployer_return_value=$?
                fi
            else
                break
            fi
        done
    fi
fi

echo "Terraform Apply return code:         $install_deployer_return_value"

if [ 0 != "$install_deployer_return_value" ]; then
    print_banner "${banner_title}" "Error when Creating the deployer" "error"

    if [ -f "${deployer_plan_name}" ]; then
        echo "Removing the plan file: $deployer_plan_name"
        rm -f "$deployer_plan_name"
    fi

fi

if DEPLOYER_KEYVAULT=$(terraform -chdir="${terraform_module_directory}" output -no-color -raw deployer_kv_user_name | tr -d \"); then
    touch "${deployer_environment_file_name}"
    printf -v val %-.20s "$DEPLOYER_KEYVAULT"
    save_config_var "DEPLOYER_KEYVAULT" "${deployer_environment_file_name}"
    export DEPLOYER_KEYVAULT

    print_banner "$banner_title" "Deployer Keyvault: $val" "info"

else
    install_deployer_return_value=2
fi

DEPLOYER_USERNAME=$(terraform -chdir="${terraform_module_directory}" output -no-color -raw deployer_username | tr -d \")
if [ -n "${DEPLOYER_USERNAME}" ]; then
    save_config_var "DEPLOYER_USERNAME" "${deployer_environment_file_name}"
    export DEPLOYER_USERNAME
fi

DEPLOYER_SSHKEY_SECRET_NAME=$(terraform -chdir="${terraform_module_directory}" output -no-color -raw deployer_sshkey | tr -d \")
if [ -n "${DEPLOYER_SSHKEY_SECRET_NAME}" ]; then
    save_config_var "DEPLOYER_SSHKEY_SECRET_NAME" "${deployer_environment_file_name}"
    export DEPLOYER_SSHKEY_SECRET_NAME
    print_banner "$banner_title" "Deployer SSH Key Secret Name: $DEPLOYER_SSHKEY_SECRET_NAME" "info" "Deployer Username: ${DEPLOYER_USERNAME:-azureadm}"
fi

APPLICATION_CONFIGURATION_NAME=$(terraform -chdir="${terraform_module_directory}" output -no-color -raw application_configuration_name | tr -d \")
if [ -n "${APPLICATION_CONFIGURATION_NAME}" ]; then
    save_config_var "APPLICATION_CONFIGURATION_NAME" "${deployer_environment_file_name}"
    export APPLICATION_CONFIGURATION_NAME
    print_banner "$banner_title" "Application Configuration Name: $APPLICATION_CONFIGURATION_NAME" "info"
fi

APPLICATION_CONFIGURATION_DEPLOYMENT=$(terraform -chdir="${terraform_module_directory}" output -no-color -raw app_config_deployment | tr -d \")
if [ -n "${APPLICATION_CONFIGURATION_DEPLOYMENT}" ]; then
    save_config_var "APPLICATION_CONFIGURATION_DEPLOYMENT" "${deployer_environment_file_name}"
    export APPLICATION_CONFIGURATION_DEPLOYMENT
    echo "APPLICATION_CONFIGURATION_DEPLOYMENT:  $APPLICATION_CONFIGURATION_DEPLOYMENT"
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
    sed -i -e /"custom_random_id"/d "${parameterfile}"
    printf "\n# The parameter 'custom_random_id' can be used to control the random 3 digits at the end of the storage accounts and key vaults\ncustom_random_id = \"%s\"\n" "${custom_random_id}" >>"${var_file}"
fi

ARM_CLIENT_ID=$(terraform -chdir="${terraform_module_directory}" output -no-color -raw deployer_client_id | tr -d \")
if [ -n "${ARM_CLIENT_ID}" ]; then
    save_config_var "ARM_CLIENT_ID" "${deployer_environment_file_name}"
    export ARM_CLIENT_ID
fi

ARM_OBJECT_ID=$(terraform -chdir="${terraform_module_directory}" output -no-color -raw deployer_user_assigned_identity | tr -d \")
if [ -n "${ARM_OBJECT_ID}" ]; then
    save_config_var "ARM_OBJECT_ID" "${deployer_environment_file_name}"
    export ARM_OBJECT_ID
fi

DevOpsInfrastructureObjectId=$(terraform -chdir="${terraform_module_directory}" output -no-color -raw DevOpsInfrastructureObjectId | tr -d \")
if [ -n "${DevOpsInfrastructureObjectId}" ]; then
    save_config_var "DevOpsInfrastructureObjectId" "${deployer_environment_file_name}"
    export DevOpsInfrastructureObjectId
fi

unset TF_DATA_DIR
echo "Exiting: ${SCRIPT_NAME} ($install_deployer_return_value)"

exit "$install_deployer_return_value"
