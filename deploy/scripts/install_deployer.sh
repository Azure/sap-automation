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
    echo "#                                                                                       #"
    echo "#   This file contains the logic to deploy the deployer.                                #"
    echo "#   The script experts the following exports:                                           #"
    echo "#                                                                                       #"
    echo "#     ARM_SUBSCRIPTION_ID to specify which subscription to deploy to                    #"
    echo "#     SAP_AUTOMATION_REPO_PATH the path to the folder containing the cloned sap-automation        #"
    echo "#                                                                                       #"
    echo "#   The script will persist the parameters needed between the executions in the         #"
    echo "#   [CONFIG_REPO_PATH]/.sap_deployment_automation folder                                #"
    echo "#                                                                                       #"
    echo "#                                                                                       #"
    echo "#   Usage: install_deployer.sh                                                          #"
    echo "#    -p deployer parameter file                                                         #"
    echo "#                                                                                       #"
    echo "#    -i interactive true/false setting the value to false will not prompt before apply  #"
    echo "#    -h Show help                                                                       #"
    echo "#                                                                                       #"
    echo "#   Example:                                                                            #"
    echo "#                                                                                       #"
    echo "#   [REPO-ROOT]deploy/scripts/install_deployer.sh \                                     #"
    echo "#      -p PROD-WEEU-DEP00-INFRASTRUCTURE.json \                                         #"
    echo "#      -i true                                                                          #"
    echo "#                                                                                       #"
    echo "#########################################################################################"
}


#process inputs - may need to check the option i for auto approve as it is not used
INPUT_ARGUMENTS=$(getopt -n install_deployer -o p:ih --longoptions parameterfile:,auto-approve,help -- "$@")
VALID_ARGUMENTS=$?

if [ "$VALID_ARGUMENTS" != "0" ]; then
    showhelp

fi

eval set -- "$INPUT_ARGUMENTS"
while :
do
    case "$1" in
        -p | --parameterfile)                      parameterfile="$2"               ; shift 2 ;;
        -i | --auto-approve)                       approve="--auto-approve"         ; shift ;;
        -h | --help)                               showhelp
        exit 3                           ; shift ;;
        --) shift; break ;;
    esac
done

deployment_system=sap_deployer

param_dirname=$(dirname "${parameterfile}")

echo "Parameter file: "${parameterfile}""

if [ ! -f "${parameterfile}" ]
then
    printf -v val %-40.40s "$parameterfile"
    echo ""
    echo "#########################################################################################"
    echo "#                                                                                       #"
    echo "#               Parameter file does not exist: ${val} #"
    echo "#                                                                                       #"
    echo "#########################################################################################"
    exit 2 #No such file or directory
fi

if [ "$param_dirname" != '.' ]; then
    echo ""
    echo "#########################################################################################"
    echo "#                                                                                       #"
    echo "#   Please run this command from the folder containing the parameter file               #"
    echo "#                                                                                       #"
    echo "#########################################################################################"
    exit 3
fi


# Check that parameter files have environment and location defined
validate_key_parameters "$parameterfile"
return_code=$?
if [ 0 != $return_code ]; then
    exit $return_code
fi

region=$(echo "${region}" | tr "[:upper:]" "[:lower:]")
# Convert the region to the correct code
get_region_code $region


key=$(echo "${parameterfile}" | cut -d. -f1)

#Persisting the parameters across executions
automation_config_directory=$CONFIG_REPO_PATH/.sap_deployment_automation/
generic_config_information="${automation_config_directory}"config
deployer_config_information="${automation_config_directory}""${environment}""${region_code}"

arm_config_stored=false
config_stored=false

param_dirname=$(pwd)

init "${automation_config_directory}" "${generic_config_information}" "${deployer_config_information}"

var_file="${param_dirname}"/"${parameterfile}"
# Check that the exports ARM_SUBSCRIPTION_ID and SAP_AUTOMATION_REPO_PATH are defined
validate_exports
return_code=$?
if [ 0 != $return_code ]; then
    exit $return_code
fi

