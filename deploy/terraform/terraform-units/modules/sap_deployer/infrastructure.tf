/*
Description:

  Define infrastructure resources for deployer(s).
*/

// TODO: Example Documentation block follows:


/*-------------------------------------+---------------------------------------*
*                                                                              *
*                                RESOURCE GROUPS                               *
*                                                                              *
*--------------------------------------4---------------------------------------8
*/
resource "azurerm_resource_group" "deployer" {
  count                                = !local.resource_group_exists ? 1 : 0
  name                                 = local.resourcegroup_name
  location                             = var.infrastructure.region
  tags                                 = var.infrastructure.tags

  lifecycle {
              ignore_changes = [
                tags
              ]
            }

}

data "azurerm_resource_group" "deployer" {
  count                                = local.resource_group_exists ? 1 : 0
  name                                 = local.resourcegroup_name
}
// TODO: Add management lock when this issue is addressed https://github.com/terraform-providers/terraform-provider-azurerm/issues/5473
//        Management lock should be implemented id a seperate Terraform workspace


// Create/Import management vnet
resource "azurerm_virtual_network" "vnet_mgmt" {
  count                                = (!local.vnet_mgmt_exists) ? 1 : 0
  name                                 = local.vnet_mgmt_name
  resource_group_name                  = local.resource_group_exists ? data.azurerm_resource_group.deployer[0].name : azurerm_resource_group.deployer[0].name
  location                             = local.resource_group_exists ? data.azurerm_resource_group.deployer[0].location : azurerm_resource_group.deployer[0].location
  address_space                        = [local.vnet_mgmt_addr]
}

data "azurerm_virtual_network" "vnet_mgmt" {
  count                                = (local.vnet_mgmt_exists) ? 1 : 0
  name                                 = split("/", local.vnet_mgmt_arm_id)[8]
  resource_group_name                  = split("/", local.vnet_mgmt_arm_id)[4]
}

// Create/Import management subnet
resource "azurerm_subnet" "subnet_mgmt" {
  count                                = (!local.management_subnet_exists) ? 1 : 0
  name                                 = local.management_subnet_name
  resource_group_name                  = local.vnet_mgmt_exists ? data.azurerm_virtual_network.vnet_mgmt[0].resource_group_name : azurerm_virtual_network.vnet_mgmt[0].resource_group_name
  virtual_network_name                 = local.vnet_mgmt_exists ? data.azurerm_virtual_network.vnet_mgmt[0].name : azurerm_virtual_network.vnet_mgmt[0].name
  address_prefixes                     = [local.management_subnet_prefix]

  private_endpoint_network_policies_enabled     = !var.use_private_endpoint

  service_endpoints                    = var.use_service_endpoint ? (
                                           var.use_webapp ? (
                                             ["Microsoft.Storage", "Microsoft.KeyVault", "Microsoft.Web"]) : (
                                             ["Microsoft.Storage", "Microsoft.KeyVault"]
                                           )) : (
                                         null)

}

data "azurerm_subnet" "subnet_mgmt" {
  count                                = (local.management_subnet_exists) ? 1 : 0
  name                                 = split("/", local.management_subnet_arm_id)[10]
  resource_group_name                  = split("/", local.management_subnet_arm_id)[4]
  virtual_network_name                 = split("/", local.management_subnet_arm_id)[8]
}

// Creates boot diagnostics storage account for Deployer
resource "azurerm_storage_account" "deployer" {
  count                                = length(var.deployer.deployer_diagnostics_account_arm_id) > 0 ? 0 : 1
  name                                 = local.storageaccount_names
  resource_group_name                  = local.resource_group_exists ? data.azurerm_resource_group.deployer[0].name : azurerm_resource_group.deployer[0].name
  location                             = local.resource_group_exists ? data.azurerm_resource_group.deployer[0].location : azurerm_resource_group.deployer[0].location
  account_replication_type             = "LRS"
  account_tier                         = "Standard"
  enable_https_traffic_only            = local.enable_secure_transfer
  min_tls_version                      = "TLS1_2"
  allow_nested_items_to_be_public      = false
  shared_access_key_enabled            = var.deployer.shared_access_key_enabled
}

data "azurerm_storage_account" "deployer" {
  count                                = length(var.deployer.deployer_diagnostics_account_arm_id) > 0 ? 1 : 0
  name                                 = split("/", var.deployer.deployer_diagnostics_account_arm_id)[8]
  resource_group_name                  = split("/", var.deployer.deployer_diagnostics_account_arm_id)[4]

}

resource "azurerm_role_assignment" "deployer_boot_diagnostics_contributor" {
  provider                             = azurerm.main
  count                                = var.assign_subscription_permissions && var.deployer.add_system_assigned_identity ? var.deployer_vm_count : 0
  scope                                = length(var.deployer.deployer_diagnostics_account_arm_id) > 0 ? var.deployer.deployer_diagnostics_account_arm_id : azurerm_storage_account.deployer[0].id
  role_definition_name                 = "Storage Account Contributor"
  principal_id                         = azurerm_linux_virtual_machine.deployer[count.index].identity[0].principal_id
}

resource "azurerm_role_assignment" "deployer_boot_diagnostics_contributor_msi" {
  provider                             = azurerm.main
  count                                = var.assign_subscription_permissions ? 1 : 0
  scope                                = length(var.deployer.deployer_diagnostics_account_arm_id) > 0 ? var.deployer.deployer_diagnostics_account_arm_id : azurerm_storage_account.deployer[0].id
  role_definition_name                 = "Storage Account Contributor"
  principal_id                         = length(var.deployer.user_assigned_identity_id) == 0 ? azurerm_user_assigned_identity.deployer[0].principal_id : data.azurerm_user_assigned_identity.deployer[0].principal_id
}

resource "azurerm_role_assignment" "resource_group_contributor" {
  provider                             = azurerm.main
  count                                = var.assign_subscription_permissions && var.deployer.add_system_assigned_identity ? var.deployer_vm_count : 0
  scope                                = local.resource_group_exists ? data.azurerm_resource_group.deployer[0].id : azurerm_resource_group.deployer[0].id
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

resource "azurerm_role_assignment" "resource_group_acsservice" {
  provider                             = azurerm.main
  count                                = var.assign_subscription_permissions && var.deployer.add_system_assigned_identity ? var.deployer_vm_count : 0
  scope                                = local.resource_group_exists ? data.azurerm_resource_group.deployer[0].id : azurerm_resource_group.deployer[0].id
  role_definition_name                 = "Azure Center for SAP solutions administrator"
  principal_id                         = azurerm_linux_virtual_machine.deployer[count.index].identity[0].principal_id
}

resource "azurerm_role_assignment" "resource_group_acsservice_msi" {
  provider                             = azurerm.main
  count                                = var.assign_subscription_permissions ? 1 : 0
  scope                                = local.resource_group_exists ? data.azurerm_resource_group.deployer[0].id : azurerm_resource_group.deployer[0].id
  role_definition_name                 = "Azure Center for SAP solutions administrator"
  principal_id                         = length(var.deployer.user_assigned_identity_id) == 0 ? azurerm_user_assigned_identity.deployer[0].principal_id : data.azurerm_user_assigned_identity.deployer[0].principal_id
}

