

#######################################4#######################################8
#                                                                              #
#                                Role Assignments                              #
#                                                                              #
#######################################4#######################################8

resource "azurerm_role_assignment" "subscription_contributor_msi" {
  count                                = var.options.assign_subscription_permissions && length(var.deployer.user_assigned_identity_id) == 0 ? 1 : 0
  provider                             = azurerm.main
  scope                                = data.azurerm_subscription.primary.id
  role_definition_name                 = "Contributor"
  principal_id                         = azurerm_user_assigned_identity.deployer[0].principal_id
}

resource "azurerm_role_assignment" "subscription_useraccessadmin_msi" {
  count                                = var.options.assign_subscription_permissions && length(var.deployer.user_assigned_identity_id) == 0 ? 1 : 0
  provider                             = azurerm.main
  scope                                = data.azurerm_subscription.primary.id
  role_definition_name                 = "User Access Administrator"
  principal_id                         = azurerm_user_assigned_identity.deployer[0].principal_id
}

###############################################################################
#                                                                             #
#                            System Assigned Identity                         #
#                                                                             #
###############################################################################
resource "azurerm_role_assignment" "deployer" {
  provider                             = azurerm.main
  count                                = var.options.assign_resource_permissions && var.deployer.add_system_assigned_identity ? var.deployer_vm_count : 0
  scope                                = length(var.deployer.deployer_diagnostics_account_arm_id) > 0 ? var.deployer.deployer_diagnostics_account_arm_id : azurerm_storage_account.deployer[0].id
  role_definition_name                 = "Storage Blob Data Contributor"
  principal_id                         = azurerm_linux_virtual_machine.deployer[count.index].identity[0].principal_id
}

resource "azurerm_role_assignment" "resource_group_contributor" {
  provider                             = azurerm.main
  count                                = var.options.assign_resource_permissions && var.deployer.add_system_assigned_identity ? var.deployer_vm_count : 0
  scope                                = var.infrastructure.resource_group.exists  ? data.azurerm_resource_group.deployer[0].id : azurerm_resource_group.deployer[0].id
  role_definition_name                 = "Contributor"
  principal_id                         = azurerm_linux_virtual_machine.deployer[count.index].identity[0].principal_id
}

resource "azurerm_role_assignment" "role_assignment_system_identity" {
  provider                             = azurerm.main
  count                                = var.options.assign_resource_permissions && var.deployer.add_system_assigned_identity && var.key_vault.enable_rbac_authorization ? var.deployer_vm_count : 0
  scope                                = var.key_vault.exists ? data.azurerm_key_vault.kv_user[0].id : azurerm_key_vault.kv_user[0].id
  role_definition_name                 = "Key Vault Secrets Officer"
  principal_id                         = azurerm_linux_virtual_machine.deployer[count.index].identity[0].principal_id
}

resource "azurerm_role_assignment" "subscription_contributor_system_identity" {
  count                                = var.options.assign_subscription_permissions && var.deployer.add_system_assigned_identity ? var.deployer_vm_count : 0
  provider                             = azurerm.main
  scope                                = data.azurerm_subscription.primary.id
  role_definition_name                 = "Reader"
  principal_id                         = azurerm_linux_virtual_machine.deployer[count.index].identity[0].principal_id
}

###############################################################################
#                                                                             #
#                            Managed Identity                                 #
#                                                                             #
###############################################################################

resource "azurerm_role_assignment" "deployer_msi" {
  provider                             = azurerm.main
  count                                = var.options.assign_resource_permissions && length(var.deployer.user_assigned_identity_id) == 0 ? 1 : 0
  scope                                = length(var.deployer.deployer_diagnostics_account_arm_id) > 0 ? var.deployer.deployer_diagnostics_account_arm_id : azurerm_storage_account.deployer[0].id
  role_definition_name                 = "Storage Blob Data Contributor"
  principal_id                         = azurerm_user_assigned_identity.deployer[0].principal_id
}

