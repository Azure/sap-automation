/*
Description:

  Define infrastructure resources for deployer(s).
*/

// TODO: Example Documentation block follows:


/*--------------------------------------+---------------------------------------*
*                                                                               *
*                                RESOURCE GROUPS                                *
*                                                                               *
*---------------------------------------4---------------------------------------8
*/
resource "azurerm_resource_group" "deployer" {
  count    = !local.resource_group_exists ? 1 : 0
  name     = local.rg_name
  location = var.infrastructure.region
  tags     = var.infrastructure.tags

  lifecycle {
    ignore_changes = [
      tags
    ]
  }

}

data "azurerm_resource_group" "deployer" {
  count = local.resource_group_exists ? 1 : 0
  name  = local.rg_name
}
// TODO: Add management lock when this issue is addressed https://github.com/terraform-providers/terraform-provider-azurerm/issues/5473
//        Management lock should be implemented id a seperate Terraform workspace


// Create/Import management vnet
resource "azurerm_virtual_network" "vnet_mgmt" {
  count               = (!local.vnet_mgmt_exists) ? 1 : 0
  name                = local.vnet_mgmt_name
  resource_group_name = local.resource_group_exists ? data.azurerm_resource_group.deployer[0].name : azurerm_resource_group.deployer[0].name
  location            = local.resource_group_exists ? data.azurerm_resource_group.deployer[0].location : azurerm_resource_group.deployer[0].location
  address_space       = [local.vnet_mgmt_addr]
}

data "azurerm_virtual_network" "vnet_mgmt" {
  count               = (local.vnet_mgmt_exists) ? 1 : 0
  name                = split("/", local.vnet_mgmt_arm_id)[8]
  resource_group_name = split("/", local.vnet_mgmt_arm_id)[4]
}

// Create/Import management subnet
resource "azurerm_subnet" "subnet_mgmt" {
  count                = (!local.management_subnet_exists) ? 1 : 0
  name                 = local.management_subnet_name
  resource_group_name  = local.vnet_mgmt_exists ? data.azurerm_virtual_network.vnet_mgmt[0].resource_group_name : azurerm_virtual_network.vnet_mgmt[0].resource_group_name
  virtual_network_name = local.vnet_mgmt_exists ? data.azurerm_virtual_network.vnet_mgmt[0].name : azurerm_virtual_network.vnet_mgmt[0].name
  address_prefixes     = [local.management_subnet_prefix]

  private_endpoint_network_policies_enabled     = !var.use_private_endpoint
  private_link_service_network_policies_enabled = false

  service_endpoints = var.use_service_endpoint ? (
    var.use_webapp ? (
      ["Microsoft.Storage", "Microsoft.KeyVault", "Microsoft.Web"]) : (
      ["Microsoft.Storage", "Microsoft.KeyVault"]
    )) : (
  null)

}

data "azurerm_subnet" "subnet_mgmt" {
  count                = (local.management_subnet_exists) ? 1 : 0
  name                 = split("/", local.management_subnet_arm_id)[10]
  resource_group_name  = split("/", local.management_subnet_arm_id)[4]
  virtual_network_name = split("/", local.management_subnet_arm_id)[8]
}

// Creates boot diagnostics storage account for Deployer
resource "azurerm_storage_account" "deployer" {
  count                           = length(var.deployer.deployer_diagnostics_account_arm_id) > 0 ? 0 : 1
  name                            = local.storageaccount_names
  resource_group_name             = local.resource_group_exists ? data.azurerm_resource_group.deployer[0].name : azurerm_resource_group.deployer[0].name
  location                        = local.resource_group_exists ? data.azurerm_resource_group.deployer[0].location : azurerm_resource_group.deployer[0].location
  account_replication_type        = "LRS"
  account_tier                    = "Standard"
  enable_https_traffic_only       = local.enable_secure_transfer
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false
}

data "azurerm_storage_account" "deployer" {
  count               = length(var.deployer.deployer_diagnostics_account_arm_id) > 0 ? 1 : 0
  name                = split("/", var.deployer.deployer_diagnostics_account_arm_id)[8]
  resource_group_name = split("/", var.deployer.deployer_diagnostics_account_arm_id)[4]

}
