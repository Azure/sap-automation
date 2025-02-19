#!/bin/bash
# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

green="\e[1;32m"
reset="\e[0m"
bold_red="\e[1;31m"
cyan="\e[1;36m"

#External helper functions
source "sap-automation/deploy/pipelines/helper.sh"

DEBUG=False

if [ "$SYSTEM_DEBUG" = True ]; then
  set -x
  set -o errexit
  DEBUG=True
	echo "Environment variables:"
	printenv | sort


fi
export DEBUG

set -eu

echo "##vso[build.updatebuildnumber]Deploying the SAP Workload zone defined in $WORKLOAD_ZONE_FOLDERNAME"

tfvarsFile="LANDSCAPE/$WORKLOAD_ZONE_FOLDERNAME/$WORKLOAD_ZONE_TFVARS_FILENAME"

if [ ! -f "$CONFIG_REPO_PATH/LANDSCAPE/$WORKLOAD_ZONE_FOLDERNAME/$WORKLOAD_ZONE_TFVARS_FILENAME" ]; then
	echo -e "$bold_red--- $WORKLOAD_ZONE_TFVARS_FILENAME was not found ---$reset"
	echo "##vso[task.logissue type=error]File $WORKLOAD_ZONE_TFVARS_FILENAME was not found."
	exit 2
fi

echo -e "$green--- Checkout $BUILD_SOURCEBRANCHNAME ---$reset"

cd "${CONFIG_REPO_PATH}" || exit
mkdir -p .sap_deployment_automation
git checkout -q "$BUILD_SOURCEBRANCHNAME"

echo -e "$green--- Validations ---$reset"
if [ "$USE_MSI" != "true" ]; then

	if [ -z "$WL_ARM_SUBSCRIPTION_ID" ]; then
		echo "##vso[task.logissue type=error]Variable ARM_SUBSCRIPTION_ID was not defined in the $VARIABLE_GROUP variable group."
		exit 2
	fi

	if [ "$WL_ARM_SUBSCRIPTION_ID" == '$$(ARM_SUBSCRIPTION_ID)' ]; then
		echo "##vso[task.logissue type=error]Variable ARM_SUBSCRIPTION_ID was not defined in the $VARIABLE_GROUP variable group."
		exit 2
	fi

	if [ -z "$WL_ARM_CLIENT_ID" ]; then
		echo "##vso[task.logissue type=error]Variable ARM_CLIENT_ID was not defined in the $VARIABLE_GROUP variable group."
		exit 2
	fi

	if [ "$WL_ARM_CLIENT_ID" == '$$(ARM_CLIENT_ID)' ]; then
		echo "##vso[task.logissue type=error]Variable ARM_CLIENT_ID was not defined in the $VARIABLE_GROUP variable group."
		exit 2
	fi

	if [ -z "$WL_ARM_CLIENT_SECRET" ]; then
		echo "##vso[task.logissue type=error]Variable ARM_CLIENT_SECRET was not defined in the $VARIABLE_GROUP variable group."
		exit 2
	fi

	if [ "$WL_ARM_CLIENT_SECRET" == '$$(ARM_CLIENT_SECRET)' ]; then
		echo "##vso[task.logissue type=error]Variable ARM_CLIENT_SECRET was not defined in the $VARIABLE_GROUP variable group."
		exit 2
	fi

	if [ -z "$WL_ARM_TENANT_ID" ]; then
		echo "##vso[task.logissue type=error]Variable ARM_TENANT_ID was not defined in the $VARIABLE_GROUP variable group."
		exit 2
	fi

	if [ "$WL_ARM_TENANT_ID" == '$$(ARM_TENANT_ID)' ]; then
		echo "##vso[task.logissue type=error]Variable ARM_TENANT_ID was not defined in the $VARIABLE_GROUP variable group."
		exit 2
	fi

	if [ -z "$CP_ARM_SUBSCRIPTION_ID" ]; then
		echo "##vso[task.logissue type=error]Variable CP_ARM_SUBSCRIPTION_ID was not defined in the $PARENT_VARIABLE_GROUP variable group."
		exit 2
	fi

	if [ -z "$CP_ARM_CLIENT_ID" ]; then
		echo "##vso[task.logissue type=error]Variable CP_ARM_CLIENT_ID was not defined in the $PARENT_VARIABLE_GROUP variable group."
		exit 2
	fi

	if [ -z "$CP_ARM_CLIENT_SECRET" ]; then
		echo "##vso[task.logissue type=error]Variable CP_ARM_CLIENT_SECRET was not defined in the $PARENT_VARIABLE_GROUP variable group."
		exit 2
	fi

	if [ -z "$CP_ARM_TENANT_ID" ]; then
		echo "##vso[task.logissue type=error]Variable CP_ARM_TENANT_ID was not defined in the $PARENT_VARIABLE_GROUP variable group."
		exit 2
	fi
