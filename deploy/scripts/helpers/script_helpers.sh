#!/bin/bash
#colors for terminal
boldreduscore="\e[1;4;31m"
boldred="\e[1;31m"
cyan="\e[1;36m"
resetformatting="\e[0m"

function control_plane_showhelp {
    echo ""
    echo "#################################################################################################################"
    echo "#                                                                                                               #"
    echo "#                                                                                                               #"
    echo "#   This file contains the logic to prepare an Azure region to support the SAP Deployment Automation by         #"
    echo "#    preparing the deployer and the library.                                                                    #"
    echo "#   The script experts the following exports:                                                                   #"
    echo "#                                                                                                               #"
    echo "#     ARM_SUBSCRIPTION_ID to specify which subscription to deploy to                                            #"
    echo "#      SAP_AUTOMATION_REPO_PATH (path to the repo folder (sap-automation))                                      #"
    echo "#      CONFIG_REPO_PATH (path to the configuration repo folder (sap-config)                                     #"
    echo "#                                                                                                               #"
    echo "#   The script is to be run from a parent folder to the folders containing the json parameter files for         #"
    echo "#    the deployer and the library and the environment.                                                          #"
    echo "#                                                                                                               #"
    echo "#   The script will persist the parameters needed between the executions in the                                 #"
    echo "#   [CONFIG_REPO_PATH]/.sap_deployment_automation folder                                                                         #"
    echo "#                                                                                                               #"
    echo "#                                                                                                               #"
    echo "#   Usage: deploy_controlplane.sh                                                                               #"
    echo "#      -d or --deployer_parameter_file       deployer parameter file                                            #"
    echo "#      -l or --library_parameter_file        library parameter file                                             #"
    echo "#                                                                                                               #"
    echo "#   Optional parameters                                                                                         #"
    echo "#      -s or --subscription                  subscription                                                       #"
    echo "#      -c or --spn_id                        SPN application id                                                 #"
    echo "#      -p or --spn_secret                    SPN password                                                       #"
    echo "#      -t or --tenant_id                     SPN Tenant id                                                      #"
    echo "#      -f or --force                         Clean up the local Terraform files.                                #"
    echo "#      -i or --auto-approve                  Silent install                                                     #"
    echo "#      -h or --help                          Help                                                               #"
    echo "#                                                                                                               #"
    echo "#   Example:                                                                                                    #"
    echo "#                                                                                                               #"
    echo "#  \$SAP_AUTOMATION_REPO_PATH/scripts/deploy_controlplane.sh \                                                   #"
    echo "#      --deployer_parameter_file DEPLOYER/MGMT-WEEU-DEP00-INFRASTRUCTURE/MGMT-WEEU-DEP00-INFRASTRUCTURE.json \  #"
    echo "#      --library_parameter_file LIBRARY/MGMT-WEEU-SAP_LIBRARY/MGMT-WEEU-SAP_LIBRARY.json \                      #"
    echo "#                                                                                                               #"
    echo "#   Example:                                                                                                    #"
    echo "#                                                                                                               #"
    echo "#   \$SAP_AUTOMATION_REPO_PATH/scripts/deploy_controlplane.sh \                                                  #"
    echo "#      --deployer_parameter_file DEPLOYER/PROD-WEEU-DEP00-INFRASTRUCTURE/PROD-WEEU-DEP00-INFRASTRUCTURE.json  \ #"
    echo "#      --library_parameter_file LIBRARY/PROD-WEEU-SAP_LIBRARY/PROD-WEEU-SAP_LIBRARY.json \                      #"
    echo "#      --subscription xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx \                                                    #"
    echo "#      --spn_id yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy \                                                          #"
    echo "#      --spn_secret ************************ \                                                                  #"
    echo "#      --tenant_id zzzzzzzz-zzzz-zzzz-zzzz-zzzzzzzzzzzz \                                                       #"
    echo "#      --auto-approve                                                                                           #"
    echo "#                                                                                                               #"
    echo "#################################################################################################################"
}

