#!/bin/bash
# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

echo "##vso[build.updatebuildnumber]Deploying the control plane defined in $DEPLOYER_FOLDERNAME $LIBRARY_FOLDERNAME"
green="\e[1;32m"
reset="\e[0m"
bold_red="\e[1;31m"
cyan="\e[1;36m"

# External helper functions
#. "$(dirname "${BASH_SOURCE[0]}")/deploy_utils.sh"
full_script_path="$(realpath "${BASH_SOURCE[0]}")"
script_directory="$(dirname "${full_script_path}")"

#call stack has full scriptname when using source
source "${script_directory}/helper.sh"

DEBUG=False

if [ "$SYSTEM_DEBUG" = True ]; then
	set -x
	DEBUG=True
	echo "Environment variables:"
	printenv | sort

fi
export DEBUG
set -eu

ENVIRONMENT=$(echo "$DEPLOYER_FOLDERNAME" | awk -F'-' '{print $1}' | xargs)
LOCATION=$(echo "$DEPLOYER_FOLDERNAME" | awk -F'-' '{print $2}' | xargs)

deployer_environment_file_name="${CONFIG_REPO_PATH}/.sap_deployment_automation/${ENVIRONMENT}$LOCATION"
deployer_configuration_file="${CONFIG_REPO_PATH}/DEPLOYER/$DEPLOYER_FOLDERNAME/$DEPLOYER_TFVARS_FILENAME"
library_configuration_file="${CONFIG_REPO_PATH}/LIBRARY/$LIBRARY_FOLDERNAME/$LIBRARY_TFVARS_FILENAME"
deployer_tfstate_key="$DEPLOYER_FOLDERNAME.terraform.tfstate"
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

if [ ! -f "${CONFIG_REPO_PATH}/DEPLOYER/$DEPLOYER_FOLDERNAME/$DEPLOYER_TFVARS_FILENAME" ]; then
	echo -e "$bold_red--- File ${CONFIG_REPO_PATH}/DEPLOYER/$DEPLOYER_FOLDERNAME/$DEPLOYER_TFVARS_FILENAME was not found ---$reset"
	echo "##vso[task.logissue type=error]File ${CONFIG_REPO_PATH}/${CONFIG_REPO_PATH}/DEPLOYER/$DEPLOYER_FOLDERNAME/$DEPLOYER_TFVARS_FILENAME was not found."
	exit 2
fi

if [ ! -f "${CONFIG_REPO_PATH}/LIBRARY/$LIBRARY_FOLDERNAME/$LIBRARY_TFVARS_FILENAME" ]; then
	echo -e "$bold_red--- File ${CONFIG_REPO_PATH}/LIBRARY/$LIBRARY_FOLDERNAME/$LIBRARY_TFVARS_FILENAME  was not found ---$reset"
	echo "##vso[task.logissue type=error]File ${CONFIG_REPO_PATH}/LIBRARY/$LIBRARY_FOLDERNAME/$LIBRARY_TFVARS_FILENAME was not found."
	exit 2
fi

echo -e "$green--- Information ---$reset"
echo "Environment:                         ${ENVIRONMENT}"
echo "Location:                            ${LOCATION}"
echo "Agent:                               $THIS_AGENT"
echo "Organization:                        $SYSTEM_COLLECTIONURI"
echo "Project:                             $SYSTEM_TEAMPROJECT"
if [ -n "$TF_VAR_agent_pat" ]; then
	echo "Deployer Agent PAT:                  IsDefined"
fi
if [ -n "$POOL" ]; then
	echo "Deployer Agent Pool:                 $POOL"
fi
echo ""
if [ "$USE_WEBAPP" = "true" ]; then
	echo "Deploy Web App:                      true"
else
	echo "Deploy Web App:                      false"
fi

TF_VAR_use_webapp=$USE_WEBAPP
export TF_VAR_use_webapp

