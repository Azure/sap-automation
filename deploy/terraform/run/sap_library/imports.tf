# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

/*
    Description:
      Import deployer resources
*/
data "azurerm_client_config" "current" {
                                         provider                   = azurerm.deployer
                                       }

data "terraform_remote_state" "deployer"          {
                                                    backend =    "azurerm"
                                                    count        = var.use_deployer && length(var.deployer_tfstate_key) > 0 ? 1 : 0
                                                    config       = {
                                                                     resource_group_name  = local.SAPLibrary_resource_group_name
                                                                     storage_account_name = local.tfstate_storage_account_name
                                                                     container_name       = local.tfstate_container_name
                                                                     key                  = var.deployer_tfstate_key
                                                                     subscription_id      = local.SAPLibrary_subscription_id
                                                                     use_msi              = true
                                                                     use_azuread_auth     = true
                                                                   }
                                                  }

locals {
  # Determine effective naming based on configuration
  use_control_plane_naming                     = length(trimspace(var.control_plane_name)) > 0
  environment_name                             = local.use_control_plane_naming ? var.control_plane_name : var.environment

  # Control plane naming resolution
  control_plane_name_resolved                  = coalesce(
                                                    var.control_plane_name,
                                                    try(data.terraform_remote_state.deployer[0].outputs.environment, "")
                                                  )


  # Conditions for credential retrieval
  retrieve_subscription_from_kv                = length(var.subscription_id) == 0 && var.use_spn
  retrieve_cp_credentials                      = var.use_spn && length(local.control_plane_name_resolved) > 0
}


#
# Control Plane Service Principal Credentials
# Used for accessing shared control plane resources
#

data "azurerm_key_vault_secret" "subscription_id" {
  count                                        = local.retrieve_cp_credentials ? 1 : 0
  name                                         = format("%s-subscription-id", local.control_plane_name_resolved)
  key_vault_id                                 = local.key_vault.id

  timeouts {
    read = "1m"
  }
}

data "azurerm_key_vault_secret" "client_id" {
  count                                        = local.retrieve_cp_credentials ? 1 : 0
  name                                         = format("%s-client-id", local.control_plane_name_resolved)
  key_vault_id                                 = local.key_vault.id

  timeouts {
    read = "1m"
  }
}

ephemeral "azurerm_key_vault_secret" "client_secret" {
  count                                        = local.retrieve_cp_credentials ? 1 : 0
  name                                         = format("%s-client-secret", local.control_plane_name_resolved)
  key_vault_id                                 = local.key_vault.id
}

data "azurerm_key_vault_secret" "tenant_id" {
  count                                        = local.retrieve_cp_credentials ? 1 : 0
  name                                         = format("%s-tenant-id", local.control_plane_name_resolved)
  key_vault_id                                 = local.key_vault.id

  timeouts {
    read = "1m"
  }
}
// Import current service principal
data "azuread_service_principal" "sp"             {
                                                    count        = local.use_spn ? 1 : 0
                                                    client_id    = data.azurerm_key_vault_secret.client_id[0].value
                                                  }
