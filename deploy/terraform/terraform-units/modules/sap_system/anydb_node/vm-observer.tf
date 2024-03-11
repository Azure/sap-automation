

#######################################4#######################################8
#                                                                              #
#                           Primary Network Interface                          #
#                                                                              #
#######################################4#######################################8
resource "azurerm_network_interface" "observer" {
  provider                             = azurerm.main
  count                                = local.deploy_observer ? 1 : 0
  name                                 = format("%s%s%s%s%s",
                                           var.naming.resource_prefixes.nic,
                                           local.prefix,
                                           var.naming.separator,
                                           var.naming.virtualmachine_names.OBSERVER_VMNAME[count.index],
                                           local.resource_suffixes.nic
                                         )
  resource_group_name                  = var.resource_group[0].name
  location                             = var.resource_group[0].location
  enable_accelerated_networking        = false
  tags                                 = var.tags

  ip_configuration {
                    name      = "IPConfig1"
                    subnet_id = var.db_subnet.id
                    private_ip_address = var.database.use_DHCP ? (
                      null) : (
                      try(local.observer.nic_ips[count.index],
                        cidrhost(
                          var.db_subnet.address_prefixes[0],
                          tonumber(count.index) + local.anydb_ip_offsets.observer_db_vm
                        )
                      )
                    )
                    private_ip_address_allocation = var.database.use_DHCP ? "Dynamic" : "Static"

                  }
}



#######################################4#######################################8
#                                                                              #
#                               Virtual Machine                                #
#                                                                              #
#######################################4#######################################8

resource "azurerm_linux_virtual_machine" "observer" {
  provider                             = azurerm.main
  count                                = local.deploy_observer  && upper(local.anydb_ostype) == "LINUX" ? 1 : 0
  depends_on                           = [var.anchor_vm]
  resource_group_name                  = var.resource_group[0].name
  location                             = var.resource_group[0].location

  name                                 = format("%s%s%s%s%s",
                                           var.naming.resource_prefixes.vm,
                                           local.prefix,
                                           var.naming.separator,
                                           var.naming.virtualmachine_names.OBSERVER_VMNAME[count.index],
                                           local.resource_suffixes.vm
                                         )
  computer_name                         = var.naming.virtualmachine_names.OBSERVER_COMPUTERNAME[count.index]

  admin_username                        = var.sid_username
  admin_password                        = local.enable_auth_key ? null : var.sid_password
  disable_password_authentication       = !local.enable_auth_password

  zone                                 = local.zonal_deployment ? local.zones[count.index % max(local.db_zone_count, 1)] : null

  network_interface_ids                = [
                                           azurerm_network_interface.observer[count.index].id
                                         ]
  size                                 = local.observer_size
  source_image_id                      = local.observer_custom_image ? local.observer_custom_image_id : null

  custom_data                          = var.deployment == "new" ? var.cloudinit_growpart_config : null

  license_type                         = length(var.license_type) > 0 ? var.license_type : null

  tags                                 = merge(local.tags, var.tags)

  dynamic "admin_ssh_key" {
                            for_each = range(var.deployment == "new" ? 1 : (local.enable_auth_password ? 0 : 1))
                            content {
                              username   = var.sid_username
                              public_key = var.sdu_public_key
                            }
                          }

  os_disk {
            name = format("%s%s%s%s%s",
              var.naming.resource_prefixes.osdisk,
              local.prefix,
              var.naming.separator,
              var.naming.virtualmachine_names.OBSERVER_VMNAME[count.index],
              local.resource_suffixes.osdisk
            )
            caching                = "ReadWrite"
            storage_account_type   = "Premium_LRS"
            disk_encryption_set_id = try(var.options.disk_encryption_set_id, null)
          }


  dynamic "source_image_reference" {
                                     for_each = range(local.observer_custom_image ? 0 : 1)
                                     content {
                                       publisher = local.observer_os.publisher
                                       offer     = local.observer_os.offer
                                       sku       = local.observer_os.sku
                                       version   = local.observer_os.version
                                     }
                                   }

  boot_diagnostics {
                     storage_account_uri = var.storage_bootdiag_endpoint
                   }

}

# Create the Windows Application VM(s)
resource "azurerm_windows_virtual_machine" "observer" {
  provider                             = azurerm.main
  count                                = local.deploy_observer  && upper(local.anydb_ostype) == "WINDOWS" ? 1 : 0
  depends_on                           = [var.anchor_vm]
  resource_group_name                  = var.resource_group[0].name
  location                             = var.resource_group[0].location

  name                                 = format("%s%s%s%s%s",
                                           var.naming.resource_prefixes.vm,
                                           local.prefix,
                                           var.naming.separator,
                                           var.naming.virtualmachine_names.OBSERVER_VMNAME[count.index],
                                           local.resource_suffixes.vm
                                         )
  computer_name                         = var.naming.virtualmachine_names.OBSERVER_COMPUTERNAME[count.index]

  admin_username                        = var.sid_username
  admin_password                        = var.sid_password

  zone                                 = local.zonal_deployment ? local.zones[count.index % max(local.db_zone_count, 1)] : null

  network_interface_ids                = [
                                           azurerm_network_interface.observer[count.index].id
                                         ]
  size                                 = local.observer_size
  source_image_id                      = local.observer_custom_image ? local.observer_custom_image_id : null

  custom_data                          = var.deployment == "new" ? var.cloudinit_growpart_config : null

  license_type                         = length(var.license_type) > 0 ? var.license_type : null

  tags                                 = merge(local.tags, var.tags)


  os_disk {
            name = format("%s%s%s%s%s",
              var.naming.resource_prefixes.osdisk,
              local.prefix,
              var.naming.separator,
              var.naming.virtualmachine_names.OBSERVER_VMNAME[count.index],
              local.resource_suffixes.osdisk
            )
            caching                = "ReadWrite"
            storage_account_type   = "Premium_LRS"
            disk_encryption_set_id = try(var.options.disk_encryption_set_id, null)
          }


  dynamic "source_image_reference" {
                                     for_each = range(local.observer_custom_image ? 0 : 1)
                                     content {
                                       publisher = local.observer_os.publisher
                                       offer     = local.observer_os.offer
                                       sku       = local.observer_os.sku
                                       version   = local.observer_os.version
                                     }
                                   }

  boot_diagnostics {
                     storage_account_uri = var.storage_bootdiag_endpoint
                   }
  lifecycle {
    ignore_changes = [
      source_image_id
    ]
  }
}
