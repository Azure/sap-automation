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
parent_directory="$(dirname "$script_directory")"

SCRIPT_NAME="$(basename "$0")"

banner_title="SAP Configuration and Installation - Ansible"

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
#Stage could be executed on a different machine by default, need to login again for ansible
#If the deployer_file exists we run on a deployer configured by the framework instead of a azdo hosted one

if is_valid_id "$APPLICATION_CONFIGURATION_ID" "/providers/Microsoft.AppConfiguration/configurationStores/"; then

	control_plane_subscription=$(getVariableFromApplicationConfiguration "$APPLICATION_CONFIGURATION_ID" "${CONTROL_PLANE_NAME}_SubscriptionId" "${CONTROL_PLANE_NAME}")

fi
export control_plane_subscription


vault_name=$(echo "${VAULT_NAME}" | tr [:upper:] [:lower:] | xargs)

az account set --subscription "$AZURE_SUBSCRIPTION_ID" --output none

set -eu

if [ ! -f "$PARAMETERS_FOLDER"/sshkey ]; then
	echo "##[section]Retrieving sshkey..."
	az keyvault secret show --name "$SSH_KEY_NAME" --vault-name "$vault_name" --subscription "$control_plane_subscription" --query value --output tsv >"$PARAMETERS_FOLDER/sshkey"
	sudo chmod 600 "$PARAMETERS_FOLDER"/sshkey
fi

password_secret=$(az keyvault secret show --name "$PASSWORD_KEY_NAME" --vault-name "$vault_name" --query value --output tsv)
ANSIBLE_PASSWORD="${password_secret}"
export ANSIBLE_PASSWORD

echo "Extra parameters passed: $EXTRA_PARAMS"

base=$(basename "$ANSIBLE_FILE_PATH")

filename_without_prefix=$(echo "$base" | awk -F'.' '{print $1}')
return_code=0

echo "Extra parameters passed: $EXTRA_PARAMS"
echo "Check for file: ${filename_without_prefix}"

command="ansible --version"
eval "${command}"

EXTRA_PARAM_FILE=""

if [ -f "$PARAMETERS_FOLDER/extra-params.yaml" ]; then
	echo "Extra parameter file passed: $PARAMETERS_FOLDER/extra-params.yaml"

	EXTRA_PARAM_FILE="-e @$PARAMETERS_FOLDER/extra-params.yaml"
fi

############################################################################################
#                                                                                          #
# Run Pre tasks if Ansible playbook with the correct naming exists                         #
#                                                                                          #
############################################################################################
filename=./config/Ansible/"${filename_without_prefix}"_pre.yml

if [ -f "${filename}" ]; then
	echo "##[group]- preconfiguration"

	redacted_command="ansible-playbook -i $INVENTORY -e @$SAP_PARAMS '$EXTRA_PARAMS' \
										$EXTRA_PARAM_FILE ${filename} -e 'kv_name=$vault_name'"
	echo "##[section]Executing [$redacted_command]..."

	command="ansible-playbook -i $INVENTORY --private-key $PARAMETERS_FOLDER/sshkey    \
						-e 'kv_name=$vault_name' -e @$SAP_PARAMS                                 \
						-e 'download_directory=$AGENT_TEMPDIRECTORY'                             \
						-e '_workspace_directory=$PARAMETERS_FOLDER' $EXTRA_PARAMS               \
            -e ansible_ssh_pass='${ANSIBLE_PASSWORD}' $EXTRA_PARAM_FILE ${filename}"

	eval "${command}"
	return_code=$?
	echo "##[section]Ansible playbook ${filename} execution completed with exit code [$return_code]"
	echo "##[endgroup]"

fi

command="ansible-playbook -i $INVENTORY --private-key $PARAMETERS_FOLDER/sshkey       \
					-e 'kv_name=$vault_name' -e @$SAP_PARAMS                                    \
					-e 'download_directory=$AGENT_TEMPDIRECTORY'                                \
					-e '_workspace_directory=$PARAMETERS_FOLDER'                                \
					-e ansible_ssh_pass='${ANSIBLE_PASSWORD}' $EXTRA_PARAMS $EXTRA_PARAM_FILE   \
          $ANSIBLE_FILE_PATH"

redacted_command="ansible-playbook -i $INVENTORY -e @$SAP_PARAMS $EXTRA_PARAMS        \
									$EXTRA_PARAM_FILE $ANSIBLE_FILE_PATH  -e 'kv_name=$vault_name'"

echo "##[section]Executing [$command]..."
echo "##[group]- output"
eval "${command}"
return_code=$?
echo "##[section]Ansible playbook execution completed with exit code [$return_code]"
echo "##[endgroup]"

############################################################################################
#                                                                                          #
# Run Post tasks if Ansible playbook with the correct naming exists                        #
#                                                                                          #
############################################################################################

filename=./config/Ansible/"${filename_without_prefix}"_post.yml
echo "Check for file: ${filename}"

if [ -f "${filename}" ]; then

	echo "##[group]- postconfiguration"
	redacted_command="ansible-playbook -i '$INVENTORY' -e @'$SAP_PARAMS' $EXTRA_PARAMS    \
										'$EXTRA_PARAM_FILE' '${filename}'  -e 'kv_name=$vault_name'"
	echo "##[section]Executing [$redacted_command]..."

	command="ansible-playbook -i '$INVENTORY' --private-key '$PARAMETERS_FOLDER/sshkey'   \
						-e 'kv_name=$vault_name' -e @$SAP_PARAMS                                    \
						-e 'download_directory=$AGENT_TEMPDIRECTORY'                                \
						-e '_workspace_directory=$PARAMETERS_FOLDER'                                \
						-e ansible_ssh_pass='${ANSIBLE_PASSWORD}' '${filename}' $EXTRA_PARAMS       \
						$EXTRA_PARAM_FILE"

	eval "${command}"
	return_code=$?
	echo "##[section]Ansible playbook ${filename} execution completed with exit code [$return_code]"
	echo "##[endgroup]"

fi

print_banner "$banner_title" "Exiting $SCRIPT_NAME" "info"

exit $return_code
