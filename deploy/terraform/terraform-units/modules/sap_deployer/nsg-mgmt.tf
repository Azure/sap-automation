/*
Description:

  Define NSG for management vnet where deployer(s) resides.
*/

// Create/Import management nsg
resource "azurerm_network_security_group" "nsg_mgmt" {
  count                                = !local.management_subnet_nsg_exists ? 1 : 0
  name                                 = local.management_subnet_nsg_name
  resource_group_name                  = local.resource_group_exists ? (
                                           data.azurerm_resource_group.deployer[0].name) : (
                                           azurerm_resource_group.deployer[0].name
                                         )
  location                             = local.resource_group_exists ? (
                                           data.azurerm_resource_group.deployer[0].location) : (
                                           azurerm_resource_group.deployer[0].location
                                         )
}

data "azurerm_network_security_group" "nsg_mgmt" {
  count                                = local.management_subnet_nsg_exists ? 1 : 0
  name                                 = split("/", local.management_subnet_nsg_arm_id)[8]
  resource_group_name                  = split("/", local.management_subnet_nsg_arm_id)[4]
}

// Link management nsg with management vnet
resource "azurerm_subnet_network_security_group_association" "associate_nsg_mgmt" {
  count                                = (!local.management_subnet_exists) ? 1 : 0
  depends_on                           = [
                                           azurerm_network_security_rule.nsr_ssh,
                                           azurerm_network_security_rule.nsr_rdp,
                                           azurerm_network_security_rule.nsr_winrm
                                         ]
  subnet_id                            = local.management_subnet_exists ? (
                                           data.azurerm_subnet.subnet_mgmt[0].id) : (
                                           azurerm_subnet.subnet_mgmt[0].id
                                         )
  network_security_group_id            = local.management_subnet_nsg_exists ? (
                                           data.azurerm_network_security_group.nsg_mgmt[0].id) : (
                                           azurerm_network_security_group.nsg_mgmt[0].id
                                         )
}

// Add SSH network security rule
resource "azurerm_network_security_rule" "nsr_ssh" {
  count                                = !local.management_subnet_nsg_exists && local.enable_deployer_public_ip ? 1 : 0
  depends_on                           = [
                                           data.azurerm_network_security_group.nsg_mgmt,
                                           azurerm_network_security_group.nsg_mgmt
                                         ]
  name                                 = "ssh"
  resource_group_name                  = local.management_subnet_nsg_exists ? (
                                           data.azurerm_network_security_group.nsg_mgmt[0].resource_group_name) : (
                                           azurerm_network_security_group.nsg_mgmt[0].resource_group_name
                                         )
  network_security_group_name          = local.management_subnet_nsg_exists ? (
                                          data.azurerm_network_security_group.nsg_mgmt[0].name) : (
                                          azurerm_network_security_group.nsg_mgmt[0].name
                                        )
  priority                             = 101
  direction                            = "Inbound"
  access                               = "Allow"
  protocol                             = "Tcp"
  source_port_range                    = "*"
  destination_port_range               = 22
  source_address_prefixes              = local.management_subnet_nsg_allowed_ips
  destination_address_prefixes         = local.management_subnet_deployed_prefixes
}

// Add RDP network security rule
resource "azurerm_network_security_rule" "nsr_rdp" {
  count                                = !local.management_subnet_nsg_exists && local.enable_deployer_public_ip ? 1 : 0
  depends_on                           = [
                                           data.azurerm_network_security_group.nsg_mgmt,
                                           azurerm_network_security_group.nsg_mgmt
                                         ]
  name                                 = "rdp"
  resource_group_name                  = local.management_subnet_nsg_exists ? (
                                           data.azurerm_network_security_group.nsg_mgmt[0].resource_group_name) : (
                                           azurerm_network_security_group.nsg_mgmt[0].resource_group_name
                                         )
  network_security_group_name          = local.management_subnet_nsg_exists ? (
                                          data.azurerm_network_security_group.nsg_mgmt[0].name) : (
                                          azurerm_network_security_group.nsg_mgmt[0].name
                                        )
  priority                             = 102
  direction                            = "Inbound"
  access                               = "Allow"
  protocol                             = "Tcp"
  source_port_range                    = "*"
  destination_port_range               = 3389
  source_address_prefixes              = local.management_subnet_nsg_allowed_ips
  destination_address_prefixes         = local.management_subnet_deployed_prefixes
}

// Add WinRM network security rule
resource "azurerm_network_security_rule" "nsr_winrm" {
  count                                = !local.management_subnet_nsg_exists && local.enable_deployer_public_ip ? 1 : 0
  depends_on                           = [
                                           data.azurerm_network_security_group.nsg_mgmt,
                                           azurerm_network_security_group.nsg_mgmt
                                         ]
  name                                 = "winrm"
  resource_group_name                  = local.management_subnet_nsg_exists ? (
                                           data.azurerm_network_security_group.nsg_mgmt[0].resource_group_name) : (
                                           azurerm_network_security_group.nsg_mgmt[0].resource_group_name
                                         )
  network_security_group_name          = local.management_subnet_nsg_exists ? (
                                          data.azurerm_network_security_group.nsg_mgmt[0].name) : (
                                          azurerm_network_security_group.nsg_mgmt[0].name
                                        )
  priority                             = 103
  direction                            = "Inbound"
  access                               = "Allow"
  protocol                             = "Tcp"
  source_port_range                    = "*"
  destination_port_ranges              = [5985, 5986]
  source_address_prefixes              = local.management_subnet_nsg_allowed_ips
  destination_address_prefixes         = local.management_subnet_deployed_prefixes
}
