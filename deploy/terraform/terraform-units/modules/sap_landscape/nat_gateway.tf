# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

# https://github.com/hashicorp/terraform-provider-azurerm/issues/18741
# public IP address for the natGateway
resource "azurerm_public_ip" "ng_pip" {
  provider                             = azurerm.main
  count                                = local.create_nat_gateway ? 1 : 0
  name                                 = format("%s%s", local.nat_gateway_name, "-pip")
  location                             = local.region
  resource_group_name                  = azurerm_resource_group.resource_group[0].name
  idle_timeout_in_minutes              = local.nat_gateway_idle_timeout_in_minutes
  zones                                = local.nat_gateway_public_ip_zones
  ip_tags                              = length(var.infrastructure.nat_gateway.ip_tags) > 0 ? var.infrastructure.nat_gateway.ip_tags : null
  tags                                 = var.infrastructure.tags
  allocation_method                    = "Static"
  sku                                  = "Standard"
  lifecycle                            {
                                         create_before_destroy = true
                                       }
}

# NAT Gateway
# Currently only Standard SKU is supported.
# https://learn.microsoft.com/en-us/azure/nat-gateway/nat-overview#availability-zones
# Only one Availability Zone can be defined. We will not provide a zone for now.
resource "azurerm_nat_gateway" "ng" {
  provider                             = azurerm.main
  count                                = local.create_nat_gateway ? 1 : 0
  name                                 = local.nat_gateway_name
  location                             = local.region
  resource_group_name                  = azurerm_resource_group.resource_group[0].name
  idle_timeout_in_minutes              = local.nat_gateway_idle_timeout_in_minutes
  sku_name                             = "Standard"
  depends_on                           = [
                                           azurerm_public_ip.ng_pip
                                         ]

}


# NAT Gateway IP Configuration
resource "azurerm_nat_gateway_public_ip_association" "ng_pip_assoc" {
  provider                             = azurerm.main
  count                                = local.create_nat_gateway ? 1 : 0
  nat_gateway_id                       = azurerm_nat_gateway.ng[0].id
  public_ip_address_id                 = azurerm_public_ip.ng_pip[0].id
}


# NAT Gateway subnet association with app subnet
resource "azurerm_subnet_nat_gateway_association" "ng_subnet_assoc" {
  provider                             = azurerm.main
  count                                = local.create_nat_gateway ? 1 : 0
  nat_gateway_id                       = azurerm_nat_gateway.ng[0].id
  subnet_id                            = azurerm_subnet.app[0].id
  depends_on                           = [
                                           azurerm_subnet.app
                                         ]
}

# NAT Gateway subnet association with db subnet
resource "azurerm_subnet_nat_gateway_association" "ng_subnet_assoc_db" {
  provider                             = azurerm.main
  count                                = local.create_nat_gateway ? 1 : 0
  nat_gateway_id                       = azurerm_nat_gateway.ng[0].id
  subnet_id                            = azurerm_subnet.db[0].id
  depends_on                           = [
                                           azurerm_subnet.db
                                         ]
}

# NAT Gateway subnet association with web subnet
resource "azurerm_subnet_nat_gateway_association" "ng_subnet_assoc_web" {
  provider                             = azurerm.main
  count                                = local.create_nat_gateway ? 1 : 0
  nat_gateway_id                       = azurerm_nat_gateway.ng[0].id
  subnet_id                            = azurerm_subnet.web[0].id
  depends_on                           = [
                                           azurerm_subnet.web
                                         ]
}