function control_plane_missing {
    printf -v val '%-40s' "$missing_value"
    echo ""
    echo "#########################################################################################"
    echo "#                                                                                       #"
    echo "#   Missing : ${val}                                  #"
    echo "#                                                                                       #"
    echo "#   Usage: deploy_controlplane.sh                                                       #"
    echo "#      -d or --deployer_parameter_file       deployer parameter file                    #"
    echo "#      -l or --library_parameter_file        library parameter file                     #"
    echo "#                                                                                       #"
    echo "#   Optional parameters                                                                 #"
    echo "#      -s or --subscription                  subscription                               #"
    echo "#      -c or --spn_id                        SPN application id                         #"
    echo "#      -p or --spn_secret                    SPN password                               #"
    echo "#      -t or --tenant_id                     SPN Tenant id                              #"
    echo "#      -f or --force                         Clean up the local Terraform files.        #"
    echo "#      -i or --auto-approve                  Silent install                             #"
    echo "#      -h or --help                          Help                                       #"
    echo "#                                                                                       #"
    echo "#########################################################################################"

}

function workload_zone_showhelp {
    echo ""
    echo "###############################################################################################"
    echo "#                                                                                             #"
    echo "#                                                                                             #"
    echo "#   This file contains the logic to deploy the workload infrastructure to Azure               #"
    echo "#                                                                                             #"
    echo "#   The script experts the following exports:                                                 #"
    echo "#                                                                                             #"
    echo "#   SAP_AUTOMATION_REPO_PATH (path to the repo folder (sap-automation))                       #"
    echo "#   CONFIG_REPO_PATH (path to the configuration repo folder (sap-config)                      #"
    echo "#                                                                                             #"
    echo "#   The script is to be run from the folder containing the json parameter file                #"
    echo "#                                                                                             #"
    echo "#   The script will persist the parameters needed between the executions in the               #"
    echo "#   [CONFIG_REPO_PATH]/.sap_deployment_automation folder                                                       #"
    echo "#                                                                                             #"
    echo "#   Usage: install_workloadzone.sh                                                            #"
    echo "#      -p or --parameterfile                deployer parameter file                           #"
    echo "#                                                                                             #"
    echo "#   Optional parameters                                                                       #"
    echo "#      -d or --deployer_tfstate_key          Deployer terraform state file name               #"
    echo "#      -e or --deployer_environment          Deployer environment, i.e. MGMT                  #"
    echo "#      -s or --subscription                  subscription                                     #"
    echo "#      -k or --state_subscription            subscription for statefile                       #"
    echo "#      -c or --spn_id                        SPN application id                               #"
    echo "#      -p or --spn_secret                    SPN password                                     #"
    echo "#      -t or --tenant_id                     SPN Tenant id                                    #"
    echo "#      -f or --force                         Clean up the local Terraform files.              #"
    echo "#      -i or --auto-approve                  Silent install                                   #"
    echo "#      -h or --help                          Help                                             #"
    echo "#                                                                                             #"
    echo "#   Example:                                                                                  #"
    echo "#                                                                                             #"
    echo "#   [REPO-ROOT]deploy/scripts/install_workloadzone.sh \                                       #"
    echo "#      --parameterfile PROD-WEEU-SAP01-INFRASTRUCTURE                                         #"
    echo "#                                                                                             #"
    echo "#   Example:                                                                                  #"
    echo "#                                                                                             #"
    echo "#   [REPO-ROOT]deploy/scripts/install_workloadzone.sh \                                       #"
    echo "#      --parameterfile PROD-WEEU-SAP01-INFRASTRUCTURE \                                       #"
    echo "#      --deployer_environment MGMT \                                                          #"
    echo "#      --subscription xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx \                                  #"
    echo "#      --spn_id yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy \                                        #"
    echo "#      --spn_secret ************************ \                                                #"
    echo "#      --spn_secret yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy \                                    #"
    echo "#      --tenant_id zzzzzzzz-zzzz-zzzz-zzzz-zzzzzzzzzzzz \                                     #"
    echo "#      --auto-approve                                                                         #"
    echo "##############################################################################################"
}

