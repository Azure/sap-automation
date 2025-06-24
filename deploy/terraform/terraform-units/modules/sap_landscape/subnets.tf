# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

// Creates admin subnet of SAP VNET
resource "azurerm_subnet" "admin" {
  provider                             = azurerm.main
  count                                = var.infrastructure.virtual_networks.sap.subnet_admin.defined ? 1 : 0
  name                                 = local.admin_subnet_name
  resource_group_name                  = var.infrastructure.virtual_networks.sap.exists ? data.azurerm_virtual_network.vnet_sap[0].resource_group_name : azurerm_virtual_network.vnet_sap[0].resource_group_name
  virtual_network_name                 = var.infrastructure.virtual_networks.sap.exists ? data.azurerm_virtual_network.vnet_sap[0].name : azurerm_virtual_network.vnet_sap[0].name
  address_prefixes                     = [var.infrastructure.virtual_networks.sap.subnet_admin.prefix]

  private_endpoint_network_policies    = var.use_private_endpoint ? "Enabled" : "Disabled"

  service_endpoints                    = var.use_service_endpoint ? (
                                          ["Microsoft.Storage", "Microsoft.KeyVault"]
                                          ) : (
                                          null
                                         )
}

data "azurerm_subnet" "admin" {
  provider                             = azurerm.main
  count                                = var.infrastructure.virtual_networks.sap.subnet_admin.exists ? 1 : 0
  name                                 = split("/", var.infrastructure.virtual_networks.sap.subnet_admin.id)[10]
  resource_group_name                  = split("/", var.infrastructure.virtual_networks.sap.subnet_admin.id)[4]
  virtual_network_name                 = split("/", var.infrastructure.virtual_networks.sap.subnet_admin.id)[8]
}


// Creates db subnet of SAP VNET
resource "azurerm_subnet" "db" {
  provider                             = azurerm.main
  count                                = var.infrastructure.virtual_networks.sap.subnet_db.defined ? 1 : 0
  name                                 = local.database_subnet_name
  resource_group_name                  = var.infrastructure.virtual_networks.sap.exists ? data.azurerm_virtual_network.vnet_sap[0].resource_group_name : azurerm_virtual_network.vnet_sap[0].resource_group_name
  virtual_network_name                 = var.infrastructure.virtual_networks.sap.exists ? data.azurerm_virtual_network.vnet_sap[0].name : azurerm_virtual_network.vnet_sap[0].name
  address_prefixes                     = [var.infrastructure.virtual_networks.sap.subnet_db.prefix]

  private_endpoint_network_policies    = var.use_private_endpoint ? "Enabled" : "Disabled"
  service_endpoints                    = var.use_service_endpoint ? (
                                           ["Microsoft.Storage", "Microsoft.KeyVault"]
                                           ) : (
                                           null
                                         )
}

data "azurerm_subnet" "db" {
  provider                             = azurerm.main
  count                                = var.infrastructure.virtual_networks.sap.subnet_db.exists ? 1 : 0
  name                                 = split("/", var.infrastructure.virtual_networks.sap.subnet_db.id)[10]
  resource_group_name                  = split("/", var.infrastructure.virtual_networks.sap.subnet_db.id)[4]
  virtual_network_name                 = split("/", var.infrastructure.virtual_networks.sap.subnet_db.id)[8]
}

// Creates app subnet of SAP VNET
resource "azurerm_subnet" "app" {
  provider                             = azurerm.main
  count                                = var.infrastructure.virtual_networks.sap.subnet_app.defined  ? 1 : 0
  name                                 = local.application_subnet_name
  resource_group_name                  = var.infrastructure.virtual_networks.sap.exists ? data.azurerm_virtual_network.vnet_sap[0].resource_group_name : azurerm_virtual_network.vnet_sap[0].resource_group_name
  virtual_network_name                 = var.infrastructure.virtual_networks.sap.exists ? data.azurerm_virtual_network.vnet_sap[0].name : azurerm_virtual_network.vnet_sap[0].name
  address_prefixes                     = [var.infrastructure.virtual_networks.sap.subnet_app.prefix]

  private_endpoint_network_policies    = var.use_private_endpoint ? "Enabled" : "Disabled"

  service_endpoints                    = var.use_service_endpoint ? (
                                           ["Microsoft.Storage", "Microsoft.KeyVault"]
                                           ) : (
                                           null
                                         )
}

data "azurerm_subnet" "app" {
  provider                             = azurerm.main
  count                                = var.infrastructure.virtual_networks.sap.subnet_app.exists ? 1 : 0
  name                                 = split("/", var.infrastructure.virtual_networks.sap.subnet_app.id)[10]
  resource_group_name                  = split("/", var.infrastructure.virtual_networks.sap.subnet_app.id)[4]
  virtual_network_name                 = split("/", var.infrastructure.virtual_networks.sap.subnet_app.id)[8]
}