fi

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
az account set --subscription $ARM_SUBSCRIPTION_ID

echo -e "$green--- Read deployment details ---$reset"
dos2unix -q tfvarsFile

ENVIRONMENT=$(grep -m1 "^environment" "$tfvarsFile" | awk -F'=' '{print $2}' | tr -d ' \t\n\r\f"')
LOCATION=$(grep -m1 "^location" "$tfvarsFile" | awk -F'=' '{print $2}' | tr 'A-Z' 'a-z' | tr -d ' \t\n\r\f"')
NETWORK=$(grep -m1 "^network_logical_name" "$tfvarsFile" | awk -F'=' '{print $2}' | tr -d ' \t\n\r\f"')

ENVIRONMENT_IN_FILENAME=$(echo "$WORKLOAD_ZONE_FOLDERNAME" | awk -F'-' '{print $1}')

LOCATION_CODE_IN_FILENAME=$(echo "$WORKLOAD_ZONE_FOLDERNAME" | awk -F'-' '{print $2}')
LOCATION_IN_FILENAME=$(get_region_from_code "$LOCATION_CODE_IN_FILENAME")

NETWORK_IN_FILENAME=$(echo "$WORKLOAD_ZONE_FOLDERNAME" | awk -F'-' '{print $3}')

echo "Environment:                         $ENVIRONMENT"
echo "Location:                            $LOCATION"
echo "Network:                             $NETWORK"

echo "Environment(filename):               $ENVIRONMENT_IN_FILENAME"
echo "Location(filename):                  $LOCATION_IN_FILENAME"
echo "Network(filename):                   $NETWORK_IN_FILENAME"

echo "Deployer Environment                 $DEPLOYER_ENVIRONMENT"
echo "Deployer Region                      $DEPLOYER_REGION"
echo "Workload TFvars                      $WORKLOAD_ZONE_TFVARS_FILENAME"
echo ""

echo "Agent pool:                          $THIS_AGENT"
echo "Organization:                        $SYSTEM_COLLECTIONURI"
echo "Project:                             $SYSTEM_TEAMPROJECT"
echo ""
echo "Azure CLI version:"
echo "-------------------------------------------------"
az --version

if [ "$ENVIRONMENT" != "$ENVIRONMENT_IN_FILENAME" ]; then
	echo "##vso[task.logissue type=error]The environment setting in $WORKLOAD_ZONE_TFVARS_FILENAME '$ENVIRONMENT' does not match the $WORKLOAD_ZONE_TFVARS_FILENAME file name '$ENVIRONMENT_IN_FILENAME'. Filename should have the pattern [ENVIRONMENT]-[REGION_CODE]-[NETWORK_LOGICAL_NAME]-INFRASTRUCTURE"
	exit 2
fi

if [ "$LOCATION" != "$LOCATION_IN_FILENAME" ]; then
	echo "##vso[task.logissue type=error]The location setting in $WORKLOAD_ZONE_TFVARS_FILENAME '$LOCATION' does not match the $WORKLOAD_ZONE_TFVARS_FILENAME file name '$LOCATION_IN_FILENAME'. Filename should have the pattern [ENVIRONMENT]-[REGION_CODE]-[NETWORK_LOGICAL_NAME]-INFRASTRUCTURE"
	exit 2
fi

if [ "$NETWORK" != "$NETWORK_IN_FILENAME" ]; then
	echo "##vso[task.logissue type=error]The network_logical_name setting in $WORKLOAD_ZONE_TFVARS_FILENAME '$NETWORK' does not match the $WORKLOAD_ZONE_TFVARS_FILENAME file name '$NETWORK_IN_FILENAME-. Filename should have the pattern [ENVIRONMENT]-[REGION_CODE]-[NETWORK_LOGICAL_NAME]-INFRASTRUCTURE"
	exit 2
