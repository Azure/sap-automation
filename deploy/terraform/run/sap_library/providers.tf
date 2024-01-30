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
                                         provider = azurerm.deployer
                                       }

provider "azurerm"                     {
                                         features {
                                                  }
                                         skip_provider_registration = true
                                         use_msi                    = var.use_spn ? false : true
                                         storage_use_azuread        = !var.shared_access_key_enabled

                                       }

provider "azurerm"                     {
                                         features {
                                                    resource_group {
                                                                     prevent_deletion_if_contains_resources = true
                                                                   }

                                                  }
                                         subscription_id            = local.spn.subscription_id
                                         client_id                  = local.use_spn ? local.spn.client_id : null
                                         client_secret              = local.use_spn ? local.spn.client_secret : null
                                         tenant_id                  = local.use_spn ? local.spn.tenant_id : null
                                         partner_id                 = "140c3bc9-c937-4139-874f-88288bab08bb"
                                         storage_use_azuread        = !var.shared_access_key_enabled
                                         use_msi                    = var.use_spn ? false : true

                                         alias = "main"
                                         skip_provider_registration = true
                                       }

provider "azurerm"                     {
                                         features {
                                                  }
                                         skip_provider_registration = true
                                         alias                      = "deployer"
                                         storage_use_azuread        = !var.shared_access_key_enabled
                                         use_msi                    = var.use_spn ? false : true

                                       }

provider "azurerm"                     {
                                         features {
                                                  }
                                         alias                      = "dnsmanagement"
                                         subscription_id            = try(coalesce(var.management_dns_subscription_id, local.spn.subscription_id), null)
                                         client_id                  = local.use_spn ? local.spn.client_id : null
                                         client_secret              = local.use_spn ? local.spn.client_secret : null
                                         tenant_id                  = local.use_spn ? local.spn.tenant_id : null
                                         skip_provider_registration = true
                                         storage_use_azuread        = !var.shared_access_key_enabled
                                         use_msi                    = var.use_spn ? false : true
                                       }

provider "azuread"                     {
                                         client_id                  = local.use_spn ? local.spn.client_id : null
                                         client_secret              = local.use_spn ? local.spn.client_secret : null
                                         tenant_id                  = local.spn.tenant_id
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

