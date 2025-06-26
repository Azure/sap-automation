#!/bin/bash
# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

# External helper functions
#. "$(dirname "${BASH_SOURCE[0]}")/deploy_utils.sh"
full_script_path="$(realpath "${BASH_SOURCE[0]}")"
script_directory="$(dirname "${full_script_path}")"
parent_directory="$(dirname "$script_directory")"

SCRIPT_NAME="$(basename "$0")"

banner_title="Check credentials"

#call stack has full script name when using source
# shellcheck disable=SC1091
source "${parent_directory}/deploy_utils.sh"

#call stack has full script name when using source
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

print_banner "$banner_title" "Starting $SCRIPT_NAME" "info"

if ! az extension list --query "[?contains(name, 'azure-devops')]" --output table; then
	az extension add --name azure-devops --output none --only-show-errors
fi

VARIABLE_GROUP="SDAF-$ZONE"

az devops configure --defaults organization=$SYSTEM_COLLECTIONURI project=$SYSTEM_TEAMPROJECTID

VARIABLE_GROUP_ID=$(az pipelines variable-group list --query "[?name=='$VARIABLE_GROUP'].id | [0]")
if [ -n "${VARIABLE_GROUP_ID}" ]; then

	print_banner "$banner_title" "VARIABLE_GROUP name: $VARIABLE_GROUP" "info" "VARIABLE_GROUP id: $VARIABLE_GROUP_ID"

	az_var=$(az pipelines variable-group variable list --group-id "${VARIABLE_GROUP_ID}" --query "APPLICATION_CONFIGURATION_ID.value" --output tsv)
	if [ -n "${az_var}" ]; then
		echo "##vso[task.setvariable variable=APPLICATION_CONFIGURATION_ID;isOutput=true]$az_var"
	else
		if checkforEnvVar APPLICATION_CONFIGURATION_ID; then
			echo "##vso[task.setvariable variable=APPLICATION_CONFIGURATION_ID;isOutput=true]$APPLICATION_CONFIGURATION_ID"
		fi
	fi

	az_var=$(az pipelines variable-group variable list --group-id "${VARIABLE_GROUP_ID}" --query "CONTROL_PLANE_NAME.value" --output tsv)
	if [ -n "${az_var}" ]; then
		echo "##vso[task.setvariable variable=CONTROL_PLANE_NAME;isOutput=true]$az_var"
	else
		if printenv CONTROL_PLANE_NAME; then
			echo "##vso[task.setvariable variable=CONTROL_PLANE_NAME;isOutput=true]$CONTROL_PLANE_NAME"
		fi
	fi

	az_var=$(az pipelines variable-group variable list --group-id "${VARIABLE_GROUP_ID}" --query "ARM_SUBSCRIPTION_ID.value" --output tsv)
	if [ -n "${az_var}" ]; then
		echo "##vso[task.setvariable variable=ARM_SUBSCRIPTION_ID;isOutput=true]$az_var"
	else
		if printenv ARM_SUBSCRIPTION_ID; then
			echo "##vso[task.setvariable variable=ARM_SUBSCRIPTION_ID;isOutput=true]$ARM_SUBSCRIPTION_ID"
		fi
	fi

	az_var=$(az pipelines variable-group variable list --group-id "${VARIABLE_GROUP_ID}" --query "ARM_CLIENT_ID.value" --output tsv)
	if [ -n "${az_var}" ]; then
		echo "##vso[task.setvariable variable=ARM_CLIENT_ID;isOutput=true]$az_var"
	else
		if printenv ARM_CLIENT_ID; then
			echo "##vso[task.setvariable variable=ARM_CLIENT_ID;isOutput=true]$ARM_CLIENT_ID"
		else
			if [[ -f /etc/profile.d/deploy_server.sh ]]; then
				ARM_CLIENT_ID=$(grep -m 1 "export ARM_CLIENT_ID=" /etc/profile.d/deploy_server.sh | awk -F'=' '{print $2}' | xargs)
				echo "##vso[task.setvariable variable=ARM_CLIENT_ID;isOutput=true]$ARM_CLIENT_ID"
			else
				echo "##vso[task.setvariable variable=ARM_CLIENT_ID;isOutput=true]"
			fi
		fi

	fi

	az_var=$(az pipelines variable-group variable list --group-id "${VARIABLE_GROUP_ID}" --query "ARM_CLIENT_SECRET.value" --output tsv)
	if [ -n "${az_var}" ]; then
		echo "##vso[task.setvariable variable=ARM_CLIENT_SECRET;isOutput=true;issecret=true]$az_var"
	else
		if printenv ARM_CLIENT_SECRET; then
			echo "##vso[task.setvariable variable=ARM_CLIENT_SECRET;isOutput=true]$ARM_CLIENT_SECRET"
		else
			echo "##vso[task.setvariable variable=ARM_CLIENT_SECRET;isOutput=true]"
		fi
	fi

	az_var=$(az pipelines variable-group variable list --group-id "${VARIABLE_GROUP_ID}" --query "ARM_TENANT_ID.value" --output tsv)
	if [ -n "${az_var}" ]; then
		echo "##vso[task.setvariable variable=ARM_TENANT_ID;isOutput=true]$az_var"
	else
		if printenv ARM_TENANT_ID; then
			echo "##vso[task.setvariable variable=ARM_TENANT_ID;isOutput=true]$ARM_TENANT_ID"
		else
			if [[ -f /etc/profile.d/deploy_server.sh ]]; then
				ARM_TENANT_ID=$(grep -m 1 "export ARM_TENANT_ID=" /etc/profile.d/deploy_server.sh | awk -F'=' '{print $2}' | xargs)
				echo "##vso[task.setvariable variable=ARM_TENANT_ID;isOutput=true]$ARM_CLIENT_ID"
			else
				echo "##vso[task.setvariable variable=ARM_TENANT_ID;isOutput=true]"
			fi
		fi
	fi

	az_var=$(az pipelines variable-group variable list --group-id "${VARIABLE_GROUP_ID}" --query "ARM_OBJECT_ID.value" --output tsv)
	if [ -n "${az_var}" ]; then
		echo "##vso[task.setvariable variable=ARM_OBJECT_ID;isOutput=true]$az_var"
	else
		if printenv ARM_OBJECT_ID; then
			echo "##vso[task.setvariable variable=ARM_OBJECT_ID;isOutput=true]$ARM_OBJECT_ID"
		fi
	fi
else
	print_banner "$banner_title" "VARIABLE_GROUP: $VARIABLE_GROUP was not found" "error"
	exit 1
fi

print_banner "$banner_title" "Exiting $SCRIPT_NAME" "info"
exit 0
