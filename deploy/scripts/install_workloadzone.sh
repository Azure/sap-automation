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
called_from_ado=0
deploy_using_msi_only=0

INPUT_ARGUMENTS=$(getopt -n install_workloadzone -o p:d:e:k:o:s:c:n:t:v:aifhm --longoptions parameterfile:,deployer_tfstate_key:,deployer_environment:,subscription:,spn_id:,spn_secret:,tenant_id:,state_subscription:,keyvault:,storageaccountname:,ado,auto-approve,force,help,msi -- "$@")
VALID_ARGUMENTS=$?
if [ "$VALID_ARGUMENTS" != "0" ]; then
    showhelp
fi

eval set -- "$INPUT_ARGUMENTS"
while :
do
    case "$1" in
        -a | --ado)                                called_from_ado=1                ; shift ;;
        -c | --spn_id)                             client_id="$2"                   ; shift 2 ;;
        -d | --deployer_tfstate_key)               deployer_tfstate_key="$2"        ; shift 2 ;;
        -e | --deployer_environment)               deployer_environment="$2"        ; shift 2 ;;
        -f | --force)                              force=1                          ; shift ;;
        -i | --auto-approve)                       approve="--auto-approve"         ; shift ;;
        -k | --state_subscription)                 STATE_SUBSCRIPTION="$2"          ; shift 2 ;;
        -m | --msi)                                deploy_using_msi_only=1          ; shift ;;
        -n | --spn_secret)                         spn_secret="$2"                  ; shift 2 ;;
        -o | --storageaccountname)                 REMOTE_STATE_SA="$2"             ; shift 2 ;;
        -p | --parameterfile)                      parameterfile="$2"               ; shift 2 ;;
        -s | --subscription)                       subscription="$2"                ; shift 2 ;;
        -t | --tenant_id)                          tenant_id="$2"                   ; shift 2 ;;
        -v | --keyvault)                           keyvault="$2"                    ; shift 2 ;;

        -h | --help)                               workload_zone_showhelp
        exit 3                           ; shift ;;
        --) shift; break ;;
    esac
done
tfstate_resource_id=""
tfstate_parameter=""

deployer_tfstate_key_parameter=""
landscape_tfstate_key=""
landscape_tfstate_key_parameter=""

deployment_system="sap_landscape"

this_ip=$(curl -s ipinfo.io/ip) >/dev/null 2>&1

deployer_environment=$(echo "${deployer_environment}" | tr "[:lower:]" "[:upper:]")

echo "Deployer environment: $deployer_environment"

if [ 1 == $called_from_ado ] ; then
    this_ip=$(curl -s ipinfo.io/ip) >/dev/null 2>&1
    export TF_VAR_Agent_IP=$this_ip
    echo "Agent IP: $this_ip"
fi


workload_file_parametername=$(basename "${parameterfile}")

param_dirname=$(dirname "${parameterfile}")

if [ "$param_dirname" != '.' ]; then
    echo ""
    echo "#########################################################################################"
    echo "#                                                                                       #"
    echo -e "#  $boldred Please run this command from the folder containing the parameter file$resetformatting               #"
    echo "#                                                                                       #"
    echo "#########################################################################################"
    exit 3
fi

if [ ! -f "${workload_file_parametername}" ]
then
    printf -v val %-40.40s "$workload_file_parametername"
    echo ""
    echo "#########################################################################################"
    echo "#                                                                                       #"
    echo -e "#                 $boldreduscore Parameter file does not exist: ${val}$resetformatting #"
    echo "#                                                                                       #"
    echo "#########################################################################################"
    exit 3
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
validate_key_parameters "$workload_file_parametername"
if [ 0 != $return_code ]; then
    exit $return_code
fi

load_config_vars "$workload_file_parametername" "network_logical_name"
network_logical_name=$(echo "${network_logical_name}" | tr "[:lower:]" "[:upper:]")

if [ -z "${network_logical_name}" ]; then
    echo "#########################################################################################"
    echo "#                                                                                       #"
    echo -e "#                         $boldred  Incorrect parameter file. $resetformatting                                  #"
    echo "#                                                                                       #"
    echo "#             The file must contain the network_logical_name attribute!!                #"
    echo "#                                                                                       #"
    echo "#########################################################################################"
    echo ""
    return 64 #script usage wrong
fi


# Convert the region to the correct code
region=$(echo "${region}" | tr "[:upper:]" "[:lower:]")
get_region_code "$region"

key=$(echo "${workload_file_parametername}" | cut -d. -f1)
landscape_tfstate_key=${key}.terraform.tfstate

echo "Deployment region: $region"
echo "Deployment region code: $region_code"
echo "Keyvault: $keyvault"

#Persisting the parameters across executions

automation_config_directory=$CONFIG_REPO_PATH/.sap_deployment_automation
generic_config_information="${automation_config_directory}"/config

if [ $deployer_environment != $environment ]; then
    if [ -f "${automation_config_directory}"/"${environment}""${region_code}" ]; then
        # Add support for having multiple vnets in the same environment and zone - rename exiting file to support seamless transition
        mv "${automation_config_directory}"/"${environment}""${region_code}" "${automation_config_directory}"/"${environment}""${region_code}""${network_logical_name}"
    fi
fi

workload_config_information="${automation_config_directory}"/"${environment}""${region_code}""${network_logical_name}"

