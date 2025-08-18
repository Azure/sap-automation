# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

data "azurerm_client_config" "current" {
  provider                            = azurerm.main

}

#######################################4#######################################8
#                                                                              #
#                            Workload zone key vault                           #
#                                                                             #
#######################################4#######################################8

// Create user KV with access policy
resource "azurerm_key_vault" "kv_user" {
  provider                             = azurerm.main
  count                                = (var.key_vault.user.exists) ? 0 : 1
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
  tenant_id                            = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days           = var.key_vault.soft_delete_retention_days
  purge_protection_enabled             = var.key_vault.enable_purge_control
  sku_name                             = "standard"
  enable_rbac_authorization            = var.key_vault.enable_rbac_authorization

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

            virtual_network_subnet_ids = distinct(concat(compact(
                                            [
                                              var.infrastructure.virtual_networks.sap.subnet_db.defined ? (
                                                var.infrastructure.virtual_networks.sap.subnet_db.exists ? var.infrastructure.virtual_networks.sap.subnet_db.id : azurerm_subnet.db[0].id) : (
                                                ""
                                                ), var.infrastructure.virtual_networks.sap.subnet_app.defined ? (
                                                var.infrastructure.virtual_networks.sap.subnet_app.exists ? var.infrastructure.virtual_networks.sap.subnet_app.id : azurerm_subnet.app[0].id) : (
                                                ""
                                              ),
                                              local.deployer_subnet_management_id,
                                              var.infrastructure.additional_subnet_id
                                            ]),
                                            try(var.deployer_tfstate.subnets_to_add_to_firewall_for_keyvaults_and_storage, [])
                                          ))
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
  count                                = var.key_vault.user.exists ? 1 : 0
  name                                 = split("/", var.key_vault.user.id)[8]
  resource_group_name                  = split("/", var.key_vault.user.id)[4]
}

resource "azurerm_management_lock" "keyvault" {
  provider                             = azurerm.main
  count                                = var.key_vault.user.exists ? 0 : var.place_delete_lock_on_resources ? 1 : 0
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
  provider                             = azurerm.deployer
  count                                = var.key_vault.enable_rbac_authorization ? 1 : 0
  scope                                = var.key_vault.user.exists ? (
                                           data.azurerm_key_vault.kv_user[0].id) : (
                                           azurerm_key_vault.kv_user[0].id
                                         )
  role_definition_name                 = "Key Vault Administrator"
  principal_id                         = var.deployer_tfstate.deployer_uai.principal_id
  timeouts                             {
                                          read   = "1m"
                                          create = "5m"
                                          delete = "5m"
                                       }
}

resource "azurerm_role_assignment" "role_assignment_vault_ssi" {
  provider                             = azurerm.deployer
  count                                = var.enable_rbac_authorization_for_keyvault && var.deployer_tfstate.deployer_uai.principal_id != data.azurerm_client_config.current.object_id ? 1 : 0
  scope                                = var.key_vault.user.exists ? (
                                           data.azurerm_key_vault.kv_user[0].id) : (
                                           azurerm_key_vault.kv_user[0].id
                                         )
  role_definition_name                 = "Key Vault Administrator"
  principal_id                         = data.azurerm_client_config.current.object_id
  timeouts                             {
                                          read   = "1m"
                                          create = "5m"
                                          delete = "5m"
                                       }
}

resource "azurerm_role_assignment" "role_assignment_msi_officer" {
  provider                             = azurerm.deployer
  count                                = var.key_vault.enable_rbac_authorization ? 1 : 0
  scope                                = var.key_vault.user.exists ? (
                                           data.azurerm_key_vault.kv_user[0].id) : (
                                           azurerm_key_vault.kv_user[0].id
                                         )
  role_definition_name                 = "Key Vault Secrets Officer"
  principal_id                         = var.deployer_tfstate.deployer_uai.principal_id
  timeouts                             {
                                          read   = "1m"
                                          create = "5m"
                                          delete = "5m"
                                       }
}

