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


}

data "azurerm_key_vault_secret" "subscription_id" {
                                                    count        = var.use_spn ? 1 : 0
                                                    name         = format("%s-subscription-id", upper(local.environment_name))
                                                    key_vault_id = var.spn_keyvault_id
                                                  }

data "azurerm_key_vault_secret" "client_id"       {
                                                    count        = var.use_spn ? 1 : 0
                                                    name         = format("%s-client-id", upper(local.environment_name))
                                                    key_vault_id = var.spn_keyvault_id
                                                  }

ephemeral "azurerm_key_vault_secret" "client_secret"   {
                                                    count        = var.use_spn ? 1 : 0
                                                    name         = format("%s-client-secret", upper(local.environment_name))
                                                    key_vault_id = var.spn_keyvault_id
                                                  }

data "azurerm_key_vault_secret" "tenant_id"       {
                                                    count        = var.use_spn ? 1 : 0
                                                    name         = format("%s-tenant-id", upper(local.environment_name))
                                                    key_vault_id = var.spn_keyvault_id
                                                  }
