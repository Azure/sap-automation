function New-SDAFUserAssignedIdentity {
  [CmdletBinding()]
  param (
    [Parameter(Mandatory = $true)]
    [string]$ManagedIdentityName,

    [Parameter(Mandatory = $true)]
    [string]$ResourceGroupName,

    [Parameter(Mandatory = $true)]
    [string]$SubscriptionId,

    [Parameter(Mandatory = $true)]
    [string]$Location
  )

  begin {
    $Roles = @(
      "Contributor",
      "Storage Blob Data Owner",
      "Key Vault Administrator",
      "Key Vault Secrets Officer",
      "App Configuration Data Owner",
      "Network Contributor"
    )

    Write-Verbose "Starting creation of user-assigned identity: $ManagedIdentityName"

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
      $rgExists = az group exists --name $ResourceGroupName --subscription $SubscriptionId
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
      Write-Host "Creating user-assigned identity '$ManagedIdentityName' in resource group '$ResourceGroupName'..." -ForegroundColor Yellow

      # Create the user-assigned identity
      $identity = az identity create `
        --name $ManagedIdentityName `
        --resource-group $ResourceGroupName `
        --location $Location `
        --query "{id:id, principalId:principalId, clientId:clientId}" `
        -o json | ConvertFrom-Json

      if ($identity) {
        Write-Host "Successfully created user-assigned identity '$ManagedIdentityName'" -ForegroundColor Green
        Write-Verbose "Identity ID: $($identity.id)"
        Write-Verbose "Principal ID: $($identity.principalId)"
        Write-Verbose "Client ID: $($identity.clientId)"

        foreach ($RoleName in $Roles) {

          Write-Host "Assigning role" $RoleName "to the Managed Identity" -ForegroundColor Green
          $roleAssignment = az role assignment create --assignee-object-id $identity.principalId --assignee-principal-type ServicePrincipal --role $RoleName --scope /subscriptions/$SubscriptionId --query id --output tsv --only-show-errors
          if ($roleAssignment) {
            Write-Host "Successfully assigned $RoleName role to identity" -ForegroundColor Green
            Write-Verbose "Role assignment ID: $roleAssignment"
          }
          else {
            Write-Warning "Identity created but role assignment may have failed"
          }
        }

        $RoleName = "User Access Administrator"
        $Condition = "( ( !(ActionMatches{'Microsoft.Authorization/roleAssignments/write'}) ) OR  (  @Request[Microsoft.Authorization/roleAssignments:RoleDefinitionId] ForAnyOfAllValues:GuidNotEquals {8e3af657-a8ff-443c-a75c-2fe8c4bcb635, 18d7d88d-d35e-4fb5-a5c3-7773c20a72d9} )) AND ( (  !(ActionMatches{'Microsoft.Authorization/roleAssignments/delete'}) ) OR  (  @Resource[Microsoft.Authorization/roleAssignments:RoleDefinitionId] ForAnyOfAllValues:GuidNotEquals {8e3af657-a8ff-443c-a75c-2fe8c4bcb635, 18d7d88d-d35e-4fb5-a5c3-7773c20a72d9} ))"

        $roleAssignment = az role assignment create --assignee-object-id $identity.principalId --assignee-principal-type ServicePrincipal --role $RoleName --scope /subscriptions/$SubscriptionId --query id --condition-version "2.0" --condition $Condition --output tsv --only-show-errors
        if ($roleAssignment) {
          Write-Host "Successfully assigned $RoleName role with condition to identity" -ForegroundColor Green
          Write-Verbose "Role assignment ID: $roleAssignment"
        }
        else {
          Write-Warning "Identity created but conditional role assignment may have failed"
        }
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
        Write-Error "Failed to create user-assigned identity"
        return
      }
    }
    catch {
      Write-Error "An error occurred while creating the identity: $_"
      return
    }
  }

  end {
    Write-Verbose "Completed creation of user-assigned identity: $ManagedIdentityName"
  }
}


# Export the function
Export-ModuleMember -Function New-SDAFUserAssignedIdentity
