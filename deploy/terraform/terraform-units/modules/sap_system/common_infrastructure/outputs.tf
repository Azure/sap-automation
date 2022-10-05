###############################################################################
#                                                                             # 
#                             Resource Group                                  # 
#                                                                             # 
###############################################################################

output "created_resource_group_id" {
  description = "Created resource group ID"
  value = local.resource_group_exists ? (
    data.azurerm_resource_group.resource_group[0].id) : (
    azurerm_resource_group.resource_group[0].id
  )
}

output "created_resource_group_name" {
  description = "Created resource group name"
  value = local.resource_group_exists ? (
    data.azurerm_resource_group.resource_group[0].name) : (
    azurerm_resource_group.resource_group[0].name
  )
}

output "created_resource_group_subscription_id" {
  description = "Created resource group' subscription ID"
  value = local.resource_group_exists ? (
    split("/", data.azurerm_resource_group.resource_group[0].id))[2] : (
    split("/", azurerm_resource_group.resource_group[0].id)[2]
  )
}

output "resource_group" {
  value = local.resource_group_exists ? data.azurerm_resource_group.resource_group : azurerm_resource_group.resource_group
}

###############################################################################
#                                                                             # 
#                             Storage accounts                                # 
#                                                                             # 
###############################################################################

output "storage_bootdiag_endpoint" {
  value = data.azurerm_storage_account.storage_bootdiag.primary_blob_endpoint
}

###############################################################################
#                                                                             # 
#                             Miscallaneous                                   # 
#                                                                             # 
###############################################################################

output "random_id" {
  value = random_id.random_id.hex
}

output "ppg" {
  value = local.ppg_exists ? data.azurerm_proximity_placement_group.ppg : azurerm_proximity_placement_group.ppg
}


###############################################################################
#                                                                             # 
#                            Network                                          # 
#                                                                             # 
###############################################################################

output "network_location" {
  value = data.azurerm_virtual_network.vnet_sap.location
}

output "network_resource_group" {
  value = try(split("/", var.landscape_tfstate.vnet_sap_arm_id)[4], "")
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

output "storage_subnet" {
  value = local.enable_db_deployment && local.enable_storage_subnet ? (
    local.sub_storage_exists ? (
      data.azurerm_subnet.storage[0]) : (
      azurerm_subnet.storage[0]
    )) : (
    null
  )
}

output "route_table_id" {
  description = "Azure resource ID of the route table"
  value       = try(var.landscape_tfstate.route_table_id, "")
}

output "firewall_id" {
  description = "Azure resource ID of the firewall"
  value       = try(var.deployer_tfstate.firewall_id, "")
}

###############################################################################
#                                                                             # 
#                            Key Vault                                        # 
#                                                                             # 
###############################################################################

output "sid_keyvault_user_id" {
  description = "User credentials keyvault"
  value = local.enable_sid_deployment && local.use_local_credentials ? (
    azurerm_key_vault.sid_keyvault_user[0].id) : (
  local.user_key_vault_id)
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

output "db_asg_id" {
  value = var.deploy_application_security_groups ? azurerm_application_security_group.db[0].id : ""
}

output "use_local_credentials" {
  value = local.use_local_credentials
}

output "cloudinit_growpart_config" {
  value = local.cloudinit_growpart_config
}


###############################################################################
#                                                                             # 
#                       Mount info                                            # 
#                                                                             # 
###############################################################################

output "sapmnt_path" {
  description = "Defines the sapmnt mount path"
  value = var.NFS_provider == "AFS" ? (
    format("%s:/%s/%s",

      length(var.sapmnt_private_endpoint_id) == 0 ? (
        try(azurerm_private_endpoint.sapmnt[0].custom_dns_configs[0].fqdn,
          azurerm_private_endpoint.sapmnt[0].private_service_connection[0].private_ip_address
        )) : (
        data.azurerm_private_endpoint_connection.sapmnt[0].private_service_connection[0].private_ip_address
      ),
      length(var.azure_files_sapmnt_id) > 0 ? (
        split("/", var.azure_files_sapmnt_id)[8]
        ) : (
        azurerm_storage_account.sapmnt[0].name
      ),
      azurerm_storage_share.sapmnt[0].name
    )
    ) : (
    var.NFS_provider == "ANF" ? (
      format("%s:/%s",
        var.hana_ANF_volumes.use_existing_sapmnt_volume ? (
          data.azurerm_netapp_volume.sapmnt[0].mount_ip_addresses[0]) : (
          azurerm_netapp_volume.sapmnt[0].mount_ip_addresses[0]
        ),
        var.hana_ANF_volumes.use_existing_sapmnt_volume ? (
          data.azurerm_netapp_volume.sapmnt[0].volume_path) : (
          azurerm_netapp_volume.sapmnt[0].volume_path
        )
      )
      ) : (
      ""
    )
  )
}

output "usrsap_path" {
  description = "Defines the /usr/sap mount path (if used)"
  value = var.NFS_provider == "ANF" && var.hana_ANF_volumes.use_for_usr_sap ? (
    format("%s:/%s",
      var.hana_ANF_volumes.use_existing_usr_sap_volume ? (
        data.azurerm_netapp_volume.usrsap[0].mount_ip_addresses[0]) : (
        azurerm_netapp_volume.usrsap[0].mount_ip_addresses[0]
      ),
      var.hana_ANF_volumes.use_existing_usr_sap_volume ? (
        data.azurerm_netapp_volume.usrsap[0].volume_path) : (
        azurerm_netapp_volume.usrsap[0].volume_path
      )
    )
    ) : (
    ""
  )

}


###############################################################################
#                                                                             # 
#                       Anchor VM                                             # 
#                                                                             # 
###############################################################################


output "anchor_vm" {
  value = local.deploy_anchor ? (
    local.anchor_ostype == "LINUX" ? (azurerm_linux_virtual_machine.anchor[0].id) : (azurerm_windows_virtual_machine.anchor[0].id)) : (
    ""
  )
}
