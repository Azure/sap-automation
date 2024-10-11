#######################################4#######################################8
#                                                                              #
#           Azure Net App Application Volume groupss for HANA                  #
#                                                                              #
#######################################4#######################################8

resource "azurerm_netapp_volume_group_sap_hana" "avg_HANA_full" {
  provider                             = azurerm.main
  depends_on                           = [ azurerm_linux_virtual_machine.vm_dbnode ]
  count                                = local.use_avg  ? length(var.database.zones) : 0
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

  volume                    {
                               name                          = format("%s%s%s%s%d",
                                                                var.naming.resource_prefixes.hanadata,
                                                                local.prefix,
                                                                var.naming.separator,
                                                                local.resource_suffixes.hanadata,
                                                                count.index + 1
                                                              )
                               volume_path                  = format("%s-%s%02d",
                                                                var.sap_sid,
                                                                local.resource_suffixes.hanadata,
                                                                count.index + 1
                                                              )
                               service_level                = local.ANF_pool_settings.service_level
                               capacity_pool_id             = data.azurerm_netapp_pool.workload_netapp_pool[0].id
                               subnet_id                    = try(local.ANF_pool_settings.subnet_id, "")
                               proximity_placement_group_id = var.ppg[count.index % max(length(var.database.zones), 1)]
                               volume_spec_name             = "data"
                               storage_quota_in_gb          = var.hana_ANF_volumes.data_volume_size
                               throughput_in_mibps          = upper(try(local.ANF_pool_settings.qos_type, "MANUAL")) == "AUTO" ? null : var.hana_ANF_volumes.data_volume_throughput

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

  volume                    {
                               name                          = format("%s%s%s%s%d",
                                                                var.naming.resource_prefixes.hanadata,
                                                                local.prefix,
                                                                var.naming.separator,
                                                                local.resource_suffixes.hanalog,
                                                                count.index + 1
                                                              )
                               volume_path                  = format("%s-%s%02d",
                                                                var.sap_sid,
                                                                local.resource_suffixes.hanalog,
                                                                count.index + 1
                                                              )
                               service_level                = local.ANF_pool_settings.service_level
                               capacity_pool_id             = data.azurerm_netapp_pool.workload_netapp_pool[0].id
                               subnet_id                    = try(local.ANF_pool_settings.subnet_id, "")
                               proximity_placement_group_id = var.ppg[count.index % max(length(var.database.zones), 1)]
                               volume_spec_name             = "log"
                               storage_quota_in_gb          = var.hana_ANF_volumes.log_volume_size
                               throughput_in_mibps          = upper(try(local.ANF_pool_settings.qos_type, "MANUAL")) == "AUTO" ? null : var.hana_ANF_volumes.log_volume_throughput

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

  dynamic "volume" {
                     iterator = pub
                     for_each = range(count.index < length(var.database.zones)  ? 1 : 0)
                     content {
                               name                         = format("%s%s%s%s%d",
                                                                var.naming.resource_prefixes.hanashared,
                                                                local.prefix,
                                                                var.naming.separator,
                                                                local.resource_suffixes.hanashared,
                                                                count.index + 1
                                                              )
                               volume_path                  =  format("%s-%s%02d",
                                                                var.sap_sid,
                                                                local.resource_suffixes.hanashared,
                                                                count.index + 1
                                                              )
                               service_level                = local.ANF_pool_settings.service_level
                               capacity_pool_id             = data.azurerm_netapp_pool.workload_netapp_pool[0].id
                               subnet_id                    = try(local.ANF_pool_settings.subnet_id, "")
                               proximity_placement_group_id = var.ppg[count.index % max(length(var.database.zones), 1)]
                               volume_spec_name             = "shared"
                               storage_quota_in_gb          = var.hana_ANF_volumes.shared_volume_size
                               throughput_in_mibps          = upper(try(local.ANF_pool_settings.qos_type, "MANUAL")) == "AUTO" ? null : var.hana_ANF_volumes.shared_volume_throughput
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


resource "azurerm_netapp_volume_group_sap_hana" "avg_HANA_data2" {
  provider                             = azurerm.main
  depends_on                           = [ azurerm_linux_virtual_machine.vm_dbnode ]
  count                                = local.use_avg && var.database_server_count / length(var.database.zones) > 1 ? length(var.database.zones) : 0
  name                                 = format("%s%s%s%sdata2_%d",
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

  volume                    {
                               name                          = format("%s%s%s%sdata_2%d",
                                                                var.naming.resource_prefixes.hanadata,
                                                                local.prefix,
                                                                var.naming.separator,
                                                                local.resource_suffixes.hanadata,
                                                                count.index + 1
                                                              )
                               volume_path                  = format("%s-%sdata2-%02d",
                                                                var.sap_sid,
                                                                local.resource_suffixes.hanadata,
                                                                count.index + 1
                                                              )
                               service_level                = local.ANF_pool_settings.service_level
                               capacity_pool_id             = data.azurerm_netapp_pool.workload_netapp_pool[0].id
                               subnet_id                    = try(local.ANF_pool_settings.subnet_id, "")
                               proximity_placement_group_id = var.ppg[count.index % max(length(var.database.zones), 1)]
                               volume_spec_name             = "data"
                               storage_quota_in_gb          = var.hana_ANF_volumes.data_volume_size
                               throughput_in_mibps          = upper(try(local.ANF_pool_settings.qos_type, "MANUAL")) == "AUTO" ? null : var.hana_ANF_volumes.data_volume_throughput

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

  volume                    {
                               name                          = format("%s%s%s%slog_2%d",
                                                                var.naming.resource_prefixes.hanadata,
                                                                local.prefix,
                                                                var.naming.separator,
                                                                local.resource_suffixes.hanalog,
                                                                count.index + 1
                                                              )
                               volume_path                  = format("%s-%s-log2%02d",
                                                                var.sap_sid,
                                                                local.resource_suffixes.hanalog,
                                                                count.index + 1
                                                              )
                               service_level                = local.ANF_pool_settings.service_level
                               capacity_pool_id             = data.azurerm_netapp_pool.workload_netapp_pool[0].id
                               subnet_id                    = try(local.ANF_pool_settings.subnet_id, "")
                               proximity_placement_group_id = var.ppg[count.index % max(length(var.database.zones), 1)]
                               volume_spec_name             = "log"
                               storage_quota_in_gb          = var.hana_ANF_volumes.log_volume_size
                               throughput_in_mibps          = upper(try(local.ANF_pool_settings.qos_type, "MANUAL")) == "AUTO" ? null : var.hana_ANF_volumes.log_volume_throughput

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


resource "azurerm_netapp_volume_group_sap_hana" "avg_HANA_data3" {
  provider                             = azurerm.main
  depends_on                           = [ azurerm_linux_virtual_machine.vm_dbnode ]
  count                                = local.use_avg && (var.database_server_count / length(var.database.zones) > 2) ? length(var.database.zones) : 0
  name                                 = format("%s%s%s%sdata3_%d",
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

  volume                    {
                               name                          = format("%s%s%s%sdata_3%d",
                                                                var.naming.resource_prefixes.hanadata,
                                                                local.prefix,
                                                                var.naming.separator,
                                                                local.resource_suffixes.hanadata,
                                                                count.index + 1
                                                              )
                               volume_path                  = format("%s-%sdata3-%02d",
                                                                var.sap_sid,
                                                                local.resource_suffixes.hanadata,
                                                                count.index + 1
                                                              )
                               service_level                = local.ANF_pool_settings.service_level
                               capacity_pool_id             = data.azurerm_netapp_pool.workload_netapp_pool[0].id
                               subnet_id                    = try(local.ANF_pool_settings.subnet_id, "")
                               proximity_placement_group_id = var.ppg[count.index % max(length(var.database.zones), 1)]
                               volume_spec_name             = "data"
                               storage_quota_in_gb          = var.hana_ANF_volumes.data_volume_size
                               throughput_in_mibps          = upper(try(local.ANF_pool_settings.qos_type, "MANUAL")) == "AUTO" ? null : var.hana_ANF_volumes.data_volume_throughput

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

  volume                    {
                               name                          = format("%s%s%s%slog_32%d",
                                                                var.naming.resource_prefixes.hanadata,
                                                                local.prefix,
                                                                var.naming.separator,
                                                                local.resource_suffixes.hanalog,
                                                                count.index + 1
                                                              )
                               volume_path                  = format("%s-%s-log2%02d",
                                                                var.sap_sid,
                                                                local.resource_suffixes.hanalog,
                                                                count.index + 1
                                                              )
                               service_level                = local.ANF_pool_settings.service_level
                               capacity_pool_id             = data.azurerm_netapp_pool.workload_netapp_pool[0].id
                               subnet_id                    = try(local.ANF_pool_settings.subnet_id, "")
                               proximity_placement_group_id = var.ppg[count.index % max(length(var.database.zones), 1)]
                               volume_spec_name             = "log"
                               storage_quota_in_gb          = var.hana_ANF_volumes.log_volume_size
                               throughput_in_mibps          = upper(try(local.ANF_pool_settings.qos_type, "MANUAL")) == "AUTO" ? null : var.hana_ANF_volumes.log_volume_throughput

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

