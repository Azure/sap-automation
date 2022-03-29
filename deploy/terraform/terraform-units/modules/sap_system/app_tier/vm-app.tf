# Create Application NICs

resource "azurerm_network_interface" "app" {
  provider                      = azurerm.main
  count                         = local.enable_deployment ? local.application_server_count : 0
  name                          = format("%s%s%s%s", local.prefix, var.naming.separator, var.naming.virtualmachine_names.APP_VMNAME[count.index], local.resource_suffixes.nic)
  location                      = var.resource_group[0].location
  resource_group_name           = var.resource_group[0].name
  enable_accelerated_networking = local.app_sizing.compute.accelerated_networking

  ip_configuration {
    name      = "IPConfig1"
    subnet_id = local.sub_app_exists ? data.azurerm_subnet.subnet_sap_app[0].id : azurerm_subnet.subnet_sap_app[0].id
    private_ip_address = var.application.use_DHCP ? (
      null) : (
      try(local.app_nic_ips[count.index],
        cidrhost(local.sub_app_exists ?
          data.azurerm_subnet.subnet_sap_app[0].address_prefixes[0] :
          azurerm_subnet.subnet_sap_app[0].address_prefixes[0],
          tonumber(count.index) + local.ip_offsets.app_vm
        )
      )
    )
    private_ip_address_allocation = var.application.use_DHCP ? "Dynamic" : "Static"

  }
}

resource "azurerm_network_interface_application_security_group_association" "app" {
  provider                      = azurerm.main
  count                         = local.enable_deployment ? local.application_server_count : 0
  network_interface_id          = azurerm_network_interface.app[count.index].id
  application_security_group_id = azurerm_application_security_group.app[0].id
}

# Create Application NICs
resource "azurerm_network_interface" "app_admin" {
  provider                      = azurerm.main
  count                         = local.enable_deployment && var.application.dual_nics ? local.application_server_count : 0
  name                          = format("%s%s%s%s", local.prefix, var.naming.separator, var.naming.virtualmachine_names.APP_VMNAME[count.index], local.resource_suffixes.admin_nic)
  location                      = var.resource_group[0].location
  resource_group_name           = var.resource_group[0].name
  enable_accelerated_networking = local.app_sizing.compute.accelerated_networking

  ip_configuration {
    name      = "IPConfig1"
    subnet_id = var.admin_subnet.id
    private_ip_address = var.application.use_DHCP ? (
      null) : (
      try(local.app_admin_nic_ips[count.index],
        cidrhost(var.admin_subnet.address_prefixes[0],
          tonumber(count.index) + local.admin_ip_offsets.app_vm
        )
      )
    )
    private_ip_address_allocation = var.application.use_DHCP ? "Dynamic" : "Static"
  }
}

