#######################################4#######################################8
#                                                                              #
#                                DNS Information                               #
#                                                                              #
#######################################4#######################################8

resource "azurerm_private_dns_zone" "dns" {
  provider                             = azurerm.main
  count                                = local.use_local_private_dns ? 1 : 0
  depends_on                           = [
                                           azurerm_resource_group.library
                                         ]
  name                                 = var.dns_label
  resource_group_name                  = local.resource_group_exists ? (
                                           split("/", var.infrastructure.resource_group.arm_id)[4]) : (
                                           azurerm_resource_group.library[0].name
                                         )
}
resource "azurerm_private_dns_zone" "blob" {
  provider                             = azurerm.main
  count                                = local.use_local_private_dns && var.use_private_endpoint ? 1 : 0
  depends_on                           = [
                                           azurerm_resource_group.library
                                         ]
  name                                 = var.dns_zone_names.blob_dns_zone_name
  resource_group_name                  = local.resource_group_exists ? (
                                           split("/", var.infrastructure.resource_group.arm_id)[4]) : (
                                           azurerm_resource_group.library[0].name
                                         )
}

resource "azurerm_private_dns_zone" "table" {
  provider                             = azurerm.main
  count                                = local.use_local_private_dns && var.use_private_endpoint && var.use_webapp ? 1 : 0
  depends_on                           = [
                                           azurerm_resource_group.library
                                         ]
  name                                 = var.dns_zone_names.table_dns_zone_name
  resource_group_name                  = local.resource_group_exists ? (
                                           split("/", var.infrastructure.resource_group.arm_id)[4]) : (
                                           azurerm_resource_group.library[0].name
                                         )
}

resource "azurerm_private_dns_zone" "file" {
  provider                             = azurerm.main
  count                                = local.use_local_private_dns && var.use_private_endpoint ? 1 : 0
  depends_on                           = [
                                           azurerm_resource_group.library
                                         ]
  name                                 = var.dns_zone_names.file_dns_zone_name
  resource_group_name                  = local.resource_group_exists ? (
                                           split("/", var.infrastructure.resource_group.arm_id)[4]) : (
                                           azurerm_resource_group.library[0].name
                                         )
}

resource "azurerm_private_dns_zone" "vault" {
  provider                             = azurerm.main
  count                                = local.use_local_private_dns && var.use_private_endpoint ? 1 : 0
  depends_on                           = [
                                           azurerm_resource_group.library
                                         ]
  name                                 = var.dns_zone_names.vault_dns_zone_name
  resource_group_name                  = local.resource_group_exists ? (
                                           split("/", var.infrastructure.resource_group.arm_id)[4]) : (
                                           azurerm_resource_group.library[0].name
                                         )
}

data "azurerm_private_dns_zone" "vault" {
  provider                             = azurerm.dnsmanagement
  count                                = !local.use_local_private_dns && var.use_private_endpoint ? 1 : 0
  name                                 = var.dns_zone_names.vault_dns_zone_name
  resource_group_name                  = var.management_dns_resourcegroup_name
}


