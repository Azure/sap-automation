#!/bin/bash
# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

green="\e[1;32m"
reset="\e[0m"
bold_red="\e[1;31m"

# External helper functions
#. "$(dirname "${BASH_SOURCE[0]}")/deploy_utils.sh"
full_script_path="$(realpath "${BASH_SOURCE[0]}")"
script_directory="$(dirname "${full_script_path}")"
parent_directory="$(dirname "$script_directory")"
grand_parent_directory="$(dirname "$parent_directory")"

SCRIPT_NAME="$(basename "$0")"
banner_title="Deploy Control Plane"

#call stack has full script name when using source
# shellcheck disable=SC1091
source "${grand_parent_directory}/deploy_utils.sh"

#call stack has full script name when using source
source "${parent_directory}/helper.sh"

echo "##vso[build.updatebuildnumber]Deploying the Control Plane defined in $DEPLOYER_FOLDERNAME"
print_banner "$banner_title" "Starting $SCRIPT_NAME" "info"

DEBUG=False

if [ "$SYSTEM_DEBUG" = True ]; then
	set -x
	DEBUG=True
	echo "Environment variables:"
	printenv | sort

fi
export DEBUG
set -eu

# Print the execution environment details
print_header

# Configure DevOps
configure_devops

# Check if running on deployer
if [[ ! -f /etc/profile.d/deploy_server.sh ]]; then
	configureNonDeployer "${tf_version:-1.13.3}"
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
	export TF_VAR_ansible_core_version=2.16.5
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

	echo "Unzipping the library state file"
	unzip -o -qq -P "${pass}" "${CONFIG_REPO_PATH}/LIBRARY/$LIBRARY_FOLDERNAME/state.zip" -d "${CONFIG_REPO_PATH}/LIBRARY/$LIBRARY_FOLDERNAME"
fi

