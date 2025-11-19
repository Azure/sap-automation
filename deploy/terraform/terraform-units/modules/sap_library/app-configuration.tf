# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

#######################################4#######################################8
#                                                                              #
#                          Azure App Configuration                             #
#                                                                              #
#######################################4#######################################8

resource "azurerm_private_dns_zone" "appconfig" {
  provider                             = azurerm.main
  count                                = local.application_configuration_deployed && local.use_local_privatelink_dns && var.dns_settings.register_storage_accounts_keyvaults_with_dns ? 1 : 0
  depends_on                           = [
                                           azurerm_resource_group.library
                                         ]
  name                                 = var.dns_settings.dns_zone_names.appconfig_dns_zone_name
  resource_group_name                  = var.infrastructure.resource_group.exists ? (
                                           split("/", var.infrastructure.resource_group.arm_id)[4]) : (
                                           azurerm_resource_group.library[0].name
                                         )
  tags                                 = var.infrastructure.tags
}

data "azurerm_private_dns_zone" "appconfig" {
  provider                             = azurerm.privatelinkdnsmanagement
  count                                = local.application_configuration_deployed && !local.use_local_privatelink_dns && var.dns_settings.register_storage_accounts_keyvaults_with_dns ? 1 : 0
  name                                 = var.dns_settings.dns_zone_names.appconfig_dns_zone_name
  resource_group_name                  = coalesce(var.dns_settings.privatelink_dns_resourcegroup_name,
                                           var.dns_settings.management_dns_resourcegroup_name,
                                           var.infrastructure.resource_group.exists ? (
                                             split("/", var.infrastructure.resource_group.id)[4]) : (
                                             azurerm_resource_group.library[0].name
                                         ))

}



data  "azurerm_app_configuration" "app_config" {
  count                                = local.application_configuration_deployed ? 1 : 0
  provider                             = azurerm.deployer
  name                                 = local.app_config_name
  resource_group_name                  = local.app_config_resource_group_name
}

data "azurerm_app_configuration_key" "deployer_network_id" {
  count                                = local.application_configuration_deployed ? 1 : 0
  configuration_store_id               = data.azurerm_app_configuration.app_config[0].id
  key                                  = format("%s_Deployer_network_id", var.deployer.control_plane_name)
  label                                = var.deployer.control_plane_name
}


resource "azurerm_app_configuration_key" "libraryStateFileName" {
  provider                             = azurerm.deployer
  depends_on                           = [
                                           azurerm_private_dns_zone_virtual_network_link.vnet_mgmt_appconfig,
                                           azurerm_private_dns_zone_virtual_network_link.appconfig_agent,
                                           azurerm_private_dns_zone_virtual_network_link.appconfig_additional
                                         ]
  count                                = local.application_configuration_deployed ? 1 : 0
  configuration_store_id               = data.azurerm_app_configuration.app_config[0].id
  key                                  = format("%s_LibraryStateFileName", var.deployer.control_plane_name)
  label                                = var.deployer.control_plane_name
  value                                = format("%s-SAP_LIBRARY.terraform.tfstate",var.naming.prefix.LIBRARY)
  content_type                         = "text/plain"
  type                                 = "kv"
  tags                                 = merge(var.infrastructure.tags, {
                                           "source" = "SAPLibrary"
                                         }  )
  lifecycle {
              ignore_changes = [
                configuration_store_id,
                etag,
                id
              ]
            }
}


