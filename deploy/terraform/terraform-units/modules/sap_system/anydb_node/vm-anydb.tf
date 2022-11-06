#############################################################################
# RESOURCES
#############################################################################

#########################################################################################
#                                                                                       #
#  Primary Network Interface                                                            #
#                                                                                       #
#########################################################################################

resource "azurerm_network_interface" "anydb_db" {
  provider = azurerm.main
  count    = local.enable_deployment ? var.database_server_count : 0
  name = format("%s%s%s%s%s",
    var.naming.resource_prefixes.db_nic,
    local.prefix,
    var.naming.separator,
    var.naming.virtualmachine_names.ANYDB_VMNAME[count.index],
    local.resource_suffixes.db_nic
  )

  location                      = var.resource_group[0].location
  resource_group_name           = var.resource_group[0].name
  enable_accelerated_networking = true
  dynamic "ip_configuration" {
    iterator = pub
    for_each = local.database_ips
    content {
      name      = pub.value.name
      subnet_id = pub.value.subnet_id
      private_ip_address = try(pub.value.nic_ips[count.index],
        var.database.use_DHCP ? (
          null) : (
          cidrhost(
            var.db_subnet.address_prefixes[0],
            tonumber(count.index) + local.anydb_ip_offsets.anydb_db_vm + pub.value.offset
          )
        )
      )
      private_ip_address_allocation = length(try(pub.value.nic_ips[count.index], "")) > 0 ? (
        "Static") : (
        pub.value.private_ip_address_allocation
      )

      primary = pub.value.primary
    }
  }

}

resource "azurerm_network_interface_application_security_group_association" "db" {
  provider = azurerm.main
  count = local.enable_deployment ? (
    var.deploy_application_security_groups ? var.database_server_count : 0) : (
    0
  )

  network_interface_id          = azurerm_network_interface.anydb_db[count.index].id
  application_security_group_id = var.db_asg_id
}

#########################################################################################
#                                                                                       #
#  Admin Network Interface                                                              #
#                                                                                       #
#########################################################################################
resource "azurerm_network_interface" "anydb_admin" {
  provider = azurerm.main
  count = local.enable_deployment && local.anydb_dual_nics ? (
    var.database_server_count) : (
    0
  )
  name = format("%s%s%s%s%s",
    var.naming.resource_prefixes.admin_nic,
    local.prefix,
    var.naming.separator,
    var.naming.virtualmachine_names.ANYDB_VMNAME[count.index],
    local.resource_suffixes.admin_nic
  )
  location                      = var.resource_group[0].location
  resource_group_name           = var.resource_group[0].name
  enable_accelerated_networking = true

  ip_configuration {
    primary   = true
    name      = "ipconfig1"
    subnet_id = var.admin_subnet.id

    private_ip_address = try(var.database_vm_admin_nic_ips[count.index], var.database.use_DHCP ? (
      null) : (
      cidrhost(
        var.admin_subnet.address_prefixes[0],
        tonumber(count.index) + local.anydb_ip_offsets.anydb_admin_vm
      )
      )
    )
    private_ip_address_allocation = length(try(var.database_vm_admin_nic_ips[count.index], "")) > 0 ? (
      "Static") : (
      "Dynamic"
    )
  }
}

