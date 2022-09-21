#!/bin/bash

#
# create_devops_artifacts.sh
#
# This script is intended to perform all the necessary initial
# setup of a Azure DevOps project.
#
# As part of doing so it will:
#
#
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
  az login --use-device-code

fi
az config set extension.use_dynamic_install=yes_without_prompt

devops_extension_installed=$(az extension list --query [].path | grep azure-devops)
if [ -z "${devops_extension_installed}" ]; then
  az extension add --name azure-devops --output none
fi

if [ -z $ADO_ORGANIZATION ]; then
  echo "Please enter the name of your Azure DevOps organization using the export ADO_ORGANIZATION= command"
  exit 1
fi

if [ -z $ADO_PROJECT ]; then
  echo "Please enter the name of your Azure DevOps project using the export ADO_PROJECT= command"
  exit 1
fi

DEVOPS_ORGANIZATION=$ADO_ORGANIZATION
DEVOPS_PROJECT_NAME=$ADO_PROJECT
DEVOPS_PROJECT_DESCRIPTION=$DEVOPS_PROJECT_NAME

echo "Installing the extensions"
extension_name=$(az devops extension show --org ${DEVOPS_ORGANIZATION} --extension vss-services-ansible  --publisher-id  ms-vscs-rm --query extensionName) 
if [ -z ${extension_name} ]; then
  az devops extension install --org ${DEVOPS_ORGANIZATION} --extension-id vss-services-ansible --publisher-id ms-vscs-rm --output none
fi

extension_name=$(az devops extension show --org ${DEVOPS_ORGANIZATION} --extension PostBuildCleanup  --publisher-id mspremier --query extensionName) | tr -d \"
if [ -z ${extension_name} ]; then
  az devops extension install --org ${DEVOPS_ORGANIZATION} --extension PostBuildCleanup  --publisher-id mspremier --output none
fi

echo "Creating the project: ${DEVOPS_PROJECT_NAME}"
id=$(az devops project create --name ${DEVOPS_PROJECT_NAME} --description ${DEVOPS_PROJECT_DESCRIPTION} --organization ${DEVOPS_ORGANIZATION} --visibility private --source-control git | jq -r '.id' | tr -d \")

repo_id=$(az repos list --org ${DEVOPS_ORGANIZATION} --project $id --query "[].id | [0]" | tr -d \")

echo "Importing the repo"
az repos import create --git-url https://github.com/Azure/sap-automation.git --org  ${DEVOPS_ORGANIZATION} --project $id --repository $repo_id --output none

az repos update --repository $repo_id --org ${DEVOPS_ORGANIZATION} --project $id --default-branch main

echo "Creating the pipelines"
az pipelines create --name 'Deploy Controlplane' --branch main --description 'Deploys the control plane' --org  ${DEVOPS_ORGANIZATION} --project $id --skip-run --yaml-path /deploy/pipelines/01-deploy-control-plane.yaml --repository $repo_id --repository-type tfsgit --output none

az pipelines create --name 'SAP workload zone deployment' --branch main --description 'Deploys the workload zone' --org  ${DEVOPS_ORGANIZATION} --project $id --skip-run --yaml-path /deploy/pipelines/02-sap-workload-zone.yaml --repository $repo_id --repository-type tfsgit --output none

az pipelines create --name 'SAP Software acquisition' --branch main --description 'Downloads the software from SAP' --org  ${DEVOPS_ORGANIZATION} --project $id --skip-run --yaml-path /deploy/pipelines/04-sap-software-download.yaml --repository $repo_id --repository-type tfsgit --output none

az pipelines create --name 'Configuration and SAP installation' --branch main --description 'Configures the Operating System and installs the SAP application' --org  ${DEVOPS_ORGANIZATION} --project $id --skip-run --yaml-path /deploy/pipelines/05-DB-and-SAP-installation.yaml --repository $repo_id --repository-type tfsgit --output none

az pipelines create --name 'Remove deployments' --branch main --description 'Removes either the SAP system or the workload zone' --org  ${DEVOPS_ORGANIZATION} --project $id --skip-run --yaml-path /deploy/pipelines/10-remover-terraform.yaml --repository $repo_id --repository-type tfsgit --output none

az pipelines create --name 'Remove deployments via ARM' --branch main --description 'Removes the resource groups via ARM. Use this only as last resort' --org  ${DEVOPS_ORGANIZATION} --project $id --skip-run --yaml-path /deploy/pipelines/11-remover-arm-fallback.yaml --repository $repo_id --repository-type tfsgit --output none

az pipelines create --name 'Remove control plane' --branch main --description 'Removes the control plane' --org  ${DEVOPS_ORGANIZATION} --project $id --skip-run --yaml-path /deploy/pipelines/12-remove-control-plane.yaml --repository $repo_id --repository-type tfsgit --output none

az pipelines create --name 'Update repository' --branch main --description 'Updates the codebase' --org  ${DEVOPS_ORGANIZATION} --project $id --skip-run --yaml-path /deploy/pipelines/20-update-ado-repository.yaml --repository $repo_id --repository-type tfsgit --output none

az pipelines create --name 'Deploy Configuration Web App' --branch main --description 'Deploys the configuration Web App' --org  ${DEVOPS_ORGANIZATION} --project $id --skip-run --yaml-path /deploy/pipelines/21-deploy-web-app.yaml --repository $repo_id --repository-type tfsgit --output none

az pipelines create --name 'Create Sample Deployer Configuration' --branch main --description 'Creates a sample configuration for the control plane deployment' --org  ${DEVOPS_ORGANIZATION} --project $id --skip-run --yaml-path /deploy/pipelines/22-sample-deployer-config.yaml --repository $repo_id --repository-type tfsgit --output none

az pipelines variable-group create --name SDAF-General --variables ANSIBLE_HOST_KEY_CHECKING=false Deployment_Configuration_Path=WORKSPACES Branch=main S-Username='Enter your S User' S-Password='Enter your S user password' tf_version=1.2.8 --output yaml --org  ${DEVOPS_ORGANIZATION} --project $id --authorize true --output none --output none
 
az pipelines variable-group create --name SDAF-MGMT --variables Agent='Azure Pipelines' APP_REGISTRATION_APP_ID='Enter your app registration ID here' ARM_CLIENT_ID='Enter your SPN ID here' ARM_CLIENT_SECRET='Enter your SPN password here' ARM_SUBSCRIPTION_ID='Enter your control plane subscription here' ARM_TENANT_ID='Enter SPNs Tenant ID here' WEB_APP_CLIENT_SECRET='Enter your App registration secret here' PAT='Enter your personal access token here' POOL=MGMT-POOL AZURE_CONNECTION_NAME=Control_Plane_Service_Connection --output yaml --org  ${DEVOPS_ORGANIZATION} --project $id --authorize true --output none

az pipelines variable-group create --name SDAF-DEV --variables Agent='Azure Pipelines' ARM_CLIENT_ID='Enter your SPN ID here' ARM_CLIENT_SECRET='Enter your SPN password here' ARM_SUBSCRIPTION_ID='Enter your control plane subscription here' ARM_TENANT_ID='Enter SPNs Tenant ID here' PAT='Enter your personal access token here' POOL=MGMT-POOL AZURE_CONNECTION_NAME=DEV_Service_Connection --output yaml --org  ${DEVOPS_ORGANIZATION} --project $id --authorize true --output none

