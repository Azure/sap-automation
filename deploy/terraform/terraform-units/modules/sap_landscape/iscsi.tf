#######################################4#######################################8
#                                                                              #
#                                      iSCSI                                   #
#                                                                              #
#######################################4#######################################8


/*
  Only create/import iSCSI subnet and nsg when iSCSI device(s) will be deployed
*/

// Creates iSCSI subnet of SAP VNET
resource "azurerm_subnet" "iscsi" {
  provider                             = azurerm.main
  count                                = local.enable_sub_iscsi ? (local.sub_iscsi_exists ? 0 : 1) : 0
  name                                 = local.sub_iscsi_name
  resource_group_name                  = local.SAP_virtualnetwork_exists ? (
                                          data.azurerm_virtual_network.vnet_sap[0].resource_group_name) : (
                                          azurerm_virtual_network.vnet_sap[0].resource_group_name
                                        )
  virtual_network_name                 = local.SAP_virtualnetwork_exists ? (
                                           data.azurerm_virtual_network.vnet_sap[0].name) : (
                                           azurerm_virtual_network.vnet_sap[0].name
                                         )
  address_prefixes                     = [local.sub_iscsi_prefix]

}

// Imports data of existing SAP iSCSI subnet
data "azurerm_subnet" "iscsi" {
  provider                             = azurerm.main
  count                                = local.enable_sub_iscsi ? (local.sub_iscsi_exists ? 1 : 0) : 0
  name                                 = split("/", local.sub_iscsi_arm_id)[10]
  resource_group_name                  = split("/", local.sub_iscsi_arm_id)[4]
  virtual_network_name                 = split("/", local.sub_iscsi_arm_id)[8]
}

// Creates SAP iSCSI subnet nsg
resource "azurerm_network_security_group" "iscsi" {
  provider                             = azurerm.main
  count                                = local.enable_sub_iscsi ? (local.sub_iscsi_nsg_exists ? 0 : 1) : 0
  name                                 = local.sub_iscsi_nsg_name
  resource_group_name                  = local.resource_group_exists ? (
                                           data.azurerm_resource_group.resource_group[0].name) : (
                                           azurerm_resource_group.resource_group[0].name
                                         )
  location                             = local.resource_group_exists ? (
                                          data.azurerm_resource_group.resource_group[0].location) : (
                                          azurerm_resource_group.resource_group[0].location
                                        )
  tags                                 = var.tags
}

// Imports the SAP iSCSI subnet nsg data
data "azurerm_network_security_group" "iscsi" {
  provider                             = azurerm.main
  count                                = local.enable_sub_iscsi ? (local.sub_iscsi_nsg_exists ? 1 : 0) : 0
  name                                 = split("/", local.sub_iscsi_nsg_arm_id)[8]
  resource_group_name                  = split("/", local.sub_iscsi_nsg_arm_id)[4]
}

// TODO: Add nsr to iSCSI's nsg

/*
  iSCSI device IP address range: .4 -
*/
// Creates the NIC and IP address for iSCSI device
resource "azurerm_network_interface" "iscsi" {
  provider                             = azurerm.main
  count                                = local.iscsi_count
  name                                 = format("%s%s%s%s%s",
                                           var.naming.resource_prefixes.nic,
                                           local.prefix,
                                           var.naming.separator,
                                           local.virtualmachine_names[count.index],
                                           local.resource_suffixes.nic
                                         )
  resource_group_name                  = local.resource_group_exists ? (
                                           data.azurerm_resource_group.resource_group[0].name) : (
                                           azurerm_resource_group.resource_group[0].name
                                         )
  location                             = local.resource_group_exists ? (
                                          data.azurerm_resource_group.resource_group[0].location) : (
                                          azurerm_resource_group.resource_group[0].location
                                        )
  tags                                 = var.tags

  ip_configuration {
                     name = "ipconfig1"
                     subnet_id = local.sub_iscsi_exists ? (
                       data.azurerm_subnet.iscsi[0].id) : (
                       azurerm_subnet.iscsi[0].id
                     )
                     private_ip_address = local.use_DHCP ? (
                       null) : (
                       local.sub_iscsi_exists ? (
                         local.iscsi_nic_ips[count.index]) : (
                         cidrhost(local.sub_iscsi_prefix, tonumber(count.index) + 4)
                       )
                     )
                     private_ip_address_allocation = local.use_DHCP ? "Dynamic" : "Static"
                   }
}

