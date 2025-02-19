# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

#########################################################################################
#                                                                                       #
#  Primary Network Interface                                                            #
#                                                                                       #
#########################################################################################

resource "azurerm_network_interface" "utility_vm" {
  provider                             = azurerm.main
  count                                = var.vm_settings.count
  name                                 = format("%s%s%s%s%s",
                                           var.naming.resource_prefixes.nic,
                                           local.prefix,
                                           var.naming.separator,
                                           var.naming.virtualmachine_names.WORKLOAD_VMNAME[count.index],
                                           local.resource_suffixes.nic
                                         )
  location                             = local.resource_group_exists ? (
                                           data.azurerm_resource_group.resource_group[0].location) : (
                                           azurerm_resource_group.resource_group[0].location
                                         )
  resource_group_name                  = local.resource_group_exists ? (
                                           data.azurerm_resource_group.resource_group[0].name) : (
                                           azurerm_resource_group.resource_group[0].name
                                         )
  tags                                 = var.tags

  ip_configuration {
                    name                          = "ipconfig1"
                    subnet_id                     = local.application_subnet_existing ? var.infrastructure.virtual_networks.sap.subnet_app.arm_id : azurerm_subnet.app[0].id
                    private_ip_address            = var.vm_settings.use_DHCP ? (
                                                       null) : (var.vm_settings.private_ip_address[count.index]
                                                     )
                    private_ip_address_allocation = length(try(var.vm_settings.private_ip_address[count.index], "")) > 0 ? (
                                                      "Static") : (
                                                      "Dynamic"
                                                    )

                   }

}


# Create the Windows Application VM(s)
resource "azurerm_windows_virtual_machine" "utility_vm" {
  provider                             = azurerm.main
  count                                = upper(var.vm_settings.image.os_type) == "WINDOWS" ? var.vm_settings.count : 0
  name                                 = format("%s%s%s%s%s",
                                           var.naming.resource_prefixes.vm,
                                           local.prefix,
                                           var.naming.separator,
                                           var.naming.virtualmachine_names.WORKLOAD_VMNAME[count.index],
                                           local.resource_suffixes.vm
                                         )
  computer_name                        = var.naming.virtualmachine_names.WORKLOAD_VMNAME[count.index]
  location                             = local.resource_group_exists ? (
                                           data.azurerm_resource_group.resource_group[0].location) : (
                                           azurerm_resource_group.resource_group[0].location
                                         )
  resource_group_name                  = local.resource_group_exists ? (
                                           data.azurerm_resource_group.resource_group[0].name) : (
                                           azurerm_resource_group.resource_group[0].name
                                         )
  tags                                 = var.tags
  network_interface_ids                = [azurerm_network_interface.utility_vm[count.index].id]

  size                                 = var.vm_settings.size
  admin_username                       = local.input_sid_username
  admin_password                       = local.input_sid_password

  // ImageDefault = Manual on Windows
  // https://learn.microsoft.com/en-us/azure/virtual-machines/automatic-vm-guest-patching#patch-orchestration-modes
  patch_mode                                             = var.infrastructure.patch_mode == "ImageDefault" ? "Manual" : var.infrastructure.patch_mode
  patch_assessment_mode                                  = var.infrastructure.patch_assessment_mode
  bypass_platform_safety_checks_on_user_schedule_enabled = var.infrastructure.patch_mode != "AutomaticByPlatform" ? false : true
  vm_agent_platform_updates_enabled                      = true
  enable_automatic_updates                               = !(var.infrastructure.patch_mode == "ImageDefault")

  encryption_at_host_enabled                             = var.infrastructure.encryption_at_host_enabled 

  os_disk {
                 name                 = format("%s%s%s%s%s",
                                          var.naming.resource_prefixes.osdisk,
                                          local.prefix,
                                          var.naming.separator,
                                          var.naming.virtualmachine_names.WORKLOAD_VMNAME[count.index],
                                          local.resource_suffixes.osdisk
                                        )
                 caching              = "ReadWrite"
                 storage_account_type = try(var.vm_settings.disk_type, "Premium_LRS")
                 disk_size_gb         = try(var.vm_settings.disk_size, 128)
          }

  source_image_reference {
                           publisher  = var.vm_settings.image.publisher
                           offer      = var.vm_settings.image.offer
                           sku        = var.vm_settings.image.sku
                           version    = var.vm_settings.image.version
                         }
  dynamic "identity"     {
                           for_each = range(length(var.infrastructure.user_assigned_identity_id) > 0 ? 1 : 0)
                           content {
                                   type         = "UserAssigned"
                                   identity_ids = [var.infrastructure.user_assigned_identity_id]
                                 }
                          }


  lifecycle {
    ignore_changes = [
      source_image_id
    ]
  }
}

