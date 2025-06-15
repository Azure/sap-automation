

#######################################4#######################################8
#                                                                              #
#                                Role Assignments                              #
#                                                                              #
#######################################4#######################################8

resource "azurerm_role_assignment" "deployer" {
  provider                             = azurerm.main
  count                                = var.assign_subscription_permissions && var.deployer.add_system_assigned_identity ? var.deployer_vm_count : 0
  scope                                = length(var.deployer.deployer_diagnostics_account_arm_id) > 0 ? var.deployer.deployer_diagnostics_account_arm_id : azurerm_storage_account.deployer[0].id
  role_definition_name                 = "Storage Blob Data Contributor"
  principal_id                         = azurerm_linux_virtual_machine.deployer[count.index].identity[0].principal_id
}

resource "azurerm_role_assignment" "deployer_msi" {
  provider                             = azurerm.main
  count                                = var.assign_subscription_permissions  ? 1 : 0
  scope                                = length(var.deployer.deployer_diagnostics_account_arm_id) > 0 ? var.deployer.deployer_diagnostics_account_arm_id : azurerm_storage_account.deployer[0].id
  role_definition_name                 = "Storage Blob Data Contributor"
  principal_id                         = length(var.deployer.user_assigned_identity_id) == 0 ? azurerm_user_assigned_identity.deployer[0].principal_id : data.azurerm_user_assigned_identity.deployer[0].principal_id
}


resource "azurerm_role_assignment" "resource_group_contributor" {
  provider                             = azurerm.main
  count                                = var.assign_subscription_permissions && var.deployer.add_system_assigned_identity ? var.deployer_vm_count : 0
  scope                                = local.resource_group_exists  ? data.azurerm_resource_group.deployer[0].id : azurerm_resource_group.deployer[0].id
  role_definition_name                 = "Contributor"
  principal_id                         = azurerm_linux_virtual_machine.deployer[count.index].identity[0].principal_id
}

resource "azurerm_role_assignment" "resource_group_contributor_contributor_msi" {
  provider                             = azurerm.main
  count                                = var.assign_subscription_permissions ? 1 : 0
  scope                                = local.resource_group_exists ? data.azurerm_resource_group.deployer[0].id : azurerm_resource_group.deployer[0].id
  role_definition_name                 = "Contributor"
  principal_id                         = length(var.deployer.user_assigned_identity_id) == 0 ? azurerm_user_assigned_identity.deployer[0].principal_id : data.azurerm_user_assigned_identity.deployer[0].principal_id
}

resource "azurerm_role_assignment" "resource_group_user_access_admin_msi" {
  provider                             = azurerm.main
  count                                = var.assign_subscription_permissions ? 1 : 0
  scope                                = local.resource_group_exists ? data.azurerm_resource_group.deployer[0].id : azurerm_resource_group.deployer[0].id
  role_definition_name                 = "Role Based Access Control Administrator"
  principal_id                         = length(var.deployer.user_assigned_identity_id) == 0 ? azurerm_user_assigned_identity.deployer[0].principal_id : data.azurerm_user_assigned_identity.deployer[0].principal_id
  # condition_version                    = "2.0"
  # condition                            = <<-EOT
  #                                           (
  #                                            (
  #                                             !(ActionMatches{'Microsoft.Authorization/roleAssignments/write'})
  #                                            )
  #                                            OR
  #                                            (
  #                                             @Request[Microsoft.Authorization/roleAssignments:RoleDefinitionId] ForAnyOfAnyValues:GuidNotEquals {8e3af657-a8ff-443c-a75c-2fe8c4bcb635, 18d7d88d-d35e-4fb5-a5c3-7773c20a72d9, f58310d9-a9f6-439a-9e8d-f62e7b41a168}
  #                                            )
  #                                           )
  #                                           AND
  #                                           (
  #                                            (
  #                                             !(ActionMatches{'Microsoft.Authorization/roleAssignments/delete'})
  #                                            )
  #                                            OR
  #                                            (
  #                                             @Resource[Microsoft.Authorization/roleAssignments:RoleDefinitionId] ForAnyOfAnyValues:GuidNotEquals {8e3af657-a8ff-443c-a75c-2fe8c4bcb635, 18d7d88d-d35e-4fb5-a5c3-7773c20a72d9, f58310d9-a9f6-439a-9e8d-f62e7b41a168}
  #                                            )
  #                                           )
  #                                           EOT
}


resource "azurerm_role_assignment" "resource_group_user_access_admin_spn" {
  provider                             = azurerm.main
  count                                = var.assign_subscription_permissions && length(var.spn_id) > 0 ? 1 : 0
  scope                                = local.resource_group_exists ? data.azurerm_resource_group.deployer[0].id : azurerm_resource_group.deployer[0].id
  role_definition_name                 = "Role Based Access Control Administrator"
  principal_type                       = "ServicePrincipal"
  principal_id                         = var.spn_id
  # condition_version                    = "2.0"
  # condition                            = <<-EOT
  #                                           (
  #                                            (
  #                                             !(ActionMatches{'Microsoft.Authorization/roleAssignments/write'})
  #                                            )
  #                                            OR
  #                                            (
  #                                             @Request[Microsoft.Authorization/roleAssignments:RoleDefinitionId] ForAnyOfAnyValues:GuidNotEquals {8e3af657-a8ff-443c-a75c-2fe8c4bcb635, 18d7d88d-d35e-4fb5-a5c3-7773c20a72d9, f58310d9-a9f6-439a-9e8d-f62e7b41a168}
  #                                            )
  #                                           )
  #                                           AND
  #                                           (
  #                                            (
  #                                             !(ActionMatches{'Microsoft.Authorization/roleAssignments/delete'})
  #                                            )
  #                                            OR
  #                                            (
  #                                             @Resource[Microsoft.Authorization/roleAssignments:RoleDefinitionId] ForAnyOfAnyValues:GuidNotEquals {8e3af657-a8ff-443c-a75c-2fe8c4bcb635, 18d7d88d-d35e-4fb5-a5c3-7773c20a72d9, f58310d9-a9f6-439a-9e8d-f62e7b41a168}
  #                                            )
  #                                           )
  #                                           EOT
}

