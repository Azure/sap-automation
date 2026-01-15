# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

# Write-Host "<Experimental>..............." -ForegroundColor Cyan

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
$ARM_TENANT_ID = $Env:ARM_TENANT_ID
$Control_plane_code = $Env:SDAF_CONTROL_PLANE_CODE
$Control_plane_subscriptionID = $Env:SDAF_ControlPlaneSubscriptionID
$ControlPlaneSubscriptionName = $Env:SDAF_ControlPlaneSubscriptionName

if ( $null -ne $Env:CreateConnections) {
  $CreateConnection = [System.Convert]::ToBoolean($Env:CreateConnections)
}
else {
  $CreateConnection = $true
}

if ( $null -ne $Env:SDAF_BRANCH ) {
  $branch = $Env:SDAF_BRANCH
}
else {
  $branch = "main"
}

if ( $null -ne $Env:ImportFromGitHub) {
  $ImportFromGitHub = [System.Convert]::ToBoolean($Env:ImportFromGitHub)
}

if ( $null -ne $Env:CreatePAT) {
  $CreatePAT = [System.Convert]::ToBoolean($Env:CreatePAT)
}
else {
  $CreatePAT = $true
}



if ($IsWindows) { $pathSeparator = "\" } else { $pathSeparator = "/" }
#endregion

$versionLabel = "v3.14.1.0"

# az logout

# az account clear

# if ($ARM_TENANT_ID.Length -eq 0) {
#   az login --output none --only-show-errors --scope https://graph.microsoft.com//.default
# }
# else {
#   az login --output none --tenant $ARM_TENANT_ID --only-show-errors --scope https://graph.microsoft.com//.default
# }

# Check if access to the Azure DevOps organization is available and prompt for PAT if needed
# Exact permissions required, to be validated, and included in the Read-Host text.
$PAT = 'Enter your personal access token here'
if ($Env:AZURE_DEVOPS_EXT_PAT.Length -gt 0) {
  Write-Host "Using the provided Personal Access Token (PAT) to authenticate to the Azure DevOps organization $ADO_Organization" -ForegroundColor Yellow
  $PAT = $Env:AZURE_DEVOPS_EXT_PAT
  $CreatePAT = $false
}

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

if (Test-Path ".${pathSeparator}start.md") { Write-Host "Removing start.md" ; Remove-Item ".${pathSeparator}start.md" }

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

az config set extension.use_dynamic_install=yes_without_prompt --only-show-errors

az extension add --name azure-devops --only-show-errors

#region Validate parameters

if ($Control_plane_subscriptionID.Length -eq 0) {
  Write-Host "$Env:ControlPlaneSubscriptionID is not set!" -ForegroundColor Red
  $Title = "Choose the subscription for the Control Plane"
  $subscriptions = $(az account list --query "[].{Name:name}" -o table | Sort-Object)
  Show-Menu($subscriptions[2..($subscriptions.Length - 1)])

  $selection = Read-Host $Title

  $selectionOffset = [convert]::ToInt32($selection, 10) + 1

  $ControlPlaneSubscriptionName = $subscriptions[$selectionOffset]

  az account set --subscription $ControlPlaneSubscriptionName
  $Control_plane_subscriptionID = (az account show --query id -o tsv)
}
else {
  az account set --sub $Control_plane_subscriptionID
  $ControlPlaneSubscriptionName = (az account show --query name -o tsv)
}

if ($ControlPlaneSubscriptionName.Length -eq 0) {
  Write-Host "ControlPlaneSubscriptionName is not set"
  exit
}

if ($ADO_Organization.Length -eq 0) {
  Write-Host "Organization is not set"
  $ADO_Organization = Read-Host "Enter your ADO organization URL"
}
else {
  Write-Host "Using Organization: $ADO_Organization" -foregroundColor Yellow
}

if ($Control_plane_code.Length -eq 0) {
  Write-Host "Control plane code is not set (MGMT, etc)"
  $Control_plane_code = Read-Host "Enter your Control plane code"
}
else {
  Write-Host "Using Control plane code: $Control_plane_code" -foregroundColor Yellow
}

$ControlPlanePrefix = "SDAF-" + $Control_plane_code

if ($Env:SDAF_POOL_NAME.Length -eq 0) {
  $Pool_Name = $ControlPlanePrefix + "-POOL"
}
else {
  $Pool_Name = $Env:SDAF_POOL_NAME
}

$WebApp = $true
if ($Env:SDAF_WEBAPP -eq "true") {
  $ApplicationName = $ControlPlanePrefix + "-configuration-app"

  if ($Env:SDAF_APP_NAME.Length -ne 0) {
    $ApplicationName = $Env:SDAF_APP_NAME
  }
}
else {
  $WebApp = $false
}

if ($Env:SDAF_AGENT_POOL_NAME.Length -ne 0) {
  $Pool_Name = $Env:SDAF_AGENT_POOL_NAME
}
else {
  $confirmation = Read-Host "Use Agent pool with name '$Pool_Name' y/n?"
  if ($confirmation -ne 'y') {
    $Pool_Name = Read-Host "Enter the name of the agent pool"
  }
}

$pipeline_permission_url = ""

$import_code = $false

$APP_REGISTRATION_ID = ""
$WEB_APP_CLIENT_SECRET = "Enter your App registration secret here"

#endregion

$fname = "start.md"

Add-Content -Path $fname -Value "# Welcome to the SDAF Wiki"
Add-Content -Path $fname -Value ""
Add-Content -Path $fname -Value "## Deployment details"
Add-Content -Path $fname -Value ""
Add-Content -Path $fname -Value "Azure DevOps organization: $ADO_Organization"

#region Install extension

Write-Host "Installing the DevOps extensions" -ForegroundColor Green
$extension_name = (az devops extension list --organization $ADO_Organization --query "[?extensionName=='Post Build Cleanup'].extensionName | [0]")

if ($extension_name.Length -eq 0) {
  az devops extension install --organization $ADO_Organization --extension PostBuildCleanup --publisher-id mspremier --output none
}

#endregion

#region Create DevOps project
$Project_ID = (az devops project list --organization $ADO_ORGANIZATION --query "[value[]] | [0] | [? name=='$ADO_PROJECT'].id | [0]" --out tsv)

if ($Project_ID.Length -eq 0) {
  Write-Host "Creating the project: " $ADO_PROJECT -ForegroundColor Green
  $Project_ID = (az devops project create --name $ADO_PROJECT --description 'SDAF Automation Project' --organization $ADO_ORGANIZATION --visibility private --source-control git --query id --output tsv)

  Add-Content -Path $fname -Value ""
  Add-Content -Path $fname -Value "Using Azure DevOps Project: $ADO_PROJECT"

  az devops configure --defaults organization=$ADO_ORGANIZATION project="$ADO_PROJECT"

  $repo_id = (az repos list --query "[?name=='$ADO_Project'].id | [0]"  --out tsv)
  $repo_url = (az repos list --query "[?name=='$ADO_Project'].webUrl | [0]"  --out tsv)

  Write-Host "Importing the content from GitHub" -ForegroundColor Green
  az repos import create --git-url https://github.com/Azure/SAP-automation-bootstrap --repository $repo_id   --output none

  az repos update --repository $repo_id --default-branch $branch   --output none

}

else {

  Add-Content -Path $fname -Value ""
  Add-Content -Path $fname -Value "DevOps Project: $ADO_PROJECT"

  Write-Host "Using an existing project"

  az devops configure --defaults organization=$ADO_ORGANIZATION project="$ADO_PROJECT"

  $repo_id = (az repos list --query "[?name=='$ADO_Project'].id | [0]"  --output tsv)
  if ($repo_id.Length -ne 0) {
    Write-Host "Using repository '$ADO_Project'" -ForegroundColor Green
  }
  $repo_url = (az repos list --query "[?name=='$ADO_Project'].webUrl | [0]"  --out tsv)

  $repo_size = (az repos list --query "[?name=='$ADO_Project'].size | [0]"  --output tsv)

  if ($repo_size -eq 0) {
    Write-Host "Importing the repository from GitHub" -ForegroundColor Green

    Add-Content -Path $fname -Value ""
    Add-Content -Path $fname -Value "Terraform and Ansible code repository stored in the DevOps project (sap-automation)"

    az repos import create --git-url https://github.com/Azure/SAP-automation-bootstrap --repository $repo_id   --output tsv
    if ($LastExitCode -eq 1) {
      Write-Host "The repository already exists" -ForegroundColor Yellow
      Write-Host "Creating repository 'SDAF Configuration'" -ForegroundColor Green
      $repo_id = (az repos create --name "SDAF Configuration" --query id --output tsv)
      az repos import create --git-url https://github.com/Azure/SAP-automation-bootstrap --repository $repo_id  --output none
    }

  }
  else {
    $confirmation = Read-Host "The repository already exists, use it? y/n"
    if ($confirmation -ne 'y') {
      Write-Host "Creating repository 'SDAF Configuration'" -ForegroundColor Green
      $repo_id = (az repos create --name "SDAF Configuration" --query id  --output tsv)
      az repos import create --git-url https://github.com/Azure/SAP-automation-bootstrap --repository $repo_id  --output none
    }
  }

  az repos update --repository $repo_id --default-branch $branch   --output none
}

if ( Test-Path "temprepo") {
  Write-Host "Removing temprepo" -ForegroundColor Green
  Remove-Item -Path (Join-Path -PAth Get-Location -ChildPath "temprepo") -Recurse -Force
}

$tempPath = New-Item -Path (Join-Path -PAth Get-Location -ChildPath "temprepo") -ItemType Directory -Force | Out-Null
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
  $confirmation = Read-Host "You can optionally import the Terraform and Ansible code from GitHub into Azure DevOps, however, this should only be done if you cannot access github from the Azure DevOps agent or if you intend to customize the code. Do you want to run the code from GitHub y/n?"
}


