output "anydb_vms" {
  value = local.enable_deployment ? (
    coalesce(azurerm_linux_virtual_machine.dbserver[*].id,
      azurerm_windows_virtual_machine.dbserver[*].id
    )
    ) : (
    [""]
  )
}
output "nics_anydb" {
  value = local.enable_deployment ? azurerm_network_interface.anydb_db : []
}

output "nics_anydb_admin" {
  value = local.enable_deployment ? azurerm_network_interface.anydb_admin : []
}

output "anydb_admin_ip" {
  value = local.enable_deployment ? (
    local.anydb_dual_nics ? (
      azurerm_network_interface.anydb_admin[*].private_ip_address) : (
    azurerm_network_interface.anydb_db[*].private_ip_address)
  ) : []
}

output "db_server_ips" {
  value = local.enable_deployment ? azurerm_network_interface.anydb_db[*].private_ip_addresses[0] : []
}

output "db_server_secondary_ips" {
  value = local.enable_deployment && var.use_secondary_ips ? azurerm_network_interface.anydb_db[*].private_ip_addresses[1] : []
}

output "db_lb_ip" {
  value = [
    local.enable_db_lb_deployment && (var.use_loadbalancers_for_standalone_deployments || local.anydb_ha) ? (
      try(azurerm_lb.anydb[0].frontend_ip_configuration[0].private_ip_address, "")) : (
      ""
    )
  ]
}

output "db_lb_id" {
  value = [
    local.enable_db_lb_deployment && (var.use_loadbalancers_for_standalone_deployments || local.anydb_ha) ? (
      try(azurerm_lb.anydb[0].id, "")) : (
      ""
    )
  ]
}

output "anydb_loadbalancers" {
  value = azurerm_lb.anydb
}

// Output for DNS
output "dns_info_vms" {
  value = local.enable_deployment ? (
    zipmap(
      concat(
        (
          local.anydb_dual_nics ? slice(var.naming.virtualmachine_names.ANYDB_VMNAME, 0, var.database_server_count) : [""]
        ),
        (
          slice(var.naming.virtualmachine_names.ANYDB_SECONDARY_DNSNAME, 0, var.database_server_count)
        )
      ),
      concat(
        (
          local.anydb_dual_nics ? slice(azurerm_network_interface.anydb_admin[*].private_ip_address, 0, var.database_server_count) : [""]
        ),
        (
          slice(azurerm_network_interface.anydb_db[*].private_ip_address, 0, var.database_server_count)
        )
    ))) : (
    null
  )
}

output "dns_info_loadbalancers" {
  value = local.enable_db_lb_deployment ? (
    zipmap([format("%s%s%s%s",
      var.naming.resource_prefixes.db_alb,
      local.prefix,
      var.naming.separator,
      local.resource_suffixes.db_alb
    )], [azurerm_lb.anydb[0].private_ip_addresses[0]])) : (
    null
  )
}

output "anydb_vm_ids" {
  value = local.enable_deployment ? concat(
    azurerm_windows_virtual_machine.dbserver[*].id,
    azurerm_linux_virtual_machine.dbserver[*].id
  ) : []
}

output "dbtier_disks" {
  value = local.enable_deployment ? local.db_disks_ansible : []
}

output "db_ha" {
  value = local.anydb_ha
}

output "observer_ips" {
  value = local.enable_deployment && local.deploy_observer ? (
    azurerm_network_interface.observer[*].private_ip_address) : (
    []
  )
}

output "observer_vms" {
  value = local.enable_deployment ? (
    coalesce(
      azurerm_linux_virtual_machine.observer[*].id,
      azurerm_windows_virtual_machine.observer[*].id
    )) : (
    [""]
  )
}

