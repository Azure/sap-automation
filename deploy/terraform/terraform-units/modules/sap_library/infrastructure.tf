#######################################4#######################################8
#                                                                              #
#                                Resource Group Information                    #
#                                                                              #
#######################################4#######################################8

resource "azurerm_resource_group" "library" {
  provider                             = azurerm.main
  count                                = local.resource_group_exists ? 0 : 1
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
  count                                = local.resource_group_exists ? 1 : 0
  name                                 = split("/", var.infrastructure.resource_group.arm_id)[4]
}

resource "azurerm_role_assignment" "library_sai" {
  provider                             = azurerm.main
  count                                = var.bootstrap ? 0 : try(var.deployer_tfstate.add_system_assigned_identity, false) ? 1 : 0
  scope                                = local.resource_group_exists ? var.infrastructure.resource_group.arm_id : azurerm_resource_group.library[0].id
  role_definition_name                 = "Storage Blob Data Contributor"
  principal_id                         = var.deployer_tfstate.deployer_system_assigned_identity[count.index]
}


resource "azurerm_role_assignment" "library_webapp_system_assigned_identity" {
  provider                             = azurerm.main
  count                                = length(var.deployer_tfstate.webapp_identity) > 0 ? 1 : 0
  scope                                = local.resource_group_exists ? var.infrastructure.resource_group.arm_id : azurerm_resource_group.library[0].id
  role_definition_name                 = "Storage Blob Data Contributor"
  principal_id                         = var.deployer_tfstate.webapp_identity
}


// TODO: Add management lock when this issue is addressed https://github.com/terraform-providers/terraform-provider-azurerm/issues/5473


resource "azurerm_private_dns_zone_virtual_network_link" "vnet_mgmt" {
  provider                             = azurerm.dnsmanagement
  count                                = length(var.dns_settings.dns_label) > 0 && !var.use_custom_dns_a_registration && var.use_private_endpoint ? 1 : 0
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
                                           local.resource_group_exists ? (
                                             split("/", var.infrastructure.resource_group.arm_id)[4]) : (
                                             azurerm_resource_group.library[0].name
                                         ))
  private_dns_zone_name                = var.dns_settings.dns_label
  virtual_network_id                   = var.deployer_tfstate.vnet_mgmt_id
  registration_enabled                 = true
}

resource "azurerm_private_dns_zone_virtual_network_link" "vnet_mgmt_blob" {
  provider                             = azurerm.dnsmanagement
  count                                = var.dns_settings.register_storage_accounts_keyvaults_with_dns && !var.use_custom_dns_a_registration && var.use_private_endpoint ? 1 : 0
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
                                           local.resource_group_exists ? (
                                             split("/", var.infrastructure.resource_group.arm_id)[4]) : (
                                             azurerm_resource_group.library[0].name
                                         ))
  private_dns_zone_name                = var.dns_settings.dns_zone_names.blob_dns_zone_name
  virtual_network_id                   = var.deployer_tfstate.vnet_mgmt_id
  registration_enabled                 = false
}


