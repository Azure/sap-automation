
#######################################4#######################################8
#                                                                              #
#                             Azure NetApp Account                             #
#                                                                              #
#######################################4#######################################8

resource "azurerm_netapp_account" "workload_netapp_account" {
  provider                             = azurerm.main
  count                                = var.ANF_settings.use && length(var.ANF_settings.arm_id) == 0 ? 1 : 0
  name                                 = format("%s%s%s%s",
                                           var.naming.resource_prefixes.netapp_account,
                                           local.prefix,
                                           var.naming.separator,
                                           local.resource_suffixes.netapp_account
                                         )

  resource_group_name                  = local.resource_group_exists ? (
                                           data.azurerm_resource_group.resource_group[0].name) : (
                                           azurerm_resource_group.resource_group[0].name
                                         )
  location                             = local.resource_group_exists ? (
                                           data.azurerm_resource_group.resource_group[0].location) : (
                                           azurerm_resource_group.resource_group[0].location
                                         )
  tags                                 = var.tags
}

data "azurerm_netapp_account" "workload_netapp_account" {
  provider                             = azurerm.main
  count                                = var.ANF_settings.use && length(var.ANF_settings.arm_id) > 0 ? 1 : 0
  name                                 = split("/", var.ANF_settings.arm_id)[8]
  resource_group_name                  = split("/", var.ANF_settings.arm_id)[4]
}

resource "azurerm_netapp_pool" "workload_netapp_pool" {
  provider                             = azurerm.main
  count                                = var.ANF_settings.use ? (
                                           var.ANF_settings.use_existing_pool ? (
                                             0) : (
                                             1
                                           )) : (
                                           0
                                         )

  name                                 = length(var.ANF_settings.pool_name) > 0 ? (
                                          var.ANF_settings.pool_name) : (
                                          format("%s%s%s%s",
                                            var.naming.resource_prefixes.netapp_pool,
                                            local.prefix,
                                            var.naming.separator,
                                            local.resource_suffixes.netapp_pool
                                          )
                                        )
  account_name                         = var.ANF_settings.use && length(var.ANF_settings.arm_id) > 0 ? (
                                           data.azurerm_netapp_account.workload_netapp_account[0].name) : (
                                           azurerm_netapp_account.workload_netapp_account[0].name
                                         )
  location                             = var.ANF_settings.use && length(var.ANF_settings.arm_id) > 0 ? (
                                           data.azurerm_netapp_account.workload_netapp_account[0].location) : (
                                           azurerm_netapp_account.workload_netapp_account[0].location
                                         )

  resource_group_name                  = var.ANF_settings.use && length(var.ANF_settings.arm_id) > 0 ? (
                                           data.azurerm_netapp_account.workload_netapp_account[0].resource_group_name) : (
                                           azurerm_netapp_account.workload_netapp_account[0].resource_group_name
                                         )

  service_level                        = var.ANF_settings.service_level
  size_in_tb                           = var.ANF_settings.size_in_tb

  qos_type                             = var.ANF_settings.qos_type
}

data "azurerm_netapp_pool" "workload_netapp_pool" {
  provider                             = azurerm.main
  count                                = var.ANF_settings.use ? (
                                           var.ANF_settings.use_existing_pool ? (
                                             1) : (
                                             0
                                           )) : (
                                           0
                                         )
  name                                 = length(var.ANF_settings.pool_name) > 0 ? (
                                           var.ANF_settings.pool_name) : (
                                           format("%s%s%s%s",
                                             var.naming.resource_prefixes.netapp_pool,
                                             local.prefix,
                                             var.naming.separator,
                                             local.resource_suffixes.netapp_pool
                                           )
                                         )
  resource_group_name                  = split("/", var.ANF_settings.arm_id)[4]
  account_name                         = var.ANF_settings.use && length(var.ANF_settings.arm_id) > 0 ? (
                                           data.azurerm_netapp_account.workload_netapp_account[0].name) : (
                                           azurerm_netapp_account.workload_netapp_account[0].name
                                         )

}

