resource "azurerm_key_vault_secret" "saplibrary_access_key" {
  provider = azurerm.deployer
  count    = length(var.key_vault.kv_spn_id) > 0 ? 1 : 0
  name     = "sapbits-access-key"
  value = local.sa_sapbits_exists ? (
    data.azurerm_storage_account.storage_sapbits[0].primary_access_key) : (
    azurerm_storage_account.storage_sapbits[0].primary_access_key
  )
  key_vault_id = var.key_vault.kv_spn_id
}

resource "azurerm_key_vault_secret" "sapbits_location_base_path" {
  provider = azurerm.deployer
  count    = length(var.key_vault.kv_spn_id) > 0 ? 1 : 0
  name     = "sapbits-location-base-path"
  value = var.storage_account_sapbits.sapbits_blob_container.is_existing ? (
    data.azurerm_storage_container.storagecontainer_sapbits[0].id) : (
    azurerm_storage_container.storagecontainer_sapbits[0].id
  )
  key_vault_id = var.key_vault.kv_spn_id
}
