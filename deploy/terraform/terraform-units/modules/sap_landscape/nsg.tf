# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

#######################################4#######################################8
#                                                                              #
#                             Network security groups                          #
#                                                                              #
#######################################4#######################################8

# Creates admin subnet nsg
resource "azurerm_network_security_group" "admin" {
  provider                             = azurerm.main
  count                                = var.infrastructure.virtual_networks.sap.subnet_admin.defined && !var.infrastructure.virtual_networks.sap.subnet_admin.nsg.exists ? 1 : 0
  name                                 = local.admin_subnet_nsg_name
  resource_group_name                  = var.infrastructure.virtual_networks.sap.exists ? (
                                           data.azurerm_virtual_network.vnet_sap[0].resource_group_name
                                           ) : (
                                           azurerm_virtual_network.vnet_sap[0].resource_group_name
                                         )
  location                             = var.infrastructure.virtual_networks.sap.exists ? (
                                           data.azurerm_virtual_network.vnet_sap[0].location) : (
                                           azurerm_virtual_network.vnet_sap[0].location
                                         )
  tags                                 = var.tags
}

# Associates admin nsg to admin subnet
resource "azurerm_subnet_network_security_group_association" "admin" {
  provider                             = azurerm.main
  count                                = var.infrastructure.virtual_networks.sap.subnet_admin.defined && !var.infrastructure.virtual_networks.sap.subnet_admin.nsg.exists ? 1 : 0
  depends_on                           = [
                                          azurerm_subnet.admin
                                        ]

  subnet_id                            = var.infrastructure.virtual_networks.sap.subnet_admin.exists ? (
                                          var.infrastructure.virtual_networks.sap.subnet_admin.id) : (
                                          azurerm_subnet.admin[0].id
                                          )
  network_security_group_id            = azurerm_network_security_group.admin[0].id
}


# Creates SAP db subnet nsg
resource "azurerm_network_security_group" "db" {
  provider                             = azurerm.main
  count                                = var.infrastructure.virtual_networks.sap.subnet_db.defined && !var.infrastructure.virtual_networks.sap.subnet_db.nsg.exists ? 1 : 0
  name                                 = local.database_subnet_nsg_name
  resource_group_name                  = var.infrastructure.virtual_networks.sap.exists ? (
                                           data.azurerm_virtual_network.vnet_sap[0].resource_group_name
                                           ) : (
                                           azurerm_virtual_network.vnet_sap[0].resource_group_name
                                         )
  location                             = var.infrastructure.virtual_networks.sap.exists ? (
                                           data.azurerm_virtual_network.vnet_sap[0].location) : (
                                           azurerm_virtual_network.vnet_sap[0].location
                                         )
  tags                                 = var.tags
}

# Associates SAP db nsg to SAP db subnet
resource "azurerm_subnet_network_security_group_association" "db" {
  provider                             = azurerm.main
  count                                = var.infrastructure.virtual_networks.sap.subnet_db.defined  && !var.infrastructure.virtual_networks.sap.subnet_db.nsg.exists ? 1 : 0
  depends_on                           = [
                                           azurerm_subnet.db
                                         ]
  subnet_id                            = var.infrastructure.virtual_networks.sap.subnet_db.exists ? var.infrastructure.virtual_networks.sap.subnet_db.id : azurerm_subnet.db[0].id
  network_security_group_id            = azurerm_network_security_group.db[0].id
}


# Creates SAP app subnet nsg
resource "azurerm_network_security_group" "app" {
  provider                             = azurerm.main
  count                                = var.infrastructure.virtual_networks.sap.subnet_app.defined && !var.infrastructure.virtual_networks.sap.subnet_app.nsg.exists ? 1 : 0
  name                                 = local.application_subnet_nsg_name
  resource_group_name                  = var.infrastructure.virtual_networks.sap.exists ? (
                                           data.azurerm_virtual_network.vnet_sap[0].resource_group_name
                                           ) : (
                                           azurerm_virtual_network.vnet_sap[0].resource_group_name
                                         )
  location                             = var.infrastructure.virtual_networks.sap.exists ? (
                                           data.azurerm_virtual_network.vnet_sap[0].location) : (
                                           azurerm_virtual_network.vnet_sap[0].location
                                         )
  tags                                 = var.tags
}


