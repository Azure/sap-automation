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
automation_config_directory=~/.sap_deployment_automation/
generic_config_information="${automation_config_directory}"config
deployer_config_information="${automation_config_directory}""${environment}""${region_code}"

arm_config_stored=false
config_stored=false

param_dirname=$(pwd)

init "${automation_config_directory}" "${generic_config_information}" "${deployer_config_information}"

var_file="${param_dirname}"/"${parameterfile}"
# Check that the exports ARM_SUBSCRIPTION_ID and DEPLOYMENT_REPO_PATH are defined
validate_exports
return_code=$?
if [ 0 != $return_code ]; then
    exit $return_code
fi

terraform_module_directory="${DEPLOYMENT_REPO_PATH}"/deploy/terraform/bootstrap/"${deployment_system}"/
export TF_DATA_DIR="${param_dirname}"/.terraform

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
            if [ $approve == "--auto-approve" ] ; then
                terraform -chdir="${terraform_module_directory}" init -upgrade=true -migrate-state -backend-config "path=${param_dirname}/terraform.tfstate"
                terraform -chdir="${terraform_module_directory}" refresh -var-file="${var_file}"
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

parallelism=10

#Provide a way to limit the number of parallell tasks for Terraform
if [[ -n "${TF_PARALLELLISM}" ]]; then
    parallelism=$TF_PARALLELLISM
fi

terraform -chdir="${terraform_module_directory}"  apply ${approve} -parallelism="${parallelism}" -var-file="${var_file}" $extra_vars
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
    exit $return_value
fi


keyvault=$(terraform -chdir="${terraform_module_directory}"  output deployer_kv_user_name | tr -d \")

return_value=0
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
unset TF_DATA_DIR
exit $return_value
