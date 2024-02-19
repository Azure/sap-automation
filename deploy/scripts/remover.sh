#!/bin/bash
#error codes include those from /usr/include/sysexits.h

#colors for terminal
boldreduscore="\e[1;4;31m"
boldred="\e[1;31m"
cyan="\e[1;36m"
resetformatting="\e[0m"

#External helper functions
#. "$(dirname "${BASH_SOURCE[0]}")/deploy_utils.sh"
full_script_path="$(realpath "${BASH_SOURCE[0]}")"
script_directory="$(dirname "${full_script_path}")"

#call stack has full scriptname when using source
source "${script_directory}/deploy_utils.sh"

#helper files
source "${script_directory}/helpers/script_helpers.sh"

#Internal helper functions
function showhelp {

    echo ""
    echo "#########################################################################################"
    echo "#                                                                                       #"
    echo -e "#                 $boldreduscore !Warning!: This script will remove deployed systems $resetformatting                 #"
    echo "#                                                                                       #"
    echo "#   This file contains the logic to remove the different systems                        #"
    echo "#   The script expects the following exports:                                           #"
    echo "#                                                                                       #"
    echo "#      SAP_AUTOMATION_REPO_PATH (path to the repo folder (sap-automation))                  #"
    echo "#      ARM_SUBSCRIPTION_ID (subscription containing the state file storage account)     #"
    echo "#      REMOTE_STATE_RG (resource group name for storage account containing state files) #"
    echo "#      REMOTE_STATE_SA (storage account for state file)                                 #"
    echo "#                                                                                       #"
    echo "#   The script will persist the parameters needed between the executions in the         #"
    echo "#   [CONFIG_REPO_PATH]/.sap_deployment_automation folder.                                                #"
    echo "#                                                                                       #"
    echo "#                                                                                       #"
    echo "#   Usage: remover.sh                                                                   #"
    echo "#    -p or --parameterfile           parameter file                                     #"
    echo "#    -t or --type                    type of system to remove                           #"
    echo "#                                         valid options:                                #"
    echo "#                                           sap_deployer                                #"
    echo "#                                           sap_library                                 #"
    echo "#                                           sap_landscape                               #"
    echo "#                                           sap_system                                  #"
    echo "#    -h or --help                    Show help                                          #"
    echo "#                                                                                       #"
    echo "#   Optional parameters                                                                 #"
    echo "#                                                                                       #"
    echo "#    -o or --storageaccountname      Storage account name for state file                #"
    echo "#    -s or --state_subscription      Subscription for tfstate storage account           #"
    echo "#                                                                                       #"
    echo "#   Example:                                                                            #"
    echo "#                                                                                       #"
    echo "#   [REPO-ROOT]deploy/scripts/remover.sh \                                              #"
    echo "#      --parameterfile DEV-WEEU-SAP01-X00.json \                                        #"
    echo "#      --type sap_system                                                                #"
    echo "#                                                                                       #"
    echo "#########################################################################################"
}

function missing {
    printf -v val %-.40s "$option"
    echo ""
    echo ""
    echo "#########################################################################################"
    echo "#                                                                                       #"
    echo "#   Missing environment variables: ${option}!!!              #"
    echo "#                                                                                       #"
    echo "#   Please export the folloing variables:                                               #"
    echo "#      SAP_AUTOMATION_REPO_PATH (path to the repo folder (sap-automation))                  #"
    echo "#      ARM_SUBSCRIPTION_ID (subscription containing the state file storage account)     #"
    echo "#                                                                                       #"
    echo "#########################################################################################"
}

#process inputs - may need to check the option i for auto approve as it is not used
INPUT_ARGUMENTS=$(getopt -n remover -o p:o:t:s:ahi --longoptions type:,parameterfile:,storageaccountname:,state_subscription:,ado,auto-approve,help -- "$@")
VALID_ARGUMENTS=$?

if [ "$VALID_ARGUMENTS" != "0" ]; then
    showhelp
fi

