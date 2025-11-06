<#
.SYNOPSIS
  Upgrade / migrate Azure DevOps variable names within a variable group for SDAF.

.DESCRIPTION
  This script imports the SDAFUtilities module and updates (copies) variables in an Azure DevOps
  variable group. It supports authenticating either via Managed Identity (MSI) or via an
  existing Service Principal (by name). The script expects configuration via environment
  variables (see PARAMETERS section).

  The script:
  - Validates required environment variables
  - Ensures Azure CLI authentication and sets the target subscription
  - Imports the local `SDAFUtilities` PowerShell module
  - Calls helper functions to set credentials in ADO (MSI or SPN)
  - Copies a series of variable names from source to target within the same variable group

PARAMETERS / ENVIRONMENT VARIABLES
  SDAF_ADO_ORGANIZATION            (optional) Azure DevOps organization (mapped to $ADO_Organization)
  SDAF_ADO_PROJECT                 (required) Azure DevOps project name (mapped to $ADO_Project)
  ARM_TENANT_ID                    (required) Azure AD tenant id (mapped to $ARM_TENANT_ID)
  VariableGroupName                (required) Name of the ADO variable group to update
  ControlPlaneVariableGroupName    (required) Name of the control plane ADO variable group
  UseMSI                           (optional) If truthy, use Managed Identity flow
  ServicePrincipalName             (required when UseMSI is false) Name of service principal to use
  ManagedIdentity                  (required when UseMSI is true) Managed identity name or id
  ManagedIdentityResourceGroup     (required when UseMSI is true) Resource group containing the identity
  ManagedIdentitySubscriptionId    (required) Subscription id to use for az account set

USAGE
  See header examples (above). This script should be run as a .ps1 file so $PSScriptRoot resolves correctly.
#>

# ------------------------
# Environment / parameters
# ------------------------
# Read configuration from environment variables. These map to the values described in the header.
$ADO_Organization = $Env:SDAF_ADO_ORGANIZATION
$ADO_Project = $Env:SDAF_ADO_PROJECT
$ARM_TENANT_ID = $Env:ARM_TENANT_ID

# Variable group name to operate on (required)
$VariableGroupName = $Env:VariableGroupName
if ( -not $VariableGroupName ) {
  Write-Error "VariableGroupName environment variable is not set."
  exit 1
}

$ControlPlaneVariableGroupName = $Env:ControlPlaneVariableGroupName

# ------------------------
# Boolean / flow selection
# ------------------------
# Decide whether to use Managed Identity (MSI) or Service Principal (SPN).
# The script expects $env:UseMSI in common truthy/falsey forms (true|false|1|0|yes|no).
$UseMSI = $true
if (-not [string]::IsNullOrWhiteSpace($env:UseMSI)) {
  try {
    $UseMSI = [System.Convert]::ToBoolean($env:UseMSI)
  }
  catch {
  }
}

# ------------------------
# Credential / identity inputs
# ------------------------
# Depending on MSI vs SPN, some of these are required.
$ServicePrincipalName = $Env:ServicePrincipalName
$ManagedIdentity = $Env:ManagedIdentity
$ManagedIdentityResourceGroup = $Env:ManagedIdentityResourceGroup
$ManagedIdentitySubscriptionId = $Env:ManagedIdentitySubscriptionId


# Validate essential ADO and ARM inputs - these are required for the script to run
if ( -not $ADO_Project ) {
  Write-Error "ADO_Project environment variable is not set."
  exit 1
}
if ( -not $ADO_Organization ) {
  Write-Error "ADO_Organization environment variable is not set."
  exit 1
}
if ( -not $ARM_TENANT_ID ) {
  Write-Error "ARM_TENANT_ID environment variable is not set."
  exit 1
}

# Validate MSI vs SPN required parameters and provide clear error messages
if ( $UseMSI -and ( -not $ManagedIdentity -or -not $ManagedIdentityResourceGroup -or -not $ManagedIdentitySubscriptionId) ) {
  Write-Error "When using Managed Identity, all of ManagedIdentity, ManagedIdentityResourceGroup, and ManagedIdentitySubscriptionId environment variables must be set."
  exit 1
}
if ( -not $UseMSI -and ( -not $ServicePrincipalName ) ) {
  Write-Error "When not using Managed Identity, ServicePrincipalName environment variable must be set."
  exit 1
}

# ------------------------
# Azure CLI authentication check
# ------------------------
# Ensure the user is logged in to Azure CLI. az account show returns the current signed-in user.
$userName = az account show --query user.name --output tsv
if (-not $userName -or $userName -eq "null") {
  Write-Error "Please login to Azure CLI using 'az login' and try again."
  return
}


Write-Output "Logged in as: $userName"

# ------------------------
# Module import: SDAFUtilities
# ------------------------
# Resolve module relative to the running script's folder. $PSScriptRoot requires the script to be executed as a file.
$ModulePath = Join-Path $PSScriptRoot "pwsh" "Output" "SDAFUtilities" "SDAFUtilities.psm1"

