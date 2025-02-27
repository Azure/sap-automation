# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

#######################################4#######################################8
#                                                                              #
#                               AnyDB definitions                              #
#                                                                              #
#######################################4#######################################8

output "loadbalancers"                 {
                                         description = "List of disks used in the application tier"
                                         value = local.enable_db_lb_deployment && (var.use_loadbalancers_for_standalone_deployments || var.database.high_availability) ? azurerm_lb.hdb : null
                                       }

output "hdb_sid"                       {
                                         description = "Database SID"
                                         value     = local.database_sid
                                       }

// Output for DNS
output "dns_info_vms"                  {
                                         description = "Database server DNS information"
                                         value       = local.enable_deployment ? (
                                                         var.database_dual_nics ? (
                                                           zipmap(
                                                             compact(
                                                               concat(
                                                                 slice(var.naming.virtualmachine_names.HANA_VMNAME, 0, length(azurerm_linux_virtual_machine.vm_dbnode)),
                                                                 slice(var.naming.virtualmachine_names.HANA_SECONDARY_DNSNAME, 0, length(azurerm_linux_virtual_machine.vm_dbnode))
                                                               )
                                                             ),
                                                             compact(
                                                               concat(
                                                                 slice(azurerm_network_interface.nics_dbnodes_admin[*].private_ip_address, 0, length(azurerm_linux_virtual_machine.vm_dbnode)),
                                                                 slice(azurerm_network_interface.nics_dbnodes_db[*].private_ip_address, 0, length(azurerm_linux_virtual_machine.vm_dbnode))
                                                               )
                                                             )
                                                           )
                                                           ) : (
                                                           zipmap(
                                                             compact(
                                                               concat(
                                                                 slice(var.naming.virtualmachine_names.HANA_VMNAME, 0, length(azurerm_linux_virtual_machine.vm_dbnode))
                                                               )
                                                             ),
                                                             compact(
                                                               concat(
                                                                 slice(azurerm_network_interface.nics_dbnodes_db[*].private_ip_address, 0, length(azurerm_linux_virtual_machine.vm_dbnode))
                                                               )
                                                             )
                                                           )
                                                         )
                                                         ) : (
                                                         null
                                                       )
                                       }

output "dns_info_loadbalancers"        {
                                         description = "Database loadbalancer DNS information"
                                         value       = local.enable_db_lb_deployment ? (
                                                        zipmap([
                                                          format("%s%s%s%s",
                                                            var.naming.resource_prefixes.db_alb,
                                                            local.prefix,
                                                            var.naming.separator,
                                                          local.resource_suffixes.db_alb)
                                                          ], [
                                                          try(azurerm_lb.hdb[0].private_ip_addresses[0], "")
                                                        ])) : (
                                                        null
                                                      )
                                       }

output "hanadb_vm_ids"                 {
                                         description = "Database loadbalancer DNS information"
                                         value       = local.enable_deployment ? azurerm_linux_virtual_machine.vm_dbnode[*].id : []
                                       }

output "database_server_vm_names"      {
                                         description = "HANA Virtual machine names"
                                         value       = local.enable_deployment ? (
                                                      azurerm_linux_virtual_machine.vm_dbnode[*].name
                                                      ) : (
                                                      [""]
                                                     )
                                       }



output "database_disks"                {
                                         description = "Disks used by the database tier"
                                         value       = local.enable_deployment ? local.db_disks_ansible : []
                                       }

output "database_loadbalancer_ip"      {
                                         description = "Database loadbalancer IP information"
                                         value       = local.enable_db_lb_deployment ? (
                                                        compact(
                                                          concat(
                                                            [
                                                              try(azurerm_lb.hdb[0].frontend_ip_configuration[0].private_ip_address, "")
                                                            ],
                                                            [
                                                              try(azurerm_lb.hdb[0].frontend_ip_configuration[1].private_ip_address, "")
                                                            ]
                                                          )
                                                        )
                                                       ) : [""]
                                       }

output "database_loadbalancer_id"      {
                                         description = "Database loadbalancer Id information"
                                         value       = [
                                                         local.enable_db_lb_deployment ? (
                                                           try(azurerm_lb.hdb[0].id, "")) : (
                                                           ""
                                                         )
                                                       ]
                                       }

output "db_admin_ip"                   {
                                         description = "Database Admin IP information"
                                         value       = local.enable_deployment && var.database_dual_nics ? (
                                                         azurerm_network_interface.nics_dbnodes_admin[*].private_ip_address) : (
                                                         []
                                                       )
                                       }

