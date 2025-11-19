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
                                          features {}
                                          subscription_id            = coalesce(var.management_subscription_id,var.subscription_id, local.deployer_subscription_id)
                                          storage_use_azuread        = true
                                          use_msi                    = true
                                        }

  provider "azurerm"                     {
                                          features {}
                                          subscription_id            = coalesce(var.management_subscription_id,var.subscription_id, local.deployer_subscription_id)
                                          storage_use_azuread        = true
                                          client_id                  = var.use_spn ? data.azurerm_key_vault_secret.cp_client_id[0].value : null
                                          client_secret              = var.use_spn ? ephemeral.azurerm_key_vault_secret.cp_client_secret[0].value : null
                                          tenant_id                  = var.use_spn ? data.azurerm_key_vault_secret.cp_tenant_id[0].value : null
                                          use_msi                    = !var.use_spn
                                          alias                      = "deployer"
                                        }


  provider "azurerm"                     {
                                          features {
                                                      resource_group {
                                                                      prevent_deletion_if_contains_resources      = var.prevent_deletion_if_contains_resources
                                                                    }
                                                      key_vault      {
                                                                        purge_soft_delete_on_destroy               = !var.enable_purge_control_for_keyvaults
                                                                        purge_soft_deleted_keys_on_destroy         = !var.enable_purge_control_for_keyvaults
                                                                        purge_soft_deleted_secrets_on_destroy      = !var.enable_purge_control_for_keyvaults
                                                                        purge_soft_deleted_certificates_on_destroy = !var.enable_purge_control_for_keyvaults
                                                                    }
                                                      storage        {
                                                                          data_plane_available                     = var.data_plane_available
                                                                    }
                                                    }
                                          subscription_id            = length(var.subscription_id) > 0 ? var.subscription_id : data.azurerm_key_vault_secret.subscription_id[0].value
                                          client_id                  = var.use_spn ? data.azurerm_key_vault_secret.cp_client_id[0].value : null
                                          client_secret              = var.use_spn ? ephemeral.azurerm_key_vault_secret.cp_client_secret[0].value : null
                                          tenant_id                  = var.use_spn ? data.azurerm_key_vault_secret.cp_tenant_id[0].value : null
                                          use_msi                    = var.use_spn ? false : true

                                          partner_id                 = "3179cd51-f54b-4c73-ac10-8e99417efce7"
                                          storage_use_azuread        = true
                                          alias                      = "system"

                                        }

  provider "azurerm"                     {
                                          features {}
                                          alias                      = "dnsmanagement"
                                          subscription_id            = coalesce(var.management_dns_subscription_id, length(local.deployer_subscription_id) > 0 ? local.deployer_subscription_id : "")
                                          client_id                  = var.use_spn ? data.azurerm_key_vault_secret.cp_client_id[0].value : null
                                          client_secret              = var.use_spn ? ephemeral.azurerm_key_vault_secret.cp_client_secret[0].value : null
                                          tenant_id                  = var.use_spn ? data.azurerm_key_vault_secret.cp_tenant_id[0].value : null
                                          use_msi                    = var.use_spn ? false : true
                                          storage_use_azuread        = true
                                        }

  provider "azurerm"                     {
                                          features {}
                                          alias                      = "privatelinkdnsmanagement"
                                          subscription_id            = coalesce(var.privatelink_dns_subscription_id, var.management_dns_subscription_id, length(local.deployer_subscription_id) > 0 ? local.deployer_subscription_id : "")
                                          client_id                  = var.use_spn ? data.azurerm_key_vault_secret.cp_client_id[0].value : null
                                          client_secret              = var.use_spn ? ephemeral.azurerm_key_vault_secret.cp_client_secret[0].value : null
                                          tenant_id                  = var.use_spn ? data.azurerm_key_vault_secret.cp_tenant_id[0].value : null
                                          use_msi                    = var.use_spn ? false : true
                                          storage_use_azuread        = true
                                        }



  provider "azuread"                     {
                                          client_id                  = var.use_spn ? data.azurerm_key_vault_secret.cp_client_id[0].value : null
                                          client_secret              = var.use_spn ? ephemeral.azurerm_key_vault_secret.cp_client_secret[0].value : null
                                          tenant_id                  = var.use_spn ? data.azurerm_key_vault_secret.cp_tenant_id[0].value : null
                                          use_msi                    = var.use_spn ? false : true
                                        }

  terraform                              {
                                          required_version    = ">= 1.0"
                                          required_providers  {
                                                                external = {
                                                                              source = "hashicorp/external"
                                                                            }
                                                                local    = {
                                                                              source = "hashicorp/local"
                                                                              version = "2.5.2"
                                                                            }
                                                                random   = {
                                                                              source = "hashicorp/random"
                                                                            }
                                                                null =     {
                                                                              source = "hashicorp/null"
                                                                            }
                                                                azuread =  {
                                                                              source  = "hashicorp/azuread"
                                                                              version = "3.6.0"
                                                                            }
                                                                azurerm =  {
                                                                              source  = "hashicorp/azurerm"
                                                                              version = "4.51.0"
                                                                            }
                                                              }
                                        }