function workload_zone_missing {
    printf -v val %-.40s "$option"
    echo ""
    echo ""
    echo "#########################################################################################"
    echo "#                                                                                       #"
    echo "#   Missing environment variables: ${option}!!!              #"
    echo "#                                                                                       #"
    echo "#   Please export the folloing variables:                                               #"
    echo "#   SAP_AUTOMATION_REPO_PATH (path to the repo folder (sap-automation))                 #"
    echo "#   CONFIG_REPO_PATH (path to the configuration repo folder (sap-config)                #"
    echo "#                                                                                       #"
    echo "#   Usage: install_workloadzone.sh                                                      #"
    echo "#      -p or --parameterfile                deployer parameter file                     #"
    echo "#                                                                                       #"
    echo "#   Optional parameters                                                                 #"
    echo "#      -d or deployer_tfstate_key            Deployer terraform state file name         #"
    echo "#      -e or deployer_environment            Deployer environment, i.e. MGMT            #"
    echo "#      -k or --state_subscription            subscription of keyvault with SPN details  #"
    echo "#      -v or --keyvault                      Name of Azure keyvault with SPN details    #"
    echo "#      -s or --subscription                  subscription                               #"
    echo "#      -c or --spn_id                        SPN application id                         #"
    echo "#      -o or --storageaccountname            Storage account for terraform state files  #"
    echo "#      -n or --spn_secret                    SPN password                               #"
    echo "#      -t or --tenant_id                     SPN Tenant id                              #"
    echo "#      -f or --force                         Clean up the local Terraform files.        #"
    echo "#      -i or --auto-approve                  Silent install                             #"
    echo "#      -h or --help                          Help                                       #"
    echo "#########################################################################################"
}

function showhelp {
    echo ""
    echo "#########################################################################################"
    echo "#                                                                                       #"
    echo "#                                                                                       #"
    echo "#   This file contains the logic to deploy the different systems                        #"
    echo "#   The script experts the following exports:                                           #"
    echo "#                                                                                       #"
    echo "#   ARM_SUBSCRIPTION_ID to specify which subscription to deploy to                      #"
    echo "#   SAP_AUTOMATION_REPO_PATH the path to the folder containing the cloned sap-automation#"
    echo "#   CONFIG_REPO_PATH (path to the configuration repo folder (sap-config)                #"
    echo "#                                                                                       #"
    echo "#   The script will persist the parameters needed between the executions in the         #"
    echo "#   [CONFIG_REPO_PATH]/.sap_deployment_automation folder                                                 #"
    echo "#                                                                                       #"
    echo "#                                                                                       #"
    echo "#   Usage: installer.sh                                                                 #"
    echo "#    -p or --parameterfile           parameter file                                     #"
    echo "#    -t or --type                         type of system to remove                      #"
    echo "#                                         valid options:                                #"
    echo "#                                           sap_deployer                                #"
    echo "#                                           sap_library                                 #"
    echo "#                                           sap_landscape                               #"
    echo "#                                           sap_system                                  #"
    echo "#                                                                                       #"
    echo "#   Optional parameters                                                                 #"
    echo "#                                                                                       #"
    echo "#    -o or --storageaccountname      Storage account name for state file                #"
    echo "#    -s or --state_subscription      Subscription for tfstate storage account           #"
    echo "#    -i or --auto-approve            Silent install                                     #"
    echo "#    -h or --help                    Show help                                          #"
    echo "#                                                                                       #"
    echo "#   Example:                                                                            #"
    echo "#                                                                                       #"
    echo "#   [REPO-ROOT]deploy/scripts/installer.sh \                                            #"
    echo "#      --parameterfile DEV-WEEU-SAP01-X00 \                                             #"
    echo "#      --type sap_system                                                                #"
    echo "#      --auto-approve                                                                   #"
    echo "#                                                                                       #"
    echo "#########################################################################################"
    return 0
}

