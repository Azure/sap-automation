# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

#######################################4#######################################8
#                                                                              #
#                               AnyDB definitions                              #
#                                                                              #
#######################################4#######################################8

output "database_cluster_ip"           {
                                         description = "AnyDB load balancer cluster IPs"
                                         value       = var.database.high_availability && local.windows_high_availability ? (
                                                         try(azurerm_lb.anydb[0].frontend_ip_configuration[1].private_ip_address, "")) : (
                                                         ""
                                                       )
                                       }
output "database_loadbalancer_id"                      {
                                         description = "AnyDB load balancer Id"
                                         value       = [
                                                         local.enable_db_lb_deployment && (var.use_loadbalancers_for_standalone_deployments || var.database.high_availability) ? (
                                                           try(azurerm_lb.anydb[0].id, "")) : (
                                                           ""
                                                         )
                                                       ]
                                       }

output "database_loadbalancer_ip"      {
                                         description = "AnyDB load balancer IPs"
                                         value       = [
                                                         local.enable_db_lb_deployment && (var.use_loadbalancers_for_standalone_deployments || var.database.high_availability) ? (
                                                           try(azurerm_lb.anydb[0].frontend_ip_configuration[0].private_ip_address, "")) : (
                                                           ""
                                                         )
                                                       ]
                                       }
output "database_server_admin_ips"     {
                                         description = "AnyDB Virtual machine Admin interface IPs"
                                         value       = local.enable_deployment ? (
                                                         local.anydb_dual_nics ? (
                                                           azurerm_network_interface.anydb_admin[*].private_ip_address) : (
                                                         azurerm_network_interface.anydb_db[*].private_ip_address)
                                                       ) : []
                                       }

output "database_server_ips"           {
                                         description = "AnyDB Virtual machine db interface IPs"
                                         value       = local.enable_deployment ? azurerm_network_interface.anydb_db[*].private_ip_addresses[0] : []
                                       }

output "database_server_secondary_ips" {
                                         description = "AnyDB Virtual machine db interface IPs"
                                         value       = local.enable_deployment && var.use_secondary_ips ? try(azurerm_network_interface.anydb_db[*].private_ip_addresses[1], []) : []
                                       }

output "database_server_vm_ids"        {
                                         description = "AnyDB Virtual machine resource IDs"
                                         value       = local.enable_deployment ? (
                                                      coalesce(azurerm_linux_virtual_machine.dbserver[*].id,
                                                        azurerm_windows_virtual_machine.dbserver[*].id
                                                      )
                                                      ) : (
                                                      [""]
                                                     )
                                       }

output "database_server_vm_names"      {
                                         description = "AnyDB Virtual machine names"
                                         value       = local.enable_deployment ? (
                                                      compact(concat(azurerm_linux_virtual_machine.dbserver[*].name,
                                                        azurerm_windows_virtual_machine.dbserver[*].name
                                                      ))
                                                      ) : (
                                                      [""]
                                                     )
                                       }


output "database_disks"                {
                                         description = "AnyDB Virtual machine disks"
                                         value       = local.enable_deployment ? local.db_disks_ansible : []
                                       }

