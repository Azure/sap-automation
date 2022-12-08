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



###############################################################################
#                                                                             #
#                            Network                                          #
#                                                                             #
###############################################################################

output "vnet_sap_id" {
  description = "Azure resource identifier for the Virtual Network"
  value       = try(local.vnet_sap_exists ? data.azurerm_virtual_network.vnet_sap[0].id : azurerm_virtual_network.vnet_sap[0].id, "")
}

output "random_id" {
  value = random_id.random_id.hex
}

output "route_table_id" {
  description = "Azure resource identifier for the route table"
  value       = local.vnet_sap_exists ? "" : try(azurerm_route_table.rt[0].id, "")
}

output "admin_subnet_id" {
  description = "Azure resource identifier for the admin subnet"
  value = local.admin_subnet_defined ? (
    local.admin_subnet_existing ? local.admin_subnet_arm_id : try(azurerm_subnet.admin[0].id, "")) : (
    ""
  )
}

output "app_subnet_id" {
  description = "Azure resource identifier for the app subnet"
  value = local.application_subnet_defined ? (
    local.application_subnet_existing ? local.application_subnet_arm_id : try(azurerm_subnet.app[0].id, "")) : (
    ""
  )
}

output "db_subnet_id" {
  description = "Azure resource identifier for the db subnet"
  value = local.database_subnet_defined ? (
    local.database_subnet_existing ? local.database_subnet_arm_id : try(azurerm_subnet.db[0].id, "")) : (
    ""
  )
}

output "web_subnet_id" {
  description = "Azure resource identifier for the web subnet"
  value = local.web_subnet_defined ? (
    local.web_subnet_existing ? local.web_subnet_arm_id : try(azurerm_subnet.web[0].id, "")) : (
    ""
  )
}


output "anf_subnet_id" {
  description = "Azure resource identifier for the anf subnet"
  value = var.NFS_provider == "ANF" && local.ANF_subnet_defined ? (
    local.ANF_subnet_existing ? local.ANF_subnet_arm_id : try(azurerm_subnet.anf[0].id, "")) : (
    ""
  )
}

output "admin_nsg_id" {
  description = "Azure resource identifier for the admin subnet network security group"
  value = local.admin_subnet_defined ? (
    local.admin_subnet_nsg_exists ? local.admin_subnet_nsg_arm_id : try(azurerm_network_security_group.admin[0].id, "")) : (
    ""
  )
}

output "app_nsg_id" {
  description = "Azure resource identifier for the app subnet network security group"
  value = local.application_subnet_defined ? (
    local.application_subnet_nsg_exists ? local.application_subnet_nsg_arm_id : try(azurerm_network_security_group.app[0].id, "")) : (
    ""
  )
}

output "db_nsg_id" {
  description = "Azure resource identifier for the database subnet network security group"
  value = local.database_subnet_defined ? (
    local.database_subnet_nsg_exists ? local.database_subnet_nsg_arm_id : try(azurerm_network_security_group.db[0].id, "")) : (
    ""
  )
}

output "web_nsg_id" {
  description = "Azure resource identifier for the web subnet network security group"
  value = local.web_subnet_defined ? (
    local.web_subnet_nsg_exists ? local.web_subnet_nsg_arm_id : try(azurerm_network_security_group.web[0].id, "")) : (
    ""
  )
}

output "subnet_mgmt_id" {
  value = local.deployer_subnet_management_id
}


###############################################################################
#                                                                             #
#                            Key Vault                                        #
#                                                                             #
###############################################################################

output "kv_user" {
  description = "Azure resource identifier for the user credential keyvault"
  value       = local.user_keyvault_exist ? try(data.azurerm_key_vault.kv_user[0].id, "") : try(azurerm_key_vault.kv_user[0].id, "")
}

# TODO Add this back when we separate the usage
# output "kv_prvt" {
#   value = local.automation_keyvault_exist ? data.azurerm_key_vault.kv_prvt[0].id : azurerm_key_vault.kv_prvt[0].id
# }

output "sid_public_key_secret_name" {
  value = local.sid_pk_name
}

output "sid_private_key_secret_name" {
  value = local.sid_ppk_name
}

output "sid_username_secret_name" {
  value = local.sid_username_secret_name
}
output "sid_password_secret_name" {
  value = local.sid_password_secret_name
}

output "workload_zone_prefix" {
  value = local.prefix
}


###############################################################################
#                                                                             #
#                            Storage accounts                                 #
#                                                                             #
###############################################################################

output "storageaccount_name" {
  description = "Diagnostics storage account name"
  value = length(var.diagnostics_storage_account.arm_id) > 0 ? (
    data.azurerm_storage_account.storage_bootdiag[0].name) : (
    try(azurerm_storage_account.storage_bootdiag[0].name, "")
  )
}

output "storageaccount_rg_name" {
  value = length(var.diagnostics_storage_account.arm_id) > 0 ? (
    data.azurerm_storage_account.storage_bootdiag[0].resource_group_name) : (
    try(azurerm_storage_account.storage_bootdiag[0].resource_group_name, "")
  )
}

output "storage_bootdiag_endpoint" {
  value = length(var.diagnostics_storage_account.arm_id) > 0 ? (
    data.azurerm_storage_account.storage_bootdiag[0].primary_blob_endpoint) : (
    try(azurerm_storage_account.storage_bootdiag[0].primary_blob_endpoint, "")
  )
}

//Witness Info
output "witness_storage_account" {
  value = length(var.witness_storage_account.arm_id) > 0 ? (
    split("/", var.witness_storage_account.arm_id)[8]) : (
    local.witness_storageaccount_name
  )
}

