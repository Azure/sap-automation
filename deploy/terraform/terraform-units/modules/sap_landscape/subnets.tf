// Creates admin subnet of SAP VNET
resource "azurerm_subnet" "admin" {
  provider             = azurerm.main
  count                = local.admin_subnet_defined && !local.admin_subnet_existing ? 1 : 0
  name                 = local.admin_subnet_name
  resource_group_name  = local.vnet_sap_exists ? data.azurerm_virtual_network.vnet_sap[0].resource_group_name : azurerm_virtual_network.vnet_sap[0].resource_group_name
  virtual_network_name = local.vnet_sap_exists ? data.azurerm_virtual_network.vnet_sap[0].name : azurerm_virtual_network.vnet_sap[0].name
  address_prefixes     = [local.admin_subnet_prefix]

  private_endpoint_network_policies_enabled     = var.use_private_endpoint
  private_link_service_network_policies_enabled = false

  service_endpoints = var.use_service_endpoint ? (
    ["Microsoft.Storage", "Microsoft.KeyVault"]
    ) : (
    null
  )
}

// Creates db subnet of SAP VNET
resource "azurerm_subnet" "db" {
  provider             = azurerm.main
  count                = local.database_subnet_defined && !local.database_subnet_existing ? 1 : 0
  name                 = local.database_subnet_name
  resource_group_name  = local.vnet_sap_exists ? data.azurerm_virtual_network.vnet_sap[0].resource_group_name : azurerm_virtual_network.vnet_sap[0].resource_group_name
  virtual_network_name = local.vnet_sap_exists ? data.azurerm_virtual_network.vnet_sap[0].name : azurerm_virtual_network.vnet_sap[0].name
  address_prefixes     = [local.database_subnet_prefix]

  private_endpoint_network_policies_enabled     = var.use_private_endpoint
  private_link_service_network_policies_enabled = false
  service_endpoints = var.use_service_endpoint ? (
    ["Microsoft.Storage", "Microsoft.KeyVault"]
    ) : (
    null
  )

}

// Creates app subnet of SAP VNET
resource "azurerm_subnet" "app" {
  provider             = azurerm.main
  count                = local.application_subnet_defined && !local.application_subnet_existing ? 1 : 0
  name                 = local.application_subnet_name
  resource_group_name  = local.vnet_sap_exists ? data.azurerm_virtual_network.vnet_sap[0].resource_group_name : azurerm_virtual_network.vnet_sap[0].resource_group_name
  virtual_network_name = local.vnet_sap_exists ? data.azurerm_virtual_network.vnet_sap[0].name : azurerm_virtual_network.vnet_sap[0].name
  address_prefixes     = [local.application_subnet_prefix]

  private_endpoint_network_policies_enabled     = var.use_private_endpoint
  private_link_service_network_policies_enabled = false

  service_endpoints = var.use_service_endpoint ? (
    ["Microsoft.Storage", "Microsoft.KeyVault"]
    ) : (
    null
  )
}

// Creates web subnet of SAP VNET
resource "azurerm_subnet" "web" {
  provider             = azurerm.main
  count                = local.web_subnet_defined && !local.web_subnet_existing ? 1 : 0
  name                 = local.web_subnet_name
  resource_group_name  = local.vnet_sap_exists ? data.azurerm_virtual_network.vnet_sap[0].resource_group_name : azurerm_virtual_network.vnet_sap[0].resource_group_name
  virtual_network_name = local.vnet_sap_exists ? data.azurerm_virtual_network.vnet_sap[0].name : azurerm_virtual_network.vnet_sap[0].name
  address_prefixes     = [local.web_subnet_prefix]

  private_endpoint_network_policies_enabled     = var.use_private_endpoint
  private_link_service_network_policies_enabled = false

  service_endpoints = var.use_service_endpoint ? (
    ["Microsoft.Storage", "Microsoft.KeyVault"]
    ) : (
    null
  )
}

