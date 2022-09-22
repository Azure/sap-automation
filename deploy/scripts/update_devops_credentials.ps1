
$Organization = $Env:ADO_ORGANIZATION

$Project = $Env:ADO_PROJECT
$YourPrefix = $Env:YourPrefix

if ($Organization.Length -eq 0) {
  Write-Host "Organization is not set"
  $Organization = Read-Host "Enter your ADO organization URL"
}
else {
  Write-Host "Using Organization: $Organization"
}

if ($Project.Length -eq 0) {
  Write-Host "Project is not set"
  $Organization = Read-Host "Enter your ADO project name"
}
else {
  Write-Host "Using Project: $Project"
}

if ($YourPrefix.Length -eq 0) {
  Write-Host "YourPrefix is not set"
  $YourPrefix = Read-Host "Enter your prefix to be prepended to the Azure AD resources"
}


$MgmtPrefix = $YourPrefix + "-SDAF-MGMT"
$DEVPrefix = $YourPrefix + "-SDAF-DEV"
$Name = $MgmtPrefix + "-configuration-app"
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


az config set extension.use_dynamic_install=yes_without_prompt --only-show-errors

az login --scope https://graph.microsoft.com//.default

$url = ( az devops project list --organization $Organization --query "value | [0].url")
if ($url.Length -eq 0) {
  Write-Host "Could not get the DevOps organization URL"
  exit
}

$idx = $url.IndexOf("_api")
$pat_url = $url.Substring(0, $idx) + "_usersSettings/tokens"

$GroupID = (az pipelines variable-group list --project $Project --organization $Organization --query "[?name=='SDAF-MGMT'].id | [0]" --only-show-errors )
if ($GroupID.Length -eq 0) {
  Write-Host "Could not find variable group SDAF-MGMT"
  exit
}

Write-Host "Found group ID $GroupID"

Write-Host "The browser will now open, please create a Personal Access Token. Ensure that Read & manage is selected for Agent Pools, Read & write is selected for Code, Read & execute is selected for Build, and Read, create, & manage is selected for Variable Groups"