// Section for Linux Virtual machine
resource "azurerm_linux_virtual_machine" "dbserver" {
  provider   = azurerm.main
  depends_on = [var.anchor_vm]
  count = local.enable_deployment ? (
    upper(local.anydb_ostype) == "LINUX" ? (
      var.database_server_count) : (
      0
    )) : (
    0
  )
  name = format("%s%s%s%s%s",
    var.naming.resource_prefixes.vm,
    local.prefix,
    var.naming.separator,
    var.naming.virtualmachine_names.ANYDB_VMNAME[count.index],
    local.resource_suffixes.vm
  )
  computer_name       = var.naming.virtualmachine_names.ANYDB_COMPUTERNAME[count.index]
  resource_group_name = var.resource_group[0].name
  location            = var.resource_group[0].location

  admin_username                  = var.sid_username
  admin_password                  = local.enable_auth_key ? null : var.sid_password
  disable_password_authentication = !local.enable_auth_password

  dynamic "admin_ssh_key" {
    for_each = range(var.deployment == "new" ? 1 : (local.enable_auth_password ? 0 : 1))
    content {
      username   = var.sid_username
      public_key = var.sdu_public_key
    }
  }

  custom_data = var.deployment == "new" ? var.cloudinit_growpart_config : null

  dynamic "os_disk" {
    iterator = disk
    for_each = range(length(local.os_disk))
    content {
      name = format("%s%s%s%s%s",
        var.naming.resource_prefixes.osdisk,
        local.prefix,
        var.naming.separator,
        var.naming.virtualmachine_names.ANYDB_VMNAME[count.index],
        local.resource_suffixes.osdisk
      )
      caching                = local.os_disk[0].caching
      storage_account_type   = local.os_disk[0].storage_account_type
      disk_size_gb           = local.os_disk[0].disk_size_gb
      disk_encryption_set_id = try(var.options.disk_encryption_set_id, null)

    }
  }

  //If no ppg defined do not put the database in a proximity placement group
  proximity_placement_group_id = local.zonal_deployment ? (
    null) : (
    local.no_ppg ? (
      null) : (
      var.ppg[0].id
    )
  )
  //If more than one servers are deployed into a single zone put them in an availability set and not a zone
  availability_set_id = local.use_avset ? (
    local.availabilitysets_exist ? (
      data.azurerm_availability_set.anydb[count.index % max(local.db_zone_count, 1)].id) : (
      azurerm_availability_set.anydb[count.index % max(local.db_zone_count, 1)].id
    )
  ) : null

  zone = local.zonal_deployment ? try(local.zones[count.index % max(local.db_zone_count, 1)], null) : null

  network_interface_ids = local.anydb_dual_nics ? (
    var.options.legacy_nic_order ? (
      [
        azurerm_network_interface.anydb_admin[count.index].id,
        azurerm_network_interface.anydb_db[count.index].id
      ]) : (
      [
        azurerm_network_interface.anydb_db[count.index].id,
        azurerm_network_interface.anydb_admin[count.index].id
      ]
    )) : (
    [azurerm_network_interface.anydb_db[count.index].id]
  )

  size = local.anydb_sku

  source_image_id = var.database.os.type == "custom" ? var.database.os.source_image_id : null

  dynamic "source_image_reference" {
    for_each = range(var.database.os.type == "marketplace" ? 1 : 0)
    content {
      publisher = var.database.os.publisher
      offer     = var.database.os.offer
      sku       = var.database.os.sku
      version   = var.database.os.version
    }
  }
  dynamic "plan" {
    for_each = range(var.database.os.type == "marketplace_with_plan" ? 1 : 0)
    content {
      name      = var.database.os.offer
      publisher = var.database.os.publisher
      product   = var.database.os.sku
    }
  }

  additional_capabilities {
    ultra_ssd_enabled = local.enable_ultradisk
  }

  boot_diagnostics {
    storage_account_uri = var.storage_bootdiag_endpoint
  }

  license_type = length(var.license_type) > 0 ? var.license_type : null

  tags = local.tags

  lifecycle {
    ignore_changes = [
      // Ignore changes to computername
      tags,
      computer_name
    ]
  }

}