# Create the Linux Application VM(s)
resource "azurerm_linux_virtual_machine" "app" {
  provider            = azurerm.main
  count               = local.enable_deployment ? (upper(local.app_ostype) == "LINUX" ? local.application_server_count : 0) : 0
  name                = format("%s%s%s%s", local.prefix, var.naming.separator, var.naming.virtualmachine_names.APP_VMNAME[count.index], local.resource_suffixes.vm)
  computer_name       = var.naming.virtualmachine_names.APP_COMPUTERNAME[count.index]
  location            = var.resource_group[0].location
  resource_group_name = var.resource_group[0].name

  //If no ppg defined do not put the application servers in a proximity placement group
  proximity_placement_group_id = local.app_no_ppg ? (
    null) : (
    local.app_zonal_deployment ? var.ppg[count.index % max(local.app_zone_count, 1)].id : var.ppg[0].id
  )

  //If more than one servers are deployed into a single zone put them in an availability set and not a zone
  availability_set_id = local.use_app_avset ? (
    length(var.application.avset_arm_ids) > 0 ? (
      var.application.avset_arm_ids[count.index % max(local.app_zone_count, 1)]) : (
      azurerm_availability_set.app[count.index % max(local.app_zone_count, 1)].id
    )) : (
    null
  )

  //If length of zones > 1 distribute servers evenly across zones
  zone = local.use_app_avset ? null : try(local.app_zones[count.index % max(local.app_zone_count, 1)], null)

  network_interface_ids = var.application.dual_nics ? (
    var.options.legacy_nic_order ? (
      [azurerm_network_interface.app_admin[count.index].id, azurerm_network_interface.app[count.index].id]) : (
      [azurerm_network_interface.app[count.index].id, azurerm_network_interface.app_admin[count.index].id]
    )
    ) : (
    [azurerm_network_interface.app[count.index].id]
  )

  size                            = length(local.app_size) > 0 ? local.app_size : local.app_sizing.compute.vm_size
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
    for_each = flatten(
      [
        for storage_type in local.app_sizing.storage : [
          for disk_count in range(storage_type.count) :
          {
            name      = storage_type.name,
            id        = disk_count,
            disk_type = storage_type.disk_type,
            size_gb   = storage_type.size_gb,
            caching   = storage_type.caching
          }
        ]
        if storage_type.name == "os"
      ]
    )

    content {
      name                   = format("%s%s%s%s", local.prefix, var.naming.separator, var.naming.virtualmachine_names.APP_VMNAME[count.index], local.resource_suffixes.osdisk)
      caching                = disk.value.caching
      storage_account_type   = disk.value.disk_type
      disk_size_gb           = disk.value.size_gb
      disk_encryption_set_id = try(var.options.disk_encryption_set_id, null)
    }
  }

  source_image_id = local.app_custom_image ? local.app_os.source_image_id : null

  dynamic "source_image_reference" {
    for_each = range(local.app_custom_image ? 0 : 1)
    content {
      publisher = local.app_os.publisher
      offer     = local.app_os.offer
      sku       = local.app_os.sku
      version   = local.app_os.version
    }
  }

  boot_diagnostics {
    storage_account_uri = var.storage_bootdiag_endpoint
  }

  license_type = length(var.license_type) > 0 ? var.license_type : null

  tags = try(var.application.app_tags, {})

}

# Create the Windows Application VM(s)
resource "azurerm_windows_virtual_machine" "app" {
  provider            = azurerm.main
  count               = local.enable_deployment ? (upper(local.app_ostype) == "WINDOWS" ? local.application_server_count : 0) : 0
  name                = format("%s%s%s%s", local.prefix, var.naming.separator, var.naming.virtualmachine_names.APP_VMNAME[count.index], local.resource_suffixes.vm)
  computer_name       = var.naming.virtualmachine_names.APP_COMPUTERNAME[count.index]
  location            = var.resource_group[0].location
  resource_group_name = var.resource_group[0].name

  //If no ppg defined do not put the application servers in a proximity placement group
  proximity_placement_group_id = local.app_no_ppg ? (
    null) : (
    local.app_zonal_deployment ? var.ppg[count.index % max(local.app_zone_count, 1)].id : var.ppg[0].id
  )

  //If more than one servers are deployed into a single zone put them in an availability set and not a zone
  availability_set_id = local.use_app_avset ? (
    length(var.application.avset_arm_ids) > 0 ? (
      var.application.avset_arm_ids[count.index % max(local.app_zone_count, 1)]) : (
      azurerm_availability_set.app[count.index % max(local.app_zone_count, 1)].id
    )) : (
    null
  )
  //If length of zones > 1 distribute servers evenly across zones
  zone = local.use_app_avset ? null : local.app_zones[count.index % max(local.app_zone_count, 1)]

  network_interface_ids = var.application.dual_nics ? (
    var.options.legacy_nic_order ? (
      [azurerm_network_interface.app_admin[count.index].id, azurerm_network_interface.app[count.index].id]) : (
      [azurerm_network_interface.app[count.index].id, azurerm_network_interface.app_admin[count.index].id]
    )
    ) : (
    [azurerm_network_interface.app[count.index].id]
  )

  size           = length(local.app_size) > 0 ? local.app_size : local.app_sizing.compute.vm_size
  admin_username = var.sid_username
  admin_password = var.sid_password

  dynamic "os_disk" {
    iterator = disk
    for_each = flatten(
      [
        for storage_type in local.app_sizing.storage : [
          for disk_count in range(storage_type.count) :
          {
            name      = storage_type.name,
            id        = disk_count,
            disk_type = storage_type.disk_type,
            size_gb   = storage_type.size_gb,
            caching   = storage_type.caching
          }
        ]
        if storage_type.name == "os"
      ]
    )

    content {
      name                   = format("%s%s%s%s", local.prefix, var.naming.separator, var.naming.virtualmachine_names.APP_VMNAME[count.index], local.resource_suffixes.osdisk)
      caching                = disk.value.caching
      storage_account_type   = disk.value.disk_type
      disk_size_gb           = disk.value.size_gb
      disk_encryption_set_id = try(var.options.disk_encryption_set_id, null)
    }
  }

  source_image_id = local.app_custom_image ? local.app_os.source_image_id : null

  dynamic "source_image_reference" {
    for_each = range(local.app_custom_image ? 0 : 1)
    content {
      publisher = local.app_os.publisher
      offer     = local.app_os.offer
      sku       = local.app_os.sku
      version   = local.app_os.version
    }
  }

  boot_diagnostics {
    storage_account_uri = var.storage_bootdiag_endpoint
  }

  #ToDo: Remove once feature is GA  patch_mode = "Manual"
  license_type = length(var.license_type) > 0 ? var.license_type : null

  tags = try(var.application.app_tags, {})

}

