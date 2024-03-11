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

function showhelp {
    echo ""
    echo "##################################################################################################################"
    echo "#                                                                                                                #"
    echo "#                                                                                                                #"
    echo "#   This file contains the logic to reimport an Azure artifact to the Terraform state file                       #"
    echo "#   The script experts the following exports:                                                                    #"
    echo "#                                                                                                                #"
    echo "#     DEPLOYMENT_REPO_PATH the path to the folder containing the cloned sap-automation                                 #"
    echo "#                                                                                                                #"
    echo "#                                                                                                                #"
    echo "#                                                                                                                #"
    echo "#   Usage: advanced_state_management.sh                                                                          #"
    echo "#    -p or --parameterfile                parameter file                                                         #"
    echo "#    -t or --type                         type of system to remove                                               #"
    echo "#                                         valid options:                                                         #"
    echo "#                                           sap_deployer                                                         #"
    echo "#                                           sap_library                                                          #"
    echo "#                                           sap_landscape                                                        #"
    echo "#                                           sap_system                                                           #"
    echo "#    -o or --operation                    Type of operation to perform: import/remove/list                       #"
    echo "#    -s or --subscription                 subscription ID for the Terraform remote state                         #"
    echo "#    -a or --storage_account_name           Name of the storage account (Terra state)                            #"
    echo "#    -k or --terraform_keyfile            Name of the Terraform remote state file                                #"
    echo "#    -n or --tf_resource_name             Full name of the Terraform resource                                    #"
    echo "#    -i or --azure_resource_id             Azure resource ID to be imported                                      #"
    echo "#   Example:                                                                                                     #"
    echo "#                                                                                                                #"
    echo "#   advanced_state_management.sh \                                                                               #"
    echo "#      --parameterfile DEV-WEEU-SAP01-X00.tfvars \                                                               #"
    echo "#      --type sap_system                                                                                         #"
    echo "#      --subscription xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx                                                       #"
    echo "#      --storage_account_name mgmtweeutfstatef5f                                                                 #"
    echo "#      --terraform_keyfile DEV-WEEU-SAP01-X00.terraform.tfstate                                                  #"
    echo "#      --tf_resource_name module.sap_system.azurerm_resource_group.deployer[0]                                   #"
    echo "#      --azure_resource_id /subscriptions/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx/resourceGroups/DEV-WEEU-SAP01-X01 #"
    echo "#                                                                                                                #"
    echo "#                                                                                                                #"
    echo "##################################################################################################################"
}

function missing {
    printf -v val '%-40s' "$missing_value"
    echo ""
    echo "#########################################################################################"
    echo "#                                                                                       #"
    echo "#   Missing : ${val}                                  #"
    echo "#                                                                                       #"
    echo "#                                                                                                                #"
    echo "#   Usage: advanced_state_management.sh                                                                          #"
    echo "#    -p or --parameterfile                parameter file                                                         #"
    echo "#    -t or --type                         type of system to remove                                               #"
    echo "#                                         valid options:                                                         #"
    echo "#                                           sap_deployer                                                         #"
    echo "#                                           sap_library                                                          #"
    echo "#                                           sap_landscape                                                        #"
    echo "#                                           sap_system                                                           #"
    echo "#    -o or --operation                    Type of operation to perform: import/remove                            #"
    echo "#    -s or --subscription                 subscription ID for the Terraform remote state                         #"
    echo "#    -a or --storage_account_name           Name of the storage account (Terra state)                            #"
    echo "#    -k or --terraform_keyfile            Name of the Terraform remote state file                                #"
    echo "#    -n or --tf_resource_name             Full name of the Terraform resource                                    #"
    echo "#    -i or --azure_resource_id             Azure resource ID to be imported                                      #"
    echo "#   Example:                                                                                                     #"
    echo "#                                                                                                                #"
    echo "#   advanced_state_management.sh \                                                                               #"
    echo "#      --parameterfile DEV-WEEU-SAP01-X00.tfvars \                                                               #"
    echo "#      --type sap_system                                                                                         #"
    echo "#      --subscription xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx                                                       #"
    echo "#      --storage_account_name mgmtweeutfstatef5f                                                                 #"
    echo "#      --operation remove                                                                                        #"
    echo "#      --terraform_keyfile DEV-WEEU-SAP01-X00.terraform.tfstate                                                  #"
    echo "#      --tf_resource_name module.sap_system.azurerm_resource_group.deployer[0]                                   #"
    echo "#      --azure_resource_id /subscriptions/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx/resourceGroups/DEV-WEEU-SAP01-X01 #"
    echo "#                                                                                                                #"
    echo "#                                                                                                                #"
    echo "##################################################################################################################"
}


INPUT_ARGUMENTS=$(getopt -n advanced_state_management -o p:s:a:k:t:n:i:l:d:o:h --longoptions parameterfile:,subscription:,storage_account_name:,terraform_keyfile:,type:,tf_resource_name:,azure_resource_id:,landscape_tfstate_key:,deployer_environment:,operation:,help -- "$@")
VALID_ARGUMENTS=$?