terraform_module_directory="${SAP_AUTOMATION_REPO_PATH}"/deploy/terraform/bootstrap/"${deployment_system}"/
export TF_DATA_DIR="${param_dirname}"/.terraform

this_ip=$(curl -s ipinfo.io/ip) >/dev/null 2>&1
export TF_VAR_Agent_IP=$this_ip
echo "Agent IP: $this_ip"


ok_to_proceed=false
new_deployment=false

# Check that Terraform and Azure CLI is installed
validate_dependencies
return_code=$?
if [ 0 != $return_code ]; then
    exit $return_code
fi

if [ ! -d ./.terraform/ ]; then
    echo "#########################################################################################"
    echo "#                                                                                       #"
    echo "#                                   New deployment                                      #"
    echo "#                                                                                       #"
    echo "#########################################################################################"
    terraform -chdir="${terraform_module_directory}" init -backend-config "path=${param_dirname}/terraform.tfstate"
else
    if [ -f ./.terraform/terraform.tfstate ]; then
        if grep "azurerm" ./.terraform/terraform.tfstate ; then
            echo "#########################################################################################"
            echo "#                                                                                       #"
            echo "#                     The state is already migrated to Azure!!!                         #"
            echo "#                                                                                       #"
            echo "#########################################################################################"
            sed -i /"use_microsoft_graph"/d "${param_dirname}/.terraform/terraform.tfstate"
            if [ $approve == "--auto-approve" ] ; then
              tfstate_resource_id=$(az resource list --name $REINSTALL_ACCOUNTNAME --subscription $REINSTALL_SUBSCRIPTION --resource-type Microsoft.Storage/storageAccounts --query "[].id | [0]" -o tsv)
              if [ -n "${tfstate_resource_id}" ]; then
                  echo "Reinitializing against remote state"
                  export TF_VAR_tfstate_resource_id=$tfstate_resource_id

                  terraform_module_directory="${SAP_AUTOMATION_REPO_PATH}"/deploy/terraform/run/"${deployment_system}"/
                  terraform -chdir="${terraform_module_directory}" init -upgrade=true     \
                  --backend-config "subscription_id=$REINSTALL_SUBSCRIPTION"              \
                  --backend-config "resource_group_name=$REINSTALL_RESOURCE_GROUP"        \
                  --backend-config "storage_account_name=$REINSTALL_ACCOUNTNAME"          \
                  --backend-config "container_name=tfstate"                               \
                  --backend-config "key=${key}.terraform.tfstate"
                terraform -chdir="${terraform_module_directory}" refresh -var-file="${var_file}"

              else
                terraform -chdir="${terraform_module_directory}" init -force-copy -migrate-state  --backend-config "path=${param_dirname}/terraform.tfstate"
                terraform -chdir="${terraform_module_directory}" init -reconfigure  --backend-config "path=${param_dirname}/terraform.tfstate"
                terraform -chdir="${terraform_module_directory}" refresh -var-file="${var_file}"
              fi
            else
                read -p "Do you want to bootstrap the deployer again Y/N?"  ans
                answer=${ans^^}
                if [ $answer == 'Y' ]; then
                    terraform -chdir="${terraform_module_directory}" init -upgrade=true  -backend-config "path=${param_dirname}/terraform.tfstate"
                    terraform -chdir="${terraform_module_directory}" refresh -var-file="${var_file}"
                else
                    unset TF_DATA_DIR
                    exit 0
                fi
            fi
        else
            terraform -chdir="${terraform_module_directory}" init -upgrade=true -backend-config "path=${param_dirname}/terraform.tfstate"
        fi
    else
        terraform -chdir="${terraform_module_directory}" init -upgrade=true -backend-config "path=${param_dirname}/terraform.tfstate"
    fi
fi

extra_vars=""

if [ -f terraform.tfvars ]; then
    extra_vars=" -var-file=${param_dirname}/terraform.tfvars "
fi

terraform -chdir="${terraform_module_directory}"  refresh -var-file="${var_file}" $extra_vars