resource "azurerm_app_configuration_key" "terraformRemoteStateStorageAccountId" {
  provider                             = azurerm.deployer
  depends_on                           = [
                                           azurerm_private_dns_zone_virtual_network_link.vnet_mgmt_appconfig,
                                           azurerm_private_dns_zone_virtual_network_link.appconfig_agent,
                                           azurerm_private_dns_zone_virtual_network_link.appconfig_additional
                                         ]
  count                                = local.application_configuration_deployed ? 1 : 0
  configuration_store_id               = data.azurerm_app_configuration.app_config[0].id
  key                                  = format("%s_TerraformRemoteStateStorageAccountId", var.deployer.control_plane_name)
  label                                = var.deployer.control_plane_name
  value                                = var.storage_account_tfstate.exists ? (
                                                            data.azurerm_storage_account.storage_tfstate[0].id) : (
                                                            try(azurerm_storage_account.storage_tfstate[0].id, "")
                                                          )
  content_type                         = "text/id"
  type                                 = "kv"
  tags                                 = merge(var.infrastructure.tags, {
                                           "source" = "SAPLibrary"
                                         }  )
  lifecycle {
              ignore_changes = [
                configuration_store_id,
                etag,
                id
              ]
            }
}


resource "azurerm_app_configuration_key" "SAPLibraryStorageAccountId" {
  provider                             = azurerm.deployer
  depends_on                           = [
                                           azurerm_private_dns_zone_virtual_network_link.vnet_mgmt_appconfig,
                                           azurerm_private_dns_zone_virtual_network_link.appconfig_agent,
                                           azurerm_private_dns_zone_virtual_network_link.appconfig_additional
                                         ]
  count                                = local.application_configuration_deployed ? 1 : 0
  configuration_store_id               = data.azurerm_app_configuration.app_config[0].id
  key                                  = format("%s_SAPLibraryStorageAccountId", var.deployer.control_plane_name)
  label                                = var.deployer.control_plane_name
  value                                = var.storage_account_tfstate.exists ? (
                                                            data.azurerm_storage_account.storage_sapbits[0].id) : (
                                                            try(azurerm_storage_account.storage_sapbits[0].id, "")
                                                          )
  content_type                         = "text/id"
  type                                 = "kv"
  tags                                 = merge(var.infrastructure.tags, {
                                           "source" = "SAPLibrary"
                                         }  )
  lifecycle {
              ignore_changes = [
                configuration_store_id,
                etag,
                id
              ]
            }
}

resource "azurerm_app_configuration_key" "SAPMediaPath" {
  provider                             = azurerm.deployer
  depends_on                           = [
                                           azurerm_private_dns_zone_virtual_network_link.vnet_mgmt_appconfig,
                                           azurerm_private_dns_zone_virtual_network_link.appconfig_agent,
                                           azurerm_private_dns_zone_virtual_network_link.appconfig_additional
                                         ]
  count                                = local.application_configuration_deployed ? 1 : 0
  configuration_store_id               = data.azurerm_app_configuration.app_config[0].id
  key                                  = format("%s_SAPMediaPath", var.deployer.control_plane_name)
  label                                = var.deployer.control_plane_name
  value                                = format("https://%s.blob.core.windows.net/%s", var.storage_account_sapbits.exists ?
                                                             split("/", var.storage_account_sapbits.id)[8] : local.storage_account_SAPmedia,
                                                             var.storage_account_sapbits.sapbits_blob_container.name)
  content_type                         = "text/plain"
  type                                 = "kv"
  tags                                 = merge(var.infrastructure.tags, {
                                           "source" = "SAPLibrary"
                                         }  )
  lifecycle {
              ignore_changes = [
                configuration_store_id,
                etag,
                id
              ]
            }
}

