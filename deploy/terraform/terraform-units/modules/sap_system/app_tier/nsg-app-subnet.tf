# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

#######################################4#######################################8
#                                                                              #
#                 Application NSG - Check if locally provided                  #
#                                                                              #
#######################################4#######################################8
resource "azurerm_network_security_group" "nsg_app" {
  provider                             = azurerm.main
  count                                = local.enable_deployment ? (var.infrastructure.virtual_networks.sap.subnet_app.nsg.exists || var.infrastructure.virtual_networks.sap.subnet_app.nsg.exists_in_workload ? 0 : 1) : 0

  name                                 = local.application_subnet_nsg_name
  resource_group_name                  = var.options.nsg_asg_with_vnet ? (
                                           var.network_resource_group) : (
                                           var.resource_group[0].name
                                         )
  location                             = var.options.nsg_asg_with_vnet ? (
                                           var.network_location) : (
                                           var.resource_group[0].location
                                         )
}

data "azurerm_network_security_group" "nsg_app" {
  provider                             = azurerm.main
  count                                = local.enable_deployment ? (var.infrastructure.virtual_networks.sap.subnet_app.nsg.exists || var.infrastructure.virtual_networks.sap.subnet_app.nsg.exists_in_workload ? 1 : 0) : 0
  name                                 = split("/", coalesce(var.infrastructure.virtual_networks.sap.subnet_app.nsg.id, var.infrastructure.virtual_networks.sap.subnet_app.nsg.id_in_workload))[8]
  resource_group_name                  = split("/", coalesce(var.infrastructure.virtual_networks.sap.subnet_app.nsg.id, var.infrastructure.virtual_networks.sap.subnet_app.nsg.id_in_workload))[4]
}

resource "azurerm_subnet_network_security_group_association" "Associate_nsg_app" {
  provider                             = azurerm.main
  count                                = local.enable_deployment ? (var.infrastructure.virtual_networks.sap.subnet_app.nsg.exists || var.infrastructure.virtual_networks.sap.subnet_app.nsg.exists_in_workload ? 0 : 1) : 0
  subnet_id                            = var.infrastructure.virtual_networks.sap.subnet_app.exists ? (
                                           coalesce(var.infrastructure.virtual_networks.sap.subnet_app.id, var.infrastructure.virtual_networks.sap.subnet_app.id_in_workload)) : (
                                           azurerm_subnet.subnet_sap_app[0].id
                                         )
  network_security_group_id            = var.infrastructure.virtual_networks.sap.subnet_app.nsg.exists ? (
                                           data.azurerm_network_security_group.nsg_app[0].id) : (
                                           azurerm_network_security_group.nsg_app[0].id
                                         )
}
