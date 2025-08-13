# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.


#######################################4#######################################8
#                                                                              #
#                                Resource Group                                #
#                                                                              #
#######################################4#######################################8

// Creates the resource group
resource "azurerm_resource_group" "resource_group" {
  provider                             = azurerm.main
  count                                = local.resource_group_exists ? 0 : 1
  name                                 = local.resourcegroup_name
  location                             = local.region
  tags                                 = merge(var.infrastructure.tags, var.tags)

}

// Imports data of existing resource group
data "azurerm_resource_group" "resource_group" {
  provider                             = azurerm.main
  count                                = local.resource_group_exists ? 1 : 0
  name                                 = local.resourcegroup_name
}

// Creates the SAP VNET
resource "azurerm_virtual_network" "vnet_sap" {
  provider                             = azurerm.main
  count                                = var.infrastructure.virtual_networks.sap.exists  ? 0 : 1
  name                                 = local.SAP_virtual_network_name
  location                             = local.resource_group_exists ? (
                                           data.azurerm_resource_group.resource_group[0].location) : (
                                           azurerm_resource_group.resource_group[0].location
                                         )
  resource_group_name                  = local.resource_group_exists ? (
                                           data.azurerm_resource_group.resource_group[0].name) : (
                                           azurerm_resource_group.resource_group[0].name
                                         )
  address_space                        = var.infrastructure.virtual_networks.sap.address_space
  flow_timeout_in_minutes              = var.infrastructure.virtual_networks.sap.flow_timeout_in_minutes
  tags                                 = var.tags
  dns_servers                          = length(var.dns_settings.dns_server_list) > 0 ? var.dns_settings.dns_server_list : []
}

// Imports data of existing SAP VNET
data "azurerm_virtual_network" "vnet_sap" {
  provider                             = azurerm.main
  count                                = var.infrastructure.virtual_networks.sap.exists  ? 1 : 0
  name                                 = split("/", var.infrastructure.virtual_networks.sap.id)[8]
  resource_group_name                  = split("/", var.infrastructure.virtual_networks.sap.id)[4]
}

resource "azurerm_virtual_network_dns_servers" "vnet_sap_dns_servers" {
  provider                             = azurerm.main
  count                                = var.infrastructure.virtual_networks.sap.exists  && length(var.dns_settings.dns_server_list) > 0 ? 1 : 0
  virtual_network_id                   = azurerm_virtual_network.vnet_sap[0].id
  dns_servers                          = var.dns_settings.dns_server_list
}


//Route table
resource "azurerm_route_table" "rt" {
  provider                             = azurerm.main
  count                                = var.infrastructure.virtual_networks.sap.exists  ? 0 : (local.create_nat_gateway ? 0 : 1)
  depends_on                           = [
                                           azurerm_virtual_network.vnet_sap
                                         ]
  name                                 = format("%s%s%s%s",
                                           var.naming.resource_prefixes.routetable,
                                           local.prefix,
                                           var.naming.separator,
                                           local.resource_suffixes.routetable
                                         )
  bgp_route_propagation_enabled        = var.infrastructure.virtual_networks.sap.enable_route_propagation
  resource_group_name                  = azurerm_virtual_network.vnet_sap[0].resource_group_name
  location                             = azurerm_virtual_network.vnet_sap[0].location

  tags                                 = var.tags
}

resource "azurerm_route" "admin" {
  provider                             = azurerm.main
  count                                = length(local.firewall_ip) > 0 ? var.infrastructure.virtual_networks.sap.exists  ? 0 : (local.create_nat_gateway ? 0 : 1) : 0
  depends_on                           = [
                                           azurerm_route_table.rt
                                         ]
  name                                 = format("%s%s%s%s",
                                           var.naming.resource_prefixes.fw_route,
                                           local.prefix,
                                           var.naming.separator,
                                           local.resource_suffixes.fw_route
                                         )
  resource_group_name                  = var.infrastructure.virtual_networks.sap.exists  ? (
                                           data.azurerm_virtual_network.vnet_sap[0].resource_group_name) : (
                                           azurerm_virtual_network.vnet_sap[0].resource_group_name
                                         )
  route_table_name                     = azurerm_route_table.rt[0].name
  address_prefix                       = "0.0.0.0/0"
  next_hop_type                        = "VirtualAppliance"
  next_hop_in_ip_address               = local.firewall_ip

}

resource "azurerm_management_lock" "vnet_sap" {
  provider                             = azurerm.main
  count                                = (var.infrastructure.virtual_networks.sap.exists ) ? 0 : var.place_delete_lock_on_resources ? 1 : 0
  name                                 = format("%s-lock", local.SAP_virtual_network_name)
  scope                                = azurerm_virtual_network.vnet_sap[0].id
  lock_level                           = "CanNotDelete"
  notes                                = "Locked because it's needed by the Workload"
  lifecycle {
              prevent_destroy = false
            }
}

#######################################4#######################################8
#                                                                              #
#                                   Peering                                    #
#                                                                              #
#######################################4#######################################8


