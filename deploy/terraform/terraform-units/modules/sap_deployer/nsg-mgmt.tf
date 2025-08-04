# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

/*
Description:

  Define NSG for management vnet where deployer(s) resides.
*/

// Create/Import management nsg
resource "azurerm_network_security_group" "nsg_mgmt" {
  count                                = !var.infrastructure.virtual_network.management.subnet_mgmt.nsg.exists ? 1 : 0
  name                                 = local.management_subnet_nsg_name
  resource_group_name                  = var.infrastructure.resource_group.exists ? (
                                           data.azurerm_resource_group.deployer[0].name) : (
                                           azurerm_resource_group.deployer[0].name
                                         )
  location                             = var.infrastructure.resource_group.exists ? (
                                           data.azurerm_resource_group.deployer[0].location) : (
                                           azurerm_resource_group.deployer[0].location
                                         )
  tags                                 = var.infrastructure.tags
}

data "azurerm_network_security_group" "nsg_mgmt" {
  count                                = var.infrastructure.virtual_network.management.subnet_mgmt.nsg.exists ? 1 : 0
  name                                 = split("/", var.infrastructure.virtual_network.management.subnet_mgmt.nsg.id)[8]
  resource_group_name                  = split("/", var.infrastructure.virtual_network.management.subnet_mgmt.nsg.id)[4]
}

// Link management nsg with management vnet
resource "azurerm_subnet_network_security_group_association" "associate_nsg_mgmt" {
  count                                = (!var.infrastructure.virtual_network.management.subnet_mgmt.nsg.exists) ? 1 : 0
  depends_on                           = [
                                           azurerm_network_security_rule.nsr_ssh,
                                           azurerm_network_security_rule.nsr_rdp,
                                           azurerm_network_security_rule.nsr_winrm
                                         ]
  subnet_id                            = var.infrastructure.virtual_network.management.subnet_mgmt.exists ? (
                                           data.azurerm_subnet.subnet_mgmt[0].id) : (
                                           azurerm_subnet.subnet_mgmt[0].id
                                         )
  network_security_group_id            = azurerm_network_security_group.nsg_mgmt[0].id
}

// Add SSH network security rule
resource "azurerm_network_security_rule" "nsr_ssh" {
  count                                = !var.infrastructure.virtual_network.management.subnet_mgmt.nsg.exists && local.enable_deployer_public_ip ? 1 : 0
  depends_on                           = [
                                           data.azurerm_network_security_group.nsg_mgmt,
                                           azurerm_network_security_group.nsg_mgmt
                                         ]
  name                                 = "ssh"
  resource_group_name                  = var.infrastructure.virtual_network.management.subnet_mgmt.nsg.exists ? (
                                           data.azurerm_network_security_group.nsg_mgmt[0].resource_group_name) : (
                                           azurerm_network_security_group.nsg_mgmt[0].resource_group_name
                                         )
  network_security_group_name          = var.infrastructure.virtual_network.management.subnet_mgmt.nsg.exists ? (
                                          data.azurerm_network_security_group.nsg_mgmt[0].name) : (
                                          azurerm_network_security_group.nsg_mgmt[0].name
                                        )
  priority                             = 101
  direction                            = "Inbound"
  access                               = "Allow"
  protocol                             = "Tcp"
  source_port_range                    = "*"
  destination_port_range               = 22
  destination_address_prefixes         = var.infrastructure.virtual_network.management.subnet_mgmt.exists ? (
                                           data.azurerm_subnet.subnet_mgmt[0].address_prefixes) : (
                                           try(azurerm_subnet.subnet_mgmt[0].address_prefixes, [])
                                         )
  source_address_prefixes              = length(var.infrastructure.virtual_network.management.subnet_mgmt.nsg.allowed_ips) > 0 ? (
                                             var.infrastructure.virtual_network.management.subnet_mgmt.nsg.allowed_ips) : (
                                             ["0.0.0.0/0"]
                                           )

}

// Add RDP network security rule
resource "azurerm_network_security_rule" "nsr_rdp" {
  count                                = !var.infrastructure.virtual_network.management.subnet_mgmt.nsg.exists && local.enable_deployer_public_ip ? 1 : 0
  depends_on                           = [
                                           data.azurerm_network_security_group.nsg_mgmt,
                                           azurerm_network_security_group.nsg_mgmt
                                         ]
  name                                 = "rdp"
  resource_group_name                  = var.infrastructure.virtual_network.management.subnet_mgmt.nsg.exists ? (
                                           data.azurerm_network_security_group.nsg_mgmt[0].resource_group_name) : (
                                           azurerm_network_security_group.nsg_mgmt[0].resource_group_name
                                         )
  network_security_group_name          = var.infrastructure.virtual_network.management.subnet_mgmt.nsg.exists ? (
                                          data.azurerm_network_security_group.nsg_mgmt[0].name) : (
                                          azurerm_network_security_group.nsg_mgmt[0].name
                                        )
  priority                             = 102
  direction                            = "Inbound"
  access                               = "Allow"
  protocol                             = "Tcp"
  source_port_range                    = "*"
  destination_port_range               = 3389
  destination_address_prefixes         = var.infrastructure.virtual_network.management.subnet_mgmt.exists ? (
                                           data.azurerm_subnet.subnet_mgmt[0].address_prefixes) : (
                                           try(azurerm_subnet.subnet_mgmt[0].address_prefixes, [])
                                         )
  source_address_prefixes              = length(var.infrastructure.virtual_network.management.subnet_mgmt.nsg.allowed_ips) > 0 ? (
                                             var.infrastructure.virtual_network.management.subnet_mgmt.nsg.allowed_ips) : (
                                             ["0.0.0.0/0"]
                                           )

}

// Add WinRM network security rule
resource "azurerm_network_security_rule" "nsr_winrm" {
  count                                = !var.infrastructure.virtual_network.management.subnet_mgmt.nsg.exists && local.enable_deployer_public_ip ? 1 : 0
  depends_on                           = [
                                           data.azurerm_network_security_group.nsg_mgmt,
                                           azurerm_network_security_group.nsg_mgmt
                                         ]
  name                                 = "winrm"
  resource_group_name                  = var.infrastructure.virtual_network.management.subnet_mgmt.nsg.exists ? (
                                           data.azurerm_network_security_group.nsg_mgmt[0].resource_group_name) : (
                                           azurerm_network_security_group.nsg_mgmt[0].resource_group_name
                                         )
  network_security_group_name          = var.infrastructure.virtual_network.management.subnet_mgmt.nsg.exists ? (
                                          data.azurerm_network_security_group.nsg_mgmt[0].name) : (
                                          azurerm_network_security_group.nsg_mgmt[0].name
                                        )
  priority                             = 103
  direction                            = "Inbound"
  access                               = "Allow"
  protocol                             = "Tcp"
  source_port_range                    = "*"
  destination_port_ranges              = [5985, 5986]
  destination_address_prefixes         = var.infrastructure.virtual_network.management.subnet_mgmt.exists ? (
                                           data.azurerm_subnet.subnet_mgmt[0].address_prefixes) : (
                                           try(azurerm_subnet.subnet_mgmt[0].address_prefixes, [])
                                         )
  source_address_prefixes              = length(var.infrastructure.virtual_network.management.subnet_mgmt.nsg.allowed_ips) > 0 ? (
                                             var.infrastructure.virtual_network.management.subnet_mgmt.nsg.allowed_ips) : (
                                             ["0.0.0.0/0"]
                                           )

}