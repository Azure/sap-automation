// Create private KV with access policy
data "azurerm_client_config" "deployer" {
  provider = azurerm.main
}

## Add an expiry date to the secrets
resource "time_offset" "secret_expiry_date" {
  offset_months = 12
}
// Create user KV with access policy
resource "azurerm_key_vault" "kv_user" {
  count                                = (var.key_vault.kv_exists) ? 0 : 1
  name                                 = local.keyvault_names.user_access
  resource_group_name                  = local.resource_group_exists ? (
                                           data.azurerm_resource_group.deployer[0].name) : (
                                           azurerm_resource_group.deployer[0].name
                                         )
  location                             = local.resource_group_exists ? (
                                           data.azurerm_resource_group.deployer[0].location) : (
                                           azurerm_resource_group.deployer[0].location
                                         )
  tenant_id                            = length(var.deployer.user_assigned_identity_id) == 0 ? azurerm_user_assigned_identity.deployer[0].tenant_id : data.azurerm_user_assigned_identity.deployer[0].tenant_id

  soft_delete_retention_days           = var.soft_delete_retention_days
  purge_protection_enabled             = var.enable_purge_control_for_keyvaults

  sku_name                             = "standard"

  public_network_access_enabled        = var.public_network_access_enabled


  dynamic "network_acls" {
                           for_each                     = range(!var.public_network_access_enabled ? 1 : 0)
                           content {

                              bypass                     = "AzureServices"
                              default_action             = var.enable_firewall_for_keyvaults_and_storage ? "Deny" : "Allow"

                              ip_rules                   = compact(
                                                            [
                                                              local.enable_deployer_public_ip ? (
                                                                azurerm_public_ip.deployer[0].ip_address) : (
                                                              ""),
                                                              length(var.Agent_IP) > 0 ? var.Agent_IP : ""
                                                            ]
                                                          )

                              virtual_network_subnet_ids = compact(local.management_subnet_exists ? (var.use_webapp ? (
                                                            flatten([data.azurerm_subnet.subnet_mgmt[0].id, data.azurerm_subnet.webapp[0].id, var.subnets_to_add])) : (
                                                            flatten([data.azurerm_subnet.subnet_mgmt[0].id, var.subnets_to_add]))
                                                            ) : (var.use_webapp ? (
                                                              compact(flatten([azurerm_subnet.subnet_mgmt[0].id, try(azurerm_subnet.webapp[0].id, null), var.subnets_to_add]))) : (
                                                              flatten([azurerm_subnet.subnet_mgmt[0].id, var.subnets_to_add])
                                                            )
                             ))
                           }
                         }

  lifecycle                        {
                                     ignore_changes = [network_acls]
                                   }

}


// Import an existing user Key Vault
data "azurerm_key_vault" "kv_user" {
  count                                = var.key_vault.kv_exists ? 1 : 0
  name                                 = split("/", var.key_vault.kv_user_id)[8]
  resource_group_name                  = split("/", var.key_vault.kv_user_id)[4]
}


// Using TF tls to generate SSH key pair and store in user KV
resource "tls_private_key" "deployer" {
  count                                = (
                                           local.enable_key
                                           && !local.key_exist
                                           && (try(file(var.authentication.path_to_public_key), "") == "")
                                         ) ? 1 : 0
  algorithm                            = "RSA"
  rsa_bits                             = 2048
}

resource "azurerm_key_vault_secret" "ppk" {
  count                                = (local.enable_key && !local.key_exist) ? 1 : 0
  name                                 = local.ppk_secret_name
  depends_on                           = [
                                           azurerm_key_vault_access_policy.kv_user_pre_deployer[0],
                                           azurerm_key_vault_access_policy.kv_user_msi,
                                           azurerm_key_vault_access_policy.kv_user_systemidentity
                                         ]
  value                                = local.private_key
  key_vault_id                         = var.key_vault.kv_exists ? (
                                           var.key_vault.kv_user_id) : (
                                           azurerm_key_vault.kv_user[0].id
                                         )

  expiration_date                      = var.set_secret_expiry ? (
                                           time_offset.secret_expiry_date.rfc3339) : (
                                           null
                                         )
}

resource "azurerm_key_vault_secret" "pk" {
  count                                = (local.enable_key && !local.key_exist) ? (
                                          (
                                            !var.bootstrap || !var.key_vault.kv_exists) ? (
                                            1) : (
                                            0
                                          )) : (
                                          0
                                        )
  depends_on                           = [
                                           azurerm_key_vault_access_policy.kv_user_pre_deployer[0],
                                           azurerm_key_vault_access_policy.kv_user_msi,
                                           azurerm_key_vault_access_policy.kv_user_systemidentity
                                         ]

  name                                 = local.pk_secret_name
  value                                = local.public_key
  key_vault_id                         = var.key_vault.kv_exists ? (
                                           var.key_vault.kv_user_id) : (
                                           azurerm_key_vault.kv_user[0].id
                                         )

  expiration_date                      = var.set_secret_expiry ? (
                                           time_offset.secret_expiry_date.rfc3339) : (
                                           null
                                         )
}