function missing {
    printf -v val %-.40s "$option"
    echo ""
    echo ""
    echo "#########################################################################################"
    echo "#                                                                                       #"
    echo "#   Missing environment variables: ${option}!!!              #"
    echo "#                                                                                       #"
    echo "#   Please export the folloing variables:                                               #"
    echo "#      SAP_AUTOMATION_REPO_PATH (path to the automation repo folder (sap-automation))   #"
    echo "#      CONFIG_REPO_PATH (path to the configuration repo folder (sap-config))            #"
    echo "#      ARM_SUBSCRIPTION_ID (subscription containing the state file storage account)     #"
    echo "#      REMOTE_STATE_RG (resource group name for storage account containing state files) #"
    echo "#      REMOTE_STATE_SA (storage account for state file)                                 #"
    echo "#                                                                                       #"
    echo "#########################################################################################"
    return 0
}


function validate_exports {
    if [ -z "$SAP_AUTOMATION_REPO_PATH" ]; then
        echo ""
        echo ""
        echo "#########################################################################################"
        echo "#                                                                                       #"
        echo -e "#  $boldred Missing environment variables (SAP_AUTOMATION_REPO_PATH)!!! $resetformatting                            #"
        echo "#                                                                                       #"
        echo "#   Please export the following variables:                                              #"
        echo "#      SAP_AUTOMATION_REPO_PATH (path to the automation repo folder (sap-automation))   #"
        echo "#      ARM_SUBSCRIPTION_ID (subscription containing the state file storage account)     #"
        echo "#      CONFIG_REPO_PATH (path to the configuration repo folder (sap-config))            #"
        echo "#                                                                                       #"
        echo "#########################################################################################"
        return 65                                                                                           #data format error
    fi

    if [ -z "$CONFIG_REPO_PATH" ]; then
        echo ""
        echo ""
        echo "#########################################################################################"
        echo "#                                                                                       #"
        echo -e "#  $boldred Missing environment variables (CONFIG_REPO_PATH)!!! $resetformatting                            #"
        echo "#                                                                                       #"
        echo "#   Please export the following variables:                                              #"
        echo "#      CONFIG_REPO_PATH (path to the repo folder (sap-automation))                      #"
        echo "#      ARM_SUBSCRIPTION_ID (subscription containing the state file storage account)     #"
        echo "#      CONFIG_REPO_PATH (path to the configuration repo folder (sap-config))            #"
        echo "#                                                                                       #"
        echo "#########################################################################################"
        return 65                                                                                           #data format error
    fi

    if [ -z "$ARM_SUBSCRIPTION_ID" ]; then
        echo ""
        echo "#########################################################################################"
        echo "#                                                                                       #"
        echo -e "#  $boldred Missing environment variables (ARM_SUBSCRIPTION_ID)!!! $resetformatting  #"
        echo "#                                                                                       #"
        echo "#   Please export the following variables:                                              #"
        echo "#      SAP_AUTOMATION_REPO_PATH (path to the repo folder (sap-automation))              #"
        echo "#      ARM_SUBSCRIPTION_ID (subscription containing the state file storage account)     #"
        echo "#      CONFIG_REPO_PATH (path to the configuration repo folder (sap-config))            #"
        echo "#                                                                                       #"
        echo "#########################################################################################"
        return 65                                                                                           #data format error
    fi

    return 0
}

