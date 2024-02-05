#!/bin/bash

################################################################################################
#                                                                                              #
#   This file contains the logic to deploy the environment to support SAP workloads.           #
#                                                                                              #
#   The script is intended to be run from a parent folder to the folders containing            #
#   the json parameter files for the deployer, the library and the environment.                #
#                                                                                              #
#   The script will persist the parameters needed between the executions in the                #
#   $CONFIG_REPO_PATH/.sap_deployment_automation folder                                        #
#                                                                                              #
#   The script experts the following exports:                                                  #
#   ARM_SUBSCRIPTION_ID to specify which subscription to deploy to                             #
#   SAP_AUTOMATION_REPO_PATH the path to the folder containing the cloned sap-automation       #
#   CONFIG_REPO_PATH the path to the folder containing the configuration for sap               #
#                                                                                              #
################################################################################################

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

force=0
recover=0
ado_flag=""
deploy_using_msi_only=0

INPUT_ARGUMENTS=$(getopt -n deploy_controlplane -o d:l:s:c:p:t:a:k:ifohrvm --longoptions deployer_parameter_file:,library_parameter_file:,subscription:,spn_id:,spn_secret:,tenant_id:,storageaccountname:,vault:,auto-approve,force,only_deployer,help,recover,ado,msi -- "$@")
VALID_ARGUMENTS=$?

if [ "$VALID_ARGUMENTS" != "0" ]; then
    control_plane_showhelp
fi

eval set -- "$INPUT_ARGUMENTS"
while :;
do
    case "$1" in
        -a | --storageaccountname)                 REMOTE_STATE_SA="$2"             ; shift 2 ;;
        -c | --spn_id)                             client_id="$2"                   ; shift 2 ;;
        -d | --deployer_parameter_file)            deployer_parameter_file="$2"     ; shift 2 ;;
        -k | --vault)                              keyvault="$2"                    ; shift 2 ;;
        -l | --library_parameter_file)             library_parameter_file="$2"      ; shift 2 ;;
        -p | --spn_secret)                         spn_secret="$2"                  ; shift 2 ;;
        -s | --subscription)                       subscription="$2"                ; shift 2 ;;
        -t | --tenant_id)                          tenant_id="$2"                   ; shift 2 ;;
        -f | --force)                              force=1                          ; shift ;;
        -i | --auto-approve)                       approve="--auto-approve"         ; shift ;;
        -m | --msi)                                deploy_using_msi_only=1          ; shift ;;
        -o | --only_deployer)                      only_deployer=1                  ; shift ;;
        -r | --recover)                            recover=1                        ; shift ;;
        -v | --ado)                                ado_flag="--ado"                 ; shift ;;
        -h | --help)                               control_plane_showhelp
        exit 3                           ; shift ;;
        --) shift; break ;;
    esac
done

echo "ADO flag ${ado_flag}"

this_ip=$(curl -s ipinfo.io/ip) >/dev/null 2>&1
root_dirname=$(pwd)

if [ ! -f /etc/profile.d/deploy_server.sh ] ; then
    export TF_VAR_Agent_IP=$this_ip
fi

if [ -n "$approve" ]; then
    approveparam=" --auto-approve"
fi

if [ ! -f "$deployer_parameter_file" ]; then
    export missing_value='deployer parameter file'
    control_plane_missing
    exit 2 #No such file or directory
fi

if [ ! -f "$library_parameter_file" ]; then
    export missing_value='library parameter file'
    control_plane_missing
    exit 2 #No such file or directory
fi

# Check that Terraform and Azure CLI is installed
validate_dependencies
return_code=$?
if [ 0 != $return_code ]; then
    echo "validate_dependencies returned $return_code"
    exit $return_code
fi

# Check that parameter files have environment and location defined
validate_key_parameters "$deployer_parameter_file"
if [ 0 != $return_code ]; then
    echo "Errors in parameter file" > "${deployer_config_information}".err
    exit $return_code
fi

# Convert the region to the correct code
get_region_code "$region"

echo "Region code for deployment:  $region_code"

automation_config_directory=$CONFIG_REPO_PATH/.sap_deployment_automation
generic_config_information="${automation_config_directory}"/config
deployer_config_information="${automation_config_directory}"/"${environment}""${region_code}"

