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


banner_title="Set Workload Zone Secrets"

echo "##vso[build.updatebuildnumber]Setting the deployment credentials for the SAP Workload zone defined in $ZONE"

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
LogonToAzure $USE_MSI
return_code=$?
if [ 0 != $return_code ]; then
	echo -e "$bold_red--- Login failed ---$reset"
	echo "##vso[task.logissue type=error]az login failed."
	exit $return_code
fi

if ! get_variable_group_id "$VARIABLE_GROUP" "VARIABLE_GROUP_ID"; then
	if [ -v VARIABLE_GROUP_CONTROL_PLANE ]; then
		if ! get_variable_group_id "$VARIABLE_GROUP_CONTROL_PLANE" "VARIABLE_GROUP_ID"; then
			echo -e "$bold_red--- Variable group $VARIABLE_GROUP not found ---$reset"
			echo "##vso[task.logissue type=error]Variable group $VARIABLE_GROUP not found."
			exit 2
		fi
		export VARIABLE_GROUP_ID
	else
		echo -e "$bold_red--- Variable group $VARIABLE_GROUP not found ---$reset"
		echo "##vso[task.logissue type=error]Variable group $VARIABLE_GROUP not found."
		exit 2
	fi
fi
if [ -v PARENT_VARIABLE_GROUP ]; then
	if get_variable_group_id "$PARENT_VARIABLE_GROUP" "PARENT_VARIABLE_GROUP_ID"; then
		DEPLOYER_KEYVAULT=$(az pipelines variable-group variable list --group-id "${PARENT_VARIABLE_GROUP_ID}" --query "DEPLOYER_KEYVAULT.value" --output tsv)

		WZ_DEPLOYER_KEYVAULT=$(az pipelines variable-group variable list --group-id "${VARIABLE_GROUP_ID}" --query "DEPLOYER_KEYVAULT.value" --output tsv)
		if [ -z "$WZ_DEPLOYER_KEYVAULT" ]; then
			az pipelines variable-group variable create --group-id "${VARIABLE_GROUP_ID}" --name "DEPLOYER_KEYVAULT" --value "$DEPLOYER_KEYVAULT" --output none
		else
			az pipelines variable-group variable update --group-id "${VARIABLE_GROUP_ID}" --name "DEPLOYER_KEYVAULT" --value "$DEPLOYER_KEYVAULT" --output none
		fi

		APPLICATION_CONFIGURATION_NAME=$(az pipelines variable-group variable list --group-id "${PARENT_VARIABLE_GROUP_ID}" --query "APPLICATION_CONFIGURATION_NAME.value" --output tsv)

		WZ_APPLICATION_CONFIGURATION_NAME=$(az pipelines variable-group variable list --group-id "${VARIABLE_GROUP_ID}" --query "APPLICATION_CONFIGURATION_NAME.value" --output tsv)
		if [ -n "$APPLICATION_CONFIGURATION_NAME" ]; then
			echo "Application Configuration Name:      $APPLICATION_CONFIGURATION_NAME"
			if [ -z "$WZ_APPLICATION_CONFIGURATION_NAME" ]; then

				az pipelines variable-group variable create --group-id "${VARIABLE_GROUP_ID}" --name "APPLICATION_CONFIGURATION_NAME" --value "$APPLICATION_CONFIGURATION_NAME" --output none
			else
				az pipelines variable-group variable update --group-id "${VARIABLE_GROUP_ID}" --name "APPLICATION_CONFIGURATION_NAME" --value "$APPLICATION_CONFIGURATION_NAME" --output none
			fi
		fi

		if [ "$USE_MSI" = "true" ]; then
			ARM_CLIENT_ID=$(az pipelines variable-group variable list --group-id "${PARENT_VARIABLE_GROUP_ID}" --query "ARM_CLIENT_ID.value" --output tsv)
			WZ_ARM_CLIENT_ID=$(az pipelines variable-group variable list --group-id "${VARIABLE_GROUP_ID}" --query "ARM_CLIENT_ID.value" --output tsv)
			if [ -z "$WZ_ARM_CLIENT_ID" ]; then
				az pipelines variable-group variable create --group-id "${VARIABLE_GROUP_ID}" --name "ARM_CLIENT_ID" --value "$ARM_CLIENT_ID" --output none
			else
				az pipelines variable-group variable update --group-id "${VARIABLE_GROUP_ID}" --name "ARM_CLIENT_ID" --value "$ARM_CLIENT_ID" --output none
			fi
			ARM_OBJECT_ID=$(az pipelines variable-group variable list --group-id "${PARENT_VARIABLE_GROUP_ID}" --query "ARM_OBJECT_ID.value" --output tsv)
			WZ_ARM_OBJECT_ID=$(az pipelines variable-group variable list --group-id "${VARIABLE_GROUP_ID}" --query "ARM_OBJECT_ID.value" --output tsv)
			if [ -z "$WZ_ARM_OBJECT_ID" ]; then
				az pipelines variable-group variable create --group-id "${VARIABLE_GROUP_ID}" --name "ARM_OBJECT_ID" --value "$ARM_OBJECT_ID" --output none
			else
				az pipelines variable-group variable update --group-id "${VARIABLE_GROUP_ID}" --name "ARM_OBJECT_ID" --value "$ARM_OBJECT_ID" --output none
			fi
		fi

		export PARENT_VARIABLE_GROUP_ID
	else
		echo -e "$bold_red--- Variable group $PARENT_VARIABLE_GROUP not found ---$reset"
		echo "##vso[task.logissue type=error]Variable group $PARENT_VARIABLE_GROUP not found."
		exit 2
	fi
