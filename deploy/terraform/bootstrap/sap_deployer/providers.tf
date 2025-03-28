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

data "azurerm_client_config" "current" {

                                       }

provider "azurerm"                     {
                                         features {
                                                    resource_group {
                                                                     prevent_deletion_if_contains_resources = var.prevent_deletion_if_contains_resources
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
                                                  }

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
                                                                        data_plane_available = true
                                                                   }
                                                  }

                                         partner_id                 = "f94f50f2-2539-42f8-9c8e-c65b28c681f7"
                                         alias                      = "main"
                                       }

provider "azurerm"                     {
                                         features {}
                                         subscription_id            = try(var.management_dns_subscription_id, null)

                                         partner_id                 = "f94f50f2-2539-42f8-9c8e-c65b28c681f7"
                                         alias                      = "dnsmanagement"
                                       }

provider "azurerm"                     {
                                         features {}
                                         subscription_id            = try(coalesce(var.privatelink_dns_subscription_id, var.management_dns_subscription_id), null)
                                         alias                      = "privatelinkdnsmanagement"
                                         storage_use_azuread        = true
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
                                                                           version = "3.0.2"
                                                                         }
                                                              azurerm =  {
                                                                           source  = "hashicorp/azurerm"
                                                                           version = "4.22.0"
                                                                         }
                                                            }
                                       }

