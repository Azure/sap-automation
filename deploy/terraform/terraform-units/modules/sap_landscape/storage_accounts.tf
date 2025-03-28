# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

################################################################################
#                                                                              #
#                     Diagnostics storage account                              #
#                                                                              #
################################################################################

resource "azurerm_storage_account" "storage_bootdiag" {
  provider                             = azurerm.main
  count                                = length(var.diagnostics_storage_account.arm_id) > 0 ? 0 : 1
  depends_on                           = [
                                           azurerm_subnet.app,
                                           azurerm_subnet.db,
                                           azurerm_subnet.web,
                                         ]
  name                                 = local.storageaccount_name

  resource_group_name                  = local.resource_group_exists ? (
                                           data.azurerm_resource_group.resource_group[0].name) : (
                                           azurerm_resource_group.resource_group[0].name
                                         )
  location                             = local.resource_group_exists ? (
                                          data.azurerm_resource_group.resource_group[0].location) : (
                                          azurerm_resource_group.resource_group[0].location
                                        )

  account_replication_type             = "LRS"
  account_tier                         = "Standard"
  https_traffic_only_enabled           = true

  min_tls_version                      = "TLS1_2"
  allow_nested_items_to_be_public      = false
  cross_tenant_replication_enabled     = false
  tags                                 = var.tags
  shared_access_key_enabled            = var.infrastructure.shared_access_key_enabled
  public_network_access_enabled        = var.public_network_access_enabled
  network_rules {
                default_action              = var.enable_firewall_for_keyvaults_and_storage ? "Deny" : "Allow"
                virtual_network_subnet_ids  = var.public_network_access_enabled ? compact([
                                                local.database_subnet_defined ? (
                                                  local.database_subnet_existing ? var.infrastructure.virtual_networks.sap.subnet_db.arm_id : azurerm_subnet.db[0].id) : (
                                                  null
                                                  ), local.application_subnet_defined ? (
                                                  local.application_subnet_existing ? var.infrastructure.virtual_networks.sap.subnet_app.arm_id : azurerm_subnet.app[0].id) : (
                                                  null
                                                ), local.web_subnet_defined ? (
                                                  local.web_subnet_existing ? var.infrastructure.virtual_networks.sap.subnet_web.arm_id : azurerm_subnet.web[0].id) : (
                                                  null
                                                ), local.enable_sub_iscsi ? (
                                                  local.sub_iscsi_exists ? var.infrastructure.virtual_networks.sap.subnet_iscsi.arm_id : azurerm_subnet.iscsi[0].id) : (
                                                  null
                                                ), length(local.deployer_subnet_management_id) > 0 ? local.deployer_subnet_management_id : null,
                                                length(var.additional_network_id) > 0 ? var.additional_network_id : null
                                                ]
                                              ) : null
                ip_rules                   = var.public_network_access_enabled ? compact([
                                               length(local.deployer_public_ip_address) > 0 ? local.deployer_public_ip_address : "",
                                               length(var.Agent_IP) > 0 ? var.Agent_IP : ""
                                              ]) : null
                bypass                     = ["Metrics", "Logging", "AzureServices"]
              }

}

data "azurerm_storage_account" "storage_bootdiag" {
  provider                             = azurerm.main
  count                                = length(var.diagnostics_storage_account.arm_id) > 0 ? 1 : 0
  name                                 = split("/", var.diagnostics_storage_account.arm_id)[8]
  resource_group_name                  = split("/", var.diagnostics_storage_account.arm_id)[4]
}