# Associates app nsg to app subnet
resource "azurerm_subnet_network_security_group_association" "app" {
  provider                             = azurerm.main
  count                                = var.infrastructure.virtual_networks.sap.subnet_app.defined && !var.infrastructure.virtual_networks.sap.subnet_app.nsg.exists ? 1 : 0
  depends_on                           = [
                                           azurerm_subnet.app
                                         ]
  subnet_id                            = var.infrastructure.virtual_networks.sap.subnet_app.exists ? var.infrastructure.virtual_networks.sap.subnet_app.id : azurerm_subnet.app[0].id
  network_security_group_id            = azurerm_network_security_group.app[0].id
}


# Creates SAP web subnet nsg
resource "azurerm_network_security_group" "web" {
  provider                             = azurerm.main
  count                                = var.infrastructure.virtual_networks.sap.subnet_web.defined && !var.infrastructure.virtual_networks.sap.subnet_web.nsg.exists ? 1 : 0
  depends_on                           = [
                                          azurerm_subnet.web
                                        ]
  name                                 = local.web_subnet_nsg_name
  resource_group_name                  = var.infrastructure.virtual_networks.sap.exists ? (
                                           data.azurerm_virtual_network.vnet_sap[0].resource_group_name
                                           ) : (
                                           azurerm_virtual_network.vnet_sap[0].resource_group_name
                                         )
  location                             = var.infrastructure.virtual_networks.sap.exists ? (
                                           data.azurerm_virtual_network.vnet_sap[0].location) : (
                                           azurerm_virtual_network.vnet_sap[0].location
                                         )
  tags                                 = var.tags
}

# Associates SAP web nsg to SAP web subnet
resource "azurerm_subnet_network_security_group_association" "web" {
  provider                             = azurerm.main
  count                                = var.infrastructure.virtual_networks.sap.subnet_web.defined && !var.infrastructure.virtual_networks.sap.subnet_web.nsg.exists ? 1 : 0
  subnet_id                            = var.infrastructure.virtual_networks.sap.subnet_web.exists ? var.infrastructure.virtual_networks.sap.subnet_web.id : azurerm_subnet.web[0].id
  network_security_group_id            = azurerm_network_security_group.web[0].id
}


# Creates SAP storage subnet nsg
resource "azurerm_network_security_group" "storage" {
  provider                             = azurerm.main
  count                                = var.infrastructure.virtual_networks.sap.subnet_storage.defined && !var.infrastructure.virtual_networks.sap.subnet_storage.nsg.exists ? 1 : 0
  depends_on                           = [
                                          azurerm_subnet.storage
                                        ]
  name                                 = local.storage_subnet_nsg_name
  resource_group_name                  = var.infrastructure.virtual_networks.sap.exists ? (
                                           data.azurerm_virtual_network.vnet_sap[0].resource_group_name
                                           ) : (
                                           azurerm_virtual_network.vnet_sap[0].resource_group_name
                                         )
  location                             = var.infrastructure.virtual_networks.sap.exists ? (
                                           data.azurerm_virtual_network.vnet_sap[0].location) : (
                                           azurerm_virtual_network.vnet_sap[0].location
                                        )
  tags                                 = var.tags
}

# Associates SAP storage nsg to SAP storage subnet
resource "azurerm_subnet_network_security_group_association" "storage" {
  provider                             = azurerm.main
  count                                = var.infrastructure.virtual_networks.sap.subnet_storage.defined && !var.infrastructure.virtual_networks.sap.subnet_storage.nsg.exists ? 1 : 0
  subnet_id                            = var.infrastructure.virtual_networks.sap.subnet_storage.exists ? var.infrastructure.virtual_networks.sap.subnet_storage.id : azurerm_subnet.storage[0].id
  network_security_group_id            = azurerm_network_security_group.storage[0].id
}


