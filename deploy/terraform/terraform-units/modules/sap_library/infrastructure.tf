/*
  Description:
  Set up infrastructure for sap library
*/

resource "azurerm_resource_group" "library" {
  provider = azurerm.main
  count    = local.resource_group_exists ? 0 : 1
  name     = local.resource_group_name
  location = local.region
  tags     = var.infrastructure.tags

  lifecycle {
    ignore_changes = [
      tags
    ]
  }

}

// Imports data of existing resource group
data "azurerm_resource_group" "library" {
  provider = azurerm.main
  count    = local.resource_group_exists ? 1 : 0
  name     = split("/", var.infrastructure.resource_group.arm_id)[4]
}

// TODO: Add management lock when this issue is addressed https://github.com/terraform-providers/terraform-provider-azurerm/issues/5473


resource "azurerm_private_dns_zone" "dns" {
  depends_on = [
    azurerm_resource_group.library
  ]
  provider = azurerm.main
  count    = local.use_local_private_dns ? 1 : 0
  name     = var.dns_label
  resource_group_name = local.resource_group_exists ? (
    split("/", var.infrastructure.resource_group.arm_id)[4]) : (
    azurerm_resource_group.library[0].name
  )
}

resource "azurerm_private_dns_zone" "blob" {
  depends_on = [
    azurerm_resource_group.library
  ]
  provider = azurerm.main
  count    = local.use_local_private_dns && var.use_private_endpoint ? 1 : 0
  name     = "privatelink.blob.core.windows.net"
  resource_group_name = local.resource_group_exists ? (
    split("/", var.infrastructure.resource_group.arm_id)[4]) : (
    azurerm_resource_group.library[0].name
  )
}

resource "azurerm_private_dns_zone" "vault" {
  depends_on = [
    azurerm_resource_group.library
  ]
  provider = azurerm.main
  count    = local.use_local_private_dns && var.use_private_endpoint ? 1 : 0
  name     = "privatelink.vaultcore.azure.net"
  resource_group_name = local.resource_group_exists ? (
    split("/", var.infrastructure.resource_group.arm_id)[4]) : (
    azurerm_resource_group.library[0].name
  )
}

resource "azurerm_private_dns_zone" "file" {
  depends_on = [
    azurerm_resource_group.library
  ]
  provider = azurerm.main
  count    = local.use_local_private_dns && var.use_private_endpoint ? 1 : 0
  name     = "privatelink.file.core.windows.net"
  resource_group_name = local.resource_group_exists ? (
    split("/", var.infrastructure.resource_group.arm_id)[4]) : (
    azurerm_resource_group.library[0].name
  )
}



resource "azurerm_private_dns_zone_virtual_network_link" "vnet_mgmt" {
  provider = azurerm.dnsmanagement
  count = length(var.dns_label) > 0 && !var.use_custom_dns_a_registration ? 1 : 0
  name = format("%s%s%s%s",
    var.naming.resource_prefixes.dns_link,
    local.prefix,
    var.naming.separator,
    var.naming.resource_suffixes.dns_link
  )

  resource_group_name = length(var.management_dns_subscription_id) == 0 ? (
    local.resource_group_exists ? (
      split("/", var.infrastructure.resource_group.arm_id)[4]) : (
      azurerm_resource_group.library[0].name
    )) : (
    var.management_dns_resourcegroup_name
  )
  private_dns_zone_name = var.dns_label
  virtual_network_id    = var.deployer_tfstate.vnet_mgmt_id
  registration_enabled  = true
}

resource "azurerm_private_dns_zone_virtual_network_link" "vnet_mgmt_blob" {
  provider = azurerm.dnsmanagement
  count = length(var.dns_label) > 0 && !var.use_custom_dns_a_registration ? 1 : 0
  name = format("%s%s%s%s-blob",
    var.naming.resource_prefixes.dns_link,
    local.prefix,
    var.naming.separator,
    var.naming.resource_suffixes.dns_link
  )

  resource_group_name = length(var.management_dns_subscription_id) == 0 ? (
    local.resource_group_exists ? (
      split("/", var.infrastructure.resource_group.arm_id)[4]) : (
      azurerm_resource_group.library[0].name
    )) : (
    var.management_dns_resourcegroup_name
  )
  private_dns_zone_name = "privatelink.blob.core.windows.net"
  virtual_network_id    = var.deployer_tfstate.vnet_mgmt_id
  registration_enabled  = false
}

resource "azurerm_role_assignment" "storage_tfstate_contributor" {
  provider             = azurerm.main
  count                = length(try(var.deployer_tfstate.deployer_system_assigned_identity, []))
  scope                = local.resource_group_exists ? data.azurerm_resource_group.library[0].id : azurerm_resource_group.library[0].id
  role_definition_name = "Contributor"
  principal_id         = var.deployer_tfstate.deployer_system_assigned_identity[count.index]
}

resource "azurerm_role_assignment" "storage_tfstate_contributor_msi" {
  provider             = azurerm.main
  scope                = local.resource_group_exists ? data.azurerm_resource_group.library[0].id : azurerm_resource_group.library[0].id
  role_definition_name = "Contributor"
  principal_id         = var.deployer_tfstate.deployer_uai.principal_id
}
