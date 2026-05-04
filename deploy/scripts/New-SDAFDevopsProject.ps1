# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

$versionLabel = "v3.14.5.0"

# Notes:
#   Colors:
#     White   Blue        Green       Cyan        Red       Magenta       Yellow      Gray
#     Black   DarkBlue    DarkGreen   DarkCyan    DarkRed   DarkMagenta   DarkYellow  DarkGray

# Write-Host  "<Experimental>..............." `
#             -ForegroundColor Cyan



<#-----------------------------------------------------------------------------|
 |                                                                             |
 | Functions                                                                   |
 |                                                                             |
 |-----------------------------------------------------------------------------|
 |-------------------------------------+---------------------------------------#>
#region
function Show-Menu($data) {
  Write-Host "  ================ $Title ================"
  $i = 1
  foreach ($d in $data) {
    Write-Host "  ($i): Select '$i' for $($d)"
    $i++
  }

  Write-Host "  (q): Select 'q' for Exit"

}
<#-------------------------------------+---------------------------------------#>
#endregion



<#-----------------------------------------------------------------------------|
 |                                                                             |
 | Initialization                                                              |
 |                                                                             |
 |-----------------------------------------------------------------------------|
 |-------------------------------------+---------------------------------------#>
#region
Write-Host  "Section: Initialization ..." `
            -ForegroundColor DarkCyan

$ADO_Organization             = $Env:SDAF_ADO_ORGANIZATION
$ADO_Project                  = $Env:SDAF_ADO_PROJECT
$ARM_TENANT_ID                = $Env:ARM_TENANT_ID
$Control_plane_code           = $Env:SDAF_CONTROL_PLANE_CODE
$Control_plane_subscriptionID = $Env:SDAF_ControlPlaneSubscriptionID
$ControlPlaneSubscriptionName = $Env:SDAF_ControlPlaneSubscriptionName
$wikiFileName                 = "start.md"
$import_code                  = $false
$pipeline_permission_url      = ""
$APP_REGISTRATION_ID          = ""
$WEB_APP_CLIENT_SECRET        = "Enter your App registration secret here"

#-------------------------------------------------------------------------------
if ( $null -ne $Env:CreateConnections) { $CreateConnection = [System.Convert]::ToBoolean($Env:CreateConnections) }
else                                   { $CreateConnection = $true }

if ( $null -ne $Env:SDAF_BRANCH )      { $branch = $Env:SDAF_BRANCH }
else                                   { $branch = "main" }

if ( $null -ne $Env:CreatePAT)         { $CreatePAT = [System.Convert]::ToBoolean($Env:CreatePAT) }
else                                   { $CreatePAT = $true }

if ($IsWindows)                        { $pathSeparator = "\" }
else                                   { $pathSeparator = "/" }

if ( $null -ne $Env:ImportFromGitHub)  { $ImportFromGitHub = [System.Convert]::ToBoolean($Env:ImportFromGitHub) }

if (Test-Path ".${pathSeparator}${wikiFileName}") { Write-Host "  Removing $wikiFileName" ; Remove-Item ".${pathSeparator}${wikiFileName}" }
<#-------------------------------------+---------------------------------------#>
#endregion



<#-----------------------------------------------------------------------------|
 |                                                                             |
 | PAT Authentication to Azure DevOps organization                             |
 |                                                                             |
 |-----------------------------------------------------------------------------|
 |  Check if access to the Azure DevOps organization is available,
 |    prompt for PAT if needed.
 |
 |  Exact permissions required, to be validated, and included in the Read-Host text.
 |-------------------------------------+---------------------------------------#>
#region
Write-Host  "Section: Authentication to Azure DevOps organization ..." `
            -ForegroundColor DarkCyan

$PAT = 'Enter your personal access token here'
if ($Env:AZURE_DEVOPS_EXT_PAT.Length -gt 0) {
  Write-Host  "  Using the provided Personal Access Token (PAT) to authenticate to the Azure DevOps organization $ADO_Organization" `
              -ForegroundColor Yellow
  $PAT        = $Env:AZURE_DEVOPS_EXT_PAT
  $CreatePAT  = $false
}

$checkPAT                   = (az devops user list --organization $ADO_Organization --only-show-errors --top 1)
if ($checkPAT.Length -eq 0) {
  $env:AZURE_DEVOPS_EXT_PAT = Read-Host "  Please enter your Personal Access Token (PAT) with full access to the Azure DevOps organization $ADO_Organization"
  $verifyPAT                = (az devops user list --organization $ADO_Organization --only-show-errors --top 1)
  if ($verifyPAT.Length -eq 0) {
    Write-Host        "    Failed to authenticate to the Azure DevOps organization $ADO_Organization" `
                      -ForegroundColor Red
    Read-Host -Prompt "press <any key> to exit"
    exit
  }
  else {
    Write-Host  "    Successfully authenticated to the Azure DevOps organization $ADO_Organization" `
                -ForegroundColor Green
  }
}
else {
  Write-Host  "  Successfully authenticated to the Azure DevOps organization $ADO_Organization" `
              -ForegroundColor Green
}
<#-----------------------------------------------------------------------------#>
#endregion



<#-----------------------------------------------------------------------------|
 |                                                                             |
 | AZ CLI extensions                                                           |
 |                                                                             |
 |-----------------------------------------------------------------------------|
 |-------------------------------------+---------------------------------------#>
#region
Write-Host  "Section: AZ CLI extensions ..." `
            -ForegroundColor DarkCyan

az config set extension.use_dynamic_install=yes_without_prompt --only-show-errors
Write-Host  "  Ensuring the Azure DevOps extension is installed for AZ CLI" `
            -ForegroundColor Green
az extension add --name azure-devops                           --only-show-errors
<#-------------------------------------+---------------------------------------#>
#endregion



<#-----------------------------------------------------------------------------|
 |                                                                             |
 | Select Service Principal or Managed Identity                                |
 |                                                                             |
 |-----------------------------------------------------------------------------|
 |-------------------------------------+---------------------------------------#>
#region
Write-Host  "Section: Authentication method ...`n" `
            -ForegroundColor DarkCyan

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

Write-Host  "  Using authentication method: $authenticationMethod" `
            -ForegroundColor Cyan
Write-Host  ""
<#-------------------------------------+---------------------------------------#>
#endregion



<#-----------------------------------------------------------------------------|
 |                                                                             |
 | Choose MSI                                                                  |
 |                                                                             |
 |-----------------------------------------------------------------------------|
 |-------------------------------------+---------------------------------------#>
#region
Write-Host  "Section: Choose Managed Identity ..." `
            -ForegroundColor DarkCyan

$MSI_objectId = $null
if ($authenticationMethod -eq "Managed Identity") {

  if ($Env:MSI_OBJECT_ID.Length -ne 0) {
    $MSI_objectId = $Env:MSI_OBJECT_ID
  }
  else {
# Choose subscription
#-------------------------------------------------------------------------------
    $Title = "Choose the subscription that contains the Managed Identity"
    $subscriptions = $(az account list --query "[].{Name:name}" -o table | Sort-Object)

    Show-Menu($subscriptions[2..($subscriptions.Length - 1)])
    $selection = Read-Host $Title
    $selectionOffset = [convert]::ToInt32($selection, 10) + 1
    $subscription = $subscriptions[$selectionOffset]

    Write-Host "  Using subscription:" $subscription `
                -ForegroundColor Magenta
    Write-Host  ""

# Choose Managed Identity
#-------------------------------------------------------------------------------
    $Title = "Choose the Managed Identity"
    $identities = $(az identity list --query "[].{Name:name}" --subscription $subscription --output table | Sort-Object)

    Show-Menu($identities[2..($identities.Length - 1)])
    $selection = Read-Host $Title
    $selectionOffset = [convert]::ToInt32($selection, 10) + 1
    $identity = $identities[$selectionOffset]

    $id = $(az identity list --query "[?name=='$identity'].id" --subscription $subscription --output tsv)
    $MSI_objectId = $(az identity show --ids $id --query "principalId" --output tsv)

    Write-Host "  Using Managed Identity:" $identity `
                -ForegroundColor Magenta
    Write-Host  ""
  }
}
<#-------------------------------------+---------------------------------------#>
#endregion



<#-----------------------------------------------------------------------------|
 |                                                                             |
 | Validate parameters                                                         |
 |                                                                             |
 |-----------------------------------------------------------------------------|
 |-------------------------------------+---------------------------------------#>
#region
Write-Host  "Section: Parameter Validation ..." `
            -ForegroundColor DarkCyan

# Ensure the Control plane subscription ID is set
#-------------------------------------------------------------------------------
if ($Control_plane_subscriptionID.Length -eq 0) {
  Write-Host  "  $Env:ControlPlaneSubscriptionID is not set!"
  $Title                        = "Choose the subscription for the Control Plane"
  $subscriptions                = $(az account list --query "[].{Name:name}" -o table | Sort-Object)

  Show-Menu($subscriptions[2..($subscriptions.Length - 1)])
  $selection                    = Read-Host $Title
  $selectionOffset              = [convert]::ToInt32($selection, 10) + 1
  $ControlPlaneSubscriptionName = $subscriptions[$selectionOffset]

  az account set --subscription $ControlPlaneSubscriptionName
  $Control_plane_subscriptionID = (az account show --query id -o tsv)
}
else {
  az account set --subscription $Control_plane_subscriptionID
  $ControlPlaneSubscriptionName = (az account show --query name -o tsv)
}
$my_scope                 = "/subscriptions/" + $Control_plane_subscriptionID

# Ensure the Control plane subscription name is set
#-------------------------------------------------------------------------------
if ($ControlPlaneSubscriptionName.Length -eq 0) {
  Write-Host  "  ControlPlaneSubscriptionName is not set" `
              -ForegroundColor Red
  exit
}

# Ensure the ADO organization is set
#-------------------------------------------------------------------------------
if ($ADO_Organization.Length -eq 0) {
  Write-Host  "  Organization is not set"
  $ADO_Organization = Read-Host "    Enter your ADO organization URL"
}
else {
  Write-Host  "  Using Organization: $ADO_Organization" `
              -ForegroundColor Cyan
}

