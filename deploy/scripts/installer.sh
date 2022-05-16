#!/bin/bash

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

force=0

INPUT_ARGUMENTS=$(getopt -n installer -o p:t:o:d:l:s:ahif --longoptions type:,parameterfile:,storageaccountname:,deployer_tfstate_key:,landscape_tfstate_key:,state_subscription:,ado,auto-approve,force,help -- "$@")
VALID_ARGUMENTS=$?

if [ "$VALID_ARGUMENTS" != "0" ]; then
    showhelp
fi
called_from_ado=0
eval set -- "$INPUT_ARGUMENTS"
while :
do
    case "$1" in
        -t | --type)                               deployment_system="$2"           ; shift 2 ;;
        -p | --parameterfile)                      parameterfile="$2"               ; shift 2 ;;
        -o | --storageaccountname)                 REMOTE_STATE_SA="$2"             ; shift 2 ;;
        -s | --state_subscription)                 STATE_SUBSCRIPTION="$2"          ; shift 2 ;;
        -d | --deployer_tfstate_key)               deployer_tfstate_key="$2"        ; shift 2 ;;
        -l | --landscape_tfstate_key)              landscape_tfstate_key="$2"       ; shift 2 ;;
        -a | --ado)                                called_from_ado=1                ; shift ;;
        -f | --force)                              force=1                          ; shift ;;
        -i | --auto-approve)                       approve="--auto-approve"         ; shift ;;
        -h | --help)                               showhelp
        exit 3                           ; shift ;;
        --) shift; break ;;
    esac
done


tfstate_resource_id=""
tfstate_parameter=""

deployer_tfstate_key_parameter=""
landscape_tfstate_key_parameter=""
landscape_tfstate_key_exists=false

parameterfile_name=$(basename "${parameterfile}")
param_dirname=$(dirname "${parameterfile}")

if [ "${param_dirname}" != '.' ]; then
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

    echo "Parameter file does not exist: ${val}" > "${system_config_information}".err

    exit 2 #No such file or directory
fi

if [ -z "${deployment_system}" ]
then
    printf -v val %-40.40s "$deployment_system"
    echo "#########################################################################################"
    echo "#                                                                                       #"
    echo -e "#  $boldred Incorrect system deployment type specified: ${val}$resetformatting#"
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

# Check that the exports ARM_SUBSCRIPTION_ID and DEPLOYMENT_REPO_PATH are defined
validate_exports
return_code=$?
if [ 0 != $return_code ]; then
    echo "Missing exports" > "${system_config_information}".err
    exit $return_code
fi

# Check that Terraform and Azure CLI is installed
validate_dependencies
return_code=$?
if [ 0 != $return_code ]; then
    echo "Missing software" > "${system_config_information}".err
    exit $return_code
fi

# Check that parameter files have environment and location defined
validate_key_parameters "$parameterfile_name"
return_code=$?
if [ 0 != $return_code ]; then
    echo "Missing parameters in $parameterfile_name" > "${system_config_information}".err
    exit $return_code
fi
region=$(echo "${region}" | tr "[:upper:]" "[:lower:]")
if valid_region_name "${region}" ; then
    # Convert the region to the correct code
    get_region_code ${region}
else
    echo "Invalid region: $region"
    exit 2
fi

key=$(echo "${parameterfile_name}" | cut -d. -f1)

#Persisting the parameters across executions

automation_config_directory=~/.sap_deployment_automation/
generic_config_information="${automation_config_directory}"config
system_config_information="${automation_config_directory}""${environment}""${region_code}"

echo "Configuration file: $system_config_information"
echo "Deployment region: $region"
echo "Deployment region code: $region_code"
if [ 1 == $called_from_ado ] ; then
    this_ip=$(curl -s ipinfo.io/ip) >/dev/null 2>&1
    export TF_VAR_Agent_IP=$this_ip
    echo "Agent IP: $this_ip"
fi

parallelism=10

#Provide a way to limit the number of parallell tasks for Terraform
if [[ -n "${TF_PARALLELLISM}" ]]; then
    parallelism=$TF_PARALLELLISM
