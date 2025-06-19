# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.


locals {

  version_label                        = trimspace(file("${path.module}/../../../configs/version.txt"))
  // The environment of sap landscape and sap system
  environment                          = upper(local.infrastructure.environment)
  vnet_sap_arm_id                      = try(data.terraform_remote_state.landscape.outputs.vnet_sap_arm_id, "")

  vnet_logical_name                    = local.infrastructure.virtual_networks.sap.logical_name
  vnet_sap_exists                      = length(local.vnet_sap_arm_id) > 0 ? true : false


  db_sid                              = upper(try(local.database.instance.sid, "HDB"))
  sap_sid                             = upper(try(local.application_tier.sid, local.db_sid))
  web_sid                             = upper(try(var.web_sid, local.sap_sid))

  enable_db_deployment                = length(local.database.platform) > 0

  db_zonal_deployment                 = length(try(local.database.zones, [])) > 0

  // Locate the tfstate storage account
  saplib_subscription_id             = split("/", var.tfstate_resource_id)[2]
  saplib_resource_group_name         = split("/", var.tfstate_resource_id)[4]
  tfstate_storage_account_name       = split("/", var.tfstate_resource_id)[8]
  tfstate_container_name             = module.sap_namegenerator.naming.resource_suffixes.tfstate

  // Retrieve the arm_id of deployer's Key Vault
  spn_key_vault_arm_id               = trimspace(coalesce(
                                         try(local.key_vault.keyvault_id_for_deployment_credentials, ""),
                                         try(data.terraform_remote_state.landscape.outputs.landscape_key_vault_spn_arm_id, ""),
                                         try(data.terraform_remote_state.deployer[0].outputs.deployer_kv_user_arm_id, ""),
                                         " "
                                       ))

  deployer_subscription_id           = length(local.spn_key_vault_arm_id) > 0 ? split("/", local.spn_key_vault_arm_id)[2] : ""

  spn                                = {
                                         subscription_id = length(var.subscription_id) > 0 ? var.subscription_id : data.azurerm_key_vault_secret.subscription_id[0].value,
                                         client_id       = var.use_spn ? data.azurerm_key_vault_secret.client_id[0].value : null,
                                         client_secret   = var.use_spn ? data.azurerm_key_vault_secret.client_secret[0].value : null,
                                         tenant_id       = var.use_spn ? data.azurerm_key_vault_secret.tenant_id[0].value : null
                                       }

  cp_spn                             = {
                                         subscription_id = local.deployer_subscription_id
                                         client_id       = var.use_spn ? try(coalesce(data.azurerm_key_vault_secret.cp_client_id[0].value, data.azurerm_key_vault_secret.client_id[0].value), null) : null,
                                         client_secret   = var.use_spn ? try(coalesce(data.azurerm_key_vault_secret.cp_client_secret[0].value, data.azurerm_key_vault_secret.client_secret[0].value), null) : null,
                                         tenant_id       = var.use_spn ? try(coalesce(data.azurerm_key_vault_secret.cp_tenant_id[0].value, data.azurerm_key_vault_secret.tenant_id[0].value), null) : null
                                       }

  service_principal                  = {
                                         subscription_id = local.spn.subscription_id,
                                         tenant_id       = var.use_spn ? local.spn.tenant_id : null,
                                         object_id       = var.use_spn ? data.azuread_service_principal.sp[0].id : null
                                       }

  account                            = {
                                        subscription_id = length(var.subscription_id) > 0 ? var.subscription_id : data.azurerm_key_vault_secret.subscription_id[0].value,
                                        tenant_id       = var.use_spn ? data.azurerm_client_config.current.tenant_id : null,
                                        object_id       = var.use_spn ? data.azurerm_client_config.current.object_id : null
                                      }

  custom_names                       = length(var.name_override_file) > 0 ? (
                                        jsondecode(file(format("%s/%s", path.cwd, var.name_override_file)))) : (
                                        null
                                      )

}
