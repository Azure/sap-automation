resource "azurerm_role_assignment" "storage_tfstate" {
  provider                             = azurerm.main
  count                                = var.storage_account_sapbits.exists ? 0 : var.infrastructure.assign_permissions ? 1 : 0
  # count                                = var.enable_storage_role_assignment && !local.sa_tfstate_exists ? 1 : 0
  scope                                = azurerm_storage_account.storage_tfstate[0].id
  role_definition_name                 = "Storage Blob Data Contributor"
  principal_id                         = data.azuread_client_config.current.object_id

  lifecycle {
    create_before_destroy              = true
  }

}

resource "azurerm_role_assignment" "blob_msi" {
  provider                             = azurerm.main
  count                                = var.deployer_tfstate.deployer_msi_id != data.azuread_client_config.current.object_id && var.infrastructure.assign_permissions && var.deployer.use ? (
                                           length(try(var.deployer_tfstate.deployer_msi_id, "")) > 0 ? 1 : 0) : (
                                           0
                                           )
  scope                                = azurerm_storage_account.storage_tfstate[0].id
  role_definition_name                 = "Storage Blob Data Contributor"
  principal_id                         = var.deployer_tfstate.deployer_msi_id
}

resource "azurerm_role_assignment" "webapp_table" {
  provider                             = azurerm.main
  count                                = var.infrastructure.assign_permissions && var.deployer.use ? (
                                           length(try(var.deployer_tfstate.deployer_msi_id, "")) > 0 ? 1 : 0) : (
                                           0
                                           )
  scope                                = azurerm_storage_account.storage_tfstate[0].id
  role_definition_name                 = "Storage Table Data Contributor"
  principal_id                         = var.deployer_tfstate.deployer_msi_id
}
resource "azurerm_role_assignment" "dns_msi" {
  provider                             = azurerm.main
  count                                = var.infrastructure.assign_permissions && var.deployer.use ? (
                                           length(try(var.deployer_tfstate.deployer_msi_id, "")) > 0 ? 1 : 0) : (
                                           0
                                           )
  scope                                = var.infrastructure.resource_group.exists ? (
                                                 data.azurerm_resource_group.library[0].id) : (
                                                 azurerm_resource_group.library[0].id
                                               )
  role_definition_name                 = "Private DNS Zone Contributor"
  principal_id                         = var.deployer_tfstate.deployer_msi_id
}


resource "azurerm_role_assignment" "dns_spn" {
  provider                             = azurerm.main
  count                                = var.infrastructure.assign_permissions && length(var.infrastructure.spn_id) > 0 ? 1 : 0
  scope                                = var.infrastructure.resource_group.exists ? (
                                                 data.azurerm_resource_group.library[0].id) : (
                                                 azurerm_resource_group.library[0].id
                                               )
  role_definition_name                 = "Private DNS Zone Contributor"
  principal_type                       = "ServicePrincipal"
  principal_id                         = var.infrastructure.spn_id
}

resource "azurerm_role_assignment" "resource_group_contributor_msi" {
  provider                             = azurerm.main
  count                                = var.infrastructure.assign_permissions && var.deployer.use ? (
                                           length(try(var.deployer_tfstate.deployer_msi_id, "")) > 0 ? 1 : 0) : (
                                           0
                                           )
  scope                                = var.infrastructure.resource_group.exists ? (
                                                 data.azurerm_resource_group.library[0].id) : (
                                                 azurerm_resource_group.library[0].id
                                               )
  role_definition_name                 = "Contributor"
  principal_id                         = var.deployer_tfstate.deployer_msi_id
}

resource "azurerm_role_assignment" "resource_group_contributor_spn" {
  provider                             = azurerm.main
  count                                = var.infrastructure.assign_permissions && length(var.infrastructure.spn_id) > 0 && try(var.deployer_tfstate.deployer_msi_id, "") != var.infrastructure.spn_id ? 1 : 0
  scope                                = var.infrastructure.resource_group.exists ? (
                                                 data.azurerm_resource_group.library[0].id) : (
                                                 azurerm_resource_group.library[0].id
                                               )
  role_definition_name                 = "Contributor"
  principal_type                       = "ServicePrincipal"
  principal_id                         = var.infrastructure.spn_id
}


resource "azurerm_role_assignment" "resource_group_user_access_admin_spn" {
  provider                             = azurerm.main
  count                                = var.infrastructure.assign_permissions && length(var.infrastructure.spn_id) > 0 ? 0 : 0
  scope                                = var.infrastructure.resource_group.exists ? (
                                                 data.azurerm_resource_group.library[0].id) : (
                                                 azurerm_resource_group.library[0].id
                                               )
  role_definition_name                 = "User Access Administrator"
  principal_type                       = "ServicePrincipal"
  principal_id                         = var.infrastructure.spn_id
  condition_version                    = "2.0"
  condition                            = <<-EOT
                                            (
                                             (
                                              !(ActionMatches{'Microsoft.Authorization/roleAssignments/write'})
                                             )
                                             OR
                                             (
                                              @Request[Microsoft.Authorization/roleAssignments:RoleDefinitionId] ForAnyOfAnyValues:GuidNotEquals {8e3af657-a8ff-443c-a75c-2fe8c4bcb635, 18d7d88d-d35e-4fb5-a5c3-7773c20a72d9, f58310d9-a9f6-439a-9e8d-f62e7b41a168}
                                             )
                                            )
                                            AND
                                            (
                                             (
                                              !(ActionMatches{'Microsoft.Authorization/roleAssignments/delete'})
                                             )
                                             OR
                                             (
                                              @Resource[Microsoft.Authorization/roleAssignments:RoleDefinitionId] ForAnyOfAnyValues:GuidNotEquals {8e3af657-a8ff-443c-a75c-2fe8c4bcb635, 18d7d88d-d35e-4fb5-a5c3-7773c20a72d9, f58310d9-a9f6-439a-9e8d-f62e7b41a168}
                                             )
                                            )
                                            EOT
}


resource "azurerm_role_assignment" "storage_sapbits" {
  provider                             = azurerm.main
  count                                = var.storage_account_sapbits.exists ? 0 : var.infrastructure.assign_permissions ? 1 : 0
  # count                                = var.enable_storage_role_assignment && !local.sa_tfstate_exists ? 1 : 0
  scope                                = azurerm_storage_account.storage_sapbits[0].id
  role_definition_name                 = "Storage Blob Data Contributor"
  principal_id                         = data.azuread_client_config.current.object_id

}
