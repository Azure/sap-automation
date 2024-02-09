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
                                           azurerm_virtual_network_peering.peering_sap_management
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

  dynamic "network_acls" {
                           for_each = range(var.enable_firewall_for_keyvaults_and_storage ? 1 : 0)
                           content {

                                      bypass         = "AzureServices"
                                      default_action = local.management_subnet_exists ? "Deny" : "Allow"

                                       ip_rules = compact(
                                        [
                                          length(local.deployer_public_ip_address) > 0 ? local.deployer_public_ip_address : "",
                                          length(var.Agent_IP) > 0 ? var.Agent_IP : ""
                                        ]
                                      )

                                       virtual_network_subnet_ids = compact(
                                        [
                                          local.database_subnet_defined ? (
                                            local.database_subnet_existing ? var.infrastructure.vnets.sap.subnet_db.arm_id : azurerm_subnet.db[0].id) : (
                                            ""
                                            ), local.application_subnet_defined ? (
                                            local.application_subnet_existing ? var.infrastructure.vnets.sap.subnet_app.arm_id : azurerm_subnet.app[0].id) : (
                                            ""
                                          ),
                                          local.deployer_subnet_management_id
                                        ]
                                      )
                                    }
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

resource "azurerm_role_assignment" "role_assignment_msi" {
  provider                             = azurerm.main
  count                                = var.enable_rbac_authorization_for_keyvault ? 1 : 0
  scope                                = local.user_keyvault_exist ? (
                                           local.user_key_vault_id) : (
                                           azurerm_key_vault.kv_user[0].id
                                         )
  role_definition_name                 = "Key Vault Administrator"
  principal_id                         = var.deployer_tfstate.deployer_uai.principal_id
}

resource "azurerm_role_assignment" "role_assignment_spn" {
  provider                             = azurerm.main
  count                                = var.enable_rbac_authorization_for_keyvault && local.service_principal.object_id != "" ? 1 : 0
  scope                                = local.user_keyvault_exist ? (
                                                                       local.user_key_vault_id) : (
                                                                       azurerm_key_vault.kv_user[0].id
                                                                     )
  role_definition_name                 = "Key Vault Administrator"
  principal_id                         = local.service_principal.object_id
}

resource "azurerm_key_vault_access_policy" "kv_user" {
  provider                             = azurerm.main
  count                                = (var.key_vault.exists || var.enable_rbac_authorization_for_keyvault) ? (
                                           0) : (
                                           (length(var.deployer_tfstate) > 0 ? var.deployer_tfstate.deployer_uai.principal_id == local.service_principal.object_id : false) ? 0 : 1
                                         )
  key_vault_id                         = local.user_keyvault_exist ? local.user_key_vault_id : azurerm_key_vault.kv_user[0].id
  tenant_id                            = local.service_principal.tenant_id
  object_id                            = local.service_principal.object_id != "" ? local.service_principal.object_id : "00000000-0000-0000-0000-000000000000"

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


// Key pair/password will be stored in the existing KV if specified, otherwise will be stored in a newly provisioned KV
resource "azurerm_key_vault_secret" "sid_ppk" {
  provider                             = azurerm.main
  count                                = !local.sid_key_exist ? 1 : 0
  depends_on                           = [
                                           azurerm_key_vault_access_policy.kv_user,
                                           azurerm_role_assignment.role_assignment_spn,
                                           azurerm_role_assignment.role_assignment_msi,
                                           azurerm_key_vault_access_policy.kv_user_msi
                                         ]
  content_type                          = ""
  name                                  = local.sid_ppk_name
  value                                 = local.sid_private_key
  key_vault_id                          = local.user_keyvault_exist ? local.user_key_vault_id : azurerm_key_vault.kv_user[0].id
}

data "azurerm_key_vault_secret" "sid_ppk" {
  provider                              = azurerm.main
  count                                 = (local.sid_key_exist) ? 1 : 0
  name                                  = local.sid_ppk_name
  key_vault_id                          = local.user_key_vault_id
}

resource "azurerm_key_vault_secret" "sid_pk" {
  provider                             = azurerm.main
  count                                = !local.sid_key_exist ? 1 : 0
  depends_on                           = [
                                           azurerm_key_vault_access_policy.kv_user,
                                           azurerm_role_assignment.role_assignment_spn,
                                           azurerm_role_assignment.role_assignment_msi,
                                           azurerm_key_vault_access_policy.kv_user_msi
                                         ]
  content_type                         = ""
  name                                 = local.sid_pk_name
  value                                = local.sid_public_key
  key_vault_id                         = local.user_keyvault_exist ? (
                                           local.user_key_vault_id) : (
                                           azurerm_key_vault.kv_user[0].id
                                         )
}

data "azurerm_key_vault_secret" "sid_pk" {
  provider                             = azurerm.main
  count                                = (local.sid_key_exist) ? 1 : 0
  name                                 = local.sid_pk_name
  key_vault_id                         = local.user_key_vault_id
}


// Credentials will be stored in the existing KV if specified, otherwise will be stored in a newly provisioned KV
resource "azurerm_key_vault_secret" "sid_username" {
  provider                             = azurerm.main
  count                                = (!local.sid_credentials_secret_exist) ? 1 : 0
  depends_on                           = [
                                          azurerm_key_vault_access_policy.kv_user,
                                          azurerm_role_assignment.role_assignment_spn,
                                           azurerm_role_assignment.role_assignment_msi,
                                           azurerm_key_vault_access_policy.kv_user_msi
                                        ]
  content_type                         = ""
  name                                 = local.sid_username_secret_name
  value                                = local.input_sid_username
  key_vault_id                         = local.user_keyvault_exist ? (
                                           local.user_key_vault_id) : (
                                           azurerm_key_vault.kv_user[0].id
                                         )
}

data "azurerm_key_vault_secret" "sid_username" {
  provider                             = azurerm.main
  count                                = (local.sid_credentials_secret_exist) ? 1 : 0
  name                                 = local.sid_username_secret_name
  key_vault_id                         = local.user_key_vault_id
}

resource "azurerm_key_vault_secret" "sid_password" {
  provider                             = azurerm.main
  count                                = (!local.sid_credentials_secret_exist) ? 1 : 0
  depends_on                           = [
                                           azurerm_key_vault_access_policy.kv_user,
                                           azurerm_role_assignment.role_assignment_spn,
                                           azurerm_role_assignment.role_assignment_msi,
                                           azurerm_key_vault_access_policy.kv_user_msi
                                         ]
  name                                 = local.sid_password_secret_name
  content_type                         = ""
  value                                = local.input_sid_password
  key_vault_id                         = local.user_keyvault_exist ? (
                                           local.user_key_vault_id) : (
                                           azurerm_key_vault.kv_user[0].id
                                         )
}

data "azurerm_key_vault_secret" "sid_password" {
  provider                             = azurerm.main
  count                                = (local.sid_credentials_secret_exist) ? 1 : 0
  name                                 = local.sid_password_secret_name
  key_vault_id                         = local.user_key_vault_id
}


//Witness access key
resource "azurerm_key_vault_secret" "witness_access_key" {
  provider                             = azurerm.main
  count                                = 1
  depends_on                           = [
                                           azurerm_key_vault_access_policy.kv_user,
                                           azurerm_role_assignment.role_assignment_spn,
                                           azurerm_role_assignment.role_assignment_msi,
                                           azurerm_key_vault_access_policy.kv_user_msi
                                         ]
  content_type                         = ""
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
                                           local.user_key_vault_id) : (
                                           azurerm_key_vault.kv_user[0].id
                                         )
}

//Witness access key
resource "azurerm_key_vault_secret" "witness_name" {
  provider                             = azurerm.main
  count                                = 1
  depends_on                           = [
                                           azurerm_key_vault_access_policy.kv_user,
                                           azurerm_role_assignment.role_assignment_spn,
                                           azurerm_role_assignment.role_assignment_msi,
                                           azurerm_key_vault_access_policy.kv_user_msi
                                         ]
  content_type                         = ""
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
                                           local.user_key_vault_id) : (
                                           azurerm_key_vault.kv_user[0].id
                                         )
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

//Witness access key
resource "azurerm_key_vault_secret" "deployer_keyvault_user_name" {
  provider                             = azurerm.main
  depends_on                           = [
                                           azurerm_key_vault_access_policy.kv_user,
                                           azurerm_role_assignment.role_assignment_spn,
                                           azurerm_role_assignment.role_assignment_msi,
                                           azurerm_key_vault_access_policy.kv_user_msi
                                         ]
  content_type                         = ""
  name                                 = "deployer-kv-name"
  value                                = local.deployer_keyvault_user_name
  key_vault_id                         = local.user_keyvault_exist ? (
                                           local.user_key_vault_id) : (
                                           azurerm_key_vault.kv_user[0].id
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

resource "azurerm_private_endpoint" "kv_user" {
  provider                             = azurerm.main
  count                                = (length(var.keyvault_private_endpoint_id) == 0 &&
                                           local.application_subnet_defined &&
                                           var.use_private_endpoint &&
                                           local.enable_landscape_kv &&
                                           !local.user_keyvault_exist
                                         ) ? 1 : 0
  depends_on                           = [
                                           azurerm_key_vault_access_policy.kv_user_msi,
                                           azurerm_key_vault_access_policy.kv_user,
                                           azurerm_private_dns_zone_virtual_network_link.vault,
                                           azurerm_key_vault_secret.sid_ppk,
                                           azurerm_key_vault_secret.sid_pk,
                                           azurerm_key_vault_secret.sid_username,
                                           azurerm_key_vault_secret.deployer_keyvault_user_name,
                                           azurerm_key_vault_secret.witness_name,
                                           azurerm_key_vault_secret.witness_access_key,
                                           azurerm_key_vault_secret.sid_password,
                                           azurerm_key_vault_secret.sid_username
                                         ]

  name                                 = format("%s%s%s",
                                           var.naming.resource_prefixes.keyvault_private_link,
                                           length(local.prefix) > 0 ? (
                                             local.prefix) : (
                                             var.infrastructure.environment
                                           ),
                                           local.resource_suffixes.keyvault_private_link
                                         )
  resource_group_name                  = local.resource_group_exists ? (
                                           data.azurerm_resource_group.resource_group[0].name) : (
                                           azurerm_resource_group.resource_group[0].name
                                         )
  location                             = local.resource_group_exists ? (
                                           data.azurerm_resource_group.resource_group[0].location) : (
                                           azurerm_resource_group.resource_group[0].location
                                         )

  subnet_id                            = local.application_subnet_existing ? (
                                           var.infrastructure.vnets.sap.subnet_app.arm_id) : (
                                           azurerm_subnet.app[0].id
                                         )

  custom_network_interface_name        = format("%s%s%s%s",
                                           var.naming.resource_prefixes.keyvault_private_link,
                                           length(local.prefix) > 0 ? (
                                             local.prefix) : (
                                             var.infrastructure.environment
                                           ),
                                           var.naming.resource_suffixes.keyvault_private_link,
                                           var.naming.resource_suffixes.nic
                                         )

  private_service_connection {
                               name = format("%s%s%s",
                                 var.naming.resource_prefixes.keyvault_private_svc,
                                 length(local.prefix) > 0 ? (
                                   local.prefix) : (
                                   var.infrastructure.environment
                                 ),
                                 local.resource_suffixes.keyvault_private_svc
                               )
                               is_manual_connection = false
                               private_connection_resource_id = local.user_keyvault_exist ? (
                                 data.azurerm_key_vault.kv_user[0].id
                                 ) : (
                                 azurerm_key_vault.kv_user[0].id
                               )
                               subresource_names = [
                                 "Vault"
                               ]
                             }

  dynamic "private_dns_zone_group" {
                                      for_each = range(var.use_private_endpoint ? 1 : 0)
                                      content {
                                        name                 = var.dns_zone_names.vault_dns_zone_name
                                        private_dns_zone_ids = [data.azurerm_private_dns_zone.keyvault[0].id]
                                      }
                                    }
}


data "azurerm_private_dns_zone" "keyvault" {
  provider                             = azurerm.dnsmanagement
  count                                = var.use_private_endpoint && !var.use_custom_dns_a_registration ? 1 : 0
  name                                 = var.dns_zone_names.vault_dns_zone_name
  resource_group_name                  = var.management_dns_resourcegroup_name
}

resource "azurerm_private_dns_a_record" "keyvault" {
  provider                             = azurerm.dnsmanagement
  count                                = local.use_Azure_native_DNS && var.use_private_endpoint ?  1 : 0
  name                                 = lower(
                                           format("%s", local.user_keyvault_name)
                                         )
  zone_name                            = var.dns_zone_names.vault_dns_zone_name
  resource_group_name                  = var.management_dns_resourcegroup_name
  ttl                                  = 10
  records                              = [
                                           length(var.keyvault_private_endpoint_id) > 0 ? (
                                             data.azurerm_private_endpoint_connection.kv_user[0].private_service_connection[0].private_ip_address) : (
                                             azurerm_private_endpoint.kv_user[0].private_service_connection[0].private_ip_address
                                           )
                                         ]
  tags                                 = var.tags

}


resource "azurerm_private_dns_zone_virtual_network_link" "vault" {
  provider                             = azurerm.dnsmanagement
  count                                = local.use_Azure_native_DNS && var.use_private_endpoint ? 1 : 0
  depends_on                           = [
                                           azurerm_virtual_network.vnet_sap
                                         ]
  name                                 = format("%s%s%s%s",
                                           var.naming.resource_prefixes.dns_link,
                                           local.prefix,
                                           var.naming.separator,
                                           "vault"
                                         )
  resource_group_name                  = var.management_dns_resourcegroup_name
  private_dns_zone_name                = var.dns_zone_names.vault_dns_zone_name
  virtual_network_id                   = azurerm_virtual_network.vnet_sap[0].id
  registration_enabled                 = false
}

data "azurerm_private_dns_zone" "vault" {
  provider                             = azurerm.dnsmanagement
  count                                = var.use_private_endpoint ? 1 : 0
  name                                 = var.dns_zone_names.vault_dns_zone_name
  resource_group_name                  = var.management_dns_resourcegroup_name
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
                                           local.user_key_vault_id) : (
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
  principal_id                         = local.service_principal.object_id
}

resource "azurerm_management_lock" "keyvault" {
  provider                             = azurerm.main
  count                                = var.key_vault.exists ? 0 : var.place_delete_lock_on_resources ? 1 : 0
  name                                 = format("%s-lock", local.user_keyvault_name)
  scope                                = azurerm_key_vault.kv_user[0].id
  lock_level                           = "CanNotDelete"
  notes                                = "Locked because it's needed by the Control Plane"

  lifecycle {
              prevent_destroy = false
            }
}
