output "hdb_vms" {
  sensitive = false
  value     = local.enable_deployment ? azurerm_linux_virtual_machine.vm_dbnode[*].id : [""]
}

output "nics_dbnodes_admin" {
  value = local.enable_deployment && var.database_dual_nics ? azurerm_network_interface.nics_dbnodes_admin : []
}

output "nics_dbnodes_db" {
  value = local.enable_deployment ? azurerm_network_interface.nics_dbnodes_db : []
}

output "loadbalancers" {
  value = local.enable_db_lb_deployment && (var.use_loadbalancers_for_standalone_deployments || local.hdb_ha) ? azurerm_lb.hdb : null
}

output "hdb_sid" {
  sensitive = false
  value     = local.hdb_sid
}

// Output for DNS
output "dns_info_vms" {
  value = local.enable_deployment ? (
    var.database_dual_nics ? (
      zipmap(
        compact(
          concat(
            slice(var.naming.virtualmachine_names.HANA_VMNAME, 0, var.database_server_count),
            slice(var.naming.virtualmachine_names.HANA_SECONDARY_DNSNAME, 0, var.database_server_count)
          )
        ),
        compact(
          concat(
            slice(azurerm_network_interface.nics_dbnodes_admin[*].private_ip_address, 0, var.database_server_count),
            slice(azurerm_network_interface.nics_dbnodes_db[*].private_ip_address, 0, var.database_server_count)
          )
        )
      )
      ) : (
      zipmap(
        compact(
          concat(
            slice(var.naming.virtualmachine_names.HANA_VMNAME, 0, var.database_server_count)
          )
        ),
        compact(
          concat(
            slice(azurerm_network_interface.nics_dbnodes_db[*].private_ip_address, 0, var.database_server_count)
          )
        )
      )
    )
    ) : (
    null
  )
}

output "dns_info_loadbalancers" {
  value = local.enable_db_lb_deployment ? (
    zipmap([
      format("%s%s%s%s",
        var.naming.resource_prefixes.db_alb,
        local.prefix,
        var.naming.separator,
      local.resource_suffixes.db_alb)
      ], [
      azurerm_lb.hdb[0].private_ip_addresses[0]
    ])) : (
    null
  )
}

output "hanadb_vm_ids" {
  value = local.enable_deployment ? azurerm_linux_virtual_machine.vm_dbnode[*].id : []
}


output "dbtier_disks" {
  value = local.enable_deployment ? local.db_disks_ansible : []
}

output "db_ha" {
  value = local.hdb_ha
}

output "db_lb_ip" {
  value = [
    local.enable_db_lb_deployment ? (
      azurerm_lb.hdb[0].frontend_ip_configuration[0].private_ip_address) : (
      ""
    )
  ]
}

output "db_lb_id" {
  value = [
    local.enable_db_lb_deployment ? (
      azurerm_lb.hdb[0].id) : (
      ""
    )
  ]
}

output "db_admin_ip" {
  value = local.enable_deployment && var.database_dual_nics ? (
    azurerm_network_interface.nics_dbnodes_admin[*].private_ip_address) : (
    []
  )
}

output "db_ip" {
  value = local.enable_deployment ? azurerm_network_interface.nics_dbnodes_db[*].private_ip_address : []
}

output "hana_data_primary" {
  value = var.hana_ANF_volumes.use_for_data ? (
    format("%s:/%s",
      var.hana_ANF_volumes.use_existing_data_volume ? (
        data.azurerm_netapp_volume.hanadata[0].mount_ip_addresses[0]) : (
        azurerm_netapp_volume.hanadata[0].mount_ip_addresses[0]
      ),
      var.hana_ANF_volumes.use_existing_data_volume ? (
        data.azurerm_netapp_volume.hanadata[0].volume_path) : (
        azurerm_netapp_volume.hanadata[0].volume_path
      )
    )
    ) : (
    ""
  )
}

output "hana_data_secondary" {
  value = var.hana_ANF_volumes.use_for_data && local.hdb_ha ? (
    format("%s:/%s",
      var.hana_ANF_volumes.use_existing_data_volume ? (
        data.azurerm_netapp_volume.hanadata[1].mount_ip_addresses[0]) : (
        azurerm_netapp_volume.hanadata[1].mount_ip_addresses[0]
      ),
      var.hana_ANF_volumes.use_existing_data_volume ? (
        data.azurerm_netapp_volume.hanadata[1].volume_path) : (
        azurerm_netapp_volume.hanadata[1].volume_path
      )
    )
    ) : (
    ""
  )
}

