# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

#######################################4#######################################8
#                                                                              #
#                              Deployment credentials                          #
#                                                                              #
#######################################4#######################################8

data "azurerm_key_vault_secret" "subscription_id" {
                                                    count        = var.use_spn ? 1 : 0
                                                    name         = format("%s-subscription-id", upper(local.infrastructure.environment))
                                                    key_vault_id = var.deployer_kv_user_arm_id
                                                  }

data "azurerm_key_vault_secret" "client_id"       {
                                                    count        = var.use_spn ? 1 : 0
                                                    name         = format("%s-client-id", upper(local.infrastructure.environment))
                                                    key_vault_id = var.deployer_kv_user_arm_id
                                                  }

data "azurerm_key_vault_secret" "client_secret"   {
                                                    count        = var.use_spn ? 1 : 0
                                                    name         = format("%s-client-secret", upper(local.infrastructure.environment))
                                                    key_vault_id = var.deployer_kv_user_arm_id
                                                  }

data "azurerm_key_vault_secret" "tenant_id"       {
                                                    count        = var.use_spn ? 1 : 0
                                                    name         = format("%s-tenant-id", upper(local.infrastructure.environment))
                                                    key_vault_id = var.deployer_kv_user_arm_id
                                                  }
