# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

// Create private KV with access policy
data "azurerm_client_config" "deployer" {
  provider = azurerm.main
}

## Add an expiry date to the secrets
resource "time_offset" "secret_expiry_date" {
  offset_months = 12
}

resource "time_sleep" "wait_for_keyvault" {
  create_duration                      = "120s"
}
// Create user KV with access policy
resource "azurerm_key_vault" "kv_user" {
  count                                = (var.key_vault.exists) ? 0 : 1
  name                                 = local.keyvault_names.user_access
  resource_group_name                  = var.infrastructure.resource_group.exists ? (
                                           data.azurerm_resource_group.deployer[0].name) : (
                                           azurerm_resource_group.deployer[0].name
                                         )
  location                             = var.infrastructure.resource_group.exists ? (
                                           data.azurerm_resource_group.deployer[0].location) : (
                                           azurerm_resource_group.deployer[0].location
                                         )
  tenant_id                            = length(var.deployer.user_assigned_identity_id) == 0 ? azurerm_user_assigned_identity.deployer[0].tenant_id : data.azurerm_user_assigned_identity.deployer[0].tenant_id
  soft_delete_retention_days           = var.soft_delete_retention_days
  purge_protection_enabled             = var.enable_purge_control_for_keyvaults
  sku_name                             = "standard"
  public_network_access_enabled        = var.bootstrap ? true : var.public_network_access_enabled
  enable_rbac_authorization            = var.key_vault.enable_rbac_authorization

  network_acls {
            bypass                     = "AzureServices"
            default_action             = var.bootstrap ? "Allow" : (var.enable_firewall_for_keyvaults_and_storage ? "Deny" : "Allow")
            ip_rules                   = compact(
                                          [
                                            local.enable_deployer_public_ip ? (
                                              azurerm_public_ip.deployer[0].ip_address) : (
                                            ""),
                                            length(var.Agent_IP) > 0 ? var.Agent_IP : ""
                                          ]
                                        )
            virtual_network_subnet_ids = compact(var.infrastructure.virtual_network.management.subnet_mgmt.exists ? (var.app_service.use ? (
                                          flatten([data.azurerm_subnet.subnet_mgmt[0].id, data.azurerm_subnet.webapp[0].id, var.subnets_to_add, var.additional_network_id])) : (
                                          flatten([data.azurerm_subnet.subnet_mgmt[0].id, var.subnets_to_add, var.additional_network_id]))
                                          ) : (var.app_service.use ? (
                                            compact(flatten([azurerm_subnet.subnet_mgmt[0].id, try(azurerm_subnet.webapp[0].id, null), var.subnets_to_add, var.additional_network_id]))) : (
                                            flatten([azurerm_subnet.subnet_mgmt[0].id, var.subnets_to_add, var.additional_network_id])
                                            )
                                          )
                                         )
          }

  lifecycle                        {
                                     ignore_changes = [network_acls]
                                   }
  tags                                 = var.infrastructure.tags

}


// Import an existing user Key Vault
data "azurerm_key_vault" "kv_user" {
  count                                = var.key_vault.exists ? 1 : 0
  name                                 = split("/", var.key_vault.id)[8]
  resource_group_name                  = split("/", var.key_vault.id)[4]
}


// Using TF tls to generate SSH key pair and store in user KV
resource "tls_private_key" "deployer" {
  count                                = (
                                           local.enable_key
                                           && length(var.key_vault.public_key_secret_name) == 0
                                           && (try(file(var.authentication.path_to_public_key), "") == "")
                                         ) ? 1 : 0
  algorithm                            = "RSA"
  rsa_bits                             = 2048
}

###############################################################################
#                                                                             #
#                         Policies and Additional Users                       #
#                                                                             #
###############################################################################