echo ""
echo "Deployer Folder:                     $DEPLOYER_FOLDERNAME"
echo "Deployer TFvars:                     $DEPLOYER_TFVARS_FILENAME"
echo "Library Folder:                      $LIBRARY_FOLDERNAME"
echo "Library TFvars:                      $LIBRARY_TFVARS_FILENAME"

echo ""
echo "Azure CLI version:"
echo "-------------------------------------------------"
az --version
echo ""
echo "Terraform version:"
echo "-------------------------------------------------"
if [ -f /opt/terraform/bin/terraform ]; then
	tfPath="/opt/terraform/bin/terraform"
else
	tfPath=$(which terraform)
fi

"${tfPath}" --version

cd "$CONFIG_REPO_PATH" || exit

echo -e "$green--- Checkout $BUILD_SOURCEBRANCHNAME ---$reset"
git checkout -q "$BUILD_SOURCEBRANCHNAME"

echo -e "$green--- Configure devops CLI extension ---$reset"
az config set extension.use_dynamic_install=yes_without_prompt --only-show-errors
az extension add --name azure-devops --output none --only-show-errors

az devops configure --defaults organization="$SYSTEM_COLLECTIONURI" project='$SYSTEM_TEAMPROJECT'

VARIABLE_GROUP_ID=$(az pipelines variable-group list --query "[?name=='$VARIABLE_GROUP'].id | [0]")
export VARIABLE_GROUP_ID
if [ -z "${VARIABLE_GROUP_ID}" ]; then
	echo "##vso[task.logissue type=error]Variable group $VARIABLE_GROUP could not be found."
	exit 2
fi

printf -v tempval '%s id:' "$VARIABLE_GROUP"
printf -v val '%-20s' "${tempval}"
echo "$val                 $VARIABLE_GROUP_ID"

# Set logon variables
ARM_CLIENT_ID="$CP_ARM_CLIENT_ID"
export ARM_CLIENT_ID
ARM_CLIENT_SECRET="$CP_ARM_CLIENT_SECRET"
export ARM_CLIENT_SECRET
ARM_TENANT_ID=$CP_ARM_TENANT_ID
export ARM_TENANT_ID
ARM_SUBSCRIPTION_ID=$CP_ARM_SUBSCRIPTION_ID
export ARM_SUBSCRIPTION_ID

# Check if running on deployer
if [[ ! -f /etc/profile.d/deploy_server.sh ]]; then
	configureNonDeployer "$(tf_version)"
	echo -e "$green--- az login ---$reset"
	LogonToAzure false
else
	LogonToAzure "$USE_MSI"
fi
return_code=$?
if [ 0 != $return_code ]; then
	echo -e "$bold_red--- Login failed ---$reset"
	echo "##vso[task.logissue type=error]az login failed."
	exit $return_code
fi
ARM_SUBSCRIPTION_ID=$CP_ARM_SUBSCRIPTION_ID
export ARM_SUBSCRIPTION_ID
TF_VAR_subscription_id=$ARM_SUBSCRIPTION_ID
export TF_VAR_subscription_id

az account set --subscription "$ARM_SUBSCRIPTION_ID"
echo "Deployer subscription:               $ARM_SUBSCRIPTION_ID"

echo -e "$green--- Configuring variables ---$reset"

echo -e "$green--- Convert config files to UX format ---$reset"
dos2unix -q "${CONFIG_REPO_PATH}/DEPLOYER/$DEPLOYER_FOLDERNAME/$DEPLOYER_TFVARS_FILENAME"
dos2unix -q "${CONFIG_REPO_PATH}/LIBRARY/$LIBRARY_FOLDERNAME/$LIBRARY_TFVARS_FILENAME"

echo -e "$green--- Variables ---$reset"
key_vault=$(getVariableFromVariableGroup "${VARIABLE_GROUP_ID}" "Deployer_Key_Vault" "${deployer_environment_file_name}" "keyvault")
if [ "$sourced_from_file" == 1 ]; then
	az pipelines variable-group variable create --group-id "${VARIABLE_GROUP_ID}" --name Deployer_Key_Vault --value "${key_vault}" --output none --only-show-errors
