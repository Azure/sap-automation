
#######################################4#######################################8
#                                                                              #
#                           Terraform state account                            #
#                                                                              #
#######################################4#######################################8

locals {
  deployer_public_ip_address_used      = length(local.deployer_public_ip_address) > 0
  deployer_tfstate_subnet_used         = length(try(var.deployer_tfstate.subnet_mgmt_id, "")) > 0
}

// Creates storage account for storing tfstate
resource "azurerm_storage_account" "storage_tfstate" {
  provider                             = azurerm.main
  count                                = local.sa_tfstate_exists ? 0 : 1
  name                                 = length(var.storage_account_tfstate.name) > 0 ? (
                                            var.storage_account_tfstate.name) : (
                                            var.naming.storageaccount_names.LIBRARY.terraformstate_storageaccount_name
                                          )
  resource_group_name                  = local.resource_group_name
  location                             = local.resource_group_library_location

  account_replication_type             = var.storage_account_tfstate.account_replication_type
  account_tier                         = var.storage_account_tfstate.account_tier
  account_kind                         = var.storage_account_tfstate.account_kind
  min_tls_version                      = "TLS1_2"
  allow_nested_items_to_be_public      = false

  public_network_access_enabled        = true #var.storage_account_sapbits.public_network_access_enabled

  enable_https_traffic_only            = true

  shared_access_key_enabled            = var.storage_account_sapbits.shared_access_key_enabled

  blob_properties {
                    delete_retention_policy {
                                              days = 7
                                            }
                  }

  routing {
            publish_microsoft_endpoints = true
            choice                      = "MicrosoftRouting"
          }

  network_rules {
                  default_action = local.enable_firewall_for_keyvaults_and_storage ? "Deny" : "Allow"
                  virtual_network_subnet_ids = local.virtual_additional_network_ids
                  ip_rules = local.deployer_public_ip_address_used ? (
                    [
                      local.deployer_public_ip_address
                    ]) : compact(
                    [
                      try(var.deployer_tfstate.Agent_IP, ""),
                      try(var.Agent_IP, "")
                    ]
                  )
                }

  # lifecycle {
  #             ignore_changes = [tags]
  #           }

  tags = {
      "enable_firewall_for_keyvaults_and_storage" = local.enable_firewall_for_keyvaults_and_storage
      "public_network_access_enabled" = var.storage_account_sapbits.public_network_access_enabled
    }

}


// Imports existing storage account to use for tfstate
data "azurerm_storage_account" "storage_tfstate" {
  provider                             = azurerm.main
  count                                = local.sa_tfstate_exists ? 1 : 0
  name                                 = split("/", var.storage_account_tfstate.arm_id)[8]
  resource_group_name                  = split("/", var.storage_account_tfstate.arm_id)[4]
}

resource "azurerm_role_assignment" "storage_tfstate_contributor" {
  count                                = try(var.deployer_tfstate.deployer_uai.principal_id, "") != "" ? 1 : 0
  provider                             = azurerm.main
  scope                                = local.sa_tfstate_exists ? var.storage_account_tfstate.arm_id : azurerm_storage_account.storage_tfstate[0].id
  role_definition_name                 = "Storage Account Contributor"
  principal_id                         = var.deployer_tfstate.deployer_uai.principal_id
}

resource "azurerm_role_assignment" "storage_tfstate_contributor_ssi" {
  provider                             = azurerm.main
  count                                = try(var.deployer_tfstate.add_system_assigned_identity, false) ? length(var.deployer_tfstate.deployer_system_assigned_identity) : 0
  scope                                = local.sa_tfstate_exists ? var.storage_account_tfstate.arm_id : azurerm_storage_account.storage_tfstate[0].id
  role_definition_name                 = "Storage Account Contributor"
  principal_id                         = var.deployer_tfstate.deployer_system_assigned_identity[count.index]
}

resource "azurerm_private_dns_a_record" "storage_tfstate_pep_a_record_registry" {
  provider                             = azurerm.dnsmanagement
  count                                = var.use_private_endpoint && var.use_custom_dns_a_registration && !local.sa_tfstate_exists ? 1 : 0
  depends_on                           = [
                                           azurerm_private_dns_zone.blob
                                         ]
  name                                 = lower(azurerm_storage_account.storage_tfstate[0].name)
  zone_name                            = var.dns_zone_names.blob_dns_zone_name
  resource_group_name                  = coalesce(
                                           var.management_dns_resourcegroup_name,
                                           local.resource_group_exists ? (
                                             data.azurerm_resource_group.library[0].name
                                             ) : (
                                             azurerm_resource_group.library[0].name
                                           )
                                         )
  ttl                                  = 3600
  records                              = [data.azurerm_network_interface.storage_tfstate[count.index].ip_configuration[0].private_ip_address]

  lifecycle {
              ignore_changes = [tags]
            }
}

