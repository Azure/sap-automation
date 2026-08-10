# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

################################################################################
#                                                                              #
#                     Utility storage accounts                                 #
#                                                                              #
################################################################################

locals {

  # Flatten file shares across all accounts, preserving parent account index
  utility_file_shares = flatten([
    for acct_idx, acct in var.utility_storage_settings : [
      for share in acct.file_shares : {
        acct_index = acct_idx
        name       = share.name
        quota      = share.quota
        protocol   = share.protocol
      }
    ]
  ])

  # Flatten blob containers across all accounts, preserving parent account index
  utility_blob_containers = flatten([
    for acct_idx, acct in var.utility_storage_settings : [
      for container in acct.blob_containers : {
        acct_index          = acct_idx
        policy_key          = format("%s/%s", acct.name, container.name)
        name                = container.name
        immutability_policy = container.immutability_policy
      }
    ]
  ])

  utility_blob_container_immutability_policies = {
    for container_idx, container in local.utility_blob_containers : container.policy_key => {
      container_index            = container_idx
      immutability_period_in_days = container.immutability_policy.immutability_period_in_days
      locked                      = container.immutability_policy.locked
      protected_append_writes     = container.immutability_policy.protected_append_writes
    } if container.immutability_policy != null
  }

  # Account indices that have at least one file share (for file PEs)
  utility_accounts_with_file_shares = [
    for idx, acct in var.utility_storage_settings : idx if length(acct.file_shares) > 0
  ]

  # Account indices that have at least one blob container (for blob PEs)
  utility_accounts_with_blob_containers = [
    for idx, acct in var.utility_storage_settings : idx if length(acct.blob_containers) > 0
  ]

}

################################################################################
#                                                                              #
#                     Utility storage account resources                        #
#                                                                              #
################################################################################

resource "azurerm_storage_account" "utility" {
  #checkov:skip=CKV_AZURE_35: public access needed for utility share
  #checkov:skip=CKV2_AZURE_38: soft-delete not required by default
  #checkov:skip=CKV2_AZURE_1: no CMK infra provisioned by default
  #checkov:skip=CKV_AZURE_36: bypass includes AzureServices, checkov cannot resolve it past the dynamic blocks
  provider                             = azurerm.main
  count                                = length(var.utility_storage_settings)
  depends_on                           = [
                                           azurerm_virtual_network_peering.peering_management_sap,
                                           azurerm_virtual_network_peering.peering_sap_management,
                                           azurerm_virtual_network_peering.peering_additional_network_sap,
                                           azurerm_virtual_network_peering.peering_sap_additional_network,
                                         ]
  name                                 = replace(
                                           lower(
                                             format("%s", local.landscape_utility_storage_account_names[count.index])
                                           ),
                                           "/[^a-z0-9]/",
                                           ""
                                         )
  resource_group_name                  = local.resource_group_exists ? (
                                           data.azurerm_resource_group.resource_group[0].name) : (
                                           azurerm_resource_group.resource_group[0].name
                                         )
  location                             = local.resource_group_exists ? (
                                          data.azurerm_resource_group.resource_group[0].location) : (
                                          azurerm_resource_group.resource_group[0].location
                                        )

  account_kind                         = var.utility_storage_settings[count.index].account_kind
  account_tier                         = var.utility_storage_settings[count.index].account_tier
  account_replication_type             = var.utility_storage_settings[count.index].account_replication_type
  https_traffic_only_enabled           = var.utility_storage_settings[count.index].https_traffic_only_enabled
  min_tls_version                      = "TLS1_2"
  allow_nested_items_to_be_public      = false
  cross_tenant_replication_enabled     = false
  public_network_access_enabled        = var.public_network_access_enabled

  shared_access_key_enabled            = var.utility_storage_settings[count.index].account_kind == "FileStorage" ? (
                                           var.infrastructure.shared_access_key_enabled_nfs) : (
                                           var.infrastructure.shared_access_key_enabled
                                         )
  default_to_oauth_authentication      = true

  network_rules {
                  default_action              = var.enable_firewall_for_keyvaults_and_storage ? "Deny" : "Allow"
                  ip_rules                    = var.public_network_access_enabled && var.utility_storage_settings[count.index].https_traffic_only_enabled ? compact([
                                                  length(local.deployer_public_ip_address) > 0 ? local.deployer_public_ip_address : "",
                                                  length(var.Agent_IP) > 0 ? var.Agent_IP : ""
                                                ]) : []
                  virtual_network_subnet_ids  = var.public_network_access_enabled ? compact([
                                                  (var.infrastructure.virtual_networks.sap.subnet_db.defined || var.infrastructure.virtual_networks.sap.subnet_db.exists) ? (
                                                    var.infrastructure.virtual_networks.sap.subnet_db.exists ? var.infrastructure.virtual_networks.sap.subnet_db.id : azurerm_subnet.db[0].id) : (
                                                    null
                                                  ),
                                                  (var.infrastructure.virtual_networks.sap.subnet_app.defined || var.infrastructure.virtual_networks.sap.subnet_app.exists) ? (
                                                    var.infrastructure.virtual_networks.sap.subnet_app.exists ? var.infrastructure.virtual_networks.sap.subnet_app.id : azurerm_subnet.app[0].id) : (
                                                    null
                                                  ),
                                                  length(local.deployer_subnet_management_id) > 0 ? local.deployer_subnet_management_id : null,
                                                  length(var.infrastructure.additional_subnet_id) > 0 ? var.infrastructure.additional_subnet_id : null
                                                ]) : null
                  bypass                      = ["Metrics", "Logging", "AzureServices"]
                }

  dynamic "blob_properties" {
    for_each                                  = var.utility_storage_settings[count.index].versioning_enabled ? [1] : []
    content {
      versioning_enabled                      = true
    }
  }

  dynamic "immutability_policy" {
    for_each                                  = var.utility_storage_settings[count.index].version_level_immutability == null ? [] : [
                                                var.utility_storage_settings[count.index].version_level_immutability
                                              ]
    content {
      state                                   = immutability_policy.value.state
      period_since_creation_in_days           = immutability_policy.value.immutability_period_in_days
      allow_protected_append_writes           = immutability_policy.value.allow_protected_append_writes
    }
  }

  tags                                 = var.tags

  lifecycle {
              ignore_changes = [network_rules[0].virtual_network_subnet_ids]
            }
}


