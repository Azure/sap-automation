
resource "azurerm_netapp_volume" "hanadata" {

  count = var.hana_ANF_data.use_ANF_for_HANA_data ? 1 : 0
  name = format("%s%s%s%s",
    var.naming.resource_prefixes.hanadata,
    local.prefix,
    var.naming.separator,
    local.resource_suffixes.hanadata
  )

  resource_group_name = local.ANF_pool_settings.resource_group_name
  location            = local.ANF_pool_settings.location
  account_name        = local.ANF_pool_settings.account_name
  pool_name           = local.ANF_pool_settings.pool_name
  volume_path         = format("%s%s", local.sid, local.resource_suffixes.hanadata)
  service_level       = local.ANF_pool_settings.service_level
  subnet_id           = local.ANF_pool_settings.subnet_id
  protocols           = ["NFSv4.1"]
  export_policy_rule {
    allowed_clients     = ["0.0.0.0/0"]
    protocols_enabled   = ["NFSv4.1"]
    rule_index          = 1
    unix_read_only      = false
    unix_read_write     = true
    root_access_enabled = true
  }
  storage_quota_in_gb = var.hana_ANF_data.HANA_data_volume_size

}

resource "azurerm_netapp_volume" "hanalog" {

  count = var.hana_ANF_data.use_ANF_for_HANA_log ? 1 : 0
  name = format("%s%s%s%s",
    var.naming.resource_prefixes.hanalog,
    local.prefix,
    var.naming.separator,
    local.resource_suffixes.hanalog
  )

  resource_group_name = local.ANF_pool_settings.resource_group_name
  location            = local.ANF_pool_settings.location
  account_name        = local.ANF_pool_settings.account_name
  pool_name           = local.ANF_pool_settings.pool_name
  volume_path         = format("%s%s", local.sid, local.resource_suffixes.hanalog)
  service_level       = local.ANF_pool_settings.service_level
  subnet_id           = local.ANF_pool_settings.subnet_id
  protocols           = ["NFSv4.1"]
  export_policy_rule {
    allowed_clients     = ["0.0.0.0/0"]
    protocols_enabled   = ["NFSv4.1"]
    rule_index          = 1
    unix_read_only      = false
    unix_read_write     = true
    root_access_enabled = true
  }
  storage_quota_in_gb = var.hana_ANF_data.HANA_log_volume_size

}