output "witness_storage_account_key" {
  sensitive = true
  value = length(var.witness_storage_account.arm_id) > 0 ? (
    data.azurerm_storage_account.witness_storage[0].primary_access_key) : (
    try(azurerm_storage_account.witness_storage[0].primary_access_key, "")
  )
}

output "transport_storage_account_id" {
  value = var.NFS_provider == "AFS" ? (
    length(var.transport_storage_account_id) > 0 ? (
      var.transport_storage_account_id) : (
      try(azurerm_storage_account.transport[0].id, "")
    )) : (
    ""
  )
}

###############################################################################
#                                                                             #
#                            DNS                                              #
#                                                                             #
###############################################################################
output "dns_info_vms" {
  value = local.iscsi_count > 0 ? (
    zipmap(local.full_iscsiserver_names, azurerm_network_interface.iscsi[*].private_ip_address)) : (
    null
  )
}

###############################################################################
#                                                                             #
#                   Azure NetApp Files output                                 #
#                                                                             #
###############################################################################

output "ANF_pool_settings" {
  value = var.ANF_settings.use ? {
    use_ANF = var.NFS_provider == "ANF"
    account_name = length(var.ANF_settings.arm_id) > 0 ? (
      data.azurerm_netapp_account.workload_netapp_account[0].name) : (
      try(azurerm_netapp_account.workload_netapp_account[0].name, "")
    )
    pool_name = length(var.ANF_settings.pool_name) == 0 ? (
      try(azurerm_netapp_pool.workload_netapp_pool[0].name, "")) : (
      var.ANF_settings.pool_name
    )

    service_level = var.ANF_settings.use_existing_pool ? (
      data.azurerm_netapp_pool.workload_netapp_pool[0].service_level
      ) : (
      try(azurerm_netapp_pool.workload_netapp_pool[0].service_level, "")
    )

    size_in_tb = var.ANF_settings.use_existing_pool ? (
      data.azurerm_netapp_pool.workload_netapp_pool[0].size_in_tb
      ) : (
      try(azurerm_netapp_pool.workload_netapp_pool[0].size_in_tb, 0)
    )

    subnet_id = local.ANF_subnet_defined ? (
      local.ANF_subnet_existing ? local.ANF_subnet_arm_id : try(azurerm_subnet.anf[0].id, "")) : (
      ""
    )

    resource_group_name = var.ANF_settings.use_existing_pool ? (
      split("/", var.ANF_settings.arm_id)[4]) : (
      azurerm_resource_group.resource_group[0].name
    )
    location = local.resource_group_exists ? (
      data.azurerm_resource_group.resource_group[0].location) : (
      azurerm_resource_group.resource_group[0].location
    )
    } : {
    use_ANF = false
  }
}

###############################################################################
#                                                                             #
#                       Mount info                                            #
#                                                                             #
###############################################################################

output "saptransport_path" {
  value = try(var.NFS_provider == "AFS" ? (
    format("%s:/%s/%s",
      length(var.transport_private_endpoint_id) == 0 ? (
        try(azurerm_private_endpoint.transport[0].custom_dns_configs[0].fqdn,
          azurerm_private_endpoint.transport[0].private_service_connection[0].private_ip_address
        )) : (
        data.azurerm_private_endpoint_connection.transport[0].private_service_connection[0].private_ip_address

      ),
      length(var.transport_storage_account_id) == 0 ? (
        azurerm_storage_account.transport[0].name) : (
        split("/", var.transport_storage_account_id)[8]
      ),
      try(azurerm_storage_share.transport[0].name, "")
    )
    ) : (
    var.NFS_provider == "ANF" ? (
      format("%s:/%s",
        var.ANF_settings.use_existing_transport_volume ? (
          data.azurerm_netapp_volume.transport[0].mount_ip_addresses[0]
          ) : (
          azurerm_netapp_volume.transport[0].mount_ip_addresses[0]
        ),
        var.ANF_settings.use_existing_transport_volume ? (
          data.azurerm_netapp_volume.transport[0].volume_path
          ) : (
          azurerm_netapp_volume.transport[0].volume_path
        )
      )
      ) : (
      ""
    )
  ), "")
}

output "install_path" {
  value = try(var.NFS_provider == "AFS" ? (
    format("%s:/%s/%s",
      length(var.install_private_endpoint_id) == 0 ? (
        try(azurerm_private_endpoint.install[0].custom_dns_configs[0].fqdn,
          azurerm_private_endpoint.install[0].private_service_connection[0].private_ip_address
        )) : (
        data.azurerm_private_endpoint_connection.install[0].private_service_connection[0].private_ip_address
      ),
      length(var.install_storage_account_id) == 0 ? (
        azurerm_storage_account.install[0].name) : (
        split("/", var.install_storage_account_id)[8]
      ),
      try(azurerm_storage_share.install[0].name, "")
    )
    ) : (
    var.NFS_provider == "ANF" ? (
      format("%s:/%s",
        var.ANF_settings.use_existing_install_volume ? (
          data.azurerm_netapp_volume.install[0].mount_ip_addresses[0]) : (
          azurerm_netapp_volume.install[0].mount_ip_addresses[0]
        ),
        var.ANF_settings.use_existing_install_volume ? (
          data.azurerm_netapp_volume.install[0].volume_path) : (
          azurerm_netapp_volume.install[0].volume_path
        )
      )
      ) : (
      ""
    )
  ), "")
}

###############################################################################
#                                                                             #
#                            iSCSI                                            #
#                                                                             #
###############################################################################

output "iscsi_authentication_type" {
  description = "Authentication type for iSCSI device"
  value       = local.iscsi_auth_type
}
output "iscsi_authentication_username" {
  description = "Username for iSCSI device"
  value       = local.iscsi_auth_username
}

output "nics_iscsi" {
  value = local.iscsi_count > 0 ? (
    azurerm_network_interface.iscsi[*]) : (
    []
  )
}