// Add network security rule
resource "azurerm_network_security_rule" "nsr_controlplane_app" {
  provider                             = azurerm.main
  count                                = var.infrastructure.virtual_networks.sap.subnet_app.nsg.exists ? 0 : 1
  depends_on                           = [
                                           azurerm_network_security_group.app
                                         ]
  name                                 = "ConnectivityToSAPApplicationSubnetFromControlPlane-ssh-rdp-winrm"
  resource_group_name                  = var.infrastructure.virtual_networks.sap.exists ? (
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
  destination_port_ranges              = [22, 443, 3389, 5985, 5986, 5404, 5405, 7630, 2049, 111]
  source_address_prefixes              = compact(concat(
                                           local.use_deployer ? var.deployer_tfstate.subnet_mgmt_address_prefixes : [""],
                                           local.use_deployer ? var.deployer_tfstate.subnet_bastion_address_prefixes : [""],
                                           var.infrastructure.virtual_networks.sap.exists ? (
                                             flatten(data.azurerm_virtual_network.vnet_sap[0].address_space)) : (
                                             flatten(azurerm_virtual_network.vnet_sap[0].address_space)
                                           )))
  destination_address_prefixes         = var.infrastructure.virtual_networks.sap.subnet_app.exists ? data.azurerm_subnet.app[0].address_prefixes : azurerm_subnet.app[0].address_prefixes
}

// Add SSH network security rule
resource "azurerm_network_security_rule" "nsr_controlplane_web" {
  provider                             = azurerm.main
  count                                = var.infrastructure.virtual_networks.sap.subnet_web.defined ? var.infrastructure.virtual_networks.sap.subnet_web.nsg.exists ? 0 : 1 : 0
  depends_on                           = [
                                           azurerm_network_security_group.web
                                         ]
  name                                 = "ConnectivityToSAPApplicationSubnetFromControlPlane-ssh-rdp-winrm"
  resource_group_name                  = var.infrastructure.virtual_networks.sap.exists ? (
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
  destination_port_ranges              = [22, 443, 3389, 5985, 5986, 2049, 111]
  source_address_prefixes              = compact(concat(
                                           local.use_deployer ? var.deployer_tfstate.subnet_mgmt_address_prefixes : [""],
                                           local.use_deployer ? var.deployer_tfstate.subnet_bastion_address_prefixes : [""],
                                           var.infrastructure.virtual_networks.sap.exists ? (
                                             flatten(data.azurerm_virtual_network.vnet_sap[0].address_space)) : (
                                             flatten(azurerm_virtual_network.vnet_sap[0].address_space)
                                           )))
  destination_address_prefixes         = var.infrastructure.virtual_networks.sap.subnet_web.exists ? data.azurerm_subnet.web[0].address_prefixes : azurerm_subnet.web[0].address_prefixes
}

// Add SSH network security rule
resource "azurerm_network_security_rule" "nsr_controlplane_storage" {
  provider                             = azurerm.main

  count                                = var.infrastructure.virtual_networks.sap.subnet_storage.defined ? var.infrastructure.virtual_networks.sap.subnet_storage.nsg.exists ? 0 : 1 : 0
  depends_on                           = [
                                           azurerm_network_security_group.storage
                                         ]
  name                                 = "ConnectivityToSAPApplicationSubnetFromControlPlane-ssh-rdp-winrm-ANF"
  resource_group_name                  = var.infrastructure.virtual_networks.sap.exists ? (
                                           data.azurerm_virtual_network.vnet_sap[0].resource_group_name
                                           ) : (
                                           azurerm_virtual_network.vnet_sap[0].resource_group_name
                                         )
  network_security_group_name          = try(azurerm_network_security_group.storage[0].name, azurerm_network_security_group.app[0].name)
  priority                             = 100
  direction                            = "Inbound"
  access                               = "Allow"
  protocol                             = "*"
  source_port_range                    = "*"
  destination_port_ranges              = [22, 443, 3389, 5985, 5986, 111, 635, 2049, 4045, 4046, 4049]
  source_address_prefixes              = compact(concat(
                                           local.use_deployer ? var.deployer_tfstate.subnet_mgmt_address_prefixes : [""],
                                           local.use_deployer ? var.deployer_tfstate.subnet_bastion_address_prefixes : [""],
                                           var.infrastructure.virtual_networks.sap.exists ? (
                                             flatten(data.azurerm_virtual_network.vnet_sap[0].address_space)) : (
                                             flatten(azurerm_virtual_network.vnet_sap[0].address_space)
                                           )))
  destination_address_prefixes         = var.infrastructure.virtual_networks.sap.subnet_storage.exists ? data.azurerm_subnet.storage[0].address_prefixes : azurerm_subnet.storage[0].address_prefixes
}

// Add SSH network security rule
resource "azurerm_network_security_rule" "nsr_controlplane_db" {
  provider                             = azurerm.main
  count                                = var.infrastructure.virtual_networks.sap.subnet_db.nsg.exists ? 0 : 1
  depends_on                           = [
                                           azurerm_network_security_group.db
                                         ]
  name                                 = "ConnectivityToSAPApplicationSubnetFromControlPlane-ssh-rdp-winrm"
  resource_group_name                  = var.infrastructure.virtual_networks.sap.exists ? (
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
  destination_port_ranges              = [22, 443, 3389, 5985, 5986,111, 635, 2049, 4045, 4046, 4049, 2049, 111]
  source_address_prefixes              = compact(concat(
                                           local.use_deployer ? var.deployer_tfstate.subnet_mgmt_address_prefixes : [""],
                                           local.use_deployer ? var.deployer_tfstate.subnet_bastion_address_prefixes : [""],
                                           var.infrastructure.virtual_networks.sap.exists ? (
                                             flatten(data.azurerm_virtual_network.vnet_sap[0].address_space)) : (
                                             flatten(azurerm_virtual_network.vnet_sap[0].address_space)
                                           )))
  destination_address_prefixes         = var.infrastructure.virtual_networks.sap.subnet_db.exists ? data.azurerm_subnet.db[0].address_prefixes : azurerm_subnet.db[0].address_prefixes
}

// Add network security rule
resource "azurerm_network_security_rule" "nsr_controlplane_admin" {
  provider                             = azurerm.main
  count                                = var.infrastructure.virtual_networks.sap.subnet_admin.nsg.exists ? 0 : (var.infrastructure.virtual_networks.sap.subnet_admin.defined ? 1 : 0)
  depends_on                           = [
                                           azurerm_network_security_group.admin
                                         ]
  name                                 = "ConnectivityToSAPApplicationSubnetFromControlPlane-ssh-rdp-winrm"
  resource_group_name                  = var.infrastructure.virtual_networks.sap.exists ? (
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
  destination_port_ranges              = [22, 443, 3389, 5985, 5986,111, 635, 2049, 4045, 4046, 4049, 2049, 111]
  source_address_prefixes              = compact(concat(
                                           local.use_deployer ? var.deployer_tfstate.subnet_mgmt_address_prefixes : [""],
                                           local.use_deployer ? var.deployer_tfstate.subnet_bastion_address_prefixes : [""],
                                           var.infrastructure.virtual_networks.sap.exists ? (
                                             flatten(data.azurerm_virtual_network.vnet_sap[0].address_space)) : (
                                             flatten(azurerm_virtual_network.vnet_sap[0].address_space)
                                           )))
  destination_address_prefixes         = var.infrastructure.virtual_networks.sap.subnet_admin.exists ? data.azurerm_subnet.admin[0].address_prefixes : azurerm_subnet.admin[0].address_prefixes
}
