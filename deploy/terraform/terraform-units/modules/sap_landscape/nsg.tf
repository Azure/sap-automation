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


// Add SSH network security rule
resource "azurerm_network_security_rule" "nsr_ssh_app" {
  depends_on = [
    azurerm_network_security_group.app
  ]
  count = local.application_subnet_nsg_exists ? 0 : 1
  name  = "ssh"
  resource_group_name = local.vnet_sap_exists ? data.azurerm_virtual_network.vnet_sap[0].resource_group_name : azurerm_virtual_network.vnet_sap[0].resource_group_name
  network_security_group_name = azurerm_network_security_group.app[0].name
  priority                     = 101
  direction                    = "Inbound"
  access                       = "Allow"
  protocol                     = "Tcp"
  source_port_range            = "*"
  destination_port_range       = 22
  source_address_prefixes      = var.deployer_tfstate.subnet_mgmt_address_prefixes
  destination_address_prefixes = azurerm_subnet.app[0].address_prefixes
}

// Add RDP network security rule
resource "azurerm_network_security_rule" "nsr_rdp_app" {
  depends_on = [
    azurerm_network_security_group.app
  ]
  count = local.application_subnet_nsg_exists ? 0 : 1
  name  = "rdp"
  resource_group_name = local.vnet_sap_exists ? data.azurerm_virtual_network.vnet_sap[0].resource_group_name : azurerm_virtual_network.vnet_sap[0].resource_group_name
  network_security_group_name = azurerm_network_security_group.app[0].name
  priority                     = 102
  direction                    = "Inbound"
  access                       = "Allow"
  protocol                     = "Tcp"
  source_port_range            = "*"
  destination_port_range       = 3389
  source_address_prefixes      = var.deployer_tfstate.subnet_mgmt_address_prefixes
  destination_address_prefixes = azurerm_subnet.app[0].address_prefixes
}

// Add WinRM network security rule
resource "azurerm_network_security_rule" "nsr_winrm_app" {
  depends_on = [
    azurerm_network_security_group.app
  ]
  count = local.application_subnet_nsg_exists ? 0 : 1
  name  = "winrm"
  resource_group_name = local.vnet_sap_exists ? data.azurerm_virtual_network.vnet_sap[0].resource_group_name : azurerm_virtual_network.vnet_sap[0].resource_group_name
  network_security_group_name = azurerm_network_security_group.app[0].name
  priority                     = 103
  direction                    = "Inbound"
  access                       = "Allow"
  protocol                     = "Tcp"
  source_port_range            = "*"
  destination_port_ranges      = [5985, 5986]
  source_address_prefixes      = var.deployer_tfstate.subnet_mgmt_address_prefixes
  destination_address_prefixes = azurerm_subnet.app[0].address_prefixes
}

// Add SSH network security rule
resource "azurerm_network_security_rule" "nsr_ssh_web" {
  depends_on = [
    azurerm_network_security_group.web
  ]
  count = local.web_subnet_nsg_exists ? 0 : 1
  name  = "ssh"
  resource_group_name = local.vnet_sap_exists ? data.azurerm_virtual_network.vnet_sap[0].resource_group_name : azurerm_virtual_network.vnet_sap[0].resource_group_name
  network_security_group_name = azurerm_network_security_group.web[0].name
  priority                     = 101
  direction                    = "Inbound"
  access                       = "Allow"
  protocol                     = "Tcp"
  source_port_range            = "*"
  destination_port_range       = 22
  source_address_prefixes      = var.deployer_tfstate.subnet_mgmt_address_prefixes
  destination_address_prefixes = azurerm_subnet.web[0].address_prefixes
}

