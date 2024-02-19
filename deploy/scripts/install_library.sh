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
    echo "#   [CONFIG_REPO_PATH]/.sap_deployment_automation folder                                                 #"
    echo "#                                                                                       #"
    echo "#                                                                                       #"
    echo "#   Usage: install_deployer.sh                                                          #"
    echo "#    -p deployer parameter file                                                         #"
    echo "#    -i interactive true/false setting the value to false will not prompt before apply  #"
    echo "#    -h Show help                                                                       #"
    echo "#                                                                                       #"
    echo "#   Example:                                                                            #"
    echo "#                                                                                       #"
    echo "#   [REPO-ROOT]deploy/scripts/install_library.sh \                                      #"
    echo "#      -p PROD-WEEU-SAP_LIBRARY.json \                                                  #"
    echo "#      -d ../../DEPLOYER/PROD-WEEU-DEP00-INFRASTRUCTURE/ \                              #"
    echo "#      -i true                                                                          #"
    echo "#                                                                                       #"
    echo "#########################################################################################"
}

#process inputs - may need to check the option i for auto approve as it is not used
INPUT_ARGUMENTS=$(getopt -n install_library -o p:d:ih --longoptions parameterfile:,deployer_statefile_foldername:,auto-approve,help -- "$@")
VALID_ARGUMENTS=$?

if [ "$VALID_ARGUMENTS" != "0" ]; then
  showhelp

fi

eval set -- "$INPUT_ARGUMENTS"
while :
do
  case "$1" in
    -p | --parameterfile)                      parameterfile="$2"                   ; shift 2 ;;
    -d | --deployer_statefile_foldername)      deployer_statefile_foldername="$2"   ; shift 2 ;;
    -i | --auto-approve)                       approve="--auto-approve"             ; shift ;;
    -h | --help)                               showhelp
                                               exit 3                               ; shift ;;
    --) shift; break ;;
  esac
done

deployment_system=sap_library
use_deployer=true

if [ ! -f "${parameterfile}" ]
then
    printf -v val %-40.40s "$parameterfile"
    echo ""
    echo "#########################################################################################"
    echo "#                                                                                       #"
    echo "#               Parameter file does not exist: ${val} #"
    echo "#                                                                                       #"
    echo "#########################################################################################"
    exit
fi

param_dirname=$(dirname "${parameterfile}")

if [ $param_dirname != '.' ]; then
    echo ""
    echo "#########################################################################################"
    echo "#                                                                                       #"
    echo "#   Please run this command from the folder containing the parameter file               #"
    echo "#                                                                                       #"
    echo "#########################################################################################"
    exit 3
fi

ext=$(echo ${parameterfile} | cut -d. -f2)

# Helper variables
if [ "${ext}" == json ]; then
    environment=$(jq --raw-output .infrastructure.environment "${parameterfile}")
    region=$(jq --raw-output .infrastructure.region "${parameterfile}")
    use_deployer=$(jq --raw-output .deployer.use "${parameterfile}")
else

    load_config_vars "${param_dirname}"/"${parameterfile}" "environment"
    load_config_vars "${param_dirname}"/"${parameterfile}" "location"
    region=$(echo ${location} | xargs)

fi


key=$(echo "${parameterfile}" | cut -d. -f1)

if [ -z "${environment}" ]
then
    echo "#########################################################################################"
    echo "#                                                                                       #"
    echo "#                           Incorrect parameter file.                                   #"
    echo "#                                                                                       #"
    echo "#              The file needs to contain the environment attribute!!                    #"
    echo "#                                                                                       #"
    echo "#########################################################################################"
    echo ""
    exit 64
fi

if [ -z "${region}" ]
then
    echo "#########################################################################################"
    echo "#                                                                                       #"
    echo "#                           Incorrect parameter file.                                   #"
    echo "#                                                                                       #"
    echo "#       The file needs to contain the infrastructure.region attribute!!                 #"
    echo "#                                                                                       #"
    echo "#########################################################################################"
    echo ""
    exit 64