resource "azurerm_role_assignment" "role_assignment_spn" {
  provider                             = azurerm.deployer
  count                                = var.key_vault.enable_rbac_authorization && var.options.assign_permissions && var.options.use_spn ? 1 : 0
  scope                                 = var.key_vault.user.exists ? (
                                           data.azurerm_key_vault.kv_user[0].id) : (
                                           azurerm_key_vault.kv_user[0].id
                                         )
  role_definition_name                 = "Key Vault Administrator"
  principal_id                         = var.options.spn_id

  timeouts                             {
                                          read   = "1m"
                                          create = "5m"
                                          delete = "5m"
                                       }

}

resource "azurerm_role_assignment" "role_assignment_spn_officer" {
  provider                             = azurerm.deployer
  count                                = var.key_vault.enable_rbac_authorization && var.options.assign_permissions && var.options.use_spn ? 1 : 0
  scope                                 = var.key_vault.user.exists ? (
                                           data.azurerm_key_vault.kv_user[0].id) : (
                                           azurerm_key_vault.kv_user[0].id
                                         )
  role_definition_name                 = "Key Vault Secrets Officer"
  principal_id                         = var.options.spn_id
  timeouts                             {
                                          read   = "1m"
                                          create = "5m"
                                          delete = "5m"
                                       }
}

