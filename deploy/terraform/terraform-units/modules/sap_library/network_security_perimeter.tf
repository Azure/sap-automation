
data "azurerm_network_security_perimeter" "perimeter" {
  provider                             = azurerm.deployer
  count                                = try(var.deployer_tfstate.network_security_perimeter_deployment, false) ? 1 : 0
  name                                 = local.network_security_name
  resource_group_name                  = local.network_security_resource_group_name
}


data "azurerm_network_security_perimeter_profile" "profile" {
  provider                             = azurerm.deployer
  count                                = try(var.deployer_tfstate.network_security_perimeter_deployment, false) ? 1 : 0
  name                                 = "SDAF"
  network_security_perimeter_id        = data.azurerm_network_security_perimeter.perimeter[0].id
}

resource "azurerm_network_security_perimeter_association" "storage_tfstate" {
  provider                               = azurerm.deployer
  count                                  = try(var.deployer_tfstate.network_security_perimeter_deployment, false) ? 1 : 0
  name                                   = var.storage_account_tfstate.exists ? (
                                                     data.azurerm_storage_account.storage_tfstate[0].name) : (
                                                     try(azurerm_storage_account.storage_tfstate[0].name, "")
                                                   )
  access_mode                            = var.deployer_tfstate.network_security_access_mode

  network_security_perimeter_profile_id = data.azurerm_network_security_perimeter_profile.profile[0].id
  resource_id                           = var.storage_account_tfstate.exists ? (
                                                     data.azurerm_storage_account.storage_tfstate[0].id) : (
                                                     try(azurerm_storage_account.storage_tfstate[0].id, "")
                                                   )
}

resource "azurerm_network_security_perimeter_association" "storage_sapbits" {
  provider                               = azurerm.deployer
  count                                  = try(var.deployer_tfstate.network_security_perimeter_deployment, false) ? 1 : 0
  name                                   = var.storage_account_sapbits.exists ? (
                                                     data.azurerm_storage_account.storage_sapbits[0].name) : (
                                                     try(azurerm_storage_account.storage_sapbits[0].name, "")
                                                   )
  access_mode                            = var.deployer_tfstate.network_security_access_mode

  network_security_perimeter_profile_id = data.azurerm_network_security_perimeter_profile.profile[0].id
  resource_id                           = var.storage_account_sapbits.exists ? (
                                                     data.azurerm_storage_account.storage_sapbits[0].id) : (
                                                     try(azurerm_storage_account.storage_sapbits[0].id, "")
                                                   )
}

locals {
  parsed_network_security_id           = try(var.deployer_tfstate.network_security_perimeter_deployment, false) ? try(provider::azurerm::parse_resource_id(var.deployer_tfstate.network_security_perimeter_id), null) : null
  network_security_name                = try(var.deployer_tfstate.network_security_perimeter_deployment, false) ? try(local.parsed_network_security_id["resource_name"], "") : ""
  network_security_resource_group_name = try(var.deployer_tfstate.network_security_perimeter_deployment, false) ? try(local.parsed_network_security_id["resource_group_name"], "") : ""

}