fi
echo "Deployer TFvars:                      $DEPLOYER_TFVARS_FILENAME"

if [ -n "${key_vault}" ]; then
	echo "Deployer Key Vault:                   ${key_vault}"
	keyvault_parameter=" --keyvault ${key_vault} "
else
	echo "Deployer Key Vault:                   undefined"
	exit 2

fi

STATE_SUBSCRIPTION=$ARM_SUBSCRIPTION_ID

echo "Terraform state subscription:         $STATE_SUBSCRIPTION"

REMOTE_STATE_SA=$(getVariableFromVariableGroup "${VARIABLE_GROUP_ID}" "Terraform_Remote_Storage_Account_Name" "${deployer_environment_file_name}" "REMOTE_STATE_SA")
export REMOTE_STATE_SA
if [ -n "${REMOTE_STATE_SA}" ]; then
	echo "Terraform storage account:            $REMOTE_STATE_SA"
	storage_account_parameter=" --storageaccountname ${REMOTE_STATE_SA} "
else
	echo "Terraform storage account:            undefined"
	storage_account_parameter=
fi

REMOTE_STATE_RG=$(getVariableFromVariableGroup "${VARIABLE_GROUP_ID}" "Terraform_Remote_Storage_Resource_Group_Name" "${deployer_environment_file_name}" "REMOTE_STATE_RG")
export REMOTE_STATE_RG

echo -e "$green--- Validations ---$reset"

if [ -z "${TF_VAR_ansible_core_version}" ]; then
	export TF_VAR_ansible_core_version=2.16
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
	fi

fi

echo -e "$green--- Adding deployment automation configuration to devops repository ---$reset"
added=0
cd "${CONFIG_REPO_PATH}" || exit

# Pull changes
git pull -q origin "$BUILD_SOURCEBRANCHNAME"

echo -e "$green--- Update repo ---$reset"
if [ -f .sap_deployment_automation/"${ENVIRONMENT}${LOCATION}" ]; then
	git add .sap_deployment_automation/"${ENVIRONMENT}${LOCATION}"
	added=1
fi

if [ -f .sap_deployment_automation/"${ENVIRONMENT}${LOCATION}".md ]; then
	git add .sap_deployment_automation/"${ENVIRONMENT}${LOCATION}".md
	added=1
fi

if [ -f "${CONFIG_REPO_PATH}/DEPLOYER/$DEPLOYER_FOLDERNAME/$DEPLOYER_TFVARS_FILENAME" ]; then
	git add -f "${CONFIG_REPO_PATH}/DEPLOYER/$DEPLOYER_FOLDERNAME/$DEPLOYER_TFVARS_FILENAME"
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

if [ -f "${CONFIG_REPO_PATH}/LIBRARY/$LIBRARY_FOLDERNAME/$LIBRARY_TFVARS_FILENAME" ]; then
	git add -f "${CONFIG_REPO_PATH}/LIBRARY/$LIBRARY_FOLDERNAME/$LIBRARY_TFVARS_FILENAME"
	added=1
fi

if [ -f "${CONFIG_REPO_PATH}/LIBRARY/$LIBRARY_FOLDERNAME/$LIBRARY_TFVARS_FILENAME" ]; then
	git add -f "${CONFIG_REPO_PATH}/LIBRARY/$LIBRARY_FOLDERNAME/$LIBRARY_TFVARS_FILENAME"
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
			if [ 0 == $return_code ]; then
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
		echo "Terraform rgname:     ${file_REMOTE_STATE_RG}"
	fi
fi

