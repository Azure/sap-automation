data "azurerm_role_assignments" "resource_group_roles" {
  provider     = azurerm.main
  scope        = var.infrastructure.resource_group.exists ? data.azurerm_resource_group.deployer[0].id : azurerm_resource_group.deployer[0].id
  principal_id = data.azurerm_client_config.deployer.object_id
}

locals {

  resource_group_user_access_admin_list = flatten(
    [
      for assignments in data.azurerm_role_assignments.resource_group_roles.role_assignments : [
        {
          principal_id         = assignments.principal_id
          principal_type       = assignments.principal_type
          role_assignment_name = assignments.role_assignment_name
          role_definition_id   = assignments.role_definition_id
        }
      ]
      if endswith(assignments.role_definition_id, "/18d7d88d-d35e-4fb5-a5c3-7773c20a72d9")
    ]
  )

  isFullUserAccessAdminForResourceGroup = length(local.resource_group_user_access_admin_list) > 0

  resource_group_user_rbac_access_admin_list = flatten(
    [
      for assignments in data.azurerm_role_assignments.resource_group_roles.role_assignments : [
        {
          principal_id         = assignments.principal_id
          principal_type       = assignments.principal_type
          role_assignment_name = assignments.role_assignment_name
          role_definition_id   = assignments.role_definition_id
        }
      ]
      if endswith(assignments.role_definition_id, "/f58310d9-a9f6-439a-9e8d-f62e7b41a168")
    ]
  )

  isRBACUserAccessAdminForResourceGroup = length(local.resource_group_user_rbac_access_admin_list) > 0

  isUserAccessAdminForResourceGroup = local.isFullUserAccessAdminForResourceGroup || local.isRBACUserAccessAdminForResourceGroup

  resource_group_contributor_list = flatten(
    [
      for assignments in data.azurerm_role_assignments.resource_group_roles.role_assignments : [
        {
          principal_id         = assignments.principal_id
          principal_type       = assignments.principal_type
          role_assignment_name = assignments.role_assignment_name
          role_definition_id   = assignments.role_definition_id
        }
      ]
      if endswith(assignments.role_definition_id, "/b24988ac-6180-42a0-ab88-20f7382dd24c")
    ]
  )

  isContributorForResourceGroup = length(local.resource_group_contributor_list) > 0

}