// Creates web subnet of SAP VNET
resource "azurerm_subnet" "web" {
  provider                             = azurerm.main
  count                                = var.infrastructure.virtual_networks.sap.subnet_web.defined  ? 1 : 0
  name                                 = local.web_subnet_name
  resource_group_name                  = var.infrastructure.virtual_networks.sap.exists ? data.azurerm_virtual_network.vnet_sap[0].resource_group_name : azurerm_virtual_network.vnet_sap[0].resource_group_name
  virtual_network_name                 = var.infrastructure.virtual_networks.sap.exists ? data.azurerm_virtual_network.vnet_sap[0].name : azurerm_virtual_network.vnet_sap[0].name
  address_prefixes                     = [var.infrastructure.virtual_networks.sap.subnet_web.prefix]

  private_endpoint_network_policies    = var.use_private_endpoint ? "Enabled" : "Disabled"

  service_endpoints                    = var.use_service_endpoint ? (
                                           ["Microsoft.Storage", "Microsoft.KeyVault"]
                                           ) : (
                                           null
                                         )
}

data "azurerm_subnet" "web" {
  provider                             = azurerm.main
  count                                = var.infrastructure.virtual_networks.sap.subnet_web.exists ? 1 : 0
  name                                 = split("/", var.infrastructure.virtual_networks.sap.subnet_web.id)[10]
  resource_group_name                  = split("/", var.infrastructure.virtual_networks.sap.subnet_web.id)[4]
  virtual_network_name                 = split("/", var.infrastructure.virtual_networks.sap.subnet_web.id)[8]
}



// Creates storage subnet of SAP VNET
resource "azurerm_subnet" "storage" {
  provider                             = azurerm.main
  count                                = var.infrastructure.virtual_networks.sap.subnet_storage.defined ? 1 : 0
  name                                 = local.storage_subnet_name
  resource_group_name                  = var.infrastructure.virtual_networks.sap.exists ? data.azurerm_virtual_network.vnet_sap[0].resource_group_name : azurerm_virtual_network.vnet_sap[0].resource_group_name
  virtual_network_name                 = var.infrastructure.virtual_networks.sap.exists ? data.azurerm_virtual_network.vnet_sap[0].name : azurerm_virtual_network.vnet_sap[0].name
  address_prefixes                     = [var.infrastructure.virtual_networks.sap.subnet_storage.prefix]

  private_endpoint_network_policies    = var.use_private_endpoint ? "Enabled" : "Disabled"

  service_endpoints                    = var.use_service_endpoint ? (
                                           ["Microsoft.Storage", "Microsoft.KeyVault"]
                                           ) : (
                                           null
                                         )
}

data "azurerm_subnet" "storage" {
  provider                             = azurerm.main
  count                                = var.infrastructure.virtual_networks.sap.subnet_storage.exists ? 1 : 0
  name                                 = split("/", var.infrastructure.virtual_networks.sap.subnet_web.prefix.id)[10]
  resource_group_name                  = split("/", var.infrastructure.virtual_networks.sap.subnet_web.prefix.id)[4]
  virtual_network_name                 = split("/", var.infrastructure.virtual_networks.sap.subnet_web.prefix.id)[8]
}



// Creates anf subnet of SAP VNET
resource "azurerm_subnet" "anf" {
  provider                             = azurerm.main
  count                                = var.NFS_provider == "ANF" && var.infrastructure.virtual_networks.sap.subnet_anf.defined  ? 1 : 0
  name                                 = local.ANF_subnet_name
  resource_group_name                  = var.infrastructure.virtual_networks.sap.exists ? data.azurerm_virtual_network.vnet_sap[0].resource_group_name : azurerm_virtual_network.vnet_sap[0].resource_group_name
  virtual_network_name                 = var.infrastructure.virtual_networks.sap.exists ? data.azurerm_virtual_network.vnet_sap[0].name : azurerm_virtual_network.vnet_sap[0].name
  address_prefixes                     = [var.infrastructure.virtual_networks.sap.subnet_anf.prefix]

  delegation {
               name = "delegation"
               service_delegation {
                                    actions = [
                                      "Microsoft.Network/networkinterfaces/*",
                                      "Microsoft.Network/virtualNetworks/subnets/join/action",
                                    ]
                                    name = "Microsoft.Netapp/volumes"
                                  }
             }
}

