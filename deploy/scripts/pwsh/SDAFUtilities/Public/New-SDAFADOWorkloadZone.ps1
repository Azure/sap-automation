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

.PARAMETER ControlPlaneName
    The control plane name (e.g., "MGMT-WEEU-DEP01").

.PARAMETER ControlPlaneSubscriptionId
    The subscription ID for the control plane resources.

.PARAMETER WorkloadZoneCode
    The workload zone code identifier (e.g., QA).

.PARAMETER WorkloadZoneName
    The workload zone name (e.g., "QA-WEEU-SAP01").

.PARAMETER WorkloadZoneSubscriptionId
    The subscription ID for the workload zone resources.

.PARAMETER AuthenticationMethod
    The authentication method to use (Service Principal or Managed Identity).

.PARAMETER ManagedIdentityObjectId
    The object ID of the managed identity (required for Managed Identity authentication).

.PARAMETER ManagedIdentityId
    The ID of the managed identity (required for Managed Identity authentication).

.PARAMETER CreateConnections
    Switch to create service connections automatically.

.PARAMETER ServiceManagementReference
    The service management reference for the project (optional).

 EXAMPLE
    New-SDAFADOWorkloadZone -AdoOrganization "https://dev.azure.com/myorg" -AdoProject "SAP-SDAF" -TenantId "12345678-1234-1234-1234-123456789012" -WorkloadZoneCode "MGMT" -WorkloadZoneSubscriptionId "87654321-4321-4321-4321-210987654321" -AgentPoolName "SDAF-MGMT-POOL" -AuthenticationMethod "Service Principal" -Verbose

.NOTES
    Author: GitHub Copilot
    Requires: Azure CLI with DevOps extension
    Copyright (c) Microsoft Corporation.
    Licensed under the MIT License.
