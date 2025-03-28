# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.


#######################################4#######################################8
#                                                                              #
#                                Network links                                 #
#                                                                              #
#######################################4#######################################8


resource "azurerm_private_dns_zone_virtual_network_link" "vnet_sap" {
  provider                             = azurerm.dnsmanagement
  count                                = local.use_Azure_native_DNS && var.use_private_endpoint && var.dns_settings.register_virtual_network_to_dns ? 1 : 0
  depends_on                           = [
                                           azurerm_virtual_network.vnet_sap,
                                           azurerm_subnet.app,
                                           azurerm_key_vault.kv_user
                                         ]
  name                                 = format("%s%s%s%s",
                                           var.naming.resource_prefixes.dns_link,
                                           local.prefix,
                                           var.naming.separator,
                                           var.naming.resource_suffixes.dns_link
                                         )

  resource_group_name                  = var.dns_settings.management_dns_resourcegroup_name

  private_dns_zone_name                = var.dns_settings.dns_label
  virtual_network_id                   = azurerm_virtual_network.vnet_sap[0].id
  registration_enabled                 = true
}

resource "azurerm_private_dns_zone_virtual_network_link" "vnet_sap_file" {
  provider                             = azurerm.privatelinkdnsmanagement
  count                                = local.use_Azure_native_DNS && var.use_private_endpoint ? 1 : 0
  depends_on                           = [
                                           azurerm_virtual_network.vnet_sap,
                                           azurerm_subnet.app,
                                           azurerm_key_vault.kv_user
                                         ]
  name                                 = format("%s%s%s%s-file",
                                           var.naming.resource_prefixes.dns_link,
                                           local.prefix,
                                           var.naming.separator,
                                           var.naming.resource_suffixes.dns_link
                                         )

  resource_group_name                  = var.dns_settings.privatelink_dns_resourcegroup_name

  private_dns_zone_name                = var.dns_settings.dns_zone_names.file_dns_zone_name
  virtual_network_id                   = azurerm_virtual_network.vnet_sap[0].id
  registration_enabled                 = false
}

resource "azurerm_private_dns_zone_virtual_network_link" "storage" {
  provider                             = azurerm.privatelinkdnsmanagement
  count                                = local.use_Azure_native_DNS  && var.use_private_endpoint ? 1 : 0
  depends_on                           = [
                                           azurerm_virtual_network.vnet_sap,
                                           azurerm_storage_account.witness_storage,
                                           azurerm_key_vault.kv_user
                                         ]
  name                                 = format("%s%s%s%s-blob",
                                           var.naming.resource_prefixes.dns_link,
                                           local.prefix,
                                           var.naming.separator,
                                           var.naming.resource_suffixes.dns_link
                                         )

  resource_group_name                  = var.dns_settings.privatelink_dns_resourcegroup_name
  private_dns_zone_name                = var.dns_settings.dns_zone_names.blob_dns_zone_name
  virtual_network_id                   = azurerm_virtual_network.vnet_sap[0].id
}

resource "azurerm_private_dns_zone_virtual_network_link" "vault" {
  provider                             = azurerm.privatelinkdnsmanagement
  count                                = local.use_Azure_native_DNS && var.use_private_endpoint ? 1 : 0
  depends_on                           = [
                                           azurerm_virtual_network.vnet_sap,
                                           azurerm_key_vault.kv_user
                                         ]
  name                                 = format("%s%s%s%s",
                                           var.naming.resource_prefixes.dns_link,
                                           local.prefix,
                                           var.naming.separator,
                                           "vault"
                                         )
  resource_group_name                  = var.dns_settings.privatelink_dns_resourcegroup_name
  private_dns_zone_name                = var.dns_settings.dns_zone_names.vault_dns_zone_name
  virtual_network_id                   = azurerm_virtual_network.vnet_sap[0].id
  registration_enabled                 = false
}


# resource "azurerm_private_dns_a_record" "transport" {
#   provider                             = azurerm.privatelinkdnsmanagement
#   count                                = var.use_private_endpoint && var.create_transport_storage && local.use_Azure_native_DNS && local.use_AFS_for_shared && length(var.transport_private_endpoint_id) == 0 ? 1 : 0
#   name                                 = replace(
#                                            lower(
#                                              format("%s", local.landscape_shared_transport_storage_account_name)
#                                            ),
#                                            "/[^a-z0-9]/",
#                                            ""
#                                          )
#   zone_name                            = var.dns_settings.dns_zone_names.file_dns_zone_name
#   resource_group_name                  = var.dns_settings.privatelink_dns_resourcegroup_name
#   ttl                                  = 10
#   records                              = [
#                                            length(var.transport_private_endpoint_id) > 0 ? (
#                                              data.azurerm_private_endpoint_connection.transport[0].private_service_connection[0].private_ip_address) : (
#                                              azurerm_private_endpoint.transport[0].private_service_connection[0].private_ip_address  )
#                                          ]
#   tags                                 = var.tags
# }

# resource "azurerm_private_dns_a_record" "install" {
#   provider                             = azurerm.privatelinkdnsmanagement
#   count                                = var.use_private_endpoint && local.use_Azure_native_DNS && local.use_AFS_for_shared && length(var.install_private_endpoint_id) == 0 ? 1 : 0
#   name                                 = replace(
#                                            lower(
#                                              format("%s", local.landscape_shared_install_storage_account_name)
#                                            ),
#                                            "/[^a-z0-9]/",
#                                            ""
#                                          )
#   zone_name                            = var.dns_settings.dns_zone_names.file_dns_zone_name
#   resource_group_name                  = var.dns_settings.privatelink_dns_resourcegroup_name
#   ttl                                  = 10
#   records                              = [
#                                            length(var.install_private_endpoint_id) > 0 ? (
#                                              data.azurerm_private_endpoint_connection.install[0].private_service_connection[0].private_ip_address) : (
#                                              azurerm_private_endpoint.install[0].private_service_connection[0].private_ip_address)
#                                          ]

