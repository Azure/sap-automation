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
                                                                     prevent_deletion_if_contains_resources = true
                                                                   }
                                                    key_vault {
                                                                 purge_soft_delete_on_destroy               = !var.enable_purge_control_for_keyvaults
                                                                 purge_soft_deleted_keys_on_destroy         = !var.enable_purge_control_for_keyvaults
                                                                 purge_soft_deleted_secrets_on_destroy      = !var.enable_purge_control_for_keyvaults
                                                                 purge_soft_deleted_certificates_on_destroy = !var.enable_purge_control_for_keyvaults
                                                              }
                                                  }
                                         partner_id                 = "f94f50f2-2539-42f8-9c8e-c65b28c681f7"
                                         skip_provider_registration = true
                                         storage_use_azuread        = !var.shared_access_key_enabled
                                         use_msi                    = var.use_spn ? false : true
                                       }

provider "azurerm"                     {
                                         features {
                                                    resource_group {
                                                                     prevent_deletion_if_contains_resources = true
                                                                   }
                                                    key_vault {
                                                                 purge_soft_delete_on_destroy               = !var.enable_purge_control_for_keyvaults
                                                                 purge_soft_deleted_keys_on_destroy         = !var.enable_purge_control_for_keyvaults
                                                                 purge_soft_deleted_secrets_on_destroy      = !var.enable_purge_control_for_keyvaults
                                                                 purge_soft_deleted_certificates_on_destroy = !var.enable_purge_control_for_keyvaults
                                                              }
                                                  }
                                         partner_id                 = "f94f50f2-2539-42f8-9c8e-c65b28c681f7"
                                         skip_provider_registration = true

                                         subscription_id            = local.spn.subscription_id
                                         client_id                  = var.use_spn ? local.spn.client_id : null
                                         client_secret              = var.use_spn ? local.spn.client_secret: null
                                         tenant_id                  = var.use_spn ? local.spn.tenant_id: null
                                         use_msi                    = var.use_spn ? false : true
                                         alias                      = "main"
                                         storage_use_azuread        = !var.shared_access_key_enabled
                                       }

provider "azurerm"                     {
                                         features {}
                                         alias                      = "dnsmanagement"
                                         subscription_id            = try(var.management_dns_subscription_id, null)
                                         client_id                  = var.use_spn ? local.spn.client_id : null
                                         client_secret              = var.use_spn ? local.spn.client_secret: null
                                         tenant_id                  = var.use_spn ? local.spn.tenant_id: null
                                         skip_provider_registration = true
                                         storage_use_azuread        = !var.shared_access_key_enabled
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
                                                                           version = ">=2.2"
                                                                         }
                                                              azurerm =  {
                                                                           source  = "hashicorp/azurerm"
                                                                           version = ">=3.3"
                                                                         }
                                                            }
                                       }

