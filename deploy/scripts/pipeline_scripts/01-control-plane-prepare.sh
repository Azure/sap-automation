#!/bin/bash
# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

echo "##vso[build.updatebuildnumber]Deploying the control plane defined in $DEPLOYER_FOLDERNAME $LIBRARY_FOLDERNAME"
green="\e[1;32m"
reset="\e[0m"
bold_red="\e[1;31m"
cyan="\e[1;36m"

#External helper functions
#. "$(dirname "${BASH_SOURCE[0]}")/deploy_utils.sh"
full_script_path="$(realpath "${BASH_SOURCE[0]}")"
script_directory="$(dirname "${full_script_path}")"

#call stack has full scriptname when using source
source "${script_directory}/helper.sh"

DEBUG=false
if [ "$SYSTEM_DEBUG" = True ]; then
	set -x
	DEBUG=true
	echo "Environment variables:"
	printenv | sort
fi

export DEBUG
set -eu
file_deployer_tfstate_key=$DEPLOYER_FOLDERNAME.tfstate
deployer_tfstate_key="$DEPLOYER_FOLDERNAME.terraform.tfstate"

cd "$CONFIG_REPO_PATH" || exit
mkdir -p .sap_deployment_automation

ENVIRONMENT=$(echo "$DEPLOYER_FOLDERNAME" | awk -F'-' '{print $1}' | xargs)
LOCATION=$(echo "$DEPLOYER_FOLDERNAME" | awk -F'-' '{print $2}' | xargs)

deployer_environment_file_name="$CONFIG_REPO_PATH/.sap_deployment_automation/${ENVIRONMENT}${LOCATION}"
deployer_tfvars_file_name="${CONFIG_REPO_PATH}/DEPLOYER/$DEPLOYER_FOLDERNAME/$DEPLOYER_TFVARS_FILENAME"
library_tfvars_file_name="${CONFIG_REPO_PATH}/LIBRARY/$LIBRARY_FOLDERNAME/$LIBRARY_TFVARS_FILENAME"

echo "Configuration file:                  $deployer_environment_file_name"
echo "Environment:                         $ENVIRONMENT"
echo "Location:                            $LOCATION"

if [ "$FORCE_RESET" == "True" ]; then
	echo "##vso[task.logissue type=warning]Forcing a re-install"
	echo -e "$bold_red--- Resetting the environment file ---$reset"
	step=0
else
	if [ -f "${deployer_environment_file_name}" ]; then
		step=$(grep -m1 "^step=" "${deployer_environment_file_name}" | awk -F'=' '{print $2}' | xargs)
	else
		step=0
	fi
fi
echo "Step:                                $step"

if [ 0 != "${step}" ]; then
	echo "##vso[task.logissue type=warning]Already prepared"
	exit 0
fi

echo -e "$green--- Checkout $BUILD_SOURCEBRANCHNAME ---$reset"
git checkout -q "$BUILD_SOURCEBRANCHNAME"

echo -e "$green--- Configure devops CLI extension ---$reset"
az config set extension.use_dynamic_install=yes_without_prompt --only-show-errors
az extension add --name azure-devops --output none --only-show-errors
az devops configure --defaults organization="$SYSTEM_COLLECTIONURI" project="$SYSTEM_TEAMPROJECT" --output none --only-show-errors

echo -e "$green--- File Validations ---$reset"
if [ ! -f "$deployer_tfvars_file_name" ]; then
	echo -e "$bold_red--- File "$deployer_tfvars_file_name" was not found ---$reset"
	echo "##vso[task.logissue type=error]File DEPLOYER/$DEPLOYER_FOLDERNAME/$DEPLOYER_TFVARS_FILENAME was not found."
	exit 2
fi
if [ ! -f $library_tfvars_file_name ]; then
	echo -e "$bold_red--- File $library_tfvars_file_name  was not found ---$reset"
	echo "##vso[task.logissue type=error]File LIBRARY/$LIBRARY_FOLDERNAME/$LIBRARY_TFVARS_FILENAME was not found."
	exit 2
fi

echo ""
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

VARIABLE_GROUP_ID=$(az pipelines variable-group list --query "[?name=='$VARIABLE_GROUP'].id | [0]")
if [ -z "${VARIABLE_GROUP_ID}" ]; then
	echo "##vso[task.logissue type=error]Variable group $VARIABLE_GROUP could not be found."
	exit 2
fi
export VARIABLE_GROUP_ID

printf -v tempval '%s id:' "$VARIABLE_GROUP"
printf -v val '%-20s' "${tempval}"
echo "$val                 $VARIABLE_GROUP_ID"