#######################################4#######################################8
#                                                                              #
#                                         DNS                                  #
#                                                                              #
#######################################4#######################################8
output "dns_info_vms"                  {
                                         description = "DNS Information for the virtual machines"
                                         value       = local.enable_deployment ? (
                                                         local.anydb_dual_nics ? (
                                                           zipmap(
                                                             compact(
                                                               concat(
                                                                 slice(var.naming.virtualmachine_names.ANYDB_VMNAME, 0, length(azurerm_linux_virtual_machine.dbserver) + length(azurerm_windows_virtual_machine.dbserver)),
                                                                 slice(var.naming.virtualmachine_names.ANYDB_SECONDARY_DNSNAME, 0, length(azurerm_linux_virtual_machine.dbserver) + length(azurerm_windows_virtual_machine.dbserver)),
                                                                 slice(var.naming.virtualmachine_names.OBSERVER_VMNAME, 0, length(azurerm_linux_virtual_machine.observer))
                                                               )
                                                             ),
                                                             compact(
                                                               concat(
                                                                 slice(azurerm_network_interface.anydb_admin[*].private_ip_address, 0, length(azurerm_linux_virtual_machine.dbserver) + length(azurerm_windows_virtual_machine.dbserver)),
                                                                 slice(azurerm_network_interface.anydb_db[*].private_ip_address, 0, length(azurerm_linux_virtual_machine.dbserver) + length(azurerm_windows_virtual_machine.dbserver)),
                                                                 slice(azurerm_network_interface.observer[*].private_ip_address, 0, length(azurerm_linux_virtual_machine.observer))
                                                               )
                                                             )
                                                           )
                                                           ) : (
                                                           zipmap(
                                                             compact(
                                                               concat(
                                                                 slice(var.naming.virtualmachine_names.ANYDB_VMNAME, 0, length(azurerm_linux_virtual_machine.dbserver) + length(azurerm_windows_virtual_machine.dbserver)),
                                                                 slice(var.naming.virtualmachine_names.OBSERVER_VMNAME, 0, length(azurerm_linux_virtual_machine.observer))
                                                               )
                                                             ),
                                                             compact(
                                                               concat(
                                                                 slice(azurerm_network_interface.anydb_db[*].private_ip_address, 0, length(azurerm_linux_virtual_machine.dbserver) + length(azurerm_windows_virtual_machine.dbserver)),
                                                                 slice(azurerm_network_interface.observer[*].private_ip_address, 0, length(azurerm_linux_virtual_machine.observer))
                                                               )
                                                             )
                                                           )
                                                         )
                                                         ) : (
                                                         null
                                                       )
                                       }

output "dns_info_loadbalancers"        {
                                         description = "DNS Information for the virtual machines"
                                         value       = local.enable_db_lb_deployment ? (
                                                         zipmap([format("%s%s%s%s",
                                                           var.naming.resource_prefixes.db_alb,
                                                           local.prefix,
                                                           var.naming.separator,
                                                           local.resource_suffixes.db_alb
                                                         )], [try(azurerm_lb.anydb[0].private_ip_addresses[0], "")])) : (
                                                         null
                                                       )
                                       }



output "observer_ips"                  {
                                         description = "IP adresses for observer nodes"
                                         value       = local.enable_deployment && local.deploy_observer ? (
                                                         azurerm_network_interface.observer[*].private_ip_address) : (
                                                         []
                                                       )
                                       }

output "observer_vms"                  {
                                         description = "Resource IDs for observer nodes"
                                         value       = local.enable_deployment ? (
                                                         coalesce(
                                                           azurerm_linux_virtual_machine.observer[*].id,
                                                           azurerm_windows_virtual_machine.observer[*].id
                                                         )) : (
                                                         [""]
                                                       )
                                       }

output "database_shared_disks"         {
                                         description = "List of Azure shared disks"
                                         value       = distinct(
                                                         flatten(
                                                           [for vm in var.naming.virtualmachine_names.ANYDB_VMNAME :
                                                             [for idx, disk in azurerm_virtual_machine_data_disk_attachment.cluster :
                                                               format("{ host: '%s', LUN: %d, type: 'ASD' }", vm, disk.lun)
                                                             ]
                                                           ]
                                                         )
                                                       )
                                       }
output "database_kdump_disks"          {
                                         description = "List of Azure kdump disks"
                                         value       = distinct(
                                                         flatten(
                                                           [for vm in var.naming.virtualmachine_names.ANYDB_VMNAME :
                                                             [for idx, disk in azurerm_virtual_machine_data_disk_attachment.kdump :
                                                               format("{ host: '%s', LUN: %d, type: 'kdump' }", vm, disk.lun)
                                                             ]
                                                           ]
                                                         )
                                                       )
                                       }