# Creates managed data disk
resource "azurerm_managed_disk" "app" {
  provider               = azurerm.main
  count                  = local.enable_deployment ? length(local.app_data_disks) : 0
  name                   = format("%s%s%s%s", local.prefix, var.naming.separator, var.naming.virtualmachine_names.APP_VMNAME[local.app_data_disks[count.index].vm_index], local.app_data_disks[count.index].suffix)
  location               = var.resource_group[0].location
  resource_group_name    = var.resource_group[0].name
  create_option          = "Empty"
  storage_account_type   = local.app_data_disks[count.index].storage_account_type
  disk_size_gb           = local.app_data_disks[count.index].disk_size_gb
  disk_encryption_set_id = try(var.options.disk_encryption_set_id, null)

  zone = local.use_app_avset ? null : (
    upper(local.app_ostype) == "LINUX" ? (
      azurerm_linux_virtual_machine.app[local.app_data_disks[count.index].vm_index].zone) : (
      azurerm_windows_virtual_machine.app[local.app_data_disks[count.index].vm_index].zone
    )
  )


}

resource "azurerm_virtual_machine_data_disk_attachment" "app" {
  provider                  = azurerm.main
  count                     = local.enable_deployment ? length(local.app_data_disks) : 0
  managed_disk_id           = azurerm_managed_disk.app[count.index].id
  virtual_machine_id        = upper(local.app_ostype) == "LINUX" ? azurerm_linux_virtual_machine.app[local.app_data_disks[count.index].vm_index].id : azurerm_windows_virtual_machine.app[local.app_data_disks[count.index].vm_index].id
  caching                   = local.app_data_disks[count.index].caching
  write_accelerator_enabled = local.app_data_disks[count.index].write_accelerator_enabled
  lun                       = local.app_data_disks[count.index].lun
}


# VM Extension 
resource "azurerm_virtual_machine_extension" "app_lnx_aem_extension" {
  provider             = azurerm.main
  count                = local.enable_deployment ? (upper(local.app_ostype) == "LINUX" ? local.application_server_count : 0) : 0
  name                 = "MonitorX64Linux"
  virtual_machine_id   = azurerm_linux_virtual_machine.app[count.index].id
  publisher            = "Microsoft.AzureCAT.AzureEnhancedMonitoring"
  type                 = "MonitorX64Linux"
  type_handler_version = "1.0"
  settings             = <<SETTINGS
  {
    "system": "SAP"
  }
SETTINGS
}


resource "azurerm_virtual_machine_extension" "app_win_aem_extension" {
  provider             = azurerm.main
  count                = local.enable_deployment ? (upper(local.app_ostype) == "WINDOWS" ? local.application_server_count : 0) : 0
  name                 = "MonitorX64Windows"
  virtual_machine_id   = azurerm_windows_virtual_machine.app[count.index].id
  publisher            = "Microsoft.AzureCAT.AzureEnhancedMonitoring"
  type                 = "MonitorX64Windows"
  type_handler_version = "1.0"
  settings             = <<SETTINGS
  {
    "system": "SAP"
  }
SETTINGS
}
