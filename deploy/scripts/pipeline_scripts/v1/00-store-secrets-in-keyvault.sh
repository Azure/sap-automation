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
banner_title="Set Workload Zone Secrets"

#call stack has full script name when using source
# shellcheck disable=SC1091
source "${grand_parent_directory}/deploy_utils.sh"

#call stack has full script name when using source
source "${parent_directory}/helper.sh"

echo "##vso[build.updatebuildnumber]Setting the deployment credentials for the SAP Workload zone defined in $ZONE"
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
		if [ -z "$WZ_APPLICATION_CONFIGURATION_NAME" ]; then
			az pipelines variable-group variable create --group-id "${VARIABLE_GROUP_ID}" --name "APPLICATION_CONFIGURATION_NAME" --value "$APPLICATION_CONFIGURATION_NAME" --output none
		else
			az pipelines variable-group variable update --group-id "${VARIABLE_GROUP_ID}" --name "APPLICATION_CONFIGURATION_NAME" --value "$APPLICATION_CONFIGURATION_NAME" --output none
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

keyvault_subscription_id=$(az graph query -q "Resources | join kind=leftouter (ResourceContainers | where type=='microsoft.resources/subscriptions' | project subscription=name, subscriptionId) on subscriptionId | where name == '$DEPLOYER_KEYVAULT' | project id, name, subscription,subscriptionId" --query data[0].subscriptionId --output tsv)

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

exit $return_code
