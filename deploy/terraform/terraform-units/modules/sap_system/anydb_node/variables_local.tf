# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

#######################################4#######################################8
#                                                                              #
#                            Local variables                                   #
#                                                                              #
#######################################4#######################################8

locals {

  faults                               = jsondecode(file(format("%s%s",
                                          path.module,
                                          "/../../../../../configs/max_fault_domain_count.json"))
                                        )
  // Return the max fault domain count for the region
  faultdomain_count                    = try(tonumber(compact(
                                           [for pair in local.faults :
                                             upper(pair.Location) == upper(var.infrastructure.region) ? pair.MaximumFaultDomainCount : ""
                                         ])[0]), 2)

  storageaccount_names                 = var.naming.storageaccount_names.SDU
  resource_suffixes                    = var.naming.resource_suffixes

  region                               = var.infrastructure.region
  anydb_sid                            = try(var.database.sid, "")
  sid                                  = length(var.sap_sid) > 0 ? var.sap_sid : local.anydb_sid
  prefix                               = trimspace(var.naming.prefix.SDU)

  // Allowing changing the base for indexing, default is zero-based indexing,
  // if customers want the first disk to start with 1 they would change this
  offset                               = try(var.options.resource_offset, 0)

  //Allowing to keep the old nic order
  legacy_nic_order                     = try(var.options.legacy_nic_order, false)
  // Availability Set
  availabilityset_arm_ids              = try(var.database.avset_arm_ids, [])
  availabilitysets_exist               = length(local.availabilityset_arm_ids) > 0 ? true : false

  // Dual network cards
  anydb_dual_nics                      = try(var.database.dual_nics, false) && length(try(var.admin_subnet.id, "")) > 0

  enable_deployment                    = contains(["ORACLE", "ORACLE-ASM", "DB2", "SQLSERVER", "SYBASE"], var.database.platform)

  // Imports database sizing information

  default_filepath                     = format("%s%s",
                                           path.module,
                                           format("/../../../../../configs/%s_sizes.json", lower(var.database.platform))
                                         )
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


  // If custom image is used, we do not overwrite os reference with default value
  anydb_custom_image                   = try(var.database.os.source_image_id, "") != "" ? true : false
  anydb_ostype                         = upper(var.database.platform) == "SQLSERVER" ? "WINDOWS" : try(var.database.os.os_type, "LINUX")
  anydb_oscode                         = upper(local.anydb_ostype) == "LINUX" ? "l" : "w"
  anydb_size                           = try(var.database.db_sizing_key, "Default")

  db_sizing                            = local.enable_deployment ? lookup(local.sizes.db, local.anydb_size).storage : []
  db_size                              = local.enable_deployment ? lookup(local.sizes.db, local.anydb_size).compute : {}

  anydb_sku                            = length(var.database.database_vm_sku) > 0 ? var.database.database_vm_sku : try(local.db_size.vm_size, "Standard_E16_v3")

  anydb_ha                             = var.database.high_availability
  db_sid                               = try(var.database.instance.sid, lower(substr(var.database.platform, 0, 3)))

  # Oracle deployments do not need a load balancer
  enable_db_lb_deployment              = (
                                           var.database_server_count > 0 &&
                                           (var.use_loadbalancers_for_standalone_deployments || var.database_server_count > 1) &&
                                           var.database.platform != "ORACLE" && var.database.platform != "ORACLE-ASM" &&
                                           var.database.platform != "NONE"
                                         )

  anydb_cred                           = try(var.database.credentials, {})

  sid_auth_type                        = try(var.database.authentication.type, "key")
  enable_auth_password                 = local.enable_deployment && local.sid_auth_type == "password"
  enable_auth_key                      = local.enable_deployment && local.sid_auth_type == "key"

  // Tags
  tags                                 = try(var.database.tags, {})

  authentication                       = {
                                           "type"     = local.sid_auth_type
                                           "username" = var.sid_username
                                           "password" = var.sid_password
                                         }
  os_defaults =                          {
                                           SYBASE   = {
                                                        "publisher" = "SUSE",
                                                        "offer"     = "sles-sap-15-sp5",
                                                        "sku"       = "gen2"
                                                        "version"   = "latest"
                                                      }
                                           DB2      = {
                                                        "publisher" = "RedHat",
                                                        "offer"     = "RHEL-SAP-HA",
                                                        "sku"       = "86sapha-gen2"
                                                        "version"   = "latest"
                                                      }
                                           HANA     = {
                                                        "publisher" = "SUSE",
                                                        "offer"     = "sles-sap-15-sp5",
                                                        "sku"       = "gen2"
                                                        "version"   = "latest"
                                                      }
                                           ORACLE    = {
                                                         "publisher" = "Oracle",
                                                         "offer"     = "Oracle-Linux",
                                                         "sku"       = "ol8_6-gen2"
                                                         "version"   = "latest"
                                                       }
                                           SQLSERVER = {
                                                         "publisher" = "MicrosoftSqlServer",
                                                         "offer"     = "SQL2017-WS2016",
                                                         "sku"       = "standard-gen2",
                                                         "version"   = "latest"
                                                       }
                                           NONE      = {
                                                         "publisher" = "",
                                                         "offer"     = "",
                                                         "sku"       = "",
                                                         "version"   = ""
                                                       }
                                         }

  anydb_os                             = local.enable_deployment ? {
                                           "source_image_id" = local.anydb_custom_image ? (
                                             var.database.os.source_image_id) : (
                                             ""
                                           )
                                           "publisher" = try(
                                             var.database.os.publisher,
                                             local.anydb_custom_image ? (
                                               "") : (
                                               local.os_defaults[upper(var.database.platform)].publisher
                                             )
                                           )
                                           "offer" = try(
                                             var.database.os.offer,
                                             local.anydb_custom_image ? (
                                               "") : (
                                               local.os_defaults[upper(var.database.platform)].offer
                                             )
                                           )
                                           "sku" = try(
                                             var.database.os.sku,
                                             local.anydb_custom_image ? (
                                               "") : (
                                               local.os_defaults[upper(var.database.platform)].sku
                                             )
                                           )
                                           "version" = try(
                                             var.database.os.version,
                                             local.anydb_custom_image ? (
                                               "") : (
                                               local.os_defaults[upper(var.database.platform)].version
                                             )
                                           )
                                         } : null

  //Observer VM
  observer                             = try(var.database.observer, {})

  #If using an existing VM for observer set use_observer to false in .tfvars
  deploy_observer                      = var.use_observer ? (
                                           (upper(var.database.platform) == "ORACLE" || upper(var.database.platform) == "ORACLE-ASM") && var.database.high_availability) : (
                                           false
                                         )
  observer_vm_size                     = try(var.observer_vm_size, "Standard_D4s_v3")
  observer_authentication              = local.authentication
  observer_custom_image                = local.anydb_custom_image
  observer_custom_image_id             = local.enable_deployment ? local.anydb_os.source_image_id : ""
  observer_os                          = local.enable_deployment ? local.anydb_os : null

  // Subnet IP Offsets
  // Note: First 4 IP addresses in a subnet are reserved by Azure
  anydb_ip_offsets                     = {
                                           anydb_lb       = 4
                                           anydb_admin_vm = 4
                                           anydb_db_vm    = 5 + 1
                                           observer_db_vm = 5
                                         }

  // Ports used for specific DB Versions
  lb_ports                             = {
                                           "SYBASE"     = [
                                                            "63500"
                                                          ]
                                           "ORACLE"     = [
                                                            "1521"
                                                          ]
                                           "ORACLE-ASM" = [
                                                            "1521"
                                                          ]
                                           "DB2"        = [
                                                            "62500"
                                                          ]
                                           "SQLSERVER"  = [
                                                            "59999"
                                                          ]
                                           "NONE"       = [
                                                            "80"
                                                          ]
                                           "HANA"       = [
                                                             "30013",
                                                             "30014",
                                                             "30015",
                                                             "30040",
                                                             "30041",
                                                             "30042",
                                                           ]
                                         }

  loadbalancer_ports                   = flatten([
                                           for port in local.lb_ports[upper(var.database.platform)] : {
                                             port = tonumber(port)
                                           }
                                         ])

  // OS disk to be created for DB nodes
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



  // List of data disks to be created for  DB nodes
  // disk_iops_read_write only apply for ultra

  data_disk_per_dbnode                 = (var.database_server_count > 0) ? flatten(
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
                                                 write_accelerator_enabled = try(storage_type.write_accelerator, false)
                                                 type                      = storage_type.name
                                                 tier                      = try(storage_type.tier, null)
                                                 lun                       = storage_type.lun_start + idx
                                               }
                                               if !try(storage_type.append, false)
                                             ]
                                             if storage_type.name != "os"
                                           ]
                                         ) : []

  append_data_disk_per_dbnode          = (var.database_server_count > 0) ? flatten(
                                         [
                                           for storage_type in local.db_sizing : [
                                             for idx, disk_count in range(storage_type.count) : {
                                               suffix = format("-%s%02d",
                                                 storage_type.name,
                                                 storage_type.name_offset + disk_count + var.options.resource_offset
                                               )
                                               storage_account_type      = storage_type.disk_type
                                               disk_size_gb              = storage_type.size_gb
                                               disk_iops_read_write      = try(storage_type.disk_iops_read_write, null)
                                               disk_mbps_read_write      = try(storage_type.disk_mbps_read_write, null)
                                               tier                      = try(storage_type.tier, null)
                                               caching                   = storage_type.caching
                                               write_accelerator_enabled = try(storage_type.write_accelerator, false)
                                               type                      = storage_type.name
                                               tier                      = try(storage_type.tier, null)
                                               lun                       = storage_type.lun_start + idx
                                             }
                                             if try(storage_type.append, false)
                                           ]
                                           if storage_type.name != "os"
                                         ]
                                       ) : []

  base_anydb_disks                     = flatten([
                                           for vm_counter in range(var.database_server_count) : [
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
                                               tier                      = datadisk.tier
                                             }
                                           ]
                                         ])

  append_anydb_disks                   = flatten([
                                          for vm_counter in range(var.database_server_count) : [
                                            for datadisk in local.append_data_disk_per_dbnode : {
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
                                              tier                      = datadisk.tier
                                            }
                                          ]
                                        ])

  anydb_disks                          = distinct(concat(local.base_anydb_disks, local.append_anydb_disks))

  //Disks for Ansible
  // host: xxx, LUN: #, type: sapusr, size: #

  db_disks_ansible                     = distinct(flatten([for vm in range(var.database_server_count) : [
                                           for idx, datadisk in local.anydb_disks :
                                           format("{ host: '%s', LUN: %d, type: '%s' }",
                                             var.naming.virtualmachine_names.ANYDB_COMPUTERNAME[vm],
                                             datadisk.lun,
                                             datadisk.type
                                           )
                                         ]]))

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

  use_ppg                              = length(var.scale_set_id) > 0 ? (
                                           false) : (
                                           var.database.use_ppg
                                         )

  //If we deploy more than one server in zone put them in an availability set
  use_avset                            = length(var.scale_set_id) > 0 ? (
                                          false) : (
                                          local.availabilitysets_exist || var.database.use_avset ? (
                                            true) : (!local.enable_ultradisk ? (
                                              !local.zonal_deployment || (var.database_server_count != local.db_zone_count)) : (
                                              false
                                            )
                                          )
                                        )

  full_observer_names                  = flatten([for vm in var.naming.virtualmachine_names.OBSERVER_VMNAME :
                                           format("%s%s%s%s%s",
                                             var.naming.resource_prefixes.vm,
                                             local.prefix,
                                             var.naming.separator,
                                             vm,
                                             var.naming.resource_suffixes.vm
                                           )]
                                         )


  dns_label                            = try(var.landscape_tfstate.dns_label, "")
  dns_resource_group_name              = try(var.landscape_tfstate.dns_resource_group_name, "")

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

  database_ips                         = (var.use_secondary_ips) ? (
                                           flatten(concat(local.database_primary_ips, local.database_secondary_ips))) : (
                                           local.database_primary_ips
                                         )


  standard_ips                              = [
                                           {
                                             name               = format("%s%s%s%s",
                                                                    var.naming.resource_prefixes.db_alb_feip,
                                                                    local.prefix,
                                                                    var.naming.separator,
                                                                    local.resource_suffixes.db_alb_feip
                                                                  )
                                             subnet_id          = var.db_subnet.id
                                             private_ip_address = length(try(var.database.loadbalancer.frontend_ips[0], "")) > 0 ? (
                                                                    var.database.loadbalancer.frontend_ips[0]) : (
                                                                    var.database.use_DHCP ? (
                                                                      null) : (
                                                                      cidrhost(
                                                                        var.db_subnet.address_prefixes[0],
                                                                        local.anydb_ip_offsets.anydb_lb
                                                                    ))
                                                                  )
                                             private_ip_address_allocation = length(try(var.database.loadbalancer.frontend_ips[0], "")) > 0 ? "Static" : "Dynamic"
                                             zones              = ["1", "2", "3"]
                                           },
                                           {
                                             name               = format("%s%s%s%s",
                                                                    var.naming.resource_prefixes.db_clst_feip,
                                                                    local.prefix,
                                                                    var.naming.separator,
                                                                    local.resource_suffixes.db_clst_feip
                                                                  )
                                             subnet_id          = var.db_subnet.id
                                             private_ip_address = length(try(var.database.loadbalancer.frontend_ips[1], "")) > 0 ? (
                                                                    var.database.loadbalancer.frontend_ips[1]) : (
                                                                    var.database.use_DHCP ? (
                                                                      null) : (
                                                                      cidrhost(
                                                                        var.db_subnet.address_prefixes[0],
                                                                        local.anydb_ip_offsets.anydb_lb + 1
                                                                    ))
                                                                  )
                                             private_ip_address_allocation = length(try(var.database.loadbalancer.frontend_ips[1], "")) > 0 ? "Static" : "Dynamic"
                                             zones              = ["1", "2", "3"]

                                           }

                                         ]

  windows_high_availability            = var.database.high_availability && upper(local.anydb_ostype) == "WINDOWS"

  frontend_ips                         = slice(local.standard_ips, 0, local.windows_high_availability ? 2 : 1)

  extension_settings                   =  length(var.database.user_assigned_identity_id) > 0 ? [{
                                           "key" = "msi_res_id"
                                           "value" = var.database.user_assigned_identity_id
                                         }] : []

  deploy_monitoring_extension          = local.enable_deployment && var.infrastructure.deploy_monitoring_extension && length(var.database.user_assigned_identity_id) > 0

}
