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

echo "##vso[build.updatebuildnumber]SAP Configuration and Installation"

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
	configureNonDeployer "${tf_version:-1.13.3}"
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

cd $SAP_PARAMS || exit

if [ ! -v SSH_KEY_NAME ]; then
	SSH_KEY_NAME="${WORKLOAD_ZONE_NAME}-sid-sshkey"
else
  if [ -z "$SSH_KEY_NAME" ]; then
		SSH_KEY_NAME="${WORKLOAD_ZONE_NAME}-sid-sshkey"
	fi
fi

if [ ! -v PASSWORD_KEY_NAME ]; then
	PASSWORD_KEY_NAME="${WORKLOAD_ZONE_NAME}-sid-password"
else
  if [ -z "$PASSWORD_KEY_NAME" ]; then
		PASSWORD_KEY_NAME="${WORKLOAD_ZONE_NAME}-sid-password"
	fi
fi

if [ ! -v USERNAME_KEY_NAME ]; then
	USERNAME_KEY_NAME="${WORKLOAD_ZONE_NAME}-sid-username"
else
  if [ -z "$USERNAME_KEY_NAME" ]; then
		USERNAME_KEY_NAME="${WORKLOAD_ZONE_NAME}-sid-username"
	fi
fi


if [ ! -f "$SSH_KEY_NAME" ]; then
	echo "##[section]Retrieving sshkey..."
	az keyvault secret show --name "$SSH_KEY_NAME" --vault-name "$key_vault_name" --subscription "$key_vault_subscription" --query value --output tsv > "$SSH_KEY_NAME"
	if [ -f "$SSH_KEY_NAME" ]; then
		sudo chmod 600 "$SSH_KEY_NAME"
	fi
else
	echo "##[section]SSH key already exists, skipping retrieval."
	sudo chmod 600 "$SSH_KEY_NAME"
	ls -lart
fi

password_secret=$(az keyvault secret show --name "$PASSWORD_KEY_NAME" --vault-name "$key_vault_name" --subscription "$key_vault_subscription" --query value --output tsv)
user_name=$(az keyvault secret show --name "$USERNAME_KEY_NAME" --vault-name "$key_vault_name" --subscription "$key_vault_subscription" --query value -o tsv)

ANSIBLE_PASSWORD="${password_secret}"
export ANSIBLE_PASSWORD

base=$(basename "$ANSIBLE_FILE_PATH")

filename_without_prefix=$(echo "$base" | awk -F'.' '{print $1}')
return_code=0

if [ -n "$EXTRA_PARAMS" ]; then
	echo "Extra parameters passed: $EXTRA_PARAMS"
fi

command="ansible --version"
eval "${command}"

EXTRA_PARAM_FILE=""

if [ -f "$SAP_PARAMS/extra-params.yaml" ]; then
	echo "Extra parameter file passed: $SAP_PARAMS/extra-params.yaml"
	EXTRA_PARAM_FILE="-e @$SAP_PARAMS/extra-params.yaml"
fi

az account set --subscription "$ARM_SUBSCRIPTION_ID" --output none

tfstate_resource_id=$(az graph query -q "Resources | join kind=leftouter (ResourceContainers | where type=='microsoft.resources/subscriptions' | project subscription=name, subscriptionId) on subscriptionId | where name == '$TERRAFORM_REMOTE_STORAGE_ACCOUNT_NAME' | project id, name, subscription" --query data[0].id --output tsv)
control_plane_subscription=$(echo "$tfstate_resource_id" | cut -d '/' -f 3)

export control_plane_subscription
if [ -f "$SAP_PARAMS/extra-params.yaml" ]; then
	echo "Extra parameter file passed: $SAP_PARAMS/extra-params.yaml"
	EXTRA_PARAM_FILE="-e @$SAP_PARAMS/extra-params.yaml"
fi

############################################################################################
#                                                                                          #
# Run Pre tasks if Ansible playbook with the correct naming exists                         #
#                                                                                          #
############################################################################################
filename=./config/Ansible/"${filename_without_prefix}"_pre.yml

echo "Check if file: ${filename} exists"

