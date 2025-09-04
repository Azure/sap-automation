function Copy-AzDevOpsVariableGroupVariable {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ProjectName,

        [Parameter(Mandatory = $true)]
        [string]$VariableGroupNameSource,

        [Parameter(Mandatory = $true)]
        [string]$VariableGroupNameTarget,

        [Parameter(Mandatory = $false)]
        [string]$VariableName = "ARM_CLIENT_ID",

        [Parameter(Mandatory = $false)]
        [string]$TargetVariableName = "ARM_CLIENT_ID",

        [Parameter(Mandatory = $false)]
        [string]$Organization
    )

    begin {
        Write-Verbose "Starting copy of variable '$VariableName' from '$VariableGroupNameSource' to '$VariableGroupNameTarget'"

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
            Write-Host "Looking up source variable group '$VariableGroupNameSource'..." -ForegroundColor Yellow
            $sourceGroupId = az pipelines variable-group list --query "[?name=='$VariableGroupNameSource'].id | [0]" --only-show-errors -o tsv

            if (-not $sourceGroupId -or $sourceGroupId -eq "null") {
                Write-Error "Source variable group '$VariableGroupNameSource' not found in project '$ProjectName'"
                return
            }
            Write-Verbose "Source variable group ID: $sourceGroupId"

            # Get target variable group ID
            Write-Host "Looking up target variable group '$VariableGroupNameTarget'..." -ForegroundColor Yellow
            $targetGroupId = az pipelines variable-group list --query "[?name=='$VariableGroupNameTarget'].id | [0]" --only-show-errors -o tsv

            if (-not $targetGroupId -or $targetGroupId -eq "null") {
                Write-Error "Target variable group '$VariableGroupNameTarget' not found in project '$ProjectName'"
                return
            }
            Write-Verbose "Target variable group ID: $targetGroupId"

            # Get the variable value from source group
            Write-Host "Retrieving variable '$VariableName' from source group..." -ForegroundColor Yellow
            $sourceVariableValue = az pipelines variable-group variable list --group-id $sourceGroupId --query "$VariableName.value" --only-show-errors -o tsv

            if (-not $sourceVariableValue -or $sourceVariableValue -eq "null") {
                Write-Error "Variable '$VariableName' not found in source variable group '$VariableGroupNameSource'"
                return
            }
            Write-Verbose "Retrieved variable value from source group"

            if ($targetGroupId -eq $sourceGroupId) {

                if( $VariableName.ToUpper() -eq $TargetVariableName.ToUpper() ) {
                  Write-Warning "Source and target variable groups are the same. Removing source variable"
                  az pipelines variable-group variable delete --group-id $targetGroupId --name $VariableName --output none --only-show-errors
                }
            }

            # Check if variable exists in target group
            $targetVariableExists = az pipelines variable-group variable list --group-id $targetGroupId --query "$TargetVariableName.value" --only-show-errors -o tsv 2>$null

            if ($targetVariableExists -and $targetVariableExists -ne "null") {
                Write-Host "Variable '$TargetVariableName' already exists in target group. Updating..." -ForegroundColor Yellow

                # Update existing variable
                az pipelines variable-group variable update --group-id $targetGroupId --name $TargetVariableName --value $sourceVariableValue --output none --only-show-errors

                if ($LASTEXITCODE -eq 0) {
                    Write-Host "Successfully updated variable '$TargetVariableName' in target variable group '$VariableGroupNameTarget'" -ForegroundColor Green
                }
                else {
                    Write-Error "Failed to update variable '$TargetVariableName' in target variable group"
                    return
                }
            }
            else {
                Write-Host "Variable '$TargetVariableName' does not exist in target group. Creating..." -ForegroundColor Yellow

                # Create new variable
                az pipelines variable-group variable create --group-id $targetGroupId --name $TargetVariableName --value $sourceVariableValue --output none --only-show-errors

                if ($LASTEXITCODE -eq 0) {
                    Write-Host "Successfully created variable '$TargetVariableName' in target variable group '$VariableGroupNameTarget'" -ForegroundColor Green
                }
                else {
                    Write-Error "Failed to create variable '$TargetVariableName' in target variable group"
                    return
                }
            }

            # Return summary information
            return [PSCustomObject]@{
                ProjectName = $ProjectName
                SourceVariableGroup = $VariableGroupNameSource
                TargetVariableGroup = $VariableGroupNameTarget
                VariableName = $VariableName
                TargetVariableName = $TargetVariableName
                SourceGroupId = $sourceGroupId
                TargetGroupId = $targetGroupId
                Operation = if ($targetVariableExists -and $targetVariableExists -ne "null") { "Updated" } else { "Created" }
                Success = $true
            }
        }
        catch {
            Write-Error "An error occurred while copying the variable: $_"
            return [PSCustomObject]@{
                ProjectName = $ProjectName
                SourceVariableGroup = $VariableGroupNameSource
                TargetVariableGroup = $VariableGroupNameTarget
                VariableName = $VariableName
                Operation = "Failed"
                Success = $false
                Error = $_.Exception.Message
            }
        }
    }

    end {
        Write-Verbose "Completed variable copy operation"
    }
}

# Export the function if this script is being imported as a module
Export-ModuleMember -Function Copy-AzDevOpsVariableGroupVariable
