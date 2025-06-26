#!/bin/bash
# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

full_script_path="$(realpath "${BASH_SOURCE[0]}")"
script_directory="$(dirname "${full_script_path}")"
parent_directory="$(dirname "$script_directory")"

source "${parent_directory}/deploy_utils.sh"
source "${script_directory}/helper.sh"

if ! az extension list --query "[?contains(name, 'azure-devops')]" --output table; then
	az extension add --name azure-devops --output none --only-show-errors
fi

az devops configure --defaults organization=$SYSTEM_COLLECTIONURI project=$SYSTEM_TEAMPROJECTID
automation_config_directory=$CONFIG_REPO_PATH/.sap_deployment_automation/
deployer_environment_file_name="${automation_config_directory}/$CONTROL_PLANE_NAME"

if is_valid_id "$APPLICATION_CONFIGURATION_ID" "/providers/Microsoft.AppConfiguration/configurationStores/"; then
	application_configuration_name=$(echo "$APPLICATION_CONFIGURATION_ID" | cut -d '/' -f 9)

	app_service_id=$(getVariableFromApplicationConfiguration "$APPLICATION_CONFIGURATION_ID" "${CONTROL_PLANE_NAME}_AppServiceId" "${CONTROL_PLANE_NAME}")
	if [ -n "$app_service_id" ]; then
		app_service_name=$(echo $app_service_id | cut -d'/' -f9)
		print_banner "Web App Preparation" "Setting the output variables" "info"
		echo "##vso[task.setvariable variable=APPSERVICE_NAME;isOutput=true]$app_service_name"
		echo "##vso[task.setvariable variable=HAS_WEBAPP;isOutput=true]true"
		print_banner "App Service details" "App Service name: $app_service_name" "info" "Has the App service deployed"
	else
		echo "##vso[task.setvariable variable=HAS_WEBAPP;isOutput=true]false"
		echo "##vso[task.setvariable variable=APPSERVICE_NAME;isOutput=true]$app_service_name"
		print_banner "App Service details" "App Service name: $app_service_name" "info" "Does not have the App service deployed"
	fi
else
  APP_SERVICE_NAME=$(grep -m1 "^APP_SERVICE_NAME" "${deployer_environment_file_name}" | awk -F'=' '{print $2}' | xargs || true)
  HAS_WEBAPP=$(grep -m1 "^HAS_WEBAPP" "${deployer_environment_file_name}" | awk -F'=' '{print $2}' | xargs || true)
	echo "##vso[task.setvariable variable=HAS_WEBAPP;isOutput=true]$HAS_WEBAPP"
	echo "##vso[task.setvariable variable=APPSERVICE_NAME;isOutput=true]$APP_SERVICE_NAME"

fi

exit 0