resource "azurerm_key_vault_secret" "username" {
  count                                = (local.enable_key && !local.key_exist) ? (
                                          (
                                            !var.bootstrap || !var.key_vault.kv_exists) ? (
                                            1) : (
                                            0
                                          )) : (
                                          0
                                        )
  depends_on                           = [
                                           azurerm_key_vault_access_policy.kv_user_pre_deployer[0],
                                           azurerm_key_vault_access_policy.kv_user_msi,
                                           azurerm_key_vault_access_policy.kv_user_systemidentity
                                         ]

  name                                 = local.username_secret_name
  value                                = local.username
  key_vault_id                         = var.key_vault.kv_exists ? (
                                           var.key_vault.kv_user_id) : (
                                           azurerm_key_vault.kv_user[0].id
                                         )

  expiration_date                      = var.set_secret_expiry ? (
                                           time_offset.secret_expiry_date.rfc3339) : (
                                           null
                                         )
}

resource "azurerm_key_vault_secret" "pat" {
  count                                = (local.enable_key && !local.key_exist) ? (
                                          (
                                            !var.bootstrap || !var.key_vault.kv_exists) ? (
                                            1) : (
                                            0
                                          )) : (
                                          0
                                        )
  depends_on                           = [
                                           azurerm_key_vault_access_policy.kv_user_pre_deployer[0],
                                           azurerm_key_vault_access_policy.kv_user_msi,
                                           azurerm_key_vault_access_policy.kv_user_systemidentity
                                         ]

  name                                 = "PAT"
  value                                = var.agent_pat
  key_vault_id                         = var.key_vault.kv_exists ? (
                                           var.key_vault.kv_user_id) : (
                                           azurerm_key_vault.kv_user[0].id
                                         )

  expiration_date                      = var.set_secret_expiry ? (
                                           time_offset.secret_expiry_date.rfc3339) : (
                                           null
                                         )
}

resource "azurerm_key_vault_secret" "web_pwd" {
  count                                = (local.enable_key && !local.key_exist) ? (
                                          (
                                            !var.bootstrap || !var.key_vault.kv_exists) ? (
                                            1) : (
                                            0
                                          )) : (
                                          0
                                        )
  depends_on                           = [
                                           azurerm_key_vault_access_policy.kv_user_pre_deployer[0],
                                           azurerm_key_vault_access_policy.kv_user_msi,
                                           azurerm_key_vault_access_policy.kv_user_systemidentity,
                                         ]

  name                                 = "WEB-PWD"
  value                                = var.webapp_client_secret
  key_vault_id                         = var.key_vault.kv_exists ? (
                                           var.key_vault.kv_user_id) : (
                                           azurerm_key_vault.kv_user[0].id
                                         )

  expiration_date                      = var.set_secret_expiry ? (
                                           time_offset.secret_expiry_date.rfc3339) : (
                                           null
                                         )
}

resource "azurerm_key_vault_secret" "pwd" {
  count                                = (local.enable_password && !local.pwd_exist) ? (
                                           (
                                             !var.bootstrap || !var.key_vault.kv_exists) ? (
                                             1) : (
                                             0
                                           )) : (
                                           0
                                         )

  depends_on                           = [
                                           azurerm_key_vault_access_policy.kv_user_pre_deployer[0],
                                           azurerm_key_vault_access_policy.kv_user_msi,
                                           azurerm_key_vault_access_policy.kv_user_systemidentity
                                         ]

  name                                 = local.pwd_secret_name
  value                                = local.password
  key_vault_id                         = var.key_vault.kv_exists ? (
                                           var.key_vault.kv_user_id) : (
                                           azurerm_key_vault.kv_user[0].id
                                         )

  expiration_date                      = var.set_secret_expiry ? (
                                           time_offset.secret_expiry_date.rfc3339) : (
                                           null
                                         )
}

data "azurerm_key_vault_secret" "pk" {
  count                                = (local.enable_key && local.key_exist) ? 1 : 0
  name                                 = local.pk_secret_name
  key_vault_id                         = var.key_vault.kv_user_id
}

data "azurerm_key_vault_secret" "ppk" {
  count                                = (local.enable_key && local.key_exist) ? 1 : 0
  name                                 = local.ppk_secret_name
  key_vault_id                         = var.key_vault.kv_user_id
}

data "azurerm_key_vault_secret" "username" {
  count                                = (local.username_exist) ? 1 : 0
  name                                 = local.username_secret_name
  key_vault_id                         = var.key_vault.kv_user_id
}

