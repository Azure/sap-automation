
$ADO_Organization = $Env:ADO_ORGANIZATION
$ADO_Project = $Env:ADO_PROJECT
$Control_plane_code = $Env:CONTROL_PLANE_CODE
$Workload_zone_code = $Env:WORKLOAD_ZONE_CODE

$ControlPlaneSubscriptionID = $Env:ControlPlaneSubscriptionID
$DevSubscriptionID = $Env:DevSubscriptionID
$ControlPlaneSubscriptionName = $Env:ControlPlaneSubscriptionName
$DevSubscriptionName = $Env:DevSubscriptionName

if ($ControlPlaneSubscriptionID.Length -eq 0) {
  Write-Host "ControlPlaneSubscriptionID is not set"
  exit
}

if ($ControlPlaneSubscriptionName.Length -eq 0) {
  Write-Host "ControlPlaneSubscriptionName is not set"
  exit
}

if ($DevSubscriptionID.Length -eq 0) {
  Write-Host "DevSubscriptionID is not set"
  exit
}

if ($DevSubscriptionName.Length -eq 0) {
  Write-Host "DevSubscriptionName is not set"
  exit
}

if ($ADO_Organization.Length -eq 0) {
  Write-Host "Organization is not set"
  $ADO_Organization = Read-Host "Enter your ADO organization URL"
}
else {
  Write-Host "Using Organization: $ADO_Organization"
}

if ($Control_plane_code.Length -eq 0) {
  Write-Host "Control plane code is not set  (MGMT, etc)"
  $Control_plane_code = Read-Host "Enter your Control plane code"
}
else {
  Write-Host "Using Control plane code: $Control_plane_code"
}

if ($Workload_zone_code.Length -eq 0) {
  Write-Host "Workload zone code is not set  (DEV, etc)"
  $Workload_zone_code = Read-Host "Enter your Workload zone code"
}
else {
  Write-Host "Using Workload zone code: $Workload_zone_code"
}


az login

az config set extension.use_dynamic_install=yes_without_prompt --only-show-errors

$ApplicationName = $ControlPlanePrefix + "-configuration-app"

if ($Env:SDAF_APP_NAME.Length -ne 0) {
  $ApplicationName = $Env:SDAF_APP_NAME
}

$ControlPlanePrefix = "SDAF-" + $Control_plane_code
$WorkloadZonePrefix = "SDAF-" + $Workload_zone_code
$Pool_Name = $ControlPlanePrefix + "-Pool"

$url = ( az devops project list --organization $ADO_Organization --query "value | [0].url")
if ($url.Length -eq 0) {
  Write-Error "Could not get the DevOps organization URL"
  exit
}

Write-Host "Installing the extensions"
$extension_name = (az devops extension list --organization $ADO_Organization --query "[?extensionName=='Post Build Cleanup'].extensionName | [0]")

if ($extension_name.Length -eq 0) {
  az devops extension install --organization $ADO_Organization --extension PostBuildCleanup  --publisher-id mspremier --output none
}

$Project_ID = (az devops project list --organization $ADO_ORGANIZATION --query "[value[]] | [0] | [? name=='$ADO_PROJECT'].id | [0]")

