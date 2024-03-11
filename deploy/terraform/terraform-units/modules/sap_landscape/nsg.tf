#######################################4#######################################8
#                                                                              #
#                             Network security groups                          #
#                                                                              #
#######################################4#######################################8

# Creates admin subnet nsg
resource "azurerm_network_security_group" "admin" {
  provider                             = azurerm.main
  count                                = local.admin_subnet_defined && !local.admin_subnet_nsg_exists ? 1 : 0
  name                                 = local.admin_subnet_nsg_name
  resource_group_name                  = local.SAP_virtualnetwork_exists ? (
                                           data.azurerm_virtual_network.vnet_sap[0].resource_group_name
                                           ) : (
                                           azurerm_virtual_network.vnet_sap[0].resource_group_name
                                         )
  location                             = local.SAP_virtualnetwork_exists ? (
                                           data.azurerm_virtual_network.vnet_sap[0].location) : (
                                           azurerm_virtual_network.vnet_sap[0].location
                                         )
  tags                                 = var.tags
}

# Associates admin nsg to admin subnet
resource "azurerm_subnet_network_security_group_association" "admin" {
  provider                             = azurerm.main
  count                                = local.admin_subnet_defined && !local.admin_subnet_nsg_exists ? 1 : 0
  depends_on                           = [
                                          azurerm_subnet.admin
                                        ]

  subnet_id                            = local.admin_subnet_existing ? (
                                          var.infrastructure.vnets.sap.subnet_admin.arm_id) : (
                                          azurerm_subnet.admin[0].id
                                          )
  network_security_group_id            = azurerm_network_security_group.admin[0].id
}


# Creates SAP db subnet nsg
resource "azurerm_network_security_group" "db" {
  provider                             = azurerm.main
  count                                = local.database_subnet_defined && !local.database_subnet_nsg_exists ? 1 : 0
  name                                 = local.database_subnet_nsg_name
  resource_group_name                  = local.SAP_virtualnetwork_exists ? (
                                           data.azurerm_virtual_network.vnet_sap[0].resource_group_name
                                           ) : (
                                           azurerm_virtual_network.vnet_sap[0].resource_group_name
                                         )
  location                             = local.SAP_virtualnetwork_exists ? (
                                           data.azurerm_virtual_network.vnet_sap[0].location) : (
                                           azurerm_virtual_network.vnet_sap[0].location
                                         )
  tags                                 = var.tags
}

# Associates SAP db nsg to SAP db subnet
resource "azurerm_subnet_network_security_group_association" "db" {
  provider                             = azurerm.main
  count                                = local.database_subnet_defined && !local.database_subnet_nsg_exists ? 1 : 0
  depends_on = [
    azurerm_subnet.db
  ]
  subnet_id                 = local.database_subnet_existing ? var.infrastructure.vnets.sap.subnet_db.arm_id : azurerm_subnet.db[0].id
  network_security_group_id = azurerm_network_security_group.db[0].id
}


# Creates SAP app subnet nsg
resource "azurerm_network_security_group" "app" {
  provider                             = azurerm.main
  count                                = local.application_subnet_defined && !local.application_subnet_nsg_exists ? 1 : 0
  name                                 = local.application_subnet_nsg_name
  resource_group_name                  = local.SAP_virtualnetwork_exists ? (
                                           data.azurerm_virtual_network.vnet_sap[0].resource_group_name
                                           ) : (
                                           azurerm_virtual_network.vnet_sap[0].resource_group_name
                                         )
  location                             = local.SAP_virtualnetwork_exists ? (
                                           data.azurerm_virtual_network.vnet_sap[0].location) : (
                                           azurerm_virtual_network.vnet_sap[0].location
                                         )
}


# Associates app nsg to app subnet
resource "azurerm_subnet_network_security_group_association" "app" {
  provider                             = azurerm.main
  count                                = local.application_subnet_defined && !local.application_subnet_nsg_exists ? 1 : 0
  depends_on                           = [
                                           azurerm_subnet.app
                                         ]
  subnet_id                            = local.application_subnet_existing ? var.infrastructure.vnets.sap.subnet_app.arm_id : azurerm_subnet.app[0].id
  network_security_group_id            = azurerm_network_security_group.app[0].id
}


# Creates SAP web subnet nsg
resource "azurerm_network_security_group" "web" {
  provider                             = azurerm.main
  count                                = local.web_subnet_defined && !local.web_subnet_nsg_exists ? 1 : 0
  depends_on                           = [
                                          azurerm_subnet.web
                                        ]
  name                                 = local.web_subnet_nsg_name
  resource_group_name                  = local.SAP_virtualnetwork_exists ? (
                                           data.azurerm_virtual_network.vnet_sap[0].resource_group_name
                                           ) : (
                                           azurerm_virtual_network.vnet_sap[0].resource_group_name
                                         )
  location                             = local.SAP_virtualnetwork_exists ? (
                                           data.azurerm_virtual_network.vnet_sap[0].location) : (
                                           azurerm_virtual_network.vnet_sap[0].location
                                         )
}

# Associates SAP web nsg to SAP web subnet
resource "azurerm_subnet_network_security_group_association" "web" {
  provider                             = azurerm.main
  count                                = local.web_subnet_defined && !local.web_subnet_nsg_exists ? 1 : 0
  subnet_id                            = local.web_subnet_existing ? var.infrastructure.vnets.sap.subnet_web.arm_id : azurerm_subnet.web[0].id
  network_security_group_id            = azurerm_network_security_group.web[0].id
}


