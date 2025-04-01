# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

data "azuread_client_config" "current" {}


#######################################4#######################################8
#                                                                              #
#                            Workload zone key vault                           #
#                                                                             #
#######################################4#######################################8

// Create user KV with access policy
resource "azurerm_key_vault" "kv_user" {
  provider                             = azurerm.main
  count                                = (var.key_vault.exists) ? 0 : 1
  depends_on                           = [
                                           azurerm_virtual_network_peering.peering_management_sap,
                                           azurerm_virtual_network_peering.peering_sap_management,
                                           azurerm_virtual_network_peering.peering_additional_network_sap,
                                           azurerm_virtual_network_peering.peering_sap_additional_network,
                                         ]
  name                                 = local.user_keyvault_name
  location                             = local.region
  resource_group_name                  = local.resource_group_exists ? (
                                           data.azurerm_resource_group.resource_group[0].name) : (
                                           azurerm_resource_group.resource_group[0].name
                                         )
  tenant_id                            = local.service_principal.tenant_id
  soft_delete_retention_days           = var.soft_delete_retention_days
  purge_protection_enabled             = var.enable_purge_control_for_keyvaults
  sku_name                             = "standard"
  enable_rbac_authorization            = var.enable_rbac_authorization_for_keyvault

  public_network_access_enabled        = var.public_network_access_enabled
  tags                                 = var.tags

  network_acls {
                        bypass         = "AzureServices"
                        default_action = var.enable_firewall_for_keyvaults_and_storage ? "Deny" : "Allow"
                        ip_rules       = compact(
                                            [
                                              length(local.deployer_public_ip_address) > 0 ? local.deployer_public_ip_address : "",
                                              length(var.Agent_IP) > 0 ? var.Agent_IP : ""
                                            ]
                                          )
            virtual_network_subnet_ids = compact(
                                            [
                                              local.database_subnet_defined ? (
                                                local.database_subnet_existing ? var.infrastructure.virtual_networks.sap.subnet_db.arm_id : azurerm_subnet.db[0].id) : (
                                                ""
                                                ), local.application_subnet_defined ? (
                                                local.application_subnet_existing ? var.infrastructure.virtual_networks.sap.subnet_app.arm_id : azurerm_subnet.app[0].id) : (
                                                ""
                                              ),
                                              local.deployer_subnet_management_id,
                                              var.additional_network_id
                                            ]
                                          )
            }

  lifecycle {
    ignore_changes = [
      network_acls
    ]
  }

}

// Import an existing user Key Vault
data "azurerm_key_vault" "kv_user" {
  provider                             = azurerm.main
  count                                = var.key_vault.exists ? 1 : 0
  name                                 = local.user_keyvault_name
  resource_group_name                  = local.user_keyvault_resourcegroup_name
}


resource "azurerm_management_lock" "keyvault" {
  provider                             = azurerm.main
  count                                = var.key_vault.exists ? 0 : var.place_delete_lock_on_resources ? 1 : 0
  name                                 = format("%s-lock", local.user_keyvault_name)
  scope                                = azurerm_key_vault.kv_user[0].id
  lock_level                           = "CanNotDelete"
  notes                                = "Locked because it's needed by the Workload zone"

  lifecycle {
              prevent_destroy = false
            }
}

#######################################4#######################################8
#                                                                              #
#                  Workload zone key vault role assignments                    #
#                                                                              #
#######################################4#######################################8


resource "azurerm_role_assignment" "role_assignment_msi" {
  provider                             = azurerm.main
  count                                = var.enable_rbac_authorization_for_keyvault && length(try(var.deployer_tfstate.deployer_uai.principal_id, "")) > 0 ? 1 : 0
  scope                                = local.user_keyvault_exist ? (
                                           local.user_key_vault_id) : (
                                           azurerm_key_vault.kv_user[0].id
                                         )
  role_definition_name                 = "Key Vault Administrator"
  principal_id                         = var.deployer_tfstate.deployer_uai.principal_id
}

