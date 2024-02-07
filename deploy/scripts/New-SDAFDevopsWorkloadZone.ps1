function Show-Menu($data) {
  Write-Host "================ $Title ================"
  $i = 1
  foreach ($d in $data) {
    Write-Host "($i): Select '$i' for $($d)"
    $i++
  }

  Write-Host "q: Select 'q' for Exit"

}


#region Initialize
# Initialize variables from Environment variables

$ADO_Organization = $Env:SDAF_ADO_ORGANIZATION
$ADO_Project = $Env:SDAF_ADO_PROJECT
$Workload_zone_subscriptionID = $Env:SDAF_WorkloadZoneSubscriptionID
$Workload_zoneSubscriptionName = $Env:SDAF_WorkloadZoneSubscriptionName
$Workload_zone_code = $Env:SDAF_WORKLOAD_ZONE_CODE

if ($Workload_zone_code.Length -eq 0) {

  $Workload_zone_code = Read-Host "Please provide the workload zone code "
}

if ($ADO_Organization.Length -eq 0) {
  Write-Host "Organization is not set"
  $ADO_Organization = Read-Host "Enter your ADO organization URL"
}
else {
  Write-Host "Using Organization: $ADO_Organization" -foregroundColor Yellow
}

if ($ADO_Project.Length -eq 0) {
  Write-Host "Project name is not set"
  $ADO_Project = Read-Host "Enter your ADO Project name"
}
else {
  Write-Host "Using Project: $ADO_Project" -foregroundColor Yellow
}

#endregion

if ($Env:ARM_TENANT_ID.Length -eq 0) {
  $Env:ARM_TENANT_ID = Read-Host "Please provide Tenant ID, you can find it in the Azure portal under Microsoft Entra ID -> Overview -> Tenant ID"
  az login --output none --only-show-errors
}
else {
  az login --output none --tenant $Env:ARM_TENANT_ID --only-show-errors
}

# Check if access to the Azure DevOps organization is available and prompt for PAT if needed
# Exact permissions required, to be validated, and included in the Read-Host text.
$checkPAT = (az devops user list --organization $ADO_Organization --only-show-errors --top 1)
if ($checkPAT.Length -eq 0) {
  $env:AZURE_DEVOPS_EXT_PAT = Read-Host "Please enter your Personal Access Token (PAT) with full access to the Azure DevOps organization $ADO_Organization"
  $verifyPAT = (az devops user list --organization $ADO_Organization --only-show-errors --top 1)
  if ($verifyPAT.Length -eq 0) {
    Read-Host -Prompt "Failed to authenticate to the Azure DevOps organization, press <any key> to exit"
    exit
  }
  else {
    Write-Host "Successfully authenticated to the Azure DevOps organization $ADO_Organization" -ForegroundColor Green
  }
}
else {
  Write-Host "Successfully authenticated to the Azure DevOps organization $ADO_Organization" -ForegroundColor Green
}

Write-Host ""
Write-Host ""

if ($Env:SDAF_AuthenticationMethod.Length -eq 0) {
  $Title = "Select the authentication method to use"
  $data = @('Service Principal', 'Managed Identity')
  Show-Menu($data)
  $selection = Read-Host $Title
  $authenticationMethod = $data[$selection - 1]

}
else {
  $authenticationMethod = $Env:SDAF_AuthenticationMethod
}

Write-Host "Using authentication method: $authenticationMethod" -ForegroundColor Yellow


Write-Host "The browser will now open, please copy the name of the Agent Pool"
$pool_url = $ADO_ORGANIZATION + "/" + [uri]::EscapeDataString($ADO_Project) + "/_settings/agentqueues"
Start-Process $pool_url

$Pool_Name = Read-Host "Please provide the Agent pool name"

Write-Host ""

az config set extension.use_dynamic_install=yes_without_prompt --only-show-errors
az extension add --name azure-devops --only-show-errors

#region Validate parameters

if ($Workload_zone_subscriptionID.Length -eq 0) {
  Write-Host "$Env:WorkloadZoneSubscriptionID is not set!" -ForegroundColor Red
  $Workload_zone_subscriptionID = Read-Host "Please enter your Workload zone subscription ID"
  az account set --sub $Workload_zone_subscriptionID
  $Workload_zoneSubscriptionName = (az account show --query name -o tsv)

  exit
}
else {
  az account set --sub $Workload_zone_subscriptionID
  $Workload_zoneSubscriptionName = (az account show --query name -o tsv)
}

if ($Workload_zoneSubscriptionName.Length -eq 0) {
  Write-Host "Workload_zoneSubscriptionName is not set"
  exit
}


az devops configure --defaults organization=$ADO_Organization project=$ADO_Project --output none

if ($Workload_zone_code.Length -eq 0) {
  Write-Host "Workload zone code is not set (DEV, etc)"
  $Workload_zone_code = Read-Host "Enter your Workload zone code"
}
else {
  Write-Host "Using Workload zone code: $Workload_zone_code" -foregroundColor Yellow
}

$WorkloadZonePrefix = "SDAF-" + $Workload_zone_code

