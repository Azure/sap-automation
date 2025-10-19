function Get-SDAFUserAssignedIdentity {
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

    Write-Verbose "Starting retrieval of user-assigned identity: $ManagedIdentityName"

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
      Write-Host "Retrieving user-assigned identity '$ManagedIdentityName' in resource group '$ResourceGroupName'..." -ForegroundColor Yellow

      # Get the user-assigned identity
      $identity = az identity list `
        --resource-group $ResourceGroupName `
        --query "[?name=='$ManagedIdentityName'].{id:id, principalId:principalId, clientId:clientId}" `
        -o json | ConvertFrom-Json

      if ($identity) {
        Write-Host "Successfully retrieved user-assigned identity '$ManagedIdentityName'" -ForegroundColor Green
        Write-Verbose "Identity ID: $($identity.id)"
        Write-Verbose "Principal ID: $($identity.principalId)"
        Write-Verbose "Client ID: $($identity.clientId)"

        # Return the identity object
        return [PSCustomObject]@{
          Name             = $ManagedIdentityName
          ResourceGroup    = $ResourceGroupName
          SubscriptionId   = $SubscriptionId
          IdentityId       = $identity.id
          PrincipalId      = $identity.principalId
          ClientId         = $identity.clientId
          RoleAssignmentId = $roleAssignment
        }
      }
      else {
        Write-Error "Failed to retrieve user-assigned identity"
        return
      }
    }
    catch {
      Write-Error "An error occurred while retrieving the identity: $_"
      return
    }
  }

  end {
    Write-Verbose "Completed retrieval of user-assigned identity: $ManagedIdentityName"
  }
}


# Export the function
Export-ModuleMember -Function Get-SDAFUserAssignedIdentity