echo ""
echo "#########################################################################################"
echo "#                                                                                       #"
echo "#                             Running Terraform plan                                    #"
echo "#                                                                                       #"
echo "#########################################################################################"
echo ""

terraform -chdir="${terraform_module_directory}"  plan  -detailed-exitcode -var-file="${var_file}" $extra_vars | tee -a plan_output.log

return_value=$?
if [ 1 == $return_value ]
then
    echo ""
    echo "#########################################################################################"
    echo "#                                                                                       #"
    echo -e "#                             $boldreduscore Errors during the plan phase $resetformatting                              #"
    echo "#                                                                                       #"
    echo "#########################################################################################"
    echo ""
    if [ -f plan_output.log ]
    then
        cat plan_output.log
        rm plan_output.log
    fi
    unset TF_DATA_DIR
    exit $return_value
fi

if [ -f plan_output.log ]; then
    rm plan_output.log
fi

echo ""
echo "#########################################################################################"
echo "#                                                                                       #"
echo "#                             Running Terraform apply                                   #"
echo "#                                                                                       #"
echo "#########################################################################################"
echo ""

parallelism=10

#Provide a way to limit the number of parallell tasks for Terraform
if [[ -n "${TF_PARALLELLISM}" ]]; then
    parallelism=$TF_PARALLELLISM
fi
if [ -n "${approve}" ]
then
  terraform -chdir="${terraform_module_directory}"  apply ${approve} -parallelism="${parallelism}" -var-file="${var_file}" $extra_vars -json | tee -a  apply_output.json
else
  terraform -chdir="${terraform_module_directory}"  apply ${approve} -parallelism="${parallelism}" -var-file="${var_file}" $extra_vars
fi
return_value=$?

rerun_apply=0
if [ -f apply_output.json ]
then
    errors_occurred=$(jq 'select(."@level" == "error") | length' apply_output.json)
    # Check for resource that can be imported
    existing=$(jq 'select(."@level" == "error") | {address: .diagnostic.address, summary: .diagnostic.summary}  | select(.summary | startswith("A resource with the ID"))' apply_output.json)
    if [[ -n ${existing} ]]
    then

        readarray -t existing_resources < <(echo ${existing} | jq -c '.' )
        for item in "${existing_resources[@]}"; do
          moduleID=$(jq -c -r '.address '  <<< "$item")
          resourceID=$(jq -c -r '.summary' <<< "$item" | awk -F'\"' '{print $2}')
          echo "Trying to import" $resourceID "into" $moduleID

          echo terraform -chdir="${terraform_module_directory}" import -var-file="${var_file}" $extra_vars $moduleID $resourceID
          terraform -chdir="${terraform_module_directory}" import -var-file="${var_file}" $extra_vars $moduleID $resourceID
        done
        rerun_apply=1
    fi
    if [ -f apply_output.json ]
    then
        rm apply_output.json
    fi

    if [ $rerun_apply == 1 ] ; then
        echo ""
        echo "#########################################################################################"
        echo "#                                                                                       #"
        echo "#                          Re-running Terraform apply                                   #"
        echo "#                                                                                       #"
        echo "#########################################################################################"
        echo ""
        terraform -chdir="${terraform_module_directory}"  apply ${approve} -parallelism="${parallelism}" -var-file="${var_file}" $extra_vars -json | tee -a  apply_output.json
        return_value=$?
        rerun_apply=0
    fi

    if [ -f apply_output.json ]
    then
        return_value=$?
        errors_occurred=$(jq 'select(."@level" == "error") | length' apply_output.json)
        # Check for resource that can be imported
        existing=$(jq 'select(."@level" == "error") | {address: .diagnostic.address, summary: .diagnostic.summary}  | select(.summary | startswith("A resource with the ID"))' apply_output.json)
        if [[ -n ${existing} ]]
        then

            readarray -t existing_resources < <(echo ${existing} | jq -c '.' )
            for item in "${existing_resources[@]}"; do
              moduleID=$(jq -c -r '.address '  <<< "$item")
              resourceID=$(jq -c -r '.summary' <<< "$item" | awk -F'\"' '{print $2}')
              echo "Trying to import" $resourceID "into" $moduleID

              echo terraform -chdir="${terraform_module_directory}" import -var-file="${var_file}" $extra_vars $moduleID $resourceID
              terraform -chdir="${terraform_module_directory}" import -var-file="${var_file}" $extra_vars $moduleID $resourceID
            done
            rerun_apply=1
        fi
        if [ -f apply_output.json ]
        then
            rm apply_output.json
        fi

        if [ $rerun_apply == 1 ] ; then
            echo ""
            echo "#########################################################################################"
            echo "#                                                                                       #"
            echo "#                          Re-running Terraform apply                                   #"
            echo "#                                                                                       #"
            echo "#########################################################################################"
            echo ""
            terraform -chdir="${terraform_module_directory}"  apply ${approve} -parallelism="${parallelism}" -var-file="${var_file}" $extra_vars -json | tee -a  apply_output.json
            return_value=$?
        fi

        return_value=$?
        errors_occurred=$(jq 'select(."@level" == "error") | length' apply_output.json)
        if [ -f apply_output.json ]
        then

          if [[ -n $errors_occurred ]]
          then
            echo ""
            echo "#########################################################################################"
            echo "#                                                                                       #"
            echo -e "#                          $boldreduscore!Errors during the apply phase!$resetformatting                              #"

            return_value=2
            all_errors=$(jq 'select(."@level" == "error") | {summary: .diagnostic.summary, detail: .diagnostic.detail}' apply_output.json)
            if [[ -n ${all_errors} ]]
            then
                readarray -t errors_strings < <(echo ${all_errors} | jq -c '.' )
                for errors_string in "${errors_strings[@]}"; do
                    string_to_report=$(jq -c -r '.detail '  <<< "$errors_string" )
                    if [[ -z ${string_to_report} ]]
                    then
                        string_to_report=$(jq -c -r '.summary '  <<< "$errors_string" )
                    fi

                    echo -e "#                          $boldreduscore  $string_to_report $resetformatting"
                    echo "##vso[task.logissue type=error]${string_to_report}"

                done

            fi
            echo "#                                                                                       #"
            echo "#########################################################################################"
            echo ""

          fi
        fi

    fi

    if [ -f apply_output.json ]
    then
        rm apply_output.json
    fi
