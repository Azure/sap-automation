#########################################################################################
#                                                                                       #
#  Primary Network Interface                                                            #
#                                                                                       #
#########################################################################################

resource "azurerm_network_interface" "app" {
  provider = azurerm.main
  count    = local.enable_deployment ? local.application_server_count : 0
  name = format("%s%s%s%s%s",
    var.naming.resource_prefixes.nic,
    local.prefix,
    var.naming.separator,
    var.naming.virtualmachine_names.APP_VMNAME[count.index],
    local.resource_suffixes.nic
  )
  location                      = var.resource_group[0].location
  resource_group_name           = var.resource_group[0].name
  enable_accelerated_networking = local.app_sizing.compute.accelerated_networking

  dynamic "ip_configuration" {
    iterator = pub
    for_each = local.application_ips
    content {
      name      = pub.value.name
      subnet_id = pub.value.subnet_id
      private_ip_address = try(pub.value.nic_ips[count.index],
        var.application_tier.use_DHCP ? (
          null) : (
          cidrhost(local.application_subnet_exists ?
            data.azurerm_subnet.subnet_sap_app[0].address_prefixes[0] :
            azurerm_subnet.subnet_sap_app[0].address_prefixes[0],
            tonumber(count.index) + local.ip_offsets.app_vm + pub.value.offset
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
  lifecycle {
    ignore_changes = [tags]
  }
}

resource "azurerm_network_interface_application_security_group_association" "app" {

  provider = azurerm.main
  count = local.enable_deployment ? (
    var.deploy_application_security_groups ? local.application_server_count : 0) : (
    0
  )
  network_interface_id          = azurerm_network_interface.app[count.index].id
  application_security_group_id = azurerm_application_security_group.app[0].id
}


#########################################################################################
#                                                                                       #
#  Admin Network Interface                                                              #
#                                                                                       #
#########################################################################################

resource "azurerm_network_interface" "app_admin" {
  provider = azurerm.main
  count = local.enable_deployment && var.application_tier.dual_nics && length(try(var.admin_subnet.id, "")) > 0 ? (
    local.application_server_count) : (
    0
  )
  name = format("%s%s%s%s%s",
    var.naming.resource_prefixes.admin_nic,
    local.prefix,
    var.naming.separator,
    var.naming.virtualmachine_names.APP_VMNAME[count.index],
    local.resource_suffixes.admin_nic
  )
  location                      = var.resource_group[0].location
  resource_group_name           = var.resource_group[0].name
  enable_accelerated_networking = local.app_sizing.compute.accelerated_networking

  ip_configuration {
    name      = "IPConfig1"
    subnet_id = var.admin_subnet.id
    private_ip_address = try(local.app_admin_nic_ips[count.index], var.application_tier.use_DHCP ? (
      null) : (
      cidrhost(
        var.admin_subnet.address_prefixes[0],
        tonumber(count.index) + local.admin_ip_offsets.app_vm
      )
      )
    )
    private_ip_address_allocation = length(try(local.app_admin_nic_ips[count.index], "")) > 0 ? (
      "Static") : (
      "Dynamic"
    )
  }

}

# Create the Linux Application VM(s)
resource "azurerm_linux_virtual_machine" "app" {
  provider   = azurerm.main
  depends_on = [azurerm_linux_virtual_machine.scs, azurerm_windows_virtual_machine.scs]
  count = local.enable_deployment && upper(var.application_tier.app_os.os_type) == "LINUX" ? (
    local.application_server_count) : (
    0
  )

  name = format("%s%s%s%s%s",
    var.naming.resource_prefixes.vm,
    local.prefix,
    var.naming.separator,
    var.naming.virtualmachine_names.APP_VMNAME[count.index],
    local.resource_suffixes.vm
  )
  computer_name       = var.naming.virtualmachine_names.APP_COMPUTERNAME[count.index]
  location            = var.resource_group[0].location
  resource_group_name = var.resource_group[0].name

  proximity_placement_group_id = var.application_tier.app_use_ppg ? (
    local.app_zonal_deployment ? var.ppg[count.index % max(local.app_zone_count, 1)] : var.ppg[0]) : (
    null
  )

  //If more than one servers are deployed into a single zone put them in an availability set and not a zone
  availability_set_id = local.use_app_avset ? (
    length(var.application_tier.avset_arm_ids) > 0 ? (
      var.application_tier.avset_arm_ids[count.index % max(local.app_zone_count, 1)]) : (
      azurerm_availability_set.app[count.index % max(local.app_zone_count, 1)].id
    )) : (
    null
  )

  virtual_machine_scale_set_id = length(var.scale_set_id) > 0 ? var.scale_set_id : null

  //If length of zones > 1 distribute servers evenly across zones
  zone = var.application_tier.app_use_avset ? null : try(local.app_zones[count.index % max(local.app_zone_count, 1)], null)

  network_interface_ids = var.application_tier.dual_nics ? (
    var.options.legacy_nic_order ? (
      [
        azurerm_network_interface.app_admin[count.index].id,
        azurerm_network_interface.app[count.index].id
      ]) : (
      [
        azurerm_network_interface.app[count.index].id,
        azurerm_network_interface.app_admin[count.index].id
      ]
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
      name = format("%s%s%s%s%s",
        var.naming.resource_prefixes.osdisk,
        local.prefix,
        var.naming.separator,
        var.naming.virtualmachine_names.APP_VMNAME[count.index],
        local.resource_suffixes.osdisk
      )
      caching                = disk.value.caching
      storage_account_type   = disk.value.disk_type
      disk_size_gb           = disk.value.size_gb
      disk_encryption_set_id = try(var.options.disk_encryption_set_id, null)
    }
  }

  source_image_id = var.application_tier.app_os.type == "custom" ? var.application_tier.app_os.source_image_id : null

  dynamic "source_image_reference" {
    for_each = range(var.application_tier.app_os.type == "marketplace" || var.application_tier.app_os.type == "marketplace_with_plan" ? 1 : 0)
    content {
      publisher = var.application_tier.app_os.publisher
      offer     = var.application_tier.app_os.offer
      sku       = var.application_tier.app_os.sku
      version   = var.application_tier.app_os.version
    }
  }

  dynamic "plan" {
    for_each = range(var.application_tier.app_os.type == "marketplace_with_plan" ? 1 : 0)
    content {
      name      = var.application_tier.app_os.sku
      publisher = var.application_tier.app_os.publisher
      product   = var.application_tier.app_os.offer
    }
  }

  boot_diagnostics {
    storage_account_uri = var.storage_bootdiag_endpoint
  }

  license_type = length(var.license_type) > 0 ? var.license_type : null

  tags = try(var.application_tier.app_tags, {})

  lifecycle {
    ignore_changes = [tags]
  }
}

# Create the Windows Application VM(s)
resource "azurerm_windows_virtual_machine" "app" {
  provider = azurerm.main
  count = local.enable_deployment && upper(var.application_tier.app_os.os_type) == "WINDOWS" ? (
    local.application_server_count) : (
    0
  )
  name = format("%s%s%s%s%s",
    var.naming.resource_prefixes.vm,
    local.prefix,
    var.naming.separator,
    var.naming.virtualmachine_names.APP_VMNAME[count.index],
    local.resource_suffixes.vm
  )
  computer_name       = var.naming.virtualmachine_names.APP_COMPUTERNAME[count.index]
  location            = var.resource_group[0].location
  resource_group_name = var.resource_group[0].name

  proximity_placement_group_id = var.application_tier.app_use_ppg ? (
    local.app_zonal_deployment ? var.ppg[count.index % max(local.app_zone_count, 1)] : var.ppg[0]) : (
    null
  )

  //If more than one servers are deployed into a single zone put them in an availability set and not a zone
  availability_set_id = local.use_app_avset ? (
    length(var.application_tier.avset_arm_ids) > 0 ? (
      var.application_tier.avset_arm_ids[count.index % max(local.app_zone_count, 1)]) : (
      azurerm_availability_set.app[count.index % max(local.app_zone_count, 1)].id
    )) : (
    null
  )

  virtual_machine_scale_set_id = length(var.scale_set_id) > 0 ? var.scale_set_id : null
  //If length of zones > 1 distribute servers evenly across zones
  zone = var.application_tier.app_use_avset ? null : try(local.app_zones[count.index % max(local.app_zone_count, 1)], null)

  network_interface_ids = var.application_tier.dual_nics ? (
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
            size_gb   = storage_type.size_gb < 128 ? 128 : storage_type.size_gb,
            caching   = storage_type.caching
          }
        ]
        if storage_type.name == "os"
      ]
    )

    content {
      name                   = format("%s%s%s%s%s", var.naming.resource_prefixes.osdisk, local.prefix, var.naming.separator, var.naming.virtualmachine_names.APP_VMNAME[count.index], local.resource_suffixes.osdisk)
      caching                = disk.value.caching
      storage_account_type   = disk.value.disk_type
      disk_size_gb           = disk.value.size_gb
      disk_encryption_set_id = try(var.options.disk_encryption_set_id, null)
    }
  }

  source_image_id = var.application_tier.app_os.type == "custom" ? var.application_tier.app_os.source_image_id : null

  dynamic "source_image_reference" {
    for_each = range(var.application_tier.app_os.type == "marketplace" || var.application_tier.app_os.type == "marketplace_with_plan" ? 1 : 0)
    content {
      publisher = var.application_tier.app_os.publisher
      offer     = var.application_tier.app_os.offer
      sku       = var.application_tier.app_os.sku
      version   = var.application_tier.app_os.version
    }
  }

  dynamic "plan" {
    for_each = range(var.application_tier.app_os.type == "marketplace_with_plan" ? 1 : 0)
    content {
      name      = var.application_tier.app_os.sku
      publisher = var.application_tier.app_os.publisher
      product   = var.application_tier.app_os.offer
    }
  }

  boot_diagnostics {
    storage_account_uri = var.storage_bootdiag_endpoint
  }

  #ToDo: Remove once feature is GA  patch_mode = "Manual"
  license_type = length(var.license_type) > 0 ? var.license_type : null

  tags = try(var.application_tier.app_tags, {})

  lifecycle {
    ignore_changes = [tags]
  }
}

# Creates managed data disk
resource "azurerm_managed_disk" "app" {
  provider = azurerm.main
  count    = local.enable_deployment ? length(local.app_data_disks) : 0
  name = format("%s%s%s%s%s",
    var.naming.resource_prefixes.disk,
    local.prefix,
    var.naming.separator,
    var.naming.virtualmachine_names.APP_VMNAME[local.app_data_disks[count.index].vm_index],
    local.app_data_disks[count.index].suffix
  )
  location               = var.resource_group[0].location
  resource_group_name    = var.resource_group[0].name
  create_option          = "Empty"
  storage_account_type   = local.app_data_disks[count.index].storage_account_type
  disk_size_gb           = local.app_data_disks[count.index].disk_size_gb
  disk_encryption_set_id = try(var.options.disk_encryption_set_id, null)

  zone = var.application_tier.app_use_avset ? null : (
    upper(var.application_tier.app_os.os_type) == "LINUX" ? (
      azurerm_linux_virtual_machine.app[local.app_data_disks[count.index].vm_index].zone) : (
      azurerm_windows_virtual_machine.app[local.app_data_disks[count.index].vm_index].zone
    )
  )
  lifecycle {
    ignore_changes = [tags]
  }
}

resource "azurerm_virtual_machine_data_disk_attachment" "app" {
  provider        = azurerm.main
  count           = local.enable_deployment ? length(local.app_data_disks) : 0
  managed_disk_id = azurerm_managed_disk.app[count.index].id
  virtual_machine_id = upper(var.application_tier.app_os.os_type) == "LINUX" ? (
    azurerm_linux_virtual_machine.app[local.app_data_disks[count.index].vm_index].id) : (
    azurerm_windows_virtual_machine.app[local.app_data_disks[count.index].vm_index].id
  )
  caching                   = local.app_data_disks[count.index].caching
  write_accelerator_enabled = local.app_data_disks[count.index].write_accelerator_enabled
  lun                       = local.app_data_disks[count.index].lun
}


# VM Extension
resource "azurerm_virtual_machine_extension" "app_lnx_aem_extension" {
  provider = azurerm.main
  count = local.enable_deployment && var.application_tier.deploy_v1_monitoring_extension && upper(var.application_tier.app_os.os_type) == "LINUX" ? (
    local.application_server_count) : (
    0
  )
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

  lifecycle {
    ignore_changes = [tags]
  }
}


resource "azurerm_virtual_machine_extension" "app_win_aem_extension" {
  provider = azurerm.main
  count = local.enable_deployment && var.application_tier.deploy_v1_monitoring_extension && upper(var.application_tier.app_os.os_type) == "WINDOWS" ? (
    local.application_server_count) : (
    0
  )
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

resource "azurerm_virtual_machine_extension" "configure_ansible_app" {

  provider = azurerm.main
  count = local.enable_deployment && upper(var.application_tier.app_os.os_type) == "WINDOWS" ? (
    local.application_server_count) : (
    0
  )

  depends_on = [azurerm_virtual_machine_data_disk_attachment.app]

  name                 = "configure_ansible"
  virtual_machine_id   = azurerm_windows_virtual_machine.app[count.index].id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.9"
  settings             = <<SETTINGS
        {
          "fileUris": ["https://raw.githubusercontent.com/Azure/sap-automation/main/deploy/scripts/configure_ansible.ps1"],
          "commandToExecute": "powershell.exe -ExecutionPolicy Unrestricted -File configure_ansible.ps1 -Verbose"
        }
    SETTINGS
}
