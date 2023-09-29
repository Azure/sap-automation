#!/bin/bash

export PATH=/opt/terraform/bin:/opt/ansible/bin:${PATH}

cmd_dir="$(dirname "$(readlink -e "${BASH_SOURCE[0]}")")"


#         # /*---------------------------------------------------------------------------8
#         # |                                                                            |
#         # |                             Playbook Wrapper                               |
#         # |                                                                            |
#         # +------------------------------------4--------------------------------------*/
#
#         export           ANSIBLE_HOST_KEY_CHECKING=False
#         # export OBJC_DISABLE_INITIALIZE_FORK_SAFETY=Yes
#         # export           ANSIBLE_KEEP_REMOTE_FILES=1
#
# Example of complete run execution:
#
#         ansible-playbook                                                                \
#           --inventory   X00-hosts.yaml                                                  \
#           --user        azureadm                                                        \
#           --private-key sshkey                                                          \
#           --extra-vars="@sap-parameters.yaml"                                           \
#           playbook_00_transition_start_for_sap_install.yaml                             \
#           playbook_01_os_base_config.yaml                                               \
#           playbook_02_os_sap_specific_config.yaml                                       \
#           playbook_03_bom_processing.yaml                                               \
#           playbook_04_00_00_hana_db_install.yaml                                        \
#           playbook_05_00_00_sap_scs_install.yaml                                        \
#           playbook_05_01_sap_dbload.yaml                                                \
#           playbook_05_02_sap_pas_install.yaml                                           \
#           playbook_05_03_sap_app_install.yaml                                           \
#           playbook_05_04_sap_web_install.yaml

# The SAP System parameters file which should exist in the current directory
sap_params_file=sap-parameters.yaml

if [[ ! -e "${sap_params_file}" ]]; then
        echo "Error: '${sap_params_file}' file not found!"
        exit 1
fi

#
# Ansible configuration settings.
#
# For more details please run `ansible-config list` and search for the
# entry associated with the specific setting.
#
export           ANSIBLE_HOST_KEY_CHECKING=False
export           ANSIBLE_COLLECTIONS_PATHS=/opt/ansible/collections${ANSIBLE_COLLECTIONS_PATHS:+${ANSIBLE_COLLECTIONS_PATHS}}

# We really should be determining the user dynamically, or requiring
# that it be specified in the inventory settings (currently true)
export           ANSIBLE_REMOTE_USER=azureadm

# Ref: https://docs.ansible.com/ansible/2.9/reference_appendices/interpreter_discovery.html
# Silence warnings about Python interpreter discovery
export           ANSIBLE_PYTHON_INTERPRETER=auto_silent

# Ref: https://docs.ansible.com/ansible/2.9/plugins/callback/default.html
# Don't show skipped tasks
# export           ANSIBLE_DISPLAY_SKIPPED_HOSTS=no                         # Hides current running task until completed

# Ref: https://docs.ansible.com/ansible/2.9/plugins/callback/profile_tasks.html
# Commented out defaults below
#export          PROFILE_TASKS_TASK_OUTPUT_LIMIT=20
#export          PROFILE_TASKS_SORT_ORDER=descending


# Don't show the skipped hosts
export ANSIBLE_DISPLAY_SKIPPED_HOSTS=false

# NOTE: In the short term, keep any modifications to the above in sync with
# ../terraform/terraform-units/modules/sap_system/output_files/ansible.cfg.tmpl


# Select command prompt
PS3='Please select playbook: '

# Selectable options list; please keep the order of the initial
# playbook related entries consistent with the ordering of the
# all_playbooks array defined below
options=(

        # Special menu entries
        "BOM Downloader"
        "Quit"
)

# List of all possible playbooks
all_playbooks=(
        ${cmd_dir}/playbook_bom_downloader.yaml
)

# Set of options that will be passed to the ansible-playbook command
playbook_options=(
        --private-key=${ANSIBLE_PRIVATE_KEY_FILE}
        --extra-vars="_workspace_directory=`pwd`"
        --extra-vars="@${sap_params_file}"
        --extra-vars="bom_processing=true"
        "${@}"
)

select opt in "${options[@]}";
do
        echo "You selected ($REPLY) $opt"

        case $opt in
        "${options[-1]}")   # Quit
                break;;
        *)
                # If not a numeric reply
                if ! [[ "${REPLY}" =~ ^[0-9]{1,2}$ ]]; then
                        echo "Invalid selection: Not a number!"
                        continue
                elif (( (REPLY > ${#all_playbooks[@]}) || (REPLY < 1) )); then
                        echo "Invalid selection: Must be in range of available options!"
                        continue
                fi
                playbooks+=( "${all_playbooks[$(( REPLY - 1 ))]}" );;
        esac

        # NOTE: If you set DEBUG to a non-empty value in your environment
        # the following line will cause the ansible-playbook command to be
        # echoed rather than executed.
        ${DEBUG:+echo} \
        ansible-playbook "${playbook_options[@]}" "${playbooks[@]}"

        break
done