fi

keyvault=$(terraform -chdir="${terraform_module_directory}"  output deployer_kv_user_name | tr -d \")
temp=$(echo "${keyvault}" | grep "Warning")
if [ -z "${temp}" ]
then
    temp=$(echo "${keyvault}" | grep "Backend reinitialization required")
    if [ -z "${temp}" ]
    then
        touch "${deployer_config_information}"
        printf -v val %-.20s "$keyvault"

        echo ""
        echo "#########################################################################################"
        echo "#                                                                                       #"
        echo -e "#                Keyvault to use for SPN details:$cyan $val $resetformatting                 #"
        echo "#                                                                                       #"
        echo "#########################################################################################"
        echo ""

        save_config_var "keyvault" "${deployer_config_information}"
        return_value=0
    else
        return_value=2
    fi
fi

sshsecret=$(terraform -chdir="${terraform_module_directory}"  output -no-color -raw deployer_sshkey_secret_name | tr -d \")
if [ -n "${sshsecret}" ]
then
    save_config_var "sshsecret" "${deployer_config_information}"
    return_value=0
fi

random_id=$(terraform -chdir="${terraform_module_directory}"  output -no-color -raw random_id_b64 | tr -d \")
if [ -n "${random_id}" ]
then
    deployer_random_id="${random_id}"
    save_config_var "deployer_random_id" "${deployer_config_information}"
    return_value=0
fi

deployer_public_ip_address=$(terraform -chdir="${terraform_module_directory}"  output -no-color -raw deployer_public_ip_address | tr -d \")
if [ -n "${deployer_public_ip_address}" ]
then
    save_config_var "deployer_public_ip_address" "${deployer_config_information}"
    return_value=0
fi


unset TF_DATA_DIR

exit $return_value
