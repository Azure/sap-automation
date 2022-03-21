
variable "anchor_vm" {
  description = "Deployed anchor VM"
}

variable "resource_group" {
  description = "Details of the resource group"
}

variable "storage_bootdiag_endpoint" {
  description = "Details of the boot diagnostics storage account"
}

variable "ppg" {
  description = "Details of the proximity placement group"
}

variable "naming" {
  description = "Defines the names for the resources"
}

variable "custom_disk_sizes_filename" {
  type        = string
  description = "Disk size json file"
  default     = ""
}

variable "admin_subnet" {
  description = "Information about SAP admin subnet"
}

variable "db_subnet" {
  description = "Information about SAP db subnet"
}

variable "storage_subnet" {
  description = "Information about storage subnet"
}

variable "sid_kv_user_id" {
  description = "Details of the user keyvault for sap_system"
}

variable "sdu_public_key" {
  description = "Public key used for authentication"
}

variable "sid_password" {
  description = "SDU password"
}

variable "sid_username" {
  description = "SDU username"
}

variable "sap_sid" {
  description = "The SID of the application"
}


variable "db_asg_id" {
  description = "Database Application Security Group"
}

variable "deployment" {
  description = "The type of deployment"
}

variable "terraform_template_version" {
  description = "The version of Terraform templates that were identified in the state file"
}

variable "cloudinit_growpart_config" {
  description = "A cloud-init config that configures automatic growpart expansion of root partition"
}

variable "license_type" {
  description = "Specifies the license type for the OS"
  default     = ""
}

variable "use_loadbalancers_for_standalone_deployments" {
  description = "Defines if load balancers are used even for standalone deployments"
  default     = true
}

variable "hana_dual_nics" {
  description = "Defines if the HANA DB uses dual network interfaces"
  default     = true
}

variable "database_vm_names" {
  default = [""]
}

variable "database_vm_db_nic_ips" {
  default = [""]
}

variable "database_vm_admin_nic_ips" {
  default = [""]
}

variable "database_vm_storage_nic_ips" {
  default = [""]
}

variable "database_server_count" {
  default = 1
}

variable   "order_deployment" {
  description = "psuedo condition for ordering deployment"
  default     = ""
}

variable "landscape_tfstate" {
  description = "Landscape remote tfstate file"
}