if ($confirmation -ne 'y') {
  Add-Content -Path $fname -Value ""
  Add-Content -Path $fname -Value "Using the code from the sap-automation repository"

  $import_code = $true
  $repo_name = "sap-automation"
  Write-Host "Creating $repo_name repository" -ForegroundColor Green
  az repos create --name $repo_name --query id  --output none
  $code_repo_id = (az repos list --query "[?name=='$repo_name'].id | [0]"  --out tsv)
  az repos import create --git-url https://github.com/Azure/SAP-automation --repository $code_repo_id  --output none
  az repos update --repository $code_repo_id --default-branch $branch   --output none

  $import_code = $true
  $repo_name = "sap-samples"
  Write-Host "Creating $repo_name repository" -ForegroundColor Green
  az repos create --name $repo_name --query id  --output none
  $sample_repo_id = (az repos list --query "[?name=='$repo_name'].id | [0]"  --out tsv)
  az repos import create --git-url https://github.com/Azure/SAP-automation-samples --repository $sample_repo_id  --output none
  az repos update --repository $sample_repo_id --default-branch $branch   --output none

  if ($ADO_Project -ne "SAP Deployment Automation Framework") {

    Write-Host "Using a non standard DevOps project name, need to update some of the parameter files" -ForegroundColor Green

    $objectId = (az devops invoke --area git --resource refs --route-parameters project=$ADO_Project repositoryId=$repo_id --query-parameters filter=heads/main --query value[0] | ConvertFrom-Json).objectId


    $templatename = "resources.yml"
    if (Test-Path $templatename) {
      Remove-Item $templatename
    }

    Add-Content -Path $templatename ""
    Add-Content -Path $templatename "parameters:"
    Add-Content -Path $templatename "  - name: stages"
    Add-Content -Path $templatename "    type: stageList"
    Add-Content -Path $templatename "    default: []"
    Add-Content -Path $templatename ""
    Add-Content -Path $templatename "stages:"
    Add-Content -Path $templatename "  - `${{ parameters.stages }}"
    Add-Content -Path $templatename ""
    Add-Content -Path $templatename "resources:"
    Add-Content -Path $templatename "  repositories:"
    Add-Content -Path $templatename "    - repository: sap-automation"
    Add-Content -Path $templatename "      type: git"
    Add-Content -Path $templatename "      name: $ADO_Project/sap-automation"
    Add-Content -Path $templatename -Value ("      ref: refs/heads/main")
    #Add-Content -Path $templatename -Value ("      ref: refs/tags/" + $versionLabel)

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

    Remove-Item $templatename
    $templatename = "resources_including_samples.yml"
    Add-Content -Path $templatename ""
    Add-Content -Path $templatename "parameters:"
    Add-Content -Path $templatename "  - name: stages"
    Add-Content -Path $templatename "    type: stageList"
    Add-Content -Path $templatename "    default: []"
    Add-Content -Path $templatename ""
    Add-Content -Path $templatename "stages:"
    Add-Content -Path $templatename "  - `${{ parameters.stages }}"
    Add-Content -Path $templatename ""
    Add-Content -Path $templatename "resources:"
    Add-Content -Path $templatename "  repositories:"
    Add-Content -Path $templatename "    - repository: sap-automation"
    Add-Content -Path $templatename "      type: git"
    Add-Content -Path $templatename "      name: $ADO_Project/sap-automation"
    Add-Content -Path $templatename -Value ("      ref: refs/heads/main")
    #Add-Content -Path $templatename -Value ("      ref: refs/tags/" + $versionLabel)
    Add-Content -Path $templatename "    - repository: sap-samples"
    Add-Content -Path $templatename "      type: git"
    Add-Content -Path $templatename "      name: $ADO_Project/sap-samples"
    Add-Content -Path $templatename "      ref: refs/heads/main"

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
  Add-Content -Path $fname -Value ""
  Add-Content -Path $fname -Value "Using the code directly from GitHub"

  $resources_url = $ADO_ORGANIZATION + "/_git/" + [uri]::EscapeDataString($ADO_Project) + "?path=/pipelines/resources.yml"

  $log = ("Please update [resources.yml](" + $resources_url + ") to point to Github instead of Azure DevOps.")

}

#endregion

$repo_id = (az repos list --query "[?name=='$ADO_Project'].id | [0]"  --out tsv)
$repo_name = (az repos list --query "[?name=='$ADO_Project'].name | [0]"  --out tsv)

$SUserName = 'Enter your S User'
$SPassword = 'Enter your S user password'

if ($Env:SUserName.Length -ne 0) {
  $SUserName = $Env:SUserName
}
if ($Env:SPassword.Length -ne 0) {
  $SPassword = $Env:SPassword
}

if ($Env:SUserName.Length -eq 0 -and $Env:SPassword.Length -eq 0) {

  $provideSUser = Read-Host "Do you want to provide the S user details y/n?"
  if ($provideSUser -eq 'y') {
    $SUserName = Read-Host "Enter your S User ID"
    $SPassword = Read-Host "Enter your S user password"
  }
}
$groups = New-Object System.Collections.Generic.List[System.Object]
$pipelines = New-Object System.Collections.Generic.List[System.Object]

Write-Host "Creating the variable group SDAF-General" -ForegroundColor Green

$general_group_id = (az pipelines variable-group list --query "[?name=='SDAF-General'].id | [0]" --only-show-errors)
if ($general_group_id.Length -eq 0) {
  az pipelines variable-group create --name SDAF-General --variables ANSIBLE_HOST_KEY_CHECKING=false Deployment_Configuration_Path=WORKSPACES Branch=main tf_version="1.11.3" ansible_core_version="2.16" S-Username=$SUserName S-Password=$SPassword --output yaml --authorize true --output none
  $general_group_id = (az pipelines variable-group list --query "[?name=='SDAF-General'].id | [0]" --only-show-errors)
  az pipelines variable-group variable update --group-id $general_group_id --name "S-Password" --value $SPassword --secret true --output none --only-show-errors
}

$groups.Add($general_group_id)

#region Create pipelines
Write-Host "Creating the pipelines in repo: " $repo_name "(" $repo_id ")" -foregroundColor Green

Add-Content -Path $fname -Value ""
Add-Content -Path $fname -Value "### Pipelines"
Add-Content -Path $fname -Value ""

$pipeline_name = 'Create Control Plane configuration'
$sample_pipeline_id = (az pipelines list --query "[?name=='$pipeline_name'].id | [0]")
if ($sample_pipeline_id.Length -eq 0) {
  az pipelines create --name $pipeline_name --branch main --description 'Create sample configuration' --skip-run --yaml-path "/pipelines/22-sample-deployer-configuration.yml" --repository $repo_id --repository-type tfsgit --output none --only-show-errors
  $sample_pipeline_id = (az pipelines list --query "[?name=='$pipeline_name'].id | [0]")
}
$this_pipeline_url = $ADO_ORGANIZATION + "/" + [uri]::EscapeDataString($ADO_Project) + "/_build?definitionId=" + $sample_pipeline_id
$log = ("[" + $pipeline_name + "](" + $this_pipeline_url + ")")
Add-Content -Path $fname -Value $log

$pipeline_name = 'Deploy Control plane'
$control_plane_pipeline_id = (az pipelines list --query "[?name=='$pipeline_name'].id | [0]")
if ($control_plane_pipeline_id.Length -eq 0) {
  az pipelines create --name $pipeline_name --branch main --description 'Deploys the control plane' --skip-run --yaml-path "/pipelines/01-deploy-control-plane.yml" --repository $repo_id --repository-type tfsgit --output none --only-show-errors
  $control_plane_pipeline_id = (az pipelines list --query "[?name=='$pipeline_name'].id | [0]")
}

$pipelines.Add($control_plane_pipeline_id)

$this_pipeline_url = $ADO_ORGANIZATION + "/" + [uri]::EscapeDataString($ADO_Project) + "/_build?definitionId=" + $control_plane_pipeline_id
$log = ("[" + $pipeline_name + "](" + $this_pipeline_url + ")")
Add-Content -Path $fname -Value $log

$pipeline_name = 'SAP Workload Zone deployment'
$wz_pipeline_id = (az pipelines list --query "[?name=='$pipeline_name'].id | [0]")
if ($wz_pipeline_id.Length -eq 0) {
  az pipelines create --name $pipeline_name --branch main --description 'Deploys the workload zone' --skip-run --yaml-path "/pipelines/02-sap-workload-zone.yml" --repository $repo_id --repository-type tfsgit --output none --only-show-errors
  $wz_pipeline_id = (az pipelines list --query "[?name=='$pipeline_name'].id | [0]")
}

$pipelines.Add($wz_pipeline_id)

$this_pipeline_url = $ADO_ORGANIZATION + "/" + [uri]::EscapeDataString($ADO_Project) + "/_build?definitionId=" + $wz_pipeline_id
$log = ("[" + $pipeline_name + "](" + $this_pipeline_url + ")")
Add-Content -Path $fname -Value $log

$pipeline_name = 'SAP SID Infrastructure deployment'
$system_pipeline_id = (az pipelines list --query "[?name=='$pipeline_name'].id | [0]")
if ($system_pipeline_id.Length -eq 0) {
  az pipelines create --name $pipeline_name --branch main --description 'Deploys the infrastructure required for a SAP SID deployment' --skip-run --yaml-path "/pipelines/03-sap-system-deployment.yml" --repository $repo_id --repository-type tfsgit --output none --only-show-errors
  $system_pipeline_id = (az pipelines list --query "[?name=='$pipeline_name'].id | [0]")
}
$pipelines.Add($system_pipeline_id)

$this_pipeline_url = $ADO_ORGANIZATION + "/" + [uri]::EscapeDataString($ADO_Project) + "/_build?definitionId=" + $system_pipeline_id
$log = ("[" + $pipeline_name + "](" + $this_pipeline_url + ")")
Add-Content -Path $fname -Value $log

$pipeline_name = 'SAP Software acquisition'
$pipeline_id = (az pipelines list --query "[?name=='$pipeline_name'].id | [0]")
if ($pipeline_id.Length -eq 0) {
  az pipelines create --name $pipeline_name --branch main --description 'Downloads the software from SAP' --skip-run --yaml-path "/pipelines/04-sap-software-download.yml" --repository $repo_id --repository-type tfsgit --output none --only-show-errors
  $pipeline_id = (az pipelines list --query "[?name=='$pipeline_name'].id | [0]")
}
$pipelines.Add($pipeline_id)

$this_pipeline_url = $ADO_ORGANIZATION + "/" + [uri]::EscapeDataString($ADO_Project) + "/_build?definitionId=" + $pipeline_id
$log = ("[" + $pipeline_name + "](" + $this_pipeline_url + ")")
Add-Content -Path $fname -Value $log

$pipeline_name = 'Configuration and SAP installation'
$installation_pipeline_id = (az pipelines list --query "[?name=='$pipeline_name'].id | [0]")
if ($installation_pipeline_id.Length -eq 0) {
  $installation_pipeline_id = (az pipelines create --name $pipeline_name --branch main --description 'Configures the Operating System and installs the SAP application' --skip-run --yaml-path "/pipelines/05-DB-and-SAP-installation.yml" --repository $repo_id --repository-type tfsgit --output none --only-show-errors)
  $installation_pipeline_id = (az pipelines list --query "[?name=='$pipeline_name'].id | [0]")
}
$pipelines.Add($installation_pipeline_id)

$this_pipeline_url = $ADO_ORGANIZATION + "/" + [uri]::EscapeDataString($ADO_Project) + "/_build?definitionId=" + $installation_pipeline_id
$log = ("[" + $pipeline_name + "](" + $this_pipeline_url + ")")
Add-Content -Path $fname -Value $log

$pipeline_name = 'Remove System or Workload Zone'
$pipeline_id = (az pipelines list --query "[?name=='$pipeline_name'].id | [0]")
if ($pipeline_id.Length -eq 0) {
  az pipelines create --name $pipeline_name --branch main --description 'Removes either the SAP system or the workload zone' --skip-run --yaml-path "/pipelines/10-remover-terraform.yml" --repository $repo_id --repository-type tfsgit --output none --only-show-errors
  $pipeline_id = (az pipelines list --query "[?name=='$pipeline_name'].id | [0]")
}
$pipelines.Add($pipeline_id)

$this_pipeline_url = $ADO_ORGANIZATION + "/" + [uri]::EscapeDataString($ADO_Project) + "/_build?definitionId=" + $pipeline_id
$log = ("[" + $pipeline_name + "](" + $this_pipeline_url + ")")
Add-Content -Path $fname -Value $log

$pipeline_name = 'Remove deployments via ARM'
$pipeline_id = (az pipelines list --query "[?name=='$pipeline_name'].id | [0]")
if ($pipeline_id.Length -eq 0) {
  az pipelines create --name $pipeline_name --branch main --description 'Removes the resource groups via ARM. Use this only as last resort' --skip-run --yaml-path "/pipelines/11-remover-arm-fallback.yml" --repository $repo_id --repository-type tfsgit --output none --only-show-errors
  $pipeline_id = (az pipelines list --query "[?name=='$pipeline_name'].id | [0]")
}
$pipelines.Add($pipeline_id)

$this_pipeline_url = $ADO_ORGANIZATION + "/" + [uri]::EscapeDataString($ADO_Project) + "/_build?definitionId=" + $pipeline_id
$log = ("[" + $pipeline_name + "](" + $this_pipeline_url + ")")
Add-Content -Path $fname -Value $log

$pipeline_name = 'Remove control plane'
$pipeline_id = (az pipelines list --query "[?name=='$pipeline_name'].id | [0]")
if ($pipeline_id.Length -eq 0) {
  az pipelines create --name $pipeline_name --branch main --description 'Removes the control plane' --skip-run --yaml-path "/pipelines/12-remove-control-plane.yml" --repository $repo_id --repository-type tfsgit --output none --only-show-errors
  $pipeline_id = (az pipelines list --query "[?name=='$pipeline_name'].id | [0]")
}
$pipelines.Add($pipeline_id)

$this_pipeline_url = $ADO_ORGANIZATION + "/" + [uri]::EscapeDataString($ADO_Project) + "/_build?definitionId=" + $pipeline_id
$log = ("[" + $pipeline_name + "](" + $this_pipeline_url + ")")
Add-Content -Path $fname -Value $log

if ($import_code) {
  $pipeline_name = 'Update repository'
  $pipeline_id = (az pipelines list --query "[?name=='$pipeline_name'].id | [0]")
  if ($pipeline_id.Length -eq 0) {
    az pipelines create --name $pipeline_name --branch main --description 'Updates the codebase' --skip-run --yaml-path "/pipelines/20-update-repositories.yml" --repository $repo_id --repository-type tfsgit --output none --only-show-errors
  }
  $pipeline_id = (az pipelines list --query "[?name=='$pipeline_name'].id | [0]")
  $this_pipeline_url = $ADO_ORGANIZATION + "/" + [uri]::EscapeDataString($ADO_Project) + "/_build?definitionId=" + $pipeline_id
  $log = ("[" + $pipeline_name + "](" + $this_pipeline_url + ")")
  Add-Content -Path $fname -Value $log
  $pipelines.Add($pipeline_id)
}


$pipeline_name = 'Update Pipelines'
$pipeline_id = (az pipelines list --query "[?name=='$pipeline_name'].id | [0]")
if ($pipeline_id.Length -eq 0) {
  az pipelines create --name $pipeline_name --branch main --description 'Updates the pipelines' --skip-run --yaml-path "/pipelines/21-update-pipelines.yml" --repository $repo_id --repository-type tfsgit --output none --only-show-errors
}
$pipeline_id = (az pipelines list --query "[?name=='$pipeline_name'].id | [0]")
$pipelines.Add($pipeline_id)

$this_pipeline_url = $ADO_ORGANIZATION + "/" + [uri]::EscapeDataString($ADO_Project) + "/_build?definitionId=" + $pipeline_id
$log = ("[" + $pipeline_name + "](" + $this_pipeline_url + ")")
Add-Content -Path $fname -Value $log

if ($true -eq $CreateConnection ) {
  $gh_connection_url = $ADO_ORGANIZATION + "/" + [uri]::EscapeDataString($ADO_Project) + "/_settings/adminservices"
  Write-Host ""
  Write-Host "The browser will now open, please create a new Github connection, record the name of the connection."
  Write-Host "URL: " $gh_connection_url
  Start-Process $gh_connection_url
  Read-Host "Please press enter when you have created the connection"

  $ghConn = (az devops service-endpoint list --query "[?type=='github'].name | [0]"  --out tsv)

  $objectId = (az devops invoke --area git --resource refs --route-parameters project=$ADO_Project repositoryId=$repo_id --query-parameters filter=heads/main --query value[0] | ConvertFrom-Json).objectId

  $templatename = "resources.yml"
  if (Test-Path $templatename) {
    Remove-Item $templatename
  }

  Add-Content -Path $templatename ""
  Add-Content -Path $templatename "parameters:"
  Add-Content -Path $templatename "  - name: stages"
  Add-Content -Path $templatename "    type: stageList"
  Add-Content -Path $templatename "    default: []"
  Add-Content -Path $templatename ""
  Add-Content -Path $templatename "stages:"
  Add-Content -Path $templatename "  - `${{ parameters.stages }}"
  Add-Content -Path $templatename ""
  Add-Content -Path $templatename "resources:"
  Add-Content -Path $templatename "  repositories:"
  Add-Content -Path $templatename "    - repository: sap-automation"
  Add-Content -Path $templatename "      type: GitHub"
  Add-Content -Path $templatename -Value ("      endpoint: " + $ghConn)
  Add-Content -Path $templatename "      name: Azure/sap-automation"
  Add-Content -Path $templatename "      ref: refs/heads/main"
  #  Add-Content -Path $templatename -Value ("      ref: refs/tags/" + $versionLabel)

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

  Remove-Item $templatename
  $templatename = "resources_including_samples.yml"

  Add-Content -Path $templatename "parameters:"
  Add-Content -Path $templatename " - name: stages"
  Add-Content -Path $templatename "   type: stageList"
  Add-Content -Path $templatename "   default: []"
  Add-Content -Path $templatename ""
  Add-Content -Path $templatename "stages:"
  Add-Content -Path $templatename " - `${{ parameters.stages }}"
  Add-Content -Path $templatename ""
  Add-Content -Path $templatename "resources:"
  Add-Content -Path $templatename "  repositories:"
  Add-Content -Path $templatename "   - repository: sap-automation"
  Add-Content -Path $templatename "     type: GitHub"
  Add-Content -Path $templatename -Value ("     endpoint: " + $ghConn)
  Add-Content -Path $templatename "     name: Azure/sap-automation"
  Add-Content -Path $templatename "     ref: refs/heads/main"
  Add-Content -Path $templatename "   - repository: sap-samples"
  Add-Content -Path $templatename "     type: GitHub"
  Add-Content -Path $templatename -Value ("     endpoint: " + $ghConn)
  Add-Content -Path $templatename "     name: Azure/sap-automation-samples"
  Add-Content -Path $templatename "     ref: refs/heads/main"

  $cont2 = Get-Content -Path $templatename -Raw

  $objectId = (az devops invoke --area git --resource refs --route-parameters project=$ADO_Project repositoryId=$repo_id --query-parameters filter=heads/main --query value[0] | ConvertFrom-Json).objectId

  Remove-Item "sdaf.json"

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
            newContent = @{content = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes($cont2))
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
  Remove-Item $inputfile

  Write-Host ""
  $Service_Connection_Name = "Control_Plane_Service_Connection"
  $epExists = (az devops service-endpoint list --query "[?name=='$Service_Connection_Name'].name | [0]" )
  if ($epExists.Length -eq 0) {

    Write-Host "The browser will now open, Please create an 'Azure Resource Manager' service connection with the name 'Control_Plane_Service_Connection'."
    $connections_url = $ADO_ORGANIZATION + "/" + [uri]::EscapeDataString($ADO_Project) + "/_settings/adminservices"
    Write-Host "URL: " $connections_url

    Start-Process $connections_url
    Read-Host -Prompt "Once you have created and validated the connection, Press any key to continue"
    $epId = az devops service-endpoint list --query "[?name=='$Service_Connection_Name'].id" -o tsv
    if ($epId.Length -ne 0) {
      az devops service-endpoint update --id $epId --enable-for-all true --output none --only-show-errors
    }
  }


}
else {
  Write-Host "Please create an 'Azure Resource Manager' service connection to the control plane subscription with the name 'Control_Plane_Service_Connection' before running any pipeline."
  Write-Host "Please create a 'GitHub' service connection before running any pipeline."
}

#endregion

Add-Content -Path $fname -Value ""
Add-Content -Path $fname -Value "### Variable Groups"
Add-Content -Path $fname -Value ""
Add-Content -Path $fname -Value "SDAF-General"
Add-Content -Path $fname -Value $ControlPlanePrefix
Add-Content -Path $fname -Value $WorkloadZonePrefix

Add-Content -Path $fname -Value "### Credentials"
Add-Content -Path $fname -Value ""
Add-Content -Path $fname -Value ("Web Application: " + $ApplicationName)

$MSI_objectId = $null
if ($authenticationMethod -eq "Managed Identity") {

  if ($Env:MSI_OBJECT_ID.Length -ne 0) {
    $MSI_objectId = $Env:MSI_OBJECT_ID
  }
  else {

    $Title = "Choose the subscription that contains the Managed Identity"
    $subscriptions = $(az account list --query "[].{Name:name}" -o table | Sort-Object)
    Show-Menu($subscriptions[2..($subscriptions.Length - 1)])
    $selection = Read-Host $Title

    $selectionOffset = [convert]::ToInt32($selection, 10) + 1

    $subscription = $subscriptions[$selectionOffset]
    Write-Host "Using subscription:" $subscription

    $Title = "Choose the Managed Identity"
    $identities = $(az identity list --query "[].{Name:name}" --subscription $subscription --output table | Sort-Object)
    Show-Menu($identities[2..($identities.Length - 1)])
    $selection = Read-Host $Title
    $selectionOffset = [convert]::ToInt32($selection, 10) + 1

    $identity = $identities[$selectionOffset]
    Write-Host "Using Managed Identity:" $identity

    $id = $(az identity list --query "[?name=='$identity'].id" --subscription $subscription --output tsv)
    $MSI_objectId = $(az identity show --ids $id --query "principalId" --output tsv)

  }
}

#region App registration
if ($WebApp) {
  Write-Host "Creating the App registration in Azure Active Directory" -ForegroundColor Green

  $found_appRegistration = (az ad app list --all --filter "startswith(displayName, '$ApplicationName')" --query  "[?displayName=='$ApplicationName'].displayName | [0]" --only-show-errors)

  if ($found_appRegistration.Length -ne 0) {
    Write-Host "Found an existing App Registration:" $ApplicationName
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
    Write-Host "Creating an App Registration for" $ApplicationName -ForegroundColor Green
    if ($IsWindows) { $manifestPath = ".\manifest.json" } else { $manifestPath = "./manifest.json" }
    Add-Content -Path manifest.json -Value '[{"resourceAppId":"00000003-0000-0000-c000-000000000000","resourceAccess":[{"id":"e1fe6dd8-ba31-4d61-89e7-88639da4683d","type":"Scope"}]}]'

    $APP_REGISTRATION_ID = (az ad app create --display-name $ApplicationName --enable-id-token-issuance true --sign-in-audience AzureADMyOrg --required-resource-access $manifestPath --query "appId" --output tsv)
    $ExistingData = (az ad app list --all --filter "startswith(displayName, '$ApplicationName')" --query  "[?displayName=='$ApplicationName']| [0]" --only-show-errors) | ConvertFrom-Json
    $APP_REGISTRATION_OBJECTID = $ExistingData.id
    az role assignment create --assignee $APP_REGISTRATION_OBJECTID --role "Reader" --subscription $Control_plane_subscriptionID --scope /subscriptions/$Control_plane_subscriptionID --output none

    az role assignment create --assignee $APP_REGISTRATION_OBJECTID --role "Storage Blob Data Contributor" --subscription $Control_plane_subscriptionID --scope /subscriptions/$Control_plane_subscriptionID --output none

    az role assignment create --assignee $APP_REGISTRATION_OBJECTID --role "Storage Table Data Contributor" --subscription $Control_plane_subscriptionID --scope /subscriptions/$Control_plane_subscriptionID --output none


    if (Test-Path $manifestPath) { Write-Host "Removing manifest.json" ; Remove-Item $manifestPath }


    # $WEB_APP_CLIENT_SECRET = (az ad app credential reset --id $APP_REGISTRATION_ID --append --query "password" --out tsv --only-show-errors --display-name "SDAF")
  }

  if ($MSI_objectId -ne $null) {
    $configureAuth = Read-Host "Configuring authentication for the App Registration (y/n)?"
    if ($configureAuth -eq 'y') {
      az rest --method POST --uri "https://graph.microsoft.com/beta/applications/$APP_REGISTRATION_OBJECTID/federatedIdentityCredentials\" --body "{'name': 'ManagedIdentityFederation', 'issuer': 'https://login.microsoftonline.com/$ARM_TENANT_ID/v2.0', 'subject': '$MSI_objectId', 'audiences': [ 'api://AzureADTokenExchange' ]}"

      $API_URL = "https://portal.azure.com/#view/Microsoft_AAD_RegisteredApps/ApplicationMenuBlade/~/ProtectAnAPI/appId/$APP_REGISTRATION_ID/isMSAApp~/false"

      Write-Host "The browser will now open, Please Add a new scope, by clicking the '+ Add a new scope link', accept the default name and click 'Save and Continue'"
      Write-Host "In the Add a scope page enter the scope name 'user_impersonation'. Choose 'Admins and Users' in the who can consent section, next provide the Admin consent display name 'Access the SDAF web application' and 'Use SDAF' as the Admin consent description, accept the changes by clicking the 'Add scope' button"

      Start-Process $API_URL
      Read-Host -Prompt "Once you have created and validated the scope, Press any key to continue"


    }

  }

}

#endregion
if ($authenticationMethod -eq "Service Principal") {
  #region Control plane Service Principal
  $spn_name = $ControlPlanePrefix + " Deployment credential"
  if ($Env:SDAF_MGMT_SPN_NAME.Length -ne 0) {
    $spn_name = $Env:SDAF_MGMT_SPN_NAME
  }

  Add-Content -Path $fname -Value ("Control Plane Service Principal: " + $spn_name)

  $scopes = "/subscriptions/" + $Control_plane_subscriptionID

  Write-Host "Creating the deployment credentials for the control plane. Service Principal Name:" $spn_name -ForegroundColor Green

  $ARM_CLIENT_ID = ""
  $ARM_OBJECT_ID = ""
  $ARM_TENANT_ID = ""
  $ARM_CLIENT_SECRET = "Please update"


  $found_appName = (az ad sp list --all --filter "startswith(displayName, '$spn_name')" --query "[?displayName=='$spn_name'].displayName | [0]" --only-show-errors)
  if ($found_appName.Length -gt 0) {
    Write-Host "Found an existing Service Principal:" $spn_name
    $ExistingData = (az ad sp list --all --filter "startswith(displayName, '$spn_name')" --query  "[?displayName=='$spn_name']| [0]" --only-show-errors) | ConvertFrom-Json
    Write-Host "Updating the variable group"

    $ARM_CLIENT_ID = $ExistingData.appId
    $ARM_OBJECT_ID = $ExistingData.Id
    $ARM_TENANT_ID = $ExistingData.appOwnerOrganizationId

    #$confirmation = Read-Host "Reset the Control Plane Service Principal password y/n?"
    # if ($confirmation -eq 'y') {

    #   $ARM_CLIENT_SECRET = (az ad sp credential reset --id $ARM_CLIENT_ID --append --query "password" --out tsv --only-show-errors).Replace("""", "")
    # }
    # else {
    $ARM_CLIENT_SECRET = Read-Host "Please enter the Control Plane Service Principal $spn_name password"
    # }

  }
  else {
    Write-Host "Creating the Service Principal" $spn_name -ForegroundColor Green
    $SPN_Created = $true
    $Control_plane_SPN_data = (az ad sp create-for-rbac --role "Contributor" --scopes $scopes --name $spn_name --only-show-errors) | ConvertFrom-Json
    $ARM_CLIENT_SECRET = $Control_plane_SPN_data.password
    $ExistingData = (az ad sp list --all --filter "startswith(displayName, '$spn_name')" --query  "[?displayName=='$spn_name'] | [0]" --only-show-errors) | ConvertFrom-Json
    $ARM_CLIENT_ID = $ExistingData.appId
    $ARM_TENANT_ID = $ExistingData.appOwnerOrganizationId
    $ARM_OBJECT_ID = $ExistingData.Id

  }

  az role assignment create --assignee $ARM_CLIENT_ID --role "Contributor" --subscription $Control_plane_subscriptionID --scope /subscriptions/$Control_plane_subscriptionID --output none

  az role assignment create --assignee $ARM_CLIENT_ID --role "User Access Administrator" --subscription $Control_plane_subscriptionID --scope /subscriptions/$Control_plane_subscriptionID --output none

  az role assignment create --assignee $ARM_CLIENT_ID --role "Storage Blob Data Contributor" --subscription $Control_plane_subscriptionID --scope /subscriptions/$Control_plane_subscriptionID --output none

  az role assignment create --assignee $ARM_CLIENT_ID --role "Storage Table Data Contributor" --subscription $Control_plane_subscriptionID --scope /subscriptions/$Control_plane_subscriptionID --output none

  az role assignment create --assignee $ARM_CLIENT_ID --role "App Configuration Data Owner" --subscription $Control_plane_subscriptionID --scope /subscriptions/$Control_plane_subscriptionID --output none

  az role assignment create --assignee $ARM_CLIENT_ID --role "Private DNS Zone Contributor" --subscription $Control_plane_subscriptionID --scope /subscriptions/$Control_plane_subscriptionID --output none

  $Control_plane_groupID = (az pipelines variable-group list --query "[?name=='$ControlPlanePrefix'].id | [0]" --only-show-errors)
  if ($Control_plane_groupID.Length -eq 0) {
    Write-Host "Creating the variable group" $ControlPlanePrefix -ForegroundColor Green

    if ($WebApp) {
      if ($authenticationMethod -eq "Managed Identity") {
        az pipelines variable-group create --name $ControlPlanePrefix --variables AGENT='Azure Pipelines'  PAT=$PAT APP_REGISTRATION_APP_ID=$APP_REGISTRATION_ID APP_REGISTRATION_OBJECTID=$APP_REGISTRATION_OBJECTID APP_TENANT_ID=$ARM_TENANT_ID ARM_CLIENT_ID=$ARM_CLIENT_ID ARM_OBJECT_ID=$ARM_OBJECT_ID ARM_CLIENT_SECRET='Enter your SPN password here' ARM_SUBSCRIPTION_ID=$Control_plane_subscriptionID ARM_TENANT_ID=$ARM_TENANT_ID POOL=$Pool_Name AZURE_CONNECTION_NAME='Control_Plane_Service_Connection' WORKLOADZONE_PIPELINE_ID=$wz_pipeline_id SYSTEM_PIPELINE_ID=$system_pipeline_id SDAF_GENERAL_GROUP_ID=$general_group_id SAP_INSTALL_PIPELINE_ID=$installation_pipeline_id TF_LOG=OFF USE_MSI=true CONTROL_PLANE_NAME=$Control_plane_code --output none --authorize true
      }
      else {
        az pipelines variable-group create --name $ControlPlanePrefix --variables AGENT='Azure Pipelines'  PAT=$PAT APP_REGISTRATION_APP_ID=$APP_REGISTRATION_ID APP_REGISTRATION_OBJECTID=$APP_REGISTRATION_OBJECTID APP_TENANT_ID=$ARM_TENANT_ID ARM_CLIENT_ID=$ARM_CLIENT_ID ARM_OBJECT_ID=$ARM_OBJECT_ID ARM_CLIENT_SECRET='Enter your SPN password here' ARM_SUBSCRIPTION_ID=$Control_plane_subscriptionID ARM_TENANT_ID=$ARM_TENANT_ID POOL=$Pool_Name AZURE_CONNECTION_NAME='Control_Plane_Service_Connection' WORKLOADZONE_PIPELINE_ID=$wz_pipeline_id SYSTEM_PIPELINE_ID=$system_pipeline_id SDAF_GENERAL_GROUP_ID=$general_group_id SAP_INSTALL_PIPELINE_ID=$installation_pipeline_id TF_LOG=OFF USE_MSI=false CONTROL_PLANE_NAME=$Control_plane_code --output none --authorize true
      }
    }
    else {
      if ($authenticationMethod -eq "Managed Identity") {
        az pipelines variable-group create --name $ControlPlanePrefix --variables AGENT='Azure Pipelines' PAT=$PAT ARM_CLIENT_ID=$ARM_CLIENT_ID ARM_OBJECT_ID=$ARM_OBJECT_ID ARM_CLIENT_SECRET='Enter your SPN password here' ARM_SUBSCRIPTION_ID=$Control_plane_subscriptionID ARM_TENANT_ID=$ARM_TENANT_ID POOL=$Pool_Name AZURE_CONNECTION_NAME='Control_Plane_Service_Connection' WORKLOADZONE_PIPELINE_ID=$wz_pipeline_id SYSTEM_PIPELINE_ID=$system_pipeline_id SDAF_GENERAL_GROUP_ID=$general_group_id SAP_INSTALL_PIPELINE_ID=$installation_pipeline_id TF_LOG=OFF USE_MSI=true CONTROL_PLANE_NAME=$Control_plane_code --output none --authorize true
      }
      else {
        az pipelines variable-group create --name $ControlPlanePrefix --variables AGENT='Azure Pipelines' PAT=$PAT ARM_CLIENT_ID=$ARM_CLIENT_ID ARM_OBJECT_ID=$ARM_OBJECT_ID ARM_CLIENT_SECRET='Enter your SPN password here' ARM_SUBSCRIPTION_ID=$Control_plane_subscriptionID ARM_TENANT_ID=$ARM_TENANT_ID POOL=$Pool_Name AZURE_CONNECTION_NAME='Control_Plane_Service_Connection' WORKLOADZONE_PIPELINE_ID=$wz_pipeline_id SYSTEM_PIPELINE_ID=$system_pipeline_id SDAF_GENERAL_GROUP_ID=$general_group_id SAP_INSTALL_PIPELINE_ID=$installation_pipeline_id TF_LOG=OFF USE_MSI=FALSE CONTROL_PLANE_NAME=$Control_plane_code --output none --authorize true
      }
    }
    $Control_plane_groupID = (az pipelines variable-group list --query "[?name=='$ControlPlanePrefix'].id | [0]" --only-show-errors)
  }

  if ($ARM_CLIENT_SECRET -ne "Please update") {
    az pipelines variable-group variable update --group-id $Control_plane_groupID --name "ARM_CLIENT_SECRET" --value $ARM_CLIENT_SECRET --secret true --output none --only-show-errors
    az pipelines variable-group variable update --group-id $Control_plane_groupID --name "ARM_CLIENT_ID" --value $ARM_CLIENT_ID --output none --only-show-errors
    az pipelines variable-group variable update --group-id $Control_plane_groupID --name "ARM_OBJECT_ID" --value $ARM_OBJECT_ID --output none --only-show-errors
  }

  Write-Host "Create the Service Endpoint in Azure for the control plane" -ForegroundColor Green

  $Service_Connection_Name = "Control_Plane_Service_Connection"
  $Env:AZURE_DEVOPS_EXT_AZURE_RM_SERVICE_PRINCIPAL_KEY = $ARM_CLIENT_SECRET

  $epExists = (az devops service-endpoint list --query "[?name=='$Service_Connection_Name'].name | [0]")
  if ($epExists.Length -eq 0) {
    Write-Host "Creating Service Endpoint" $Service_Connection_Name -ForegroundColor Green
    az devops service-endpoint azurerm create --azure-rm-service-principal-id $ARM_CLIENT_ID --azure-rm-subscription-id $Control_plane_subscriptionID --azure-rm-subscription-name $ControlPlaneSubscriptionName --azure-rm-tenant-id $ARM_TENANT_ID --name $Service_Connection_Name --output none --only-show-errors
    $epId = az devops service-endpoint list --query "[?name=='$Service_Connection_Name'].id" -o tsv
    az devops service-endpoint update --id $epId --enable-for-all true --output none --only-show-errors
  }
  else {
    Write-Host "Service Endpoint already exists, recreating it with the updated credentials" -ForegroundColor Green
    $epId = az devops service-endpoint list --query "[?name=='$Service_Connection_Name'].id" -o tsv
    az devops service-endpoint delete --id $epId --yes
    az devops service-endpoint azurerm create --azure-rm-service-principal-id $ARM_CLIENT_ID --azure-rm-subscription-id $Control_plane_subscriptionID --azure-rm-subscription-name $ControlPlaneSubscriptionName --azure-rm-tenant-id $ARM_TENANT_ID --name $Service_Connection_Name --output none --only-show-errors
    $epId = az devops service-endpoint list --query "[?name=='$Service_Connection_Name'].id" -o tsv
    az devops service-endpoint update --id $epId --enable-for-all true --output none --only-show-errors
  }

}
else {
  $Control_plane_groupID = (az pipelines variable-group list --query "[?name=='$ControlPlanePrefix'].id | [0]" --only-show-errors)
  if ($Control_plane_groupID.Length -eq 0) {
    Write-Host "Creating the variable group" $ControlPlanePrefix -ForegroundColor Green
    if ($WebApp) {
      az pipelines variable-group create --name $ControlPlanePrefix --variables AGENT='Azure Pipelines' PAT=$PAT APP_REGISTRATION_APP_ID=$APP_REGISTRATION_ID APP_REGISTRATION_OBJECTID=$APP_REGISTRATION_OBJECTID APP_TENANT_ID=$ARM_TENANT_ID ARM_SUBSCRIPTION_ID=$Control_plane_subscriptionID POOL=$Pool_Name AZURE_CONNECTION_NAME='Control_Plane_Service_Connection' WORKLOADZONE_PIPELINE_ID=$wz_pipeline_id SYSTEM_PIPELINE_ID=$system_pipeline_id SDAF_GENERAL_GROUP_ID=$general_group_id SAP_INSTALL_PIPELINE_ID=$installation_pipeline_id TF_LOG=OFF USE_MSI=true CONTROL_PLANE_NAME=$Control_plane_code --output none --authorize true
    }
    else {
      az pipelines variable-group create --name $ControlPlanePrefix --variables AGENT='Azure Pipelines'  PAT=$PAT ARM_SUBSCRIPTION_ID=$Control_plane_subscriptionID POOL=$Pool_Name AZURE_CONNECTION_NAME='Control_Plane_Service_Connection' WORKLOADZONE_PIPELINE_ID=$wz_pipeline_id SYSTEM_PIPELINE_ID=$system_pipeline_id SDAF_GENERAL_GROUP_ID=$general_group_id SAP_INSTALL_PIPELINE_ID=$installation_pipeline_id TF_LOG=OFF USE_MSI=true CONTROL_PLANE_NAME=$Control_plane_code --output none --authorize true
    }

    $Control_plane_groupID = (az pipelines variable-group list --query "[?name=='$ControlPlanePrefix'].id | [0]" --only-show-errors)
  }

}

$groups.Add($Control_plane_groupID)


#endregion

$POOL_ID = 0
$POOL_NAME_FOUND = (az pipelines pool list --query "[?name=='$Pool_Name'].name | [0]")
if ($POOL_NAME_FOUND.Length -gt 0) {
  Write-Host "Agent pool" $Pool_Name "already exists" -ForegroundColor Yellow
  $POOL_ID = (az pipelines pool list --query "[?name=='$Pool_Name'].id | [0]" --output tsv)
  $queue_id = (az pipelines queue list --query "[?name=='$Pool_Name'].id | [0]" --output tsv)
}
else {

  Write-Host "Creating agent pool" $Pool_Name -ForegroundColor Green

  Set-Content -Path pool.json -Value (ConvertTo-Json @{name = $Pool_Name; autoProvision = $true })
  az devops invoke --area distributedtask --resource pools --http-method POST --api-version "7.1-preview" --in-file ".${pathSeparator}pool.json" --query-parameters authorizePipelines=true --query id --output none --only-show-errors --route-parameters project=$ADO_Project
  $POOL_ID = (az pipelines pool list --query "[?name=='$Pool_Name'].id | [0]" --output tsv)
  Write-Host "Agent pool" $Pool_Name "created"
  $queue_id = (az pipelines queue list --query "[?name=='$Pool_Name'].id | [0]" --output tsv)

}

if (Test-Path ".${pathSeparator}pool.json") { Write-Host "Removing pool.json" ; Remove-Item ".${pathSeparator}pool.json" }

if ($CreatePAT) {
  # Get pat_url directly from the $ADO_Organization, avoiding double slashes.
  $pat_url = ($ADO_Organization.TrimEnd('/') + "/_usersSettings/tokens").Replace("""", "")
  Write-Host ""
  Write-Host "The browser will now open, please create a Personal Access Token. Ensure that Read & manage is selected for Agent Pools, Read & write is selected for Code, Read & execute is selected for Build, and Read, create, & manage is selected for Variable Groups"
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
    Write-Host "Setting permissions for variable group:" $group.ToString() -ForegroundColor Yellow

    foreach ($pipeline in $pipelines) {
      $bodyText.pipelines[0].id = $pipeline
      $body = $bodyText | ConvertTo-Json -Depth 10
      Write-Host "  Allowing pipeline id:" $pipeline.ToString() -ForegroundColor Yellow
      $response = Invoke-RestMethod -Method PATCH -Uri $pipeline_permission_url -Headers @{Authorization = "Basic $base64AuthInfo" } -Body $body -ContentType "application/json"
    }
  }

  $bodyText = [PSCustomObject]@{
    allPipelines = @{
      authorized = $false
    }
    pipelines    = @([ordered]@{
        id         = 000
        authorized = $true
      })
  }
}
Remove-Item -Path "user.json"

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

az devops invoke --area MemberEntitlementManagement --resource ServicePrincipalEntitlements  --in-file user.json --api-version "7.1-preview" --http-method POST

# Read-Host -Prompt "Press any key to continue"
if ($PAT.Length -gt 0) {
  $base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes((":{0}" -f $PAT)))

  $pipeline_permission_url = $ADO_ORGANIZATION + "/" + $Project_ID + "/_apis/pipelines/pipelinePermissions/queue/" + $queue_id.ToString() + "?api-version=5.1-preview.1"
  Write-Host "Setting permissions for agent pool:" $Pool_Name "(" $queue_id ")" -ForegroundColor Yellow
  foreach ($pipeline in $pipelines) {
    $bodyText.pipelines[0].id = $pipeline
    $body = $bodyText | ConvertTo-Json -Depth 10
    Write-Host "  Allowing pipeline id:" $pipeline.ToString() " access to " $Pool_Name -ForegroundColor Yellow
    $response = Invoke-RestMethod -Method PATCH -Uri $pipeline_permission_url -Headers @{Authorization = "Basic $base64AuthInfo" } -Body $body -ContentType "application/json"
  }
}

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

$pipeline_url = $ADO_ORGANIZATION + "/" + [uri]::EscapeDataString($ADO_Project) + "/_build?definitionId=" + $sample_pipeline_id

$control_plane_pipeline_url = $ADO_ORGANIZATION + "/" + [uri]::EscapeDataString($ADO_Project) + "/_build?definitionId=" + $control_plane_pipeline_id

Add-Content -Path $fname -Value "## Next steps"
Add-Content -Path $fname -Value ""
Add-Content -Path $fname -Value ( "Use the [Create Control Plane Configuration Sample](" + $pipeline_url + ") to create the control plane configuration in the region you select." )
Add-Content -Path $fname -Value ""
Add-Content -Path $fname -Value ( "Once it is complete use the [Deploy Control Plane Pipeline ](" + $control_plane_pipeline_url + ") to create the control plane configuration in the region you select.")
Add-Content -Path $fname -Value ""

$WIKI_NAME_FOUND = (az devops wiki list --query "[?name=='SDAF'].name | [0]")
if ($WIKI_NAME_FOUND.Length -gt 0) {
  Write-Host "Wiki SDAF already exists"
  $eTag = (az devops wiki page show --path 'Next steps' --wiki SDAF --query eTag )
  if ($eTag -ne $null) {
    $page_id = (az devops wiki page update --path 'Next steps' --wiki SDAF --file-path ".${pathSeparator}start.md" --only-show-errors --version $eTag --query page.id)
  }
}
else {
  az devops wiki create --name SDAF --output none --only-show-errors
  az devops wiki page create --path 'Next steps' --wiki SDAF --file-path ".${pathSeparator}start.md" --output none --only-show-errors
}

$page_id = (az devops wiki page show --path 'Next steps' --wiki SDAF --query page.id )

$wiki_url = $ADO_ORGANIZATION + "/" + [uri]::EscapeDataString($ADO_Project) + "/_wiki/wikis/SDAF/" + $page_id + "/Next-steps"
Write-Host "URL: " $wiki_url
if ($true -eq $CreateConnection) {
  Start-Process $wiki_url
}
if (Test-Path ".${pathSeparator}start.md") { Write-Host "Removing start.md" ; Remove-Item ".${pathSeparator}start.md" }

Write-Host "Adding the Build Service user to the Build Administrators group for thge Project" -ForegroundColor Green
$SecurityServiceGroupId = $(az devops security group list --scope organization --query "graphGroups | [?displayName=='Security Service Group'].descriptor | [0]" --output tsv)
$ProjectBuildAdminGroupId = $(az devops security group list --project $ADO_Project --query "graphGroups | [?displayName=='Build Administrators'].descriptor | [0]" --output tsv)
$GroupItems = $(az devops security group membership list --id $SecurityServiceGroupId --output table )

$Service_Name = $ADO_Project + " Build Service"
$Descriptor = ""
$Name = ""
$Parts = $GroupItems[1].Split(' ')
$RealItems = $GroupItems[2..($GroupItems.Length - 2)]
foreach ($Item in $RealItems) {
  $Name = $Item.Substring(0, $Parts[0].Length).Trim()
  if ($Name.StartsWith($Service_Name)) {
    $Descriptor = $Item.Substring($Parts[0].Length + $Parts[1].Length + $Parts[2].Length).Trim()
    break

  }

}

if ($Descriptor -eq "") {
  Write-Host "The Build Service user was not found in the Security Service Group" -ForegroundColor Red
}
else {
  Write-Host "Adding the Build Service user to the Build Administrators group" -ForegroundColor Green
  az devops security group membership add --member-id $Descriptor --group-id $ProjectBuildAdminGroupId
}


Write-Host "The script has completed" -ForegroundColor Green
