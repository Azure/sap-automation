#!/bin/bash

# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

export PATH=/opt/terraform/bin:/opt/ansible/bin:${PATH}

cmd_dir="$(dirname "$(readlink -e "${BASH_SOURCE[0]}")")"
source "${cmd_dir}/script_helper.sh"

#         # /*---------------------------------------------------------------------------8
#         # |                                                                            |
#         # |                     Quality Assurance Playbook Wrapper                     |
#         # |                                                                            |
#         # |  Prepares the controller with roles-misc/0.10-sap-automation-qa and then    |
#         # |  runs the selected Azure/sap-automation-qa playbook against the current     |
#         # |  SAP system directory.                                                      |
#         # |                                                                            |
#         # +------------------------------------4--------------------------------------*/

sap_params_file=sap-parameters.yaml

if [[ ! -e "${sap_params_file}" ]]; then
	print_banner "Quality Assurance" "SAP parameters file '${sap_params_file}' not found!" "error" "Current directory '$(basename "$(pwd)")'"
	exit 1
fi

sap_sid="$(awk '$1 == "sap_sid:" {print $2}' ${sap_params_file})"
workload_vault_name="$(awk '$1 == "kv_name:" {print $2}' ${sap_params_file})"
prefix="$(awk '$1 == "secret_prefix:" {print $2}' ${sap_params_file})"

if [[ -z "${sap_sid}" ]]; then
	print_banner "Quality Assurance" "Variable 'sap_sid' not found in '${sap_params_file}'!" "error"
	exit 1
fi

if [[ -z "${workload_vault_name}" ]]; then
	print_banner "Quality Assurance" "Variable 'kv_name' not found in '${sap_params_file}'!" "error"
	exit 1
fi

if [[ -z "${prefix}" ]]; then
	print_banner "Quality Assurance" "Variable 'secret_prefix' not found in '${sap_params_file}'!" "error"
	exit 1
fi

if ! az account show --output none 2>/dev/null; then
	print_banner "Quality Assurance" "Not logged in to Azure!" "error" "Run 'az login' before starting this wrapper"
	exit 1
fi

password_secret_name=$prefix-sid-password
ANSIBLE_PASSWORD=$(az keyvault secret show --vault-name "${workload_vault_name}" --name "${password_secret_name}" --query value --output tsv)
export ANSIBLE_PASSWORD

workspace_directory="$(pwd)"
qa_directory="${QA_DIRECTORY:-/opt/microsoft/sap_automation_qa}"
orchestration_user="${ORCHESTRATION_ANSIBLE_USER:-${USER:-$(id -un)}}"
qa_log_path="${workspace_directory}/logs/execution_$(date +%Y%m%d_%H%M%S).log"

export ANSIBLE_HOST_KEY_CHECKING=False
export ANSIBLE_INVENTORY="${sap_sid%$'\r'}_hosts.yaml"
export ANSIBLE_PRIVATE_KEY_FILE=sshkey
export ANSIBLE_REMOTE_USER=$USER
export ANSIBLE_PYTHON_INTERPRETER=auto_silent
export ANSIBLE_DISPLAY_SKIPPED_HOSTS=false

# Selectable options list; keep the order consistent with the test_types,
# functional_types and qa_playbooks arrays defined below.
PS3='Please select the quality assurance run: '

options=(
	"Configuration checks"
	"Database high availability functional tests"
	"Central services high availability functional tests"
	"Azure Backup database functional tests"
	"Database high availability offline tests"
	"Central services high availability offline tests"
	"Quit"
)

test_types=(
	"ConfigurationChecks"
	"SAPFunctionalTests"
	"SAPFunctionalTests"
	"SAPFunctionalTests"
	"SAPFunctionalTests"
	"SAPFunctionalTests"
)

functional_types=(
	""
	"DatabaseHighAvailability"
	"CentralServicesHighAvailability"
	"AzureBackupDatabase"
	"DatabaseHighAvailability"
	"CentralServicesHighAvailability"
)

qa_playbooks=(
	"playbook_00_configuration_checks"
	"playbook_00_ha_db_functional_tests"
	"playbook_00_ha_scs_functional_tests"
	"playbook_00_backup_db_functional_tests"
	"playbook_01_ha_offline_tests"
	"playbook_01_ha_offline_tests"
)

