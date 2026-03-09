resource "azurerm_network_security_perimeter" "perimeter" {
  count               = var.options.network_security_perimeter.deploy && !var.options.network_security_perimeter.exists  ? 1 : 0
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
  count               = var.options.network_security_perimeter.deploy && var.options.network_security_perimeter.exists  ? 1 : 0
  name                = var.options.network_security_perimeter.name
  resource_group_name = var.infrastructure.resource_group.exists ? (
                                           data.azurerm_resource_group.deployer[0].name) : (
                                           azurerm_resource_group.deployer[0].name
                                         )
}


resource "azurerm_network_security_perimeter_profile" "profile" {
  count                          = var.options.network_security_perimeter.deploy ? 1 : 0
  name                           = "SDAF"
  network_security_perimeter_id  = !var.options.network_security_perimeter.exists ? azurerm_network_security_perimeter.perimeter[0].id : data.azurerm_network_security_perimeter.perimeter[0].id
}

# resource "azurerm_network_security_perimeter_access_rule" "inbound" {
#   count                                  = var.options.network_security_perimeter.deploy ? 1 : 0
#   name                                   = local.prefix
#   network_security_perimeter_profile_id  = azurerm_network_security_perimeter_profile.profile[0].id
#   direction                              = "Inbound"

#   address_prefixes = var.infrastructure.virtual_network.management.exists ? data.azurerm_virtual_network.vnet_mgmt[0].address_space : azurerm_virtual_network.vnet_mgmt[0].address_space
# }

resource "azurerm_network_security_perimeter_association" "vault" {
  count                                  = var.options.network_security_perimeter.deploy ? 1 : 0
  name                                   = local.keyvault_names.user_access
  access_mode                            = "Enforced"

  network_security_perimeter_profile_id = !var.options.network_security_perimeter.exists ? azurerm_network_security_perimeter_profile.profile[0].id : null
  resource_id                           = var.key_vault.exists ? data.azurerm_key_vault.kv_user[0].id : azurerm_key_vault.kv_user[0].id
}

resource "azurerm_network_security_perimeter_association" "app_config" {
  count                                  = var.options.network_security_perimeter.deploy && var.app_config_service.deploy ? 1 : 0
  name                                   = local.app_config_name
  access_mode                            = "Enforced"

  network_security_perimeter_profile_id = !var.options.network_security_perimeter.exists ? azurerm_network_security_perimeter_profile.profile[0].id : null
  resource_id                           = length(var.app_config_service.id) == 0 ? azurerm_app_configuration.app_config[0].id : data.azurerm_app_configuration.app_config[0].id
}

resource "azurerm_network_security_perimeter_association" "webapp" {
  count                                  = var.options.network_security_perimeter.deploy && var.app_service.use ? 1 : 0
  name                                   = azurerm_windows_web_app.webapp[0].name
  access_mode                            = "Enforced"

  network_security_perimeter_profile_id = !var.options.network_security_perimeter.exists ? azurerm_network_security_perimeter_profile.profile[0].id : null
  resource_id                           = azurerm_windows_web_app.webapp[0].id
}



output "network_security_perimeter_id" {
  value                                  = var.options.network_security_perimeter.deploy ? azurerm_network_security_perimeter.perimeter[0].id : ""
}
