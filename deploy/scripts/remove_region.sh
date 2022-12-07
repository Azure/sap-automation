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


################################################################################################
#                                                                                              #
#   This file contains the logic to deploy the environment to support SAP workloads.           #
#                                                                                              #
#   The script is intended to be run from a parent folder to the folders containing            #
#   the json parameter files for the deployer, the library and the environment.                #
#                                                                                              #
#   The script will persist the parameters needed between the executions in the                #
#   [CONFIG_REPO_PATH]/.sap_deployment_automation folder                                                        #
#                                                                                              #
#   The script experts the following exports:                                                  #
#   ARM_SUBSCRIPTION_ID to specify which subscription to deploy to                             #
#   DEPLOYMENT_REPO_PATH the path to the folder containing the cloned sap-automation                 #
#                                                                                              #
################################################################################################

function showhelp {
    echo ""
    echo "#################################################################################################################"
    echo "#                                                                                                               #"
    echo "#                                                                                                               #"
    echo "#   This file contains the logic to remove the deployer and library from an Azure region                        #"
    echo "#                                                                                                               #"
    echo "#   The script experts the following exports:                                                                   #"
    echo "#                                                                                                               #"
    echo "#     DEPLOYMENT_REPO_PATH the path to the folder containing the cloned sap-automation                                #"
    echo "#                                                                                                               #"
    echo "#   The script is to be run from a parent folder to the folders containing the json parameter files for         #"
    echo "#    the deployer and the library and the environment.                                                          #"
    echo "#                                                                                                               #"
    echo "#   The script will persist the parameters needed between the executions in the                                 #"
    echo "#   [CONFIG_REPO_PATH]/.sap_deployment_automation folder                                                                         #"
    echo "#                                                                                                               #"
    echo "#                                                                                                               #"
    echo "#   Usage: remove_region.sh                                                                                     #"
    echo "#      -d or --deployer_parameter_file       deployer parameter file                                            #"
    echo "#      -l or --library_parameter_file        library parameter file                                             #"
    echo "#                                                                                                               #"
    echo "#                                                                                                               #"
    echo "#   Example:                                                                                                    #"
    echo "#                                                                                                               #"
    echo "#   DEPLOYMENT_REPO_PATH/scripts/remove_region.sh \                                                             #"
    echo "#      --deployer_parameter_file DEPLOYER/PROD-WEEU-DEP00-INFRASTRUCTURE/PROD-WEEU-DEP00-INFRASTRUCTURE.json \  #"
    echo "#      --library_parameter_file LIBRARY/PROD-WEEU-SAP_LIBRARY/PROD-WEEU-SAP_LIBRARY.json \                      #"
    echo "#                                                                                                               #"
    echo "#################################################################################################################"
}

function missing {
    printf -v val '%-40s' "$missing_value"
    echo ""
    echo "#########################################################################################"
    echo "#                                                                                       #"
    echo "#   Missing : ${val}                                  #"
    echo "#                                                                                       #"
    echo "#   Usage: remove_region.sh                                                             #"
    echo "#      -d or --deployer_parameter_file       deployer parameter file                    #"
    echo "#      -l or --library_parameter_file        library parameter file                     #"
    echo "#                                                                                       #"
    echo "#########################################################################################"

}

force=0
ado=0
INPUT_ARGUMENTS=$(getopt -n remove_region -o d:l:s:b:r:iha --longoptions deployer_parameter_file:,library_parameter_file:,subscription:,resource_group:,storage_account:,auto-approve,ado,help -- "$@")
VALID_ARGUMENTS=$?

if [ "$VALID_ARGUMENTS" != "0" ]; then
    showhelp
fi
echo "$INPUT_ARGUMENTS"
eval set -- "$INPUT_ARGUMENTS"
while :
do
    case "$1" in
        -d | --deployer_parameter_file)            deployer_parameter_file="$2"        ; shift 2 ;;
        -l | --library_parameter_file)             library_parameter_file="$2"         ; shift 2 ;;
        -s | --subscription)                       subscription="$2"                   ; shift 2 ;;
        -b | --storage_account)                    storage_account="$2"                ; shift 2 ;;
        -r | --resource_group)                     resource_group="$2"                 ; shift 2 ;;
        -a | --ado)                                approveparam="--auto-approve;ado=1" ; shift ;;
        -i | --auto-approve)                       approveparam="--auto-approve"       ; shift ;;
        -h | --help)                               showhelp
        exit 3                           ; shift ;;
        --) shift; break ;;
    esac
done

if [ -z "$deployer_parameter_file" ]; then
    missing_value='deployer parameter file'
    missing
    exit 2
fi