if [ "$VALID_ARGUMENTS" != "0" ]; then
  showhelp
fi

eval set -- "$INPUT_ARGUMENTS"
while :
do
  case "$1" in
    -p | --parameterfile)                      parameterfile="$2"         ; shift 2 ;;
    -s | --subscription)                       subscription_id="$2"       ; shift 2 ;;
    -a | --storage_account_name)               storage_account_name="$2"  ; shift 2 ;;
    -d | --deployer_environment)               deployer_environment="$2"  ; shift 2 ;;
    -o | --operation)                          operation="$2"              ; shift 2 ;;
    -l | --landscape_tfstate_key)              landscape_tfstate_key="$2" ; shift 2 ;;
    -k | --terraform_keyfile)                  key="$2"                   ; shift 2 ;;
    -t | --type)                               type="$2"                  ; shift 2 ;;
    -n | --tf_resource_name)                   moduleID="$2"              ; shift 2 ;;
    -i | --azure_resource_id)                  resourceID="$2"            ; shift 2 ;;
    -h | --help)                               showhelp
    exit 3                                                                ; shift ;;
    --) shift; break ;;
  esac
done

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

if [ -z "${type}" ]
then
    printf -v val %-40.40s "$type"
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

if [ -z "${operation}" ]
then
    echo "#########################################################################################"
    echo "#                                                                                       #"
    echo -e "#  $boldred Incorrect system deployment type specified: ${val}$resetformatting#"
    echo "#                            operation must be specified                                #"
    echo "#                                                                                       #"
    echo "#     Valid options are:                                                                #"
    echo "#       import                                                                          #"
    echo "#       remove                                                                          #"
    echo "#                                                                                       #"
    echo "#########################################################################################"
    echo ""
    exit 64 #script usage wrong
fi


# Check that the exports ARM_SUBSCRIPTION_ID and DEPLOYMENT_REPO_PATH are defined

validate_exports
return_code=$?
if [ 0 != $return_code ]; then
    exit $return_code
fi

# Check that parameter files have environment and location defined
validate_key_parameters "$parameterfile"
if [ 0 != $return_code ]; then
    exit $return_code
fi

if valid_region_name ${region} ; then
    # Convert the region to the correct code
    get_region_code ${region}
else
    echo "Invalid region: $region"
    exit 2
fi

automation_config_directory=$CONFIG_REPO_PATH/.sap_deployment_automation/
system_config_information="${automation_config_directory}""${environment}""${region_code}"

#Plugins
sudo mkdir -p /opt/terraform/.terraform.d/plugin-cache
sudo chown -R $USER:$USER /opt/terraform
export TF_PLUGIN_CACHE_DIR=/opt/terraform/.terraform.d/plugin-cache


set_executing_user_environment_variables "none"

if [ -n "${resourceID}" ] ; then

  subscription_with_resource=$(echo "$resourceID" | cut -d / -f3)

  az account set --sub "${subscription_with_resource}"
  az resource show --ids "${resourceID}"
  return_value=$?
  if [ 0 != $return_value ] ; then
      echo ""
      printf -v val %-40.40s "$resourceID"
      echo "#########################################################################################"
      echo "#                                                                                       #"
      echo -e "#  $boldred Incorrect resource ID specified: $resetformatting                                                   #"
      echo "#   ${resourceID} "
      echo "#                                                                                       #"
      echo "#########################################################################################"
      unset TF_DATA_DIR
      exit $return_value
  fi
fi

if [ -n "${storage_account_name}" ] ; then
  tfstate_resource_id=$(az resource list --name "${storage_account_name}" --resource-type Microsoft.Storage/storageAccounts | jq --raw-output '.[0].id')
else
  load_config_vars "${system_config_information}" "tfstate_resource_id"
  storage_account_name=$(echo "$tfstate_resource_id" | cut -d / -f9)
  STATE_SUBSCRIPTION=$(echo "$tfstate_resource_id" | cut -d / -f3)
fi
if [ -z "${storage_account_name}" ]
then
    if [ -n "${deployer_environment}" ]
    then
        deployer_config_information="${automation_config_directory}"/"${deployer_environment}""${region_code}"
        if [ -f "$deployer_config_information" ]
        then
            load_config_vars "${deployer_config_information}" "REMOTE_STATE_RG"
            load_config_vars "${deployer_config_information}" "REMOTE_STATE_SA"
            load_config_vars "${deployer_config_information}" "tfstate_resource_id"
            load_config_vars "${deployer_config_information}" "STATE_SUBSCRIPTION"
            subscription_id="${STATE_SUBSCRIPTION}"
            storage_account_name="${REMOTE_STATE_SA}"

            if [[ -z $tfstate_resource_id ]]
            then
                az account set --sub "${STATE_SUBSCRIPTION}"
                tfstate_resource_id=$(az resource list --name "${storage_account_name}" --resource-type Microsoft.Storage/storageAccounts | jq --raw-output '.[0].id')
            fi
            fail_if_null tfstate_resource_id
        fi
    fi

