
// Creates endpoint subnet
resource "azurerm_subnet" "endpoint" {
  provider                             = azurerm.main
  count                                = var.infrastructure.virtual_network.management.subnet_endpoint.defined ? 1 : 0
  name                                 = local.endpoint_subnet_name
  resource_group_name                  = var.infrastructure.virtual_network.management.exists ? data.azurerm_virtual_network.vnet_mgmt[0].resource_group_name : azurerm_virtual_network.vnet_mgmt[0].resource_group_name
  virtual_network_name                 = var.infrastructure.virtual_network.management.exists ? data.azurerm_virtual_network.vnet_mgmt[0].name : azurerm_virtual_network.vnet_mgmt[0].name
  address_prefixes                     = [var.infrastructure.virtual_network.management.subnet_endpoint.prefix]

  service_endpoints                    = var.use_service_endpoint ? (
                                           ["Microsoft.Storage", "Microsoft.KeyVault"]
                                           ) : (
                                           null
                                         )
}

data "azurerm_subnet" "endpoint" {
  provider                             = azurerm.main
  count                                = var.infrastructure.virtual_network.management.subnet_endpoint.exists ? 1 : 0
  name                                 = split("/", var.infrastructure.virtual_network.management.subnet_endpoint.id)[10]
  resource_group_name                  = split("/", var.infrastructure.virtual_network.management.subnet_endpoint.id)[4]
  virtual_network_name                 = split("/", var.infrastructure.virtual_network.management.subnet_endpoint.id)[8]
}

resource "azurerm_network_security_group" "endpoint" {
  provider                             = azurerm.main
  count                                = var.infrastructure.virtual_network.management.subnet_endpoint.defined && !var.infrastructure.virtual_network.management.subnet_endpoint.nsg.exists ? 1 : 0
  name                                 = local.endpoint_subnet_nsg_name
  resource_group_name                  = local.resourcegroup_name
  location                             = var.infrastructure.resource_group.exists ? data.azurerm_resource_group.deployer[0].location : azurerm_resource_group.deployer[0].location
  tags                                 = var.infrastructure.tags
}

data "azurerm_network_security_group" "endpoint" {
  provider                             = azurerm.main
  count                                = var.infrastructure.virtual_network.management.subnet_endpoint.defined && var.infrastructure.virtual_network.management.subnet_endpoint.nsg.exists ? 1 : 0
  name                                 = split("/", var.infrastructure.virtual_network.management.subnet_endpoint.nsg.id)[8]
  resource_group_name                  = split("/", var.infrastructure.virtual_network.management.subnet_endpoint.nsg.id)[4]
}

resource "azurerm_subnet_network_security_group_association" "endpoint" {
  provider                             = azurerm.main
  count                                = var.infrastructure.virtual_network.management.subnet_endpoint.defined ? 1 : 0
  subnet_id                            = azurerm_subnet.endpoint[0].id
  network_security_group_id            = var.infrastructure.virtual_network.management.subnet_endpoint.nsg.exists ? data.azurerm_network_security_group.endpoint[0].id : azurerm_network_security_group.endpoint[0].id
}
