
resource "azurerm_netapp_volume" "hanadata" {

  count = var.hana_ANF_volumes.use_for_data ? (
    var.hana_ANF_volumes.use_existing_data_volume ? (
      0
      ) : (
      local.hdb_ha ? 2 : 1
    )) : (
    0
  )
  name = format("%s%s%s%s%d",
    var.naming.resource_prefixes.hanadata,
    local.prefix,
    var.naming.separator,
    local.resource_suffixes.hanadata, count.index + 1
  )

  resource_group_name = local.ANF_pool_settings.resource_group_name
  location            = local.ANF_pool_settings.location
  account_name        = local.ANF_pool_settings.account_name
  pool_name           = local.ANF_pool_settings.pool_name
  volume_path         = format("%s%s-%d", local.sid, local.resource_suffixes.hanadata, count.index + 1)
  service_level       = local.ANF_pool_settings.service_level
  subnet_id           = local.ANF_pool_settings.subnet_id
  protocols           = ["NFSv4.1"]
  export_policy_rule {
    allowed_clients     = [azurerm_network_interface.nics_dbnodes_db[count.index].private_ip_address]
    protocols_enabled   = ["NFSv4.1"]
    rule_index          = 1
    unix_read_only      = false
    unix_read_write     = true
    root_access_enabled = true
  }
  storage_quota_in_gb = var.hana_ANF_volumes.data_volume_size
  throughput_in_mibps = var.hana_ANF_volumes.data_volume_throughput

  snapshot_directory_visible = true

}

data "azurerm_netapp_volume" "hanadata" {

  count = var.hana_ANF_volumes.use_for_data ? (
    var.hana_ANF_volumes.use_existing_data_volume ? (
      local.hdb_ha ? 2 : 1
      ) : (
      0
    )) : (
    0
  )
  resource_group_name = local.ANF_pool_settings.resource_group_name
  account_name        = local.ANF_pool_settings.account_name
  pool_name           = local.ANF_pool_settings.pool_name
  name                = var.hana_ANF_volumes.data_volume_name[count.index]

}


resource "azurerm_netapp_volume" "hanalog" {

  count = var.hana_ANF_volumes.use_for_log ? (
    var.hana_ANF_volumes.use_existing_log_volume ? (
      0
      ) : (
      local.hdb_ha ? 2 : 1
    )) : (
    0
  )
  name = format("%s%s%s%s%d",
    var.naming.resource_prefixes.hanalog,
    local.prefix,
    var.naming.separator,
    local.resource_suffixes.hanalog, count.index + 1
  )

  resource_group_name = local.ANF_pool_settings.resource_group_name
  location            = local.ANF_pool_settings.location
  account_name        = local.ANF_pool_settings.account_name
  pool_name           = local.ANF_pool_settings.pool_name
  volume_path         = format("%s%s-%d", local.sid, local.resource_suffixes.hanalog, count.index + 1)
  service_level       = local.ANF_pool_settings.service_level
  subnet_id           = local.ANF_pool_settings.subnet_id
  protocols           = ["NFSv4.1"]
  export_policy_rule {
    allowed_clients     = [azurerm_network_interface.nics_dbnodes_db[count.index].private_ip_address]
    protocols_enabled   = ["NFSv4.1"]
    rule_index          = 1
    unix_read_only      = false
    unix_read_write     = true
    root_access_enabled = true
  }

  storage_quota_in_gb = var.hana_ANF_volumes.log_volume_size
  throughput_in_mibps = var.hana_ANF_volumes.log_volume_throughput

  snapshot_directory_visible = true
}

data "azurerm_netapp_volume" "hanalog" {

  count = var.hana_ANF_volumes.use_for_log ? (
    var.hana_ANF_volumes.use_existing_log_volume ? (
      local.hdb_ha ? 2 : 1
      ) : (
      0
    )) : (
    0
  )
  resource_group_name = local.ANF_pool_settings.resource_group_name
  account_name        = local.ANF_pool_settings.account_name
  pool_name           = local.ANF_pool_settings.pool_name
  name                = var.hana_ANF_volumes.log_volume_name[count.index]

}

resource "azurerm_netapp_volume" "hanashared" {

  count = var.hana_ANF_volumes.use_for_shared ? (
    var.hana_ANF_volumes.use_existing_shared_volume ? (
      0
      ) : (
      local.hdb_ha ? 2 : 1
    )) : (
    0
  )
  name = format("%s%s%s%s%d",
    var.naming.resource_prefixes.hanashared,
    local.prefix,
    var.naming.separator,
    local.resource_suffixes.hanashared, count.index + 1
  )

  resource_group_name = local.ANF_pool_settings.resource_group_name
  location            = local.ANF_pool_settings.location
  account_name        = local.ANF_pool_settings.account_name
  pool_name           = local.ANF_pool_settings.pool_name
  volume_path         = format("%s%s-%d", local.sid, local.resource_suffixes.hanashared, count.index + 1)
  service_level       = local.ANF_pool_settings.service_level
  subnet_id           = local.ANF_pool_settings.subnet_id
  protocols           = ["NFSv4.1"]
  export_policy_rule {
    allowed_clients     = [azurerm_network_interface.nics_dbnodes_db[count.index].private_ip_address]
    protocols_enabled   = ["NFSv4.1"]
    rule_index          = 1
    unix_read_only      = false
    unix_read_write     = true
    root_access_enabled = true
  }
  storage_quota_in_gb = var.hana_ANF_volumes.shared_volume_size
  throughput_in_mibps = var.hana_ANF_volumes.shared_volume_throughput

  snapshot_directory_visible = true

}

data "azurerm_netapp_volume" "hanashared" {

  count = var.hana_ANF_volumes.use_for_shared ? (
    var.hana_ANF_volumes.use_existing_shared_volume ? (
      local.hdb_ha ? 2 : 1
      ) : (
      0
    )) : (
    0
  )
  resource_group_name = local.ANF_pool_settings.resource_group_name
  account_name        = local.ANF_pool_settings.account_name
  pool_name           = local.ANF_pool_settings.pool_name
  name                = var.hana_ANF_volumes.shared_volume_name[count.index]

}
