#Requires -Version 5.1

<#
.SYNOPSIS
    Creates a new SDAF (SAP Deployment Automation Framework) Azure DevOps project with all necessary resources.

.DESCRIPTION
    This cmdlet creates a comprehensive Azure DevOps project for SAP Deployment Automation Framework (SDAF) including:
    - DevOps project and repositories
    - Service connections and authentication
    - Variable groups
    - CI/CD pipelines
    - Agent pools
    - Wiki documentation

.PARAMETER AdoOrganization
    The Azure DevOps organization URL.

.PARAMETER AdoProject
    The name of the Azure DevOps project to create or use.

.PARAMETER ControlPlaneCode
    The code for the control plane, used to identify the project.

.PARAMETER AuthenticationMethod
    The authentication method to use (Service Principal or Managed Identity).

.PARAMETER EnableWebApp
    Switch to enable the creation of a web application for configuration management.

.PARAMETER WebAppName
    The name of the web application to create for configuration management (if EnableWebApp is set).

.PARAMETER AgentPoolName
    The name of the agent pool to use for the project. If not specified, a default pool will be created.


.EXAMPLE
    Remove-SDAFADOProject -AdoOrganization "https://dev.azure.com/myorg" -AdoProject "SAP-SDAF"

.NOTES
    Author: GitHub Copilot
    Requires: Azure CLI with DevOps extension
    Copyright (c) Microsoft Corporation.
    Licensed under the MIT License.