data "azurerm_key_vault_secret" "pwd" {
  count                                = (local.enable_password && local.pwd_exist) ? 1 : 0
  name                                 = local.pwd_secret_name
  key_vault_id                         = var.key_vault.kv_user_id
}


###############################################################################
#                                                                             #
#                         Policies and Additional Users                       #
#                                                                             #
###############################################################################

resource "azurerm_key_vault_access_policy" "kv_user_msi" {
  provider                             = azurerm.main

  key_vault_id                         = var.key_vault.kv_exists ? data.azurerm_key_vault.kv_user[0].id : azurerm_key_vault.kv_user[0].id
  tenant_id                            = length(var.deployer.user_assigned_identity_id) == 0 ? azurerm_user_assigned_identity.deployer[0].tenant_id : data.azurerm_user_assigned_identity.deployer[0].tenant_id
  object_id                            = length(var.deployer.user_assigned_identity_id) == 0 ? azurerm_user_assigned_identity.deployer[0].principal_id : data.azurerm_user_assigned_identity.deployer[0].principal_id


  secret_permissions                   = [
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

resource "azurerm_key_vault_access_policy" "kv_user_systemidentity" {
  provider                             = azurerm.main
  count                                = var.deployer.add_system_assigned_identity ? var.deployer_vm_count : 0

  key_vault_id                         = var.key_vault.kv_exists ? data.azurerm_key_vault.kv_user[0].id : azurerm_key_vault.kv_user[0].id
  tenant_id                            = azurerm_linux_virtual_machine.deployer[count.index].identity[0].tenant_id
  object_id                            = azurerm_linux_virtual_machine.deployer[count.index].identity[0].principal_id

  secret_permissions                   = [
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
  provider                             = azurerm.main
  count                                = var.key_vault.kv_exists && length(var.spn_id) > 0 ? 0 : 1

  key_vault_id                         = azurerm_key_vault.kv_user[0].id
  tenant_id                            = length(var.deployer.user_assigned_identity_id) == 0 ? azurerm_user_assigned_identity.deployer[0].tenant_id : data.azurerm_user_assigned_identity.deployer[0].tenant_id
  # If running as a normal user use the object ID of the user otherwise use the object_id from AAD
  object_id                            = coalesce(data.azurerm_client_config.deployer.object_id,
                                            var.spn_id,
                                            var.arm_client_id
                                          )
  #application_id = data.azurerm_client_config.deployer.client_id

  secret_permissions                   = [
                                           "Get",
                                           "List",
                                           "Set",
                                           "Delete",
                                           "Recover",
                                           "Backup",
                                           "Restore",
                                           "Purge"
                                         ]

  lifecycle {
    ignore_changes = [
      object_id
    ]
  }

}


resource "azurerm_key_vault_access_policy" "kv_user_additional_users" {
  provider                             = azurerm.main
  count                                = !var.key_vault.kv_exists && length(compact(var.additional_users_to_add_to_keyvault_policies)) > 0 ? (
                                           length(compact(var.additional_users_to_add_to_keyvault_policies))) : (
                                           0
                                         )
  key_vault_id                         = azurerm_key_vault.kv_user[0].id

  tenant_id                            = length(var.deployer.user_assigned_identity_id) == 0 ? azurerm_user_assigned_identity.deployer[0].tenant_id : data.azurerm_user_assigned_identity.deployer[0].tenant_id
  object_id                            = var.additional_users_to_add_to_keyvault_policies[count.index]
  secret_permissions                   = [
                                           "Get",
                                           "List",
                                           "Set",
                                           "Recover"
                                         ]


}

# resource "azurerm_key_vault_access_policy" "webapp" {
#   provider = azurerm.main
#   count = var.use_webapp ? 1 : 0

#   key_vault_id = var.key_vault.kv_exists ? (
#     var.key_vault.kv_user_id) : (
#     azurerm_key_vault.kv_user[0].id
#   )

#   tenant_id = azurerm_windows_web_app.webapp[0].identity[0].tenant_id
#   object_id = azurerm_windows_web_app.webapp[0].identity[0].principal_id
#   secret_permissions = [
#     "Get",
#     "List",
#     "Set",
#     "Recover"
#   ]

# }




resource "azurerm_management_lock" "keyvault" {
  provider                             = azurerm.main
  count                                = (var.key_vault.kv_exists) ? 0 : var.place_delete_lock_on_resources ? 1 : 0
  name                                 = format("%s-lock", local.keyvault_names.user_access)
  scope                                = azurerm_key_vault.kv_user[0].id
  lock_level                           = "CanNotDelete"
  notes                                = "Locked because it's needed by the Control Plane"
  lifecycle {
              prevent_destroy = false
            }
}