resource "azurerm_netapp_volume" "transport" {
  provider                             = azurerm.main
  count                                = var.create_transport_storage && var.NFS_provider == "ANF" && !var.use_AFS_for_shared_storage ? (
                                           var.ANF_settings.use_existing_transport_volume ? (
                                             0) : (
                                             1
                                           )
                                           ) : (
                                           0
                                         )
  name                                 = format("%s%s%s%s",
                                           var.naming.resource_prefixes.transport_volume,
                                           local.prefix,
                                           var.naming.separator,
                                           local.resource_suffixes.transport_volume
                                         )


  resource_group_name                  = length(var.ANF_settings.arm_id) > 0 ? (
                                          data.azurerm_netapp_account.workload_netapp_account[0].resource_group_name) : (
                                          azurerm_netapp_account.workload_netapp_account[0].resource_group_name
                                        )
  location                             = length(var.ANF_settings.arm_id) > 0 ? (
                                            data.azurerm_netapp_account.workload_netapp_account[0].location) : (
                                            azurerm_netapp_account.workload_netapp_account[0].location
                                          )
  account_name                         = length(var.ANF_settings.arm_id) > 0 ? (
                                           data.azurerm_netapp_account.workload_netapp_account[0].name) : (
                                           azurerm_netapp_account.workload_netapp_account[0].name
                                         )

  pool_name                            = var.ANF_settings.use_existing_pool ? (
                                           data.azurerm_netapp_pool.workload_netapp_pool[0].name
                                           ) : (
                                           azurerm_netapp_pool.workload_netapp_pool[0].name
                                         )
  zone                                 = length(var.ANF_settings.transport_volume_zone) > 0 ? (
                                           var.ANF_settings.transport_volume_zone
                                         ) : (
                                           null
                                         )

  throughput_in_mibps                  = var.ANF_settings.use_existing_pool ? (
                                          var.ANF_settings.transport_volume_throughput
                                          ) : (
                                          azurerm_netapp_pool.workload_netapp_pool[0].qos_type == "Auto" ? null : var.ANF_settings.transport_volume_throughput
                                        )

  volume_path                          = format("%s%s%s",
                                           var.naming.resource_prefixes.transport_volume,
                                           var.infrastructure.environment,
                                           local.resource_suffixes.transport_volume
                                         )
  service_level                        = var.ANF_settings.service_level
  subnet_id                            = local.ANF_subnet_existing ? var.infrastructure.vnets.sap.subnet_anf.arm_id : azurerm_subnet.anf[0].id
  storage_quota_in_gb                  = var.ANF_settings.transport_volume_size

  network_features                     = "Standard"
  protocols                            = ["NFSv4.1"]

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

data "azurerm_netapp_volume" "transport" {
  provider                             = azurerm.main
  count                                = var.create_transport_storage && var.NFS_provider == "ANF" ? (
                                           var.ANF_settings.use_existing_transport_volume ? (
                                             1) : (
                                             0
                                           )
                                           ) : (
                                           0
                                         )
  resource_group_name                  = length(var.ANF_settings.arm_id) > 0 ? (
                                           data.azurerm_netapp_account.workload_netapp_account[0].resource_group_name) : (
                                           azurerm_netapp_account.workload_netapp_account[0].resource_group_name
                                         )
  account_name                         = length(var.ANF_settings.arm_id) > 0 ? (
                                           data.azurerm_netapp_account.workload_netapp_account[0].name) : (
                                           azurerm_netapp_account.workload_netapp_account[0].name
                                         )
  pool_name                            = var.ANF_settings.use_existing_pool ? (
                                           data.azurerm_netapp_pool.workload_netapp_pool[0].name
                                           ) : (
                                           azurerm_netapp_pool.workload_netapp_pool[0].name
                                         )
  name                                 = length(var.ANF_settings.transport_volume_name) > 0 ? (
                                           var.ANF_settings.transport_volume_name
                                           ) : (
                                           format("%s%s%s",
                                             var.naming.resource_prefixes.transport_volume,
                                             var.infrastructure.environment,
                                             local.resource_suffixes.transport_volume
                                           )
                                         )
}

################################################################################
#                                                                              #
#                                Install media                                 #
#                                                                              #
################################################################################

resource "azurerm_netapp_volume" "install" {
  provider                             = azurerm.main
  count                                = var.NFS_provider == "ANF" && !var.use_AFS_for_shared_storage ? (
                                           var.ANF_settings.use_existing_install_volume ? (
                                             0) : (
                                             1
                                           )
                                           ) : (
                                           0
                                         )
  name                                 = format("%s%s%s%s",
                                           var.naming.resource_prefixes.install_volume,
                                           local.prefix,
                                           var.naming.separator,
                                           local.resource_suffixes.install_volume
                                         )

  resource_group_name                  = length(var.ANF_settings.arm_id) > 0 ? (
                                           data.azurerm_netapp_account.workload_netapp_account[0].resource_group_name) : (
                                           azurerm_netapp_account.workload_netapp_account[0].resource_group_name
                                         )
  location                             = length(var.ANF_settings.arm_id) > 0 ? (
                                           data.azurerm_netapp_account.workload_netapp_account[0].location) : (
                                           azurerm_netapp_account.workload_netapp_account[0].location
                                         )
  account_name                         = length(var.ANF_settings.arm_id) > 0 ? (
                                            data.azurerm_netapp_account.workload_netapp_account[0].name) : (
                                            azurerm_netapp_account.workload_netapp_account[0].name
                                          )

  pool_name                            = var.ANF_settings.use_existing_pool ? (
                                           data.azurerm_netapp_pool.workload_netapp_pool[0].name
                                           ) : (
                                           azurerm_netapp_pool.workload_netapp_pool[0].name
                                         )

  zone                                 = length(var.ANF_settings.install_volume_zone) > 0 ? (
                                           var.ANF_settings.install_volume_zone
                                         ) : (
                                           null
                                         )


  throughput_in_mibps                  = var.ANF_settings.use_existing_pool ? (
                                           var.ANF_settings.install_volume_throughput
                                           ) : (
                                           azurerm_netapp_pool.workload_netapp_pool[0].qos_type == "Auto" ? null : var.ANF_settings.install_volume_throughput
                                         )

  volume_path                          = format("%s%s%s",
                                           var.naming.resource_prefixes.install_volume,
                                           var.infrastructure.environment,
                                           local.resource_suffixes.install_volume
                                         )
  service_level                        = var.ANF_settings.service_level
  subnet_id                            = local.ANF_subnet_existing ? var.infrastructure.vnets.sap.subnet_anf.arm_id : azurerm_subnet.anf[0].id

  protocols                            = ["NFSv4.1"]
  network_features                     = "Standard"

  tags                                 = var.tags

  export_policy_rule {
                       allowed_clients     = ["0.0.0.0/0"]
                       protocols_enabled   = ["NFSv4.1"]
                       rule_index          = 1
                       unix_read_only      = false
                       unix_read_write     = true
                       root_access_enabled = true
                     }

  storage_quota_in_gb                  = var.ANF_settings.install_volume_size
}

data "azurerm_netapp_volume" "install" {
  provider                             = azurerm.main
  count                                = var.NFS_provider == "ANF" ? (
                                           var.ANF_settings.use_existing_install_volume ? (
                                             1) : (
                                             0
                                           )
                                           ) : (
                                           0
                                         )
  resource_group_name                  = length(var.ANF_settings.arm_id) > 0 ? (
                                           data.azurerm_netapp_account.workload_netapp_account[0].resource_group_name) : (
                                           azurerm_netapp_account.workload_netapp_account[0].resource_group_name
                                         )
  account_name                         = length(var.ANF_settings.arm_id) > 0 ? (
                                           data.azurerm_netapp_account.workload_netapp_account[0].name) : (
                                           azurerm_netapp_account.workload_netapp_account[0].name
                                         )
  pool_name                            = var.ANF_settings.use_existing_pool ? (
                                            data.azurerm_netapp_pool.workload_netapp_pool[0].name
                                            ) : (
                                            azurerm_netapp_pool.workload_netapp_pool[0].name
                                          )
  name                                 = length(var.ANF_settings.install_volume_name) > 0 ? (
                                           var.ANF_settings.install_volume_name
                                           ) : (
                                           format("%s%s%s",
                                             var.naming.resource_prefixes.transport_volume,
                                             var.infrastructure.environment,
                                             local.resource_suffixes.transport_volume
                                           )
                                         )
}
