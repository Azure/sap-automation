locals {
  base_app_data_disk_per_node          = (local.application_server_count > 0) ? flatten(
                                           [
                                             for storage_type in local.app_sizing.storage : [
                                               for idx, disk_count in range(storage_type.count) : {
                                                 suffix               = format("-%s%02d", storage_type.name, disk_count + var.options.resource_offset)
                                                 storage_account_type = storage_type.disk_type,
                                                 disk_size_gb         = storage_type.size_gb,
                                                 //The following two lines are for Ultradisks only
                                                 disk_iops_read_write      = try(storage_type.disk_iops_read_write, null)
                                                 disk_mbps_read_write      = try(storage_type.disk_mbps_read_write, null)
                                                 caching                   = storage_type.caching,
                                                 write_accelerator_enabled = storage_type.write_accelerator
                                                 type                      = storage_type.name
                                                 lun                       = try(storage_type.lun_start, 0) + idx
                                               }
                                             ]
                                             if storage_type.name != "os" && !try(storage_type.append, false)
                                           ] ) : (
                                           []
                                         )


  append_app_data_disk_per_node        = (local.application_server_count > 0) ? flatten(
                                          [
                                            for storage_type in local.app_sizing.storage : [
                                              for idx, disk_count in range(storage_type.count) : {
                                                suffix = format("-%s%02d",
                                                  storage_type.name,
                                                  storage_type.name_offset + disk_count + var.options.resource_offset
                                                )
                                                storage_account_type = storage_type.disk_type,
                                                disk_size_gb         = storage_type.size_gb,
                                                //The following two lines are for Ultradisks only
                                                disk_iops_read_write      = try(storage_type.disk_iops_read_write, null)
                                                disk_mbps_read_write      = try(storage_type.disk_mbps_read_write, null)
                                                caching                   = storage_type.caching,
                                                write_accelerator_enabled = storage_type.write_accelerator
                                                type                      = storage_type.name
                                                lun                       = storage_type.lun_start + idx
                                              }
                                            ]
                                            if storage_type.name != "os" && try(storage_type.append, false)
                                          ] ) : (
                                          []
                                         )

  app_data_disk_per_node               = distinct(
                                           concat(
                                             local.base_app_data_disk_per_node,
                                             local.append_app_data_disk_per_node
                                           )
                                         )

  app_data_disks                       = flatten(
                                           [
                                               for idx, datadisk in local.app_data_disk_per_node : [
                                                 for vm_counter in range(local.application_server_count) : {
                                                   suffix                    = datadisk.suffix
                                                   vm_index                  = vm_counter
                                                   caching                   = datadisk.caching
                                                   storage_account_type      = datadisk.storage_account_type
                                                   disk_size_gb              = datadisk.disk_size_gb
                                                   write_accelerator_enabled = datadisk.write_accelerator_enabled
                                                   disk_iops_read_write      = datadisk.disk_iops_read_write
                                                   disk_mbps_read_write      = datadisk.disk_mbps_read_write
                                                   lun                       = datadisk.lun
                                                   type                      = datadisk.type
                                                 }
                                               ]
                                            ]
                                         )

  base_scs_data_disk_per_node          = (local.enable_deployment) ? flatten(
                                         [
                                           for storage_type in local.scs_sizing.storage : [
                                             for idx, disk_count in range(storage_type.count) : {
                                               suffix               = format("-%s%02d", storage_type.name, disk_count + var.options.resource_offset)
                                               storage_account_type = storage_type.disk_type,
                                               disk_size_gb         = storage_type.size_gb,
                                               //The following two lines are for Ultradisks only
                                               disk_iops_read_write      = try(storage_type.disk_iops_read_write, null)
                                               disk_mbps_read_write      = try(storage_type.disk_mbps_read_write, null)
                                               caching                   = storage_type.caching,
                                               write_accelerator_enabled = storage_type.write_accelerator
                                               type                      = storage_type.name
                                               lun                       = try(storage_type.lun_start, 0) + idx
                                             }
                                           ]
                                           if storage_type.name != "os" && !try(storage_type.append, false)
                                         ]) : (
                                         []
                                         )

  append_scs_data_disk_per_node        = (local.enable_deployment) ? flatten(
                                             [
                                               for storage_type in local.scs_sizing.storage : [
                                                 for idx, disk_count in range(storage_type.count) : {
                                                   suffix = format("-%s%02d",
                                                     storage_type.name,
                                                     storage_type.name_offset + disk_count + var.options.resource_offset
                                                   )
                                                   storage_account_type = storage_type.disk_type,
                                                   disk_size_gb         = storage_type.size_gb,
                                                   //The following two lines are for Ultradisks only
                                                   disk_iops_read_write      = try(storage_type.disk_iops_read_write, null)
                                                   disk_mbps_read_write      = try(storage_type.disk_mbps_read_write, null)
                                                   caching                   = storage_type.caching,
                                                   write_accelerator_enabled = storage_type.write_accelerator
                                                   type                      = storage_type.name
                                                   lun                       = storage_type.lun_start + idx
                                                 }
                                               ]
                                               if storage_type.name != "os" && try(storage_type.append, false)
                                             ] ) : (
                                             []
                                           )

  scs_data_disk_per_node               = distinct(
                                           concat(
                                             local.base_scs_data_disk_per_node,
                                             local.append_scs_data_disk_per_node
                                           )
                                         )

  scs_data_disks                       = flatten(
                                           [
                                             for idx, datadisk in local.scs_data_disk_per_node : [
                                               for vm_counter in range(local.scs_server_count) : {
                                                 suffix                    = datadisk.suffix
                                                 vm_index                  = vm_counter
                                                 caching                   = datadisk.caching
                                                 storage_account_type      = datadisk.storage_account_type
                                                 disk_size_gb              = datadisk.disk_size_gb
                                                 write_accelerator_enabled = datadisk.write_accelerator_enabled
                                                 disk_iops_read_write      = datadisk.disk_iops_read_write
                                                 disk_mbps_read_write      = datadisk.disk_mbps_read_write
                                                 type                      = datadisk.type
                                                 lun                       = datadisk.lun

                                               }
                                             ]
                                           ]
                                         )

  base_web_data_disk_per_node          = (local.webdispatcher_count > 0) ? flatten(
                                         [
                                           for storage_type in local.web_sizing.storage : [
                                             for idx, disk_count in range(storage_type.count) : {
                                               suffix               = format("-%s%02d", storage_type.name, disk_count + var.options.resource_offset)
                                               storage_account_type = storage_type.disk_type,
                                               disk_size_gb         = storage_type.size_gb,
                                               //The following two lines are for Ultradisks only
                                               disk_iops_read_write      = try(storage_type.disk_iops_read_write, null)
                                               disk_mbps_read_write      = try(storage_type.disk_mbps_read_write, null)
                                               caching                   = storage_type.caching,
                                               write_accelerator_enabled = storage_type.write_accelerator
                                               type                      = storage_type.name
                                               lun                       = try(storage_type.lun_start, 0) + idx

                                             }
                                           ]
                                           if storage_type.name != "os" && !try(storage_type.append, false)
                                         ] ) : (
                                         []
                                       )

  append_web_data_disk_per_node        = (local.webdispatcher_count > 0) ? flatten(
                                          [
                                            for storage_type in local.web_sizing.storage : [
                                              for idx, disk_count in range(storage_type.count) : {
                                                suffix = format("-%s%02d",
                                                  storage_type.name,
                                                  storage_type.name_offset + disk_count + var.options.resource_offset
                                                )
                                                storage_account_type = storage_type.disk_type,
                                                disk_size_gb         = storage_type.size_gb,
                                                //The following two lines are for Ultradisks only
                                                disk_iops_read_write      = try(storage_type.disk_iops_read_write, null)
                                                disk_mbps_read_write      = try(storage_type.disk_mbps_read_write, null)
                                                caching                   = storage_type.caching,
                                                write_accelerator_enabled = storage_type.write_accelerator
                                                type                      = storage_type.name
                                                lun                       = storage_type.lun_start + idx
                                              }
                                            ]
                                            if storage_type.name != "os" && try(storage_type.append, false)
                                          ] ) : (
                                          []
                                        )

  web_data_disk_per_node               = distinct(
                                           concat(
                                              local.base_web_data_disk_per_node,
                                              local.append_web_data_disk_per_node
                                           )
                                         )

  web_data_disks                       = flatten(
                                           [
                                             for idx, datadisk in local.web_data_disk_per_node : [
                                               for vm_counter in range(local.webdispatcher_count) : {
                                                 suffix                    = datadisk.suffix
                                                 vm_index                  = vm_counter
                                                 caching                   = datadisk.caching
                                                 storage_account_type      = datadisk.storage_account_type
                                                 disk_size_gb              = datadisk.disk_size_gb
                                                 write_accelerator_enabled = datadisk.write_accelerator_enabled
                                                 disk_iops_read_write      = datadisk.disk_iops_read_write
                                                 disk_mbps_read_write      = datadisk.disk_mbps_read_write
                                                 lun                       = datadisk.lun
                                                 type                      = datadisk.type
                                               }
                                             ]
                                           ]
                                         )

  full_appserver_names                 = distinct(flatten([for vm in var.naming.virtualmachine_names.APP_VMNAME :
                                           format("%s%s%s%s", local.prefix, var.naming.separator, vm, local.resource_suffixes.vm)]
                                         ))

  full_scsserver_names                 = distinct(flatten([for vm in var.naming.virtualmachine_names.SCS_VMNAME :
                                           format("%s%s%s%s", local.prefix, var.naming.separator, vm, local.resource_suffixes.vm)]
                                         ))

  full_webserver_names                 = distinct(flatten([for vm in var.naming.virtualmachine_names.WEB_VMNAME :
                                           format("%s%s%s%s", local.prefix, var.naming.separator, vm, local.resource_suffixes.vm)]
                                         ))

  //Disks for Ansible
  // host: xxx, LUN: #, type: sapusr, size: #

  app_disks_ansible                    = distinct(flatten([for vm in var.naming.virtualmachine_names.APP_COMPUTERNAME : [
                                           for idx, datadisk in local.app_data_disk_per_node :
                                           format("{ host: '%s', LUN: %d, type: '%s' }", vm, datadisk.lun, datadisk.type)
                                         ]]))

  scs_disks_ansible                    = distinct(flatten([for vm in var.naming.virtualmachine_names.SCS_COMPUTERNAME : [
                                           for idx, datadisk in local.scs_data_disk_per_node :
                                           format("{ host: '%s', LUN: %d, type: '%s' }", vm, datadisk.lun, datadisk.type)
                                         ]]))

  web_disks_ansible                    = distinct(flatten([for vm in var.naming.virtualmachine_names.WEB_COMPUTERNAME : [
                                           for idx, datadisk in local.web_data_disk_per_node :
                                           format("{ host: '%s', LUN: %d, type: '%s' }", vm, datadisk.lun, datadisk.type)
                                         ]]))

}