resource "azurerm_key_vault_access_policy" "kv_user_msi" {
  provider                             = azurerm.main
  count                                = !var.key_vault.enable_rbac_authorization ? 1 : 0
  key_vault_id                         = var.key_vault.exists ? data.azurerm_key_vault.kv_user[0].id : azurerm_key_vault.kv_user[0].id
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
  count                                = var.key_vault.enable_rbac_authorization || var.key_vault.exists ? 0 : var.deployer_vm_count

  key_vault_id                         = var.key_vault.exists ? data.azurerm_key_vault.kv_user[0].id : azurerm_key_vault.kv_user[0].id
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
  count                                = var.key_vault.enable_rbac_authorization || var.key_vault.exists ? 0 : length(var.spn_id) != 36 ? 0 : 1

  key_vault_id                         = azurerm_key_vault.kv_user[0].id
  tenant_id                            = length(var.deployer.user_assigned_identity_id) == 0 ? azurerm_user_assigned_identity.deployer[0].tenant_id : data.azurerm_user_assigned_identity.deployer[0].tenant_id
  # If running as a normal user use the object ID of the user otherwise use the object_id from AAD
  object_id                            = coalesce((length(var.spn_id) != 36 ? var.spn_id : ""),
                                            data.azurerm_client_config.deployer.object_id,
                                            (length(var.arm_client_id) != 36 ? var.arm_client_id : "")
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
  count                                = var.key_vault.enable_rbac_authorization || var.key_vault.exists ? 0 : length(var.spn_id) != 36 ? 0 : length(compact(var.additional_users_to_add_to_keyvault_policies))
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

resource "azurerm_key_vault_access_policy" "webapp" {
  provider                             = azurerm.main
  count                                = !var.key_vault.exists && !var.key_vault.enable_rbac_authorization && var.app_service.use ? 1 : 0

  key_vault_id                         = var.key_vault.exists ? data.azurerm_key_vault.kv_user[0].id : azurerm_key_vault.kv_user[0].id

  tenant_id                            = azurerm_windows_web_app.webapp[0].identity[0].tenant_id
  object_id                            = azurerm_windows_web_app.webapp[0].identity[0].principal_id
  secret_permissions                   = [
                                            "Get",
                                            "List",
                                            "Set",
                                            "Recover"
                                          ]

}




resource "azurerm_management_lock" "keyvault" {
  provider                             = azurerm.main
  count                                = (var.key_vault.exists) ? 0 : var.place_delete_lock_on_resources ? 1 : 0
  name                                 = format("%s-lock", local.keyvault_names.user_access)
  scope                                = azurerm_key_vault.kv_user[0].id
  lock_level                           = "CanNotDelete"
  notes                                = "Locked because it's needed by the Control Plane"
  lifecycle {
              prevent_destroy = false
            }
}

resource "azurerm_key_vault_secret" "subscription" {
  count                                = !var.key_vault.exists ? (1) : (0)

  depends_on                           = [
                                           azurerm_key_vault_access_policy.kv_user_pre_deployer[0],
                                           azurerm_key_vault_access_policy.kv_user_msi,
                                           azurerm_key_vault_access_policy.kv_user_additional_users,
                                           azurerm_role_assignment.role_assignment_msi,
                                           azurerm_virtual_network_peering.peering_management_agent,
                                           azurerm_private_endpoint.kv_user
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
}
resource "azurerm_key_vault_secret" "ppk" {
  count                                = (local.enable_key && length(var.key_vault.private_key_secret_name) == 0 && !var.key_vault.exists ) ? 1 : 0
  depends_on                           = [
                                           azurerm_key_vault_access_policy.kv_user_pre_deployer[0],
                                           azurerm_key_vault_access_policy.kv_user_msi,
                                           azurerm_key_vault_access_policy.kv_user_additional_users,
                                           azurerm_role_assignment.role_assignment_msi,
                                           azurerm_virtual_network_peering.peering_management_agent,
                                           azurerm_private_endpoint.kv_user
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
}

resource "azurerm_key_vault_secret" "pk" {
  count                                = local.enable_key && (length(var.key_vault.public_key_secret_name)  == 0 ) && !var.key_vault.exists ? 1 : 0
  depends_on                           = [
                                           azurerm_key_vault_access_policy.kv_user_pre_deployer[0],
                                           azurerm_key_vault_access_policy.kv_user_msi,
                                           azurerm_key_vault_access_policy.kv_user_additional_users,
                                           azurerm_role_assignment.role_assignment_msi,
                                           azurerm_virtual_network_peering.peering_management_agent,
                                           azurerm_private_endpoint.kv_user
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
}
resource "azurerm_key_vault_secret" "username" {
  count                                = local.enable_key && (length(var.key_vault.username_secret_name) == 0 ) && !var.key_vault.exists ? 1 : 0
  depends_on                           = [
                                           azurerm_key_vault_access_policy.kv_user_pre_deployer[0],
                                           azurerm_key_vault_access_policy.kv_user_msi,
                                           azurerm_key_vault_access_policy.kv_user_additional_users,
                                           azurerm_role_assignment.role_assignment_msi,
                                           azurerm_virtual_network_peering.peering_management_agent,
                                           azurerm_private_endpoint.kv_user
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
}

resource "azurerm_key_vault_secret" "pat" {
  count                                = local.enable_key && (length(var.agent_pat)> 0 ) && !var.key_vault.exists  ? 1 : 0

  depends_on                           = [
                                           azurerm_key_vault_access_policy.kv_user_pre_deployer[0],
                                           azurerm_key_vault_access_policy.kv_user_msi,
                                           azurerm_key_vault_access_policy.kv_user_additional_users,
                                           azurerm_role_assignment.role_assignment_msi,
                                           azurerm_virtual_network_peering.peering_management_agent,
                                           azurerm_private_endpoint.kv_user
                                         ]
  name                                 = "PAT"
  value                                = var.agent_pat
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
}

# resource "azurerm_key_vault_secret" "web_pwd" {
#   count                                = (local.enable_key && !local.key_exist) ? (
#                                           (
#                                             !var.bootstrap || !var.key_vault.exists) ? (
#                                             1) : (
#                                             0
#                                           )) : (
#                                           0
#                                         )
#   depends_on                           = [
#                                            azurerm_key_vault_access_policy.kv_user_pre_deployer[0],
#                                            azurerm_key_vault_access_policy.kv_user_msi,
#                                            azurerm_key_vault_access_policy.kv_user_systemidentity,
#                                          ]

#   name                                 = "WEB-PWD"
#   value                                = var.webapp_client_secret
#   key_vault_id                         = var.key_vault.exists ? (
#                                            var.key_vault.id) : (
#                                            azurerm_key_vault.kv_user[0].id
#                                          )

#   expiration_date                      = var.set_secret_expiry ? (
#                                            time_offset.secret_expiry_date.rfc3339) : (
#                                            null
#                                          )
# }

resource "azurerm_key_vault_secret" "pwd" {
  count                                = local.enable_password && (length(var.key_vault.username_secret_name) == 0 ) && !var.key_vault.exists  ? 1 : 0
  depends_on                           = [
                                           azurerm_key_vault_access_policy.kv_user_pre_deployer[0],
                                           azurerm_key_vault_access_policy.kv_user_msi,
                                           azurerm_key_vault_access_policy.kv_user_additional_users,
                                           azurerm_role_assignment.role_assignment_msi,
                                           azurerm_virtual_network_peering.peering_management_agent,
                                           azurerm_private_endpoint.kv_user
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
}


#######################################4#######################################8
#                                                                              #
#                           Azure Key Vault endpoints                          #
#                                                                              #
#######################################4#######################################8


resource "azurerm_private_endpoint" "kv_user" {
  provider                             = azurerm.main
  count                                = !var.bootstrap && var.use_private_endpoint ? 1 : 0
  name                                 = format("%s%s%s",
                                          var.naming.resource_prefixes.keyvault_private_link,
                                          local.prefix,
                                          var.naming.resource_suffixes.keyvault_private_link
                                        )
  resource_group_name                  = var.infrastructure.resource_group.exists ? (
                                           data.azurerm_resource_group.deployer[0].name) : (
                                           azurerm_resource_group.deployer[0].name
                                         )
  location                             = var.infrastructure.resource_group.exists ? (
                                           data.azurerm_resource_group.deployer[0].location) : (
                                           azurerm_resource_group.deployer[0].location
                                         )
  subnet_id                            = var.infrastructure.virtual_network.management.subnet_mgmt.exists ? (
                                           data.azurerm_subnet.subnet_mgmt[0].id) : (
                                           azurerm_subnet.subnet_mgmt[0].id
                                                                          )
  custom_network_interface_name        = format("%s%s%s%s",
                                           var.naming.resource_prefixes.keyvault_private_link,
                                           local.prefix,
                                           var.naming.resource_suffixes.keyvault_private_link,
                                           var.naming.resource_suffixes.nic
                                         )

  private_service_connection {
                               name                           = format("%s%s%s",
                                                                  var.naming.resource_prefixes.keyvault_private_svc,
                                                                  local.prefix,
                                                                  var.naming.resource_suffixes.keyvault_private_svc
                                                                )
                               is_manual_connection           = false
                               private_connection_resource_id = var.key_vault.exists ? data.azurerm_key_vault.kv_user[0].id : azurerm_key_vault.kv_user[0].id
                               subresource_names              = [
                                                                  "Vault"
                                                                ]
                             }

  dynamic "private_dns_zone_group" {
                                     for_each = range(var.dns_settings.register_storage_accounts_keyvaults_with_dns ? 1 : 0)
                                     content {
                                               name                 = var.dns_settings.dns_zone_names.vault_dns_zone_name
                                               private_dns_zone_ids = [data.azurerm_private_dns_zone.vault[0].id]
                                             }
                                   }
  tags                                 = var.infrastructure.tags

}


data "azurerm_private_dns_zone" "vault" {
  provider                             = azurerm.privatelinkdnsmanagement
  count                                = !var.bootstrap && var.dns_settings.register_storage_accounts_keyvaults_with_dns ? 1 : 0
  name                                 = var.dns_settings.dns_zone_names.vault_dns_zone_name
  resource_group_name                  = coalesce(
                                           var.dns_settings.privatelink_dns_resourcegroup_name,
                                           var.dns_settings.management_dns_resourcegroup_name,
                                           var.dns_settings.local_dns_resourcegroup_name)

}