#Errors can occure when the dns record has not properly been activated, add a wait timer to give
#it just a little bit more time
resource "time_sleep" "wait_for_dns_refresh" {
  create_duration                      = "120s"

  depends_on                           = [
                                           azurerm_private_dns_a_record.storage_tfstate_pep_a_record_registry,
                                           azurerm_private_dns_a_record.storage_sapbits_pep_a_record_registry
                                         ]
}


resource "azurerm_private_endpoint" "storage_tfstate" {
  provider                             = azurerm.main
  count                                = var.use_private_endpoint && !local.sa_tfstate_exists ? 1 : 0
  name                                 = format("%s%s%s",
                                           var.naming.resource_prefixes.storage_private_link_tf,
                                           local.prefix,
                                           var.naming.resource_suffixes.storage_private_link_tf
                                         )
  resource_group_name                  = local.resource_group_exists ? (
                                           data.azurerm_resource_group.library[0].name) : (
                                           azurerm_resource_group.library[0].name
                                         )
  location                             = local.resource_group_exists ? (
                                           data.azurerm_resource_group.library[0].location) : (
                                           azurerm_resource_group.library[0].location
                                         )

  subnet_id                            = var.deployer_tfstate.subnet_mgmt_id

  custom_network_interface_name        = var.short_named_endpoints_nics ? format("%s%s%s%s",
                                           var.naming.resource_prefixes.storage_private_link_tf,
                                           length(local.prefix) > 0 ? (
                                             local.prefix) : (
                                             var.infrastructure.environment
                                           ),
                                           var.naming.resource_suffixes.storage_private_link_tf,
                                           var.naming.resource_suffixes.nic
                                         ) : null

  private_service_connection {
                               name = format("%s%s%s", var.naming.resource_prefixes.storage_private_svc_tf,
                                 local.prefix,
                                 var.naming.resource_suffixes.storage_private_svc_tf
                               )
                               is_manual_connection = false
                               private_connection_resource_id = local.sa_tfstate_exists ? (
                                 var.storage_account_tfstate.arm_id) : (
                                 azurerm_storage_account.storage_tfstate[0].id
                               )
                               subresource_names = [
                                 "Blob"
                               ]
                             }

  dynamic "private_dns_zone_group" {
                                     for_each = range(var.use_private_endpoint && !var.use_custom_dns_a_registration ? 1 : 0)
                                     content {
                                               name                 = var.dns_zone_names.blob_dns_zone_name
                                               private_dns_zone_ids = [local.use_local_private_dns ? azurerm_private_dns_zone.blob[0].id : data.azurerm_private_dns_zone.storage[0].id]
                                             }
                                   }

  lifecycle {
              ignore_changes = [tags]
            }
}

resource "azurerm_private_endpoint" "table_tfstate" {
  provider                             = azurerm.main
  count                                = var.use_private_endpoint && !local.sa_tfstate_exists && var.use_webapp ? 1 : 0
  depends_on                           = [ azurerm_private_dns_zone.table ]
  name                                 = format("%s%s-table%s",
                                           var.naming.resource_prefixes.storage_private_link_tf,
                                           local.prefix,
                                           var.naming.resource_suffixes.storage_private_link_tf
                                         )
  resource_group_name                  = local.resource_group_exists ? (
                                           data.azurerm_resource_group.library[0].name) : (
                                           azurerm_resource_group.library[0].name
                                         )
  location                             = local.resource_group_exists ? (
                                           data.azurerm_resource_group.library[0].location) : (
                                           azurerm_resource_group.library[0].location
                                         )

  subnet_id                            = var.deployer_tfstate.subnet_mgmt_id

  custom_network_interface_name        = var.short_named_endpoints_nics ? format("%s%s%s%s",
                                           var.naming.resource_prefixes.storage_private_link_tf,
                                           length(local.prefix) > 0 ? (
                                             local.prefix) : (
                                             var.infrastructure.environment
                                           ),
                                           var.naming.resource_suffixes.storage_private_link_tf,
                                           var.naming.resource_suffixes.nic
                                         ) : null

  private_service_connection {
                               name = format("%s%s%s", var.naming.resource_prefixes.storage_private_svc_tf,
                                 local.prefix,
                                 var.naming.resource_suffixes.storage_private_svc_tf
                               )
                               is_manual_connection = false
                               private_connection_resource_id = local.sa_tfstate_exists ? (
                                 var.storage_account_tfstate.arm_id) : (
                                 azurerm_storage_account.storage_tfstate[0].id
                               )
                               subresource_names = [
                                 "table"
                               ]
                             }

  dynamic "private_dns_zone_group" {
                                     for_each = range(var.use_private_endpoint && !var.use_custom_dns_a_registration && var.use_webapp ? 1 : 0)
                                     content {
                                               name                 = var.dns_zone_names.blob_dns_zone_name
                                               private_dns_zone_ids = [local.use_local_private_dns ? azurerm_private_dns_zone.table[0].id : data.azurerm_private_dns_zone.table[0].id]
                                             }
                                   }

  lifecycle {
              ignore_changes = [tags]
            }
}