if [ -z "$library_parameter_file" ]; then
    missing_value='library parameter file'
    missing
    exit 2
fi


# Check that the exports ARM_SUBSCRIPTION_ID and DEPLOYMENT_REPO_PATH are defined
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
validate_key_parameters "$deployer_parameter_file"
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

automation_config_directory=$CONFIG_REPO_PATH/.sap_deployment_automation
generic_config_information="${automation_config_directory}"/config
deployer_config_information="${automation_config_directory}"/"${environment}""${region_code}"

if [ -z "$deployer_config_information" ]; then
    rm $deployer_config_information
fi

root_dirname=$(pwd)

init "${automation_config_directory}" "${generic_config_information}" "${deployer_config_information}"

this_ip=$(curl -s ipinfo.io/ip) >/dev/null 2>&1

echo "Deployer environment: $deployer_environment"

this_ip=$(curl -s ipinfo.io/ip) >/dev/null 2>&1
export TF_VAR_Agent_IP=$this_ip
echo "Agent IP: $this_ip"

if [ -n "${subscription}" ]
then
    export ARM_SUBSCRIPTION_ID=$subscription
else
    subscription=$ARM_SUBSCRIPTION_ID
fi

deployer_dirname=$(dirname "${deployer_parameter_file}")
deployer_file_parametername=$(basename "${deployer_parameter_file}")

library_dirname=$(dirname "${library_parameter_file}")
library_file_parametername=$(basename "${library_parameter_file}")

relative_path="${root_dirname}"/"${deployer_dirname}"
export TF_DATA_DIR="${relative_path}"/.terraform

curdir=$(pwd)

#we know that we have a valid az session so let us set the environment variables
set_executing_user_environment_variables "none"

# Deployer

cd "${deployer_dirname}" || exit

param_dirname=$(pwd)

relative_path="${curdir}"/"${deployer_dirname}"

terraform_module_directory="${DEPLOYMENT_REPO_PATH}"/deploy/terraform/run/sap_deployer/
export TF_DATA_DIR="${param_dirname}/.terraform"

if [ -z "${storage_account}" ]; then
    load_config_vars "${deployer_config_information}" "STATE_SUBSCRIPTION"
    load_config_vars "${deployer_config_information}" "REMOTE_STATE_SA"
    load_config_vars "${deployer_config_information}" "REMOTE_STATE_RG"
    load_config_vars "${deployer_config_information}" "tfstate_resource_id"

    if [ -n "${STATE_SUBSCRIPTION}" ]
    then
        subscription="${STATE_SUBSCRIPTION}"
        az account set --sub "${STATE_SUBSCRIPTION}"

    fi

    if [ -n "${REMOTE_STATE_SA}" ]
    then
        storage_account="${REMOTE_STATE_SA}"
    fi

    if [ -n "${REMOTE_STATE_RG}" ]
    then
        resource_group="${REMOTE_STATE_RG}"
    fi
fi

key=$(echo "${deployer_file_parametername}" | cut -d. -f1)

# Reinitialize
echo ""
echo "#########################################################################################"
echo "#                                                                                       #"
echo "#                          Running Terraform init (deployer)                            #"
echo "#                                                                                       #"
echo "#########################################################################################"
echo ""
echo "#  subscription_id=${subscription}"
echo "#  backend-config resource_group_name=${resource_group}"
echo "#  storage_account_name=${storage_account}"
echo "#  container_name=tfstate"
echo "#  key=${key}.terraform.tfstate"

isLocal=""
if [ -f ./.terraform/terraform.tfstate ]; then
   if grep "azurerm" ./.terraform/terraform.tfstate ; then
     isLocal=""
     echo "State is stored in Azure"
   else
     isLocal="-migrate-state"
   fi
fi

terraform -chdir="${terraform_module_directory}" init $isLocal -upgrade=true  \
--backend-config "subscription_id=${subscription}"                            \
--backend-config "resource_group_name=${resource_group}"                      \
--backend-config "storage_account_name=${storage_account}"                    \
--backend-config "container_name=tfstate"                                     \
--backend-config "key=${key}.terraform.tfstate"

#Initialize the statefile and copy to local
terraform_module_directory="${DEPLOYMENT_REPO_PATH}"/deploy/terraform/bootstrap/sap_deployer/

echo ""
echo "#########################################################################################"
echo "#                                                                                       #"
echo "#                     Running Terraform init (deployer - local)                         #"
echo "#                                                                                       #"
echo "#########################################################################################"
echo ""


terraform -chdir="${terraform_module_directory}" init -migrate-state -force-copy --backend-config "path=${param_dirname}/terraform.tfstate"