if [ -f "${CONFIG_REPO_PATH}/DEPLOYER/$DEPLOYER_FOLDERNAME/state.zip" ]; then
	pass=${SYSTEM_COLLECTIONID//-/}

	echo "Unzipping the deployer state file"
	unzip -o -qq -P "${pass}" "${CONFIG_REPO_PATH}/DEPLOYER/$DEPLOYER_FOLDERNAME/state.zip" -d "${CONFIG_REPO_PATH}/DEPLOYER/$DEPLOYER_FOLDERNAME"
fi

export TF_LOG_PATH=${CONFIG_REPO_PATH}/.sap_deployment_automation/terraform.log
print_banner "$banner_title" "Starting the deployment" "info"
sudo chmod +x "$SAP_AUTOMATION_REPO_PATH/deploy/scripts/deploy_controlplane.sh"
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
		echo "##vso[task.logissue type=warning]Return code from deploy_controlplane $return_code."
		echo "Return code from deploy_controlplane $return_code."
	else
		return_code=$?
		echo "##vso[task.logissue type=warning]Return code from deploy_controlplane $return_code."
		echo "Return code from deploy_controlplane $return_code."
	fi

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

if [ -f "LIBRARY/$LIBRARY_FOLDERNAME/.terraform/terraform.tfstate" ]; then
	git add -f "LIBRARY/$LIBRARY_FOLDERNAME/.terraform/terraform.tfstate"
	added=1
	# || true suppresses the exitcode of grep. To not trigger the strict exit on error
	local_backend=$(grep "\"type\": \"local\"" LIBRARY/$LIBRARY_FOLDERNAME/.terraform/terraform.tfstate || true)
	if [ -n "$local_backend" ]; then
		echo "Library Terraform state:               local"
		if [ -f "LIBRARY/$LIBRARY_FOLDERNAME/terraform.tfstate" ]; then
			sudo apt-get -qq install zip

			echo "Compressing the library state file"
			pass=${SYSTEM_COLLECTIONID//-/}
			zip -q -j -P "${pass}" "LIBRARY/$LIBRARY_FOLDERNAME/state" "LIBRARY/$LIBRARY_FOLDERNAME/terraform.tfstate"
			git add -f "LIBRARY/$LIBRARY_FOLDERNAME/state.zip"
			rm "LIBRARY/$LIBRARY_FOLDERNAME/terraform.tfstate"
			added=1
		fi
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

# if [ -f ".sap_deployment_automation/${ENVIRONMENT}${LOCATION}.md" ]; then
#   echo "##vso[task.uploadsummary].sap_deployment_automation/${ENVIRONMENT}${LOCATION}.md"
# fi

if [ -f "${deployer_environment_file_name}" ]; then

	APPLICATION_CONFIGURATION_NAME=$(grep -m1 "^APPLICATION_CONFIGURATION_NAME" "${deployer_environment_file_name}" | awk -F'=' '{print $2}' | xargs || true)
	if [ -n "${APPLICATION_CONFIGURATION_NAME}" ]; then
		export APPLICATION_CONFIGURATION_NAME
		echo "APPLICATION_CONFIGURATION_NAME:      ${APPLICATION_CONFIGURATION_NAME}"
		saveVariableInVariableGroup "${VARIABLE_GROUP_ID}" "APPLICATION_CONFIGURATION_NAME" "$APPLICATION_CONFIGURATION_NAME"
	fi

	DevOpsInfrastructureObjectId=$(grep -m1 "^DevOpsInfrastructureObjectId" "${deployer_environment_file_name}" | awk -F'=' '{print $2}' | xargs || true)
	if [ -n "$DevOpsInfrastructureObjectId" ]; then
		export DevOpsInfrastructureObjectId
		echo "DevOpsInfrastructureObjectId:      ${DevOpsInfrastructureObjectId}"
		saveVariableInVariableGroup "${VARIABLE_GROUP_ID}" "DEVOPS_OBJECT_ID" "$DevOpsInfrastructureObjectId"
	fi

	APPLICATION_CONFIGURATION_DEPLOYMENT=$(grep -m1 "^APPLICATION_CONFIGURATION_DEPLOYMENT" "${deployer_environment_file_name}" | awk -F'=' '{print $2}' | xargs || true)
	if [ -n "${APPLICATION_CONFIGURATION_DEPLOYMENT}" ]; then
		export APPLICATION_CONFIGURATION_DEPLOYMENT
		echo "APPLICATION_CONFIGURATION_DEPLOYMENT:  ${APPLICATION_CONFIGURATION_DEPLOYMENT}"
		saveVariableInVariableGroup "${VARIABLE_GROUP_ID}" "APPLICATION_CONFIGURATION_DEPLOYMENT" "$APPLICATION_CONFIGURATION_DEPLOYMENT"
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

	APP_SERVICE_NAME=$(grep "^APP_SERVICE_NAME=" "${deployer_environment_file_name}" | awk -F'=' '{print $2}' | xargs || true)
	if [ -n "${APP_SERVICE_NAME}" ]; then
		if saveVariableInVariableGroup "${VARIABLE_GROUP_ID}" "APP_SERVICE_NAME" "$APP_SERVICE_NAME"; then
			echo "Variable APP_SERVICE_NAME was added to the $VARIABLE_GROUP variable group."
		else
			echo "##vso[task.logissue type=error]Variable APP_SERVICE_NAME was not added to the $VARIABLE_GROUP variable group."
			echo "Variable APP_SERVICE_NAME was not added to the $VARIABLE_GROUP variable group."
		fi

		echo "Webapp URL Base:      ${APP_SERVICE_NAME}"

		if saveVariableInVariableGroup "${VARIABLE_GROUP_ID}" "APP_SERVICE_DEPLOYMENT" "true"; then
			echo "Variable APP_SERVICE_DEPLOYMENT was added to the $VARIABLE_GROUP variable group."
		else
			echo "##vso[task.logissue type=error]Variable APP_SERVICE_DEPLOYMENT was not added to the $VARIABLE_GROUP variable group."
			echo "Variable APP_SERVICE_DEPLOYMENT was not added to the $VARIABLE_GROUP variable group."
		fi
	else
		if saveVariableInVariableGroup "${VARIABLE_GROUP_ID}" "APP_SERVICE_DEPLOYMENT" "false"; then
			echo "Variable APP_SERVICE_DEPLOYMENT was added to the $VARIABLE_GROUP variable group."
		else
			echo "##vso[task.logissue type=error]Variable APP_SERVICE_DEPLOYMENT was not added to the $VARIABLE_GROUP variable group."
			echo "Variable APP_SERVICE_DEPLOYMENT was not added to the $VARIABLE_GROUP variable group."
		fi
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

	if saveVariableInVariableGroup "${VARIABLE_GROUP_ID}" "TERRAFORM_REMOTE_STORAGE_ACCOUNT_NAME" "${file_REMOTE_STATE_SA}"; then
		echo "Variable TERRAFORM_REMOTE_STORAGE_ACCOUNT_NAME was added to the $VARIABLE_GROUP variable group."
	else
		echo "##vso[task.logissue type=error]Variable TERRAFORM_REMOTE_STORAGE_ACCOUNT_NAME was not added to the $VARIABLE_GROUP variable group."
		echo "Variable TERRAFORM_REMOTE_STORAGE_ACCOUNT_NAME was not added to the $VARIABLE_GROUP variable group."
	fi
fi

if saveVariableInVariableGroup "${VARIABLE_GROUP_ID}" "DEPLOYER_KEYVAULT" "$file_key_vault"; then
	echo "Variable DEPLOYER_KEYVAULT was added to the $VARIABLE_GROUP variable group."
else
	echo "##vso[task.logissue type=error]Variable DEPLOYER_KEYVAULT was not added to the $VARIABLE_GROUP variable group."
	echo "Variable DEPLOYER_KEYVAULT was not added to the $VARIABLE_GROUP variable group."
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

if saveVariableInVariableGroup "${VARIABLE_GROUP_ID}" "APP_SERVICE_NAME" "$APP_SERVICE_NAME"; then
	echo "Variable APP_SERVICE_NAME was added to the $VARIABLE_GROUP variable group."
else
	echo "##vso[task.logissue type=error]Variable APP_SERVICE_NAME was not added to the $VARIABLE_GROUP variable group."
	echo "Variable WEBAPP_URL_BASE was not added to the $VARIABLE_GROUP variable group."
fi

if saveVariableInVariableGroup "${VARIABLE_GROUP_ID}" "WEBAPP_ID" "$webapp_id"; then
	echo "Variable WEBAPP_ID was added to the $VARIABLE_GROUP variable group."
else
	echo "##vso[task.logissue type=error]Variable WEBAPP_ID was not added to the $VARIABLE_GROUP variable group."
	echo "Variable WEBAPP_ID was not added to the $VARIABLE_GROUP variable group."
fi
exit $return_code
