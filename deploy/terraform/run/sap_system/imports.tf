/*
    Description:
    Retrieve remote tfstate file(s) and current environment's SPN
*/


data "azurerm_client_config" "current" {
}

data "terraform_remote_state" "deployer" {
  backend = "azurerm"
  count   = length(try(var.deployer_tfstate_key, "")) > 1 ? 1 : 0
  config = {
    resource_group_name  = local.saplib_resource_group_name
    storage_account_name = local.tfstate_storage_account_name
    container_name       = local.tfstate_container_name
    key                  = try(var.deployer_tfstate_key, "")
    subscription_id      = local.saplib_subscription_id
  }
}

data "terraform_remote_state" "landscape" {
  backend = "azurerm"
  config = {
    resource_group_name  = local.saplib_resource_group_name
    storage_account_name = local.tfstate_storage_account_name
    container_name       = "tfstate"
    key                  = var.landscape_tfstate_key
    subscription_id      = local.saplib_subscription_id
  }
}

data "azurerm_key_vault_secret" "subscription_id" {
  name         = format("%s-subscription-id", local.environment)
  key_vault_id = local.spn_key_vault_arm_id
}

data "azurerm_key_vault_secret" "client_id" {
  count        = var.use_spn ? 1 : 0
  name         = format("%s-client-id", local.environment)
  key_vault_id = local.spn_key_vault_arm_id
}

data "azurerm_key_vault_secret" "client_secret" {
  count        = var.use_spn ? 1 : 0
  name         = format("%s-client-secret", local.environment)
  key_vault_id = local.spn_key_vault_arm_id
}

data "azurerm_key_vault_secret" "tenant_id" {
  count        = var.use_spn ? 1 : 0
  name         = format("%s-tenant-id", local.environment)
  key_vault_id = local.spn_key_vault_arm_id
}

// Import current service principal
data "azuread_service_principal" "sp" {
  count          = var.use_spn ? 1 : 0
  application_id = local.spn.client_id
}
