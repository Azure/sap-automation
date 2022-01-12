data "azurerm_storage_account" "transport" {
  provider = azurerm.main
  count = var.NFS_provider == "AFS" ? (
    length(var.azure_files_transport_storage_account_id) > 0 ? (
      1) : (
      0
    )) : (
    0
  )
  name                = split("/", var.azure_files_transport_storage_account_id)[8]
  resource_group_name = split("/", var.azure_files_transport_storage_account_id)[4]
}


resource "azurerm_storage_account" "transport" {
  provider = azurerm.main
  count = var.NFS_provider == "AFS" ? (
    length(var.azure_files_transport_storage_account_id) > 0 ? (
      0) : (
      1
    )) : (
    0
  )
  name                      = replace(lower(format("%s", local.landscape_shared_transport_storage_account_name)), "/[^a-z0-9]/", "")
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
        local.sub_web_existing ? local.sub_web_arm_id : azurerm_subnet.web[0].id,
        local.deployer_subnet_mgmt_id
      ]
    )
    bypass = ["AzureServices", "Logging", "Metrics"]
  }
}

resource "azurerm_storage_share" "transport" {
  provider = azurerm.main
  count = var.NFS_provider == "AFS" ? (
    length(var.azure_files_transport_storage_account_id) > 0 ? (
      0) : (
      1
    )) : (
    0
  )

  name                 = format("%s", local.resource_suffixes.transport_volume)
  storage_account_name = azurerm_storage_account.transport[0].name
  enabled_protocol     = "NFS"

  quota = var.transport_volume_size
}