az account set --subscription "$ARM_SUBSCRIPTION_ID"
echo "Deployer subscription:               $ARM_SUBSCRIPTION_ID"

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
	configureNonDeployer "$TF_VERSION"

	ARM_CLIENT_ID="$servicePrincipalId"
	export ARM_CLIENT_ID
	TF_VAR_spn_id=$ARM_CLIENT_ID
	export TF_VAR_spn_id

	ARM_OIDC_TOKEN="$idToken"
	if [ -n "$ARM_OIDC_TOKEN" ]; then
		export ARM_OIDC_TOKEN
		ARM_USE_OIDC=true
		export ARM_USE_OIDC
		unset ARM_CLIENT_SECRET
	else
		unset ARM_OIDC_TOKEN
		ARM_CLIENT_SECRET="$servicePrincipalKey"
		export ARM_CLIENT_SECRET
	fi

	ARM_TENANT_ID="$tenantId"
	export ARM_TENANT_ID

	ARM_USE_AZUREAD=true
	export ARM_USE_AZUREAD



else
	echo -e "$green--- az login ---$reset"
	LogonToAzure "$USE_MSI"
fi
return_code=$?
if [ 0 != $return_code ]; then
	echo -e "$bold_red--- Login failed ---$reset"
	echo "##vso[task.logissue type=error]az login failed."
	exit $return_code
fi

# Reset the account if sourcing was done
ARM_SUBSCRIPTION_ID=$CP_ARM_SUBSCRIPTION_ID
export ARM_SUBSCRIPTION_ID
az account set --subscription "$ARM_SUBSCRIPTION_ID"
echo "Deployer subscription:               $ARM_SUBSCRIPTION_ID"

echo -e "$green--- Convert config files to UX format ---$reset"
dos2unix -q "$deployer_tfvars_file_name"
dos2unix -q "$library_tfvars_file_name"

key_vault=$(getVariableFromVariableGroup "${VARIABLE_GROUP_ID}" "Deployer_Key_Vault" "${deployer_environment_file_name}" "keyvault")
if [ -n "$key_vault" ]; then
	echo "Deployer Key Vault:                  ${key_vault}"
	key_vault_id=$(az resource list --name "${key_vault}" --resource-type Microsoft.KeyVault/vaults --query "[].id | [0]" --subscription "$ARM_SUBSCRIPTION_ID" --output tsv)

	if [ -z "${key_vault_id}" ]; then
		echo "##vso[task.logissue type=error]Key Vault $key_vault could not be found, trying to recover"
		key_vault=$(az keyvault list-deleted --query "[?name=='${key_vault}'].name | [0]" --subscription "$ARM_SUBSCRIPTION_ID" --output tsv)
		if [ -n "$key_vault" ]; then
			echo "Deployer Key Vault:                  ${key_vault} is deleted, recovering"
			az keyvault recover --name "${key_vault}" --subscription "$ARM_SUBSCRIPTION_ID" --output none
			key_vault_id=$(az resource list --name "${key_vault}" --resource-type Microsoft.KeyVault/vaults --query "[].id | [0]" --subscription "$ARM_SUBSCRIPTION_ID" --output tsv)
			if [ -n "${key_vault_id}" ]; then
				export TF_VAR_deployer_kv_user_arm_id=${key_vault_id}
				this_ip=$(curl -s ipinfo.io/ip) >/dev/null 2>&1
				az keyvault network-rule add --name "${key_vault}" --ip-address "${this_ip}" --subscription "$ARM_SUBSCRIPTION_ID" --only-show-errors --output none
			fi
		fi
	else
		export TF_VAR_deployer_kv_user_arm_id=${key_vault_id}
		this_ip=$(curl -s ipinfo.io/ip) >/dev/null 2>&1
		az keyvault network-rule add --name "${key_vault}" --ip-address "${this_ip}" --subscription "$ARM_SUBSCRIPTION_ID" --only-show-errors --output none

	fi
else
	echo "Deployer Key Vault:                  undefined"
fi

