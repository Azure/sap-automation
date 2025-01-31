# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

/*
    Description:
    Retrieve remote tfstate file of Deployer and current environment's SPN
*/


data "azurerm_client_config" "current" {}

data "terraform_remote_state" "deployer" {
  backend                              = "azurerm"

  count                                = length(try(var.deployer_tfstate_key, "")) > 0 ? 1 : 0
  config                               = {
                                           resource_group_name  = local.saplib_resource_group_name
                                           storage_account_name = local.tfstate_storage_account_name
                                           container_name       = local.tfstate_container_name
                                           key                  = trimspace(var.deployer_tfstate_key)
                                           subscription_id      = local.saplib_subscription_id

                                         }
}

data "azurerm_key_vault_secret" "subscription_id" {
  count                                = length(var.subscription_id) > 0 ? 0 : (var.use_spn ? 1 : 0)
  name                                 = format("%s-subscription-id", local.environment)
  key_vault_id                         = local.spn_key_vault_arm_id
  timeouts                             {
                                          read = "1m"
                                       }
}

data "azurerm_key_vault_secret" "client_id" {
  count                                = var.use_spn ? 1 : 0
  name                                 = format("%s-client-id", local.environment)
  key_vault_id                         = local.spn_key_vault_arm_id
  timeouts                             {
                                          read = "1m"
                                       }
}

data "azurerm_key_vault_secret" "client_secret" {
  count                                = var.use_spn ? 1 : 0
  name                                 = format("%s-client-secret", local.environment)
  key_vault_id                         = local.spn_key_vault_arm_id
  timeouts                             {
                                          read = "1m"
                                       }
}

data "azurerm_key_vault_secret" "tenant_id" {
  count                                = var.use_spn ? 1 : 0
  name                                 = format("%s-tenant-id", local.environment)
  key_vault_id                         = local.spn_key_vault_arm_id
  timeouts                             {
                                          read = "1m"
                                       }
}

data "azurerm_key_vault_secret" "cp_subscription_id" {
  count                                = length(try(data.terraform_remote_state.deployer[0].outputs.environment, "")) > 0 ?  (var.use_spn ? 1 : 0) : 0
  name                                 = format("%s-subscription-id", data.terraform_remote_state.deployer[0].outputs.environment)
  key_vault_id                         = local.spn_key_vault_arm_id
  timeouts                             {
                                          read = "1m"
                                       }
}

data "azurerm_key_vault_secret" "cp_client_id" {
  count                                = var.use_spn ? 1 : 0
  name                                 = format("%s-client-id", data.terraform_remote_state.deployer[0].outputs.environment)
  key_vault_id                         = local.spn_key_vault_arm_id
  timeouts                             {
                                          read = "1m"
                                       }
}

data "azurerm_key_vault_secret" "cp_client_secret" {
  count                                = var.use_spn ? 1 : 0
  name                                 = format("%s-client-secret", data.terraform_remote_state.deployer[0].outputs.environment)
  key_vault_id                         = local.spn_key_vault_arm_id
  timeouts                             {
                                          read = "1m"
                                       }
}

data "azurerm_key_vault_secret" "cp_tenant_id" {
  count                                = var.use_spn ? 1 : 0
  name                                 = format("%s-tenant-id", data.terraform_remote_state.deployer[0].outputs.environment)
  key_vault_id                         = local.spn_key_vault_arm_id
  timeouts                             {
                                          read = "1m"
                                       }
}

// Import current service principal
data "azuread_service_principal" "sp"             {
                                                    count          = var.use_spn ? 1 : 0
                                                    client_id      = local.spn.client_id
                                                  }