fi

# Convert the region to the correct code
region=$(echo "${region}" | tr "[:upper:]" "[:lower:]")
get_region_code $region


if [ true == "$use_deployer" ]
then
    if [ ! -d "${deployer_statefile_foldername}" ]
    then
        printf -v val %-40.40s "$deployer_statefile_foldername"
        echo ""
        echo "#########################################################################################"
        echo "#                                                                                       #"
        echo "#                    Directory does not exist:  "${deployer_statefile_foldername}" #"
        echo "#                                                                                       #"
        echo "#########################################################################################"
        exit
    fi
fi

#Persisting the parameters across executions
automation_config_directory=$CONFIG_REPO_PATH/.sap_deployment_automation/
generic_config_information="${automation_config_directory}"config
library_config_information="${automation_config_directory}""${environment}""${region_code}"

#Plugins
sudo mkdir -p /opt/terraform/.terraform.d/plugin-cache
sudo chown -R $USER:$USER /opt/terraform
export TF_PLUGIN_CACHE_DIR=/opt/terraform/.terraform.d/plugin-cache


param_dirname=$(pwd)


arm_config_stored=false

param_dirname=$(pwd)

init "${automation_config_directory}" "${generic_config_information}" "${library_config_information}"

export TF_DATA_DIR="${param_dirname}"/.terraform
var_file="${param_dirname}"/"${parameterfile}"

if [ ! -n "${SAP_AUTOMATION_REPO_PATH}" ]; then
    echo ""
    echo "#########################################################################################"
    echo "#                                                                                       #"
    echo "#   Missing environment variables (SAP_AUTOMATION_REPO_PATH)!!!                             #"
    echo "#                                                                                       #"
    echo "#   Please export the folloing variables:                                               #"
    echo "#      SAP_AUTOMATION_REPO_PATH (path to the repo folder (sap-automation))                        #"
    echo "#      ARM_SUBSCRIPTION_ID (subscription containing the state file storage account)     #"
    echo "#                                                                                       #"
    echo "#########################################################################################"
    unset TF_DATA_DIR
    exit 4
fi

templen=$(echo "${ARM_SUBSCRIPTION_ID}" | wc -c)
# Subscription length is 37
if [ 37 != $templen ]
then
    arm_config_stored=false
fi

if [ ! -n "$ARM_SUBSCRIPTION_ID" ]; then
    echo ""
    echo "#########################################################################################"
    echo "#                                                                                       #"
    echo "#   Missing environment variables (ARM_SUBSCRIPTION_ID)!!!                              #"
    echo "#                                                                                       #"
    echo "#   Please export the folloing variables:                                               #"
    echo "#      SAP_AUTOMATION_REPO_PATH (path to the repo folder (sap-automation))                        #"
    echo "#      ARM_SUBSCRIPTION_ID (subscription containing the state file storage account)     #"
    echo "#                                                                                       #"
    echo "#########################################################################################"
    unset TF_DATA_DIR
    exit 3
fi

terraform_module_directory="${SAP_AUTOMATION_REPO_PATH}"/deploy/terraform/bootstrap/"${deployment_system}"/

if [ ! -d ${terraform_module_directory} ]
then
    echo "#########################################################################################"
    echo "#                                                                                       #"
    echo "#   Incorrect system deployment type specified :" ${deployment_system} "            #"
    echo "#                                                                                       #"
    echo "#   Valid options are:                                                                  #"
    echo "#      sap_library                                                                      #"
    echo "#                                                                                       #"
    echo "#########################################################################################"
    echo ""
    unset TF_DATA_DIR
    exit 64
fi

reinitialized=0

if [ -f ./backend-config.tfvars ]
then
    echo "#########################################################################################"
    echo "#                                                                                       #"
    echo "#                        The bootstrapping has already been done!                       #"
    echo "#                                                                                       #"
    echo "#########################################################################################"
