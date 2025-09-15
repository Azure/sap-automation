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

.PARAMETER TenantId
    The Azure Active Directory tenant ID.

.PARAMETER ControlPlaneCode
    The control plane code identifier (e.g., MGMT).

.PARAMETER ControlPlaneSubscriptionId
    The subscription ID for the control plane resources.

.PARAMETER AgentPoolName
    The name of the agent pool to create or use.

.PARAMETER AuthenticationMethod
    The authentication method to use (Service Principal or Managed Identity).

.PARAMETER ManagedIdentityObjectId
    The object ID of the managed identity (required for Managed Identity authentication).

.PARAMETER CreateConnections
    Switch to create service connections automatically.

.PARAMETER ShouldImportCodeFromGitHub
    Switch to import code repositories from GitHub.

.PARAMETER CreatePAT
    Switch to prompt for Personal Access Token creation.

.PARAMETER EnableWebApp
    Switch to enable the creation of a web application for configuration management.

.PARAMETER WebAppName
    The name of the web application to create for configuration management (if EnableWebApp is set).

.PARAMETER ServiceManagementReference
    The service management reference for the project (optional).

.PARAMETER BranchName
    The branch name for the project repositories (default is "main").

.PARAMETER GitHubRepoName
    The GitHub repository name for the project (default is "Azure/sap-automation").

 EXAMPLE
    New-SDAFADOProject -AdoOrganization "https://dev.azure.com/myorg" -AdoProject "SAP-SDAF" -TenantId "12345678-1234-1234-1234-123456789012" -ControlPlaneCode "MGMT" -ControlPlaneSubscriptionId "87654321-4321-4321-4321-210987654321" -AgentPoolName "SDAF-MGMT-POOL" -AuthenticationMethod "Service Principal" -Verbose

.NOTES
    Author: GitHub Copilot
    Requires: Azure CLI with DevOps extension
    Copyright (c) Microsoft Corporation.
    Licensed under the MIT License.