# output "hana_data" {
#   value = var.hana_ANF_volumes.use_for_data ? (
#     local.hdb_ha ? (
#       [format("%s:/%s",
#         var.hana_ANF_volumes.use_existing_data_volume ? (
#           data.azurerm_netapp_volume.hanadata[0].mount_ip_addresses[0]) : (
#           azurerm_netapp_volume.hanadata[0].mount_ip_addresses[0]
#         ),
#         var.hana_ANF_volumes.use_existing_data_volume ? (
#           data.azurerm_netapp_volume.hanadata[0].volume_path) : (
#           azurerm_netapp_volume.hanadata[0].volume_path
#         )
#         ), format("%s:/%s",
#         var.hana_ANF_volumes.use_existing_data_volume ? (
#           data.azurerm_netapp_volume.hanadata[1].mount_ip_addresses[1]) : (
#           azurerm_netapp_volume.hanadata[1].mount_ip_addresses[1]
#         ),
#         var.hana_ANF_volumes.use_existing_data_volume ? (
#           data.azurerm_netapp_volume.hanadata[1].volume_path) : (
#           azurerm_netapp_volume.hanadata[1].volume_path
#         )
#       )]
#       ) : (
#       [format("%s:/%s",
#         var.hana_ANF_volumes.use_existing_data_volume ? (
#           data.azurerm_netapp_volume.hanadata[0].mount_ip_addresses[0]) : (
#           azurerm_netapp_volume.hanadata[0].mount_ip_addresses[0]
#         ),
#         var.hana_ANF_volumes.use_existing_data_volume ? (
#           data.azurerm_netapp_volume.hanadata[0].volume_path) : (
#           azurerm_netapp_volume.hanadata[0].volume_path
#         )
#       )]
#     )
#     ) : (
#   [""])
# }
output "hana_log_primary" {
  value = var.hana_ANF_volumes.use_for_log ? (
    format("%s:/%s",
      var.hana_ANF_volumes.use_existing_log_volume ? (
        data.azurerm_netapp_volume.hanalog[0].mount_ip_addresses[0]) : (
        azurerm_netapp_volume.hanalog[0].mount_ip_addresses[0]
      ),
      var.hana_ANF_volumes.use_existing_log_volume ? (
        data.azurerm_netapp_volume.hanalog[0].volume_path) : (
        azurerm_netapp_volume.hanalog[0].volume_path
      )
    )
    ) : (
    ""
  )
}

output "hana_log_secondary" {
  value = var.hana_ANF_volumes.use_for_log && local.hdb_ha ? (
    format("%s:/%s",
      var.hana_ANF_volumes.use_existing_log_volume ? (
        data.azurerm_netapp_volume.hanalog[1].mount_ip_addresses[0]) : (
        azurerm_netapp_volume.hanalog[1].mount_ip_addresses[0]
      ),
      var.hana_ANF_volumes.use_existing_log_volume ? (
        data.azurerm_netapp_volume.hanalog[1].volume_path) : (
        azurerm_netapp_volume.hanalog[1].volume_path
      )
    )
    ) : (
    ""
  )
}

output "hana_shared_primary" {
  value = var.hana_ANF_volumes.use_for_shared ? (
    format("%s:/%s",
      var.hana_ANF_volumes.use_existing_shared_volume ? (
        data.azurerm_netapp_volume.hanashared[0].mount_ip_addresses[0]) : (
        azurerm_netapp_volume.hanashared[0].mount_ip_addresses[0]
      ),
      var.hana_ANF_volumes.use_existing_shared_volume ? (
        data.azurerm_netapp_volume.hanashared[0].volume_path) : (
        azurerm_netapp_volume.hanashared[0].volume_path
      )
    )
    ) : (
    ""
  )
}

output "hana_shared_secondary" {
  value = var.hana_ANF_volumes.use_for_shared && local.hdb_ha ? (
    format("%s:/%s",
      var.hana_ANF_volumes.use_existing_shared_volume ? (
        data.azurerm_netapp_volume.hanashared[1].mount_ip_addresses[0]) : (
        azurerm_netapp_volume.hanashared[1].mount_ip_addresses[0]
      ),
      var.hana_ANF_volumes.use_existing_shared_volume ? (
        data.azurerm_netapp_volume.hanashared[1].volume_path) : (
        azurerm_netapp_volume.hanashared[1].volume_path
      )
    )
    ) : (
    ""
  )
}
