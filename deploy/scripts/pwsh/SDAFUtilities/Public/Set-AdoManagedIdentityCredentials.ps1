function Set-AdoManagedIdentityCredentials {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ProjectName,

        [Parameter(Mandatory = $true)]
        [string]$ManagedIdentity,

        [Parameter(Mandatory = $true)]
        [string]$ResourceGroupName,

        [Parameter(Mandatory = $true)]
        [string]$VariableGroupName,

        [Parameter(Mandatory = $false)]
        [string]$Organization,

        [Parameter(Mandatory = $false)]
        [string]$SubscriptionId

    )

    begin {
        Write-Verbose "Starting setting of managed identity '$ManagedIdentity' for variable group '$VariableGroupName' in subscription '$SubscriptionId'"

        # Ensure Azure CLI and DevOps extension are available
        try {
            $cliVersion = az --version 2>$null
            if (-not $cliVersion) {
                throw "Azure CLI not found"
            }
            Write-Verbose "Azure CLI is available"
        }
        catch {
            Write-Error "Azure CLI is required but not found. Please install Azure CLI first."
            return
        }

        # Check if DevOps extension is installed
        try {
            $devopsExtension = az extension list --query "[?name=='azure-devops'].name | [0]" -o tsv 2>$null
            if (-not $devopsExtension) {
                Write-Host "Installing Azure DevOps CLI extension..." -ForegroundColor Yellow
                az extension add --name azure-devops --output none
            }
            Write-Verbose "Azure DevOps CLI extension is available"
        }
        catch {
            Write-Error "Failed to install Azure DevOps CLI extension: $_"
            return
        }

        # Set organization context if provided
        if ($Organization) {
            try {
                az devops configure --defaults organization=$Organization project=$ProjectName
                Write-Verbose "Set Azure DevOps context to organization: $Organization, project: $ProjectName"
            }
            catch {
                Write-Error "Failed to set Azure DevOps context: $_"
                return
            }
        }
        else {
            # Just set the project
            try {
                az devops configure --defaults project=$ProjectName
                Write-Verbose "Set Azure DevOps project context to: $ProjectName"
            }
            catch {
                Write-Error "Failed to set Azure DevOps project context: $_"
                return
            }
        }
    }

    process {
        try {
            # Get source variable group ID
            Write-Host "Looking up source variable group '$VariableGroupName'..." -ForegroundColor Yellow
            $sourceGroupId = az pipelines variable-group list --query "[?name=='$VariableGroupName'].id | [0]" --only-show-errors -o tsv

            if (-not $sourceGroupId -or $sourceGroupId -eq "null") {
                Write-Error "Source variable group '$VariableGroupName' not found in project '$ProjectName'"
                return
            }
            Write-Verbose "Source variable group ID: $sourceGroupId"

            try {
                $identity = az identity show --name $ManagedIdentity --resource-group $ResourceGroupName --subscription $SubscriptionId --output json  | ConvertFrom-Json
                if (-not $identity -or $identity -eq "null") {
                    Write-Error "Managed identity '$ManagedIdentity' not found in resource group '$ResourceGroupName'"
                    return
                }

                Write-Output $identity

                # Set the managed identity for the target variable group
                Write-Host "Setting managed identity '$ManagedIdentity' for target variable group..." -ForegroundColor Yellow

                # Get the variable value from source group
                $VariableName = "ARM_CLIENT_ID"
                Write-Host "Retrieving variable '$VariableName' from source group..." -ForegroundColor Yellow
                $sourceVariableValue = az pipelines variable-group variable list --group-id $sourceGroupId --query "$VariableName.value" --only-show-errors -o tsv

                if (-not $sourceVariableValue -or $sourceVariableValue -eq "null") {
                    Write-Verbose "Variable '$VariableName' not found in source variable group '$VariableGroupName'"
                    az pipelines variable-group variable create --group-id $sourceGroupId --name $VariableName --value $identity.clientId --output none --only-show-errors
                }
                else {
                    az pipelines variable-group variable update --group-id $sourceGroupId --name $VariableName --value $identity.clientId --output none --only-show-errors
                }
                Write-Verbose "Updated variable $VariableName in variable group"

                # Get the variable value from source group
                $VariableName = "ARM_OBJECT_ID"
                Write-Host "Retrieving variable '$VariableName' from source group..." -ForegroundColor Yellow
                $sourceVariableValue = az pipelines variable-group variable list --group-id $sourceGroupId --query "$VariableName.value" --only-show-errors -o tsv

                if (-not $sourceVariableValue -or $sourceVariableValue -eq "null") {
                    Write-Verbose "Variable '$VariableName' not found in source variable group '$VariableGroupName'"
                    az pipelines variable-group variable create --group-id $sourceGroupId --name $VariableName --value $identity.principalId --output none --only-show-errors
                }
                else {
                    az pipelines variable-group variable update --group-id $sourceGroupId --name $VariableName --value $identity.principalId --output none --only-show-errors
                }
                Write-Verbose "Updated variable $VariableName in variable group"

                # Get the variable value from source group
                $VariableName = "ARM_TENANT_ID"
                Write-Host "Retrieving variable '$VariableName' from source group..." -ForegroundColor Yellow
                $sourceVariableValue = az pipelines variable-group variable list --group-id $sourceGroupId --query "$VariableName.value" --only-show-errors -o tsv

                if (-not $sourceVariableValue -or $sourceVariableValue -eq "null") {
                    Write-Verbose "Variable '$VariableName' not found in source variable group '$VariableGroupName'"
                    az pipelines variable-group variable create --group-id $sourceGroupId --name $VariableName --value $identity.tenantId --output none --only-show-errors
                }
                else {
                    az pipelines variable-group variable update --group-id $sourceGroupId --name $VariableName --value $identity.tenantId --output none --only-show-errors
                }

                $VariableName = "ARM_USE_MSI"
                Write-Host "Retrieving variable '$VariableName' from source group..." -ForegroundColor Yellow
                $sourceVariableValue = az pipelines variable-group variable list --group-id $sourceGroupId --query "$VariableName.value" --only-show-errors -o tsv

                if (-not $sourceVariableValue -or $sourceVariableValue -eq "null") {
                    Write-Verbose "Variable '$VariableName' not found in source variable group '$VariableGroupName'"
                    az pipelines variable-group variable create --group-id $sourceGroupId --name $VariableName --value "true" --output none --only-show-errors
                }
                else {
                    az pipelines variable-group variable update --group-id $sourceGroupId --name $VariableName --value "true" --output none --only-show-errors
                }

                Write-Verbose "Updated variable $VariableName in variable group"


            }
            catch {
                Write-Error "Failed to set Azure DevOps project context: $_"
                return
            }

            if ($LASTEXITCODE -eq 0) {
                Write-Host "Successfully set managed identity for target variable group '$VariableGroupNameTarget'" -ForegroundColor Green
            }
            else {
                Write-Error "Failed to set managed identity for target variable group"
                return
            }

            # Return summary information
            return [PSCustomObject]@{
                ProjectName         = $ProjectName
                SourceVariableGroup = $VariableGroupName
                Success             = $true
            }
        }
        catch {
            Write-Error "An error occurred while copying the variable: $_"
            return [PSCustomObject]@{
                ProjectName         = $ProjectName
                SourceVariableGroup = $VariableGroupName
                Success             = $false
                Error               = $_.Exception.Message
            }
        }
    }

    end {
        Write-Verbose "Completed variable copy operation"
    }
}

# Export the function if this script is being imported as a module
#
Export-ModuleMember -Function Set-AdoManagedIdentityCredentials
