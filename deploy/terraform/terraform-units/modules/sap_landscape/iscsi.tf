# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

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

  service_endpoints                    = var.use_service_endpoint ? (
                                           ["Microsoft.Storage", "Microsoft.KeyVault"]
                                           ) : (
                                           null
                                         )

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



resource "azurerm_subnet_route_table_association" "iscsi" {
  provider                             = azurerm.main
  count                                = local.enable_iscsi && !local.SAP_virtualnetwork_exists && !local.sub_iscsi_exists ?  (local.create_nat_gateway ? 0 : 1)  : 0
  depends_on                           = [
                                           azurerm_route_table.rt,
                                           azurerm_subnet.iscsi
                                         ]
  subnet_id                            = local.sub_iscsi_exists ? var.infrastructure.virtual_networks.sap.sub_iscsi.arm_id : azurerm_subnet.iscsi[0].id
  route_table_id                       = azurerm_route_table.rt[0].id
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

// Add SSH network security rule
resource "azurerm_network_security_rule" "nsr_controlplane_iscsi" {
  provider                             = azurerm.main
  count                                = local.enable_sub_iscsi ? local.sub_iscsi_nsg_exists ? 0 : 1 : 0
  depends_on                           = [
                                           azurerm_network_security_group.iscsi
                                         ]
  name                                 = "ConnectivityToISCSISubnetFromControlPlane-ssh-rdp-winrm"
  resource_group_name                  = local.SAP_virtualnetwork_exists ? (
                                           data.azurerm_virtual_network.vnet_sap[0].resource_group_name
                                           ) : (
                                           azurerm_virtual_network.vnet_sap[0].resource_group_name
                                         )
  network_security_group_name          = try(azurerm_network_security_group.iscsi[0].name, azurerm_network_security_group.app[0].name)
  priority                             = 100
  direction                            = "Inbound"
  access                               = "Allow"
  protocol                             = "Tcp"
  source_port_range                    = "*"
  destination_port_ranges              = [22, 443, 3389, 5985, 5986, 2049, 111]
  source_address_prefixes              = compact(concat(
                                           var.deployer_tfstate.subnet_mgmt_address_prefixes,
                                           var.deployer_tfstate.subnet_bastion_address_prefixes,
                                           local.SAP_virtualnetwork_exists ? (
                                             flatten(data.azurerm_virtual_network.vnet_sap[0].address_space)) : (
                                             flatten(azurerm_virtual_network.vnet_sap[0].address_space)
                                           )))
  destination_address_prefixes         = local.sub_iscsi_exists ? data.azurerm_subnet.iscsi[0].address_prefixes : azurerm_subnet.iscsi[0].address_prefixes
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

  patch_mode                                             = var.infrastructure.patch_mode
  patch_assessment_mode                                  = var.infrastructure.patch_assessment_mode
  bypass_platform_safety_checks_on_user_schedule_enabled = var.infrastructure.patch_mode != "AutomaticByPlatform" ? false : true
  vm_agent_platform_updates_enabled                      = true

  encryption_at_host_enabled                             = var.temp_infrastructure.encryption_at_host_enabled

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
  count                                = (local.create_workloadzone_keyvault && local.enable_iscsi_auth_key && !local.iscsi_key_exist) ? 1 : 0
  depends_on                           = [
                                           azurerm_key_vault_access_policy.kv_user,
                                           azurerm_role_assignment.role_assignment_spn,
                                           azurerm_role_assignment.role_assignment_msi,
                                           azurerm_key_vault_access_policy.kv_user_msi,
                                           azurerm_private_endpoint.kv_user
                                        ]
  content_type                         = "secret"
  name                                 = local.iscsi_ppk_name
  value                                = local.iscsi_private_key
  key_vault_id                         = local.user_keyvault_exist ? local.user_key_vault_id : azurerm_key_vault.kv_user[0].id
  expiration_date                      = var.key_vault.set_secret_expiry ? (
                                           time_offset.secret_expiry_date.rfc3339) : (
                                           null
                                         )
}

resource "azurerm_key_vault_secret" "iscsi_pk" {
  provider                             = azurerm.main
  count                                = (local.create_workloadzone_keyvault && local.enable_iscsi_auth_key && !local.iscsi_key_exist) ? 1 : 0
  depends_on                           = [
                                           azurerm_key_vault_access_policy.kv_user,
                                           azurerm_role_assignment.role_assignment_spn,
                                           azurerm_role_assignment.role_assignment_msi,
                                           azurerm_key_vault_access_policy.kv_user_msi,
                                           azurerm_private_endpoint.kv_user
                                         ]
  content_type                         = "secret"
  name                                 = local.iscsi_pk_name
  value                                = local.iscsi_public_key
  key_vault_id                         = local.user_keyvault_exist ? local.user_key_vault_id : azurerm_key_vault.kv_user[0].id
  expiration_date                      = var.key_vault.set_secret_expiry ? (
                                           time_offset.secret_expiry_date.rfc3339) : (
                                           null
                                         )
}

resource "azurerm_key_vault_secret" "iscsi_username" {
  provider                             = azurerm.main
  count                                = (local.create_workloadzone_keyvault && local.enable_iscsi && !local.iscsi_username_exist) ? 1 : 0
  depends_on                           = [
                                           azurerm_key_vault_access_policy.kv_user,
                                           azurerm_role_assignment.role_assignment_spn,
                                           azurerm_role_assignment.role_assignment_msi,
                                           azurerm_key_vault_access_policy.kv_user_msi,
                                           azurerm_private_endpoint.kv_user
                                         ]
  content_type                         = "configuration"
  name                                 = local.iscsi_username_name
  value                                = local.iscsi_auth_username
  key_vault_id                         = local.user_keyvault_exist ? local.user_key_vault_id : azurerm_key_vault.kv_user[0].id
  expiration_date                      = var.key_vault.set_secret_expiry ? (
                                           time_offset.secret_expiry_date.rfc3339) : (
                                           null
                                         )
}

resource "azurerm_key_vault_secret" "iscsi_password" {
  provider                             = azurerm.main
  count                                = (local.create_workloadzone_keyvault && local.enable_iscsi_auth_password && !local.iscsi_pwd_exist) ? 1 : 0
  depends_on                           = [
                                           azurerm_key_vault_access_policy.kv_user,
                                           azurerm_role_assignment.role_assignment_spn,
                                           azurerm_role_assignment.role_assignment_msi,
                                           azurerm_key_vault_access_policy.kv_user_msi,
                                           azurerm_private_endpoint.kv_user
                                         ]
  content_type                         = "secret"
  name                                 = local.iscsi_pwd_name
  value                                = local.iscsi_auth_password
  key_vault_id                         = local.user_keyvault_exist ? local.user_key_vault_id : azurerm_key_vault.kv_user[0].id
  expiration_date                       = var.key_vault.set_secret_expiry ? (
                                           time_offset.secret_expiry_date.rfc3339) : (
                                           null
                                         )
}

// Generate random password if password is set as authentication type and user doesn't specify a password, and save in KV
resource "random_password" "iscsi_password" {
  count                                = (local.create_workloadzone_keyvault && local.enable_iscsi_auth_password  && !local.iscsi_pwd_exist  && try(var.authentication.password, null) == null) ? 1 : 0
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
  count                                = (local.create_workloadzone_keyvault && local.enable_iscsi_auth_key && local.iscsi_key_exist) ? 1 : 0
  name                                 = local.iscsi_pk_name
  key_vault_id                         = local.user_key_vault_id
}

data "azurerm_key_vault_secret" "iscsi_ppk" {
  provider                             = azurerm.main
  count                                = (local.create_workloadzone_keyvault && local.enable_iscsi_auth_key && local.iscsi_key_exist) ? 1 : 0
  name                                 = local.iscsi_ppk_name
  key_vault_id                         = local.user_key_vault_id
}

data "azurerm_key_vault_secret" "iscsi_password" {
  provider                             = azurerm.main
  count                                = (local.create_workloadzone_keyvault && local.enable_iscsi_auth_password && local.iscsi_pwd_exist) ? 1 : 0
  name                                 = local.iscsi_pwd_name
  key_vault_id                         = local.user_key_vault_id
}

data "azurerm_key_vault_secret" "iscsi_username" {
  provider                             = azurerm.main
  count                                = (local.create_workloadzone_keyvault && local.enable_iscsi && local.iscsi_username_exist) ? 1 : 0
  name                                 = local.iscsi_username_name
  key_vault_id                         = local.user_key_vault_id
}

// Using TF tls to generate SSH key pair for iscsi devices and store in user KV
resource "tls_private_key" "iscsi" {
  count                                = (
                                           local.create_workloadzone_keyvault
                                           && local.enable_iscsi_auth_key
                                           && !local.iscsi_key_exist
                                           && try(file(var.authentication.path_to_public_key), null) == null
                                         ) ? 1 : 0
  algorithm                            = "RSA"
  rsa_bits                             = 2048
}


resource "azurerm_virtual_machine_extension" "monitoring_extension_iscsi_lnx" {
  provider                             = azurerm.main
  count                                = local.deploy_monitoring_extension ? (
                                           local.iscsi_count) : (
                                           0
                                         )
  virtual_machine_id                   = azurerm_linux_virtual_machine.iscsi[count.index].id
  name                                 = "Microsoft.Azure.Monitor.AzureMonitorLinuxAgent"
  publisher                            = "Microsoft.Azure.Monitor"
  type                                 = "AzureMonitorLinuxAgent"
  type_handler_version                 = "1.0"
  auto_upgrade_minor_version           = true
  automatic_upgrade_enabled            = true
}

resource "azurerm_virtual_machine_extension" "monitoring_defender_iscsi_lnx" {
  provider                             = azurerm.main
  count                                = var.infrastructure.deploy_defender_extension ? (
                                           local.iscsi_count) : (
                                           0
                                         )
  virtual_machine_id                   = azurerm_linux_virtual_machine.iscsi[count.index].id
  name                                 = "Microsoft.Azure.Security.Monitoring.AzureSecurityLinuxAgent"
  publisher                            = "Microsoft.Azure.Security.Monitoring"
  type                                 = "AzureSecurityLinuxAgent"
  type_handler_version                 = "2.0"
  auto_upgrade_minor_version           = true
  automatic_upgrade_enabled            = true

  settings                             = jsonencode(
                                           {
                                              "authentication"  =  {
                                                   "managedIdentity" = {
                                                        "identifier-name" : "mi_res_id",
                                                        "identifier-value": var.infrastructure.iscsi.user_assigned_identity_id
                                                      }
                                                }
                                            }
                                            )
}

