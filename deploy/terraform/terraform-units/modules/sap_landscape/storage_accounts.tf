resource "azurerm_storage_account" "shared" {
  name                      = replace(lower(format("%s%s", local.prefix, local.landscape_shared_storageaccount_name)), "/[^a-z0-9]/", "")
  resource_group_name       = local.rg_exists ? data.azurerm_resource_group.resource_group[0].name : azurerm_resource_group.resource_group[0].name
  location                  = var.infrastructure.region
  account_tier              = "Premium"
  account_replication_type  = "ZRS"
  account_kind              = "FileStorage"
  enable_https_traffic_only = false


  network_rules {
    default_action = "Deny"
    virtual_network_subnet_ids = compact(
      [
        local.sub_admin_existing ? local.sub_admin_arm_id : azurerm_subnet.admin[0].id,
        local.sub_app_existing ? local.sub_app_arm_id : azurerm_subnet.app[0].id,
        local.sub_db_existing ? local.sub_db_arm_id : azurerm_subnet.db[0].id,
        local.sub_web_existing ? local.sub_web_arm_id : azurerm_subnet.web[0].id
      ]
    )
    bypass = ["AzureServices", "Logging", "Metrics"]
  }
}

