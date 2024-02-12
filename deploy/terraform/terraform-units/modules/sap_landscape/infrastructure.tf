
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
  count                                = local.SAP_virtualnetwork_exists ? 0 : 1
  name                                 = local.SAP_virtualnetwork_name
  location                             = local.resource_group_exists ? (
                                           data.azurerm_resource_group.resource_group[0].location) : (
                                           azurerm_resource_group.resource_group[0].location
                                         )
  resource_group_name                  = local.resource_group_exists ? (
                                           data.azurerm_resource_group.resource_group[0].name) : (
                                           azurerm_resource_group.resource_group[0].name
                                         )
  address_space                        = local.network_address_space
  tags                                 = var.tags
}

// Imports data of existing SAP VNET
data "azurerm_virtual_network" "vnet_sap" {
  provider                             = azurerm.main
  count                                = local.SAP_virtualnetwork_exists ? 1 : 0
  name                                 = split("/", local.SAP_virtualnetwork_id)[8]
  resource_group_name                  = split("/", local.SAP_virtualnetwork_id)[4]
}

resource "azurerm_virtual_network_dns_servers" "vnet_sap_dns_servers" {
  provider                             = azurerm.main
  count                                = local.SAP_virtualnetwork_exists && length(var.dns_server_list) > 0 ? 1 : 0
  virtual_network_id                   = local.SAP_virtualnetwork_exists ? (
                                           data.azurerm_virtual_network.vnet_sap[0].id) : (
                                           azurerm_virtual_network.vnet_sap[0].id
                                         )
  dns_servers                          = var.dns_server_list
}

# // Peers management VNET to SAP VNET
resource "azurerm_virtual_network_peering" "peering_management_sap" {
  provider                             = azurerm.peering
  depends_on                           = [
                                           azurerm_subnet.app,
                                           azurerm_subnet.db,
                                           azurerm_subnet.web,
                                           azurerm_subnet.admin,
                                           azurerm_subnet.ams

                                         ]

  count                                = var.peer_with_control_plane_vnet ? (
                                           local.SAP_virtualnetwork_exists || !var.use_deployer ? 0 : 1) : (
                                           0
                                         )
  name                                 = substr(
                                           format("%s_to_%s",
                                             split("/", local.deployer_virtualnetwork_id)[8],
                                             local.SAP_virtualnetwork_exists ? (
                                               data.azurerm_virtual_network.vnet_sap[0].name) : (
                                               azurerm_virtual_network.vnet_sap[0].name
                                             )
                                           ),
                                           0,
                                           80
                                         )
  virtual_network_name                 = split("/", local.deployer_virtualnetwork_id)[8]
  resource_group_name                  = split("/", local.deployer_virtualnetwork_id)[4]
  remote_virtual_network_id            = local.SAP_virtualnetwork_exists ? (
                                           data.azurerm_virtual_network.vnet_sap[0].id) : (
                                           azurerm_virtual_network.vnet_sap[0].id
                                         )

  allow_virtual_network_access         = true
}

// Peers SAP VNET to management VNET
resource "azurerm_virtual_network_peering" "peering_sap_management" {
  provider                             = azurerm.main
  count                                = var.peer_with_control_plane_vnet ? (
                                           local.SAP_virtualnetwork_exists || !var.use_deployer ? 0 : 1) : (
                                           0
                                         )
  depends_on                           = [
                                           azurerm_subnet.app,
                                           azurerm_subnet.db,
                                           azurerm_subnet.web,
                                           azurerm_subnet.admin,
                                           azurerm_subnet.ams

                                         ]

  name                                 = substr(
                                           format("%s_to_%s",
                                             local.SAP_virtualnetwork_exists ? (
                                               data.azurerm_virtual_network.vnet_sap[0].name) : (
                                               azurerm_virtual_network.vnet_sap[0].name
                                             ), split("/", local.deployer_virtualnetwork_id)[8]
                                           ),
                                           0,
                                           80
                                         )
  resource_group_name                  = local.SAP_virtualnetwork_exists ? (
                                           data.azurerm_virtual_network.vnet_sap[0].resource_group_name) : (
                                           azurerm_virtual_network.vnet_sap[0].resource_group_name
                                         )
  virtual_network_name                 = local.SAP_virtualnetwork_exists ? (
                                           data.azurerm_virtual_network.vnet_sap[0].name) : (
                                           azurerm_virtual_network.vnet_sap[0].name
                                         )
  remote_virtual_network_id            = local.deployer_virtualnetwork_id
  allow_virtual_network_access         = true
  allow_forwarded_traffic              = true
}