fi

deployer_environment_file_name="$CONFIG_REPO_PATH/.sap_deployment_automation/$DEPLOYER_ENVIRONMENT$DEPLOYER_REGION"
echo "Deployer Environment File:           $deployer_environment_file_name"
if [ ! -f "${deployer_environment_file_name}" ]; then
	echo -e "$bold_red--- $DEPLOYER_ENVIRONMENT$DEPLOYER_REGION was not found ---$reset"
	echo "##vso[task.logissue type=error]Control plane configuration file $DEPLOYER_ENVIRONMENT$DEPLOYER_REGION was not found."
	exit 2
fi
workload_environment_file_name="$CONFIG_REPO_PATH/.sap_deployment_automation/${ENVIRONMENT}${LOCATION_CODE_IN_FILENAME}${NETWORK}"
echo "Workload Zone Environment File:      $workload_environment_file_name"
touch "$workload_environment_file_name"

echo -e "$green--- Configure devops CLI extension ---$reset"
az config set extension.use_dynamic_install=yes_without_prompt --output none

az extension add --name azure-devops --output none --only-show-errors

az devops configure --defaults organization="$SYSTEM_COLLECTIONURI" project="$SYSTEM_TEAMPROJECT" --output none

PARENT_VARIABLE_GROUP_ID=$(az pipelines variable-group list --query "[?name=='$PARENT_VARIABLE_GROUP'].id | [0]")

if [ -z "${PARENT_VARIABLE_GROUP_ID}" ]; then
	echo "##vso[task.logissue type=error]Variable group $PARENT_VARIABLE_GROUP could not be found."
	exit 2
fi
export PARENT_VARIABLE_GROUP_ID

VARIABLE_GROUP_ID=$(az pipelines variable-group list --query "[?name=='$VARIABLE_GROUP'].id | [0]")

if [ -z "${VARIABLE_GROUP_ID}" ]; then
	echo "##vso[task.logissue type=error]Variable group $VARIABLE_GROUP could not be found."
	exit 2
fi
export VARIABLE_GROUP_ID

printf -v tempval '%s id:' "$VARIABLE_GROUP"
printf -v val '%-20s' "${tempval}"
echo "$val                 $VARIABLE_GROUP_ID"

printf -v tempval '%s id:' "$PARENT_VARIABLE_GROUP"
printf -v val '%-20s' "${tempval}"
echo "$val                 $PARENT_VARIABLE_GROUP_ID"

echo -e "$green--- Read parameter values ---$reset"

dos2unix -q "${deployer_environment_file_name}"
dos2unix -q "${workload_environment_file_name}"

landscape_tfstate_key=$WORKLOAD_ZONE_FOLDERNAME.terraform.tfstate
export landscape_tfstate_key

deployer_tfstate_key=$(getVariableFromVariableGroup "${PARENT_VARIABLE_GROUP_ID}" "Deployer_State_FileName" "${workload_environment_file_name}" "deployer_tfstate_key")
export deployer_tfstate_key

key_vault=$(getVariableFromVariableGroup "${PARENT_VARIABLE_GROUP_ID}" "Deployer_Key_Vault" "${deployer_environment_file_name}" "keyvault")
export key_vault

REMOTE_STATE_SA=$(getVariableFromVariableGroup "${PARENT_VARIABLE_GROUP_ID}" "Terraform_Remote_Storage_Account_Name" "${deployer_environment_file_name}" "REMOTE_STATE_SA")
export REMOTE_STATE_SA

STATE_SUBSCRIPTION=$(getVariableFromVariableGroup "${PARENT_VARIABLE_GROUP_ID}" "Terraform_Remote_Storage_Subscription" "${deployer_environment_file_name}" "STATE_SUBSCRIPTION")
export STATE_SUBSCRIPTION

workload_key_vault=$(getVariableFromVariableGroup "${VARIABLE_GROUP_ID}" "Workload_Key_Vault" "${workload_environment_file_name}" "workloadkeyvault")
export workload_key_vault

echo "Deployer statefile:                  $deployer_tfstate_key"
echo "Workload Key vault:                  ${workload_key_vault}"
echo "Target subscription                  $WL_ARM_SUBSCRIPTION_ID"

