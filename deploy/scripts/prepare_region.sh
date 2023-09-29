#!/bin/bash

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

INPUT_ARGUMENTS=$(getopt -n prepare_region -o d:l:s:c:p:t:a:ifohrv --longoptions deployer_parameter_file:,library_parameter_file:,subscription:,spn_id:,spn_secret:,tenant_id:,storageaccountname:,auto-approve,force,only_deployer,help,recover,ado -- "$@")
VALID_ARGUMENTS=$?

if [ "$VALID_ARGUMENTS" != "0" ]; then
    control_plane_showhelp
fi

eval set -- "$INPUT_ARGUMENTS"
while :;
do
    case "$1" in
        -d | --deployer_parameter_file)            deployer_parameter_file="$2"     ; shift 2 ;;
        -l | --library_parameter_file)             library_parameter_file="$2"      ; shift 2 ;;
        -s | --subscription)                       subscription="$2"                ; shift 2 ;;
        -c | --spn_id)                             client_id="$2"                   ; shift 2 ;;
        -p | --spn_secret)                         spn_secret="$2"                  ; shift 2 ;;
        -t | --tenant_id)                          tenant_id="$2"                   ; shift 2 ;;
        -a | --storageaccountname)                 REMOTE_STATE_SA="$2"             ; shift 2 ;;
        -v | --ado)                                ado_flag="--ado"                 ; shift ;;
        -f | --force)                              force=1                          ; shift ;;
        -o | --only_deployer)                      only_deployer=1                  ; shift ;;
        -r | --recover)                            recover=1                        ; shift ;;
        -i | --auto-approve)                       approve="--auto-approve"         ; shift ;;
        -h | --help)                               control_plane_showhelp
        exit 3                           ; shift ;;
        --) shift; break ;;
    esac
done

echo "ADO flag ${ado_flag}"

this_ip=$(curl -s ipinfo.io/ip) >/dev/null 2>&1
root_dirname=$(pwd)

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

if [ -n "${subscription}" ]; then
    ARM_SUBSCRIPTION_ID="${subscription}"
    export ARM_SUBSCRIPTION_ID=$subscription
fi
# Check that the exports ARM_SUBSCRIPTION_ID and DEPLOYMENT_REPO_PATH are defined
validate_exports
return_code=$?
if [ 0 != $return_code ]; then
    echo "Missing exports" > "${deployer_config_information}".err
    exit $return_code
fi
# Check that webapp exports are defined, if deploying webapp
if [ "${TF_VAR_use_webapp}" = "true" ]; then
    validate_webapp_exports
    return_code=$?
    if [ 0 != $return_code ]; then
        exit $return_code
    fi
fi

deployer_dirname=$(dirname "${deployer_parameter_file}")
deployer_file_parametername=$(basename "${deployer_parameter_file}")

library_dirname=$(dirname "${library_parameter_file}")
library_file_parametername=$(basename "${library_parameter_file}")

relative_path="${root_dirname}"/"${deployer_dirname}"
export TF_DATA_DIR="${relative_path}"/.terraform

step=0

echo "#########################################################################################"
echo "#                                                                                       #"
echo -e "#                   $cyan Starting the control plane deployment $resetformatting                             #"
echo "#                                                                                       #"
echo "#########################################################################################"

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
    az account set --sub "${subscription}"
    export ARM_SUBSCRIPTION_ID="${subscription}"
fi

if [ 3 == $step ]; then
    spn_secret="none"
fi

set_executing_user_environment_variables "${spn_secret}"

load_config_vars "${deployer_config_information}" "step"

load_config_vars "${deployer_config_information}" "keyvault"