resource "azurerm_private_endpoint" "storage_bootdiag" {
  provider                             = azurerm.main
  count                                = var.use_private_endpoint && local.admin_subnet_defined && (length(var.diagnostics_storage_account.arm_id) == 0) ? 1 : 0
  depends_on                           = [
                                           azurerm_subnet.app
                                         ]
  name                                 = format("%s%s%s",
                                           var.naming.resource_prefixes.storage_private_link_diag,
                                           local.prefix,
                                           local.resource_suffixes.storage_private_link_diag
                                         )
  custom_network_interface_name        = format("%s%s%s%s",
                                           var.naming.resource_prefixes.storage_private_link_diag,
                                           local.prefix,
                                           local.resource_suffixes.storage_private_link_diag,
                                           var.naming.resource_suffixes.nic
                                         )

  resource_group_name                  = local.resource_group_exists ? (
                                           data.azurerm_resource_group.resource_group[0].name) : (
                                           azurerm_resource_group.resource_group[0].name
                                         )
  location                             = local.resource_group_exists ? (
                                          data.azurerm_resource_group.resource_group[0].location) : (
                                          azurerm_resource_group.resource_group[0].location
                                        )
  subnet_id                            = local.application_subnet_existing ? (
                                           var.infrastructure.virtual_networks.sap.subnet_app.arm_id) : (
                                           azurerm_subnet.app[0].id
                                         )
  tags                                 = var.tags

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
                                 "blob"
                               ]
                             }
  timeouts {
              create = "10m"
              delete = "30m"
            }

  dynamic "private_dns_zone_group" {
                                     for_each = range(var.dns_settings.register_endpoints_with_dns ? 1 : 0)
                                     content {
                                       name                 = var.dns_settings.dns_zone_names.blob_dns_zone_name
                                       private_dns_zone_ids = local.privatelink_storage_defined ? (
                                        [var.dns_settings.privatelink_storage_id]) : (
                                        [data.azurerm_private_dns_zone.storage[0].id]
                                        )
                                     }
                                   }

}

################################################################################
#                                                                              #
#                        Witness storage account                               #
#                                                                              #
################################################################################

resource "azurerm_storage_account" "witness_storage" {
  provider                             = azurerm.main
  count                                = length(var.witness_storage_account.arm_id) > 0 ? 0 : 1
  depends_on                           = [
                                           azurerm_subnet.app,
                                           azurerm_subnet.db
                                         ]
  name                                 = local.witness_storageaccount_name
  resource_group_name                  = local.resource_group_exists ? (
                                           data.azurerm_resource_group.resource_group[0].name) : (
                                           azurerm_resource_group.resource_group[0].name
                                         )
  location                             = local.resource_group_exists ? (
                                          data.azurerm_resource_group.resource_group[0].location) : (
                                          azurerm_resource_group.resource_group[0].location
                                        )

  account_replication_type             = "LRS"
  account_tier                         = "Standard"
  https_traffic_only_enabled            = true
  min_tls_version                      = "TLS1_2"
  allow_nested_items_to_be_public      = false
  cross_tenant_replication_enabled     = false
  public_network_access_enabled        = var.public_network_access_enabled
  shared_access_key_enabled            = var.infrastructure.shared_access_key_enabled

  tags                                 = var.tags
  network_rules {
                  default_action              = var.enable_firewall_for_keyvaults_and_storage ? "Deny" : "Allow"
                  virtual_network_subnet_ids  = var.public_network_access_enabled ? compact([
                                                  local.database_subnet_defined ? (
                                                    local.database_subnet_existing ? var.infrastructure.virtual_networks.sap.subnet_db.arm_id : azurerm_subnet.db[0].id) : (
                                                    null
                                                    ), local.application_subnet_defined ? (
                                                    local.application_subnet_existing ? var.infrastructure.virtual_networks.sap.subnet_app.arm_id : azurerm_subnet.app[0].id) : (
                                                    null
                                                  ),
                                                  length(local.deployer_subnet_management_id) > 0 ? local.deployer_subnet_management_id : null,
                                                  length(var.additional_network_id) > 0 ? var.additional_network_id : null
                                                  ]
                                                ) : null
                  ip_rules                   = var.public_network_access_enabled ? compact([
                                                 length(local.deployer_public_ip_address) > 0 ? local.deployer_public_ip_address : "",
                                                 length(var.Agent_IP) > 0 ? var.Agent_IP : ""
                                                ]) : null
                  bypass                     = ["Metrics", "Logging", "AzureServices"]
                }


}