called_from_ado=0
eval set -- "$INPUT_ARGUMENTS"
while :
do
    case "$1" in
        -p | --parameterfile)                      parameterfile="$2"               ; shift 2 ;;
        -o | --storageaccountname)                 REMOTE_STATE_SA="$2"             ; shift 2 ;;
        -s | --state_subscription)                 STATE_SUBSCRIPTION="$2"          ; shift 2 ;;
        -t | --type)                               deployment_system="$2"           ; shift 2 ;;
        -i | --auto-approve)                       approve="--auto-approve"         ; shift ;;
        -a | --ado)                                called_from_ado=1                ; shift ;;
        -h | --help)                               showhelp
        exit 3                           ; shift ;;
        --) shift; break ;;
    esac
done

#variables
tfstate_resource_id=""
tfstate_parameter=""
deployer_tfstate_key=""
deployer_tfstate_key_parameter=""
landscape_tfstate_key=""
landscape_tfstate_key_parameter=""

# unused variables
#show_help=false
#deployer_tfstate_key_exists=false
#landscape_tfstate_key_exists=false
echo "parameterfile: $parameterfile"

working_directory=$(pwd)

parameterfile_path=$(realpath "${parameterfile}")
parameterfile_name=$(basename "${parameterfile_path}")
parameterfile_dirname=$(dirname "${parameterfile_path}")

if [ "${parameterfile_dirname}" != "${working_directory}" ]; then
    echo ""
    echo "#########################################################################################"
    echo "#                                                                                       #"
    echo -e "#  $boldred Please run this command from the folder containing the parameter file $resetformatting              #"
    echo "#                                                                                       #"
    echo "#########################################################################################"
    exit 3
fi

if [ ! -f "${parameterfile}" ]
then
    printf -v val %-35.35s "$parameterfile"
    echo ""
    echo "#########################################################################################"
    echo "#                                                                                       #"
    echo -e "#                 $boldred  Parameter file does not exist: ${val} $resetformatting #"
    echo "#                                                                                       #"
    echo "#########################################################################################"
    exit 2 #No such file or directory
fi


if [ -z "${deployment_system}" ]; then
    printf -v val %-40.40s "$deployment_system"
    echo "#########################################################################################"
    echo "#                                                                                       #"
    echo -e "# $boldred Incorrect system deployment type specified: ${val} $resetformatting #"
    echo "#                                                                                       #"
    echo "#     Valid options are:                                                                #"
    echo "#       sap_deployer                                                                    #"
    echo "#       sap_library                                                                     #"
    echo "#       sap_landscape                                                                   #"
    echo "#       sap_system                                                                      #"
    echo "#                                                                                       #"
    echo "#########################################################################################"
    echo ""
    exit 64 #script usage wrong
fi

# Check that the exports ARM_SUBSCRIPTION_ID and SAP_AUTOMATION_REPO_PATH are defined
validate_exports
return_code=$?
if [ 0 != $return_code ]; then
    exit $return_code
fi

# Check that Terraform and Azure CLI is installed
validate_dependencies
return_code=$?
if [ 0 != $return_code ]; then
    exit $return_code
fi

# Check that parameter files have environment and location defined
validate_key_parameters "$parameterfile_name"
return_code=$?
if [ 0 != $return_code ]; then
    exit $return_code
fi

if valid_region_name "${region}" ; then
    # Convert the region to the correct code
    get_region_code ${region}
else
    echo "Invalid region: $region"
    exit 2
fi

this_ip=$(curl -s ipinfo.io/ip) >/dev/null 2>&1

echo "Deployer environment: $deployer_environment"

this_ip=$(curl -s ipinfo.io/ip) >/dev/null 2>&1
export TF_VAR_Agent_IP=$this_ip
echo "Agent IP: $this_ip"

automation_config_directory=$CONFIG_REPO_PATH/.sap_deployment_automation
generic_config_information="${automation_config_directory}"/config

system_config_information="${automation_config_directory}"/"${environment}""${region_code}"

if [ "${deployment_system}" == sap_landscape ]; then
    load_config_vars "$parameterfile_name" "network_logical_name"
    network_logical_name=$(echo "${network_logical_name}" | tr "[:lower:]" "[:upper:]")

    system_config_information="${automation_config_directory}"/"${environment}""${region_code}""${network_logical_name}"
fi