# Create the Linux Application VM(s)
resource "azurerm_linux_virtual_machine" "utility_vm" {
  provider                             = azurerm.main
  count                                = upper(var.vm_settings.image.os_type) == "LINUX" ? var.vm_settings.count : 0
  name                                 = format("%s%s%s%s%s",
                                           var.naming.resource_prefixes.vm,
                                           local.prefix,
                                           var.naming.separator,
                                           var.naming.virtualmachine_names.WORKLOAD_VMNAME[count.index],
                                           local.resource_suffixes.vm
                                         )
  computer_name                        = var.naming.virtualmachine_names.WORKLOAD_VMNAME[count.index]
  location                             = local.resource_group_exists ? (
                                           data.azurerm_resource_group.resource_group[0].location) : (
                                           azurerm_resource_group.resource_group[0].location
                                         )
  resource_group_name                  = local.resource_group_exists ? (
                                           data.azurerm_resource_group.resource_group[0].name) : (
                                           azurerm_resource_group.resource_group[0].name
                                         )
  tags                                 = var.tags
  network_interface_ids                = [azurerm_network_interface.utility_vm[count.index].id]

  size                                 = var.vm_settings.size
  admin_username                       = local.input_sid_username
  admin_password                       = local.input_sid_password
  disable_password_authentication      = true

  patch_mode                                             = var.infrastructure.patch_mode
  patch_assessment_mode                                  = var.infrastructure.patch_assessment_mode
  bypass_platform_safety_checks_on_user_schedule_enabled = var.infrastructure.patch_mode != "AutomaticByPlatform" ? false : true
  vm_agent_platform_updates_enabled                      = true

  encryption_at_host_enabled                             = var.infrastructure.encryption_at_host_enabled

  dynamic "admin_ssh_key"              {
                                        for_each = range(1)
                                        content {
                                          username   = local.input_sid_username
                                          public_key = local.sid_public_key
                                        }
                                      }


  os_disk                             {
                                         name                 = format("%s%s%s%s%s",
                                                                  var.naming.resource_prefixes.osdisk,
                                                                  local.prefix,
                                                                  var.naming.separator,
                                                                  var.naming.virtualmachine_names.WORKLOAD_VMNAME[count.index],
                                                                  local.resource_suffixes.osdisk
                                                                )
                                         caching              = "ReadWrite"
                                         storage_account_type = try(var.vm_settings.disk_type, "Premium_LRS")
                                         disk_size_gb         = try(var.vm_settings.disk_size, 128)
                                      }

  source_image_reference {
                           publisher  = var.vm_settings.image.publisher
                           offer      = var.vm_settings.image.offer
                           sku        = var.vm_settings.image.sku
                           version    = var.vm_settings.image.version

                         }
  dynamic "identity"     {
                           for_each = range(length(var.infrastructure.user_assigned_identity_id) > 0 ? 1 : 0)
                           content {
                                   type         = "UserAssigned"
                                   identity_ids = [var.infrastructure.user_assigned_identity_id]
                                 }
                          }


}


resource "azurerm_virtual_machine_extension" "monitoring_extension_utility_lnx" {
  provider                             = azurerm.main
  count                                = local.deploy_monitoring_extension && upper(var.vm_settings.image.os_type) == "LINUX" ? var.vm_settings.count : 0
  virtual_machine_id                   = azurerm_linux_virtual_machine.utility_vm[count.index].id
  name                                 = "Microsoft.Azure.Monitor.AzureMonitorLinuxAgent"
  publisher                            = "Microsoft.Azure.Monitor"
  type                                 = "AzureMonitorLinuxAgent"
  type_handler_version                 = "1.0"
  auto_upgrade_minor_version           = true
  automatic_upgrade_enabled            = true
}


resource "azurerm_virtual_machine_extension" "monitoring_extension_utility_win" {
  provider                             = azurerm.main
  count                                = local.deploy_monitoring_extension && upper(var.vm_settings.image.os_type) == "WINDOWS" ? var.vm_settings.count : 0

  virtual_machine_id                   = azurerm_windows_virtual_machine.utility_vm[count.index].id
  name                                 = "Microsoft.Azure.Monitor.AzureMonitorWindowsAgent"
  publisher                            = "Microsoft.Azure.Monitor"
  type                                 = "AzureMonitorWindowsAgent"
  type_handler_version                 = "1.0"
  auto_upgrade_minor_version           = true
  automatic_upgrade_enabled            = true
}


resource "azurerm_virtual_machine_extension" "monitoring_defender_utility_lnx" {
  provider                             = azurerm.main
  count                                = var.infrastructure.deploy_defender_extension && upper(var.vm_settings.image.os_type) == "LINUX" ? var.vm_settings.count : 0
  virtual_machine_id                   = azurerm_linux_virtual_machine.utility_vm[count.index].id
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

resource "azurerm_virtual_machine_extension" "monitoring_defender_utility_win" {
  provider                             = azurerm.main
  count                                = var.infrastructure.deploy_defender_extension && upper(var.vm_settings.image.os_type) == "WINDOWS" ? var.vm_settings.count : 0
  virtual_machine_id                   = azurerm_windows_virtual_machine.utility_vm[count.index].id
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
