resource "azurerm_key_vault_secret" "subscription" {
  count                                = !var.key_vault.exists ? (1) : (0)
  depends_on                           = [
                                           time_sleep.wait_for_keyvault
                                         ]
  name                                 = format("%s-subscription-id", upper(var.naming.prefix.DEPLOYER))
  value                                = data.azurerm_client_config.deployer.subscription_id
  key_vault_id                         = var.key_vault.exists ? (
                                           var.key_vault.id) : (
                                           azurerm_key_vault.kv_user[0].id
                                         )

  expiration_date                      = var.set_secret_expiry ? (
                                           time_offset.secret_expiry_date.rfc3339) : (
                                           null
                                         )
  tags                                 = var.infrastructure.tags
  lifecycle {
    ignore_changes = [ expiration_date]
  }
}

resource "azurerm_key_vault_secret" "tenant" {
  count                                = !var.key_vault.exists ? (1) : (0)
  depends_on                           = [
                                           time_sleep.wait_for_keyvault
                                         ]
  name                                 = format("%s-tenant-id", upper(var.naming.prefix.DEPLOYER))
  value                                = data.azurerm_client_config.deployer.tenant_id
  key_vault_id                         = var.key_vault.exists ? (
                                           var.key_vault.id) : (
                                           azurerm_key_vault.kv_user[0].id
                                         )

  expiration_date                      = var.set_secret_expiry ? (
                                           time_offset.secret_expiry_date.rfc3339) : (
                                           null
                                         )
  tags                                 = var.infrastructure.tags
  lifecycle {
    ignore_changes = [ expiration_date]
  }
}

resource "azurerm_key_vault_secret" "ppk" {
  count                                = (local.enable_key && length(var.key_vault.private_key_secret_name) == 0 && !var.key_vault.exists ) ? 1 : 0
  depends_on                           = [
                                           time_sleep.wait_for_keyvault
                                         ]
  name                                 = local.private_key_secret_name
  value                                = local.private_key
  key_vault_id                         = var.key_vault.exists ? (
                                           var.key_vault.id) : (
                                           azurerm_key_vault.kv_user[0].id
                                         )

  expiration_date                      = var.set_secret_expiry ? (
                                           time_offset.secret_expiry_date.rfc3339) : (
                                           null
                                         )
  content_type                         = "secret"
  tags                                 = var.infrastructure.tags
  lifecycle {
    ignore_changes = [ expiration_date]
  }
}

resource "azurerm_key_vault_secret" "pk" {
  count                                = local.enable_key && (length(var.key_vault.public_key_secret_name)  == 0 ) && !var.key_vault.exists ? 1 : 0
  depends_on                           = [
                                           time_sleep.wait_for_keyvault
                                         ]
  name                                 = local.public_key_secret_name
  value                                = local.public_key
  key_vault_id                         = var.key_vault.exists ? (
                                           var.key_vault.id) : (
                                           azurerm_key_vault.kv_user[0].id
                                         )

  expiration_date                      = var.set_secret_expiry ? (
                                           time_offset.secret_expiry_date.rfc3339) : (
                                           null
                                         )
  content_type                         = "secret"
  tags                                 = var.infrastructure.tags

  lifecycle {
    ignore_changes = [ expiration_date]
  }
}
resource "azurerm_key_vault_secret" "username" {
  count                                = local.enable_key && (length(var.key_vault.username_secret_name) == 0 ) && !var.key_vault.exists ? 1 : 0
  depends_on                           = [
                                           time_sleep.wait_for_keyvault
                                         ]
  name                                 = local.username_secret_name
  value                                = try(var.authentication.username, "azureadm")
  key_vault_id                         = var.key_vault.exists ? (
                                           var.key_vault.id) : (
                                           azurerm_key_vault.kv_user[0].id
                                         )

  expiration_date                      = var.set_secret_expiry ? (
                                           time_offset.secret_expiry_date.rfc3339) : (
                                           null
                                         )
  content_type                         = "configuration"
  tags                                 = var.infrastructure.tags
  lifecycle {
    ignore_changes = [ expiration_date]
  }
}

resource "azurerm_key_vault_secret" "pwd" {
  count                                = local.enable_password && (length(var.key_vault.username_secret_name) == 0 ) && !var.key_vault.exists  ? 1 : 0
  depends_on                           = [
                                           time_sleep.wait_for_keyvault
                                         ]
  name                                 = local.pwd_secret_name
  value                                = local.password
  key_vault_id                         = var.key_vault.exists ? (
                                           var.key_vault.id) : (
                                           azurerm_key_vault.kv_user[0].id
                                         )

  expiration_date                      = var.set_secret_expiry ? (
                                           time_offset.secret_expiry_date.rfc3339) : (
                                           null
                                         )
  content_type                         = "secret"
  tags                                 = var.infrastructure.tags
  lifecycle {
    ignore_changes = [ expiration_date]
  }
}


resource "azurerm_key_vault_secret" "pat" {
  count                                = local.enable_key && (length(coalesce(var.infrastructure.devops.agent_pat, var.infrastructure.devops.devops.app_token, " ")) > 1) && !var.key_vault.exists  ? 1 : 0
  name                                 = "PAT"
  value                                = coalesce(var.infrastructure.devops.agent_pat, var.infrastructure.devops.app_token)
  key_vault_id                         = var.key_vault.exists ? (
                                           var.key_vault.id) : (
                                           azurerm_key_vault.kv_user[0].id
                                         )

  expiration_date                      = var.set_secret_expiry ? (
                                           time_offset.secret_expiry_date.rfc3339) : (
                                           null
                                         )
  content_type                         = "secret"
  tags                                 = var.infrastructure.tags
  lifecycle {
    ignore_changes = [ expiration_date]
  }
}