// Creates AMS subnet of SAP VNET
resource "azurerm_subnet" "ams" {
  provider                             = azurerm.main
  count                                = local.create_ams_instance  && var.infrastructure.virtual_networks.sap.subnet_ams.defined ? 1 : 0
  name                                 = local.ams_subnet_name
  resource_group_name                  = var.infrastructure.virtual_networks.sap.exists ? data.azurerm_virtual_network.vnet_sap[0].resource_group_name : azurerm_virtual_network.vnet_sap[0].resource_group_name
  virtual_network_name                 = var.infrastructure.virtual_networks.sap.exists ? data.azurerm_virtual_network.vnet_sap[0].name : azurerm_virtual_network.vnet_sap[0].name
  address_prefixes                     = [var.infrastructure.virtual_networks.sap.subnet_ams.prefix]

  delegation {
               name = "delegation"
               service_delegation {
                                    name = "Microsoft.Web/serverFarms"
                                  }
             }
}

#Associate the subnets to the route table

resource "azurerm_subnet_route_table_association" "admin" {
  provider                             = azurerm.main
  count                                = var.infrastructure.virtual_networks.sap.subnet_admin.defined && !var.infrastructure.virtual_networks.sap.exists ? (local.create_nat_gateway ? 0 : 1) : 0
  depends_on                           = [
                                          azurerm_route_table.rt,
                                          azurerm_subnet.admin
                                        ]
  subnet_id                            = azurerm_subnet.admin[0].id
  route_table_id                       = azurerm_route_table.rt[0].id
}

resource "azurerm_subnet_route_table_association" "db" {
  provider                             = azurerm.main
  count                                = var.infrastructure.virtual_networks.sap.subnet_db.defined && !var.infrastructure.virtual_networks.sap.exists ? (local.create_nat_gateway ? 0 : 1) : 0
  depends_on                           = [
                                           azurerm_route_table.rt,
                                           azurerm_subnet.db
                                         ]
  subnet_id                            = azurerm_subnet.db[0].id
  route_table_id                       = azurerm_route_table.rt[0].id
}

resource "azurerm_subnet_route_table_association" "app" {
  provider                             = azurerm.main
  count                                = var.infrastructure.virtual_networks.sap.subnet_app.defined && !var.infrastructure.virtual_networks.sap.exists ? (local.create_nat_gateway ? 0 : 1) : 0
  depends_on                           = [
                                           azurerm_route_table.rt,
                                           azurerm_subnet.db
                                         ]
  subnet_id                            = azurerm_subnet.app[0].id
  route_table_id                       = azurerm_route_table.rt[0].id
}

resource "azurerm_subnet_route_table_association" "web" {
  provider                             = azurerm.main
  count                                = var.infrastructure.virtual_networks.sap.subnet_web.defined && !var.infrastructure.virtual_networks.sap.exists ? (local.create_nat_gateway ? 0 : 1) : 0
  depends_on                           = [
                                           azurerm_route_table.rt,
                                           azurerm_subnet.web
                                         ]
  subnet_id                            = var.infrastructure.virtual_networks.sap.subnet_web.exists ? var.infrastructure.virtual_networks.sap.subnet_web.id : azurerm_subnet.web[0].id
  route_table_id                       = azurerm_route_table.rt[0].id
}

# Creates network security rule to allow internal traffic for SAP db subnet
resource "azurerm_network_security_rule" "nsr_internal_db" {
  provider                             = azurerm.main
  count                                = var.infrastructure.virtual_networks.sap.subnet_db.nsg.exists ? 0 : 0
  name                                 = "allow-internal-traffic"
  resource_group_name                  = var.infrastructure.virtual_networks.sap.exists ? data.azurerm_virtual_network.vnet_sap[0].resource_group_name : azurerm_virtual_network.vnet_sap[0].resource_group_name
  network_security_group_name          = azurerm_network_security_group.db[0].name
  priority                             = 101
  direction                            = "Inbound"
  access                               = "Allow"
  protocol                             = "Tcp"
  source_port_range                    = "*"
  destination_port_range               = "*"
  source_address_prefixes              = !var.infrastructure.virtual_networks.sap.exists ? azurerm_virtual_network.vnet_sap[0].address_space : data.azurerm_virtual_network.vnet_sap[0].address_space
  destination_address_prefixes         = azurerm_subnet.db[0].address_prefixes
}

# Creates network security rule to deny external traffic for SAP db subnet
resource "azurerm_network_security_rule" "nsr_external_db" {
  provider                             = azurerm.main
  count                                = var.infrastructure.virtual_networks.sap.subnet_db.nsg.exists ? 0 : 0
  name                                 = "deny-inbound-traffic"
  resource_group_name                  = var.infrastructure.virtual_networks.sap.exists ? data.azurerm_virtual_network.vnet_sap[0].resource_group_name : azurerm_virtual_network.vnet_sap[0].resource_group_name

  network_security_group_name          = azurerm_network_security_group.db[0].name
  priority                             = 102
  direction                            = "Inbound"
  access                               = "Deny"
  protocol                             = "Tcp"
  source_port_range                    = "*"
  destination_port_range               = "*"
  source_address_prefix                = "*"
  destination_address_prefixes         = azurerm_subnet.db[0].address_prefixes
}