# // Peers management VNET to SAP VNET
resource "azurerm_virtual_network_peering" "peering_management_sap" {
  provider                             = azurerm.peering
  depends_on                           = [ azurerm_subnet.admin, azurerm_subnet.app, azurerm_subnet.db, azurerm_subnet.web, azurerm_subnet.iscsi, azurerm_subnet.storage, azurerm_subnet.ams, azurerm_subnet.anf ]
  count                                = length(local.deployer_virtual_network_id) > 0 ? (
                                           var.infrastructure.virtual_networks.sap.exists ? 0 : 1 ) : (
                                           0
                                         )
  name                                 = substr(
                                           format("%s_to_%s",
                                             split("/", local.deployer_virtual_network_id)[8],
                                             var.infrastructure.virtual_networks.sap.exists  ? (
                                               data.azurerm_virtual_network.vnet_sap[0].name) : (
                                               azurerm_virtual_network.vnet_sap[0].name
                                             )
                                           ),
                                           0,
                                           80
                                         )
  virtual_network_name                 = split("/", local.deployer_virtual_network_id)[8]
  resource_group_name                  = split("/", local.deployer_virtual_network_id)[4]
  remote_virtual_network_id            = azurerm_virtual_network.vnet_sap[0].id

  allow_virtual_network_access         = true
}

// Peers SAP VNET to management VNET
resource "azurerm_virtual_network_peering" "peering_sap_management" {
  provider                             = azurerm.main
  depends_on                           = [ azurerm_subnet.admin, azurerm_subnet.app, azurerm_subnet.db, azurerm_subnet.web, azurerm_subnet.iscsi, azurerm_subnet.storage, azurerm_subnet.ams, azurerm_subnet.anf ]
  count                                = length(local.deployer_virtual_network_id) > 0 ? (
                                           var.infrastructure.virtual_networks.sap.exists ? 0 : 1 ) : (
                                           0
                                         )

  name                                 = substr(
                                           format("%s_to_%s",
                                             var.infrastructure.virtual_networks.sap.exists  ? (
                                               data.azurerm_virtual_network.vnet_sap[0].name) : (
                                               azurerm_virtual_network.vnet_sap[0].name
                                             ), split("/", local.deployer_virtual_network_id)[8]
                                           ),
                                           0,
                                           80
                                         )
  resource_group_name                  = var.infrastructure.virtual_networks.sap.exists  ? (
                                           data.azurerm_virtual_network.vnet_sap[0].resource_group_name) : (
                                           azurerm_virtual_network.vnet_sap[0].resource_group_name
                                         )
  virtual_network_name                 = azurerm_virtual_network.vnet_sap[0].name

  remote_virtual_network_id            = local.deployer_virtual_network_id
  allow_virtual_network_access         = true
  allow_forwarded_traffic              = true
}


// Peers SAP VNET to management VNET

# // Peers additional VNET to SAP VNET
resource "azurerm_virtual_network_peering" "peering_additional_network_sap" {
  provider                             = azurerm.peering
  count                                = length(try(var.infrastructure.additional_network_id, "")) > 0 ? 1 : 0
  name                                 = substr(
                                           format("%s_to_%s",
                                             split("/", var.infrastructure.additional_network_id)[8],
                                             var.infrastructure.virtual_networks.sap.exists  ? (
                                               data.azurerm_virtual_network.vnet_sap[0].name) : (
                                               azurerm_virtual_network.vnet_sap[0].name
                                             )
                                           ),
                                           0,
                                           80
                                         )
  virtual_network_name                 = split("/", var.infrastructure.additional_network_id)[8]
  resource_group_name                  = split("/", var.infrastructure.additional_network_id)[4]
  remote_virtual_network_id            = var.infrastructure.virtual_networks.sap.exists  ? (
                                           data.azurerm_virtual_network.vnet_sap[0].id) : (
                                           azurerm_virtual_network.vnet_sap[0].id
                                         )

  allow_virtual_network_access         = true
}



resource "azurerm_virtual_network_peering" "peering_sap_additional_network" {
  provider                             = azurerm.main
  count                                = length(try(var.infrastructure.additional_network_id, "")) > 0 ? 1 : 0
  name                                 = substr(
                                           format("%s_to_%s",
                                             var.infrastructure.virtual_networks.sap.exists  ? (
                                               data.azurerm_virtual_network.vnet_sap[0].name) : (
                                               azurerm_virtual_network.vnet_sap[0].name
                                             ), split("/", var.infrastructure.additional_network_id)[8]
                                           ),
                                           0,
                                           80
                                         )
  resource_group_name                  = var.infrastructure.virtual_networks.sap.exists  ? (
                                           data.azurerm_virtual_network.vnet_sap[0].resource_group_name) : (
                                           azurerm_virtual_network.vnet_sap[0].resource_group_name
                                         )
  virtual_network_name                 = var.infrastructure.virtual_networks.sap.exists  ? (
                                           data.azurerm_virtual_network.vnet_sap[0].name) : (
                                           azurerm_virtual_network.vnet_sap[0].name
                                         )
  remote_virtual_network_id            = var.infrastructure.additional_network_id
  allow_virtual_network_access         = true
  allow_forwarded_traffic              = true
}