echo "Terraform state file subscription:   $STATE_SUBSCRIPTION"
echo "Terraform state file storage account:$REMOTE_STATE_SA"

if [ -n "$key_vault" ]; then
	echo "Deployer Key Vault:                  ${key_vault}"
	key_vault_id=$(az resource list --name "${key_vault}" --resource-type Microsoft.KeyVault/vaults --query "[].id | [0]" --subscription "$STATE_SUBSCRIPTION" --output tsv)

	export TF_VAR_spn_keyvault_id=${key_vault_id}
else
	echo "Deployer Key Vault:                  undefined"
fi

secrets_set=1
az account set --subscription $STATE_SUBSCRIPTION
echo -e "$green --- Set secrets ---$reset"

if [ "$USE_MSI" != "true" ]; then
	"$SAP_AUTOMATION_REPO_PATH/deploy/scripts/set_secrets.sh" --workload --vault "${key_vault}" --environment "${ENVIRONMENT}" \
		--region "${LOCATION}" --subscription "$WL_ARM_SUBSCRIPTION_ID" --spn_id "$WL_ARM_CLIENT_ID" --spn_secret "${WL_ARM_CLIENT_SECRET}" \
		--tenant_id "$WL_ARM_TENANT_ID" --keyvault_subscription "$STATE_SUBSCRIPTION"
else
	"$SAP_AUTOMATION_REPO_PATH/deploy/scripts/set_secrets.sh" --workload --vault "${key_vault}" --environment "${ENVIRONMENT}" \
		--region "${LOCATION}" --subscription "$WL_ARM_SUBSCRIPTION_ID" --keyvault_subscription "$STATE_SUBSCRIPTION" --msi
fi
secrets_set=$?
echo "Set Secrets returned: $secrets_set"

tfstate_resource_id=$(az resource list --name "${REMOTE_STATE_SA}" --subscription "$STATE_SUBSCRIPTION" --resource-type Microsoft.Storage/storageAccounts --query "[].id | [0]" -o tsv)
export tfstate_resource_id

echo -e "$green--- Set Permissions ---$reset"

