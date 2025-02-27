# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.


resource "azurerm_storage_account" "hanashared" {
  provider                             = azurerm.main
  count                                = var.NFS_provider == "AFS" && var.database.scale_out ? (
                                           try(length(var.hanashared_id) > 0, false) ? (
                                             0) : (
                                             var.use_single_hana_shared ? 1 : length(var.database.zones)
                                           )) : (
                                           0
                                         )
  name                                 = substr(replace(
                                           lower(
                                             format("%s%s%s%01d",
                                               local.prefix,
                                               local.resource_suffixes.hanasharedafs,
                                               try(
                                                 local.resource_suffixes.hanasharedafs_id,
                                                 substr(var.random_id,0,3)
                                               ),
                                               count.index + 1  # Bumping with 1 to not have overlap with the sapmnnt storage account
                                             )
                                           ),
                                           "/[^a-z0-9]/",
                                           ""
                                         ), 0, 24)


  resource_group_name                  = var.resource_group[0].name
  location                             = var.resource_group[0].location
  account_tier                         = "Premium"
  account_replication_type             = "ZRS"
  account_kind                         = "FileStorage"
  https_traffic_only_enabled            = false
  min_tls_version                      = "TLS1_2"
  allow_nested_items_to_be_public      = false
  cross_tenant_replication_enabled     = false

  shared_access_key_enabled            = var.infrastructure.shared_access_key_enabled_nfs
  tags                                 = var.tags

  network_rules {
                  default_action       = var.enable_firewall_for_keyvaults_and_storage ? "Deny" : "Allow"
                  bypass               = ["Metrics", "Logging", "AzureServices"]
            virtual_network_subnet_ids = compact(
                                                 [
                                                   try(var.landscape_tfstate.admin_subnet_id, ""),
                                                   try(var.landscape_tfstate.app_subnet_id, ""),
                                                   try(var.landscape_tfstate.db_subnet_id, ""),
                                                   try(var.landscape_tfstate.web_subnet_id, ""),
                                                   try(var.landscape_tfstate.subnet_mgmt_id, "")
                                                 ]
                                               )
          }
}

#########################################################################################
#                                                                                       #
#  NFS share                                                                            #
#                                                                                       #
#########################################################################################

resource "azurerm_storage_share" "hanashared" {
  provider                             = azurerm.main
   count                                = var.NFS_provider == "AFS" && var.database.scale_out ? (
                                           length(try(var.hanashared_id, "")) > 0 ? (
                                             0) : (
                                             length(var.database.zones)
                                           )) : (
                                           0
                                         )
 depends_on                           = [
                                           azurerm_storage_account.hanashared,
                                           azurerm_private_endpoint.hanashared,
                                           time_sleep.wait_for_private_endpoints
                                         ]

  name                                 = format("%s%01d",
                                          local.resource_suffixes.hanashared,
                                          count.index+1
                                         )
  storage_account_id                   = var.NFS_provider == "AFS" ? (
                                           length(try(var.hanashared_id, "")) > 0 ? (
                                             var.hanashared_id[var.use_single_hana_shared ? 0 : count.index]) : (
                                             azurerm_storage_account.hanashared[var.use_single_hana_shared ? 0 : count.index].id
                                           )
                                           ) : (
                                           ""
                                         )
  enabled_protocol                     = "NFS"

  quota                                = var.hanashared_volume_size
}

resource "azurerm_private_endpoint" "hanashared" {
  provider                             = azurerm.main
  count                                = var.NFS_provider == "AFS" && var.use_private_endpoint && var.database.scale_out ? (
                                          length(try(var.hanashared_private_endpoint_id, "")) > 0 ? (
                                            0) : (
                                            var.use_single_hana_shared ? 1 : length(var.database.zones)
                                          )) : (
                                          0
                                        )
  name                                 = format("%s%s%s%s",
                                           var.naming.resource_prefixes.storage_privatelink_hanashared,
                                           local.prefix,
                                           var.use_single_hana_shared ? "" : tostring(count.index),
                                           local.resource_suffixes.storage_privatelink_hanashared
                                         )

  resource_group_name                  = var.resource_group[0].name
  location                             = var.resource_group[0].location

  subnet_id                            = try(var.landscape_tfstate.use_separate_storage_subnet, false) ? (
                                         var.landscape_tfstate.storage_subnet_id ) : (
                                         var.landscape_tfstate.admin_subnet_id
                                       )
  tags                                 = var.tags

  custom_network_interface_name        = format("%s%s%s%s%s",
                                           var.naming.resource_prefixes.storage_privatelink_hanashared,
                                           local.prefix,
                                           var.naming.resource_suffixes.storage_privatelink_hanashared,
                                           var.use_single_hana_shared ? "" : tostring(count.index),
                                           var.naming.resource_suffixes.nic
                                         )


  private_service_connection {
                              name = format("%s%s%s%s",
                                var.naming.resource_prefixes.storage_privatelink_hanashared,
                                local.prefix,
                                var.use_single_hana_shared ? "" : tostring(count.index),
                                local.resource_suffixes.storage_privatelink_hanashared
                              )
                              is_manual_connection = false
                              private_connection_resource_id = length(try(var.hanashared_id, "")) > 0 ? (
                                var.hanashared_id[var.use_single_hana_shared ? 0 : count.index]) : (
                                azurerm_storage_account.hanashared[var.use_single_hana_shared ? 0 : count.index].id
                              )
                              subresource_names = [
                                "File"
                              ]
                            }


  dynamic "private_dns_zone_group" {
                                     for_each = range(length(try(var.landscape_tfstate.privatelink_file_id, "")) > 0 && var.dns_settings.register_endpoints_with_dns ? 1 : 0)
                                     content {
                                       name                 = var.dns_settings.dns_zone_names.file_dns_zone_name
                                       private_dns_zone_ids = [var.landscape_tfstate.privatelink_file_id]
                                     }
                                   }

  timeouts {
             create = "10m"
             delete = "30m"
           }
}

#Private endpoint tend to take a while to be created, so we need to wait for it to be ready before we can use it
resource "time_sleep" "wait_for_private_endpoints" {
  create_duration                      = "120s"

  depends_on                           = [ azurerm_private_endpoint.hanashared ]
}

data "azurerm_private_endpoint_connection" "hanashared" {
  provider                             = azurerm.main
  count                                = var.NFS_provider == "AFS" && var.use_private_endpoint && var.database.scale_out && try(length(var.hanashared_private_endpoint_id) > 0, false) ? (
                                           length(var.hanashared_private_endpoint_id) > 0 ? (
                                             length(var.database.zones)) : (
                                             0
                                           )) : (
                                           0
                                         )
  name                                 = split("/", var.hanashared_private_endpoint_id[count.index])[8]
  resource_group_name                  = split("/", var.hanashared_private_endpoint_id[count.index])[4]

}