data "azurerm_storage_account" "witness_storage" {
  provider                             = azurerm.main
  count                                = length(var.witness_storage_account.arm_id) > 0 ? 1 : 0
  name                                 = split("/", var.witness_storage_account.arm_id)[8]
  resource_group_name                  = split("/", var.witness_storage_account.arm_id)[4]
}

resource "azurerm_private_endpoint" "witness_storage" {
  provider                             = azurerm.main
  count                                = var.use_private_endpoint && local.admin_subnet_defined && (length(var.witness_storage_account.arm_id) == 0) ? 1 : 0
  depends_on                           = [
                                           azurerm_subnet.db,
                                           azurerm_private_dns_zone_virtual_network_link.storage[0]
                                         ]
  name                                 = format("%s%s%s",
                                           var.naming.resource_prefixes.storage_private_link_witness,
                                           local.prefix,
                                           local.resource_suffixes.storage_private_link_witness
                                         )

  custom_network_interface_name        = format("%s%s%s%s",
                                           var.naming.resource_prefixes.storage_private_link_witness,
                                           local.prefix,
                                           local.resource_suffixes.storage_private_link_witness,
                                           local.resource_suffixes.nic
                                         )

  resource_group_name                  = local.resource_group_exists ? (
                                           data.azurerm_resource_group.resource_group[0].name) : (
                                           azurerm_resource_group.resource_group[0].name
                                         )
  location                             = local.resource_group_exists ? (
                                          data.azurerm_resource_group.resource_group[0].location) : (
                                          azurerm_resource_group.resource_group[0].location
                                        )
  subnet_id                            = local.database_subnet_defined ? (
                                           local.database_subnet_existing ? (
                                             var.infrastructure.virtual_networks.sap.subnet_db.arm_id) : (
                                             azurerm_subnet.db[0].id)) : (
                                           ""
                                         )

  tags                                 = var.tags
  private_service_connection {
                               name = format("%s%s%s",
                                 var.naming.resource_prefixes.storage_private_svc_witness,
                                 local.prefix,
                                 local.resource_suffixes.storage_private_svc_witness
                               )
                               is_manual_connection = false
                               private_connection_resource_id = length(var.witness_storage_account.arm_id) > 0 ? (
                                 var.witness_storage_account.arm_id) : (
                                 azurerm_storage_account.witness_storage[0].id
                               )
                               subresource_names = [
                                 "blob"
                               ]
                             }


  timeouts {
              create = "10m"
              delete = "30m"
            }

  dynamic "private_dns_zone_group" {
                                     for_each = range(var.dns_settings.register_endpoints_with_dns ? 1 : 0)
                                     content {
                                       name                 = var.dns_settings.dns_zone_names.blob_dns_zone_name
                                       private_dns_zone_ids = local.privatelink_storage_defined ? (
                                        [var.dns_settings.privatelink_storage_id]) : (
                                        [data.azurerm_private_dns_zone.storage[0].id]
                                        )
                                     }
                                   }

}

################################################################################
#                                                                              #
#                        Transport storage account                             #
#                                                                              #
################################################################################

