#!/bin/bash
# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

green="\e[1;32m"
reset="\e[0m"

full_script_path="$(realpath "${BASH_SOURCE[0]}")"
script_directory="$(dirname "${full_script_path}")"
parent_directory="$(dirname "$script_directory")"

SCRIPT_NAME="$(basename "$0")"

if [ "$SYSTEM_DEBUG" = True ]; then
	set -x
	debug=true
	export debug
fi

if [ "${#PAT}" -gt 0 ]; then
	echo "Using PAT for authentication"
	AZURE_DEVOPS_EXT_PAT=$PAT
else
	echo "Using SYSTEM_ACCESSTOKEN for authentication"
	AZURE_DEVOPS_EXT_PAT=$SYSTEM_ACCESSTOKEN
fi

export AZURE_DEVOPS_EXT_PAT

banner_title="Remove Workload Zone"

#call stack has full script name when using source
# shellcheck disable=SC1091
source "${parent_directory}/deploy_utils.sh"

#call stack has full script name when using source
source "${script_directory}/helper.sh"

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

echo -e "$green--- Adding deployment automation configuration to devops repository ---$reset"
ENVIRONMENT=$(echo "$WORKLOAD_ZONE_FOLDERNAME" | awk -F'-' '{print $1}' | xargs)
echo "Environment:                           $ENVIRONMENT"

LOCATION=$(echo "$WORKLOAD_ZONE_FOLDERNAME" | awk -F'-' '{print $2}' | xargs)
echo
echo "Location:                              $LOCATION"

NETWORK=$(echo "$WORKLOAD_ZONE_FOLDERNAME" | awk -F'-' '{print $3}' | xargs)
echo "Network:                               $NETWORK"

cd "$CONFIG_REPO_PATH" || exit
git config --global user.email "$BUILD_REQUESTEDFOREMAIL"
git config --global user.name "$BUILD_REQUESTEDFOR"
git commit -m "Added updates from devops deployment $BUILD_BUILDNUMBER [skip ci]"

git checkout -q "$BUILD_SOURCEBRANCHNAME"
git clean -d -f -X

echo "##vso[build.updatebuildnumber]Removing workload zone $WORKLOAD_ZONE_FOLDERNAME"
changed=0

if [ -f "LANDSCAPE/$WORKLOAD_ZONE_FOLDERNAME/$WORKLOAD_ZONE_CONFIG" ]; then
	sed -i /"custom_random_id"/d "LANDSCAPE/$WORKLOAD_ZONE_FOLDERNAME/$WORKLOAD_ZONE_CONFIG"
	git add -f "LANDSCAPE/$WORKLOAD_ZONE_FOLDERNAME/$WORKLOAD_ZONE_CONFIG"
	changed=1
fi

if [ -d "LANDSCAPE/$WORKLOAD_ZONE_FOLDERNAME/.terraform" ]; then
	git rm -r -f --ignore-unmatch "LANDSCAPE/$WORKLOAD_ZONE_FOLDERNAME/.terraform"
	changed=1
fi
if [ -f ".sap_deployment_automation/${ENVIRONMENT}${LOCATION}${NETWORK}" ]; then
	git rm --ignore-unmatch -f ".sap_deployment_automation/${ENVIRONMENT}${LOCATION}${NETWORK}"
	changed=1
fi
if [ -f ".sap_deployment_automation/${ENVIRONMENT}${LOCATION}${NETWORK}.md" ]; then
	git rm --ignore-unmatch -f ".sap_deployment_automation/${ENVIRONMENT}${LOCATION}${NETWORK}.md"
	changed=1
fi

if [ 1 == $changed ]; then
	git commit -m "Removal of Workload zone $BUILD_BUILDNUMBER [skip ci]"
	if git -c http.extraheader="AUTHORIZATION: bearer $SYSTEM_ACCESSTOKEN" push; then
		echo "Removal of Workload zone $BUILD_BUILDNUMBER pushed to devops repository"
	else
		echo "Failed to push changes to devops repository"
		return_code=1
	fi
fi

if [ -n "$VARIABLE_GROUP_ID" ]; then
	echo "Deleting variables"

	remove_variable "$VARIABLE_GROUP_ID" "Terraform_Remote_Storage_Account_Name"
	remove_variable "$VARIABLE_GROUP_ID" "Terraform_Remote_Storage_Resource_Group_Name"
	remove_variable "$VARIABLE_GROUP_ID" "Terraform_Remote_Storage_Subscription"
	remove_variable "$VARIABLE_GROUP_ID" "Deployer_State_FileName"
	remove_variable "$VARIABLE_GROUP_ID" "Deployer_Key_Vault"
	remove_variable "$VARIABLE_GROUP_ID" "INSTALLATION_MEDIA_ACCOUNT"
	remove_variable "$VARIABLE_GROUP_ID" "APPLICATION_CONFIGURATION_ID"

fi

exit $return_code
