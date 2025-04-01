# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.


#######################################4#######################################8
#                                                                              #
#                             Azure Storage Account                            #
#                                                                              #
#######################################4#######################################8

resource "azurerm_storage_account" "sapmnt" {
  provider                             = azurerm.main
  count                                = var.NFS_provider == "AFS" ? (
                                           length(var.azure_files_sapmnt_id) > 0 ? (
                                             0) : (
                                             1
                                           )) : (
                                           0
                                         )
  name                                 = substr(replace(
                                           lower(
                                             format("%s%s%s",
                                               local.prefix,
                                               local.resource_suffixes.sapmnt,
                                               try(
                                                 local.resource_suffixes.sapmnt_id,
                                                 substr(random_id.random_id.hex, 0, 3)
                                               )
                                             )
                                           ),
                                           "/[^a-z0-9]/",
                                           ""
                                         ), 0, 24)


  resource_group_name                  = local.resource_group_exists ? (
                                          data.azurerm_resource_group.resource_group[0].name) : (
                                          azurerm_resource_group.resource_group[0].name
                                        )
  location                             = var.infrastructure.region
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
                  default_action       = var.enable_firewall_for_keyvaults_and_storage ? "Deny" : "Allow"
                  bypass               = ["Metrics", "Logging", "AzureServices"]
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

}

data "azurerm_storage_account" "sapmnt" {
  provider                             = azurerm.main
  count                                = var.NFS_provider == "AFS" ? (
                                           length(var.azure_files_sapmnt_id) > 0 ? (
                                             1) : (
                                             0
                                           )) : (
                                           0
                                         )
  name                                 = split("/", var.azure_files_sapmnt_id)[8]
  resource_group_name                  = split("/", var.azure_files_sapmnt_id)[4]
}

resource "azurerm_private_endpoint" "sapmnt" {
  provider                             = azurerm.main
  count                                = var.NFS_provider == "AFS" && var.use_private_endpoint ? (
                                          length(var.sapmnt_private_endpoint_id) > 0 ? (
                                            0) : (
                                            1
                                          )) : (
                                          0
                                        )
  name                                 = format("%s%s%s",
                                           var.naming.resource_prefixes.storage_private_link_sapmnt,
                                           local.prefix,
                                           local.resource_suffixes.storage_private_link_sapmnt
                                         )

  resource_group_name                  = local.resourcegroup_name
  location                             = local.resource_group_exists ? (
                                           data.azurerm_resource_group.resource_group[0].location) : (
                                           azurerm_resource_group.resource_group[0].location
                                         )
  subnet_id                            = try(var.landscape_tfstate.use_separate_storage_subnet, false) ? (
                                         var.landscape_tfstate.storage_subnet_id ) : (
                                         var.landscape_tfstate.app_subnet_id
                                       )
  tags                                 = var.tags

  custom_network_interface_name        = format("%s%s%s%s",
                                           var.naming.resource_prefixes.storage_private_link_sapmnt,
                                           local.prefix,
                                           var.naming.resource_suffixes.storage_private_link_sapmnt,
                                           try(var.naming.resource_suffixes.private_endpoint_nic, var.naming.resource_suffixes.nic)
                                         )


  private_service_connection {
                              name = format("%s%s%s",
                                var.naming.resource_prefixes.storage_private_link_sapmnt,
                                local.prefix,
                                local.resource_suffixes.storage_private_link_sapmnt
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

  depends_on                           = [ azurerm_private_endpoint.sapmnt ]
}



data "azurerm_private_endpoint_connection" "sapmnt" {
  provider                             = azurerm.main
  count                                = var.NFS_provider == "AFS" ? (
                                           length(var.sapmnt_private_endpoint_id) > 0 ? (
                                             1) : (
                                             0
                                           )) : (
                                           0
                                         )
  name                                 = split("/", var.sapmnt_private_endpoint_id)[8]
  resource_group_name                  = split("/", var.sapmnt_private_endpoint_id)[4]

}

#########################################################################################
#                                                                                       #
#  NFS share                                                                            #
#                                                                                       #
#########################################################################################

resource "azurerm_storage_share" "sapmnt" {
  provider                             = azurerm.main
  count                                = var.NFS_provider == "AFS" ? 1 : 0
  depends_on                           = [
                                           azurerm_storage_account.sapmnt,
                                           azurerm_private_endpoint.sapmnt,
                                           time_sleep.wait_for_private_endpoints
                                         ]

  name                                 = format("%s", try(
                                           local.resource_suffixes.sapmnt_share,
                                           local.resource_suffixes.sapmnt
                                         ))
  storage_account_id                   = var.NFS_provider == "AFS" ? (
                                           length(var.azure_files_sapmnt_id) > 0 ? (
                                             data.azurerm_storage_account.sapmnt[0].id) : (
                                             azurerm_storage_account.sapmnt[0].id
                                           )
                                           ) : (
                                           ""
                                         )
  enabled_protocol                     = "NFS"

  quota                                = var.sapmnt_volume_size
}

#########################################################################################
#                                                                                       #
#  SMB share                                                                            #
#                                                                                       #
#########################################################################################

resource "azurerm_storage_share" "sapmnt_smb" {
  provider                             = azurerm.main
  count                                = var.NFS_provider == "AFS" && local.app_tier_os == "WINDOWS" ? (
                                           length(var.azure_files_sapmnt_id) > 0 ? (
                                             0) : (
                                             1
                                           )) : (
                                           0
                                         )
  depends_on                           = [
                                          azurerm_storage_account.sapmnt,
                                          azurerm_private_endpoint.sapmnt,
                                          time_sleep.wait_for_private_endpoints
                                        ]

  name                                 = format("%s", local.resource_suffixes.sapmnt_smb)
  storage_account_id                   = var.NFS_provider == "AFS" ? azurerm_storage_account.sapmnt[0].id : ""
  enabled_protocol                     = "SMB"

  quota                                = var.sapmnt_volume_size

}
