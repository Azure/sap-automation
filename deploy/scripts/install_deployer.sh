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
    echo "#     DEPLOYMENT_REPO_PATH the path to the folder containing the cloned sap-automation        #"
    echo "#                                                                                       #"
    echo "#   The script will persist the parameters needed between the executions in the         #"
    echo "#   ~/.sap_deployment_automation folder                                                 #"
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
else

    load_config_vars "${param_dirname}"/"${parameterfile}" "environment"
    load_config_vars "${param_dirname}"/"${parameterfile}" "location"
    region=$(echo ${location} | xargs)
fi

# Convert the region to the correct code
get_region_code $region


key=$(echo "${parameterfile}" | cut -d. -f1)

if [ ! -n "${environment}" ]
then
    echo "#########################################################################################"
    echo "#                                                                                       #"
    echo "#                           Incorrect parameter file.                                   #"
    echo "#                                                                                       #"
    echo "#     The file needs to contain the infrastructure.environment attribute!!              #"
    echo "#                                                                                       #"
    echo "#########################################################################################"
    echo ""
    exit 64
fi

if [ ! -n "${region}" ]
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

#Persisting the parameters across executions
automation_config_directory=~/.sap_deployment_automation/
generic_config_information="${automation_config_directory}"config
deployer_config_information="${automation_config_directory}""${environment}""${region_code}"

arm_config_stored=false
config_stored=false

param_dirname=$(pwd)

init "${automation_config_directory}" "${generic_config_information}" "${deployer_config_information}"

var_file="${param_dirname}"/"${parameterfile}" 

if [ ! -n "${DEPLOYMENT_REPO_PATH}" ]; then
    echo ""
    echo "#########################################################################################"
    echo "#                                                                                       #"
    echo "#   Missing environment variables (DEPLOYMENT_REPO_PATH)!!!                             #"
    echo "#                                                                                       #"
    echo "#   Please export the folloing variables:                                               #"
    echo "#      DEPLOYMENT_REPO_PATH (path to the repo folder (sap-automation))                        #"
    echo "#      ARM_SUBSCRIPTION_ID (subscription containing the state file storage account)     #"
    echo "#                                                                                       #"
    echo "#########################################################################################"
    exit 4
else
    if [ $config_stored == false ]
    then
        save_config_var "DEPLOYMENT_REPO_PATH" "${generic_config_information}"
    fi
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
    echo "#      DEPLOYMENT_REPO_PATH (path to the repo folder (sap-automation))                        #"
    echo "#      ARM_SUBSCRIPTION_ID (subscription containing the state file storage account)     #"
    echo "#                                                                                       #"
    echo "#########################################################################################"
    exit 3
else
    if [  $arm_config_stored  == false ]
    then
        echo "Storing the configuration"
        save_config_var "ARM_SUBSCRIPTION_ID" "${deployer_config_information}"
        STATE_SUBSCRIPTION=$ARM_SUBSCRIPTION_ID
        save_config_var "STATE_SUBSCRIPTION" "${deployer_config_information}"
    fi
fi

terraform_module_directory="${DEPLOYMENT_REPO_PATH}"/deploy/terraform/bootstrap/"${deployment_system}"/
export TF_DATA_DIR="${param_dirname}"/.terraform

ok_to_proceed=false
new_deployment=false

if [ ! -d "$HOME/.terraform.d/plugin-cache" ]
then
    mkdir -p "$HOME/.terraform.d/plugin-cache"
fi
export TF_PLUGIN_CACHE_DIR="$HOME/.terraform.d/plugin-cache"



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
            read -p "Do you want to bootstrap the deployer again Y/N?"  ans
            answer=${ans^^}
            if [ $answer == 'Y' ]; then
                terraform -chdir="${terraform_module_directory}" init -upgrade=true  -backend-config "path=${param_dirname}/terraform.tfstate"
                terraform -chdir="${terraform_module_directory}" refresh -var-file="${var_file}" 
            else
                unset TF_DATA_DIR
                exit 0
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

echo ""
echo "#########################################################################################"
echo "#                                                                                       #"
echo "#                             Running Terraform plan                                    #"
echo "#                                                                                       #"
echo "#########################################################################################"
echo ""

terraform -chdir="${terraform_module_directory}"  plan  -detailed-exitcode -var-file="${var_file}" $extra_vars > plan_output.log 2>&1

return_value=$?
if [ 1 == $return_value ]
then
    echo ""
    echo "#########################################################################################"
    echo "#                                                                                       #"
    echo -e "#                             $boldreduscoreErrors during the plan phase$resetformatting                              #"
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

terraform -chdir="${terraform_module_directory}"  apply ${approve} -var-file="${var_file}" $extra_vars 
return_value=$?
    
if [ 0 != $return_value ] ; then
    echo ""
    echo "#########################################################################################"
    echo "#                                                                                       #"
    echo -e "#                          $boldreduscore Errors during the apply phase $resetformatting                              #"
    echo "#                                                                                       #"
    echo "#########################################################################################"
    echo ""
    unset TF_DATA_DIR
    exit -1
fi


keyvault=$(terraform -chdir="${terraform_module_directory}"  output deployer_kv_user_name | tr -d \")

return_value=-1
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
        return_value=-1
    fi
fi
unset TF_DATA_DIR
exit $return_value
