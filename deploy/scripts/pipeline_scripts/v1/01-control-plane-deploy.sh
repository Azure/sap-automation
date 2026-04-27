#!/bin/bash
# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

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
# Cleanup DevOps Artifacts                                                      #
#                                                                               #
#-------------------------------------------------------------------------------#
# Environment variables that equal a pattern $(...) can cause issues when used in
# scripts, as they may be unintentionally executed. To prevent this, we can check
# for such patterns and handle them appropriately. In this case, we will check if
# any of the critical environment variables contain the pattern $(...) and log a
# warning if they do. This is a safety measure to avoid potential command
# injection or unintended behavior in the scripts.
#		
# Unset exported env vars whose VALUE contains a $(...) pattern
#---------------------------------------+---------------------------------------#
while IFS= read -r name; do
  echo -e "${cyan}No value provided ... unsetting environment variable: ${name}${reset}"
  unset "$name"
done < <(
  env | awk -F= '
		index($0,"="){
    	name=$1
    	val=substr($0, length(name)+2)

      # VALUE is exactly $(...) (single token, starts with $)
      if (val ~ /^\$\([^[:space:]]+\)$/) print name
  	}'
)
#-------------------------------------------------------------------------------#


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
# shellcheck disable=SC1091
source "${grand_parent_directory}/deploy_utils.sh"
source "${parent_directory}/helper.sh"
#-------------------------------------------------------------------------------#
# endregion


banner_title="Deploy Control Plane"

echo "##vso[build.updatebuildnumber]Deploying the Control Plane defined in $DEPLOYER_FOLDERNAME"
print_banner "$banner_title" "Starting $SCRIPT_NAME" "info"

# Print the execution environment details
print_header

# Configure DevOps
configure_devops

# Check if running on deployer
if [[ ! -f /etc/profile.d/deploy_server.sh ]]; then
    configureNonDeployer "${tf_version:-1.14.5}"
fi

echo -e "$green--- Validations ---$reset"
if [ "$USE_MSI" != "true" ]; then

    if ! printenv ARM_SUBSCRIPTION_ID; then
        echo "##vso[task.logissue type=error]Variable ARM_SUBSCRIPTION_ID was not defined in the $VARIABLE_GROUP variable group."
        print_banner "$banner_title" "Variable ARM_SUBSCRIPTION_ID was not defined in the $VARIABLE_GROUP variable group" "error"
        exit 2
    fi

    if ! printenv ARM_CLIENT_SECRET; then
        echo "##vso[task.logissue type=error]Variable ARM_CLIENT_SECRET was not defined in the $VARIABLE_GROUP variable group."
        print_banner "$banner_title" "Variable ARM_CLIENT_SECRET was not defined in the $VARIABLE_GROUP variable group" "error"
        exit 2
    fi

    if ! printenv ARM_CLIENT_ID; then
        echo "##vso[task.logissue type=error]Variable ARM_CLIENT_ID was not defined in the $VARIABLE_GROUP variable group."
        print_banner "$banner_title" "Variable ARM_CLIENT_ID was not defined in the $VARIABLE_GROUP variable group" "error"
        exit 2
    fi

    if ! printenv ARM_TENANT_ID; then
        echo "##vso[task.logissue type=error]Variable ARM_TENANT_ID was not defined in the $VARIABLE_GROUP variable group."
        print_banner "$banner_title" "Variable ARM_SUBSCRIPTION_ID was not defined in the $VARIABLE_GROUP variable group" "error"
        exit 2
    fi
fi

echo -e "$green--- az login ---$reset"
# Set logon variables
if [ "$USE_MSI" != "true" ]; then

    ARM_TENANT_ID=$(az account show --query tenantId --output tsv)
    export ARM_TENANT_ID
    ARM_SUBSCRIPTION_ID=$(az account show --query id --output tsv)
    export ARM_SUBSCRIPTION_ID
else
    unset ARM_CLIENT_SECRET
    ARM_USE_MSI=true
    export ARM_USE_MSI
