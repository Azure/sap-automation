#######################################4#######################################8
#                                                                              #
#                        Azure Net App Volumes for HANA                        #
#                                                                              #
#######################################4#######################################8

resource "azurerm_netapp_volume" "hanadata" {
  provider                             = azurerm.main
  count                                = length(local.ANF_pool_settings.pool_name) > 0 ? var.hana_ANF_volumes.use_for_data && !local.use_avg ? (
                                           var.hana_ANF_volumes.use_existing_data_volume ? (
                                             0
                                             ) : (
                                             (var.database_server_count - var.database.stand_by_node_count) * var.hana_ANF_volumes.data_volume_count
                                           )) : (
                                           0
                                         ) : 0
  name                                 = format("%s%s%s%s%d",
                                           var.naming.resource_prefixes.hanadata,
                                           local.prefix,
                                           var.naming.separator,
                                           local.resource_suffixes.hanadata, count.index + 1
                                         )

  resource_group_name                  = local.ANF_pool_settings.resource_group_name
  location                             = local.ANF_pool_settings.location

  account_name                         = local.ANF_pool_settings.account_name
  pool_name                            = local.ANF_pool_settings.pool_name
  volume_path                          = format("%s%s-%d", local.sid, local.resource_suffixes.hanadata, count.index + 1)
  service_level                        = local.ANF_pool_settings.service_level

  subnet_id                            = local.ANF_pool_settings.subnet_id
  zone                                 = local.db_zone_count > 0 && var.hana_ANF_volumes.use_zones ? try(local.zones[count.index], null) : null

  network_features                     = "Standard"
  protocols                            = ["NFSv4.1"]
  storage_quota_in_gb                  = var.hana_ANF_volumes.data_volume_size
  throughput_in_mibps                  = var.hana_ANF_volumes.data_volume_throughput

  snapshot_directory_visible           = true

  tags                                 = var.tags

  export_policy_rule {
                       allowed_clients     = ["0.0.0.0/0"]
                       protocols_enabled   = ["NFSv4.1"]
                       rule_index          = 1
                       unix_read_only      = false
                       unix_read_write     = true
                       root_access_enabled = true
                     }

}

data "azurerm_netapp_volume" "hanadata" {
  provider                             = azurerm.main

  depends_on                           = [azurerm_netapp_volume_group_sap_hana.avg_HANA]

  count                                = length(local.ANF_pool_settings.pool_name) > 0 ? var.hana_ANF_volumes.use_for_data ? (
                                          var.hana_ANF_volumes.use_existing_data_volume || local.use_avg ? (
                                            (var.database_server_count - var.database.stand_by_node_count) * var.hana_ANF_volumes.data_volume_count
                                            ) : (
                                            0
                                          )) : (
                                          0
                                        ) : 0
  name                                 = local.use_avg ? (
                                           format("%s%s%s%s%d",
                                             var.naming.resource_prefixes.hanadata,
                                             local.prefix,
                                             var.naming.separator,
                                             local.resource_suffixes.hanadata, count.index + 1
                                          )) : (
                                           var.hana_ANF_volumes.data_volume_name[count.index]
                                         )
  resource_group_name                  = local.ANF_pool_settings.resource_group_name
  account_name                         = local.ANF_pool_settings.account_name
  pool_name                            = local.ANF_pool_settings.pool_name

}


resource "azurerm_netapp_volume" "hanalog" {
  provider                             = azurerm.main
  depends_on                           = [azurerm_netapp_volume_group_sap_hana.avg_HANA]

  count                                = length(local.ANF_pool_settings.pool_name) > 0 ? var.hana_ANF_volumes.use_for_log && !local.use_avg ? (
                                           var.hana_ANF_volumes.use_existing_log_volume ? (
                                             0
                                             ) : (
                                             (var.database_server_count - var.database.stand_by_node_count) * var.hana_ANF_volumes.log_volume_count
                                           )) : (
                                           0
                                         ) : 0
  name                                 = format("%s%s%s%s%d",
                                           var.naming.resource_prefixes.hanalog,
                                           local.prefix,
                                           var.naming.separator,
                                           local.resource_suffixes.hanalog, count.index + 1
                                         )

  resource_group_name                  = local.ANF_pool_settings.resource_group_name
  location                             = local.ANF_pool_settings.location
  account_name                         = local.ANF_pool_settings.account_name
  pool_name                            = local.ANF_pool_settings.pool_name
  volume_path                          = format("%s%s-%d", local.sid, local.resource_suffixes.hanalog, count.index + 1)
  service_level                        = local.ANF_pool_settings.service_level
  subnet_id                            = local.ANF_pool_settings.subnet_id
  zone                                 = local.db_zone_count > 0 && var.hana_ANF_volumes.use_zones ? try(local.zones[count.index], null) : null

  network_features                     = "Standard"
  protocols                            = ["NFSv4.1"]
  storage_quota_in_gb                  = var.hana_ANF_volumes.log_volume_size
  throughput_in_mibps                  = var.hana_ANF_volumes.log_volume_throughput
  snapshot_directory_visible           = true

  tags                                 = var.tags

  export_policy_rule {
                       allowed_clients     = ["0.0.0.0/0"]
                       protocols_enabled   = ["NFSv4.1"]
                       rule_index          = 1
                       unix_read_only      = false
                       unix_read_write     = true
                       root_access_enabled = true
                     }


}

