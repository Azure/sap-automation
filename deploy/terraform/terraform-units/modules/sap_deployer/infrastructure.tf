# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

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
  count                                = (!local.management_virtual_network_exists) ? 1 : 0
  name                                 = local.vnet_mgmt_name
  resource_group_name                  = local.resource_group_exists ? data.azurerm_resource_group.deployer[0].name : azurerm_resource_group.deployer[0].name
  location                             = local.resource_group_exists ? data.azurerm_resource_group.deployer[0].location : azurerm_resource_group.deployer[0].location
  address_space                        = [local.vnet_mgmt_addr]
  flow_timeout_in_minutes              = var.infrastructure.vnets.management.flow_timeout_in_minutes
  tags                                 = var.infrastructure.tags
}

data "azurerm_virtual_network" "vnet_mgmt" {
  count                                = (local.management_virtual_network_exists) ? 1 : 0
  name                                 = split("/", local.vnet_mgmt_arm_id)[8]
  resource_group_name                  = split("/", local.vnet_mgmt_arm_id)[4]
}

// Create/Import management subnet
resource "azurerm_subnet" "subnet_mgmt" {
  count                                = (!local.management_subnet_exists) ? 1 : 0
  name                                 = local.management_subnet_name
  resource_group_name                  = local.management_virtual_network_exists ? data.azurerm_virtual_network.vnet_mgmt[0].resource_group_name : azurerm_virtual_network.vnet_mgmt[0].resource_group_name
  virtual_network_name                 = local.management_virtual_network_exists ? data.azurerm_virtual_network.vnet_mgmt[0].name : azurerm_virtual_network.vnet_mgmt[0].name
  address_prefixes                     = [local.management_subnet_prefix]

  private_endpoint_network_policies    = !var.use_private_endpoint ? "Enabled" : "Disabled"

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
  depends_on                           = [ azurerm_subnet.subnet_mgmt ]
  count                                = length(var.deployer.deployer_diagnostics_account_arm_id) > 0 ? 0 : 1
  name                                 = local.storageaccount_names
  resource_group_name                  = local.resource_group_exists ? data.azurerm_resource_group.deployer[0].name : azurerm_resource_group.deployer[0].name
  location                             = local.resource_group_exists ? data.azurerm_resource_group.deployer[0].location : azurerm_resource_group.deployer[0].location
  account_replication_type             = "LRS"
  account_tier                         = "Standard"
  https_traffic_only_enabled            = local.enable_secure_transfer
  min_tls_version                      = "TLS1_2"
  allow_nested_items_to_be_public      = false
  shared_access_key_enabled            = var.deployer.shared_access_key_enabled

  cross_tenant_replication_enabled     = false

   network_rules {
    default_action                     = var.enable_firewall_for_keyvaults_and_storage ? "Deny" : "Allow"
    virtual_network_subnet_ids         = var.use_service_endpoint ? [(local.management_subnet_exists) ? local.management_subnet_arm_id : azurerm_subnet.subnet_mgmt[0].id] : null
    bypass                             = ["Metrics", "Logging", "AzureServices"]
  }

}

data "azurerm_storage_account" "deployer" {
  count                                = length(var.deployer.deployer_diagnostics_account_arm_id) > 0 ? 1 : 0
  name                                 = split("/", var.deployer.deployer_diagnostics_account_arm_id)[8]
  resource_group_name                  = split("/", var.deployer.deployer_diagnostics_account_arm_id)[4]

}

resource "azurerm_virtual_network_peering" "peering_management_agent" {
  provider                             = azurerm.main
  count                                = length(var.additional_network_id) > 0 ? 1 : 0
  name                                 = substr(
                                           format("%s_to_%s",
                                             split("/", var.additional_network_id)[8],
                                             local.management_virtual_network_exists ? (
                                               data.azurerm_virtual_network.vnet_mgmt[0].name) : (
                                               azurerm_virtual_network.vnet_mgmt[0].name
                                             )
                                           ),
                                           0,
                                           80
                                         )
  resource_group_name                  = local.resource_group_exists ? (
                                           data.azurerm_resource_group.deployer[0].name) : (
                                           azurerm_resource_group.deployer[0].name
                                         )

  remote_virtual_network_id            = data.azurerm_virtual_network.agent_virtual_network[0].id

  virtual_network_name                 = local.management_virtual_network_exists ? (
                                               data.azurerm_virtual_network.vnet_mgmt[0].name) : (
                                               azurerm_virtual_network.vnet_mgmt[0].name
                                             )

  allow_virtual_network_access         = true
}

resource "azurerm_virtual_network_peering" "peering_agent_management" {
  provider                             = azurerm.main
  count                                = length(var.additional_network_id) > 0 ? 1:0

  name                                 = substr(
                                           format("%s_to_%s",
                                               local.management_virtual_network_exists ? (
                                                data.azurerm_virtual_network.vnet_mgmt[0].name) : (
                                                azurerm_virtual_network.vnet_mgmt[0].name
                                             ),
                                             split("/", var.additional_network_id)[8]
                                           ),
                                           0,
                                           80
                                         )
  resource_group_name                  = split("/", var.additional_network_id)[4]
  virtual_network_name                 = split("/", var.additional_network_id)[8]
  remote_virtual_network_id            = local.management_virtual_network_exists ? (
                                               data.azurerm_virtual_network.vnet_mgmt[0].id) : (
                                               azurerm_virtual_network.vnet_mgmt[0].id
                                             )
  allow_virtual_network_access         = true
  allow_forwarded_traffic              = true
}


data "azurerm_virtual_network" "agent_virtual_network" {
  count                                = length(var.additional_network_id) > 0 ? 1:0
  name                                 = split("/", var.additional_network_id)[8]
  resource_group_name                  = split("/", var.additional_network_id)[4]
}



