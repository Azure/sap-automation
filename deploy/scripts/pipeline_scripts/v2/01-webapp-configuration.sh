#!/bin/bash
# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.
set -o errexit

if [ "$SYSTEM_DEBUG" = True ]; then
	set -x
	DEBUG=True
	echo "Environment variables:"
	printenv | sort

fi
export DEBUG
set -euo pipefail

full_script_path="$(realpath "${BASH_SOURCE[0]}")"
script_directory="$(dirname "${full_script_path}")"
parent_directory="$(dirname "$script_directory")"

source "${parent_directory}/deploy_utils.sh"
source "${script_directory}/helper.sh"

ARM_TENANT_ID=$(az account show --query homeTenantId -o tsv)

app_service_id=$(getVariableFromApplicationConfiguration "$APPLICATION_CONFIGURATION_ID" "${CONTROL_PLANE_NAME}_AppServiceId" "${CONTROL_PLANE_NAME}")
app_service_identity_id=$(getVariableFromApplicationConfiguration "$APPLICATION_CONFIGURATION_ID" "${CONTROL_PLANE_NAME}_AppServiceIdentityId" "${CONTROL_PLANE_NAME}")
deployer_msi_id=$(getVariableFromApplicationConfiguration "$APPLICATION_CONFIGURATION_ID" "${CONTROL_PLANE_NAME}_Deployer_MSI_Id" "${CONTROL_PLANE_NAME}")
app_service_name=$(echo "$app_service_id" | cut -d '/' -f 9)
app_service_resource_group=$(echo "$app_service_id" | cut -d '/' -f 5)
app_service_subscription=$(echo "$app_service_id" | cut -d '/' -f 3)
tfstate_resource_id=$(getVariableFromApplicationConfiguration "$APPLICATION_CONFIGURATION_ID" "${CONTROL_PLANE_NAME}_TerraformRemoteStateStorageAccountId" "${CONTROL_PLANE_NAME}")
Terraform_Remote_Storage_Resource_Group_Name=$(echo "$tfstate_resource_id" | cut -d '/' -f 5)

printf "Configure the Web Application authentication using the following script.\n" >"$BUILD_REPOSITORY_LOCALPATH/Web Application Configuration.md"
printf "\n\n" >>"$BUILD_REPOSITORY_LOCALPATH/Web Application Configuration.md"

printf "az ad app update --id %s --web-home-page-url https://%s.azurewebsites.net --web-redirect-uris https://%s.azurewebsites.net/ https://%s.azurewebsites.net/.auth/login/aad/callback\n\n" "$APP_REGISTRATION_APP_ID" "$app_service_name" "$app_service_name" "$app_service_name" >>"$BUILD_REPOSITORY_LOCALPATH/Web Application Configuration.md"

printf "\n" >>"$BUILD_REPOSITORY_LOCALPATH/Web Application Configuration.md"
printf "az role assignment create --assignee %s --role reader --subscription %s --scope /subscriptions/%s\n" "$app_service_identity_id" "$ARM_SUBSCRIPTION_ID" "$ARM_SUBSCRIPTION_ID" >>"$BUILD_REPOSITORY_LOCALPATH/Web Application Configuration.md"
printf "Run the above command for all subscriptions you want to use in the Web Application\n" >>"$BUILD_REPOSITORY_LOCALPATH/Web Application Configuration.md"

printf "\n" >>"$BUILD_REPOSITORY_LOCALPATH/Web Application Configuration.md"
printf "az role assignment create --assignee %s --role 'Storage Blob Data Contributor' --subscription %s --scope /subscriptions/%s/resourceGroups/%s\n" "$app_service_identity_id" "$ARM_SUBSCRIPTION_ID" "$ARM_SUBSCRIPTION_ID" "$Terraform_Remote_Storage_Resource_Group_Name" >>"$BUILD_REPOSITORY_LOCALPATH/Web Application Configuration.md"
printf "az role assignment create --assignee %s --role 'Storage Table Data Contributor' --subscription %s --scope /subscriptions/%s/resourceGroups/%s \n\n" "$app_service_identity_id" "$ARM_SUBSCRIPTION_ID" "$ARM_SUBSCRIPTION_ID" "$Terraform_Remote_Storage_Resource_Group_Name" >>"$BUILD_REPOSITORY_LOCALPATH/Web Application Configuration.md"

printf "\n" >>"$BUILD_REPOSITORY_LOCALPATH/Web Application Configuration.md"

printf "az rest --method POST --uri \"https://graph.microsoft.com/beta/applications/%s/federatedIdentityCredentials\" --body \"{'name': 'ManagedIdentityFederation', 'issuer': 'https://login.microsoftonline.com/%s/v2.0', 'subject': '%s', 'audiences': [ 'api://AzureADTokenExchange' ]}\"" "$APP_REGISTRATION_OBJECT_ID" "$ARM_TENANT_ID" "$deployer_msi_id" >>"$BUILD_REPOSITORY_LOCALPATH/Web Application Configuration.md"
printf "\n" >>"$BUILD_REPOSITORY_LOCALPATH/Web Application Configuration.md"

printf "az webapp restart --name %s  --resource-group %s --subscription %s \n\n" "$app_service_name" "$app_service_resource_group" "$app_service_subscription">>"$BUILD_REPOSITORY_LOCALPATH/Web Application Configuration.md"
printf "\n\n" >>"$BUILD_REPOSITORY_LOCALPATH/Web Application Configuration.md"

printf "[Access the Web App](https://%s.azurewebsites.net) \n\n" $app_service_name >>"$BUILD_REPOSITORY_LOCALPATH/Web Application Configuration.md"

echo "##vso[task.uploadsummary]$BUILD_REPOSITORY_LOCALPATH/Web Application Configuration.md"
exit 0