data "azurerm_netapp_volume" "hanalog" {
  provider                             = azurerm.main
  depends_on                           = [azurerm_netapp_volume_group_sap_hana.avg_HANA]

  count                                = length(local.ANF_pool_settings.pool_name) > 0 ? var.hana_ANF_volumes.use_for_log ? (
                                           var.hana_ANF_volumes.use_existing_log_volume || local.use_avg ? (
                                             (var.database_server_count - var.database.stand_by_node_count) * var.hana_ANF_volumes.log_volume_count
                                             ) : (
                                             0
                                           )) : (
                                           0
                                         ) : 0
  name                                 = local.use_avg ? (
                                           format("%s%s%s%s%d",
                                             var.naming.resource_prefixes.hanalog,
                                             local.prefix,
                                             var.naming.separator,
                                             local.resource_suffixes.hanalog, count.index + 1
                                               )) : (
                                           var.hana_ANF_volumes.log_volume_name[count.index]
                                           )
  resource_group_name                  = local.ANF_pool_settings.resource_group_name
  account_name                         = local.ANF_pool_settings.account_name
  pool_name                            = local.ANF_pool_settings.pool_name

}

resource "azurerm_netapp_volume" "hanashared" {
  provider                             = azurerm.main
  depends_on                           = [azurerm_netapp_volume_group_sap_hana.avg_HANA]

  count                                = length(local.ANF_pool_settings.pool_name) > 0 ? var.hana_ANF_volumes.use_for_shared && !local.use_avg ? (
                                           var.hana_ANF_volumes.use_existing_shared_volume ? (
                                             0
                                             ) : (
                                             1
                                           )) : (
                                           0
                                         ) : 0
  name                                 = format("%s%s%s%s%d",
                                           var.naming.resource_prefixes.hanashared,
                                           local.prefix,
                                           var.naming.separator,
                                           local.resource_suffixes.hanashared, count.index + 1
                                         )

  resource_group_name                  = local.ANF_pool_settings.resource_group_name
  location                             = local.ANF_pool_settings.location
  account_name                         = local.ANF_pool_settings.account_name
  pool_name                            = local.ANF_pool_settings.pool_name
  volume_path                          = format("%s%s-%d", local.sid, local.resource_suffixes.hanashared, count.index + 1)
  service_level                        = local.ANF_pool_settings.service_level
  subnet_id                            = local.ANF_pool_settings.subnet_id
  network_features                     = "Standard"
  protocols                            = ["NFSv4.1"]
  storage_quota_in_gb                  = var.hana_ANF_volumes.shared_volume_size
  throughput_in_mibps                  = var.hana_ANF_volumes.shared_volume_throughput


  zone = local.db_zone_count > 0 && var.hana_ANF_volumes.use_zones ? try(local.zones[count.index], null) : null

  snapshot_directory_visible           = true

  tags                                 = var.tags

  export_policy_rule {
                       allowed_clients     = ["0.0.0.0/0"]
                       protocols_enabled   = ["NFSv4.1"]
                       rule_index          = 1
                       unix_read_only      = false
                       unix_read_write     = true
                       root_access_enabled = true
                     }


}

data "azurerm_netapp_volume" "hanashared" {
  provider                             = azurerm.main
  depends_on                           = [azurerm_netapp_volume_group_sap_hana.avg_HANA]

  count                                = length(local.ANF_pool_settings.pool_name) > 0 ? var.hana_ANF_volumes.use_for_shared ? (
                                           var.hana_ANF_volumes.use_existing_shared_volume || local.use_avg ? (
                                             1
                                             ) : (
                                             0
                                           )) : (
                                           0
                                         ) : 0
  name                                 = local.use_avg ? (
                                        format("%s%s%s%s%d",
                                          var.naming.resource_prefixes.hanashared,
                                          local.prefix,
                                          var.naming.separator,
                                          local.resource_suffixes.hanashared, count.index + 1)
                                        ) : (
                                          var.hana_ANF_volumes.shared_volume_name[count.index]
                                        )
  resource_group_name                  = local.ANF_pool_settings.resource_group_name
  account_name                         = local.ANF_pool_settings.account_name
  pool_name                            = local.ANF_pool_settings.pool_name

}