if [ $FORCE_RESET == True ]; then
	echo "##vso[task.logissue type=warning]Forcing a re-install"
	echo "Running on:            $THIS_AGENT"
	sed -i 's/step=1/step=0/' "$deployer_environment_file_name"
	sed -i 's/step=2/step=0/' "$deployer_environment_file_name"
	sed -i 's/step=3/step=0/' "$deployer_environment_file_name"

	TERRAFORM_REMOTE_STORAGE_ACCOUNT_NAME=$(getVariableFromVariableGroup "${VARIABLE_GROUP_ID}" "TERRAFORM_REMOTE_STORAGE_ACCOUNT_NAME" "${deployer_environment_file_name}" "REMOTE_STATE_SA")
	TERRAFORM_REMOTE_STORAGE_RESOURCE_GROUP_NAME=$(getVariableFromVariableGroup "${VARIABLE_GROUP_ID}" "TERRAFORM_REMOTE_STORAGE_RESOURCE_GROUP_NAME" "${deployer_environment_file_name}" "REMOTE_STATE_RG")

	if [ -n "${TERRAFORM_REMOTE_STORAGE_ACCOUNT_NAME}" ]; then
		echo "Terraform Remote State Account:       ${TERRAFORM_REMOTE_STORAGE_ACCOUNT_NAME}"
	fi

	if [ -n "${TERRAFORM_REMOTE_STORAGE_RESOURCE_GROUP_NAME}" ]; then
		echo "Terraform Remote State RG Name:       ${TERRAFORM_REMOTE_STORAGE_RESOURCE_GROUP_NAME}"
	fi

	if [ -n "${TERRAFORM_REMOTE_STORAGE_ACCOUNT_NAME}" ] && [ -n "${TERRAFORM_REMOTE_STORAGE_RESOURCE_GROUP_NAME}" ]; then
		tfstate_resource_id=$(az resource list --name "$TERRAFORM_REMOTE_STORAGE_ACCOUNT_NAME" --subscription "$ARM_SUBSCRIPTION_ID" --resource-type Microsoft.Storage/storageAccounts --query "[].id | [0]" -o tsv)
		if [ -n "${tfstate_resource_id}" ]; then
			this_ip=$(curl -s ipinfo.io/ip) >/dev/null 2>&1
			az storage account network-rule add --account-name "$TERRAFORM_REMOTE_STORAGE_ACCOUNT_NAME" --resource-group "$TERRAFORM_REMOTE_STORAGE_RESOURCE_GROUP_NAME" --ip-address "${this_ip}" --only-show-errors --output none
		fi

		REINSTALL_ACCOUNTNAME=$TERRAFORM_REMOTE_STORAGE_ACCOUNT_NAME
		export REINSTALL_ACCOUNTNAME
		REINSTALL_SUBSCRIPTION=$ARM_SUBSCRIPTION_ID
		export REINSTALL_SUBSCRIPTION
		REINSTALL_RESOURCE_GROUP=$TERRAFORM_REMOTE_STORAGE_RESOURCE_GROUP_NAME
		export REINSTALL_RESOURCE_GROUP
	fi
fi

echo -e "$green--- Variables ---$reset"

if [ -z "${TF_VAR_ansible_core_version}" ]; then
	TF_VAR_ansible_core_version=2.16
	export TF_VAR_ansible_core_version
fi