fi

echo "Parallelism count $parallelism"

param_dirname=$(pwd)

init "${automation_config_directory}" "${generic_config_information}" "${system_config_information}"

var_file="${param_dirname}"/"${parameterfile}"

extra_vars=""

if [ -f terraform.tfvars ]; then
    extra_vars=" -var-file=${param_dirname}/terraform.tfvars "
fi

if [ "${deployment_system}" == sap_deployer ]
then
    deployer_tfstate_key=${key}.terraform.tfstate
fi

if [[ -z $REMOTE_STATE_SA ]];
then
    echo "Loading the State file information"
    load_config_vars "${system_config_information}" "REMOTE_STATE_SA"
    load_config_vars "${system_config_information}" "REMOTE_STATE_RG"
    load_config_vars "${system_config_information}" "tfstate_resource_id"
    load_config_vars "${system_config_information}" "STATE_SUBSCRIPTION"
else
    save_config_vars "${system_config_information}" REMOTE_STATE_SA
fi

echo "Terraform state file storage:" "${REMOTE_STATE_SA}"
echo "Terraform state subscription:" "${STATE_SUBSCRIPTION}"

deployer_tfstate_key_parameter=''

if [[ -z $deployer_tfstate_key ]];
then
    load_config_vars "${system_config_information}" "deployer_tfstate_key"
else
    echo "Deployer state file name:" "${deployer_tfstate_key}"
    save_config_vars "${system_config_information}" deployer_tfstate_key
fi

if [ "${deployment_system}" != sap_deployer ]
then
    if [ -z ${deployer_tfstate_key} ]; then
        if [ 1 != $called_from_ado ]; then
            read -p "Deployer terraform statefile name :" landscape_tfstate_key
            deployer_tfstate_key_parameter=" -var deployer_tfstate_key=${deployer_tfstate_key}"
            save_config_var "deployer_tfstate_key" "${system_config_information}"
        else
            echo ""
            echo "#########################################################################################"
            echo "#                                                                                       #"
            echo -e "#                          $boldreduscore!Deployer state file name is missing!$resetformatting                        #"
            echo "#                                                                                       #"
            echo "#########################################################################################"
            echo ""

            echo "Deployer terraform statefile name is missing" > "${system_config_information}".err
            unset TF_DATA_DIR
            exit 2
        fi
    else
        deployer_tfstate_key_parameter=" -var deployer_tfstate_key=${deployer_tfstate_key}"
    fi
fi

landscape_tfstate_key_parameter=''

if [[ -z $landscape_tfstate_key ]];
then
    load_config_vars "${system_config_information}" "landscape_tfstate_key"
else
    echo "Workload zone file name:" "${landscape_tfstate_key}"
    save_config_vars "${system_config_information}" landscape_tfstate_key
fi

if [ "${deployment_system}" == sap_system ]
then
    if [ -z ${landscape_tfstate_key} ]; then
        if [ 1 != $called_from_ado ]; then
            read -p "Workload terraform statefile name :" landscape_tfstate_key
            landscape_tfstate_key_parameter=" -var landscape_tfstate_key=${landscape_tfstate_key}"
            save_config_var "landscape_tfstate_key" "${system_config_information}"
        else
            echo ""
            echo "#########################################################################################"
            echo "#                                                                                       #"
            echo -e "#                     $boldred Workload zone terraform statefile name is missing $resetformatting               #"
            echo "#                                                                                       #"
            echo "#########################################################################################"
            echo ""

            echo "Workload zone terraform statefile name is missing" > "${system_config_information}".err

            unset TF_DATA_DIR
            exit 2
        fi
    else
        landscape_tfstate_key_parameter=" -var landscape_tfstate_key=${landscape_tfstate_key}"
    fi
fi

if [[ -z $STATE_SUBSCRIPTION ]];
then
    load_config_vars "${system_config_information}" "STATE_SUBSCRIPTION"