// Add RDP network security rule
resource "azurerm_network_security_rule" "nsr_rdp_web" {
  depends_on = [
    azurerm_network_security_group.web
  ]
  count = local.web_subnet_nsg_exists ? 0 : 1
  name  = "rdp"
  resource_group_name = local.vnet_sap_exists ? data.azurerm_virtual_network.vnet_sap[0].resource_group_name : azurerm_virtual_network.vnet_sap[0].resource_group_name
  network_security_group_name = azurerm_network_security_group.web[0].name
  priority                     = 102
  direction                    = "Inbound"
  access                       = "Allow"
  protocol                     = "Tcp"
  source_port_range            = "*"
  destination_port_range       = 3389
  source_address_prefixes      = var.deployer_tfstate.subnet_mgmt_address_prefixes
  destination_address_prefixes = azurerm_subnet.web[0].address_prefixes
}

// Add WinRM network security rule
resource "azurerm_network_security_rule" "nsr_winrm_web" {
  depends_on = [
    azurerm_network_security_group.web
  ]
  count = local.web_subnet_nsg_exists ? 0 : 1
  name  = "winrm"
  resource_group_name = local.vnet_sap_exists ? data.azurerm_virtual_network.vnet_sap[0].resource_group_name : azurerm_virtual_network.vnet_sap[0].resource_group_name
  network_security_group_name = azurerm_network_security_group.web[0].name
  priority                     = 103
  direction                    = "Inbound"
  access                       = "Allow"
  protocol                     = "Tcp"
  source_port_range            = "*"
  destination_port_ranges      = [5985, 5986]
  source_address_prefixes      = var.deployer_tfstate.subnet_mgmt_address_prefixes
  destination_address_prefixes = azurerm_subnet.web[0].address_prefixes
}

// Add SSH network security rule
resource "azurerm_network_security_rule" "nsr_ssh_db" {
  depends_on = [
    azurerm_network_security_group.db
  ]
  count = local.database_subnet_nsg_exists ? 0 : 1
  name  = "ssh"
  resource_group_name = local.vnet_sap_exists ? data.azurerm_virtual_network.vnet_sap[0].resource_group_name : azurerm_virtual_network.vnet_sap[0].resource_group_name
  network_security_group_name = azurerm_network_security_group.db[0].name
  priority                     = 101
  direction                    = "Inbound"
  access                       = "Allow"
  protocol                     = "Tcp"
  source_port_range            = "*"
  destination_port_range       = 22
  source_address_prefixes      = var.deployer_tfstate.subnet_mgmt_address_prefixes
  destination_address_prefixes = azurerm_subnet.db[0].address_prefixes
}

// Add RDP network security rule
resource "azurerm_network_security_rule" "nsr_rdp_db" {
  depends_on = [
    azurerm_network_security_group.db
  ]
  count = local.database_subnet_nsg_exists ? 0 : 1
  name  = "rdp"
  resource_group_name = local.vnet_sap_exists ? data.azurerm_virtual_network.vnet_sap[0].resource_group_name : azurerm_virtual_network.vnet_sap[0].resource_group_name
  network_security_group_name = azurerm_network_security_group.db[0].name
  priority                     = 102
  direction                    = "Inbound"
  access                       = "Allow"
  protocol                     = "Tcp"
  source_port_range            = "*"
  destination_port_range       = 3389
  source_address_prefixes      = var.deployer_tfstate.subnet_mgmt_address_prefixes
  destination_address_prefixes = azurerm_subnet.db[0].address_prefixes
}

// Add WinRM network security rule
resource "azurerm_network_security_rule" "nsr_winrm_db" {
  depends_on = [
    azurerm_network_security_group.db
  ]
  count = local.database_subnet_nsg_exists ? 0 : 1
  name  = "winrm"
  resource_group_name = local.vnet_sap_exists ? data.azurerm_virtual_network.vnet_sap[0].resource_group_name : azurerm_virtual_network.vnet_sap[0].resource_group_name
  network_security_group_name = azurerm_network_security_group.app[0].name
  priority                     = 103
  direction                    = "Inbound"
  access                       = "Allow"
  protocol                     = "Tcp"
  source_port_range            = "*"
  destination_port_ranges      = [5985, 5986]
  source_address_prefixes      = var.deployer_tfstate.subnet_mgmt_address_prefixes
  destination_address_prefixes = azurerm_subnet.db[0].address_prefixes
}
