output "anchor_vm" {
  value = local.deploy_anchor ? (
    local.anchor_ostype == "LINUX" ? (azurerm_linux_virtual_machine.anchor[0].id) : (azurerm_windows_virtual_machine.anchor[0].id)) : (
    ""
  )
}

output "resource_group" {
  value = local.rg_exists ? data.azurerm_resource_group.resource_group : azurerm_resource_group.resource_group
}

output "storage_bootdiag_endpoint" {
  value = data.azurerm_storage_account.storage_bootdiag.primary_blob_endpoint
}

output "random_id" {
  value = random_id.random_id.hex
}

output "iscsi_private_ip" {
  value = try(var.landscape_tfstate.iscsi_private_ip, [])
}

output "ppg" {
  value = local.ppg_exists ? data.azurerm_proximity_placement_group.ppg : azurerm_proximity_placement_group.ppg
}

output "admin_subnet" {
  value = local.enable_admin_subnet ? (
    local.admin_subnet_exists ? data.azurerm_subnet.admin[0] : azurerm_subnet.admin[0]) : (
    null
  )
}

output "db_subnet" {
  value = local.enable_db_deployment ? (
    local.database_subnet_exists ? data.azurerm_subnet.db[0] : azurerm_subnet.db[0]) : (
    null
  )
  #local.database_subnet_exists ? data.azurerm_subnet.db[0] : azurerm_subnet.db[0]
}

output "network_location" {
  value = data.azurerm_virtual_network.vnet_sap.location
}

output "network_resource_group" {
  value = split("/", var.landscape_tfstate.vnet_sap_arm_id)[4]
}


output "sid_keyvault_user_id" {
  value = local.enable_sid_deployment && local.use_local_credentials ? (
    azurerm_key_vault.sid_keyvault_user[0].id) : (
  local.user_key_vault_id)
}

output "sid_kv_prvt_id" {
  value = local.enable_sid_deployment && local.use_local_credentials ? (
    azurerm_key_vault.sid_keyvault_prvt[0].id) : (
  local.prvt_key_vault_id)
}

output "storage_subnet" {
  value = local.enable_db_deployment && local.enable_storage_subnet ? (
    local.sub_storage_exists ? (
      data.azurerm_subnet.storage[0]) : (
      azurerm_subnet.storage[0]
    )) : (
    null
  )
}

output "sid_password" {
  sensitive = true
  value     = local.sid_auth_password
}

output "sid_username" {
  sensitive = true
  value     = local.sid_auth_username
}

//Output the SDU specific SSH key
output "sdu_public_key" {
  sensitive = true
  value     = local.sid_public_key
}

output "route_table_id" {
  value = var.landscape_tfstate.route_table_id
}

output "firewall_id" {
  value = try(var.deployer_tfstate.firewall_id, "")
}

output "db_asg_id" {
  value = azurerm_application_security_group.db.id
}

output "use_local_credentials" {
  value = local.use_local_credentials
}

output "cloudinit_growpart_config" {
  value = local.cloudinit_growpart_config
}

output "sapmnt_path" {
  value = var.NFS_provider == "AFS" ? (
    format("%s:/%s/%s", azurerm_private_endpoint.shared[0].private_service_connection[0].private_ip_address, azurerm_storage_account.shared[0].name, azurerm_storage_share.sapmnt[0].name)
    ) : (
    var.NFS_provider == "ANF" ? (
      format("%s:/%s", azurerm_netapp_volume.sapmnt[0].mount_ip_addresses[0], azurerm_netapp_volume.sapmnt[0].volume_path)
      ) : (
      ""
    )
  )
}

output "install_path" {
  value = var.NFS_provider == "AFS" ? try(format("%s:/%s/%s", azurerm_private_endpoint.shared[0].private_service_connection[0].private_ip_address, azurerm_storage_account.shared[0].name, azurerm_storage_share.install[0].name), "") : ""
}
