# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

#######################################4#######################################8
#                                                                              #
#                            Local variables                                   #
#                                                                              #
#######################################4#######################################8
locals {
  version_label                        = trimspace(file("${path.module}/../../../configs/version.txt"))

  // Management vnet

  //There is no default as the name is mandatory unless arm_id is specified
  vnet_mgmt_name                       = local.infrastructure.virtual_network.management.exists ? (
                                           split("/", local.infrastructure.virtual_network.management.id)[8]) : (
                                           length(local.infrastructure.virtual_network.management.name) > 0 ? (
                                             local.infrastructure.virtual_network.management.name) : (
                                             "DEP00"
                                           )
                                         )

  parsed_id                           = provider::azurerm::parse_resource_id(var.tfstate_resource_id)

  SAPLibrary_subscription_id          = local.parsed_id["subscription_id"]
  SAPLibrary_resource_group_name      = local.parsed_id["resource_group_name"]
  tfstate_storage_account_name        = local.parsed_id["resource_name"]

  // Default naming of vnet has multiple parts. Taking the second-last part as the name incase the name ends with -vnet
  vnet_mgmt_parts                      = length(split("-", local.vnet_mgmt_name))
  vnet_mgmt_name_part                  = substr(upper(local.vnet_mgmt_name), -5, 5) == "-VNET" ? (
                                           split("-", local.vnet_mgmt_name)[(local.vnet_mgmt_parts - 2)]) : (
                                           local.vnet_mgmt_name
                                         )

  custom_names                         = length(var.name_override_file) > 0 ? (
                                           jsondecode(file(format("%s/%s", path.cwd, var.name_override_file)))) : (
                                           null
                                         )

  spn                                  = {
                                           subscription_id = coalesce(var.subscription_id, try(data.azurerm_key_vault_secret.subscription_id[0].value,null))
                                           client_id       = var.use_spn ? data.azurerm_key_vault_secret.client_id[0].value : null,
                                           client_secret   = var.use_spn ? ephemeral.azurerm_key_vault_secret.client_secret[0].value : null,
                                           tenant_id       = var.use_spn ? data.azurerm_key_vault_secret.tenant_id[0].value : null
                                         }

}
