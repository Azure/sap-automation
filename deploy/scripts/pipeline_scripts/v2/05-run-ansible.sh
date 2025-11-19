#!/bin/bash
# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

# Source the shared platform configuration
SCRIPT_DIR="$(dirname "${BASH_SOURCE[0]}")"
source "${SCRIPT_DIR}/shared_platform_config.sh"
source "${SCRIPT_DIR}/shared_functions.sh"
source "${SCRIPT_DIR}/set-colors.sh"

SCRIPT_NAME="$(basename "$0")"

# Set platform-specific output
if [ "$PLATFORM" == "devops" ]; then
	echo "##vso[build.updatebuildnumber]SAP Configuration and Installation"
fi

# External helper functions
#. "$(dirname "${BASH_SOURCE[0]}")/deploy_utils.sh"
full_script_path="$(realpath "${BASH_SOURCE[0]}")"
script_directory="$(dirname "${full_script_path}")"
parent_directory="$(dirname "$script_directory")"
grand_parent_directory="$(dirname "$parent_directory")"
#call stack has full script name when using source
# shellcheck disable=SC1091
source "${grand_parent_directory}/deploy_utils.sh"
source "${parent_directory}/helper.sh"

SCRIPT_NAME="$(basename "$0")"

banner_title="SAP Configuration and Installation - Ansible"

# Print the execution environment details
print_header
echo ""

# Platform-specific configuration
if [ "$PLATFORM" == "devops" ]; then
	DEBUG=false

	if [ "${SYSTEM_DEBUG:-False}" = True ]; then
		set -x
		DEBUG=True
		echo "Environment variables:"
		printenv | sort

	fi
	export DEBUG
	set -eu
	# Configure DevOps
	configure_devops

	platform_flag="--ado"

	if ! get_variable_group_id "$VARIABLE_GROUP" "VARIABLE_GROUP_ID"; then
		echo -e "$bold_red--- Variable group $VARIABLE_GROUP not found ---$reset"
		echo "##vso[task.logissue type=error]Variable group $VARIABLE_GROUP not found."
		exit 2
	fi
	export VARIABLE_GROUP_ID
elif [ "$PLATFORM" == "github" ]; then
	# No specific variable group setup for GitHub Actions
	# Values will be stored in GitHub Environment variables
	echo "Configuring for GitHub Actions"
	export VARIABLE_GROUP_ID="${WORKLOAD_ZONE_NAME}"
	git config --global --add safe.directory "$CONFIG_REPO_PATH"
	platform_flag="--github"
else
	platform_flag=""
fi

print_banner "$banner_title" "Starting $SCRIPT_NAME" "info"
#Stage could be executed on a different machine by default, need to login again for ansible
#If the deployer_file exists we run on a deployer configured by the framework instead of a azdo hosted one

if [[ ! -f /etc/profile.d/deploy_server.sh ]]; then
	configureNonDeployer "${tf_version:-1.13.3}"
fi
if [ "$PLATFORM" == "devops" ]; then
	# Set logon variables
	if [ $USE_MSI == "true" ]; then
		unset ARM_CLIENT_SECRET
		ARM_USE_MSI=true
		export ARM_USE_MSI
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
fi

tfstate_resource_id=$(getVariableFromApplicationConfiguration "$APPLICATION_CONFIGURATION_ID" "${CONTROL_PLANE_NAME}_TerraformRemoteStateStorageAccountId" "${CONTROL_PLANE_NAME}")
control_plane_subscription=$(echo "$tfstate_resource_id" | cut -d '/' -f 3)

export control_plane_subscription

key_vault_id=$(getVariableFromApplicationConfiguration "$APPLICATION_CONFIGURATION_ID" "${WORKLOAD_ZONE_NAME}_KeyVaultResourceId" "${WORKLOAD_ZONE_NAME}")
key_vault_subscription=$(echo "$key_vault_id" | cut -d '/' -f 3)
key_vault_name=$(echo "$key_vault_id" | cut -d '/' -f 9)


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

az account set --subscription "$key_vault_subscription" --output none

if [ -n "$key_vault_subscription" ]; then
	echo "##[section]Using Key Vault subscription: $key_vault_subscription"
else
	echo "##[error]Key Vault subscription not found for vault: $key_vault_name"
	exit 1
fi

set -eu

curdir=$(dirname "$SAP_PARAMS")

cd "$curdir" || exit
echo "SSH Key name: $SSH_KEY_NAME"

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

