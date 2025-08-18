resource "azurerm_role_assignment" "resource_group_user_access_admin" {
  provider                             = azurerm.deployer
  count                                = var.options.assign_permissions && contains(keys(var.deployer_tfstate),"deployer_uai") ? 1 : 0
  scope                                = local.resource_group_exists ? (
                                                                   data.azurerm_resource_group.resource_group[0].id) : (
                                                                   try(azurerm_resource_group.resource_group[0].id, "")
                                                                 )
  role_definition_name                 = "User Access Administrator"
  principal_id                         = var.deployer_tfstate.deployer_uai.principal_id
}