if [ $recover == 1 ]; then
    if [ -n "$REMOTE_STATE_SA" ]; then
        save_config_var "REMOTE_STATE_SA" "${deployer_config_information}"
        get_and_store_sa_details ${REMOTE_STATE_SA} "${deployer_config_information}"
        #Support running prepare_region on new host when the resources are already deployed
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

    "${DEPLOYMENT_REPO_PATH}"/deploy/scripts/install_deployer.sh $allParams
    return_code=$?
    if [ 0 != $return_code ]; then
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

    export step=1
    save_config_var "step" "${deployer_config_information}"

    cd "$root_dirname" || exit

    echo "#########################################################################################"
    echo "#                                                                                       #"
    echo -e "#                         $cyan  Copying the parameterfiles $resetformatting                                 #"
    echo "#                                                                                       #"
    echo "#########################################################################################"
    echo ""

    load_config_vars "${deployer_config_information}" "sshsecret"
    load_config_vars "${deployer_config_information}" "keyvault"
    load_config_vars "${deployer_config_information}" "deployer_public_ip_address"

    if [ -n "${deployer_public_ip_address}" ]; then
        if [ "$this_ip" != "$deployer_public_ip_address" ]; then
            # Only run this when not on deployer
            if [ -n "${sshsecret}" ]
            then
                echo "#########################################################################################"
                echo "#                                                                                       #"
                echo -e "#                            $cyan Collecting secrets from KV $resetformatting                               #"
                echo "#                                                                                       #"
                echo "#########################################################################################"
                echo ""

                temp_file=$(mktemp)
                ppk=$(az keyvault secret show --vault-name "${keyvault}" --name "${sshsecret}" | jq -r .value)
                echo "${ppk}" > "${temp_file}"
                chmod 600 "${temp_file}"

                remote_deployer_dir="$HOME/Azure_SAP_Automated_Deployment/WORKSPACES/"$(dirname "$deployer_parameter_file")
                remote_library_dir="$HOME/Azure_SAP_Automated_Deployment/WORKSPACES/"$(dirname "$library_parameter_file")
                remote_config_dir="$HOME/.sap_deployment_automation"

                ssh -i "${temp_file}" -o StrictHostKeyChecking=no -o ConnectTimeout=10 azureadm@"${deployer_public_ip_address}" "mkdir -p ${remote_deployer_dir}"/.terraform 2> /dev/null
                scp -i "${temp_file}" -q -o StrictHostKeyChecking=no -o ConnectTimeout=120 "$deployer_parameter_file" azureadm@"${deployer_public_ip_address}":"${remote_deployer_dir}"/. 2> /dev/null
                scp -i "${temp_file}" -q -o StrictHostKeyChecking=no -o ConnectTimeout=120 "$(dirname "$deployer_parameter_file")"/.terraform/terraform.tfstate azureadm@"${deployer_public_ip_address}":"${remote_deployer_dir}"/.terraform/terraform.tfstate 2> /dev/null
                scp -i "${temp_file}" -q -o StrictHostKeyChecking=no -o ConnectTimeout=120 "$(dirname "$deployer_parameter_file")"/terraform.tfstate azureadm@"${deployer_public_ip_address}":"${remote_deployer_dir}"/terraform.tfstate 2> /dev/null

                ssh -i "${temp_file}" -o StrictHostKeyChecking=no -o ConnectTimeout=10 azureadm@"${deployer_public_ip_address}" " mkdir -p ${remote_library_dir}"/.terraform 2> /dev/null
                scp -i "${temp_file}" -q -o StrictHostKeyChecking=no -o ConnectTimeout=120 "$library_parameter_file" azureadm@"${deployer_public_ip_address}":"$remote_library_dir"/. 2> /dev/null

                ssh -i "${temp_file}" -o StrictHostKeyChecking=no -o ConnectTimeout=10 azureadm@"${deployer_public_ip_address}" "mkdir -p ${remote_config_dir}" 2> /dev/null
                scp -i "${temp_file}" -q -o StrictHostKeyChecking=no -o ConnectTimeout=120 "${deployer_config_information}" azureadm@"${deployer_public_ip_address}":"${remote_config_dir}"/. 2> /dev/null

                rm "${temp_file}"
            fi
        fi

    else
        echo ""
        echo "#########################################################################################"
        echo "#                                                                                       #"
        echo -e "#                          $cyan Deployer is bootstrapped $resetformatting                                   #"
        echo "#                                                                                       #"
        echo "#########################################################################################"
        echo ""
    fi
