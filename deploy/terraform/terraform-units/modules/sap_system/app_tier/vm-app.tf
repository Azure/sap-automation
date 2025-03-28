# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.


#######################################4#######################################8
#                                                                              #
#                           Primary Network Interface                          #
#                                                                              #
#######################################4#######################################8

resource "azurerm_network_interface" "app" {
  provider                             = azurerm.main
  count                                = local.enable_deployment ? local.application_server_count : 0
  name                                 = format("%s%s%s%s%s",
                                           var.naming.resource_prefixes.nic,
                                           local.prefix,
                                           var.naming.separator,
                                           var.naming.virtualmachine_names.APP_VMNAME[count.index],
                                           local.resource_suffixes.nic
                                         )
  location                             = var.resource_group[0].location
  resource_group_name                  = var.resource_group[0].name
  accelerated_networking_enabled        = local.app_sizing.compute.accelerated_networking
  tags                                 = var.tags

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
}

resource "azurerm_network_interface_application_security_group_association" "app" {
  provider                             = azurerm.main
  count                                = local.enable_deployment ? (
                                           var.deploy_application_security_groups ? local.application_server_count : 0) : (
                                           0
                                         )
  network_interface_id                 = var.use_admin_nic_for_asg && var.application_tier.dual_nics ? azurerm_network_interface.app_admin[count.index].id : azurerm_network_interface.app[count.index].id
  application_security_group_id        = azurerm_application_security_group.app[0].id
}

#######################################4#######################################8
#                                                                              #
#                            Admin Network Interface                           #
#                                                                              #
#######################################4#######################################8

