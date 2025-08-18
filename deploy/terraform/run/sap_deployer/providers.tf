# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

/*
Description:

  Constraining provider versions
    =    (or no operator): exact version equality
    !=   version not equal
    >    greater than version number
    >=   greater than or equal to version number
    <    less than version number
    <=   less than or equal to version number
    ~>   pessimistic constraint operator, constraining both the oldest and newest version allowed.
           For example, ~> 0.9   is equivalent to >= 0.9,   < 1.0
                        ~> 0.8.4 is equivalent to >= 0.8.4, < 0.9
*/

provider "azurerm"                     {
                                         features {
                                                    resource_group {
                                                                     prevent_deletion_if_contains_resources = var.prevent_deletion_if_contains_resources
                                                                   }
                                                    key_vault      {
                                                                      purge_soft_delete_on_destroy               = !var.enable_purge_control_for_keyvaults
                                                                      purge_soft_deleted_keys_on_destroy         = false
                                                                      purge_soft_deleted_secrets_on_destroy      = false
                                                                      purge_soft_deleted_certificates_on_destroy = false
                                                                   }

                                                    storage        {
                                                                        data_plane_available = var.data_plane_available
                                                                   }
                                                  }
                                         partner_id                 = "f94f50f2-2539-42f8-9c8e-c65b28c681f7"
                                         storage_use_azuread        = !var.shared_access_key_enabled
                                         subscription_id            = var.subscription_id
                                         use_msi                    = true

                                       }

provider "azurerm"                     {
                                         features {
                                                    resource_group {
                                                                     prevent_deletion_if_contains_resources = true
                                                                   }
                                                    key_vault      {
                                                                      purge_soft_delete_on_destroy               = !var.enable_purge_control_for_keyvaults
                                                                      purge_soft_deleted_keys_on_destroy         = !var.enable_purge_control_for_keyvaults
                                                                      purge_soft_deleted_secrets_on_destroy      = !var.enable_purge_control_for_keyvaults
                                                                      purge_soft_deleted_certificates_on_destroy = !var.enable_purge_control_for_keyvaults
                                                                   }
                                                    storage        {
                                                                        data_plane_available = var.data_plane_available
                                                                   }
                                                  app_configuration {
                                                                       purge_soft_delete_on_destroy = !var.enable_purge_control_for_keyvaults
                                                                       recover_soft_deleted         = !var.enable_purge_control_for_keyvaults
                                                                    }
                                                  }
                                         partner_id                 = "f94f50f2-2539-42f8-9c8e-c65b28c681f7"

                                         subscription_id            = var.subscription_id
                                         client_id                  = try(data.azurerm_key_vault_secret.client_id[0].value, null)
                                         client_secret              = try(ephemeral.azurerm_key_vault_secret.client_secret[0].value, null)
                                         tenant_id                  = try(data.azurerm_key_vault_secret.tenant_id[0].value, null)
                                         use_msi                    = var.use_spn ? false : true
                                         alias                      = "main"
                                         storage_use_azuread        = var.data_plane_available
                                       }

provider "azurerm"                     {
                                         features {}
                                         alias                      = "dnsmanagement"
                                         subscription_id            = try(coalesce(var.management_dns_subscription_id, var.subscription_id), null)
                                         client_id                  = try(data.azurerm_key_vault_secret.client_id[0].value, null)
                                         client_secret              = try(ephemeral.azurerm_key_vault_secret.client_secret[0].value, null)
                                         tenant_id                  = try(data.azurerm_key_vault_secret.tenant_id[0].value, null)
                                         use_msi                    = var.use_spn ? false : true
                                         storage_use_azuread        = !var.shared_access_key_enabled
                                       }

provider "azurerm"                     {
                                         features {}
                                         subscription_id            = try(coalesce(var.privatelink_dns_subscription_id, var.management_dns_subscription_id, var.subscription_id), null)
                                         alias                      = "privatelinkdnsmanagement"
                                         client_id                  = try(data.azurerm_key_vault_secret.client_id[0].value, null)
                                         client_secret              = try(ephemeral.azurerm_key_vault_secret.client_secret[0].value, null)
                                         tenant_id                  = try(data.azurerm_key_vault_secret.tenant_id[0].value, null)
                                         use_msi                    = var.use_spn ? false : true
                                         storage_use_azuread        = !var.shared_access_key_enabled
                                        #  use_msi                    = false #var.use_spn ? false : true
                                       }

provider "azapi"                       {
                                          alias                      = "restapi"
                                          subscription_id            = var.subscription_id
                                          use_msi                    = var.use_spn ? false : true
                                       }

provider "azuread"                     {
                                         use_msi                    = var.use_spn ? false : true
                                       }


terraform                              {
                                         required_version = ">= 1.0"
                                         required_providers {
                                                              external = {
                                                                           source = "hashicorp/external"
                                                                         }
                                                              local    = {
                                                                           source = "hashicorp/local"
                                                                         }
                                                              random   = {
                                                                           source = "hashicorp/random"
                                                                         }
                                                              null =     {
                                                                           source = "hashicorp/null"
                                                                         }
                                                              azuread =  {
                                                                           source  = "hashicorp/azuread"
                                                                         }
                                                              azurerm =  {
                                                                           source  = "hashicorp/azurerm"
                                                                           version = "4.39.0"
                                                                         }
                                                              azapi =   {
                                                                           source  = "Azure/azapi"
                                                                           version = "2.5.0"
                                                                         }

                                                            }
                                       }

