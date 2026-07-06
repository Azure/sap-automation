# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.


###############################################################################
#                                                                             #
#                             Resource Group                                  #
#                                                                             #
###############################################################################

output "created_resource_group_id"              {
                                                  description = "Created resource group ID"
                                                  value       = var.infrastructure.resource_group.exists ? data.azurerm_resource_group.library[0].id : azurerm_resource_group.library[0].id
                                                }

output "created_resource_group_subscription_id" {
                                                  description = "Created resource group' subscription ID"
                                                  value = var.infrastructure.resource_group.exists ? (
                                                    split("/", data.azurerm_resource_group.library[0].id))[2] : (
                                                    split("/", azurerm_resource_group.library[0].id)[2]
                                                  )
                                                }

output "created_resource_group_name"            {
                                                  description = "Created resource group name"
                                                  value = var.infrastructure.resource_group.exists ? (
                                                    data.azurerm_resource_group.library[0].name) : (
                                                    azurerm_resource_group.library[0].name
                                                  )
                                                }


###############################################################################
#                                                                             #
#                             Storage Accounts                                #
#                                                                             #
###############################################################################

output "tfstate_storage_account"                 {
                                                   description = "TFState storage account name"
                                                   value = var.storage_account_tfstate.exists ? (
                                                     split("/", var.storage_account_tfstate.id)[8]) : (
                                                     length(var.storage_account_tfstate.name) > 0 ? (
                                                       var.storage_account_tfstate.name) : (
                                                       var.naming.storageaccount_names.LIBRARY.terraformstate_storageaccount_name
                                                   ))
                                                 }

output "storagecontainer_tfstate"                {
                                                   description = "TFState container name"
                                                   value       = var.storage_account_tfstate.tfstate_blob_container.name
                                                 }


output "sapbits_storage_account_name"            {
                                                   description = "SAPBits storage account name"
                                                   value = var.storage_account_sapbits.exists ? (
                                                     split("/", var.storage_account_sapbits.id)[8]) : (
                                                     length(var.storage_account_sapbits.name) > 0 ? (
                                                       var.storage_account_sapbits.name) : (
                                                       var.naming.storageaccount_names.LIBRARY.library_storageaccount_name
                                                   ))

                                                 }

output "sapbits_sa_resource_group_name"          {
                                                   description = "SAPBits storage account resource group name"
                                                   value       = local.resource_group_name
                                                 }

output "storagecontainer_sapbits_name"           {
                                                   description = "SAP Bits container name"
                                                   value       = var.storage_account_sapbits.file_share.name
                                                 }

output "random_id"                               {
                                                   value = random_id.post_fix.hex
                                                 }

output "remote_state_storage_account_name"       {
                                                   description = "Storage account name for Terraform remote state"
                                                   value = var.storage_account_tfstate.exists ? (
                                                     split("/", var.storage_account_tfstate.id)[8]) : (
                                                     length(var.storage_account_tfstate.name) > 0 ? (
                                                       var.storage_account_tfstate.name) : (
                                                       var.naming.storageaccount_names.LIBRARY.terraformstate_storageaccount_name
                                                   ))
                                                 }


output "tfstate_resource_id"                     {
                                                   description = "value of the Azure resource id for the tfstate storage account"
                                                   value = var.storage_account_tfstate.exists ? (
                                                     data.azurerm_storage_account.storage_tfstate[0].id) : (
                                                     try(azurerm_storage_account.storage_tfstate[0].id, "")
                                                   )
                                                 }

output "sa_connection_string"                    {
                                                   description = "Connection string to storage account"
                                                   sensitive   = true
                                                   value = var.storage_account_tfstate.exists ? (
                                                     data.azurerm_storage_account.storage_tfstate[0].primary_connection_string) : (
                                                     try(azurerm_storage_account.storage_tfstate[0].primary_connection_string, "")
                                                   )
                                                 }

output "resource_creation_counts" {
  description = "Cardinality (creation count) of core library resources for terraform test diagnostics. 1 = created (greenfield), 0 = looked up (brownfield)."
  value = {
    resource_group          = length(azurerm_resource_group.library)
    sapbits_storage_account = length(azurerm_storage_account.storage_sapbits)
    tfstate_storage_account = length(azurerm_storage_account.storage_tfstate)
  }
}

output "resource_tags" {
  description = "Tags as seen by the selected greenfield/brownfield branch, per resource"
  value = {
    resource_group = var.infrastructure.resource_group.exists ? (
      try(data.azurerm_resource_group.library[0].tags, {})) : (
      try(azurerm_resource_group.library[0].tags, {})
    )
    sapbits_storage_account = var.storage_account_sapbits.exists ? (
      try(data.azurerm_storage_account.storage_sapbits[0].tags, {})) : (
      try(azurerm_storage_account.storage_sapbits[0].tags, {})
    )
    tfstate_storage_account = var.storage_account_tfstate.exists ? (
      try(data.azurerm_storage_account.storage_tfstate[0].tags, {})) : (
      try(azurerm_storage_account.storage_tfstate[0].tags, {})
    )
  }
}

output "dns_zone_counts" {
  description = "Cardinality of Private Link DNS zones (created vs. imported) for terraform test diagnostics"
  value = {
    blob_created   = length(azurerm_private_dns_zone.blob)
    blob_imported  = length(data.azurerm_private_dns_zone.storage)
    vault_imported = length(data.azurerm_private_dns_zone.vault)
  }
}

output "private_endpoint_counts" {
  description = "Cardinality of private endpoints created for storage accounts, for terraform test diagnostics"
  value = {
    storage_tfstate = length(azurerm_private_endpoint.storage_tfstate)
    storage_sapbits = length(azurerm_private_endpoint.storage_sapbits)
    table_tfstate   = length(azurerm_private_endpoint.table_tfstate)
  }
}

output "dns_link_counts" {
  description = "Cardinality of Private Link DNS zone virtual-network links for terraform test diagnostics"
  value = {
    vault_additional     = length(azurerm_private_dns_zone_virtual_network_link.vault_additional)
    blob_agent           = length(azurerm_private_dns_zone_virtual_network_link.blob_agent)
    appconfig_management = length(azurerm_private_dns_zone_virtual_network_link.vnet_mgmt_appconfig)
    appconfig_additional = length(azurerm_private_dns_zone_virtual_network_link.appconfig_additional)
    appconfig_agent      = length(azurerm_private_dns_zone_virtual_network_link.appconfig_agent)
  }
}
