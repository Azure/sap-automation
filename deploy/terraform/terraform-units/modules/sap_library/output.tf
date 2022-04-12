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
  value = local.rg_name
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
  value = local.rg_name
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
  value = local.sa_tfstate_exists ? data.azurerm_storage_account.storage_tfstate[0].id : azurerm_storage_account.storage_tfstate[0].id
}

