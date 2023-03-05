
data "azurerm_key_vault_secret" "subscription_id" {
  count        = length(var.deployer_kv_user_arm_id) > 0 ? 1 : 0
  name         = format("%s-subscription-id", upper(local.infrastructure.environment))
  key_vault_id = var.deployer_kv_user_arm_id
}

data "azurerm_key_vault_secret" "client_id" {
  count        = length(var.deployer_kv_user_arm_id) > 0 ? 1 : 0
  name         = format("%s-client-id", upper(local.infrastructure.environment))
  key_vault_id = var.deployer_kv_user_arm_id
}

data "azurerm_key_vault_secret" "client_secret" {
  count        = length(var.deployer_kv_user_arm_id) > 0 ? 1 : 0
  name         = format("%s-client-secret", upper(local.infrastructure.environment))
  key_vault_id = var.deployer_kv_user_arm_id
}

data "azurerm_key_vault_secret" "tenant_id" {
  count        = length(var.deployer_kv_user_arm_id) > 0 ? 1 : 0
  name         = format("%s-tenant-id", upper(local.infrastructure.environment))
  key_vault_id = var.deployer_kv_user_arm_id
}

// Import current service principal
data "azuread_service_principal" "sp" {
  count        = length(var.deployer_kv_user_arm_id) > 0 ? 1 : 0
  application_id = local.spn.client_id
}
