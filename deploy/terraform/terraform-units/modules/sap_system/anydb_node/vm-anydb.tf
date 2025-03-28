# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.


#######################################4#######################################8
#                                                                              #
#                           Primary Network Interface                          #
#                                                                              #
#######################################4#######################################8

resource "azurerm_network_interface" "anydb_db" {
  provider                             = azurerm.main
  count                                = local.enable_deployment ? var.database_server_count : 0
  name                                 = format("%s%s%s%s%s",
                                           var.naming.resource_prefixes.db_nic,
                                           local.prefix,
                                           var.naming.separator,
                                           var.naming.virtualmachine_names.ANYDB_VMNAME[count.index],
                                           local.resource_suffixes.db_nic
                                         )

  location                             = var.resource_group[0].location
  resource_group_name                  = var.resource_group[0].name
  accelerated_networking_enabled        = true
  tags                                 = var.tags
  dynamic "ip_configuration" {
                               iterator             = pub
                               for_each             = local.database_ips
                               content {
                                 name               = pub.value.name
                                 subnet_id          = pub.value.subnet_id
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

                                 primary            = pub.value.primary
                               }
                             }

}

resource "azurerm_network_interface_application_security_group_association" "db" {
  provider                             = azurerm.main
  count                                = local.enable_deployment ? (
                                           var.deploy_application_security_groups ? var.database_server_count : 0) : (
                                           0
                                         )

  network_interface_id                 = var.use_admin_nic_for_asg && local.anydb_dual_nics ? azurerm_network_interface.anydb_admin[count.index].id : azurerm_network_interface.anydb_db[count.index].id
  application_security_group_id        = var.db_asg_id
}

