#######################################4#######################################8
#                                                                              #
#                 Application NSG - Check if locally provided                  #
#                                                                              #
#######################################4#######################################8
resource "azurerm_network_security_group" "nsg_app" {
  provider                             = azurerm.main
  count                                = local.enable_deployment ? (local.application_subnet_nsg_exists ? 0 : 1) : 0
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
  count                                = local.enable_deployment ? (
                                           local.application_subnet_nsg_exists ? 1 : 0) : (
                                           0
                                         )
  name                                 = split("/", local.application_subnet_nsg_arm_id)[8]
  resource_group_name                  = split("/", local.application_subnet_nsg_arm_id)[4]
}

resource "azurerm_subnet_network_security_group_association" "Associate_nsg_app" {
  provider                             = azurerm.main
  count                                = local.enable_deployment ? (
                                           signum(
                                             (local.application_subnet_exists ? 0 : 1) +
                                             (local.application_subnet_nsg_exists ? 0 : 1)
                                           )) : (
                                           0
                                         )
  subnet_id                            = local.application_subnet_exists ? (
                                           local.application_subnet_arm_id) : (
                                           azurerm_subnet.subnet_sap_app[0].id
                                         )
  network_security_group_id            = local.application_subnet_nsg_exists ? (
                                           data.azurerm_network_security_group.nsg_app[0].id) : (
                                           azurerm_network_security_group.nsg_app[0].id
                                         )
}