if [ "${force}" == 1 ]
then
    if [ -f "${workload_config_information}" ]
    then
        rm "${workload_config_information}"
    fi
    rm -Rf .terraform terraform.tfstate*
fi

echo "Workload configuration file: $workload_config_information"

if [ -n "$STATE_SUBSCRIPTION" ]
then
    echo "Saving the state subscription"
    if is_valid_guid "$STATE_SUBSCRIPTION" ; then
        echo "Valid subscription format"
        save_config_vars "${workload_config_information}" \
        STATE_SUBSCRIPTION

        echo ""
        echo "#########################################################################################"
        echo "#                                                                                       #"
        echo -e "#       $cyan Changing the subscription to: $STATE_SUBSCRIPTION $resetformatting            #"
        echo "#                                                                                       #"
        echo "#########################################################################################"
        echo ""
        az account set --sub "${STATE_SUBSCRIPTION}"

    else
        printf -v val %-40.40s "$STATE_SUBSCRIPTION"
        echo "#########################################################################################"
        echo "#                                                                                       #"
        echo -e "#The provided state_subscription is not valid:$boldred ${val} $resetformatting#"
        echo "#                                                                                       #"
        echo "#########################################################################################"
        echo "The provided subscription for the terraform storage is not valid: ${val}" > "${workload_config_information}".err
        exit 65
    fi

fi

if [ -n "$REMOTE_STATE_SA" ] ; then

    get_and_store_sa_details ${REMOTE_STATE_SA} ${workload_config_information}
fi

if [ -n "$keyvault" ]
then
    if valid_kv_name "$keyvault" ; then
        save_config_var "keyvault" "${workload_config_information}"
    else
        printf -v val %-40.40s "$keyvault"
        echo "#########################################################################################"
        echo "#                                                                                       #"
        echo -e "#       The provided keyvault is not valid:$boldred ${val} $resetformatting  #"
        echo "#                                                                                       #"
        echo "#########################################################################################"

        echo "The provided keyvault is not valid: ${val}" > "${workload_config_information}".err
        exit 65
    fi

fi


if [ ! -f "${workload_config_information}" ]
then
    # Ask for deployer environment name and try to read the deployer state file and resource group details from the configuration file
    if [ -z "$deployer_environment" ]
    then
        read -p "Deployer environment name: " deployer_environment
    fi

    deployer_config_information="${automation_config_directory}"/"${deployer_environment}""${region_code}"
    if [ -f "$deployer_config_information" ]
    then
        if [ -z "${keyvault}" ]
        then
            load_config_vars "${deployer_config_information}" "keyvault"
        fi

        load_config_vars "${deployer_config_information}" "REMOTE_STATE_RG"
        if [ -z "${REMOTE_STATE_SA}" ]
        then
            load_config_vars "${deployer_config_information}" "REMOTE_STATE_SA"
        fi
        load_config_vars "${deployer_config_information}" "tfstate_resource_id"
        load_config_vars "${deployer_config_information}" "deployer_tfstate_key"

        save_config_vars "${workload_config_information}" \
        keyvault \
        subscription \
        deployer_tfstate_key \
        tfstate_resource_id \
        REMOTE_STATE_SA \
        REMOTE_STATE_RG
    fi
fi

if [ -z "$tfstate_resource_id" ]
then
    echo "No tfstate_resource_id"
    if [ -n "$deployer_environment" ]
    then
        deployer_config_information="${automation_config_directory}"/"${deployer_environment}""${region_code}"
        echo "Deployer config file $deployer_config_information"
        if [ -f "$deployer_config_information" ]
        then
            load_config_vars "${deployer_config_information}" "keyvault"
            load_config_vars "${deployer_config_information}" "REMOTE_STATE_RG"
            load_config_vars "${deployer_config_information}" "REMOTE_STATE_SA"
            load_config_vars "${deployer_config_information}" "tfstate_resource_id"
            load_config_vars "${deployer_config_information}" "deployer_tfstate_key"
            echo "tfstate_resource_id: $tfstate_resource_id"
            save_config_vars "${workload_config_information}" \
            tfstate_resource_id

            save_config_vars "${workload_config_information}" \
            keyvault \
            subscription \
            deployer_tfstate_key \
            REMOTE_STATE_SA \
            REMOTE_STATE_RG
        fi
    fi
else
    echo "tfstate_resource_id $tfstate_resource_id"
    save_config_vars "${workload_config_information}" \
    tfstate_resource_id
fi


init "${automation_config_directory}" "${generic_config_information}" "${workload_config_information}"

param_dirname=$(pwd)
var_file="${param_dirname}"/"${parameterfile}"
export TF_DATA_DIR="${param_dirname}/.terraform"

if [ -n "$subscription" ]
then
    if is_valid_guid "$subscription"  ; then
        echo "Valid subscription format"
    else
        printf -v val %-40.40s "$subscription"
        echo "#########################################################################################"
        echo "#                                                                                       #"
        echo -e "#   The provided subscription is not valid:$boldred ${val} $resetformatting#   "
        echo "#                                                                                       #"
        echo "#########################################################################################"

        echo "The provided subscription is not valid: ${val}" > "${workload_config_information}".err

        exit 65
    fi