// Creates the storage container inside the storage account for sapsystem
resource "azurerm_storage_container" "storagecontainer_tfstate" {
  provider                             = azurerm.main
  count                                = var.storage_account_tfstate.tfstate_blob_container.is_existing ? 0 : 1
  depends_on                           = [
                                           time_sleep.wait_for_dns_refresh,
                                           azurerm_private_endpoint.storage_tfstate,
                                           azurerm_private_dns_a_record.storage_tfstate_pep_a_record_registry
                                         ]
  name                                 = var.storage_account_tfstate.tfstate_blob_container.name
                                           storage_account_name = local.sa_tfstate_exists ? (
                                             data.azurerm_storage_account.storage_tfstate[0].name) : (
                                             azurerm_storage_account.storage_tfstate[0].name
                                           )
  container_access_type                = "private"

}

data "azurerm_storage_container" "storagecontainer_tfstate" {
  provider                             = azurerm.main
  count                                = var.storage_account_tfstate.tfstate_blob_container.is_existing ? 1 : 0
  name                                 = var.storage_account_tfstate.tfstate_blob_container.name
                                           storage_account_name = local.sa_tfstate_exists ? (
                                             data.azurerm_storage_account.storage_tfstate[0].name) : (
                                             azurerm_storage_account.storage_tfstate[0].name
                                           )
}

##############################################################################################
#
#  SAPBits storage account which is used to store the SAP media and the BoM files
#
##############################################################################################
resource "azurerm_storage_account" "storage_sapbits" {
  provider                             = azurerm.main
  count                                = local.sa_sapbits_exists ? 0 : 1
  name                                 = length(var.storage_account_sapbits.name) > 0 ? (
                                           var.storage_account_sapbits.name) : (
                                           var.naming.storageaccount_names.LIBRARY.library_storageaccount_name
                                         )
  resource_group_name                  = local.resource_group_name
  location                             = local.resource_group_library_location
  account_replication_type             = var.storage_account_sapbits.account_replication_type
  account_tier                         = var.storage_account_sapbits.account_tier
  account_kind                         = var.storage_account_sapbits.account_kind
  enable_https_traffic_only            = true
  min_tls_version                      = "TLS1_2"

  allow_nested_items_to_be_public      = false

  public_network_access_enabled        = var.storage_account_sapbits.public_network_access_enabled

  routing {
            publish_microsoft_endpoints = true
            choice                      = "MicrosoftRouting"
          }
  network_rules {
                  default_action = local.enable_firewall_for_keyvaults_and_storage ? "Deny" : "Allow"
                  virtual_network_subnet_ids = local.virtual_additional_network_ids
                  ip_rules = local.deployer_public_ip_address_used ? (
                    [
                      local.deployer_public_ip_address
                    ]) : compact(
                    [
                      try(var.deployer_tfstate.Agent_IP, ""),
                      try(var.Agent_IP, "")
                    ]
                  )
                }

  lifecycle {
              ignore_changes = [tags]
            }
}

resource "azurerm_private_dns_a_record" "storage_sapbits_pep_a_record_registry" {
  provider                             = azurerm.dnsmanagement
  count                                = var.use_private_endpoint && var.use_custom_dns_a_registration && !local.sa_sapbits_exists ? 1 : 0
  depends_on                           = [
                                           azurerm_private_dns_zone.blob
                                         ]

  name                                 = lower(azurerm_storage_account.storage_sapbits[0].name)
  zone_name                            = var.dns_zone_names.blob_dns_zone_name
  resource_group_name                  = coalesce(
                                            var.management_dns_resourcegroup_name,
                                            local.resource_group_exists ? (
                                              data.azurerm_resource_group.library[0].name) : (
                                              azurerm_resource_group.library[0].name)
                                         )
  ttl                                  = 3600
  records                              = [data.azurerm_network_interface.storage_sapbits[count.index].ip_configuration[0].private_ip_address]

  lifecycle {
              ignore_changes = [tags]
            }
}