function validate_webapp_exports {
    if [ -z "$TF_VAR_app_registration_app_id" ]; then
        echo ""
        echo ""
        echo "#########################################################################################"
        echo "#                                                                                       #"
        echo -e "#        $boldred Missing environment variables (TF_VAR_app_registration_app_id)!!! $resetformatting             #"
        echo "#                                                                                       #"
        echo "#   Please export the following variables to successfully deploy the Webapp:            #"
        echo "#      TF_VAR_app_registration_app_id (webapp registration application id)              #"
        echo "#      TF_VAR_webapp_client_secret (webapp registration password / secret)              #"
        echo "#                                                                                       #"
        echo "#   If you do not wish to deploy the Webapp, unset the TF_VAR_use_webapp variable       #"
        echo "#                                                                                       #"
        echo "#########################################################################################"
        return 65                                                                                           #data format error
    fi

    if [ -z "$TF_VAR_webapp_client_secret" ]; then
        echo ""
        echo "#########################################################################################"
        echo "#                                                                                       #"
        echo -e "#            $boldred Missing environment variables (TF_VAR_webapp_client_secret)!!! $resetformatting           #"
        echo "#                                                                                       #"
        echo "#   Please export the following variables to successfully deploy the Webapp:            #"
        echo "#      TF_VAR_app_registration_app_id (webapp registration application id)              #"
        echo "#      TF_VAR_webapp_client_secret (webapp registration password / secret)              #"
        echo "#                                                                                       #"
        echo "#   If you do not wish to deploy the Webapp, unset the TF_VAR_use_webapp variable       #"
        echo "#                                                                                       #"
        echo "#########################################################################################"
        return 65                                                                                           #data format error
    fi

    return 0
}

function showhelp {
    echo ""
    echo "#########################################################################################"
    echo "#                                                                                       #"
    echo "#                                                                                       #"
    echo "#   This file contains the logic to deploy the different systems                        #"
    echo "#   The script experts the following exports:                                           #"
    echo "#                                                                                       #"
    echo "#   ARM_SUBSCRIPTION_ID to specify which subscription to deploy to                      #"
    echo "#   SAP_AUTOMATION_REPO_PATH the path to the folder containing the cloned sap-automation#"
    echo "#   CONFIG_REPO_PATH (path to the configuration repo folder (sap-config)                #"
    echo "#                                                                                       #"
    echo "#   The script will persist the parameters needed between the executions in the         #"
    echo "#   [CONFIG_REPO_PATH]/.sap_deployment_automation folder                                                 #"
    echo "#                                                                                       #"
    echo "#                                                                                       #"
    echo "#   Usage: installer.sh                                                                 #"
    echo "#    -p or --parameterfile           parameter file                                     #"
    echo "#    -t or --type                         type of system to remove                      #"
    echo "#                                         valid options:                                #"
    echo "#                                           sap_deployer                                #"
    echo "#                                           sap_library                                 #"
    echo "#                                           sap_landscape                               #"
    echo "#                                           sap_system                                  #"
    echo "#                                                                                       #"
    echo "#   Optional parameters                                                                 #"
    echo "#                                                                                       #"
    echo "#    -o or --storageaccountname      Storage account name for state file                #"
    echo "#    -s or --state_subscription      Subscription for tfstate storage account           #"
    echo "#    -i or --auto-approve            Silent install                                     #"
    echo "#    -h or --help                    Show help                                          #"
    echo "#                                                                                       #"
    echo "#   Example:                                                                            #"
    echo "#                                                                                       #"
    echo "#   [REPO-ROOT]deploy/scripts/installer.sh \                                            #"
    echo "#      --parameterfile DEV-WEEU-SAP01-X00 \                                             #"
    echo "#      --type sap_system                                                                #"
    echo "#      --auto-approve                                                                   #"
    echo "#                                                                                       #"
    echo "#########################################################################################"
}

function missing {
    printf -v val %-.40s "$option"
    echo ""
    echo ""
    echo "#########################################################################################"
    echo "#                                                                                       #"
    echo "#   Missing environment variables: ${option}!!!              #"
    echo "#                                                                                       #"
    echo "#   Please export the folloing variables:                                               #"
    echo "#      SAP_AUTOMATION_REPO_PATH (path to the repo folder (sap-automation))              #"
    echo "#      CONFIG_REPO_PATH (path to the configuration repo folder (sap-config)             #"
    echo "#      ARM_SUBSCRIPTION_ID (subscription containing the state file storage account)     #"
    echo "#      REMOTE_STATE_RG (resource group name for storage account containing state files) #"
    echo "#      REMOTE_STATE_SA (storage account for state file)                                 #"
    echo "#                                                                                       #"
    echo "#########################################################################################"
}