#######################################4#######################################8
#                                                                              #
#                            Admin Network Interface                           #
#                                                                              #
#######################################4#######################################8
resource "azurerm_network_interface" "anydb_admin" {
  provider                             = azurerm.main
  count                                = local.enable_deployment && local.anydb_dual_nics ? (
                                          var.database_server_count) : (
                                          0
                                        )
  name                                 = format("%s%s%s%s%s",
                                           var.naming.resource_prefixes.admin_nic,
                                           local.prefix,
                                           var.naming.separator,
                                           var.naming.virtualmachine_names.ANYDB_VMNAME[count.index],
                                           local.resource_suffixes.admin_nic
                                         )
  location                             = var.resource_group[0].location
  resource_group_name                  = var.resource_group[0].name
  accelerated_networking_enabled        = true
  tags                                 = var.tags

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


#######################################4#######################################8
#                                                                              #
#                           Linux Virtual Machine                              #
#                                                                              #
#######################################4#######################################8
resource "azurerm_linux_virtual_machine" "dbserver" {
  provider                             = azurerm.main
  depends_on                           = [var.anchor_vm]
  count                                = local.enable_deployment ? (
                                           upper(local.anydb_ostype) == "LINUX" ? (
                                             var.database_server_count) : (
                                             0
                                           )) : (
                                           0
                                         )
  name                                 = format("%s%s%s%s%s",
                                           var.naming.resource_prefixes.vm,
                                           local.prefix,
                                           var.naming.separator,
                                           var.naming.virtualmachine_names.ANYDB_VMNAME[count.index],
                                           local.resource_suffixes.vm
                                         )
  computer_name                        = var.naming.virtualmachine_names.ANYDB_COMPUTERNAME[count.index]
  resource_group_name                  = var.resource_group[0].name
  location                             = var.resource_group[0].location

  proximity_placement_group_id         = local.use_ppg ? (
                                           var.ppg[count.index % max(local.db_zone_count, 1)]) : (
                                           null
                                         )

  //If more than one servers are deployed into a single zone put them in an availability set and not a zone
  availability_set_id                  = var.database.use_avset ? (
                                           local.availabilitysets_exist ? (
                                             data.azurerm_availability_set.anydb[count.index % max(length(data.azurerm_availability_set.anydb), 1)].id) : (
                                             azurerm_availability_set.anydb[count.index % max(length(azurerm_availability_set.anydb), 1)].id
                                           )
                                         ) : null

  virtual_machine_scale_set_id         = length(var.scale_set_id) > 0 ? var.scale_set_id : null

  zone                                 = local.zonal_deployment && !var.database.use_avset ? try(local.zones[count.index % max(local.db_zone_count, 1)], local.zones[0]) : null

  network_interface_ids                = local.anydb_dual_nics ? (
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

  size                                 = local.anydb_sku
  source_image_id                      = var.database.os.type == "custom" ? var.database.os.source_image_id : null
  license_type                         = length(var.license_type) > 0 ? var.license_type : null

  admin_username                       = var.sid_username
  admin_password                       = local.enable_auth_key ? null : var.sid_password
  disable_password_authentication      = !local.enable_auth_password

  custom_data                          = var.deployment == "new" ? var.cloudinit_growpart_config : null

  patch_mode                                             = var.infrastructure.patch_mode
  patch_assessment_mode                                  = var.infrastructure.patch_assessment_mode
  bypass_platform_safety_checks_on_user_schedule_enabled = var.infrastructure.patch_mode != "AutomaticByPlatform" ? false : true
  vm_agent_platform_updates_enabled                      = var.infrastructure.platform_updates

  tags                                 = merge(local.tags, var.tags)

  encryption_at_host_enabled                             = var.infrastructure.encryption_at_host_enabled

  dynamic "admin_ssh_key" {
                            for_each = range(var.deployment == "new" ? 1 : (local.enable_auth_password ? 0 : 1))
                            content {
                              username   = var.sid_username
                              public_key = var.sdu_public_key
                            }
                          }

  dynamic "os_disk" {
                      iterator = disk
                      for_each = range(length(local.os_disk))
                      content {
                        name                                 = format("%s%s%s%s%s",
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

  dynamic "source_image_reference" {
                                     for_each = range(var.database.os.type == "marketplace" || var.database.os.type == "marketplace_with_plan" ? 1 : 0)
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
                     name      = var.database.os.sku
                     publisher = var.database.os.publisher
                     product   = var.database.os.offer
                   }
                 }

  additional_capabilities {
                            ultra_ssd_enabled = local.enable_ultradisk
                          }

  boot_diagnostics {
                     storage_account_uri = var.storage_bootdiag_endpoint
                   }
  dynamic "identity" {
                       for_each = range((var.use_msi_for_clusters && var.database.high_availability) || length(var.database.user_assigned_identity_id) > 0 ? 1 : 0)
                       content {
                         type         = var.use_msi_for_clusters && length(var.database.user_assigned_identity_id) > 0 ? "SystemAssigned, UserAssigned" : var.use_msi_for_clusters ? "SystemAssigned" : "UserAssigned"
                         identity_ids = length(var.database.user_assigned_identity_id) > 0 ? [var.database.user_assigned_identity_id] : null
                       }
                     }

  lifecycle {
    ignore_changes = [
      // Ignore changes to computername
      computer_name,
      source_image_id
    ]
  }

}

#######################################4#######################################8
#                                                                              #
#                          Windows Virtual Machine                             #
#                                                                              #
#######################################4#######################################8
resource "azurerm_windows_virtual_machine" "dbserver" {
  provider                             = azurerm.main
  count                                = local.enable_deployment ? (
                                           upper(local.anydb_ostype) == "WINDOWS" ? (
                                             var.database_server_count) : (
                                             0
                                           )) : (
                                           0
                                         )
  name                                 = format("%s%s%s%s%s",
                                           var.naming.resource_prefixes.vm,
                                           local.prefix,
                                           var.naming.separator,
                                           var.naming.virtualmachine_names.ANYDB_VMNAME[count.index],
                                           local.resource_suffixes.vm
                                         )
  computer_name                        = var.naming.virtualmachine_names.ANYDB_COMPUTERNAME[count.index]
  resource_group_name                  = var.resource_group[0].name
  location                             = var.resource_group[0].location

  proximity_placement_group_id         = local.use_ppg ? (
                                           var.ppg[count.index % max(local.db_zone_count, 1)]) : (
                                           null
                                         )

  //If more than one servers are deployed into a single zone put them in an availability set and not a zone
  availability_set_id                  = var.database.use_avset ? (
                                           local.availabilitysets_exist ? (
                                             data.azurerm_availability_set.anydb[count.index % max(length(data.azurerm_availability_set.anydb), 1)].id) : (
                                             azurerm_availability_set.anydb[count.index % max(length(azurerm_availability_set.anydb), 1)].id
                                           )
                                         ) : null

  virtual_machine_scale_set_id         = length(var.scale_set_id) > 0 ? var.scale_set_id : null

  zone                                 = local.zonal_deployment && !var.database.use_avset ? try(local.zones[count.index % max(local.db_zone_count, 1)], local.zones[0]) : null

  network_interface_ids                = local.anydb_dual_nics ? (
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

  size                                 = local.anydb_sku
  source_image_id                      = var.database.os.type == "custom" ? var.database.os.source_image_id : null
  license_type                         = length(var.license_type) > 0 ? var.license_type : null

  // ImageDefault = Manual on Windows
  // https://learn.microsoft.com/en-us/azure/virtual-machines/automatic-vm-guest-patching#patch-orchestration-modes
  patch_mode                                             = var.infrastructure.patch_mode == "ImageDefault" ? "Manual" : var.infrastructure.patch_mode
  patch_assessment_mode                                  = var.infrastructure.patch_assessment_mode
  bypass_platform_safety_checks_on_user_schedule_enabled = var.infrastructure.patch_mode != "AutomaticByPlatform" ? false : true
  vm_agent_platform_updates_enabled                      = var.infrastructure.platform_updates
  enable_automatic_updates                               = !(var.infrastructure.patch_mode == "ImageDefault")

  admin_username                       = var.sid_username
  admin_password                       = var.sid_password

  tags                                 = merge(local.tags, var.tags)

  encryption_at_host_enabled                             = var.infrastructure.encryption_at_host_enabled

  dynamic "os_disk" {
                      iterator = disk
                      for_each = range(length(local.os_disk))
                      content {
                        name                                 = format("%s%s%s%s%s",
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

  dynamic "source_image_reference" {
                                     for_each = range(var.database.os.type == "marketplace" || var.database.os.type == "marketplace_with_plan" ? 1 : 0)
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
                     name      = var.database.os.sku
                     publisher = var.database.os.publisher
                     product   = var.database.os.offer
                   }
                 }

  additional_capabilities {
                            ultra_ssd_enabled = local.enable_ultradisk
                          }

  boot_diagnostics {
                     storage_account_uri = var.storage_bootdiag_endpoint
                   }
  dynamic "identity" {
                       for_each = range((var.use_msi_for_clusters && var.database.high_availability) || length(var.database.user_assigned_identity_id) > 0 ? 1 : 0)
                       content {
                         type         = var.use_msi_for_clusters && length(var.database.user_assigned_identity_id) > 0 ? "SystemAssigned, UserAssigned" : var.use_msi_for_clusters ? "SystemAssigned" : "UserAssigned"
                         identity_ids = length(var.database.user_assigned_identity_id) > 0 ? [var.database.user_assigned_identity_id] : null
                       }
                     }

  lifecycle {
    ignore_changes = [
      // Ignore changes to computername
      computer_name,
      source_image_id
    ]
  }
}

#######################################4#######################################8
#                                                                              #
#                                     Disks                                    #
#                                                                              #
#######################################4#######################################8
resource "azurerm_managed_disk" "disks" {
  provider                             = azurerm.main
  count                                = local.enable_deployment ? length(local.anydb_disks) : 0
  name                                 = format("%s%s%s%s%s",
                                           var.naming.resource_prefixes.disk,
                                           local.prefix,
                                           var.naming.separator,
                                           var.naming.virtualmachine_names.ANYDB_VMNAME[local.anydb_disks[count.index].vm_index],
                                           local.anydb_disks[count.index].suffix
                                         )
  location                             = var.resource_group[0].location
  resource_group_name                  = var.resource_group[0].name

  create_option                        = "Empty"

  storage_account_type                 = local.anydb_disks[count.index].storage_account_type
  disk_size_gb                         = local.anydb_disks[count.index].disk_size_gb
  tier                                 = local.anydb_disks[count.index].tier
  disk_encryption_set_id               = try(var.options.disk_encryption_set_id, null)
  disk_iops_read_write                 = "UltraSSD_LRS" == local.anydb_disks[count.index].storage_account_type ? (
                                            local.anydb_disks[count.index].disk_iops_read_write) : (
                                            null
                                          )
  disk_mbps_read_write                 = "UltraSSD_LRS" == local.anydb_disks[count.index].storage_account_type ? (
                                            local.anydb_disks[count.index].disk_mbps_read_write) : (
                                            null
                                          )

  zone                                 = local.zonal_deployment && !var.database.use_avset ? (
                                           upper(local.anydb_ostype) == "LINUX" ? (
                                             azurerm_linux_virtual_machine.dbserver[local.anydb_disks[count.index].vm_index].zone) : (
                                             azurerm_windows_virtual_machine.dbserver[local.anydb_disks[count.index].vm_index].zone
                                         )) : (
                                           null
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

// Manages attaching a Disk to a Virtual Machine
resource "azurerm_virtual_machine_data_disk_attachment" "vm_disks" {
  provider                             = azurerm.main
  count                                = local.enable_deployment ? length(local.anydb_disks) : 0
  managed_disk_id                      = azurerm_managed_disk.disks[count.index].id
  virtual_machine_id                   = upper(local.anydb_ostype) == "LINUX" ? (
                                           azurerm_linux_virtual_machine.dbserver[local.anydb_disks[count.index].vm_index].id) : (
                                           azurerm_windows_virtual_machine.dbserver[local.anydb_disks[count.index].vm_index].id
                                         )
  caching                              = local.anydb_disks[count.index].caching
  write_accelerator_enabled            = local.anydb_disks[count.index].write_accelerator_enabled
  lun                                  = local.anydb_disks[count.index].lun
  # tier                      = local.anydb_disks[count.index].tier

}


# VM Extension
resource "azurerm_virtual_machine_extension" "anydb_lnx_aem_extension" {
  provider                             = azurerm.main
  count                                = local.enable_deployment && var.database.deploy_v1_monitoring_extension ? (
                                           upper(local.anydb_ostype) == "LINUX" ? (
                                             var.database_server_count) : (
                                             0
                                           )) : (
                                           0
                                         )
  depends_on                           = [azurerm_virtual_machine_data_disk_attachment.vm_disks]
  name                                 = "MonitorX64Linux"
  virtual_machine_id                   = azurerm_linux_virtual_machine.dbserver[count.index].id
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


resource "azurerm_virtual_machine_extension" "anydb_win_aem_extension" {
  provider                             = azurerm.main
  count                                = local.enable_deployment && var.database.deploy_v1_monitoring_extension ? (
                                           upper(local.anydb_ostype) == "WINDOWS" ? (
                                             var.database_server_count) : (
                                             0
                                           )) : (
                                           0
                                         )
  depends_on                           = [azurerm_virtual_machine_data_disk_attachment.vm_disks]
  name                                 = "MonitorX64Windows"
  virtual_machine_id                   = azurerm_windows_virtual_machine.dbserver[count.index].id
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


#######################################4#######################################8
#                                                                              #
#                                Configure Ansible                             #
#                                                                              #
#######################################4#######################################8

resource "azurerm_virtual_machine_extension" "configure_ansible" {
  provider                             = azurerm.main
  count                                = local.enable_deployment ? (
                                           upper(local.anydb_ostype) == "WINDOWS" ? (
                                             var.database_server_count) : (
                                             0
                                           )) : (
                                           0
                                         )
  depends_on                           = [azurerm_virtual_machine_data_disk_attachment.vm_disks]

  name                                 = "configure_ansible"
  virtual_machine_id                   = azurerm_windows_virtual_machine.dbserver[count.index].id
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


#########################################################################################
#                                                                                       #
#  Azure Shared Disk for SBD                                                            #
#                                                                                       #
#######################################+#################################################
resource "azurerm_managed_disk" "cluster" {
  provider                             = azurerm.main
  count                                = (
                                           local.enable_deployment &&
                                           var.database.high_availability &&
                                           (
                                             upper(var.database.os.os_type) == "WINDOWS" ||
                                             (
                                               upper(var.database.os.os_type) == "LINUX" &&
                                               upper(var.database.database_cluster_type) == "ASD"
                                             )
                                           )
                                         ) ? 1 : 0

  name                                 = format("%s%s%s%s",
                                           var.naming.resource_prefixes.database_cluster_disk,
                                           local.prefix,
                                           var.naming.separator,
                                           var.naming.resource_suffixes.database_cluster_disk
                                         )
  location                             = var.resource_group[0].location
  resource_group_name                  = var.resource_group[0].name
  create_option                        = "Empty"
  storage_account_type                 = var.database.database_cluster_disk_type
  disk_size_gb                         = var.database.database_cluster_disk_size
  disk_encryption_set_id               = try(var.options.disk_encryption_set_id, null)
  max_shares                           = var.database_server_count
  tags                                 = var.tags

  zone                                 = var.database.database_cluster_disk_type == "Premium_LRS" && local.zonal_deployment && !var.database.use_avset ? (
                                           upper(local.anydb_ostype) == "LINUX" ? (
                                             azurerm_linux_virtual_machine.dbserver[local.anydb_disks[count.index].vm_index].zone) : (
                                             azurerm_windows_virtual_machine.dbserver[local.anydb_disks[count.index].vm_index].zone
                                         )) : (
                                           null
                                         )
  lifecycle {
    ignore_changes = [
      create_option,
      hyper_v_generation,
      source_resource_id,
      tags
    ]
  }
}

resource "azurerm_virtual_machine_data_disk_attachment" "cluster" {
  provider                             = azurerm.main
  count                                = (
                                           local.enable_deployment &&
                                           var.database.high_availability &&
                                           (
                                             upper(var.database.os.os_type) == "WINDOWS" ||
                                             (
                                               upper(var.database.os.os_type) == "LINUX" &&
                                               upper(var.database.database_cluster_type) == "ASD"
                                             )
                                           )
                                         ) ? var.database_server_count : 0

  managed_disk_id                      = azurerm_managed_disk.cluster[0].id
  virtual_machine_id                   = (upper(var.database.os.os_type) == "LINUX"                                # If Linux
                                         ) ? (
                                           azurerm_linux_virtual_machine.dbserver[count.index].id
                                         ) : (
                                           (upper(var.database.os.os_type) == "WINDOWS"                            # If Windows
                                           ) ? (
                                             azurerm_windows_virtual_machine.dbserver[count.index].id
                                           ) : (
                                             null                                                                  # If Other
                                           )
                                         )
  caching                              = "None"
  lun                                  = var.database.database_cluster_disk_lun
}


resource "azurerm_role_assignment" "role_assignment_msi" {
  provider                             = azurerm.main
  count                                = (
                                           var.use_msi_for_clusters &&
                                           length(var.fencing_role_name) > 0 &&
                                           var.database_server_count > 1
                                           ) ? (
                                           var.database_server_count
                                           ) : (
                                           0
                                         )
  scope                                = (upper(var.database.os.os_type) == "LINUX"                                # If Linux
                                         ) ? (
                                           azurerm_linux_virtual_machine.dbserver[count.index].id
                                         ) : (
                                           (upper(var.database.os.os_type) == "WINDOWS"                            # If Windows
                                           ) ? (
                                             azurerm_windows_virtual_machine.dbserver[count.index].id
                                           ) : (
                                             null                                                                  # If Other
                                           )
                                         )
  role_definition_name                 = var.fencing_role_name
  principal_id                         = (upper(var.database.os.os_type) == "LINUX"                                # If Linux
                                         ) ? (
                                           azurerm_linux_virtual_machine.dbserver[count.index].identity[0].principal_id
                                         ) : (
                                           (upper(var.database.os.os_type) == "WINDOWS"                            # If Windows
                                           ) ? (
                                             azurerm_windows_virtual_machine.dbserver[count.index].identity[0].principal_id
                                           ) : (
                                             null                                                                  # If Other
                                           )
                                         )
}

resource "azurerm_role_assignment" "role_assignment_msi_ha" {
  provider                             = azurerm.main
  count                                = (
                                          var.use_msi_for_clusters &&
                                          length(var.fencing_role_name) > 0 &&
                                          var.database_server_count > 1
                                          ) ? (
                                          var.database_server_count
                                          ) : (
                                          0
                                        )
  scope                                = (upper(var.database.os.os_type) == "LINUX"                                # If Linux
                                         ) ? (
                                           azurerm_linux_virtual_machine.dbserver[count.index].id
                                         ) : (
                                           (upper(var.database.os.os_type) == "WINDOWS"                            # If Windows
                                           ) ? (
                                             azurerm_windows_virtual_machine.dbserver[count.index].id
                                           ) : (
                                             null                                                                  # If Other
                                           )
                                         )
  role_definition_name                 = var.fencing_role_name
  principal_id                         = (upper(var.database.os.os_type) == "LINUX"                                # If Linux
                                         ) ? (
                                           azurerm_linux_virtual_machine.dbserver[(count.index +1) % var.database_server_count].identity[0].principal_id
                                         ) : (
                                           (upper(var.database.os.os_type) == "WINDOWS"                            # If Windows
                                           ) ? (
                                             azurerm_windows_virtual_machine.dbserver[(count.index +1) % var.database_server_count].identity[0].principal_id
                                           ) : (
                                             null                                                                  # If Other
                                           )
                                         )

}


#########################################################################################
#                                                                                       #
#  Azure Data Disk for Kdump                                                            #
#                                                                                       #
#######################################+#################################################
resource "azurerm_managed_disk" "kdump" {
  provider                             = azurerm.main
  count                                = (
                                           local.enable_deployment &&
                                           var.database.high_availability &&
                                           (
                                               upper(var.database.os.os_type) == "LINUX" &&
                                               ( var.database.fence_kdump_disk_size > 0 )
                                           )
                                         ) ? var.database_server_count : 0

  name                                 = format("%s%s%s%s%s",
                                           try( var.naming.resource_prefixes.fence_kdump_disk, ""),
                                           local.prefix,
                                           var.naming.separator,
                                           var.naming.virtualmachine_names.ANYDB_VMNAME[count.index],
                                           try( var.naming.resource_suffixes.fence_kdump_disk, "fence_kdump_disk" )
                                         )
  location                             = var.resource_group[0].location
  resource_group_name                  = var.resource_group[0].name
  create_option                        = "Empty"
  storage_account_type                 = "Premium_LRS"
  disk_size_gb                         = try(var.database.fence_kdump_disk_size,128)
  disk_encryption_set_id               = try(var.options.disk_encryption_set_id, null)
  tags                                 = var.tags

  zone                                 = local.zonal_deployment && !var.database.use_avset ? (
                                             azurerm_linux_virtual_machine.dbserver[count.index].zone
                                         ) : (
                                           null
                                         )
  lifecycle {
    ignore_changes = [
      create_option,
      hyper_v_generation,
      source_resource_id,
      tags
    ]
  }
}

resource "azurerm_virtual_machine_data_disk_attachment" "kdump" {
  provider                             = azurerm.main
  count                                = (
                                           local.enable_deployment &&
                                           var.database.high_availability &&
                                           (
                                               upper(var.database.os.os_type) == "LINUX" &&
                                               ( var.database.fence_kdump_disk_size > 0 )
                                           )
                                         ) ? var.database_server_count : 0

  managed_disk_id                      = azurerm_managed_disk.kdump[count.index].id
  virtual_machine_id                   = (upper(var.database.os.os_type) == "LINUX"                                # If Linux
                                         ) ? (
                                           azurerm_linux_virtual_machine.dbserver[count.index].id
                                         ) : null
  caching                              = "None"
  lun                                  = var.database.fence_kdump_lun_number
}

resource "azurerm_virtual_machine_extension" "monitoring_extension_db_lnx" {
  provider                             = azurerm.main
  count                                = local.deploy_monitoring_extension  && upper(var.database.os.os_type) == "LINUX" ? (
                                           var.database_server_count) : (
                                           0                                           )
  virtual_machine_id                   = azurerm_linux_virtual_machine.dbserver[count.index].id
  name                                 = "Microsoft.Azure.Monitor.AzureMonitorLinuxAgent"
  publisher                            = "Microsoft.Azure.Monitor"
  type                                 = "AzureMonitorLinuxAgent"
  type_handler_version                 = "1.0"
  auto_upgrade_minor_version           = true
  automatic_upgrade_enabled            = true

}


resource "azurerm_virtual_machine_extension" "monitoring_extension_db_win" {
  provider                             = azurerm.main
  count                                = local.deploy_monitoring_extension  && upper(var.database.os.os_type) == "WINDOWS" ? (
                                           var.database_server_count) : (
                                           0                                           )
  virtual_machine_id                   = azurerm_windows_virtual_machine.dbserver[count.index].id
  name                                 = "Microsoft.Azure.Monitor.AzureMonitorWindowsAgent"
  publisher                            = "Microsoft.Azure.Monitor"
  type                                 = "AzureMonitorWindowsAgent"
  type_handler_version                 = "1.0"
  auto_upgrade_minor_version           = true
  automatic_upgrade_enabled            = true

}


resource "azurerm_virtual_machine_extension" "monitoring_defender_db_lnx" {
  provider                             = azurerm.main
  count                                = var.infrastructure.deploy_defender_extension  && upper(var.database.os.os_type) == "LINUX" ? (
                                           var.database_server_count) : (
                                           0
                                         )
  virtual_machine_id                   = azurerm_linux_virtual_machine.dbserver[count.index].id
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

resource "azurerm_virtual_machine_extension" "monitoring_defender_db_win" {
  provider                             = azurerm.main
  count                                = var.infrastructure.deploy_defender_extension  && upper(var.database.os.os_type) == "WINDOWS" ? (
                                           var.database_server_count) : (
                                           0
                                         )
  virtual_machine_id                   = azurerm_windows_virtual_machine.dbserver[count.index].id
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