if [ "${deployment_system}" == sap_system ]; then
    load_config_vars "$parameterfile_name" "network_logical_name"
    network_logical_name=$(echo "${network_logical_name}" | tr "[:lower:]" "[:upper:]")

    system_config_information="${automation_config_directory}"/"${environment}""${region_code}""${network_logical_name}"
fi

echo "Configuration file: $system_config_information"
echo "Deployment region: $region"
echo "Deployment region code: $region_code"

key=$(echo "${parameterfile_name}" | cut -d. -f1)

#Plugins
if [ ! -d /opt/terraform/.terraform.d/plugin-cache ]
then
    mkdir /opt/terraform/.terraform.d/plugin-cache
fi
export TF_PLUGIN_CACHE_DIR=/opt/terraform/.terraform.d/plugin-cache


init "${automation_config_directory}" "${generic_config_information}" "${system_config_information}"
var_file="${parameterfile_dirname}"/"${parameterfile}"
if [ -z "$REMOTE_STATE_SA" ];
then
    load_config_vars "${system_config_information}" "REMOTE_STATE_SA"
    load_config_vars "${system_config_information}" "REMOTE_STATE_RG"
    load_config_vars "${system_config_information}" "tfstate_resource_id"
    load_config_vars "${system_config_information}" "STATE_SUBSCRIPTION"
else
    save_config_vars "${system_config_information}" REMOTE_STATE_SA
    get_and_store_sa_details ${REMOTE_STATE_SA} "${system_config_information}"
    load_config_vars "${system_config_information}" "STATE_SUBSCRIPTION"
    load_config_vars "${system_config_information}" "REMOTE_STATE_RG"
    load_config_vars "${system_config_information}" "tfstate_resource_id"
fi

load_config_vars "${system_config_information}" "deployer_tfstate_key"
load_config_vars "${system_config_information}" "landscape_tfstate_key"
load_config_vars "${system_config_information}" "ARM_SUBSCRIPTION_ID"

deployer_tfstate_key_parameter=''
if [ "${deployment_system}" != sap_deployer ]; then
    deployer_tfstate_key_parameter=" -var deployer_tfstate_key=${deployer_tfstate_key}"
fi

landscape_tfstate_key_parameter=''
if [ "${deployment_system}" == sap_system ]; then
    landscape_tfstate_key_parameter=" -var landscape_tfstate_key=${landscape_tfstate_key}"
fi

tfstate_parameter=" -var tfstate_resource_id=${tfstate_resource_id}"

#setting the user environment variables
set_executing_user_environment_variables "none"

if [ -n "${STATE_SUBSCRIPTION}" ]; then
    az account set --sub "${STATE_SUBSCRIPTION}"
fi

export TF_DATA_DIR="${parameterfile_dirname}"/.terraform

terraform_module_directory="${SAP_AUTOMATION_REPO_PATH}"/deploy/terraform/run/"${deployment_system}"/

if [ ! -d "${terraform_module_directory}" ]; then
    printf -v val %-40.40s "$deployment_system"
    echo "#########################################################################################"
    echo "#                                                                                       #"
    echo -e "#  $boldred Incorrect system deployment type specified: ${val} $resetformatting#"
    echo "#                                                                                       #"
    echo "#     Valid options are:                                                                #"
    echo "#       sap_deployer                                                                    #"
    echo "#       sap_library                                                                     #"
    echo "#       sap_landscape                                                                   #"
    echo "#       sap_system                                                                      #"
    echo "#                                                                                       #"
    echo "#########################################################################################"
    echo ""
    exit 66 #cannot open input file/folder
fi

#ok_to_proceed=false
#new_deployment=false

if [ -f backend.tf ]; then
    rm backend.tf
fi

echo ""
echo "#########################################################################################"
echo "#                                                                                       #"
echo -e "#                            $cyan Running Terraform init $resetformatting                                   #"
echo "#                                                                                       #"
echo "#########################################################################################"
echo ""

terraform -chdir="${terraform_module_directory}" init  -reconfigure \
--backend-config "subscription_id=${STATE_SUBSCRIPTION}"          \
--backend-config "resource_group_name=${REMOTE_STATE_RG}"         \
--backend-config "storage_account_name=${REMOTE_STATE_SA}"        \
--backend-config "container_name=tfstate"                         \
--backend-config "key=${key}.terraform.tfstate" || {
    echo "Terraform init failed"
    exit 1
}