# Ensure the module exists at the expected path to avoid silent failures later.
if (-not (Test-Path $ModulePath)) {
  Write-Error "Module path not found: $ModulePath"
  exit 1
}

# Import helper functions used below (Set-AdoManagedIdentityCredentials, Set-AdoSPNCredentials, Copy-AzDevOpsVariableGroupVariable)
Import-Module $ModulePath -Verbose

# Verify import succeeded
if (-not (Get-Module -Name "SDAFUtilities")) {
  Write-Error "Failed to import module: SDAFUtilities"
  exit 1
}

# ------------------------
# Wire ADO credentials (MSI or SPN)
# ------------------------
# These helper functions are provided by SDAFUtilities. They register credentials/service-connection
# information into the Azure DevOps project variable group specified by $VariableGroupName so later
# pipeline runs can use them securely.
if ( $UseMSI ) {
  # Managed Identity flow:
  # - uses the ManagedIdentity resource in the specified resource group and subscription
  # - is suitable when the agent or calling identity can access the MSI
  # Set the target subscription to the one that contains the Managed Identity resources (or your target subscription)
  az account set --subscription $ManagedIdentitySubscriptionId
  Set-AdoManagedIdentityCredentials -ProjectName $ADO_Project -ManagedIdentity $ManagedIdentity -ResourceGroupName $ManagedIdentityResourceGroup -SubscriptionId $ManagedIdentitySubscriptionId -VariableGroupName $VariableGroupName -Verbose
}
else {
  # Service Principal flow:
  # - requires a pre-existing service principal name that the helper will locate and wire into ADO
  Set-AdoSPNCredentials -ProjectName $ADO_Project -ServicePrincipalName $ServicePrincipalName -VariableGroupName $VariableGroupName -Verbose
}

# ------------------------
# Variable rename / copy operations
# ------------------------
# Each call below calls a helper that reads the named variable from the source variable group and
# creates/updates the target variable with the mapped name.
# The helpers will typically preserve secrecy flags when copying secret variables; check SDAFUtilities implementation for details.

# Map Deployer_Key_Vault -> DEPLOYER_KEYVAULT
Copy-AzDevOpsVariableGroupVariable -ProjectName $ADO_Project -VariableGroupNameSource $VariableGroupName -VariableGroupNameTarget $VariableGroupName -VariableName "Deployer_Key_Vault" -TargetVariableName "DEPLOYER_KEYVAULT"  -Verbose

# Map Deployer_State_FileName -> DEPLOYER_STATE_FILENAME
Copy-AzDevOpsVariableGroupVariable -ProjectName $ADO_Project -VariableGroupNameSource $VariableGroupName -VariableGroupNameTarget $VariableGroupName -VariableName "Deployer_State_FileName" -TargetVariableName "DEPLOYER_STATE_FILENAME"  -Verbose

# Map Terraform_Remote_Storage_Account_Name -> TERRAFORM_REMOTE_STORAGE_ACCOUNT_NAME
Copy-AzDevOpsVariableGroupVariable -ProjectName $ADO_Project -VariableGroupNameSource $VariableGroupName -VariableGroupNameTarget $VariableGroupName -VariableName "Terraform_Remote_Storage_Account_Name" -TargetVariableName "TERRAFORM_REMOTE_STORAGE_ACCOUNT_NAME"  -Verbose

# Map WL_ARM_SUBSCRIPTION_ID -> ARM_SUBSCRIPTION_ID
# This maps the workload zone subscription id variable to the standardized ARM_SUBSCRIPTION_ID name.
Copy-AzDevOpsVariableGroupVariable -ProjectName $ADO_Project -VariableGroupNameSource $VariableGroupName -VariableGroupNameTarget $VariableGroupName -VariableName "WL_ARM_SUBSCRIPTION_ID" -TargetVariableName "ARM_SUBSCRIPTION_ID"  -Verbose

# Map USE_MSI -> ARM_USE_MSI
# This maps the workload zone use msi variable to the standardized ARM_USE_MSI name.
Copy-AzDevOpsVariableGroupVariable -ProjectName $ADO_Project -VariableGroupNameSource $VariableGroupName -VariableGroupNameTarget $VariableGroupName -VariableName "USE_MSI" -TargetVariableName "ARM_USE_MSI"  -Verbose


# Copy values from control plane variable group to workload zone variable group
Copy-AzDevOpsVariableGroupVariable -ProjectName $ADO_Project -VariableGroupNameSource $ControlPlaneVariableGroupName -VariableGroupNameTarget $VariableGroupName -VariableName "DEPLOYER_KEYVAULT" -TargetVariableName "DEPLOYER_KEYVAULT"  -Verbose

Copy-AzDevOpsVariableGroupVariable -ProjectName $ADO_Project -VariableGroupNameSource $ControlPlaneVariableGroupName -VariableGroupNameTarget $VariableGroupName -VariableName "TERRAFORM_REMOTE_STORAGE_ACCOUNT_NAME" -TargetVariableName "TERRAFORM_REMOTE_STORAGE_ACCOUNT_NAME"  -Verbose


Write-Host "Variable group upgrade completed." -ForegroundColor Green
exit 0
