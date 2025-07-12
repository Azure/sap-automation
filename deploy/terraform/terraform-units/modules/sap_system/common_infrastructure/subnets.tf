# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

#######################################4#######################################8
#                                                                              #
#                                Admin Subnet                                  #
#                                                                              #
#######################################4#######################################8

resource "azurerm_subnet" "admin" {
  provider                             = azurerm.main
  count                                = local.enable_admin_subnet ? var.infrastructure.virtual_networks.sap.subnet_db.defined  ? 1 : 0 : 0
  name                                 = local.admin_subnet_name
  resource_group_name                  = data.azurerm_virtual_network.vnet_sap.resource_group_name
  virtual_network_name                 = data.azurerm_virtual_network.vnet_sap.name
  address_prefixes                     = [var.infrastructure.virtual_networks.sap.subnet_admin.prefix]

}

resource "azurerm_subnet_route_table_association" "admin" {
  provider                             = azurerm.main
  count                                = var.infrastructure.virtual_networks.sap.subnet_admin.defined && local.enable_admin_subnet && length(var.landscape_tfstate.route_table_id) > 0 ? (
                                           1) : (
                                           0
                                         )
  subnet_id                            = azurerm_subnet.admin[0].id
  route_table_id                       = var.landscape_tfstate.route_table_id
}


// Imports data of existing SAP admin subnet
data "azurerm_subnet" "admin" {
  provider                             = azurerm.main
  count                                = local.enable_admin_subnet ? var.infrastructure.virtual_networks.sap.subnet_admin.exists || var.infrastructure.virtual_networks.sap.subnet_admin.exists_in_workload ? 1 : 0 ? 0 : 1 : 0
  name                                 = split("/", coalesce(var.infrastructure.virtual_networks.sap.subnet_admin.id, var.infrastructure.virtual_networks.sap.subnet_admin.id_in_workload))[10]
  resource_group_name                  = split("/", coalesce(var.infrastructure.virtual_networks.sap.subnet_admin.id, var.infrastructure.virtual_networks.sap.subnet_admin.id_in_workload))[4]
  virtual_network_name                 = split("/", coalesce(var.infrastructure.virtual_networks.sap.subnet_admin.id, var.infrastructure.virtual_networks.sap.subnet_admin.id_in_workload))[8]
}


#######################################4#######################################8
#                                                                              #
#                                  DB Subnet                                   #
#                                                                              #
#######################################4#######################################8

resource "azurerm_subnet" "db" {
  provider                             = azurerm.main
  count                                = var.infrastructure.virtual_networks.sap.subnet_db.defined ? 1 : 0
  name                                 = local.database_subnet_name
  resource_group_name                  = data.azurerm_virtual_network.vnet_sap.resource_group_name
  virtual_network_name                 = data.azurerm_virtual_network.vnet_sap.name
  address_prefixes                     = [var.infrastructure.virtual_networks.sap.subnet_db.prefix]
}

// Imports data of existing db subnet
data "azurerm_subnet" "db" {
  provider                             = azurerm.main
  count                                = var.infrastructure.virtual_networks.sap.subnet_db.exists || var.infrastructure.virtual_networks.sap.subnet_db.exists_in_workload ? 1 : 0
  name                                 = split("/", coalesce(var.infrastructure.virtual_networks.sap.subnet_db.id, var.infrastructure.virtual_networks.sap.subnet_db.id_in_workload))[10]
  resource_group_name                  = split("/", coalesce(var.infrastructure.virtual_networks.sap.subnet_db.id, var.infrastructure.virtual_networks.sap.subnet_db.id_in_workload))[4]
  virtual_network_name                 = split("/", coalesce(var.infrastructure.virtual_networks.sap.subnet_db.id, var.infrastructure.virtual_networks.sap.subnet_db.id_in_workload))[8]
}

resource "azurerm_subnet_route_table_association" "db" {
  provider                             = azurerm.main
  count                                = (
                                           var.infrastructure.virtual_networks.sap.subnet_db.defined && length(var.landscape_tfstate.route_table_id) > 0
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
  count                                = var.infrastructure.virtual_networks.sap.subnet_storage.defined ? 1 : 0
  name                                 = local.storage_subnet_name
  resource_group_name                  = data.azurerm_virtual_network.vnet_sap.resource_group_name
  virtual_network_name                 = data.azurerm_virtual_network.vnet_sap.name
  address_prefixes                     = [var.infrastructure.virtual_networks.sap.subnet_storage.prefix]
}

// Imports data of existing db subnet
data "azurerm_subnet" "storage" {
  provider                             = azurerm.main
  count                                = var.infrastructure.virtual_networks.sap.subnet_storage.exists || var.infrastructure.virtual_networks.sap.subnet_storage.exists_in_workload ? 1 : 0
  name                                 = split("/", coalesce(var.infrastructure.virtual_networks.sap.subnet_storage.id, var.infrastructure.virtual_networks.sap.subnet_storage.id_in_workload))[10]
  resource_group_name                  = split("/", coalesce(var.infrastructure.virtual_networks.sap.subnet_storage.id, var.infrastructure.virtual_networks.sap.subnet_storage.id_in_workload))[4]
  virtual_network_name                 = split("/", coalesce(var.infrastructure.virtual_networks.sap.subnet_storage.id, var.infrastructure.virtual_networks.sap.subnet_storage.id_in_workload))[8]
}