echo -e "$green--- Adding variables to the variable group: $VARIABLE_GROUP ---$reset"
if [ 0 = $return_code ]; then
	if [ -n "${file_REMOTE_STATE_SA}" ]; then
		if saveVariableInVariableGroup "${VARIABLE_GROUP_ID}" "Terraform_Remote_Storage_Account_Name" "${file_REMOTE_STATE_SA}"; then
			echo "Variable Terraform_Remote_Storage_Account_Name was added to the $VARIABLE_GROUP variable group."
		else
			echo "##vso[task.logissue type=error]Variable Terraform_Remote_Storage_Account_Name was not added to the $VARIABLE_GROUP variable group."
			echo "Variable Terraform_Remote_Storage_Account_Name was not added to the $VARIABLE_GROUP variable group."
		fi
	fi

	if [ -n "${file_REMOTE_STATE_RG}" ]; then
		if saveVariableInVariableGroup "${VARIABLE_GROUP_ID}" "Terraform_Remote_Storage_Resource_Group_Name" "${file_REMOTE_STATE_RG}"; then
			echo "Variable Terraform_Remote_Storage_Resource_Group_Name was added to the $VARIABLE_GROUP variable group."
		else
			echo "##vso[task.logissue type=error]Variable Terraform_Remote_Storage_Resource_Group_Name was not added to the $VARIABLE_GROUP variable group."
			echo "Variable Terraform_Remote_Storage_Resource_Group_Name was not added to the $VARIABLE_GROUP variable group."
		fi
	fi

	if saveVariableInVariableGroup "${VARIABLE_GROUP_ID}" "Terraform_Remote_Storage_Subscription" "$ARM_SUBSCRIPTION_ID"; then
		echo "Variable Terraform_Remote_Storage_Subscription was added to the $VARIABLE_GROUP variable group."
	else
		echo "##vso[task.logissue type=error]Variable Terraform_Remote_Storage_Subscription was not added to the $VARIABLE_GROUP variable group."
		echo "Variable Terraform_Remote_Storage_Subscription was not added to the $VARIABLE_GROUP variable group."
	fi

	if saveVariableInVariableGroup "${VARIABLE_GROUP_ID}" "Deployer_State_FileName" "$deployer_tfstate_key"; then
		echo "Variable Deployer_State_FileName was added to the $VARIABLE_GROUP variable group."
	else
		echo "##vso[task.logissue type=error]Variable Deployer_State_FileName was not added to the $VARIABLE_GROUP variable group."
		echo "Variable Deployer_State_FileName was not added to the $VARIABLE_GROUP variable group."
	fi

	if saveVariableInVariableGroup "${VARIABLE_GROUP_ID}" "Deployer_Key_Vault" "$file_key_vault"; then
		echo "Variable Deployer_Key_Vault was added to the $VARIABLE_GROUP variable group."
	else
		echo "##vso[task.logissue type=error]Variable Deployer_Key_Vault was not added to the $VARIABLE_GROUP variable group."
		echo "Variable Deployer_Key_Vault was not added to the $VARIABLE_GROUP variable group."
	fi

	if saveVariableInVariableGroup "${VARIABLE_GROUP_ID}" "ControlPlaneEnvironment" "$ENVIRONMENT"; then
		echo "Variable ControlPlaneEnvironment was added to the $VARIABLE_GROUP variable group."
	else
		echo "##vso[task.logissue type=error]Variable ControlPlaneEnvironment was not added to the $VARIABLE_GROUP variable group."
		echo "Variable ControlPlaneEnvironment was not added to the $VARIABLE_GROUP variable group."
	fi

	if saveVariableInVariableGroup "${VARIABLE_GROUP_ID}" "ControlPlaneLocation" "$LOCATION"; then
		echo "Variable ControlPlaneLocation was added to the $VARIABLE_GROUP variable group."
	else
		echo "##vso[task.logissue type=error]Variable ControlPlaneLocation was not added to the $VARIABLE_GROUP variable group."
		echo "Variable ControlPlaneLocation was not added to the $VARIABLE_GROUP variable group."
	fi

fi
exit $return_code