#>
function Remove-SDAFADOProject {
  [CmdletBinding(SupportsShouldProcess)]
  param(
    [Parameter(Mandatory = $true, HelpMessage = "Azure DevOps organization URL")]
    [ValidateNotNullOrEmpty()]
    [string]$AdoOrganization,

    [Parameter(Mandatory = $true, HelpMessage = "Azure DevOps project name")]
    [ValidateNotNullOrEmpty()]
    [string]$AdoProject,

    [Parameter(Mandatory = $false, HelpMessage = "Azure DevOps project name")]
    [ValidateNotNullOrEmpty()]
    [string]$ControlPlaneCode,

    [Parameter(Mandatory = $true, HelpMessage = "Authentication method to use")]
    [ValidateSet("Service Principal", "Managed Identity")]
    [string]$AuthenticationMethod,

    [Parameter(HelpMessage = "Enable Web Application for configuration management")]
    [switch]$EnableWebApp,

    [Parameter(HelpMessage = "Web Application Name for configuration management")]
    [ValidateLength(1, 100)]
    [string]$WebAppName,

    [Parameter(HelpMessage = "Agent pool name to use for the project")]
    [ValidateLength(1, 100)]
    [string]$AgentPoolName = ""

  )

  begin {
    Write-Verbose "Starting Remove-SDAFADOProject cmdlet"
    Write-Verbose "Parameters received:"
    Write-Verbose "  AdoOrganization: $AdoOrganization"
    Write-Verbose "  AdoProject: $AdoProject"
    Write-Verbose "  ControlPlaneCode: $ControlPlaneCode"
    Write-Verbose "  Agent pool name: $AgentPoolName"
    Write-Verbose "  Web app enabled: $EnableWebApp"
  }

  process {
    try {
      Write-Verbose "Beginning main processing"

      #region Initialize variables
      Write-Verbose "Initializing variables from parameters"
      $VersionLabel = "v3.16.0.2"
      Write-Verbose "Version label set to: $VersionLabel"
      #endregion

      $ControlPlanePrefix = "SDAF-" + $ControlPlaneCode
      Write-Verbose "Control plane prefix: $ControlPlanePrefix"

      $ApplicationName = ""
      if ($EnableWebApp) {
        $ApplicationName = $ControlPlanePrefix + "-configuration-app"
        if ($Env:SDAF_APP_NAME.Length -ne 0) {
          $ApplicationName = $Env:SDAF_APP_NAME
        }
      }

      if ($EnableWebApp) {
        Write-Verbose "  Application name: $ApplicationName"
      }

      #region Install DevOps extensions
      Write-Host "Installing the DevOps extensions" -ForegroundColor Green
      Write-Verbose "Checking for Post Build Cleanup extension"
      az config set extension.use_dynamic_install=yes_without_prompt --only-show-errors

      $ExtensionName = (az devops extension list --organization $AdoOrganization --query "[?extensionName=='Post Build Cleanup'].extensionName | [0]")

      if ($ExtensionName.Length -eq 0) {
        Write-Verbose "Installing Post Build Cleanup extension"
        if ($PSCmdlet.ShouldProcess("DevOps Organization", "Install Post Build Cleanup Extension")) {
          az devops extension install --organization $AdoOrganization --extension PostBuildCleanup --publisher-id mspremier --output none
        }
      }
      else {
        Write-Verbose "Post Build Cleanup extension already installed"
      }
      #endregion

      #region Authentication and PAT handling
      Write-Verbose "Handling Personal Access Token authentication"

      if ($Env:AZURE_DEVOPS_EXT_PAT.Length -gt 0) {
        Write-Host "Using the provided Personal Access Token (PAT) to authenticate to the Azure DevOps organization $AdoOrganization" -ForegroundColor Yellow
        Write-Verbose "Using PAT from environment variable"
      }

      Write-Verbose "Testing PAT authentication"
      $CheckPersonalAccessToken = (az devops user list --organization $AdoOrganization --only-show-errors --top 1)
      if ($CheckPersonalAccessToken.Length -eq 0) {
        Write-Verbose "PAT authentication failed, prompting for new PAT"
        $env:AZURE_DEVOPS_EXT_PAT = Read-Host "Please enter your Personal Access Token (PAT) with full access to the Azure DevOps organization $AdoOrganization"
        $VerifyPersonalAccessToken = (az devops user list --organization $AdoOrganization --only-show-errors --top 1)
        if ($VerifyPersonalAccessToken.Length -eq 0) {
          Write-Error "Failed to authenticate to the Azure DevOps organization"
          Read-Host -Prompt "Failed to authenticate to the Azure DevOps organization, press <any key> to exit"
          return
        }
        else {
          Write-Host "Successfully authenticated to the Azure DevOps organization $AdoOrganization" -ForegroundColor Green
          Write-Verbose "PAT authentication successful"
        }
      }
      else {
        Write-Host "Successfully authenticated to the Azure DevOps organization $AdoOrganization" -ForegroundColor Green
        Write-Verbose "Existing PAT authentication verified"
      }
      #endregion

      Write-Host ""


      #region Validate organization and control plane code
      Write-Host "Using Organization: $AdoOrganization" -foregroundColor Yellow
      Write-Verbose "ADO Organization validated: $AdoOrganization"


      #region Remove DevOps project
      $ProjectId = (az devops project list --organization $AdoOrganization --query "[value[]] | [0] | [? name=='$AdoProject'].id | [0]" --out tsv)

      if ($AgentPoolName.Length -ne 0) {

        $AgentPoolId = (az pipelines pool list --query "[?name=='$AgentPoolName'].id | [0]")
        if ($AgentPoolId.Length -gt 0) {
          Write-Host "Agent pool" $AgentPoolName "found" -ForegroundColor Yellow

          $accessToken = az account get-access-token --resource 499b84ac-1321-427f-aa17-267ca6975798 --query "accessToken" --output tsv
          $headers = @{
            Accept        = "application/json"
            Authorization = "Bearer $accessToken"
          }


          $DevOpsRestUrl = $AdoOrganization + "/_apis/distributedtask/pools/" + $AgentPoolId.ToString() + "?api-version=7.1"

          $response = Invoke-RestMethod -Method DELETE -Uri $DevOpsRestUrl -Headers $headers -ContentType "application/json"
          Write-Verbose "Response from DevOps REST API: $response"
          Write-Verbose "Agent pool $AgentPoolName removed successfully"
        }
      }


      if ($ProjectId.Length -ne 0) {
        Write-Host "Removing the project: " $AdoProject -ForegroundColor Green
        az devops project delete --id $ProjectId --only-show-errors
      }
      else {
      }

      if ($AuthenticationMethod -eq "Service Principal") {
        #region Service Principal
        $ServicePrincipalName = $ControlPlanePrefix + " Deployment credential"
        if ($Env:SDAF_MGMT_ServicePrincipalName.Length -ne 0) {
          $ServicePrincipalName = $Env:SDAF_MGMT_ServicePrincipalName
        }

        $ServicePrincipalId = (az ad sp list --all --filter "startswith(displayName, '$ServicePrincipalName')" --query "[?displayName=='$ServicePrincipalName'].id | [0]" --only-show-errors)
        if ($ServicePrincipalId.Length -gt 0) {
          Write-Host "Found an existing Service Principal:" $ServicePrincipalName

          $confirmation = Read-Host "Remove control plane service principal y/n?"
          if ($confirmation -eq 'y') {
            Write-Host "Removing the Service Principal:" $ServicePrincipalName -ForegroundColor Green
            az ad sp delete --id $ServicePrincipalId --only-show-errors
          }
          else {
            Write-Host "Skipping removal of Service Principal" $ServicePrincipalName -ForegroundColor Yellow
          }

        }
        else {
          Write-Host "No Service Principal found for: $ServicePrincipalName" -ForegroundColor Yellow
        }
      }


      $FoundAppRegistration = (az ad app list --all --filter "startswith(displayName, '$ApplicationName')" --query  "[?displayName=='$ApplicationName'].id | [0]" --only-show-errors)
      if ($FoundAppRegistration.Length -ne 0) {
        $confirmation = Read-Host "Remove App registration y/n?"
        if ($confirmation -eq 'y') {
          Write-Host "Removing the App Registration: $ApplicationName" -ForegroundColor Green
          az ad app delete --id $FoundAppRegistration
        }
        else {
          Write-Host "Skipping removal of App registration" $ServicePrincipalName -ForegroundColor Yellow
        }
      }
      else {
        Write-Host "No App Registration found for: $ApplicationName" -ForegroundColor Yellow
      }
      #endregion

      Write-Host "The script has completed" -ForegroundColor Green
      Write-Verbose "New-SDAFADOProject cmdlet completed successfully"

    }
    catch {
      Write-Error "An error occurred during execution: $($_.Exception.Message)"
      Write-Verbose "Error details: $($_.Exception.ToString())"
      throw
    }
  }

  end {
    Write-Verbose "Remove-SDAFADOProject cmdlet finished"
  }
}

# Export the function
Export-ModuleMember -Function Remove-SDAFADOProject