resource "azurerm_key_vault_access_policy" "kv_user" {
  provider                             = azurerm.main
  count                                = 0
  key_vault_id                         = var.key_vault.user.exists ? (
                                           data.azurerm_key_vault.kv_user[0].id) : (
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

resource "azurerm_key_vault_access_policy" "kv_user_spn" {
  provider                             = azurerm.main
  count                                = !var.key_vault.user.exists && !var.key_vault.enable_rbac_authorization && var.options.use_spn ? 1 : 0
  key_vault_id                         = var.key_vault.user.exists ? (
                                           data.azurerm_key_vault.kv_user[0].id) : (
                                           azurerm_key_vault.kv_user[0].id
                                         )
  tenant_id                            = data.azurerm_client_config.current.tenant_id
  object_id                            = var.options.spn_id

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
  count                                = !var.key_vault.user.exists && !var.key_vault.enable_rbac_authorization ? (
                                           0) : (
                                           length(var.deployer_tfstate) > 0 ? (
                                             length(var.deployer_tfstate.deployer_uai) == 2 ? (
                                               1) : (
                                               0
                                             )) : (
                                             0
                                           )
                                         )
  key_vault_id                         = var.key_vault.user.exists ? (
                                           data.azurerm_key_vault.kv_user[0].id) : (
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

resource "azurerm_role_assignment" "kv_user_msi_rbac" {
  provider                             = azurerm.deployer
  count                                = !var.key_vault.user.exists && var.key_vault.enable_rbac_authorization && var.options.assign_permissions ? (
                                           0) : (
                                           length(var.deployer_tfstate) > 0 ? (
                                             length(var.deployer_tfstate.deployer_uai) == 2 ? (
                                               1) : (
                                               0
                                             )) : (
                                             0
                                           )
                                         )
  scope                               = var.key_vault.user.exists ? (
                                           data.azurerm_key_vault.kv_user[0].id) : (
                                           azurerm_key_vault.kv_user[0].id
                                         )

  role_definition_name                 = "Key Vault Administrator"
  principal_id                         = var.deployer_tfstate.deployer_uai.principal_id
  timeouts                             {
                                          read   = "1m"
                                          create = "5m"
                                          delete = "5m"
                                       }
}

resource "azurerm_role_assignment" "kv_user_msi_rbac_secret_officer" {
  provider                             = azurerm.deployer
  count                                = 0
  //count                                = !var.key_vault.user.exists && var.enable_rbac_authorization_for_keyvault && var.options.assign_permissions ? (
  //                                         0) : (
  //                                         length(var.deployer_tfstate) > 0 ? (
  //                                           length(var.deployer_tfstate.deployer_uai) == 2 ? (
  //                                             1) : (
  //                                             0
  //                                           )) : (
  //                                           0
  //                                         )
  //                                       )
  scope                                = var.key_vault.user.exists ? (
                                           data.azurerm_key_vault.kv_user[0].id) : (
                                           azurerm_key_vault.kv_user[0].id
                                         )

  role_definition_name                 = "Key Vault Secrets Officer"
  principal_id                         = var.deployer_tfstate.deployer_uai.principal_id
  timeouts                             {
                                          read   = "1m"
                                          create = "5m"
                                          delete = "5m"
                                       }
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


resource "time_sleep" "wait_for_role_assignment" {
  create_duration                      = "60s"

  triggers                           = {
                                           msi = try(azurerm_role_assignment.role_assignment_msi[0].id, "")
                                           spn = try(azurerm_role_assignment.role_assignment_spn[0].id, "")
                                           ssi = try(azurerm_role_assignment.role_assignment_vault_ssi[0].id, "")
                                           policy_msi = try(azurerm_key_vault_access_policy.kv_user_msi[0].id, "")
                                           policy_spn = try(azurerm_key_vault_access_policy.kv_user[0].id, "")
                                       }
}


//Witness access key

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
  count                                = var.key_vault.enable_rbac_authorization ? (
                                           0) : (
                                           length(compact(var.additional_users_to_add_to_keyvault_policies)) > 0 ? (
                                             length(var.additional_users_to_add_to_keyvault_policies)) : (
                                             0
                                           )
                                         )

  key_vault_id                         = var.key_vault.user.exists ? (
                                           data.azurerm_key_vault.kv_user[0].id) : (
                                           azurerm_key_vault.kv_user[0].id
                                         )

  tenant_id                            = data.azurerm_client_config.current.tenant_id
  object_id                            = var.additional_users_to_add_to_keyvault_policies[count.index]
  secret_permissions                   = [
                                           "Get",
                                           "List"
                                         ]
}

resource "azurerm_role_assignment" "kv_user_additional_users" {
  provider                             = azurerm.main
  count                                = var.key_vault.enable_rbac_authorization ? (
                                           length(compact(var.additional_users_to_add_to_keyvault_policies)) > 0 ? (
                                             length(var.additional_users_to_add_to_keyvault_policies)) : (
                                             0
                                           )) : (
                                           0
                                         )
  scope                                = var.key_vault.user.exists ? (
                                           data.azurerm_key_vault.kv_user[0].id) : (
                                           azurerm_key_vault.kv_user[0].id
                                         )

  role_definition_name                 = "Key Vault Secrets Officer"
  principal_id                         = var.additional_users_to_add_to_keyvault_policies[count.index]
  timeouts                             {
                                          read   = "1m"
                                          create = "5m"
                                          delete = "5m"
                                       }
}



resource "azurerm_private_endpoint" "kv_user" {
  provider                             = azurerm.main
  count                                = (length(var.keyvault_private_endpoint_id) == 0 &&
                                           var.use_private_endpoint &&
                                           !var.key_vault.user.exists
                                         ) ? 1 : 0
  depends_on                           = [
                                           azurerm_private_dns_zone_virtual_network_link.vault,
                                           azurerm_virtual_network_peering.peering_sap_management,
                                           azurerm_virtual_network_peering.peering_management_sap
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

  subnet_id                            = var.infrastructure.virtual_networks.sap.subnet_app.exists ? (
                                           var.infrastructure.virtual_networks.sap.subnet_app.id) : (
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
  tags                                 = var.tags
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
                               private_connection_resource_id = var.key_vault.user.exists ? (
                                 data.azurerm_key_vault.kv_user[0].id
                                 ) : (
                                 azurerm_key_vault.kv_user[0].id
                               )
                               subresource_names = [
                                 "Vault"
                               ]
                             }

  dynamic "private_dns_zone_group" {
                                      for_each = range(var.dns_settings.register_endpoints_with_dns ? 1 : 0)
                                      content {
                                        name                 = var.dns_settings.dns_zone_names.vault_dns_zone_name
                                        private_dns_zone_ids = [data.azurerm_private_dns_zone.keyvault[0].id]
                                      }
                                    }

}


// Key pair/password will be stored in the existing KV if specified, otherwise will be stored in a newly provisioned KV
resource "azurerm_key_vault_secret" "sid_ppk" {
  provider                             = azurerm.main
  depends_on                           = [
                                           time_sleep.wait_for_role_assignment,
                                           azurerm_private_endpoint.kv_user,
                                           azurerm_private_dns_zone_virtual_network_link.vault
                                         ]
  count                                = length(var.key_vault.private_key_secret_name) == 0 ? 1 : 0
  content_type                         = "secret"
  name                                 = local.sid_public_key_secret_name
  value                                = local.sid_private_key
  key_vault_id                         = var.key_vault.user.exists ? (
                                            data.azurerm_key_vault.kv_user[0].id) : (
                                            azurerm_key_vault.kv_user[0].id
                                          )
  expiration_date                      = var.key_vault.set_secret_expiry ? (
                                           time_offset.secret_expiry_date.rfc3339) : (
                                           null
                                         )
  timeouts                              {
                                          read   = "1m"
                                          create = "5m"
                                          delete = "5m"
                                        }
}

data "azurerm_key_vault_secret" "sid_ppk" {
  provider                              = azurerm.main
  count                                 = length(var.key_vault.private_key_secret_name) > 0 ? 1 : 0
  depends_on                            = [
                                           time_sleep.wait_for_role_assignment,
                                           azurerm_private_endpoint.kv_user,
                                           azurerm_private_dns_zone_virtual_network_link.vault
                                          ]
  name                                  = local.sid_public_key_secret_name
  key_vault_id                          = var.key_vault.user.exists ? data.azurerm_key_vault.kv_user[0].id : azurerm_key_vault.kv_user[0].id
}

resource "azurerm_key_vault_secret" "sid_pk" {
  provider                             = azurerm.main
  depends_on                           = [
                                           time_sleep.wait_for_role_assignment,
                                           azurerm_private_endpoint.kv_user,
                                           azurerm_private_dns_zone_virtual_network_link.vault
                                         ]
  count                                = length(var.key_vault.public_key_secret_name) == 0 ? 1 : 0
  content_type                         = "secret"
  name                                 = local.sid_private_key_secret_name
  value                                = local.sid_public_key
  key_vault_id                         = var.key_vault.user.exists ? (
                                           data.azurerm_key_vault.kv_user[0].id) : (
                                           azurerm_key_vault.kv_user[0].id
                                         )
  expiration_date                      = var.key_vault.set_secret_expiry ? (
                                           time_offset.secret_expiry_date.rfc3339) : (
                                           null
                                         )
  timeouts                              {
                                          read   = "1m"
                                          create = "5m"
                                          delete = "5m"
                                        }
}

data "azurerm_key_vault_secret" "sid_pk" {
  provider                             = azurerm.main
  depends_on                           = [
                                           time_sleep.wait_for_role_assignment,
                                           azurerm_private_endpoint.kv_user,
                                           azurerm_private_dns_zone_virtual_network_link.vault
                                         ]
  count                                = var.key_vault.user.exists && length(var.key_vault.public_key_secret_name) >  0 ? 1 : 0
  name                                 = local.sid_private_key_secret_name
  key_vault_id                         = var.key_vault.user.exists ? (
                                           data.azurerm_key_vault.kv_user[0].id) : (
                                           azurerm_key_vault.kv_user[0].id
                                         )
}


// Credentials will be stored in the existing KV if specified, otherwise will be stored in a newly provisioned KV
resource "azurerm_key_vault_secret" "sid_username" {
  provider                             = azurerm.main
  depends_on                           = [
                                           time_sleep.wait_for_role_assignment,
                                           azurerm_private_endpoint.kv_user,
                                           azurerm_private_dns_zone_virtual_network_link.vault
                                         ]
  count                                = length(var.key_vault.username_secret_name) == 0 ? 1 : 0
  content_type                         = "configuration"
  name                                 = local.sid_username_secret_name
  value                                = local.input_sid_username
  key_vault_id                         = var.key_vault.user.exists ? (
                                           data.azurerm_key_vault.kv_user[0].id) : (
                                           azurerm_key_vault.kv_user[0].id
                                         )
  expiration_date                      = var.key_vault.set_secret_expiry ? (
                                           time_offset.secret_expiry_date.rfc3339) : (
                                           null
                                         )
  timeouts                              {
                                          read   = "1m"
                                          create = "5m"
                                          delete = "5m"
                                        }
}

data "azurerm_key_vault_secret" "sid_username" {
  provider                             = azurerm.main
  depends_on                           = [
                                           time_sleep.wait_for_role_assignment,
                                           azurerm_private_endpoint.kv_user,
                                           azurerm_private_dns_zone_virtual_network_link.vault
                                         ]
  count                                = length(var.key_vault.username_secret_name) > 0 ? 1 : 0
  name                                 = local.sid_username_secret_name
  key_vault_id                         = var.key_vault.user.exists ? (
                                           data.azurerm_key_vault.kv_user[0].id) : (
                                           azurerm_key_vault.kv_user[0].id
                                         )
}

resource "azurerm_key_vault_secret" "sid_password" {
  provider                             = azurerm.main
  depends_on                           = [
                                           time_sleep.wait_for_role_assignment,
                                           azurerm_private_endpoint.kv_user,
                                           azurerm_private_dns_zone_virtual_network_link.vault
                                         ]
  count                                = length(var.key_vault.password_secret_name) == 0 ? 1 : 0
  name                                 = local.sid_password_secret_name
  content_type                         = "secret"
  value                                = local.input_sid_password
  key_vault_id                         = var.key_vault.user.exists ? (
                                           data.azurerm_key_vault.kv_user[0].id) : (
                                           azurerm_key_vault.kv_user[0].id
                                         )
  expiration_date                       = var.key_vault.set_secret_expiry ? (
                                           time_offset.secret_expiry_date.rfc3339) : (
                                           null
                                         )
  timeouts                              {
                                          read   = "1m"
                                          create = "5m"
                                          delete = "5m"
                                        }
}

resource "azurerm_key_vault_secret" "deployer_keyvault_user_name" {
  provider                             = azurerm.main
  depends_on                           = [
                                           time_sleep.wait_for_role_assignment,
                                           azurerm_private_endpoint.kv_user,
                                           azurerm_private_dns_zone_virtual_network_link.vault
                                         ]
  content_type                         = "configuration"
  name                                 = "deployer-kv-name"
  value                                = local.deployer_keyvault_user_name
  key_vault_id                         = var.key_vault.user.exists ? (
                                           data.azurerm_key_vault.kv_user[0].id) : (
                                           azurerm_key_vault.kv_user[0].id
                                         )
  expiration_date                       = var.key_vault.set_secret_expiry ? (
                                           time_offset.secret_expiry_date.rfc3339) : (
                                           null
                                         )
  timeouts                              {
                                          read   = "1m"
                                          create = "5m"
                                          delete = "5m"
                                        }
}

data "azurerm_key_vault_secret" "sid_password" {
  provider                             = azurerm.main
  depends_on                           = [
                                           time_sleep.wait_for_role_assignment,
                                           azurerm_private_endpoint.kv_user,
                                           azurerm_private_dns_zone_virtual_network_link.vault
                                         ]
  count                                = length(var.key_vault.password_secret_name) > 0 ? 1 : 0
  name                                 = local.sid_password_secret_name
  key_vault_id                         = var.key_vault.user.exists ? (
                                           data.azurerm_key_vault.kv_user[0].id) : (
                                           azurerm_key_vault.kv_user[0].id
                                         )
}


//Witness access key
resource "azurerm_key_vault_secret" "witness_access_key" {
  provider                             = azurerm.main
  depends_on                           = [
                                           time_sleep.wait_for_role_assignment,
                                           azurerm_private_endpoint.kv_user,
                                           azurerm_private_dns_zone_virtual_network_link.vault
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
  value                                = length(var.witness_storage_account.id) > 0 ? (
                                           data.azurerm_storage_account.witness_storage[0].primary_access_key) : (
                                           azurerm_storage_account.witness_storage[0].primary_access_key
                                         )
  key_vault_id                         = var.key_vault.user.exists ? (
                                           data.azurerm_key_vault.kv_user[0].id) : (
                                           azurerm_key_vault.kv_user[0].id
                                         )
  expiration_date                       = var.key_vault.set_secret_expiry ? (
                                           time_offset.secret_expiry_date.rfc3339) : (
                                           null
                                         )

  timeouts                              {
                                          read   = "1m"
                                          create = "5m"
                                          delete = "5m"
                                        }
}
