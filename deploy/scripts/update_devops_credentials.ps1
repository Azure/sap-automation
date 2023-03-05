#----------------------
# Set $Organization
#   Input     or    $Env:ADO_ORGANIZATION
#----------------------
if ($Env:ADO_ORGANIZATION.Length -eq 0) {
  Write-Host "Organization is not set"
  $Organization = Read-Host "Enter your ADO organization URL"
}
else {
  $Organization = $Env:ADO_ORGANIZATION
}
Write-Host "Organization:                   $Organization"
#----------------------

#----------------------
# Set $Project
#   Input     or    $Env:ADO_PROJECT
#----------------------
if ($Env:ADO_PROJECT.Length -eq 0) {
  Write-Host "Project is not set"
  $Project = Read-Host "Enter your ADO organization URL"
}
else {
  $Project = $Env:ADO_PROJECT
}
Write-Host "Project:                        $Project"
#----------------------

#----------------------
# Set $SDAF_CONTROL_PLANE_CODE
#   Default     or    $Env:SDAF_CONTROL_PLANE_CODE
#----------------------
if ($Env:SDAF_CONTROL_PLANE_CODE.Length -ne 0) {
  $SDAF_CONTROL_PLANE_CODE = $Env:SDAF_CONTROL_PLANE_CODE
}
else { $SDAF_CONTROL_PLANE_CODE = "MGMT" }
Write-Host "SDAF_CONTROL_PLANE_CODE:        $SDAF_CONTROL_PLANE_CODE"
#----------------------

#----------------------
# Set $SDAF_WORKLOAD_ZONE_CODE
#   Default     or    $Env:SDAF_WORKLOAD_ZONE_CODE
#----------------------
if ($Env:SDAF_WORKLOAD_ZONE_CODE.Length -ne 0) {
  $SDAF_WORKLOAD_ZONE_CODE = $Env:SDAF_WORKLOAD_ZONE_CODE
}
else { $SDAF_WORKLOAD_ZONE_CODE = "DEV" }
Write-Host "SDAF_WORKLOAD_ZONE_CODE:        $SDAF_WORKLOAD_ZONE_CODE"
#----------------------

$MgmtPrefix = "SDAF-"+$SDAF_CONTROL_PLANE_CODE
$DEVPrefix = "SDAF-"+$SDAF_WORKLOAD_ZONE_CODE

#----------------------
# Set $Name
#   Default     or    $Env:SDAF_APP_NAME
#----------------------
if ($Env:SDAF_APP_NAME.Length -eq 0) {
  $Name = $MgmtPrefix + "-configuration-app"
}
else { $Name = $Env:SDAF_APP_NAME }
Write-Host "Name:                           $Name"
#----------------------

#----------------------
# Set $ControlPlaneSubscriptionID
#   Exit     or    $Env:ControlPlaneSubscriptionID
#----------------------
if ($Env:ControlPlaneSubscriptionID.Length -ne 0) {
  $ControlPlaneSubscriptionID = $Env:ControlPlaneSubscriptionID
}
else { Write-Host "ControlPlaneSubscriptionID is not set"; exit }
Write-Host "ControlPlaneSubscriptionID:     $ControlPlaneSubscriptionID"
#----------------------

#----------------------
# Set $ControlPlaneSubscriptionName
#   Exit     or    $Env:ControlPlaneSubscriptionName
#----------------------
if ($Env:ControlPlaneSubscriptionName.Length -ne 0) {
  $ControlPlaneSubscriptionName = $Env:ControlPlaneSubscriptionName
}
else { Write-Host "ControlPlaneSubscriptionName is not set"; exit }
Write-Host "ControlPlaneSubscriptionName:   $ControlPlaneSubscriptionName"
#----------------------

#----------------------
# Set $DevSubscriptionID
#   Exit     or    $Env:DevSubscriptionID
#----------------------
if ($Env:DevSubscriptionID.Length -ne 0) {
  $DevSubscriptionID = $Env:DevSubscriptionID
}
else { Write-Host "DevSubscriptionID is not set"; exit }
Write-Host "DevSubscriptionID:              $DevSubscriptionID"
#----------------------

#----------------------
# Set $DevSubscriptionName
#   Exit     or    $Env:DevSubscriptionName
#----------------------
if ($Env:DevSubscriptionName.Length -ne 0) {
  $DevSubscriptionName = $Env:DevSubscriptionName
}
else { Write-Host "DevSubscriptionName is not set"; exit }
Write-Host "DevSubscriptionName:            $DevSubscriptionName"
#----------------------