if [ -f "${CONFIG_REPO_PATH}/DEPLOYER/$DEPLOYER_FOLDERNAME/state.zip" ]; then
	# shellcheck disable=SC2001
	# shellcheck disable=SC2005
	pass=${SYSTEM_COLLECTIONID//-/}
	echo "Unzipping state.zip"
	unzip -qq -o -P "${pass}" "${CONFIG_REPO_PATH}/DEPLOYER/$DEPLOYER_FOLDERNAME/state.zip" -d "${CONFIG_REPO_PATH}/DEPLOYER/$DEPLOYER_FOLDERNAME"
fi

export TF_LOG_PATH=$CONFIG_REPO_PATH/.sap_deployment_automation/terraform.log
set +eu

if [ "$USE_MSI" != "true" ]; then
	"$SAP_AUTOMATION_REPO_PATH/deploy/scripts/deploy_controlplane.sh" \
		--deployer_parameter_file "${CONFIG_REPO_PATH}/DEPLOYER/$DEPLOYER_FOLDERNAME/$DEPLOYER_TFVARS_FILENAME" \
		--library_parameter_file "${CONFIG_REPO_PATH}/LIBRARY/$LIBRARY_FOLDERNAME/$LIBRARY_TFVARS_FILENAME" \
		--subscription "$ARM_SUBSCRIPTION_ID" --spn_id "$ARM_CLIENT_ID" \
		--spn_secret "$ARM_CLIENT_SECRET" --tenant_id "$ARM_TENANT_ID" \
		--auto-approve --ado --only_deployer

else
	"$SAP_AUTOMATION_REPO_PATH/deploy/scripts/deploy_controlplane.sh" \
		--deployer_parameter_file "${CONFIG_REPO_PATH}/DEPLOYER/$DEPLOYER_FOLDERNAME/$DEPLOYER_TFVARS_FILENAME" \
		--library_parameter_file "${CONFIG_REPO_PATH}/LIBRARY/$LIBRARY_FOLDERNAME/$LIBRARY_TFVARS_FILENAME" \
		--subscription "$ARM_SUBSCRIPTION_ID" --auto-approve --ado --only_deployer --msi
fi
return_code=$?
echo ""
echo -e "${cyan}Deploy_controlplane returned:        $return_code${reset_formatting}"
echo ""

set -eu

if [ -f "${deployer_environment_file_name}" ]; then
	file_deployer_tfstate_key=$(grep -m1 "^deployer_tfstate_key" "${deployer_environment_file_name}" | awk -F'=' '{print $2}' | xargs || true)
	if [ -z "$file_deployer_tfstate_key" ]; then
		deployer_tfstate_key=$file_deployer_tfstate_key
		export deployer_tfstate_key
	fi
	echo "Deployer State File:                 $deployer_tfstate_key"

	file_key_vault=$(grep -m1 "^keyvault=" "${deployer_environment_file_name}" | awk -F'=' '{print $2}' | xargs || true)
	echo "Deployer Key Vault:                  ${file_key_vault}"

	file_REMOTE_STATE_SA=$(grep -m1 "^REMOTE_STATE_SA" "${deployer_environment_file_name}" | awk -F'=' '{print $2}' | xargs || true)
	if [ -n "${file_REMOTE_STATE_SA}" ]; then
		echo "Terraform Remote State Account:       ${file_REMOTE_STATE_SA}"
	fi

	file_REMOTE_STATE_RG=$(grep -m1 "^REMOTE_STATE_RG" "${deployer_environment_file_name}" | awk -F'=' '{print $2}' | xargs || true)
	if [ -n "${file_REMOTE_STATE_SA}" ]; then
		echo "Terraform Remote State RG Name:       ${file_REMOTE_STATE_RG}"
	fi
fi
echo -e "$green--- Adding deployment automation configuration to devops repository ---$reset"
added=0
cd "$CONFIG_REPO_PATH" || exit

# Pull changes
git pull -q origin "$BUILD_SOURCEBRANCHNAME"

echo -e "$green--- Update repo ---$reset"

if [ -f ".sap_deployment_automation/${ENVIRONMENT}${LOCATION}" ]; then
	git add ".sap_deployment_automation/${ENVIRONMENT}${LOCATION}"
	added=1
fi

if [ -f "DEPLOYER/$DEPLOYER_FOLDERNAME/deployer_tfvars_file_name" ]; then
	git add -f "DEPLOYER/$DEPLOYER_FOLDERNAME/deployer_tfvars_file_name"
	added=1
fi

if [ -f "DEPLOYER/$DEPLOYER_FOLDERNAME/.terraform/terraform.tfstate" ]; then
	git add -f "DEPLOYER/$DEPLOYER_FOLDERNAME/.terraform/terraform.tfstate"
	added=1
fi

if [ -f "DEPLOYER/$DEPLOYER_FOLDERNAME/terraform.tfstate" ]; then
	sudo apt-get install zip -y
	pass=${SYSTEM_COLLECTIONID//-/}
	zip -q -j -P "${pass}" "DEPLOYER/$DEPLOYER_FOLDERNAME/state" "DEPLOYER/$DEPLOYER_FOLDERNAME/terraform.tfstate"
	git add -f "DEPLOYER/$DEPLOYER_FOLDERNAME/state.zip"
	added=1
fi

if [ 1 = $added ]; then
	git config --global user.email "$BUILD_REQUESTEDFOREMAIL"
	git config --global user.name "$BUILD_REQUESTEDFOR"
	git commit -m "Added updates from Control Plane Deployment for $DEPLOYER_FOLDERNAME $LIBRARY_FOLDERNAME $BUILD_BUILDNUMBER [skip ci]"
	if ! git -c http.extraheader="AUTHORIZATION: bearer $SYSTEM_ACCESSTOKEN" push --set-upstream origin "$BUILD_SOURCEBRANCHNAME" --force-with-lease; then
		echo "##vso[task.logissue type=error]Failed to push changes to the repository."
	fi
fi

if [ -f "$CONFIG_REPO_PATH/.sap_deployment_automation/${ENVIRONMENT}${LOCATION}.md" ]; then
	echo "##vso[task.uploadsummary]$CONFIG_REPO_PATH/.sap_deployment_automation/${ENVIRONMENT}${LOCATION}.md"
fi
echo -e "$green--- Adding variables to the variable group: $VARIABLE_GROUP ---$reset"
if [ 0 = $return_code ]; then

	saveVariableInVariableGroup "${VARIABLE_GROUP_ID}" "Deployer_State_FileName" "$deployer_tfstate_key"
	saveVariableInVariableGroup "${VARIABLE_GROUP_ID}" "Deployer_Key_Vault" "$file_key_vault"
	saveVariableInVariableGroup "${VARIABLE_GROUP_ID}" "ControlPlaneEnvironment" "$ENVIRONMENT"
	saveVariableInVariableGroup "${VARIABLE_GROUP_ID}" "ControlPlaneLocation" "$LOCATION"

fi
exit $return_code
