#######################################4#######################################8
#                                                                              #
#                                Admin Subnet                                  #
#                                                                              #
#######################################4#######################################8

resource "azurerm_subnet" "admin" {
  provider                             = azurerm.main
  count                                = !local.admin_subnet_exists && local.enable_admin_subnet ? 1 : 0
  name                                 = local.admin_subnet_name
  resource_group_name                  = data.azurerm_virtual_network.vnet_sap.resource_group_name
  virtual_network_name                 = data.azurerm_virtual_network.vnet_sap.name
  address_prefixes                     = [local.admin_subnet_prefix]

}

resource "azurerm_subnet_route_table_association" "admin" {
  provider                             = azurerm.main
  count                                = local.admin_subnet_defined && !local.admin_subnet_exists && local.enable_admin_subnet && length(var.landscape_tfstate.route_table_id) > 0 ? (
                                           1) : (
                                           0
                                         )
  subnet_id                            = azurerm_subnet.admin[0].id
  route_table_id                       = var.landscape_tfstate.route_table_id
}


// Imports data of existing SAP admin subnet
data "azurerm_subnet" "admin" {
  provider                             = azurerm.main
  count                                = local.admin_subnet_exists && local.enable_admin_subnet ? 1 : 0
  name                                 = split("/", local.admin_subnet_arm_id)[10]
  resource_group_name                  = split("/", local.admin_subnet_arm_id)[4]
  virtual_network_name                 = split("/", local.admin_subnet_arm_id)[8]
}


#######################################4#######################################8
#                                                                              #
#                                  DB Subnet                                   #
#                                                                              #
#######################################4#######################################8

resource "azurerm_subnet" "db" {
  provider                             = azurerm.main
  count                                = length(trimspace(local.database_subnet_arm_id)) == 0 ? 1 : 0
  name                                 = local.database_subnet_name
  resource_group_name                  = data.azurerm_virtual_network.vnet_sap.resource_group_name
  virtual_network_name                 = data.azurerm_virtual_network.vnet_sap.name
  address_prefixes                     = [local.database_subnet_prefix]
}

// Imports data of existing db subnet
data "azurerm_subnet" "db" {
  provider                             = azurerm.main
  count                                = length(local.database_subnet_arm_id) > 0 ? 1 : 0
  name                                 = split("/", local.database_subnet_arm_id)[10]
  resource_group_name                  = split("/", local.database_subnet_arm_id)[4]
  virtual_network_name                 = split("/", local.database_subnet_arm_id)[8]
}

resource "azurerm_subnet_route_table_association" "db" {
  provider                             = azurerm.main
  count                                = (
                                           local.database_subnet_defined && !local.database_subnet_exists && length(var.landscape_tfstate.route_table_id) > 0
                                           ) ? (
                                           1) : (
                                           0
                                         )
  subnet_id                            = azurerm_subnet.db[0].id
  route_table_id                       = var.landscape_tfstate.route_table_id
}


#########################################################################################
#                                                                                       #
#  Scaleout Subnet variables                                                            #
#                                                                                       #
#########################################################################################

resource "azurerm_subnet" "storage" {
  provider                             = azurerm.main
  count                                = local.enable_db_deployment && local.enable_storage_subnet ? (
                                           local.sub_storage_exists ? 0 : 1) : (
                                           0
                                         )
  name                                 = local.sub_storage_name
  resource_group_name                  = data.azurerm_virtual_network.vnet_sap.resource_group_name
  virtual_network_name                 = data.azurerm_virtual_network.vnet_sap.name
  address_prefixes                     = [local.sub_storage_prefix]
}

// Imports data of existing db subnet
data "azurerm_subnet" "storage" {
  provider                             = azurerm.main
  count                                = local.enable_db_deployment && local.enable_storage_subnet ? (
                                           local.sub_storage_exists ? 1 : 0) : (
                                           0
                                         )
  name                                 = split("/", local.sub_storage_arm_id)[10]
  resource_group_name                  = split("/", local.sub_storage_arm_id)[4]
  virtual_network_name                 = split("/", local.sub_storage_arm_id)[8]
}