# Ensure the Control plane code is set
#-------------------------------------------------------------------------------
if ($Control_plane_code.Length -eq 0) {
  Write-Host  "  Control plane code is not set (MGMT, MGMT-REG-VNET, etc...)"
  $Control_plane_code = Read-Host "    Enter your Control plane code"
}
else {
  Write-Host  "  Using Control plane code: $Control_plane_code" `
              -ForegroundColor Cyan
}

# Set the Control Plane prefix, which is used for naming the resources in Azure DevOps
#-------------------------------------------------------------------------------
$ControlPlanePrefix = "SDAF-" + $Control_plane_code

# Set the name of the agent pool to use in Azure DevOps
#-------------------------------------------------------------------------------
if ($Env:SDAF_POOL_NAME.Length -eq 0) {
  $Pool_Name = $ControlPlanePrefix + "-POOL"
}
else {
  $Pool_Name = $Env:SDAF_POOL_NAME
}

if ($Env:SDAF_AGENT_POOL_NAME.Length -ne 0) {
  $Pool_Name = $Env:SDAF_AGENT_POOL_NAME
}
else {
  $confirmation = Read-Host "  Use default Agent pool with name '$Pool_Name' y/n?"
  if ($confirmation -ne 'y') {
    $Pool_Name  = Read-Host "    Enter the name of the agent pool"
  }
}
  Write-Host  "  Using Pool: $Pool_Name" `
              -ForegroundColor Cyan

# Ensure the Web App setting is configured
#-------------------------------------------------------------------------------
$WebApp = $true
# if ($Env:SDAF_WEBAPP -eq "true") {
if ($Env:SDAF_WEBAPP) {
  $ApplicationName = $ControlPlanePrefix + "-configuration-app"

  if ($Env:SDAF_APP_NAME.Length -ne 0) {
    $ApplicationName = $Env:SDAF_APP_NAME
  }
}
else {
  $WebApp = $false
}

# Ensure the S-User details are set, if desired
#-------------------------------------------------------------------------------
$SUserName = 'Enter your S-User ID'
$SPassword = 'Enter your S-User password'

if ($Env:SUserName.Length -ne 0) { $SUserName = $Env:SUserName }
if ($Env:SPassword.Length -ne 0) { $SPassword = $Env:SPassword }

if ($Env:SUserName.Length -eq 0 -and $Env:SPassword.Length -eq 0) {
  $provideSUser = Read-Host "  Do you want to provide the S-User details y/n?"
  if ($provideSUser -eq 'y') {
    $SUserName = Read-Host "    Enter your S-User ID"
    $SPassword = Read-Host "    Enter your S-User password"
  }
}

<#-------------------------------------+---------------------------------------#>
#endregion



<#-----------------------------------------------------------------------------|
 |                                                                             |
 | Wiki Content                                                                |
 |                                                                             |
 |-----------------------------------------------------------------------------|
---------------------------------------+---------------------------------------#>
#region
Add-Content -Path $wikiFileName -Value "# Welcome to the SDAF Wiki"
Add-Content -Path $wikiFileName -Value ""
Add-Content -Path $wikiFileName -Value "## Deployment details"
Add-Content -Path $wikiFileName -Value ""
Add-Content -Path $wikiFileName -Value "Azure DevOps organization: $ADO_Organization"
<#-------------------------------------+---------------------------------------#>
#endregion



<#-----------------------------------------------------------------------------|
 |                                                                             |
 | Install DevOps extension                                                    |
 |                                                                             |
 |-----------------------------------------------------------------------------|
  Install the Azure DevOps extensions required for the pipelines. The main one is
  the Post Build Cleanup extension, which is used to clean up the Terraform state
  after the deployment, but there are also some others that are needed for
  specific tasks in the pipelines.
 |-------------------------------------+---------------------------------------#>
#region
Write-Host  "Section: Installing the DevOps extensions ..." `
            -ForegroundColor DarkCyan

$extension_name = (az devops extension list --organization $ADO_Organization --query "[?extensionName=='Post Build Cleanup'].extensionName | [0]")

if ($extension_name.Length -eq 0) {
  Write-Host  "  Installing the Post Build Cleanup extension from the marketplace" `
              -ForegroundColor Green
  az devops extension install --organization $ADO_Organization --extension PostBuildCleanup --publisher-id mspremier --output none
}
else {
  Write-Host  "  Post Build Cleanup extension is already installed" `
              -ForegroundColor Yellow
}
<#-------------------------------------+---------------------------------------#>
#endregion



<#-----------------------------------------------------------------------------|
 |                                                                             |
 | Create DevOps project                                                       |
 |                                                                             |
 |-----------------------------------------------------------------------------|
 |-------------------------------------+---------------------------------------#>
#region
Write-Host  "Section: Create DevOps Project ..." `
            -ForegroundColor DarkCyan

$Project_ID = (az devops project list --organization $ADO_ORGANIZATION --query "[value[]] | [0] | [? name=='$ADO_PROJECT'].id | [0]" --out tsv)

if ($Project_ID.Length -eq 0) {
  Write-Host  "  Creating the project: " $ADO_PROJECT `
              -ForegroundColor Green
  $Project_ID = (az devops project create --name $ADO_PROJECT                     `
                                          --description 'SDAF Automation Project' `
                                          --organization $ADO_ORGANIZATION        `
                                          --visibility private                    `
                                          --source-control git                    `
                                          --query id                              `
                                          --output tsv)

  Add-Content -Path $wikiFileName -Value ""
  Add-Content -Path $wikiFileName -Value "Using Azure DevOps Project: $ADO_PROJECT"

  az devops configure --defaults organization=$ADO_ORGANIZATION project="$ADO_PROJECT"

  $repo_id  = (az repos list --query "[?name=='$ADO_Project'].id     | [0]"  --out tsv)
  $repo_url = (az repos list --query "[?name=='$ADO_Project'].webUrl | [0]"  --out tsv)

  Write-Host  "  Importing the content from GitHub" `
              -ForegroundColor Green

  az repos import create  --git-url https://github.com/Azure/SAP-automation-bootstrap `
                          --repository $repo_id                                       `
                          --output none

  az repos update         --repository $repo_id    `
                          --default-branch $branch `
                          --output none
}
else {

  Write-Host "  Using an existing project"

  Add-Content -Path $wikiFileName -Value ""
  Add-Content -Path $wikiFileName -Value "DevOps Project: $ADO_PROJECT"

  az devops configure --defaults organization=$ADO_ORGANIZATION project="$ADO_PROJECT"

  $repo_id   = (az repos list --query "[?name=='$ADO_Project'].id     | [0]"  --output tsv)
  $repo_url  = (az repos list --query "[?name=='$ADO_Project'].webUrl | [0]"  --output tsv)
  $repo_size = (az repos list --query "[?name=='$ADO_Project'].size   | [0]"  --output tsv)

  if ($repo_id.Length -ne 0) {
    Write-Host  "  Using repository '$ADO_Project'" `
                -ForegroundColor Green
  }

  if ($repo_size -eq 0) {
    Write-Host  "  Importing the repository from GitHub" `
                -ForegroundColor Green

    az repos import create --git-url https://github.com/Azure/SAP-automation-bootstrap --repository $repo_id   --output tsv
    if ($LastExitCode -eq 1) {
      Write-Host  "  The repository already exists" `
                  -ForegroundColor Yellow
      Write-Host  "  Creating repository 'SDAF Configuration'" `
                  -ForegroundColor Green
      $repo_id = (az repos create --name "SDAF Configuration" --query id --output tsv)
      az repos import create --git-url https://github.com/Azure/SAP-automation-bootstrap --repository $repo_id  --output none
    }

    Add-Content -Path $wikiFileName -Value ""
    Add-Content -Path $wikiFileName -Value "Terraform and Ansible code repository stored in the DevOps project (sap-automation)"
  }
  else {

    $confirmation = Read-Host "  The repository already exists, use it? y/n"
    if ($confirmation -ne 'y') {
      Write-Host  "  Creating repository 'SDAF Configuration'" `
                  -ForegroundColor Green
      $repo_id = (az repos create --name "SDAF Configuration" --query id  --output tsv)
      az repos import create --git-url https://github.com/Azure/SAP-automation-bootstrap `
                             --repository $repo_id  `
                             --output none
    }
  }

  az repos update --repository $repo_id --default-branch $branch   --output none
}
<#-------------------------------------+---------------------------------------#>
#endregion



<#-----------------------------------------------------------------------------|
 |                                                                             |
 | Repositories                                                                |
 |                                                                             |
 |-----------------------------------------------------------------------------|
 |-------------------------------------+---------------------------------------#>
#region
Write-Host  "Section: Repositories ..." `
            -ForegroundColor DarkCyan

if ( Test-Path "temprepo") {
  Write-Host  "  Removing temprepo" `
              -ForegroundColor Green
  Remove-Item -Path (Join-Path -Path Get-Location -ChildPath "temprepo") -Recurse -Force
}

$tempPath = New-Item -Path (Join-Path -Path Get-Location -ChildPath "temprepo") -ItemType Directory -Force | Out-Null
git clone $repo_url $tempPath

if ( $null -ne $Env:ImportFromGitHub) {
  if ([System.Convert]::ToBoolean($Env:ImportFromGitHub)) {
    $confirmation = "y"
  }
  else {
    $confirmation = "n"
  }
}
else {
  Write-Host "  You can optionally import the Terraform and Ansible code from GitHub into Azure DevOps,"
  Write-Host "   however, this should only be done if you cannot access github from the Azure DevOps agent"
  Write-Host "   or if you intend to customize the code.`n"
  $confirmation = Read-Host "  Do you want to run the code from GitHub y/n?"
}


if ($confirmation -ne 'y') {
  Add-Content -Path $wikiFileName -Value ""
  Add-Content -Path $wikiFileName -Value "Using the code from the sap-automation repository"

  $import_code = $true
  $repo_name = "sap-automation"
  Write-Host  "  Creating $repo_name repository" `
              -ForegroundColor Green
  az repos create --name $repo_name --query id  --output none
  $code_repo_id = (az repos list --query "[?name=='$repo_name'].id | [0]"  --out tsv)
  az repos import create --git-url https://github.com/Azure/SAP-automation --repository $code_repo_id  --output none
  az repos update --repository $code_repo_id --default-branch $branch   --output none

  $import_code = $true
  $repo_name = "sap-samples"
  Write-Host  "  Creating $repo_name repository" `
              -ForegroundColor Green
  az repos create --name $repo_name --query id  --output none
  $sample_repo_id = (az repos list --query "[?name=='$repo_name'].id | [0]"  --out tsv)
  az repos import create --git-url https://github.com/Azure/SAP-automation-samples --repository $sample_repo_id  --output none
  az repos update --repository $sample_repo_id --default-branch $branch   --output none

  if ($ADO_Project -ne "SAP Deployment Automation Framework") {

    Write-Host  "  Using a non standard DevOps project name, need to update some of the parameter files" `
                -ForegroundColor Green

    $objectId = (az devops invoke --area git --resource refs --route-parameters project=$ADO_Project repositoryId=$repo_id --query-parameters filter=heads/main --query value[0] | ConvertFrom-Json).objectId


    $templatename = "resources.yml"
    if (Test-Path $templatename) { Remove-Item $templatename }

    Add-Content -Path $templatename -Value @(
                                              "",
                                              "parameters:",
                                              "  - name:    stages",
                                              "    type:    stageList",
                                              "    default: []",
                                              "",
                                              "stages:",
                                              "  - `${{ parameters.stages }}",
                                              "",
                                              "resources:",
                                              "  repositories:",
                                              "    - repository: sap-automation",
                                              "      type:       git",
                                              "      name:       $ADO_Project/sap-automation",
                                              "      ref:        refs/heads/main"
                                            )
#                                             "      ref:        refs/tags/$versionLabel"

    $cont = Get-Content -Path $templatename -Raw

    $inputfile = "sdaf.json"

    $postBody = [PSCustomObject]@{
      refUpdates = @(@{
          name        = "refs/heads/main"
          oldObjectId = $objectId
        })
      commits    = @(@{
          comment = "Updated repository.yml"
          changes = @(@{
              changetype = "edit"
              item       = @{path = "/pipelines/resources.yml" }
              newContent = @{content = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes($cont))
                contentType          = "base64Encoded"
              }

            })
        })
    }

    Set-Content -Path $inputfile -Value ($postBody | ConvertTo-Json -Depth 6)

    az devops invoke `
      --area git --resource pushes `
      --route-parameters project=$ADO_Project repositoryId=$repo_id `
      --http-method POST --in-file $inputfile `
      --api-version "6.0" --output none

    if (Test-Path $templatename) { Remove-Item $templatename }


    $templatename = "resources_including_samples.yml"
    if (Test-Path $templatename) { Remove-Item $templatename }

    Add-Content -Path $templatename -Value @(
                                              "",
                                              "parameters:",
                                              "  - name:    stages",
                                              "    type:    stageList",
                                              "    default: []",
                                              "",
                                              "stages:",
                                              "  - `${{ parameters.stages }}",
                                              "",
                                              "resources:",
                                              "  repositories:",
                                              "    - repository: sap-automation",
                                              "      type:       git",
                                              "      name:       $ADO_Project/sap-automation",
                                              "      ref:        refs/heads/main",
                                              "",
                                              "    - repository: sap-samples",
                                              "      type:       git",
                                              "      name:       $ADO_Project/sap-automation-samples",
                                              "      ref:        refs/heads/main"
                                            )
#                                             "      ref:        refs/tags/$versionLabel"

    $objectId = (az devops invoke --area git --resource refs --route-parameters project=$ADO_Project repositoryId=$repo_id --query-parameters filter=heads/main --query value[0] | ConvertFrom-Json).objectId

    Remove-Item "sdaf.json"
    $cont = Get-Content -Path $templatename -Raw

    $postBody = [PSCustomObject]@{
      refUpdates = @(@{
          name        = "refs/heads/main"
          oldObjectId = $objectId
        })
      commits    = @(@{
          comment = "Updated resources_including_samples.yml"
          changes = @(@{
              changetype = "edit"
              item       = @{path = "/pipelines/resources_including_samples.yml" }
              newContent = @{content = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes($cont))
                contentType          = "base64Encoded"
              }

            })
        })
    }

    Set-Content -Path $inputfile -Value ($postBody | ConvertTo-Json -Depth 6)

    az devops invoke `
      --area git --resource pushes `
      --route-parameters project=$ADO_Project repositoryId=$repo_id `
      --http-method POST --in-file $inputfile `
      --api-version "6.0" --output none

    Remove-Item $templatename
  }

  $code_repo_id = (az repos list --query "[?name=='sap-automation'].id | [0]"  --out tsv)

  $queryString = "?api-version=6.0-preview"
  $pipeline_permission_url = "$ADO_ORGANIZATION/$projectID/_apis/pipelines/pipelinePermissions/repository/$projectID.$code_repo_id$queryString"
}
else {
  Add-Content -Path $wikiFileName -Value ""
  Add-Content -Path $wikiFileName -Value "Using the code directly from GitHub"

  $resources_url = $ADO_ORGANIZATION + "/_git/" + [uri]::EscapeDataString($ADO_Project) + "?path=/pipelines/resources.yml"

  $log = ("Please update [resources.yml](" + $resources_url + ") to point to GitHub instead of Azure DevOps.")

}
<#-------------------------------------+---------------------------------------#>
#endregion



