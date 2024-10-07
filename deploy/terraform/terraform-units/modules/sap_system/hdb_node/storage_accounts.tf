
resource "azurerm_storage_account" "hanashared" {
  provider                             = azurerm.main
  count                                = var.NFS_provider == "AFS" && var.database.scale_out ? (
                                           length(var.hanashared_id) > 0 ? (
                                             0) : (
                                             length(var.database.zones)
                                           )) : (
                                           0
                                         )
  name                                 = substr(replace(
                                           lower(
                                             format("%s%s%01d%s",
                                               lower(local.sid),
                                               local.resource_suffixes.hanasharedafs, count.index,var.random_id
                                             )
                                           ),
                                           "/[^a-z0-9]/",
                                           ""
                                         ), 0, 24)


  resource_group_name                  = var.resource_group[0].name
  location                             = var.resource_group[0].location
  account_tier                         = "Premium"
  account_replication_type             = "ZRS"
  account_kind                         = "FileStorage"
  https_traffic_only_enabled            = false
  min_tls_version                      = "TLS1_2"
  allow_nested_items_to_be_public      = false
  cross_tenant_replication_enabled     = false
  shared_access_key_enabled            = var.infrastructure.shared_access_key_enabled_nfs

  public_network_access_enabled        = try(var.landscape_tfstate.public_network_access_enabled, true)
  tags                                 = var.tags

  network_rules {
                  default_action = "Deny"
                  virtual_network_subnet_ids = compact(
                    [
                      try(var.landscape_tfstate.admin_subnet_id, ""),
                      try(var.landscape_tfstate.app_subnet_id, ""),
                      try(var.landscape_tfstate.db_subnet_id, ""),
                      try(var.landscape_tfstate.web_subnet_id, ""),
                      try(var.landscape_tfstate.subnet_mgmt_id, "")
                    ]
                  )
                  ip_rules = compact(
                    [
                      length(var.Agent_IP) > 0 ? var.Agent_IP : ""
                    ]
                  )
                }


}


data "azurerm_storage_account" "hanashared" {
  provider                             = azurerm.main
  count                                = var.NFS_provider == "AFS" && var.database.scale_out ? (
                                           length(var.hanashared_id) > 0 ? (
                                             length(var.hanashared_id)) : (
                                             0
                                           )) : (
                                           0
                                         )
  name                                 = split("/", var.hanashared_id[count.index])[8]
  resource_group_name                  = split("/", var.hanashared_id[count.index])[4]
}
#########################################################################################
#                                                                                       #
#  NFS share                                                                            #
#                                                                                       #
#########################################################################################

resource "azurerm_storage_share" "hanashared" {
  provider                             = azurerm.main
   count                                = var.NFS_provider == "AFS" && var.database.scale_out ? (
                                           length(var.hanashared_id) > 0 ? (
                                             0) : (
                                             length(var.database.zones)
                                           )) : (
                                           0
                                         )
 depends_on                           = [
                                           azurerm_storage_account.hanashared,
                                           azurerm_private_endpoint.hanashared,
                                           time_sleep.wait_for_private_endpoints
                                         ]

  name                                 = format("%s-%s-%01d", lower(local.sid),local.resource_suffixes.hanasharedafs, count.index+1)
  storage_account_name                 = var.NFS_provider == "AFS" ? (
                                           length(var.hanashared_id) > 0 ? (
                                             data.azurerm_storage_account.hanashared[count.index].name) : (
                                             azurerm_storage_account.hanashared[count.index].name
                                           )
                                           ) : (
                                           ""
                                         )
  enabled_protocol                     = "NFS"

  quota                                = var.hanashared_volume_size
}

resource "azurerm_private_endpoint" "hanashared" {
  provider                             = azurerm.main
  count                                = var.NFS_provider == "AFS" && var.use_private_endpoint && var.database.scale_out ? (
                                          length(var.hanashared_private_endpoint_id) > 0 ? (
                                            0) : (
                                            length(var.database.zones)
                                          )) : (
                                          0
                                        )
  name                                 = format("%s%s%d%s",
                                           var.naming.resource_prefixes.storage_privatelink_hanashared,
                                           local.prefix,count.index,
                                           local.resource_suffixes.storage_privatelink_hanashared
                                         )

  resource_group_name                  = var.resource_group[0].name
  location                             = var.resource_group[0].location

  subnet_id                            = var.landscape_tfstate.admin_subnet_id
  tags                                 = var.tags

  custom_network_interface_name        = format("%s%s%s%d%s",
                                           var.naming.resource_prefixes.storage_privatelink_hanashared,
                                           length(local.prefix) > 0 ? (
                                             local.prefix) : (
                                             var.infrastructure.environment
                                           ),
                                           var.naming.resource_suffixes.storage_privatelink_hanashared,
                                           count.index,
                                           var.naming.resource_suffixes.nic
                                         )


  private_service_connection {
                              name = format("%s%s%d%s",
                                var.naming.resource_prefixes.storage_privatelink_hanashared,
                                local.prefix,
                                count.index,
                                local.resource_suffixes.storage_privatelink_hanashared
                              )
                              is_manual_connection = false
                              private_connection_resource_id = length(var.hanashared_id) > 0 ? (
                                var.hanashared_id[count.index]) : (
                                azurerm_storage_account.hanashared[count.index].id
                              )
                              subresource_names = [
                                "File"
                              ]
                            }


  dynamic "private_dns_zone_group" {
                                     for_each = range(length(try(var.landscape_tfstate.privatelink_file_id, "")) > 0 && var.dns_settings.register_endpoints_with_dns ? 1 : 0)
                                     content {
                                       name                 = var.dns_settings.dns_zone_names.file_dns_zone_name
                                       private_dns_zone_ids = [var.landscape_tfstate.privatelink_file_id]
                                     }
                                   }

  timeouts {
             create = "10m"
             delete = "30m"
           }
}

#Private endpoint tend to take a while to be created, so we need to wait for it to be ready before we can use it
resource "time_sleep" "wait_for_private_endpoints" {
  create_duration                      = "120s"

  depends_on                           = [ azurerm_private_endpoint.hanashared ]
}

data "azurerm_private_endpoint_connection" "hanashared" {
  provider                             = azurerm.main
  count                                = var.NFS_provider == "AFS" && var.use_private_endpoint && var.database.scale_out ? (
                                           length(var.hanashared_private_endpoint_id) > 0 ? (
                                             length(var.database.zones)) : (
                                             0
                                           )) : (
                                           0
                                         )
  name                                 = split("/", var.hanashared_private_endpoint_id[count.index])[8]
  resource_group_name                  = split("/", var.hanashared_private_endpoint_id[count.index])[4]

}