// Manages the association between NIC and NSG
resource "azurerm_network_interface_security_group_association" "iscsi" {
  provider                             = azurerm.main
  count                                = local.iscsi_count
  network_interface_id                 = azurerm_network_interface.iscsi[count.index].id
  network_security_group_id            = local.sub_iscsi_nsg_exists ? (
                                            data.azurerm_network_security_group.iscsi[0].id) : (
                                            azurerm_network_security_group.iscsi[0].id
                                          )
}

// Manages Linux Virtual Machine for iSCSI
resource "azurerm_linux_virtual_machine" "iscsi" {
  provider                             = azurerm.main
  count                                = local.iscsi_count
  name                                 = format("%s%s%s%s%s",
                                           var.naming.resource_prefixes.vm,
                                           local.prefix,
                                           var.naming.separator,
                                           local.virtualmachine_names[count.index],
                                           local.resource_suffixes.vm
                                         )
  computer_name                        = local.virtualmachine_names[count.index]
  resource_group_name                  = local.resource_group_exists ? (
                                           data.azurerm_resource_group.resource_group[0].name) : (
                                           azurerm_resource_group.resource_group[0].name
                                         )
  location                             = local.resource_group_exists ? (
                                          data.azurerm_resource_group.resource_group[0].location) : (
                                          azurerm_resource_group.resource_group[0].location
                                        )
  tags                                 = var.tags
  network_interface_ids                = [azurerm_network_interface.iscsi[count.index].id]
  size                                 = local.iscsi.size
  admin_username                       = local.iscsi.authentication.username
  admin_password                       = local.iscsi_auth_password
  disable_password_authentication      = local.enable_iscsi_auth_key

  //If length of zones > 1 distribute servers evenly across zones
  zone                                 = try(local.iscsi.zones[count.index % max(length(local.iscsi.zones), 1)], null)

  //custom_data = try(data.template_cloudinit_config.config_growpart.rendered, "Cg==")

  os_disk {
            name = format("%s%s%s%s%s",
              var.naming.resource_prefixes.osdisk,
              local.prefix,
              var.naming.separator,
              local.virtualmachine_names[count.index],
              local.resource_suffixes.osdisk
            )
            caching              = "ReadWrite"
            storage_account_type = "Premium_LRS"
          }

  source_image_reference {
                           publisher = local.iscsi.os.publisher
                           offer     = local.iscsi.os.offer
                           sku       = local.iscsi.os.sku
                           version   = "latest"
                         }

  dynamic "admin_ssh_key" {
                            for_each = range(local.enable_iscsi_auth_key ? 1 : 0)
                            content {
                              username   = local.iscsi_auth_username
                              public_key = local.iscsi_public_key
                            }
                          }

  boot_diagnostics {
                     storage_account_uri = length(var.diagnostics_storage_account.arm_id) > 0 ? (
                       data.azurerm_storage_account.storage_bootdiag[0].primary_blob_endpoint) : (
                       azurerm_storage_account.storage_bootdiag[0].primary_blob_endpoint
                     )
                   }
  dynamic "identity"   {
                         for_each = range(length(var.infrastructure.iscsi.user_assigned_identity_id) > 0 ? 1 : 0)
                         content {
                                   type         = "UserAssigned"
                                   identity_ids = [var.infrastructure.iscsi.user_assigned_identity_id]
                                 }
                       }

}


// Define a cloud-init config that disables the automatic expansion
// of the root partition.
data "template_cloudinit_config" "config_growpart" {
  gzip                                 = true
  base64_encode                        = true

  # Main cloud-config configuration file.
  part {
         content_type = "text/cloud-config"
         content      = "growpart: {'mode': 'auto'}"
       }
}

resource "azurerm_key_vault_secret" "iscsi_ppk" {
  provider                             = azurerm.main
  count                                = (local.enable_landscape_kv && local.enable_iscsi_auth_key && !local.iscsi_key_exist) ? 1 : 0
  depends_on                           = [
                                           azurerm_key_vault_access_policy.kv_user,
                                           azurerm_role_assignment.role_assignment_spn,
                                           azurerm_role_assignment.role_assignment_msi,
                                           azurerm_key_vault_access_policy.kv_user_msi
                                        ]
  content_type                         = ""
  name                                 = local.iscsi_ppk_name
  value                                = local.iscsi_private_key
  key_vault_id                         = local.user_keyvault_exist ? local.user_key_vault_id : azurerm_key_vault.kv_user[0].id
}

