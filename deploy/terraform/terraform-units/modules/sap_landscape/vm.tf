#########################################################################################
#                                                                                       #
#  Primary Network Interface                                                            #
#                                                                                       #
#########################################################################################

resource "azurerm_network_interface" "utility_vm" {
  provider = azurerm.main
  count    = var.vm_settings.count
  name = format("%s%s%s%s%s",
    var.naming.resource_prefixes.nic,
    local.prefix,
    var.naming.separator,
    var.naming.virtualmachine_names.WORKLOAD_VMNAME[count.index],
    local.resource_suffixes.nic
  )
  location = local.resource_group_exists ? (
    data.azurerm_resource_group.resource_group[0].location) : (
    azurerm_resource_group.resource_group[0].location
  )
  resource_group_name = local.resource_group_exists ? (
    data.azurerm_resource_group.resource_group[0].name) : (
    azurerm_resource_group.resource_group[0].name
  )

  ip_configuration {
    name      = "ipconfig1"
    subnet_id = local.application_subnet_existing ? local.application_subnet_arm_id : azurerm_subnet.app[0].id
    private_ip_address = var.vm_settings.use_DHCP ? (
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
  provider = azurerm.main
  count    = var.vm_settings.count
  name = format("%s%s%s%s%s",
    var.naming.resource_prefixes.vm,
    local.prefix,
    var.naming.separator,
    var.naming.virtualmachine_names.WORKLOAD_VMNAME[count.index],
    local.resource_suffixes.vm
  )
  computer_name = var.naming.virtualmachine_names.WORKLOAD_VMNAME[count.index]
  location = local.resource_group_exists ? (
    data.azurerm_resource_group.resource_group[0].location) : (
    azurerm_resource_group.resource_group[0].location
  )
  resource_group_name = local.resource_group_exists ? (
    data.azurerm_resource_group.resource_group[0].name) : (
    azurerm_resource_group.resource_group[0].name
  )

  network_interface_ids = [azurerm_network_interface.utility_vm[count.index].id]


  size           = var.vm_settings.size
  admin_username = local.input_sid_username
  admin_password = local.input_sid_password

  os_disk {
    name = format("%s%s%s%s%s",
      var.naming.resource_prefixes.osdisk,
      local.prefix,
      var.naming.separator,
      var.naming.virtualmachine_names.WORKLOAD_VMNAME[count.index],
      local.resource_suffixes.osdisk
    )
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
    disk_size_gb         = 128
  }

  source_image_reference {
    publisher = var.vm_settings.image.publisher
    offer     = var.vm_settings.image.offer
    sku       = var.vm_settings.image.sku
    version   = var.vm_settings.image.version
  }


}