fi

if [ -v MSI_ID ]; then
    echo "Using Managed Identity:              $MSI_ID"
    TF_VAR_user_assigned_identity_id="$MSI_ID"
    export TF_VAR_user_assigned_identity_id
fi

LogonToAzure $USE_MSI
return_code=$?
if [ 0 != $return_code ]; then
    echo -e "$bold_red--- Login failed ---$reset"
    echo "##vso[task.logissue type=error]az login failed."
    exit $return_code
fi

variableGroupName="$VARIABLE_GROUP_CONTROL_PLANE"

if ! get_variable_group_id "$variableGroupName" "VARIABLE_GROUP_ID"; then
    echo -e "$cyan--- Variable group $variableGroupName not found ---$reset"
    variableGroupName="$VARIABLE_GROUP"

    if ! get_variable_group_id "$variableGroupName" "VARIABLE_GROUP_ID"; then
        echo -e "$bold_red--- Variable group $variableGroupName not found ---$reset"
        echo "##vso[task.logissue type=error]Variable group $variableGroupName not found."
        exit 2
    fi
else
    VARIABLE_GROUP="${VARIABLE_GROUP_CONTROL_PLANE}"
    export VARIABLE_GROUP
fi

export VARIABLE_GROUP_ID

if [ -v SYSTEM_ACCESSTOKEN ]; then
    export TF_VAR_PAT="$SYSTEM_ACCESSTOKEN"
fi

TF_VAR_subscription_id=$ARM_SUBSCRIPTION_ID
export TF_VAR_subscription_id

az account set --subscription "$ARM_SUBSCRIPTION_ID"

ENVIRONMENT=$(echo "$DEPLOYER_FOLDERNAME" | awk -F'-' '{print $1}' | xargs)
export ENVIRONMENT
LOCATION=$(echo "$DEPLOYER_FOLDERNAME" | awk -F'-' '{print $2}' | xargs)
export LOCATION
NETWORK=$(echo "$DEPLOYER_FOLDERNAME" | awk -F'-' '{print $3}' | xargs)
export NETWORK

automation_config_directory="$CONFIG_REPO_PATH/.sap_deployment_automation/"

deployer_environment_file_name=$(get_configuration_file "$automation_config_directory" "$ENVIRONMENT" "$LOCATION" "$NETWORK")

SYSTEM_CONFIGURATION_FILE="$deployer_environment_file_name"
export SYSTEM_CONFIGURATION_FILE

deployer_configuration_file="${CONFIG_REPO_PATH}/DEPLOYER/$DEPLOYER_FOLDERNAME/$DEPLOYER_FOLDERNAME.tfvars"
library_configuration_file="${CONFIG_REPO_PATH}/LIBRARY/$LIBRARY_FOLDERNAME/$LIBRARY_FOLDERNAME.tfvars"
deployer_tfstate_key="$DEPLOYER_FOLDERNAME.terraform.tfstate"

if saveVariableInVariableGroup "${VARIABLE_GROUP_ID}" "DEPLOYER_STATE_FILENAME" "$deployer_tfstate_key"; then
    echo "Variable DEPLOYER_STATE_FILENAME was added to the $VARIABLE_GROUP variable group."
else
    echo "##vso[task.logissue type=error]Variable DEPLOYER_STATE_FILENAME was not added to the $VARIABLE_GROUP variable group."
    echo "Variable Deployer_State_FileName was not added to the $VARIABLE_GROUP variable group."
fi

if [ -f "${deployer_environment_file_name}" ]; then
    step=$(grep -m1 "^step=" "${deployer_environment_file_name}" | awk -F'=' '{print $2}' | xargs)
    echo "Step:                                $step"
fi

file_deployer_tfstate_key=$DEPLOYER_FOLDERNAME.tfstate
file_key_vault=""
file_REMOTE_STATE_SA=""
file_REMOTE_STATE_RG=$DEPLOYER_FOLDERNAME
REMOTE_STATE_SA=""
REMOTE_STATE_RG=$DEPLOYER_FOLDERNAME
sourced_from_file=0