fi

cd "$root_dirname" || exit

if [ 1 = "${only_deployer:-}" ]; then
    load_config_vars "${deployer_config_information}" deployer_public_ip_address
    echo ""
    echo -e "Please ${cyan}login${resetformatting} to the deployer node (${boldred}${deployer_public_ip_address}${resetformatting}) and re-run ${boldred}$(basename ${0})${resetformatting} to continue."
    unset TF_DATA_DIR
    printf -v secretname '%-40s' "${environment}"-client-id
    printf -v secretname2 '%-40s' "${environment}"-client-secret
    printf -v secretname3 '%-40s' "${environment}"-subscription-id
    printf -v secretname4 '%-40s' "${environment}"-tenant-id
    printf -v deployerpara '%-40s' "-d ${deployer_parameter_file}"
    printf -v librarypara '%-40s' "-l ${library_parameter_file}"

    echo ""
    echo "#########################################################################################"
    echo "#                                                                                       #"
    echo -e "# $cyan Please populate the keyvault: ${keyvault} $resetformatting                                   #"
    echo "#     with the following secrets:                                                       #"
    echo "#     - $secretname                                        #"
    echo "#     - $secretname2                                        #"
    echo "#     - $secretname3                                        #"
    echo "#     - $secretname4                                        #"
    echo "#                                                                                       #"
    echo "#  Once done please logon to the deployer and resume by running:                        #"
    echo "#                                                                                       #"
    echo "#    \$DEPLOYMENT_REPO_PATH/deploy/scripts/prepare_region.sh \                           #"
    echo "#    $deployerpara     #"
    echo "#    $librarypara                        #"
    echo "#                                                                                       #"
    echo "#########################################################################################"
    echo ""

    step=6
    save_config_var "step" "${deployer_config_information}"
    exit 0
fi

if [ 1 == $step ]; then
    secretname="${environment}"-client-id
    echo ""
    echo "#########################################################################################"
    echo "#                                                                                       #"
    echo -e "#                          $cyan Validating keyvault access $resetformatting                                 #"
    echo "#                                                                                       #"
    echo "#########################################################################################"
    echo ""

    if [ -z "$keyvault" ]; then
        read -r -p "Deployer keyvault name: " keyvault
    fi

    access_error=$(az keyvault secret list --vault "$keyvault" --only-show-errors | grep "The user, group or application")
    if [ -z "${access_error}" ]; then
        save_config_var "client_id" "${deployer_config_information}"
        save_config_var "tenant_id" "${deployer_config_information}"

        if [ -n "$spn_secret" ]; then
            allParams=$(printf " -e %s -r %s -v %s --spn_secret %s " "${environment}" "${region_code}" "${keyvault}" "${spn_secret}")

            "${DEPLOYMENT_REPO_PATH}"/deploy/scripts/set_secrets.sh $allParams
            return_code=$?
            if [ 0 != $return_code ]; then
                echo "Could not set the secrets in key vault" > "${deployer_config_information}".err
                exit $return_code
            fi
        else
            read -p "Do you want to specify the SPN Details Y/N?" ans
            answer=${ans^^}
            if [ "$answer" == 'Y' ]; then
                allParams=$(printf " -e %s -r %s -v %s " "${environment}" "${region_code}" "${keyvault}" )

                #$allParams as an array (); array math can be done in shell, allowing dynamic parameter lists to be created
                #"${allParams[@]}" - quotes all elements of the array

                "${DEPLOYMENT_REPO_PATH}"/deploy/scripts/set_secrets.sh $allParams
                return_code=$?
                if [ 0 == $return_code ]; then
                    exit $return_code
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
        step=2
        save_config_var "step" "${deployer_config_information}"
    else
        az_subscription_id=$(az account show --query id -o tsv)
        printf -v val %-40.40s "$az_subscription_id"
        echo "#########################################################################################"
        echo "#                                                                                       #"
        echo -e "#$boldred User account ${val} does not have access to: $keyvault  $resetformatting"
        echo "#                                                                                       #"
        echo "#########################################################################################"
        echo "User account ${val} does not have access to: $keyvault" > "${deployer_config_information}".err

        exit 65

    fi