resource "azurerm_role_assignment" "role_assignment_msi" {
  provider                             = azurerm.main
  count                                = var.assign_subscription_permissions && var.key_vault.enable_rbac_authorization ? 1 : 0
  scope                                = var.key_vault.kv_exists ? data.azurerm_key_vault.kv_user[0].id : azurerm_key_vault.kv_user[0].id
  role_definition_name                 = "Key Vault Administrator"
  principal_id                         = length(var.deployer.user_assigned_identity_id) == 0 ? azurerm_user_assigned_identity.deployer[0].principal_id : data.azurerm_user_assigned_identity.deployer[0].principal_id
}

resource "azurerm_role_assignment" "role_assignment_spn" {
  provider                             = azurerm.main
  count                                = length(var.spn_id) > 0 && var.assign_subscription_permissions && var.key_vault.enable_rbac_authorization ? 1 : 0
  scope                                = var.key_vault.kv_exists ? data.azurerm_key_vault.kv_user[0].id : azurerm_key_vault.kv_user[0].id
  role_definition_name                 = "Key Vault Administrator"
  principal_type                       = "ServicePrincipal"
  principal_id                         = var.spn_id
}

resource "azurerm_role_assignment" "role_assignment_msi_officer" {
  provider                             = azurerm.main
  count                                = var.assign_subscription_permissions && var.key_vault.enable_rbac_authorization ? 1 : 0
  scope                                = var.key_vault.kv_exists ? data.azurerm_key_vault.kv_user[0].id : azurerm_key_vault.kv_user[0].id
  role_definition_name                 = "Key Vault Secrets Officer"
  principal_id                         = length(var.deployer.user_assigned_identity_id) == 0 ? azurerm_user_assigned_identity.deployer[0].principal_id : data.azurerm_user_assigned_identity.deployer[0].principal_id

}

resource "azurerm_role_assignment" "role_assignment_system_identity" {
  provider                             = azurerm.main
  depends_on                           = [ azurerm_key_vault_secret.pk ]
  count                                = var.assign_subscription_permissions && var.deployer.add_system_assigned_identity && var.key_vault.enable_rbac_authorization ? var.deployer_vm_count : 0
  scope                                = var.key_vault.kv_exists ? data.azurerm_key_vault.kv_user[0].id : azurerm_key_vault.kv_user[0].id
  role_definition_name                 = "Key Vault Secrets Officer"
  principal_id                         = azurerm_linux_virtual_machine.deployer[count.index].identity[0].principal_id
}

resource "azurerm_role_assignment" "role_assignment_additional_users" {
  provider                             = azurerm.main
  count                                = var.assign_subscription_permissions && !var.key_vault.kv_exists && var.key_vault.enable_rbac_authorization && length(compact(var.additional_users_to_add_to_keyvault_policies)) > 0 ? (
                                           length(compact(var.additional_users_to_add_to_keyvault_policies))) : (
                                           0
                                         )

  scope                                = var.key_vault.kv_exists ? data.azurerm_key_vault.kv_user[0].id : azurerm_key_vault.kv_user[0].id
  role_definition_name                 = "Key Vault Secrets Officer"
  principal_id                         = var.additional_users_to_add_to_keyvault_policies[count.index]
}

resource "azurerm_role_assignment" "role_assignment_webapp" {
  provider                             = azurerm.main
  count                                = var.assign_subscription_permissions && !var.key_vault.kv_exists && !var.key_vault.enable_rbac_authorization && var.app_service.use ? 1 : 0
  scope                                = var.key_vault.kv_exists ? data.azurerm_key_vault.kv_user[0].id : azurerm_key_vault.kv_user[0].id
  role_definition_name                 = "Key Vault Secrets User"
  principal_id                         = azurerm_windows_web_app.webapp[0].identity[0].principal_id
}

# // Add role to be able to deploy resources
resource "azurerm_role_assignment" "subscription_contributor_system_identity" {
  count                                = var.assign_subscription_permissions && var.deployer.add_system_assigned_identity ? var.deployer_vm_count : 0
  provider                             = azurerm.main
  scope                                = data.azurerm_subscription.primary.id
  role_definition_name                 = "Reader"
  principal_id                         = azurerm_linux_virtual_machine.deployer[count.index].identity[0].principal_id
}

resource "azurerm_role_assignment" "subscription_contributor_msi" {
  count                                = var.assign_subscription_permissions ? 1 : 0
  provider                             = azurerm.main
  scope                                = data.azurerm_subscription.primary.id
  role_definition_name                 = "Contributor"
  principal_id                         = length(var.deployer.user_assigned_identity_id) == 0 ? azurerm_user_assigned_identity.deployer[0].principal_id : data.azurerm_user_assigned_identity.deployer[0].principal_id
}