fi

cd "${CONFIG_REPO_PATH}" || exit
git checkout -q "$BUILD_SOURCEBRANCHNAME"

echo ""
echo -e "$green--- Read parameter values ---$reset"

keyvault_subscription_id=$(az graph query -q                                        \
                              "Resources                                            \
															| join kind=leftouter                                 \
																	(ResourceContainers                               \
																  | where type=='microsoft.resources/subscriptions' \
																  | project subscription=name, subscriptionId       \
																  ) on subscriptionId                               \
															| where name == '$DEPLOYER_KEYVAULT'                  \
															| project id, name, subscription,subscriptionId"      \
															--query data[0].subscriptionId                        \
															--output tsv)

if [ "$USE_MSI" != "true" ]; then

	if "$SAP_AUTOMATION_REPO_PATH/deploy/scripts/set_secrets_v2.sh" --prefix "${ZONE}" --key_vault "${DEPLOYER_KEYVAULT}" --keyvault_subscription "$keyvault_subscription_id" \
		--subscription "$ARM_SUBSCRIPTION_ID" --client_id "$ARM_CLIENT_ID" --client_secret "$ARM_CLIENT_SECRET" --client_tenant_id "$ARM_TENANT_ID" --ado; then
		return_code=$?
	else
		return_code=$?
		print_banner "$banner_title - Set secrets" "Set_secrets failed" "error"
		exit $return_code
	fi
else
	if "$SAP_AUTOMATION_REPO_PATH/deploy/scripts/set_secrets_v2.sh" --prefix "${ZONE}" --key_vault "${DEPLOYER_KEYVAULT}" --keyvault_subscription "$keyvault_subscription_id" \
		--subscription "$ARM_SUBSCRIPTION_ID" --msi --ado; then
		return_code=$?
	else
		return_code=$?
		print_banner "$banner_title - Set secrets" "Set_secrets failed" "error"
		exit $return_code
	fi

fi
print_banner "$banner_title" "Exiting $SCRIPT_NAME" "info"


#----------------------------------- EXIT --------------------------------------#
echo -e "\n${cyan}Exiting script:  ${BASH_SOURCE[0]}${reset}"
echo -e   "${cyan}   Return code:  ${return_code}${reset}"
exit $return_code
