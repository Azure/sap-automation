################################################################################
#                                                                              # 
#                     Diagnostics storage account                              #
#                                                                              # 
################################################################################

resource "azurerm_storage_account" "storage_bootdiag" {
  provider = azurerm.main
  count    = length(var.diagnostics_storage_account.arm_id) > 0 ? 0 : 1
  name     = local.storageaccount_name
  resource_group_name = local.rg_exists ? (
    data.azurerm_resource_group.resource_group[0].name) : (
    azurerm_resource_group.resource_group[0].name
  )
  location = local.rg_exists ? (
    data.azurerm_resource_group.resource_group[0].location) : (
    azurerm_resource_group.resource_group[0].location
  )
  account_replication_type  = "LRS"
  account_tier              = "Standard"
  enable_https_traffic_only = true

}

resource "azurerm_storage_account_network_rules" "storage_bootdiag" {
  count = length(var.diagnostics_storage_account.arm_id) > 0 ? (
    0) : (
    var.use_private_endpoint ? (
      1) : (
      0
    )
  )
  provider           = azurerm.main
  storage_account_id = azurerm_storage_account.storage_bootdiag[0].id

  default_action = "Deny"
  ip_rules       = length(var.Agent_IP) > 0 ? [var.Agent_IP] : null
  virtual_network_subnet_ids = compact(
    [
      local.admin_subnet_existing ? (
        local.admin_subnet_arm_id) : (
        azurerm_subnet.admin[0].id
      ),
      local.application_subnet_existing ? (
        local.application_subnet_arm_id) : (
        azurerm_subnet.app[0].id
      ),
      local.database_subnet_existing ? (
        local.database_subnet_arm_id) : (
        azurerm_subnet.db[0].id
      ),
      local.web_subnet_existing ? (
        local.web_subnet_arm_id) : (
        azurerm_subnet.web[0].id
      ),
      local.deployer_subnet_management_id
    ]
  )
  bypass = ["AzureServices", "Logging", "Metrics"]

}


data "azurerm_storage_account" "storage_bootdiag" {
  provider            = azurerm.main
  count               = length(var.diagnostics_storage_account.arm_id) > 0 ? 1 : 0
  name                = split("/", var.diagnostics_storage_account.arm_id)[8]
  resource_group_name = split("/", var.diagnostics_storage_account.arm_id)[4]
}

resource "azurerm_private_endpoint" "storage_bootdiag" {
  provider = azurerm.main
  count    = var.use_private_endpoint && local.admin_subnet_defined && (length(var.diagnostics_storage_account.arm_id) == 0) ? 1 : 0
  name = format("%s%s%s",
    var.naming.resource_prefixes.storage_private_link_diag,
    local.prefix,
    local.resource_suffixes.storage_private_link_diag
  )
  resource_group_name = local.rg_name
  location            = local.rg_exists ? data.azurerm_resource_group.resource_group[0].location : azurerm_resource_group.resource_group[0].location
  subnet_id = local.admin_subnet_defined ? (
    local.admin_subnet_existing ? (
      local.admin_subnet_arm_id) : (
      azurerm_subnet.admin[0].id
    )) : (
    ""
  )

  private_service_connection {
    name = format("%s%s%s",
      var.naming.resource_prefixes.storage_private_svc_diag,
      local.prefix,
      local.resource_suffixes.storage_private_svc_diag
    )
    is_manual_connection = false
    private_connection_resource_id = length(var.witness_storage_account.arm_id) > 0 ? (
      data.azurerm_storage_account.storage_bootdiag[0].id) : (
      azurerm_storage_account.storage_bootdiag[0].id
    )
    subresource_names = [
      "File"
    ]
  }
}

################################################################################
#                                                                              # 
#                        Witness storage account                               #
#                                                                              # 
################################################################################

resource "azurerm_storage_account" "witness_storage" {
  provider = azurerm.main
  count    = length(var.witness_storage_account.arm_id) > 0 ? 0 : 1
  name     = local.witness_storageaccount_name
  resource_group_name = local.rg_exists ? (
    data.azurerm_resource_group.resource_group[0].name) : (
    azurerm_resource_group.resource_group[0].name
  )
  location = local.rg_exists ? (
    data.azurerm_resource_group.resource_group[0].location) : (
    azurerm_resource_group.resource_group[0].location
  )
  account_replication_type  = "LRS"
  account_tier              = "Standard"
  enable_https_traffic_only = true
}

resource "azurerm_storage_account_network_rules" "witness_storage" {
  count              = length(var.witness_storage_account.arm_id) > 0 ? 0 : var.use_private_endpoint ? 1 : 0
  provider           = azurerm.main
  storage_account_id = azurerm_storage_account.witness_storage[0].id

  default_action = "Deny"
  ip_rules       = length(var.Agent_IP) > 0 ? [var.Agent_IP] : null
  virtual_network_subnet_ids = compact(
    [
      local.admin_subnet_existing ? (
        local.admin_subnet_arm_id) : (
        azurerm_subnet.admin[0].id
      ),
      local.application_subnet_existing ? (
        local.application_subnet_arm_id) : (
        azurerm_subnet.app[0].id
      ),
      local.database_subnet_existing ? (
        local.database_subnet_arm_id) : (
        azurerm_subnet.db[0].id
      ),
      local.web_subnet_existing ? (
        local.web_subnet_arm_id) : (
        azurerm_subnet.web[0].id
      ),
      local.deployer_subnet_management_id
    ]
  )
  bypass = ["AzureServices", "Logging", "Metrics"]

}


