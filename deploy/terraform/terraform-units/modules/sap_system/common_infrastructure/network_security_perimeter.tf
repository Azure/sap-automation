
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

resource "azurerm_network_security_perimeter_association" "sapmnt" {
  provider                               = azurerm.deployer
  count                                  = try(var.deployer_tfstate.network_security_perimeter_deployment, false) ? 1 : 0
  name                                   = length(var.azure_files_sapmnt_id) > 0 ? (
                                                     data.azurerm_storage_account.sapmnt[0].name) : (
                                                     try(azurerm_storage_account.sapmnt[0].name, "")
                                                   )
  access_mode                            = var.deployer_tfstate.network_security_access_mode

  network_security_perimeter_profile_id = data.azurerm_network_security_perimeter_profile.profile[0].id
  resource_id                           = length(var.azure_files_sapmnt_id) > 0 ? (
                                                     data.azurerm_storage_account.sapmnt[0].id) : (
                                                     try(azurerm_storage_account.sapmnt[0].id, "")
                                                   )
}

locals {
  parsed_network_security_id           = try(var.deployer_tfstate.network_security_perimeter_deployment, false) ? try(provider::azurerm::parse_resource_id(var.deployer_tfstate.network_security_perimeter_id), null) : null
  network_security_name                = try(var.deployer_tfstate.network_security_perimeter_deployment, false) ? try(local.parsed_network_security_id["resource_name"], "") : ""
  network_security_resource_group_name = try(var.deployer_tfstate.network_security_perimeter_deployment, false) ? try(local.parsed_network_security_id["resource_group_name"], "") : ""

}
