
$Organization = $Env:ADO_ORGANIZATION

$Project = $Env:ADO_PROJECT
$YourPrefix = $Env:YourPrefix

if ($Organization.Length -eq 0) {
    Write-Host "Organization is not set"
    $Organization = Read-Host "Enter your ADO organization URL"
}

if ($Project.Length -eq 0) {
  Write-Host "Project is not set"
  $Organization = Read-Host "Enter your ADO project name"
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

az config set extension.use_dynamic_install=yes_without_prompt

az login

$url = ( az devops project list --organization $Organization --query "value | [0].url")
$idx = $url.IndexOf("_api")
$pat_url = $url.Substring(0, $idx) + "_usersSettings/tokens"

$GroupID = (az pipelines variable-group list  --project $Project --query "[?name=='SDAF-MGMT'].id | [0]")
if ($GroupID.Length -eq 0) {
    Write-Host "Could not find variable group SDAF-MGMT"
    exit
}


Write-Host "The browser will now open, please create a Personal Access Token. Ensure that Read & manage is selected for Agent Pools, Read & write is selected for Code, Read & execute is selected for Build, and Read, create, & manage is selected for Variable Groups"

Start-Process $pat_url.Replace("""", "")

$PAT = Read-Host -Prompt "Enter the PAT you just created" -AsSecureString

$pool_url = $url.Substring(0, $idx) + "_settings/agentpools"

Write-Host "The browser will now open, please an Agent Pool with the name 'MGMT-POOL'. Ensure that the Agent Pool is define using the Self-hosted pool type."

Start-Process $pool_url.Replace("""", "")

Read-Host -Prompt "Once you have created the Agent pool, Press any key to continue"


Write-Host "Creating the App registration in Azure Active Directory"

$found_appRegistration = (az ad app list --show-mine --query "[?displayName=='$Name'].displayName | [0]")

if ($found_appRegistration -eq $Name) {
  Write-Host "Found an existing SApp Registration" + $Name
  $ExistingData = (az ad app list --show-mine --query "[?Name=='$app_name']| [0]") | ConvertFrom-Json
  Write-Host "Updating the variable group (APP_REGISTRATION_APP_ID)"

  az pipelines variable-group variable update --group-id $GroupID --project $Project --name "APP_REGISTRATION_APP_ID" --value $ExistingData.appId
  Write-Host "Please update the WEB_APP_CLIENT_SECRET manually if needed in variable group SDAF-MGMT"

}
else {
  Add-Content -Path manifest.json -Value '[{"resourceAppId":"00000003-0000-0000-c000-000000000000","resourceAccess":[{"id":"e1fe6dd8-ba31-4d61-89e7-88639da4683d","type":"Scope"}]}]'

  $APP_REGISTRATION_ID = (az ad app create --display-name $Name --enable-id-token-issuance true --sign-in-audience AzureADMyOrg --required-resource-access .\manifest.json --query "appId").Replace('"', "")

  del manifest.json

  Write-Host "Updating the variable group (APP_REGISTRATION_APP_ID)"

  az pipelines variable-group variable update --group-id $GroupID --project $Project --name "APP_REGISTRATION_APP_ID" --value $APP_REGISTRATION_ID

  $passw = (az ad app credential reset --id $APP_REGISTRATION_ID --append --query "password")
  Write-Host "Updating the variable group (WEB_APP_CLIENT_SECRET)"

  az pipelines variable-group variable update --group-id $GroupID --project $Project --name "WEB_APP_CLIENT_SECRET" --value $passw --secret true
  }


az pipelines variable-group variable update --group-id $GroupID --project $Project --name "ARM_SUBSCRIPTION_ID" --value $ControlPlaneSubscriptionID


$app_name = $MgmtPrefix + " Deployment credential"
$scopes = "/subscriptions/" + $ControlPlaneSubscriptionID

Write-Host "Creating the deployment credentials for the control plane. Service Principal Name" + $app_name

$found_appName = (az ad sp list --show-mine --query "[?displayName=='$app_name'].displayName | [0]")
$MGMTData = null
if ($found_appName -eq $app_name) {
  Write-Host "Found an existing Service Principal " $app_name
  $ExistingData = (az ad sp list --show-mine --query "[?displayName=='$app_name']| [0]") | ConvertFrom-Json
  Write-Host "Updating the variable group"
  az pipelines variable-group variable update --group-id $GroupID --project $Project --name "ARM_CLIENT_ID" --value $ExistingData.appId --output none
  az pipelines variable-group variable update --group-id $GroupID --project $Project --name "ARM_TENANT_ID" --value $ExistingData.appOwnerOrganizationId --output none
  Write-Host "Please update the Control Plane Service Principal Password manually if needed"
}
else {
  Write-Host "Creating the Service Principal" + $app_name
  $MGMTData = (az ad sp create-for-rbac --role="Contributor" --scopes=$scopes --name=$app_name) | ConvertFrom-Json
  Write-Host "Updating the variable group"

  az pipelines variable-group variable update --group-id $GroupID --project $Project --name "ARM_CLIENT_ID" --value $MGMTData.appId --output none
  az pipelines variable-group variable update --group-id $GroupID --project $Project --name "ARM_TENANT_ID" --value $MGMTData.tenant --output none
  az pipelines variable-group variable update --group-id $GroupID --project $Project --name "ARM_CLIENT_SECRET" --value $MGMTData.password --secret true --output none
}
az pipelines variable-group variable update --group-id $GroupID --project $Project --name "PAT" --value $PAT --secret true

$DevGroupID = (az pipelines variable-group list  --project $Project --query "[?name=='SDAF-DEV'].id | [0]")
$dev_scopes = "/subscriptions/" + $DevSubscriptionID
$dev_app_name = $DevPrefix + " Deployment credential"

$found_appName = (az ad sp list --show-mine --query "[?displayName=='$dev_app_name'].displayName | [0]")

if ($found_appName -eq $dev_app_name) {
  Write-Host "Found an existing Service Principal " $dev_app_name
  $ExistingData = (az ad sp list --show-mine --query "[?displayName=='$dev_app_name'] | [0]") | ConvertFrom-Json
  Write-Host "Updating the variable group"
  az pipelines variable-group variable update --group-id $GroupID --project $Project --name "ARM_CLIENT_ID" --value $ExistingData.appId --output none
  az pipelines variable-group variable update --group-id $GroupID --project $Project --name "ARM_TENANT_ID" --value $ExistingData.appOwnerOrganizationId --output none
  Write-Host "Please update the Workoad zone Service Principal Password manually if needed"
}
else {
  Write-Host "Creating the Service Principal" $app_name
  $Data = (az ad sp create-for-rbac --role="Contributor" --scopes=$dev_scopes --name=$dev_app_name) | ConvertFrom-Json
  Write-Host "Updating the variable group"

  az pipelines variable-group variable update --group-id $DevGroupID --project $Project --name "ARM_SUBSCRIPTION_ID" --value $DevSubscriptionID --output none
  az pipelines variable-group variable update --group-id $DevGroupID --project $Project --name "ARM_CLIENT_ID" --value $Data.appId --output none
  az pipelines variable-group variable update --group-id $DevGroupID --project $Project --name "ARM_TENANT_ID" --value $Data.tenant --output none
  az pipelines variable-group variable update --group-id $DevGroupID --project $Project --name "ARM_CLIENT_SECRET" --value $Data.password --secret true --output none
}

az pipelines variable-group variable update --group-id $DevGroupID --project $Project --name "PAT" --value $PAT --secret true

Write-Host "Next create a Service Connection, please use the details shown below"
Write-Host $MGMTData

Write-Host "The browser will now open, please create the Service Connection for the 'Azure Resource Manager' type"

$service_url=$Env:ADO_ORGANIZATION+"/"+$Env:ADO_PROJECT + "/_settings/adminservices"
Start-Process $service_url.Replace("""", "")

$ServiceConnection = Read-Host -Prompt "Enter the Service Connection Name you just created" -AsSecureString

az pipelines variable-group variable create --group-id $GroupID --project $Project --name "AZURE_CONNECTION_NAME" --value $ServiceConnection