$url = ( az devops project list --organization $ADO_Organization --query "value | [0].url")
if ($url.Length -eq 0) {
  Write-Error "Could not get the DevOps organization URL"
  exit
}

$Project_ID = (az devops project list --organization $ADO_ORGANIZATION --query "[value[]] | [0] | [?name=='$ADO_Project'].id | [0]")

if ($Project_ID.Length -eq 0) {
  Write-Host "Project " $ADO_PROJECT " was not found" -ForegroundColor Red
  exit
}

#region Workload zone Service Principal

$ARM_CLIENT_SECRET = "Please update"
$ARM_OBJECT_ID = ""

$workload_zone_scopes = "/subscriptions/" + $Workload_zone_subscriptionID
$workload_zone_spn_name = $Workload_zonePrefix + " Deployment credential"

if ($Env:SDAF_WorkloadZone_SPN_NAME.Length -ne 0) {
  $workload_zone_spn_name = $Env:SDAF_WorkloadZone_SPN_NAME
}
else {
  if ($authenticationMethod -eq "Service Principal") {
    $workload_zone_spn_name = Read-Host "Please provide the Service Principal name to be used for the deployments in the workload zone"
  }
}

if ($authenticationMethod -eq "Service Principal") {

  $found_appName = (az ad sp list --all --filter "startswith(displayName,' $workload_zone_spn_name')" --query  "[?displayName=='$workload_zone_spn_name'].displayName | [0]" --only-show-errors)

  if ($found_appName.Length -ne 0) {
    Write-Host "Found an existing Service Principal:" $workload_zone_spn_name -ForegroundColor Green
    $ExistingData = (az ad sp list --all --filter "startswith(displayName,'$workload_zone_spn_name')" --query  "[?displayName=='$workload_zone_spn_name'] | [0]" --only-show-errors) | ConvertFrom-Json
    $ARM_CLIENT_ID = $ExistingData.appId
    $ARM_TENANT_ID = $ExistingData.appOwnerOrganizationId
    $ARM_OBJECT_ID = $ExistingData.Id

    $confirmation = Read-Host "Reset the Workload zone Service Principal password y/n?"
    if ($confirmation -eq 'y') {
      $ARM_CLIENT_SECRET = (az ad sp credential reset --id $ARM_CLIENT_ID --append --query "password" --out tsv --only-show-errors)
    }
    else {
      $ARM_CLIENT_SECRET = Read-Host "Enter the Workload zone Service Principal password"
    }

  }
  else {
    Write-Host "Creating the Service Principal" $workload_zone_spn_name -ForegroundColor Green
    $Data = (az ad sp create-for-rbac --role="Contributor" --scopes=$workload_zone_scopes --name=$workload_zone_spn_name --only-show-errors) | ConvertFrom-Json
    $ARM_CLIENT_SECRET = $Data.password
    $ExistingData = (az ad sp list --all --filter "startswith(displayName,'$workload_zone_spn_name')" --query  "[?displayName=='$workload_zone_spn_name'] | [0]" --only-show-errors) | ConvertFrom-Json
    $ARM_CLIENT_ID = $ExistingData.appId
    $ARM_TENANT_ID = $ExistingData.appOwnerOrganizationId
    $ARM_OBJECT_ID = $ExistingData.Id
  }


  $Service_Connection_Name = $Workload_zone_code + "_WorkloadZone_Service_Connection"

  $GroupID = (az pipelines variable-group list --query "[?name=='$WorkloadZonePrefix'].id | [0]" --organization $ADO_ORGANIZATION --project $ADO_Project --only-show-errors )
  if ($GroupID.Length -eq 0) {
    Write-Host "Creating the variable group" $WorkloadZonePrefix -ForegroundColor Green
    az pipelines variable-group create --name $WorkloadZonePrefix --variables Agent='Azure Pipelines' ARM_CLIENT_ID=$ARM_CLIENT_ID ARM_OBJECT_ID=$ARM_OBJECT_ID ARM_CLIENT_SECRET=$ARM_CLIENT_SECRET ARM_SUBSCRIPTION_ID=$Workload_zone_subscriptionID ARM_TENANT_ID=$ARM_TENANT_ID WZ_PAT='Enter your personal access token here' POOL=$Pool_Name AZURE_CONNECTION_NAME=$Service_Connection_Name TF_LOG=OFF Logon_Using_SPN=true USE_MSI=false--output none --authorize true  --organization $ADO_ORGANIZATION --project $ADO_Project
    $GroupID = (az pipelines variable-group list --query "[?name=='$WorkloadZonePrefix'].id | [0]"  --organization $ADO_ORGANIZATION --project $ADO_Project --only-show-errors)
  }

}
else {
  $Service_Connection_Name = $Workload_zone_code + "_WorkloadZone_Service_Connection"

  $GroupID = (az pipelines variable-group list --query "[?name=='$WorkloadZonePrefix'].id | [0]" --organization $ADO_ORGANIZATION --project $ADO_Project --only-show-errors )
  if ($GroupID.Length -eq 0) {
    Write-Host "Creating the variable group" $WorkloadZonePrefix -ForegroundColor Green
    az pipelines variable-group create --name $WorkloadZonePrefix --variables Agent='Azure Pipelines' ARM_SUBSCRIPTION_ID=$Workload_zone_subscriptionID WZ_PAT='Enter your personal access token here' POOL=$Pool_Name AZURE_CONNECTION_NAME=$Service_Connection_Name TF_LOG=OFF Logon_Using_SPN=false USE_MSI=true --output none --authorize true  --organization $ADO_ORGANIZATION --project $ADO_Project
    $GroupID = (az pipelines variable-group list --query "[?name=='$WorkloadZonePrefix'].id | [0]"  --organization $ADO_ORGANIZATION --project $ADO_Project --only-show-errors)
  }
}
$idx = $url.IndexOf("_api")
$pat_url = ($url.Substring(0, $idx) + "_usersSettings/tokens").Replace("""", "")

Write-Host ""
Write-Host "The browser will now open, please create a Personal Access Token. Ensure that Read & manage is selected for Agent Pools, Read & write is selected for Code, Read & execute is selected for Build, and Read, create, & manage is selected for Variable Groups"
Start-Process $pat_url

$PAT = Read-Host -Prompt "Please enter the PAT token: "
az pipelines variable-group variable update --group-id $GroupID --name "WZ_PAT" --value $PAT --secret true --only-show-errors --organization $ADO_ORGANIZATION --project $ADO_Project --output none
if ($authenticationMethod -eq "Service Principal") {

  $Env:AZURE_DEVOPS_EXT_AZURE_RM_SERVICE_PRINCIPAL_KEY = $ARM_CLIENT_SECRET

  az pipelines variable-group variable update --group-id $GroupID --name "ARM_CLIENT_SECRET" --value $ARM_CLIENT_SECRET --secret true  --organization $ADO_ORGANIZATION --project $ADO_Project --output none --only-show-errors
  az pipelines variable-group variable update --group-id $GroupID --name "ARM_CLIENT_ID" --value $ARM_CLIENT_ID  --organization $ADO_ORGANIZATION --project $ADO_Project --output none --only-show-errors
  az pipelines variable-group variable update --group-id $GroupID --name "ARM_OBJECT_ID" --value $ARM_OBJECT_ID  --organization $ADO_ORGANIZATION --project $ADO_Project --output none --only-show-errors


  $epExists = (az devops service-endpoint list --query "[?name=='$Service_Connection_Name'].name | [0]")
  if ($epExists.Length -eq 0) {
    Write-Host "Creating Service Endpoint" $Service_Connection_Name -ForegroundColor Green
    az devops service-endpoint azurerm create --azure-rm-service-principal-id $ARM_CLIENT_ID --azure-rm-subscription-id $Workload_zone_subscriptionID --azure-rm-subscription-name $Workload_zoneSubscriptionName --azure-rm-tenant-id $ARM_TENANT_ID --name $Service_Connection_Name  --organization $ADO_ORGANIZATION --project $ADO_Project --output none --only-show-errors
    $epId = az devops service-endpoint list --query "[?name=='$Service_Connection_Name'].id" -o tsv  --organization $ADO_ORGANIZATION --project $ADO_Project
    az devops service-endpoint update --id $epId --enable-for-all true --output none --only-show-errors  --organization $ADO_ORGANIZATION --project $ADO_Project
  }
  else {
    Write-Host "Service Endpoint already exists, recreating it with the updated credentials" -ForegroundColor Green
    $epId = az devops service-endpoint list --query "[?name=='$Service_Connection_Name'].id" -o tsv  --organization $ADO_ORGANIZATION --project $ADO_Project
    az devops service-endpoint delete --id $epId --yes  --organization $ADO_ORGANIZATION --project $ADO_Project
    az devops service-endpoint azurerm create --azure-rm-service-principal-id $ARM_CLIENT_ID --azure-rm-subscription-id $Workload_zone_subscriptionID --azure-rm-subscription-name $Workload_zoneSubscriptionName --azure-rm-tenant-id $ARM_TENANT_ID --name $Service_Connection_Name --output none --only-show-errors  --organization $ADO_ORGANIZATION --project $ADO_Project
    $epId = az devops service-endpoint list --query "[?name=='$Service_Connection_Name'].id" -o tsv  --organization $ADO_ORGANIZATION --project $ADO_Project
    az devops service-endpoint update --id $epId --enable-for-all true --output none --only-show-errors  --organization $ADO_ORGANIZATION --project $ADO_Project
  }
}
else {
  Write-Host ""
  $Service_Connection_Name = $Workload_zone_code + "_WorkloadZone_Service_Connection"
  Write-Host "The browser will now open, Please create an 'Azure Resource Manager' service connection with the name '$Service_Connection_Name'."
  $connections_url = $ADO_ORGANIZATION + "/" + [uri]::EscapeDataString($ADO_Project) + "/_settings/adminservices"
  Write-Host "URL: " $connections_url


  Start-Process $connections_url
  Read-Host -Prompt "Once you have created and validated the connection, Press any key to continue"

}
#endregion