resource "azurerm_role_assignment" "role_assignment_spn" {
  provider                             = azurerm.main
  count                                = var.enable_rbac_authorization_for_keyvault && local.service_principal.object_id != "" && !var.options.use_spn ? 1 : 0
  scope                                = local.user_keyvault_exist ? (
                                                                       local.user_key_vault_id) : (
                                                                       azurerm_key_vault.kv_user[0].id
                                                                     )
  role_definition_name                 = "Key Vault Administrator"
  principal_id                         = local.service_principal.object_id
}

resource "azurerm_key_vault_access_policy" "kv_user" {
  provider                             = azurerm.deployer
  count                                = 0
  key_vault_id                         = local.user_keyvault_exist ? local.user_key_vault_id : azurerm_key_vault.kv_user[0].id
  tenant_id                            = local.service_principal.tenant_id
  object_id                            = var.deployer_tfstate.deployer_uai.principal_id

  secret_permissions                   = [
                                          "Get",
                                          "List",
                                          "Set",
                                          "Delete",
                                          "Recover",
                                          "Restore",
                                          "Purge"
                                        ]
}

resource "azurerm_key_vault_access_policy" "kv_user_spn" {
  provider                             = azurerm.main
  count                                = var.service_principal.exists ? 1 : 0
  key_vault_id                         = local.user_keyvault_exist ? data.azurerm_key_vault.kv_user[0].id : azurerm_key_vault.kv_user[0].id
  tenant_id                            = var.service_principal.tenant_id
  object_id                            = var.service_principal.object_id

  secret_permissions                   = [
                                          "Get",
                                          "List",
                                          "Set",
                                          "Delete",
                                          "Recover",
                                          "Restore",
                                          "Purge"
                                        ]
}


resource "azurerm_key_vault_access_policy" "kv_user_msi" {
  provider                             = azurerm.main
  count                                = local.user_keyvault_exist && var.enable_rbac_authorization_for_keyvault ? (
                                           0) : (
                                           length(var.deployer_tfstate) > 0 ? (
                                             length(var.deployer_tfstate.deployer_uai) == 2 ? (
                                               1) : (
                                               0
                                             )) : (
                                             0
                                           )
                                         )
  key_vault_id                         = local.user_keyvault_exist ? (
                                           local.user_key_vault_id) : (
                                           azurerm_key_vault.kv_user[0].id
                                         )

  tenant_id                            = var.deployer_tfstate.deployer_uai.tenant_id
  object_id                            = var.deployer_tfstate.deployer_uai.principal_id

  secret_permissions                   = [
                                          "Get",
                                          "List",
                                          "Set",
                                          "Delete",
                                          "Recover",
                                          "Restore",
                                          "Purge"
                                         ]
}

###############################################################################
#                                                                             #
#                                       Secrets                               #
#                                                                             #
###############################################################################

// Using TF tls to generate SSH key pair for SID
resource "tls_private_key" "sid" {
  count                                = (try(file(var.authentication.path_to_public_key), null) == null) ? 1 : 0
  algorithm                            = "RSA"
  rsa_bits                             = 2048
}

resource "random_password" "created_password" {
  length                               = 32
  min_upper                            = 2
  min_lower                            = 2
  min_numeric                          = 2
}

## Add an expiry date to the secrets
resource "time_offset" "secret_expiry_date" {
  offset_months = 12
}

// Key pair/password will be stored in the existing KV if specified, otherwise will be stored in a newly provisioned KV
resource "azurerm_key_vault_secret" "sid_ppk" {
  provider                             = azurerm.main
  depends_on                           = [
                                           azurerm_key_vault_access_policy.kv_user_spn,
                                           azurerm_key_vault_access_policy.kv_user_msi,
                                           azurerm_private_endpoint.kv_user,
                                           time_sleep.wait_for_private_endpoints,
                                           azurerm_role_assignment.role_assignment_msi,
                                           azurerm_role_assignment.role_assignment_spn
                                         ]
  count                                = !local.sid_key_exist ? 1 : 0
  content_type                         = "secret"
  name                                 = local.sid_ppk_name
  value                                = local.sid_private_key
  key_vault_id                         = local.user_keyvault_exist ? (
                                            data.azurerm_key_vault.kv_user[0].id) : (
                                            azurerm_key_vault.kv_user[0].id
                                          )
  expiration_date                      = var.key_vault.set_secret_expiry ? (
                                           time_offset.secret_expiry_date.rfc3339) : (
                                           null
                                         )
}