fi
if [ 0 = "${deploy_using_msi_only:-}" ]; then
  if [ -n "$client_id" ]
  then
      if is_valid_guid "$client_id" ; then
          echo "Valid spn id format"
      else
          printf -v val %-40.40s "$client_id"
          echo "#########################################################################################"
          echo "#                                                                                       #"
          echo -e "#         The provided spn_id is not valid:$boldred ${val} $resetformatting   #"
          echo "#                                                                                       #"
          echo "#########################################################################################"
          exit 65
      fi
  fi

  if [ -n "$tenant_id" ]
  then
      if is_valid_guid "$tenant_id" ; then
          echo "Valid tenant id format"
      else
          printf -v val %-40.40s "$tenant_id"
          echo "#########################################################################################"
          echo "#                                                                                       #"
          echo -e "#       The provided tenant_id is not valid:$boldred ${val} $resetformatting  #"
          echo "#                                                                                       #"
          echo "#########################################################################################"
          exit 65
      fi

  fi
  #setting the user environment variables
  set_executing_user_environment_variables "${spn_secret}"
else
  #setting the user environment variables
  set_executing_user_environment_variables "N/A"
fi

if [[ -z ${REMOTE_STATE_SA} ]]; then
    load_config_vars "${workload_config_information}" "REMOTE_STATE_SA"
fi

load_config_vars "${workload_config_information}" "REMOTE_STATE_RG"
load_config_vars "${workload_config_information}" "tfstate_resource_id"

if [[ -z ${STATE_SUBSCRIPTION} ]]; then
    load_config_vars "${workload_config_information}" "STATE_SUBSCRIPTION"
fi

if [[ -z ${subscription} ]]; then
    load_config_vars "${workload_config_information}" "subscription"
fi

if [[ -z ${deployer_tfstate_key} ]]; then
    load_config_vars "${workload_config_information}" "deployer_tfstate_key"
fi

if [ -n "$tfstate_resource_id" ]
then
    REMOTE_STATE_RG=$(echo "$tfstate_resource_id" | cut -d / -f5)
    REMOTE_STATE_SA=$(echo "$tfstate_resource_id" | cut -d / -f9)
    STATE_SUBSCRIPTION=$(echo "$tfstate_resource_id" | cut -d / -f3)

    save_config_vars "${workload_config_information}" \
    REMOTE_STATE_SA \
    REMOTE_STATE_RG \
    STATE_SUBSCRIPTION
else
    get_and_store_sa_details ${REMOTE_STATE_SA} ${workload_config_information}
fi


if [ -z "$subscription" ]
then
  subscription="${STATE_SUBSCRIPTION}"
fi

if [ -z "$REMOTE_STATE_SA" ]
then
    if [ -z "$REMOTE_STATE_RG" ]
    then
        load_config_vars "${workload_config_information}" "tfstate_resource_id"
        if [ -n "${tfstate_resource_id}" ]
        then
            REMOTE_STATE_RG=$(echo "$tfstate_resource_id" | cut -d / -f5)
            REMOTE_STATE_SA=$(echo "$tfstate_resource_id" | cut -d / -f9)
            STATE_SUBSCRIPTION=$(echo "$tfstate_resource_id" | cut -d / -f3)
        fi
    fi

    tfstate_parameter=" -var tfstate_resource_id=${tfstate_resource_id}"
else
    if [ -z "$REMOTE_STATE_RG" ]
    then
        get_and_store_sa_details "${REMOTE_STATE_SA}" "${workload_config_information}"
        load_config_vars "${workload_config_information}" "STATE_SUBSCRIPTION"
        load_config_vars "${workload_config_information}" "REMOTE_STATE_RG"
        load_config_vars "${workload_config_information}" "tfstate_resource_id"
    fi
fi

if [ 1 = "${deploy_using_msi_only:-}" ]; then
  if [ -n "${keyvault}" ]
  then
      echo "Setting the secrets"

      allParams=$(printf " --workload --environment %s --region %s --vault %s --subscription %s --msi " "${environment}" "${region_code}" "${keyvault}"  "${subscription}" )

      echo "Calling set_secrets with " "${allParams}"

      "${SAP_AUTOMATION_REPO_PATH}"/deploy/scripts/set_secrets.sh ${allParams}

      if [ -f secret.err ]; then
          error_message=$(cat secret.err)
          echo "##vso[task.logissue type=error]${error_message}"
          rm secret.err
          exit 65
      fi
  fi

else
  if [ -n "${keyvault}" ]
  then
      echo "Setting the secrets"

      save_config_var "client_id" "${workload_config_information}"
      save_config_var "tenant_id" "${workload_config_information}"

      if [ -n "$spn_secret" ]
      then
          allParams=$(printf " --workload --environment %s --region %s --vault %s --spn_secret ***** --subscription %s --spn_id %s --tenant_id %s " "${environment}" "${region_code}" "${keyvault}"  "${subscription}" "${client_id}" "${tenant_id}" )

          echo "Calling set_secrets with " "${allParams}"

          allParams=$(printf " --workload --environment %s --region %s --vault %s --spn_secret %s --subscription %s --spn_id %s --tenant_id %s " "${environment}" "${region_code}" "${keyvault}" "${spn_secret}" "${subscription}" "${client_id}" "${tenant_id}" )

          "${SAP_AUTOMATION_REPO_PATH}"/deploy/scripts/set_secrets.sh ${allParams}

          if [ -f secret.err ]; then
              error_message=$(cat secret.err)
              echo "##vso[task.logissue type=error]${error_message}"

              exit 65
          fi
      else
          read -p "Do you want to specify the Workload SPN Details Y/N?"  ans
          answer=${ans^^}
          if [ ${answer} == 'Y' ]; then
              allParams=$(printf " --workload --environment %s --region %s --vault %s --subscription %s  --spn_id %s " "${environment}" "${region_code}" "${keyvault}" "${subscription}" "${client_id}" )

              "${SAP_AUTOMATION_REPO_PATH}"/deploy/scripts/set_secrets.sh ${allParams}
              if [ $? -eq 255 ]
              then
                  exit $?
              fi
          fi
      fi

      if [ -f kv.log ]
      then
          rm kv.log
      fi
  fi
