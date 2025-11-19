# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

/*
    Description:
    Retrieve remote tfstate file of Deployer and current environment's SPN
*/


data "azurerm_client_config" "current" {}

data "azurerm_client_config" "current_main" {
  provider                            = azurerm.workload

}

data "terraform_remote_state" "deployer" {
  backend                              = "azurerm"

  count                                = var.use_deployer && length(try(var.deployer_tfstate_key, "")) > 0 ? 1 : 0
  config                               = {
                                           resource_group_name  = local.SAPLibrary_resource_group_name
                                           storage_account_name = local.tfstate_storage_account_name
                                           container_name       = local.tfstate_container_name
                                           key                  = trimspace(var.deployer_tfstate_key)
                                           subscription_id      = local.SAPLibrary_subscription_id

                                         }
}

data "azurerm_key_vault_secret" "subscription_id" {
  count                                = length(var.subscription_id) > 0 ? 0 : (var.use_spn ? 1 : 0)
  name                                 = format("%s-subscription-id", local.environment)
  key_vault_id                         = local.key_vault.spn.id
  timeouts                             {
                                          read = "1m"
                                       }
}

data "azurerm_key_vault_secret" "client_id" {
  count                                = var.use_spn ? 1 : 0
  name                                 = format("%s-client-id", local.environment)
  key_vault_id                         = local.key_vault.spn.id
  timeouts                             {
                                          read = "1m"
                                       }
}

ephemeral "azurerm_key_vault_secret" "client_secret" {
  count                                = var.use_spn ? 1 : 0
  name                                 = format("%s-client-secret", local.environment)
  key_vault_id                         = local.key_vault.spn.id

}

data "azurerm_key_vault_secret" "tenant_id" {
  count                                = var.use_spn ? 1 : 0
  name                                 = format("%s-tenant-id", local.environment)
  key_vault_id                         = local.key_vault.spn.id
  timeouts                             {
                                          read = "1m"
                                       }
}

data "azurerm_key_vault_secret" "cp_subscription_id" {
  count                                = length(try(data.terraform_remote_state.deployer[0].outputs.environment, "")) > 0 ?  (var.use_spn ? 1 : 0) : 0
  name                                 = format("%s-subscription-id", data.terraform_remote_state.deployer[0].outputs.environment)
  key_vault_id                         = local.key_vault.spn.id
  timeouts                             {
                                          read = "1m"
                                       }
}

data "azurerm_key_vault_secret" "cp_client_id" {
  count                                = var.use_spn ? 1 : 0
  name                                 = format("%s-client-id", data.terraform_remote_state.deployer[0].outputs.environment)
  key_vault_id                         = local.key_vault.spn.id

}

ephemeral "azurerm_key_vault_secret" "cp_client_secret" {
  count                                = var.use_spn ? 1 : 0
  name                                 = format("%s-client-secret", data.terraform_remote_state.deployer[0].outputs.environment)
  key_vault_id                         = local.key_vault.spn.id
}

data "azurerm_key_vault_secret" "cp_tenant_id" {
  count                                = var.use_spn ? 1 : 0
  name                                 = format("%s-tenant-id", data.terraform_remote_state.deployer[0].outputs.environment)
  key_vault_id                         = local.key_vault.spn.id
}

data "azurerm_key_vault_secret" "subscription_id_v2" {
  count                                = length(var.subscription_id) > 0 ? 0 : (var.use_spn ? 1 : 0)
  name                                 = format("%s-subscription-id", local.workload_zone_name)
  key_vault_id                         = local.key_vault.spn.id
  timeouts                             {
                                          read = "1m"
                                       }
}

data "azurerm_key_vault_secret" "client_id_v2" {
  count                                = var.use_spn ? 1 : 0
  name                                 = format("%s-client-id", local.workload_zone_name)
  key_vault_id                         = local.key_vault.spn.id
  timeouts                             {
                                          read = "1m"
                                       }
}
ephemeral "azurerm_key_vault_secret" "client_secret_v2" {
  count                                = var.use_spn ? 1 : 0
  name                                 = format("%s-client-secret", local.workload_zone_name)
  key_vault_id                         = local.key_vault.spn.id

}

data "azurerm_key_vault_secret" "tenant_id_v2" {
  count                                = var.use_spn ? 1 : 0
  name                                 = format("%s-tenant-id", local.workload_zone_name)
  key_vault_id                         = local.key_vault.spn.id
  timeouts                             {
                                          read = "1m"
                                       }
}


data "azurerm_app_configuration_key" "deployer_state_file" {
  count                                = local.infrastructure.use_application_configuration ? 1 : 0
  configuration_store_id               = local.infrastructure.application_configuration_id
  key                                  = format("%s_StateFileName", var.control_plane_name)
  label                                = var.control_plane_name
}
data "azurerm_app_configuration_key" "deployer_subscription_id" {
  count                                = local.infrastructure.use_application_configuration ? 1 : 0
  configuration_store_id               = local.infrastructure.application_configuration_id
  key                                  = format("%s_SubscriptionId", var.control_plane_name)
  label                                = var.control_plane_name
}

data "azurerm_app_configuration_key" "deployer_key_vault_id" {
  count                                = local.infrastructure.use_application_configuration ? 1 : 0
  configuration_store_id               = local.infrastructure.application_configuration_id
  key                                  = format("%s_KeyVaultResourceId", var.control_plane_name)
  label                                = var.control_plane_name
}