if [ -f "$curdir/extra-params.yaml" ]; then
	echo "Extra parameter file passed: $curdir/extra-params.yaml"
	EXTRA_PARAM_FILE="-e @$curdir/extra-params.yaml"
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

	redacted_command="ansible-playbook -i '$INVENTORY' --private-key $curdir/$SSH_KEY_NAME -e 'kv_name=$VAULT_NAME' -e 'download_directory=$AGENT_TEMPDIRECTORY' -e '_workspace_directory=$curdir' $EXTRA_PARAMS -e orchestration_ansible_user=${USER:-$user_name} -e ansible_user=$user_name -e ansible_python_interpreter=/usr/bin/python3 -e @$curdir $EXTRA_PARAM_FILE	${filename}"

	echo "##[section]Executing [$redacted_command]..."

	command="ansible-playbook -i '$INVENTORY'                                \
	              --private-key $curdir/$SSH_KEY_NAME                        \
								-e 'kv_name=$VAULT_NAME'                                   \
								-e 'download_directory=$AGENT_TEMPDIRECTORY'               \
								-e '_workspace_directory=$curdir' $EXTRA_PARAMS            \
							  -e orchestration_ansible_user=${USER:-$user_name}          \
								-e ansible_user=$user_name                                 \
								-e ansible_python_interpreter=/usr/bin/python3             \
    						-e ansible_ssh_pass='${ANSIBLE_PASSWORD}' -e @$SAP_PARAMS  \
		      			$EXTRA_PARAM_FILE	${filename}"

	eval "${command}"
	return_code=$?
	echo "##[section]Ansible playbook ${filename} execution completed with exit code [$return_code]"
	echo "##[endgroup]"

fi

command="ansible-playbook -i '$INVENTORY'                                  \
	              --private-key $curdir/$SSH_KEY_NAME                        \
								-e 'kv_name=$VAULT_NAME'                                   \
								-e 'download_directory=$AGENT_TEMPDIRECTORY'               \
								-e '_workspace_directory=$curdir' $EXTRA_PARAMS            \
								-e orchestration_ansible_user=${USER:-$user_name}          \
								-e ansible_user=$user_name                                 \
								-e ansible_python_interpreter=/usr/bin/python3             \
    						-e ansible_ssh_pass='${ANSIBLE_PASSWORD}' -e @$SAP_PARAMS  \
					      $EXTRA_PARAM_FILE	${ANSIBLE_FILE_PATH}	"

redacted_command="ansible-playbook -i '$INVENTORY' --private-key $SAP_PARAMS/artifacts/$SSH_KEY_NAME -e 'kv_name=$VAULT_NAME' -e 'download_directory=$AGENT_TEMPDIRECTORY' -e '_workspace_directory=$SAP_PARAMS' $EXTRA_PARAMS -e orchestration_ansible_user=${USER:-$user_name} -e ansible_user=$user_name -e ansible_python_interpreter=/usr/bin/python3 -e @$SAP_PARAMS $EXTRA_PARAM_FILE	${ANSIBLE_FILE_PATH}"

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
	redacted_command="ansible-playbook -i '$INVENTORY' --private-key $SAP_PARAMS/artifacts/$SSH_KEY_NAME -e 'kv_name=$VAULT_NAME' -e 'download_directory=$AGENT_TEMPDIRECTORY' -e '_workspace_directory=$SAP_PARAMS' $EXTRA_PARAMS -e orchestration_ansible_user=${USER:-$user_name} -e ansible_user=$user_name -e ansible_python_interpreter=/usr/bin/python3 -e @$SAP_PARAMS $EXTRA_PARAM_FILE	${filename}"
	echo "##[section]Executing [$redacted_command]..."

	command="ansible-playbook -i '$INVENTORY'                                \
	              --private-key $curdir/$SSH_KEY_NAME                        \
								-e 'kv_name=$VAULT_NAME'                                   \
								-e 'download_directory=$AGENT_TEMPDIRECTORY'               \
								-e '_workspace_directory=$curdir' $EXTRA_PARAMS            \
								-e orchestration_ansible_user=${USER:-$user_name}          \
								-e ansible_user=$user_name                                 \
								-e ansible_python_interpreter=/usr/bin/python3             \
    						-e ansible_ssh_pass='${ANSIBLE_PASSWORD}' -e @$SAP_PARAMS  \
								$EXTRA_PARAM_FILE	${filename}"

	eval "${command}"
	return_code=$?
	echo "##[section]Ansible playbook ${filename} execution completed with exit code [$return_code]"
	echo "##[endgroup]"

fi

print_banner "$banner_title" "Exiting $SCRIPT_NAME" "info"

exit $return_code
