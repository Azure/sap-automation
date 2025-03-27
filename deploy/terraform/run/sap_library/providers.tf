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

                                                    storage        {
                                                                        data_plane_available = var.data_plane_available
                                                                   }
                                                  }

                                         storage_use_azuread        = true
                                         use_msi                    = true
                                         subscription_id            = var.subscription_id

                                       }

provider "azurerm"                     {
                                         features {
                                                    resource_group {
                                                                     prevent_deletion_if_contains_resources = true
                                                                   }
                                                    storage        {
                                                                        data_plane_available = var.data_plane_available
                                                                   }

                                                  }

                                         subscription_id            = var.subscription_id
                                         client_id                  = var.use_spn ? data.azurerm_key_vault_secret.client_id[0].value: null
                                         client_secret              = var.use_spn ? ephemeral.azurerm_key_vault_secret.client_secret[0].value: null
                                         tenant_id                  = var.use_spn ? data.azurerm_key_vault_secret.tenant_id[0].value: null

                                         alias                      = "main"

                                         storage_use_azuread        = true
                                         use_msi                    = var.use_spn ? false : true
                                       }


provider "azurerm"                     {
                                         features {
                                                  }
                                         alias                      = "deployer"

                                         storage_use_azuread        = true
                                         use_msi                    = true
                                         subscription_id            = var.subscription_id
                                         tenant_id                  = var.use_spn ? data.azurerm_key_vault_secret.tenant_id[0].value: null
                                       }

provider "azurerm"                     {
                                         features {}
                                         subscription_id            = var.use_spn ? coalesce(var.management_dns_subscription_id, var.subscription_id): null
                                         alias                      = "dnsmanagement"
                                         client_id                  = var.use_spn ? data.azurerm_key_vault_secret.client_id[0].value: null
                                         client_secret              = var.use_spn ? ephemeral.azurerm_key_vault_secret.client_secret[0].value: null
                                         tenant_id                  = var.use_spn ? data.azurerm_key_vault_secret.tenant_id[0].value: null

                                         storage_use_azuread        = true
                                         use_msi                    = var.use_spn ? false : true

                                       }

provider "azurerm"                     {
                                         features {}
                                         subscription_id            = var.use_spn ? coalesce(var.privatelink_dns_subscription_id, var.subscription_id): null
                                         client_id                  = var.use_spn ? data.azurerm_key_vault_secret.client_id[0].value: null
                                         client_secret              = var.use_spn ? ephemeral.azurerm_key_vault_secret.client_secret[0].value: null
                                         tenant_id                  = var.use_spn ? data.azurerm_key_vault_secret.tenant_id[0].value: null
                                         alias                      = "privatelinkdnsmanagement"

                                         storage_use_azuread        = true
                                         use_msi                    = var.use_spn ? false : true
                                       }

provider "azuread"                     {
                                         client_id                  = local.spn.client_id
                                         client_secret              = var.use_spn ? ephemeral.azurerm_key_vault_secret.client_secret[0].value: null
                                         tenant_id                  = var.use_spn ? data.azurerm_key_vault_secret.tenant_id[0].value: null
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

