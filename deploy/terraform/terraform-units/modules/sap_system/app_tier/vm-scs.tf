# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.


#######################################4#######################################8
#                                                                              #
#                           Primary Network Interface                          #
#                                                                              #
#######################################4#######################################8
resource "azurerm_network_interface" "scs" {
  provider                             = azurerm.main
  count                                = local.enable_deployment ? local.scs_server_count : 0
  name                                 = format("%s%s%s%s%s",
                                           var.naming.resource_prefixes.nic,
                                           local.prefix,
                                           var.naming.separator,
                                           var.naming.virtualmachine_names.SCS_VMNAME[count.index],
                                           local.resource_suffixes.nic
                                         )
  location                             = var.resource_group[0].location
  resource_group_name                  = var.resource_group[0].name
  accelerated_networking_enabled        = local.scs_sizing.compute.accelerated_networking
  tags                                 = var.tags

  dynamic "ip_configuration" {
                               iterator = pub
                               for_each = local.scs_ips
                               content {
                                         name      = pub.value.name
                                         subnet_id = pub.value.subnet_id
                                         private_ip_address = try(pub.value.nic_ips[count.index],
                                           var.application_tier.use_DHCP ? (
                                             null) : (
                                             cidrhost(local.application_subnet_exists ?
                                               data.azurerm_subnet.subnet_sap_app[0].address_prefixes[0] :
                                               azurerm_subnet.subnet_sap_app[0].address_prefixes[0],
                                               tonumber(count.index) + local.ip_offsets.scs_vm + pub.value.offset
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

resource "azurerm_network_interface_application_security_group_association" "scs" {
  provider                             = azurerm.main
  count                                = local.enable_deployment ? (
                                           var.deploy_application_security_groups ? local.scs_server_count : 0) : (
                                           0
                                         )

  network_interface_id                 = var.use_admin_nic_for_asg && var.application_tier.dual_nics ? azurerm_network_interface.scs_admin[count.index].id : azurerm_network_interface.scs[count.index].id
  application_security_group_id        = azurerm_application_security_group.app[0].id
}


#######################################4#######################################8
#                                                                              #
#                             Admin Network Interface                          #
#                                                                              #
#######################################4#######################################8

resource "azurerm_network_interface" "scs_admin" {
  provider                             = azurerm.main
  count                                = local.enable_deployment && var.application_tier.dual_nics && length(try(var.admin_subnet.id, "")) > 0 ? (
                                           local.scs_server_count) : (
                                           0
                                         )
  name                                 = format("%s%s%s%s%s",
                                           var.naming.resource_prefixes.admin_nic,
                                           local.prefix,
                                           var.naming.separator,
                                           var.naming.virtualmachine_names.SCS_VMNAME[count.index],
                                           local.resource_suffixes.admin_nic
                                         )
  location                             = var.resource_group[0].location
  resource_group_name                  = var.resource_group[0].name
  accelerated_networking_enabled        = local.scs_sizing.compute.accelerated_networking

  ip_configuration {
                      name      = "IPConfig1"
                      subnet_id = var.admin_subnet.id
                      private_ip_address = try(local.scs_admin_nic_ips[count.index], var.application_tier.use_DHCP ? (
                        null) : (
                        cidrhost(
                          var.admin_subnet.address_prefixes[0],
                          tonumber(count.index) + local.admin_ip_offsets.scs_vm
                        )
                        )
                      )
                      private_ip_address_allocation = length(try(local.scs_admin_nic_ips[count.index], "")) > 0 ? (
                        "Static") : (
                        "Dynamic"
                      )
                    }
}

# Associate SCS VM NICs with the Load Balancer Backend Address Pool
resource "azurerm_network_interface_backend_address_pool_association" "scs" {
  provider                             = azurerm.main
  count                                = local.enable_scs_lb_deployment ? local.scs_server_count : 0
  network_interface_id                 = azurerm_network_interface.scs[count.index].id
  ip_configuration_name                = azurerm_network_interface.scs[count.index].ip_configuration[0].name
  backend_address_pool_id              = azurerm_lb_backend_address_pool.scs[0].id
}

# Create the SCS Linux VM(s)
resource "azurerm_linux_virtual_machine" "scs" {
  provider                             = azurerm.main
  count                                = local.enable_deployment && upper(var.application_tier.scs_os.os_type) == "LINUX" ? (
                                           local.scs_server_count) : (
                                           0
                                         )
  name                                 = format("%s%s%s%s%s",
                                           var.naming.resource_prefixes.vm,
                                           local.prefix,
                                           var.naming.separator,
                                           var.naming.virtualmachine_names.SCS_VMNAME[count.index],
                                           local.resource_suffixes.vm
                                         )
  computer_name                        = var.naming.virtualmachine_names.SCS_COMPUTERNAME[count.index]
  location                             = var.resource_group[0].location
  resource_group_name                  = var.resource_group[0].name

  //If no ppg defined do not put the scs servers in a proximity placement group
  proximity_placement_group_id         = var.application_tier.scs_use_ppg ? (
                                           local.scs_zonal_deployment ? var.ppg[count.index % max(length(var.ppg), 1)] : var.ppg[0]) : (
                                           null
                                         )

  //If more than one servers are deployed into a single zone put them in an availability set and not a zone
  availability_set_id                  = local.use_scs_avset ? (
                                           azurerm_availability_set.scs[count.index % max(length(azurerm_availability_set.scs), 1)].id) : (
                                           null
                                         )

  virtual_machine_scale_set_id         = length(var.scale_set_id) > 0 ? var.scale_set_id : null

  patch_mode                                             = var.infrastructure.patch_mode

  patch_assessment_mode                                  = var.infrastructure.patch_assessment_mode
  bypass_platform_safety_checks_on_user_schedule_enabled = var.infrastructure.patch_mode != "AutomaticByPlatform" ? false : true
  vm_agent_platform_updates_enabled                      = var.infrastructure.platform_updates
  //If length of zones > 1 distribute servers evenly across zones
  zone                                 = local.use_scs_avset ? null : try(local.scs_zones[count.index % max(local.scs_zone_count, 1)], null)
  network_interface_ids                = var.application_tier.dual_nics ? (
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
                                           [azurerm_network_interface.scs[count.index].id]
                                         )

  size                                 = length(local.scs_size) > 0 ? local.scs_size : local.scs_sizing.compute.vm_size
  admin_username                       = var.sid_username
  admin_password                       = local.enable_auth_key ? null : var.sid_password
  disable_password_authentication      = !local.enable_auth_password
  custom_data                          = var.deployment == "new" ? var.cloudinit_growpart_config : null

  source_image_id                      = var.application_tier.scs_os.type == "custom" ? var.application_tier.scs_os.source_image_id : null
  license_type                         = length(var.license_type) > 0 ? var.license_type : null
  # ToDo Add back later
# patch_mode                           = var.infrastructure.patch_mode

  tags                                 = merge(var.application_tier.scs_tags, var.tags)

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
                          for storage_type in local.scs_sizing.storage : [
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
                                  var.naming.virtualmachine_names.SCS_VMNAME[count.index],
                                  local.resource_suffixes.osdisk
                                )
                                caching                = disk.value.caching
                                storage_account_type   = disk.value.disk_type
                                disk_size_gb           = disk.value.size_gb
                                disk_encryption_set_id = try(var.options.disk_encryption_set_id, null)
                              }
                    }

  dynamic "source_image_reference" {
                                     for_each = range(var.application_tier.scs_os.type == "marketplace" || var.application_tier.scs_os.type == "marketplace_with_plan" ? 1 : 0)
                                     content {
                                       publisher = var.application_tier.scs_os.publisher
                                       offer     = var.application_tier.scs_os.offer
                                       sku       = var.application_tier.scs_os.sku
                                       version   = var.application_tier.scs_os.version
                                     }
                                   }

  dynamic "plan" {
                   for_each = range(var.application_tier.scs_os.type == "marketplace_with_plan" ? 1 : 0)
                   content {
                             name      = var.application_tier.scs_os.sku
                             publisher = var.application_tier.scs_os.publisher
                             product   = var.application_tier.scs_os.offer
                           }
                 }
  boot_diagnostics {
                     storage_account_uri = var.storage_bootdiag_endpoint
                   }

  dynamic "identity" {
                       for_each = range((var.use_msi_for_clusters && var.application_tier.scs_high_availability) || length(var.application_tier.user_assigned_identity_id) > 0 ? 1 : 0)
                       content {
                         type         = var.use_msi_for_clusters && length(var.application_tier.user_assigned_identity_id) > 0 ? "SystemAssigned, UserAssigned" : var.use_msi_for_clusters ? "SystemAssigned" : "UserAssigned"
                         identity_ids = length(var.application_tier.user_assigned_identity_id) > 0 ? [var.application_tier.user_assigned_identity_id] : null
                       }
                     }
  lifecycle {
    ignore_changes = [
      source_image_id
    ]
  }


}

resource "azurerm_role_assignment" "scs" {
  provider                             = azurerm.main
  depends_on                           = [ azurerm_linux_virtual_machine.scs  ]
  count                                = (
                                           var.use_msi_for_clusters &&
                                           local.enable_deployment &&
                                           upper(var.application_tier.scs_os.os_type) == "LINUX" &&
                                           length(var.fencing_role_name) > 0 &&
                                           local.scs_server_count > 1
                                           ) ? (
                                           local.scs_server_count
                                           ) : (
                                           0
                                         )

  scope                                = azurerm_linux_virtual_machine.scs[count.index].id

  role_definition_name                 = var.fencing_role_name
  principal_id                         =  azurerm_linux_virtual_machine.scs[count.index].identity[0].principal_id

}

resource "azurerm_role_assignment" "scs_ha" {
  provider                             = azurerm.main
  depends_on                           = [ azurerm_linux_virtual_machine.scs  ]
  count                                = (
                                            var.use_msi_for_clusters &&
                                            local.enable_deployment &&
                                            upper(var.application_tier.scs_os.os_type) == "LINUX" &&
                                            length(var.fencing_role_name) > 0 &&
                                            local.scs_server_count > 1
                                            ) ? (
                                            local.scs_server_count
                                            ) : (
                                            0
                                          )

  scope                                = azurerm_linux_virtual_machine.scs[count.index].id

  role_definition_name                 = var.fencing_role_name
  principal_id                         =  azurerm_linux_virtual_machine.scs[(count.index +1) % local.scs_server_count].identity[0].principal_id

}

# Create the SCS Windows VM(s)
resource "azurerm_windows_virtual_machine" "scs" {
  provider                             = azurerm.main
  count                                = local.enable_deployment && upper(var.application_tier.scs_os.os_type) == "WINDOWS" ? (
                                           local.scs_server_count) : (
                                           0
                                         )
  name                                 = format("%s%s%s%s%s",
                                           var.naming.resource_prefixes.vm,
                                           local.prefix,
                                           var.naming.separator,
                                           var.naming.virtualmachine_names.SCS_VMNAME[count.index],
                                           local.resource_suffixes.vm
                                         )
  computer_name                        = var.naming.virtualmachine_names.SCS_COMPUTERNAME[count.index]

  location                             = var.resource_group[0].location
  resource_group_name                  = var.resource_group[0].name

  //If no ppg defined do not put the scs servers in a proximity placement group
  proximity_placement_group_id         = var.application_tier.scs_use_ppg ? (
                                           local.scs_zonal_deployment ? var.ppg[count.index % max(length(var.ppg), 1)] : var.ppg[0]) : (
                                           null
                                         )

  //If more than one servers are deployed into a single zone put them in an availability set and not a zone
  availability_set_id                  = local.use_scs_avset ? (
                                           azurerm_availability_set.scs[count.index % max(length(azurerm_availability_set.scs), 1)].id) : (
                                           null
                                         )

  virtual_machine_scale_set_id         = length(var.scale_set_id) > 0 ? var.scale_set_id : null

  // ImageDefault = Manual on Windows
  // https://learn.microsoft.com/en-us/azure/virtual-machines/automatic-vm-guest-patching#patch-orchestration-modes
  patch_mode                                             = var.infrastructure.patch_mode == "ImageDefault" ? "Manual" : var.infrastructure.patch_mode
  patch_assessment_mode                                  = var.infrastructure.patch_assessment_mode
  bypass_platform_safety_checks_on_user_schedule_enabled = var.infrastructure.patch_mode != "AutomaticByPlatform" ? false : true
  vm_agent_platform_updates_enabled                      = var.infrastructure.platform_updates
  enable_automatic_updates                               = !(var.infrastructure.patch_mode == "ImageDefault")
  //If length of zones > 1 distribute servers evenly across zones
  zone                                 = local.use_scs_avset ? (
                                            null) : (
                                            try(local.scs_zones[count.index % max(local.scs_zone_count, 1)], null)
                                          )

  network_interface_ids                = var.application_tier.dual_nics ? (
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
                                           [azurerm_network_interface.scs[count.index].id]
                                         )

  size                               = length(local.scs_size) > 0 ? (
                                         local.scs_size) : (
                                         local.scs_sizing.compute.vm_size
                                       )
  source_image_id                    = var.application_tier.scs_os.type == "custom" ? var.application_tier.scs_os.source_image_id : null

  admin_username                     = var.sid_username
  admin_password                     = var.sid_password

  license_type                       = length(var.license_type) > 0 ? var.license_type : null

  tags                               = merge(var.application_tier.scs_tags, var.tags)

  encryption_at_host_enabled         = var.infrastructure.encryption_at_host_enabled


  dynamic "os_disk" {
                      iterator = disk
                      for_each = flatten(
                        [
                          for storage_type in local.scs_sizing.storage : [
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
                                name = format("%s%s%s%s%s",
                                  var.naming.resource_prefixes.osdisk,
                                  local.prefix,
                                  var.naming.separator,
                                  var.naming.virtualmachine_names.SCS_VMNAME[count.index],
                                  local.resource_suffixes.osdisk
                                )
                                caching                = disk.value.caching
                                storage_account_type   = disk.value.disk_type
                                disk_size_gb           = disk.value.size_gb
                                disk_encryption_set_id = try(var.options.disk_encryption_set_id, null)
                              }
                    }

  dynamic "source_image_reference" {
                                     for_each = range(var.application_tier.scs_os.type == "marketplace" || var.application_tier.scs_os.type == "marketplace_with_plan" ? 1 : 0)
                                     content {
                                       publisher = var.application_tier.scs_os.publisher
                                       offer     = var.application_tier.scs_os.offer
                                       sku       = var.application_tier.scs_os.sku
                                       version   = var.application_tier.scs_os.version
                                     }
                                   }

  dynamic "plan" {
                   for_each = range(var.application_tier.scs_os.type == "marketplace_with_plan" ? 1 : 0)
                   content {
                     name      = var.application_tier.scs_os.sku
                     publisher = var.application_tier.scs_os.publisher
                     product   = var.application_tier.scs_os.offer
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
      source_image_id
    ]
  }

}

# Creates managed data disk
resource "azurerm_managed_disk" "scs" {
  provider                             = azurerm.main
  count                                = local.enable_deployment ? length(local.scs_data_disks) : 0
  name                                 = format("%s%s%s%s%s",
                                           var.naming.resource_prefixes.disk,
                                           local.prefix,
                                           var.naming.separator,
                                           var.naming.virtualmachine_names.SCS_VMNAME[local.scs_data_disks[count.index].vm_index],
                                           local.scs_data_disks[count.index].suffix
                                         )
  location                             = var.resource_group[0].location
  resource_group_name                  = var.resource_group[0].name
  create_option                        = "Empty"
  storage_account_type                 = local.scs_data_disks[count.index].storage_account_type
  disk_size_gb                         = local.scs_data_disks[count.index].disk_size_gb
  disk_encryption_set_id               = try(var.options.disk_encryption_set_id, null)

  tags                                 = var.tags

  zone                                 = !local.use_scs_avset ? (
                                           upper(var.application_tier.scs_os.os_type) == "LINUX" ? (
                                             azurerm_linux_virtual_machine.scs[local.scs_data_disks[count.index].vm_index].zone) : (
                                             azurerm_windows_virtual_machine.scs[local.scs_data_disks[count.index].vm_index].zone
                                           )) : (
                                           null
                                         )

  lifecycle {
    ignore_changes = [
      create_option,
      hyper_v_generation,
      source_resource_id
    ]
  }

}

resource "azurerm_virtual_machine_data_disk_attachment" "scs" {
  provider                             = azurerm.main
  count                                = local.enable_deployment ? length(local.scs_data_disks) : 0
  managed_disk_id                      = azurerm_managed_disk.scs[count.index].id
  virtual_machine_id                   = upper(var.application_tier.scs_os.os_type) == "LINUX" ? (
                                           azurerm_linux_virtual_machine.scs[local.scs_data_disks[count.index].vm_index].id) : (
                                           azurerm_windows_virtual_machine.scs[local.scs_data_disks[count.index].vm_index].id
                                         )
  caching                              = local.scs_data_disks[count.index].caching
  write_accelerator_enabled            = local.scs_data_disks[count.index].write_accelerator_enabled
  lun                                  = local.scs_data_disks[count.index].lun
}

resource "azurerm_virtual_machine_extension" "scs_lnx_aem_extension" {
  provider                             = azurerm.main
  count                                = local.enable_deployment && var.application_tier.deploy_v1_monitoring_extension && upper(var.application_tier.scs_os.os_type) == "LINUX" ? (
                                           local.scs_server_count) : (
                                           0
                                         )
  name                                 = "MonitorX64Linux"
  virtual_machine_id                   = azurerm_linux_virtual_machine.scs[count.index].id
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


resource "azurerm_virtual_machine_extension" "scs_win_aem_extension" {
  provider                             = azurerm.main
  count                                = local.enable_deployment && var.application_tier.deploy_v1_monitoring_extension && upper(var.application_tier.scs_os.os_type) == "WINDOWS" ? (
                                           local.scs_server_count) : (
                                           0
                                         )
  name                                 = "MonitorX64Windows"
  virtual_machine_id                   = azurerm_windows_virtual_machine.scs[count.index].id
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

resource "azurerm_virtual_machine_extension" "configure_ansible_scs" {

  provider                             = azurerm.main
  count                                = local.enable_deployment && upper(var.application_tier.scs_os.os_type) == "WINDOWS" ? (
                                           local.scs_server_count) : (
                                           0
                                         )

  depends_on                           = [azurerm_virtual_machine_data_disk_attachment.scs]

  virtual_machine_id                   = azurerm_windows_virtual_machine.scs[count.index].id
  name                                 = "configure_ansible"
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
  provider                              = azurerm.main
  count                                 = (
                                            local.enable_deployment &&
                                            var.application_tier.scs_high_availability &&
                                            (
                                              upper(var.application_tier.scs_os.os_type) == "WINDOWS" ||
                                              (
                                                upper(var.application_tier.scs_os.os_type) == "LINUX" &&
                                                upper(var.application_tier.scs_cluster_type) == "ASD"
                                              )
                                            )
                                          ) ? 1 : 0

  name                                  = format("%s%s%s%s",
                                            var.naming.resource_prefixes.scs_cluster_disk,
                                            local.prefix,
                                            var.naming.separator,
                                            var.naming.resource_suffixes.scs_cluster_disk
                                          )
  location                              = var.resource_group[0].location
  resource_group_name                   = var.resource_group[0].name
  create_option                         = "Empty"
  storage_account_type                  = var.application_tier.scs_cluster_disk_type
  disk_size_gb                          = var.application_tier.scs_cluster_disk_size
  disk_encryption_set_id                = try(var.options.disk_encryption_set_id, null)
  max_shares                            = local.scs_server_count

  zone                                  = (var.application_tier.scs_cluster_disk_type == "Premium_LRS") && !local.use_scs_avset ? (
                                            upper(var.application_tier.scs_os.os_type) == "LINUX" ? (
                                              azurerm_linux_virtual_machine.scs[local.scs_data_disks[count.index].vm_index].zone) : (
                                              azurerm_windows_virtual_machine.scs[local.scs_data_disks[count.index].vm_index].zone
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
  provider                              = azurerm.main
  count                                 = (
                                            local.enable_deployment &&
                                            var.application_tier.scs_high_availability &&
                                            (
                                              upper(var.application_tier.scs_os.os_type) == "WINDOWS" ||
                                              (
                                                upper(var.application_tier.scs_os.os_type) == "LINUX" &&
                                                upper(var.application_tier.scs_cluster_type) == "ASD"
                                              )
                                            )
                                          ) ? local.scs_server_count : 0

  managed_disk_id                       = azurerm_managed_disk.cluster[0].id
  virtual_machine_id                    = (upper(var.application_tier.scs_os.os_type) == "LINUX"                    # If Linux
                                          ) ? (
                                            azurerm_linux_virtual_machine.scs[count.index].id
                                          ) : (
                                            (upper(var.application_tier.scs_os.os_type) == "WINDOWS"                # If Windows
                                            ) ? (
                                              azurerm_windows_virtual_machine.scs[count.index].id
                                            ) : (
                                              null                                                                  # If Other
                                            )
                                          )
  caching                               = "None"
  lun                                   = var.application_tier.scs_cluster_disk_lun
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
                                           var.application_tier.scs_high_availability &&
                                           (
                                               upper(var.application_tier.scs_os.os_type) == "LINUX" &&
                                               ( var.application_tier.fence_kdump_disk_size > 0 )
                                           )
                                         ) ? local.scs_server_count : 0

  name                                 = format("%s%s%s%s%s",
                                           try( var.naming.resource_prefixes.fence_kdump_disk, ""),
                                           local.prefix,
                                           var.naming.separator,
                                           var.naming.virtualmachine_names.SCS_VMNAME[count.index],
                                           try( var.naming.resource_suffixes.fence_kdump_disk, "fence_kdump_disk" )
                                         )
  location                             = var.resource_group[0].location
  resource_group_name                  = var.resource_group[0].name
  create_option                        = "Empty"
  storage_account_type                 = "Premium_LRS"
  disk_size_gb                         = try(var.application_tier.fence_kdump_disk_size,64)
  disk_encryption_set_id               = try(var.options.disk_encryption_set_id, null)
  tags                                 = var.tags

  zone                                 = local.scs_zonal_deployment ? (
                                           upper(var.application_tier.scs_os.os_type) == "LINUX" ? (
                                             azurerm_linux_virtual_machine.scs[count.index].zone) :
                                             null
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
                                           var.application_tier.scs_high_availability &&
                                           (
                                               upper(var.application_tier.scs_os.os_type) == "LINUX" &&
                                               ( var.application_tier.fence_kdump_disk_size > 0 )
                                           )
                                         ) ? local.scs_server_count : 0

  managed_disk_id                      = azurerm_managed_disk.kdump[count.index].id
  virtual_machine_id                   = (upper(var.application_tier.scs_os.os_type) == "LINUX"                                # If Linux
                                         ) ? (
                                           azurerm_linux_virtual_machine.scs[count.index].id
                                         ) : null
  caching                              = "None"
  lun                                  = var.application_tier.fence_kdump_lun_number
}

resource "azurerm_virtual_machine_extension" "monitoring_extension_scs_lnx" {
  provider                             = azurerm.main
  count                                = local.deploy_monitoring_extension  && upper(var.application_tier.scs_os.os_type) == "LINUX" ? (
                                           local.scs_server_count) : (
                                           0                                           )
  virtual_machine_id                   = azurerm_linux_virtual_machine.scs[count.index].id
  name                                 = "Microsoft.Azure.Monitor.AzureMonitorLinuxAgent"
  publisher                            = "Microsoft.Azure.Monitor"
  type                                 = "AzureMonitorLinuxAgent"
  type_handler_version                 = "1.0"
  auto_upgrade_minor_version           = true
  automatic_upgrade_enabled            = true
}


resource "azurerm_virtual_machine_extension" "monitoring_extension_scs_win" {
  provider                             = azurerm.main
  count                                = local.deploy_monitoring_extension  && upper(var.application_tier.scs_os.os_type) == "WINDOWS" ? (
                                           local.scs_server_count) : (
                                           0                                           )
  virtual_machine_id                   = azurerm_windows_virtual_machine.scs[count.index].id
  name                                 = "Microsoft.Azure.Monitor.AzureMonitorWindowsAgent"
  publisher                            = "Microsoft.Azure.Monitor"
  type                                 = "AzureMonitorWindowsAgent"
  type_handler_version                 = "1.0"
  auto_upgrade_minor_version           = true
  automatic_upgrade_enabled            = true
}


resource "azurerm_virtual_machine_extension" "monitoring_defender_scs_lnx" {
  provider                             = azurerm.main
  count                                = var.infrastructure.deploy_defender_extension && upper(var.application_tier.scs_os.os_type) == "LINUX" ? (
                                           local.scs_server_count) : (
                                           0                                           )
  virtual_machine_id                   = azurerm_linux_virtual_machine.scs[count.index].id
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

resource "azurerm_virtual_machine_extension" "monitoring_defender_scs_win" {
  provider                             = azurerm.main
  count                                = var.infrastructure.deploy_defender_extension && upper(var.application_tier.scs_os.os_type) == "WINDOWS" ? (
                                           local.scs_server_count) : (
                                           0                                           )
  virtual_machine_id                   = azurerm_windows_virtual_machine.scs[count.index].id
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
