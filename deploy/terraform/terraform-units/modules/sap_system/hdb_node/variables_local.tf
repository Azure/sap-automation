
locals {
  // Resources naming
  computer_names                       = var.naming.virtualmachine_names.HANA_COMPUTERNAME
  virtualmachine_names                 = var.naming.virtualmachine_names.HANA_VMNAME

  storageaccount_names                 = var.naming.storageaccount_names.SDU
  resource_suffixes                    = var.naming.resource_suffixes

  default_filepath                     = var.database_use_premium_v2_storage ? format("%s%s", path.module, "/../../../../../configs/hana_sizes_v2.json") : format("%s%s", path.module, "/../../../../../configs/hana_sizes.json")
  custom_sizing                        = length(var.custom_disk_sizes_filename) > 0

  // Imports database sizing information
  file_name                            = local.custom_sizing ? (
                                           fileexists(var.custom_disk_sizes_filename) ? (
                                             var.custom_disk_sizes_filename) : (
                                             format("%s/%s", path.cwd, var.custom_disk_sizes_filename)
                                           )) : (
                                           local.default_filepath
                                         )

  sizes                                = jsondecode(file(local.file_name))

  faults                               = jsondecode(file(
                                           format("%s%s",
                                             path.module,
                                             "/../../../../../configs/max_fault_domain_count.json"
                                           )
                                         ))

  region                               = var.infrastructure.region
  sid                                  = upper(var.sap_sid)
  prefix                               = trimspace(var.naming.prefix.SDU)
  resource_group_exists                = length(try(var.infrastructure.resource_group.arm_id, "")) > 0
  resourcegroup_name                   = local.resource_group_exists ? (
                                          try(split("/", var.infrastructure.resource_group.arm_id)[4], "")) : (
                                          coalesce(
                                            try(var.infrastructure.resource_group.name, ""),
                                            format("%s%s%s",
                                              var.naming.resource_prefixes.sdu_rg,
                                              local.prefix,
                                              local.resource_suffixes.sdu_rg
                                            )
                                          )
                                        )

  enable_deployment                    = (var.database.platform == "HANA")


  //ANF support
  use_ANF                              = try(var.database.use_ANF, false)
  //Scalout subnet is needed if ANF is used and there are more than one hana node
  dbnode_per_site                      = length(try(var.database.dbnodes, [{}]))
  enable_storage_subnet                = local.use_ANF && local.dbnode_per_site > 1

  // Availability Set
  availabilityset_arm_ids              = try(var.database.avset_arm_ids, [])
  availabilitysets_exist               = length(local.availabilityset_arm_ids) > 0 ? true : false

  // Return the max fault domain count for the region
  faultdomain_count                    = try(tonumber(compact(
                                           [for pair in local.faults :
                                             upper(pair.Location) == upper(var.infrastructure.region) ? pair.MaximumFaultDomainCount : ""
                                         ])[0]), 2)

  // Tags
  tags                                 = try(var.database.tags, {})

  hdb_version                          = try(var.database.db_version, "2.00.066")
  // If custom image is used, we do not overwrite os reference with default value
  hdb_custom_image                     = length(try(var.database.os.source_image_id, "")) > 0
  hdb_os                               = {
                                           os_type = "LINUX"
                                           source_image_id = local.hdb_custom_image ? (
                                             var.database.os.source_image_id) : (
                                             ""
                                           )
                                           publisher = local.hdb_custom_image ? (
                                             "") : (
                                             length(try(var.database.os.publisher, "")) > 0 ? (
                                               var.database.os.publisher) : (
                                               "SUSE"
                                             )
                                           )
                                           offer = local.hdb_custom_image ? (
                                             "") : (
                                             length(try(var.database.os.offer, "")) > 0 ? (
                                               var.database.os.offer) : (
                                               "sles-sap-15-sp3"
                                             )
                                           )
                                           sku = local.hdb_custom_image ? (
                                             "") : (
                                             length(try(var.database.os.sku, "")) > 0 ? (
                                               var.database.os.sku) : (
                                               "gen2"
                                             )
                                           )
                                           version = local.hdb_custom_image ? (
                                             "") : (
                                             length(try(var.database.os.version, "")) > 0 ? (
                                               var.database.os.version) : (
                                               "latest"
                                             )
                                           )
                                         }

  db_sizing_key                        = try(var.database.db_sizing_key, "Default")

  db_sizing                            = local.enable_deployment ? lookup(local.sizes.db, local.db_sizing_key).storage : []
  db_size                              = local.enable_deployment ? lookup(local.sizes.db, local.db_sizing_key).compute : {}

  hdb_vm_sku                           = length(var.database.database_vm_sku) > 0 ? var.database.database_vm_sku : try(local.db_size.vm_size, "Standard_E16_v3")

  sid_auth_type                       = try(var.database.authentication.type, "key")
  enable_auth_password                = try(var.database.authentication.type, "key") == "password"
  enable_auth_key                     = try(var.database.authentication.type, "key") == "key"

  authentication                      = {
                                          "type"     = local.sid_auth_type
                                          "username" = var.sid_username
                                          "password" = var.sid_password
                                        }

  enable_db_lb_deployment             = var.database_server_count > 0 && (var.use_loadbalancers_for_standalone_deployments || var.database_server_count > 1)

  database_sid                        = try(var.database.instance.sid, local.sid) // HANA database sid from the Databases array for use as reference to LB/AS
  database_instance                   = try(var.database.instance.number, "00")

  loadbalancer                        = try(var.database.loadbalancer, {})

  // Subnet IP Offsets
  // Note: First 4 IP addresses in a subnet are reserved by Azure
  hdb_ip_offsets                      = {
                                          hdb_lb         = 4
                                          hdb_admin_vm   = 4
                                          hdb_db_vm      = 5
                                          hdb_storage_vm = 4
                                        }

  // Ports used for specific HANA Versions
  lb_ports                            = {
                                          "1" = [
                                            "30015",
                                            "30017",
                                          ]

                                          "2" = [
                                            "30013",
                                            "30014",
                                            "30015",
                                            "30040",
                                            "30041",
                                            "30042",
                                          ]
                                        }

  loadbalancer_ports                  = local.enable_deployment ? (
                                          flatten([
                                            for port in local.lb_ports[split(".", local.hdb_version)[0]] : {
                                              sid  = var.sap_sid
                                              port = tonumber(port) + (tonumber(try(var.database.instance.number, 0)) * 100)
                                            }
                                          ])) : (
                                          null
                                        )

  // OS disk to be created for HANA DB nodes
  // disk_iops_read_write only apply for ultra
  os_disk                              = flatten(
                                           [
                                             for storage_type in local.db_sizing : [
                                               for idx, disk_count in range(storage_type.count) : {
                                                 storage_account_type      = storage_type.disk_type,
                                                 disk_size_gb              = storage_type.size_gb,
                                                 disk_iops_read_write      = try(storage_type.disk_iops_read_write, null)
                                                 disk_mbps_read_write      = try(storage_type.disk_mbps_read_write, null)
                                                 caching                   = storage_type.caching,
                                                 write_accelerator_enabled = try(storage_type.write_accelerator, false)
                                               }
                                               if !try(storage_type.append, false)
                                             ]
                                             if storage_type.name == "os"
                                           ]
                                         )


#######################################4#######################################8
#                                                                              #
#                                     Data disks                               #
#                                                                              #
#######################################4#######################################8
  data_disk_per_dbnode                 = var.database_server_count > 0 ? (
                                         flatten(
                                           [
                                             for storage_type in local.db_sizing : [
                                               for idx, disk_count in range(storage_type.count) : {
                                                 suffix = format("-%s%02d",
                                                   storage_type.name,
                                                   disk_count + var.options.resource_offset
                                                 )
                                                 storage_account_type      = storage_type.disk_type,
                                                 disk_size_gb              = storage_type.size_gb,
                                                 disk_iops_read_write      = try(storage_type.disk_iops_read_write, null)
                                                 disk_mbps_read_write      = try(storage_type.disk_mbps_read_write, null)
                                                 caching                   = storage_type.caching,
                                                 write_accelerator_enabled = storage_type.write_accelerator
                                                 type                      = storage_type.name
                                                 lun                       = storage_type.lun_start + idx
                                               }
                                               if !try(storage_type.append, false)
                                             ]
                                             if storage_type.name != "os"
                                           ]
                                         )) : (
                                         [
                                         ]
                                       )

#######################################4#######################################8
#                                                                              #
#                       Data disks to append (extensibility)                   #
#                 Append disks with the attribute append: true                 #
#                                                                              #
#######################################4#######################################8

  append_disk_per_dbnode               = var.database_server_count > 0 ? (
                                         flatten(
                                           [
                                             for storage_type in local.db_sizing : [
                                               for idx, disk_count in range(storage_type.count) : {
                                                 suffix = format("-%s%02d",
                                                   storage_type.name,
                                                   storage_type.name_offset + disk_count + var.options.resource_offset
                                                 )
                                                 storage_account_type      = storage_type.disk_type,
                                                 disk_size_gb              = storage_type.size_gb,
                                                 disk_iops_read_write      = try(storage_type.disk_iops_read_write, null)
                                                 disk_mbps_read_write      = try(storage_type.disk_mbps_read_write, null)
                                                 caching                   = storage_type.caching,
                                                 write_accelerator_enabled = storage_type.write_accelerator
                                                 type                      = storage_type.name
                                                 lun                       = storage_type.lun_start + idx
                                               }
                                               if try(storage_type.append, false)
                                             ]
                                             if storage_type.name != "os"
                                           ]
                                         )) : (
                                         [
                                         ]
                                       )


  base_data_disk_list                  = flatten(
                                           [
                                           for vm_counter in range(var.database_server_count) :
                                             [
                                               for datadisk in local.data_disk_per_dbnode : {
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

  append_data_disk_list                = flatten(
                                           [
                                           for vm_counter in range(var.database_server_count) :
                                             [
                                               for datadisk in local.append_disk_per_dbnode : {
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

  data_disk_list                       = distinct(concat(local.base_data_disk_list, local.append_data_disk_list))

  //Disks for Ansible
  // host: xxx, LUN: #, type: sapusr, size: #

  db_disks_ansible                     = distinct(
                                           flatten(
                                             [
                                               for vm in range(var.database_server_count) : [
                                                 for idx, datadisk in local.data_disk_list :
                                                 format("{ host: '%s', LUN: %d, type: '%s' }",
                                                   var.naming.virtualmachine_names.HANA_COMPUTERNAME[vm],
                                                   datadisk.lun,
                                                   datadisk.type
                                                 )
                                               ]
                                             ]
                                           )
                                         )

  enable_ultradisk                     = try(
                                           compact(
                                             [
                                               for storage in local.db_sizing : storage.disk_type == "UltraSSD_LRS" ? true : ""
                                             ]
                                           )[0],
                                           false
                                         )

  // Zones
  zones                                = try(var.database.zones, [])
  db_zone_count                        = length(local.zones)

  //Ultra disk requires zonal deployment
  zonal_deployment                     = local.db_zone_count > 0 || local.enable_ultradisk ? true : false

  //If we deploy more than one server in zone put them in an availability set

  use_avset                            = local.availabilitysets_exist ? (
                                           true) : (var.database.use_avset && !local.enable_ultradisk ? (
                                             !local.zonal_deployment || (var.database_server_count != local.db_zone_count)) : (
                                             false
                                           )
                                         )


  dns_label                            = try(var.landscape_tfstate.dns_label, "")

  ANF_pool_settings                    = try(var.landscape_tfstate.ANF_pool_settings,
                                           {
                                             use_ANF             = false
                                             account_name        = ""
                                             account_id          = ""
                                             pool_name           = ""
                                             service_level       = ""
                                             size_in_tb          = ""
                                             subnet_id           = ""
                                             resource_group_name = ""
                                             location            = ""
                                           }
                                         )

  database_primary_ips                 = [
                                           {
                                             name                          = "IPConfig1"
                                             subnet_id                     = var.db_subnet.id
                                             nic_ips                       = var.database_vm_db_nic_ips
                                             private_ip_address_allocation = var.database.use_DHCP ? "Dynamic" : "Static"
                                             offset                        = 0
                                             primary                       = true
                                           }
                                         ]

  database_secondary_ips               = [
                                           {
                                             name                          = "IPConfig2"
                                             subnet_id                     = var.db_subnet.id
                                             nic_ips                       = var.database_vm_db_nic_secondary_ips
                                             private_ip_address_allocation = var.database.use_DHCP ? "Dynamic" : "Static"
                                             offset                        = var.database_server_count
                                             primary                       = false
                                           }
                                         ]

  database_ips                         = var.use_secondary_ips ? (
                                           flatten(concat(local.database_primary_ips, local.database_secondary_ips))) : (
                                           local.database_primary_ips
                                         )



  data_volume_count                    = (var.hana_ANF_volumes.use_for_data || var.hana_ANF_volumes.use_existing_data_volume) ? (
                                           (var.database_server_count - var.database.stand_by_node_count) * var.hana_ANF_volumes.data_volume_count) : (
                                           0
                                         )
  log_volume_count                    = (var.hana_ANF_volumes.use_for_log || var.hana_ANF_volumes.use_existing_log_volume) ? (
                                           (var.database_server_count - var.database.stand_by_node_count) * var.hana_ANF_volumes.log_volume_count) : (
                                           0
                                         )

}