data "azurerm_key_vault_secret" "sid_ppk" {
  provider                              = azurerm.main
  count                                 = (local.sid_key_exist) ? 1 : 0
  name                                  = local.sid_ppk_name
  key_vault_id                          = local.user_key_vault_id
}

resource "azurerm_key_vault_secret" "sid_pk" {
  provider                             = azurerm.main
  depends_on                           = [
                                           azurerm_key_vault_access_policy.kv_user_spn,
                                           azurerm_key_vault_access_policy.kv_user_msi,
                                           azurerm_private_endpoint.kv_user,
                                           time_sleep.wait_for_private_endpoints,
                                           azurerm_role_assignment.role_assignment_msi,
                                           azurerm_role_assignment.role_assignment_spn
                                         ]
  count                                = !local.sid_key_exist ? 1 : 0
  content_type                         = "secret"
  name                                 = local.sid_pk_name
  value                                = local.sid_public_key
  key_vault_id                         = local.user_keyvault_exist ? (
                                           data.azurerm_key_vault.kv_user[0].id) : (
                                           azurerm_key_vault.kv_user[0].id
                                         )
  expiration_date                      = var.key_vault.set_secret_expiry ? (
                                           time_offset.secret_expiry_date.rfc3339) : (
                                           null
                                         )
}

data "azurerm_key_vault_secret" "sid_pk" {
  provider                             = azurerm.main
  depends_on                           = [
                                           azurerm_key_vault_access_policy.kv_user_spn,
                                           azurerm_key_vault_access_policy.kv_user_msi,
                                           azurerm_private_endpoint.kv_user,
                                           time_sleep.wait_for_private_endpoints
                                         ]
  count                                = (local.sid_key_exist) ? 1 : 0
  name                                 = local.sid_pk_name
  key_vault_id                         = local.user_key_vault_id
}


// Credentials will be stored in the existing KV if specified, otherwise will be stored in a newly provisioned KV
resource "azurerm_key_vault_secret" "sid_username" {
  provider                             = azurerm.main
  depends_on                           = [
                                           azurerm_key_vault_access_policy.kv_user_spn,
                                           azurerm_key_vault_access_policy.kv_user_msi,
                                           azurerm_private_endpoint.kv_user,
                                           time_sleep.wait_for_private_endpoints,
                                           azurerm_role_assignment.role_assignment_msi,
                                           azurerm_role_assignment.role_assignment_spn
                                         ]
  count                                = (!local.sid_credentials_secret_exist) ? 1 : 0
  content_type                         = "configuration"
  name                                 = local.sid_username_secret_name
  value                                = local.input_sid_username
  key_vault_id                         = local.user_keyvault_exist ? (
                                           data.azurerm_key_vault.kv_user[0].id) : (
                                           azurerm_key_vault.kv_user[0].id
                                         )
  expiration_date                      = var.key_vault.set_secret_expiry ? (
                                           time_offset.secret_expiry_date.rfc3339) : (
                                           null
                                         )
}

data "azurerm_key_vault_secret" "sid_username" {
  provider                             = azurerm.main
  depends_on                           = [
                                           azurerm_key_vault_access_policy.kv_user_spn,
                                           azurerm_key_vault_access_policy.kv_user_msi,
                                           azurerm_private_endpoint.kv_user,
                                           time_sleep.wait_for_private_endpoints,
                                           azurerm_role_assignment.role_assignment_msi,
                                           azurerm_role_assignment.role_assignment_spn
                                         ]
  count                                = (local.sid_credentials_secret_exist) ? 1 : 0
  name                                 = local.sid_username_secret_name
  key_vault_id                         = local.user_key_vault_id
}

