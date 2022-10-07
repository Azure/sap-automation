#!/bin/bash

#
# create_devops_artifacts.sh
#
# This script is intended to perform all the necessary initial
# setup of a Azure DevOps project.
#
#
# Setup some useful shell options
#

# Fail if any command exits with a non-zero exit status
set -o errexit

# Ensure that the exit status of a pipeline command is non-zero if any
# stage of the pipefile has a non-zero exit status.
set -o pipefail

#colors for terminal
boldreduscore="\e[1;4;31m"
boldred="\e[1;31m"
cyan="\e[1;36m"
resetformatting="\e[0m"

#External helper functions
#. "$(dirname "${BASH_SOURCE[0]}")/deploy_utils.sh"
full_script_path="$(realpath "${BASH_SOURCE[0]}")"
script_directory="$(dirname "${full_script_path}")"

type=$(az account show --query "user.cloudShellID")
if [ -n "${type}" ] ; then
  az logout
  if [ -z $ARM_TENANT_ID ] ; then
    az login --use-device-code
  else
    az login --use-device-code --tenant $ARM_TENANT_ID
  fi

fi
az config set extension.use_dynamic_install=yes_without_prompt

devops_extension_installed=$(az extension list --query [].path | grep azure-devops)
if [ -z $devops_extension_installed ]; then
  az extension add --name azure-devops --output none
fi

if [ -z $ADO_ORGANIZATION ]; then
  echo "Please enter the name of your Azure DevOps organization using the export ADO_ORGANIZATION= command"
  exit 1
fi

if [ -z "${ADO_PROJECT}" ]; then
  echo "Please enter the name of your Azure DevOps project using the export ADO_PROJECT= command"
  exit 1
fi

echo "Installing the extensions"
extension_name=$(az devops extension show --org $ADO_ORGANIZATION --extension vss-services-ansible  --publisher-id  ms-vscs-rm --query extensionName)
if [ -z ${extension_name} ]; then
   az devops extension install --org $ADO_ORGANIZATION --extension-id vss-services-ansible --publisher-id ms-vscs-rm --output none
fi


extension_name=$(az devops extension show --org $ADO_ORGANIZATION --extension PostBuildCleanup  --publisher-id mspremier --query extensionName) | tr -d \"
if [ -z ${extension_name} ]; then
  az devops extension install --org $ADO_ORGANIZATION --extension PostBuildCleanup  --publisher-id mspremier --output none
fi

