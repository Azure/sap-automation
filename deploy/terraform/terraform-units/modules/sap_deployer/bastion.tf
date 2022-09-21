// Create/Import bastion subnet

resource "azurerm_subnet" "bastion" {
  count = var.bastion_deployment ? (
    length(var.infrastructure.vnets.management.subnet_bastion.arm_id) == 0 ? (
      1) : (
      0
    )) : (
    0
  )
  name = "AzureBastionSubnet"
  resource_group_name = local.vnet_mgmt_exists ? (
    data.azurerm_virtual_network.vnet_mgmt[0].resource_group_name) : (
    azurerm_virtual_network.vnet_mgmt[0].resource_group_name
  )
  virtual_network_name = local.vnet_mgmt_exists ? (
    data.azurerm_virtual_network.vnet_mgmt[0].name) : (
    azurerm_virtual_network.vnet_mgmt[0].name
  )
  address_prefixes = [var.infrastructure.vnets.management.subnet_bastion.prefix]

  private_endpoint_network_policies_enabled     = var.use_private_endpoint
  private_link_service_network_policies_enabled = false

  service_endpoints = var.use_service_endpoint ? (
    ["Microsoft.Storage", "Microsoft.KeyVault"]) : (
    null
  )
}

data "azurerm_subnet" "bastion" {
  count = var.bastion_deployment ? (
    length(var.infrastructure.vnets.management.subnet_bastion.arm_id) == 0 ? (
      0) : (
      1
    )) : (
    0
  )
  name                 = split("/", try(var.infrastructure.vnets.management.subnet_bastion.arm_id, ""))[10]
  resource_group_name  = split("/", try(var.infrastructure.vnets.management.subnet_bastion.arm_id, ""))[4]
  virtual_network_name = split("/", try(var.infrastructure.vnets.management.subnet_bastion.arm_id, ""))[8]
}

# Create a public IP address for the Azure Bastion
resource "azurerm_public_ip" "bastion" {
  count = var.bastion_deployment ? 1 : 0
  name = format("%s%s%s%s",
    var.naming.resource_prefixes.bastion_pip,
    local.prefix,
    var.naming.separator,
    var.naming.resource_suffixes.bastion_pip
  )
  location = local.vnet_mgmt_exists ? (
    data.azurerm_virtual_network.vnet_mgmt[0].location) : (
    azurerm_virtual_network.vnet_mgmt[0].location
  )
  resource_group_name = local.vnet_mgmt_exists ? (
    data.azurerm_virtual_network.vnet_mgmt[0].resource_group_name) : (
    azurerm_virtual_network.vnet_mgmt[0].resource_group_name
  )
  allocation_method = "Static"
  sku               = "Standard"
}

# Create the Bastion Host
resource "azurerm_bastion_host" "bastion" {
  count = var.bastion_deployment ? 1 : 0
  name = format("%s%s%s%s",
    var.naming.resource_prefixes.bastion_host,
    local.prefix,
    var.naming.separator,
    var.naming.resource_suffixes.bastion_host
  )
  location = local.vnet_mgmt_exists ? (
    data.azurerm_virtual_network.vnet_mgmt[0].location) : (
    azurerm_virtual_network.vnet_mgmt[0].location
  )
  resource_group_name = local.vnet_mgmt_exists ? (
    data.azurerm_virtual_network.vnet_mgmt[0].resource_group_name) : (
    azurerm_virtual_network.vnet_mgmt[0].resource_group_name
  )

  ip_configuration {
    name = "configuration"
    subnet_id = length(var.infrastructure.vnets.management.subnet_bastion.arm_id) == 0 ? (
      azurerm_subnet.bastion[0].id) : (
      data.azurerm_subnet.bastion[0].id
    )
    public_ip_address_id = azurerm_public_ip.bastion[0].id
  }
}