################################################################################
#                                                                              #
#                     Utility file shares                                      #
#                                                                              #
################################################################################

resource "azurerm_storage_share" "utility" {
  provider                             = azurerm.main
  count                                = length(local.utility_file_shares)

  name                                 = local.utility_file_shares[count.index].name
  storage_account_id                   = azurerm_storage_account.utility[local.utility_file_shares[count.index].acct_index].id
  enabled_protocol                     = local.utility_file_shares[count.index].protocol
  quota                                = local.utility_file_shares[count.index].quota

}


################################################################################
#                                                                              #
#                     Utility blob containers                                  #
#                                                                              #
################################################################################

resource "azurerm_storage_container" "utility" {
  #checkov:skip=CKV2_AZURE_21: no Log Analytics workspace dependency
  provider                             = azurerm.main
  count                                = length(local.utility_blob_containers)

  name                                 = local.utility_blob_containers[count.index].name
  storage_account_id                   = azurerm_storage_account.utility[local.utility_blob_containers[count.index].acct_index].id
  container_access_type                = "private"

}


resource "azurerm_storage_container_immutability_policy" "utility" {
  provider                              = azurerm.main
  for_each                              = local.utility_blob_container_immutability_policies

  storage_container_resource_manager_id = azurerm_storage_container.utility[each.value.container_index].id
  immutability_period_in_days            = each.value.immutability_period_in_days
  locked                                 = each.value.locked
  protected_append_writes_enabled        = each.value.protected_append_writes == "append_blobs"
  protected_append_writes_all_enabled    = each.value.protected_append_writes == "all"

}


################################################################################
#                                                                              #
#                     Utility file private endpoints                           #
#                                                                              #
################################################################################