$POOL=$SDAF_CONTROL_PLANE_CODE+"-POOL"


Write-Host

Write-Host "Set Defaults..."
az config set extension.use_dynamic_install=yes_without_prompt --only-show-errors
az devops configure --defaults organization=$Env:ADO_ORGANIZATION project=$Env:ADO_PROJECT

Write-Host "Perform Login..."
az login --scope https://graph.microsoft.com//.default

Write-Host "Validate Organization URL..."
$url = ( az devops project list --organization $Organization --query "value | [0].url")
if ($url.Length -eq 0) { Write-Host "Could not get the DevOps organization URL"; exit }
else { $url_substr = $url.Substring(0, $url.IndexOf("_api")) }
Write-Host "  url_substr:       $url_substr"


Write-Host "Validate Project ID..."
$project_id = (az devops project list --organization $Env:ADO_ORGANIZATION --query "[value[]] | [0] | [? name=='$Env:ADO_PROJECT'].id | [0]").Replace("""", "")
if ($project_id.Length -eq 0) { Write-Host "Could not get the DevOps Project ID"; exit }
Write-Host "  project_id:       $project_id"


$pat_url = ($url_substr + "_usersSettings/tokens").Replace("""", "")
$permissions_url = ($url_substr + $project_id + "/_settings/repositories?_a=permissions").Replace("""", "")
$pool_url = ($url_substr + "_settings/agentpools").Replace("""", "")
Write-Host "Defining URL's..."
Write-Host "  pat_url:         $pat_url"
Write-Host "  permissions_url: $permissions_url"
Write-Host "  pool_url:        $pool_url"


Write-Host "Getting Group ID for: $MgmtPrefix"
$GroupID = (az pipelines variable-group list --project $Project --organization $Organization --query "[?name=='$MgmtPrefix'].id | [0]" --only-show-errors )
if ($GroupID.Length -eq 0) { Write-Host "Could not find variable group $MgmtPrefix"; exit }
Write-Host " Found group ID $GroupID"


Write-Host "Checking PAT Secret..."
$AlreadySet = [Boolean](az pipelines variable-group variable list --group-id $GroupID --query PAT.isSecret --only-show-errors)
if ($AlreadySet) { Write-Host " The PAT is already set" }
else {
  Write-Host "The browser will now open, please create a Personal Access Token. Ensure that Read & manage is selected for Agent Pools, Read & write is selected for Code, Read & execute is selected for Build, and Read, create, & manage is selected for Variable Groups"
  Start-Process $pat_url

  $PAT = Read-Host -Prompt "Enter the PAT you just created"
  Write-Host "  Setting PAT Secret..."
  az pipelines variable-group variable update --group-id $GroupID --project $Project --organization $Organization --name "PAT" --value $PAT --secret true --only-show-errors
}


Write-Host "Checking Agent Pool: $POOL..."
$POOL_NAME = $(az pipelines pool list  --organization $Organization  --query "[?name=='$POOL'].name | [0]")
if ($POOL_NAME.Length -ne 0) { Write-Host " Agent pool " $POOL " already exists" }
else {
  Write-Host "The browser will now open, please create an Agent Pool with the name '$POOL'. Ensure that the Agent Pool is define using the Self-hosted pool type."

  Start-Process $pool_url
  Read-Host -Prompt "Once you have created the Agent pool, Press any key to continue"
}


Write-Host "Build Service Permissions..."
Write-Host "The browser will now open, please ensure that the '" $Env:ADO_PROJECT " Build Service' has 'Allow' in the Contribute section"

Start-Process $permissions_url
Read-Host -Prompt "Once you have verified the permission, Press any key to continue"


Write-Host "Creating the App registration in Azure Active Directory"

$found_appRegistration = (az ad app list --show-mine --query "[?displayName=='$Name'].displayName | [0]" --only-show-errors)

if ($found_appRegistration -eq $Name) {
  Write-Host "Found an existing App Registration" + $Name
  $ExistingData = (az ad app list --show-mine --query "[?displayName=='$Name']| [0]" --only-show-errors) | ConvertFrom-Json
  Write-Host "Updating the variable group (APP_REGISTRATION_APP_ID)"

  az pipelines variable-group variable update --group-id $GroupID --project $Project --organization $Organization --name "APP_REGISTRATION_APP_ID" --value $ExistingData.appId --only-show-errors
  Write-Host "Please update the WEB_APP_CLIENT_SECRET manually if needed in variable group " + $MgmtPrefix

}
else {
  Add-Content -Path manifest.json -Value '[{"resourceAppId":"00000003-0000-0000-c000-000000000000","resourceAccess":[{"id":"e1fe6dd8-ba31-4d61-89e7-88639da4683d","type":"Scope"}]}]'

  $APP_REGISTRATION_ID = (az ad app create --display-name $Name --enable-id-token-issuance true --sign-in-audience AzureADMyOrg --required-resource-access .\manifest.json --query "appId").Replace('"', "")

  Remove-Item manifest.json

  Write-Host "Set the application registration id"

  az pipelines variable-group variable update --group-id $GroupID --project $Project --organization $Organization --name "APP_REGISTRATION_APP_ID" --value $APP_REGISTRATION_ID --only-show-errors

  $passw = (az ad app credential reset --id $APP_REGISTRATION_ID --append --query "password" --only-show-errors)
  Write-Host "Set the web application secret"

  az pipelines variable-group variable update --group-id $GroupID --project $Project --organization $Organization --name "WEB_APP_CLIENT_SECRET" --value $passw --secret true --only-show-errors
}


az pipelines variable-group variable update --group-id $GroupID --project $Project --organization $Organization --name "ARM_SUBSCRIPTION_ID" --value $ControlPlaneSubscriptionID --only-show-errors

$app_name = $MgmtPrefix + " Deployment credential"
if ($Env:SDAF_MGMT_SPN_NAME.Length -ne 0) {
  $app_name = $Env:SDAF_MGMT_SPN_NAME
}

$scopes = "/subscriptions/" + $ControlPlaneSubscriptionID

Write-Host "Creating the deployment credentials for the control plane. Service Principal Name" $app_name

$found_appName = (az ad sp list --show-mine --query "[?displayName=='$app_name'].displayName | [0]" --only-show-errors)
if ($found_appName.Length -gt 0) {
  Write-Host "Found an existing Service Principal " $app_name
  $ExistingData = (az ad sp list --show-mine --query "[?displayName=='$app_name']| [0]" --only-show-errors) | ConvertFrom-Json
  Write-Host "Updating the variable group"

  az pipelines variable-group variable update --group-id $GroupID --project $Project --organization $Organization --name "CP_ARM_CLIENT_ID" --value $ExistingData.appId --output none --only-show-errors
  az pipelines variable-group variable update --group-id $GroupID --project $Project --organization $Organization --name "CP_ARM_OBJECT_ID" --value $ExistingData.Id --output none --only-show-errors
  az pipelines variable-group variable update --group-id $GroupID --project $Project --organization $Organization --name "CP_ARM_TENANT_ID" --value $ExistingData.appOwnerOrganizationId --output none --only-show-errors
  Write-Host "Please update the Control Plane Service Principal Password manually if needed"
}
else {
  Write-Host "Creating the Service Principal" $app_name
  $MGMTData = (az ad sp create-for-rbac --role="Contributor" --scopes=$scopes --name=$app_name --only-show-errors) | ConvertFrom-Json
  Write-Host "Updating the variable group"

  az pipelines variable-group variable update --group-id $GroupID --project $Project --organization $Organization --name "CP_ARM_CLIENT_ID" --value $MGMTData.appId --output none --only-show-errors
  az pipelines variable-group variable update --group-id $GroupID --project $Project --organization $Organization --name "CP_ARM_OBJECT_ID" --value $MGMTData.Id --output none --only-show-errors
  az pipelines variable-group variable update --group-id $GroupID --project $Project --organization $Organization --name "CP_ARM_TENANT_ID" --value $MGMTData.tenant --output none --only-show-errors
  az pipelines variable-group variable update --group-id $GroupID --project $Project --organization $Organization --name "CP_ARM_CLIENT_SECRET" --value $MGMTData.password --secret true --output none --only-show-errors
  $Env:AZURE_DEVOPS_EXT_AZURE_RM_SERVICE_PRINCIPAL_KEY = $MGMTData.password
  $epExists = (az devops service-endpoint list  --project $Project --organization $Organization --query "[?name=='Control_Plane_Service_Connection'].name | [0]")
  if ($epExists.Length -eq 0) {
    az devops service-endpoint azurerm create --project $Project --organization $Organization --azure-rm-service-principal-id $MGMTData.appId --azure-rm-subscription-id $ControlPlaneSubscriptionID --azure-rm-subscription-name $ControlPlaneSubscriptionName --azure-rm-tenant-id $MGMTData.tenant --name "Control_Plane_Service_Connection" --output none --only-show-errors
  }

  az pipelines variable-group variable update --group-id $GroupID --project $Project --organization $Organization --name "AZURE_CONNECTION_NAME" --value "Control_Plane_Service_Connection" --only-show-errors
}



$DevGroupID = (az pipelines variable-group list --project $Project  --organization $Organization --query "[?name=='$DEVPrefix'].id | [0]")
Write-Host "SDAF-DEV variable group ID" $DevGroupID
$dev_scopes = "/subscriptions/" + $DevSubscriptionID
$dev_app_name = $DevPrefix + " Deployment credential"
if ($Env:SDAF_DEV_SPN_NAME.Length -ne 0) {
  $dev_app_name = $Env:SDAF_DEV_SPN_NAME
}

$found_appName = (az ad sp list --show-mine --query "[?displayName=='$dev_app_name'].displayName | [0]" --only-show-errors)

if ($found_appName.Length -ne 0) {
  Write-Host "Found an existing Service Principal " $dev_app_name
  $ExistingData = (az ad sp list --show-mine --query "[?displayName=='$dev_app_name'] | [0]" --only-show-errors) | ConvertFrom-Json
  Write-Host "Updating the variable group"
  az pipelines variable-group variable update --group-id $DevGroupID --project $Project --organization $Organization --name "ARM_CLIENT_ID" --value $ExistingData.appId --output none --only-show-errors
  az pipelines variable-group variable update --group-id $DevGroupID --project $Project --organization $Organization --name "ARM_OBJECT_ID" --value $ExistingData.Id --output none --only-show-errors
  az pipelines variable-group variable update --group-id $DevGroupID --project $Project --organization $Organization --name "ARM_TENANT_ID" --value $ExistingData.appOwnerOrganizationId --output none --only-show-errors
  Write-Host "Please update the Workload zone Service Principal Password manually if needed"
}
else {
  Write-Host "Creating the Service Principal" $app_name
  $Data = (az ad sp create-for-rbac --role="Contributor" --scopes=$dev_scopes --name=$dev_app_name --only-show-errors) | ConvertFrom-Json
  Write-Host "Updating the variable group"

  az pipelines variable-group variable update --group-id $DevGroupID --project $Project --organization $Organization --name "ARM_SUBSCRIPTION_ID" --value $DevSubscriptionID --output none --only-show-errors
  az pipelines variable-group variable update --group-id $DevGroupID --project $Project --organization $Organization --name "ARM_CLIENT_ID" --value $Data.appId --output none --only-show-errors
  az pipelines variable-group variable update --group-id $DevGroupID --project $Project --organization $Organization --name "ARM_OBJECT_ID" --value $Data.Id --output none --only-show-errors
  az pipelines variable-group variable update --group-id $DevGroupID --project $Project --organization $Organization --name "ARM_TENANT_ID" --value $Data.tenant --output none --only-show-errors
  az pipelines variable-group variable update --group-id $DevGroupID --project $Project --organization $Organization --name "ARM_CLIENT_SECRET" --value $Data.password --secret true --output none --only-show-errors
  $Env:AZURE_DEVOPS_EXT_AZURE_RM_SERVICE_PRINCIPAL_KEY = $Data.password

  $Dev_Connection=$SDAF_WORKLOAD_ZONE_CODE+"_Service_Connection"
  $epExists = (az devops service-endpoint list  --project $Project --organization $Organization --query "[?name=='$Dev_Connection'].name | [0]")
  if ($epExists.Length -eq 0) {
    az devops service-endpoint azurerm create --project $Project --organization $Organization --azure-rm-service-principal-id $Data.appId --azure-rm-subscription-id $DevSubscriptionID --azure-rm-subscription-name $DevSubscriptionName --azure-rm-tenant-id $Data.tenant --name $Dev_Connection --output none --only-show-errors
  }
}
if ($AlreadySet) {
  Write-Host "The PAT is already set"
}
else {
  az pipelines variable-group variable update --group-id $DevGroupID --project $Project --organization $Organization --name "PAT" --value $PAT --secret true --only-show-errors
}