// Creates anf subnet of SAP VNET
resource "azurerm_subnet" "anf" {
  provider = azurerm.main
  count = var.NFS_provider == "ANF" ? (
    local.ANF_subnet_existing ? (
      0) : (
      1
    )) : (
    0
  )
  name                 = local.ANF_subnet_name
  resource_group_name  = local.vnet_sap_exists ? data.azurerm_virtual_network.vnet_sap[0].resource_group_name : azurerm_virtual_network.vnet_sap[0].resource_group_name
  virtual_network_name = local.vnet_sap_exists ? data.azurerm_virtual_network.vnet_sap[0].name : azurerm_virtual_network.vnet_sap[0].name
  address_prefixes     = [local.ANF_subnet_prefix]

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


# Creates admin subnet nsg
resource "azurerm_network_security_group" "admin" {
  provider            = azurerm.main
  count               = local.admin_subnet_defined && !local.admin_subnet_nsg_exists ? 1 : 0
  name                = local.admin_subnet_nsg_name
  resource_group_name = local.vnet_sap_exists ? data.azurerm_virtual_network.vnet_sap[0].resource_group_name : azurerm_virtual_network.vnet_sap[0].resource_group_name
  location            = local.vnet_sap_exists ? data.azurerm_virtual_network.vnet_sap[0].location : azurerm_virtual_network.vnet_sap[0].location
}

# Associates admin nsg to admin subnet
resource "azurerm_subnet_network_security_group_association" "admin" {
  provider = azurerm.main
  count    = local.admin_subnet_defined && !local.admin_subnet_nsg_exists ? 1 : 0

  subnet_id                 = local.admin_subnet_existing ? local.admin_subnet_arm_id : azurerm_subnet.admin[0].id
  network_security_group_id = azurerm_network_security_group.admin[0].id
}


# Creates SAP db subnet nsg
resource "azurerm_network_security_group" "db" {
  provider            = azurerm.main
  count               = local.database_subnet_defined && !local.database_subnet_nsg_exists ? 1 : 0
  name                = local.database_subnet_nsg_name
  resource_group_name = local.vnet_sap_exists ? data.azurerm_virtual_network.vnet_sap[0].resource_group_name : azurerm_virtual_network.vnet_sap[0].resource_group_name
  location            = local.vnet_sap_exists ? data.azurerm_virtual_network.vnet_sap[0].location : azurerm_virtual_network.vnet_sap[0].location
}

# Associates SAP db nsg to SAP db subnet
resource "azurerm_subnet_network_security_group_association" "db" {
  provider                  = azurerm.main
  count                     = local.database_subnet_defined && !local.database_subnet_nsg_exists ? 1 : 0
  subnet_id                 = local.database_subnet_existing ? local.database_subnet_arm_id : azurerm_subnet.db[0].id
  network_security_group_id = azurerm_network_security_group.db[0].id
}


# Creates SAP app subnet nsg
resource "azurerm_network_security_group" "app" {
  provider            = azurerm.main
  count               = local.application_subnet_defined && !local.application_subnet_nsg_exists ? 1 : 0
  name                = local.application_subnet_nsg_name
  resource_group_name = local.vnet_sap_exists ? data.azurerm_virtual_network.vnet_sap[0].resource_group_name : azurerm_virtual_network.vnet_sap[0].resource_group_name
  location            = local.vnet_sap_exists ? data.azurerm_virtual_network.vnet_sap[0].location : azurerm_virtual_network.vnet_sap[0].location
}

# Associates app nsg to app subnet
resource "azurerm_subnet_network_security_group_association" "app" {
  provider                  = azurerm.main
  count                     = local.application_subnet_defined && !local.application_subnet_nsg_exists ? 1 : 0
  subnet_id                 = local.application_subnet_existing ? local.application_subnet_arm_id : azurerm_subnet.app[0].id
  network_security_group_id = azurerm_network_security_group.app[0].id
}


# Creates SAP web subnet nsg
resource "azurerm_network_security_group" "web" {
  provider            = azurerm.main
  count               = local.web_subnet_defined && !local.web_subnet_nsg_exists ? 1 : 0
  name                = local.web_subnet_nsg_name
  resource_group_name = local.vnet_sap_exists ? data.azurerm_virtual_network.vnet_sap[0].resource_group_name : azurerm_virtual_network.vnet_sap[0].resource_group_name
  location            = local.vnet_sap_exists ? data.azurerm_virtual_network.vnet_sap[0].location : azurerm_virtual_network.vnet_sap[0].location
}

# Associates SAP web nsg to SAP web subnet
resource "azurerm_subnet_network_security_group_association" "web" {
  provider                  = azurerm.main
  count                     = local.web_subnet_defined && !local.web_subnet_nsg_exists ? 1 : 0
  subnet_id                 = local.web_subnet_existing ? local.web_subnet_arm_id : azurerm_subnet.web[0].id
  network_security_group_id = azurerm_network_security_group.web[0].id
}

#Associate the subnets to the route table

resource "azurerm_subnet_route_table_association" "admin" {
  depends_on = [
    azurerm_route_table.rt
  ]

  provider       = azurerm.main
  count          = local.admin_subnet_defined && !local.vnet_sap_exists && !local.admin_subnet_existing ? 1 : 0
  subnet_id      = local.admin_subnet_existing ? local.admin_subnet_arm_id : azurerm_subnet.admin[0].id
  route_table_id = azurerm_route_table.rt[0].id
}

resource "azurerm_subnet_route_table_association" "db" {
  depends_on = [
    azurerm_route_table.rt
  ]
  provider       = azurerm.main
  count          = local.database_subnet_defined && !local.vnet_sap_exists && !local.database_subnet_existing ? 1 : 0 
  subnet_id      = local.database_subnet_existing ? local.database_subnet_arm_id : azurerm_subnet.db[0].id
  route_table_id = azurerm_route_table.rt[0].id
}

resource "azurerm_subnet_route_table_association" "app" {
  depends_on = [
    azurerm_route_table.rt
  ]
  provider       = azurerm.main
  count          = local.application_subnet_defined && !local.vnet_sap_exists && !local.application_subnet_existing ? 1 : 0
  subnet_id      = local.application_subnet_existing ? local.application_subnet_arm_id : azurerm_subnet.app[0].id
  route_table_id = azurerm_route_table.rt[0].id
}

resource "azurerm_subnet_route_table_association" "web" {
  depends_on = [
    azurerm_route_table.rt
  ]
  provider       = azurerm.main
  count          = local.web_subnet_defined && !local.vnet_sap_exists && !local.web_subnet_existing ? 1 : 0
  subnet_id      = local.web_subnet_existing ? local.web_subnet_arm_id : azurerm_subnet.web[0].id
  route_table_id = azurerm_route_table.rt[0].id
}

# Creates network security rule to allow internal traffic for SAP db subnet
resource "azurerm_network_security_rule" "nsr_internal_db" {
  provider                     = azurerm.main
  count                        = local.database_subnet_nsg_exists ? 0 : 0
  name                         = "allow-internal-traffic"
  resource_group_name          = local.vnet_sap_exists ? data.azurerm_virtual_network.vnet_sap[0].resource_group_name : azurerm_virtual_network.vnet_sap[0].resource_group_name
  network_security_group_name  = azurerm_network_security_group.db[0].name
  priority                     = 101
  direction                    = "Inbound"
  access                       = "Allow"
  protocol                     = "Tcp"
  source_port_range            = "*"
  destination_port_range       = "*"
  source_address_prefixes      = !local.vnet_sap_exists ? azurerm_virtual_network.vnet_sap[0].address_space : data.azurerm_virtual_network.vnet_sap[0].address_space
  destination_address_prefixes = azurerm_subnet.db[0].address_prefixes
}

# Creates network security rule to deny external traffic for SAP db subnet
resource "azurerm_network_security_rule" "nsr_external_db" {
  provider = azurerm.main

  count               = local.database_subnet_nsg_exists ? 0 : 0
  name                = "deny-inbound-traffic"
  resource_group_name = local.vnet_sap_exists ? data.azurerm_virtual_network.vnet_sap[0].resource_group_name : azurerm_virtual_network.vnet_sap[0].resource_group_name


  network_security_group_name  = azurerm_network_security_group.db[0].name
  priority                     = 102
  direction                    = "Inbound"
  access                       = "Deny"
  protocol                     = "Tcp"
  source_port_range            = "*"
  destination_port_range       = "*"
  source_address_prefix        = "*"
  destination_address_prefixes = azurerm_subnet.db[0].address_prefixes
}