created_resource_group_id=$(terraform -chdir="${terraform_module_directory}" output -no-color -raw created_resource_group_id | tr -d \")
created_resource_group_id_length=$(expr length "$created_resource_group_id")
created_resource_group_subscription_id=$(terraform -chdir="${terraform_module_directory}" output -no-color -raw created_resource_group_subscription_id | tr -d \")
created_resource_group_subscription_id_length=$(expr length "$created_resource_group_subscription_id")

if [ "${created_resource_group_id_length}" -eq 0 ] && [ "${created_resource_group_subscription_id_length}" -eq 0 ]; then
    resource_group_exist=$(az group exists --name "${created_resource_group_id}" --subscription "${created_resource_group_subscription_id}")
else
    resource_group_exist=true
fi

if [ $resource_group_exist ];
then
    echo ""
    echo "#########################################################################################"
    echo "#                                                                                       #"
    echo -e "#                            $cyan Running Terraform destroy$resetformatting                                 #"
    echo "#                                                                                       #"
    echo "#########################################################################################"
    echo ""

    if [ "$deployment_system" == "sap_deployer" ]; then
        terraform -chdir="${terraform_bootstrap_directory}" refresh -var-file="${var_file}" \
        $deployer_tfstate_key_parameter

        echo -e "#$cyan processing $deployment_system removal as defined in $parameterfile_name $resetformatting"
        terraform -chdir="${terraform_module_directory}" destroy -var-file="${var_file}" \
        $deployer_tfstate_key_parameter

        elif [ "$deployment_system" == "sap_library" ]; then
        echo -e "#$cyan processing $deployment_system removal as defined in $parameterfile_name $resetformatting"

        terraform_bootstrap_directory="${SAP_AUTOMATION_REPO_PATH}/deploy/terraform/bootstrap/${deployment_system}/"
        if [ ! -d "${terraform_bootstrap_directory}" ]; then
            printf -v val %-40.40s "$terraform_bootstrap_directory"
            echo "#########################################################################################"
            echo "#                                                                                       #"
            echo -e "#  $boldred Unable to find bootstrap directory: ${val}$resetformatting#"
            echo "#                                                                                       #"
            echo "#########################################################################################"
            echo ""
            exit 66 #cannot open input file/folder
        fi
        terraform -chdir="${terraform_bootstrap_directory}" init -upgrade=true -force-copy

        terraform -chdir="${terraform_bootstrap_directory}" refresh -var-file="${var_file}" \
        $landscape_tfstate_key_parameter \
        $deployer_tfstate_key_parameter

        terraform -chdir="${terraform_bootstrap_directory}" destroy -var-file="${var_file}" ${approve} \
        $landscape_tfstate_key_parameter \
        $deployer_tfstate_key_parameter
    else

        echo -e "#$cyan processing $deployment_system removal as defined in $parameterfile_name $resetformatting"
        echo $tfstate_parameter $landscape_tfstate_key_parameter $deployer_tfstate_key_parameter
        if [ -n "${approve}" ]
        then

            terraform -chdir="${terraform_module_directory}" destroy -var-file="${var_file}" ${approve} \
                $tfstate_parameter \
                $landscape_tfstate_key_parameter \
                $deployer_tfstate_key_parameter  -json  | tee -a  destroy_output.json
        else
            terraform -chdir="${terraform_module_directory}" destroy -var-file="${var_file}" ${approve} \
                $tfstate_parameter \
                $landscape_tfstate_key_parameter \
                $deployer_tfstate_key_parameter

        fi

        return_value=$?

        if [ -f destroy_output.json ]
        then
            errors_occurred=$(jq 'select(."@level" == "error") | length' destroy_output.json)

            if [[ -n $errors_occurred ]]
            then
                echo ""
                echo "#########################################################################################"
                echo "#                                                                                       #"
                echo -e "#                         $boldreduscore!Errors during the destroy phase!$resetformatting                             #"

                return_value=2
                all_errors=$(jq 'select(."@level" == "error") | {summary: .diagnostic.summary, detail: .diagnostic.detail}' destroy_output.json)
                if [[ -n ${all_errors} ]]
                then
                    readarray -t errors_strings < <(echo ${all_errors} | jq -c '.' )
                    for errors_string in "${errors_strings[@]}"; do
                        string_to_report=$(jq -c -r '.detail '  <<< "$errors_string" )
                        if [[ -z ${string_to_report} ]]
                        then
                            string_to_report=$(jq -c -r '.summary '  <<< "$errors_string" )
                        fi

                        report=$(echo $string_to_report | grep -m1 "Message=" "${var_file}" | cut -d'=' -f2-  | tr -d ' ' | tr -d '"')
                        if [[ -n ${report} ]] ; then
                            echo -e "#                          $boldreduscore  $report $resetformatting"
                            echo "##vso[task.logissue type=error]${report}"
                        else
                            echo -e "#                          $boldreduscore  $string_to_report $resetformatting"
                            echo "##vso[task.logissue type=error]${string_to_report}"
                        fi


                    done

                fi
                echo "#                                                                                       #"
                echo "#########################################################################################"
                echo ""

            fi

        fi

        if [ -f destroy_output.json ]
        then
            rm destroy_output.json
        fi

    fi


else
    return_value=0
fi


if [ "${deployment_system}" == sap_deployer ]; then
    sed -i /deployer_tfstate_key/d "${system_config_information}"
fi

if [ "${deployment_system}" == sap_landscape ]; then
    rm "${system_config_information}"
fi

if [ "${deployment_system}" == sap_library ]; then
    sed -i /REMOTE_STATE_RG/d "${system_config_information}"
    sed -i /REMOTE_STATE_SA/d "${system_config_information}"
    sed -i /tfstate_resource_id/d "${system_config_information}"
fi

# if [ "${deployment_system}" == sap_system ]; then

#     echo "#########################################################################################"
#     echo "#                                                                                       #"
#     echo -e "#                            $cyan Clean up load balancer IP $resetformatting        #"
#     echo "#                                                                                       #"
#     echo "#########################################################################################"

#     database_loadbalancer_public_ip_address=$(terraform -chdir="${terraform_module_directory}" output -no-color database_loadbalancer_ip | tr -d "\n"  | tr -d "("  | tr -d ")" | tr -d " ")
#     database_loadbalancer_public_ip_address=$(echo ${database_loadbalancer_public_ip_address/tolist/})
#     database_loadbalancer_public_ip_address=$(echo ${database_loadbalancer_public_ip_address/,]/]})
#     echo "Database Load Balancer IP: $database_loadbalancer_public_ip_address"

#     load_config_vars "${parameterfile_name}" "database_loadbalancer_ips"
#     database_loadbalancer_ips=$(echo ${database_loadbalancer_ips} | xargs)

#     if [[ "${database_loadbalancer_public_ip_address}" != "${database_loadbalancer_ips}" ]];
#     then
#       database_loadbalancer_ips=${database_loadbalancer_public_ip_address}
#       save_config_var "database_loadbalancer_ips" "${parameterfile_name}"
#     fi

#     scs_loadbalancer_public_ip_address=$(terraform -chdir="${terraform_module_directory}" output -no-color scs_loadbalancer_ips | tr -d "\n"  | tr -d "("  | tr -d ")" | tr -d " ")
#     scs_loadbalancer_public_ip_address=$(echo ${scs_loadbalancer_public_ip_address/tolist/})
#     scs_loadbalancer_public_ip_address=$(echo ${scs_loadbalancer_public_ip_address/,]/]})
#     echo "SCS Load Balancer IP: $scs_loadbalancer_public_ip_address"

#     load_config_vars "${parameterfile_name}" "scs_server_loadbalancer_ips"
#     scs_server_loadbalancer_ips=$(echo ${scs_server_loadbalancer_ips} | xargs)

#     if [[ "${scs_loadbalancer_public_ip_address}" != "${scs_server_loadbalancer_ips}" ]];
#     then
#       scs_server_loadbalancer_ips=${scs_loadbalancer_public_ip_address}
#       save_config_var "scs_server_loadbalancer_ips" "${parameterfile_name}"
#     fi
# fi

unset TF_DATA_DIR

exit $return_value