fi
if [ -z "${deployer_tfstate_key}" ]
then
    load_config_vars "${workload_config_information}" "deployer_tfstate_key"
    if [ -n "${deployer_tfstate_key}" ]
    then
        # Deployer state was specified in $CONFIG_REPO_PATH/.sap_deployment_automation library config
        deployer_tfstate_key_parameter=" -var deployer_tfstate_key=${deployer_tfstate_key}"
    fi
else
    deployer_tfstate_key_parameter=" -var deployer_tfstate_key=${deployer_tfstate_key}"
    save_config_vars "${workload_config_information}" deployer_tfstate_key
fi

if [ -z "${REMOTE_STATE_SA}" ]; then
    read -p "Terraform state storage account name:"  REMOTE_STATE_SA
    get_and_store_sa_details "${REMOTE_STATE_SA}" "${workload_config_information}"
    load_config_vars "${workload_config_information}" "STATE_SUBSCRIPTION"
    load_config_vars "${workload_config_information}" "REMOTE_STATE_RG"
    load_config_vars "${workload_config_information}" "tfstate_resource_id"

    tfstate_parameter=" -var tfstate_resource_id=${tfstate_resource_id}"

    if [ -n "${STATE_SUBSCRIPTION}" ]
    then
        if [ $account_set == 0 ]
        then
            az account set --sub "${STATE_SUBSCRIPTION}"
            account_set=1
        fi
    fi
fi

if [ -z "${REMOTE_STATE_RG}" ]; then
    if [ -n "${REMOTE_STATE_SA}" ]; then
        get_and_store_sa_details ${REMOTE_STATE_SA} "${workload_config_information}"
        load_config_vars "${workload_config_information}" "STATE_SUBSCRIPTION"
        load_config_vars "${workload_config_information}" "REMOTE_STATE_RG"
        load_config_vars "${workload_config_information}" "tfstate_resource_id"

        tfstate_parameter=" -var tfstate_resource_id=${tfstate_resource_id}"
    else
        option="REMOTE_STATE_RG"
        read -p "Remote state resource group name:"  REMOTE_STATE_RG
        save_config_vars "${workload_config_information}" REMOTE_STATE_RG
    fi
fi

if [ -n "${tfstate_resource_id}" ]
then
    tfstate_parameter=" -var tfstate_resource_id=${tfstate_resource_id}"
else
    get_and_store_sa_details ${REMOTE_STATE_SA} "${workload_config_information}"
    load_config_vars "${workload_config_information}" "tfstate_resource_id"
    tfstate_parameter=" -var tfstate_resource_id=${tfstate_resource_id}"
fi

terraform_module_directory="$(realpath "${SAP_AUTOMATION_REPO_PATH}"/deploy/terraform/run/"${deployment_system}" )"

if [ ! -d "${terraform_module_directory}" ]
then
    printf -v val %-40.40s "$deployment_system"
    echo "#########################################################################################"
    echo "#                                                                                       #"
    echo -e "#  $boldred Incorrect system deployment type specified: ${val}$resetformatting#"
    echo "#                                                                                       #"
    echo "#     Valid options are:                                                                #"
    echo "#       sap_landscape                                                                   #"
    echo "#                                                                                       #"
    echo "#########################################################################################"
    echo ""
    exit 1
fi

ok_to_proceed=false
new_deployment=false

#Plugins
sudo mkdir -p /opt/terraform/.terraform.d/plugin-cache
sudo chown -R $USER:$USER /opt/terraform

export TF_PLUGIN_CACHE_DIR=/opt/terraform/.terraform.d/plugin-cache

root_dirname=$(pwd)

echo "     subscription_id=${STATE_SUBSCRIPTION}"
echo " resource_group_name=${REMOTE_STATE_RG}"
echo "storage_account_name=${REMOTE_STATE_SA}"


if [ ! -d ./.terraform/ ];
then
    terraform -chdir="${terraform_module_directory}" init -upgrade=true  \
    --backend-config "subscription_id=${STATE_SUBSCRIPTION}"             \
    --backend-config "resource_group_name=${REMOTE_STATE_RG}"            \
    --backend-config "storage_account_name=${REMOTE_STATE_SA}"           \
    --backend-config "container_name=tfstate"                            \
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
        check_output=1
        terraform -chdir="${terraform_module_directory}" init -upgrade=true -reconfigure \
        --backend-config "subscription_id=${STATE_SUBSCRIPTION}"                         \
        --backend-config "resource_group_name=${REMOTE_STATE_RG}"                        \
        --backend-config "storage_account_name=${REMOTE_STATE_SA}"                       \
        --backend-config "container_name=tfstate"                                        \
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
    echo "Terraform initialization failed" > "${workload_config_information}".err
    exit $return_value
