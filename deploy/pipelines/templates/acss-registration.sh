#!/bin/bash
# Exit immediately if a command exits with a non-zero status.
# Treat unset variables as an error when substituting.
set -eu

#--------------------------------------+---------------------------------------8
#                                                                              |
# Setup variables                                                              |
#                                                                              |
#--------------------------------------+---------------------------------------8
green="\e[1;32m" ; reset="\e[0m" ; boldred="\e[1;31m"
__basedir="${ROOT_FOLDER}"
acss_environment=${ACSS_ENVIRONMENT}
acss_sap_product=${ACSS_SAP_PRODUCT}
acss_workloads_extension_url="https://aka.ms/ACSSCLI"
#--------------------------------------+---------------------------------------8

echo -e "$green-- CODE_FOLDER:${CODE_FOLDER} --$reset"

#--------------------------------------+---------------------------------------8
#                                                                              |
# Install ACSS Workloads extension for Azure CLI                               |
#                                                                              |
#--------------------------------------+---------------------------------------8
set -x
if [ -z "$(az extension list | grep \"name\": | grep \"workloads\")" ]
then
  echo -e "$green--- Installing ACSS \"Workloads\" CLI extension ---$reset"
  # wget $acss_workloads_extension_url -O workloads-0.1.0-py3-none-any.whl || exit 1
  az extension add --name workloads --yes || exit 1
else
  echo -e "$green--- ACSS \"Workloads\" CLI extension already installed ---$reset"
fi
set +x
#--------------------------------------+---------------------------------------8

#--------------------------------------+---------------------------------------8
#                                                                              |
# Authenticate to Azure                                                        |
#                                                                              |
#--------------------------------------+---------------------------------------8
az login --service-principal --username $ARM_CLIENT_ID --password=$ARM_CLIENT_SECRET --tenant $ARM_TENANT_ID  --output none
#--------------------------------------+---------------------------------------8

#--------------------------------------+---------------------------------------8
#                                                                              |
# Initialize Terraform and access State File                                   |
#                                                                              |
#--------------------------------------+---------------------------------------8
# Get Terraform State Outputs
# TODO: Should test if Terraform is available or needs to be installed
#
echo -e "$green--- Initializing Terraform for: $SAP_SYSTEM_CONFIGURATION_NAME ---$reset"
__configDir=${__basedir}
__moduleDir=${CODE_FOLDER}/deploy/terraform/run/sap_system/
TF_DATA_DIR=${__configDir}

cd ${__configDir}

tfstate_resource_id=$(az resource list --name "${TERRAFORM_REMOTE_STORAGE_ACCOUNT_NAME}" --subscription ${TERRAFORM_REMOTE_STORAGE_SUBSCRIPTION} --resource-type Microsoft.Storage/storageAccounts --query "[].id | [0]" -o tsv)

TERRAFORM_REMOTE_STORAGE_RESOURCE_GROUP_NAME=$(az resource show --id "${tfstate_resource_id}" --query resourceGroup -o tsv)


# Init Terraform
__output=$( \
terraform -chdir="${__moduleDir}"                                                       \
init -upgrade=true                                                                      \
--backend-config "subscription_id=${TERRAFORM_REMOTE_STORAGE_SUBSCRIPTION}"             \
--backend-config "resource_group_name=${TERRAFORM_REMOTE_STORAGE_RESOURCE_GROUP_NAME}"  \
--backend-config "storage_account_name=${TERRAFORM_REMOTE_STORAGE_ACCOUNT_NAME}"        \
--backend-config "container_name=tfstate"                                               \
--backend-config "key=${SAP_SYSTEM_CONFIGURATION_NAME}.terraform.tfstate"               \
)
[ $? -ne 0 ] && echo "$__output" && exit 1
echo -e "$green--- Successfully configured the backend "azurerm"! Terraform will automatically use this backend unless the backend configuration changes. ---$reset"

# Fetch values from Terraform State file
# have awk only fetch the first line of the output: NR==2
acss_scs_vm_id=$(     terraform -chdir="${__moduleDir}" output scs_vm_ids                  | awk -F\" 'NR==2{print $2}' | tr -d '\n\r\t[:space:]')
echo -e "$green--- SCS VM ID: $acss_scs_vm_id ---$reset"
acss_sid=$(           terraform -chdir="${__moduleDir}" output sid                         | tr -d '"')
acss_resource_group=$(terraform -chdir="${__moduleDir}" output created_resource_group_name | tr -d '"')
acss_location=$(      terraform -chdir="${__moduleDir}" output region                      | tr -d '"')

unset TF_DATA_DIR __configDir __moduleDir __output
cd $__basedir
#--------------------------------------+---------------------------------------8

#--------------------------------------+---------------------------------------8
#                                                                              |
# Register in ACSS                                                             |
#                                                                              |
#--------------------------------------+---------------------------------------8
echo -e "$green--- Registering SID: $acss_sid in ACSS ---$reset"

# Create JSON Payload as variable
acss_configuration=$(cat << EOF
  {
    "configurationType": "Discovery",
    "centralServerVmId": "${acss_scs_vm_id}"
  }
EOF
)

# ACSS Registration Command
set -x

az workloads sap-virtual-instance create              \
--sap-virtual-instance-name  "${acss_sid}"            \
--resource-group             "${acss_resource_group}" \
--location                   "${acss_location}"       \
--environment                "${acss_environment}"    \
--sap-product                "${acss_sap_product}"    \
--configuration              "${acss_configuration}"  \
  || exit 1

set +x
#--------------------------------------+---------------------------------------8