resource "azurerm_storage_account" "transport" {
  provider                             = azurerm.main
  count                                = var.create_transport_storage && local.use_AFS_for_shared && length(var.transport_storage_account_id) == 0 ? 1 : 0
  depends_on                           = [
                                           azurerm_subnet.app
                                         ]
  name                                 = replace(
                                          lower(
                                            format("%s", local.landscape_shared_transport_storage_account_name)
                                          ),
                                          "/[^a-z0-9]/",
                                          ""
                                        )
  resource_group_name                  = local.resource_group_exists ? (
                                           data.azurerm_resource_group.resource_group[0].name) : (
                                           azurerm_resource_group.resource_group[0].name
                                         )
  location                             = local.resource_group_exists ? (
                                          data.azurerm_resource_group.resource_group[0].location) : (
                                          azurerm_resource_group.resource_group[0].location
                                        )
  account_tier                         = "Premium"
  account_replication_type             = "ZRS"
  account_kind                         = "FileStorage"
  https_traffic_only_enabled            = false
  min_tls_version                      = "TLS1_2"
  allow_nested_items_to_be_public      = false

  shared_access_key_enabled            = var.infrastructure.shared_access_key_enabled_nfs

  cross_tenant_replication_enabled     = false
  public_network_access_enabled        = var.public_network_access_enabled

  network_rules {
                  default_action              = var.enable_firewall_for_keyvaults_and_storage ? "Deny" : "Allow"
                  virtual_network_subnet_ids  = var.public_network_access_enabled ? compact([
                                                  local.database_subnet_defined ? (
                                                    local.database_subnet_existing ? var.infrastructure.virtual_networks.sap.subnet_db.arm_id : azurerm_subnet.db[0].id) : (
                                                    null
                                                    ), local.application_subnet_defined ? (
                                                    local.application_subnet_existing ? var.infrastructure.virtual_networks.sap.subnet_app.arm_id : azurerm_subnet.app[0].id) : (
                                                    null
                                                  ),
                                                  length(local.deployer_subnet_management_id) > 0 ? local.deployer_subnet_management_id : null,
                                                  length(var.additional_network_id) > 0 ? var.additional_network_id : null
                                                  ]
                                                ) : null
                  ip_rules                   = var.public_network_access_enabled ? compact([
                                                 length(local.deployer_public_ip_address) > 0 ? local.deployer_public_ip_address : "",
                                                 length(var.Agent_IP) > 0 ? var.Agent_IP : ""
                                                ]) : null
                  bypass                     = ["Metrics", "Logging", "AzureServices"]
                }


  tags                                 = var.tags

}

resource "azurerm_storage_share" "transport" {
  provider                             = azurerm.main
  count                                = var.create_transport_storage && local.use_AFS_for_shared ? (
                                           length(var.transport_storage_account_id) > 0 ? (
                                             var.install_always_create_fileshares ? 1 : 0) : (
                                             1
                                           )) : (
                                           0
                                         )
  name                                 = format("%s", local.resource_suffixes.transport_volume)

  storage_account_id                   = length(var.transport_storage_account_id) > 0 ? (
                                           var.transport_storage_account_id
                                           ) : (
                                           azurerm_storage_account.transport[0].id
                                         )

  # storage_account_name                 = var.data_plane_available ? length(var.transport_storage_account_id) > 0 ? (
  #                                          split("/", var.transport_storage_account_id)[8]
  #                                          ) : (
  #                                          azurerm_storage_account.transport[0].name
  #                                        ) : null

  enabled_protocol                     = "NFS"

  quota                                = var.transport_volume_size
}

data "azurerm_storage_account" "transport" {
  provider                             = azurerm.main
  count                                = var.create_transport_storage && local.use_AFS_for_shared ? (
                                          length(var.transport_storage_account_id) > 0 ? (
                                            1) : (
                                            0
                                          )) : (
                                          0
                                        )
  name                                 = split("/", var.transport_storage_account_id)[8]
  resource_group_name                  = split("/", var.transport_storage_account_id)[4]
}