else
    echo "Saving the state subscription"
    if is_valid_guid "$STATE_SUBSCRIPTION" ; then
        save_config_var "STATE_SUBSCRIPTION" "${system_config_information}"
    else
        printf -v val %-40.40s "$STATE_SUBSCRIPTION"
        echo "#########################################################################################"
        echo "#                                                                                       #"
        echo -e "# The provided state_subscription is not valid:$boldred ${val}$resetformatting#"
        echo "#                                                                                       #"
        echo "#########################################################################################"
        echo "The provided subscription for Terraform remote state is not valid:${val}" > "${system_config_information}".err
        exit 65
    fi

fi

account_set=0

#setting the user environment variables
set_executing_user_environment_variables "none"

if [[ -n ${subscription} ]]; then
    if is_valid_guid "${subscription}" ; then
        echo "Valid subscription format"
    else
        printf -v val %-40.40s "$subscription"
        echo "#########################################################################################"
        echo "#                                                                                       #"
        echo -e "#   The provided subscription is not valid:$boldred ${val} $resetformatting#   "
        echo "#                                                                                       #"
        echo "#########################################################################################"
        echo "The provided subscription is not valid:${val}" > "${system_config_information}".err
        exit 65
    fi
    export ARM_SUBSCRIPTION_ID="${subscription}"
fi

if [[ -n $STATE_SUBSCRIPTION ]];
then
    echo ""
    echo "#########################################################################################"
    echo "#                                                                                       #"
    echo -e "#       $cyan Changing the subscription to: $STATE_SUBSCRIPTION $resetformatting            #"
    echo "#                                                                                       #"
    echo "#########################################################################################"
    echo ""
    az account set --sub "${STATE_SUBSCRIPTION}"
fi

load_config_vars "${system_config_information}" "STATE_SUBSCRIPTION"
load_config_vars "${system_config_information}" "REMOTE_STATE_RG"
load_config_vars "${system_config_information}" "tfstate_resource_id"

if [[ -z ${REMOTE_STATE_SA} ]]; then
    if [ 1 != $called_from_ado ]; then
        read -p "Terraform state storage account name:"  REMOTE_STATE_SA

        get_and_store_sa_details "${REMOTE_STATE_SA}" "${system_config_information}"
        load_config_vars "${system_config_information}" "STATE_SUBSCRIPTION"
        load_config_vars "${system_config_information}" "REMOTE_STATE_RG"
        load_config_vars "${system_config_information}" "tfstate_resource_id"
    fi
fi

echo "Terraform state storage " "${REMOTE_STATE_SA}"

if [ -z ${REMOTE_STATE_SA} ]; then
    option="REMOTE_STATE_SA"
    missing
    exit 1
fi

if [[ -z ${REMOTE_STATE_RG} ]]; then
    get_and_store_sa_details "${REMOTE_STATE_SA}" "${system_config_information}"
    load_config_vars "${system_config_information}" "STATE_SUBSCRIPTION"
    load_config_vars "${system_config_information}" "REMOTE_STATE_RG"
    load_config_vars "${system_config_information}" "tfstate_resource_id"
fi

if [[ -z ${tfstate_resource_id} ]]; then
    get_and_store_sa_details "${REMOTE_STATE_SA}" "${system_config_information}"
    load_config_vars "${system_config_information}" "STATE_SUBSCRIPTION"
    load_config_vars "${system_config_information}" "REMOTE_STATE_RG"
    load_config_vars "${system_config_information}" "tfstate_resource_id"

fi

if [ "${deployment_system}" != sap_deployer ]
then
    tfstate_parameter=" -var tfstate_resource_id=${tfstate_resource_id}"
else
    tfstate_parameter=" "
fi

terraform_module_directory="${DEPLOYMENT_REPO_PATH}"/deploy/terraform/run/"${deployment_system}"/
export TF_DATA_DIR="${param_dirname}/.terraform"