resource "azurerm_key_vault_secret" "sid_password" {
  provider                             = azurerm.main
  depends_on                           = [
                                           azurerm_key_vault_access_policy.kv_user_spn,
                                           azurerm_key_vault_access_policy.kv_user_msi,
                                           azurerm_private_endpoint.kv_user,
                                           time_sleep.wait_for_private_endpoints,
                                           azurerm_role_assignment.role_assignment_msi,
                                           azurerm_role_assignment.role_assignment_spn
                                         ]
  count                                = (!local.sid_credentials_secret_exist) ? 1 : 0
  name                                 = local.sid_password_secret_name
  content_type                         = "secret"
  value                                = local.input_sid_password
  key_vault_id                         = local.user_keyvault_exist ? (
                                           data.azurerm_key_vault.kv_user[0].id) : (
                                           azurerm_key_vault.kv_user[0].id
                                         )
  expiration_date                       = var.key_vault.set_secret_expiry ? (
                                           time_offset.secret_expiry_date.rfc3339) : (
                                           null
                                         )
}

data "azurerm_key_vault_secret" "sid_password" {
  provider                             = azurerm.main
  depends_on                           = [
                                           azurerm_key_vault_access_policy.kv_user_spn,
                                           azurerm_key_vault_access_policy.kv_user_msi,
                                           azurerm_private_endpoint.kv_user,
                                           time_sleep.wait_for_private_endpoints,
                                           azurerm_role_assignment.role_assignment_msi,
                                           azurerm_role_assignment.role_assignment_spn
                                         ]
  count                                = (local.sid_credentials_secret_exist) ? 1 : 0
  name                                 = local.sid_password_secret_name
  key_vault_id                         = local.user_key_vault_id
}


//Witness access key
resource "azurerm_key_vault_secret" "witness_access_key" {
  provider                             = azurerm.main
  depends_on                           = [
                                           azurerm_key_vault_access_policy.kv_user_spn,
                                           azurerm_key_vault_access_policy.kv_user_msi,
                                           azurerm_private_endpoint.kv_user,
                                           time_sleep.wait_for_private_endpoints,
                                           azurerm_role_assignment.role_assignment_msi,
                                           azurerm_role_assignment.role_assignment_spn
                                         ]
  count                                = 1
  content_type                         = "secret"
  name                                 = replace(
                                          format("%s%s%s",
                                            length(local.prefix) > 0 ? (
                                              local.prefix) : (
                                              var.infrastructure.environment
                                            ),
                                            var.naming.separator,
                                            local.resource_suffixes.witness_accesskey
                                          ),
                                          "/[^A-Za-z0-9-]/",
                                          ""
                                        )
  value                                = length(var.witness_storage_account.arm_id) > 0 ? (
                                           data.azurerm_storage_account.witness_storage[0].primary_access_key) : (
                                           azurerm_storage_account.witness_storage[0].primary_access_key
                                         )
  key_vault_id                         = local.user_keyvault_exist ? (
                                           data.azurerm_key_vault.kv_user[0].id) : (
                                           azurerm_key_vault.kv_user[0].id
                                         )
  expiration_date                       = var.key_vault.set_secret_expiry ? (
                                           time_offset.secret_expiry_date.rfc3339) : (
                                           null
                                         )
}