$import_code = $false
if ($Project_ID.Length -eq 0) {
  Write-Host "Creating the project: " $ADO_PROJECT
  $Project_ID = (az devops project create --name $ADO_PROJECT --description 'SDAF Automation Project' --organization $ADO_ORGANIZATION --visibility private --source-control git  --query id).Replace("""", "")

  az devops configure --defaults organization=$ADO_ORGANIZATION project='$ADO_PROJECT'

  $repo_id = (az repos list --query "[].id | [0]").Replace("""", "")

  Write-Host "Importing the repo"
  az repos import create --git-url https://github.com/Azure/SAP-automation-bootstrap --repository $repo_id --output none

  az repos update --repository $repo_id --default-branch main

  Write-Host "You can optionally import the code from GitHub into Azure DevOps, however, this should only be done if you cannot access github from the Azure DevOps agent or if you intend to customize the code-"

  $confirmation = Read-Host "Do you want to import the code from GitHub y/n?"
  if ($confirmation -eq 'y') {
    $import_code = $true
    $code_repo_id = (az repos create --name sap-automation --query id)
    az repos import create --git-url https://github.com/Azure/SAP-automation --repository $code_repo_id --output none
    az repos update --repository $code_repo_id --default-branch main
  }
}

else {
  Write-Host "Project: $ADO_PROJECT already exists, do you want to re-import the code from GitHub y/n?"
  $confirmation = Read-Host "Do you want to import the code from GitHub y/n?"
  if ($confirmation -eq 'y') {
    az devops configure --defaults organization=$ADO_ORGANIZATION project='$ADO_PROJECT'

    $repo_id = (az repos list --query "[].id | [0]").Replace("""", "")
    az repos delete --id $repo_id

    $repo_id = (az repos list --query "[].id | [0]").Replace("""", "")
    az repos delete --id $repo_id

    Write-Host "Importing the repo"
    az repos import create --git-url https://github.com/Azure/SAP-automation-bootstrap --repository $repo_id --output none

    az repos update --repository $repo_id --default-branch main

    Write-Host "You can optionally import the code from GitHub into Azure DevOps, however, this should only be done if you cannot access github from the Azure DevOps agent or if you intend to customize the code-"

    $confirmation = Read-Host "Do you want to import the code from GitHub y/n?"
    if ($confirmation -eq 'y') {
      $import_code = $true
      $code_repo_id = (az repos create --name sap-automation --query id)
      az repos import create --git-url https://github.com/Azure/SAP-automation --repository $code_repo_id --output none
      az repos update --repository $code_repo_id --default-branch main
    }
  }

}

$idx = $url.IndexOf("_api")
$pat_url = ($url.Substring(0, $idx) + "_usersSettings/tokens").Replace("""", "")

Write-Host "Creating the pipelines"

$pipeline_name = 'Deploy Control plane'
$pipeline_id = (az pipelines list  --query "[?name=='$pipeline_name'].id | [0]")
if ($pipeline_id.Length -eq 0) {
  az pipelines create --name $pipeline_name --branch main --description 'Deploys the control plane'  --skip-run --yaml-path "/pipelines/01-deploy-control-plane.yml" --repository $repo_id --repository-type tfsgit --output none
}

$pipeline_name = 'SAP Workload Zone deployment'
$wz_pipeline_id = (az pipelines list  --query "[?name=='$pipeline_name'].id | [0]")
if ($wz_pipeline_id.Length -eq 0) {
  az pipelines create --name $pipeline_name --branch main --description 'Deploys the workload zone'  --skip-run --yaml-path "/pipelines/02-sap-workload-zone.yml" --repository $repo_id --repository-type tfsgit --output none
  $wz_pipeline_id = (az pipelines list  --query "[?name=='$pipeline_name'].id | [0]")
}

$pipeline_name = 'SAP SID Infrastructure deployment'
$system_pipeline_id = (az pipelines list  --query "[?name=='$pipeline_name'].id | [0]")
if ($system_pipeline_id.Length -eq 0) {
  az pipelines create --name $pipeline_name --branch main --description 'Deploys the infrastructure required for a SAP SID deployment' --skip-run --yaml-path "/pipelines/03-sap-system-deployment.yml" --repository $repo_id --repository-type tfsgit --output none
  $system_pipeline_id = (az pipelines list  --query "[?name=='$pipeline_name'].id | [0]")
}

$pipeline_name = 'SAP Software acquisition'
$pipeline_id = (az pipelines list  --query "[?name=='$pipeline_name'].id | [0]")
if ($pipeline_id.Length -eq 0) {
  az pipelines create --name $pipeline_name --branch main --description 'Downloads the software from SAP'  --skip-run --yaml-path "/pipelines/04-sap-software-download.yml" --repository $repo_id --repository-type tfsgit --output none
}

$pipeline_name = 'Configuration and SAP installation'
$installation_pipeline_id = (az pipelines list  --query "[?name=='$pipeline_name'].id | [0]")
if ($installation_pipeline_id.Length -eq 0) {
  $installation_pipeline_id = (az pipelines create --name $pipeline_name --branch main --description 'Configures the Operating System and installs the SAP application' --skip-run --yaml-path "/pipelines/05-DB-and-SAP-installation.yml" --repository $repo_id --repository-type tfsgit --output none)
}

$pipeline_name = 'Remove System of Workload Zone'
$pipeline_id = (az pipelines list  --query "[?name=='$pipeline_name'].id | [0]")
if ($pipeline_id.Length -eq 0) {
  az pipelines create --name $pipeline_name --branch main --description 'Removes either the SAP system or the workload zone'  --skip-run --yaml-path "/pipelines/10-remover-terraform.yml" --repository $repo_id --repository-type tfsgit --output none
}

$pipeline_name = 'Remove deployments via ARM'
$pipeline_id = (az pipelines list  --query "[?name=='$pipeline_name'].id | [0]")
if ($pipeline_id.Length -eq 0) {
  az pipelines create --name $pipeline_name --branch main --description 'Removes the resource groups via ARM. Use this only as last resort'  --skip-run --yaml-path "/pipelines/11-remover-arm-fallback.yml" --repository $repo_id --repository-type tfsgit --output none
}

$pipeline_name = 'Remove control plane'
$pipeline_id = (az pipelines list  --query "[?name=='$pipeline_name'].id | [0]")
if ($pipeline_id.Length -eq 0) {
  az pipelines create --name $pipeline_name --branch main --description 'Removes the control plane'  --skip-run --yaml-path "/pipelines/12-remove-control-plane.yml" --repository $repo_id --repository-type tfsgit --output none
}

if ($import_code) {
  $pipeline_name = 'Update repository'
  $pipeline_id = (az pipelines list  --query "[?name=='$pipeline_name'].id | [0]")
  if ($pipeline_id.Length -eq 0) {
    az pipelines create --name 'Update repository' --branch main --description 'Updates the codebase'  --skip-run --yaml-path "/pipelines/20-update-ado-repository.yml" --repository $repo_id --repository-type tfsgit --output none
  }
}

$pipeline_name = 'Create Control Plane configuration'
$sample_pipeline_id = (az pipelines list  --query "[?name=='$pipeline_name'].id | [0]")
if ($sample_pipeline_id.Length -eq 0) {
  az pipelines create --name $pipeline_name --branch main --description 'Create sample configuration'  --skip-run --yaml-path "/pipelines/22-sample-deployer-configuration.yml" --repository $repo_id --repository-type tfsgit --output none
  $sample_pipeline_id = (az pipelines list  --query "[?name=='$pipeline_name'].id | [0]")
}


Write-Host "Creating the variable group SDAF-General"

$general_group_id = (az pipelines variable-group list  --query "[?name=='SDAF-General'].id | [0]" --only-show-errors)
if ($general_group_id.Length -eq 0) {
  az pipelines variable-group create --name SDAF-General --variables ANSIBLE_HOST_KEY_CHECKING=false Deployment_Configuration_Path=WORKSPACES Branch=main S-Username='Enter your S User' S-Password='Enter your S user password' tf_version=1.2.8 ansible_core_version=2.13 --output yaml  --authorize true --output none
  $general_group_id = (az pipelines variable-group list  --query "[?name=='SDAF-General'].id | [0]" --only-show-errors)
}


Write-Host "Creating the App registration in Azure Active Directory"

$found_appRegistration = (az ad app list --show-mine --query "[?displayName=='$ApplicationName'].displayName | [0]" --only-show-errors)

$APP_REGISTRATION_ID = ""
$WEB_APP_CLIENT_SECRET = "Enter your App registration secret here"

if ($found_appRegistration.Length -ne 0) {
  Write-Host "Found an existing App Registration:" $ApplicationName
  $ExistingData = (az ad app list --show-mine --query "[?displayName=='$ApplicationName']| [0]" --only-show-errors) | ConvertFrom-Json

  $APP_REGISTRATION_ID = $ExistingData.appId
  Write-Host "Please update the WEB_APP_CLIENT_SECRET manually if needed in variable group '$ControlPlanePrefix'"

}
else {
  Write-Host "Creating an App Registration"  $ApplicationName
  Add-Content -Path manifest.json -Value '[{"resourceAppId":"00000003-0000-0000-c000-000000000000","resourceAccess":[{"id":"e1fe6dd8-ba31-4d61-89e7-88639da4683d","type":"Scope"}]}]'

  $APP_REGISTRATION_ID = (az ad app create --display-name $ApplicationName --enable-id-token-issuance true --sign-in-audience AzureADMyOrg --required-resource-access .\manifest.json --query "appId").Replace('"', "")

  Remove-Item manifest.json

  $WEB_APP_CLIENT_SECRET = (az ad app credential reset --id $APP_REGISTRATION_ID --append --query "password" --only-show-errors)
}

$app_name = $ControlPlanePrefix + " Deployment credential"
if ($Env:SDAF_MGMT_SPN_NAME.Length -ne 0) {
  $app_name = $Env:SDAF_MGMT_SPN_NAME
}

$scopes = "/subscriptions/" + $ControlPlaneSubscriptionID

Write-Host "Creating the deployment credentials for the control plane. Service Principal Name:" $app_name

$ARM_CLIENT_ID = ""
$ARM_TENANT_ID = ""
$ARM_CLIENT_SECRET = "Please update"

$SPN_Created = $false

$found_appName = (az ad sp list --show-mine --query "[?displayName=='$app_name'].displayName | [0]" --only-show-errors)
if ($found_appName.Length -gt 0) {
  Write-Host "Found an existing Service Principal " $app_name
  $ExistingData = (az ad sp list --show-mine --query "[?displayName=='$app_name']| [0]" --only-show-errors) | ConvertFrom-Json
  Write-Host "Updating the variable group"

  $ARM_CLIENT_ID = $ExistingData.appId

  $ARM_TENANT_ID = $ExistingData.appOwnerOrganizationId

  Write-Host "Please update the Control Plane Service Principal Password manually if needed"
}
else {
  Write-Host "Creating the Service Principal" $app_name
  $SPN_Created = $true
  $MGMTData = (az ad sp create-for-rbac --role "Contributor" --scopes $scopes --name $app_name --only-show-errors) | ConvertFrom-Json
  $ARM_CLIENT_ID = $MGMTData.appId
  $ARM_TENANT_ID = $MGMTData.tenant
  $ARM_CLIENT_SECRET = $MGMTData.password

  az role assignment create --assignee $ARM_CLIENT_ID --role "Reader" --subscription $DevSubscriptionID --output none
  az role assignment create --assignee $ARM_CLIENT_ID --role "User Access Administrator" --subscription $ControlPlaneSubscriptionID --output none

  Write-Host "Create the Service Endpoint in Azure DevOps"

  $Env:AZURE_DEVOPS_EXT_AZURE_RM_SERVICE_PRINCIPAL_KEY = $MGMTData.password
  $epExists = (az devops service-endpoint list   --query "[?name=='Control_Plane_Service_Connection'].name | [0]")
  if ($epExists.Length -eq 0) {
    az devops service-endpoint azurerm create  --azure-rm-service-principal-id $ARM_CLIENT_ID --azure-rm-subscription-id $ControlPlaneSubscriptionID --azure-rm-subscription-name $ControlPlaneSubscriptionName --azure-rm-tenant-id $ARM_TENANT_ID --name "Control_Plane_Service_Connection" --output none --only-show-errors

    $epId = az devops service-endpoint list  --query "[?name=='Control_Plane_Service_Connection'].id" -o tsv
    az devops service-endpoint update --id $epId --enable-for-all true --output none --only-show-errors
  }

}

$MGMTGroupID = (az pipelines variable-group list  --query "[?name=='$ControlPlanePrefix'].id | [0]" --only-show-errors)
if ($MGMTGroupID.Length -eq 0) {
  Write-Host "Creating the variable group" $ControlPlanePrefix
  az pipelines variable-group create --name $ControlPlanePrefix --variables Agent='Azure Pipelines' APP_REGISTRATION_APP_ID=$APP_REGISTRATION_ID ARM_CLIENT_ID=$ARM_CLIENT_ID ARM_CLIENT_SECRET='Enter your SPN password here' ARM_SUBSCRIPTION_ID=$ControlPlaneSubscriptionID ARM_TENANT_ID=$ARM_TENANT_ID WEB_APP_CLIENT_SECRET=$WEB_APP_CLIENT_SECRET PAT='Enter your personal access token here' POOL=$Pool_Name AZURE_CONNECTION_NAME='Control_Plane_Service_Connection' WORKLOADZONE_PIPELINE_ID=$wz_pipeline_id SYSTEM_PIPELINE_ID=$system_pipeline_id SDAF_GENERAL_GROUP_ID=$general_group_id SAP_INSTALL_PIPELINE_ID=$installation_pipeline_id --output yaml  --authorize true --output none
  $MGMTGroupID = (az pipelines variable-group list  --query "[?name=='$ControlPlanePrefix'].id | [0]" --only-show-errors)
}

$AlreadySet = [Boolean](az pipelines variable-group variable list --group-id $MGMTGroupID --query ARM_CLIENT_SECRET.isSecret --only-show-errors)
if ($AlreadySet) {
  Write-Host "The secret is already set"
}
else {
  if ( $SPN_Created ) {
    az pipelines variable-group variable update --group-id $MGMTGroupID  --name "ARM_CLIENT_SECRET" --value $ARM_CLIENT_SECRET --secret true --output none --only-show-errors
  }

  az pipelines variable-group variable update --group-id $MGMTGroupID  --name "WEB_APP_CLIENT_SECRET" --value $WEB_APP_CLIENT_SECRET --secret true --output none --only-show-errors
}

$dev_scopes = "/subscriptions/" + $DevSubscriptionID
$dev_app_name = $DevPrefix + " Deployment credential"
if ($Env:SDAF_WorkloadZone_SPN_NAME.Length -ne 0) {
  $dev_app_name = $Env:SDAF_WorkloadZone_SPN_NAME
}


$SPN_Created = $false
$found_appName = (az ad sp list --show-mine --query "[?displayName=='$dev_app_name'].displayName | [0]" --only-show-errors)

if ($found_appName.Length -ne 0) {
  Write-Host "Found an existing Service Principal " $dev_app_name
  $ExistingData = (az ad sp list --show-mine --query "[?displayName=='$dev_app_name'] | [0]" --only-show-errors) | ConvertFrom-Json
  $ARM_CLIENT_ID = $ExistingData.appId
  $ARM_TENANT_ID = $ExistingData.appOwnerOrganizationId
  Write-Host "Please update the Workload zone Service Principal Password manually if needed"
}
else {
  Write-Host "Creating the Service Principal" $dev_app_name
  $SPN_Created = $true
  $Data = (az ad sp create-for-rbac --role="Contributor" --scopes=$dev_scopes --name=$dev_app_name --only-show-errors) | ConvertFrom-Json
  $ARM_CLIENT_ID = $Data.appId
  $ARM_TENANT_ID = $Data.tenant
  $ARM_CLIENT_SECRET = $Data.password

  Write-Host "Assigning reader permissions to the control plane subscription"

  az role assignment create --assignee $ARM_CLIENT_ID --role "Reader" --subscription $ControlPlaneSubscriptionID --output none

  Write-Host "Create the Service Endpoint in Azure DevOps"

  $Env:AZURE_DEVOPS_EXT_AZURE_RM_SERVICE_PRINCIPAL_KEY = $Data.password
  $epExists = (az devops service-endpoint list   --query "[?name=='WorkloadZone_Service_Connection'].name | [0]")
  if ($epExists.Length -eq 0) {
    az devops service-endpoint azurerm create  --azure-rm-service-principal-id $Data.appId --azure-rm-subscription-id $DevSubscriptionID --azure-rm-subscription-name $DevSubscriptionName --azure-rm-tenant-id $Data.tenant --name "WorkloadZone_Service_Connection" --output none --only-show-errors
    $epId = az devops service-endpoint list  --query "[?name=='WorkloadZone_Service_Connection'].id" -o tsv
    az devops service-endpoint update --id $epId --enable-for-all true --output none --only-show-errors
  }
}

$GroupID = (az pipelines variable-group list  --query "[?name=='$WorkloadZonePrefix'].id | [0]" --only-show-errors )
if ($GroupID.Length -eq 0) {
  Write-Host "Creating the variable group" $WorkloadZonePrefix
  az pipelines variable-group create --name $WorkloadZonePrefix --variables Agent='Azure Pipelines' ARM_CLIENT_ID=$ARM_CLIENT_ID ARM_CLIENT_SECRET=$ARM_CLIENT_SECRET ARM_SUBSCRIPTION_ID=$DevSubscriptionID ARM_TENANT_ID=$ARM_TENANT_ID PAT='Enter your personal access token here' POOL=$Pool_Name AZURE_CONNECTION_NAME=DEV_Service_Connection --output yaml  --authorize true --output none
  $GroupID = (az pipelines variable-group list  --query "[?name=='$WorkloadZonePrefix'].id | [0]" --only-show-errors)
}

$AlreadySet = [Boolean](az pipelines variable-group variable list --group-id $GroupID --query ARM_CLIENT_SECRET.isSecret --only-show-errors)
if ($AlreadySet) {
  Write-Host "The secret is already set"
}
else {
  if ($SPN_Created) {
    az pipelines variable-group variable update --group-id $GroupID  --name "ARM_CLIENT_SECRET" --value $ARM_CLIENT_SECRET --secret true --output none --only-show-errors
  }

}

if ($import_code) {
}
else {

  $gh_connection_url = $ADO_ORGANIZATION + "/" + [uri]::EscapeDataString($ADO_Project) + "/_settings/adminservices"
  Write-Host "The browser will now open, please create a new Github connection"
  Start-Process $gh_connection_url

}


$AlreadySet = [Boolean](az pipelines variable-group variable list --group-id $GroupID --query PAT.isSecret --only-show-errors)

if ($AlreadySet) {
  Write-Host "The PAT is already set"
}
else {
  Write-Host "The browser will now open, please create a Personal Access Token. Ensure that Read & manage is selected for Agent Pools, Read & write is selected for Code, Read & execute is selected for Build, and Read, create, & manage is selected for Variable Groups"
  Start-Process $pat_url

  $PAT = Read-Host -Prompt "Enter the PAT you just created"
  az pipelines variable-group variable update --group-id $MGMTGroupID  --name "PAT" --value $PAT --secret true --only-show-errors
  az pipelines variable-group variable update --group-id $GroupID  --name "PAT" --value $PAT --secret true --only-show-errors
  <# Action when all if and elseif conditions are false #>
}

$pool_url = $url.Substring(0, $idx) + "_settings/agentpools"

$POOL_NAME_FOUND = (az pipelines pool list  --query "[?name=='$Pool_Name'].name | [0]")
if ($POOL_NAME_FOUND.Length -gt 0) {
  Write-Host "Agent pool " $Pool_Name  " already exists"
}
else {
  Write-Host "The browser will now open, please create an Agent Pool with the name '$Pool_Name'. Ensure that the Agent Pool is defined using the Self-hosted pool type."

  Start-Process $pool_url.Replace("""", "")
  Read-Host -Prompt "Once you have created the Agent pool, Press any key to continue"
}

Write-Host "The browser will now open, Select the '" $Env:ADO_PROJECT " Build Service' user and ensure that it has 'Allow' in the Contribute section."

$permissions_url = $ADO_ORGANIZATION + "/" + [uri]::EscapeDataString($ADO_Project) + "/_settings/repositories?_a=permissions"

Start-Process $permissions_url
Read-Host -Prompt "Once you have verified the permission, Press any key to continue"

$pipeline_url = $ADO_ORGANIZATION + "/" + [uri]::EscapeDataString($ADO_Project) + "/_build?definitionId=" + $sample_pipeline_id

Write-Host "The browser will now open, please create the control plane configuration in the region you select."

Start-Process $pipeline_url