resource "azurerm_private_endpoint" "transport" {
  provider                             = azurerm.main
  depends_on                           = [
                                           azurerm_subnet.app,
                                           azurerm_private_dns_zone_virtual_network_link.vnet_sap_file
                                         ]
  count                                = var.create_transport_storage && var.use_private_endpoint && local.use_AFS_for_shared ? (
                                           length(var.transport_storage_account_id) > 0 ? (
                                             0) : (
                                             1
                                           )) : (
                                           0
                                         )

  name                                 = format("%s%s%s",
                                           var.naming.resource_prefixes.storage_private_link_transport,
                                           local.prefix,
                                           local.resource_suffixes.storage_private_link_transport
                                         )
  custom_network_interface_name        = format("%s%s%s%s",
                                           var.naming.resource_prefixes.storage_private_link_transport,
                                           local.prefix,
                                           local.resource_suffixes.storage_private_link_transport,
                                           var.naming.resource_suffixes.nic
                                         )

  resource_group_name                  = local.resource_group_exists ? (
                                           data.azurerm_resource_group.resource_group[0].name) : (
                                           azurerm_resource_group.resource_group[0].name
                                         )
  location                             = local.resource_group_exists ? (
                                          data.azurerm_resource_group.resource_group[0].location) : (
                                          azurerm_resource_group.resource_group[0].location
                                        )

  subnet_id                             = local.application_subnet_defined ? (
                                          local.application_subnet_existing ? (
                                            var.infrastructure.virtual_networks.sap.subnet_app.arm_id) : (
                                            azurerm_subnet.app[0].id)) : (
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
  dynamic "private_dns_zone_group" {
                                     for_each = range(var.dns_settings.register_endpoints_with_dns ? 1 : 0)
                                     content {
                                       name                 = var.dns_settings.dns_zone_names.file_dns_zone_name
                                       private_dns_zone_ids = local.privatelink_file_defined ? (
                                        [var.dns_settings.privatelink_file_id]) : (
                                        [data.azurerm_private_dns_zone.file[0].id]
                                        )
                                     }
                                   }

  timeouts {
             create = "10m"
             delete = "30m"
           }
}

data "azurerm_private_endpoint_connection" "transport" {
  provider                             = azurerm.main
  count                                = var.create_transport_storage && local.use_AFS_for_shared ? (
                                          length(var.transport_private_endpoint_id) > 0 ? (
                                            1) : (
                                            0
                                          )) : (
                                          0
                                        )
  name                                 = split("/", var.transport_private_endpoint_id)[8]
  resource_group_name                  = split("/", var.transport_private_endpoint_id)[4]

}


################################################################################
#                                                                              #
#                     Install media storage account                            #
#                                                                              #
################################################################################

resource "azurerm_storage_account" "install" {
  provider                             = azurerm.main
  count                                = local.use_AFS_for_shared && length(var.install_storage_account_id) == 0 ? 1 : 0
  depends_on                           = [
                                           azurerm_subnet.app,
                                           azurerm_subnet.db,
                                           azurerm_subnet.web,
                                           azurerm_virtual_network_peering.peering_additional_network_sap,
                                           azurerm_virtual_network_peering.peering_sap_additional_network
                                         ]
  name                                 = replace(
                                           lower(
                                             format("%s", local.landscape_shared_install_storage_account_name)
                                           ),
                                           "/[^a-z0-9]/",
                                           ""
                                         )
  resource_group_name                  = local.resource_group_exists ? (
                                           data.azurerm_resource_group.resource_group[0].name) : (
                                           azurerm_resource_group.resource_group[0].name
                                         )
  location                             = local.resource_group_exists ? (
                                          data.azurerm_resource_group.resource_group[0].location) : (
                                          azurerm_resource_group.resource_group[0].location
                                        )

  account_kind                         = "FileStorage"
  account_replication_type             = var.storage_account_replication_type
  account_tier                         = "Premium"
  allow_nested_items_to_be_public      = false
  https_traffic_only_enabled            = false
  min_tls_version                      = "TLS1_2"
  cross_tenant_replication_enabled     = false
  public_network_access_enabled        = var.public_network_access_enabled
  tags                                 = var.tags
  shared_access_key_enabled            = var.infrastructure.shared_access_key_enabled_nfs

}

resource "azurerm_storage_account_network_rules" "install" {
  provider                             = azurerm.main
  count                                = local.use_AFS_for_shared && var.enable_firewall_for_keyvaults_and_storage  && length(var.install_storage_account_id) == 0 ? 1 : 0
  depends_on                           = [
                                            azurerm_storage_account.install,
                                            azurerm_storage_share.install,
                                            azurerm_storage_share.install_smb
                                         ]

  storage_account_id                   = azurerm_storage_account.install[0].id
  default_action                       = var.enable_firewall_for_keyvaults_and_storage ? "Deny" : "Allow"

  ip_rules                             = var.public_network_access_enabled ? compact([
                                                 length(local.deployer_public_ip_address) > 0 ? local.deployer_public_ip_address : "",
                                                 length(var.Agent_IP) > 0 ? var.Agent_IP : ""
                                                ]) : null

  virtual_network_subnet_ids           = var.public_network_access_enabled ? compact([
                                                  local.database_subnet_defined ? (
                                                    local.database_subnet_existing ? var.infrastructure.virtual_networks.sap.subnet_db.arm_id : azurerm_subnet.db[0].id) : (
                                                    null
                                                    ), local.application_subnet_defined ? (
                                                    local.application_subnet_existing ? var.infrastructure.virtual_networks.sap.subnet_app.arm_id : azurerm_subnet.app[0].id) : (
                                                    null
                                                  ),
                                                  length(local.deployer_subnet_management_id) > 0 ? local.deployer_subnet_management_id : null
                                                  ]
                                                ) : null
  bypass                               = ["Metrics", "Logging", "AzureServices"]
  lifecycle {
              ignore_changes = [virtual_network_subnet_ids]
            }
}
data "azurerm_storage_account" "install" {
  provider                             = azurerm.main
  count                                = local.use_AFS_for_shared && length(var.install_storage_account_id) > 0 ? 1 : 0
  name                                 = split("/", var.install_storage_account_id)[8]
  resource_group_name                  = split("/", var.install_storage_account_id)[4]
}

data "azurerm_private_endpoint_connection" "install" {
  provider                             = azurerm.main
  count                                = local.use_AFS_for_shared ? (
                                           length(var.install_private_endpoint_id) > 0 ? (
                                             1) : (
                                             0
                                           )) : (
                                           0
                                         )
  name                                 = split("/", var.install_private_endpoint_id)[8]
  resource_group_name                  = split("/", var.install_private_endpoint_id)[4]

}

resource "azurerm_private_endpoint" "install" {
  provider                             = azurerm.main

  depends_on                           = [
                                           azurerm_subnet.app,
                                           azurerm_storage_account.install,
                                           azurerm_private_dns_zone_virtual_network_link.vnet_sap_file,
                                           azurerm_storage_share.install,
                                           azurerm_storage_share.install_smb
                                         ]
  count                                = local.use_AFS_for_shared && var.use_private_endpoint ? (
                                           length(var.install_private_endpoint_id) > 0 ? (
                                             0) : (
                                             1
                                           )) : (
                                           0
                                         )
  name                                 = format("%s%s%s",
                                           var.naming.resource_prefixes.storage_private_link_install,
                                           local.prefix,
                                           local.resource_suffixes.storage_private_link_install
                                         )
  custom_network_interface_name        = format("%s%s%s%s",
                                          var.naming.resource_prefixes.storage_private_link_install,
                                          local.prefix,
                                          local.resource_suffixes.storage_private_link_install,
                                          var.naming.resource_suffixes.nic
                                        )

  resource_group_name                  = local.resource_group_exists ? (
                                           data.azurerm_resource_group.resource_group[0].name) : (
                                           azurerm_resource_group.resource_group[0].name
                                         )
  location                             = local.resource_group_exists ? (
                                          data.azurerm_resource_group.resource_group[0].location) : (
                                          azurerm_resource_group.resource_group[0].location
                                        )
  subnet_id                            = local.application_subnet_defined ? (
                                          local.application_subnet_existing ? var.infrastructure.virtual_networks.sap.subnet_app.arm_id : azurerm_subnet.app[0].id) : (
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

  dynamic "private_dns_zone_group" {
                                     for_each = range(var.dns_settings.register_endpoints_with_dns ? 1 : 0)
                                     content {
                                       name                 = var.dns_settings.dns_zone_names.file_dns_zone_name
                                       private_dns_zone_ids = local.privatelink_file_defined ? (
                                        [var.dns_settings.privatelink_file_id]) : (
                                        [data.azurerm_private_dns_zone.file[0].id])
                                     }
                                   }

  timeouts {
             create = "10m"
             delete = "30m"
           }
}

resource "azurerm_storage_share" "install" {
  provider                             = azurerm.main
  count                                = local.use_AFS_for_shared ? (
                                           length(var.install_storage_account_id) > 0 ? (
                                             var.install_always_create_fileshares ? 1 : 0) : (
                                             1
                                           )) : (
                                           0
                                         )

  name                                 = format("%s", local.resource_suffixes.install_volume)
  storage_account_id                   = local.use_AFS_for_shared ? (
                                           length(var.install_storage_account_id) > 0 ? (
                                             var.install_storage_account_id
                                             ) : (
                                             azurerm_storage_account.install[0].id
                                           )) : (
                                           ""
                                         )

  enabled_protocol                     = "NFS"

  quota                                = var.install_volume_size
}

resource "azurerm_storage_share" "install_smb" {
  provider                             = azurerm.main
  count                                = local.use_AFS_for_shared && var.install_create_smb_shares ? (
                                           length(var.install_storage_account_id) > 0 ? (
                                             var.install_always_create_fileshares ? 1 : 0) : (
                                             1
                                           )) : (
                                           0
                                         )

  name                                 = format("%s", local.resource_suffixes.install_volume_smb)
  storage_account_id                   = local.use_AFS_for_shared ? (
                                           length(var.install_storage_account_id) > 0 ? (
                                             var.install_storage_account_id
                                             ) : (
                                             azurerm_storage_account.install[0].id
                                           )) : (
                                           ""
                                         )

  enabled_protocol                     = "SMB"

  quota                                = var.install_volume_size
}

#Private endpoint tend to take a while to be created, so we need to wait for it to be ready before we can use it
resource "time_sleep" "wait_for_private_endpoints" {
  create_duration                      = "120s"

  depends_on                           = [
                                           azurerm_private_endpoint.install,
                                           azurerm_private_endpoint.transport,
                                           azurerm_private_endpoint.kv_user
                                         ]
}


# data "azurerm_network_interface" "storage_bootdiag" {
#   provider                             = azurerm.main
#   count                                = var.use_private_endpoint && length(var.diagnostics_storage_account.arm_id) == 0 && length(try(azurerm_private_endpoint.storage_bootdiag[0].network_interface[0].id, "")) > 0 ? 1 : 0
#   name                                 = azurerm_private_endpoint.storage_bootdiag[count.index].network_interface[0].name
#   resource_group_name                  = split("/", azurerm_private_endpoint.storage_bootdiag[count.index].network_interface[0].id)[4]
# }

# data "azurerm_network_interface" "witness_storage" {
#   provider                             = azurerm.main
#   count                                = var.use_private_endpoint && length(var.witness_storage_account.arm_id) == 0 && length(try(azurerm_private_endpoint.witness_storage[0].network_interface[0].id, "")) > 0 ? 1 : 0
#   name                                 = azurerm_private_endpoint.witness_storage[count.index].network_interface[0].name
#   resource_group_name                  = split("/", azurerm_private_endpoint.witness_storage[count.index].network_interface[0].id)[4]
# }

# data "azurerm_network_interface" "install" {
#   provider            = azurerm.main
#   count               = var.use_private_endpoint && length(var.install_storage_account_id) == 0 && var.NFS_provider == "AFS" && length(try(azurerm_private_endpoint.install[0].network_interface[0].name, "")) > 0 ? 1 : 0
#   name                = azurerm_private_endpoint.install[count.index].network_interface[0].name
#   resource_group_name = split("/", azurerm_private_endpoint.install[count.index].network_interface[0].id)[4]
# }

# data "azurerm_network_interface" "transport" {
#   provider            = azurerm.main
#   count               = var.use_private_endpoint && length(var.transport_storage_account_id) == 0 && var.NFS_provider == "AFS" && length(try(azurerm_private_endpoint.transport[0].network_interface[0].name, "")) > 0 ? 1 : 0
#   name                = azurerm_private_endpoint.transport[count.index].network_interface[0].name
#   resource_group_name = split("/", azurerm_private_endpoint.transport[count.index].network_interface[0].id)[4]
# }
