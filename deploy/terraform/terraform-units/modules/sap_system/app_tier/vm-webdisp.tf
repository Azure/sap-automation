# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.


#######################################4#######################################8
#                                                                              #
#                           Primary Network Interface                          #
#                                                                              #
#######################################4#######################################8
resource "azurerm_network_interface" "web" {
  provider                             = azurerm.main
  count                                = local.enable_deployment ? local.webdispatcher_count : 0
  name                                 = format("%s%s%s%s%s",
                                           var.naming.resource_prefixes.nic,
                                           local.prefix,
                                           var.naming.separator,
                                           var.naming.virtualmachine_names.WEB_VMNAME[count.index],
                                           local.resource_suffixes.nic
                                         )
  location                             = var.resource_group[0].location
  resource_group_name                  = var.resource_group[0].name
  accelerated_networking_enabled       = local.web_sizing.compute.accelerated_networking
  tags                                 = var.tags

  dynamic "ip_configuration" {
                                iterator = pub
                                for_each = local.web_dispatcher_ips
                                content {
                                          name      = pub.value.name
                                          subnet_id = pub.value.subnet_id

                                          private_ip_address = try(pub.value.nic_ips[count.index],
                                            var.application_tier.use_DHCP ? (
                                              null) : (
                                              var.infrastructure.virtual_networks.sap.subnet_web.defined ?
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

}

resource "azurerm_network_interface_application_security_group_association" "web" {
  provider                             = azurerm.main
  count                                = local.enable_deployment ? (
                                           var.deploy_application_security_groups ? local.webdispatcher_count : 0) : (
                                           0
                                         )

  network_interface_id                 = azurerm_network_interface.web[count.index].id
  application_security_group_id        = azurerm_application_security_group.web[0].id
}


#######################################4#######################################8
#                                                                              #
#                             Admin Network Interface                          #
#                                                                              #
#######################################4#######################################8

resource "azurerm_network_interface" "web_admin" {
  provider                             = azurerm.main
  count                                = local.enable_deployment && var.application_tier.dual_nics && length(try(var.admin_subnet.id, "")) > 0 ? (
                                           local.webdispatcher_count) : (
                                           0
                                         )
  name                                 = format("%s%s%s%s%s",
                                           var.naming.resource_prefixes.admin_nic,
                                           local.prefix,
                                           var.naming.separator,
                                           var.naming.virtualmachine_names.WEB_VMNAME[count.index],
                                           local.resource_suffixes.admin_nic
                                         )
  location                             = var.resource_group[0].location
  resource_group_name                  = var.resource_group[0].name
  accelerated_networking_enabled        = local.web_sizing.compute.accelerated_networking

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
  provider                             = azurerm.main
  count                                = local.enable_deployment && upper(var.application_tier.web_os.os_type) == "LINUX" ? (
                                           local.webdispatcher_count) : (
                                           0
                                         )
  name                                 = format("%s%s%s%s%s",
                                           var.naming.resource_prefixes.vm,
                                           local.prefix,
                                           var.naming.separator,
                                           var.naming.virtualmachine_names.WEB_VMNAME[count.index],
                                           local.resource_suffixes.vm
                                         )
  computer_name                        = var.naming.virtualmachine_names.WEB_COMPUTERNAME[count.index]
  location                             = var.resource_group[0].location
  resource_group_name                  = var.resource_group[0].name

  proximity_placement_group_id         = var.application_tier.web_use_ppg ? (
                                           local.web_zonal_deployment ? var.ppg[count.index % max(local.web_zone_count, 1)] : var.ppg[0]) : (
                                           null
                                         )

  //If more than one servers are deployed into a single zone put them in an availability set and not a zone
  availability_set_id                  = local.use_web_avset ? (
                                           azurerm_availability_set.web[count.index % max(length(azurerm_availability_set.web), 1)].id
                                           ) : (
                                           null
                                         )

  virtual_machine_scale_set_id         = length(var.scale_set_id) > 0 ? var.scale_set_id : null

  patch_mode                                             = var.infrastructure.patch_mode

  patch_assessment_mode                                  = var.infrastructure.patch_assessment_mode
  bypass_platform_safety_checks_on_user_schedule_enabled = var.infrastructure.patch_mode != "AutomaticByPlatform" ? false : true
  vm_agent_platform_updates_enabled                      = true
  //If length of zones > 1 distribute servers evenly across zones
  zone                                 = local.use_web_avset ? null : try(local.web_zones[count.index % max(local.web_zone_count, 1)], null)

  network_interface_ids                = var.application_tier.dual_nics ? (
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

  size                                 = length(local.web_size) > 0 ? (
                                           local.web_size) : (
                                           local.web_sizing.compute.vm_size
                                         )
  admin_username                       = var.sid_username
  admin_password                       = local.enable_auth_key ? null : var.sid_password
  disable_password_authentication      = !local.enable_auth_password

  custom_data                          = var.deployment == "new" ? var.cloudinit_growpart_config : null

  source_image_id                      = var.application_tier.web_os.type == "custom" ? var.application_tier.web_os.source_image_id : null
  license_type                         = length(var.license_type) > 0 ? var.license_type : null
  # ToDo Add back later
# patch_mode                           = var.infrastructure.patch_mode

  tags                                 = merge(var.application_tier.web_tags, var.tags)

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


  dynamic "source_image_reference" {
                                     for_each = range(var.application_tier.web_os.type == "marketplace" || var.application_tier.web_os.type == "marketplace_with_plan" ? 1 : 0)
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
                     name      = var.application_tier.web_os.sku
                     publisher = var.application_tier.web_os.publisher
                     product   = var.application_tier.web_os.offer
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

# Create the Windows Web dispatcher VM(s)
resource "azurerm_windows_virtual_machine" "web" {
  provider                             = azurerm.main
  count                                = local.enable_deployment && upper(var.application_tier.web_os.os_type) == "WINDOWS" ? (
                                           local.webdispatcher_count) : (
                                           0
                                         )
  name                                 = format("%s%s%s%s%s",
                                           var.naming.resource_prefixes.vm,
                                           local.prefix,
                                           var.naming.separator,
                                           var.naming.virtualmachine_names.WEB_VMNAME[count.index],
                                           local.resource_suffixes.vm
                                         )
  computer_name                        = var.naming.virtualmachine_names.WEB_COMPUTERNAME[count.index]
  location                             = var.resource_group[0].location
  resource_group_name                  = var.resource_group[0].name

  proximity_placement_group_id         = var.application_tier.web_use_ppg ? (
                                           local.web_zonal_deployment ? var.ppg[count.index % max(local.web_zone_count, 1)] : var.ppg[0]) : (
                                           null
                                         )

  //If more than one servers are deployed into a single zone put them in an availability set and not a zone
  availability_set_id                  = local.use_web_avset ? (
                                           azurerm_availability_set.web[count.index % max(length(azurerm_availability_set.web), 1)].id
                                           ) : (
                                           null
                                         )

  virtual_machine_scale_set_id         = length(var.scale_set_id) > 0 ? var.scale_set_id : null

  // ImageDefault = Manual on Windows
  // https://learn.microsoft.com/en-us/azure/virtual-machines/automatic-vm-guest-patching#patch-orchestration-modes
  patch_mode                                             = var.infrastructure.patch_mode == "ImageDefault" ? "Manual" : var.infrastructure.patch_mode
  patch_assessment_mode                                  = var.infrastructure.patch_assessment_mode
  bypass_platform_safety_checks_on_user_schedule_enabled = var.infrastructure.patch_mode != "AutomaticByPlatform" ? false : true
  vm_agent_platform_updates_enabled                      = true
  enable_automatic_updates                               = !(var.infrastructure.patch_mode == "ImageDefault")

  //If length of zones > 1 distribute servers evenly across zones
  zone                                 = local.use_web_avset ? (
                                           null) : (
                                           try(local.web_zones[count.index % max(local.web_zone_count, 1)], null)
                                         )

  network_interface_ids                = var.application_tier.dual_nics ? (
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

  size                                 = local.web_sizing.compute.vm_size
  admin_username                       = var.sid_username
  admin_password                       = var.sid_password

  source_image_id                      = var.application_tier.web_os.type == "custom" ? var.application_tier.web_os.source_image_id : null

  #ToDo: Remove once feature is GA  patch_mode = "Manual"
  license_type                         = length(var.license_type) > 0 ? var.license_type : null
  # ToDo Add back later
# patch_mode                           = var.infrastructure.patch_mode

  tags                                 = merge(var.application_tier.web_tags, var.tags)

  encryption_at_host_enabled           = var.infrastructure.encryption_at_host_enabled

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
                                  var.naming.virtualmachine_names.WEB_VMNAME[count.index],
                                  local.resource_suffixes.osdisk
                                )
                                caching                = disk.value.caching
                                storage_account_type   = disk.value.disk_type
                                disk_size_gb           = disk.value.size_gb
                                disk_encryption_set_id = try(var.options.disk_encryption_set_id, null)
                              }
                    }

  dynamic "source_image_reference" {
                                     for_each = range(var.application_tier.web_os.type == "marketplace" || var.application_tier.web_os.type == "marketplace_with_plan" ? 1 : 0)
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
                             name      = var.application_tier.web_os.sku
                             publisher = var.application_tier.web_os.publisher
                             product   = var.application_tier.web_os.offer
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
resource "azurerm_managed_disk" "web" {
  provider                             = azurerm.main
  count                                = local.enable_deployment ? length(local.web_data_disks) : 0
  name                                 = format("%s%s%s%s%s",
                                           var.naming.resource_prefixes.disk,
                                           local.prefix,
                                           var.naming.separator,
                                           var.naming.virtualmachine_names.WEB_VMNAME[local.web_data_disks[count.index].vm_index],
                                           local.web_data_disks[count.index].suffix
                                         )
  location                             = var.resource_group[0].location
  resource_group_name                  = var.resource_group[0].name
  create_option                        = "Empty"
  storage_account_type                 = local.web_data_disks[count.index].storage_account_type
  disk_size_gb                         = local.web_data_disks[count.index].disk_size_gb
  disk_encryption_set_id               = try(var.options.disk_encryption_set_id, null)
  tags                                 = var.tags

  zone                                 = !local.use_web_avset ? (
                                           upper(var.application_tier.web_os.os_type) == "LINUX" ? (
                                             azurerm_linux_virtual_machine.web[local.web_data_disks[count.index].vm_index].zone) : (
                                             azurerm_windows_virtual_machine.web[local.web_data_disks[count.index].vm_index].zone
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

resource "azurerm_virtual_machine_data_disk_attachment" "web" {
  provider                             = azurerm.main
  count                                = local.enable_deployment ? length(local.web_data_disks) : 0
  managed_disk_id                      = azurerm_managed_disk.web[count.index].id
  virtual_machine_id                   = upper(var.application_tier.web_os.os_type) == "LINUX" ? (
                                           azurerm_linux_virtual_machine.web[local.web_data_disks[count.index].vm_index].id) : (
                                           azurerm_windows_virtual_machine.web[local.web_data_disks[count.index].vm_index].id
                                         )
  caching                              = local.web_data_disks[count.index].caching
  write_accelerator_enabled            = local.web_data_disks[count.index].write_accelerator_enabled
  lun                                  = local.web_data_disks[count.index].lun
}

resource "azurerm_virtual_machine_extension" "web_lnx_aem_extension" {
  provider                             = azurerm.main
  count                                = local.enable_deployment && var.application_tier.deploy_v1_monitoring_extension && upper(var.application_tier.web_os.os_type) == "LINUX" ? (
                                           local.webdispatcher_count) : (
                                           0
                                         )
  name                                 = "MonitorX64Linux"
  virtual_machine_id                   = azurerm_linux_virtual_machine.web[count.index].id
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


resource "azurerm_virtual_machine_extension" "web_win_aem_extension" {
  provider                             = azurerm.main
  count                                = local.enable_deployment && var.application_tier.deploy_v1_monitoring_extension && upper(var.application_tier.web_os.os_type) == "WINDOWS" ? (
                                           local.webdispatcher_count) : (
                                           0
                                         )
  name                                 = "MonitorX64Windows"
  virtual_machine_id                   = azurerm_windows_virtual_machine.web[count.index].id
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

resource "azurerm_virtual_machine_extension" "configure_ansible_web" {

  provider                             = azurerm.main
  count                                = local.enable_deployment && upper(var.application_tier.web_os.os_type) == "WINDOWS" ? (
                                           local.webdispatcher_count) : (
                                           0
                                         )

  depends_on                           = [azurerm_virtual_machine_data_disk_attachment.web]

  virtual_machine_id                   = azurerm_windows_virtual_machine.web[count.index].id
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

#######################################4#######################################8
#                                                                              #
#                   Create the Wewb Load Balancer                               #
#                                                                              #
#######################################4#######################################8


# Create the Web dispatcher Load Balancer
resource "azurerm_lb" "web" {
  provider                             = azurerm.main
  count                                = local.enable_web_lb_deployment ? 1 : 0
  name                                 = format("%s%s%s%s",
                                           var.naming.resource_prefixes.web_alb,
                                           local.prefix,
                                           var.naming.separator,
                                           local.resource_suffixes.web_alb
                                         )
  resource_group_name                  = var.resource_group[0].name
  location                             = var.resource_group[0].location
  sku                                  = "Standard"
  tags                                 = var.tags

  frontend_ip_configuration {
                              name = format("%s%s%s%s",
                                var.naming.resource_prefixes.web_alb_feip,
                                local.prefix,
                                var.naming.separator,
                                local.resource_suffixes.web_alb_feip
                              )
                              subnet_id = local.web_subnet_deployed.id
                              private_ip_address = var.application_tier.use_DHCP ? (
                                null) : (
                                try(
                                  local.webdispatcher_loadbalancer_ips[0],
                                  cidrhost(
                                    local.web_subnet_deployed.address_prefixes[0],
                                    local.ip_offsets.web_lb
                                  )
                                )
                              )
                              private_ip_address_allocation = var.application_tier.use_DHCP ? "Dynamic" : "Static"
                              zones                         = ["1", "2", "3"]
                            }
}

resource "azurerm_lb_backend_address_pool" "web" {
  provider                             = azurerm.main
  count                                = local.enable_web_lb_deployment ? 1 : 0
  name                                 = format("%s%s%s%s",
                                            var.naming.resource_prefixes.web_alb_bepool,
                                            local.prefix,
                                            var.naming.separator,
                                            local.resource_suffixes.web_alb_bepool
                                          )
  loadbalancer_id                      = azurerm_lb.web[0].id
}

resource "azurerm_lb_probe" "web" {
  provider                             = azurerm.main
  count                                = local.enable_web_lb_deployment ? 1 : 0
  loadbalancer_id                      = azurerm_lb.web[0].id
  name                                 = format("%s%s%s%s",
                                           var.naming.resource_prefixes.web_alb_hp,
                                           local.prefix,
                                           var.naming.separator,
                                           local.resource_suffixes.web_alb_hp
                                         )
  port                                 = 443
  protocol                             = "Tcp"
  interval_in_seconds                  = 5
  number_of_probes                     = 2
  probe_threshold                      = 2
}

# Create the Web dispatcher Load Balancer Rules
resource "azurerm_lb_rule" "web" {
  provider                             = azurerm.main
  count                                = local.enable_web_lb_deployment ? 1 : 0
  loadbalancer_id                      = azurerm_lb.web[0].id
  name                                 = format("%s%s%s%s",
                                           var.naming.resource_prefixes.web_alb_inrule,
                                           local.prefix,
                                           var.naming.separator,
                                           local.resource_suffixes.web_alb_inrule
                                         )
  protocol                             = "All"
  frontend_port                        = 0
  backend_port                         = 0
  frontend_ip_configuration_name       = azurerm_lb.web[0].frontend_ip_configuration[0].name
  backend_address_pool_ids             = [azurerm_lb_backend_address_pool.web[0].id]
  enable_floating_ip                   = false
  probe_id                             = azurerm_lb_probe.web[0].id
}

# Associate Web dispatcher VM NICs with the Load Balancer Backend Address Pool
resource "azurerm_network_interface_backend_address_pool_association" "web" {
  provider                             = azurerm.main
  count                                = local.enable_web_lb_deployment ? local.webdispatcher_count : 0
  depends_on                           = [azurerm_lb_backend_address_pool.web]
  network_interface_id                 = azurerm_network_interface.web[count.index].id
  ip_configuration_name                = azurerm_network_interface.web[count.index].ip_configuration[0].name
  backend_address_pool_id              = azurerm_lb_backend_address_pool.web[0].id
}

##############################################################################################
#
#  Create the Web dispatcher Availability Set
#
##############################################################################################

resource "azurerm_availability_set" "web" {
  provider                             = azurerm.main
  count                                = local.use_web_avset ? max(length(local.web_zones), 1) : 0
  name                                 = format("%s%s%s",
                                           local.prefix, var.naming.separator,
                                           var.naming.availabilityset_names.web[count.index]
                                         )
  location                             = var.resource_group[0].location
  resource_group_name                  = var.resource_group[0].name
  platform_update_domain_count         = 20
  platform_fault_domain_count          = local.faultdomain_count
  proximity_placement_group_id         = try(local.web_zonal_deployment ? var.ppg[count.index % length(local.web_zones)] : var.ppg[0], null)
  managed                              = true

  tags                                 = var.tags

}

resource "azurerm_virtual_machine_extension" "monitoring_extension_web_lnx" {
  provider                             = azurerm.main
  count                                = local.deploy_monitoring_extension  && upper(var.application_tier.web_os.os_type) == "LINUX" ? (
                                           local.webdispatcher_count) : (
                                           0                                           )
  virtual_machine_id                   = azurerm_linux_virtual_machine.web[count.index].id
  name                                 = "Microsoft.Azure.Monitor.AzureMonitorLinuxAgent"
  publisher                            = "Microsoft.Azure.Monitor"
  type                                 = "AzureMonitorLinuxAgent"
  type_handler_version                 = "1.0"
  auto_upgrade_minor_version           = true
  automatic_upgrade_enabled            = true
}


resource "azurerm_virtual_machine_extension" "monitoring_extension_web_win" {
  provider                             = azurerm.main
  count                                = local.deploy_monitoring_extension  && upper(var.application_tier.web_os.os_type) == "WINDOWS" ? (
                                           local.webdispatcher_count) : (
                                           0                                           )
  virtual_machine_id                   = azurerm_windows_virtual_machine.web[count.index].id
  name                                 = "Microsoft.Azure.Monitor.AzureMonitorWindowsAgent"
  publisher                            = "Microsoft.Azure.Monitor"
  type                                 = "AzureMonitorWindowsAgent"
  type_handler_version                 = "1.0"
  auto_upgrade_minor_version           = true
  automatic_upgrade_enabled            = true
}

resource "azurerm_virtual_machine_extension" "monitoring_defender_web_lnx" {
  provider                             = azurerm.main
  count                                = var.infrastructure.deploy_defender_extension  && upper(var.application_tier.scs_os.os_type) == "LINUX" ? (
                                           local.webdispatcher_count) : (
                                           0                                           )
  virtual_machine_id                   = azurerm_linux_virtual_machine.web[count.index].id
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

resource "azurerm_virtual_machine_extension" "monitoring_defender_web_win" {
  provider                             = azurerm.main
  count                                = var.infrastructure.deploy_defender_extension  && upper(var.application_tier.app_os.os_type) == "WINDOWS" ? (
                                           local.webdispatcher_count) : (
                                           0                                           )
  virtual_machine_id                   = azurerm_windows_virtual_machine.web[count.index].id
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

