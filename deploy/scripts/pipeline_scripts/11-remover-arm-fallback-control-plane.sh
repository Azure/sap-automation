#!/bin/bash

# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

green="\e[1;32m"
reset="\e[0m"

full_script_path="$(realpath "${BASH_SOURCE[0]}")"
script_directory="$(dirname "${full_script_path}")"

source "${script_directory}/helper.sh"

deployerTFvarsFile="${CONFIG_REPO_PATH}/DEPLOYER/$DEPLOYER_FOLDERNAME/$DEPLOYER_TFVARS_FILENAME"
libraryTFvarsFile="${CONFIG_REPO_PATH}/LIBRARY/$LIBRARY_FOLDERNAME/$LIBRARY_TFVARS_FILENAME"

if [ "$SYSTEM_DEBUG" = True ]; then
	set -x
	debug=true
	export debug
	printenv | sort
fi

if [ "${#PAT}" -gt 0 ]; then
	echo "Using PAT for authentication"
	AZURE_DEVOPS_EXT_PAT=$PAT
else
	echo "Using SYSTEM_ACCESSTOKEN for authentication"
	AZURE_DEVOPS_EXT_PAT=$SYSTEM_ACCESSTOKEN
fi
export AZURE_DEVOPS_EXT_PAT

# Print the execution environment details
print_header

# Configure DevOps
configure_devops

if ! get_variable_group_id "$VARIABLE_GROUP" "VARIABLE_GROUP_ID"; then
	echo -e "$bold_red--- Variable group $VARIABLE_GROUP not found ---$reset"
	echo "##vso[task.logissue type=error]Variable group $VARIABLE_GROUP not found."
	exit 2
fi
export VARIABLE_GROUP_ID

return_code=0

ENVIRONMENT=$(echo "$DEPLOYER_FOLDERNAME" | awk -F'-' '{print $1}' | xargs)
echo "Environment:                         $ENVIRONMENT"

LOCATION=$(echo "$DEPLOYER_FOLDERNAME" | awk -F'-' '{print $2}' | xargs)
echo "Location:                            $LOCATION"

NETWORK=$(echo "$DEPLOYER_FOLDERNAME" | awk -F'-' '{print $3}' | xargs)
echo "Network:                             $NETWORK"

subscription=$ARM_SUBSCRIPTION_ID
echo "Subscription:                        $subscription"

