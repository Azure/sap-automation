# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

#######################################4#######################################8
#                                                                              #
#                              Deployment credentials                          #
#                                                                              #
#######################################4#######################################8

locals {
  # Determine effective naming based on configuration
  use_control_plane_naming                     = length(trimspace(var.control_plane_name)) > 0
  environment_name                             = local.use_control_plane_naming ? var.control_plane_name : var.environment

  # Control plane naming resolution
  control_plane_name_resolved                  = coalesce(
                                                    var.control_plane_name,
                                                    var.environment
                                                  )


  # Conditions for credential retrieval
  retrieve_subscription_from_kv                = length(var.subscription_id) == 0 && var.use_spn
  retrieve_cp_credentials                      = var.use_spn && length(local.control_plane_name_resolved) > 0
}


data "azurerm_key_vault_secret" "subscription_id" {
                                                    count        = var.use_spn ? 1 : 0
                                                    name         = format("%s-subscription-id", local.environment_name)
                                                    key_vault_id = local.key_vault.id
                                                  }

data "azurerm_key_vault_secret" "client_id"       {
                                                    count        = var.use_spn ? 1 : 0
                                                    name         = format("%s-client-id", local.environment_name)
                                                    key_vault_id = local.key_vault.id
                                                  }

ephemeral "azurerm_key_vault_secret" "client_secret"   {
                                                    count        = var.use_spn ? 1 : 0
                                                    name         = format("%s-client-secret", local.environment_name)
                                                    key_vault_id = local.key_vault.id
                                                  }

data "azurerm_key_vault_secret" "tenant_id"       {
                                                    count        = var.use_spn ? 1 : 0
                                                    name         = format("%s-tenant-id", local.environment_name)
                                                    key_vault_id = local.key_vault.id
                                                  }