data "azurerm_storage_account" "storage_sapbits" {
  provider                             = azurerm.main
  count                                = local.sa_sapbits_exists ? 1 : 0
  name                                 = split("/", var.storage_account_sapbits.arm_id)[8]
  resource_group_name                  = split("/", var.storage_account_sapbits.arm_id)[4]
}


resource "azurerm_private_endpoint" "storage_sapbits" {
  provider                             = azurerm.main
  count                                = var.use_private_endpoint && !local.sa_sapbits_exists ? 1 : 0
  name                                 = format("%s%s%s",
                                           var.naming.resource_prefixes.storage_private_link_sap,
                                           local.prefix,
                                           var.naming.resource_suffixes.storage_private_link_sap
                                         )
  resource_group_name                  = local.resource_group_exists ? (
                                          data.azurerm_resource_group.library[0].name) : (
                                          azurerm_resource_group.library[0].name
                                        )

  location                             = local.resource_group_exists ? (
                                           data.azurerm_resource_group.library[0].location) : (
                                           azurerm_resource_group.library[0].location
                                         )
  subnet_id                            = var.deployer_tfstate.subnet_mgmt_id
  custom_network_interface_name        = var.short_named_endpoints_nics ? format("%s%s%s%s",
                                           var.naming.resource_prefixes.storage_private_link_sap,
                                           length(local.prefix) > 0 ? (
                                             local.prefix) : (
                                             var.infrastructure.environment
                                           ),
                                           var.naming.resource_suffixes.storage_private_link_sap,
                                           var.naming.resource_suffixes.nic
                                         ) : null

  private_service_connection {
                               name = format("%s%s%s",
                                         var.naming.resource_prefixes.storage_private_svc_sap,
                                         local.prefix,
                                         var.naming.resource_suffixes.storage_private_svc_sap
                                       )
                               is_manual_connection = false
                               private_connection_resource_id = local.sa_sapbits_exists ? (
                                 data.azurerm_storage_account.storage_sapbits[0].id) : (
                                 azurerm_storage_account.storage_sapbits[0].id
                               )
                               subresource_names = [
                                                     "Blob"
                                                   ]
                             }

  dynamic "private_dns_zone_group" {
                                      for_each = range(var.use_private_endpoint && !var.use_custom_dns_a_registration ? 1 : 0)
                                      content {
                                                name                 = var.dns_zone_names.blob_dns_zone_name
                                                private_dns_zone_ids = [local.use_local_private_dns ? azurerm_private_dns_zone.blob[0].id : data.azurerm_private_dns_zone.storage[0].id]
                                              }

                                    }

  lifecycle {
    ignore_changes = [tags]
  }
}

// Creates the storage container inside the storage account for SAP bits
resource "azurerm_storage_container" "storagecontainer_sapbits" {
  provider                             = azurerm.main
  count                                = var.storage_account_sapbits.sapbits_blob_container.is_existing ? 0 : 1
  depends_on                           = [
                                           time_sleep.wait_for_dns_refresh,
                                           azurerm_private_endpoint.storage_sapbits,
                                           azurerm_private_dns_a_record.storage_sapbits_pep_a_record_registry
                                         ]
  name                                 = var.storage_account_sapbits.sapbits_blob_container.name
  storage_account_name                 = local.sa_sapbits_exists ? (
                                             data.azurerm_storage_account.storage_sapbits[0].name) : (
                                             azurerm_storage_account.storage_sapbits[0].name
                                           )
  container_access_type                = "private"
}

// Imports existing storage blob container for SAP bits
data "azurerm_storage_container" "storagecontainer_sapbits" {
  provider                             = azurerm.main
  count                                = var.storage_account_sapbits.sapbits_blob_container.is_existing ? 1 : 0
  name                                 = var.storage_account_sapbits.sapbits_blob_container.name
                                           storage_account_name = local.sa_sapbits_exists ? (
                                             data.azurerm_storage_account.storage_sapbits[0].name) : (
                                             azurerm_storage_account.storage_sapbits[0].name
                                           )
}