if [ $force == 1 ]; then
    if [ -f "${deployer_config_information}" ]; then
        rm "${deployer_config_information}"
    fi
fi

init "${automation_config_directory}" "${generic_config_information}" "${deployer_config_information}"

# Check that the exports ARM_SUBSCRIPTION_ID and SAP_AUTOMATION_REPO_PATH are defined
validate_exports
return_code=$?
if [ 0 != $return_code ]; then
    echo "Missing exports" > "${deployer_config_information}".err
    exit $return_code
fi
# Check that webapp exports are defined, if deploying webapp
if [ -n "${TF_VAR_use_webapp}" ]; then
    if [ "${TF_VAR_use_webapp}" == "true" ]; then
        validate_webapp_exports
        return_code=$?
        if [ 0 != $return_code ]; then
            exit $return_code
        fi
    fi
fi

deployer_dirname=$(dirname "${deployer_parameter_file}")
deployer_file_parametername=$(basename "${deployer_parameter_file}")

library_dirname=$(dirname "${library_parameter_file}")
library_file_parametername=$(basename "${library_parameter_file}")

relative_path="${deployer_dirname}"
export TF_DATA_DIR="${relative_path}"/.terraform

step=0

echo "#########################################################################################"
echo "#                                                                                       #"
echo -e "#                   $cyan Starting the control plane deployment $resetformatting                             #"
echo "#                                                                                       #"
echo "#########################################################################################"

noAccess=$( az account show --query name | grep  "N/A(tenant level account)")

if [ -n "$noAccess" ]; then
  echo "#########################################################################################"
  echo "#                                                                                       #"
  echo -e "#        $boldred The provided credentials do not have access to the subscription!!! $resetformatting           #"
  echo "#                                                                                       #"
  echo "#########################################################################################"

  az account show --output table

  exit 65
fi
az account list --query "[].{Name:name,Id:id}" --output table
#setting the user environment variables
if [ -n "${subscription}" ]; then
    if is_valid_guid "$subscription"; then
        echo ""
    else
        printf -v val %-40.40s "$subscription"
        echo "#########################################################################################"
        echo "#                                                                                       #"
        echo -e "#   The provided subscription is not valid:$boldred ${val} $resetformatting#   "
        echo "#                                                                                       #"
        echo "#########################################################################################"

        echo "The provided subscription is not valid: ${subscription}" > "${deployer_config_information}".err

        exit 65
    fi
    echo ""
    echo "#########################################################################################"
    echo "#                                                                                       #"
    echo -e "#       $cyan Changing the subscription to: $subscription $resetformatting            #"
    echo "#                                                                                       #"
    echo "#########################################################################################"
    echo ""

    if [ -z $keyvault ] ; then
        load_config_vars "${deployer_config_information}" "keyvault"
    fi

    if [ -n "${keyvault}" ] ; then


      kv_found=$(az keyvault list --subscription "${subscription}" --query [].name | grep  "${keyvault}")

      if [ -z "${kv_found}" ] ; then
          echo "#########################################################################################"
          echo "#                                                                                       #"
          echo -e "#                            $boldred  Detected a failed deployment $resetformatting                            #"
          echo "#                                                                                       #"
          echo -e "#                                  $cyan Trying to recover $resetformatting                                  #"
          echo "#                                                                                       #"
          echo "#########################################################################################"
          step=0
          save_config_var "step" "${deployer_config_information}"
      fi
    else
      step=0
      save_config_var "step" "${deployer_config_information}"

    fi



fi


load_config_vars "${deployer_config_information}" "step"

if [ 0 = "${deploy_using_msi_only:-}" ]; then
  echo "Using Service Principal for deployment"
  set_executing_user_environment_variables "${spn_secret}"
else
  echo "Using Managed Identity for deployment"
  set_executing_user_environment_variables "none"
fi

if [ $recover == 1 ]; then
    if [ -n "$REMOTE_STATE_SA" ]; then
        save_config_var "REMOTE_STATE_SA" "${deployer_config_information}"
        get_and_store_sa_details ${REMOTE_STATE_SA} "${deployer_config_information}"
        #Support running deploy_controlplane on new host when the resources are already deployed
        step=3
        save_config_var "step" "${deployer_config_information}"
    fi
fi