if [ "$USE_MSI" != "true" ]; then

	isUserAccessAdmin=$(az role assignment list --role "User Access Administrator" --subscription "$STATE_SUBSCRIPTION" --assignee "$ARM_OBJECT_ID" --query "[].principalName | [0]" --output tsv)

	if [ -n "${isUserAccessAdmin}" ]; then

		echo -e "$green--- Set permissions ---$reset"
		perms=$(az role assignment list --subscription "$STATE_SUBSCRIPTION" --role "Reader" --assignee "$ARM_OBJECT_ID" --query "[].principalName | [0]" --output tsv --only-show-errors)
		if [ -z "$perms" ]; then
			echo -e "$green --- Assign subscription permissions to $perms ---$reset"
			az role assignment create --assignee "$ARM_OBJECT_ID" --role "Reader" --scope "/subscriptions/${STATE_SUBSCRIPTION}" --output none
		fi

		resource_group_id=$(az group show --name "${REMOTE_STATE_SA}" --subscription "$STATE_SUBSCRIPTION" query "id" -o tsv)
		perms=$(az role assignment list --subscription "$STATE_SUBSCRIPTION" --role "Storage Blob Data Contributor" --scope "${resource_group_id}" --assignee "$ARM_OBJECT_ID" --query "[].principalName | [0]" --only-show-errors)
		if [ -z $perms ]; then
			echo "Assigning Storage Blob Data Contributor permissions for $ARM_OBJECT_ID to ${resource_group_id}"
			az role assignment create --assignee "$ARM_OBJECT_ID" --role "Storage Blob Data Contributor" --scope "${resource_group_id}" --output none
		fi

		perms=$(az role assignment list --subscription "$STATE_SUBSCRIPTION" --role "Storage Blob Data Contributor" --scope "${tfstate_resource_id}" --assignee "$ARM_OBJECT_ID" --query "[].principalName | [0]" --only-show-errors)
		if [ -z "$perms" ]; then
			echo "Assigning Storage Blob Data Contributor permissions for $ARM_OBJECT_ID to ${tfstate_resource_id}"
			az role assignment create --assignee "$ARM_OBJECT_ID" --role "Storage Blob Data Contributor" --scope "${tfstate_resource_id}" --output none
		fi

		resource_group_name=$(az resource show --id "${tfstate_resource_id}" --query resourceGroup -o tsv)

		if [ -n "$resource_group_name" ]; then
			for scope in $(az resource list --resource-group "${resource_group_name}" --subscription "$STATE_SUBSCRIPTION" --resource-type Microsoft.Network/privateDnsZones --query "[].id" --output tsv); do
				perms=$(az role assignment list --subscription "$STATE_SUBSCRIPTION" --role "Private DNS Zone Contributor" --scope "$scope" --assignee "$ARM_OBJECT_ID" --query "[].principalName | [0]" --output tsv --only-show-errors)
				if [ -z $perms ]; then
					echo "Assigning DNS Zone Contributor permissions for $ARM_OBJECT_ID to ${scope}"
					az role assignment create --assignee "$ARM_OBJECT_ID" --role "Private DNS Zone Contributor" --scope "$scope" --output none
				fi
			done
		fi

		resource_group_name=$(az keyvault show --name "${key_vault}" --query resourceGroup --subscription "$STATE_SUBSCRIPTION" -o tsv)

		if [ -n "${resource_group_name}" ]; then
			resource_group_id=$(az group show --name "${resource_group_name}" --subscription "$STATE_SUBSCRIPTION" --query id -o tsv)

			vnet_resource_id=$(az resource list --resource-group "${resource_group_name}" --subscription "$STATE_SUBSCRIPTION" --resource-type Microsoft.Network/virtualNetworks -o tsv --query "[].id | [0]")
			if [ -n "${vnet_resource_id}" ]; then
				perms=$(az role assignment list --subscription "$STATE_SUBSCRIPTION" --role "Network Contributor" --scope "$vnet_resource_id" --query "[].principalName | [0]" --assignee "$ARM_OBJECT_ID" --output tsv --only-show-errors)

				if [ -z $perms ]; then
					echo "Assigning Network Contributor rights for $ARM_OBJECT_ID to ${vnet_resource_id}"
					az role assignment create --assignee "$ARM_OBJECT_ID" --role "Network Contributor" --scope "$vnet_resource_id" --output none
				fi
			fi
		fi
	else
		echo " ##vso[task.logissue type=warning]Service Principal $WL_ARM_CLIENT_ID does not have 'User Access Administrator' permissions. Please ensure that the service principal $WL_ARM_CLIENT_ID has permissions on the Terrafrom state storage account and if needed on the Private DNS zone and the source management network resource"
	fi
fi

echo -e "$green--- Deploy the workload zone ---$reset"
cd "$CONFIG_REPO_PATH/LANDSCAPE/$WORKLOAD_ZONE_FOLDERNAME" || exit

# Set logon variables
ARM_CLIENT_ID="$WL_ARM_CLIENT_ID"
export ARM_CLIENT_ID
ARM_CLIENT_SECRET="$WL_ARM_CLIENT_SECRET"
export ARM_CLIENT_SECRET
ARM_TENANT_ID=$WL_ARM_TENANT_ID
export ARM_TENANT_ID
ARM_SUBSCRIPTION_ID=$WL_ARM_SUBSCRIPTION_ID
export ARM_SUBSCRIPTION_ID

# Check if running on deployer
if [[ ! -f /etc/profile.d/deploy_server.sh ]]; then
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

az account set --subscription "$ARM_SUBSCRIPTION_ID"

if "$SAP_AUTOMATION_REPO_PATH/deploy/scripts/install_workloadzone.sh" --parameterfile "$WORKLOAD_ZONE_TFVARS_FILENAME" \
	--deployer_environment "$DEPLOYER_ENVIRONMENT" --subscription "$WL_ARM_SUBSCRIPTION_ID" \
	--deployer_tfstate_key "${deployer_tfstate_key}" --keyvault "${key_vault}" --storageaccountname "${REMOTE_STATE_SA}" \
	--state_subscription "${STATE_SUBSCRIPTION}" --auto-approve --ado --msi; then
	echo "##vso[task.logissue type=warning]Workload zone deployment completed successfully."
else
	return_code=$?
	echo "##vso[task.logissue type=error]Workload zone deployment failed."
	exit 1
fi

echo "Return code from deployment:         ${return_code}"
cd "$CONFIG_REPO_PATH" || exit

