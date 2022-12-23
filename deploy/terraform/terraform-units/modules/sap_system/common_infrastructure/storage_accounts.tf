
#########################################################################################
#                                                                                       #
#  sapmnt                                                                               #
#                                                                                       #
#########################################################################################

resource "azurerm_storage_account" "sapmnt" {
  count = var.NFS_provider == "AFS" ? (
    length(var.azure_files_sapmnt_id) > 0 ? (
      0) : (
      1
    )) : (
    0
  )
  name = replace(
    lower(
      format("%s%s",
        local.prefix,
        local.resource_suffixes.sapmnt
      )
    ),
    "/[^a-z0-9]/",
    ""
  )
  resource_group_name = local.resource_group_exists ? (
    data.azurerm_resource_group.resource_group[0].name) : (
    azurerm_resource_group.resource_group[0].name
  )
  location                        = var.infrastructure.region
  account_tier                    = "Premium"
  account_replication_type        = "ZRS"
  account_kind                    = "FileStorage"
  enable_https_traffic_only       = false
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false

}
resource "azurerm_storage_account_network_rules" "sapmnt" {
  count = var.NFS_provider == "AFS" ? (
    length(var.azure_files_sapmnt_id) > 0 ? (
      0) : (
      1
    )) : (
    0
  )
  storage_account_id = azurerm_storage_account.sapmnt[0].id
  default_action     = "Deny"

  bypass = ["AzureServices", "Logging", "Metrics"]
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

resource "azurerm_private_dns_a_record" "sapmnt" {
  depends_on = [
    azurerm_private_endpoint.sapmnt
  ]
  count               = var.use_private_endpoint && var.use_custom_dns_a_registration ? 1 : 0
  name = replace(
    lower(
      format("%s%s",
        local.prefix,
        local.resource_suffixes.sapmnt
      )
    ),
    "/[^a-z0-9]/",
    ""
  )
  zone_name           = "privatelink.file.core.windows.net"
  resource_group_name = var.management_dns_resourcegroup_name
  ttl                 = 3600
  records             = [data.azurerm_network_interface.sapmnt[count.index].ip_configuration[0].private_ip_address]

  provider = azurerm.dnsmanagement

  lifecycle {
    ignore_changes = [tags]
  }
}

#Errors can occure when the dns record has not properly been activated, add a wait timer to give
#it just a little bit more time
resource "time_sleep" "wait_for_dns_refresh" {
  create_duration = "120s"

  depends_on = [azurerm_private_dns_a_record.sapmnt]
}

data "azurerm_storage_account" "sapmnt" {
  count = var.NFS_provider == "AFS" ? (
    length(var.azure_files_sapmnt_id) > 0 ? (
      1) : (
      0
    )) : (
    0
  )
  name                = split("/", var.azure_files_sapmnt_id)[8]
  resource_group_name = split("/", var.azure_files_sapmnt_id)[4]
}

resource "azurerm_private_endpoint" "sapmnt" {
  depends_on = [
    azurerm_storage_account.sapmnt
  ]

  provider = azurerm.main
  count = var.NFS_provider == "AFS" ? (
    length(var.azure_files_sapmnt_id) > 0 ? (
      0) : (
      1
    )) : (
    var.use_private_endpoint ? 1 : 0
  )
  name = format("%s%s%s",
    var.naming.resource_prefixes.storage_private_link_sapmnt,
    local.prefix,
    local.resource_suffixes.storage_private_link_sapmnt
  )
  resource_group_name = local.rg_name
  location = local.resource_group_exists ? (
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
    private_connection_resource_id = length(var.azure_files_sapmnt_id) > 0 ? (
      var.azure_files_sapmnt_id) : (
      azurerm_storage_account.sapmnt[0].id
    )
    subresource_names = [
      "File"
    ]
  }

  dynamic "private_dns_zone_group" {
    for_each = range(var.use_private_endpoint && var.use_custom_dns_a_registration ? 1 : 0)
    content {
      name                 = "privatelink.blob.core.windows.net"
      private_dns_zone_ids = [data.azurerm_private_dns_zone.storage[0].id]
    }
  }

  lifecycle {
    ignore_changes = [tags]
  }
}

data "azurerm_private_endpoint_connection" "sapmnt" {
  provider = azurerm.main
  count = var.NFS_provider == "AFS" ? (
    length(var.sapmnt_private_endpoint_id) > 0 ? (
      1) : (
      0
    )) : (
    0
  )
  name                = split("/", var.sapmnt_private_endpoint_id)[8]
  resource_group_name = split("/", var.sapmnt_private_endpoint_id)[4]

}


#########################################################################################
#                                                                                       #
#  NFS share                                                                            #
#                                                                                       #
#########################################################################################

resource "azurerm_storage_share" "sapmnt" {
  count = var.NFS_provider == "AFS" ? (1) : (0)
  depends_on = [
    azurerm_storage_account.sapmnt,
    azurerm_private_endpoint.sapmnt,
    time_sleep.wait_for_dns_refresh
  ]

  name = format("%s", local.resource_suffixes.sapmnt)
  storage_account_name = var.NFS_provider == "AFS" ? (
    length(var.azure_files_sapmnt_id) > 0 ? (
      data.azurerm_storage_account.sapmnt[0].name) : (
      azurerm_storage_account.sapmnt[0].name
    )
    ) : (
    ""
  )
  enabled_protocol = "NFS"

  quota = var.sapmnt_volume_size
}

#########################################################################################
#                                                                                       #
#  SMB share                                                                            #
#                                                                                       #
#########################################################################################

resource "azurerm_storage_share" "sapmnt_smb" {
  count = var.NFS_provider == "AFS" && local.app_tier_os == "WINDOWS" ? (
    length(var.azure_files_sapmnt_id) > 0 ? (
      0) : (
      1
    )) : (
    0
  )

  name                 = format("%s", local.resource_suffixes.sapmnt_smb)
  storage_account_name = var.NFS_provider == "AFS" ? azurerm_storage_account.sapmnt[0].name : ""
  enabled_protocol     = "SMB"

  quota = var.sapmnt_volume_size
}


data "azurerm_private_dns_zone" "storage" {
  count               = var.use_private_endpoint && var.use_custom_dns_a_registration ? 1 : 0
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = var.management_dns_resourcegroup_name
  provider = azurerm.dnsmanagement

}

data "azurerm_network_interface" "sapmnt" {
  count               = var.use_private_endpoint && length(var.azure_files_sapmnt_id) == 0  ? 1 : 0
  name                = azurerm_private_endpoint.sapmnt[count.index].network_interface[0].name
  resource_group_name = split("/", azurerm_private_endpoint.sapmnt[count.index].network_interface[0].id)[4]
}