fi
unset TF_DATA_DIR
cd "$root_dirname" || exit

if [ 2 == $step ]; then

    echo ""
    echo "#########################################################################################"
    echo "#                                                                                       #"
    echo -e "#                          $cyan Bootstrapping the library $resetformatting                                  #"
    echo "#                                                                                       #"
    echo "#########################################################################################"
    echo ""

    relative_path="${root_dirname}"/"${library_dirname}"
    export TF_DATA_DIR="${relative_path}/.terraform"
    relative_path="${root_dirname}"/"${deployer_dirname}"

    cd "${library_dirname}" || exit

    if [ $force == 1 ]; then
        rm -Rf .terraform terraform.tfstate*
    fi

    allParams=$(printf " -p %s -d %s %s" "${library_file_parametername}" "${relative_path}" "${approveparam}")

    "${DEPLOYMENT_REPO_PATH}"/deploy/scripts/install_library.sh $allParams
    return_code=$?
    if [ 0 != $return_code ]; then
        echo "Bootstrapping of the SAP Library failed" > "${deployer_config_information}".err
        exit 20
    fi

    if [ "${TF_VAR_use_webapp}" = "true" ]; then
        echo "#########################################################################################"
        echo "#                                                                                       #"
        echo -e "#                           $cyan Configuring the Web App $resetformatting                                   #"
        echo "#                                                                                       #"
        echo "#########################################################################################"
        terraform_module_directory="${DEPLOYMENT_REPO_PATH}"/deploy/terraform/bootstrap/sap_library/
        TF_VAR_sa_connection_string=$(terraform -chdir="${terraform_module_directory}" output -no-color -raw sa_connection_string | tr -d \")
        az keyvault secret set --vault-name "${keyvault}" --name "sa-connection-string" --value "${TF_VAR_sa_connection_string}"
    fi

    cd "${curdir}" || exit
    export step=3
    save_config_var "step" "${deployer_config_information}"
else
    echo ""
    echo "#########################################################################################"
    echo "#                                                                                       #"
    echo -e "#                           $cyan Library is bootstrapped $resetformatting                                   #"
    echo "#                                                                                       #"
    echo "#########################################################################################"
    echo ""

fi

unset TF_DATA_DIR
cd "$root_dirname" || exit

export AA=$REMOTE_STATE_SA

load_config_vars "${deployer_config_information}" "REMOTE_STATE_SA"

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
    allParams=$(printf " --parameterfile %s --storageaccountname %s --type sap_deployer %s %s " "${deployer_file_parametername}" "${REMOTE_STATE_SA}" "${approveparam}" "${ado_flag}" )

    if [ "${TF_VAR_use_webapp}" = "true" ]; then
      TF_VAR_sa_connection_string=$(az keyvault secret show --vault-name "${keyvault}" --name "sa-connection-string" | jq -r .value)
      export TF_VAR_sa_connection_string
    fi

    echo "calling installer.sh with parameters: $allParams"

    "${DEPLOYMENT_REPO_PATH}"/deploy/scripts/installer.sh $allParams
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

    "${DEPLOYMENT_REPO_PATH}"/deploy/scripts/installer.sh $allParams
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
    "${deployer_config_information}".err
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
    if [ $ado_flag != "--ado" ] ; then
        cd "${curdir}" || exit

        load_config_vars "${deployer_config_information}" "sshsecret"
        load_config_vars "${deployer_config_information}" "keyvault"
        load_config_vars "${deployer_config_information}" "deployer_public_ip_address"
        if [ "$this_ip" != "$deployer_public_ip_address" ] ; then
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
                remote_config_dir="/home/azureadm/.sap_deployment_automation"

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

unset TF_DATA_DIR

exit 0