resource "azurerm_role_assignment" "resource_group_contributor_contributor_msi" {
  provider                             = azurerm.main
  count                                = var.options.assign_resource_permissions && length(var.deployer.user_assigned_identity_id) == 0 ? 1 : 0
  scope                                = var.infrastructure.resource_group.exists ? data.azurerm_resource_group.deployer[0].id : azurerm_resource_group.deployer[0].id
  role_definition_name                 = "Contributor"
  principal_id                         = azurerm_user_assigned_identity.deployer[0].principal_id
}


resource "azurerm_role_assignment" "role_assignment_msi" {
  provider                             = azurerm.main
  count                                = var.options.assign_resource_permissions && var.key_vault.enable_rbac_authorization && length(var.deployer.user_assigned_identity_id) == 0 ? 1 : 0
  scope                                = var.key_vault.exists ? data.azurerm_key_vault.kv_user[0].id : azurerm_key_vault.kv_user[0].id
  role_definition_name                 = "Key Vault Administrator"
  principal_id                         = azurerm_user_assigned_identity.deployer[0].principal_id
}


resource "azurerm_role_assignment" "role_assignment_msi_officer" {
  provider                             = azurerm.main
  count                                = var.options.assign_resource_permissions && var.key_vault.enable_rbac_authorization && length(var.deployer.user_assigned_identity_id) == 0 ? 1 : 0
  scope                                = var.key_vault.exists ? data.azurerm_key_vault.kv_user[0].id : azurerm_key_vault.kv_user[0].id
  role_definition_name                 = "Key Vault Secrets Officer"
  principal_id                         = azurerm_user_assigned_identity.deployer[0].principal_id

}