id=$(az devops project list --organization $ADO_ORGANIZATION --query "[value[]] | [0] | [? name=='$ADO_PROJECT'].id | [0]" | tr -d \")
if [ -z $id ]; then
  echo "Creating the project: ${ADO_PROJECT}"
  id=$(az devops project create --name "${ADO_PROJECT}" --description 'SDAF Automation Project' --organization $ADO_ORGANIZATION --visibility private --source-control git | jq -r '.id' | tr -d \")
  repo_id=$(az repos list --org $ADO_ORGANIZATION --project $id --query "[].id | [0]" | tr -d \")

  echo "Importing the repo"
  az repos import create --git-url https://github.com/Azure/sap-automation.git --org  $ADO_ORGANIZATION --project $id --repository $repo_id --output none

  az repos update --repository $repo_id --org $ADO_ORGANIZATION --project $id --default-branch main

else
  echo "Project: ${ADO_PROJECT} already exists"
  repo_id=$(az repos list --org $ADO_ORGANIZATION --project $id --query "[].id | [0]" | tr -d \")
fi

echo "Creating the pipelines"

pipeline_name='Deploy Controlplane'
pipeline_id=$(az pipelines list --org "${ADO_ORGANIZATION}" --project "${ADO_PROJECT}" --query "[?name=='${pipeline_name}'].id | [0]" | tr -d \")
if [ -z ${pipeline_id} ]; then
  az pipelines create --name 'Deploy Controlplane' --branch main --description 'Deploys the control plane' --org  $ADO_ORGANIZATION --project $id --skip-run --yaml-path /deploy/pipelines/01-deploy-control-plane.yaml --repository $repo_id --repository-type tfsgit --output none
fi

pipeline_name='SAP workload zone deployment'
wz_pipeline_id=$(az pipelines list --org "${ADO_ORGANIZATION}" --project "${ADO_PROJECT}" --query "[?name=='${pipeline_name}'].id | [0]" | tr -d \")
if [ -z $wz_pipeline_id ] ; then
  az pipelines create --name 'SAP workload zone deployment' --branch main --description 'Deploys the workload zone' --org  $ADO_ORGANIZATION --project $id --skip-run --yaml-path /deploy/pipelines/02-sap-workload-zone.yaml --repository $repo_id --repository-type tfsgit --output none
  wz_pipeline_id=$(az pipelines list --org "${ADO_ORGANIZATION}" --project "${ADO_PROJECT}" --query "[?name=='${pipeline_name}'].id | [0]" | tr -d \")
fi

pipeline_name='SAP system deployment (infrastructure)'
system_pipeline_id=$(az pipelines list --org "${ADO_ORGANIZATION}" --project "${ADO_PROJECT}" --query "[?name=='${pipeline_name}'].id | [0]" | tr -d \")
if [ -z $system_pipeline_id ] ; then
  az pipelines create --name 'SAP system deployment (infrastructure)' --branch main --description 'SAP system deployment (infrastructure)' --org  $ADO_ORGANIZATION --project $id --skip-run --yaml-path /deploy/pipelines/03-sap-system-deployment.yaml --repository $repo_id --repository-type tfsgit --output none
  system_pipeline_id=$(az pipelines list --org "${ADO_ORGANIZATION}" --project "${ADO_PROJECT}" --query "[?name=='${pipeline_name}'].id | [0]" | tr -d \")
fi

pipeline_name='SAP Software acquisition'
pipeline_id=$(az pipelines list --org "${ADO_ORGANIZATION}" --project "${ADO_PROJECT}" --query "[?name=='${pipeline_name}'].id | [0]" | tr -d \")
if [ -z $pipeline_id ] ; then
  az pipelines create --name 'SAP Software acquisition' --branch main --description 'Downloads the software from SAP' --org  $ADO_ORGANIZATION --project $id --skip-run --yaml-path /deploy/pipelines/04-sap-software-download.yaml --repository $repo_id --repository-type tfsgit --output none
fi

pipeline_name='Configuration and SAP installation'
installation_pipeline_id=$(az pipelines list --org "${ADO_ORGANIZATION}" --project "${ADO_PROJECT}" --query "[?name=='${pipeline_name}'].id | [0]" | tr -d \")
if [ -z $installation_pipeline_id ] ; then
  installation_pipeline_id=$(az pipelines create --name 'Configuration and SAP installation' --branch main --description 'Configures the Operating System and installs the SAP application' --org  $ADO_ORGANIZATION --project $id --skip-run --yaml-path /deploy/pipelines/05-DB-and-SAP-installation.yaml --repository $repo_id --repository-type tfsgit --output none)
fi

pipeline_name='Remove deployments'
pipeline_id=$(az pipelines list --org "${ADO_ORGANIZATION}" --project "${ADO_PROJECT}" --query "[?name=='${pipeline_name}'].id | [0]" | tr -d \")
if [ -z $pipeline_id ] ; then
  az pipelines create --name 'Remove deployments' --branch main --description 'Removes either the SAP system or the workload zone' --org  $ADO_ORGANIZATION --project $id --skip-run --yaml-path /deploy/pipelines/10-remover-terraform.yaml --repository $repo_id --repository-type tfsgit --output none
fi

pipeline_name='Remove deployments via ARM'
pipeline_id=$(az pipelines list --org "${ADO_ORGANIZATION}" --project "${ADO_PROJECT}" --query "[?name=='${pipeline_name}'].id | [0]" | tr -d \")
if [ -z $pipeline_id ] ; then
  az pipelines create --name 'Remove deployments via ARM' --branch main --description 'Removes the resource groups via ARM. Use this only as last resort' --org  $ADO_ORGANIZATION --project $id --skip-run --yaml-path /deploy/pipelines/11-remover-arm-fallback.yaml --repository $repo_id --repository-type tfsgit --output none
fi

pipeline_name='Remove control plane'
pipeline_id=$(az pipelines list --org "${ADO_ORGANIZATION}" --project "${ADO_PROJECT}" --query "[?name=='${pipeline_name}'].id | [0]" | tr -d \")
if [ -z $pipeline_id ] ; then
  az pipelines create --name 'Remove control plane' --branch main --description 'Removes the control plane' --org  $ADO_ORGANIZATION --project $id --skip-run --yaml-path /deploy/pipelines/12-remove-control-plane.yaml --repository $repo_id --repository-type tfsgit --output none
fi

pipeline_name='Update repository'
pipeline_id=$(az pipelines list --org "${ADO_ORGANIZATION}" --project "${ADO_PROJECT}" --query "[?name=='${pipeline_name}'].id | [0]" | tr -d \")
if [ -z $pipeline_id ] ; then
  az pipelines create --name 'Update repository' --branch main --description 'Updates the codebase' --org  $ADO_ORGANIZATION --project $id --skip-run --yaml-path /deploy/pipelines/20-update-ado-repository.yaml --repository $repo_id --repository-type tfsgit --output none
fi

pipeline_name='Create Sample Deployer Configuration'
pipeline_id=$(az pipelines list --org "${ADO_ORGANIZATION}" --project "${ADO_PROJECT}" --query "[?name=='${pipeline_name}'].id | [0]" | tr -d \")
if [ -z $pipeline_id ] ; then
  az pipelines create --name 'Create Sample Deployer Configuration' --branch main --description 'Creates a sample configuration for the control plane deployment' --org  $ADO_ORGANIZATION --project $id --skip-run --yaml-path /deploy/pipelines/22-sample-deployer-config.yaml --repository $repo_id --repository-type tfsgit --output none
fi

pipeline_name='Update Key Vault'
pipeline_id=$(az pipelines list --org "${ADO_ORGANIZATION}" --project "${ADO_PROJECT}" --query "[?name=='${pipeline_name}'].id | [0]" | tr -d \")
if [ -z $pipeline_id ] ; then
  az pipelines create --name 'Update Key Vault' --branch main --description 'Updates Key vault for traing' --org  $ADO_ORGANIZATION --project $id --skip-run --yaml-path /deploy/pipelines/23-levelup-configuration.yaml --repository $repo_id --repository-type tfsgit --output none
fi

echo "Creating the variable groups"

general_group_id=$(az pipelines variable-group list --project "${ADO_PROJECT}" --organization "${ADO_ORGANIZATION}" --query "[?name=='SDAF-General'].id | [0]" --only-show-errors)
if [ -z $general_group_id ] ; then
  az pipelines variable-group create --name SDAF-General --variables ANSIBLE_HOST_KEY_CHECKING=false Deployment_Configuration_Path=WORKSPACES Branch=main S-Username='Enter your S User' S-Password='Enter your S user password' tf_version=1.2.8 --output yaml --org  $ADO_ORGANIZATION --project $id --authorize true --output none
  general_group_id=$(az pipelines variable-group list --project "${ADO_PROJECT}" --organization "${ADO_ORGANIZATION}" --query "[?name=='SDAF-General'].id | [0]" --only-show-errors | tr -d \")
fi

GroupID=$(az pipelines variable-group list --project "${ADO_PROJECT}" --organization "${ADO_ORGANIZATION}" --query "[?name=='SDAF-MGMT'].id | [0]" --only-show-errors)
if [ -z $GroupID ] ; then
  az pipelines variable-group create --name SDAF-MGMT --variables Agent='Azure Pipelines' APP_REGISTRATION_APP_ID='Enter your app registration ID here' ARM_CLIENT_ID='Enter your SPN ID here' ARM_CLIENT_SECRET='Enter your SPN password here' ARM_SUBSCRIPTION_ID='Enter your control plane subscription here' ARM_TENANT_ID='Enter SPNs Tenant ID here' WEB_APP_CLIENT_SECRET='Enter your App registration secret here' PAT='Enter your personal access token here' POOL=MGMT-POOL AZURE_CONNECTION_NAME=Control_Plane_Service_Connection WORKLOADZONE_PIPELINE_ID=${wz_pipeline_id} SYSTEM_PIPELINE_ID=${system_pipeline_id} SDAF_GENERAL_GROUP_ID=${general_group_id} SAP_INSTALL_PIPELINE_ID=${installation_pipeline_id} --output yaml --org  $ADO_ORGANIZATION --project $id --authorize true --output none
fi

GroupID=$(az pipelines variable-group list --project "${ADO_PROJECT}" --organization "${ADO_ORGANIZATION}" --query "[?name=='SDAF-DEV'].id | [0]" --only-show-errors )
if [ -z $GroupID ] ; then
  az pipelines variable-group create --name SDAF-DEV --variables Agent='Azure Pipelines' ARM_CLIENT_ID='Enter your SPN ID here' ARM_CLIENT_SECRET='Enter your SPN password here' ARM_SUBSCRIPTION_ID='Enter your target subscription here' ARM_TENANT_ID='Enter SPNs Tenant ID here' PAT='Enter your personal access token here' POOL=MGMT-POOL AZURE_CONNECTION_NAME=DEV_Service_Connection --output yaml --org  $ADO_ORGANIZATION --project $id --authorize true --output none
fi