function validate_dependencies {
    # Check terraform
    tf=$(terraform -version | grep Terraform)
    if [ -z "$tf" ]; then
        echo ""
        echo "#########################################################################################"
        echo "#                                                                                       #"
        echo -e "#                          $boldreduscore  Please install Terraform $resetformatting                                 #"
        echo "#                                                                                       #"
        echo "#########################################################################################"
        echo ""
        return 2 #No such file or directory
    fi
    # Set Terraform Plug in cache
    sudo mkdir -p /opt/terraform/.terraform.d/plugin-cache
    sudo chown -R $USER:$USER /opt/terraform
    export TF_PLUGIN_CACHE_DIR=/opt/terraform/.terraform.d/plugin-cache


    az --version >stdout.az 2>&1
    az=$(grep "azure-cli" stdout.az)
    if [ -z "${az}" ]; then
        echo ""
        echo "#########################################################################################"
        echo "#                                                                                       #"
        echo -e "#                          $boldreduscore Please install the Azure CLI $resetformatting                               #"
        echo "#                                                                                       #"
        echo "#########################################################################################"
        echo ""
        if [ -f stdout.az ]; then
            rm stdout.az
        fi
        return 2 #No such file or directory
    fi
    # Checking for valid az session
    temp=$(grep "az login" stdout.az)
    if [ -n "${temp}" ]; then
        echo ""
        echo "#########################################################################################"
        echo "#                                                                                       #"
        echo -e "#                          $boldred Please login using az login! $resetformatting                               #"
        echo "#                                                                                       #"
        echo "#########################################################################################"
        echo ""
        if [ -f stdout.az ]; then
            rm stdout.az
        fi
        exit 67                                                                                             #addressee unknown
    fi
    cloudIDUsed=$(az account show | grep "cloudShellID")
    if [ -n "${cloudIDUsed}" ];
    then
        echo ""
        echo "#########################################################################################"
        echo "#                                                                                       #"
        echo -e "#         $boldred Please login using your credentials or service principal credentials! $resetformatting       #"
        echo "#                                                                                       #"
        echo "#########################################################################################"
        echo ""
        exit 67                                                                                             #addressee unknown
    fi

    return 0
}

function validate_key_parameters {
    echo "Validating $1"
    ext=$(echo $1 | cut -d. -f2)

    # Helper variables
    if [ "${ext}" == json ]; then
        export environment=$(jq --raw-output .infrastructure.environment $1)
        export region=$(jq --raw-output .infrastructure.region $1)
    else
        load_config_vars $1 "environment"
        environment=$(echo ${environment} | xargs | tr "[:lower:]" "[:upper:]" )
        load_config_vars $1 "location"
        region=$(echo ${location} | xargs)
    fi

    if [ -z "${environment}" ]; then
        echo "#########################################################################################"
        echo "#                                                                                       #"
        echo -e "#                         $boldred  Incorrect parameter file. $resetformatting                                  #"
        echo "#                                                                                       #"
        echo "#                The file must contain the environment attribute!!                      #"
        echo "#                                                                                       #"
        echo "#########################################################################################"
        echo ""
        return 64 #script usage wrong
    fi

    if [ -z "${region}" ]; then
        echo "#########################################################################################"
        echo "#                                                                                       #"
        echo -e "#                          $boldred Incorrect parameter file. $resetformatting                                  #"
        echo "#                                                                                       #"
        echo "#              The file must contain the region/location attribute!!                    #"
        echo "#                                                                                       #"
        echo "#########################################################################################"
        echo ""
        return 64                                                                                           #script usage wrong
    fi

    return 0
}


