# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

/*
    Description:
      Import deployer resources
*/

data "terraform_remote_state" "deployer"          {
                                                    backend =    "azurerm"
                                                    count        = var.use_deployer && length(var.deployer_tfstate_key) > 0 ? 1 : 0
                                                    config       = {
                                                                     resource_group_name  = local.SAPLibrary_resource_group_name
                                                                     storage_account_name = local.tfstate_storage_account_name
                                                                     container_name       = local.tfstate_container_name
                                                                     key                  = local.deployer_tfstate_key
                                                                     subscription_id      = local.SAPLibrary_subscription_id
                                                                     use_msi              = true
                                                                   }
                                                  }


data "azurerm_key_vault_secret" "subscription_id" {
                                                    count        = var.use_deployer && var.use_spn ? 1 : 0
                                                    name         = format("%s-subscription-id", upper(var.environment))
                                                    key_vault_id = local.key_vault.keyvault_id_for_deployment_credentials
                                                  }


data "azurerm_key_vault_secret" "client_id"       {
                                                    count        = var.use_deployer && var.use_spn ? 1 : 0
                                                    name         = format("%s-client-id", upper(var.environment))
                                                    key_vault_id = local.key_vault.keyvault_id_for_deployment_credentials
                                                  }

ephemeral "azurerm_key_vault_secret" "client_secret"   {
                                                    count        = var.use_deployer && var.use_spn ? 1 : 0
                                                    name         = format("%s-client-secret", upper(var.environment))
                                                    key_vault_id = local.key_vault.keyvault_id_for_deployment_credentials
                                                  }

data "azurerm_key_vault_secret" "tenant_id"       {
                                                    count        = var.use_deployer && var.use_spn ? 1 : 0
                                                    name         = format("%s-tenant-id", upper(var.environment))
                                                    key_vault_id = local.key_vault.keyvault_id_for_deployment_credentials
                                                  }
// Import current service principal
data "azuread_service_principal" "sp"             {
                                                    count        = local.use_spn ? 1 : 0
                                                    client_id    = data.azurerm_key_vault_secret.client_id[0].value
                                                  }
