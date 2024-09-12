// Creates admin subnet of SAP VNET
resource "azurerm_subnet" "admin" {
  provider                             = azurerm.main
  count                                = local.admin_subnet_defined && !local.admin_subnet_existing ? 1 : 0
  name                                 = local.admin_subnet_name
  resource_group_name                  = local.SAP_virtualnetwork_exists ? data.azurerm_virtual_network.vnet_sap[0].resource_group_name : azurerm_virtual_network.vnet_sap[0].resource_group_name
  virtual_network_name                 = local.SAP_virtualnetwork_exists ? data.azurerm_virtual_network.vnet_sap[0].name : azurerm_virtual_network.vnet_sap[0].name
  address_prefixes                     = [local.admin_subnet_prefix]

  private_endpoint_network_policies    = var.use_private_endpoint ? "Enabled" : "Disabled"

  service_endpoints                    = var.use_service_endpoint ? (
                                          ["Microsoft.Storage", "Microsoft.KeyVault"]
                                          ) : (
                                          null
                                         )
}

data "azurerm_subnet" "admin" {
  provider                             = azurerm.main
  count                                = local.admin_subnet_existing ? 1 : 0
  name                                 = split("/", local.admin_subnet_arm_id)[10]
  resource_group_name                  = split("/", local.admin_subnet_arm_id)[4]
  virtual_network_name                 = split("/", local.admin_subnet_arm_id)[8]
}


// Creates db subnet of SAP VNET
resource "azurerm_subnet" "db" {
  provider                             = azurerm.main
  count                                = local.database_subnet_defined && !local.database_subnet_existing ? 1 : 0
  name                                 = local.database_subnet_name
  resource_group_name                  = local.SAP_virtualnetwork_exists ? data.azurerm_virtual_network.vnet_sap[0].resource_group_name : azurerm_virtual_network.vnet_sap[0].resource_group_name
  virtual_network_name                 = local.SAP_virtualnetwork_exists ? data.azurerm_virtual_network.vnet_sap[0].name : azurerm_virtual_network.vnet_sap[0].name
  address_prefixes                     = [local.database_subnet_prefix]

  private_endpoint_network_policies    = var.use_private_endpoint ? "Enabled" : "Disabled"
  service_endpoints                    = var.use_service_endpoint ? (
                                           ["Microsoft.Storage", "Microsoft.KeyVault"]
                                           ) : (
                                           null
                                         )
}

data "azurerm_subnet" "db" {
  provider                             = azurerm.main
  count                                = local.database_subnet_existing ? 1 : 0
  name                                 = split("/", local.database_subnet_arm_id)[10]
  resource_group_name                  = split("/", local.database_subnet_arm_id)[4]
  virtual_network_name                 = split("/", local.database_subnet_arm_id)[8]
}

// Creates app subnet of SAP VNET
resource "azurerm_subnet" "app" {
  provider                             = azurerm.main
  count                                = local.application_subnet_defined && !local.application_subnet_existing ? 1 : 0
  name                                 = local.application_subnet_name
  resource_group_name                  = local.SAP_virtualnetwork_exists ? data.azurerm_virtual_network.vnet_sap[0].resource_group_name : azurerm_virtual_network.vnet_sap[0].resource_group_name
  virtual_network_name                 = local.SAP_virtualnetwork_exists ? data.azurerm_virtual_network.vnet_sap[0].name : azurerm_virtual_network.vnet_sap[0].name
  address_prefixes                     = [local.application_subnet_prefix]

  private_endpoint_network_policies    = var.use_private_endpoint ? "Enabled" : "Disabled"

  service_endpoints                    = var.use_service_endpoint ? (
                                           ["Microsoft.Storage", "Microsoft.KeyVault"]
                                           ) : (
                                           null
                                         )
}

data "azurerm_subnet" "app" {
  provider                             = azurerm.main
  count                                = local.application_subnet_existing ? 1 : 0
  name                                 = split("/", local.application_subnet_arm_id)[10]
  resource_group_name                  = split("/", local.application_subnet_arm_id)[4]
  virtual_network_name                 = split("/", local.application_subnet_arm_id)[8]
}