else
    sed -i /REMOTE_STATE_RG/d  "${library_config_information}"
    sed -i /REMOTE_STATE_SA/d  "${library_config_information}"
    sed -i /tfstate_resource_id/d  "${library_config_information}"
fi

if [ ! -d ./.terraform/ ]; then
    echo "#########################################################################################"
    echo "#                                                                                       #"
    echo "#                                   New deployment                                      #"
    echo "#                                                                                       #"
    echo "#########################################################################################"
    terraform -chdir="${terraform_module_directory}" init -upgrade=true -backend-config "path=${param_dirname}/terraform.tfstate"
    sed -i /REMOTE_STATE_RG/d  "${library_config_information}"
    sed -i /REMOTE_STATE_SA/d  "${library_config_information}"
    sed -i /tfstate_resource_id/d  "${library_config_information}"

else
    if [ -f ./.terraform/terraform.tfstate ]; then
        if grep "azurerm" ./.terraform/terraform.tfstate ; then
            echo "#########################################################################################"
            echo "#                                                                                       #"
            echo "#                     The state is already migrated to Azure!!!                         #"
            echo "#                                                                                       #"
            echo "#########################################################################################"

            if [ $approve == "--auto-approve" ] ; then
              tfstate_resource_id=$(az resource list --name $REINSTALL_ACCOUNTNAME --subscription $REINSTALL_SUBSCRIPTION --resource-type Microsoft.Storage/storageAccounts --query "[].id | [0]" -o tsv)
              if [ -n "${tfstate_resource_id}" ]; then
                  echo "Reinitializing against remote state"
                  terraform_module_directory="${SAP_AUTOMATION_REPO_PATH}"/deploy/terraform/run/"${deployment_system}"/
                  export TF_VAR_tfstate_resource_id=$tfstate_resource_id
                  terraform -chdir="${terraform_module_directory}" init -upgrade=true     \
                  --backend-config "subscription_id=$REINSTALL_SUBSCRIPTION"              \
                  --backend-config "resource_group_name=$REINSTALL_RESOURCE_GROUP"        \
                  --backend-config "storage_account_name=$REINSTALL_ACCOUNTNAME"          \
                  --backend-config "container_name=tfstate"                               \
                  --backend-config "key=${key}.terraform.tfstate"
                terraform -chdir="${terraform_module_directory}" refresh -var-file="${var_file}"

              else
                terraform -chdir="${terraform_module_directory}" init -upgrade=true -reconfigure  -backend-config "path=${param_dirname}/terraform.tfstate"
                terraform -chdir="${terraform_module_directory}" refresh -var-file="${var_file}"
              fi
            else

                read -p "Do you want to re bootstrap the SAP library Y/N?"  ans
                answer=${ans^^}
                if [ $answer == 'Y' ]; then
                    terraform -chdir="${terraform_module_directory}" init -upgrade=true -reconfigure -backend-config "path=${param_dirname}/terraform.tfstate"
                    return_value=$?
                    if [ 0 != $return_value ] ; then
                        echo ""
                        echo "#########################################################################################"
                        echo "#                                                                                       #"
                        echo -e "#                          $boldreduscore Errors during the init phase $resetformatting                               #"
                        echo "#                                                                                       #"
                        echo "#########################################################################################"
                        echo ""
                        unset TF_DATA_DIR
                        exit $return_value
                    fi
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


echo ""
echo "#########################################################################################"
echo "#                                                                                       #"
echo "#                             Running Terraform plan                                    #"
echo "#                                                                                       #"
echo "#########################################################################################"
echo ""

if [ -n "${deployer_statefile_foldername}" ]; then
    echo "Deployer folder specified:" "${deployer_statefile_foldername}"
    terraform -chdir="${terraform_module_directory}" plan -no-color -detailed-exitcode -var-file="${var_file}" -var deployer_statefile_foldername="${deployer_statefile_foldername}" > plan_output.log 2>&1
else
    terraform -chdir="${terraform_module_directory}" plan -no-color -detailed-exitcode -var-file="${var_file}"  > plan_output.log 2>&1
