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
                                                    count        = length(local.key_vault.id) > 0 ? (var.use_deployer && var.use_spn ? 1 : 0) : 0
                                                    name         = format("%s-subscription-id", var.use_deployer ? upper(coalesce(data.terraform_remote_state.deployer[0].outputs.control_plane_name, var.control_plane_name)) : upper(var.control_plane_name))
                                                    key_vault_id = local.key_vault.id
                                                  }


data "azurerm_key_vault_secret" "client_id"       {
                                                    count        = length(local.key_vault.id) > 0 ? (var.use_deployer && var.use_spn ? 1 : 0) : 0
                                                    name         = format("%s-client-id", var.use_deployer ? upper(coalesce(data.terraform_remote_state.deployer[0].outputs.control_plane_name, var.control_plane_name)) : upper(var.control_plane_name))
                                                    key_vault_id = local.key_vault.id
                                                  }

ephemeral "azurerm_key_vault_secret" "client_secret"   {
                                                    count        = length(local.key_vault.id) > 0 ? (var.use_deployer && var.use_spn ? 1 : 0) : 0
                                                    name         = format("%s-client-secret", var.use_deployer ? upper(coalesce(data.terraform_remote_state.deployer[0].outputs.control_plane_name, var.control_plane_name)) : upper(var.control_plane_name))
                                                    key_vault_id = local.key_vault.id
                                                  }

data "azurerm_key_vault_secret" "tenant_id"       {
                                                    count        = length(local.key_vault.id) > 0 ? (var.use_deployer && var.use_spn ? 1 : 0) : 0
                                                    name         = format("%s-tenant-id", var.use_deployer ? upper(coalesce(data.terraform_remote_state.deployer[0].outputs.control_plane_name, var.control_plane_name)) : upper(var.control_plane_name))
                                                    key_vault_id = local.key_vault.id
                                                  }
// Import current service principal
data "azuread_service_principal" "sp"             {
                                                    count        = local.use_spn ? 1 : 0
                                                    client_id    = data.azurerm_key_vault_secret.client_id[0].value
                                                  }
