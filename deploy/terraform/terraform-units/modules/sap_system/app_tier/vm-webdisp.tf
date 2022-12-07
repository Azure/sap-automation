#########################################################################################
#                                                                                       #
#  Primary Network Interface                                                            #
#                                                                                       #
#########################################################################################
resource "azurerm_network_interface" "web" {
  provider = azurerm.main
  count    = local.enable_deployment ? local.webdispatcher_count : 0
  name = format("%s%s%s%s%s",
    var.naming.resource_prefixes.nic,
    local.prefix,
    var.naming.separator,
    var.naming.virtualmachine_names.WEB_VMNAME[count.index],
    local.resource_suffixes.nic
  )
  location                      = var.resource_group[0].location
  resource_group_name           = var.resource_group[0].name
  enable_accelerated_networking = local.web_sizing.compute.accelerated_networking

  dynamic "ip_configuration" {
    iterator = pub
    for_each = local.web_dispatcher_ips
    content {
      name      = pub.value.name
      subnet_id = pub.value.subnet_id

      private_ip_address = try(pub.value.nic_ips[count.index],
        var.application_tier.use_DHCP ? (
          null) : (
          local.web_subnet_defined ?
          cidrhost(
            local.web_subnet_prefix,
            (tonumber(count.index) + local.ip_offsets.web_vm + pub.value.offset)
          ) :
          cidrhost(
            local.application_subnet_prefix,
            (tonumber(count.index) * -1 + local.ip_offsets.web_vm + pub.value.offset)
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

resource "azurerm_network_interface_application_security_group_association" "web" {
  count = local.enable_deployment ? (
    var.deploy_application_security_groups ? local.webdispatcher_count : 0) : (
    0
  )

  network_interface_id          = azurerm_network_interface.web[count.index].id
  application_security_group_id = azurerm_application_security_group.web[0].id
}


#########################################################################################
#                                                                                       #
#  Admin Network Interface                                                              #
#                                                                                       #
#########################################################################################

resource "azurerm_network_interface" "web_admin" {
  provider = azurerm.main
  count = local.enable_deployment && var.application_tier.dual_nics && length(try(var.admin_subnet.id, "")) > 0 ? (
    local.webdispatcher_count) : (
    0
  )
  name = format("%s%s%s%s%s",
    var.naming.resource_prefixes.admin_nic,
    local.prefix,
    var.naming.separator,
    var.naming.virtualmachine_names.WEB_VMNAME[count.index],
    local.resource_suffixes.admin_nic
  )
  location                      = var.resource_group[0].location
  resource_group_name           = var.resource_group[0].name
  enable_accelerated_networking = local.app_sizing.compute.accelerated_networking

  ip_configuration {
    name      = "IPConfig1"
    subnet_id = var.admin_subnet.id
    private_ip_address = try(local.web_admin_nic_ips[count.index], var.application_tier.use_DHCP ? (
      null) : (
      cidrhost(
        var.admin_subnet.address_prefixes[0],
        tonumber(count.index) + local.admin_ip_offsets.web_vm
      )
      )
    )
    private_ip_address_allocation = length(try(local.web_admin_nic_ips[count.index], "")) > 0 ? (
      "Static") : (
      "Dynamic"
    )
  }
}

# Create the Linux Web dispatcher VM(s)
resource "azurerm_linux_virtual_machine" "web" {
  provider = azurerm.main
  count = local.enable_deployment && upper(var.application_tier.web_os.os_type) == "LINUX" ? (
    local.webdispatcher_count) : (
    0
  )
  name = format("%s%s%s%s%s",
    var.naming.resource_prefixes.vm,
    local.prefix,
    var.naming.separator,
    var.naming.virtualmachine_names.WEB_VMNAME[count.index],
    local.resource_suffixes.vm
  )
  computer_name       = var.naming.virtualmachine_names.WEB_COMPUTERNAME[count.index]
  location            = var.resource_group[0].location
  resource_group_name = var.resource_group[0].name

  //If no ppg defined do not put the web dispatchers in a proximity placement group
  proximity_placement_group_id = local.web_no_ppg ? (
    null) : (
    local.web_zonal_deployment ? (
      var.ppg[count.index % max(local.web_zone_count, 1)].id) : (
      var.ppg[0].id
    )
  )

  //If more than one servers are deployed into a single zone put them in an availability set and not a zone
  availability_set_id = local.use_web_avset ? (
    azurerm_availability_set.web[count.index % max(local.web_zone_count, 1)].id) : (
    null
  )

  //If length of zones > 1 distribute servers evenly across zones
  zone = local.use_web_avset ? null : try(local.web_zones[count.index % max(local.web_zone_count, 1)], null)

  network_interface_ids = var.application_tier.dual_nics ? (
    var.options.legacy_nic_order ? (
      [
        azurerm_network_interface.scs_admin[count.index].id,
        azurerm_network_interface.scs[count.index].id
      ]) : (
      [
        azurerm_network_interface.scs[count.index].id,
        azurerm_network_interface.scs_admin[count.index].id
      ]
    )
    ) : (
    [azurerm_network_interface.web[count.index].id]
  )

  size = length(local.web_size) > 0 ? (
    local.web_size) : (
    local.web_sizing.compute.vm_size
  )
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
        for storage_type in local.web_sizing.storage : [
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
        var.naming.virtualmachine_names.WEB_VMNAME[count.index],
        local.resource_suffixes.osdisk
      )
      caching                = disk.value.caching
      storage_account_type   = disk.value.disk_type
      disk_size_gb           = disk.value.size_gb
      disk_encryption_set_id = try(var.options.disk_encryption_set_id, null)
    }
  }

  source_image_id = var.application_tier.web_os.type == "custom" ? var.application_tier.web_os.source_image_id : null

  dynamic "source_image_reference" {
    for_each = range(var.application_tier.web_os.type == "marketplace" ? 1 : 0)
    content {
      publisher = var.application_tier.web_os.publisher
      offer     = var.application_tier.web_os.offer
      sku       = var.application_tier.web_os.sku
      version   = var.application_tier.web_os.version
    }
  }
  dynamic "plan" {
    for_each = range(var.application_tier.web_os.type == "marketplace_with_plan" ? 1 : 0)
    content {
      name      = var.application_tier.web_os.offer
      publisher = var.application_tier.web_os.publisher
      product   = var.application_tier.web_os.sku
    }
  }

  boot_diagnostics {
    storage_account_uri = var.storage_bootdiag_endpoint
  }

  license_type = length(var.license_type) > 0 ? var.license_type : null

  tags = try(var.application_tier.web_tags, {})

  lifecycle {
    ignore_changes = [tags]
  }
}

# Create the Windows Web dispatcher VM(s)
resource "azurerm_windows_virtual_machine" "web" {
  provider = azurerm.main
  count = local.enable_deployment && upper(var.application_tier.web_os.os_type) == "WINDOWS" ? (
    local.webdispatcher_count) : (
    0
  )
  name = format("%s%s%s%s%s",
    var.naming.resource_prefixes.vm,
    local.prefix,
    var.naming.separator,
    var.naming.virtualmachine_names.WEB_VMNAME[count.index],
    local.resource_suffixes.vm
  )
  computer_name       = var.naming.virtualmachine_names.WEB_COMPUTERNAME[count.index]
  location            = var.resource_group[0].location
  resource_group_name = var.resource_group[0].name

  //If no ppg defined do not put the web dispatchers in a proximity placement group
  proximity_placement_group_id = local.web_no_ppg ? (
    null) : (
    local.web_zonal_deployment ? (
      var.ppg[count.index % max(local.web_zone_count, 1)].id) : (
      var.ppg[0].id
    )
  )

  //If more than one servers are deployed into a single zone put them in an availability set and not a zone
  availability_set_id = local.use_web_avset ? (
    azurerm_availability_set.web[count.index % max(local.web_zone_count, 1)].id) : (
    null
  )

  //If length of zones > 1 distribute servers evenly across zones
  zone = local.use_web_avset ? (
    null) : (
    try(local.web_zones[count.index % max(local.web_zone_count, 1)], null)
  )

  network_interface_ids = var.application_tier.dual_nics ? (
    var.options.legacy_nic_order ? (
      [
        azurerm_network_interface.web_admin[count.index].id,
        azurerm_network_interface.web[count.index].id
      ]) : (
      [
        azurerm_network_interface.web[count.index].id,
        azurerm_network_interface.web_admin[count.index].id
      ]
    )
    ) : (
    [azurerm_network_interface.web[count.index].id]
  )

  size           = local.web_sizing.compute.vm_size
  admin_username = var.sid_username
  admin_password = var.sid_password

  dynamic "os_disk" {
    iterator = disk
    for_each = flatten(
      [
        for storage_type in local.web_sizing.storage : [
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
        var.naming.virtualmachine_names.WEB_VMNAME[count.index],
        local.resource_suffixes.osdisk
      )
      caching                = disk.value.caching
      storage_account_type   = disk.value.disk_type
      disk_size_gb           = disk.value.size_gb
      disk_encryption_set_id = try(var.options.disk_encryption_set_id, null)
    }
  }

  source_image_id = var.application_tier.web_os.type == "custom" ? var.application_tier.web_os.source_image_id : null

  dynamic "source_image_reference" {
    for_each = range(var.application_tier.web_os.type == "marketplace" ? 1 : 0)
    content {
      publisher = var.application_tier.web_os.publisher
      offer     = var.application_tier.web_os.offer
      sku       = var.application_tier.web_os.sku
      version   = var.application_tier.web_os.version
    }
  }
  dynamic "plan" {
    for_each = range(var.application_tier.web_os.type == "marketplace_with_plan" ? 1 : 0)
    content {
      name      = var.application_tier.web_os.offer
      publisher = var.application_tier.web_os.publisher
      product   = var.application_tier.web_os.sku
    }
  }

  boot_diagnostics {
    storage_account_uri = var.storage_bootdiag_endpoint
  }


  #ToDo: Remove once feature is GA  patch_mode = "Manual"
  license_type = length(var.license_type) > 0 ? var.license_type : null

  tags = try(var.application_tier.web_tags, {})
}

# Creates managed data disk
resource "azurerm_managed_disk" "web" {
  provider = azurerm.main
  count    = local.enable_deployment ? length(local.web_data_disks) : 0
  name = format("%s%s%s%s%s",
    var.naming.resource_prefixes.disk,
    local.prefix,
    var.naming.separator,
    var.naming.virtualmachine_names.WEB_VMNAME[local.web_data_disks[count.index].vm_index],
    local.web_data_disks[count.index].suffix
  )
  location               = var.resource_group[0].location
  resource_group_name    = var.resource_group[0].name
  create_option          = "Empty"
  storage_account_type   = local.web_data_disks[count.index].storage_account_type
  disk_size_gb           = local.web_data_disks[count.index].disk_size_gb
  disk_encryption_set_id = try(var.options.disk_encryption_set_id, null)

  zone = !local.use_web_avset ? (
    upper(var.application_tier.web_os.os_type) == "LINUX" ? (
      azurerm_linux_virtual_machine.web[local.web_data_disks[count.index].vm_index].zone) : (
      azurerm_windows_virtual_machine.web[local.web_data_disks[count.index].vm_index].zone
    )) : (
    null
  )

  lifecycle {
    ignore_changes = [tags]
  }
}

resource "azurerm_virtual_machine_data_disk_attachment" "web" {
  provider        = azurerm.main
  count           = local.enable_deployment ? length(local.web_data_disks) : 0
  managed_disk_id = azurerm_managed_disk.web[count.index].id
  virtual_machine_id = upper(var.application_tier.web_os.os_type) == "LINUX" ? (
    azurerm_linux_virtual_machine.web[local.web_data_disks[count.index].vm_index].id) : (
    azurerm_windows_virtual_machine.web[local.web_data_disks[count.index].vm_index].id
  )
  caching                   = local.web_data_disks[count.index].caching
  write_accelerator_enabled = local.web_data_disks[count.index].write_accelerator_enabled
  lun                       = local.web_data_disks[count.index].lun
}

resource "azurerm_virtual_machine_extension" "web_lnx_aem_extension" {
  provider = azurerm.main
  count = local.enable_deployment && upper(var.application_tier.web_os.os_type) == "LINUX" ? (
    local.webdispatcher_count) : (
    0
  )
  name                 = "MonitorX64Linux"
  virtual_machine_id   = azurerm_linux_virtual_machine.web[count.index].id
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


resource "azurerm_virtual_machine_extension" "web_win_aem_extension" {
  provider = azurerm.main
  count = local.enable_deployment && upper(var.application_tier.web_os.os_type) == "WINDOWS" ? (
    local.webdispatcher_count) : (
    0
  )
  name                 = "MonitorX64Windows"
  virtual_machine_id   = azurerm_windows_virtual_machine.web[count.index].id
  publisher            = "Microsoft.AzureCAT.AzureEnhancedMonitoring"
  type                 = "MonitorX64Windows"
  type_handler_version = "1.0"
  settings             = <<SETTINGS
  {
    "system": "SAP"
  }
SETTINGS
}

resource "azurerm_virtual_machine_extension" "configure_ansible_web" {

  provider = azurerm.main
  count = local.enable_deployment && upper(var.application_tier.web_os.os_type) == "WINDOWS" ? (
    local.webdispatcher_count) : (
    0
  )
  virtual_machine_id   = azurerm_windows_virtual_machine.web[count.index].id
  name                 = "configure_ansible"
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