//Route table
resource "azurerm_route_table" "rt" {
  provider                             = azurerm.main
  count                                = local.SAP_virtualnetwork_exists ? 0 : 1
  depends_on                           = [
                                           azurerm_virtual_network.vnet_sap
                                         ]
  name                                 = format("%s%s%s%s",
                                           var.naming.resource_prefixes.routetable,
                                           local.prefix,
                                           var.naming.separator,
                                           local.resource_suffixes.routetable
                                         )
  resource_group_name                  = local.SAP_virtualnetwork_exists ? (
                                           data.azurerm_virtual_network.vnet_sap[0].resource_group_name) : (
                                           azurerm_virtual_network.vnet_sap[0].resource_group_name
                                         )
  location                             = local.SAP_virtualnetwork_exists ? (
                                            data.azurerm_virtual_network.vnet_sap[0].location) : (
                                            azurerm_virtual_network.vnet_sap[0].location
                                          )
  disable_bgp_route_propagation        = false
  tags                                 = var.tags
}

resource "azurerm_route" "admin" {
  provider                             = azurerm.main
  count                                = length(local.firewall_ip) > 0 ? local.SAP_virtualnetwork_exists ? 0 : 1 : 0
  depends_on                           = [
                                           azurerm_route_table.rt
                                         ]
  name                                 = format("%s%s%s%s",
                                           var.naming.resource_prefixes.fw_route,
                                           local.prefix,
                                           var.naming.separator,
                                           local.resource_suffixes.fw_route
                                         )
  resource_group_name                  = local.SAP_virtualnetwork_exists ? (
                                           data.azurerm_virtual_network.vnet_sap[0].resource_group_name) : (
                                           azurerm_virtual_network.vnet_sap[0].resource_group_name
                                         )
  route_table_name                     = azurerm_route_table.rt[0].name
  address_prefix                       = "0.0.0.0/0"
  next_hop_type                        = "VirtualAppliance"
  next_hop_in_ip_address               = local.firewall_ip

}

resource "azurerm_private_dns_zone_virtual_network_link" "vnet_sap" {
  provider                             = azurerm.dnsmanagement
  count                                = local.use_Azure_native_DNS && var.use_private_endpoint && var.register_virtual_network_to_dns ? 1 : 0
  depends_on                           = [
                                           azurerm_virtual_network.vnet_sap
                                         ]
  name                                 = format("%s%s%s%s",
                                           var.naming.resource_prefixes.dns_link,
                                           local.prefix,
                                           var.naming.separator,
                                           var.naming.resource_suffixes.dns_link
                                         )

  resource_group_name                  = var.management_dns_resourcegroup_name

  private_dns_zone_name                = var.dns_label
  virtual_network_id                   = azurerm_virtual_network.vnet_sap[0].id
  registration_enabled                 = true
}

resource "azurerm_private_dns_zone_virtual_network_link" "vnet_sap_file" {
  provider                             = azurerm.dnsmanagement
  count                                = local.use_Azure_native_DNS && var.use_private_endpoint ? 1 : 0
  depends_on                           = [
                                           azurerm_virtual_network.vnet_sap
                                         ]
  name                                 = format("%s%s%s%s-file",
                                           var.naming.resource_prefixes.dns_link,
                                           local.prefix,
                                           var.naming.separator,
                                           var.naming.resource_suffixes.dns_link
                                         )

  resource_group_name                  = var.management_dns_resourcegroup_name

  private_dns_zone_name                = var.dns_zone_names.file_dns_zone_name
  virtual_network_id                   = azurerm_virtual_network.vnet_sap[0].id
  registration_enabled                 = false
}

data "azurerm_private_dns_zone" "file" {
  provider                             = azurerm.dnsmanagement
  count                                = var.use_private_endpoint ? 1 : 0
  name                                 = var.dns_zone_names.file_dns_zone_name
  resource_group_name                  = var.management_dns_resourcegroup_name
}

resource "azurerm_private_dns_zone_virtual_network_link" "storage" {
  provider                             = azurerm.dnsmanagement
  count                                = local.use_Azure_native_DNS  && var.use_private_endpoint ? 1 : 0
  depends_on                           = [
                                           azurerm_virtual_network.vnet_sap
                                         ]
  name                                 = format("%s%s%s%s-blob",
                                           var.naming.resource_prefixes.dns_link,
                                           local.prefix,
                                           var.naming.separator,
                                           var.naming.resource_suffixes.dns_link
                                         )

  resource_group_name                  = var.management_dns_resourcegroup_name
  private_dns_zone_name                = var.dns_zone_names.blob_dns_zone_name
  virtual_network_id                   = azurerm_virtual_network.vnet_sap[0].id
}

data "azurerm_private_dns_zone" "storage" {
  provider                             = azurerm.dnsmanagement
  count                                = var.use_private_endpoint ? 1 : 0
  name                                 = var.dns_zone_names.blob_dns_zone_name
  resource_group_name                  = var.management_dns_resourcegroup_name
}

resource "azurerm_management_lock" "vnet_sap" {
  provider                             = azurerm.main
  count                                = (local.SAP_virtualnetwork_exists) ? 0 : var.place_delete_lock_on_resources ? 1 : 0
  name                                 = format("%s-lock", local.SAP_virtualnetwork_name)
  scope                                = azurerm_virtual_network.vnet_sap[0].id
  lock_level                           = "CanNotDelete"
  notes                                = "Locked because it's needed by the Workload"
  lifecycle {
              prevent_destroy = false
            }
}

