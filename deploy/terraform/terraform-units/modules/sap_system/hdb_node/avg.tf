#######################################4#######################################8
#                                                                              #
#           Azure Net App Application Volume groupss for HANA                  #
#                                                                              #
#######################################4#######################################8

resource "azurerm_netapp_volume_group_sap_hana" "avg_HANA" {
  provider                             = azurerm.main
  count                                = local.use_avg  ? length(var.ppg) : 0
  name                                 = format("%s%s%s%s%d",
                                           var.naming.resource_prefixes.hana_avg,
                                           local.prefix,
                                           var.naming.separator,
                                           local.resource_suffixes.hana_avg, count.index + 1
                                         )
  resource_group_name                  = local.ANF_pool_settings.resource_group_name
  location                             = local.ANF_pool_settings.location

  account_name                         = local.ANF_pool_settings.account_name
  group_description                    = format("Application Volume %d group for %s", count.index + 1, var.sap_sid)
  application_identifier               = local.sid

  dynamic "volume" {
                     iterator = pub
                     for_each = (count.index == 0 ? local.volumes_primary : local.volumes_secondary)
                     content {
                               name                         = pub.value.name
                               volume_path                  = pub.value.path
                               service_level                = local.ANF_pool_settings.service_level
                               capacity_pool_id             = data.azurerm_netapp_pool.workload_netapp_pool[0].id
                               subnet_id                    = try(local.ANF_pool_settings.subnet_id, "")
                               proximity_placement_group_id = pub.value.proximityPlacementGroup
                               volume_spec_name             = pub.value.volumeSpecName
                               storage_quota_in_gb          = pub.value.storage_quota_in_gb
                               throughput_in_mibps          = pub.value.throughput_in_mibps
                               protocols                    = ["NFSv4.1"]
                               security_style               = "unix"
                               snapshot_directory_visible   = false

                               export_policy_rule {
                                                    rule_index          = 1
                                                    allowed_clients     = "0.0.0.0/0"
                                                    nfsv3_enabled       = false
                                                    nfsv41_enabled      = true
                                                    unix_read_only      = false
                                                    unix_read_write     = true
                                                    root_access_enabled = true
                                                  }
                             }
                   }

}


data "azurerm_netapp_pool" "workload_netapp_pool" {
  provider                             = azurerm.main
  count                                = length(local.ANF_pool_settings.pool_name) > 0 ? 1 : 0
  resource_group_name                  = data.azurerm_netapp_account.workload_netapp_account[0].resource_group_name
  name                                 = try(local.ANF_pool_settings.pool_name, "")
  account_name                         = local.ANF_pool_settings.account_name

}

data "azurerm_netapp_account" "workload_netapp_account" {
  provider                             = azurerm.main
  count                                = length(local.ANF_pool_settings.account_id) > 0 ? 1 : 0
  name                                 = try(split("/", local.ANF_pool_settings.account_id)[8], "")
  resource_group_name                  = try(split("/", local.ANF_pool_settings.account_id)[4], "")
}