fi

if [ -z "${subscription_id}" ]
then
    read -p "Subscription ID containing Terraform state storage account:"  subscription_id
    az account set --sub "${subscription_id}"
fi


if [ -z "${storage_account_name}" ]
then
    read -p "Terraform state storage account:"  storage_account_name
    tfstate_resource_id=$(az resource list --name "${storage_account_name}" --resource-type Microsoft.Storage/storageAccounts | jq --raw-output '.[0].id')
fi

resource_group_name=$(echo "${tfstate_resource_id}" | cut -d/ -f5 | tr -d \" | xargs)

directory=$(pwd)/.terraform

module_dir=$DEPLOYMENT_REPO_PATH/deploy/terraform/run/${type}

export TF_DATA_DIR="${directory}"

terraform -chdir="${module_dir}" init                                      \
  -backend-config "subscription_id=${subscription_id}"                   \
  -backend-config "resource_group_name=${resource_group_name}"           \
  -backend-config "storage_account_name=${storage_account_name}"         \
  -backend-config "container_name=tfstate"                               \
  -backend-config "key=${key}"

return_value=$?

if [ 0 != $return_value ] ; then
    echo ""
    echo "#########################################################################################"
    echo "#                                                                                       #"
    echo -e "#                          $boldreduscore!Errors during the init phase!$resetformatting                              #"
    echo "#                                                                                       #"
    echo "#########################################################################################"
    echo ""
    unset TF_DATA_DIR
    exit $return_value
fi

if [ -z "$landscape_tfstate_key" ];
then
    load_config_vars "${system_config_information}" "landscape_tfstate_key"
else
    save_config_vars "${system_config_information}" landscape_tfstate_key
fi


if [ "${type}" == sap_system ] && [ "${operation}" == "import" ]
then
    if [ -n "${landscape_tfstate_key}" ]; then
        landscape_tfstate_key_parameter=" -var landscape_tfstate_key=${landscape_tfstate_key}"
    else
        read -p "Workload terraform statefile name :" landscape_tfstate_key
        landscape_tfstate_key_parameter=" -var landscape_tfstate_key=${landscape_tfstate_key}"
        save_config_var "landscape_tfstate_key" "${system_config_information}"
    fi
else
    landscape_tfstate_key_parameter=""
fi

echo "Looking for resource:" "${moduleID}"

terraform  -chdir="${module_dir}" state list > resources.lst

if [ "${operation}" == "list" ] ; then
  echo "#########################################################################################"
  echo "#                                                                                       #"
  echo -e "#                                    $cyan  Resources: $resetformatting                                      #"
  echo "#                                                                                       #"
  echo "#########################################################################################"
  echo ""
  cat resources.lst
  unset TF_DATA_DIR

  exit 0

fi


shorter_name=$(echo "${moduleID}" | cut -d[ -f1)
tf_resource=$(grep "${shorter_name}" resources.lst)
echo "Result after grep: " "${tf_resource}"
if [ "${operation}" == "import" ] || [ "${operation}" == "remove" ] ; then
  if [ -n "${tf_resource}" ]; then

    echo "#########################################################################################"
    echo "#                                                                                       #"
    echo -e "#                          $cyan Removing the item: ${moduleID}$resetformatting                                   #"
    echo "#                                                                                       #"
    echo "#########################################################################################"
    echo ""
    terraform  -chdir="${module_dir}" state rm "${moduleID}"
    return_value=$?
    if [ 0 != $return_value ] ; then
        echo ""
        echo "#########################################################################################"
        echo "#                                                                                       #"
        echo -e "#                          $boldreduscore!Errors removing the item!$resetformatting                                   #"
        echo "#                                                                                       #"
        echo "#########################################################################################"
        echo ""
  #      unset TF_DATA_DIR
  #      exit $return_value
    fi
  fi
fi

rm resources.lst

if [ "${operation}" == "import" ]  ; then

  tfstate_parameter=" -var tfstate_resource_id=${tfstate_resource_id}"

  terraform -chdir="${module_dir}" import -var-file $(pwd)/"${parameterfile}"  "${tfstate_parameter}" "${landscape_tfstate_key_parameter}" "${moduleID}" "${resourceID}"

  return_value=$?
  if [ 0 != $return_value ] ; then
      echo ""
      echo "#########################################################################################"
      echo "#                                                                                       #"
      echo -e "#                          $boldreduscore!Errors importing the item!$resetformatting                                  #"
      echo "#                                                                                       #"
      echo "#########################################################################################"
      echo ""
      unset TF_DATA_DIR
      exit $return_value
  fi
fi

unset TF_DATA_DIR