#>
function New-SDAFADOWorkloadZone {
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

    [Parameter(Mandatory = $true, HelpMessage = "Control Plane code (e.g., MGMT)")]
    [string]$ControlPlaneCode,

    [Parameter(Mandatory = $false, HelpMessage = "Control Plane name (e.g., MGMT-WEEU-DEP01)")]
    [string]$ControlPlaneName = "",

    [Parameter(Mandatory = $true, HelpMessage = "Control Plane subscription ID")]
    [ValidateScript({ [System.Guid]::TryParse($_, [ref][System.Guid]::Empty) })]
    [string]$ControlPlaneSubscriptionId,

    [Parameter(Mandatory = $true, HelpMessage = "Workload zone code (e.g., DEV)")]
    [string]$WorkloadZoneCode,

    [Parameter(Mandatory = $false, HelpMessage = "Workload zone name (e.g., DEV-WEEU-SAP01)")]
    [string]$WorkloadZoneName = "",

    [Parameter(Mandatory = $true, HelpMessage = "Workload zone subscription ID")]
    [ValidateScript({ [System.Guid]::TryParse($_, [ref][System.Guid]::Empty) })]
    [string]$WorkloadZoneSubscriptionId,

    [Parameter(Mandatory = $true, HelpMessage = "Authentication method to use")]
    [ValidateSet("Service Principal", "Managed Identity")]
    [string]$AuthenticationMethod,

    # Service Principal specific parameters
    [Parameter(ParameterSetName = "ServicePrincipal", Mandatory = $false)]
    [string]$ServicePrincipalClientId,

    [Parameter(ParameterSetName = "ServicePrincipal", Mandatory = $false)]
    [SecureString]$ServicePrincipalSecret,

    # Managed Identity specific parameters
    [Parameter(ParameterSetName = "ManagedIdentity", Mandatory = $true)]
    [ValidateScript({ [System.Guid]::TryParse($_, [ref][System.Guid]::Empty) })]
    [string]$ManagedIdentityObjectId,

    # Managed Identity specific parameters
    [Parameter(ParameterSetName = "ManagedIdentity", Mandatory = $false)]
    [string]$ManagedIdentityId,

    # Switch parameters
    [Parameter(HelpMessage = "Create service connections automatically")]
    [switch]$CreateConnections,

    [Parameter(HelpMessage = "Service Management Reference")]
    [string]$ServiceManagementReference = ""
  )

  begin {
    Write-Verbose "Starting New-SDAFADOWorkloadZone cmdlet"
    Write-Verbose "Parameters received:"
    Write-Verbose "  AdoOrganization: $AdoOrganization"
    Write-Verbose "  AdoProject: $AdoProject"
    Write-Verbose "  TenantId: $TenantId"
    Write-Verbose "  AuthenticationMethod: $AuthenticationMethod"
    Write-Verbose "  ManagedIdentityObjectId: $ManagedIdentityObjectId"
    Write-Verbose "  ManagedIdentityId: $ManagedIdentityId"
    Write-Verbose "  WorkloadZoneCode: $WorkloadZoneCode"
    Write-Verbose "  WorkloadZoneSubscriptionId: $WorkloadZoneSubscriptionId"
    Write-Verbose "  CreateConnections: $CreateConnections"
    Write-Verbose "  ServiceManagementReference: $ServiceManagementReference"

    # Initialize error tracking
    $ErrorActionPreference = 'Stop'
    $script:DeploymentErrors = @()
    $script:OperationLog = @()

    $Roles = @(
      "Contributor",
      "Role Based Access Control Administrator",
      "Storage Blob Data Owner",
      "Key Vault Administrator",
      "Key Vault Secret Officer",
      "App Configuration Data Owner"
    )

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

    function CreateServiceConnection {
      param(
        [string]$ConnectionName,
        [string]$ServiceConnectionDescription,
        [string]$TenantId,
        [string]$ManagedIdentityClientId,
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

      Write-Verbose "Creating JSON input file for service connection"
      Write-Verbose $PostBody | ConvertTo-Json -Depth 6
      Set-Content -Path $JsonInputFile -Value ($PostBody | ConvertTo-Json -Depth 6)

      Write-Verbose "Creating service connection: $ConnectionName"
      az devops service-endpoint create --service-endpoint-configuration $JsonInputFile --organization $AdoOrganization --project $AdoProject --output none --only-show-errors
      if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to create service connection '$ConnectionName'"
        throw "Service connection creation failed"
      }
      Write-Host "Service connection '$ConnectionName' created successfully." -ForegroundColor Green

      if (Test-Path $JsonInputFile) {
        Remove-Item $JsonInputFile
      }
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
      $VersionLabel = "v3.18.0.0"
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

      #region Validate and set subscription
      Write-Verbose "Validating workload zone subscription"
      if ($WorkloadZoneSubscriptionIdInternal.Length -eq 0) {
        Write-Host "Workload zone subscription ID is not set!" -ForegroundColor Red
        $Title = "Choose the subscription for the Workload zone"
        $Subscriptions = $(az account list --query "[].{Name:name}" -o table | Sort-Object)
        Show-Menu($Subscriptions[2..($Subscriptions.Length - 1)])

        $Selection = Read-Host $Title
        $SelectionOffset = [convert]::ToInt32($Selection, 10) + 1
        $WorkloadZoneSubscriptionName = $Subscriptions[$SelectionOffset]

        az account set --subscription $WorkloadZoneSubscriptionName
        $WorkloadZoneSubscriptionIdInternal = (az account show --query id -o tsv)
      }
      else {
        Write-Verbose "Setting subscription to: $WorkloadZoneSubscriptionIdInternal"
        az account set --sub $WorkloadZoneSubscriptionIdInternal
        $WorkloadZoneSubscriptionName = (az account show --query name -o tsv)
      }

      if ($WorkloadZoneSubscriptionName.Length -eq 0) {
        Write-Error "WorkloadZoneSubscriptionName is not set"
        return
      }
      Write-Verbose "Using subscription: $WorkloadZoneSubscriptionName ($WorkloadZoneSubscriptionIdInternal)"
      #endregion

      #region Validate organization and workload zone code
      Write-Host "Using Organization: $AdoOrganization" -foregroundColor Yellow
      Write-Verbose "ADO Organization validated: $AdoOrganization"

      Write-Host "Using Workload zone code: $WorkloadZoneCode" -foregroundColor Yellow
      Write-Verbose "Workload zone code validated: $WorkloadZoneCode"
      #endregion

      #region Set up prefixes

      if ($WorkloadZoneName.Length -ne 0) {
        $WorkloadZonePrefix = "SDAF-" + $WorkloadZoneName
      }
      else {
        $WorkloadZonePrefix = "SDAF-" + $WorkloadZoneCode
      }
      Write-Verbose "Workload zone prefix: $WorkloadZonePrefix"

      if ($ControlPlaneName.Length -eq 0) {
        $ControlPlanePrefix = "SDAF-" + $ControlPlaneCode
      }
      else {
        $ControlPlanePrefix = "SDAF-" + $ControlPlaneName
      }

      Write-Verbose "Control plane prefix: $ControlPlanePrefix"

      #endregion

      $ProjectId = (az devops project list --organization $AdoOrganization --query "[value[]] | [0] | [? name=='$AdoProject'].id | [0]" --out tsv)

      if ($ProjectId.Length -eq 0) {
        Write-Error "Project $AdoProject was not found in the Azure DevOps organization $AdoOrganization"
        throw "Project not found"
      }

      Write-Verbose "Setting Azure DevOps defaults: organization=$AdoOrganization project=$AdoProject"
      az devops configure --defaults organization=$AdoOrganization project="$AdoProject"

      $ControlPlaneVariableGroupId = (az pipelines variable-group list --query "[?name=='$ControlPlanePrefix'].id | [0]" --only-show-errors)
      $AgentPoolName = ""
      if ($ControlPlaneVariableGroupId.Length -ne 0) {
        $AgentPoolName = (az pipelines variable-group variable list --group-id $ControlPlaneVariableGroupId --query "POOL.value" --out tsv)
      }

      $ServiceConnectionName = $WorkloadZoneCode + "_WorkloadZone_Service_Connection"
      $WorkloadZoneVariableGroupId = (az pipelines variable-group list --query "[?name=='$WorkloadZonePrefix'].id | [0]" --only-show-errors)
      if ($WorkloadZoneVariableGroupId.Length -eq 0) {
        Write-Host "Creating the variable group" $WorkloadZonePrefix -ForegroundColor Green
        $WorkloadZoneVariableGroupId = (az pipelines variable-group create --name $WorkloadZonePrefix --variables AGENT='Azure Pipelines' POOL=$AgentPoolName ARM_TENANT_ID=$ArmTenantId ARM_SUBSCRIPTION_ID=$WorkloadZoneSubscriptionId AZURE_CONNECTION_NAME=$ServiceConnectionName TF_LOG=OFF --query id --output tsv --authorize true)
      }

      if ($AuthenticationMethod -eq "Managed Identity") {
        $Roles = @(
          "Contributor",
          "Role Based Access Control Administrator",
          "Storage Blob Data Owner",
          "Key Vault Administrator",
          "Key Vault Secret Officer",
          "App Configuration Data Owner"
        )

        if ($ManagedIdentityId.Length -ne 0) {
          $ResourceGroupName = $ManagedIdentityId.Split("/")[4]
          $ManagedIdentityClientId = $(az identity list --query "[?principalId=='$ManagedIdentityObjectId'].clientId" --subscription $ControlPlaneSubscriptionId --resource-group $ResourceGroupName --output tsv)
          Write-Verbose "Client ID of the Managed Identity: $ManagedIdentityClientId"
          if ($ManagedIdentityClientId.Length -eq 0) {
            Write-Error "Managed Identity with Object ID $ManagedIdentityObjectId was not found in subscription $ControlPlaneSubscriptionId"
            throw "Managed Identity not found"
          }

        }

        foreach ($RoleName in $Roles) {

          Write-Host "Assigning role $RoleName to the Managed Identity" -ForegroundColor Green
          Write-Verbose "Assigning role $RoleName to the Managed Identity ($ManagedIdentityObjectId)"
          $roleAssignment = az role assignment create --assignee-object-id $ManagedIdentityObjectId --role $RoleName --scope /subscriptions/$WorkloadZoneSubscriptionId --query id --output tsv --only-show-errors
          if ($roleAssignment) {
            Write-Host "Successfully assigned $RoleName role to identity" -ForegroundColor Green
            Write-Verbose "Role assignment ID: $roleAssignment"
          }
          else {
            Write-Warning "Identity created but role assignment may have failed"
          }
        }


        $ServiceEndpointExists = (az devops service-endpoint list --query "[?name=='$ServiceConnectionName'].name | [0]"  --out tsv)
        if ($ServiceEndpointExists.Length -eq 0) {
          CreateServiceConnection -ConnectionName $ServiceConnectionName `
            -ServiceConnectionDescription "$WorkloadZoneCode Service Connection" `
            -TenantId $ArmTenantId `
            -ManagedIdentityClientId $ManagedIdentityClientId `
            -SubscriptionId $WorkloadZoneSubscriptionId `
            -ProjectId $ProjectId `
            -ProjectName $AdoProject
          $ServiceEndpointId = az devops service-endpoint list --query "[?name=='$ServiceConnectionName'].id" -o tsv
          if ($ServiceEndpointId.Length -ne 0) {
            az devops service-endpoint update --id $ServiceEndpointId --enable-for-all true --output none --only-show-errors
          }
          SetVariableGroupVariable -VariableGroupId $WorkloadZoneVariableGroupId -VariableName "ARM_OBJECT_ID" -VariableValue $ManagedIdentityObjectId
          SetVariableGroupVariable -VariableGroupId $WorkloadZoneVariableGroupId -VariableName "ARM_CLIENT_ID" -VariableValue $ManagedIdentityClientId
          SetVariableGroupVariable -VariableGroupId $WorkloadZoneVariableGroupId -VariableName "USE_MSI" -VariableValue "true"
          SetVariableGroupVariable -VariableGroupId $WorkloadZoneVariableGroupId -VariableName "ARM_USE_MSI" -VariableValue "true"


        }
        else {
          Write-Host "Service Endpoint already exists, skipping creation." -ForegroundColor Yellow
        }
      }

      #region ServiceConnections

      if ($AuthenticationMethod -eq "Service Principal") {
        #region Workload zone Service Principal
        $ServicePrincipalName = $WorkloadZonePrefix + " Deployment credential"
        if ($Env:SDAF_MGMT_ServicePrincipalName.Length -ne 0) {
          $ServicePrincipalName = $Env:SDAF_MGMT_ServicePrincipalName
        }

        Add-Content -Path $WikiFileName -Value ("Workload zone Service Principal: " + $ServicePrincipalName)
        SetVariableGroupVariable -VariableGroupId $WorkloadZoneVariableGroupId -VariableName "USE_MSI" -VariableValue "false"

        $Scope = "/subscriptions/" + $WorkloadZoneSubscriptionId

        Write-Host "Creating the deployment credentials for the workload zone. Service Principal Name:" $ServicePrincipalName -ForegroundColor Green

        $WorkloadZoneClientId = ""
        $WorkloadZoneObjectId = ""
        $WorkloadZoneTenantId = ""
        $WorkloadZoneClientSecret = "Please update"

        $ServicePrincipalFound = (az ad sp list --all --filter "startswith(displayName, '$ServicePrincipalName')" --query "[?displayName=='$ServicePrincipalName'].displayName | [0]" --only-show-errors)
        if ($ServicePrincipalFound.Length -gt 0) {
          Write-Host "Found an existing Service Principal:" $ServicePrincipalName
          $ServicePrincipalInformation = (az ad sp list --all --filter "startswith(displayName, '$ServicePrincipalName')" --query  "[?displayName=='$ServicePrincipalName']| [0]" --only-show-errors) | ConvertFrom-Json
          Write-Host "Updating the variable group"

          $WorkloadZoneClientId = $ServicePrincipalInformation.appId
          $WorkloadZoneObjectId = $ServicePrincipalInformation.Id
          $WorkloadZoneTenantId = $ServicePrincipalInformation.appOwnerOrganizationId

          $confirmation = Read-Host "Reset the Workload zone Service Principal password y/n?"
          if ($confirmation -eq 'y') {

            $WorkloadZoneClientSecret = (az ad sp credential reset --id $WorkloadZoneClientId --append --query "password" --out tsv --only-show-errors).Replace("""", "")
          }
          else {
            $WorkloadZoneClientSecret = Read-Host "Please enter the Workload zone Service Principal $ServicePrincipalName password"
          }
        }
        else {
          Write-Host "Creating the Service Principal" $ServicePrincipalName -ForegroundColor Green
          $WorkloadZoneServicePrincipalData = (az ad sp create-for-rbac --role "Contributor" --scopes $Scope --name $ServicePrincipalName --only-show-errors  --service-management-reference $ServiceManagementReference) | ConvertFrom-Json
          $WorkloadZoneClientSecret = $WorkloadZoneServicePrincipalData.password
          $ServicePrincipalInformation = (az ad sp list --all --filter "startswith(displayName, '$ServicePrincipalName')" --query  "[?displayName=='$ServicePrincipalName'] | [0]" --only-show-errors) | ConvertFrom-Json
          $WorkloadZoneClientId = $ServicePrincipalInformation.appId
          $WorkloadZoneTenantId = $ServicePrincipalInformation.appOwnerOrganizationId
          $WorkloadZoneObjectId = $ServicePrincipalInformation.Id
        }

        foreach ($RoleName in $Roles) {

          Write-Host "Assigning role" $RoleName "to the workload zone Service Principal" -ForegroundColor Green
          az role assignment create --assignee $WorkloadZoneClientId --role $RoleName --scope /subscriptions/$WorkloadZoneSubscriptionId --output none --only-show-errors
        }

        SetVariableGroupVariable -VariableGroupId $WorkloadZoneVariableGroupId -VariableName "ARM_CLIENT_ID" -VariableValue $WorkloadZoneClientClientId
        SetVariableGroupVariable -VariableGroupId $WorkloadZoneVariableGroupId -VariableName "ARM_CLIENT_SECRET" -VariableValue $WorkloadZoneClientSecret -IsSecret
        SetVariableGroupVariable -VariableGroupId $WorkloadZoneVariableGroupId -VariableName "ARM_OBJECT_ID" -VariableValue $WorkloadZoneClientObjectId
        SetVariableGroupVariable -VariableGroupId $WorkloadZoneVariableGroupId -VariableName "USE_MSI" -VariableValue "false"
        SetVariableGroupVariable -VariableGroupId $WorkloadZoneVariableGroupId -VariableName "ARM_USE_MSI" -VariableValue "false"

        Write-Host "Create the Service Endpoint in Azure for the workload zone" -ForegroundColor Green

        $ServiceConnectionName = $WorkloadZoneCode + "_WorkloadZone_Service_Connection"
        $Env:AZURE_DEVOPS_EXT_AZURE_RM_SERVICE_PRINCIPAL_KEY = $WorkloadZoneClientSecret

        $ServiceConnectionExists = (az devops service-endpoint list --query "[?name=='$ServiceConnectionName'].name | [0]")
        if ($ServiceConnectionExists.Length -eq 0) {
          Write-Host "Creating Service Endpoint" $ServiceConnectionName -ForegroundColor Green
          az devops service-endpoint azurerm create --azure-rm-service-principal-id $WorkloadZoneClientId --azure-rm-subscription-id $WorkloadZoneSubscriptionId --azure-rm-subscription-name $WorkloadZoneSubscriptionName --azure-rm-tenant-id $WorkloadZoneTenantId --name $ServiceConnectionName --output none --only-show-errors
          if ($LASTEXITCODE -ne 0) {
            Write-Error "Failed to create service connection '$ServiceConnectionName'"
            throw "Service connection creation failed"
          }
          Write-Host "Service connection '$ServiceConnectionName' created successfully." -ForegroundColor Green
          $ServiceConnectionId = az devops service-endpoint list --query "[?name=='$ServiceConnectionName'].id" -o tsv
          az devops service-endpoint update --id $ServiceConnectionId --enable-for-all true --output none --only-show-errors
          if ($LASTEXITCODE -ne 0) {
            Write-Error "Failed to enable service connection '$ServiceConnectionName' for all pipelines"
            throw "Service connection update failed"
          }
        }
        else {
          Write-Host "Service Endpoint already exists, recreating it with the updated credentials" -ForegroundColor Green
          $ServiceConnectionId = az devops service-endpoint list --query "[?name=='$ServiceConnectionName'].id" -o tsv
          az devops service-endpoint delete --id $ServiceConnectionId --yes
          if ($LASTEXITCODE -ne 0) {
            Write-Error "Failed to delete existing service connection '$ServiceConnectionName'"
            throw "Service connection deletion failed"
          }
          az devops service-endpoint azurerm create --azure-rm-service-principal-id $WorkloadZoneClientId --azure-rm-subscription-id $WorkloadZoneSubscriptionId --azure-rm-subscription-name $WorkloadZoneSubscriptionName --azure-rm-tenant-id $WorkloadZoneTenantId --name $ServiceConnectionName --output none --only-show-errors
          if ($LASTEXITCODE -ne 0) {
            Write-Error "Failed to recreate service connection '$ServiceConnectionName'"
            throw "Service connection creation failed"
          }
          Write-Host "Service connection '$ServiceConnectionName' recreated successfully." -ForegroundColor Green
          $ServiceConnectionId = az devops service-endpoint list --query "[?name=='$ServiceConnectionName'].id" -o tsv
          az devops service-endpoint update --id $ServiceConnectionId --enable-for-all true --output none --only-show-errors
          if ($LASTEXITCODE -ne 0) {
            Write-Error "Failed to enable service connection '$ServiceConnectionName' for all pipelines"
            throw "Service connection update failed"
          }
        }
      }

      Write-Host "The script has completed" -ForegroundColor Green
      Write-Verbose "New-SDAFADOWorkloadZone cmdlet completed successfully"

    }
    catch {
      Write-Error "An error occurred during execution: $($_.Exception.Message)"
      Write-Verbose "Error details: $($_.Exception.ToString())"
      throw
    }
  }

  end {
    Write-Verbose "New-SDAFADOWorkloadZone cmdlet finished"
  }
}

# Export the function
Export-ModuleMember -Function New-SDAFADOWorkloadZone
