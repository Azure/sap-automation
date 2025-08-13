#!/bin/bash
# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

full_script_path="$(realpath "${BASH_SOURCE[0]}")"
script_directory="$(dirname "${full_script_path}")"
parent_directory="$(dirname "$script_directory")"
SCRIPT_NAME="$(basename "$0")"

#call stack has full script name when using source
source "${script_directory}/helper.sh"
source "${parent_directory}/deploy_utils.sh"
set -e

print_banner "$banner_title" "Starting $SCRIPT_NAME" "info"

DEBUG=false

if [ "$SYSTEM_DEBUG" = true ]; then
	set -x
	DEBUG=true
	echo "Environment variables:"
	printenv | sort

fi
export DEBUG
set -eu

# Print the execution environment details
print_header

# Configure DevOps
configure_devops

az account show --query user --output table

echo "Getting the queue ID for $AGENT_POOL"
queueId=$(az pipelines queue list --query "[?name=='$AGENT_POOL'].id | [0]" -o tsv)

pipeLines=$(az pipelines list --query [].id --output tsv)

for pipeLine in $pipeLines; do

	json_string=$(printf '{
    "pipelines": [
       { "id": "%s",
          "authorized": true
       }
    ]
}' "$pipeLine")

	if [ -f ./pipeline.json ]; then
		rm ./pipeline.json
	fi

	echo "$json_string" | jq >./pipeline.json

	az devops invoke --api-version "7.1-preview" --area "pipelinePermissions" --resource "pipelinePermissions" --http-method PATCH \
		--in-file ./pipeline.json --route-parameters project="$SYSTEM_TEAMPROJECTID" resource="pipelinePermissions" resourceType="queue" \
		resourceId="$queueId"
	if [ -f ./pipeline.json ]; then
		rm ./pipeline.json
	fi

done
exit 0