// Add network security rule
resource "azurerm_network_security_rule" "nsr_controlplane_app" {
  provider                             = azurerm.main
  count                                = local.application_subnet_nsg_exists ? 0 : 1
  depends_on                           = [
                                           azurerm_network_security_group.app
                                         ]
  name                                 = "ConnectivityToSAPApplicationSubnetFromControlPlane-ssh-rdp-winrm"
  resource_group_name                  = local.SAP_virtualnetwork_exists ? (
                                           data.azurerm_virtual_network.vnet_sap[0].resource_group_name
                                           ) : (
                                           azurerm_virtual_network.vnet_sap[0].resource_group_name
                                         )
  network_security_group_name          = azurerm_network_security_group.app[0].name
  priority                             = 100
  direction                            = "Inbound"
  access                               = "Allow"
  protocol                             = "Tcp"
  source_port_range                    = "*"
  destination_port_ranges              = [22, 443, 3389, 5985, 5986, 5404, 5405, 7630]
  source_address_prefixes              = compact(concat(var.deployer_tfstate.subnet_mgmt_address_prefixes, var.deployer_tfstate.subnet_bastion_address_prefixes))
  destination_address_prefixes         = azurerm_subnet.app[0].address_prefixes
}

// Add SSH network security rule
resource "azurerm_network_security_rule" "nsr_controlplane_web" {
  provider                             = azurerm.main
  count                                = local.web_subnet_defined ? local.web_subnet_nsg_exists ? 0 : 1 : 0
  depends_on                           = [
                                           azurerm_network_security_group.web
                                         ]
  name                                 = "ConnectivityToSAPApplicationSubnetFromControlPlane-ssh-rdp-winrm"
  resource_group_name                  = local.SAP_virtualnetwork_exists ? (
                                           data.azurerm_virtual_network.vnet_sap[0].resource_group_name
                                           ) : (
                                           azurerm_virtual_network.vnet_sap[0].resource_group_name
                                         )
  network_security_group_name          = try(azurerm_network_security_group.web[0].name, azurerm_network_security_group.app[0].name)
  priority                             = 100
  direction                            = "Inbound"
  access                               = "Allow"
  protocol                             = "Tcp"
  source_port_range                    = "*"
  destination_port_ranges              = [22, 443, 3389, 5985, 5986]
  source_address_prefixes              = compact(concat(var.deployer_tfstate.subnet_mgmt_address_prefixes, var.deployer_tfstate.subnet_bastion_address_prefixes))
  destination_address_prefixes         = azurerm_subnet.web[0].address_prefixes
}

// Add SSH network security rule
resource "azurerm_network_security_rule" "nsr_controlplane_db" {
  provider                             = azurerm.main
  count                                = local.database_subnet_nsg_exists ? 0 : 1
  depends_on                           = [
                                           azurerm_network_security_group.db
                                         ]
  name                                 = "ConnectivityToSAPApplicationSubnetFromControlPlane-ssh-rdp-winrm"
  resource_group_name                  = local.SAP_virtualnetwork_exists ? (
                                           data.azurerm_virtual_network.vnet_sap[0].resource_group_name
                                           ) : (
                                           azurerm_virtual_network.vnet_sap[0].resource_group_name
                                         )
  network_security_group_name          = azurerm_network_security_group.db[0].name
  priority                             = 100
  direction                            = "Inbound"
  access                               = "Allow"
  protocol                             = "Tcp"
  source_port_range                    = "*"
  destination_port_ranges              = [22, 443, 3389, 5985, 5986]
  source_address_prefixes              = compact(concat(
                                           var.deployer_tfstate.subnet_mgmt_address_prefixes,
                                           var.deployer_tfstate.subnet_bastion_address_prefixes)
                                         )
  destination_address_prefixes         = azurerm_subnet.db[0].address_prefixes
}

// Add network security rule
resource "azurerm_network_security_rule" "nsr_controlplane_admin" {
  provider                             = azurerm.main
  count                                = local.admin_subnet_nsg_exists ? 0 : (local.admin_subnet_defined ? 1 : 0)
  depends_on                           = [
                                           azurerm_network_security_group.admin
                                         ]
  name                                 = "ConnectivityToSAPApplicationSubnetFromControlPlane-ssh-rdp-winrm"
  resource_group_name                  = local.SAP_virtualnetwork_exists ? (
                                           data.azurerm_virtual_network.vnet_sap[0].resource_group_name
                                           ) : (
                                           azurerm_virtual_network.vnet_sap[0].resource_group_name
                                         )
  network_security_group_name          = azurerm_network_security_group.admin[0].name
  priority                             = 100
  direction                            = "Inbound"
  access                               = "Allow"
  protocol                             = "Tcp"
  source_port_range                    = "*"
  destination_port_ranges              = [22, 443, 3389, 5985, 5986]
  source_address_prefixes              = compact(concat(
                                           var.deployer_tfstate.subnet_mgmt_address_prefixes,
                                           var.deployer_tfstate.subnet_bastion_address_prefixes)
                                         )
  destination_address_prefixes         = azurerm_subnet.admin[0].address_prefixes
}