// Section for Windows Virtual machine
resource "azurerm_windows_virtual_machine" "dbserver" {
  provider   = azurerm.main
  depends_on = [var.anchor_vm]
  count = local.enable_deployment ? (
    upper(local.anydb_ostype) == "WINDOWS" ? (
      var.database_server_count) : (
      0
    )
    ) : (
    0
  )
  name = format("%s%s%s%s%s",
    var.naming.resource_prefixes.vm,
    local.prefix,
    var.naming.separator,
    var.naming.virtualmachine_names.ANYDB_VMNAME[count.index],
    local.resource_suffixes.vm
  )
  computer_name       = var.naming.virtualmachine_names.ANYDB_COMPUTERNAME[count.index]
  resource_group_name = var.resource_group[0].name
  location            = var.resource_group[0].location
  admin_username      = var.sid_username
  admin_password      = var.sid_password

  dynamic "os_disk" {
    iterator = disk
    for_each = range(length(local.os_disk))
    content {
      name = format("%s%s%s%s%s",
        var.naming.resource_prefixes.osdisk,
        local.prefix,
        var.naming.separator,
        var.naming.virtualmachine_names.ANYDB_VMNAME[count.index],
        local.resource_suffixes.osdisk
      )
      caching                = local.os_disk[0].caching
      storage_account_type   = local.os_disk[0].storage_account_type
      disk_size_gb           = local.os_disk[0].disk_size_gb < 128 ? 128 : local.os_disk[0].disk_size_gb
      disk_encryption_set_id = try(var.options.disk_encryption_set_id, null)

    }
  }

  //If no ppg defined do not put the database in a proximity placement group
  proximity_placement_group_id = local.zonal_deployment ? (
    null) : (
    local.no_ppg ? (
      null) : (
      var.ppg[0].id
    )
  )

  //If more than one servers are deployed into a single zone put them in an availability set and not a zone
  availability_set_id = local.use_avset ? (
    local.availabilitysets_exist ? (
      data.azurerm_availability_set.anydb[count.index % max(local.db_zone_count, 1)].id) : (
      azurerm_availability_set.anydb[count.index % max(local.db_zone_count, 1)].id
    )
  ) : null

  zone = local.zonal_deployment ? try(local.zones[count.index % max(local.db_zone_count, 1)], null) : null

  network_interface_ids = local.anydb_dual_nics ? (
    var.options.legacy_nic_order ? (
      [
        azurerm_network_interface.anydb_admin[count.index].id,
        azurerm_network_interface.anydb_db[count.index].id
      ]) : (
      [
        azurerm_network_interface.anydb_db[count.index].id,
        azurerm_network_interface.anydb_admin[count.index].id
      ]
    )) : (
    [azurerm_network_interface.anydb_db[count.index].id]
  )

  size = local.anydb_sku

  source_image_id = var.database.os.type == "custom" ? var.database.os.source_image_id : null

  dynamic "source_image_reference" {
    for_each = range(var.database.os.type == "marketplace" ? 1 : 0)
    content {
      publisher = var.database.os.publisher
      offer     = var.database.os.offer
      sku       = var.database.os.sku
      version   = var.database.os.version
    }
  }
  dynamic "plan" {
    for_each = range(var.database.os.type == "marketplace_with_plan" ? 1 : 0)
    content {
      name      = var.database.os.offer
      publisher = var.database.os.publisher
      product   = var.database.os.sku
    }
  }

  additional_capabilities {
    ultra_ssd_enabled = local.enable_ultradisk
  }

  boot_diagnostics {
    storage_account_uri = var.storage_bootdiag_endpoint
  }

  #ToDo: Remove once feature is GA  patch_mode = "Manual"
  license_type = length(var.license_type) > 0 ? var.license_type : null

  tags = local.tags
  lifecycle {
    ignore_changes = [
      // Ignore changes to computername
      computer_name,
      tags
    ]
  }
}

