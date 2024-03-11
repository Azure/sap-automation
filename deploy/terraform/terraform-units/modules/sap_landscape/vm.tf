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
                    subnet_id                     = local.application_subnet_existing ? var.infrastructure.vnets.sap.subnet_app.arm_id : azurerm_subnet.app[0].id
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


}

