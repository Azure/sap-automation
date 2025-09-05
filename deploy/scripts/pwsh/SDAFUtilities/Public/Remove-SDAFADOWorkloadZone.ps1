#Requires -Version 5.1

<#
.SYNOPSIS
    Removes a new SDAF (SAP Deployment Automation Framework) Azure DevOps project with all necessary resources.

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

.PARAMETER WorkloadZoneCode
    The workload zone code identifier (e.g., MGMT).

.PARAMETER AuthenticationMethod
    The authentication method to use (Service Principal or Managed Identity).

 EXAMPLE
    Remove-SDAFADOWorkloadZone -AdoOrganization "https://dev.azure.com/myorg" -AdoProject "SAP-SDAF" -TenantId "12345678-1234-1234-1234-123456789012" -WorkloadZoneCode "MGMT" -AuthenticationMethod "Service Principal" -Verbose

.NOTES
    Author: GitHub Copilot
    Requires: Azure CLI with DevOps extension
    Copyright (c) Microsoft Corporation.
    Licensed under the MIT License.
#>
function Remove-SDAFADOWorkloadZone {
  [CmdletBinding(SupportsShouldProcess)]
  param(
    # Common parameters
    [Parameter(Mandatory = $true, HelpMessage = "Azure DevOps organization URL")]
    [ValidateScript({ $_ -match '^https://dev\.azure\.com/[^/]+/?$' })]
    [string]$AdoOrganization,

    [Parameter(Mandatory = $true, HelpMessage = "Azure DevOps project name")]
    [ValidateLength(1, 64)]
    [ValidatePattern('^[a-zA-Z0-9][a-zA-Z0-9 ._-]*[a-zA-Z0-9]$')]
    [string]$AdoProject,

    [Parameter(Mandatory = $true, HelpMessage = "Workload zone code (e.g., DEV)")]
    [ValidateLength(2, 8)]
    [ValidatePattern('^[A-Z0-9]+$')]
    [string]$WorkloadZoneCode,

    [Parameter(Mandatory = $true, HelpMessage = "Authentication method to use")]
    [ValidateSet("Service Principal", "Managed Identity")]
    [string]$AuthenticationMethod

  )

  begin {
    Write-Verbose "Starting Remove-SDAFADOWorkloadZone cmdlet"
    Write-Verbose "Parameters received:"
    Write-Verbose "  AdoOrganization: $AdoOrganization"
    Write-Verbose "  AdoProject: $AdoProject"
    Write-Verbose "  AuthenticationMethod: $AuthenticationMethod"
    Write-Verbose "  WorkloadZoneCode: $WorkloadZoneCode"

    # Initialize error tracking
    $ErrorActionPreference = 'Stop'
    $script:DeploymentErrors = @()
    $script:OperationLog = @()

    # Helper function for menu display
    function Show-Menu($data) {
      Write-Host "================ $Title ================"
      $i = 1
      foreach ($d in $data) {
        Write-Host "($i): Select '$i' for $($d)"
        $i++
      }
      Write-Host "q: Select 'q' for Exit"
    }
    function SetVariableGroupVariable {
      param(
        [Parameter(Mandatory = $true)]
        [string]$VariableGroupId,

        [Parameter(Mandatory = $true)]
        [string]$VariableName,

        [Parameter(Mandatory = $true)]
        [string]$VariableValue,

        [Parameter(Mandatory = $false)]
        [switch]$IsSecret
      )
      Write-Verbose "Setting variable '$VariableName' in variable group '$VariableGroupId' with value '$VariableValue' (IsSecret: $IsSecret)"
      $value = (az pipelines variable-group variable list --group-id $VariableGroupId --query "$VariableName.value" --out tsv)
      if ($null -eq $value) {
        Write-Verbose "Variable '$VariableName' does not exist in variable group '$VariableGroupId'. Adding new variable."
        az pipelines variable-group variable create --group-id $VariableGroupId --name $VariableName --value $VariableValue --output none --secret $IsSecret
      }
      else {
        Write-Verbose "Variable '$VariableName' already exists in variable group '$VariableGroupId'. Updating value."
        az pipelines variable-group variable update --group-id $VariableGroupId --name $VariableName --value $VariableValue --output none --secret $IsSecret
      }
    }

  }
  process {
    try {
      Write-Verbose "Beginning main processing"

      #region Initialize variables
      Write-Verbose "Initializing variables from parameters"
      $ArmTenantId = $TenantId
      $WorkloadZoneSubscriptionIdInternal = $WorkloadZoneSubscriptionId
      $VersionLabel = "v3.16.0.2"
      Write-Verbose "Version label set to: $VersionLabel"

      # Set path separator based on OS
      if ($IsWindows) {
        $PathSeparator = "\"
      }
      else {
        $PathSeparator = "/"
      }
      Write-Verbose "Path separator set to: $PathSeparator"


      #endregion

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
      $PersonalAccessToken = 'Enter your personal access token here'

      if ($Env:AZURE_DEVOPS_EXT_PAT.Length -gt 0) {
        Write-Host "Using the provided Personal Access Token (PAT) to authenticate to the Azure DevOps organization $AdoOrganization" -ForegroundColor Yellow
        Write-Verbose "Using PAT from environment variable"
        $PersonalAccessToken = $Env:AZURE_DEVOPS_EXT_PAT
        $CreatePAT = $false
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
      Write-Host "Using authentication method: $AuthenticationMethod" -ForegroundColor Yellow
      Write-Verbose "Authentication method selected: $AuthenticationMethod"

      #region Validate organization and workload zone code
      Write-Host "Using Organization: $AdoOrganization" -foregroundColor Yellow
      Write-Verbose "ADO Organization validated: $AdoOrganization"

      Write-Host "Using Workload zone code: $WorkloadZoneCode" -foregroundColor Yellow
      Write-Verbose "Workload zone code validated: $WorkloadZoneCode"
      #endregion

      #region Set up prefixes
      $WorkloadZonePrefix = "SDAF-" + $WorkloadZoneCode
      Write-Verbose "Workload zone prefix: $WorkloadZonePrefix"

      #endregion


      $ProjectId = (az devops project list --organization $AdoOrganization --query "[value[]] | [0] | [? name=='$AdoProject'].id | [0]" --out tsv)

      if ($ProjectId.Length -eq 0) {
        Write-Error "Project $AdoProject was not found in the Azure DevOps organization $AdoOrganization"
        throw "Project not found"
      }

      $ServiceConnectionName = $WorkloadZoneCode + "_WorkloadZone_Service_Connection"

      $ServiceConnectionId = (az devops service-endpoint list --query "[?name=='$ConnectionName'].id | [0]" --project $ProjectId --out tsv)
      if ($ServiceConnectionId.Length -gt 0) {
        Write-Host "Service Connection" $ServiceConnectionName "exists, removing it." -ForegroundColor Yellow
        az devops service-endpoint delete --id $ServiceConnectionId --only-show-errors
      }
      else {
        Write-Host "Service Connection" $ServiceConnectionName "not found, skipping removal."

      }

      $WorkloadZoneVariableGroupId = (az pipelines variable-group list --query "[?name=='$WorkloadZonePrefix'].id | [0]" --only-show-errors)
      if ($WorkloadZoneVariableGroupId.Length -ne 0) {
        Write-Host "Removing the variable group" $WorkloadZonePrefix -ForegroundColor Yellow
        az pipelines variable-group delete --id $WorkloadZoneVariableGroupId  --only-show-errors
      }


      if ($AuthenticationMethod -eq "Service Principal") {
        #region Workload zone Service Principal
        $ServicePrincipalName = $WorkloadZonePrefix + " Deployment credential"
        if ($Env:SDAF_MGMT_ServicePrincipalName.Length -ne 0) {
          $ServicePrincipalName = $Env:SDAF_MGMT_ServicePrincipalName
        }


        $ServicePrincipalId = (az ad sp list --all --filter "startswith(displayName, '$ServicePrincipalName')" --query "[?displayName=='$ServicePrincipalName'].id | [0]" --only-show-errors)
        if ($ServicePrincipalId.Length -gt 0) {
          Write-Host "Found an existing Service Principal:" $ServicePrincipalName

          $confirmation = Read-Host "Remove  Workload zone Service Principal y/n?"
          if ($confirmation -eq 'y') {
            Write-Host "Removing the Service Principal:" $ServicePrincipalName -ForegroundColor Green
            az ad sp delete --id $ServicePrincipalId --only-show-errors
          }
          else {
            Write-Host "Skipping removal of Service Principal" $ServicePrincipalName -ForegroundColor Yellow

          }

        }
      }

      Write-Host "The script has completed" -ForegroundColor Green
      Write-Verbose "Remove-SDAFADOWorkloadZone cmdlet completed successfully"

    }
    catch {
      Write-Error "An error occurred during execution: $($_.Exception.Message)"
      Write-Verbose "Error details: $($_.Exception.ToString())"
      throw
    }
  }

  end {
    Write-Verbose "Remove-SDAFADOWorkloadZone cmdlet finished"
  }
}

# Export the function
Export-ModuleMember -Function Remove-SDAFADOWorkloadZone
