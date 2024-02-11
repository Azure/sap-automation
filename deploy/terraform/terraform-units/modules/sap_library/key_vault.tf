
#######################################4#######################################8
#                                                                              #
#                           Azure Key Vault secrets                            #
#                                                                              #
#######################################4#######################################8


## Add an expiry date to the secrets
resource "time_offset" "secret_expiry_date" {
  offset_months                        = 12
}

resource "azurerm_key_vault_secret" "saplibrary_access_key" {
  provider                             = azurerm.deployer

  count                                = length(var.key_vault.kv_spn_id) > 0  ? 1 : 0
  depends_on                           = [azurerm_private_endpoint.kv_user]
  name                                 = "sapbits-access-key"
  value                                = local.sa_sapbits_exists ? (
                                           data.azurerm_storage_account.storage_sapbits[0].primary_access_key) : (
                                           azurerm_storage_account.storage_sapbits[0].primary_access_key
                                         )
  key_vault_id                         = var.key_vault.kv_spn_id

  expiration_date                      = try(var.deployer_tfstate.set_secret_expiry, false) ? (
                                          time_offset.secret_expiry_date.rfc3339) : (
                                          null
                                        )

}

resource "azurerm_key_vault_secret" "sapbits_location_base_path" {
  provider                             = azurerm.deployer
  count                                = length(var.key_vault.kv_spn_id) > 0 ? 1 : 0
  depends_on                           = [azurerm_private_endpoint.kv_user]
  name                                 = "sapbits-location-base-path"
  value                                = var.storage_account_sapbits.sapbits_blob_container.is_existing ? (
                                          data.azurerm_storage_container.storagecontainer_sapbits[0].id) : (
                                          azurerm_storage_container.storagecontainer_sapbits[0].id
                                        )
  key_vault_id                         = var.key_vault.kv_spn_id
  expiration_date                      = try(var.deployer_tfstate.set_secret_expiry, false) ? (
                                           time_offset.secret_expiry_date.rfc3339) : (
                                           null
                                         )
}


resource "azurerm_key_vault_secret" "sa_connection_string" {
  provider                             = azurerm.deployer
  count                                = length(var.key_vault.kv_spn_id) > 0 ? 1 : 0
  depends_on                           = [azurerm_private_endpoint.kv_user]
  name                                 = "sa-connection-string"
  value                                = local.sa_tfstate_exists ? (
                                           data.azurerm_storage_account.storage_tfstate[0].primary_connection_string) : (
                                           azurerm_storage_account.storage_tfstate[0].primary_connection_string
                                         )
  key_vault_id                         = var.key_vault.kv_spn_id
  expiration_date                      = try(var.deployer_tfstate.set_secret_expiry, false) ? (
                                           time_offset.secret_expiry_date.rfc3339) : (
                                           null
                                         )
}

resource "azurerm_key_vault_secret" "tfstate" {
  provider                             = azurerm.deployer
  count                                = length(var.key_vault.kv_spn_id) > 0 ? 1 : 0
  depends_on                           = [azurerm_private_endpoint.kv_user]
  name                                 = "tfstate"
  value                                = var.use_private_endpoint ? (
                                          format("https://%s.blob.core.windows.net", local.sa_tfstate_exists ? (data.azurerm_storage_account.storage_tfstate[0].name) : (azurerm_storage_account.storage_tfstate[0].name))) : (
                                          format("https://%s.blob.core.windows.net", local.sa_tfstate_exists ? (data.azurerm_storage_account.storage_tfstate[0].name) : (azurerm_storage_account.storage_tfstate[0].name))
                                          )
  key_vault_id                         = var.key_vault.kv_spn_id
  expiration_date                      = try(var.deployer_tfstate.set_secret_expiry, false) ? (
                                           time_offset.secret_expiry_date.rfc3339) : (
                                           null
                                         )
}



resource "azurerm_private_dns_a_record" "kv_user" {
  provider                             = azurerm.deployer
  count                                = var.use_private_endpoint && var.use_custom_dns_a_registration ? 1 : 0
  name                                 = lower(split("/", var.key_vault.kv_spn_id)[8])
  zone_name                            = var.dns_zone_names.vault_dns_zone_name
  resource_group_name                  = var.management_dns_resourcegroup_name
  ttl                                  = 3600
  records                              = [azurerm_private_endpoint.kv_user[0].private_service_connection[0].private_ip_address]

  lifecycle {
    ignore_changes = [tags]
  }
}