resource "azurerm_private_dns_zone_virtual_network_link" "vnet_mgmt_appconfig" {
  provider                             = azurerm.dnsmanagement
  count                                = var.dns_settings.register_storage_accounts_keyvaults_with_dns && !var.use_custom_dns_a_registration && var.use_private_endpoint ? 1 : 0
  depends_on                           = [
                                           azurerm_private_dns_zone.appconfig
                                         ]
  name                                 = format("%s%s%s%s-appconfig",
                                           try(var.naming.resource_prefixes.appconfig_link, ""),
                                           local.prefix,
                                           var.naming.separator,
                                           try(var.naming.resource_suffixes.appconfig_link, "appconfig-link")
                                         )

  resource_group_name                  = coalesce(var.dns_settings.privatelink_dns_resourcegroup_name,
                                           var.dns_settings.management_dns_resourcegroup_name,
                                           var.infrastructure.resource_group.exists ? (
                                             split("/", var.infrastructure.resource_group.id)[4]) : (
                                             azurerm_resource_group.library[0].name
                                         ))
  private_dns_zone_name                = var.dns_settings.dns_zone_names.appconfig_dns_zone_name
  virtual_network_id                   = var.deployer_tfstate.vnet_mgmt_id
  registration_enabled                 = false
  tags                                 = var.infrastructure.tags
}


resource "azurerm_private_dns_zone_virtual_network_link" "appconfig_additional" {
  provider                             = azurerm.dnsmanagement
  count                                = var.dns_settings.register_storage_accounts_keyvaults_with_dns && var.use_private_endpoint && length(var.dns_settings.additional_network_id) > 0 ? 1 : 0
  depends_on                           = [
                                            azurerm_private_dns_zone.appconfig
                                         ]

  name                                 = format("%s%s%s%s-appconfig-additional",
                                           try(var.naming.resource_prefixes.appconfig_link, ""),
                                           local.prefix,
                                           var.naming.separator,
                                           try(var.naming.resource_suffixes.appconfig_link, "appconfig-link")
                                         )

  resource_group_name                  = coalesce(var.dns_settings.privatelink_dns_resourcegroup_name,
                                           var.dns_settings.management_dns_resourcegroup_name,
                                           var.infrastructure.resource_group.exists ? (
                                             split("/", var.infrastructure.resource_group.id)[4]) : (
                                             azurerm_resource_group.library[0].name
                                         ))
  private_dns_zone_name                = var.dns_settings.dns_zone_names.appconfig_dns_zone_name
  virtual_network_id                   = var.dns_settings.additional_network_id
  registration_enabled                 = false
  tags                                 = var.infrastructure.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "appconfig_agent" {
  provider                             = azurerm.dnsmanagement
  count                                = ( var.dns_settings.register_storage_accounts_keyvaults_with_dns &&
                                           var.use_private_endpoint &&
                                           (contains(keys(var.deployer_tfstate), "additional_network_id") ? length(var.deployer_tfstate.additional_network_id) > 0 : false) ? 1 : 0
  )
  depends_on                           = [
                                            azurerm_private_dns_zone.appconfig
                                         ]

  name                                 = format("%s%s%s%s-appconfig-agent",
                                           try(var.naming.resource_prefixes.appconfig_link, ""),
                                           local.prefix,
                                           var.naming.separator,
                                           try(var.naming.resource_suffixes.appconfig_link, "appconfig-link")
                                         )

  resource_group_name                  = coalesce(var.dns_settings.privatelink_dns_resourcegroup_name,
                                           var.dns_settings.management_dns_resourcegroup_name,
                                           var.infrastructure.resource_group.exists ? (
                                             split("/", var.infrastructure.resource_group.id)[4]) : (
                                             azurerm_resource_group.library[0].name
                                         ))
  private_dns_zone_name                = var.dns_settings.dns_zone_names.appconfig_dns_zone_name
  virtual_network_id                   = var.deployer_tfstate.additional_network_id
  registration_enabled                 = false
  tags                                 = var.infrastructure.tags
}

locals {
  application_configuration_deployed   = length(var.deployer.application_configuration_id ) > 0
  parsed_id                            = local.application_configuration_deployed ? provider::azurerm::parse_resource_id(coalesce(var.deployer.application_configuration_id, try(var.deployer_tfstate.application_configuration_id, ""))) : null
  app_config_name                      = local.application_configuration_deployed ? local.parsed_id["resource_name"] : ""
  app_config_resource_group_name       = local.application_configuration_deployed ? local.parsed_id["resource_group_name"] : ""
}