if [ ! -d "${terraform_module_directory}" ]
then
    printf -v val %-40.40s "$deployment_system"
    echo "#########################################################################################"
    echo "#                                                                                       #"
    echo -e "#   $boldred Incorrect system deployment type specified: ${val}$resetformatting#"
    echo "#                                                                                       #"
    echo "#     Valid options are:                                                                #"
    echo "#       sap_deployer                                                                    #"
    echo "#       sap_library                                                                     #"
    echo "#       sap_landscape                                                                   #"
    echo "#       sap_system                                                                      #"
    echo "#                                                                                       #"
    echo "#########################################################################################"
    echo ""
    exit 1
fi

ok_to_proceed=false

echo "subscription_id=${STATE_SUBSCRIPTION}"
echo "resource_group_name=${REMOTE_STATE_RG}"
echo "storage_account_name=${REMOTE_STATE_SA}"

# This is used to tell Terraform if this is a new deployment or an update
deployment_parameter=""
# This is used to tell Terraform the version information from the state file
version_parameter=""

check_output=0
if [ ! -d ./.terraform/ ];
then
    deployment_parameter=" -var deployment=new "

    terraform -chdir="${terraform_module_directory}" init -upgrade=true     \
    --backend-config "subscription_id=${STATE_SUBSCRIPTION}"                \
    --backend-config "resource_group_name=${REMOTE_STATE_RG}"               \
    --backend-config "storage_account_name=${REMOTE_STATE_SA}"              \
    --backend-config "container_name=tfstate"                               \
    --backend-config "key=${key}.terraform.tfstate"
    return_value=$?

else
    temp=$(grep "\"type\": \"local\"" .terraform/terraform.tfstate)
    if [ -n "${temp}" ]
    then
        terraform -chdir="${terraform_module_directory}" init -upgrade=true -force-copy \
        --backend-config "subscription_id=${STATE_SUBSCRIPTION}"                        \
        --backend-config "resource_group_name=${REMOTE_STATE_RG}"                       \
        --backend-config "storage_account_name=${REMOTE_STATE_SA}"                      \
        --backend-config "container_name=tfstate"                                       \
        --backend-config "key=${key}.terraform.tfstate"
        return_value=$?

    else
        echo ""
        echo "#########################################################################################"
        echo "#                                                                                       #"
        echo -e "#            $cyan The system has already been deployed and the statefile is in Azure $resetformatting       #"
        echo "#                                                                                       #"
        echo "#########################################################################################"
        echo ""

        check_output=1
        terraform -chdir="${terraform_module_directory}" init -upgrade=true -reconfigure  \
        --backend-config "subscription_id=${STATE_SUBSCRIPTION}" \
        --backend-config "resource_group_name=${REMOTE_STATE_RG}" \
        --backend-config "storage_account_name=${REMOTE_STATE_SA}" \
        --backend-config "container_name=tfstate" \
        --backend-config "key=${key}.terraform.tfstate"
        return_value=$?

    fi
fi
if [ 0 != $return_value ]
then
    echo "#########################################################################################"
    echo "#                                                                                       #"
    echo -e "#                            $boldreduscore!!! Error when Initializing !!!$resetformatting                            #"
    echo "#                                                                                       #"
    echo "#########################################################################################"
    echo ""
    echo "Error when initializing Terraform" > "${system_config_information}".err
    exit $return_value
