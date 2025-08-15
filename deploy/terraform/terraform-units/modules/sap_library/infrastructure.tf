# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

#######################################4#######################################8
#                                                                              #
#                                Resource Group Information                    #
#                                                                              #
#######################################4#######################################8

resource "azurerm_resource_group" "library" {
  provider                             = azurerm.main
  count                                = var.infrastructure.resource_group.exists ? 0 : 1
  name                                 = local.resource_group_name
  location                             = var.infrastructure.region
  tags                                 = var.infrastructure.tags

  lifecycle {
              ignore_changes = [
                tags
              ]
            }

}

// Imports data of existing resource group
data "azurerm_resource_group" "library" {
  provider                             = azurerm.main
  count                                = var.infrastructure.resource_group.exists ? 1 : 0
  name                                 = split("/", var.infrastructure.resource_group.id)[4]
}

// TODO: Add management lock when this issue is addressed https://github.com/terraform-providers/terraform-provider-azurerm/issues/5473


resource "azurerm_private_dns_zone_virtual_network_link" "vnet_mgmt" {
  provider                             = azurerm.dnsmanagement
  count                                = var.dns_settings.register_storage_accounts_keyvaults_with_dns && length(var.dns_settings.dns_label) > 0 && !var.use_custom_dns_a_registration ? 1 : 0
  depends_on                           = [
                                           azurerm_private_dns_zone.dns
                                         ]
  name                                 = format("%s%s%s%s",
                                           var.naming.resource_prefixes.dns_link,
                                           local.prefix,
                                           var.naming.separator,
                                           var.naming.resource_suffixes.dns_link
                                         )

  resource_group_name                  = coalesce(var.dns_settings.management_dns_resourcegroup_name,
                                           var.infrastructure.resource_group.exists ? (
                                             split("/", var.infrastructure.resource_group.id)[4]) : (
                                             azurerm_resource_group.library[0].name
                                         ))
  private_dns_zone_name                = var.dns_settings.dns_label
  virtual_network_id                   = local.management_network_id
  registration_enabled                 = true
  tags                                 = var.infrastructure.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "vnet_mgmt_blob" {
  provider                             = azurerm.dnsmanagement
  count                                = var.dns_settings.register_storage_accounts_keyvaults_with_dns && !var.use_custom_dns_a_registration ? 1 : 0
  depends_on                           = [
                                           azurerm_storage_account.storage_tfstate,
                                           azurerm_private_dns_zone.blob
                                         ]
  name                                 = format("%s%s%s%s-blob",
                                           var.naming.resource_prefixes.dns_link,
                                           local.prefix,
                                           var.naming.separator,
                                           var.naming.resource_suffixes.dns_link
                                         )

  resource_group_name                  = coalesce(var.dns_settings.privatelink_dns_resourcegroup_name,
                                           var.dns_settings.management_dns_resourcegroup_name,
                                           var.infrastructure.resource_group.exists ? (
                                             split("/", var.infrastructure.resource_group.id)[4]) : (
                                             azurerm_resource_group.library[0].name
                                         ))
  private_dns_zone_name                = var.dns_settings.dns_zone_names.blob_dns_zone_name
  virtual_network_id                   = local.management_network_id
  registration_enabled                 = false
  tags                                 = var.infrastructure.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "vnet_mgmt_blob-agent" {
  provider                             = azurerm.dnsmanagement
  count                                = var.dns_settings.register_storage_accounts_keyvaults_with_dns && contains(keys(var.deployer_tfstate), "additional_network_id") ? 1 : 0
  depends_on                           = [
                                           azurerm_storage_account.storage_tfstate,
                                           azurerm_private_dns_zone.blob
                                         ]
  name                                 = format("%s%s%s%s-blob-agent",
                                           var.naming.resource_prefixes.dns_link,
                                           local.prefix,
                                           var.naming.separator,
                                           var.naming.resource_suffixes.dns_link
                                         )

  resource_group_name                  = coalesce(var.dns_settings.privatelink_dns_resourcegroup_name,
                                           var.dns_settings.management_dns_resourcegroup_name,
                                           var.infrastructure.resource_group.exists ? (
                                             split("/", var.infrastructure.resource_group.id)[4]) : (
                                             azurerm_resource_group.library[0].name
                                         ))
  private_dns_zone_name                = var.dns_settings.dns_zone_names.blob_dns_zone_name
  virtual_network_id                   = var.deployer_tfstate.additional_network_id
  registration_enabled                 = false
  tags                                 = var.infrastructure.tags
}



resource "azurerm_private_dns_zone_virtual_network_link" "vault" {
  provider                             = azurerm.dnsmanagement
  count                                = var.dns_settings.register_storage_accounts_keyvaults_with_dns ? 1 : 0
  depends_on                           = [
                                            azurerm_private_dns_zone.vault
                                         ]

  name                                 = format("%s%s%s%s",
                                           var.naming.resource_prefixes.dns_link,
                                           local.prefix,
                                           var.naming.separator,
                                           "vault"
                                         )
  resource_group_name                  = length(var.dns_settings.privatelink_dns_subscription_id) == 0 ? (
                                           var.infrastructure.resource_group.exists ? (
                                             split("/", var.infrastructure.resource_group.id)[4]) : (
                                             azurerm_resource_group.library[0].name
                                           )) : (
                                           var.dns_settings.privatelink_dns_resourcegroup_name
                                         )
  private_dns_zone_name                = var.dns_settings.dns_zone_names.vault_dns_zone_name
  virtual_network_id                   = local.management_network_id
  registration_enabled                 = false
  tags                                 = var.infrastructure.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "vault_agent" {
  provider                             = azurerm.dnsmanagement
  count                                = var.dns_settings.register_storage_accounts_keyvaults_with_dns && contains(keys(var.deployer_tfstate), "additional_network_id") ? 1 : 0
  depends_on                           = [
                                            azurerm_private_dns_zone.vault
                                         ]

  name                                 = format("%s%s%s%s",
                                           var.naming.resource_prefixes.dns_link,
                                           local.prefix,
                                           var.naming.separator,
                                           "vault-agent"
                                         )
  resource_group_name                  = length(var.dns_settings.privatelink_dns_subscription_id) == 0 ? (
                                           var.infrastructure.resource_group.exists ? (
                                             split("/", var.infrastructure.resource_group.id)[4]) : (
                                             azurerm_resource_group.library[0].name
                                           )) : (
                                           var.dns_settings.privatelink_dns_resourcegroup_name
                                         )
  private_dns_zone_name                = var.dns_settings.dns_zone_names.vault_dns_zone_name
  virtual_network_id                   = var.deployer_tfstate.additional_network_id
  registration_enabled                 = false
  tags                                 = var.infrastructure.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "vault_additional" {
  provider                             = azurerm.dnsmanagement
  count                                = var.dns_settings.register_storage_accounts_keyvaults_with_dns && length(var.dns_settings.additional_network_id) > 0 && try(var.dns_settings.additional_network_id != try(var.deployer_tfstate.additional_network_id,"") , false) ? 1 : 0
  depends_on                           = [
                                            azurerm_private_dns_zone.vault
                                         ]

  name                                 = format("%s%s%s%s",
                                           var.naming.resource_prefixes.dns_link,
                                           local.prefix,
                                           var.naming.separator,
                                           "vault-additional"
                                         )
  resource_group_name                  = length(var.dns_settings.privatelink_dns_subscription_id) == 0 ? (
                                           var.infrastructure.resource_group.exists ? (
                                             split("/", var.infrastructure.resource_group.id)[4]) : (
                                             azurerm_resource_group.library[0].name
                                           )) : (
                                           var.dns_settings.privatelink_dns_resourcegroup_name
                                         )
  private_dns_zone_name                = var.dns_settings.dns_zone_names.vault_dns_zone_name
  virtual_network_id                   = var.dns_settings.additional_network_id
  registration_enabled                 = false
  tags                                 = var.infrastructure.tags
}


resource "azurerm_private_dns_zone_virtual_network_link" "blob_agent" {
  provider                             = azurerm.dnsmanagement
  count                                = var.dns_settings.register_storage_accounts_keyvaults_with_dns && length(var.dns_settings.additional_network_id) > 0 ? 1 : 0
  depends_on                           = [
                                            azurerm_private_dns_zone.vault
                                         ]

  name                                 = format("%s%s%s%s",
                                           var.naming.resource_prefixes.dns_link,
                                           local.prefix,
                                           var.naming.separator,
                                           "blob-agent"
                                         )
  resource_group_name                  = length(var.dns_settings.privatelink_dns_subscription_id) == 0 ? (
                                           var.infrastructure.resource_group.exists ? (
                                             split("/", var.infrastructure.resource_group.id)[4]) : (
                                             azurerm_resource_group.library[0].name
                                           )) : (
                                           var.dns_settings.privatelink_dns_resourcegroup_name
                                         )
  private_dns_zone_name                = var.dns_settings.dns_zone_names.blob_dns_zone_name
  virtual_network_id                   = var.dns_settings.additional_network_id
  registration_enabled                 = false
  tags                                 = var.infrastructure.tags
}