#>
function New-SDAFADOProject {
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

    [Parameter(Mandatory = $true, HelpMessage = "Azure AD tenant ID")]
    [ValidateScript({ [System.Guid]::TryParse($_, [ref][System.Guid]::Empty) })]
    [string]$TenantId,

    [Parameter(Mandatory = $true, HelpMessage = "Control plane code (e.g., MGMT)")]
    [ValidateLength(2, 8)]
    [ValidatePattern('^[A-Z0-9]+$')]
    [string]$ControlPlaneCode,

    [Parameter(Mandatory = $true, HelpMessage = "Control plane subscription ID")]
    [ValidateScript({ [System.Guid]::TryParse($_, [ref][System.Guid]::Empty) })]
    [string]$ControlPlaneSubscriptionId,

    [Parameter(Mandatory = $true, HelpMessage = "Authentication method to use")]
    [ValidateSet("Service Principal", "Managed Identity")]
    [string]$AuthenticationMethod,

    # Service Principal specific parameters
    [Parameter(ParameterSetName = "ServicePrincipal", Mandatory = $false)]
    [string]$ServicePrincipalClientId,

    [Parameter(ParameterSetName = "ServicePrincipal", Mandatory = $false)]
    [SecureString]$ServicePrincipalSecret,

    # Managed Identity specific parameters
    [Parameter(ParameterSetName = "ManagedIdentity", Mandatory = $false)]
    [ValidateScript({ [System.Guid]::TryParse($_, [ref][System.Guid]::Empty) })]
    [string]$ManagedIdentityObjectId,

    # Optional parameters
    [Parameter(HelpMessage = "Agent Pool Name")]
    [ValidateLength(1, 100)]
    [string]$AgentPoolName,

    # Switch parameters
    [Parameter(HelpMessage = "Create service connections automatically")]
    [switch]$CreateConnections,

    [Parameter(HelpMessage = "Import code from GitHub repositories")]
    [switch]$ShouldImportCodeFromGitHub,

    [Parameter(HelpMessage = "Enable Web Application for configuration management")]
    [switch]$EnableWebApp,

    [Parameter(HelpMessage = "Web Application Name for configuration management")]
    [ValidateLength(1, 100)]
    [string]$WebAppName,

    [Parameter(HelpMessage = "Service Management Reference")]
    [string]$ServiceManagementReference = "",

    [Parameter(Mandatory = $false, HelpMessage = "Branch name for the project repositories")]
    [string]$BranchName = "main",

    [Parameter(Mandatory = $false, HelpMessage = "GitHub repository name for the project")]
    [string]$GitHubRepoName = "Azure/sap-automation"

  )

  begin {
    Write-Verbose "Starting New-SDAFADOProject cmdlet"
    Write-Verbose "Parameters received:"
    Write-Verbose "  AdoOrganization: $AdoOrganization"
    Write-Verbose "  AdoProject: $AdoProject"
    Write-Verbose "  TenantId: $TenantId"
    Write-Verbose "  AuthenticationMethod: $AuthenticationMethod"
    Write-Verbose "  ManagedIdentityObjectId: $ManagedIdentityObjectId"
    Write-Verbose "  ControlPlaneCode: $ControlPlaneCode"
    Write-Verbose "  ControlPlaneSubscriptionId: $ControlPlaneSubscriptionId"
    Write-Verbose "  AgentPoolName: $AgentPoolName"
    Write-Verbose "  CreateConnections: $CreateConnections"
    Write-Verbose "  ShouldImportCodeFromGitHub: $ShouldImportCodeFromGitHub"
    Write-Verbose "  CreatePAT: $CreatePAT"
    Write-Verbose "  EnableWebApp: $EnableWebApp"
    Write-Verbose "  WebAppName: $WebAppName"
    Write-Verbose "  ServiceManagementReference: $ServiceManagementReference"

    # Initialize error tracking
    $ErrorActionPreference = 'Stop'
    $script:DeploymentErrors = @()
    $script:OperationLog = @()


    $Repositories = @{
      Bootstrap  = "https://github.com/Azure/SAP-automation-bootstrap"
      Automation = "https://github.com/Azure/SAP-automation"
      Samples    = "https://github.com/Azure/SAP-automation-samples"
    }

    $Roles = @(
      "Contributor",
      "Role Based Access Control Administrator",
      "Storage Blob Data Owner",
      "Key Vault Administrator",
      "App Configuration Data Owner"
    )

    $Pipelines = @(
      @{ Name = "Create Control Plane configuration"; Description = "Create sample configuration"; YamlPath = "/pipelines/22-sample-deployer-configuration.yml" },
      @{ Name = "Deploy Control plane"; Description = "Deploys the control plane"; YamlPath = "/pipelines/01-deploy-control-plane.yml" },
      @{ Name = "Deploy Workload Zone"; Description = "Deploys the workload zone"; YamlPath = "/pipelines/02-sap-workload-zone.yml" },
      @{ Name = "SAP SID Infrastructure deployment"; Description = "Deploys the infrastructure required for a SAP SID deployment"; YamlPath = "/pipelines/03-sap-system-deployment.yml" },
      @{ Name = "SAP Software acquisition"; Description = "Downloads the software from SAP"; YamlPath = "/pipelines/04-sap-software-download.yml" },
      @{ Name = "Configuration and SAP installation"; Description = "Configures the Operating System and installs the SAP application"; YamlPath = "/pipelines/05-DB-and-SAP-installation.yml" },
      @{ Name = "SAP installation using SAP-CAL"; Description = "Configures the Operating System and installs the SAP application using SAP CAL"; YamlPath = "/pipelines/07-sap-cal-installation.yml" },
      @{ Name = "Remove System or Workload Zone"; Description = "Removes either the SAP system or the workload zone"; YamlPath = "/pipelines/10-remover-terraform.yml" },
      @{ Name = "Remove deployments via ARM"; Description = "Removes the resource groups via ARM. Use this only as last resort"; YamlPath = "/pipelines/11-remover-arm-fallback.yml" },
      @{ Name = "Remove control plane"; Description = "Removes the control plane"; YamlPath = "/pipelines/12-remove-control-plane.yml" },
      @{ Name = "Update Pipelines"; Description = "Updates the pipelines"; YamlPath = "/pipelines/21-update-pipelines.yml" }
    )
    # Logging function
    function Write-OperationLog {
      param(
        [Parameter(Mandatory)]
        [string]$Message,

        [Parameter()]
        [ValidateSet('Info', 'Warning', 'Error', 'Success')]
        [string]$Level = 'Info',

        [Parameter()]
        [string]$Component = 'Main'
      )

      $logEntry = [PSCustomObject]@{
        Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        Level     = $Level
        Component = $Component
        Message   = $Message
      }

      $script:OperationLog += $logEntry

      switch ($Level) {
        'Info' { Write-Verbose "[$Component] $Message" }
        'Warning' { Write-Warning "[$Component] $Message" }
        'Error' { Write-Error "[$Component] $Message" }
        'Success' { Write-Host "[$Component] $Message" -ForegroundColor Green }
      }
    }

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

    # Helper function to add pipelines
    function AddPipeline {
      param(
        [string]$PipelineName,
        [string]$Description,
        [string]$YamlName,
        [string]$LogFile
      )
      Write-Host "Adding pipeline: $PipelineName"

      $PipelineId = (az pipelines list --query "[?name=='$PipelineName'].id | [0]")
      if ($PipelineId.Length -eq 0) {
        az pipelines create --name $PipelineName --branch main --description $Description --skip-run --yaml-path $YamlName --repository $RepositoryId --repository-type tfsgit --output none --only-show-errors
        $PipelineId = (az pipelines list --query "[?name=='$PipelineName'].id | [0]")
      }
      $ThisPipelineUrl = $AdoOrganization + "/" + [uri]::EscapeDataString($AdoProject) + "/_build?definitionId=" + $PipelineId
      $LogEntry = ("[" + $PipelineName + "](" + $ThisPipelineUrl + ")")
      Add-Content -Path $LogFile -Value $LogEntry
      Write-Verbose "Pipeline: $PipelineName ($PipelineId)"

      return $PipelineId
    }

    function CreateServiceConnection {
      param(
        [string]$ConnectionName,
        [string]$ServiceConnectionDescription,
        [string]$TenantId,
        [string]$ManagedIdentityObjectId,
        [string]$SubscriptionId,
        [string]$ProjectId,
        [string]$ProjectName

      )

      $ServiceConnectionExists = (az devops service-endpoint list --query "[?name=='$ConnectionName'].name | [0]"  --out tsv)
      if ($ServiceConnectionExists.Length -ne 0) {
        Write-Host "Service connection '$ConnectionName' already exists, skipping creation." -ForegroundColor Yellow
        return
      }
      $JsonInputFile = "sdafMI.json"

      $ManagedIdentityClientId = (az ad sp show --id $ManagedIdentityObjectId --query appId --output tsv)

      $PostBody = [PSCustomObject]@{
        authorization                    = [PSCustomObject]@{
          parameters = [PSCustomObject]@{
            tenantid                             = $TenantId
            workloadIdentityFederationIssuerType = "EntraID"
            serviceprincipalid                   = $ManagedIdentityClientId
            scope                                = "/subscriptions/" + $SubscriptionId

          }
          scheme     = "WorkloadIdentityFederation"
        }
        data                             = [PSCustomObject]@{
          environment      = "AzureCloud"
          scopeLevel       = "Subscription"
          subscriptionId   = $SubscriptionId
          subscriptionName = (az account show --query name -o tsv)
          creationMode     = "Automatic"
          identityType     = "ManagedIdentity"
        }
        name                             = $ConnectionName
        owner                            = "library"
        type                             = "azurerm"
        url                              = "https://management.azure.com/"
        description                      = $ServiceConnectionDescription
        serviceEndpointProjectReferences = [PSCustomObject]@{
          name             = $ConnectionName
          description      = $ServiceConnectionDescription
          projectReference = [PSCustomObject]@{
            id   = $ProjectId
            name = $ProjectName
          }
        }
      }
      Set-Content -Path $JsonInputFile -Value ($PostBody | ConvertTo-Json -Depth 6)

      Write-Verbose "Creating service connection: $ConnectionName"
      az devops service-endpoint create --service-endpoint-configuration $JsonInputFile --organization $AdoOrganization --project $AdoProject --output none --only-show-errors
      Write-Host "Service connection '$ConnectionName' created successfully." -ForegroundColor Green

      if (Test-Path $JsonInputFile) {
        Remove-Item $JsonInputFile
      }
    }

    function UpdateAdoRepositoryReferences {
      param(
        [string]$RepositoryId,
        [string]$AdoProject,
        [string]$RepositoryName
      )

      Write-Host "Updating repository references for $RepositoryName in project $AdoProject" -ForegroundColor Green

      Write-Host "Using a non standard DevOps project name, need to update some of the parameter files" -ForegroundColor Green

      $ObjectId = (az devops invoke --area git --resource refs --route-parameters project=$AdoProject repositoryId=$RepositoryId --query-parameters filter=heads/main --query value[0] | ConvertFrom-Json).objectId

      $TemplateFileName = "resources.yml"
      if (Test-Path $TemplateFileName) {
        Remove-Item $TemplateFileName
      }

      # Create updated resources.yml content
      $ResourcesContent = @"
parameters:
  - name: stages
    type: stageList
    default: []

stages:
  - `${{ parameters.stages }}

resources:
  repositories:
    - repository: sap-automation
      type: git
      name: $AdoProject/sap-automation
      ref: refs/heads/main
"@

      Set-Content -Path $TemplateFileName -Value $ResourcesContent

      $FileContent = Get-Content -Path $TemplateFileName -Raw

      $JsonInputFile = "sdaf.json"

      $PostBody = [PSCustomObject]@{
        refUpdates = @(@{
            name        = "refs/heads/main"
            oldObjectId = $ObjectId
          })
        commits    = @(@{
            comment = "Updated repository.yml"
            changes = @(@{
                changetype = "edit"
                item       = @{path = "/pipelines/resources.yml" }
                newContent = @{
                  content     = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes($FileContent))
                  contentType = "base64Encoded"
                }
              })
          })
      }

      Set-Content -Path $JsonInputFile -Value ($PostBody | ConvertTo-Json -Depth 6)

      az devops invoke `
        --area git --resource pushes `
        --route-parameters project=$AdoProject repositoryId=$RepositoryId `
        --http-method POST --in-file $JsonInputFile `
        --api-version "6.0" --output none

      Remove-Item $TemplateFileName

      # Create resources_including_samples.yml
      $TemplateFileName = "resources_including_samples.yml"
      $ResourcesSamplesContent = @"
parameters:
  - name: stages
    type: stageList
    default: []

stages:
  - `${{ parameters.stages }}

resources:
  repositories:
    - repository: sap-automation
      type: git
      name: $AdoProject/sap-automation
      ref: refs/heads/main
    - repository: sap-samples
      type: git
      name: $AdoProject/sap-samples
      ref: refs/heads/main
"@

      Set-Content -Path $TemplateFileName -Value $ResourcesSamplesContent

      $ObjectId = (az devops invoke --area git --resource refs --route-parameters project=$AdoProject repositoryId=$RepositoryId --query-parameters filter=heads/main --query value[0] | ConvertFrom-Json).objectId

      Remove-Item $JsonInputFile
      $FileContent2 = Get-Content -Path $TemplateFileName -Raw

      $PostBody = [PSCustomObject]@{
        refUpdates = @(@{
            name        = "refs/heads/main"
            oldObjectId = $ObjectId
          })
        commits    = @(@{
            comment = "Updated resources_including_samples.yml"
            changes = @(@{
                changetype = "edit"
                item       = @{path = "/pipelines/resources_including_samples.yml" }
                newContent = @{
                  content     = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes($FileContent2))
                  contentType = "base64Encoded"
                }
              })
          })
      }

      Set-Content -Path $JsonInputFile -Value ($PostBody | ConvertTo-Json -Depth 6)

      az devops invoke `
        --area git --resource pushes `
        --route-parameters project=$AdoProject repositoryId=$RepositoryId `
        --http-method POST --in-file $JsonInputFile `
        --api-version "6.0" --output none

      if (Test-Path $TemplateFileName) {
        Remove-Item $TemplateFileName
      }
    }
    function UpdateGitHubRepositoryReferences {
      param(
        [string]$RepositoryId,
        [string]$AdoProject,
        [string]$GitHubConnection,
        [string]$BranchName,
        [string]$GitHubRepoName
      )


      # Update resources files with GitHub connection
      $ObjectId = (az devops invoke --area git --resource refs --route-parameters project=$AdoProject repositoryId=$RepositoryId --query-parameters filter=heads/main --query value[0] | ConvertFrom-Json).objectId

      # Create GitHub-based resources.yml
      $TemplateFileName = "resources.yml"
      if (Test-Path $TemplateFileName) {
        Remove-Item $TemplateFileName
      }

      $GitHubResourcesContent = @"
parameters:
  - name: stages
    type: stageList
    default: []

stages:
  - `${{ parameters.stages }}

resources:
  repositories:
    - repository: sap-automation
      type: GitHub
      endpoint: $GitHubConnection
      name: $GitHubRepoName
      ref: refs/heads/$BranchName
"@

      Set-Content -Path $TemplateFileName -Value $GitHubResourcesContent
      $FileContent = Get-Content -Path $TemplateFileName -Raw

      $JsonInputFile = "sdaf.json"
      $PostBody = [PSCustomObject]@{
        refUpdates = @(@{
            name        = "refs/heads/main"
            oldObjectId = $ObjectId
          })
        commits    = @(@{
            comment = "Updated repository.yml"
            changes = @(@{
                changetype = "edit"
                item       = @{path = "/pipelines/resources.yml" }
                newContent = @{
                  content     = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes($FileContent))
                  contentType = "base64Encoded"
                }
              })
          })
      }

      Set-Content -Path $JsonInputFile -Value ($PostBody | ConvertTo-Json -Depth 6)

      az devops invoke `
        --area git --resource pushes `
        --route-parameters project=$AdoProject repositoryId=$RepositoryId `
        --http-method POST --in-file $JsonInputFile `
        --api-version "6.0" --output none

      if (Test-Path $TemplateFileName) {
        Remove-Item $TemplateFileName
      }

      # Create GitHub-based resources_including_samples.yml
      $TemplateFileName = "resources_including_samples.yml"
      $GitHubSamplesContent = @"
parameters:
  - name: stages
    type: stageList
    default: []

stages:
  - `${{ parameters.stages }}

resources:
  repositories:
    - repository: sap-automation
      type: GitHub
      endpoint: $GitHubConnection
      name: $GitHubRepoName
      ref: refs/heads/$BranchName
    - repository: sap-samples
      type: GitHub
      endpoint: $GitHubConnection
      name: Azure/sap-automation-samples
      ref: refs/heads/main
"@

      Set-Content -Path $TemplateFileName -Value $GitHubSamplesContent
      $FileContent2 = Get-Content -Path $TemplateFileName -Raw

      $ObjectId = (az devops invoke --area git --resource refs --route-parameters project=$AdoProject repositoryId=$RepositoryId --query-parameters filter=heads/main --query value[0] | ConvertFrom-Json).objectId

      Remove-Item $JsonInputFile

      $PostBody = [PSCustomObject]@{
        refUpdates = @(@{
            name        = "refs/heads/main"
            oldObjectId = $ObjectId
          })
        commits    = @(@{
            comment = "Updated resources_including_samples.yml"
            changes = @(@{
                changetype = "edit"
                item       = @{path = "/pipelines/resources_including_samples.yml" }
                newContent = @{
                  content     = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes($FileContent2))
                  contentType = "base64Encoded"
                }
              })
          })
      }

      Set-Content -Path $JsonInputFile -Value ($PostBody | ConvertTo-Json -Depth 6)

      az devops invoke `
        --area git --resource pushes `
        --route-parameters project=$AdoProject repositoryId=$RepositoryId `
        --http-method POST --in-file $JsonInputFile `
        --api-version "6.0" --output none

      if (Test-Path $TemplateFileName) {
        Remove-Item $TemplateFileName
      }
      Remove-Item $JsonInputFile
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
      if ( $VariableValue.Length -gt 0 ) {
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
      else {
        Write-Verbose "Variable '$VariableName' is empty, skipping setting variable in group '$VariableGroupId'."
      }
    }
  }
  process {
    try {
      Write-Verbose "Beginning main processing"

      #region Initialize variables
      Write-Verbose "Initializing variables from parameters"
      $ArmTenantId = $TenantId
      $ControlPlaneSubscriptionIdInternal = $ControlPlaneSubscriptionId
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
      Write-Host ""

      # Clean up any existing start.md file
      if (Test-Path ".${PathSeparator}start.md") {
        Write-Verbose "Removing existing start.md file"
        Remove-Item ".${PathSeparator}start.md"
      }

      Write-Host "Using authentication method: $AuthenticationMethod" -ForegroundColor Yellow
      Write-Verbose "Authentication method selected: $AuthenticationMethod"

      #region Validate and set subscription
      Write-Verbose "Validating control plane subscription"
      if ($ControlPlaneSubscriptionIdInternal.Length -eq 0) {
        Write-Host "Control plane subscription ID is not set!" -ForegroundColor Red
        $Title = "Choose the subscription for the Control Plane"
        $Subscriptions = $(az account list --query "[].{Name:name}" -o table | Sort-Object)
        Show-Menu($Subscriptions[2..($Subscriptions.Length - 1)])

        $Selection = Read-Host $Title
        $SelectionOffset = [convert]::ToInt32($Selection, 10) + 1
        $ControlPlaneSubscriptionName = $Subscriptions[$SelectionOffset]

        az account set --subscription $ControlPlaneSubscriptionName
        $ControlPlaneSubscriptionIdInternal = (az account show --query id -o tsv)
      }
      else {
        Write-Verbose "Setting subscription to: $ControlPlaneSubscriptionIdInternal"
        az account set --sub $ControlPlaneSubscriptionIdInternal
        $ControlPlaneSubscriptionName = (az account show --query name -o tsv)
      }

      if ($ControlPlaneSubscriptionName.Length -eq 0) {
        Write-Error "ControlPlaneSubscriptionName is not set"
        return
      }
      Write-Verbose "Using subscription: $ControlPlaneSubscriptionName ($ControlPlaneSubscriptionIdInternal)"
      #endregion

      #region Validate organization and control plane code
      Write-Host "Using Organization: $AdoOrganization" -foregroundColor Yellow
      Write-Verbose "ADO Organization validated: $AdoOrganization"

      Write-Host "Using Control plane code: $ControlPlaneCode" -foregroundColor Yellow
      Write-Verbose "Control plane code validated: $ControlPlaneCode"
      #endregion

      #region Set up prefixes and pool names
      $ControlPlanePrefix = "SDAF-" + $ControlPlaneCode
      Write-Verbose "Control plane prefix: $ControlPlanePrefix"

      $AgentPoolNameFinal = $AgentPoolName
      if ($AgentPoolNameFinal.Length -eq 0) {
        $AgentPoolNameFinal = $ControlPlanePrefix + "-POOL"
        $UserConfirmation = Read-Host "Use Agent pool with name '$AgentPoolNameFinal' y/n?"
        if ($UserConfirmation -ne 'y') {
          $AgentPoolNameFinal = Read-Host "Enter the name of the agent pool"
        }
      }

      if ($ApplicationName.Length -eq 0) {
        $ApplicationName = $ControlPlanePrefix + "-configuration"
      }

      Write-Verbose "Agent pool name: $AgentPoolNameFinal"
      Write-Verbose "Web app enabled: $EnableWebApp"
      if ($EnableWebApp) {
        Write-Verbose "Application name: $ApplicationName"
      }
      #endregion

      $PipelinePermissionUrl = ""
      $ImportCodeFromGitHub = $false
      $AppRegistrationId = ""
      $WebAppClientSecret = "Enter your App registration secret here"

      $WikiFileName = "start.md"

      Add-Content -Path $WikiFileName -Value "# Welcome to the SDAF Wiki"
      Add-Content -Path $WikiFileName -Value ""
      Add-Content -Path $WikiFileName -Value "## Deployment details"
      Add-Content -Path $WikiFileName -Value ""
      Add-Content -Path $WikiFileName -Value "Azure DevOps organization: $AdoOrganization"

      #region Create DevOps project
      $ProjectId = (az devops project list --organization $AdoOrganization --query "[value[]] | [0] | [? name=='$AdoProject'].id | [0]" --out tsv)

      if ($ProjectId.Length -eq 0) {
        Write-Host "Creating the project: " $AdoProject -ForegroundColor Green
        $ProjectId = (az devops project create --name $AdoProject --description 'SDAF Automation Project' --organization $AdoOrganization --visibility private --source-control git --query id --output tsv)

        Add-Content -Path $WikiFileName -Value ""
        Add-Content -Path $WikiFileName -Value "Using Azure DevOps Project: $AdoProject"

        az devops configure --defaults organization=$AdoOrganization project="$AdoProject"

        $RepositoryId = (az repos list --query "[?name=='$AdoProject'].id | [0]"  --out tsv)

        Write-Host "Importing the content from GitHub" -ForegroundColor Green
        az repos import create --git-url $Repositories.Bootstrap --repository $RepositoryId   --output none

        az repos update --repository $RepositoryId --default-branch main  --output none
      }
      else {
        Add-Content -Path $WikiFileName -Value ""
        Add-Content -Path $WikiFileName -Value "DevOps Project: $AdoProject"

        Write-Host "Using an existing project"

        az devops configure --defaults organization=$AdoOrganization project="$AdoProject"

        $RepositoryId = (az repos list --query "[?name=='$AdoProject'].id | [0]"  --output tsv)
        if ($RepositoryId.Length -ne 0) {
          Write-Host "Using repository '$AdoProject'" -ForegroundColor Green
        }

        $RepositorySize = (az repos list --query "[?name=='$AdoProject'].size | [0]"  --output tsv)

        if ($RepositorySize -eq 0) {
          Write-Host "Importing the repository from GitHub" -ForegroundColor Green

          Add-Content -Path $WikiFileName -Value ""
          Add-Content -Path $WikiFileName -Value "Terraform and Ansible code repository stored in the DevOps project (sap-automation)"

          az repos import create --git-url $Repositories.Bootstrap --repository $RepositoryId   --output tsv
          if ($LastExitCode -eq 1) {
            Write-Host "The repository already exists" -ForegroundColor Yellow
            Write-Host "Creating repository 'SDAF Configuration'" -ForegroundColor Green
            $RepositoryId = (az repos create --name "SDAF Configuration" --query id --output tsv)
            az repos import create --git-url $Repositories.Bootstrap --repository $RepositoryId  --output none
          }
        }
        else {
          $UserConfirmation = Read-Host "The repository already exists, use it? y/n"
          if ($UserConfirmation -ne 'y') {
            Write-Host "Creating repository 'SDAF Configuration'" -ForegroundColor Green
            $RepositoryId = (az repos create --name "SDAF Configuration" --query id  --output tsv)
            az repos import create --git-url $Repositories.Bootstrap --repository $RepositoryId  --output none
          }
        }

        az repos update --repository $RepositoryId --default-branch main  --output none
      }

      # Handle GitHub import decision
      if ($ShouldImportCodeFromGitHub) {
        Add-Content -Path $WikiFileName -Value ""
        Add-Content -Path $WikiFileName -Value "Using the code from the sap-automation repository"

        $ImportCodeFromGitHub = $true
        $CodeRepositoryName = "sap-automation"
        Write-Host "Creating $CodeRepositoryName repository" -ForegroundColor Green
        az repos create --name $CodeRepositoryName --query id  --output none
        $CodeRepositoryId = (az repos list --query "[?name=='$CodeRepositoryName'].id | [0]"  --out tsv)
        az repos import create --git-url $Repositories.Automation --repository $CodeRepositoryId  --output none
        az repos update --repository $CodeRepositoryId --default-branch main  --output none

        $SampleRepositoryName = "sap-samples"
        Write-Host "Creating $SampleRepositoryName repository" -ForegroundColor Green
        az repos create --name $SampleRepositoryName --query id  --output none
        $SampleRepositoryId = (az repos list --query "[?name=='$SampleRepositoryName'].id | [0]"  --out tsv)
        az repos import create --git-url $Repositories.Samples --repository $SampleRepositoryId  --output none
        az repos update --repository $SampleRepositoryId --default-branch main  --output none

        # Update resource files for non-standard project names
        if ($AdoProject -ne "SAP Deployment Automation Framework") {
          UpdateAdoRepositoryReferences -RepositoryId $RepositoryId -AdoProject $AdoProject
        }

        $CodeRepositoryId = (az repos list --query "[?name=='sap-automation'].id | [0]"  --out tsv)
        $QueryString = "?api-version=6.0-preview"
        $PipelinePermissionUrl = "$AdoOrganization/$ProjectId/_apis/pipelines/pipelinePermissions/repository/$ProjectId.$CodeRepositoryId$QueryString"
      }
      else {
        Add-Content -Path $WikiFileName -Value ""
        Add-Content -Path $WikiFileName -Value "Using the code directly from GitHub"

        $ResourcesUrl = $AdoOrganization + "/_git/" + [uri]::EscapeDataString($AdoProject) + "?path=/pipelines/resources.yml"
        $LogEntry = ("Please update [resources.yml](" + $ResourcesUrl + ") to point to Github instead of Azure DevOps.")
      }
      #endregion

      $RepositoryId = (az repos list --query "[?name=='$AdoProject'].id | [0]"  --out tsv)
      $RepositoryName = (az repos list --query "[?name=='$AdoProject'].name | [0]"  --out tsv)

      # Handle S-User credentials
      $SUserName = 'Enter your S User'
      $SPassword = 'Enter your S user password'

      if ($Env:SUserName.Length -ne 0) {
        $SUserName = $Env:SUserName
      }
      if ($Env:SPassword.Length -ne 0) {
        $SPassword = $Env:SPassword
      }

      if ($Env:SUserName.Length -eq 0 -and $Env:SPassword.Length -eq 0) {
        $ProvideSUser = Read-Host "Do you want to provide the S user details y/n?"
        if ($ProvideSUser -eq 'y') {
          $SUserName = Read-Host "Enter your S User ID"
          $SPassword = Read-Host "Enter your S user password"
        }
      }

      # Initialize collections
      $VariableGroups = New-Object System.Collections.Generic.List[System.Object]
      $PipelineIds = New-Object System.Collections.Generic.List[System.Object]

      Write-Host "Creating the variable group SDAF-General" -ForegroundColor Green

      $GeneralGroupId = (az pipelines variable-group list --query "[?name=='SDAF-General'].id | [0]" --only-show-errors)
      if ($GeneralGroupId.Length -eq 0) {
        az pipelines variable-group create --name SDAF-General --variables ANSIBLE_HOST_KEY_CHECKING=false Deployment_Configuration_Path=WORKSPACES Branch=main tf_version="1.12.2" ansible_core_version="2.16" S-Username=$SUserName S-Password=$SPassword --output yaml --authorize true --output none
        $GeneralGroupId = (az pipelines variable-group list --query "[?name=='SDAF-General'].id | [0]" --only-show-errors)
        az pipelines variable-group variable update --group-id $GeneralGroupId --name "S-Password" --value $SPassword --secret true --output none --only-show-errors
      }

      $VariableGroups.Add($GeneralGroupId)

      #region Create pipelines
      Write-Host "Creating the pipelines in repo: " $RepositoryName "(" $RepositoryId ")" -foregroundColor Green

      Add-Content -Path $WikiFileName -Value ""
      Add-Content -Path $WikiFileName -Value "### Pipelines"
      Add-Content -Path $WikiFileName -Value ""

      foreach ($Pipeline in $Pipelines) {
        $PipelineName = $Pipeline.Name
        $Description = $Pipeline.Description
        $YamlPath = $Pipeline.YamlPath

        Write-Host "Creating pipeline: $PipelineName" -ForegroundColor Green

        $PipelineId = AddPipeline -PipelineName $PipelineName -Description $Description -YamlName $YamlPath -LogFile $WikiFileName
        if ($PipelineId) {
          $PipelineIds.Add($PipelineId)
        }
      }

      if ($ImportCodeFromGitHub) {
        $UpdateRepoPipelineId = AddPipeline -PipelineName "Update repository" -Description 'Updates the codebase' -YamlName "/pipelines/20-update-repositories.yml" -LogFile $WikiFileName
        $PipelineIds.Add($UpdateRepoPipelineId)
      }

      $SamplePipelineId = (az pipelines list --project $AdoProject --query "[?name=='Create Control Plane configuration'].id | [0]" --output tsv)
      $ControlPlanePipelineId = (az pipelines list --project $AdoProject --query "[?name=='Deploy Control Plane'].id | [0]" --output tsv)

      $WorkloadZonePipelineId = (az pipelines list --project $AdoProject --query "[?name=='Deploy Workload Zone'].id | [0]" --output tsv)
      $SystemPipelineId = (az pipelines list --project $AdoProject --query "[?name=='SAP SID Infrastructure deployment'].id | [0]" --output tsv)
      $InstallationPipelineId = (az pipelines list --project $AdoProject --query "[?name=='Configuration and SAP installation'].id | [0]" --output tsv)
      #endregion
      #region GitHubConnections

      # Handle service connections based on CreateConnections parameter
      $GitHubConnection = (az devops service-endpoint list --query "[?type=='github'].name | [0]"  --out tsv)

      if ($CreateConnections -and $GitHubConnection.Length -eq 0) {
        $GitHubConnectionUrl = $AdoOrganization + "/" + [uri]::EscapeDataString($AdoProject) + "/_settings/adminservices"
        Write-Host ""
        Write-Host "The browser will now open, please create a new Github connection, record the name of the connection." -ForegroundColor Blue
        Write-Host "URL: " $GitHubConnectionUrl -ForegroundColor Blue
        Start-Process $GitHubConnectionUrl
        Read-Host "Please press enter when you have created the connection"

        $GitHubConnection = (az devops service-endpoint list --query "[?type=='github'].name | [0]"  --out tsv)
        UpdateGitHubRepositoryReferences -RepositoryId $RepositoryId -AdoProject $AdoProject -GitHubConnection $GitHubConnection -BranchName $BranchName -GitHubRepoName $GitHubRepoName

        Write-Host ""
      }
      else {
        Write-Host "Please create an 'Azure Resource Manager' service connection to the control plane subscription with the name 'Control_Plane_Service_Connection' before running any pipeline."
        Write-Host "Please create a 'GitHub' service connection before running any pipeline."
      }
      #endregion

      Add-Content -Path $WikiFileName -Value ""
      Add-Content -Path $WikiFileName -Value "### Variable Groups"
      Add-Content -Path $WikiFileName -Value ""
      Add-Content -Path $WikiFileName -Value "SDAF-General"
      Add-Content -Path $WikiFileName -Value $ControlPlanePrefix

      Add-Content -Path $WikiFileName -Value "### Credentials"
      Add-Content -Path $WikiFileName -Value ""
      Add-Content -Path $WikiFileName -Value ("Web Application: " + $ApplicationName)

      #region App registration
      $ControlPlaneVariableGroupId = (az pipelines variable-group list --query "[?name=='$ControlPlanePrefix'].id | [0]" --only-show-errors)
      if ($ControlPlaneVariableGroupId.Length -eq 0) {
        Write-Host "Creating the variable group" $ControlPlanePrefix -ForegroundColor Green
        $ControlPlaneVariableGroupId = (az pipelines variable-group create --name $ControlPlanePrefix --variables AGENT='Azure Pipelines' ARM_SUBSCRIPTION_ID=$ControlPlaneSubscriptionId ARM_TENANT_ID=$ArmTenantId POOL=$AgentPoolName AZURE_CONNECTION_NAME='Control_Plane_Service_Connection' WORKLOADZONE_PIPELINE_ID=$WorkloadZonePipelineId SYSTEM_PIPELINE_ID=$SystemPipelineId SDAF_GeneralGroupId=$GeneralGroupId SAP_INSTALL_PIPELINE_ID=$InstallationPipelineId TF_LOG=OFF --query id --output tsv --authorize true)
      }
      $VariableGroups.Add($ControlPlaneVariableGroupId)

      if ($EnableWebApp) {
        Write-Host "Creating the App registration in Entra Id" -ForegroundColor Green

        $FoundAppRegistration = (az ad app list --all --filter "startswith(displayName, '$ApplicationName')" --query  "[?displayName=='$ApplicationName'].displayName | [0]" --only-show-errors)

        if ($FoundAppRegistration.Length -ne 0) {
          Write-Host "Found an existing App Registration:" $ApplicationName
          $ServicePrincipalInformation = (az ad app list --all --filter "startswith(displayName, '$ApplicationName')" --query  "[?displayName=='$ApplicationName']| [0]" --only-show-errors) | ConvertFrom-Json

          $AppRegistrationId = $ServicePrincipalInformation.appId
          $AppRegistrationObjectId = $ServicePrincipalInformation.id

        }
        else {
          Write-Host "Creating an App Registration for" $ApplicationName -ForegroundColor Green
          if ($IsWindows) { $manifestPath = ".\manifest.json" } else { $manifestPath = "./manifest.json" }
          Add-Content -Path manifest.json -Value '[{"resourceAppId":"00000003-0000-0000-c000-000000000000","resourceAccess":[{"id":"e1fe6dd8-ba31-4d61-89e7-88639da4683d","type":"Scope"}]}]'

          $AppRegistrationId = (az ad app create --display-name $ApplicationName --enable-id-token-issuance true --sign-in-audience AzureADMyOrg --required-resource-access $manifestPath --query "appId" --output tsv --service-management-reference $ServiceManagementReference )
          $ServicePrincipalInformation = (az ad app list --all --filter "startswith(displayName, '$ApplicationName')" --query  "[?displayName=='$ApplicationName']| [0]" --only-show-errors) | ConvertFrom-Json
          $AppRegistrationObjectId = $ServicePrincipalInformation.id

          if (Test-Path $manifestPath) { Write-Host "Removing manifest.json" ; Remove-Item $manifestPath }
        }
        SetVariableGroupVariable -VariableGroupId $ControlPlaneVariableGroupId -VariableName "APP_REGISTRATION_APP_ID" -VariableValue $AppRegistrationId
        SetVariableGroupVariable -VariableGroupId $ControlPlaneVariableGroupId -VariableName "APP_REGISTRATION_OBJECTID" -VariableValue $AppRegistrationObjectId
      }
      #endregion

      if ($AuthenticationMethod -eq "Managed Identity") {

        if ($ManagedIdentityObjectId.Length -eQ 0) {

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
          $ManagedIdentityObjectId = $(az identity show --ids $id --query "principalId" --output tsv)
        }

        SetVariableGroupVariable -VariableGroupId $ControlPlaneVariableGroupId -VariableName "ARM_OBJECT_ID" -VariableValue $ManagedIdentityObjectId
        SetVariableGroupVariable -VariableGroupId $ControlPlaneVariableGroupId -VariableName "USE_MSI" -VariableValue "true"

        $ManagedIdentityClientId = (az ad sp show --id $ManagedIdentityObjectId --query appId --output tsv)
        SetVariableGroupVariable -VariableGroupId $ControlPlaneVariableGroupId -VariableName "ARM_CLIENT_ID" -VariableValue $ManagedIdentityClientId

        $ServiceConnectionName = "Control_Plane_Service_Connection"
        $ServiceEndpointExists = (az devops service-endpoint list --query "[?name=='$ServiceConnectionName'].name | [0]" )
        if ($ServiceEndpointExists.Length -eq 0) {
          CreateServiceConnection -ConnectionName $ServiceConnectionName `
            -ServiceConnectionDescription "Control Plane Service Connection" `
            -TenantId $ArmTenantId `
            -ManagedIdentityObjectId $ManagedIdentityObjectId `
            -SubscriptionId $ControlPlaneSubscriptionIdInternal `
            -ProjectId $ProjectId `
            -ProjectName $AdoProject
          $ServiceEndpointId = az devops service-endpoint list --query "[?name=='$ServiceConnectionName'].id" -o tsv
          if ($ServiceEndpointId.Length -ne 0) {
            az devops service-endpoint update --id $ServiceEndpointId --enable-for-all true --output none --only-show-errors
          }

          if ($EnableWebApp) {
            $ConfigureAuthentication = Read-Host "Configuring authentication for the App Registration (y/n)?"
            if ($ConfigureAuthentication -eq 'y') {
              az rest --method POST --uri "https://graph.microsoft.com/beta/applications/$AppRegistrationObjectId/federatedIdentityCredentials\" --body "{'name': 'ManagedIdentityFederation', 'issuer': 'https://login.microsoftonline.com/$ArmTenantId/v2.0', 'subject': '$ManagedIdentityObjectId', 'audiences': [ 'api://AzureADTokenExchange' ]}"

              $ConfigurationUrl = "https://portal.azure.com/#view/Microsoft_AAD_RegisteredApps/ApplicationMenuBlade/~/ProtectAnAPI/appId/$AppRegistrationId/isMSAApp~/false"

              Write-Host "The browser will now open, Please Add a new scope, by clicking the '+ Add a new scope link', accept the default name and click 'Save and Continue'" -ForegroundColor Blue
              Write-Host "In the Add a scope page enter the scope name 'user_impersonation'. Choose 'Admins and Users' in the who can consent section, next provide the Admin consent display name 'Access the SDAF web application' and 'Use SDAF' as the Admin consent description, accept the changes by clicking the 'Add scope' button"  -ForegroundColor Blue

              Start-Process $ConfigurationUrl
              Read-Host -Prompt "Once you have created and validated the scope, Press any key to continue"
            }
          }
        }

        #endregion
        if ($AuthenticationMethod -eq "Service Principal") {
          #region Control plane Service Principal
          $ServicePrincipalName = $ControlPlanePrefix + " Deployment credential"
          if ($Env:SDAF_MGMT_ServicePrincipalName.Length -ne 0) {
            $ServicePrincipalName = $Env:SDAF_MGMT_ServicePrincipalName
          }

          Add-Content -Path $WikiFileName -Value ("Control Plane Service Principal: " + $ServicePrincipalName)

          $Scope = "/subscriptions/" + $ControlPlaneSubscriptionId

          Write-Host "Creating the deployment credentials for the control plane. Service Principal Name:" $ServicePrincipalName -ForegroundColor Green

          $ControlPlaneClientId = ""
          $ControlPlaneObjectId = ""
          $ControlPlaneTenantId = ""
          $ControlPlaneClientSecret = "Please update"

          SetVariableGroupVariable -VariableGroupId $ControlPlaneVariableGroupId -VariableName "USE_MSI" -VariableValue "false"

          $ServicePrincipalFound = (az ad sp list --all --filter "startswith(displayName, '$ServicePrincipalName')" --query "[?displayName=='$ServicePrincipalName'].displayName | [0]" --only-show-errors)
          if ($ServicePrincipalFound.Length -gt 0) {
            Write-Host "Found an existing Service Principal:" $ServicePrincipalName
            $ServicePrincipalInformation = (az ad sp list --all --filter "startswith(displayName, '$ServicePrincipalName')" --query  "[?displayName=='$ServicePrincipalName']| [0]" --only-show-errors) | ConvertFrom-Json
            Write-Host "Updating the variable group"

            $ControlPlaneClientId = $ServicePrincipalInformation.appId
            $ControlPlaneObjectId = $ServicePrincipalInformation.Id
            $ControlPlaneTenantId = $ServicePrincipalInformation.appOwnerOrganizationId

            $confirmation = Read-Host "Reset the Control Plane Service Principal password y/n?"
            if ($confirmation -eq 'y') {

              $ControlPlaneClientSecret = (az ad sp credential reset --id $ControlPlaneClientId --append --query "password" --out tsv --only-show-errors).Replace("""", "")
            }
            else {
              $ControlPlaneClientSecret = Read-Host "Please enter the Control Plane Service Principal $ServicePrincipalName password"
            }

          }
          else {
            Write-Host "Creating the Service Principal" $ServicePrincipalName -ForegroundColor Green
            $ControlPlaneServicePrincipalData = (az ad sp create-for-rbac --role "Contributor" --scopes $Scope --name $ServicePrincipalName --only-show-errors  --service-management-reference $ServiceManagementReference) | ConvertFrom-Json
            $ControlPlaneClientSecret = $ControlPlaneServicePrincipalData.password
            $ServicePrincipalInformation = (az ad sp list --all --filter "startswith(displayName, '$ServicePrincipalName')" --query  "[?displayName=='$ServicePrincipalName'] | [0]" --only-show-errors) | ConvertFrom-Json
            $ControlPlaneClientId = $ServicePrincipalInformation.appId
            $ControlPlaneTenantId = $ServicePrincipalInformation.appOwnerOrganizationId
            $ControlPlaneObjectId = $ServicePrincipalInformation.Id

          }

          SetVariableGroupVariable -VariableGroupId $ControlPlaneVariableGroupId -VariableName "ARM_CLIENT_ID" -VariableValue $ControlPlaneClientId
          SetVariableGroupVariable -VariableGroupId $ControlPlaneVariableGroupId -VariableName "ARM_CLIENT_SECRET" -VariableValue $ControlPlaneClientSecret -IsSecret
          SetVariableGroupVariable -VariableGroupId $ControlPlaneVariableGroupId -VariableName "ARM_OBJECT_ID" -VariableValue $ControlPlaneObjectId
          SetVariableGroupVariable -VariableGroupId $ControlPlaneVariableGroupId -VariableName "USE_MSI" -VariableValue "false"

          foreach ($RoleName in $Roles) {

            Write-Host "Assigning role" $RoleName "to the control plane Service Principal" -ForegroundColor Green
            az role assignment create --assignee $ControlPlaneClientId --role $RoleName --scope /subscriptions/$Control_plane_subscriptionID --output none --only-show-errors
          }

          Write-Host "Create the Service Endpoint in Azure for the control plane" -ForegroundColor Green

          $Service_Connection_Name = "Control_Plane_Service_Connection"
          $Env:AZURE_DEVOPS_EXT_AZURE_RM_SERVICE_PRINCIPAL_KEY = $ControlPlaneClientSecret

          $ServiceConnectionExists = (az devops service-endpoint list --query "[?name=='$Service_Connection_Name'].name | [0]")
          if ($ServiceConnectionExists.Length -eq 0) {
            Write-Host "Creating Service Endpoint" $Service_Connection_Name -ForegroundColor Green
            az devops service-endpoint azurerm create --azure-rm-service-principal-id $ControlPlaneClientId --azure-rm-subscription-id $Control_plane_subscriptionID --azure-rm-subscription-name $ControlPlaneSubscriptionName --azure-rm-tenant-id $ControlPlaneTenantId --name $Service_Connection_Name --output none --only-show-errors
            $ServiceConnectionId = az devops service-endpoint list --query "[?name=='$Service_Connection_Name'].id" -o tsv
            az devops service-endpoint update --id $ServiceConnectionId --enable-for-all true --output none --only-show-errors
          }
          else {
            Write-Host "Service Endpoint already exists, recreating it with the updated credentials" -ForegroundColor Yellow
            $ServiceConnectionId = az devops service-endpoint list --query "[?name=='$Service_Connection_Name'].id" -o tsv
            az devops service-endpoint delete --id $ServiceConnectionId --yes
            az devops service-endpoint azurerm create --azure-rm-service-principal-id $ControlPlaneClientId --azure-rm-subscription-id $Control_plane_subscriptionID --azure-rm-subscription-name $ControlPlaneSubscriptionName --azure-rm-tenant-id $ControlPlaneTenantId --name $Service_Connection_Name --output none --only-show-errors
            $ServiceConnectionId = az devops service-endpoint list --query "[?name=='$Service_Connection_Name'].id" -o tsv
            az devops service-endpoint update --id $ServiceConnectionId --enable-for-all true --output none --only-show-errors
          }
        }
      }

      $AgentPoolId = (az pipelines pool list --query "[?name=='$AgentPoolName'].id | [0]")
      if ($AgentPoolId.Length -gt 0) {
        Write-Host "Agent pool" $AgentPoolName "already exists" -ForegroundColor Yellow
      }
      else {
        Write-Host "Creating agent pool" $AgentPoolName -ForegroundColor Green

        Set-Content -Path pool.json -Value (ConvertTo-Json @{name = $AgentPoolName; autoProvision = $true })
        $AgentPoolId = (az devops invoke --area distributedtask --resource pools --http-method POST --api-version "7.1-preview" --in-file ".${pathSeparator}pool.json" --query-parameters authorizePipelines=true --query id --output tsv --only-show-errors --route-parameters project=$ADO_Project)
        Write-Host "Agent pool" $AgentPoolName "created"
      }


      $ConfigurationUrl = "$AdoOrganization/_settings/agentpools?poolId=$AgentPoolId&view=security"
      Write-Host "The browser will now open, Please '$AdoProject Build Service' as an Administrator to the Application Pool." -ForegroundColor Blue

      Start-Process $ConfigurationUrl
      Read-Host -Prompt "Once you have added the user, Press any key to continue"
      $QueueId = (az pipelines queue list --query "[?name=='$AgentPoolName'].id | [0]" --output tsv)

      if (Test-Path ".${pathSeparator}pool.json") {
        Remove-Item ".${pathSeparator}pool.json"
      }

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

      $accessToken = az account get-access-token --resource 499b84ac-1321-427f-aa17-267ca6975798 --query "accessToken" --output tsv
      $headers = @{
        Accept        = "application/json"
        Authorization = "Bearer $accessToken"
      }

      foreach ($VariableGroup in $VariableGroups) {

        $bodyText.resource.id = $VariableGroup

        $DevOpsRestUrl = $AdoOrganization + "/" + $AdoProject + "/_apis/pipelines/pipelinePermissions/variablegroup/" + $VariableGroup.ToString() + "?api-version=5.1-preview.1"
        Write-Host "Setting pipeline permissions for variable group:" $VariableGroup.ToString() -ForegroundColor Yellow

        foreach ($PipelineId in $PipelineIds) {

          $bodyText.pipelines[0].id = $PipelineId

          $body = $bodyText | ConvertTo-Json -Depth 10
          Write-Host "  Allowing pipeline id:" $PipelineId.ToString() -ForegroundColor Yellow
          $response = Invoke-RestMethod -Method PATCH -Uri $DevOpsRestUrl -Headers $headers -Body $body -ContentType "application/json"

        }
      }

      if (Test-Path ".${pathSeparator}user.json") {
        Remove-Item ".${pathSeparator}user.json"
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
      $postBody = [PSCustomObject]@{
        accessLevel         = @{
          accountLicenseType = "stakeholder"
        }
        user                = @{
          origin      = "aad"
          originId    = $ManagedIdentityObjectId
          subjectKind = "servicePrincipal"
        }
        projectEntitlements = @([ordered]@{
            group      = @{
              groupType = "projectAdministrator"
            }
            projectRef = @{
              id = $ProjectId
            }

          })
        servicePrincipal    = @{
          origin      = "aad"
          originId    = $ManagedIdentityObjectId
          subjectKind = "servicePrincipal"
        }

      }

      Set-Content -Path "user.json" -Value ($postBody | ConvertTo-Json -Depth 6)

      az devops invoke --area MemberEntitlementManagement --resource ServicePrincipalEntitlements  --in-file user.json --api-version "7.1-preview" --http-method POST --output none --only-show-errors
      if (Test-Path "user.json") {
        Write-Host "Removing user.json" -ForegroundColor Yellow
        Remove-Item -Path "user.json"
      }

      $DevOpsRestUrl = $AdoOrganization + "/" + $AdoProject + "/_apis/pipelines/pipelinePermissions/queue/" + $QueueId.ToString() + "?api-version=5.1-preview.1"
      Write-Host "Setting permissions for agent pool:" $AgentPoolName "(" $QueueId ")" -ForegroundColor Yellow
      foreach ($PipelineId in $PipelineIds) {
        $bodyText.pipelines[0].id = $PipelineId
        $body = $bodyText | ConvertTo-Json -Depth 10
        Write-Host "  Allowing pipeline id:" $PipelineId.ToString() " access to " $AgentPoolName -ForegroundColor Yellow
        $response = Invoke-RestMethod -Method PATCH -Uri $DevOpsRestUrl -Headers $headers -Body $body -ContentType "application/json"
      }

      Write-Host "Adding the Build Service user to the Build Administrators group for the Project" -ForegroundColor Green
      $SecurityServiceGroupId = $(az devops security group list --scope organization --query "graphGroups | [?displayName=='Security Service Group'].descriptor | [0]" --output tsv)
      $ProjectBuildAdminGroupId = $(az devops security group list --project $AdoProject --query "graphGroups | [?displayName=='Build Administrators'].descriptor | [0]" --output tsv)
      $GroupItems = $(az devops security group membership list --id $SecurityServiceGroupId --output table )

      $Service_Name = $AdoProject + " Build Service"
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
        az devops security group membership add --member-id $Descriptor --group-id $ProjectBuildAdminGroupId --output none --only-show-errors
      }

      $SamplePipelineId = (az pipelines list --project $AdoProject --query "[?name=='Create Control Plane configuration'].id | [0]" --output tsv)
      $ControlPlanePipelineId = (az pipelines list --project $AdoProject --query "[?name=='Deploy Control Plane'].id | [0]" --output tsv)

      $PipelineUrl = $AdoOrganization + "/" + [uri]::EscapeDataString($AdoProject) + "/_build?definitionId=" + $SamplePipelineId

      $ControlPlanePipelineUrl = $AdoOrganization + "/" + [uri]::EscapeDataString($AdoProject) + "/_build?definitionId=" + $ControlPlanePipelineId

      Add-Content -Path $WikiFileName -Value "## Next steps"
      Add-Content -Path $WikiFileName -Value ""
      Add-Content -Path $WikiFileName -Value ( "Use the [Create Control Plane Configuration Sample](" + $PipelineUrl + ") to create the control plane configuration using the code '" + $ControlPlaneCode + "' in the region you selected.")
      Add-Content -Path $WikiFileName -Value ""
      Add-Content -Path $WikiFileName -Value ( "Once it is complete use the [Deploy Control Plane Pipeline ](" + $ControlPlanePipelineUrl + ") to create the control plane configuration in the region you select.")
      Add-Content -Path $WikiFileName -Value ""

      $WikiFound = (az devops wiki list --query "[?name=='SDAF'].name | [0]")
      if ($WikiFound.Length -gt 0) {
        Write-Host "Wiki SDAF already exists"
        $eTag = (az devops wiki page show --path 'Next steps' --wiki SDAF --query eTag )
        if ($null -ne $eTag  ) {
          $PageId = (az devops wiki page update --path 'Next steps' --wiki SDAF --file-path ".${pathSeparator}start.md" --only-show-errors --version $eTag --query page.id)
        }
      }
      else {
        az devops wiki create --name SDAF --output none --only-show-errors
        az devops wiki page create --path 'Next steps' --wiki SDAF --file-path ".${pathSeparator}start.md" --output none --only-show-errors
      }

      $PageId = (az devops wiki page show --path 'Next steps' --wiki SDAF --query page.id )

      $wiki_url = $AdoOrganization + "/" + [uri]::EscapeDataString($AdoProject) + "/_wiki/wikis/SDAF/" + $PageId + "/Next-steps"
      Write-Host "URL: " $wiki_url
      if ($true -eq $CreateConnections) {
        Start-Process $wiki_url
      }
      if (Test-Path ".${pathSeparator}start.md") { Write-Host "Removing start.md" ; Remove-Item ".${pathSeparator}start.md" }

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
    Write-Verbose "New-SDAFADOProject cmdlet finished"
  }
}

# Export the function
Export-ModuleMember -Function New-SDAFADOProject