resource "azurerm_key_vault_secret" "iscsi_pk" {
  provider                             = azurerm.main
  count                                = (local.enable_landscape_kv && local.enable_iscsi_auth_key && !local.iscsi_key_exist) ? 1 : 0
  depends_on                           = [
                                           azurerm_key_vault_access_policy.kv_user,
                                           azurerm_role_assignment.role_assignment_spn,
                                           azurerm_role_assignment.role_assignment_msi,
                                           azurerm_key_vault_access_policy.kv_user_msi
                                         ]
  content_type                         = ""
  name                                 = local.iscsi_pk_name
  value                                = local.iscsi_public_key
  key_vault_id                         = local.user_keyvault_exist ? local.user_key_vault_id : azurerm_key_vault.kv_user[0].id
}

resource "azurerm_key_vault_secret" "iscsi_username" {
  provider                             = azurerm.main
  count                                = (local.enable_landscape_kv && local.enable_iscsi && !local.iscsi_username_exist) ? 1 : 0
  depends_on                           = [
                                           azurerm_key_vault_access_policy.kv_user,
                                           azurerm_role_assignment.role_assignment_spn,
                                           azurerm_role_assignment.role_assignment_msi,
                                           azurerm_key_vault_access_policy.kv_user_msi
                                         ]
  content_type                         = ""
  name                                 = local.iscsi_username_name
  value                                = local.iscsi_auth_username
  key_vault_id                         = local.user_keyvault_exist ? local.user_key_vault_id : azurerm_key_vault.kv_user[0].id
}

resource "azurerm_key_vault_secret" "iscsi_password" {
  provider                             = azurerm.main
  count                                = (local.enable_landscape_kv && local.enable_iscsi_auth_password && !local.iscsi_pwd_exist) ? 1 : 0
  depends_on                           = [
                                           azurerm_key_vault_access_policy.kv_user,
                                           azurerm_role_assignment.role_assignment_spn,
                                           azurerm_role_assignment.role_assignment_msi,
                                           azurerm_key_vault_access_policy.kv_user_msi
                                         ]
  content_type                         = ""
  name                                 = local.iscsi_pwd_name
  value                                = local.iscsi_auth_password
  key_vault_id                         = local.user_keyvault_exist ? local.user_key_vault_id : azurerm_key_vault.kv_user[0].id
}

// Generate random password if password is set as authentication type and user doesn't specify a password, and save in KV
resource "random_password" "iscsi_password" {
  count                                = (local.enable_landscape_kv && local.enable_iscsi_auth_password  && !local.iscsi_pwd_exist  && try(var.authentication.password, null) == null) ? 1 : 0
  length                               = 32
  min_upper                            = 2
  min_lower                            = 2
  min_numeric                          = 2
  special                              = true
  override_special                     = "_%@"
}

// Import secrets about iSCSI
data "azurerm_key_vault_secret" "iscsi_pk" {
  provider                             = azurerm.main
  count                                = (local.enable_landscape_kv && local.enable_iscsi_auth_key && local.iscsi_key_exist) ? 1 : 0
  name                                 = local.iscsi_pk_name
  key_vault_id                         = local.user_key_vault_id
}

data "azurerm_key_vault_secret" "iscsi_ppk" {
  provider                             = azurerm.main
  count                                = (local.enable_landscape_kv && local.enable_iscsi_auth_key && local.iscsi_key_exist) ? 1 : 0
  name                                 = local.iscsi_ppk_name
  key_vault_id                         = local.user_key_vault_id
}

data "azurerm_key_vault_secret" "iscsi_password" {
  provider                             = azurerm.main
  count                                = (local.enable_landscape_kv && local.enable_iscsi_auth_password && local.iscsi_pwd_exist) ? 1 : 0
  name                                 = local.iscsi_pwd_name
  key_vault_id                         = local.user_key_vault_id
}

data "azurerm_key_vault_secret" "iscsi_username" {
  provider                             = azurerm.main
  count                                = (local.enable_landscape_kv && local.enable_iscsi && local.iscsi_username_exist) ? 1 : 0
  name                                 = local.iscsi_username_name
  key_vault_id                         = local.user_key_vault_id
}

// Using TF tls to generate SSH key pair for iscsi devices and store in user KV
resource "tls_private_key" "iscsi" {
  count                                = (
                                           local.enable_landscape_kv
                                           && local.enable_iscsi_auth_key
                                           && !local.iscsi_key_exist
                                           && try(file(var.authentication.path_to_public_key), null) == null
                                         ) ? 1 : 0
  algorithm                            = "RSA"
  rsa_bits                             = 2048
}