// Creates web subnet of SAP VNET
resource "azurerm_subnet" "web" {
  provider                             = azurerm.main
  count                                = local.web_subnet_defined && !local.web_subnet_existing ? 1 : 0
  name                                 = local.web_subnet_name
  resource_group_name                  = local.SAP_virtualnetwork_exists ? data.azurerm_virtual_network.vnet_sap[0].resource_group_name : azurerm_virtual_network.vnet_sap[0].resource_group_name
  virtual_network_name                 = local.SAP_virtualnetwork_exists ? data.azurerm_virtual_network.vnet_sap[0].name : azurerm_virtual_network.vnet_sap[0].name
  address_prefixes                     = [local.web_subnet_prefix]

  private_endpoint_network_policies    = var.use_private_endpoint ? "Enabled" : "Disabled"

  service_endpoints                    = var.use_service_endpoint ? (
                                           ["Microsoft.Storage", "Microsoft.KeyVault"]
                                           ) : (
                                           null
                                         )
}

data "azurerm_subnet" "web" {
  provider                             = azurerm.main
  count                                = local.web_subnet_existing ? 1 : 0
  name                                 = split("/", local.web_subnet_arm_id)[10]
  resource_group_name                  = split("/", local.web_subnet_arm_id)[4]
  virtual_network_name                 = split("/", local.web_subnet_arm_id)[8]
}



// Creates storage subnet of SAP VNET
resource "azurerm_subnet" "storage" {
  provider                             = azurerm.main
  count                                = local.storage_subnet_defined && !local.storage_subnet_existing ? 1 : 0
  name                                 = local.storage_subnet_name
  resource_group_name                  = local.SAP_virtualnetwork_exists ? data.azurerm_virtual_network.vnet_sap[0].resource_group_name : azurerm_virtual_network.vnet_sap[0].resource_group_name
  virtual_network_name                 = local.SAP_virtualnetwork_exists ? data.azurerm_virtual_network.vnet_sap[0].name : azurerm_virtual_network.vnet_sap[0].name
  address_prefixes                     = [local.subnet_cidr_storage]

  private_endpoint_network_policies    = var.use_private_endpoint ? "Enabled" : "Disabled"

  service_endpoints                    = var.use_service_endpoint ? (
                                           ["Microsoft.Storage", "Microsoft.KeyVault"]
                                           ) : (
                                           null
                                         )
}

data "azurerm_subnet" "storage" {
  provider                             = azurerm.main
  count                                = local.storage_subnet_existing ? 1 : 0
  name                                 = split("/", local.storage_subnet_arm_id)[10]
  resource_group_name                  = split("/", local.storage_subnet_arm_id)[4]
  virtual_network_name                 = split("/", local.storage_subnet_arm_id)[8]
}



// Creates anf subnet of SAP VNET
resource "azurerm_subnet" "anf" {
  provider                             = azurerm.main
  count                                = var.NFS_provider == "ANF" ? (
                                           local.ANF_subnet_existing ? (
                                             0) : (
                                             1
                                           )) : (
                                           0
                                         )
  name                                 = local.ANF_subnet_name
  resource_group_name                  = local.SAP_virtualnetwork_exists ? data.azurerm_virtual_network.vnet_sap[0].resource_group_name : azurerm_virtual_network.vnet_sap[0].resource_group_name
  virtual_network_name                 = local.SAP_virtualnetwork_exists ? data.azurerm_virtual_network.vnet_sap[0].name : azurerm_virtual_network.vnet_sap[0].name
  address_prefixes                     = [local.ANF_subnet_prefix]

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
  count                                = local.create_ams_instance && local.ams_subnet_defined && !local.ams_subnet_existing ? 1 : 0
  name                                 = local.ams_subnet_name
  resource_group_name                  = local.SAP_virtualnetwork_exists ? data.azurerm_virtual_network.vnet_sap[0].resource_group_name : azurerm_virtual_network.vnet_sap[0].resource_group_name
  virtual_network_name                 = local.SAP_virtualnetwork_exists ? data.azurerm_virtual_network.vnet_sap[0].name : azurerm_virtual_network.vnet_sap[0].name
  address_prefixes                     = [local.ams_subnet_prefix]

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
  count                                = local.admin_subnet_defined && !local.SAP_virtualnetwork_exists && !local.admin_subnet_existing ? (local.create_nat_gateway ? 0 : 1) : 0
  depends_on                           = [
                                          azurerm_route_table.rt,
                                          azurerm_subnet.admin
                                        ]
  subnet_id                            = local.admin_subnet_existing ? var.infrastructure.vnets.sap.subnet_admin.arm_id : azurerm_subnet.admin[0].id
  route_table_id                       = azurerm_route_table.rt[0].id
}