#   lifecycle {
#               ignore_changes = [tags]
#             }
# }


#######################################4#######################################8
#                                                                              #
#                                 DNS records                                  #
#                                                                              #
#######################################4#######################################8

# resource "azurerm_private_dns_a_record" "witness_storage" {
#   provider                             = azurerm.privatelinkdnsmanagement
#   count                                = var.dns_settings.register_storage_accounts_keyvaults_with_dns ? 0 : 0
#   name                                 = lower(local.witness_storageaccount_name)
#   zone_name                            = var.dns_settings.dns_zone_names.blob_dns_zone_name
#   resource_group_name                  = var.dns_settings.privatelink_dns_resourcegroup_name
#   ttl                                  = 3600
#   records                              = [azurerm_private_endpoint.witness_storage[count.index].private_service_connection[0].private_ip_address]

#   tags                                 = var.tags
# }


# resource "azurerm_private_dns_a_record" "storage_bootdiag" {
#   provider                             = azurerm.privatelinkdnsmanagement
#   count                                = var.dns_settings.register_storage_accounts_keyvaults_with_dns ? 0 : 0
#   name                                 = lower(local.storageaccount_name)

#   zone_name                            = var.dns_settings.dns_zone_names.blob_dns_zone_name
#   resource_group_name                  = local.resource_group_exists ? (
#                                            data.azurerm_resource_group.resource_group[0].name) : (
#                                            azurerm_resource_group.resource_group[0].name
#                                          )
#   ttl                                  = 3600
#   records                              = [azurerm_private_endpoint.storage_bootdiag[count.index].private_service_connection[0].private_ip_address]
#   tags                                 = var.tags
# }

data "azurerm_private_dns_a_record" "install" {
  provider                             = azurerm.privatelinkdnsmanagement
  count                                = var.use_private_endpoint && length(var.install_private_endpoint_id) > 0 ? 1 : 0
  name                                 = replace(
                                          lower(
                                            format("%s", local.landscape_shared_install_storage_account_name)
                                          ),
                                          "/[^a-z0-9]/",
                                          ""
                                        )
  zone_name                            = var.dns_settings.dns_zone_names.file_dns_zone_name
  resource_group_name                  = var.dns_settings.privatelink_dns_resourcegroup_name
}

data "azurerm_private_dns_a_record" "transport" {
  provider                             = azurerm.privatelinkdnsmanagement
  count                                = var.create_transport_storage && var.use_private_endpoint && length(var.transport_private_endpoint_id) > 0 ? 1 : 0
  name                                 = replace(
                                           lower(
                                             format("%s", local.landscape_shared_transport_storage_account_name)
                                           ),
                                           "/[^a-z0-9]/",
                                           ""
                                         )
  zone_name                            = var.dns_settings.dns_zone_names.file_dns_zone_name
  resource_group_name                  = var.dns_settings.privatelink_dns_resourcegroup_name
}

# Duplicate code, the private endpoint deployment performs the DNS registration
# resource "azurerm_private_dns_a_record" "keyvault" {
#   provider                             = azurerm.privatelinkdnsmanagement
#   count                                = local.use_Azure_native_DNS && var.use_private_endpoint ?  0 : 0
#   name                                 = lower(
#                                            format("%s", local.user_keyvault_name)
#                                          )
#   zone_name                            = var.dns_settings.dns_zone_names.vault_dns_zone_name
#   resource_group_name                  = var.dns_settings.privatelink_dns_resourcegroup_name
#   ttl                                  = 10
#   records                              = [
#                                            length(var.keyvault_private_endpoint_id) > 0 ? (
#                                              data.azurerm_private_endpoint_connection.kv_user[0].private_service_connection[0].private_ip_address) : (
#                                              azurerm_private_endpoint.kv_user[0].private_service_connection[0].private_ip_address
#                                            )
#                                          ]
#   tags                                 = var.tags

# }

#######################################4#######################################8
#                                                                              #
#                                   DNS zones                                  #
#                                                                              #
#######################################4#######################################
data "azurerm_private_dns_zone" "file" {
  provider                             = azurerm.privatelinkdnsmanagement
  count                                = !local.privatelink_file_defined && var.dns_settings.register_storage_accounts_keyvaults_with_dns ? 1 : 0
  name                                 = var.dns_settings.dns_zone_names.file_dns_zone_name
  resource_group_name                  = var.dns_settings.privatelink_dns_resourcegroup_name
}

data "azurerm_private_dns_zone" "storage" {
  provider                             = azurerm.privatelinkdnsmanagement
  count                                = !local.privatelink_storage_defined && var.dns_settings.register_storage_accounts_keyvaults_with_dns ? 1 : 0
  name                                 = var.dns_settings.dns_zone_names.blob_dns_zone_name
  resource_group_name                  = var.dns_settings.privatelink_dns_resourcegroup_name
}

data "azurerm_private_dns_zone" "keyvault" {
  provider                             = azurerm.privatelinkdnsmanagement
  count                                = !local.privatelink_keyvault_defined && var.dns_settings.register_storage_accounts_keyvaults_with_dns ? 1 : 0
  name                                 = var.dns_settings.dns_zone_names.vault_dns_zone_name
  resource_group_name                  = var.dns_settings.privatelink_dns_resourcegroup_name
}
