// Create private KV with access policy
data "azurerm_client_config" "deployer" {}


// Create user KV with access policy
resource "azurerm_key_vault" "kv_user" {
  count = (!local.user_keyvault_exist) ? 1 : 0
  name  = local.keyvault_names.user_access
  resource_group_name = local.resource_group_exists ? (
    data.azurerm_resource_group.deployer[0].name) : (
    azurerm_resource_group.deployer[0].name
  )
  location = local.resource_group_exists ? (
    data.azurerm_resource_group.deployer[0].location) : (
    azurerm_resource_group.deployer[0].location
  )
  tenant_id                  = azurerm_user_assigned_identity.deployer.tenant_id
  soft_delete_retention_days = 7
  purge_protection_enabled   = var.enable_purge_control_for_keyvaults

  sku_name = "standard"

  network_acls {
    bypass         = "AzureServices"
    default_action = "Allow"
    ip_rules = var.use_private_endpoint ? (
      [
        local.enable_deployer_public_ip ? azurerm_public_ip.deployer[0].ip_address : ""
      ]
      ) : (
      [
        
      ]
    )
    virtual_network_subnet_ids = [
      local.management_subnet_exists ? (
        data.azurerm_subnet.subnet_mgmt[0].id) : (
        azurerm_subnet.subnet_mgmt[0].id
      )
    ]
  }

}

// Import an existing user Key Vault
data "azurerm_key_vault" "kv_user" {
  count               = (local.user_keyvault_exist) ? 1 : 0
  name                = split("/", local.user_key_vault_id)[8]
  resource_group_name = split("/", local.user_key_vault_id)[4]
}

resource "azurerm_key_vault_access_policy" "kv_user_msi" {
  count = (!local.user_keyvault_exist) ? 1 : 0

  key_vault_id = azurerm_key_vault.kv_user[0].id

  tenant_id = azurerm_user_assigned_identity.deployer.tenant_id
  object_id = azurerm_user_assigned_identity.deployer.principal_id

  secret_permissions = [
    "Get",
    "List",
    "Set",
    "Delete",
    "Recover",
    "Backup",
    "Restore",
    "Purge"
  ]
}

resource "azurerm_key_vault_access_policy" "kv_user_pre_deployer" {

  count        = (!local.user_keyvault_exist) ? 1 : 0
  key_vault_id = azurerm_key_vault.kv_user[0].id

  tenant_id = azurerm_user_assigned_identity.deployer.tenant_id
  # If running as a normal user use the object ID of the user otherwise use the object_id from AAD
  object_id = coalesce(
    data.azurerm_client_config.deployer.object_id,
    data.azurerm_client_config.deployer.client_id,
    var.arm_client_id
  )
  #application_id = data.azurerm_client_config.deployer.client_id

  secret_permissions = [
    "Get",
    "List",
    "Set",
    "Delete",
    "Recover",
    "Backup",
    "Restore",
    "Purge"
  ]

}

// Using TF tls to generate SSH key pair and store in user KV
resource "tls_private_key" "deployer" {
  count = (
    local.enable_key
    && !local.key_exist
    && (try(file(var.authentication.path_to_public_key), "") == "")
  ) ? 1 : 0
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "azurerm_key_vault_secret" "ppk" {
  depends_on = [
    azurerm_key_vault_access_policy.kv_user_pre_deployer[0],
    azurerm_key_vault_access_policy.kv_user_msi[0]
  ]
  count        = (local.enable_key && !local.key_exist) ? 1 : 0
  name         = local.ppk_secret_name
  value        = local.private_key
  key_vault_id = local.user_keyvault_exist ? local.user_key_vault_id : azurerm_key_vault.kv_user[0].id
}

resource "azurerm_key_vault_secret" "pk" {
  depends_on = [
    azurerm_key_vault_access_policy.kv_user_pre_deployer[0],
    azurerm_key_vault_access_policy.kv_user_msi[0]
  ]
  count        = (local.enable_key && !local.key_exist) ? 1 : 0
  name         = local.pk_secret_name
  value        = local.public_key
  key_vault_id = local.user_keyvault_exist ? local.user_key_vault_id : azurerm_key_vault.kv_user[0].id
}

resource "azurerm_key_vault_secret" "username" {
  depends_on = [
    azurerm_key_vault_access_policy.kv_user_pre_deployer[0],
    azurerm_key_vault_access_policy.kv_user_msi[0]
  ]
  count        = (!local.username_exist) ? 1 : 0
  name         = local.username_secret_name
  value        = local.username
  key_vault_id = local.user_keyvault_exist ? local.user_key_vault_id : azurerm_key_vault.kv_user[0].id
}

// Generate random password if password is set as authentication type, and save in KV
resource "random_password" "deployer" {
  count = (
    local.enable_password
    && !local.pwd_exist
    && try(var.authentication.password, "") == ""
  ) ? 1 : 0

  length           = 32
  min_upper        = 2
  min_lower        = 2
  min_numeric      = 2
  special          = true
  override_special = "_%@"
}

resource "azurerm_key_vault_secret" "pwd" {
  depends_on = [
    azurerm_key_vault_access_policy.kv_user_pre_deployer[0],
    azurerm_key_vault_access_policy.kv_user_msi[0]
  ]
  count = (local.enable_password && !local.pwd_exist) ? 1 : 0
  name  = local.pwd_secret_name
  value = local.password
  key_vault_id = local.user_keyvault_exist ? (
    local.user_key_vault_id) : (
    azurerm_key_vault.kv_user[0].id
  )
}

data "azurerm_key_vault_secret" "pk" {
  count        = (local.enable_key && local.key_exist) ? 1 : 0
  name         = local.pk_secret_name
  key_vault_id = local.user_key_vault_id
}

data "azurerm_key_vault_secret" "ppk" {
  count        = (local.enable_key && local.key_exist) ? 1 : 0
  name         = local.ppk_secret_name
  key_vault_id = local.user_key_vault_id
}

data "azurerm_key_vault_secret" "username" {
  count        = (local.username_exist) ? 1 : 0
  name         = local.username_secret_name
  key_vault_id = local.user_key_vault_id
}

data "azurerm_key_vault_secret" "pwd" {
  count        = (local.enable_password && local.pwd_exist) ? 1 : 0
  name         = local.pwd_secret_name
  key_vault_id = local.user_key_vault_id
}


resource "azurerm_private_endpoint" "kv_user" {
  count = var.use_private_endpoint && !local.user_keyvault_exist ? 1 : 0
  name = format("%s%s%s",
    var.naming.resource_prefixes.keyvault_private_link,
    local.prefix,
    local.resource_suffixes.keyvault_private_link
  )
  resource_group_name = local.resource_group_exists ? (
    data.azurerm_resource_group.deployer[0].name) : (
    azurerm_resource_group.deployer[0].name
  )
  location = local.resource_group_exists ? (
    data.azurerm_resource_group.deployer[0].location) : (
    azurerm_resource_group.deployer[0].location
  )
  subnet_id = local.management_subnet_exists ? (
    data.azurerm_subnet.subnet_mgmt[0].id) : (
    azurerm_subnet.subnet_mgmt[0].id
  )

  private_service_connection {
    name = format("%s%s%s",
      var.naming.resource_prefixes.keyvault_private_svc,
      local.prefix,
      local.resource_suffixes.keyvault_private_svc
    )
    is_manual_connection = false
    private_connection_resource_id = local.user_keyvault_exist ? (
      data.azurerm_key_vault.kv_user[0].id) : (
      azurerm_key_vault.kv_user[0].id
    )
    subresource_names = [
      "Vault"
    ]
  }
}