resource "azurerm_private_endpoint" "utility_file" {
  provider                             = azurerm.main
  depends_on                           = [
                                           azurerm_subnet.app,
                                           azurerm_private_dns_zone_virtual_network_link.vnet_sap_file
                                         ]
  count                                = var.use_private_endpoint && (
                                           var.infrastructure.virtual_networks.sap.subnet_app.defined || var.infrastructure.virtual_networks.sap.subnet_app.exists
                                         ) ? length(local.utility_accounts_with_file_shares) : 0

  name                                 = format("%s%s%s%02d",
                                           var.naming.resource_prefixes.storage_private_link_utility_file,
                                           local.prefix,
                                           local.resource_suffixes.storage_private_link_utility_file,
                                           local.utility_accounts_with_file_shares[count.index]
                                         )
  tags                                 = var.tags
  custom_network_interface_name        = format("%s%s%s%02d%s",
                                           var.naming.resource_prefixes.storage_private_link_utility_file,
                                           local.prefix,
                                           local.resource_suffixes.storage_private_link_utility_file,
                                           local.utility_accounts_with_file_shares[count.index],
                                           var.naming.resource_suffixes.nic
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

  private_service_connection {
                               name = format("%s%s%s%02d",
                                 var.naming.resource_prefixes.storage_private_svc_utility_file,
                                 local.prefix,
                                 local.resource_suffixes.storage_private_svc_utility_file,
                                 local.utility_accounts_with_file_shares[count.index]
                               )
                               is_manual_connection          = false
                               private_connection_resource_id = azurerm_storage_account.utility[local.utility_accounts_with_file_shares[count.index]].id
                               subresource_names = [
                                 "File"
                               ]
                             }

  dynamic "private_dns_zone_group" {
                                     for_each = range(var.dns_settings.register_endpoints_with_dns ? 1 : 0)
                                     content {
                                       name                 = var.dns_settings.dns_zone_names.file_dns_zone_name
                                       private_dns_zone_ids = local.privatelink_file_defined ? (
                                        [var.dns_settings.privatelink_file_id]) : (
                                        [data.azurerm_private_dns_zone.file[0].id]
                                        )
                                     }
                                   }

  timeouts {
             create = "10m"
             delete = "30m"
           }
}


################################################################################
#                                                                              #
#                     Utility blob private endpoints                           #
#                                                                              #
################################################################################

resource "azurerm_private_endpoint" "utility_blob" {
  provider                             = azurerm.main
  depends_on                           = [
                                           azurerm_subnet.app,
                                           azurerm_private_dns_zone_virtual_network_link.vnet_sap
                                         ]
  count                                = var.use_private_endpoint && (
                                           var.infrastructure.virtual_networks.sap.subnet_app.defined || var.infrastructure.virtual_networks.sap.subnet_app.exists
                                         ) ? length(local.utility_accounts_with_blob_containers) : 0

  name                                 = format("%s%s%s%02d",
                                           var.naming.resource_prefixes.storage_private_link_utility_blob,
                                           local.prefix,
                                           local.resource_suffixes.storage_private_link_utility_blob,
                                           local.utility_accounts_with_blob_containers[count.index]
                                         )
  tags                                 = var.tags
  custom_network_interface_name        = format("%s%s%s%02d%s",
                                           var.naming.resource_prefixes.storage_private_link_utility_blob,
                                           local.prefix,
                                           local.resource_suffixes.storage_private_link_utility_blob,
                                           local.utility_accounts_with_blob_containers[count.index],
                                           var.naming.resource_suffixes.nic
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

  private_service_connection {
                               name = format("%s%s%s%02d",
                                 var.naming.resource_prefixes.storage_private_svc_utility_blob,
                                 local.prefix,
                                 local.resource_suffixes.storage_private_svc_utility_blob,
                                 local.utility_accounts_with_blob_containers[count.index]
                               )
                               is_manual_connection          = false
                               private_connection_resource_id = azurerm_storage_account.utility[local.utility_accounts_with_blob_containers[count.index]].id
                               subresource_names = [
                                 "blob"
                               ]
                             }

  dynamic "private_dns_zone_group" {
                                     for_each = range(var.dns_settings.register_endpoints_with_dns ? 1 : 0)
                                     content {
                                       name                 = var.dns_settings.dns_zone_names.blob_dns_zone_name
                                       private_dns_zone_ids = local.privatelink_storage_defined ? (
                                        [var.dns_settings.privatelink_storage_id]) : (
                                        [data.azurerm_private_dns_zone.storage[0].id]
                                        )
                                     }
                                   }

  timeouts {
             create = "10m"
             delete = "30m"
           }
}
