
data "azurerm_network_security_perimeter" "perimeter" {
  count                          = var.deployer_tfstate.network_security_perimeter_deployment ? 1 : 0
  name                           = local.network_security_name
  resource_group_name            = local.network_security_resource_group_name
}


data "azurerm_network_security_perimeter_profile" "profile" {
  count                          = var.deployer_tfstate.network_security_perimeter_deployment ? 1 : 0
  name                           = "SDAF"
  network_security_perimeter_id  = data.azurerm_network_security_perimeter.perimeter[0].id
}

resource "azurerm_network_security_perimeter_association" "storage_tfstate" {
  count                                  = var.deployer_tfstate.network_security_perimeter_deployment ? 1 : 0
  name                                   = var.storage_account_tfstate.exists ? (
                                                     data.azurerm_storage_account.storage_tfstate[0].name) : (
                                                     try(azurerm_storage_account.storage_tfstate[0].name, "")
                                                   )
  access_mode                            = "Enforced"

  network_security_perimeter_profile_id = data.azurerm_network_security_perimeter_profile.profile[0].id
  resource_id                           = var.storage_account_tfstate.exists ? (
                                                     data.azurerm_storage_account.storage_tfstate[0].id) : (
                                                     try(azurerm_storage_account.storage_tfstate[0].id, "")
                                                   )
}

resource "azurerm_network_security_perimeter_association" "storage_sapbits" {
  count                                  = var.deployer_tfstate.network_security_perimeter_deployment ? 1 : 0
  name                                   = var.storage_account_sapbits.exists ? (
                                                     data.azurerm_storage_account.storage_sapbits[0].name) : (
                                                     try(azurerm_storage_account.storage_sapbits[0].name, "")
                                                   )
  access_mode                            = "Enforced"

  network_security_perimeter_profile_id = data.azurerm_network_security_perimeter_profile.profile[0].id
  resource_id                           = var.storage_account_sapbits.exists ? (
                                                     data.azurerm_storage_account.storage_sapbits[0].id) : (
                                                     try(azurerm_storage_account.storage_sapbits[0].id, "")
                                                   )
}

locals {
  parsed_network_security_id           = var.deployer_tfstate.network_security_perimeter_deployment ? try(provider::azurerm::parse_resource_id(var.deployer_tfstate.network_security_perimeter_id), "") : null
  network_security_name                = var.deployer_tfstate.network_security_perimeter_deployment ? local.parsed_network_security_id["resource_name"] : ""
  network_security_resource_group_name = var.deployer_tfstate.network_security_perimeter_deployment ? local.parsed_network_security_id["resource_group_name"] : ""

}
