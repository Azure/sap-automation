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

# External helper functions
#. "$(dirname "${BASH_SOURCE[0]}")/deploy_utils.sh"
full_script_path="$(realpath "${BASH_SOURCE[0]}")"
script_directory="$(dirname "${full_script_path}")"
parent_directory="$(dirname "$script_directory")"
grand_parent_directory="$(dirname "$parent_directory")"

#call stack has full script name when using source
# shellcheck disable=SC1091
source "${grand_parent_directory}/deploy_utils.sh"

#call stack has full script name when using source
source "${parent_directory}/helper.sh"

app_resource_id=$(az graph query -q "Resources | join kind=leftouter (ResourceContainers | where type=='microsoft.resources/subscriptions' | project subscription=name, subscriptionId) on subscriptionId | where name == '$APP_SERVICE_NAME' | project id, name, subscription" --query data[0].id --output tsv)
{
	printf "Configure the Web Application authentication using the following script.\n"
	printf "\n\n"

	printf "az ad app update --id %s --web-home-page-url https://%s.azurewebsites.net --web-redirect-uris https://%s.azurewebsites.net/ https://%s.azurewebsites.net/.auth/login/aad/callback\n\n" "$APP_REGISTRATION_APP_ID" "$APP_SERVICE_NAME" "$APP_SERVICE_NAME" "$APP_SERVICE_NAME"

	printf "\n" >>"$BUILDPATH/Web Application Configuration.md"

	printf "az rest --method POST --uri \"https://graph.microsoft.com/beta/applications/%s/federatedIdentityCredentials\" --body \"{'name': 'ManagedIdentityFederation', 'issuer': 'https://login.microsoftonline.com/%s/v2.0', 'subject': '%s', 'audiences': [ 'api://AzureADTokenExchange' ]}\"" "$APP_REGISTRATION_OBJECTID" "$ARM_TENANT_ID" "$ARM_OBJECT_ID"
	printf "\n" >>"$BUILDPATH/Web Application Configuration.md"

	printf "az webapp restart --ids %s\n\n" "$app_resource_id"
	printf "\n\n" >>"$BUILDPATH/Web Application Configuration.md"

	printf "[Access the Web App](https://%s.azurewebsites.net) \n\n" "$APP_SERVICE_NAME"
} >>"$BUILDPATH/Web Application Configuration.md"
echo "##vso[task.uploadsummary]$BUILDPATH/Web Application Configuration.md"
exit 0