fi
if [ 1 == $check_output ]
then
    outputs=$(terraform -chdir="${terraform_module_directory}" output )
    if echo "${outputs}" | grep "No outputs"; then
        ok_to_proceed=true
        echo "#########################################################################################"
        echo "#                                                                                       #"
        echo -e "#                                 $cyan  New deployment $resetformatting                                      #"
        echo "#                                                                                       #"
        echo "#########################################################################################"

        deployment_parameter=" -var deployment=new "

    else
        echo ""
        echo "#########################################################################################"
        echo "#                                                                                       #"
        echo -e "#                          $cyan Existing deployment was detected$resetformatting                            #"
        echo "#                                                                                       #"
        echo "#########################################################################################"
        echo ""
        allParams=$(printf " -var-file=%s %s %s %s %s %s %s" "${var_file}" "${extra_vars}" "${tfstate_parameter}" "${landscape_tfstate_key_parameter}" "${deployer_tfstate_key_parameter}" "${deployment_parameter}" "${version_parameter}" )
        terraform -chdir="${terraform_module_directory}" refresh $allParams

        deployment_parameter=" "

        deployed_using_version=$(terraform -chdir="${terraform_module_directory}" output automation_version | tr -d \")

        if [ -z "${deployed_using_version}" ]; then
            echo ""
            echo "#########################################################################################"
            echo "#                                                                                       #"
            echo -e "#   $boldred The environment was deployed using an older version of the Terrafrom templates$resetformatting     #"
            echo "#                                                                                       #"
            echo "#                               !!! Risk for Data loss !!!                              #"
            echo "#                                                                                       #"
            echo "#        Please inspect the output of Terraform plan carefully before proceeding        #"
            echo "#                                                                                       #"
            echo "#########################################################################################"

            if [ 1 == $called_from_ado ] ; then
                unset TF_DATA_DIR
                exit 1
            fi
            read -p "Do you want to continue Y/N?"  ans
            answer=${ans^^}
            if [ $answer == 'Y' ]; then
                ok_to_proceed=true
            else
                unset TF_DATA_DIR
                exit 1
            fi
        else
            version_parameter=" -var terraform_template_version=${deployed_using_version} "

            printf -v val %-.20s "$deployed_using_version"
            echo ""
            echo "#########################################################################################"
            echo "#                                                                                       #"
            echo -e "#              $cyan Deployed using the Terraform templates version: $val $resetformatting                #"
            echo "#                                                                                       #"
            echo "#########################################################################################"
            echo ""
            #Add version logic here
        fi
    fi
fi

echo ""
echo "#########################################################################################"
echo "#                                                                                       #"
echo -e "#                            $cyan Running Terraform plan $resetformatting                                   #"
echo "#                                                                                       #"
echo "#########################################################################################"
echo ""

if [ -f plan_output.log ]
then
    rm plan_output.log
fi

allParams=$(printf " -var-file=%s %s %s %s %s %s %s" "${var_file}" "${extra_vars}" "${tfstate_parameter}" "${landscape_tfstate_key_parameter}" "${deployer_tfstate_key_parameter}" "${deployment_parameter}" "${version_parameter}" )

terraform -chdir="$terraform_module_directory" plan -no-color -detailed-exitcode $allParams > plan_output.log
return_value=$?
if [ 1 == $return_value ]
then
    echo ""
    echo "#########################################################################################"
    echo "#                                                                                       #"
    echo -e "#                            $boldreduscore Errors during the plan phase$resetformatting                              #"
    echo "#                                                                                       #"
    echo "#########################################################################################"
    echo ""
    echo "Error when running Terraform plan" > "${system_config_information}".err

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

    if [ "${deployment_system}" == sap_deployer ]
    then
        deployer_public_ip_address=$(terraform -chdir="${terraform_module_directory}" output deployer_public_ip_address | tr -d \")
        keyvault=$(terraform -chdir="${terraform_module_directory}"  output deployer_kv_user_name | tr -d \")
        save_config_var "keyvault" "${system_config_information}"
        save_config_var "deployer_public_ip_address" "${system_config_information}"

    fi

    if [ "${deployment_system}" == sap_landscape ]
    then
        if [ $landscape_tfstate_key_exists == false ]
        then
            save_config_vars "${system_config_information}" \
            landscape_tfstate_key
        fi
    fi

    if [ "${deployment_system}" == sap_library ]
    then

        tfstate_resource_id=$(terraform -chdir="${terraform_module_directory}" output tfstate_resource_id| tr -d \")
        STATE_SUBSCRIPTION=$(echo "$tfstate_resource_id" | cut -d/ -f3 | tr -d \" | xargs)

        az account set --sub "${STATE_SUBSCRIPTION}"

        REMOTE_STATE_SA=$(terraform -chdir="${terraform_module_directory}" output remote_state_storage_account_name| tr -d \")

        get_and_store_sa_details "${REMOTE_STATE_SA}" "${system_config_information}"

    fi

    unset TF_DATA_DIR
    exit $return_value
fi
if [ 2 == $return_value ] ; then
    fatal_errors=0
    # HANA VM
    test=$(grep vm_dbnode plan_output.log | grep -m1 replaced)
    if [ -n "${test}" ] ; then
        echo ""
        echo "#########################################################################################"
        echo "#                                                                                       #"
        echo -e "#                               $boldreduscore!!! Risk for Data loss !!!$resetformatting                              #"
        echo "#                                                                                       #"
        echo "#                          Database server(s) will be replaced                          #"
        echo "#                                                                                       #"
        echo "#########################################################################################"
        echo ""
        echo ""
        fatal_errors=1
    fi
    # HANA VM disks
    test=$(grep azurerm_managed_disk.data_disk plan_output.log | grep  -m1 replaced)
    if [ -n "${test}" ] ; then
        echo ""
        echo "#########################################################################################"
        echo "#                                                                                       #"
        echo -e "#                               $boldreduscore!!! Risk for Data loss !!!$resetformatting                              #"
        echo "#                                                                                       #"
        echo "#                        Database server disks will be replaced                         #"
        echo "#                                                                                       #"
        echo "#########################################################################################"
        echo ""
        echo ""
        fatal_errors=1
    fi

    # AnyDB server
    test=$(grep dbserver plan_output.log | grep -m1 replaced)
    if [ -n "${test}" ] ; then
        echo ""
        echo "#########################################################################################"
        echo "#                                                                                       #"
        echo -e "#                               $boldreduscore!!! Risk for Data loss !!!$resetformatting                              #"
        echo "#                                                                                       #"
        echo "#                          Database server(s) will be replaced                          #"
        echo "#                                                                                       #"
        echo "#########################################################################################"
        echo ""
        echo ""
        fatal_errors=1
    fi
    # AnyDB disks
    test=$(grep azurerm_managed_disk.disks plan_output.log | grep -m1 replaced)
    if [ -n "${test}" ] ; then
        echo ""
        echo "#########################################################################################"
        echo "#                                                                                       #"
        echo -e "#                               $boldreduscore!!! Risk for Data loss !!!$resetformatting                              #"
        echo "#                                                                                       #"
        echo "#                        Database server disks will be replaced                         #"
        echo "#                                                                                       #"
        echo "#########################################################################################"
        echo ""
        echo ""
        fatal_errors=1
    fi

    # App server
    test=$(grep virtual_machine.app plan_output.log | grep -m1 replaced)
    if [ -n "${test}" ] ; then
        echo ""
        echo "#########################################################################################"
        echo "#                                                                                       #"
        echo -e "#                               $boldreduscore!!! Risk for Data loss !!!$resetformatting                              #"
        echo "#                                                                                       #"
        echo "#                          Application server will be replaced                          #"
        echo "#                                                                                       #"
        echo "#########################################################################################"
        echo ""
        echo ""
        fatal_errors=1
    fi
    # App server disks
    test=$(grep azurerm_managed_disk.app plan_output.log | grep -m1 replaced)
    if [ -n "${test}" ] ; then
        echo ""
        echo "#########################################################################################"
        echo "#                                                                                       #"
        echo -e "#                               $boldreduscore!!! Risk for Data loss !!!$resetformatting                              #"
        echo "#                                                                                       #"
        echo "#                      Application server disks will be replaced                        #"
        echo "#                                                                                       #"
        echo "#########################################################################################"
        echo ""
        echo ""
        fatal_errors=1
    fi

    # SCS server
    test=$(grep virtual_machine.scs plan_output.log | grep -m1 replaced)
    if [ -n "${test}" ] ; then
        echo ""
        echo "#########################################################################################"
        echo "#                                                                                       #"
        echo -e "#                               $boldreduscore!!! Risk for Data loss !!!$resetformatting                              #"
        echo "#                                                                                       #"
        echo "#                        SCS server(s) disks will be replaced                           #"
        echo "#                                                                                       #"
        echo "#########################################################################################"
        echo ""
        echo ""
        fatal_errors=1
    fi

    # SCS server disks
    test=$(grep azurerm_managed_disk.scs plan_output.log | grep -m1 replaced)
    if [ -n "${test}" ] ; then
        echo ""
        echo "#########################################################################################"
        echo "#                                                                                       #"
        echo -e "#                               $boldreduscore!!! Risk for Data loss !!!$resetformatting                              #"
        echo "#                                                                                       #"
        echo "#                          SCS server disks will be replaced                            #"
        echo "#                                                                                       #"
        echo "#########################################################################################"
        echo ""
        echo ""
        fatal_errors=1
    fi

    # Web server
    test=$(grep virtual_machine.web plan_output.log | grep -m1 replaced)
    if [ -n "${test}" ] ; then
        echo ""
        echo "#########################################################################################"
        echo "#                                                                                       #"
        echo -e "#                               $boldreduscore!!! Risk for Data loss !!!$resetformatting                              #"
        echo "#                                                                                       #"
        echo "#                         Web Dispatcher server(s) will be replaced                     #"
        echo "#                                                                                       #"
        echo "#########################################################################################"
        echo ""
        echo ""
        fatal_errors=1
    fi
    # Web dispatcher server disks
    test=$(grep azurerm_managed_disk.web plan_output.log | grep -m1 replaced)
    if [ -n "${test}" ] ; then
        echo ""
        echo "#########################################################################################"
        echo "#                                                                                       #"
        echo -e "#                               $boldreduscore!!! Risk for Data loss !!!$resetformatting                              #"
        echo "#                                                                                       #"
        echo "#                       Web Dispatcher server disks will be replaced                    #"
        echo "#                                                                                       #"
        echo "#########################################################################################"
        echo ""
        echo ""
        fatal_errors=1
    fi

    if [ $fatal_errors == 1 ] ; then

        echo ""
        echo "#########################################################################################"
        echo "#                                                                                       #"
        echo -e "#                               $boldreduscore!!! Risk for Data loss !!!$resetformatting                              #"
        echo "#                                                                                       #"
        echo "#        Please inspect the output of Terraform plan carefully before proceeding        #"
        echo "#                                                                                       #"
        echo "#########################################################################################"
        echo ""
        if [ 1 == "$called_from_ado" ]; then
            unset TF_DATA_DIR
            echo "Risk for data loss, Please inspect the output of Terraform plan carefully. Run manually from deployer" > "${system_config_information}".err

            exit 1
        fi

        if [ 1 == $force ]; then
            ok_to_proceed=true
        else
            read -p "Do you want to continue with the deployment Y/N?"  ans
            answer=${ans^^}
            if [ $answer == 'Y' ]; then
                ok_to_proceed=true
            else
                unset TF_DATA_DIR
                exit 1
            fi
        fi

    fi
else
    ok_to_proceed=true
fi

if [ $ok_to_proceed ]; then

    if [ -f error.log ]
    then
        rm error.log
    fi
    if [ -f plan_output.log ]
    then
        rm plan_output.log
    fi

    echo ""
    echo "#########################################################################################"
    echo "#                                                                                       #"
    echo -e "#                            $cyan Running Terraform apply$resetformatting                                   #"
    echo "#                                                                                       #"
    echo "#########################################################################################"
    echo ""

    allParams=$(printf " -var-file=%s %s %s %s %s %s %s %s " "${var_file}" "${extra_vars}" "${tfstate_parameter}" "${landscape_tfstate_key_parameter}" "${deployer_tfstate_key_parameter}" "${deployment_parameter}" "${version_parameter}  "${approve}"" )

    if [ 1 == $called_from_ado ] ; then
        terraform -chdir="${terraform_module_directory}" apply -parallelism="${parallelism}" -no-color -compact-warnings $allParams  2>error.log
    else
        terraform -chdir="${terraform_module_directory}" apply -parallelism="${parallelism}" $allParams  2>error.log
    fi
    return_value=$?

    if [ 0 != $return_value ] ; then
        echo ""
        echo "#########################################################################################"
        echo "#                                                                                       #"
        echo -e "#                          $boldreduscore!Errors during the apply phase!$resetformatting                              #"
        echo "#                                                                                       #"
        echo "#########################################################################################"
        echo ""
        if [ -f error.log ]; then
            cat error.log
            export LASTERROR=$(grep -m1 Error: error.log | tr -cd "[:print:]" )
            echo "$LASTERROR" > "${system_config_information}".err

            if [ 1 == $called_from_ado ] ; then
                echo "##vso[task.logissue type=error]$LASTERROR"
            fi
            rm error.log
        fi
        unset TF_DATA_DIR
        exit $return_value
    fi

fi


if [ "${deployment_system}" == sap_deployer ]
then
    deployer_public_ip_address=$(terraform -chdir="${terraform_module_directory}" output deployer_public_ip_address | tr -d \")
    keyvault=$(terraform -chdir="${terraform_module_directory}"  output deployer_kv_user_name | tr -d \")

    save_config_var "keyvault" "${system_config_information}"
    save_config_var "deployer_public_ip_address" "${system_config_information}"
fi

if [ "${deployment_system}" == sap_system ]
then
    re_run=0
    database_loadbalancer_public_ip_address=$(terraform -chdir="${terraform_module_directory}" output database_loadbalancer_ip | tr -d "\n"  | tr -d "("  | tr -d ")" | tr -d " ")
    database_loadbalancer_public_ip_address=$(echo ${database_loadbalancer_public_ip_address/tolist/})
    database_loadbalancer_public_ip_address=$(echo ${database_loadbalancer_public_ip_address/,]/]})
    echo "Database Load Balancer IP: $database_loadbalancer_public_ip_address"

    load_config_vars "${parameterfile_name}" "database_loadbalancer_ips"
    database_loadbalancer_ips=$(echo ${database_loadbalancer_ips} | xargs)

    if [[ "${database_loadbalancer_public_ip_address}" != "${database_loadbalancer_ips}" ]];
    then
      database_loadbalancer_ips=${database_loadbalancer_public_ip_address}
      save_config_var "database_loadbalancer_ips" "${parameterfile_name}"
      re_run=1
    fi

    scs_loadbalancer_public_ip_address=$(terraform -chdir="${terraform_module_directory}" output scs_loadbalancer_ips | tr -d "\n"  | tr -d "("  | tr -d ")" | tr -d " ")
    scs_loadbalancer_public_ip_address=$(echo ${scs_loadbalancer_public_ip_address/tolist/})
    scs_loadbalancer_public_ip_address=$(echo ${scs_loadbalancer_public_ip_address/,]/]})
    echo "SCS Load Balancer IP: $scs_loadbalancer_public_ip_address"

    load_config_vars "${parameterfile_name}" "scs_server_loadbalancer_ips"
    scs_server_loadbalancer_ips=$(echo ${scs_server_loadbalancer_ips} | xargs)

    if [[ "${scs_loadbalancer_public_ip_address}" != "${scs_server_loadbalancer_ips}" ]];
    then
      scs_server_loadbalancer_ips=${scs_loadbalancer_public_ip_address}
      save_config_var "scs_server_loadbalancer_ips" "${parameterfile_name}"
      re_run=1
    fi

    if [ 1 == $re_run ] ; then
        if [ 1 == $called_from_ado ] ; then
            terraform -chdir="${terraform_module_directory}" apply -parallelism="${parallelism}" -no-color -compact-warnings $allParams  2>error.log
        else
            terraform -chdir="${terraform_module_directory}" apply -parallelism="${parallelism}" $allParams  2>error.log
        fi
    fi
fi


if [ "${deployment_system}" == sap_landscape ]
then
    save_config_vars "${system_config_information}" \
    landscape_tfstate_key
fi

if [ "${deployment_system}" == sap_library ]
then
    REMOTE_STATE_SA=$(terraform -chdir="${terraform_module_directory}" output remote_state_storage_account_name| tr -d \")

    get_and_store_sa_details "${REMOTE_STATE_SA}" "${system_config_information}"

fi

if [ -f "${system_config_information}".err ]; then
    "${system_config_information}".err
fi


unset TF_DATA_DIR
exit $return_value