workload_environment_file_name=".sap_deployment_automation/${ENVIRONMENT}${LOCATION_CODE_IN_FILENAME}${NETWORK}"

if [ -f "${workload_environment_file_name}" ]; then
	workload_key_vault=$(grep "workloadkeyvault=" "${workload_environment_file_name}" | awk -F'=' '{print $2}' | xargs || true)
	export workload_key_vault
	echo "Workload zone key vault:             ${workload_key_vault}"

	workload_prefix=$(grep "workload_zone_prefix=" "${workload_environment_file_name}" | awk -F'=' '{print $2}' | xargs || true)
	export workload_prefix
	echo "Workload zone prefix:                ${workload_prefix}"

fi

prefix="${ENVIRONMENT}${LOCATION_CODE_IN_FILENAME}${NETWORK}"

echo -e "$green--- Adding variables to the variable group" "$VARIABLE_GROUP" "---$reset"
if [ -n "${VARIABLE_GROUP_ID}" ]; then

	if saveVariableInVariableGroup "${VARIABLE_GROUP_ID}" "Terraform_Remote_Storage_Account_Name" "${REMOTE_STATE_SA}"; then
		echo "Variable Terraform_Remote_Storage_Account_Name was added to the $VARIABLE_GROUP variable group."
	else
		echo "##vso[task.logissue type=error]Variable Terraform_Remote_Storage_Account_Name was not added to the $VARIABLE_GROUP variable group."
		echo "Variable Terraform_Remote_Storage_Account_Name was not added to the $VARIABLE_GROUP variable group."
	fi

	if saveVariableInVariableGroup "${VARIABLE_GROUP_ID}" "Terraform_Remote_Storage_Subscription" "${STATE_SUBSCRIPTION}"; then
		echo "Variable Terraform_Remote_Storage_Subscription was added to the $VARIABLE_GROUP variable group."
	else
		echo "##vso[task.logissue type=error]Variable Terraform_Remote_Storage_Subscription was not added to the $VARIABLE_GROUP variable group."
		echo "Variable Terraform_Remote_Storage_Subscription was not added to the $VARIABLE_GROUP variable group."
	fi

	if saveVariableInVariableGroup "${VARIABLE_GROUP_ID}" "Deployer_State_FileName" "${deployer_tfstate_key}"; then
		echo "Variable Deployer_State_FileName was added to the $VARIABLE_GROUP variable group."
	else
		echo "##vso[task.logissue type=error]Variable Deployer_State_FileName was not added to the $VARIABLE_GROUP variable group."
		echo "Variable Deployer_State_FileName was not added to the $VARIABLE_GROUP variable group."
	fi

	if saveVariableInVariableGroup "${VARIABLE_GROUP_ID}" "Deployer_Key_Vault" "${key_vault}"; then
		echo "Variable Deployer_Key_Vault was added to the $VARIABLE_GROUP variable group."
	else
		echo "##vso[task.logissue type=error]Variable Deployer_Key_Vault was not added to the $VARIABLE_GROUP variable group."
		echo "Variable Deployer_Key_Vault was not added to the $VARIABLE_GROUP variable group."
	fi

	if saveVariableInVariableGroup "${VARIABLE_GROUP_ID}" "${prefix}Workload_Key_Vault" "${workload_key_vault}"; then
		echo "Variable ${prefix}Workload_Key_Vault was added to the $VARIABLE_GROUP variable group."
	else
		echo "##vso[task.logissue type=error]Variable ${prefix}Workload_Key_Vault was not added to the $VARIABLE_GROUP variable group."
		echo "Variable ${prefix}Workload_Key_Vault was not added to the $VARIABLE_GROUP variable group."
	fi

	if saveVariableInVariableGroup "${VARIABLE_GROUP_ID}" "${prefix}Workload_Secret_Prefix" "${ENVIRONMENT}-${LOCATION_CODE_IN_FILENAME}-${NETWORK}"; then
		echo "Variable ${prefix}Workload_Secret_Prefix was added to the $VARIABLE_GROUP variable group."
	else
		echo "##vso[task.logissue type=error]Variable ${prefix}Workload_Secret_Prefix was not added to the $VARIABLE_GROUP variable group."
		echo "Variable ${prefix}Workload_Secret_Prefix was not added to the $VARIABLE_GROUP variable group."
	fi

	if saveVariableInVariableGroup "${VARIABLE_GROUP_ID}" "${prefix}Workload_Zone_State_FileName" "${landscape_tfstate_key}" ; then
		echo "Variable ${prefix}Workload_Zone_State_FileName was added to the $VARIABLE_GROUP variable group."
	else
		echo "##vso[task.logissue type=error]Variable ${prefix}Workload_Zone_State_FileName was not added to the $VARIABLE_GROUP variable group."
		echo "Variable ${prefix}Workload_Zone_State_FileName was not added to the $VARIABLE_GROUP variable group."
	fi