library_return_code=0
resourceGroupName=$(az group list --subscription "$subscription" --query "[?name=='$LIBRARY_FOLDERNAME'].name | [0]")
if [ ${#resourceGroupName} != 0 ]; then
	print_banner "Removal using ARM" "Deleting resource group: $LIBRARY_FOLDERNAME" "info"
	echo "##vso[task.setprogress value=0;]Progress Indicator"

	# shellcheck disable=SC2046
	az group delete --subscription "$subscription" --name $LIBRARY_FOLDERNAME --yes --only-show-errors
	library_return_code=$?
	echo "##vso[task.setprogress value=30;]Progress Indicator"
else
	print_banner "Removal using ARM" "Resource group: $LIBRARY_FOLDERNAME was not found" "warning"

fi

deployer_return_code=0
resourceGroupName=$(az group list --subscription "$subscription" --query "[?name=='$DEPLOYER_FOLDERNAME'].name  | [0]")
if [ ${#resourceGroupName} != 0 ]; then
	print_banner "Removal using ARM" "Deleting resource group: $DEPLOYER_FOLDERNAME" "info"
	echo "##vso[task.setprogress value=60;]Progress Indicator"
	az group delete --subscription "$subscription" --name "$DEPLOYER_FOLDERNAME" --yes --only-show-errors
	deployer_return_code=$?
else
	print_banner "Removal using ARM" "Resource group: $DEPLOYER_FOLDERNAME was not found" "warning"
fi

echo -e "$green--- Removing deployment automation configuration from devops repository ---$reset"

echo "##vso[task.setprogress value=90;]Progress Indicator"
echo -e "$green--- Deleting variables ---$reset"

if [ 0 == $library_return_code ] && [ 0 == $deployer_return_code ]; then

	if [ -n "$VARIABLE_GROUP_ID" ]; then
		echo "Deleting variables"

		remove_variable "$VARIABLE_GROUP_ID" "Deployer_State_FileName"
		remove_variable "$VARIABLE_GROUP_ID" "Deployer_Key_Vault"
		remove_variable "$VARIABLE_GROUP_ID" "WEBAPP_URL_BASE"
		remove_variable "$VARIABLE_GROUP_ID" "WEBAPP_IDENTITY"
		remove_variable "$VARIABLE_GROUP_ID" "WEBAPP_ID"
		remove_variable "$VARIABLE_GROUP_ID" "WEBAPP_RESOURCE_GROUP"
		remove_variable "$VARIABLE_GROUP_ID" "INSTALLATION_MEDIA_ACCOUNT"
		remove_variable "$VARIABLE_GROUP_ID" "DEPLOYER_RANDOM_ID"
		remove_variable "$VARIABLE_GROUP_ID" "LIBRARY_RANDOM_ID"
		remove_variable "$VARIABLE_GROUP_ID" "APPLICATION_CONFIGURATION_ID"
		remove_variable "$VARIABLE_GROUP_ID" "HAS_APPSERVICE_DEPLOYED"
		remove_variable "$VARIABLE_GROUP_ID" "Terraform_Remote_Storage_Account_Name"
		remove_variable "$VARIABLE_GROUP_ID" "Terraform_Remote_Storage_Resource_Group_Name"
		remove_variable "$VARIABLE_GROUP_ID" "Terraform_Remote_Storage_Subscription"

	fi
	cd "$CONFIG_REPO_PATH" || exit
	git checkout -q $BUILD_SOURCEBRANCHNAME
	git pull
	changed=0

	echo "##vso[build.updatebuildnumber]Removing control plane $DEPLOYER_FOLDERNAME $LIBRARY_FOLDERNAME"
	if [ -f "LIBRARY/$LIBRARY_FOLDERNAME/$libraryTFvarsFile" ]; then
		sed -i /"custom_random_id"/d "LIBRARY/$LIBRARY_FOLDERNAME/$libraryTFvarsFile"
		git add -f "LIBRARY/$LIBRARY_FOLDERNAME/$libraryTFvarsFile"
		changed=1
	fi

	if [ -f "DEPLOYER/$DEPLOYER_FOLDERNAME/$deployerTFvarsFile" ]; then
		sed -i /"custom_random_id"/d "DEPLOYER/$DEPLOYER_FOLDERNAME/$deployerTFvarsFile"
		git add -f "DEPLOYER/$DEPLOYER_FOLDERNAME/$deployerTFvarsFile"
		changed=1
	fi

	if [ -d "DEPLOYER/$DEPLOYER_FOLDERNAME/.terraform" ]; then
		git rm -q -r --ignore-unmatch "DEPLOYER/$DEPLOYER_FOLDERNAME/.terraform"
		changed=1
	fi

	if [ -f "DEPLOYER/$DEPLOYER_FOLDERNAME/state.zip" ]; then
		git rm -q --ignore-unmatch "DEPLOYER/$DEPLOYER_FOLDERNAME/state.zip"
		changed=1
	fi

	if [ -d "LIBRARY/$LIBRARY_FOLDERNAME/.terraform" ]; then
		git rm -q -r --ignore-unmatch "LIBRARY/$LIBRARY_FOLDERNAME/.terraform"
		changed=1
	fi

	if [ -f "LIBRARY/$LIBRARY_FOLDERNAME/state.zip" ]; then
		git rm -q --ignore-unmatch "LIBRARY/$LIBRARY_FOLDERNAME/state.zip"
		changed=1
	fi

	if [ -f ".sap_deployment_automation/${ENVIRONMENT}${LOCATION}" ]; then
		git rm -q --ignore-unmatch ".sap_deployment_automation/${ENVIRONMENT}${LOCATION}"
		changed=1
	fi

	if [ -f ".sap_deployment_automation/${ENVIRONMENT}-${LOCATION}-${NETWORK}" ]; then
		git rm -q --ignore-unmatch ".sap_deployment_automation/${ENVIRONMENT}-${LOCATION}-${NETWORK}"
		changed=1
	fi

	if [ -f ".sap_deployment_automation/${ENVIRONMENT}${LOCATION}.md" ]; then
		git rm -q --ignore-unmatch ".sap_deployment_automation/${ENVIRONMENT}${LOCATION}.md"
		changed=1
	fi

	if [ -f "LIBRARY/$LIBRARY_FOLDERNAME/backend-config.tfvars" ]; then
		git rm -q --ignore-unmatch "LIBRARY/$LIBRARY_FOLDERNAME/backend-config.tfvars"
		changed=1
	fi

	if [ 1 == $changed ]; then
		git config --global user.email "$BUILD_REQUESTEDFOREMAIL"
		git config --global user.name "$BUILD_REQUESTEDFOR"
		git commit -m "Added updates from devops deployment $BUILD_BUILDNUMBER [skip ci]"
		if git -c http.extraheader="AUTHORIZATION: bearer $SYSTEM_ACCESSTOKEN" push --set-upstream origin "$BUILD_SOURCEBRANCHNAME" --force-with-lease; then
			echo "##vso[task.logissue type=warning]Changes pushed to $BUILD_SOURCEBRANCHNAME"
		else
			echo "##vso[task.logissue type=error]Failed to push changes to $BUILD_SOURCEBRANCHNAME"
		fi

	fi
fi

echo "##vso[task.setprogress value=100;]Progress Indicator"

exit $return_code