data "azurerm_storage_account" "witness_storage" {
  provider            = azurerm.main
  count               = length(var.witness_storage_account.arm_id) > 0 ? 1 : 0
  name                = split("/", var.witness_storage_account.arm_id)[8]
  resource_group_name = split("/", var.witness_storage_account.arm_id)[4]
}

resource "azurerm_private_endpoint" "witness_storage" {
  provider = azurerm.main
  count    = var.use_private_endpoint && local.admin_subnet_defined && (length(var.witness_storage_account.arm_id) == 0) ? 1 : 0
  name = format("%s%s%s",
    var.naming.resource_prefixes.storage_private_link_witness,
    local.prefix,
    local.resource_suffixes.storage_private_link_witness
  )
  resource_group_name = local.rg_name
  location = local.rg_exists ? (
    data.azurerm_resource_group.resource_group[0].location) : (
    azurerm_resource_group.resource_group[0].location
  )
  subnet_id = local.database_subnet_defined ? (
    local.database_subnet_existing ? (
      local.database_subnet_arm_id) : (
      azurerm_subnet.db[0].id
    )) : (
    ""
  )

  private_service_connection {
    name = format("%s%s%s",
      var.naming.resource_prefixes.storage_private_svc_witness,
      local.prefix,
      local.resource_suffixes.storage_private_svc_witness
    )
    is_manual_connection           = false
    private_connection_resource_id = length(var.witness_storage_account.arm_id) > 0 ? var.witness_storage_account.arm_id : azurerm_storage_account.witness_storage[0].id
    subresource_names = [
      "File"
    ]
  }
}

################################################################################
#                                                                              # 
#                        Transport storage account                             #
#                                                                              # 
################################################################################

resource "azurerm_storage_account" "transport" {
  provider = azurerm.main
  count = var.NFS_provider == "AFS" ? (
    length(var.azure_files_transport_storage_account_id) > 0 ? (
      0) : (
      1
    )) : (
    0
  )
  name = replace(
    lower(
      format("%s", local.landscape_shared_transport_storage_account_name)
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

resource "azurerm_storage_account_network_rules" "transport" {
  count = var.NFS_provider == "AFS" && var.use_private_endpoint ? (
    1) : (
    0
  )
  provider           = azurerm.main
  storage_account_id = azurerm_storage_account.transport[0].id

  default_action = "Deny"
  ip_rules       = length(var.Agent_IP) > 0 ? [var.Agent_IP] : null
  virtual_network_subnet_ids = compact(
    [
      local.admin_subnet_existing ? (
        local.admin_subnet_arm_id) : (
        azurerm_subnet.admin[0].id
      ),
      local.application_subnet_existing ? (
        local.application_subnet_arm_id) : (
        azurerm_subnet.app[0].id
      ),
      local.database_subnet_existing ? (
        local.database_subnet_arm_id) : (
        azurerm_subnet.db[0].id
      ),
      local.web_subnet_existing ? (
        local.web_subnet_arm_id) : (
        azurerm_subnet.web[0].id
      ),
      local.deployer_subnet_management_id
    ]
  )
  bypass = ["AzureServices", "Logging", "Metrics"]

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

  name = format("%s", local.resource_suffixes.transport_volume)

  storage_account_name = azurerm_storage_account.transport[0].name
  enabled_protocol     = "NFS"

  quota = var.transport_volume_size
}

resource "azurerm_private_endpoint" "transport" {
  provider = azurerm.main
  count = var.NFS_provider == "AFS" ? (
    length(var.azure_files_transport_storage_account_id) > 0 ? (
      0) : (
      1
    )) : (
    0
  )
  name = format("%s%s%s",
    var.naming.resource_prefixes.storage_private_link_transport,
    local.prefix,
    local.resource_suffixes.storage_private_link_transport
  )
  resource_group_name = local.rg_name
  location            = local.rg_exists ? (
    data.azurerm_resource_group.resource_group[0].location) : (
      azurerm_resource_group.resource_group[0].location
      )
  subnet_id = local.application_subnet_defined ? (
    local.application_subnet_existing ? local.application_subnet_arm_id : azurerm_subnet.app[0].id) : (
    ""
  )

  private_service_connection {
    name = format("%s%s%s",
      var.naming.resource_prefixes.storage_private_svc_transport,
      local.prefix,
      local.resource_suffixes.storage_private_svc_transport
    )
    is_manual_connection           = false
    private_connection_resource_id = length(var.azure_files_transport_storage_account_id) > 0 ? (
      data.azurerm_storage_account.transport[0].id) : (
        azurerm_storage_account.transport[0].id
        )
    subresource_names = [
      "File"
    ]
  }
}