output "database_server_ips"           {
                                         description = "Database Server IP information"
                                         value       = local.enable_deployment ? azurerm_network_interface.nics_dbnodes_db[*].private_ip_addresses[0] : []
                                       }

output "database_server_secondary_ips" {
                                         description = "Database Server IP information"
                                         value       = local.enable_deployment && var.use_secondary_ips ? (
                                                         try(azurerm_network_interface.nics_dbnodes_db[*].private_ip_addresses[1], [])) : (
                                                         []
                                                       )
                                       }


output "hana_data_ANF_volumes"         {
                                         description = "HANA Data volumes"
                                         value       = local.data_volume_count > 0 ? flatten([
                                                           for idx in range(local.data_volume_count) : [
                                                           format("%s:/%s",
                                                             var.hana_ANF_volumes.use_existing_data_volume || local.use_avg ? (
                                                               data.azurerm_netapp_volume.hanadata[idx].mount_ip_addresses[0]) : (
                                                               azurerm_netapp_volume.hanadata[idx].mount_ip_addresses[0]
                                                             ),
                                                             var.hana_ANF_volumes.use_existing_data_volume || local.use_avg ? (
                                                               data.azurerm_netapp_volume.hanadata[idx].volume_path) : (
                                                               azurerm_netapp_volume.hanadata[idx].volume_path
                                                             )
                                                           )
                                                           ]
                                                           ]) : []
                                       }

output "hana_log_ANF_volumes"          {
                                         description = "HANA Log volumes"
                                         value       = local.log_volume_count > 0 ? flatten([
                                                           for idx in range(local.log_volume_count) : [
                                                           format("%s:/%s",
                                                             var.hana_ANF_volumes.use_existing_log_volume || local.use_avg ? (
                                                               data.azurerm_netapp_volume.hanalog[idx].mount_ip_addresses[0]) : (
                                                               azurerm_netapp_volume.hanalog[idx].mount_ip_addresses[0]
                                                             ),
                                                             var.hana_ANF_volumes.use_existing_log_volume || local.use_avg ? (
                                                               data.azurerm_netapp_volume.hanalog[idx].volume_path) : (
                                                               azurerm_netapp_volume.hanalog[idx].volume_path
                                                             )
                                                             )

                                                           ]
                                                         ]) : []
                                       }

# Order the list so that the zonal information is in the correct order

output "hana_shared"                   {
                                         description = "HANA Shared volumes"
                                         value       = local.shared_volume_count == 0 ? (
                                                         []
                                                         ) : ((
                                                         var.hana_ANF_volumes.use_existing_shared_volume || local.use_avg ? data.azurerm_netapp_volume.hanashared[0].zone : azurerm_netapp_volume.hanashared[0].zone)) == var.database.zones[0] ? (
                                                         [
                                                           format("%s:/%s",
                                                             var.hana_ANF_volumes.use_existing_shared_volume || local.use_avg ? (
                                                               data.azurerm_netapp_volume.hanashared[0].mount_ip_addresses[0]) : (
                                                               azurerm_netapp_volume.hanashared[0].mount_ip_addresses[0]
                                                             ),
                                                             var.hana_ANF_volumes.use_existing_shared_volume || local.use_avg ? (
                                                               data.azurerm_netapp_volume.hanashared[0].volume_path) : (
                                                               azurerm_netapp_volume.hanashared[0].volume_path
                                                             )
                                                           ),
                                                           format("%s:/%s",
                                                             var.hana_ANF_volumes.use_existing_shared_volume || local.use_avg ? (
                                                               data.azurerm_netapp_volume.hanashared[1].mount_ip_addresses[0]) : (
                                                               azurerm_netapp_volume.hanashared[1].mount_ip_addresses[0]
                                                             ),
                                                             var.hana_ANF_volumes.use_existing_shared_volume || local.use_avg ? (
                                                               data.azurerm_netapp_volume.hanashared[1].volume_path) : (
                                                               azurerm_netapp_volume.hanashared[1].volume_path
                                                             )
                                                           )
                                                         ]
                                                         ) : (
                                                         [
                                                           format("%s:/%s",
                                                             var.hana_ANF_volumes.use_existing_shared_volume || local.use_avg ? (
                                                               data.azurerm_netapp_volume.hanashared[1].mount_ip_addresses[0]) : (
                                                               azurerm_netapp_volume.hanashared[1].mount_ip_addresses[0]
                                                             ),
                                                             var.hana_ANF_volumes.use_existing_shared_volume || local.use_avg ? (
                                                               data.azurerm_netapp_volume.hanashared[1].volume_path) : (
                                                               azurerm_netapp_volume.hanashared[1].volume_path
                                                             )
                                                           ),
                                                           format("%s:/%s",
                                                             var.hana_ANF_volumes.use_existing_shared_volume || local.use_avg ? (
                                                               data.azurerm_netapp_volume.hanashared[0].mount_ip_addresses[0]) : (
                                                               azurerm_netapp_volume.hanashared[0].mount_ip_addresses[0]
                                                             ),
                                                             var.hana_ANF_volumes.use_existing_shared_volume || local.use_avg ? (
                                                               data.azurerm_netapp_volume.hanashared[0].volume_path) : (
                                                               azurerm_netapp_volume.hanashared[0].volume_path
                                                             )
                                                           )
                                                         ]
                                                       )
                                                     }

