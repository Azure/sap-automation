resource "azurerm_network_security_perimeter" "perimeter" {
  count               = try(var.options.network_security_perimeter.deploy, false) && !try(var.options.network_security_perimeter.exists, false)  ? 1 : 0
  name                = var.options.network_security_perimeter.name
  resource_group_name = var.infrastructure.resource_group.exists ? (
                                           data.azurerm_resource_group.deployer[0].name) : (
                                           azurerm_resource_group.deployer[0].name
                                         )
  location            = var.infrastructure.resource_group.exists ? (
                                           data.azurerm_resource_group.deployer[0].location) : (
                                           azurerm_resource_group.deployer[0].location
                                         )
}

data "azurerm_network_security_perimeter" "perimeter" {
  count               = try(var.options.network_security_perimeter.deploy, false) && try(var.options.network_security_perimeter.exists, false)  ? 1 : 0
  name                = local.security_perimeter_name
  resource_group_name = local.security_perimeter_resource_group_name
}


resource "azurerm_network_security_perimeter_profile" "profile" {
  count                          = try(var.options.network_security_perimeter.deploy, false) ? 1 : 0
  name                           = "SDAF"
  network_security_perimeter_id  = try(var.options.network_security_perimeter.exists, false)  ? data.azurerm_network_security_perimeter.perimeter[0].id : azurerm_network_security_perimeter.perimeter[0].id
}

# resource "azurerm_network_security_perimeter_access_rule" "inbound" {
#   count                                  = try(var.options.network_security_perimeter.deploy, false) ? 1 : 0
#   name                                   = local.prefix
#   network_security_perimeter_profile_id  = azurerm_network_security_perimeter_profile.profile[0].id
#   direction                              = "Inbound"

#   address_prefixes = var.infrastructure.virtual_network.management.exists ? data.azurerm_virtual_network.vnet_mgmt[0].address_space : azurerm_virtual_network.vnet_mgmt[0].address_space
# }

resource "azurerm_network_security_perimeter_association" "vault" {
  count                                  = try(var.options.network_security_perimeter.deploy, false) ? 1 : 0
  name                                   = local.keyvault_names.user_access
  access_mode                            = var.options.network_security_perimeter.network_security_access_mode

  network_security_perimeter_profile_id = azurerm_network_security_perimeter_profile.profile[0].id
  resource_id                           = var.key_vault.exists ? data.azurerm_key_vault.kv_user[0].id : azurerm_key_vault.kv_user[0].id
}

resource "azurerm_network_security_perimeter_association" "app_config" {
  count                                  = try(var.options.network_security_perimeter.deploy, false) && var.app_config_service.deploy ? 1 : 0
  name                                   = local.app_config_name
  access_mode                            = var.options.network_security_perimeter.network_security_access_mode

  network_security_perimeter_profile_id = azurerm_network_security_perimeter_profile.profile[0].id
  resource_id                           = length(var.app_config_service.id) == 0 ? azurerm_app_configuration.app_config[0].id : data.azurerm_app_configuration.app_config[0].id
}

resource "azurerm_network_security_perimeter_association" "webapp" {
  count                                  = try(var.options.network_security_perimeter.deploy, false) && var.app_service.use ? 1 : 0
  name                                   = azurerm_windows_web_app.webapp[0].name
  access_mode                            = var.options.network_security_perimeter.network_security_access_mode

  network_security_perimeter_profile_id = azurerm_network_security_perimeter_profile.profile[0].id
  resource_id                           = azurerm_windows_web_app.webapp[0].id
}

output "network_security_perimeter_id" {
  description                            = "The Azure network security perimeter id"
  value                                  = try(var.options.network_security_perimeter.deploy, false) ? (
                                             try(var.options.network_security_perimeter.exists, false) ? (
                                               data.azurerm_network_security_perimeter.perimeter[0].id) : (
                                               azurerm_network_security_perimeter.perimeter[0].id)) : (
                                             "")
}

locals {

  security_perimeter_parsed_id            = var.options.network_security_perimeter.deploy ? provider::azurerm::parse_resource_id(var.options.network_security_perimeter.id) : null
  security_perimeter_name                 = var.options.network_security_perimeter.deploy ? local.security_perimeter_parsed_id["resource_name"] : ""
  security_perimeter_resource_group_name  = var.options.network_security_perimeter.deploy ? local.security_perimeter_parsed_id["resource_group_name"] : ""
  }