if [[ -f /etc/profile.d/deploy_server.sh ]]; then
    path=$(grep -m 1 "export PATH=" /etc/profile.d/deploy_server.sh | awk -F'=' '{print $2}' | xargs)
    export PATH=$PATH:$path
fi

echo -e "$green--- File Validations ---$reset"

if [ ! -f "${deployer_configuration_file}" ]; then
    print_banner "$banner_title" "File ${deployer_configuration_file} was not found" "error"
    echo "##vso[task.logissue type=error]File ${deployer_configuration_file} was not found."
    exit 2
fi

if [ ! -f "${library_configuration_file}" ]; then
    print_banner "$banner_title" "File ${library_configuration_file} was not found" "error"
    echo "##vso[task.logissue type=error]File ${library_configuration_file} was not found."
    exit 2
fi

echo "Deployer subscription:               $ARM_SUBSCRIPTION_ID"

# echo -e "$green--- Convert config files to UX format ---$reset"
# dos2unix -q "${deployer_configuration_file}"
# dos2unix -q "${library_configuration_file}"

echo -e "$green--- Read Variables from Variable group ---$reset"
key_vault=$(getVariableFromVariableGroup "${VARIABLE_GROUP_ID}" "DEPLOYER_KEYVAULT" "${deployer_environment_file_name}" "keyvault")
if [ "$sourced_from_file" == 1 ]; then
    az pipelines variable-group variable create --group-id "${VARIABLE_GROUP_ID}" --name DEPLOYER_KEYVAULT --value "${key_vault}" --output none --only-show-errors
fi
echo "Deployer TFvars:                      $deployer_configuration_file"

if [ -n "${key_vault}" ]; then
    echo "Deployer Key Vault:                   ${key_vault}"
    keyvault_parameter=" --keyvault ${key_vault} "
else
    echo "Deployer Key Vault:                   undefined"
    exit 2

fi

TF_VAR_DevOpsInfrastructure_object_id=$(getVariableFromVariableGroup "${VARIABLE_GROUP_ID}" "DEVOPS_OBJECT_ID" "${deployer_environment_file_name}" "DevOpsInfrastructureObjectId")
if [ -n "${TF_VAR_DevOpsInfrastructure_object_id}" ]; then
    echo "DevOps Infrastructure Object ID:      ${TF_VAR_DevOpsInfrastructure_object_id}"
    export TF_VAR_DevOpsInfrastructure_object_id
fi

STATE_SUBSCRIPTION=$ARM_SUBSCRIPTION_ID

echo "Terraform state subscription:         $STATE_SUBSCRIPTION"

REMOTE_STATE_SA=$(getVariableFromVariableGroup "${VARIABLE_GROUP_ID}" "TERRAFORM_REMOTE_STORAGE_ACCOUNT_NAME" "${deployer_environment_file_name}" "REMOTE_STATE_SA")
export REMOTE_STATE_SA
if [ -n "${REMOTE_STATE_SA}" ]; then
    echo "Terraform storage account:            $REMOTE_STATE_SA"
    storage_account_parameter=" --storageaccountname ${REMOTE_STATE_SA} "
    tfstate_resource_id=$(az graph query -q "Resources | join kind=leftouter (ResourceContainers | where type=='microsoft.resources/subscriptions' | project subscription=name, subscriptionId) on subscriptionId | where name == '$REMOTE_STATE_SA' | project id, name, subscription" --query data[0].id --output tsv)
    REMOTE_STATE_RG=$(echo "$tfstate_resource_id" | cut -d '/' -f 5)
    export REMOTE_STATE_RG

else
    echo "Terraform storage account:            undefined"
    storage_account_parameter=
fi

echo -e "$green--- Validations ---$reset"

if [ -z "${TF_VAR_ansible_core_version}" ]; then
    export TF_VAR_ansible_core_version=2.16.18
fi

