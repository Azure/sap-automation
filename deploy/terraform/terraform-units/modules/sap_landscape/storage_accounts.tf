################################################################################
#                                                                              # 
#                     Diagnostics storage account                              #
#                                                                              # 
################################################################################

resource "azurerm_storage_account" "storage_bootdiag" {
  provider = azurerm.main
  count    = length(var.diagnostics_storage_account.arm_id) > 0 ? 0 : 1
  name     = local.storageaccount_name
  resource_group_name = local.resource_group_exists ? (
    data.azurerm_resource_group.resource_group[0].name) : (
    azurerm_resource_group.resource_group[0].name
  )
  location = local.resource_group_exists ? (
    data.azurerm_resource_group.resource_group[0].location) : (
    azurerm_resource_group.resource_group[0].location
  )
  account_replication_type        = "LRS"
  account_tier                    = "Standard"
  enable_https_traffic_only       = true
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false
}

resource "azurerm_storage_account_network_rules" "storage_bootdiag" {
  count = length(var.diagnostics_storage_account.arm_id) > 0 ? (
    0) : (
    var.use_private_endpoint ? (
      1) : (
      0
    )
  )
  depends_on = [
    azurerm_subnet.app,
    azurerm_subnet.db,
    azurerm_subnet.web,
  ]

  provider           = azurerm.main
  storage_account_id = azurerm_storage_account.storage_bootdiag[0].id

  default_action = "Deny"
  ip_rules       = length(var.Agent_IP) > 0 ? [var.Agent_IP] : [""]
  virtual_network_subnet_ids = compact(
    [
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
  depends_on = [
    azurerm_subnet.app,
    azurerm_subnet.db,
    azurerm_subnet.web,
  ]
  count = var.use_private_endpoint && local.admin_subnet_defined && (length(var.diagnostics_storage_account.arm_id) == 0) ? 1 : 0
  name = format("%s%s%s",
    var.naming.resource_prefixes.storage_private_link_diag,
    local.prefix,
    local.resource_suffixes.storage_private_link_diag
  )
  resource_group_name = local.rg_name
  location            = local.resource_group_exists ? data.azurerm_resource_group.resource_group[0].location : azurerm_resource_group.resource_group[0].location
  subnet_id           = local.application_subnet_existing ? local.application_subnet_arm_id : azurerm_subnet.app[0].id

  private_service_connection {
    name = format("%s%s%s",
      var.naming.resource_prefixes.storage_private_svc_diag,
      local.prefix,
      local.resource_suffixes.storage_private_svc_diag
    )
    is_manual_connection = false
    private_connection_resource_id = length(var.diagnostics_storage_account.arm_id) > 0 ? (
      var.diagnostics_storage_account.arm_id) : (
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
  depends_on = [
    azurerm_subnet.app,
    azurerm_subnet.db
  ]
  name = local.witness_storageaccount_name
  resource_group_name = local.resource_group_exists ? (
    data.azurerm_resource_group.resource_group[0].name) : (
    azurerm_resource_group.resource_group[0].name
  )
  location = local.resource_group_exists ? (
    data.azurerm_resource_group.resource_group[0].location) : (
    azurerm_resource_group.resource_group[0].location
  )
  account_replication_type        = "LRS"
  account_tier                    = "Standard"
  enable_https_traffic_only       = true
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false

}

resource "azurerm_storage_account_network_rules" "witness_storage" {
  count              = length(var.witness_storage_account.arm_id) > 0 ? 0 : var.use_private_endpoint ? 1 : 0
  provider           = azurerm.main
  storage_account_id = azurerm_storage_account.witness_storage[0].id
  depends_on = [
    azurerm_subnet.app,
    azurerm_subnet.db
  ]

  default_action = "Deny"
  ip_rules       = length(var.Agent_IP) > 0 ? [var.Agent_IP] : [""]
  virtual_network_subnet_ids = compact(
    [
      local.application_subnet_existing ? (
        local.application_subnet_arm_id) : (
        azurerm_subnet.app[0].id
      ),
      local.database_subnet_existing ? (
        local.database_subnet_arm_id) : (
        azurerm_subnet.db[0].id
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
  depends_on = [
    azurerm_storage_account_network_rules.witness_storage
  ]
  name = format("%s%s%s",
    var.naming.resource_prefixes.storage_private_link_witness,
    local.prefix,
    local.resource_suffixes.storage_private_link_witness
  )
  resource_group_name = local.rg_name
  location = local.resource_group_exists ? (
    data.azurerm_resource_group.resource_group[0].location) : (
    azurerm_resource_group.resource_group[0].location
  )
  subnet_id = local.application_subnet_defined ? (
    local.application_subnet_existing ? local.application_subnet_arm_id : azurerm_subnet.app[0].id) : (
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
  depends_on = [
    azurerm_subnet.app
  ]
  provider = azurerm.main
  count = var.NFS_provider == "AFS" ? (
    length(var.transport_storage_account_id) > 0 ? (
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

resource "azurerm_storage_share" "transport" {
  provider = azurerm.main
  count = var.NFS_provider == "AFS" ? (
    length(var.transport_storage_account_id) > 0 ? (
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

data "azurerm_storage_account" "transport" {
  provider = azurerm.main
  count = var.NFS_provider == "AFS" ? (
    length(var.transport_storage_account_id) > 0 ? (
      1) : (
      0
    )) : (
    0
  )
  name                = split("/", var.transport_storage_account_id)[8]
  resource_group_name = split("/", var.transport_storage_account_id)[4]
}



resource "azurerm_storage_account_network_rules" "transport" {
  count = var.NFS_provider == "AFS" && var.use_private_endpoint ? (
    1) : (
    0
  )
  depends_on = [
    azurerm_subnet.app
  ]

  provider           = azurerm.main
  storage_account_id = azurerm_storage_account.transport[0].id

  default_action = "Deny"
  ip_rules       = length(var.Agent_IP) > 0 ? [var.Agent_IP] : [""]
  virtual_network_subnet_ids = compact(
    [
      local.application_subnet_existing ? (
        local.application_subnet_arm_id) : (
        azurerm_subnet.app[0].id
      ),
      local.deployer_subnet_management_id
    ]
  )
  bypass = ["AzureServices", "Logging", "Metrics"]

}

resource "azurerm_private_endpoint" "transport" {
  provider = azurerm.main
  depends_on = [
    azurerm_subnet.app
  ]
  count = var.NFS_provider == "AFS" ? (
    length(var.transport_storage_account_id) > 0 ? (
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
  location = local.resource_group_exists ? (
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
    is_manual_connection = false
    private_connection_resource_id = length(var.transport_storage_account_id) > 0 ? (
      data.azurerm_storage_account.transport[0].id) : (
      azurerm_storage_account.transport[0].id
    )
    subresource_names = [
      "File"
    ]
  }
}

data "azurerm_private_endpoint_connection" "transport" {
  provider = azurerm.main
  count = var.NFS_provider == "AFS" ? (
    length(var.transport_private_endpoint_id) > 0 ? (
      1) : (
      0
    )) : (
    0
  )
  name                = split("/",var.transport_private_endpoint_id)[8]
  resource_group_name = split("/",var.transport_private_endpoint_id)[4]

}

################################################################################
#                                                                              # 
#                     Install media storage account                            #
#                                                                              # 
################################################################################

resource "azurerm_storage_account" "install" {
  count = var.NFS_provider == "AFS" ? (
    length(var.install_storage_account_id) > 0 ? (
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
  resource_group_name = local.rg_name
  location = local.resource_group_exists ? (
    data.azurerm_resource_group.resource_group[0].location) : (
    azurerm_resource_group.resource_group[0].location
  )

  account_tier                    = "Premium"
  account_replication_type        = "ZRS"
  account_kind                    = "FileStorage"
  enable_https_traffic_only       = false
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false
}

data "azurerm_storage_account" "install" {
  count = var.NFS_provider == "AFS" ? (
    length(var.install_storage_account_id) > 0 ? (
      1) : (
      0
    )) : (
    0
  )
  name                = split("/", var.install_storage_account_id)[8]
  resource_group_name = split("/", var.install_storage_account_id)[4]
}
 
data "azurerm_private_endpoint_connection" "install" {
  provider = azurerm.main
  count = var.NFS_provider == "AFS" ? (
    length(var.install_private_endpoint_id) > 0 ? (
      1) : (
      0
    )) : (
    0
  )
  name                = split("/",var.install_private_endpoint_id)[8]
  resource_group_name = split("/",var.install_private_endpoint_id)[4]

}

resource "azurerm_storage_account_network_rules" "install" {
  depends_on = [
    azurerm_subnet.app,
    azurerm_subnet.db,
    azurerm_subnet.web
  ]
  count = var.NFS_provider == "AFS" && var.use_private_endpoint ? (
    length(var.install_storage_account_id) > 0 ? (
      0) : (
      0
    )) : (
    0
  )

  storage_account_id = azurerm_storage_account.install[0].id

  default_action = "Deny"
  ip_rules       = [var.Agent_IP]
  virtual_network_subnet_ids = compact([
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

resource "azurerm_private_endpoint" "install" {
  depends_on = [
    azurerm_subnet.app
  ]
  provider = azurerm.main
  count = var.NFS_provider == "AFS" ? (
    length(var.install_storage_account_id) > 0 ? (
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
  location = local.resource_group_exists ? (
    data.azurerm_resource_group.resource_group[0].location) : (
    azurerm_resource_group.resource_group[0].location
  )
  subnet_id = local.application_subnet_defined ? (
    local.application_subnet_existing ? local.application_subnet_arm_id : azurerm_subnet.app[0].id) : (
    ""
  )

  private_service_connection {
    name = format("%s%s%s",
      var.naming.resource_prefixes.storage_private_svc_install,
      local.prefix,
      local.resource_suffixes.storage_private_svc_install
    )
    is_manual_connection = false
    private_connection_resource_id = length(var.install_storage_account_id) > 0 ? (
      data.azurerm_storage_account.install[0].id) : (
      azurerm_storage_account.install[0].id
    )
    subresource_names = [
      "File"
    ]
  }
}

resource "azurerm_storage_share" "install" {
  count = var.NFS_provider == "AFS" ? (
    length(var.install_storage_account_id) > 0 ? (
      0) : (
      1
    )) : (
    0
  )

  name                 = format("%s", local.resource_suffixes.install_volume)
  storage_account_name = var.NFS_provider == "AFS" ? azurerm_storage_account.install[0].name : ""
  enabled_protocol     = "NFS"

  quota = var.install_volume_size
}

resource "azurerm_storage_share" "install_smb" {
  count = var.NFS_provider == "AFS" ? (
    length(var.install_storage_account_id) > 0 ? (
      0) : (
      1
    )) : (
    0
  )

  name                 = format("%s", local.resource_suffixes.install_volume_smb)
  storage_account_name = var.NFS_provider == "AFS" ? azurerm_storage_account.install[0].name : ""
  enabled_protocol     = "SMB"

  quota = var.install_volume_size
}