resource "azurerm_network_interface" "app_admin" {
  provider                             = azurerm.main
  count                                = local.enable_deployment && var.application_tier.dual_nics && length(try(var.admin_subnet.id, "")) > 0 ? (
                                           local.application_server_count) : (
                                           0
                                         )
  name                                 = format("%s%s%s%s%s",
                                           var.naming.resource_prefixes.admin_nic,
                                           local.prefix,
                                           var.naming.separator,
                                           var.naming.virtualmachine_names.APP_VMNAME[count.index],
                                           local.resource_suffixes.admin_nic
                                         )
  location                             = var.resource_group[0].location
  resource_group_name                  = var.resource_group[0].name
  accelerated_networking_enabled        = local.app_sizing.compute.accelerated_networking
  tags                                 = var.tags

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
  provider                             = azurerm.main
  count                                = local.enable_deployment && upper(var.application_tier.app_os.os_type) == "LINUX" ? (
                                           local.application_server_count) : (
                                           0
                                         )
  depends_on                           = [azurerm_virtual_machine_data_disk_attachment.scs, azurerm_availability_set.app]
  name                                 = format("%s%s%s%s%s",
                                           var.naming.resource_prefixes.vm,
                                           local.prefix,
                                           var.naming.separator,
                                           var.naming.virtualmachine_names.APP_VMNAME[count.index],
                                           local.resource_suffixes.vm
                                         )
  computer_name                        = var.naming.virtualmachine_names.APP_COMPUTERNAME[count.index]

  source_image_id                      = var.application_tier.app_os.type == "custom" ? var.application_tier.app_os.source_image_id : null

  license_type                         = length(var.license_type) > 0 ? var.license_type : null
  # ToDo Add back later
# patch_mode                           = var.infrastructure.patch_mode

  custom_data                          = var.deployment == "new" ? var.cloudinit_growpart_config : null
  location                             = var.resource_group[0].location
  resource_group_name                  = var.resource_group[0].name

  proximity_placement_group_id         = var.application_tier.app_use_avset || length(var.scale_set_id) > 0 ? (
                                           null) : (
                                           var.application_tier.app_use_ppg ? (
                                             var.ppg[count.index % max(length(var.ppg), 1)]) : (
                                             null)
                                            )

  //If more than one servers are deployed into a single zone put them in an availability set and not a zone
  availability_set_id                  = var.application_tier.app_use_avset ? (
                                           try(length(var.application_tier.avset_arm_ids) > 0 ? (
                                             var.application_tier.avset_arm_ids[count.index % max(length(var.application_tier.avset_arm_ids), 1)]) : (
                                             azurerm_availability_set.app[count.index % max(length(var.ppg), 1)].id
                                           ), null)) : (
                                           null
                                         )


  virtual_machine_scale_set_id         = length(var.scale_set_id) > 0 ? var.scale_set_id : null

  patch_mode                                             = var.infrastructure.patch_mode

  patch_assessment_mode                                  = var.infrastructure.patch_assessment_mode
  bypass_platform_safety_checks_on_user_schedule_enabled = var.infrastructure.patch_mode != "AutomaticByPlatform" ? false : true
  vm_agent_platform_updates_enabled                      = var.infrastructure.platform_updates

  //If length of zones > 1 distribute servers evenly across zones
  zone                                 = var.application_tier.app_use_avset ? null : try(local.app_zones[count.index % max(local.app_zone_count, 1)], null)

  network_interface_ids                = var.application_tier.dual_nics ? (
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

  size                                 = length(local.app_size) > 0 ? local.app_size : local.app_sizing.compute.vm_size
  admin_username                       = var.sid_username
  admin_password                       = local.enable_auth_key ? null : var.sid_password
  disable_password_authentication      = !local.enable_auth_password

  tags             =  merge(var.application_tier.app_tags, var.tags)

  encryption_at_host_enabled           = var.infrastructure.encryption_at_host_enabled

  dynamic "admin_ssh_key" {
                            for_each = range(var.deployment == "new" ? 1 : (local.enable_auth_password ? 0 : 1))
                            content {
                              username   = var.sid_username
                              public_key = var.sdu_public_key
                            }
                          }

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

  dynamic "identity"   {
                         for_each = range(length(var.application_tier.user_assigned_identity_id) > 0 ? 1 : 0)
                         content {
                                   type         = "UserAssigned"
                                   identity_ids = [var.application_tier.user_assigned_identity_id]
                                 }
                       }
  lifecycle {
    ignore_changes = [
      source_image_id,
      proximity_placement_group_id,
      zone
    ]
  }

}

# Create the Windows Application VM(s)
resource "azurerm_windows_virtual_machine" "app" {
  provider                             = azurerm.main
  count                                = local.enable_deployment && upper(var.application_tier.app_os.os_type) == "WINDOWS" ? (
                                           local.application_server_count) : (
                                           0
                                         )
  depends_on                           = [azurerm_virtual_machine_data_disk_attachment.scs]
  name                                 = format("%s%s%s%s%s",
                                           var.naming.resource_prefixes.vm,
                                           local.prefix,
                                           var.naming.separator,
                                           var.naming.virtualmachine_names.APP_VMNAME[count.index],
                                           local.resource_suffixes.vm
                                         )
  computer_name                        = var.naming.virtualmachine_names.APP_COMPUTERNAME[count.index]
  location                             = var.resource_group[0].location
  resource_group_name                  = var.resource_group[0].name
  source_image_id                      = var.application_tier.app_os.type == "custom" ? var.application_tier.app_os.source_image_id : null


  proximity_placement_group_id         = var.application_tier.app_use_avset || length(var.scale_set_id) > 0 ? (
                                           null) : (
                                           var.application_tier.app_use_ppg ? (
                                             var.ppg[count.index % max(length(var.ppg), 1)]) : (
                                             null)
                                            )


  //If more than one servers are deployed into a single zone put them in an availability set and not a zone
  availability_set_id                  = var.application_tier.app_use_avset ? (
                                           try(length(var.application_tier.avset_arm_ids) > 0 ? (
                                             var.application_tier.avset_arm_ids[count.index % max(length(var.application_tier.avset_arm_ids), 1)]) : (
                                             azurerm_availability_set.app[count.index % max(length(var.ppg), 1)].id
                                           ), null)) : (
                                           null
                                         )


  virtual_machine_scale_set_id         = length(var.scale_set_id) > 0 ? var.scale_set_id : null

  // ImageDefault = Manual on Windows
  // https://learn.microsoft.com/en-us/azure/virtual-machines/automatic-vm-guest-patching#patch-orchestration-modes
  patch_mode                                             = var.infrastructure.patch_mode == "ImageDefault" ? "Manual" : var.infrastructure.patch_mode
  enable_automatic_updates                               = !(var.infrastructure.patch_mode == "ImageDefault")
  patch_assessment_mode                                  = var.infrastructure.patch_assessment_mode
  bypass_platform_safety_checks_on_user_schedule_enabled = var.infrastructure.patch_mode != "AutomaticByPlatform" ? false : true
  vm_agent_platform_updates_enabled                      = var.infrastructure.platform_updates

  //If length of zones > 1 distribute servers evenly across zones
  zone                                 = var.application_tier.app_use_avset ? null : try(local.app_zones[count.index % max(local.app_zone_count, 1)], null)

  network_interface_ids                = var.application_tier.dual_nics ? (
                                           var.options.legacy_nic_order ? (
                                             [azurerm_network_interface.app_admin[count.index].id, azurerm_network_interface.app[count.index].id]) : (
                                             [azurerm_network_interface.app[count.index].id, azurerm_network_interface.app_admin[count.index].id]
                                           )
                                           ) : (
                                           [azurerm_network_interface.app[count.index].id]
                                         )

  size                                 = length(local.app_size) > 0 ? local.app_size : local.app_sizing.compute.vm_size
  admin_username                       = var.sid_username
  admin_password                       = var.sid_password

  license_type                         = length(var.license_type) > 0 ? var.license_type : null

  tags                                 = merge(var.application_tier.app_tags, var.tags)

  encryption_at_host_enabled           = var.infrastructure.encryption_at_host_enabled

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
                        name                    = format("%s%s%s%s%s",
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
  dynamic "identity"   {
                         for_each = range(length(var.application_tier.user_assigned_identity_id) > 0 ? 1 : 0)
                         content {
                                   type         = "UserAssigned"
                                   identity_ids = [var.application_tier.user_assigned_identity_id]
                                 }
                       }
  lifecycle {
    ignore_changes = [
      // Ignore changes to computername
      source_image_id,
      zone
    ]
  }

}

# Creates managed data disk
resource "azurerm_managed_disk" "app" {
  provider                             = azurerm.main
  count                                = local.enable_deployment ? length(local.app_data_disks) : 0
  name                                 = format("%s%s%s%s%s",
                                           var.naming.resource_prefixes.disk,
                                           local.prefix,
                                           var.naming.separator,
                                           var.naming.virtualmachine_names.APP_VMNAME[local.app_data_disks[count.index].vm_index],
                                           local.app_data_disks[count.index].suffix
                                         )
  location                             = var.resource_group[0].location
  resource_group_name                  = var.resource_group[0].name
  create_option                        = "Empty"
  storage_account_type                 = local.app_data_disks[count.index].storage_account_type
  disk_size_gb                         = local.app_data_disks[count.index].disk_size_gb
  disk_encryption_set_id               = try(var.options.disk_encryption_set_id, null)

  zone                                 = var.application_tier.app_use_avset ? null : (
                                           upper(var.application_tier.app_os.os_type) == "LINUX" ? (
                                             azurerm_linux_virtual_machine.app[local.app_data_disks[count.index].vm_index].zone) : (
                                             azurerm_windows_virtual_machine.app[local.app_data_disks[count.index].vm_index].zone
                                           )
                                         )
  tags                                 = var.tags

  lifecycle {
    ignore_changes = [
      create_option,
      hyper_v_generation,
      source_resource_id
    ]
  }

}

resource "azurerm_virtual_machine_data_disk_attachment" "app" {
  provider                             = azurerm.main
  count                                = local.enable_deployment ? length(local.app_data_disks) : 0
  managed_disk_id                      = azurerm_managed_disk.app[count.index].id
  virtual_machine_id                   = upper(var.application_tier.app_os.os_type) == "LINUX" ? (
                                           azurerm_linux_virtual_machine.app[local.app_data_disks[count.index].vm_index].id) : (
                                           azurerm_windows_virtual_machine.app[local.app_data_disks[count.index].vm_index].id
                                         )
  caching                              = local.app_data_disks[count.index].caching
  write_accelerator_enabled            = local.app_data_disks[count.index].write_accelerator_enabled
  lun                                  = local.app_data_disks[count.index].lun
}


# VM Extension
resource "azurerm_virtual_machine_extension" "app_lnx_aem_extension" {
  provider                             = azurerm.main
  count                                = local.enable_deployment && var.application_tier.deploy_v1_monitoring_extension && upper(var.application_tier.app_os.os_type) == "LINUX" ? (
                                           local.application_server_count) : (
                                           0
                                         )
  name                                 = "MonitorX64Linux"
  virtual_machine_id                   = azurerm_linux_virtual_machine.app[count.index].id
  publisher                            = "Microsoft.AzureCAT.AzureEnhancedMonitoring"
  type                                 = "MonitorX64Linux"
  type_handler_version                 = "1.0"
  settings                             = jsonencode(
                                           {
                                             "system": "SAP",

                                           }
                                         )
  tags                                 = var.tags
}


resource "azurerm_virtual_machine_extension" "app_win_aem_extension" {
  provider                             = azurerm.main
  count                                = local.enable_deployment && var.application_tier.deploy_v1_monitoring_extension && upper(var.application_tier.app_os.os_type) == "WINDOWS" ? (
    local.application_server_count) : (
    0
  )
  name                                 = "MonitorX64Windows"
  virtual_machine_id                   = azurerm_windows_virtual_machine.app[count.index].id
  publisher                            = "Microsoft.AzureCAT.AzureEnhancedMonitoring"
  type                                 = "MonitorX64Windows"
  type_handler_version                 = "1.0"
  settings                             = jsonencode(
                                           {
                                             "system": "SAP",

                                           }
                                         )
  tags                                 = var.tags
}

resource "azurerm_virtual_machine_extension" "configure_ansible_app" {
  provider                             = azurerm.main
  count                                = local.enable_deployment && upper(var.application_tier.app_os.os_type) == "WINDOWS" ? (
                                           local.application_server_count) : (
                                           0
                                         )

  depends_on                           = [azurerm_virtual_machine_data_disk_attachment.app]

  name                                 = "configure_ansible"
  virtual_machine_id                   = azurerm_windows_virtual_machine.app[count.index].id
  publisher                            = "Microsoft.Compute"
  type                                 = "CustomScriptExtension"
  type_handler_version                 = "1.9"
  settings                             = jsonencode(
                                           {
                                              "fileUris": ["https://raw.githubusercontent.com/Azure/sap-automation/main/deploy/scripts/configure_ansible.ps1"],
                                              "commandToExecute": "powershell.exe -ExecutionPolicy Unrestricted -File configure_ansible.ps1 -Verbose"
                                           }
                                         )
  tags                                 = var.tags
}


resource "azurerm_virtual_machine_extension" "monitoring_extension_app_lnx" {
  provider                             = azurerm.main
  count                                = local.deploy_monitoring_extension  && upper(var.application_tier.app_os.os_type) == "LINUX" ? (
                                           local.application_server_count) : (
                                           0                                           )
  virtual_machine_id                   = azurerm_linux_virtual_machine.app[count.index].id
  name                                 = "Microsoft.Azure.Monitor.AzureMonitorLinuxAgent"
  publisher                            = "Microsoft.Azure.Monitor"
  type                                 = "AzureMonitorLinuxAgent"
  type_handler_version                 = "1.0"
  auto_upgrade_minor_version           = true
  automatic_upgrade_enabled            = true

}


resource "azurerm_virtual_machine_extension" "monitoring_extension_app_win" {
  provider                             = azurerm.main
  count                                = local.deploy_monitoring_extension  && upper(var.application_tier.app_os.os_type) == "WINDOWS" ? (
                                           local.application_server_count) : (
                                           0                                           )
  virtual_machine_id                   = azurerm_windows_virtual_machine.app[count.index].id
  name                                 = "Microsoft.Azure.Monitor.AzureMonitorWindowsAgent"
  publisher                            = "Microsoft.Azure.Monitor"
  type                                 = "AzureMonitorWindowsAgent"
  type_handler_version                 = "1.0"
  auto_upgrade_minor_version           = true
  automatic_upgrade_enabled            = true

}

resource "azurerm_virtual_machine_extension" "monitoring_defender_app_lnx" {
  provider                             = azurerm.main
  count                                = var.infrastructure.deploy_defender_extension  && upper(var.application_tier.app_os.os_type) == "LINUX" ? (
                                           local.application_server_count) : (
                                           0                                           )
  virtual_machine_id                   = azurerm_linux_virtual_machine.app[count.index].id
  name                                 = "Microsoft.Azure.Security.Monitoring.AzureSecurityLinuxAgent"
  publisher                            = "Microsoft.Azure.Security.Monitoring"
  type                                 = "AzureSecurityLinuxAgent"
  type_handler_version                 = "2.0"
  auto_upgrade_minor_version           = true
  automatic_upgrade_enabled            = true

  settings                             = jsonencode(
                                            {
                                              "enableGenevaUpload"  = true,
                                              "enableAutoConfig"  = true,
                                              "reportSuccessOnUnsupportedDistro"  = true,
                                            }
                                          )
}

resource "azurerm_virtual_machine_extension" "monitoring_defender_app_win" {
  provider                             = azurerm.main
  count                                = var.infrastructure.deploy_defender_extension  && upper(var.application_tier.app_os.os_type) == "WINDOWS" ? (
                                           local.application_server_count) : (
                                           0                                           )
  virtual_machine_id                   = azurerm_windows_virtual_machine.app[count.index].id
  name                                 = "Microsoft.Azure.Security.Monitoring.AzureSecurityWindowsAgent"
  publisher                            = "Microsoft.Azure.Security.Monitoring"
  type                                 = "AzureSecurityWindowsAgent"
  type_handler_version                 = "1.0"
  auto_upgrade_minor_version           = true
  automatic_upgrade_enabled            = true

  settings                             = jsonencode(
                                            {
                                              "enableGenevaUpload"  = true,
                                              "enableAutoConfig"  = true,
                                              "reportSuccessOnUnsupportedDistro"  = true,
                                            }
                                          )
}