locals {
  // Resources naming
  computer_names       = var.naming.virtualmachine_names.HANA_COMPUTERNAME
  virtualmachine_names = var.naming.virtualmachine_names.HANA_VMNAME

  storageaccount_names = var.naming.storageaccount_names.SDU
  resource_suffixes    = var.naming.resource_suffixes

  default_filepath = format("%s%s", path.module, "/../../../../../configs/hdb_sizes.json")
  custom_sizing    = length(var.custom_disk_sizes_filename) > 0

  // Imports database sizing information
  file_name = local.custom_sizing ? (
    fileexists(var.custom_disk_sizes_filename) ? (
      var.custom_disk_sizes_filename) : (
      format("%s/%s", path.cwd, var.custom_disk_sizes_filename)
    )) : (
    local.default_filepath

  )

  sizes = jsondecode(file(local.file_name))

  faults = jsondecode(file(format("%s%s", path.module, "/../../../../../configs/max_fault_domain_count.json")))

  region    = var.infrastructure.region
  sid       = upper(var.sap_sid)
  prefix    = trimspace(var.naming.prefix.SDU)
  rg_exists = length(try(var.infrastructure.resource_group.arm_id, "")) > 0
  rg_name = local.rg_exists ? (
    try(split("/", var.infrastructure.resource_group.arm_id)[4], "")) : (
    coalesce(try(var.infrastructure.resource_group.name, ""), format("%s%s", local.prefix, local.resource_suffixes.sdu_rg))
  )

  hdb_list = [
    for db in var.databases : db
    if try(db.platform, "NONE") == "HANA"
  ]

  enable_deployment = (length(local.hdb_list) > 0) ? true : false

  // Filter the list of databases to only HANA platform entries
  hdb = var.databases[0]

  //ANF support
  use_ANF = try(local.hdb.use_ANF, false)
  //Scalout subnet is needed if ANF is used and there are more than one hana node 
  dbnode_per_site       = length(try(local.hdb.dbnodes, [{}]))
  enable_storage_subnet = local.use_ANF && local.dbnode_per_site > 1

  // Availability Set 
  availabilityset_arm_ids = try(local.hdb.avset_arm_ids, [])
  availabilitysets_exist  = length(local.availabilityset_arm_ids) > 0 ? true : false

  // Return the max fault domain count for the region
  faultdomain_count = try(tonumber(compact(
    [for pair in local.faults :
      upper(pair.Location) == upper(var.infrastructure.region) ? pair.MaximumFaultDomainCount : ""
  ])[0]), 2)

  // Tags
  tags = try(local.hdb.tags, {})

  // Support dynamic addressing

  hdb_platform = try(local.hdb.platform, "NONE")
  hdb_version  = try(local.hdb.db_version, "2.00.043")
  // If custom image is used, we do not overwrite os reference with default value
  hdb_custom_image = length(try(local.hdb.os.source_image_id, "")) > 0
  hdb_os = {
    os_type         = "LINUX"
    source_image_id = local.hdb_custom_image ? local.hdb.os.source_image_id : ""
    publisher       = local.hdb_custom_image ? "" : length(try(local.hdb.os.publisher, "")) > 0 ? local.hdb.os.publisher : "SUSE"
    offer           = local.hdb_custom_image ? "" : length(try(local.hdb.os.offer, "")) > 0 ? local.hdb.os.offer : "sles-sap-12-sp5"
    sku             = local.hdb_custom_image ? "" : length(try(local.hdb.os.sku, "")) > 0 ? local.hdb.os.sku : "gen1"
    version         = local.hdb_custom_image ? "" : length(try(local.hdb.os.version, "")) > 0 ? local.hdb.os.version : "latest"
  }

  hdb_size = try(local.hdb.size, "Default")

  db_sizing = local.enable_deployment ? lookup(local.sizes.db, local.hdb_size).storage : []
  db_size   = local.enable_deployment ? lookup(local.sizes.db, local.hdb_size).compute.vm_size : ""

  hdb_vm_sku = length(local.db_size) > 0 ? local.db_size : "Standard_E4s_v3"

  hdb_ha = try(local.hdb.high_availability, false)

  sid_auth_type        = try(local.hdb.authentication.type, "key")
  enable_auth_password = try(var.databases[0].authentication.type, "key") == "password"
  enable_auth_key      = try(var.databases[0].authentication.type, "key") == "key"

  authentication = {
    "type"     = local.sid_auth_type
    "username" = var.sid_username
    "password" = var.sid_password
  }
  
  enable_db_lb_deployment = var.database_server_count > 0 && (var.use_loadbalancers_for_standalone_deployments || var.database_server_count > 1)


  hdb_ins = try(local.hdb.instance, {})
  hdb_sid = try(local.hdb_ins.sid, local.sid) // HANA database sid from the Databases array for use as reference to LB/AS
  hdb_nr  = try(local.hdb_ins.instance_number, "00")

  loadbalancer = try(local.hdb.loadbalancer, {})

  // Subnet IP Offsets
  // Note: First 4 IP addresses in a subnet are reserved by Azure
  hdb_ip_offsets = {
    hdb_lb         = 4
    hdb_admin_vm   = 4
    hdb_db_vm      = 5
    hdb_storage_vm = 4
  }

  // Ports used for specific HANA Versions
  lb_ports = {
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

  loadbalancer_ports = local.enable_deployment ? flatten([
    for port in local.lb_ports[split(".", local.hdb_version)[0]] : {
      sid  = var.sap_sid
      port = tonumber(port) + (tonumber(try(var.databases[0].instance.instance_number, 0)) * 100)
    }
  ]) : null


  // List of data disks to be created for HANA DB nodes
  // disk_iops_read_write only apply for ultra
  data_disk_per_dbnode = (var.database_server_count > 0) ? flatten(
    [
      for storage_type in local.db_sizing : [
        for idx, disk_count in range(storage_type.count) : {
          suffix                    = format("-%s%02d", storage_type.name, disk_count + var.options.resource_offset)
          storage_account_type      = storage_type.disk_type,
          disk_size_gb              = storage_type.size_gb,
          disk_iops_read_write      = try(storage_type.disk-iops-read-write, null)
          disk_mbps_read_write      = try(storage_type.disk-mbps-read-write, null)
          caching                   = storage_type.caching,
          write_accelerator_enabled = storage_type.write_accelerator
          type                      = storage_type.name
          lun                       = storage_type.lun_start + idx
        }
        if !try(storage_type.append, false)
      ]
      if storage_type.name != "os"
    ]
  ) : []

  // OS disk to be created for HANA DB nodes
  // disk_iops_read_write only apply for ultra
  os_disk = flatten(
    [
      for storage_type in local.db_sizing : [
        for idx, disk_count in range(storage_type.count) : {
          storage_account_type      = storage_type.disk_type,
          disk_size_gb              = storage_type.size_gb,
          disk_iops_read_write      = try(storage_type.disk-iops-read-write, null)
          disk_mbps_read_write      = try(storage_type.disk-mbps-read-write, null)
          caching                   = storage_type.caching,
          write_accelerator_enabled = try(storage_type.write_accelerator, false)
        }
        if !try(storage_type.append, false)
      ]
      if storage_type.name == "os"
    ]
  )

  append_disk_per_dbnode = (var.database_server_count > 0) ? flatten(
    [
      for storage_type in local.db_sizing : [
        for idx, disk_count in range(storage_type.count) : {
          suffix                    = format("-%s%02d", storage_type.name, disk_count + var.options.resource_offset)
          storage_account_type      = storage_type.disk_type,
          disk_size_gb              = storage_type.size_gb,
          disk_iops_read_write      = try(storage_type.disk-iops-read-write, null)
          disk_mbps_read_write      = try(storage_type.disk-mbps-read-write, null)
          caching                   = storage_type.caching,
          write_accelerator_enabled = storage_type.write_accelerator
          type                      = storage_type.name
          lun                       = storage_type.lun_start + idx
        }
        if try(storage_type.append, false)
      ]
      if storage_type.name != "os"
    ]
  ) : []

  all_data_disk_per_dbnode = distinct(concat(local.data_disk_per_dbnode, local.append_disk_per_dbnode))

  data_disk_list = flatten([
    for vm_counter in range(var.database_server_count) : [
      for datadisk in local.all_data_disk_per_dbnode : {
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
  ])

  //Disks for Ansible
  // host: xxx, LUN: #, type: sapusr, size: #

  db_disks_ansible = distinct(flatten([for vm in range(var.database_server_count) : [
    for idx, datadisk in local.data_disk_list :
    format("{ host: '%s', LUN: %d, type: '%s' }", var.naming.virtualmachine_names.HANA_COMPUTERNAME[vm], datadisk.lun, datadisk.type)
  ]]))

  enable_ultradisk = try(
    compact(
      [
        for storage in local.db_sizing : storage.disk_type == "UltraSSD_LRS" ? true : ""
      ]
    )[0],
    false
  )

  // Zones
  zones         = try(local.hdb.zones, [])
  db_zone_count = length(local.zones)

  //Ultra disk requires zonal deployment
  zonal_deployment = local.db_zone_count > 0 || local.enable_ultradisk ? true : false

  //If we deploy more than one server in zone put them in an availability set
  use_avset = var.database_server_count > 0 && !try(local.hdb.no_avset, false) ? !local.zonal_deployment || (var.database_server_count != local.db_zone_count) : false

  //PPG control flag
  no_ppg = var.databases[0].no_ppg

  dns_label               = try(var.landscape_tfstate.dns_label, "")
  dns_resource_group_name = try(var.landscape_tfstate.dns_resource_group_name, "")

}