fi
return_value=$?

if [ 0 == $return_value ] ; then
    echo ""
    echo "#########################################################################################"
    echo "#                                                                                       #"
    echo -e "#                          $cyan Infrastructure is up to date $resetformatting                               #"
    echo "#                                                                                       #"
    echo "#########################################################################################"
    echo ""
    if [ -f plan_output.log ]
    then
        rm plan_output.log
    fi

    tfstate_resource_id=$(terraform -chdir="${terraform_module_directory}" output -no-color -raw tfstate_resource_id| tr -d \")
    STATE_SUBSCRIPTION=$(echo $tfstate_resource_id | cut -d/ -f3 | tr -d \" | xargs)

    az account set --sub $STATE_SUBSCRIPTION

    REMOTE_STATE_SA=$(terraform -chdir="${terraform_module_directory}" output -no-color -raw remote_state_storage_account_name| tr -d \")

    get_and_store_sa_details ${REMOTE_STATE_SA} "${system_config_information}"

    unset TF_DATA_DIR
    exit $return_value
fi

if [ 1 == $return_value ]
then
    echo ""
    echo "#########################################################################################"
    echo "#                                                                                       #"
    echo -e "#                          $boldreduscore Errors during the plan phase $resetformatting                               #"
    echo "#                                                                                       #"
    echo "#########################################################################################"
    echo ""

    if [ -f plan_output.log ]; then
        cat plan_output.log
        rm plan_output.log
    fi
    unset TF_DATA_DIR
    exit $return_value
fi

if [ -f plan_output.log ]; then
    cat plan_output.log
    rm plan_output.log
fi

echo ""
echo "#########################################################################################"
echo "#                                                                                       #"
echo "#                             Running Terraform apply                                   #"
echo "#                                                                                       #"
echo "#########################################################################################"
echo ""

deployer_parameter=""
if [ -n "${deployer_statefile_foldername}" ];
then
    echo "Deployer folder specified:" "${deployer_statefile_foldername}"
    if [ -n "${approve}" ]
    then
        terraform -chdir="${terraform_module_directory}" apply -var-file="${var_file}" -var deployer_statefile_foldername="${deployer_statefile_foldername}" -auto-approve -json | tee -a  apply_output.json
    else
        terraform -chdir="${terraform_module_directory}" apply -var-file="${var_file}" -var deployer_statefile_foldername="${deployer_statefile_foldername}"
    fi
else
    if [ -n "${approve}" ]
    then
      terraform -chdir="${terraform_module_directory}" apply -var-file="${var_file}" -auto-approve -json | tee -a  apply_output.json
    else
      terraform -chdir="${terraform_module_directory}" apply -var-file="${var_file}"
    fi
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

          if [ -n "${deployer_statefile_foldername}" ];
          then
              echo "Deployer folder specified:" "${deployer_statefile_foldername}"
              terraform -chdir="${terraform_module_directory}" import -var-file="${var_file}" -var deployer_statefile_foldername="${deployer_statefile_foldername}" $moduleID $resourceID
          else
              terraform -chdir="${terraform_module_directory}" import -var-file="${var_file}" $moduleID $resourceID
          fi

        done
        rerun_apply=1
    fi
    if [ $rerun_apply == 1 ] ; then
        echo ""
        echo "#########################################################################################"
        echo "#                                                                                       #"
        echo "#                          Re-running Terraform apply                                   #"
        echo "#                                                                                       #"
        echo "#########################################################################################"
        echo ""
        if [ -n "${deployer_statefile_foldername}" ];
        then
            echo "Deployer folder specified:" "${deployer_statefile_foldername}"
            terraform -chdir="${terraform_module_directory}" apply -var-file="${var_file}" -var deployer_statefile_foldername="${deployer_statefile_foldername}" -auto-approve -json | tee -a  apply_output.json
        else
            terraform -chdir="${terraform_module_directory}" apply -var-file="${var_file}" -auto-approve -json | tee -a  apply_output.json
        fi
        return_value=$?
        rerun_apply=0
    fi
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

          if [ -n "${deployer_statefile_foldername}" ];
          then
              echo "Deployer folder specified:" "${deployer_statefile_foldername}"
              terraform -chdir="${terraform_module_directory}" import -var-file="${var_file}" -var deployer_statefile_foldername="${deployer_statefile_foldername}" $moduleID $resourceID
          else
              terraform -chdir="${terraform_module_directory}" import -var-file="${var_file}" $moduleID $resourceID
          fi

        done
        rerun_apply=1
    fi

    if [ $rerun_apply == 1 ] ; then
        echo ""
        echo "#########################################################################################"
        echo "#                                                                                       #"
        echo "#                          Re-running Terraform apply                                   #"
        echo "#                                                                                       #"
        echo "#########################################################################################"
        echo ""
        if [ -n "${deployer_statefile_foldername}" ];
        then
            echo "Deployer folder specified:" "${deployer_statefile_foldername}"
            terraform -chdir="${terraform_module_directory}" apply -var-file="${var_file}" -var deployer_statefile_foldername="${deployer_statefile_foldername}" -auto-approve -json | tee -a  apply_output.json
        else
            terraform -chdir="${terraform_module_directory}" apply -var-file="${var_file}" -auto-approve -json | tee -a  apply_output.json
        fi
        return_value=$?
        rerun_apply=0
    fi
    errors_occurred=$(jq 'select(."@level" == "error") | length' apply_output.json)

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

if [ -f apply_output.json ]
then
    rm apply_output.json
fi

if [ 1 == $return_value ] ; then
    echo ""
    echo "#########################################################################################"
    echo "#                                                                                       #"
    echo -e "#                          $boldreduscore Errors during the apply phase $resetformatting                              #"
    echo "#                                                                                       #"
    echo "#########################################################################################"
    echo ""
    unset TF_DATA_DIR
    exit $return_value
fi

REMOTE_STATE_SA=$(terraform -chdir="${terraform_module_directory}" output -no-color -raw remote_state_storage_account_name| tr -d \")
temp=$(echo "${REMOTE_STATE_SA}" | grep -m1 "Warning")
if [ -z "${temp}" ]
then
    temp=$(echo "${REMOTE_STATE_SA}" | grep "Backend reinitialization required")
    if [ -z "${temp}" ]
    then
        save_config_var "REMOTE_STATE_SA" "${library_config_information}"
    fi
fi

tfstate_resource_id=$(terraform -chdir="${terraform_module_directory}" output -no-color -raw tfstate_resource_id| tr -d \")
temp=$(echo $tfstate_resource_id | grep -m1 "Warning")
if [ -z "${temp}" ]
then
    temp=$(echo "${tfstate_resource_id}" | grep "Backend reinitialization required")
    if [ -z "${temp}" ]
    then
        save_config_var "tfstate_resource_id" "${library_config_information}"
    fi
fi

REMOTE_STATE_RG=$(terraform -chdir="${terraform_module_directory}" output -no-color -raw created_resource_group_name | tr -d \")
temp=$(echo "${REMOTE_STATE_RG}" | grep -m1 "Warning")
if [ -z "${temp}" ]
then
    temp=$(echo "${REMOTE_STATE_RG}" | grep "Backend reinitialization required")
    if [ -z "${temp}" ]
    then
        save_config_var "REMOTE_STATE_RG" "${library_config_information}"
        return_value=0
    fi
fi

random_id_b64=$(terraform -chdir="${terraform_module_directory}" output -no-color -raw random_id_b64 | tr -d \")
temp=$(echo "${random_id_b64}" | grep -m1 "Warning")
if [ -z "${temp}" ]
then
    temp=$(echo "${random_id_b64}" | grep "Backend reinitialization required")
    if [ -z "${temp}" ]
    then
        save_config_var "library_random_id" "${random_id_b64}"
        return_value=0
    fi
fi

exit $return_value