fi

az_var=$(az pipelines variable-group variable list --group-id "${VARIABLE_GROUP_ID}" --query "FENCING_SPN_ID.value")
if [ -z "${az_var}" ]; then
	echo "##vso[task.logissue type=warning]Variable FENCING_SPN_ID is not set. Required for highly available deployments when using Service Principals for fencing."
else
	fencing_id=$(az keyvault secret list --vault-name "$workload_key_vault" --subscription "$STATE_SUBSCRIPTION" --query [].name -o tsv | grep "${workload_prefix}-fencing-spn-id" | xargs || true)
	if [ -z "$fencing_id" ]; then
		az keyvault secret set --name "${workload_prefix}-fencing-spn-id" --vault-name "$workload_key_vault" --value "$FENCING_SPN_ID" --subscription "$STATE_SUBSCRIPTION" --expires "$(date -d '+1 year' -u +%Y-%m-%dT%H:%M:%SZ)" --output none
		az keyvault secret set --name "${workload_prefix}-fencing-spn-pwd" --vault-name "$workload_key_vault" --value="$FENCING_SPN_PWD" --subscription "$STATE_SUBSCRIPTION" --expires "$(date -d '+1 year' -u +%Y-%m-%dT%H:%M:%SZ)" --output none
		az keyvault secret set --name "${workload_prefix}-fencing-spn-tenant" --vault-name "$workload_key_vault" --value "$FENCING_SPN_TENANT" --subscription "$STATE_SUBSCRIPTION" --expires "$(date -d '+1 year' -u +%Y-%m-%dT%H:%M:%SZ)" --output none
	fi
fi

set +o errexit

echo -e "$green--- Add & update files in the DevOps Repository ---$reset"

cd "$CONFIG_REPO_PATH" || exit
# Pull changes
git pull -q origin "$BUILD_SOURCEBRANCHNAME"

added=0
if [ -f ".sap_deployment_automation/${prefix}" ]; then
	git add ".sap_deployment_automation/${prefix}"
	added=1
fi

cd "$CONFIG_REPO_PATH/LANDSCAPE/$WORKLOAD_ZONE_FOLDERNAME" || exit
normalizedName=$(echo "${workload_prefix}" | tr -d '-')

if [ -f "${workload_prefix}.md" ]; then

	mv "${workload_prefix}.md" "${normalizedName}.md"
	git add "${normalizedName}.md"
	# echo "##vso[task.uploadsummary]./${normalizedName}.md"
	added=1
fi

if [ -f "$WORKLOAD_ZONE_TFVARS_FILENAME" ]; then
	git add -f "$WORKLOAD_ZONE_TFVARS_FILENAME"
	added=1
fi

if [ -f "/.terraform/terraform.tfstate" ]; then
	git add -f "LANDSCAPE/$WORKLOAD_ZONE_FOLDERNAME/.terraform/terraform.tfstate"
	added=1
fi

if [ 1 == $added ]; then
	git config --global user.email "$BUILD_REQUESTEDFOREMAIL"
	git config --global user.name "$BUILD_REQUESTEDFOR"
	git commit -m "Added updates from devops deployment $BUILD_BUILDNUMBER of $WORKLOAD_ZONE_FOLDERNAME [skip ci]"
	if git -c http.extraheader="AUTHORIZATION: bearer $SYSTEM_ACCESSTOKEN" push --set-upstream origin "$BUILD_SOURCEBRANCHNAME" --force-with-lease; then
		echo "##vso[task.logissue type=warning]Workload deployment $WORKLOAD_ZONE_FOLDERNAME pushed to $BUILD_SOURCEBRANCHNAME"
	else
		echo "##vso[task.logissue type=error]Failed to push changes to $BUILD_SOURCEBRANCHNAME"
	fi

fi

exit $return_code