<#-----------------------------------------------------------------------------|
 |                                                                             |
 | Creating the variable group SDAF-General                                    |
 |                                                                             |
 |-----------------------------------------------------------------------------|
 |-------------------------------------+---------------------------------------#>
#region
Write-Host  "Section: Create Variable Group SDAF-General ..." `
            -ForegroundColor DarkCyan

$repo_id   = (az repos list --query "[?name=='$ADO_Project'].id   | [0]"  --out tsv)
$repo_name = (az repos list --query "[?name=='$ADO_Project'].name | [0]"  --out tsv)


Write-Host  "Creating the variable group SDAF-General" `
            -ForegroundColor Green

$groups = New-Object System.Collections.Generic.List[System.Object]

$general_group_id = (az pipelines variable-group list --query "[?name=='SDAF-General'].id | [0]" --only-show-errors)
if ($general_group_id.Length -eq 0) {
  az pipelines variable-group create  --name SDAF-General                                  `
                                      --variables ANSIBLE_HOST_KEY_CHECKING=false          `
                                                  Deployment_Configuration_Path=WORKSPACES `
                                                  Branch=main                              `
                                                  tf_version="1.15.1"                      `
                                                  ansible_core_version="2.16.18"           `
                                                  S-Username=$SUserName                    `
                                                  S-Password=$SPassword                    `
                                      --authorize true                                     `
                                      --output none
  $general_group_id = (az pipelines variable-group list --query "[?name=='SDAF-General'].id | [0]" --only-show-errors)
  az pipelines variable-group variable update --group-id $general_group_id --name "S-Password" --value $SPassword --secret true --output none --only-show-errors
}

$groups.Add($general_group_id)
<#-------------------------------------+---------------------------------------#>
#endregion



<#-----------------------------------------------------------------------------|
 |                                                                             |
 | Create pipelines                                                            |
 |                                                                             |
 |-----------------------------------------------------------------------------|
 |-------------------------------------+---------------------------------------#>
#region
Write-Host  "Section: Pipelines ..." `
            -ForegroundColor DarkCyan

Write-Host  "Creating the pipelines in repo: $repo_name ($repo_id)" `
            -ForegroundColor Green

Add-Content -Path $wikiFileName -Value @(
                                          "",
                                          "### Pipelines",
                                          ""
                                        )

$pipelines = New-Object System.Collections.Generic.List[System.Object]

# Pipeline: Create Control Plane configuration
#-------------------------------------------------------------------------------
$pipeline_name = 'Create Control Plane configuration'
Write-Host  "`n  Pipeline: $pipeline_name" `
            -ForegroundColor Green
$sample_pipeline_id = (az pipelines list --query "[?name=='$pipeline_name'].id | [0]")
if ($sample_pipeline_id.Length -eq 0) {
  Write-Host  "    Creating pipeline: $pipeline_name" `
              -ForegroundColor Green
  az pipelines create --name $pipeline_name                                         `
                      --branch main                                                 `
                      --description 'Create sample configuration'                   `
                      --skip-run                                                    `
                      --yaml-path "/pipelines/22-sample-deployer-configuration.yml" `
                      --repository $repo_id                                         `
                      --repository-type tfsgit                                      `
                      --output none                                                 `
                      --only-show-errors
  $sample_pipeline_id = (az pipelines list --query "[?name=='$pipeline_name'].id | [0]")
} else {
  Write-Host  "    Pipeline already exists, skipping creation" `
              -ForegroundColor Yellow
}

$this_pipeline_url = $ADO_ORGANIZATION + "/" + [uri]::EscapeDataString($ADO_Project) + "/_build?definitionId=" + $sample_pipeline_id
$log = ("[" + $pipeline_name + "](" + $this_pipeline_url + ")")
Add-Content -Path $wikiFileName -Value $log

# Pipeline: Deploy Control plane
#-------------------------------------------------------------------------------
$pipeline_name = 'Deploy Control plane'
Write-Host  "`n  Pipeline: $pipeline_name" `
            -ForegroundColor Green
$control_plane_pipeline_id = (az pipelines list --query "[?name=='$pipeline_name'].id | [0]")
if ($control_plane_pipeline_id.Length -eq 0) {
  Write-Host  "    Creating pipeline: $pipeline_name" `
              -ForegroundColor Green
  az pipelines create --name $pipeline_name                                         `
                      --branch main                                                 `
                      --description 'Deploys the control plane'                     `
                      --skip-run                                                    `
                      --yaml-path "/pipelines/01-deploy-control-plane.yml"          `
                      --repository $repo_id                                         `
                      --repository-type tfsgit                                      `
                      --output none                                                 `
                      --only-show-errors
  $control_plane_pipeline_id = (az pipelines list --query "[?name=='$pipeline_name'].id | [0]")
} else {
  Write-Host  "    Pipeline already exists, skipping creation" `
              -ForegroundColor Yellow
}

$pipelines.Add($control_plane_pipeline_id)

$this_pipeline_url = $ADO_ORGANIZATION + "/" + [uri]::EscapeDataString($ADO_Project) + "/_build?definitionId=" + $control_plane_pipeline_id
$log = ("[" + $pipeline_name + "](" + $this_pipeline_url + ")")
Add-Content -Path $wikiFileName -Value $log

# Pipeline: SAP Workload Zone deployment
#-------------------------------------------------------------------------------
$pipeline_name = 'SAP Workload Zone deployment'
Write-Host  "`n  Pipeline: $pipeline_name" `
            -ForegroundColor Green
$wz_pipeline_id = (az pipelines list --query "[?name=='$pipeline_name'].id | [0]")
if ($wz_pipeline_id.Length -eq 0) {
  Write-Host  "    Creating pipeline: $pipeline_name" `
              -ForegroundColor Green
  az pipelines create --name $pipeline_name                                         `
                      --branch main                                                 `
                      --description 'Deploys the workload zone'                     `
                      --skip-run                                                    `
                      --yaml-path "/pipelines/02-sap-workload-zone.yml"             `
                      --repository $repo_id                                         `
                      --repository-type tfsgit                                      `
                      --output none                                                 `
                      --only-show-errors
  $wz_pipeline_id = (az pipelines list --query "[?name=='$pipeline_name'].id | [0]")
} else {
  Write-Host  "    Pipeline already exists, skipping creation" `
              -ForegroundColor Yellow
}

$pipelines.Add($wz_pipeline_id)

$this_pipeline_url = $ADO_ORGANIZATION + "/" + [uri]::EscapeDataString($ADO_Project) + "/_build?definitionId=" + $wz_pipeline_id
$log = ("[" + $pipeline_name + "](" + $this_pipeline_url + ")")
Add-Content -Path $wikiFileName -Value $log

# Pipeline: SAP SID Infrastructure deployment
#-------------------------------------------------------------------------------
$pipeline_name = 'SAP SID Infrastructure deployment'
Write-Host  "`n  Pipeline: $pipeline_name" `
            -ForegroundColor Green
$system_pipeline_id = (az pipelines list --query "[?name=='$pipeline_name'].id | [0]")
if ($system_pipeline_id.Length -eq 0) {
  Write-Host  "    Creating pipeline: $pipeline_name" `
              -ForegroundColor Green
  az pipelines create --name $pipeline_name                                                         `
                      --branch main                                                                 `
                      --description 'Deploys the infrastructure required for a SAP SID deployment'  `
                      --skip-run                                                                    `
                      --yaml-path "/pipelines/03-sap-system-deployment.yml"                         `
                      --repository $repo_id                                                         `
                      --repository-type tfsgit                                                      `
                      --output none                                                                 `
                      --only-show-errors
  $system_pipeline_id = (az pipelines list --query "[?name=='$pipeline_name'].id | [0]")
} else {
  Write-Host  "    Pipeline already exists, skipping creation" `
              -ForegroundColor Yellow
}

$pipelines.Add($system_pipeline_id)

$this_pipeline_url = $ADO_ORGANIZATION + "/" + [uri]::EscapeDataString($ADO_Project) + "/_build?definitionId=" + $system_pipeline_id
$log = ("[" + $pipeline_name + "](" + $this_pipeline_url + ")")
Add-Content -Path $wikiFileName -Value $log

# Pipeline: SAP Software acquisition
#-------------------------------------------------------------------------------
$pipeline_name = 'SAP Software acquisition'
Write-Host  "`n  Pipeline: $pipeline_name" `
            -ForegroundColor Green
$pipeline_id   = (az pipelines list --query "[?name=='$pipeline_name'].id | [0]")
if ($pipeline_id.Length -eq 0) {
  Write-Host  "    Creating pipeline: $pipeline_name" `
              -ForegroundColor Green
  az pipelines create --name $pipeline_name                                         `
                      --branch main                                                 `
                      --description 'Downloads the software from SAP'               `
                      --skip-run                                                    `
                      --yaml-path "/pipelines/04-sap-software-download.yml"         `
                      --repository $repo_id                                         `
                      --repository-type tfsgit                                      `
                      --output none                                                 `
                      --only-show-errors
  $pipeline_id = (az pipelines list --query "[?name=='$pipeline_name'].id | [0]")
} else {
  Write-Host  "    Pipeline already exists, skipping creation" `
              -ForegroundColor Yellow
}

$pipelines.Add($pipeline_id)

$this_pipeline_url = $ADO_ORGANIZATION + "/" + [uri]::EscapeDataString($ADO_Project) + "/_build?definitionId=" + $pipeline_id
$log = ("[" + $pipeline_name + "](" + $this_pipeline_url + ")")
Add-Content -Path $wikiFileName -Value $log

# Pipeline: SAP Software acquisition new
#-------------------------------------------------------------------------------
$pipeline_name = 'SAP Software acquisition new'
Write-Host  "`n  Pipeline: $pipeline_name" `
            -ForegroundColor Green
$pipeline_id   = (az pipelines list --query "[?name=='$pipeline_name'].id | [0]")
if ($pipeline_id.Length -eq 0) {
  Write-Host  "    Creating pipeline: $pipeline_name" `
              -ForegroundColor Green
  az pipelines create --name $pipeline_name                                         `
                      --branch main                                                 `
                      --description 'Downloads the software from SAP'               `
                      --skip-run                                                    `
                      --yaml-path "/pipelines/04-sap-software-download_v2.yml"      `
                      --repository $repo_id                                         `
                      --repository-type tfsgit                                      `
                      --output none                                                 `
                      --only-show-errors
  $pipeline_id = (az pipelines list --query "[?name=='$pipeline_name'].id | [0]")
} else {
  Write-Host  "    Pipeline already exists, skipping creation" `
              -ForegroundColor Yellow
}

$pipelines.Add($pipeline_id)
$this_pipeline_url = $ADO_ORGANIZATION + "/" + [uri]::EscapeDataString($ADO_Project) + "/_build?definitionId=" + $pipeline_id
$log = ("[" + $pipeline_name + "](" + $this_pipeline_url + ")")
Add-Content -Path $wikiFileName -Value $log

# Pipeline: Configuration and SAP installation
#-------------------------------------------------------------------------------
$pipeline_name = 'Configuration and SAP installation'
Write-Host  "`n  Pipeline: $pipeline_name" `
            -ForegroundColor Green
$installation_pipeline_id = (az pipelines list --query "[?name=='$pipeline_name'].id | [0]")
if ($installation_pipeline_id.Length -eq 0) {
  Write-Host  "    Creating pipeline: $pipeline_name" `
              -ForegroundColor Green
  az pipelines create --name $pipeline_name                                                             `
                      --branch main                                                                     `
                      --description 'Configures the Operating System and installs the SAP application'  `
                      --skip-run                                                                        `
                      --yaml-path "/pipelines/05-DB-and-SAP-installation.yml"                           `
                      --repository $repo_id                                                             `
                      --repository-type tfsgit                                                          `
                      --output none                                                                     `
                      --only-show-errors
  $installation_pipeline_id = (az pipelines list --query "[?name=='$pipeline_name'].id | [0]")
} else {
  Write-Host  "    Pipeline already exists, skipping creation" `
              -ForegroundColor Yellow
}

$pipelines.Add($installation_pipeline_id)

$this_pipeline_url = $ADO_ORGANIZATION + "/" + [uri]::EscapeDataString($ADO_Project) + "/_build?definitionId=" + $installation_pipeline_id
$log = ("[" + $pipeline_name + "](" + $this_pipeline_url + ")")
Add-Content -Path $wikiFileName -Value $log

# Pipeline: Remove System or Workload Zone
#-------------------------------------------------------------------------------
$pipeline_name = 'Remove System or Workload Zone'
Write-Host  "`n  Pipeline: $pipeline_name" `
            -ForegroundColor Green
$pipeline_id   = (az pipelines list --query "[?name=='$pipeline_name'].id | [0]")
if ($pipeline_id.Length -eq 0) {
  Write-Host  "    Creating pipeline: $pipeline_name" `
              -ForegroundColor Green
  az pipelines create --name $pipeline_name                                               `
                      --branch main                                                       `
                      --description 'Removes either the SAP system or the workload zone'  `
                      --skip-run                                                          `
                      --yaml-path "/pipelines/10-remover-terraform.yml"                   `
                      --repository $repo_id                                               `
                      --repository-type tfsgit                                            `
                      --output none                                                       `
                      --only-show-errors
  $pipeline_id = (az pipelines list --query "[?name=='$pipeline_name'].id | [0]")
} else {
  Write-Host  "    Pipeline already exists, skipping creation" `
              -ForegroundColor Yellow
}

$pipelines.Add($pipeline_id)

$this_pipeline_url = $ADO_ORGANIZATION + "/" + [uri]::EscapeDataString($ADO_Project) + "/_build?definitionId=" + $pipeline_id
$log = ("[" + $pipeline_name + "](" + $this_pipeline_url + ")")
Add-Content -Path $wikiFileName -Value $log

# Pipeline: Remove deployments via ARM
#-------------------------------------------------------------------------------
$pipeline_name = 'Remove deployments via ARM'
Write-Host  "`n  Pipeline: $pipeline_name" `
            -ForegroundColor Green
$pipeline_id   = (az pipelines list --query "[?name=='$pipeline_name'].id | [0]")
if ($pipeline_id.Length -eq 0) {
  Write-Host  "    Creating pipeline: $pipeline_name" `
              -ForegroundColor Green
  az pipelines create --name $pipeline_name                                                             `
                      --branch main                                                                     `
                      --description 'Removes the resource groups via ARM. Use this only as last resort' `
                      --skip-run                                                                        `
                      --yaml-path "/pipelines/11-remover-arm-fallback.yml"                              `
                      --repository $repo_id                                                             `
                      --repository-type tfsgit                                                          `
                      --output none                                                                     `
                      --only-show-errors
  $pipeline_id = (az pipelines list --query "[?name=='$pipeline_name'].id | [0]")
} else {
  Write-Host  "    Pipeline already exists, skipping creation" `
              -ForegroundColor Yellow
}

$pipelines.Add($pipeline_id)

$this_pipeline_url = $ADO_ORGANIZATION + "/" + [uri]::EscapeDataString($ADO_Project) + "/_build?definitionId=" + $pipeline_id
$log = ("[" + $pipeline_name + "](" + $this_pipeline_url + ")")
Add-Content -Path $wikiFileName -Value $log

# Pipeline: Remove control plane
#-------------------------------------------------------------------------------
$pipeline_name = 'Remove control plane'
Write-Host  "`n  Pipeline: $pipeline_name" `
            -ForegroundColor Green
$pipeline_id   = (az pipelines list --query "[?name=='$pipeline_name'].id | [0]")
if ($pipeline_id.Length -eq 0) {
  Write-Host  "    Creating pipeline: $pipeline_name" `
                -ForegroundColor Green
  az pipelines create --name $pipeline_name                                         `
                      --branch main                                                 `
                      --description 'Removes the control plane'                     `
                      --skip-run                                                    `
                      --yaml-path "/pipelines/12-remove-control-plane.yml"          `
                      --repository $repo_id                                         `
                      --repository-type tfsgit                                      `
                      --output none                                                 `
                      --only-show-errors
  $pipeline_id = (az pipelines list --query "[?name=='$pipeline_name'].id | [0]")
} else {
  Write-Host  "    Pipeline already exists, skipping creation" `
              -ForegroundColor Yellow
}

$pipelines.Add($pipeline_id)

$this_pipeline_url = $ADO_ORGANIZATION + "/" + [uri]::EscapeDataString($ADO_Project) + "/_build?definitionId=" + $pipeline_id
$log = ("[" + $pipeline_name + "](" + $this_pipeline_url + ")")
Add-Content -Path $wikiFileName -Value $log

# Pipeline: Update repository
#-------------------------------------------------------------------------------
if ($import_code) {
  $pipeline_name = 'Update repository'
  Write-Host  "`n  Pipeline: $pipeline_name" `
              -ForegroundColor Green
  $pipeline_id   = (az pipelines list --query "[?name=='$pipeline_name'].id | [0]")
  if ($pipeline_id.Length -eq 0) {
    Write-Host  "    Creating pipeline: $pipeline_name" `
                -ForegroundColor Green
    az pipelines create --name $pipeline_name                                       `
                        --branch main                                               `
                        --description 'Updates the codebase'                        `
                        --skip-run                                                  `
                        --yaml-path "/pipelines/20-update-repositories.yml"         `
                        --repository $repo_id                                       `
                        --repository-type tfsgit                                    `
                        --output none                                               `
                        --only-show-errors
    $pipeline_id = (az pipelines list --query "[?name=='$pipeline_name'].id | [0]")
  } else {
    Write-Host  "    Pipeline already exists, skipping creation" `
                -ForegroundColor Yellow
  }

  $pipelines.Add($pipeline_id)

  $this_pipeline_url = $ADO_ORGANIZATION + "/" + [uri]::EscapeDataString($ADO_Project) + "/_build?definitionId=" + $pipeline_id
  $log = ("[" + $pipeline_name + "](" + $this_pipeline_url + ")")
  Add-Content -Path $wikiFileName -Value $log
}

