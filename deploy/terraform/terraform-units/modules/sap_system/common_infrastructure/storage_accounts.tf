data "azurerm_storage_account" "shared" {
  count = var.NFS_provider == "AFS" ? (
    length(var.azure_files_storage_account_id) > 0 ? (
      1) : (
      0
    )) : (
    0
  )
  name                = split("/", var.azure_files_storage_account_id)[8]
  resource_group_name = split("/", var.azure_files_storage_account_id)[4]
}


resource "azurerm_storage_account" "shared" {
  count = var.NFS_provider == "AFS" ? (
    length(var.azure_files_storage_account_id) > 0 ? (
      0) : (
      1
    )) : (
    0
  )
  name = replace(
    lower(
      format("%s%s",
        local.prefix,
        local.resource_suffixes.install_volume
      )
    ),
    "/[^a-z0-9]/",
    ""
  )
  resource_group_name = local.rg_exists ? (
    data.azurerm_resource_group.resource_group[0].name) : (
    azurerm_resource_group.resource_group[0].name
  )
  location                  = var.infrastructure.region
  account_tier              = "Premium"
  account_replication_type  = "ZRS"
  account_kind              = "FileStorage"
  enable_https_traffic_only = false

}

resource "azurerm_storage_account_network_rules" "shared" {
  count = var.NFS_provider == "AFS" && var.use_private_endpoint ? (
    1) : (
    0
  )
  provider           = azurerm.main
  storage_account_id = azurerm_storage_account.shared[0].id

  default_action = "Deny"
  ip_rules       = length(var.Agent_IP) > 0 ? [var.Agent_IP] : null
  virtual_network_subnet_ids = compact(
    [
      try(var.landscape_tfstate.admin_subnet_id, ""),
      try(var.landscape_tfstate.app_subnet_id, ""),
      try(var.landscape_tfstate.db_subnet_id, ""),
      try(var.landscape_tfstate.subnet_mgmt_id, "")
    ]
  )
  bypass = ["AzureServices", "Logging", "Metrics"]

}


resource "azurerm_storage_share" "install" {
  count = var.NFS_provider == "AFS" ? (
    length(var.azure_files_storage_account_id) > 0 ? (
      0) : (
      1
    )) : (
    0
  )

  name                 = format("%s", local.resource_suffixes.install_volume)
  storage_account_name = var.NFS_provider == "AFS" ? azurerm_storage_account.shared[0].name : ""
  enabled_protocol     = "NFS"

  quota = 128
}

resource "azurerm_storage_account_network_rules" "install" {
  count = var.NFS_provider == "AFS" && var.use_private_endpoint ? (
    length(var.azure_files_storage_account_id) > 0 ? (
      0) : (
      0
    )) : (
    0
  )

  storage_account_id = azurerm_storage_account.shared[0].id

  default_action = "Deny"
  ip_rules       = [var.Agent_IP]
  virtual_network_subnet_ids = compact([
    try(var.landscape_tfstate.app_subnet_id, ""),
    try(var.landscape_tfstate.db_subnet_id, ""),
    try(var.landscape_tfstate.web_subnet_id, ""),
    try(var.landscape_tfstate.subnet_management_id, "")]
  )
  bypass = ["AzureServices", "Logging", "Metrics"]

}

resource "azurerm_storage_share" "sapmnt" {
  count = var.NFS_provider == "AFS" ? (
    length(var.azure_files_storage_account_id) > 0 ? (
      0) : (
      1
    )) : (
    0
  )

  name                 = format("%s", local.resource_suffixes.sapmnt)
  storage_account_name = var.NFS_provider == "AFS" ? azurerm_storage_account.shared[0].name : ""
  enabled_protocol     = "NFS"

  quota = var.sapmnt_volume_size
}

resource "azurerm_private_endpoint" "shared" {
  provider = azurerm.main
  count = var.NFS_provider == "AFS" ? (
    length(var.azure_files_storage_account_id) > 0 ? (
      0) : (
      1
    )) : (
    0
  )
  name = format("%s%s%s",
    var.naming.resource_prefixes.storage_private_link_install,
    local.prefix,
    local.resource_suffixes.storage_private_link_install
  )
  resource_group_name = local.rg_name
  location = local.rg_exists ? (
    data.azurerm_resource_group.resource_group[0].location) : (
    azurerm_resource_group.resource_group[0].location
  )
  subnet_id = try(var.landscape_tfstate.app_subnet_id, "")


  private_service_connection {
    name = format("%s%s%s",
      var.naming.resource_prefixes.storage_private_svc_install,
      local.prefix,
      local.resource_suffixes.storage_private_svc_install
    )
    is_manual_connection = false
    private_connection_resource_id = length(var.azure_files_storage_account_id) > 0 ? (
      data.azurerm_storage_account.shared[0].id) : (
      azurerm_storage_account.shared[0].id
    )
    subresource_names = [
      "File"
    ]
  }
}


