data "azurerm_key_vault_secret" "subscription_id" {
  name         = format("%s-subscription-id", upper(local.infrastructure.environment))
  key_vault_id = var.key_vault.kv_exists ? var.key_vault.kv_user_id : azurerm_key_vault.kv_user[0].id
}

data "azurerm_key_vault_secret" "client_id" {
  name         = format("%s-client-id", upper(local.infrastructure.environment))
  key_vault_id = var.key_vault.kv_exists ? var.key_vault.kv_user_id : azurerm_key_vault.kv_user[0].id
}

data "azurerm_key_vault_secret" "client_secret" {
  name         = format("%s-client-secret", upper(local.infrastructure.environment))
  key_vault_id = var.key_vault.kv_exists ? var.key_vault.kv_user_id : azurerm_key_vault.kv_user[0].id
}

data "azurerm_key_vault_secret" "tenant_id" {
  name         = format("%s-tenant-id", upper(local.infrastructure.environment))
  key_vault_id = var.key_vault.kv_exists ? var.key_vault.kv_user_id : azurerm_key_vault.kv_user[0].id
}

// Import current service principal
data "azuread_service_principal" "sp" {
  application_id = local.spn.client_id
}
