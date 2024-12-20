# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

/*
    Description:
      Import deployer resources
*/

data "terraform_remote_state" "deployer"          {
                                                    backend      = "local"
                                                    count        = length(var.deployer_statefile_foldername) > 0  ? 1 : 0
                                                    config       = {
                                                                     path = length(var.deployer_statefile_foldername) > 0 ? (
                                                                              "${var.deployer_statefile_foldername}/terraform.tfstate") : (
                                                                              "${abspath(path.cwd)}/../../LOCAL/${local.deployer_rg_name}/terraform.tfstate"
                                                                            )
                                                                   }
                                                  }

data "azurerm_key_vault_secret" "subscription_id" {
                                                    count        = length(local.key_vault.kv_spn_id) > 0 ? (var.use_deployer && var.use_spn ? 1 : 0) : 0
                                                    name         = format("%s-subscription-id", upper(local.infrastructure.environment))
                                                    key_vault_id = local.key_vault.kv_spn_id
                                                  }

data "azurerm_key_vault_secret" "client_id"       {
                                                    count        = length(local.key_vault.kv_spn_id) > 0 ? (var.use_deployer && var.use_spn ? 1 : 0) : 0
                                                    name         = format("%s-client-id", upper(local.infrastructure.environment))
                                                    key_vault_id = local.key_vault.kv_spn_id
                                                  }

data "azurerm_key_vault_secret" "client_secret"   {
                                                    count        = length(local.key_vault.kv_spn_id) > 0 ? (var.use_deployer && var.use_spn ? 1 : 0) : 0
                                                    name         = format("%s-client-secret", upper(local.infrastructure.environment))
                                                    key_vault_id = local.key_vault.kv_spn_id
                                                  }

data "azurerm_key_vault_secret" "tenant_id"       {
                                                    count        = length(local.key_vault.kv_spn_id) > 0 ? (var.use_deployer && var.use_spn ? 1 : 0) : 0
                                                    name         = format("%s-tenant-id", upper(local.infrastructure.environment))
                                                    key_vault_id = local.key_vault.kv_spn_id
                                                  }
// Import current service principal
data "azuread_service_principal" "sp"             {
                                                    count        = local.use_spn ? 1 : 0
                                                    client_id    = local.spn.client_id
                                                  }
