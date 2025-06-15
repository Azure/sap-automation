function Remove-SDAFUserAssignedIdentity {
  [CmdletBinding()]
  param (
    [Parameter(Mandatory = $true)]
    [string]$ManagedIdentityName,

    [Parameter(Mandatory = $true)]
    [string]$ResourceGroupName,

    [Parameter(Mandatory = $true)]
    [string]$SubscriptionId
  )

  begin {
    Write-Verbose "Starting removal of user-assigned identity: $ManagedIdentityName"

    # Ensure Azure CLI is logged in
    try {
      $account = az account show --query name -o tsv
      if (-not $account) {
        throw "Not logged in to Azure CLI"
      }
      Write-Verbose "Currently logged in to Azure account: $account"
    }
    catch {
      Write-Error "Please login to Azure CLI first using 'az login'"
      return
    }
    # Set the subscription context
    try {
      az account set --subscription $SubscriptionId
      Write-Verbose "Set subscription context to: $SubscriptionId"
    }
    catch {
      Write-Error "Failed to set subscription context to $SubscriptionId. Please verify the subscription ID is correct."
      return
    }

    # Verify resource group exists
    try {
      $rgExists = az group exists --name $ResourceGroupName
      if ($rgExists -eq "false") {
        Write-Error "Resource group '$ResourceGroupName' does not exist in subscription '$SubscriptionId'"
        return
      }
      Write-Verbose "Resource group '$ResourceGroupName' exists"
    }
    catch {
      Write-Error "Failed to verify resource group existence: $_"
      return
    }
  }

  process {
    try {
      Write-Host "Removing user-assigned identity '$ManagedIdentityName' in resource group '$ResourceGroupName'..." -ForegroundColor Yellow

      # Create the user-assigned identity
      az identity delete `
        --name $ManagedIdentityName `
        --resource-group $ResourceGroupName `
        --subscription $SubscriptionId

    }
    catch {
      Write-Error "An error occurred while creating the identity: $_"
      return
    }
  }

  end {
    Write-Verbose "Completed removal of user-assigned identity: $ManagedIdentityName"
  }
}


# Export the function
Export-ModuleMember -Function Remove-SDAFUserAssignedIdentity