locals {
  use_avg = (
              var.hana_ANF_volumes.use_AVG_for_data) && (
              var.hana_ANF_volumes.use_for_data || var.hana_ANF_volumes.use_for_log || var.hana_ANF_volumes.use_for_shared
            ) && !var.use_scalesets_for_deployment

  hana_data1 = {
                 name = format("%s%s%s%s%d",
                   var.naming.resource_prefixes.hanadata,
                   local.prefix,
                   var.naming.separator,
                   local.resource_suffixes.hanadata, 1
                 )
                 path = format("%s-%s%02d",
                   var.sap_sid,
                   local.resource_suffixes.hanadata,
                   1
                 )
                 volumeSpecName          = "data"
                 proximityPlacementGroup = length(var.scale_set_id) == 0 ? try(var.ppg[0], null) : null
                 storage_quota_in_gb     = var.hana_ANF_volumes.data_volume_size
                 throughput_in_mibps     = var.hana_ANF_volumes.data_volume_throughput
                 zone                    = local.db_zone_count > 0 ? try(local.zones[0], null) : null
               }

  hana_data2 = {
                 name = format("%s%s%s%s%d",
                   var.naming.resource_prefixes.hanadata,
                   local.prefix,
                   var.naming.separator,
                   local.resource_suffixes.hanadata, 2
                 )
                 path = format("%s-%s%02d",
                   var.sap_sid,
                   local.resource_suffixes.hanadata,
                   2
                 )
                 volumeSpecName          = "data"
                 proximityPlacementGroup = length(var.scale_set_id) == 0 ? (length(var.ppg) > 1 ? try(var.ppg[1], null) : try(var.ppg[0], null)) : null
                 storage_quota_in_gb     = var.hana_ANF_volumes.data_volume_size
                 throughput_in_mibps     = var.hana_ANF_volumes.data_volume_throughput
                 zone                    = local.db_zone_count > 1 ? try(local.zones[1], null) : null

               }

  hana_log1 = {
                name = format("%s%s%s%s%d",
                  var.naming.resource_prefixes.hanalog,
                  local.prefix,
                  var.naming.separator,
                  local.resource_suffixes.hanalog, 1
                )
                path = format("%s-%s%02d",
                  var.sap_sid,
                  local.resource_suffixes.hanalog,
                  1
                )
                volumeSpecName          = "log"
                proximityPlacementGroup = length(var.scale_set_id) == 0 ? try(var.ppg[0], null) : null
                storage_quota_in_gb     = var.hana_ANF_volumes.log_volume_size
                throughput_in_mibps     = var.hana_ANF_volumes.log_volume_throughput
                zone                    = local.db_zone_count > 0 ? try(local.zones[0], null) : null
              }

  hana_log2 = {
                name = format("%s%s%s%s%d",
                  var.naming.resource_prefixes.hanalog,
                  local.prefix,
                  var.naming.separator,
                  local.resource_suffixes.hanalog, 2
                )
                path = format("%s-%s%02d",
                  var.sap_sid,
                  local.resource_suffixes.hanalog,
                  2
                )
                volumeSpecName          = "log"
                proximityPlacementGroup = length(var.scale_set_id) == 0 ? (length(var.ppg) > 1 ? try(var.ppg[1], null) : try(var.ppg[0], null)) : null
                storage_quota_in_gb     = var.hana_ANF_volumes.log_volume_size
                throughput_in_mibps     = var.hana_ANF_volumes.log_volume_throughput
                zone                    = local.db_zone_count > 1 ? try(local.zones[1], null) : null
              }

  hana_shared1 = {
                   name = format("%s%s%s%s%d",
                     var.naming.resource_prefixes.hanashared,
                     local.prefix,
                     var.naming.separator,
                     local.resource_suffixes.hanashared, 1
                   )
                   path = format("%s-%s%02d",
                     var.sap_sid,
                     local.resource_suffixes.hanashared,
                     1
                   )
                   volumeSpecName          = "shared"
                   proximityPlacementGroup = length(var.scale_set_id) == 0 ? try(var.ppg[0], null) : null
                   storage_quota_in_gb     = var.hana_ANF_volumes.shared_volume_size
                   throughput_in_mibps     = var.hana_ANF_volumes.shared_volume_throughput
                   zone                    = local.db_zone_count > 0 ? try(local.zones[0], null) : null
                 }

  hana_shared2 = {
                   name = format("%s%s%s%s%d",
                     var.naming.resource_prefixes.hanashared,
                     local.prefix,
                     var.naming.separator,
                     local.resource_suffixes.hanashared, 2
                   )
                   path = format("%s-%s%02d",
                     var.sap_sid,
                     local.resource_suffixes.hanashared,
                     2
                   )
                   volumeSpecName          = "shared"

                     proximityPlacementGroup = length(var.scale_set_id) == 0 ? (length(var.ppg) > 1 ? try(var.ppg[1], null) : try(var.ppg[0], null)) : null
                   storage_quota_in_gb     = var.hana_ANF_volumes.shared_volume_size
                   throughput_in_mibps     = var.hana_ANF_volumes.shared_volume_throughput
                   zone                    = local.db_zone_count > 1 ? try(local.zones[1], null) : null
                 }

  volumes_primary   = [
                        local.hana_data1, local.hana_log1, local.hana_shared1
                      ]
  volumes_secondary = [
                        local.hana_data2, local.hana_log2, local.hana_shared2
                      ]

}