output "application_volume_group"      {
                                         description = "Application volume group"
                                         value       = azurerm_netapp_volume_group_sap_hana.avg_HANA_full
                                       }


output "database_shared_disks"         {
                                         description = "List of Azure shared disks"
                                         value       = distinct(
                                                         flatten(
                                                           [for vm in var.naming.virtualmachine_names.HANA_COMPUTERNAME :
                                                             [for idx, disk in azurerm_virtual_machine_data_disk_attachment.cluster :
                                                               format("{ host: '%s', LUN: %d, type: 'ASD' }", vm, disk.lun)
                                                             ]
                                                           ]
                                                         )
                                                       )
                                       }

output "database_kdump_disks"          {
                                         description = "List of Azure disks for kdump"
                                         value       = distinct(
                                                         flatten(
                                                           [for vm in var.naming.virtualmachine_names.HANA_COMPUTERNAME :
                                                             [for idx, disk in azurerm_virtual_machine_data_disk_attachment.kdump :
                                                               format("{ host: '%s', LUN: %d, type: 'kdump' }", vm, disk.lun)
                                                             ]
                                                           ]
                                                         )
                                                       )
                                       }


output "ANF_subnet_prefix"             {
                                             description = "ANF subnet prefix"
                                             value       = (local.enable_deployment && length(local.ANF_pool_settings.subnet_id) > 0) ? (
                                                             data.azurerm_subnet.ANF[0].address_prefixes[0] ): (
                                                             ""
                                                           )

                                           }


output "observer_ips"                  {
                                         description = "IP adresses for observer nodes"
                                         value       = local.enable_deployment && var.use_observer ? (
                                                         azurerm_network_interface.observer[*].private_ip_address) : (
                                                         []
                                                       )
                                       }

output "observer_vms"                  {
                                         description = "Resource IDs for observer nodes"
                                         value       = local.enable_deployment && var.use_observer ? (
                                                         azurerm_linux_virtual_machine.observer[*].id) : (
                                                         [""]
                                                       )
                                       }

output "site_information"              {
                                         description = "Site information"
                                         value       = local.enable_deployment ? (
                                                         local.site_information) : (
                                                         null
                                                       )
                                       }

output "hana_shared_afs_path"          {
                                          description = "Defines the hanashared mount path"
                                          value       = var.database.scale_out && var.NFS_provider == "AFS" ? compact(
                                                          [
                                                           format("%s:/%s/%s",
                                                               try(azurerm_private_endpoint.hanashared[0].private_dns_zone_configs[0].record_sets[0].fqdn,
                                                                 try(azurerm_private_endpoint.hanashared[0].private_service_connection[0].private_ip_address,"")
                                                               ),
                                                             length(try(var.hanashared_id, "")) > 0 ? (
                                                               split("/", var.hanashared_id[0])[8]
                                                               ) : (
                                                               azurerm_storage_account.hanashared[0].name
                                                             ),
                                                             azurerm_storage_share.hanashared[0].name
                                                           ),
                                                           length(var.database.zones) > 1 ?
                                                           format("%s:/%s/%s",
                                                               try(azurerm_private_endpoint.hanashared[var.use_single_hana_shared ? 0 : 1].private_dns_zone_configs[0].record_sets[0].fqdn,
                                                                 try(azurerm_private_endpoint.hanashared[var.use_single_hana_shared ? 0 : 1].private_service_connection[0].private_ip_address,"")
                                                               ),
                                                             length(try(var.hanashared_id, "")) > 0 ? (
                                                               split("/", var.hanashared_id[1])[8]
                                                               ) : (
                                                               azurerm_storage_account.hanashared[var.use_single_hana_shared ? 0 : 1].name
                                                             ),
                                                             azurerm_storage_share.hanashared[1].name
                                                           ) : ""
                                                         ]) : []
                                        }