// Creates managed data disks
resource "azurerm_managed_disk" "disks" {
  provider = azurerm.main
  count    = local.enable_deployment ? length(local.anydb_disks) : 0
  name = format("%s%s%s%s%s",
    var.naming.resource_prefixes.disk,
    local.prefix,
    var.naming.separator,
    var.naming.virtualmachine_names.ANYDB_VMNAME[local.anydb_disks[count.index].vm_index],
    local.anydb_disks[count.index].suffix
  )
  location               = var.resource_group[0].location
  resource_group_name    = var.resource_group[0].name
  create_option          = "Empty"
  storage_account_type   = local.anydb_disks[count.index].storage_account_type
  disk_size_gb           = local.anydb_disks[count.index].disk_size_gb
  disk_encryption_set_id = try(var.options.disk_encryption_set_id, null)
  disk_iops_read_write = "UltraSSD_LRS" == local.anydb_disks[count.index].storage_account_type ? (
    local.anydb_disks[count.index].disk_iops_read_write) : (
    null
  )
  disk_mbps_read_write = "UltraSSD_LRS" == local.anydb_disks[count.index].storage_account_type ? (
    local.anydb_disks[count.index].disk_mbps_read_write) : (
    null
  )

  zone = local.zonal_deployment ? (
    upper(local.anydb_ostype) == "LINUX" ? (
      azurerm_linux_virtual_machine.dbserver[local.anydb_disks[count.index].vm_index].zone) : (
      azurerm_windows_virtual_machine.dbserver[local.anydb_disks[count.index].vm_index].zone
  )) : null

}

// Manages attaching a Disk to a Virtual Machine
resource "azurerm_virtual_machine_data_disk_attachment" "vm_disks" {
  provider        = azurerm.main
  count           = local.enable_deployment ? length(local.anydb_disks) : 0
  managed_disk_id = azurerm_managed_disk.disks[count.index].id
  virtual_machine_id = upper(local.anydb_ostype) == "LINUX" ? (
    azurerm_linux_virtual_machine.dbserver[local.anydb_disks[count.index].vm_index].id) : (
    azurerm_windows_virtual_machine.dbserver[local.anydb_disks[count.index].vm_index].id
  )
  caching                   = local.anydb_disks[count.index].caching
  write_accelerator_enabled = local.anydb_disks[count.index].write_accelerator_enabled
  lun                       = local.anydb_disks[count.index].lun
}


# VM Extension
resource "azurerm_virtual_machine_extension" "anydb_lnx_aem_extension" {
  provider = azurerm.main
  count = local.enable_deployment ? (
    upper(local.anydb_ostype) == "LINUX" ? (
      var.database_server_count) : (
      0
    )) : (
    0
  )
  name                 = "MonitorX64Linux"
  virtual_machine_id   = azurerm_linux_virtual_machine.dbserver[count.index].id
  publisher            = "Microsoft.AzureCAT.AzureEnhancedMonitoring"
  type                 = "MonitorX64Linux"
  type_handler_version = "1.0"
  settings             = <<SETTINGS
  {
    "system": "SAP"
  }
SETTINGS
}


resource "azurerm_virtual_machine_extension" "anydb_win_aem_extension" {
  provider = azurerm.main
  count = local.enable_deployment ? (
    upper(local.anydb_ostype) == "WINDOWS" ? (
      var.database_server_count) : (
      0
    )) : (
    0
  )
  name                 = "MonitorX64Windows"
  virtual_machine_id   = azurerm_windows_virtual_machine.dbserver[count.index].id
  publisher            = "Microsoft.AzureCAT.AzureEnhancedMonitoring"
  type                 = "MonitorX64Windows"
  type_handler_version = "1.0"
  settings             = <<SETTINGS
  {
    "system": "SAP"
  }
SETTINGS
}

resource "azurerm_virtual_machine_extension" "configure_ansible" {

  provider = azurerm.main
  count = local.enable_deployment ? (
    upper(local.anydb_ostype) == "WINDOWS" ? (
      var.database_server_count) : (
      0
    )) : (
    0
  )


  name                 = "configure_ansible"
  virtual_machine_id   = azurerm_windows_virtual_machine.dbserver[count.index].id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.9"
  settings             = <<SETTINGS
        {
          "fileUris": ["https://raw.githubusercontent.com/ansible/ansible/devel/examples/scripts/ConfigureRemotingForAnsible.ps1"],
          "commandToExecute": "powershell.exe -ExecutionPolicy Unrestricted -File ConfigureRemotingForAnsible.ps1 -Verbose"
        }
    SETTINGS
}
