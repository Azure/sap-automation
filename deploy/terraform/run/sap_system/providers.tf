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
                                                  }
                                         subscription_id            = local.spn.subscription_id
                                         client_id                  = var.use_spn ? local.spn.client_id : null
                                         client_secret              = var.use_spn ? local.spn.client_secret : null
                                         tenant_id                  = var.use_spn ? local.spn.tenant_id : null
                                         use_msi                    = var.use_spn ? false : true

                                         partner_id                 = "3179cd51-f54b-4c73-ac10-8e99417efce7"
                                         alias                      = "system"
                                         skip_provider_registration = true
                                       }

provider "azurerm"                     {
                                         features {}
                                         subscription_id            = length(local.deployer_subscription_id) > 0 ? local.deployer_subscription_id : null
                                         skip_provider_registration = true
                                         use_msi                    = var.use_spn ? false : true
                                       }

provider "azurerm"                     {
                                         features {}
                                         alias                      = "dnsmanagement"
                                         subscription_id            = length(try(data.terraform_remote_state.landscape.outputs.management_dns_subscription_id, "")) > 1 ? data.terraform_remote_state.landscape.outputs.management_dns_subscription_id : length(local.deployer_subscription_id) > 0 ? local.deployer_subscription_id : null
                                         use_msi                    = var.use_spn ? false : true
                                         client_id                  = var.use_spn ? local.cp_spn.client_id : null
                                         client_secret              = var.use_spn ? local.cp_spn.client_secret : null
                                         tenant_id                  = var.use_spn ? local.cp_spn.tenant_id : null
                                         skip_provider_registration = true
                                       }

provider "azuread"                     {
                                         client_id     = local.spn.client_id
                                         client_secret = local.spn.client_secret
                                         tenant_id     = local.spn.tenant_id
                                       }

# provider "azapi" {
#   alias           = "api"
#   subscription_id = local.spn.subscription_id
#   client_id       = local.spn.client_id
#   client_secret   = local.spn.client_secret
#   tenant_id       = local.spn.tenant_id
# }

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

