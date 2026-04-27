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



app_resource_id=$(az graph query -q "Resources | join kind=leftouter (ResourceContainers | where type=='microsoft.resources/subscriptions' | project subscription=name, subscriptionId) on subscriptionId | where name == '$APP_SERVICE_NAME' | project id, name, subscription" --query data[0].id --output tsv)
app_service_resource_group=$(echo "$app_resource_id" | cut -d '/' -f 5)
app_service_subscription=$(echo "$app_resource_id" | cut -d '/' -f 3)
{
printf "Configure the Web Application authentication using the following script.\n" >"$BUILD_REPOSITORY_LOCALPATH/Web Application Configuration.md"
printf "\n\n" >>"$BUILD_REPOSITORY_LOCALPATH/Web Application Configuration.md"
printf "**Configure authentication**\n" >>"$BUILD_REPOSITORY_LOCALPATH/Web Application Configuration.md"

printf "\n\n" >>"$BUILD_REPOSITORY_LOCALPATH/Web Application Configuration.md"

printf "az ad app update --id %s --web-home-page-url https://%s.azurewebsites.net --web-redirect-uris https://%s.azurewebsites.net/ https://%s.azurewebsites.net/.auth/login/aad/callback\n\n" "$APP_REGISTRATION_APP_ID" "$APP_SERVICE_NAME" "$APP_SERVICE_NAME" "$APP_SERVICE_NAME" >>"$BUILD_REPOSITORY_LOCALPATH/Web Application Configuration.md"

printf "\n" >>"$BUILD_REPOSITORY_LOCALPATH/Web Application Configuration.md"
printf "az role assignment create --assignee %s --role reader --subscription %s --scope /subscriptions/%s\n" "$APP_REGISTRATION_APP_ID" "$ARM_SUBSCRIPTION_ID" "$ARM_SUBSCRIPTION_ID" >>"$BUILD_REPOSITORY_LOCALPATH/Web Application Configuration.md"

printf "\n" >>"$BUILD_REPOSITORY_LOCALPATH/Web Application Configuration.md"
printf "\n" >>"$BUILD_REPOSITORY_LOCALPATH/Web Application Configuration.md"
printf "**Assign permissions**\n" >>"$BUILD_REPOSITORY_LOCALPATH/Web Application Configuration.md"

printf "\n" >>"$BUILD_REPOSITORY_LOCALPATH/Web Application Configuration.md"
printf "\n" >>"$BUILD_REPOSITORY_LOCALPATH/Web Application Configuration.md"
printf "az rest --method POST --uri \"https://graph.microsoft.com/beta/applications/%s/federatedIdentityCredentials\" --body \"{'name': 'ManagedIdentityFederation', 'issuer': 'https://login.microsoftonline.com/%s/v2.0', 'subject': '%s', 'audiences': [ 'api://AzureADTokenExchange' ]}\"" "$APP_REGISTRATION_OBJECTID" "$ARM_TENANT_ID" "$ARM_OBJECT_ID" >>"$BUILD_REPOSITORY_LOCALPATH/Web Application Configuration.md"
printf "\n" >>"$BUILD_REPOSITORY_LOCALPATH/Web Application Configuration.md"

printf "az webapp restart --name %s  --resource-group %s --subscription %s \n\n" "$APP_SERVICE_NAME" "$app_service_resource_group" "$app_service_subscription">>"$BUILD_REPOSITORY_LOCALPATH/Web Application Configuration.md"
printf "\n\n" >>"$BUILD_REPOSITORY_LOCALPATH/Web Application Configuration.md"

printf "[Access the Web App](https://%s.azurewebsites.net) \n\n" $APP_SERVICE_NAME >>"$BUILD_REPOSITORY_LOCALPATH/Web Application Configuration.md"
} >>"$BUILD_REPOSITORY_LOCALPATH/Web Application Configuration.md"
echo "##vso[task.uploadsummary]$BUILD_REPOSITORY_LOCALPATH/Web Application Configuration.md"


return_code=0
#----------------------------------- EXIT --------------------------------------#
echo -e "\n${cyan}Exiting script:  ${BASH_SOURCE[0]}${reset}"
echo -e   "${cyan}   Return code:  ${return_code}${reset}"
exit $return_code