select opt in "${options[@]}"; do
	if [[ "${opt}" == "${options[-1]}" ]]; then
		exit 0
	fi

	if ! [[ "${REPLY}" =~ ^[0-9]{1,2}$ ]]; then
		echo "Invalid selection: Not a number!"
		continue
	elif ((REPLY > ${#qa_playbooks[@]} || REPLY < 1)); then
		echo "Invalid selection: Must be in range of available options!"
		continue
	fi

	echo "You selected (${REPLY}) ${opt}"

	test_type="${test_types[$((REPLY - 1))]}"
	functional_test_type="${functional_types[$((REPLY - 1))]}"
	qa_playbook="${qa_playbooks[$((REPLY - 1))]}"
	break
done

setup_parameters=(
	--extra-vars="_workspace_directory=${workspace_directory}"
	--extra-vars="@${workspace_directory}/${sap_params_file}"
	--extra-vars="sap_automation_qa_test_type=${test_type}"
	--extra-vars="sap_automation_qa_directory=${qa_directory}"
	--extra-vars="sap_automation_qa_system_directory=${workspace_directory}"
	--extra-vars="SAP_FUNCTIONAL_TEST_TYPE=${functional_test_type}"
	--extra-vars="sap_automation_qa_test_groups=${TEST_GROUPS:-}"
	--extra-vars="sap_automation_qa_test_cases=${TEST_CASES:-}"
	--extra-vars="orchestration_ansible_user=${orchestration_user}"
	"${@}"
)

print_banner "Quality Assurance" "Retrieving the SAP system SSH key" "info" "Key Vault '${workload_vault_name}'"

ANSIBLE_CONFIG="${cmd_dir}/ansible.cfg" \
	ANSIBLE_COLLECTIONS_PATH="/opt/ansible/collections:${ANSIBLE_COLLECTIONS_PATH:-}" \
	ANSIBLE_LOOKUP_PLUGINS="${cmd_dir}/lookup_plugins:${ANSIBLE_LOOKUP_PLUGINS:-}" \
	${DEBUG:+echo} ansible-playbook \
	--extra-vars="_workspace_directory=${workspace_directory}" \
	"${cmd_dir}/pb_get-sshkey.yaml"
return_value=$?

if [[ ${return_value} -ne 0 ]]; then
	print_banner "Quality Assurance" "Failed to retrieve the SAP system SSH key" "error" "Return code ${return_value}"
	exit ${return_value}
fi

print_banner "Quality Assurance" "Preparing the quality assurance framework" "info" "Test type '${test_type}'"

ANSIBLE_CONFIG="${cmd_dir}/ansible.cfg" \
	ANSIBLE_COLLECTIONS_PATH="/opt/ansible/collections:${ANSIBLE_COLLECTIONS_PATH:-}" \
	ANSIBLE_LOOKUP_PLUGINS="${cmd_dir}/lookup_plugins:${ANSIBLE_LOOKUP_PLUGINS:-}" \
	${DEBUG:+echo} ansible-playbook \
	"${setup_parameters[@]}" \
	"${cmd_dir}/playbook_06_03_00_sap_functional_tests.yaml"
return_value=$?

if [[ ${return_value} -ne 0 ]]; then
	print_banner "Quality Assurance" "Preparation failed" "error" "Return code ${return_value}"
	rm -f -- "${workspace_directory}/sshkey"
	exit ${return_value}
fi

execution_parameters=(
	--inventory-file="${ANSIBLE_INVENTORY}"
	--private-key="${ANSIBLE_PRIVATE_KEY_FILE}"
	--extra-vars="_workspace_directory=${workspace_directory}"
	--extra-vars="@${workspace_directory}/${sap_params_file}"
	--extra-vars="@${workspace_directory}/artifacts/qa_test_selection.json"
	-e ansible_ssh_pass='{{ lookup("env", "ANSIBLE_PASSWORD") }}'
)

if [[ -n "${ARM_CLIENT_ID:-}" ]]; then
	execution_parameters+=(--extra-vars="user_assigned_identity_client_id=${ARM_CLIENT_ID}")
fi

execution_parameters+=("${@}")

print_banner "Quality Assurance" "Executing '${qa_playbook}.yml'" "info" "Results in '${workspace_directory}/quality_assurance'"

ANSIBLE_CONFIG="${qa_directory}/src/ansible.cfg" \
	ANSIBLE_LIBRARY="${qa_directory}/src/modules" \
	ANSIBLE_MODULE_UTILS="${qa_directory}/src/module_utils" \
	ANSIBLE_COLLECTIONS_PATH="${qa_directory}/.ansible/collections:${HOME}/.ansible/collections:/opt/ansible/collections" \
	ANSIBLE_LOG_PATH="${qa_log_path}" \
	${DEBUG:+echo} ansible-playbook \
	"${execution_parameters[@]}" \
	"${qa_directory}/src/${qa_playbook}.yml"
return_value=$?

rm -f -- "${workspace_directory}/sshkey"

if [[ ${return_value} -ne 0 ]]; then
	print_banner "Quality Assurance" "Playbook '${qa_playbook}.yml' failed" "error" "Return code ${return_value}"
else
	print_banner "Quality Assurance" "Playbook '${qa_playbook}.yml' completed successfully" "success" "Log '${qa_log_path}'"
fi

exit ${return_value}