# Pipeline: Update Pipelines
#-------------------------------------------------------------------------------
$pipeline_name = 'Update Pipelines'
Write-Host  "`n  Pipeline: $pipeline_name" `
            -ForegroundColor Green
$pipeline_id = (az pipelines list --query "[?name=='$pipeline_name'].id | [0]")
if ($pipeline_id.Length -eq 0) {
  Write-Host  "    Creating pipeline: $pipeline_name" `
              -ForegroundColor Green
  az pipelines create --name $pipeline_name                                         `
                      --branch main                                                 `
                      --description 'Updates the pipelines'                         `
                      --skip-run                                                    `
                      --yaml-path "/pipelines/21-update-pipelines.yml"              `
                      --repository $repo_id                                         `
                      --repository-type tfsgit                                      `
                      --output none                                                 `
                      --only-show-errors
  $pipeline_id = (az pipelines list --query "[?name=='$pipeline_name'].id | [0]")
} else {
  Write-Host  "    Pipeline already exists, skipping creation" `
              -ForegroundColor Yellow
}

$pipelines.Add($pipeline_id)

$this_pipeline_url = $ADO_ORGANIZATION + "/" + [uri]::EscapeDataString($ADO_Project) + "/_build?definitionId=" + $pipeline_id
$log = ("[" + $pipeline_name + "](" + $this_pipeline_url + ")")
Add-Content -Path $wikiFileName -Value $log
Write-Host  ""
<#-------------------------------------+---------------------------------------#>
#endregion



<#-----------------------------------------------------------------------------|
 |                                                                             |
 | Github Connection                                                           |
 |                                                                             |
 |-----------------------------------------------------------------------------|
 |-------------------------------------+---------------------------------------#>
#region
Write-Host  "Section: GitHub Connection ..." `
            -ForegroundColor DarkCyan

if ($true -eq $CreateConnection ) {
  $gh_connection_url = $ADO_ORGANIZATION + "/" + [uri]::EscapeDataString($ADO_Project) + "/_settings/adminservices"
  Write-Host "  The browser will now open, please create a new GitHub connection, record the name of the connection."
  Write-Host "  URL: " $gh_connection_url
  Start-Process $gh_connection_url
  Read-Host "  Please press enter when you have created the connection"
}
else {
  Write-Host  "  Please create a 'GitHub' service connection before running any pipeline." `
              -ForegroundColor Yellow
}
Write-Host  ""
<#-------------------------------------+---------------------------------------#>
#endregion



<#-----------------------------------------------------------------------------|
 |                                                                             |
 | Create resources files                                                      |
 |                                                                             |
 |-----------------------------------------------------------------------------|
 |-------------------------------------+---------------------------------------#>
#region
Write-Host  "Section: Create resources files ..." `
            -ForegroundColor DarkCyan

if ($true -eq $CreateConnection ) {
  $ghConn       = (az devops service-endpoint list --query "[?type=='github'].name | [0]"  --out tsv)
  $objectId     = (az devops invoke --area git                               `
                                    --resource refs                          `
                                    --route-parameters project=$ADO_Project  `
                                                       repositoryId=$repo_id `
                                    --query-parameters filter=heads/main     `
                                    --query value[0]                         `
                                    | ConvertFrom-Json).objectId

  $templatename = "resources.yml"
  if (Test-Path $templatename) { Remove-Item $templatename }

  Add-Content -Path $templatename -Value @(
                                            "",
                                            "parameters:",
                                            "  - name:    stages",
                                            "    type:    stageList",
                                            "    default: []",
                                            "",
                                            "stages:",
                                            "  - `${{ parameters.stages }}",
                                            "",
                                            "resources:",
                                            "  repositories:",
                                            "",
                                            "    - repository: sap-automation",
                                            "      type:       GitHub",
                                            "      endpoint:   $ghConn",
                                            "      name:       Azure/sap-automation",
                                            "      ref:        refs/heads/main"
                                          )
#                                           "      ref:        refs/tags/$versionLabel"
  $content    = Get-Content -Path $templatename -Raw

  $inputfile  = "sdaf.json"
  $postBody   = [PSCustomObject]@{
                                    refUpdates = @(@{
                                        name                  = "refs/heads/main"
                                        oldObjectId           = $objectId
                                      })
                                    commits    = @(@{
                                        comment               = "Updated repository.yml"
                                        changes   = @(@{
                                            changetype        = "edit"
                                            item        = @{
                                                path          = "/pipelines/resources.yml"
                                              }
                                            newContent  = @{
                                                content       = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes($content))
                                                contentType   = "base64Encoded"
                                              }
                                          })
                                      })
                                  }
  Set-Content -Path $inputfile -Value ($postBody | ConvertTo-Json -Depth 6)

  az devops invoke --area git                                                    `
                   --resource pushes                                             `
                   --route-parameters project=$ADO_Project repositoryId=$repo_id `
                   --http-method POST                                            `
                   --in-file $inputfile                                          `
                   --api-version "6.0"                                           `
                   --output none

  if (Test-Path $templatename) { Remove-Item $templatename }
  if (Test-Path $inputfile   ) { Remove-Item $inputfile    }
  $templatename = "resources_including_samples.yml"

  Add-Content -Path $templatename -Value @(
                                            "",
                                            "parameters:",
                                            "  - name:    stages",
                                            "    type:    stageList",
                                            "    default: []",
                                            "",
                                            "stages:",
                                            "  - `${{ parameters.stages }}",
                                            "",
                                            "resources:",
                                            "  repositories:",
                                            "",
                                            "    - repository: sap-automation",
                                            "      type:       GitHub",
                                            "      endpoint:   $ghConn",
                                            "      name:       Azure/sap-automation",
                                            "      ref:        refs/heads/main",
                                            "",
                                            "    - repository: sap-samples",
                                            "      type:       GitHub",
                                            "      endpoint:   $ghConn",
                                            "      name:       Azure/sap-automation-samples",
                                            "      ref:        refs/heads/main"
                                          )


  $objectId = (az devops invoke --area git                               `
                                --resource refs                          `
                                --route-parameters project=$ADO_Project  `
                                                   repositoryId=$repo_id `
                                --query-parameters filter=heads/main     `
                                --query value[0]                         `
                                | ConvertFrom-Json).objectId

  $content = Get-Content -Path $templatename -Raw

  # file: sdaf.json
  $postBody   = [PSCustomObject]@{
                                    refUpdates = @(@{
                                        name                  = "refs/heads/main"
                                        oldObjectId           = $objectId
                                      })
                                    commits    = @(@{
                                        comment               = "Updated resources_including_samples.yml"
                                        changes   = @(@{
                                            changetype        = "edit"
                                            item        = @{
                                                path          = "/pipelines/resources_including_samples.yml"
                                              }
                                            newContent  = @{
                                                content       = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes($content))
                                                contentType   = "base64Encoded"
                                              }
                                          })
                                      })
                                  }
  Set-Content -Path $inputfile -Value ($postBody | ConvertTo-Json -Depth 6)

  az devops invoke  --area git                               `
                    --resource pushes                        `
                    --route-parameters project=$ADO_Project  `
                                       repositoryId=$repo_id `
                    --http-method POST                       `
                    --in-file $inputfile                     `
                    --api-version "6.0"                      `
                    --output none

  if (Test-Path $templatename) { Remove-Item $templatename }
  if (Test-Path $inputfile   ) { Remove-Item $inputfile    }
}
<#-------------------------------------+---------------------------------------#>
#endregion



<#-----------------------------------------------------------------------------|
 |                                                                             |
 | Create ARM Service Connection                                                  |
 |                                                                             |
 |-----------------------------------------------------------------------------|
 |-------------------------------------+---------------------------------------#>
#region
Write-Host  "Section: Create ARM Service Connection ..." `
            -ForegroundColor DarkCyan

if ($true -eq $CreateConnection ) {

  $Service_Connection_Name = "Control_Plane_Service_Connection"
  $epExists                = (az devops service-endpoint list --query "[?name=='$Service_Connection_Name'].name | [0]" )

  if ($epExists.Length -eq 0) {

    $connections_url = $ADO_ORGANIZATION + "/" + [uri]::EscapeDataString($ADO_Project) + "/_settings/adminservices"
    Write-Host "  The browser will now open, Please create an 'Azure Resource Manager' service connection with the name 'Control_Plane_Service_Connection'."
    Write-Host "  URL: " $connections_url
    Start-Process $connections_url
    Read-Host -Prompt "  Once you have created and validated the connection, Press any key to continue"
    $epId = az devops service-endpoint list --query "[?name=='$Service_Connection_Name'].id" -o tsv
    if ($epId.Length -ne 0) {
      az devops service-endpoint update --id $epId --enable-for-all true --output none --only-show-errors
    }
  }
}
else {
  Write-Host  "  Please create an 'Azure Resource Manager' service connection to the control plane subscription with the name 'Control_Plane_Service_Connection' before running any pipeline." `
              -ForegroundColor Yellow
}
<#-------------------------------------+---------------------------------------#>
#endregion



<#-----------------------------------------------------------------------------|
 |                                                                             |
 | Wiki Content (cont.)                                                        |
 |                                                                             |
 |-----------------------------------------------------------------------------|
---------------------------------------+---------------------------------------#>
#region
Add-Content -Path $wikiFileName -Value ""
Add-Content -Path $wikiFileName -Value "### Variable Groups"
Add-Content -Path $wikiFileName -Value ""
Add-Content -Path $wikiFileName -Value "SDAF-General"
Add-Content -Path $wikiFileName -Value $ControlPlanePrefix
Add-Content -Path $wikiFileName -Value $WorkloadZonePrefix

Add-Content -Path $wikiFileName -Value "### Credentials"
Add-Content -Path $wikiFileName -Value ""
Add-Content -Path $wikiFileName -Value ("Web Application: " + $ApplicationName)
<#-------------------------------------+---------------------------------------#>
#endregion



<#-----------------------------------------------------------------------------|
 |                                                                             |
 | App Registration                                                            |
 |                                                                             |
 |-----------------------------------------------------------------------------|
 |-------------------------------------+---------------------------------------#>
#region
Write-Host  "App registration section..." `
            -ForegroundColor DarkCyan

if ($WebApp) {
  Write-Host  "Creating the App registration in Azure Active Directory" `
              -ForegroundColor Green

  $found_appRegistration = (az ad app list --all --filter "startswith(displayName, '$ApplicationName')" --query  "[?displayName=='$ApplicationName'].displayName | [0]" --only-show-errors)

  if ($found_appRegistration.Length -ne 0) {
    Write-Host  "Found an existing App Registration:" $ApplicationName `
                -ForegroundColor Green
    $ExistingData = (az ad app list --all --filter "startswith(displayName, '$ApplicationName')" --query  "[?displayName=='$ApplicationName']| [0]" --only-show-errors) | ConvertFrom-Json

    $APP_REGISTRATION_ID = $ExistingData.appId
    $APP_REGISTRATION_OBJECTID = $ExistingData.id

    # $confirmation = Read-Host "Reset the app registration secret y/n?"
    # if ($confirmation -eq 'y') {
    #   $WEB_APP_CLIENT_SECRET = (az ad app credential reset --id $APP_REGISTRATION_ID --append --query "password" --out tsv --only-show-errors --display-name "SDAF")
    # }
    # else {
    #   $WEB_APP_CLIENT_SECRET = Read-Host "Please enter the app registration secret"
    # }
  }
  else {
    Write-Host  "Creating an App Registration for" $ApplicationName `
                -ForegroundColor Green
    if ($IsWindows) { $manifestPath = ".\manifest.json" } else { $manifestPath = "./manifest.json" }
    Add-Content -Path manifest.json -Value '[{"resourceAppId":"00000003-0000-0000-c000-000000000000","resourceAccess":[{"id":"e1fe6dd8-ba31-4d61-89e7-88639da4683d","type":"Scope"}]}]'

    $APP_REGISTRATION_ID = (az ad app create --display-name $ApplicationName --enable-id-token-issuance true --sign-in-audience AzureADMyOrg --required-resource-access $manifestPath --query "appId" --output tsv)
    $ExistingData = (az ad app list --all --filter "startswith(displayName, '$ApplicationName')" --query  "[?displayName=='$ApplicationName']| [0]" --only-show-errors) | ConvertFrom-Json
    $APP_REGISTRATION_OBJECTID = $ExistingData.id

    az role assignment create --assignee $APP_REGISTRATION_OBJECTID --role "Reader"                         --subscription $Control_plane_subscriptionID --scope $my_scope --output none
    az role assignment create --assignee $APP_REGISTRATION_OBJECTID --role "Storage Blob Data Contributor"  --subscription $Control_plane_subscriptionID --scope $my_scope --output none
    az role assignment create --assignee $APP_REGISTRATION_OBJECTID --role "Storage Table Data Contributor" --subscription $Control_plane_subscriptionID --scope $my_scope --output none

    if (Test-Path $manifestPath) { Write-Host "Removing manifest.json" ; Remove-Item $manifestPath }

    # $WEB_APP_CLIENT_SECRET = (az ad app credential reset --id $APP_REGISTRATION_ID --append --query "password" --out tsv --only-show-errors --display-name "SDAF")
  }

  if ($MSI_objectId -ne $null) {
    $configureAuth = Read-Host "Configuring authentication for the App Registration (y/n)?"
    if ($configureAuth -eq 'y') {
      az rest --method POST --uri "https://graph.microsoft.com/beta/applications/$APP_REGISTRATION_OBJECTID/federatedIdentityCredentials\" --body "{'name': 'ManagedIdentityFederation', 'issuer': 'https://login.microsoftonline.com/$ARM_TENANT_ID/v2.0', 'subject': '$MSI_objectId', 'audiences': [ 'api://AzureADTokenExchange' ]}"

      $API_URL = "https://portal.azure.com/#view/Microsoft_AAD_RegisteredApps/ApplicationMenuBlade/~/ProtectAnAPI/appId/$APP_REGISTRATION_ID/isMSAApp~/false"

      Write-Host "The browser will now open, Please Add a new scope, by clicking the '+ Add a scope' link, accept the default name and click 'Save and Continue'"
      Write-Host "In the Add a scope page enter the scope name 'user_impersonation'. Choose 'Admins and Users' in the who can consent section, next provide the Admin consent display name 'Access the SDAF web application' and 'Use SDAF' as the Admin consent description, accept the changes by clicking the 'Add scope' button"

      Start-Process $API_URL
      Read-Host -Prompt "Once you have created and validated the scope, Press any key to continue"
    }
  }
}
<#-------------------------------------+---------------------------------------#>
#endregion



<#-----------------------------------------------------------------------------|
 |                                                                             |
 | When authenticationMethod is SPN                                            |
 |                                                                             |
 |-----------------------------------------------------------------------------|
 |-------------------------------------+---------------------------------------#>
#region
Write-Host  "Section: SPN ..." `
            -ForegroundColor DarkCyan

if ($authenticationMethod -eq "Service Principal") {
  $spn_name = $ControlPlanePrefix + " Deployment Credential"
  if ($Env:SDAF_MGMT_SPN_NAME.Length -ne 0) {
    $spn_name = $Env:SDAF_MGMT_SPN_NAME
  }

  Add-Content -Path $wikiFileName -Value ("Control Plane Service Principal: " + $spn_name)

  Write-Host  "  Creating the deployment credentials for the control plane. Service Principal Name:" $spn_name `
              -ForegroundColor Green

  $ARM_CLIENT_ID      = ""
  $ARM_OBJECT_ID      = ""
  $ARM_TENANT_ID      = ""
  $ARM_CLIENT_SECRET  = "Please update"
  $found_appName      = (az ad sp list --all                                                   `
                                       --filter "startswith(displayName, '$spn_name')"         `
                                       --query "[?displayName=='$spn_name'].displayName | [0]" `
                                       --only-show-errors)

  if ($found_appName.Length -gt 0) {
    Write-Host  "    Found an existing Service Principal:" $spn_name `
                -ForegroundColor Yellow
    $ExistingData      = (az ad sp list --all                                           `
                                        --filter "startswith(displayName, '$spn_name')" `
                                        --query  "[?displayName=='$spn_name'] | [0]"    `
                                        --only-show-errors)                             `
                                        | ConvertFrom-Json
    $ARM_CLIENT_ID     = $ExistingData.appId
    $ARM_OBJECT_ID     = $ExistingData.Id
    $ARM_TENANT_ID     = $ExistingData.appOwnerOrganizationId
    $ARM_CLIENT_SECRET = Read-Host "    Please enter the Control Plane Service Principal $spn_name password"

    #$confirmation = Read-Host "Reset the Control Plane Service Principal password y/n?"
    # if ($confirmation -eq 'y') {
    #   $ARM_CLIENT_SECRET = (az ad sp credential reset --id $ARM_CLIENT_ID --append --query "password" --out tsv --only-show-errors).Replace("""", "")
    # }
    # else {
    #   $ARM_CLIENT_SECRET = Read-Host "Please enter the Control Plane Service Principal $spn_name password"
    # }
  }
  else {
    Write-Host  "    Creating the Service Principal" $spn_name `
                -ForegroundColor Green

    # $SPN_Created = $true                                                      # Not used anywhere
    $Control_plane_SPN_data = (az ad sp create-for-rbac --role "Contributor" `
                                                        --scopes $my_scope   `
                                                        --name $spn_name     `
                                                        --only-show-errors)  `
                                                        | ConvertFrom-Json
    $ExistingData           = (az ad sp list --all --filter "startswith(displayName, '$spn_name')" --query  "[?displayName=='$spn_name'] | [0]" --only-show-errors) | ConvertFrom-Json
    $ARM_CLIENT_ID          = $ExistingData.appId
    $ARM_TENANT_ID          = $ExistingData.appOwnerOrganizationId
    $ARM_OBJECT_ID          = $ExistingData.Id
    $ARM_CLIENT_SECRET      = $Control_plane_SPN_data.password
  }

  Write-Host  "  Adding role assignments to the Service Principal: $spn_name" `
              -ForegroundColor DarkCyan
  # az role assignment create --assignee $ARM_CLIENT_ID --role "Contributor"                    --subscription $Control_plane_subscriptionID --scope $my_scope --output none
  # az role assignment create --assignee $ARM_CLIENT_ID --role "User Access Administrator"      --subscription $Control_plane_subscriptionID --scope $my_scope --output none
  # az role assignment create --assignee $ARM_CLIENT_ID --role "Storage Blob Data Contributor"  --subscription $Control_plane_subscriptionID --scope $my_scope --output none
  # az role assignment create --assignee $ARM_CLIENT_ID --role "Storage Table Data Contributor" --subscription $Control_plane_subscriptionID --scope $my_scope --output none
  # az role assignment create --assignee $ARM_CLIENT_ID --role "App Configuration Data Owner"   --subscription $Control_plane_subscriptionID --scope $my_scope --output none
  # az role assignment create --assignee $ARM_CLIENT_ID --role "Private DNS Zone Contributor"   --subscription $Control_plane_subscriptionID --scope $my_scope --output none
  $roles = @("Contributor",                    `
             "Storage Blob Data Contributor",  `
             "Storage Table Data Contributor", `
             "App Configuration Data Owner",   `
             "Private DNS Zone Contributor",   `
             "Network Contributor")
  foreach ($role in $roles) {
    Write-Host  "    Adding role assignment for $role ..." `
                -ForegroundColor DarkCyan
    az role assignment create --assignee     $ARM_CLIENT_ID                `
                              --role         $role                         `
                              --subscription $Control_plane_subscriptionID `
                              --scope        $my_scope                     `
                              --output       none
  }

  $RoleName = "User Access Administrator"
  $Condition = "( ( !(ActionMatches{'Microsoft.Authorization/roleAssignments/write'}) ) OR  (  @Request[Microsoft.Authorization/roleAssignments:RoleDefinitionId] ForAnyOfAllValues:GuidNotEquals {8e3af657-a8ff-443c-a75c-2fe8c4bcb635, 18d7d88d-d35e-4fb5-a5c3-7773c20a72d9} )) AND ( (  !(ActionMatches{'Microsoft.Authorization/roleAssignments/delete'}) ) OR  (  @Resource[Microsoft.Authorization/roleAssignments:RoleDefinitionId] ForAnyOfAllValues:GuidNotEquals {8e3af657-a8ff-443c-a75c-2fe8c4bcb635, 18d7d88d-d35e-4fb5-a5c3-7773c20a72d9} ))"

  $roleAssignment = az role assignment create --assignee-object-id $identity.principalId --assignee-principal-type ServicePrincipal --role $RoleName --scope /subscriptions/$SubscriptionId --query id --condition-version "2.0" --condition $Condition --output tsv --only-show-errors
  if ($roleAssignment) {
    Write-Host "Successfully assigned $RoleName role with condition to identity" -ForegroundColor Green
    Write-Verbose "Role assignment ID: $roleAssignment"
  }
  else {
    Write-Warning "Identity created but conditional role assignment may have failed"
  }

}
<#-------------------------------------+---------------------------------------#>
#endregion



<#-----------------------------------------------------------------------------|
 |                                                                             |
 | Create SPN Service Endpoint                                                 |
 |                                                                             |
 |-----------------------------------------------------------------------------|
 |-------------------------------------+---------------------------------------#>
#region
Write-Host  "Section: Service Endpoint ..." `
            -ForegroundColor DarkCyan

if ($authenticationMethod -eq "Service Principal") {

  Write-Host  "  Create the Service Endpoint in Azure for the control plane" `
              -ForegroundColor Green

  $Service_Connection_Name                             = "Control_Plane_Service_Connection"
  $Env:AZURE_DEVOPS_EXT_AZURE_RM_SERVICE_PRINCIPAL_KEY = $ARM_CLIENT_SECRET

  $epExists = (az devops service-endpoint list --query "[?name=='$Service_Connection_Name'].name | [0]")
  if ($epExists.Length -eq 0) {
    Write-Host  "    Creating Service Endpoint" $Service_Connection_Name `
                -ForegroundColor Green

    az devops service-endpoint azurerm create --azure-rm-service-principal-id $ARM_CLIENT_ID             `
                                              --azure-rm-subscription-id $Control_plane_subscriptionID   `
                                              --azure-rm-subscription-name $ControlPlaneSubscriptionName `
                                              --azure-rm-tenant-id $ARM_TENANT_ID                        `
                                              --name $Service_Connection_Name                            `
                                              --output none                                              `
                                              --only-show-errors
    $epId = (az devops service-endpoint list --query "[?name=='$Service_Connection_Name'].id" --output tsv)
    az devops service-endpoint update --id $epId            `
                                      --enable-for-all true `
                                      --output none         `
                                      --only-show-errors
  }
  else {
    Write-Host  "    Service Endpoint already exists, recreating it with the updated credentials" `
                -ForegroundColor Green

    $epId = (az devops service-endpoint list --query "[?name=='$Service_Connection_Name'].id" --output tsv)
    az devops service-endpoint delete --id $epId --yes
    az devops service-endpoint azurerm create --azure-rm-service-principal-id $ARM_CLIENT_ID             `
                                              --azure-rm-subscription-id $Control_plane_subscriptionID   `
                                              --azure-rm-subscription-name $ControlPlaneSubscriptionName `
                                              --azure-rm-tenant-id $ARM_TENANT_ID                        `
                                              --name $Service_Connection_Name                            `
                                              --output none                                              `
                                              --only-show-errors
    $epId = (az devops service-endpoint list --query "[?name=='$Service_Connection_Name'].id" --output tsv)
    az devops service-endpoint update --id $epId            `
                                      --enable-for-all true `
                                      --output none         `
                                      --only-show-errors
  }
}
<#-------------------------------------+---------------------------------------#>
#endregion




<#-----------------------------------------------------------------------------|
 |                                                                             |
 | Create Variable Group                                                       |
 |                                                                             |
 |-----------------------------------------------------------------------------|
 |-------------------------------------+---------------------------------------#>
#region
Write-Host  "Section: Variable Group $ControlPlanePrefix ..." `
            -ForegroundColor DarkCyan

$Control_plane_groupID = (az pipelines variable-group list --query "[?name=='$ControlPlanePrefix'].id | [0]" --only-show-errors)
if ($Control_plane_groupID.Length -eq 0) {
  Write-Host  "  Creating the variable group" $ControlPlanePrefix `
              -ForegroundColor Green

  az pipelines variable-group create  --name $ControlPlanePrefix `
                                      --variables                             PAT=$PAT                               `
                                                                             POOL=$Pool_Name                         `
                                                                            AGENT='Azure Pipelines'                  `
                                                                           TF_LOG=OFF                                `
                                                               SYSTEM_PIPELINE_ID=$system_pipeline_id                `
                                                             CONTROL_PLANE_NAME=$Control_plane_code                  `
                                                            ARM_SUBSCRIPTION_ID=$Control_plane_subscriptionID        `
                                                            SDAF_GENERAL_GROUP_ID=$general_group_id                  `
                                                          AZURE_CONNECTION_NAME='Control_Plane_Service_Connection'   `
                                                          SAP_INSTALL_PIPELINE_ID=$installation_pipeline_id          `
                                                         WORKLOADZONE_PIPELINE_ID=$wz_pipeline_id                    `
                                      --output none                                                                  `
                                      --authorize true
  $Control_plane_groupID = (az pipelines variable-group list --query "[?name=='$ControlPlanePrefix'].id | [0]" --only-show-errors)

  if ($WebApp) {
    az pipelines variable-group variable create --group-id $Control_plane_groupID --name 'APP_REGISTRATION_APP_ID'   --value $APP_REGISTRATION_ID        --output none --only-show-errors
    az pipelines variable-group variable create --group-id $Control_plane_groupID --name 'APP_REGISTRATION_OBJECTID' --value $APP_REGISTRATION_OBJECTID  --output none --only-show-errors
    az pipelines variable-group variable create --group-id $Control_plane_groupID --name 'APP_TENANT_ID'             --value $APP_TENANT_ID              --output none --only-show-errors
  }

  if ($authenticationMethod -eq "Managed Identity") {
    az pipelines variable-group variable create --group-id $Control_plane_groupID --name 'USE_MSI'                   --value true                        --output none --only-show-errors
  }

  if ($authenticationMethod -eq "Service Principal") {
    az pipelines variable-group variable create --group-id $Control_plane_groupID --name 'USE_MSI'                   --value false                       --output none --only-show-errors
    az pipelines variable-group variable create --group-id $Control_plane_groupID --name 'ARM_CLIENT_ID'             --value $ARM_CLIENT_ID              --output none --only-show-errors
    az pipelines variable-group variable create --group-id $Control_plane_groupID --name 'ARM_CLIENT_SECRET'         --value 'Please update'             --output none --only-show-errors
    az pipelines variable-group variable create --group-id $Control_plane_groupID --name 'ARM_TENANT_ID'             --value $ARM_TENANT_ID              --output none --only-show-errors
    az pipelines variable-group variable create --group-id $Control_plane_groupID --name 'ARM_OBJECT_ID'             --value $ARM_OBJECT_ID              --output none --only-show-errors
    if ($ARM_CLIENT_SECRET -ne "Please update") {
      az pipelines variable-group variable update --group-id $Control_plane_groupID `
                                                  --name     'ARM_CLIENT_SECRET'    `
                                                  --value    $ARM_CLIENT_SECRET     `
                                                  --secret   true                   `
                                                  --output   none                   `
                                                  --only-show-errors
    }
  }
}
else {
  if (   $authenticationMethod -eq "Service Principal" `
       -and $ARM_CLIENT_SECRET -ne "Please update") {
    az pipelines variable-group variable update --group-id $Control_plane_groupID --name 'ARM_CLIENT_SECRET'         --value $ARM_CLIENT_SECRET          --output none --only-show-errors --secret true
    az pipelines variable-group variable update --group-id $Control_plane_groupID --name 'ARM_CLIENT_ID'             --value $ARM_CLIENT_ID              --output none --only-show-errors
    az pipelines variable-group variable update --group-id $Control_plane_groupID --name 'ARM_OBJECT_ID'             --value $ARM_OBJECT_ID              --output none --only-show-errors
  }
}
$groups.Add($Control_plane_groupID)
<#-------------------------------------+---------------------------------------#>
#endregion



<#-----------------------------------------------------------------------------|
 |                                                                             |
 | Create Variable Group      OLD CODE                                         |
 |                                                                             |
 |-----------------------------------------------------------------------------|
 |-------------------------------------+---------------------------------------#>
#region
# Write-Host  "Section: Variable Group ..." `
#             -ForegroundColor DarkCyan

# if ($authenticationMethod -eq "Service Principal") {
#   Write-Host  "  Updating the variable group"

#   $Control_plane_groupID = (az pipelines variable-group list --query "[?name=='$ControlPlanePrefix'].id | [0]" --only-show-errors)
#   if ($Control_plane_groupID.Length -eq 0) {
#     Write-Host  "Creating the variable group" $ControlPlanePrefix `
#                 -ForegroundColor Green

#     if ($WebApp) {
#       if ($authenticationMethod -eq "Managed Identity") {
#         az pipelines variable-group create  --name $ControlPlanePrefix `
#                                             --variables                     AGENT='Azure Pipelines'  `
#                                                           APP_REGISTRATION_APP_ID=$APP_REGISTRATION_ID `
#                                                         APP_REGISTRATION_OBJECTID=$APP_REGISTRATION_OBJECTID `
#                                                                     APP_TENANT_ID=$ARM_TENANT_ID `
#                                                                     ARM_CLIENT_ID=$ARM_CLIENT_ID `
#                                                                     ARM_OBJECT_ID=$ARM_OBJECT_ID `
#                                                                     ARM_TENANT_ID=$ARM_TENANT_ID `
#                                                                 ARM_CLIENT_SECRET='Enter your SPN password here' `
#                                                                           USE_MSI=true `
#                                                               ARM_SUBSCRIPTION_ID=$Control_plane_subscriptionID `
#                                                             AZURE_CONNECTION_NAME='Control_Plane_Service_Connection' `
#                                                               CONTROL_PLANE_NAME=$Control_plane_code `
#                                                                               PAT=$PAT `
#                                                                             POOL=$Pool_Name `
#                                                           SAP_INSTALL_PIPELINE_ID=$installation_pipeline_id `
#                                                             SDAF_GENERAL_GROUP_ID=$general_group_id `
#                                                               SYSTEM_PIPELINE_ID=$system_pipeline_id `
#                                                                           TF_LOG=OFF `
#                                                         WORKLOADZONE_PIPELINE_ID=$wz_pipeline_id `
#                                             --output none `
#                                             --authorize true
#       }
#       else {
#         az pipelines variable-group create  --name $ControlPlanePrefix `
#                                             --variables                     AGENT='Azure Pipelines'  `
#                                                           APP_REGISTRATION_APP_ID=$APP_REGISTRATION_ID `
#                                                         APP_REGISTRATION_OBJECTID=$APP_REGISTRATION_OBJECTID `
#                                                                     APP_TENANT_ID=$ARM_TENANT_ID `
#                                                                     ARM_CLIENT_ID=$ARM_CLIENT_ID `
#                                                                     ARM_OBJECT_ID=$ARM_OBJECT_ID `
#                                                                     ARM_TENANT_ID=$ARM_TENANT_ID `
#                                                                 ARM_CLIENT_SECRET='Enter your SPN password here' `
#                                                                           USE_MSI=false `
#                                                               ARM_SUBSCRIPTION_ID=$Control_plane_subscriptionID `
#                                                             AZURE_CONNECTION_NAME='Control_Plane_Service_Connection' `
#                                                                               PAT=$PAT `
#                                                                              POOL=$Pool_Name `
#                                                           SAP_INSTALL_PIPELINE_ID=$installation_pipeline_id `
#                                                             SDAF_GENERAL_GROUP_ID=$general_group_id `
#                                                                SYSTEM_PIPELINE_ID=$system_pipeline_id `
#                                                                            TF_LOG=OFF `
#                                                          WORKLOADZONE_PIPELINE_ID=$wz_pipeline_id `
#                                                                CONTROL_PLANE_NAME=$Control_plane_code `
#                                             --output none `
#                                             --authorize true
#       }
#     }
#     else {
#       if ($authenticationMethod -eq "Managed Identity") {
#         az pipelines variable-group create  --name $ControlPlanePrefix `
#                                             --variables                     AGENT='Azure Pipelines' `
#                                                                               PAT=$PAT `
#                                                                     ARM_CLIENT_ID=$ARM_CLIENT_ID `
#                                                                     ARM_OBJECT_ID=$ARM_OBJECT_ID `
#                                                                 ARM_CLIENT_SECRET='Enter your SPN password here' `
#                                                                     ARM_TENANT_ID=$ARM_TENANT_ID `
#                                                                           USE_MSI=true `
#                                                                ARM_SUBSCRIPTION_ID=$Control_plane_subscriptionID `
#                                                                              POOL=$Pool_Name `
#                                                             AZURE_CONNECTION_NAME='Control_Plane_Service_Connection' `
#                                                          WORKLOADZONE_PIPELINE_ID=$wz_pipeline_id `
#                                                                SYSTEM_PIPELINE_ID=$system_pipeline_id `
#                                                             SDAF_GENERAL_GROUP_ID=$general_group_id `
#                                                           SAP_INSTALL_PIPELINE_ID=$installation_pipeline_id `
#                                                                            TF_LOG=OFF `
#                                                                CONTROL_PLANE_NAME=$Control_plane_code `
#                                             --output none `
#                                             --authorize true
#       }
#       else {
#         az pipelines variable-group create  --name $ControlPlanePrefix `
#                                             --variables                     AGENT='Azure Pipelines' `
#                                                                               PAT=$PAT `
#                                                                     ARM_CLIENT_ID=$ARM_CLIENT_ID `
#                                                                     ARM_OBJECT_ID=$ARM_OBJECT_ID `
#                                                                 ARM_CLIENT_SECRET='Enter your SPN password here' `
#                                                                     ARM_TENANT_ID=$ARM_TENANT_ID `
#                                                                           USE_MSI=false `
#                                                              ARM_SUBSCRIPTION_ID=$Control_plane_subscriptionID `
#                                                                              POOL=$Pool_Name `
#                                                             AZURE_CONNECTION_NAME='Control_Plane_Service_Connection' `
#                                                          WORKLOADZONE_PIPELINE_ID=$wz_pipeline_id `
#                                                                SYSTEM_PIPELINE_ID=$system_pipeline_id `
#                                                             SDAF_GENERAL_GROUP_ID=$general_group_id `
#                                                           SAP_INSTALL_PIPELINE_ID=$installation_pipeline_id `
#                                                                            TF_LOG=OFF `
#                                                                CONTROL_PLANE_NAME=$Control_plane_code `
#                                             --output none `
#                                             --authorize true
#       }
#     }
#     $Control_plane_groupID = (az pipelines variable-group list --query "[?name=='$ControlPlanePrefix'].id | [0]" --only-show-errors)
#   }

#   if ($ARM_CLIENT_SECRET -ne "Please update") {
#     az pipelines variable-group variable update --group-id $Control_plane_groupID --name "ARM_CLIENT_SECRET" --value $ARM_CLIENT_SECRET --secret true --output none --only-show-errors
#     az pipelines variable-group variable update --group-id $Control_plane_groupID --name "ARM_CLIENT_ID" --value $ARM_CLIENT_ID --output none --only-show-errors
#     az pipelines variable-group variable update --group-id $Control_plane_groupID --name "ARM_OBJECT_ID" --value $ARM_OBJECT_ID --output none --only-show-errors
#   }

# }
# else {
#   $Control_plane_groupID = (az pipelines variable-group list --query "[?name=='$ControlPlanePrefix'].id | [0]" --only-show-errors)
#   if ($Control_plane_groupID.Length -eq 0) {
#     Write-Host  "Creating the variable group" $ControlPlanePrefix `
#                 -ForegroundColor Green
#     if ($WebApp) {
#       az pipelines variable-group create  --name $ControlPlanePrefix                                               `
#                                           --variables                     AGENT='Azure Pipelines'                  `
#                                                         APP_REGISTRATION_APP_ID=$APP_REGISTRATION_ID               `
#                                                       APP_REGISTRATION_OBJECTID=$APP_REGISTRATION_OBJECTID         `
#                                                                   APP_TENANT_ID=$ARM_TENANT_ID                     `
#                                                             ARM_SUBSCRIPTION_ID=$Control_plane_subscriptionID      `
#                                                           AZURE_CONNECTION_NAME='Control_Plane_Service_Connection' `
#                                                              CONTROL_PLANE_NAME=$Control_plane_code                `
#                                                                             PAT=$PAT                               `
#                                                                            POOL=$Pool_Name                         `
#                                                         SAP_INSTALL_PIPELINE_ID=$installation_pipeline_id          `
#                                                           SDAF_GENERAL_GROUP_ID=$general_group_id                  `
#                                                              SYSTEM_PIPELINE_ID=$system_pipeline_id                `
#                                                                          TF_LOG=OFF                                `
#                                                                         USE_MSI=true                               `
#                                                        WORKLOADZONE_PIPELINE_ID=$wz_pipeline_id                    `
#                                           --output none                                                            `
#                                           --authorize true
#     }
#     else {
#       az pipelines variable-group create  --name $ControlPlanePrefix                                              `
#                                           --variables                    AGENT='Azure Pipelines'                  `
#                                                            ARM_SUBSCRIPTION_ID=$Control_plane_subscriptionID      `
#                                                          AZURE_CONNECTION_NAME='Control_Plane_Service_Connection' `
#                                                             CONTROL_PLANE_NAME=$Control_plane_code                `
#                                                                            PAT=$PAT                               `
#                                                                           POOL=$Pool_Name                         `
#                                                        SAP_INSTALL_PIPELINE_ID=$installation_pipeline_id          `
#                                                          SDAF_GENERAL_GROUP_ID=$general_group_id                  `
#                                                             SYSTEM_PIPELINE_ID=$system_pipeline_id                `
#                                                                         TF_LOG=OFF                                `
#                                                                        USE_MSI=true                               `
#                                                       WORKLOADZONE_PIPELINE_ID=$wz_pipeline_id                    `
#                                          --output none                                                            `
#                                          --authorize true
#     }
#     $Control_plane_groupID = (az pipelines variable-group list --query "[?name=='$ControlPlanePrefix'].id | [0]" --only-show-errors)
#   }
# }

# $groups.Add($Control_plane_groupID)
<#-------------------------------------+---------------------------------------#>
#endregion



<#-----------------------------------------------------------------------------|
 |                                                                             |
 | Create Agent Pool                                                           |
 |                                                                             |
 |-----------------------------------------------------------------------------|
 |-------------------------------------+---------------------------------------#>
#region
Write-Host  "Section: Agent Pool ..." `
            -ForegroundColor DarkCyan

$POOL_ID = 0
$POOL_NAME_FOUND = (az pipelines pool list --query "[?name=='$Pool_Name'].name | [0]")
if ($POOL_NAME_FOUND.Length -gt 0) {
  Write-Host  "Agent pool" $Pool_Name "already exists" `
              -ForegroundColor Yellow
  $POOL_ID = (az pipelines pool list --query "[?name=='$Pool_Name'].id | [0]" --output tsv)
  $queue_id = (az pipelines queue list --query "[?name=='$Pool_Name'].id | [0]" --output tsv)
}
else {

  Write-Host  "Creating agent pool" $Pool_Name `
              -ForegroundColor Green

  Set-Content -Path pool.json -Value (ConvertTo-Json @{name = $Pool_Name; autoProvision = $true })
  az devops invoke --area distributedtask --resource pools --http-method POST --api-version "7.1-preview" --in-file ".${pathSeparator}pool.json" --query-parameters authorizePipelines=true --query id --output none --only-show-errors --route-parameters project=$ADO_Project
  $POOL_ID = (az pipelines pool list --query "[?name=='$Pool_Name'].id | [0]" --output tsv)
  Write-Host "Agent pool" $Pool_Name "created"
  $queue_id = (az pipelines queue list --query "[?name=='$Pool_Name'].id | [0]" --output tsv)

}
if (Test-Path ".${pathSeparator}pool.json") { Write-Host "Removing pool.json" ; Remove-Item ".${pathSeparator}pool.json" }
<#-------------------------------------+---------------------------------------#>
#endregion



<#-----------------------------------------------------------------------------|
 |                                                                             |
 | Create Personal Access Token (PAT)                                          |
 |                                                                             |
 |-----------------------------------------------------------------------------|
 |-------------------------------------+---------------------------------------#>
#region
Write-Host  "Section: Personal Access Token (PAT) ..." `
            -ForegroundColor DarkCyan

if ($CreatePAT) {
  # Get pat_url directly from the $ADO_Organization, avoiding double slashes.
  $pat_url = ($ADO_Organization.TrimEnd('/') + "/_usersSettings/tokens").Replace("""", "")
  Write-Host ""
  Write-Host "The browser will now open, please create a Personal Access Token."
  Write-Host "Ensure that:"
  Write-Host "   Agent Pools     is set to Read & manage"
  Write-Host "   Build           is set to Read & execute"
  Write-Host "   Code            is set to Read & write"
  Write-Host "   Variable Groups is set to Read, create, & manage"
  Write-Host "URL: " $pat_url
  Start-Process $pat_url
  $PAT = Read-Host -Prompt "Please enter the PAT "
}

if ($PAT.Length -gt 0) {
  # Create header with PAT
  az pipelines variable-group variable update --group-id $Control_plane_groupID --name "PAT" --value $PAT --secret true --output none --only-show-errors
  $base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes((":{0}" -f $PAT)))

  $bodyText = [PSCustomObject]@{
    allPipelines = @{
      authorized = $false
    }
    resource     = @{
      id   = 000
      type = "variablegroup"
    }
    pipelines    = @([ordered]@{
        id         = 000
        authorized = $true
      })
  }

  foreach ($group in $groups) {
    $bodyText.resource.id = $group
    $pipeline_permission_url = $ADO_ORGANIZATION + "/" + $Project_ID + "/_apis/pipelines/pipelinePermissions/variablegroup/" + $group.ToString() + "?api-version=5.1-preview.1"
    Write-Host  "Setting permissions for variable group:" $group.ToString() `
                -ForegroundColor Yellow

    foreach ($pipeline in $pipelines) {
      $bodyText.pipelines[0].id = $pipeline
      $body = $bodyText | ConvertTo-Json -Depth 10
      Write-Host  "  Allowing pipeline id:" $pipeline.ToString() `
                  -ForegroundColor Yellow
      $response = Invoke-RestMethod -Method PATCH -Uri $pipeline_permission_url -Headers @{Authorization = "Basic $base64AuthInfo" } -Body $body -ContentType "application/json"
    }
  }
}
<#-------------------------------------+---------------------------------------#>
#endregion



<#-----------------------------------------------------------------------------|
 |                                                                             |
 | Set Entitlements                                                            |
 |                                                                             |
 |-----------------------------------------------------------------------------|
 |-------------------------------------+---------------------------------------#>
#region
Write-Host  "Section: Set Entitlements ..." `
            -ForegroundColor DarkCyan

$postBody = [PSCustomObject]@{
  accessLevel         = @{
    accountLicenseType = "stakeholder"
  }
  user                = @{
    origin      = "aad"
    originId    = $MSI_objectId
    subjectKind = "servicePrincipal"
  }
  projectEntitlements = @([ordered]@{
      group      = @{
        groupType = "projectContributor"
      }
      projectRef = @{
        id = $Project_ID
      }

    })
  servicePrincipal    = @{
    origin      = "aad"
    originId    = $MSI_objectId
    subjectKind = "servicePrincipal"
  }
}

Set-Content -Path "user.json" -Value ($postBody | ConvertTo-Json -Depth 6)

$response = az devops invoke  --area        MemberEntitlementManagement  `
                              --resource    ServicePrincipalEntitlements `
                              --in-file     user.json                    `
                              --api-version "7.1-preview"                `
                              --http-method POST

if (Test-Path ".${pathSeparator}user.json") { Write-Host "Removing user.json" ; Remove-Item ".${pathSeparator}user.json" }
<#-------------------------------------+---------------------------------------#>
#endregion



<#-----------------------------------------------------------------------------|
 |                                                                             |
 | Set permissions for Agent Pool                                              |
 |                                                                             |
 |-----------------------------------------------------------------------------|
 |-------------------------------------+---------------------------------------#>
#region
Write-Host  "Section: Set permissions for Agent Pool ..." `
            -ForegroundColor DarkCyan

# Read-Host -Prompt "Press any key to continue"
if ($PAT.Length -gt 0) {
  $base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes((":{0}" -f $PAT)))

  $bodyText = [PSCustomObject]@{
    allPipelines = @{
      authorized = $false
    }
    pipelines    = @([ordered]@{
        id         = 000
        authorized = $true
      })
  }

  $pipeline_permission_url = $ADO_ORGANIZATION + "/" + $Project_ID + "/_apis/pipelines/pipelinePermissions/queue/" + $queue_id.ToString() + "?api-version=5.1-preview.1"
  Write-Host  "Setting permissions for agent pool:" $Pool_Name "(" $queue_id ")" `
              -ForegroundColor Yellow
  foreach ($pipeline in $pipelines) {
    $bodyText.pipelines[0].id = $pipeline
    $body = $bodyText | ConvertTo-Json -Depth 10
    Write-Host  "  Allowing pipeline id:" $pipeline.ToString() " access to " $Pool_Name `
                -ForegroundColor Yellow
    $response = Invoke-RestMethod -Method PATCH -Uri $pipeline_permission_url -Headers @{Authorization = "Basic $base64AuthInfo" } -Body $body -ContentType "application/json"
  }
}
<#-------------------------------------+---------------------------------------#>
#endregion



<#-----------------------------------------------------------------------------|
 |                                                                             |
 | Set repository permissions for Build Service                                |
 |                                                                             |
 |-----------------------------------------------------------------------------|
 |-------------------------------------+---------------------------------------#>
#region
Write-Host  "Section: Set permissions for Build Service ..." `
            -ForegroundColor DarkCyan

if ($true -eq $CreateConnection) {
  Write-Host ""
  Write-Host "The browser will now open, Select the '"$ADO_PROJECT "Build Service' user and ensure that it has 'Allow' in the Contribute section."

  $permissions_url = $ADO_ORGANIZATION + "/" + [uri]::EscapeDataString($ADO_Project) + "/_settings/repositories?_a=permissions"
  Write-Host "URL: " $permissions_url

  Start-Process $permissions_url
  Read-Host -Prompt "Once you have verified the permission, Press any key to continue"
}
else {
  Write-Host "Please ensure that the '"$ADO_PROJECT "Build Service' user has 'Allow' in the Contribute section in the repository before running any pipelines"
}
<#-------------------------------------+---------------------------------------#>
#endregion



<#-----------------------------------------------------------------------------|
 |                                                                             |
 | Write Wiki                                                                  |
 |                                                                             |
 |-----------------------------------------------------------------------------|
 |-------------------------------------+---------------------------------------#>
#region
Write-Host  "Section: Write Wiki ..." `
            -ForegroundColor DarkCyan

$pipeline_url               = $ADO_ORGANIZATION + "/" + [uri]::EscapeDataString($ADO_Project) + "/_build?definitionId=" + $sample_pipeline_id
$control_plane_pipeline_url = $ADO_ORGANIZATION + "/" + [uri]::EscapeDataString($ADO_Project) + "/_build?definitionId=" + $control_plane_pipeline_id

Add-Content -Path $wikiFileName -Value "## Next steps"
Add-Content -Path $wikiFileName -Value ""
Add-Content -Path $wikiFileName -Value ( "Use the [Create Control Plane Configuration Sample](" + $pipeline_url + ") to create the control plane configuration in the region you select." )
Add-Content -Path $wikiFileName -Value ""
Add-Content -Path $wikiFileName -Value ( "Once it is complete use the [Deploy Control Plane Pipeline ](" + $control_plane_pipeline_url + ") to create the control plane configuration in the region you select.")
Add-Content -Path $wikiFileName -Value ""

$WIKI_NAME_FOUND = (az devops wiki list --query "[?name=='SDAF'].name | [0]")
if ($WIKI_NAME_FOUND.Length -gt 0) {
  Write-Host "Wiki SDAF already exists"
  $eTag = (az devops wiki page show --path 'Next steps' --wiki SDAF --query eTag )
  if ($eTag -ne $null) {
    $page_id = (az devops wiki page update --path 'Next steps' --wiki SDAF --file-path ".${pathSeparator}$wikiFileName" --only-show-errors --version $eTag --query page.id)
  }
}
else {
  az devops wiki create --name SDAF --output none --only-show-errors
  az devops wiki page create --path 'Next steps' --wiki SDAF --file-path ".${pathSeparator}$wikiFileName" --output none --only-show-errors
}

$page_id = (az devops wiki page show --path 'Next steps' --wiki SDAF --query page.id )

$wiki_url = $ADO_ORGANIZATION + "/" + [uri]::EscapeDataString($ADO_Project) + "/_wiki/wikis/SDAF/" + $page_id + "/Next-steps"
Write-Host "URL: " $wiki_url
if ($true -eq $CreateConnection) {
  Start-Process $wiki_url
}
if (Test-Path ".${pathSeparator}$wikiFileName") { Write-Host "Removing $wikiFileName" ; Remove-Item ".${pathSeparator}$wikiFileName" }
<#-------------------------------------+---------------------------------------#>
#endregion



<#-----------------------------------------------------------------------------|
 |                                                                             |
 | Build Service permissions                                                   |
 |                                                                             |
 |-----------------------------------------------------------------------------|
 |-------------------------------------+---------------------------------------#>
#region
Write-Host  "Section: Set permissions for Build Service ..." `
            -ForegroundColor DarkCyan

Write-Host  "Adding the Build Service user to the Build Administrators group for the Project" `
            -ForegroundColor Green
$SecurityServiceGroupId   = $(az devops security group list --scope organization   --query "graphGroups | [?displayName=='Security Service Group'].descriptor | [0]" --output tsv)
$ProjectBuildAdminGroupId = $(az devops security group list --project $ADO_Project --query "graphGroups | [?displayName=='Build Administrators'].descriptor   | [0]" --output tsv)
$GroupItems               = $(az devops security group membership list --id $SecurityServiceGroupId --output table )

$Service_Name = $ADO_Project + " Build Service"
$Descriptor   = ""
$Name         = ""
$Parts        = $GroupItems[1].Split(' ')
$RealItems    = $GroupItems[2..($GroupItems.Length - 2)]
foreach ($Item in $RealItems) {
  $Name = $Item.Substring(0, $Parts[0].Length).Trim()
  if ($Name.StartsWith($Service_Name)) {
    $Descriptor = $Item.Substring($Parts[0].Length + $Parts[1].Length + $Parts[2].Length).Trim()
    break
  }
}

if ($Descriptor -eq "") {
  Write-Host  "The Build Service user was not found in the Security Service Group" `
              -ForegroundColor Red
}
else {
  Write-Host  "Adding the Build Service user to the Build Administrators group" `
              -ForegroundColor Green
  $response = az devops security group membership add --member-id $Descriptor               `
                                                      --group-id $ProjectBuildAdminGroupId
}
<#-------------------------------------+---------------------------------------#>
#endregion



Write-Host  "The script has completed" `
            -ForegroundColor Green