if [ "$USE_WEBAPP" = "true" ]; then
    echo "Deploy Web Application:               true"

    if [ -z "$APP_REGISTRATION_APP_ID" ]; then
        echo "##vso[task.logissue type=error]Variable APP_REGISTRATION_APP_ID was not defined."
        exit 2
    fi
    echo "App Registration ID:                  $APP_REGISTRATION_APP_ID"
    TF_VAR_app_registration_app_id=$APP_REGISTRATION_APP_ID
    export TF_VAR_app_registration_app_id

    if [ -z "$WEB_APP_CLIENT_SECRET" ]; then
        echo "##vso[task.logissue type=error]Variable WEB_APP_CLIENT_SECRET was not defined."
        exit 2
    fi

    TF_VAR_webapp_client_secret=$WEB_APP_CLIENT_SECRET
    export TF_VAR_webapp_client_secret

    TF_VAR_use_webapp=true
    export TF_VAR_use_webapp
else
    echo "Deploy Web Application:               false"
fi

file_REMOTE_STATE_SA=""
file_REMOTE_STATE_RG=""

echo -e "$green--- Update .sap_deployment_automation/config as SAP_AUTOMATION_REPO_PATH can change on devops agent ---$reset"
cd "${CONFIG_REPO_PATH}" || exit
mkdir -p .sap_deployment_automation
echo "SAP_AUTOMATION_REPO_PATH=$SAP_AUTOMATION_REPO_PATH" >.sap_deployment_automation/config
export SAP_AUTOMATION_REPO_PATH

ip_added=0

if [ -n "${key_vault}" ]; then

    key_vault_id=$(az resource list --name "${key_vault}" --resource-type Microsoft.KeyVault/vaults --query "[].id | [0]" -o tsv)
    if [ -n "${key_vault_id}" ]; then
        if [ "azure pipelines" = "$THIS_AGENT" ]; then
            this_ip=$(curl -s ipinfo.io/ip) >/dev/null 2>&1
            az keyvault network-rule add --name "${key_vault}" --ip-address "${this_ip}" --only-show-errors --output none
            ip_added=1
        fi
    fi
fi

echo -e "$green--- Preparing for the Control Plane deployment---$reset"