if [ -f "${filename}" ]; then
	echo "##[group]- preconfiguration"

	redacted_command="ansible-playbook -i '$INVENTORY' --private-key $SAP_PARAMS/$SSH_KEY_NAME -e 'kv_name=$VAULT_NAME' -e 'download_directory=$AGENT_TEMPDIRECTORY' -e '_workspace_directory=$curdir' $EXTRA_PARAMS -e orchestration_ansible_user=$USER -e ansible_user=$user_name -e ansible_python_interpreter=/usr/bin/python3 -e @$SAP_PARAMS $EXTRA_PARAM_FILE	${filename}"

	echo "##[section]Executing [$redacted_command]..."

	command="ansible-playbook -i '$INVENTORY'                                    \
	              --private-key $SAP_PARAMS/$SSH_KEY_NAME                        \
								-e 'kv_name=$VAULT_NAME'                                       \
								-e 'download_directory=$AGENT_TEMPDIRECTORY'                   \
								-e '_workspace_directory=$curdir' $EXTRA_PARAMS                \
								-e orchestration_ansible_user=$USER                            \
								-e ansible_user=$user_name                                     \
								-e ansible_python_interpreter=/usr/bin/python3                 \
    						-e ansible_ssh_pass='{{ lookup("env", "ANSIBLE_PASSWORD") }}'  \
		      			-e @$SAP_PARAMS $EXTRA_PARAM_FILE	${filename}"

	eval "${command}"
	return_code=$?
	echo "##[section]Ansible playbook ${filename} execution completed with exit code [$return_code]"
	echo "##[endgroup]"

fi

command="ansible-playbook -i '$INVENTORY'                                      \
	              --private-key $SAP_PARAMS/$SSH_KEY_NAME                        \
								-e 'kv_name=$VAULT_NAME'                                       \
								-e 'download_directory=$AGENT_TEMPDIRECTORY'                   \
								-e '_workspace_directory=$curdir' $EXTRA_PARAMS                \
								-e orchestration_ansible_user=$USER                            \
								-e ansible_user=$user_name                                     \
								-e ansible_python_interpreter=/usr/bin/python3                 \
    						-e ansible_ssh_pass='{{ lookup("env", "ANSIBLE_PASSWORD") }}'  \
		      			-e @$SAP_PARAMS $EXTRA_PARAM_FILE	${ANSIBLE_FILE_PATH}	"

redacted_command="ansible-playbook -i '$INVENTORY' --private-key $SSH_KEY_NAME -e 'kv_name=$VAULT_NAME' -e 'download_directory=$AGENT_TEMPDIRECTORY' -e '_workspace_directory=$curdir' $EXTRA_PARAMS -e orchestration_ansible_user=$USER -e ansible_user=$user_name -e ansible_python_interpreter=/usr/bin/python3 -e @$SAP_PARAMS $EXTRA_PARAM_FILE	${ANSIBLE_FILE_PATH}"

echo "##[section]Executing [$command]..."
echo "##[group]- configuration"
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
echo "Check if file: ${filename} exists"

if [ -f "${filename}" ]; then

	echo "##[group]- postconfiguration"
	redacted_command="ansible-playbook -i '$INVENTORY' --private-key $SSH_KEY_NAME -e 'kv_name=$VAULT_NAME' -e 'download_directory=$AGENT_TEMPDIRECTORY' -e '_workspace_directory=$curdir' $EXTRA_PARAMS -e orchestration_ansible_user=$USER -e ansible_user=$user_name -e @$SAP_PARAMS $EXTRA_PARAM_FILE	${filename}"
	echo "##[section]Executing [$redacted_command]..."

	command="ansible-playbook -i '$INVENTORY'                                    \
	              --private-key $SAP_PARAMS/$SSH_KEY_NAME                        \
								-e 'kv_name=$VAULT_NAME'                                       \
								-e 'download_directory=$AGENT_TEMPDIRECTORY'                   \
								-e '_workspace_directory=$curdir' $EXTRA_PARAMS                \
								-e orchestration_ansible_user=$USER                            \
								-e ansible_user=$user_name                                     \
								-e ansible_python_interpreter=/usr/bin/python3                 \
    						-e ansible_ssh_pass='{{ lookup("env", "ANSIBLE_PASSWORD") }}'  \
		      			-e @$SAP_PARAMS $EXTRA_PARAM_FILE	${filename}"

	eval "${command}"
	return_code=$?
	echo "##[section]Ansible playbook ${filename} execution completed with exit code [$return_code]"
	echo "##[endgroup]"

fi

print_banner "$banner_title" "Exiting $SCRIPT_NAME" "info"

exit $return_code
