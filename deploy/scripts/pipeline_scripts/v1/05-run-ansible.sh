#!/bin/bash
# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

green="\e[1;32m"
reset="\e[0m"
bold_red="\e[1;31m"


#External helper functions
full_script_path="$(realpath "${BASH_SOURCE[0]}")"
script_directory="$(dirname "${full_script_path}")"
parent_directory="$(dirname "$script_directory")"
grand_parent_directory="$(dirname "$parent_directory")"

SCRIPT_NAME="$(basename "$0")"

banner_title="Deploy SAP System"

#call stack has full script name when using source
# shellcheck disable=SC1091
source "${grand_parent_directory}/deploy_utils.sh"

#call stack has full script name when using source
source "${parent_directory}/helper.sh"

SCRIPT_NAME="$(basename "$0")"

banner_title="SAP Configuration and Installation - Ansible"

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

print_banner "$banner_title" "Starting $SCRIPT_NAME" "info"
#Stage could be executed on a different machine by default, need to login again for ansible
#If the deployer_file exists we run on a deployer configured by the framework instead of a azdo hosted one

# Set logon variables
if [ $USE_MSI == "true" ]; then
	unset ARM_CLIENT_SECRET
	ARM_USE_MSI=true
	export ARM_USE_MSI
fi

if [[ ! -f /etc/profile.d/deploy_server.sh ]]; then
	configureNonDeployer "${tf_version:-1.12.2}"
fi

if az account show --query name; then
	echo -e "$green--- Already logged in to Azure ---$reset"
else
	# Check if running on deployer
	echo -e "$green--- az login ---$reset"
	LogonToAzure $USE_MSI
	return_code=$?
	if [ 0 != $return_code ]; then
		echo -e "$bold_red--- Login failed ---$reset"
		echo "##vso[task.logissue type=error]az login failed."
		exit $return_code
	fi
fi

key_vault_id=$(az graph query -q "Resources | join kind=leftouter (ResourceContainers | where type=='microsoft.resources/subscriptions' | project subscription=name, subscriptionId) on subscriptionId | where name == '$VAULT_NAME' | project id, name, subscription" --query data[0].id --output tsv)
key_vault_subscription=$(echo "$key_vault_id" | cut -d '/' -f 3)

if [ -n "$key_vault_subscription" ]; then
	echo "##[section]Using Key Vault subscription: $key_vault_subscription"
else
	echo "##[error]Key Vault subscription not found for vault: $VAULT_NAME"
	exit 1
fi

set -eu

if [ ! -f "$PARAMETERS_FOLDER"/sshkey ]; then
	echo "##[section]Retrieving sshkey..."
	az keyvault secret show --name "$SSH_KEY_NAME" --vault-name "$VAULT_NAME" --subscription "$key_vault_subscription" --query value --output tsv >"$PARAMETERS_FOLDER/sshkey"
	sudo chmod 600 "$PARAMETERS_FOLDER"/sshkey
fi

password_secret=$(az keyvault secret show --name "$PASSWORD_KEY_NAME" --vault-name "$VAULT_NAME" --subscription "$key_vault_subscription" --query value --output tsv)
user_name=$(az keyvault secret show --name "$USERNAME_KEY_NAME" --vault-name "$VAULT_NAME" --subscription "$key_vault_subscription" --query value -o tsv)

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

az account set --subscription "$ARM_SUBSCRIPTION_ID" --output none

############################################################################################
#                                                                                          #
# Run Pre tasks if Ansible playbook with the correct naming exists                         #
#                                                                                          #
############################################################################################
filename=./config/Ansible/"${filename_without_prefix}"_pre.yml

if [ -f "${filename}" ]; then
	echo "##[group]- preconfiguration"

	redacted_command="ansible-playbook -i $INVENTORY -e @$SAP_PARAMS '$EXTRA_PARAMS' \
										$EXTRA_PARAM_FILE ${filename} -e 'kv_name=$VAULT_NAME'"
	echo "##[section]Executing [$redacted_command]..."

	command="ansible-playbook -i $INVENTORY --private-key $PARAMETERS_FOLDER/sshkey    \
						-e 'kv_name=$VAULT_NAME' -e @$SAP_PARAMS                                 \
						-e 'download_directory=$AGENT_TEMPDIRECTORY'                             \
						-e '_workspace_directory=$PARAMETERS_FOLDER' $EXTRA_PARAMS               \
						-e orchestration_ansible_user=$USER                                      \
						-e ansible_user=$user_name                                               \
						-e ansible_python_interpreter=/usr/bin/python3                          \
						-e ansible_ssh_pass='${ANSIBLE_PASSWORD}' $EXTRA_PARAM_FILE ${filename}"

	eval "${command}"
	return_code=$?
	echo "##[section]Ansible playbook ${filename} execution completed with exit code [$return_code]"
	echo "##[endgroup]"

fi

command="ansible-playbook -i $INVENTORY --private-key $PARAMETERS_FOLDER/sshkey       \
					-e 'kv_name=$VAULT_NAME' -e @$SAP_PARAMS                                    \
					-e 'download_directory=$AGENT_TEMPDIRECTORY'                                \
					-e '_workspace_directory=$PARAMETERS_FOLDER'                                \
					-e orchestration_ansible_user=$USER                                         \
  				-e ansible_user=$user_name                                                  \
					-e ansible_python_interpreter=/usr/bin/python3                              \
					-e ansible_ssh_pass='${ANSIBLE_PASSWORD}' $EXTRA_PARAMS $EXTRA_PARAM_FILE   \
          $ANSIBLE_FILE_PATH"

redacted_command="ansible-playbook -i $INVENTORY -e @$SAP_PARAMS $EXTRA_PARAMS        \
									$EXTRA_PARAM_FILE $ANSIBLE_FILE_PATH  -e 'kv_name=$VAULT_NAME'"

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
										'$EXTRA_PARAM_FILE' '${filename}'  -e 'kv_name=$VAULT_NAME'"
	echo "##[section]Executing [$redacted_command]..."

	command="ansible-playbook -i '$INVENTORY' --private-key '$PARAMETERS_FOLDER/sshkey'   \
						-e 'kv_name=$VAULT_NAME' -e @$SAP_PARAMS                                    \
						-e 'download_directory=$AGENT_TEMPDIRECTORY'                                \
						-e orchestration_ansible_user=$USER                                         \
  					-e ansible_user=$user_name                                                  \
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