if [ -f "${CONFIG_REPO_PATH}/LIBRARY/$LIBRARY_FOLDERNAME/state.zip" ]; then
    # shellcheck disable=SC2001
    pass=${SYSTEM_COLLECTIONID//-/}

	echo "Unzipping the library state file to ${CONFIG_REPO_PATH}/LIBRARY/${LIBRARY_FOLDERNAME}"
    unzip -o -qq -P "${pass}" "${CONFIG_REPO_PATH}/LIBRARY/$LIBRARY_FOLDERNAME/state.zip" -d "${CONFIG_REPO_PATH}/LIBRARY/$LIBRARY_FOLDERNAME"
fi

if [ -f "${CONFIG_REPO_PATH}/DEPLOYER/$DEPLOYER_FOLDERNAME/state.zip" ]; then
    pass=${SYSTEM_COLLECTIONID//-/}

	echo "Unzipping the deployer state file to ${CONFIG_REPO_PATH}/DEPLOYER/${DEPLOYER_FOLDERNAME}"
    unzip -o -qq -P "${pass}" "${CONFIG_REPO_PATH}/DEPLOYER/$DEPLOYER_FOLDERNAME/state.zip" -d "${CONFIG_REPO_PATH}/DEPLOYER/$DEPLOYER_FOLDERNAME"
fi

export TF_LOG_PATH=${CONFIG_REPO_PATH}/.sap_deployment_automation/terraform.log
print_banner "$banner_title" "Starting the deployment" "info"

# 04/21/2026 - Remove this comment block on next release
# Removed because the script is executable in the repository and should keep its permissions.
# If there are issues with permissions, it should be fixed outside of this script as part of the repository management.
# sudo chmod +x "$SAP_AUTOMATION_REPO_PATH/deploy/scripts/deploy_controlplane.sh"

if [ "$USE_MSI" != "true" ]; then

    export TF_VAR_use_spn=true

    if "$SAP_AUTOMATION_REPO_PATH/deploy/scripts/deploy_controlplane.sh" \
    --deployer_parameter_file "${deployer_configuration_file}" \
    --library_parameter_file "${library_configuration_file}" \
    --subscription "$ARM_SUBSCRIPTION_ID" \
    --spn_secret "$ARM_CLIENT_SECRET" \
    --tenant_id "$ARM_TENANT_ID" \
    --auto-approve --ado \
    "${storage_account_parameter}" "${keyvault_parameter}"; then
        return_code=$?
        if [ -f "${CONFIG_REPO_PATH}/DEPLOYER/$DEPLOYER_FOLDERNAME/exports.sh" ]; then
            source "${CONFIG_REPO_PATH}/DEPLOYER/$DEPLOYER_FOLDERNAME/exports.sh"
        fi

        echo "##vso[task.logissue type=warning]Return code from deploy_controlplane $return_code."
        echo "Return code from deploy_controlplane $return_code."
    else
        return_code=$?
        echo "##vso[task.logissue type=warning]Return code from deploy_controlplane $return_code."
        echo "Return code from deploy_controlplane $return_code."
    fi
else
    export TF_VAR_use_spn=false

	if "${SAP_AUTOMATION_REPO_PATH}/deploy/scripts/deploy_controlplane.sh" \
		--deployer_parameter_file "${deployer_configuration_file}" \
		--library_parameter_file "${library_configuration_file}" \
		--subscription "$ARM_SUBSCRIPTION_ID" \
		--auto-approve --ado --msi \
		"${storage_account_parameter}" "${keyvault_parameter}"; then
		return_code=$?
		if [ -f  "${CONFIG_REPO_PATH}/DEPLOYER/$DEPLOYER_FOLDERNAME/export.sh" ]; then
			source "${CONFIG_REPO_PATH}/DEPLOYER/$DEPLOYER_FOLDERNAME/export.sh"
		fi
		echo "##vso[task.logissue type=warning]Return code from deploy_controlplane $return_code."
		echo "Return code from deploy_controlplane $return_code."
	else
		return_code=$?
		echo "##vso[task.logissue type=warning]Return code from deploy_controlplane $return_code."
		echo "Return code from deploy_controlplane $return_code."
	fi

fi

detect_platform

if [ -v SDAF_APPLICATION_CONFIGURATION_NAME	]; then
    saveVariableInVariableGroup "${VARIABLE_GROUP_ID}" "APPLICATION_CONFIGURATION_NAME" "$SDAF_APPLICATION_CONFIGURATION_NAME"
    saveVariableInVariableGroup "${VARIABLE_GROUP_ID}" "APPLICATION_CONFIGURATION_DEPLOYMENT" "true"
else
    saveVariableInVariableGroup "${VARIABLE_GROUP_ID}" "APPLICATION_CONFIGURATION_DEPLOYMENT" "false"
fi

if [ -v SDAF_APPSERVICE_NAME	]; then
    saveVariableInVariableGroup "${VARIABLE_GROUP_ID}" "APPSERVICE_NAME" "$SDAF_APPSERVICE_NAME"
    saveVariableInVariableGroup "${VARIABLE_GROUP_ID}" "APPSERVICE_DEPLOYMENT" "true"
else
    saveVariableInVariableGroup "${VARIABLE_GROUP_ID}" "APPSERVICE_DEPLOYMENT" "false"
fi

if [ -v SDAF_KEYVAULT_NAME	]; then
    saveVariableInVariableGroup "${VARIABLE_GROUP_ID}" "DEPLOYER_KEYVAULT" "$SDAF_KEYVAULT_NAME"
fi

if [ -v SDAF_TERRAFORM_STORAGE_ACCOUNT_NAME	]; then
    saveVariableInVariableGroup "${VARIABLE_GROUP_ID}" "TERRAFORM_REMOTE_STORAGE_ACCOUNT_NAME" "$SDAF_TERRAFORM_STORAGE_ACCOUNT_NAME"
fi

echo -e "$green--- Adding deployment automation configuration to devops repository ---$reset"
added=0
cd "${CONFIG_REPO_PATH}" || exit

# Pull changes
git pull -q origin "$BUILD_SOURCEBRANCHNAME"

echo -e "$green--- Update repo ---$reset"

if [ -f "${deployer_environment_file_name}" ]; then
    git add "${deployer_environment_file_name}"
    added=1
    if [ -f .sap_deployment_automation/"${ENVIRONMENT}${LOCATION}" ]; then
        rm -f .sap_deployment_automation/"${ENVIRONMENT}${LOCATION}"
        git rm --ignore-unmatch -q -f .sap_deployment_automation/"${ENVIRONMENT}${LOCATION}"

    fi
fi

if [ -f .sap_deployment_automation/"${ENVIRONMENT}${LOCATION}".md ]; then
    git add .sap_deployment_automation/"${ENVIRONMENT}${LOCATION}".md
    added=1
fi

if [ -f "${deployer_configuration_file}" ]; then
    git add -f "${deployer_configuration_file}"
    added=1
fi

if [ -f DEPLOYER/${DEPLOYER_FOLDERNAME}/readme.md ]; then
    git add -f "DEPLOYER/${DEPLOYER_FOLDERNAME}/readme.md"
    added=1
fi

if [ -f "DEPLOYER/$DEPLOYER_FOLDERNAME/.terraform/terraform.tfstate" ]; then
    git add -f "DEPLOYER/$DEPLOYER_FOLDERNAME/.terraform/terraform.tfstate"
    added=1

    # || true suppresses the exitcode of grep. To not trigger the strict exit on error
    local_backend=$(grep "\"type\": \"local\"" DEPLOYER/$DEPLOYER_FOLDERNAME/.terraform/terraform.tfstate || true)

    if [ -n "$local_backend" ]; then
        echo "Deployer Terraform state:              local"

        if [ -f "DEPLOYER/$DEPLOYER_FOLDERNAME/terraform.tfstate" ]; then
            echo "Compressing the deployer state file"
            sudo apt-get -qq install zip

            pass=${SYSTEM_COLLECTIONID//-/}
            zip -q -j -P "${pass}" "DEPLOYER/$DEPLOYER_FOLDERNAME/state" "DEPLOYER/$DEPLOYER_FOLDERNAME/terraform.tfstate"
            git add -f "DEPLOYER/$DEPLOYER_FOLDERNAME/state.zip"
            rm "DEPLOYER/$DEPLOYER_FOLDERNAME/terraform.tfstate"
            added=1
        fi
    else
        echo "Deployer Terraform state:              remote"
        if [ -f "DEPLOYER/$DEPLOYER_FOLDERNAME/terraform.tfstate" ]; then
            git rm -q --ignore-unmatch -f "DEPLOYER/$DEPLOYER_FOLDERNAME/terraform.tfstate"
            echo "Removed the deployer state file"
            added=1
        fi
        if [ -f "DEPLOYER/$DEPLOYER_FOLDERNAME/state.zip" ]; then
            if [ 0 == $return_code ]; then
                echo "Removing the deployer state zip file"
                git rm -q --ignore-unmatch -f "DEPLOYER/$DEPLOYER_FOLDERNAME/state.zip"

                added=1
            fi
        fi
    fi
fi

if [ -f "${library_configuration_file}" ]; then
    git add -f "${library_configuration_file}"
    added=1
fi

if [ -f "LIBRARY/$LIBRARY_FOLDERNAME/terraform.tfstate" ]; then
    sudo apt-get -qq install zip

    echo "Compressing the library state file"
    pass=${SYSTEM_COLLECTIONID//-/}
    zip -q -j -P "${pass}" "LIBRARY/$LIBRARY_FOLDERNAME/state" "LIBRARY/$LIBRARY_FOLDERNAME/terraform.tfstate"
    git add -f "LIBRARY/$LIBRARY_FOLDERNAME/state.zip"
    rm "LIBRARY/$LIBRARY_FOLDERNAME/terraform.tfstate"
    added=1
fi

if [ -f "LIBRARY/$LIBRARY_FOLDERNAME/.terraform/terraform.tfstate" ]; then
    git add -f "LIBRARY/$LIBRARY_FOLDERNAME/.terraform/terraform.tfstate"
    added=1
    # || true suppresses the exitcode of grep. To not trigger the strict exit on error
    local_backend=$(grep "\"type\": \"local\"" LIBRARY/$LIBRARY_FOLDERNAME/.terraform/terraform.tfstate || true)
    if [ -n "$local_backend" ]; then
        echo "Library Terraform state:               local"
    else
        echo "Library Terraform state:               remote"
        if [ -f "LIBRARY/$LIBRARY_FOLDERNAME/terraform.tfstate" ]; then
            if [ "$return_code" -eq 0 ]; then
                echo "Removing the library state file"
                git rm -q -f --ignore-unmatch "LIBRARY/$LIBRARY_FOLDERNAME/terraform.tfstate"
                added=1
            fi
        fi
        if [ -f "LIBRARY/$LIBRARY_FOLDERNAME/state.zip" ]; then
            echo "Removing the library state zip file"
            git rm -q --ignore-unmatch -f "LIBRARY/$LIBRARY_FOLDERNAME/state.zip"
            added=1
        fi
    fi
fi

if [ 1 = $added ]; then
    git config --global user.email "$BUILD_REQUESTEDFOREMAIL"
    git config --global user.name "$BUILD_REQUESTEDFOR"
    if [ $DEBUG = True ]; then
        git status --verbose
        if git commit --message --verbose "Added updates from Control Plane Deployment for $DEPLOYER_FOLDERNAME $LIBRARY_FOLDERNAME $BUILD_BUILDNUMBER [skip ci]"; then
            if git -c http.extraheader="AUTHORIZATION: bearer $SYSTEM_ACCESSTOKEN" push --set-upstream origin "$BUILD_SOURCEBRANCHNAME" --force-with-lease; then
                echo "Failed to push changes to the repository."
            fi
        fi

    else
        if git commit -m "Added updates from Control Plane Deployment for $DEPLOYER_FOLDERNAME $LIBRARY_FOLDERNAME $BUILD_BUILDNUMBER [skip ci]"; then
            if git -c http.extraheader="AUTHORIZATION: bearer $SYSTEM_ACCESSTOKEN" push --set-upstream origin "$BUILD_SOURCEBRANCHNAME" --force-with-lease; then
                echo "Failed to push changes to the repository."
            fi
        fi
    fi
fi


if [ -f "${deployer_environment_file_name}" ]; then

    DevOpsInfrastructureObjectId=$(grep -m1 "^DevOpsInfrastructureObjectId" "${deployer_environment_file_name}" | awk -F'=' '{print $2}' | xargs || true)
    if [ -n "$DevOpsInfrastructureObjectId" ]; then
        export DevOpsInfrastructureObjectId
        echo "DevOpsInfrastructureObjectId:      ${DevOpsInfrastructureObjectId}"
        saveVariableInVariableGroup "${VARIABLE_GROUP_ID}" "DEVOPS_OBJECT_ID" "$DevOpsInfrastructureObjectId"
    fi

    file_deployer_tfstate_key=$(grep "^deployer_tfstate_key=" "${deployer_environment_file_name}" | awk -F'=' '{print $2}' | xargs || true)
    echo "Deployer State:       ${file_deployer_tfstate_key}"

    file_key_vault=$(grep "^keyvault=" "${deployer_environment_file_name}" | awk -F'=' '{print $2}' | xargs || true)
    echo "Deployer Keyvault:    ${file_key_vault}"

    file_REMOTE_STATE_SA=$(grep "^REMOTE_STATE_SA=" "${deployer_environment_file_name}" | awk -F'=' '{print $2}' | xargs || true)
    if [ -n "${file_REMOTE_STATE_SA}" ]; then
        echo "Terraform account:    ${file_REMOTE_STATE_SA}"
    fi

    file_REMOTE_STATE_RG=$(grep "^REMOTE_STATE_RG=" "${deployer_environment_file_name}" | awk -F'=' '{print $2}' | xargs || true)
    if [ -n "${file_REMOTE_STATE_RG}" ]; then
        echo "Terraform rg name:    ${file_REMOTE_STATE_RG}"
    fi

    webapp_id=$(grep "^webapp_id=" "${deployer_environment_file_name}" | awk -F'=' '{print $2}' | xargs || true)
    if [ -n "${webapp_id}" ]; then
        echo "Webapp ID:            ${webapp_id}"
    fi

fi

echo -e "$green--- Adding variables to the variable group: $VARIABLE_GROUP ---$reset"
if [ -n "${file_REMOTE_STATE_SA}" ]; then
    tfstate_resource_id=$(az graph query -q "Resources | join kind=leftouter (ResourceContainers | where type=='microsoft.resources/subscriptions' | project subscription=name, subscriptionId) on subscriptionId | where name == '$file_REMOTE_STATE_SA' | project id, name, subscription" --query data[0].id --output tsv)
    control_plane_subscription=$(echo "$tfstate_resource_id" | cut -d '/' -f 3)
    if [ -n "$control_plane_subscription" ]; then
        if saveVariableInVariableGroup "${VARIABLE_GROUP_ID}" "TERRAFORM_REMOTE_STORAGE_SUBSCRIPTION" "$control_plane_subscription"; then
            echo "Variable TERRAFORM_REMOTE_STORAGE_SUBSCRIPTION was added to the $VARIABLE_GROUP variable group."
        else
            echo "##vso[task.logissue type=error]Variable TERRAFORM_REMOTE_STORAGE_SUBSCRIPTION was not added to the $VARIABLE_GROUP variable group."
            echo "Variable TERRAFORM_REMOTE_STORAGE_SUBSCRIPTION was not added to the $VARIABLE_GROUP variable group."
        fi
    fi

fi

if saveVariableInVariableGroup "${VARIABLE_GROUP_ID}" "CONTROL_PLANE_ENVIRONMENT" "$ENVIRONMENT"; then
    echo "Variable CONTROL_PLANE_ENVIRONMENT was added to the $VARIABLE_GROUP variable group."
else
    echo "##vso[task.logissue type=error]Variable CONTROL_PLANE_ENVIRONMENT was not added to the $VARIABLE_GROUP variable group."
    echo "Variable CONTROL_PLANE_ENVIRONMENT was not added to the $VARIABLE_GROUP variable group."
fi

if saveVariableInVariableGroup "${VARIABLE_GROUP_ID}" "CONTROL_PLANE_LOCATION" "$LOCATION"; then
    echo "Variable CONTROL_PLANE_LOCATION was added to the $VARIABLE_GROUP variable group."
else
    echo "##vso[task.logissue type=error]Variable CONTROL_PLANE_LOCATION was not added to the $VARIABLE_GROUP variable group."
    echo "Variable CONTROL_PLANE_LOCATION was not added to the $VARIABLE_GROUP variable group."
fi

if saveVariableInVariableGroup "${VARIABLE_GROUP_ID}" "WEBAPP_ID" "$webapp_id"; then
    echo "Variable WEBAPP_ID was added to the $VARIABLE_GROUP variable group."
else
    echo "##vso[task.logissue type=error]Variable WEBAPP_ID was not added to the $VARIABLE_GROUP variable group."
    echo "Variable WEBAPP_ID was not added to the $VARIABLE_GROUP variable group."
fi


#----------------------------------- EXIT --------------------------------------#
echo -e "\n${cyan}Exiting script:  ${BASH_SOURCE[0]}${reset}"
echo -e   "${cyan}   Return code:  ${return_code}${reset}"
exit $return_code
