
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

resource "azurerm_network_security_perimeter_association" "witness_storage" {
  provider                               = azurerm.deployer
  count                                  = try(var.deployer_tfstate.network_security_perimeter_deployment, false) ? 1 : 0
  name                                   = length(var.witness_storage_account.id) > 0 ? (
                                                     data.azurerm_storage_account.witness_storage[0].name) : (
                                                     try(azurerm_storage_account.witness_storage[0].name, "")
                                                   )
  access_mode                            = var.deployer_tfstate.network_security_access_mode

  network_security_perimeter_profile_id = data.azurerm_network_security_perimeter_profile.profile[0].id
  resource_id                           = length(var.witness_storage_account.id) > 0 ? (
                                                     data.azurerm_storage_account.witness_storage[0].id) : (
                                                     try(azurerm_storage_account.witness_storage[0].id, "")
                                                   )
}

resource "azurerm_network_security_perimeter_association" "transport" {
  provider                               = azurerm.deployer
  count                                  = try(var.deployer_tfstate.network_security_perimeter_deployment, false) ? 1 : 0
  name                                   = var.create_transport_storage && local.use_AFS_for_shared && length(var.transport_storage_account_id) == 0 ? (
                                                     azurerm_storage_account.transport[0].name) : (
                                                     try(data.azurerm_storage_account.transport[0].name, "")
                                                   )
  access_mode                            = var.deployer_tfstate.network_security_access_mode

  network_security_perimeter_profile_id = data.azurerm_network_security_perimeter_profile.profile[0].id
  resource_id                           = var.create_transport_storage && local.use_AFS_for_shared && length(var.transport_storage_account_id) == 0 ? (
                                                     azurerm_storage_account.transport[0].id) : (
                                                     try(data.azurerm_storage_account.transport[0].id, "")
                                                   )
}

resource "azurerm_network_security_perimeter_association" "install" {
  provider                               = azurerm.deployer
  count                                  = try(var.deployer_tfstate.network_security_perimeter_deployment, false) ? 1 : 0
  name                                   = local.use_AFS_for_shared && length(var.install_storage_account_id) == 0 ? (
                                                     azurerm_storage_account.install[0].name) : (
                                                     try(data.azurerm_storage_account.install[0].name, "")
                                                   )
  access_mode                            = var.deployer_tfstate.network_security_access_mode

  network_security_perimeter_profile_id = data.azurerm_network_security_perimeter_profile.profile[0].id
  resource_id                           = local.use_AFS_for_shared && length(var.install_storage_account_id) == 0 ? (
                                                     azurerm_storage_account.install[0].id) : (
                                                     try(data.azurerm_storage_account.install[0].id, "")
                                                   )
}

resource "azurerm_network_security_perimeter_association" "kv_user" {
  provider                               = azurerm.deployer
  count                                  = try(var.deployer_tfstate.network_security_perimeter_deployment, false) ? 1 : 0
  name                                   = var.key_vault.user.exists ? (
                                                     data.azurerm_key_vault.kv_user[0].name) : (
                                                     azurerm_key_vault.kv_user[0].name
                                                   )
  access_mode                            = var.deployer_tfstate.network_security_access_mode

  network_security_perimeter_profile_id = data.azurerm_network_security_perimeter_profile.profile[0].id
  resource_id                           = var.key_vault.user.exists ? (
                                                     data.azurerm_key_vault.kv_user[0].id) : (
                                                     azurerm_key_vault.kv_user[0].id
                                                   )
}



locals {
  parsed_network_security_id           = try(var.deployer_tfstate.network_security_perimeter_deployment, false) ? try(provider::azurerm::parse_resource_id(var.deployer_tfstate.network_security_perimeter_id), null) : null
  network_security_name                = try(local.parsed_network_security_id["resource_name"], "")
  network_security_resource_group_name = try(local.parsed_network_security_id["resource_group_name"], "")

}