curdir=$(pwd)
if [ 0 == $step ]; then
    echo ""
    echo "#########################################################################################"
    echo "#                                                                                       #"
    echo -e "#                          $cyan Bootstrapping the deployer $resetformatting                                 #"
    echo "#                                                                                       #"
    echo "#########################################################################################"
    echo ""

    allParams=$(printf " --parameterfile %s %s" "${deployer_file_parametername}" "${approveparam}")

    echo $allParams

    cd "${deployer_dirname}" || exit

    if [ $force == 1 ]; then
        rm -Rf .terraform terraform.tfstate*
    fi

    "${SAP_AUTOMATION_REPO_PATH}"/deploy/scripts/install_deployer.sh $allParams
    return_code=$?
    if [ 0 != $return_code ]; then
        echo "Bootstrapping of the deployer failed" > "${deployer_config_information}".err
        exit 10
    fi

    load_config_vars "${deployer_config_information}" "keyvault"
    echo "Key vault:" $keyvault

    if [ -z "$keyvault" ]; then
        echo "#########################################################################################"
        echo "#                                                                                       #"
        echo -e "#                       $boldred  Bootstrapping of the deployer failed $resetformatting                         #"
        echo "#                                                                                       #"
        echo "#########################################################################################"
        echo "Bootstrapping of the deployer failed" > "${deployer_config_information}".err
        exit 10
    fi

    #Persist the parameters
    if [ -n "$subscription" ]; then
        save_config_var "subscription" "${deployer_config_information}"
        export STATE_SUBSCRIPTION=$subscription
        save_config_var "STATE_SUBSCRIPTION" "${deployer_config_information}"
    fi

    if [ -n "$client_id" ]; then
        save_config_var "client_id" "${deployer_config_information}"
    fi

    if [ -n "$tenant_id" ]; then
        save_config_var "tenant_id" "${deployer_config_information}"
    fi

    if [ -n "${FORCE_RESET}" ]; then
      step=3
      save_config_var "step" "${deployer_config_information}"
      exit 0
    else
      export step=1
    fi
    save_config_var "step" "${deployer_config_information}"

    cd "$root_dirname" || exit

    load_config_vars "${deployer_config_information}" "sshsecret"
    load_config_vars "${deployer_config_information}" "keyvault"
    load_config_vars "${deployer_config_information}" "deployer_public_ip_address"

    echo "##vso[task.setprogress value=20;]Progress Indicator"
else
    echo ""
    echo "#########################################################################################"
    echo "#                                                                                       #"
    echo -e "#                          $cyan Deployer is bootstrapped $resetformatting                                   #"
    echo "#                                                                                       #"
    echo "#########################################################################################"
    echo ""
    echo "##vso[task.setprogress value=20;]Progress Indicator"
fi

cd "$root_dirname" || exit

