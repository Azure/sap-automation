
###############################################################################
#                                                                             # 
#                             Resource Group                                  # 
#                                                                             # 
###############################################################################

output "created_resource_group_id" {
  description = "Created resource group ID"
  value = local.resource_group_exists ? data.azurerm_resource_group.library[0].id : azurerm_resource_group.library[0].id
}

output "created_resource_group_subscription_id" {
  description = "Created resource group' subscription ID"
  value = local.resource_group_exists ? (
    split("/",data.azurerm_resource_group.library[0].id))[2] : (
    split("/",azurerm_resource_group.library[0].id)[2]
  )
}

output "created_resource_group_name" {
  description = "Created resource group name"
  value = local.resource_group_exists ? (
    data.azurerm_resource_group.library[0].name) : (
    azurerm_resource_group.library[0].name
  )
}

output "tfstate_storage_account" {
  value = local.sa_tfstate_exists ? (
    split("/", local.sa_tfstate_arm_id)[8]) : (
    length(var.storage_account_tfstate.name) > 0 ? (
      var.storage_account_tfstate.name) : (
      var.naming.storageaccount_names.LIBRARY.terraformstate_storageaccount_name
  ))
}

output "sapbits_storage_account_name" {
  value = local.sa_sapbits_exists ? (
    split("/", var.storage_account_sapbits.arm_id)[8]) : (
    length(var.storage_account_sapbits.name) > 0 ? (
      var.storage_account_sapbits.name) : (
      var.naming.storageaccount_names.LIBRARY.library_storageaccount_name
  ))

}

output "sapbits_sa_resource_group_name" {
  value = local.resource_group_name
}

output "storagecontainer_tfstate" {
  value = var.storage_account_tfstate.tfstate_blob_container.name
}

output "storagecontainer_sapbits_name" {
  value = var.storage_account_sapbits.file_share.name
}

output "random_id" {
  value = random_id.post_fix.hex
}

output "remote_state_resource_group_name" {
  value = local.resource_group_name
}

output "remote_state_storage_account_name" {
  value = local.sa_tfstate_exists ? (
    split("/", local.sa_tfstate_arm_id)[8]) : (
    length(var.storage_account_tfstate.name) > 0 ? (
      var.storage_account_tfstate.name) : (
      var.naming.storageaccount_names.LIBRARY.terraformstate_storageaccount_name
  ))
}


output "tfstate_resource_id" {
  value = local.sa_tfstate_exists ? (
    data.azurerm_storage_account.storage_tfstate[0].id) : (
    azurerm_storage_account.storage_tfstate[0].id
  )
}

output "cmdb_connection_string" {
  sensitive = true
  value = var.use_webapp ? azurerm_cosmosdb_account.cmdb[0].connection_strings[0] : ""
}