// Creates file share inside the storage account for SAP bits
resource "azurerm_storage_share" "fileshare_sapbits" {
  provider                             = azurerm.main
  count                                = !var.storage_account_sapbits.file_share.is_existing ? 0 : 0
  name                                 = var.storage_account_sapbits.file_share.name
                                           storage_account_name = local.sa_sapbits_exists ? (
                                             data.azurerm_storage_account.storage_sapbits[0].name) : (
                                             azurerm_storage_account.storage_sapbits[0].name
                                           )
  quota                                = 1024
}

resource "azurerm_role_assignment" "storage_sapbits_contributor" {
  provider                             = azurerm.main
  count                                = try(var.deployer_tfstate.deployer_uai.principal_id, "") != "" ? 1 : 0
  scope                                = local.sa_sapbits_exists ? var.storage_account_sapbits.arm_id : azurerm_storage_account.storage_sapbits[0].id
  role_definition_name                 = "Storage Account Contributor"
  principal_id                         = var.deployer_tfstate.deployer_uai.principal_id
}

resource "azurerm_role_assignment" "storage_sapbits_contributor_ssi" {
  provider                             = azurerm.main
  count                                = try(var.deployer_tfstate.add_system_assigned_identity, false) ? length(var.deployer_tfstate.deployer_system_assigned_identity) : 0
  scope                                = local.sa_sapbits_exists ? var.storage_account_sapbits.arm_id : azurerm_storage_account.storage_sapbits[0].id
  role_definition_name                 = "Storage Account Contributor"
  principal_id                         = var.deployer_tfstate.deployer_system_assigned_identity[count.index]
}



data "azurerm_private_dns_zone" "storage" {
  provider                             = azurerm.dnsmanagement
  count                                = !local.use_local_private_dns && var.use_private_endpoint ? 1 : 0
  name                                 = var.dns_zone_names.blob_dns_zone_name
  resource_group_name                  = var.management_dns_resourcegroup_name

}

data "azurerm_private_dns_zone" "table" {
  provider                             = azurerm.dnsmanagement
  count                                = !local.use_local_private_dns && var.use_private_endpoint ? 1 : 0
  name                                 = var.dns_zone_names.table_dns_zone_name
  resource_group_name                  = var.management_dns_resourcegroup_name

}

data "azurerm_network_interface" "storage_tfstate" {
  count                                = var.use_private_endpoint && !local.sa_tfstate_exists ? 1 : 0
  name                                 = azurerm_private_endpoint.storage_tfstate[count.index].network_interface[0].name
  resource_group_name                  = split("/", azurerm_private_endpoint.storage_tfstate[count.index].network_interface[0].id)[4]
}

data "azurerm_network_interface" "storage_sapbits" {
  count                                = var.use_private_endpoint && !local.sa_sapbits_exists ? 1 : 0
  name                                 = azurerm_private_endpoint.storage_sapbits[count.index].network_interface[0].name
  resource_group_name                  = split("/", azurerm_private_endpoint.storage_sapbits[count.index].network_interface[0].id)[4]
}

resource "azurerm_management_lock" "storage_tfstate" {
  provider                             = azurerm.main
  count                                = (local.sa_tfstate_exists) ? 0 : var.place_delete_lock_on_resources ? 1 : 0
  name                                 = format("%s-lock", azurerm_storage_account.storage_tfstate[0].name)
  scope                                = azurerm_storage_account.storage_tfstate[0].id
  lock_level                           = "CanNotDelete"
  notes                                = "Locked because it's needed by Terraform to store state"
  lifecycle {
    prevent_destroy = false
  }
}

// Creates the storage container inside the storage account for sapsystem
resource "azurerm_storage_container" "storagecontainer_tfvars" {
  provider                             = azurerm.main
  count                                = var.storage_account_tfstate.tfvars_blob_container.is_existing ? 0 : 1
  depends_on                           = [
                                           azurerm_private_endpoint.storage_tfstate
                                         ]
  name                                 = var.storage_account_tfstate.tfvars_blob_container.name
  storage_account_name                 = local.sa_tfstate_exists ? (
                                           data.azurerm_storage_account.storage_tfstate[0].name) : (
                                           azurerm_storage_account.storage_tfstate[0].name
                                         )
  container_access_type                = "private"

}

data "azurerm_storage_container" "storagecontainer_tfvars" {
  provider                             = azurerm.main
  count                                = var.storage_account_tfstate.tfvars_blob_container.is_existing ? 1 : 0
  name                                 = var.storage_account_tfstate.tfvars_blob_container.name
  storage_account_name                 = local.sa_tfstate_exists ? (
                                           data.azurerm_storage_account.storage_tfstate[0].name) : (
                                           azurerm_storage_account.storage_tfstate[0].name
                                         )
}