if [ 1 == $step ] || [ 3 == $step ] ; then

    if [ -z "$keyvault" ]; then

      key=$(echo "${deployer_file_parametername}" | cut -d. -f1)
      if [ $recover == 1 ]; then
        terraform_module_directory="$SAP_AUTOMATION_REPO_PATH"/deploy/terraform/run/sap_deployer/
        terraform -chdir="${terraform_module_directory}" init -upgrade=true     \
        --backend-config "subscription_id=${STATE_SUBSCRIPTION}"                \
        --backend-config "resource_group_name=${REMOTE_STATE_RG}"               \
        --backend-config "storage_account_name=${REMOTE_STATE_SA}"              \
        --backend-config "container_name=tfstate"                               \
        --backend-config "key=${key}.terraform.tfstate"

        keyvault=$(terraform -chdir="${terraform_module_directory}"  output deployer_kv_user_name | tr -d \")
      fi
    fi

    if [ -z "$keyvault" ]; then
        if [ $ado_flag != "--ado" ] ; then
            read -r -p "Deployer keyvault name: " keyvault
        else
            exit 10
        fi
    fi

    secretname="${environment}"-subscription-id
    echo ""
    echo "#########################################################################################"
    echo "#                                                                                       #"
    echo -e "#              $cyan Validating keyvault access to $keyvault $resetformatting                      #"
    echo "#                                                                                       #"
    echo "#########################################################################################"
    echo ""

    kv_name_check=$(az keyvault list --query "[?name=='$keyvault'].name | [0]" --subscription "${subscription}")
    if [ -z $kv_name_check ]; then
      echo ""
      echo "#########################################################################################"
      echo "#                                                                                       #"
      echo -e "#                             $cyan  Retrying keyvault access $resetformatting                               #"
      echo "#                                                                                       #"
      echo "#########################################################################################"
      echo ""
      sleep 60
      kv_name_check=$(az keyvault list --query "[?name=='$keyvault'].name | [0]" --subscription "${subscription}")
    fi

    if [ -z $kv_name_check ]; then
        echo "#########################################################################################"
        echo "#                                                                                       #"
        echo -e "#                               $boldred  Unable to access keyvault: $keyvault $resetformatting                            #"
        echo "#                             Please ensure the key vault exists.                       #"
        echo "#                                                                                       #"
        echo "#########################################################################################"
        echo ""
        exit 10
    fi

    access_error=$(az keyvault secret list --vault "$keyvault" --subscription "${subscription}" --only-show-errors | grep "The user, group or application")
    if [ -z "${access_error}" ]; then
        # save_config_var "client_id" "${deployer_config_information}"
        # save_config_var "tenant_id" "${deployer_config_information}"

        if [ -n "$spn_secret" ]; then
            allParams=$(printf " -e %s -r %s -v %s --spn_secret %s " "${environment}" "${region_code}" "${keyvault}" "${spn_secret}")

            "${SAP_AUTOMATION_REPO_PATH}"/deploy/scripts/set_secrets.sh $allParams
            if [ -f secret.err ]; then
                error_message=$(cat secret.err)
                echo "##vso[task.logissue type=error]${error_message}"

                exit 65
            fi

            return_code=$?
            if [ 0 != $return_code ]; then
                echo "Could not set the secrets in key vault" > "${deployer_config_information}".err
                exit $return_code
            fi
        else
            if [ 0 = "${deploy_using_msi_only:-}" ]; then


              read -p "Do you want to specify the SPN Details Y/N?" ans
              answer=${ans^^}
              if [ "$answer" == 'Y' ]; then
                  allParams=$(printf " -e %s -r %s -v %s " "${environment}" "${region_code}" "${keyvault}" )

                  #$allParams as an array (); array math can be done in shell, allowing dynamic parameter lists to be created
                  #"${allParams[@]}" - quotes all elements of the array

                  "${SAP_AUTOMATION_REPO_PATH}"/deploy/scripts/set_secrets.sh $allParams
                  return_code=$?
                  if [ 0 != $return_code ]; then
                      exit $return_code
                  fi
              fi
            else
              allParams=$(printf " -e %s -r %s -v %s --subscription %s --msi " "${environment}" "${region_code}" "${keyvault}" "${subscription}")

              "${SAP_AUTOMATION_REPO_PATH}"/deploy/scripts/set_secrets.sh $allParams
              if [ -f secret.err ]; then
                  error_message=$(cat secret.err)
                  echo "##vso[task.logissue type=error]${error_message}"

                  exit 65
              fi

            fi
        fi

        if [ -f post_deployment.sh ]; then
            ./post_deployment.sh
            return_code=$?
            if [ 0 != $return_code ]; then
                exit $return_code
            fi
        fi
        cd "${curdir}" || exit
        if [ 1 == $step ] ; then
          step=2
          save_config_var "step" "${deployer_config_information}"
        fi
    else
        az_subscription_id=$(az account show --query id -o tsv)
        printf -v val %-40.40s "$az_subscription_id"
        echo "#########################################################################################"
        echo "#                                                                                       #"
        echo -e "#$boldred User account ${val} does not have access to: $keyvault  $resetformatting"
        echo "#                                                                                       #"
        echo "#########################################################################################"
        echo "User account ${val} does not have access to: $keyvault" > "${deployer_config_information}".err

        echo "##vso[task.setprogress value=40;]Progress Indicator"
        exit 65

    fi

else
    echo "##vso[task.setprogress value=40;]Progress Indicator"
fi
unset TF_DATA_DIR

cd "$root_dirname" || exit

if [ 1 = "${only_deployer:-}" ]; then

    step=2
    save_config_var "step" "${deployer_config_information}"
    exit 0
fi

if [ 2 == $step ]; then

    echo ""
    echo "#########################################################################################"
    echo "#                                                                                       #"
    echo -e "#                          $cyan Bootstrapping the library $resetformatting                                  #"
    echo "#                                                                                       #"
    echo "#########################################################################################"
    echo ""

    relative_path="${library_dirname}"
    export TF_DATA_DIR="${relative_path}/.terraform"
    relative_path="${deployer_dirname}"

    cd "${library_dirname}" || exit

    if [ $force == 1 ]; then
        rm -Rf .terraform terraform.tfstate*
    fi

    allParams=$(printf " -p %s -d %s %s" "${library_file_parametername}" "${relative_path}" "${approveparam}")
    echo "${allParams}"

    "${SAP_AUTOMATION_REPO_PATH}"/deploy/scripts/install_library.sh $allParams
    return_code=$?
    if [ 0 != $return_code ]; then
        echo "Bootstrapping of the SAP Library failed" > "${deployer_config_information}".err
        step=1
        save_config_var "step" "${deployer_config_information}"
        exit 20
    fi
    terraform_module_directory="${SAP_AUTOMATION_REPO_PATH}"/deploy/terraform/bootstrap/sap_library/
    REMOTE_STATE_RG=$(terraform -chdir="${terraform_module_directory}" output -no-color -raw sapbits_sa_resource_group_name  | tr -d \")
    REMOTE_STATE_SA=$(terraform -chdir="${terraform_module_directory}" output -no-color -raw remote_state_storage_account_name | tr -d \")
    STATE_SUBSCRIPTION=$(terraform -chdir="${terraform_module_directory}" output -no-color -raw created_resource_group_subscription_id  | tr -d \")

    if [ $ado_flag != "--ado" ] ; then
        az storage account network-rule add -g "${REMOTE_STATE_RG}" --account-name "${REMOTE_STATE_SA}" --ip-address ${this_ip} --output none
    fi

    TF_VAR_sa_connection_string=$(terraform -chdir="${terraform_module_directory}" output -no-color -raw sa_connection_string | tr -d \")
    export TF_VAR_sa_connection_string

    secretname=sa-connection-string
    deleted=$(az keyvault secret list-deleted --vault-name "${keyvault}" --query "[].{Name:name} | [? contains(Name,'${secretname}')] | [0]" | tr -d \")
    if [ "${deleted}" == "${secretname}"  ]; then
        echo -e "\t $cyan Recovering secret ${secretname} in keyvault ${keyvault} $resetformatting \n"
        az keyvault secret recover --name "${secretname}" --vault-name "${keyvault}"
        sleep 10
    fi

    v=""
    secret=$(az keyvault secret list --vault-name "${keyvault}" --query "[].{Name:name} | [? contains(Name,'${secretname}')] | [0]" | tr -d \")
    if [ "${secret}" == "${secretname}"  ];
    then
        v=$(az keyvault secret show --name "${secretname}" --vault-name "${keyvault}" --query value | tr -d \")
        if [ "${v}" != "${TF_VAR_sa_connection_string}" ] ; then
            az keyvault secret set --name "${secretname}" --vault-name "${keyvault}" --value "${TF_VAR_sa_connection_string}" --only-show-errors --output none
        fi
    else
        az keyvault secret set --name "${secretname}" --vault-name "${keyvault}" --value "${TF_VAR_sa_connection_string}" --only-show-errors --output none
    fi

    cd "${curdir}" || exit
    export step=3
    save_config_var "step" "${deployer_config_information}"
    echo "##vso[task.setprogress value=60;]Progress Indicator"

else
    echo ""
    echo "#########################################################################################"
    echo "#                                                                                       #"
    echo -e "#                           $cyan Library is bootstrapped $resetformatting                                   #"
    echo "#                                                                                       #"
    echo "#########################################################################################"
    echo ""
    echo "##vso[task.setprogress value=60;]Progress Indicator"

fi

unset TF_DATA_DIR
cd "$root_dirname" || exit
echo "##vso[task.setprogress value=80;]Progress Indicator"

if [ 3 == $step ]; then
    echo ""
    echo "#########################################################################################"
    echo "#                                                                                       #"
    echo -e "#                          $cyan Migrating the deployer state $resetformatting                               #"
    echo "#                                                                                       #"
    echo "#########################################################################################"
    echo ""

    cd "${deployer_dirname}" || exit

    # Remove the script file
    if [ -f post_deployment.sh ]; then
        rm post_deployment.sh
    fi

    secretname=sa-connection-string
    deleted=$(az keyvault secret list-deleted --vault-name "${keyvault}" --query "[].{Name:name} | [? contains(Name,'${secretname}')] | [0]" | tr -d \")
    if [ "${deleted}" == "${secretname}"  ]; then
        echo -e "\t $cyan Recovering secret ${secretname} in keyvault ${keyvault} $resetformatting \n"
        az keyvault secret recover --name "${secretname}" --vault-name "${keyvault}"
        sleep 10
    fi

    v=""
    secret=$(az keyvault secret list --vault-name "${keyvault}" --query "[].{Name:name} | [? contains(Name,'${secretname}')] | [0]" | tr -d \")
    if [ "${secret}" == "${secretname}"  ]; then
      TF_VAR_sa_connection_string=$(az keyvault secret show --name "${secretname}" --vault-name "${keyvault}" --query value | tr -d \")
      export TF_VAR_sa_connection_string

    fi

    if [[ -z $REMOTE_STATE_SA ]];
    then
        echo "Loading the State file information"
        load_config_vars "${deployer_config_information}" "REMOTE_STATE_SA"
    fi

    allParams=$(printf " --parameterfile %s --storageaccountname %s --type sap_deployer %s %s " "${deployer_file_parametername}" "${REMOTE_STATE_SA}" "${approveparam}" "${ado_flag}" )

    echo -e "$cyan calling installer.sh with parameters: $allParams"

    "${SAP_AUTOMATION_REPO_PATH}"/deploy/scripts/installer.sh $allParams
    return_code=$?
    if [ 0 != $return_code ]; then
        echo "Migrating the deployer state failed" > "${deployer_config_information}".err

        exit 11
    fi

    cd "${curdir}" || exit
    export step=4
    save_config_var "step" "${deployer_config_information}"

fi

unset TF_DATA_DIR
cd "$root_dirname" || exit

load_config_vars "${deployer_config_information}" "keyvault"
load_config_vars "${deployer_config_information}" "deployer_public_ip_address"
load_config_vars "${deployer_config_information}" "REMOTE_STATE_SA"

if [ 4 == $step ]; then
    echo ""
    echo "#########################################################################################"
    echo "#                                                                                       #"
    echo -e "#                          $cyan Migrating the library state $resetformatting                                #"
    echo "#                                                                                       #"
    echo "#########################################################################################"
    echo ""

    cd "${library_dirname}" || exit
    allParams=$(printf " --parameterfile %s --storageaccountname %s --type sap_library %s %s" "${library_file_parametername}" "${REMOTE_STATE_SA}" "${approveparam}"  "${ado_flag}")

    echo -e "$cyan calling installer.sh with parameters: $allParams"

    "${SAP_AUTOMATION_REPO_PATH}"/deploy/scripts/installer.sh $allParams
    return_code=$?
    if [ 0 != $return_code ]; then
        echo "Migrating the SAP Library state failed" > "${deployer_config_information}".err
        exit 21
    fi

    cd "$root_dirname" || exit

    step=5
    save_config_var "step" "${deployer_config_information}"
fi

printf -v kvname '%-40s' "${keyvault}"
printf -v dep_ip '%-40s' "${deployer_public_ip_address}"
printf -v storage_account '%-40s' "${REMOTE_STATE_SA}"
echo ""
echo "#########################################################################################"
echo "#                                                                                       #"
echo -e "# $cyan Please save these values: $resetformatting                                                           #"
echo "#     - Key Vault: ${kvname}                             #"
echo "#     - Deployer IP: ${dep_ip}                           #"
echo "#     - Storage Account: ${storage_account}                       #"
echo "#                                                                                       #"
echo "#########################################################################################"

if [ -f "${deployer_config_information}".err ]; then
    rm "${deployer_config_information}".err
fi

now=$(date)
cat <<EOF > "${deployer_config_information}".md
# Control Plane Deployment #

Date : "${now}"

## Configuration details ##

| Item                    | Name                 |
| ----------------------- | -------------------- |
| Environment             | $environment         |
| Location                | $region              |
| Keyvault Name           | ${kvname}            |
| Deployer IP             | ${dep_ip}            |
| Terraform state         | ${storage_account}   |

EOF

cat "${deployer_config_information}".md
export deployer_keyvault="${keyvault}"
export deployer_ip="${deployer_public_ip_address}"
export terraform_state_storage_account="${REMOTE_STATE_SA}"

if [ 5 == $step ]; then
    if [ "${ado_flag}" != "--ado" ] ; then
        cd "${curdir}" || exit

        load_config_vars "${deployer_config_information}" "sshsecret"
        load_config_vars "${deployer_config_information}" "keyvault"
        load_config_vars "${deployer_config_information}" "deployer_public_ip_address"
        if [ ! -f /etc/profile.d/deploy_server.sh ] ; then
            # Only run this when not on deployer
            echo "#########################################################################################"
            echo "#                                                                                       #"
            echo -e "#                         $cyan  Copying the parameterfiles $resetformatting                                 #"
            echo "#                                                                                       #"
            echo "#########################################################################################"
            echo ""

            if [ -n "${sshsecret}" ]; then
                step=3
                save_config_var "step" "${deployer_config_information}"
                printf "%s\n" "Collecting secrets from KV"
                temp_file=$(mktemp)
                ppk=$(az keyvault secret show --vault-name "${keyvault}" --name "${sshsecret}" | jq -r .value)
                echo "${ppk}" > "${temp_file}"
                chmod 600 "${temp_file}"

                remote_deployer_dir="/home/azureadm/Azure_SAP_Automated_Deployment/WORKSPACES/"$(dirname "$deployer_parameter_file")
                remote_library_dir="/home/azureadm/Azure_SAP_Automated_Deployment/WORKSPACES/"$(dirname "$library_parameter_file")
                remote_config_dir="$CONFIG_REPO_PATH/.sap_deployment_automation"

                ssh -i "${temp_file}" -o StrictHostKeyChecking=no -o ConnectTimeout=10 azureadm@"${deployer_public_ip_address}" "mkdir -p ${remote_deployer_dir}"/.terraform 2> /dev/null
                scp -i "${temp_file}" -q -o StrictHostKeyChecking=no -o ConnectTimeout=120 -p "$deployer_parameter_file" azureadm@"${deployer_public_ip_address}":"${remote_deployer_dir}"/. 2> /dev/null
                scp -i "${temp_file}" -q -o StrictHostKeyChecking=no -o ConnectTimeout=120 -p "$(dirname "$deployer_parameter_file")"/.terraform/terraform.tfstate azureadm@"${deployer_public_ip_address}":"${remote_deployer_dir}"/.terraform/terraform.tfstate 2> /dev/null
                scp -i "${temp_file}" -q -o StrictHostKeyChecking=no -o ConnectTimeout=120 -p "$(dirname "$deployer_parameter_file")"/terraform.tfstate azureadm@"${deployer_public_ip_address}":"${remote_deployer_dir}"/terraform.tfstate 2> /dev/null

                ssh -i "${temp_file}" -o StrictHostKeyChecking=no -o ConnectTimeout=10 azureadm@"${deployer_public_ip_address}" " mkdir -p ${remote_library_dir}"/.terraform 2> /dev/null
                scp -i "${temp_file}" -q -o StrictHostKeyChecking=no -o ConnectTimeout=120 -p "$(dirname "$deployer_parameter_file")"/.terraform/terraform.tfstate azureadm@"${deployer_public_ip_address}":"${remote_deployer_dir}"/. 2> /dev/null
                scp -i "${temp_file}" -q -o StrictHostKeyChecking=no -o ConnectTimeout=120 -p "$library_parameter_file" azureadm@"${deployer_public_ip_address}":"$remote_library_dir"/. 2> /dev/null

                ssh -i "${temp_file}" -o StrictHostKeyChecking=no -o ConnectTimeout=10 azureadm@"${deployer_public_ip_address}" "mkdir -p ${remote_config_dir}" 2> /dev/null
                scp -i "${temp_file}" -q -o StrictHostKeyChecking=no -o ConnectTimeout=120 -p "${deployer_config_information}" azureadm@"${deployer_public_ip_address}":"${remote_config_dir}"/. 2> /dev/null
                rm "${temp_file}"
            fi
        fi

    fi
fi

step=3
save_config_var "step" ${deployer_config_information}
echo "##vso[task.setprogress value=100;]Progress Indicator"

unset TF_DATA_DIR

exit 0