//Witness access key
resource "azurerm_key_vault_secret" "witness_name" {
  provider                             = azurerm.main
  depends_on                           = [
                                           azurerm_key_vault_access_policy.kv_user_spn,
                                           azurerm_key_vault_access_policy.kv_user_msi,
                                           azurerm_private_endpoint.kv_user,
                                           time_sleep.wait_for_private_endpoints,
                                           azurerm_role_assignment.role_assignment_msi,
                                           azurerm_role_assignment.role_assignment_spn
                                         ]
  count                                = 1
  content_type                         = "configuration"
  name                                 = replace(
                                           format("%s%s%s",
                                             length(local.prefix) > 0 ? (
                                               local.prefix) : (
                                               var.infrastructure.environment
                                             ),
                                             var.naming.separator,
                                             local.resource_suffixes.witness_name
                                           ),
                                           "/[^A-Za-z0-9-]/",
                                           ""
                                         )
  value                                = length(var.witness_storage_account.arm_id) > 0 ? (
                                           data.azurerm_storage_account.witness_storage[0].name) : (
                                           azurerm_storage_account.witness_storage[0].name
                                         )
  key_vault_id                         = local.user_keyvault_exist ? (
                                           data.azurerm_key_vault.kv_user[0].id) : (
                                           azurerm_key_vault.kv_user[0].id
                                         )
  expiration_date                       = var.key_vault.set_secret_expiry ? (
                                           time_offset.secret_expiry_date.rfc3339) : (
                                           null
                                         )
}

//Witness access key
resource "azurerm_key_vault_secret" "deployer_keyvault_user_name" {
  provider                             = azurerm.main
  depends_on                           = [
                                           azurerm_key_vault_access_policy.kv_user_spn,
                                           azurerm_key_vault_access_policy.kv_user_msi,
                                           azurerm_private_endpoint.kv_user,
                                           time_sleep.wait_for_private_endpoints,
                                           azurerm_role_assignment.role_assignment_msi,
                                           azurerm_role_assignment.role_assignment_spn
                                         ]
  content_type                         = "configuration"
  name                                 = "deployer-kv-name"
  value                                = local.deployer_keyvault_user_name
  key_vault_id                         = local.user_keyvault_exist ? (
                                           data.azurerm_key_vault.kv_user[0].id) : (
                                           azurerm_key_vault.kv_user[0].id
                                         )
  expiration_date                       = var.key_vault.set_secret_expiry ? (
                                           time_offset.secret_expiry_date.rfc3339) : (
                                           null
                                         )
}


data "azurerm_private_endpoint_connection" "kv_user" {
  provider                             = azurerm.main
  count                                = length(var.keyvault_private_endpoint_id) > 0 ? (
                                            1) : (
                                            0
                                          )
  name                                 = split("/", var.keyvault_private_endpoint_id)[8]
  resource_group_name                  = split("/", var.keyvault_private_endpoint_id)[4]

}
###############################################################################
#                                                                             #
#                                Additional Users                             #
#                                                                             #
###############################################################################

resource "azurerm_key_vault_access_policy" "kv_user_additional_users" {
  provider                             = azurerm.main
  count                                = var.enable_rbac_authorization_for_keyvault ? (
                                           0) : (
                                           length(compact(var.additional_users_to_add_to_keyvault_policies)) > 0 ? (
                                             length(var.additional_users_to_add_to_keyvault_policies)) : (
                                             0
                                           )
                                         )

  key_vault_id                         = local.user_keyvault_exist ? (
                                           data.azurerm_key_vault.kv_user[0].id) : (
                                           azurerm_key_vault.kv_user[0].id
                                         )

  tenant_id                            = local.service_principal.tenant_id
  object_id                            = var.additional_users_to_add_to_keyvault_policies[count.index]
  secret_permissions                   = [
                                           "Get",
                                           "List"
                                         ]
}

resource "azurerm_role_assignment" "kv_user_additional_users" {
  provider                             = azurerm.main
  count                                = var.enable_rbac_authorization_for_keyvault ? (
                                           length(compact(var.additional_users_to_add_to_keyvault_policies)) > 0 ? (
                                             length(var.additional_users_to_add_to_keyvault_policies)) : (
                                             0
                                           )) : (
                                           0
                                         )

  scope                                = local.user_keyvault_exist ? (
                                                                       local.user_key_vault_id) : (
                                                                       azurerm_key_vault.kv_user[0].id
                                                                     )
  role_definition_name                 = "Key Vault Secrets Officer"
  principal_id                         = var.additional_users_to_add_to_keyvault_policies[count.index]
}