resource "azurerm_role_assignment" "resource_group_user_access_admin_msi" {
  provider                             = azurerm.main
  count                                = var.options.assign_resource_permissions && length(var.deployer.user_assigned_identity_id) == 0 ? 1 : 0
  scope                                = var.infrastructure.resource_group.exists ? data.azurerm_resource_group.deployer[0].id : azurerm_resource_group.deployer[0].id
  role_definition_name                 = "User Access Administrator"
  principal_id                         = azurerm_user_assigned_identity.deployer[0].principal_id

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

###############################################################################
#                                                                             #
#                            Service Principal                                #
#                                                                             #
###############################################################################

resource "azurerm_role_assignment" "resource_group_user_access_admin_spn" {
  provider                             = azurerm.main
  count                                = var.options.assign_resource_permissions && !local.run_as_msi ? 1 : 0
  scope                                = var.infrastructure.resource_group.exists ? data.azurerm_resource_group.deployer[0].id : azurerm_resource_group.deployer[0].id
  role_definition_name                 = "User Access Administrator"
  principal_type                       = "ServicePrincipal"
  principal_id                         = data.azurerm_client_config.current.object_id
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

resource "azurerm_role_assignment" "role_assignment_spn" {
  provider                             = azurerm.main
  count                                = var.options.assign_resource_permissions && var.key_vault.enable_rbac_authorization  && !local.run_as_msi ?  1 : 0
  scope                                = var.key_vault.exists ? data.azurerm_key_vault.kv_user[0].id : azurerm_key_vault.kv_user[0].id
  role_definition_name                 = "Key Vault Administrator"
  principal_type                       = "ServicePrincipal"
  principal_id                         = data.azurerm_client_config.current.object_id

}

resource "azurerm_role_assignment" "role_assignment_additional_users" {
  provider                             = azurerm.main
  count                                = var.options.assign_resource_permissions && var.key_vault.enable_rbac_authorization && !var.key_vault.exists && length(compact(var.additional_users_to_add_to_keyvault_policies)) > 0 ? (
                                           length(compact(var.additional_users_to_add_to_keyvault_policies))) : (
                                           0
                                         )
  scope                                = var.key_vault.exists ? data.azurerm_key_vault.kv_user[0].id : azurerm_key_vault.kv_user[0].id
  role_definition_name                 = "Key Vault Secrets Officer"
  principal_id                         = var.additional_users_to_add_to_keyvault_policies[count.index]
}

resource "azurerm_role_assignment" "role_assignment_webapp" {
  provider                             = azurerm.main
  count                                = var.options.assign_resource_permissions && var.key_vault.enable_rbac_authorization && !var.key_vault.exists  && var.app_service.use ? 1 : 0
  scope                                = var.key_vault.exists ? data.azurerm_key_vault.kv_user[0].id : azurerm_key_vault.kv_user[0].id
  role_definition_name                 = "Key Vault Secrets User"
  principal_id                         = azurerm_windows_web_app.webapp[0].identity[0].principal_id
}

#######################################4#######################################8
#                                                                              #
#                              Managed DevOps Pool                             #
#                                                                              #
#######################################4#######################################8


resource "azurerm_role_assignment" "dev_center_reader" {
  count                                         = var.options.assign_resource_permissions && var.infrastructure.dev_center_deployment && var.infrastructure.devops.DevOpsInfrastructure_object_id != "" ? 1 : 0
  scope                                         = var.infrastructure.resource_group.exists ? data.azurerm_resource_group.deployer[0].id : azurerm_resource_group.deployer[0].id
  role_definition_name                          = "Reader"
  principal_id                                  = var.infrastructure.devops.DevOpsInfrastructure_object_id
}

resource "azurerm_role_assignment" "dev_center_network_contributor" {
  count                                         = var.options.assign_resource_permissions && var.infrastructure.dev_center_deployment && var.infrastructure.devops.DevOpsInfrastructure_object_id != "" ? 1 : 0
  scope                                         = var.infrastructure.resource_group.exists ? data.azurerm_resource_group.deployer[0].id : azurerm_resource_group.deployer[0].id
  role_definition_name                          = "Network Contributor"
  principal_id                                  = var.infrastructure.devops.DevOpsInfrastructure_object_id
}

#########################################################################################
#                                                                                       #
#  Application configuration variables                                                  #
#                                                                                       #
#########################################################################################

resource "azurerm_role_assignment" "appconfig_data_owner_msi" {
  provider                             = azurerm.main
  count                                = var.options.assign_resource_permissions && var.app_config_service.deploy ? 1 : 0
  scope                                = var.app_config_service.deploy ? (
                                          length(var.app_config_service.id) == 0 ? (
                                            azurerm_app_configuration.app_config[0].id) : (
                                            data.azurerm_app_configuration.app_config[0].id)) : (
                                          0
                                          )
  role_definition_name                 = "App Configuration Data Owner"
  principal_id                         = length(var.deployer.user_assigned_identity_id) == 0 ? azurerm_user_assigned_identity.deployer[0].principal_id : data.azurerm_user_assigned_identity.deployer[0].principal_id
}

resource "azurerm_role_assignment" "appconfig_data_owner_spn" {
  provider                             = azurerm.main
  count                                = var.options.assign_resource_permissions && var.app_config_service.deploy && !local.run_as_msi ?  1 : 0
  scope                                = length(var.app_config_service.id) == 0 ? azurerm_app_configuration.app_config[0].id : data.azurerm_app_configuration.app_config[0].id
  role_definition_name                 = "App Configuration Data Owner"
  principal_type                       = "ServicePrincipal"
  principal_id                         = data.azurerm_client_config.current.object_id

}

locals {
  run_as_msi                           = length(var.deployer.user_assigned_identity_id) == 0 ? (
                                           var.bootstrap || var.options.use_spn ? false : azurerm_user_assigned_identity.deployer[0].principal_id == data.azurerm_client_config.current.object_id ) : (
                                           data.azurerm_user_assigned_identity.deployer[0].principal_id == data.azurerm_client_config.current.object_id
                                         )
}