cd "${curdir}" || exit

key=$(echo "${library_file_parametername}" | cut -d. -f1)
cd "${library_dirname}" || exitstorage_account
param_dirname=$(pwd)

#Library

terraform_module_directory="${DEPLOYMENT_REPO_PATH}"/deploy/terraform/run/sap_library/
export TF_DATA_DIR="${param_dirname}/.terraform"

#Reinitialize

key=$(echo "${library_file_parametername}" | cut -d. -f1)

echo ""
echo "#########################################################################################"
echo "#                                                                                       #"
echo "#                             Running Terraform init (library)                          #"
echo "#                                                                                       #"
echo "#########################################################################################"
echo ""
echo ""
echo "#  subscription_id=${subscription}"
echo "#  backend-config resource_group_name=${resource_group}"
echo "#  storage_account_name=${storage_account}"
echo "#  container_name=tfstate"
echo "#  key=${key}.terraform.tfstate"

isLocal=""
if [ -f ./.terraform/terraform.tfstate ]; then
   if grep "azurerm" ./.terraform/terraform.tfstate ; then
     isLocal=""
     echo "State is stored in Azure"
   else
     isLocal="-migrate-state"
   fi
fi

terraform -chdir="${terraform_module_directory}" init $isLocal -upgrade=true  \
--backend-config "subscription_id=${subscription}"                            \
--backend-config "resource_group_name=${resource_group}"                      \
--backend-config "storage_account_name=${storage_account}"                    \
--backend-config "container_name=tfstate"                                     \
--backend-config "key=${key}.terraform.tfstate"

echo ""
echo "#########################################################################################"
echo "#                                                                                       #"
echo "#                     Running Terraform init (library - local)                          #"
echo "#                                                                                       #"
echo "#########################################################################################"
echo ""

#Initialize the statefile and copy to local
terraform_module_directory="${DEPLOYMENT_REPO_PATH}"/deploy/terraform/bootstrap/sap_library/
terraform -chdir="${terraform_module_directory}" init -force-copy -migrate-state  --backend-config "path=${param_dirname}/terraform.tfstate"

extra_vars=""

if [ -f terraform.tfvars ]; then
    extra_vars=" -var-file=${param_dirname}/terraform.tfvars "
fi

var_file="${param_dirname}"/"${library_file_parametername}"

allParams=$(printf " -var-file=%s -var use_deployer=false -var deployer_statefile_foldername=%s %s %s " "${var_file}" "${relative_path}" "${extra_vars}" "${approveparam}" )

export TF_DATA_DIR="${param_dirname}/.terraform"
export TF_use_spn=false

echo ""
echo "#########################################################################################"
echo "#                                                                                       #"
echo "#                     Running Terraform destroy (library)                               #"
echo "#                                                                                       #"
echo "#########################################################################################"
echo ""

terraform -chdir="${terraform_module_directory}" destroy  $allParams
return_value=$?

if [ 0 != $return_value ]
then
    exit $return_value
fi

cd "${curdir}" || exit

cd "${deployer_dirname}" || exit

param_dirname=$(pwd)

terraform_module_directory="${DEPLOYMENT_REPO_PATH}"/deploy/terraform/bootstrap/sap_deployer/
export TF_DATA_DIR="${param_dirname}/.terraform"

extra_vars=""

if [ -f terraform.tfvars ]; then
    extra_vars=" -var-file=${param_dirname}/terraform.tfvars "
fi

var_file="${param_dirname}"/"${deployer_file_parametername}"
allParams=$(printf " -var-file=%s %s %s " "${var_file}" "${extra_vars}" "${approveparam}"  )

echo ""
echo "#########################################################################################"
echo "#                                                                                       #"
echo "#                     Running Terraform destroy (deployer)                              #"
echo "#                                                                                       #"
echo "#########################################################################################"
echo ""

terraform -chdir="${terraform_module_directory}" destroy $allParams
return_value=$?

cd "${curdir}" || exit

unset TF_DATA_DIR

step=0
save_config_var "step" "${deployer_config_information}"


echo ""
echo "#########################################################################################"
echo "#                                                                                       #"
echo "#                                       Reset settings                                  #"
echo "#                                                                                       #"
echo "#########################################################################################"
echo ""

STATE_SUBSCRIPTION=''
REMOTE_STATE_SA=''
REMOTE_STATE_RG=''
tfstate_resource_id=''
keyvault=''
save_config_vars "${deployer_config_information}" \
        keyvault \
        tfstate_resource_id \
        REMOTE_STATE_SA \
        REMOTE_STATE_RG \
        STATE_SUBSCRIPTION

exit $return_value
