#!/bin/bash
# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

# Exit immediately if a command exits with a non-zero status.
# Treat unset variables as an error when substituting.
if [ "$DEBUG" = True ]; then
	cyan="\e[1;36m"
	reset_formatting="\e[0m"
	echo -e "$cyanEnabling debug mode$reset_formatting"
	set -x
	set -o errexit
fi
#Stage could be executed on a different machine by default, need to login again for ansible
#If the deployer_file exists we run on a deployer configured by the framework instead of a azdo hosted one
control_plane_subscription=$CONTROL_PLANE_SUBSCRIPTION_ID
export control_plane_subscription

deployer_file=/etc/profile.d/deploy_server.sh

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
	if [[ ! -f /etc/profile.d/deploy_server.sh ]]; then
		configureNonDeployer "${tf_version:-1.12.2}"
		echo -e "$green--- az login ---$reset"
		LogonToAzure $USE_MSI
	else
		LogonToAzure $USE_MSI
	fi
	return_code=$?
	if [ 0 != $return_code ]; then
		echo -e "$bold_red--- Login failed ---$reset"
		echo "##vso[task.logissue type=error]az login failed."
		exit $return_code
	fi
fi

set -eu

if [ ! -f $PARAMETERS_FOLDER/sshkey ]; then
	echo "##[section]Retrieving sshkey..."
	az keyvault secret show --name "$SSH_KEY_NAME" --vault-name "$VAULT_NAME" --subscription "$CONTROL_PLANE_SUBSCRIPTION_ID" --query value --output tsv >"$PARAMETERS_FOLDER/sshkey"
	sudo chmod 600 "$PARAMETERS_FOLDER"/sshkey
fi

password_secret=$(az keyvault secret show --name "$PASSWORD_KEY_NAME" --vault-name "$VAULT_NAME" --query value --output tsv)

echo "Extra parameters passed: " "$EXTRA_PARAMS"

base=$(basename "$ANSIBLE_FILE_PATH")

filename_without_prefix=$(echo "$base" | awk -F'.' '{print $1}')
filename=./config/Ansible/"${filename_without_prefix}"_pre.yml
return_code=0

echo "Extra parameters passed: " $EXTRA_PARAMS
echo "Check for file: ${filename}"

command="ansible --version"
eval $command

EXTRA_PARAM_FILE=""

if [ -f $PARAMETERS_FOLDER/extra-params.yaml ]; then
	echo "Extra parameter file passed: " $PARAMETERS_FOLDER/extra-params.yaml

	EXTRA_PARAM_FILE="-e @$PARAMETERS_FOLDER/extra-params.yaml"
fi

############################################################################################
#                                                                                          #
# Run Pre tasks if Ansible playbook with the correct naming exists                         #
#                                                                                          #
############################################################################################

if [ -f "${filename}" ]; then
	echo "##[group]- preconfiguration"

	redacted_command="ansible-playbook -i $INVENTORY -e @$SAP_PARAMS "$EXTRA_PARAMS" $EXTRA_PARAM_FILE ${filename} -e 'kv_name=$VAULT_NAME'"
	echo "##[section]Executing [$redacted_command]..."

	command="ansible-playbook -i $INVENTORY --private-key $PARAMETERS_FOLDER/sshkey  -e 'kv_name=$VAULT_NAME' \
            -e @$SAP_PARAMS -e 'download_directory=$AGENT_TEMPDIRECTORY' -e '_workspace_directory=$PARAMETERS_FOLDER' "$EXTRA_PARAMS"  \
						-e orchestration_ansible_user=$USER \
            -e ansible_ssh_pass='${password_secret}' $EXTRA_PARAM_FILE ${filename}"

	eval $command
	return_code=$?
	echo "##[section]Ansible playbook ${filename} execution completed with exit code [$return_code]"
	echo "##[endgroup]"

fi

command="ansible-playbook -i $INVENTORY --private-key $PARAMETERS_FOLDER/sshkey   -e 'kv_name=$VAULT_NAME'   \
      -e @$SAP_PARAMS -e 'download_directory=$AGENT_TEMPDIRECTORY' -e '_workspace_directory=$PARAMETERS_FOLDER' \
      -e ansible_ssh_pass='${password_secret}' "$EXTRA_PARAMS" $EXTRA_PARAM_FILE                                  \
			-e orchestration_ansible_user=$USER \
       $ANSIBLE_FILE_PATH"

redacted_command="ansible-playbook -i $INVENTORY -e @$SAP_PARAMS "$EXTRA_PARAMS" $EXTRA_PARAM_FILE $ANSIBLE_FILE_PATH  -e 'kv_name=$VAULT_NAME'"

echo "##[section]Executing [$redacted_command]..."
echo "##[group]- output"
eval $command
return_code=$?
echo "##[section]Ansible playbook execution completed with exit code [$return_code]"
echo "##[endgroup]"

filename=./config/Ansible/"${filename_without_prefix}"_post.yml
echo "Check for file: ${filename}"

############################################################################################
#                                                                                          #
# Run Post tasks if Ansible playbook with the correct naming exists                        #
#                                                                                          #
############################################################################################

if [ -f ${filename} ]; then

	echo "##[group]- postconfiguration"
	redacted_command="ansible-playbook -i "$INVENTORY" -e @"$SAP_PARAMS" "$EXTRA_PARAMS" $EXTRA_PARAM_FILE "${filename}"  -e 'kv_name=$VAULT_NAME'"
	echo "##[section]Executing [$redacted_command]..."

	command="ansible-playbook -i "$INVENTORY" --private-key $PARAMETERS_FOLDER/sshkey   -e 'kv_name=$VAULT_NAME'      \
            -e @$SAP_PARAMS -e 'download_directory=$AGENT_TEMPDIRECTORY' -e '_workspace_directory=$PARAMETERS_FOLDER' \
						-e orchestration_ansible_user=$USER \
            -e ansible_ssh_pass='${password_secret}' ${filename}  "$EXTRA_PARAMS" $EXTRA_PARAM_FILE"

	eval $command
	return_code=$?
	echo "##[section]Ansible playbook ${filename} execution completed with exit code [$return_code]"
	echo "##[endgroup]"

fi

exit $return_code