resource "azurerm_subnet_route_table_association" "db" {
  provider                             = azurerm.main
  count                                = local.database_subnet_defined && !local.SAP_virtualnetwork_exists && !local.database_subnet_existing ? (local.create_nat_gateway ? 0 : 1) : 0
  depends_on                           = [
                                           azurerm_route_table.rt,
                                           azurerm_subnet.db
                                         ]
  subnet_id                            = local.database_subnet_existing ? var.infrastructure.vnets.sap.subnet_db.arm_id : azurerm_subnet.db[0].id
  route_table_id                       = azurerm_route_table.rt[0].id
}

resource "azurerm_subnet_route_table_association" "app" {
  provider                             = azurerm.main
  count                                = local.application_subnet_defined && !local.SAP_virtualnetwork_exists && !local.application_subnet_existing ? (local.create_nat_gateway ? 0 : 1) : 0
  depends_on                           = [
                                           azurerm_route_table.rt,
                                           azurerm_subnet.db
                                         ]
  subnet_id                            = local.application_subnet_existing ? var.infrastructure.vnets.sap.subnet_app.arm_id : azurerm_subnet.app[0].id
  route_table_id                       = azurerm_route_table.rt[0].id
}

resource "azurerm_subnet_route_table_association" "web" {
  provider                             = azurerm.main
  count                                = local.web_subnet_defined && !local.SAP_virtualnetwork_exists && !local.web_subnet_existing ? (local.create_nat_gateway ? 0 : 1) : 0
  depends_on                           = [
                                           azurerm_route_table.rt,
                                           azurerm_subnet.web
                                         ]
  subnet_id                            = local.web_subnet_existing ? var.infrastructure.vnets.sap.subnet_web.arm_id : azurerm_subnet.web[0].id
  route_table_id                       = azurerm_route_table.rt[0].id
}

# Creates network security rule to allow internal traffic for SAP db subnet
resource "azurerm_network_security_rule" "nsr_internal_db" {
  provider                             = azurerm.main
  count                                = local.database_subnet_nsg_exists ? 0 : 0
  name                                 = "allow-internal-traffic"
  resource_group_name                  = local.SAP_virtualnetwork_exists ? data.azurerm_virtual_network.vnet_sap[0].resource_group_name : azurerm_virtual_network.vnet_sap[0].resource_group_name
  network_security_group_name          = azurerm_network_security_group.db[0].name
  priority                             = 101
  direction                            = "Inbound"
  access                               = "Allow"
  protocol                             = "Tcp"
  source_port_range                    = "*"
  destination_port_range               = "*"
  source_address_prefixes              = !local.SAP_virtualnetwork_exists ? azurerm_virtual_network.vnet_sap[0].address_space : data.azurerm_virtual_network.vnet_sap[0].address_space
  destination_address_prefixes         = azurerm_subnet.db[0].address_prefixes
}

# Creates network security rule to deny external traffic for SAP db subnet
resource "azurerm_network_security_rule" "nsr_external_db" {
  provider                             = azurerm.main
  count                                = local.database_subnet_nsg_exists ? 0 : 0
  name                                 = "deny-inbound-traffic"
  resource_group_name                  = local.SAP_virtualnetwork_exists ? data.azurerm_virtual_network.vnet_sap[0].resource_group_name : azurerm_virtual_network.vnet_sap[0].resource_group_name

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


data "azurerm_resource_group" "mgmt" {
  provider                             = azurerm.deployer
  count                                = length(local.deployer_subnet_management_id) > 0 ? 1 : 0
  name                                 = split("/", local.deployer_subnet_management_id)[4]
}