fi

check_output=0
echo ""
echo "#########################################################################################"
echo "#                                                                                       #"
echo -e "#       $cyan Changing the subscription to: ${subscription} $resetformatting            #"
echo "#                                                                                       #"
echo "#########################################################################################"
echo ""
#az account set --sub "${subscription}"

save_config_var "REMOTE_STATE_SA" "${workload_config_information}"
save_config_var "subscription" "${workload_config_information}"
save_config_var "STATE_SUBSCRIPTION" "${workload_config_information}"
save_config_var "tfstate_resource_id" "${workload_config_information}"

if [ 1 == $check_output ]
then
    outputs=$(terraform -chdir="${terraform_module_directory}" output)
    if echo "${outputs}" | grep "No outputs"; then
        ok_to_proceed=true
        new_deployment=true
        echo "#########################################################################################"
        echo "#                                                                                       #"
        echo -e "#                                  $cyan New deployment $resetformatting                                     #"
        echo "#                                                                                       #"
        echo "#########################################################################################"
    else
        echo ""
        echo "#########################################################################################"
        echo "#                                                                                       #"
        echo -e "#                          $cyan Existing deployment was detected $resetformatting                           #"
        echo "#                                                                                       #"
        echo "#########################################################################################"
        echo ""

        workloadkeyvault=$(terraform -chdir="${terraform_module_directory}" output -no-color -raw workloadzone_kv_name | tr -d \")
        if valid_kv_name "$workloadkeyvault" ; then
            save_config_var "workloadkeyvault" "${workload_config_information}"
        fi

        deployed_using_version=$(terraform -chdir="${terraform_module_directory}" output -no-color -raw automation_version)
        if [ -z "${deployed_using_version}" ]; then
            echo ""
            echo "#########################################################################################"
            echo "#                                                                                       #"
            echo -e "#   $boldred The environment was deployed using an older version of the Terrafrom templates $resetformatting    #"
            echo "#                                                                                       #"
            echo "#                               !!! Risk for Data loss !!!                              #"
            echo "#                                                                                       #"
            echo "#        Please inspect the output of Terraform plan carefully before proceeding        #"
            echo "#                                                                                       #"
            echo "#########################################################################################"
            if [ 1 == $called_from_ado ] ; then
                unset TF_DATA_DIR
                echo "The environment was deployed using an older version of the Terrafrom templates, Risk for data loss" > "${workload_config_information}".err

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
            printf -v val %-.20s "$deployed_using_version"
            echo ""
            echo "#########################################################################################"
            echo "#                                                                                       #"
            echo -e "#             $cyan Deployed using the Terraform templates version: $val $resetformatting               #"
            echo "#                                                                                       #"
            echo "#########################################################################################"
            echo ""
            #Add version logic here
        fi
    fi
fi

# ip_saved=0
# if [ 1 == $called_from_ado ] ; then

#     load_config_vars "${workload_config_information}" "azure_files_transport_storage_account_id"
#     echo "Transport SA: " ${azure_files_transport_storage_account_id}
#     if [ -n "${azure_files_transport_storage_account_id}" ]; then
#         RG=$(echo "$azure_files_transport_storage_account_id" | cut -d / -f5)
#         SA=$(echo "$azure_files_transport_storage_account_id" | cut -d / -f9)
#         SUB=$(echo "$azure_files_transport_storage_account_id" | cut -d / -f3)
#         az storage account network-rule add --resource-group "${RG}" --account-name "${SA}" --subscription "${SUB}"  --ip-address $this_ip
#         echo "Wait 60 seconds for network rule"
#         sleep 60
#     else
#         azure_files_transport_storage_account_id=$(terraform -chdir="${terraform_module_directory}"  output azure_files_transport_storage_account_id | tr -d \")
#         echo "Transport SA: " ${azure_files_transport_storage_account_id}
#         RG=$(echo "$azure_files_transport_storage_account_id" | cut -d / -f5)
#         SA=$(echo "$azure_files_transport_storage_account_id" | cut -d / -f9)
#         SUB=$(echo "$azure_files_transport_storage_account_id" | cut -d / -f3)
#         if [ -n "${SA}" ]; then
#             az storage account network-rule add --resource-group "${RG}" --account-name "${SA}" --subscription "${SUB}" --ip-address $this_ip
#             echo "Wait 60 seconds for network rule"
#             sleep 60
#             ip_saved=1
#             save_config_var "azure_files_transport_storage_account_id" "${workload_config_information}"
#         fi
#     fi
# fi

echo ""
echo "#########################################################################################"
echo "#                                                                                       #"
echo -e "#                           $cyan  Running Terraform plan $resetformatting                                   #"
echo "#                                                                                       #"
echo "#########################################################################################"
echo ""

if [ 1 == $called_from_ado ] ; then
  terraform -chdir="${terraform_module_directory}" plan -no-color -detailed-exitcode  -var-file=${var_file} $tfstate_parameter $deployer_tfstate_key_parameter  | tee -a plan_output.log
else
  terraform -chdir="${terraform_module_directory}" plan -detailed-exitcode  -var-file=${var_file} $tfstate_parameter $deployer_tfstate_key_parameter  | tee -a plan_output.log
fi
return_value=$?

echo "Terraform Plan return code: " $return_value
if [ 1 == $return_value ]
then
    echo "#########################################################################################"
    echo "#                                                                                       #"
    echo -e "#                           $boldreduscore  Errors running plan $resetformatting                                   #"
    echo "#                                                                                       #"
    echo "#########################################################################################"
    echo ""
    if [ -f plan_output.log ] ; then
        cat plan_output.log
        rm plan_output.log
    fi
    unset TF_DATA_DIR
    echo "Errors running Terraform plan" > "${workload_config_information}".err
    exit $return_value
fi

  echo "TEST_ONLY: " $TEST_ONLY
  if [ "${TEST_ONLY}" == "True" ]; then
      echo ""
      echo "#########################################################################################"
      echo "#                                                                                       #"
      echo -e "#                                 $cyan Running plan only. $resetformatting                                  #"
      echo "#                                                                                       #"
      echo "#                                  No deployment performed.                             #"
      echo "#                                                                                       #"
      echo "#########################################################################################"
      echo ""
      exit 0
  fi


ok_to_proceed=0
if [ -f plan_output.log ]; then
    cat plan_output.log
    LASTERROR=$(grep -m1 'Error: ' plan_output.log )

    if [ -n "${LASTERROR}" ] ; then
        echo "3"
        if [ 1 == $called_from_ado ] ; then
            echo "##vso[task.logissue type=error]$LASTERROR"
        fi


        return_value=1
    fi
fi

if [ 0 == $return_value ] ; then
    if [ -f plan_output.log ]
    then
        rm plan_output.log
    fi

    workloadkeyvault=$(terraform -chdir="${terraform_module_directory}" output -no-color -raw workloadzone_kv_name | tr -d \")
    if valid_kv_name "$workloadkeyvault" ; then
        save_config_var "workloadkeyvault" "${workload_config_information}"
    fi
    save_config_vars "landscape_tfstate_key" "${workload_config_information}"

    ok_to_proceed=1
fi

if [ 2 == $return_value ] ; then
    test=$(grep kv_user plan_output.log | grep -m1 replaced)
    if [ -n "${test}" ] ; then
        echo ""
        echo "#########################################################################################"
        echo "#                                                                                       #"
        echo -e "#                              $boldred !!! Risk for Data loss !!! $resetformatting                             #"
        echo "#                                                                                       #"
        echo "#        Please inspect the output of Terraform plan carefully before proceeding        #"
        echo "#                                                                                       #"
        echo "#########################################################################################"
        echo ""
        if [ 1 == $called_from_ado ] ; then
            unset TF_DATA_DIR
            exit 1
        fi
        read -n 1 -r -s -p $'Press enter to continue...\n'

        cat plan_output.log
        read -p "Do you want to continue with the deployment Y/N?"  ans
        answer=${ans^^}
        if [ $answer == 'Y' ]; then
            ok_to_proceed=1
        else
            unset TF_DATA_DIR

            exit 0
        fi
    else
        ok_to_proceed=1
    fi
fi

if [ 1 == $ok_to_proceed ]; then
    echo ""
    echo "#########################################################################################"
    echo "#                                                                                       #"
    echo  -e "#                            $cyan Running Terraform apply $resetformatting                                  #"
    echo "#                                                                                       #"
    echo "#########################################################################################"
    echo ""

    parallelism=10

    #Provide a way to limit the number of parallell tasks for Terraform
    if [[ -n "${TF_PARALLELLISM}" ]]; then
        parallelism=$TF_PARALLELLISM
    fi

    if [ 1 == $called_from_ado ] ; then
        terraform -chdir="${terraform_module_directory}" apply ${approve} -parallelism="${parallelism}" -no-color -var-file=${var_file} $tfstate_parameter $landscape_tfstate_key_parameter $deployer_tfstate_key_parameter -json  | tee -a  apply_output.json
    else
        if [ -n "${approve}" ]
        then
          terraform -chdir="${terraform_module_directory}" apply ${approve} -parallelism="${parallelism}" -var-file=${var_file} $tfstate_parameter $landscape_tfstate_key_parameter $deployer_tfstate_key_parameter -json  | tee -a  apply_output.json
        else
          terraform -chdir="${terraform_module_directory}" apply ${approve} -parallelism="${parallelism}" -var-file=${var_file} $tfstate_parameter $landscape_tfstate_key_parameter $deployer_tfstate_key_parameter
        fi

    fi

    return_value=$?

fi
rerun_apply=0
if [ -f apply_output.json ]
then
    # Check for resource that can be imported
    existing=$(jq 'select(."@level" == "error") | {address: .diagnostic.address, summary: .diagnostic.summary}  | select(.summary | startswith("A resource with the ID"))' apply_output.json)
    if [[ -n ${existing} ]]
    then

        readarray -t existing_resources < <(echo ${existing} | jq -c '.' )
        for item in "${existing_resources[@]}"; do
            moduleID=$(jq -c -r '.address '  <<< "$item")
            resourceID=$(jq -c -r '.summary' <<< "$item" | awk -F'\"' '{print $2}')
            echo "Trying to import" $resourceID "into" $moduleID
            allParamsforImport=$(printf " -var-file=%s %s %s %s %s %s %s %s " "${var_file}" "${extra_vars}" "${tfstate_parameter}" "${landscape_tfstate_key_parameter}" "${deployer_tfstate_key_parameter}" "${deployment_parameter}" "${version_parameter} " )
            echo terraform -chdir="${terraform_module_directory}" import $allParamsforImport $moduleID $resourceID
            terraform -chdir="${terraform_module_directory}" import $allParamsforImport $moduleID $resourceID
        done

        rerun_apply=1
        rm apply_output.json
        echo ""
        echo ""
        echo "#########################################################################################"
        echo "#                                                                                       #"
        echo -e "#                          $cyan Re running Terraform apply$resetformatting                                  #"
        echo "#                                                                                       #"
        echo "#########################################################################################"
        echo ""
        echo ""
        if [ 1 == $called_from_ado ] ; then
            terraform -chdir="${terraform_module_directory}" apply ${approve} -parallelism="${parallelism}" -no-color -var-file=${var_file} $tfstate_parameter $landscape_tfstate_key_parameter $deployer_tfstate_key_parameter -json  | tee -a  apply_output.json
        else
            terraform -chdir="${terraform_module_directory}" apply ${approve} -parallelism="${parallelism}" -var-file=${var_file} $tfstate_parameter $landscape_tfstate_key_parameter $deployer_tfstate_key_parameter -json  | tee -a  apply_output.json
        fi
        return_value=$?

    fi

    if [ -f apply_output.json ]
    then
        # Check for resource that can be imported
        existing=$(jq 'select(."@level" == "error") | {address: .diagnostic.address, summary: .diagnostic.summary}  | select(.summary | startswith("A resource with the ID"))' apply_output.json)
        if [[ -n ${existing} ]]
        then

            readarray -t existing_resources < <(echo ${existing} | jq -c '.' )
            for item in "${existing_resources[@]}"; do
                moduleID=$(jq -c -r '.address '  <<< "$item")
                resourceID=$(jq -c -r '.summary' <<< "$item" | awk -F'\"' '{print $2}')
                echo "Trying to import" $resourceID "into" $moduleID
                allParamsforImport=$(printf " -var-file=%s %s %s %s %s %s %s %s " "${var_file}" "${extra_vars}" "${tfstate_parameter}" "${landscape_tfstate_key_parameter}" "${deployer_tfstate_key_parameter}" "${deployment_parameter}" "${version_parameter} " )
                echo terraform -chdir="${terraform_module_directory}" import $allParamsforImport $moduleID $resourceID
                terraform -chdir="${terraform_module_directory}" import $allParamsforImport $moduleID $resourceID
            done

            rerun_apply=1
        fi
        if [ $rerun_apply == 1 ] ; then
            echo ""
            echo ""
            echo "#########################################################################################"
            echo "#                                                                                       #"
            echo -e "#                          $cyan Re running Terraform apply$resetformatting                                  #"
            echo "#                                                                                       #"
            echo "#########################################################################################"
            echo ""
            echo ""
            if [ 1 == $called_from_ado ] ; then
                terraform -chdir="${terraform_module_directory}" apply ${approve} -parallelism="${parallelism}" -no-color -var-file=${var_file} $tfstate_parameter $landscape_tfstate_key_parameter $deployer_tfstate_key_parameter -json  | tee -a  apply_output.json
            else
                terraform -chdir="${terraform_module_directory}" apply ${approve} -parallelism="${parallelism}" -var-file=${var_file} $tfstate_parameter $landscape_tfstate_key_parameter $deployer_tfstate_key_parameter -json  | tee -a  apply_output.json
            fi
            return_value=$?
        fi

        return_value=0
        errors_occurred=$(jq 'select(."@level" == "error") | length' apply_output.json)

        if [[ -n $errors_occurred ]]
        then
          echo ""
          echo "#########################################################################################"
          echo "#                                                                                       #"
          echo -e "#                          $boldreduscore!Errors during the apply phase!$resetformatting                              #"

          return_value=2
          all_errors=$(jq 'select(."@level" == "error") | {summary: .diagnostic.summary, detail: .diagnostic.detail} | select(.summary ) ' apply_output.json)
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
                      if [ 1 == $called_from_ado ] ; then

                          roleAssignmentExists=$(echo ${report} | grep -m1 "RoleAssignmentExists")
                          if [ -z ${roleAssignmentExists} ] ; then
                              echo "##vso[task.logissue type=error]${report}"
                          fi
                      fi
                  else
                      echo -e "#                          $boldreduscore  $string_to_report $resetformatting"
                      if [ 1 == $called_from_ado ] ; then
                          roleAssignmentExists=$(echo ${string_to_report} | grep -m1 "RoleAssignmentExists")
                          if [ -z ${roleAssignmentExists} ]
                          then
                              echo "##vso[task.logissue type=error]${string_to_report}"
                          fi
                      fi
                  fi
                  echo -e "#                          $boldreduscore  $string_to_report $resetformatting"

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

workload_zone_prefix=$(terraform -chdir="${terraform_module_directory}" output -no-color -raw workload_zone_prefix | tr -d \")
save_config_var "workload_zone_prefix" "${workload_config_information}"
save_config_var "landscape_tfstate_key" "${workload_config_information}"

if [ 0 == $return_value ] ; then

    save_config_vars "landscape_tfstate_key" "${workload_config_information}"
    workloadkeyvault=$(terraform -chdir="${terraform_module_directory}" output -no-color -raw workloadzone_kv_name | tr -d \")

    temp=$(echo "${workloadkeyvault}" | grep "Warning")
    if [ -z "${temp}" ]
    then
        temp=$(echo "${workloadkeyvault}" | grep "Backend reinitialization required")
        if [ -z "${temp}" ]
        then

            printf -v val %-.20s "$workloadkeyvault"

            echo ""
            echo "#########################################################################################"
            echo "#                                                                                       #"
            echo -e "#                Keyvault to use for System details:$cyan $val $resetformatting               #"
            echo "#                                                                                       #"
            echo "#########################################################################################"
            echo ""

            save_config_var "workloadkeyvault" "${workload_config_information}"
        fi
    fi

fi

if [ 0 != $return_value ] ; then
    unset TF_DATA_DIR
    exit $return_value
fi

echo ""
echo "#########################################################################################"
echo "#                                                                                       #"
echo  -e "#                            $cyan Creating deployment     $resetformatting                                  #"
echo "#                                                                                       #"
echo "#########################################################################################"
echo ""

if [ -n "${spn_secret}" ]
then
    az logout
    echo "Login as SPN"
    az login --service-principal --username "${client_id}" --password="${spn_secret}" --tenant "${tenant_id}" --output none
fi

rg_name=$(terraform -chdir="${terraform_module_directory}"  output -no-color -raw created_resource_group_name | tr -d \")
az deployment group create --resource-group "${rg_name}" --name "SAP-WORKLOAD-ZONE_${rg_name}" --subscription "${subscription}" --template-file "${script_directory}/templates/empty-deployment.json" --output none

now=$(date)
cat <<EOF > "${workload_config_information}".md
# Workload Zone Deployment #

Date : "${now}"

## Configuration details ##

| Item                    | Name                 |
| ----------------------- | -------------------- |
| Environment             | $environment         |
| Location                | $region              |
| Keyvault Name           | ${workloadkeyvault}  |

EOF

if [ -f "${workload_config_information}".err ]; then
    cat "${workload_config_information}".err
fi

echo ""
echo "#########################################################################################"
echo "#                                                                                       #"
echo -e "#             $cyan  Adding the subnets to storage account firewalls $resetformatting                        #"
echo "#                                                                                       #"
echo "#########################################################################################"
echo ""

subnet_id=$(terraform -chdir="${terraform_module_directory}"  output -no-color -raw app_subnet_id | tr -d \")

useSAS=$(az storage account show  --name  "${REMOTE_STATE_SA}"   --query allowSharedKeyAccess --subscription "${STATE_SUBSCRIPTION}" --out tsv)
echo "useSAS = $useSAS"

if [ -n "${subnet_id}" ]; then
  echo "Adding the app subnet"
  az storage account network-rule add --resource-group "${REMOTE_STATE_RG}" --account-name "${REMOTE_STATE_SA}" --subscription "${STATE_SUBSCRIPTION}" --subnet $subnet_id --output none
  if [ -n "$SAPBITS" ] ; then
    az storage account network-rule add --resource-group "${REMOTE_STATE_RG}" --account-name $SAPBITS --subscription "${STATE_SUBSCRIPTION}" --subnet $subnet_id --output none
  fi
fi

subnet_id=$(terraform -chdir="${terraform_module_directory}"  output -no-color -raw db_subnet_id | tr -d \")

if [ -n "${subnet_id}" ]; then
  echo "Adding the db subnet"
  az storage account network-rule add --resource-group "${REMOTE_STATE_RG}" --account-name "${REMOTE_STATE_SA}" --subscription "${STATE_SUBSCRIPTION}" --subnet $subnet_id --output none
fi

unset TF_DATA_DIR


#################################################################################
#                                                                               #
#                           Copy tfvars to storage account                      #
#                                                                               #
#                                                                               #
#################################################################################

if [ "$useSAS" = "true" ] ; then
  container_exists=$(az storage container exists --subscription "${STATE_SUBSCRIPTION}" --account-name "${REMOTE_STATE_SA}" --name tfvars --only-show-errors --query exists)
else
  container_exists=$(az storage container exists --subscription "${STATE_SUBSCRIPTION}" --account-name "${REMOTE_STATE_SA}" --name tfvars --only-show-errors --query exists --auth-mode login)
fi

if [ "${container_exists}" == "false" ]; then
  if [ "$useSAS" = "true" ] ; then
    az storage container create --subscription "${STATE_SUBSCRIPTION}" --account-name "${REMOTE_STATE_SA}" --name tfvars --only-show-errors
  else
    az storage container create --subscription "${STATE_SUBSCRIPTION}" --account-name "${REMOTE_STATE_SA}" --name tfvars --auth-mode login --only-show-errors
  fi
fi

if [ "$useSAS" = "true" ] ; then
  az storage blob upload --file "${parameterfile}" --container-name tfvars/LANDSCAPE/"${key}" --name "${parameterfile_name}" --subscription "${STATE_SUBSCRIPTION}" --account-name "${REMOTE_STATE_SA}"  --no-progress --overwrite --only-show-errors  --output none
else
  az storage blob upload --file "${parameterfile}" --container-name tfvars/LANDSCAPE/"${key}" --name "${parameterfile_name}" --subscription "${STATE_SUBSCRIPTION}" --account-name "${REMOTE_STATE_SA}"  --no-progress --overwrite --auth-mode login --only-show-errors  --output none
fi


exit $return_value