Start-Process $pat_url.Replace("""", "")

$PAT = Read-Host -Prompt "Enter the PAT you just created" -AsSecureString
az pipelines variable-group variable update --group-id $GroupID --project $Project --organization $Organization --name "PAT" --value $PAT --secret true --only-show-errors

$pool_url = $url.Substring(0, $idx) + "_settings/agentpools"

Write-Host "The browser will now open, please an Agent Pool with the name 'MGMT-POOL'. Ensure that the Agent Pool is define using the Self-hosted pool type."

Start-Process $pool_url.Replace("""", "")

Read-Host -Prompt "Once you have created the Agent pool, Press any key to continue"

Write-Host "Creating the App registration in Azure Active Directory"

$found_appRegistration = (az ad app list --show-mine --query "[?displayName=='$Name'].displayName | [0]" --only-show-errors)

if ($found_appRegistration -eq $Name) {
  Write-Host "Found an existing App Registration" + $Name
  $ExistingData = (az ad app list --show-mine --query "[?Name=='$app_name']| [0]" --only-show-errors) | ConvertFrom-Json
  Write-Host "Updating the variable group (APP_REGISTRATION_APP_ID)"

  az pipelines variable-group variable update --group-id $GroupID --project $Project --organization $Organization --name "APP_REGISTRATION_APP_ID" --value $ExistingData.appId --only-show-errors
  Write-Host "Please update the WEB_APP_CLIENT_SECRET manually if needed in variable group SDAF-MGMT"

}
else {
  Add-Content -Path manifest.json -Value '[{"resourceAppId":"00000003-0000-0000-c000-000000000000","resourceAccess":[{"id":"e1fe6dd8-ba31-4d61-89e7-88639da4683d","type":"Scope"}]}]'

  $APP_REGISTRATION_ID = (az ad app create --display-name $Name --enable-id-token-issuance true --sign-in-audience AzureADMyOrg --required-resource-access .\manifest.json --query "appId").Replace('"', "")

  Remove-Item manifest.json

  Write-Host "Updating the variable group (APP_REGISTRATION_APP_ID)"

  az pipelines variable-group variable update --group-id $GroupID --project $Project --organization $Organization --name "APP_REGISTRATION_APP_ID" --value $APP_REGISTRATION_ID --only-show-errors

  $passw = (az ad app credential reset --id $APP_REGISTRATION_ID --append --query "password" --only-show-errors)
  Write-Host "Updating the variable group (WEB_APP_location =CLIENT_SECRET)"

  az pipelines variable-group variable update --group-id $GroupID --project $Project --organization $Organization --name "WEB_APP_CLIENT_SECRET" --value $passw --secret true --only-show-errors
}


az pipelines variable-group variable update --group-id $GroupID --project $Project --organization $Organization --name "ARM_SUBSCRIPTION_ID" --value $ControlPlaneSubscriptionID --only-show-errors


$app_name = $MgmtPrefix + " Deployment credential"
$scopes = "/subscriptions/" + $ControlPlaneSubscriptionID

Write-Host "Creating the deployment credentials for the control plane. Service Principal Name" $app_name

$found_appName = (az ad sp list --show-mine --query "[?displayName=='$app_name'].displayName | [0]" --only-show-errors)
if ($found_appName -eq $app_name) {
  Write-Host "Found an existing Service Principal " $app_name
  $ExistingData = (az ad sp list --show-mine --query "[?displayName=='$app_name']| [0]" --only-show-errors) | ConvertFrom-Json
  Write-Host "Updating the variable group"

  az pipelines variable-group variable update --group-id $GroupID --project $Project --organization $Organization --name "ARM_CLIENT_ID" --value $ExistingData.appId --output none --only-show-errors
  az pipelines variable-group variable update --group-id $GroupID --project $Project --organization $Organization --name "ARM_TENANT_ID" --value $ExistingData.appOwnerOrganizationId --output none --only-show-errors
  Write-Host "Please update the Control Plane Service Principal Password manually if needed"
}
else {
  Write-Host "Creating the Service Principal" $app_name
  $MGMTData = (az ad sp create-for-rbac --role="Contributor" --scopes=$scopes --name=$app_name --only-show-errors) | ConvertFrom-Json
  Write-Host "Updating the variable group"

  az pipelines variable-group variable update --group-id $GroupID --project $Project --organization $Organization --name "ARM_CLIENT_ID" --value $MGMTData.appId --output none --only-show-errors
  az pipelines variable-group variable update --group-id $GroupID --project $Project --organization $Organization --name "ARM_TENANT_ID" --value $MGMTData.tenant --output none --only-show-errors
  az pipelines variable-group variable update --group-id $GroupID --project $Project --organization $Organization --name "ARM_CLIENT_SECRET" --value $MGMTData.password --secret true --output none --only-show-errors
  $Env:AZURE_DEVOPS_EXT_AZURE_RM_SERVICE_PRINCIPAL_KEY = $MGMTData.password
  $epExists = (az devops service-endpoint list  --project $Project --organization $Organization --query "[?name=='Control_Plane_Service_Connection'].name | [0]")
  if ($epExists -ne 'Control_Plane_Service_Connection') {
    az devops service-endpoint azurerm create --project $Project --organization $Organization --azure-rm-service-principal-id $MGMTData.appId --azure-rm-subscription-id $ControlPlaneSubscriptionID --azure-rm-subscription-name $ControlPlaneSubscriptionName --azure-rm-tenant-id $MGMTData.tenant --name "Control_Plane_Service_Connection" --output none --only-show-errors
  }
  
  az pipelines variable-group variable update --group-id $GroupID --project $Project --organization $Organization --name "AZURE_CONNECTION_NAME" --value "Control_Plane_Service_Connection" --only-show-errors
}


$DevGroupID = (az pipelines variable-group list --project $Project  --organization $Organization --query "[?name=='SDAF-DEV'].id | [0]")
Write-Host "SDAF-DEV variable group ID" $DevGroupID
$dev_scopes = "/subscriptions/" + $DevSubscriptionID
$dev_app_name = $DevPrefix + " Deployment credential"

$found_appName = (az ad sp list --show-mine --query "[?displayName=='$dev_app_name'].displayName | [0]" --only-show-errors)

if ($found_appName -eq $dev_app_name) {
  Write-Host "Found an existing Service Principal " $dev_app_name
  $ExistingData = (az ad sp list --show-mine --query "[?displayName=='$dev_app_name'] | [0]" --only-show-errors) | ConvertFrom-Json
  Write-Host "Updating the variable group"
  az pipelines variable-group variable update --group-id $DevGroupID --project $Project --organization $Organization --name "ARM_CLIENT_ID" --value $ExistingData.appId --output none --only-show-errors
  az pipelines variable-group variable update --group-id $DevGroupID --project $Project --organization $Organization --name "ARM_TENANT_ID" --value $ExistingData.appOwnerOrganizationId --output none --only-show-errors
  Write-Host "Please update the Workoad zone Service Principal Password manually if needed"
}
else {
  Write-Host "Creating the Service Principal" $app_name
  $Data = (az ad sp create-for-rbac --role="Contributor" --scopes=$dev_scopes --name=$dev_app_name --only-show-errors) | ConvertFrom-Json
  Write-Host "Updating the variable group"

  az pipelines variable-group variable update --group-id $DevGroupID --project $Project --organization $Organization --name "ARM_SUBSCRIPTION_ID" --value $DevSubscriptionID --output none --only-show-errors
  az pipelines variable-group variable update --group-id $DevGroupID --project $Project --organization $Organization --name "ARM_CLIENT_ID" --value $Data.appId --output none --only-show-errors
  az pipelines variable-group variable update --group-id $DevGroupID --project $Project --organization $Organization --name "ARM_TENANT_ID" --value $Data.tenant --output none --only-show-errors
  az pipelines variable-group variable update --group-id $DevGroupID --project $Project --organization $Organization --name "ARM_CLIENT_SECRET" --value $Data.password --secret true --output none --only-show-errors
  $Env:AZURE_DEVOPS_EXT_AZURE_RM_SERVICE_PRINCIPAL_KEY = $Data.password
  $epExists = (az devops service-endpoint list  --project $Project --organization $Organization --query "[?name=='DEV_Service_Connection'].name | [0]")
  if ($epExists -ne 'DEV_Service_Connection') {
    az devops service-endpoint azurerm create --project $Project --organization $Organization --azure-rm-service-principal-id $Data.appId --azure-rm-subscription-id $DevSubscriptionID --azure-rm-subscription-name $DevSubscriptionName --azure-rm-tenant-id $Data.tenant --name "DEV_Service_Connection" --output none --only-show-errors
  }
}

az pipelines variable-group variable update --group-id $DevGroupID --project $Project --organization $Organization --name "PAT" --value $PAT --secret true --only-show-errors


