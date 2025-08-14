# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

/*
Description:

*/

#######################################4#######################################8
#                                                                              #
#  The deployer will be used to run Terraform and Ansible tasks to create the  #
#   SAP environments                                                           #
#                                                                              #
#   Define 0..n Deployer(s).                                                   #
#                                                                              #
#######################################4#######################################8


data "azurerm_subscription" "primary" {}
data "azurerm_client_config" "current" {}

// Public IP address and nic for Deployer
resource "azurerm_public_ip" "deployer" {
  count                                = local.enable_deployer_public_ip ? var.deployer_vm_count : 0
  name                                 = format("%s%s%s%s%s",
                                           var.naming.resource_prefixes.pip,
                                           local.prefix,
                                           var.naming.separator,
                                           var.naming.virtualmachine_names.DEPLOYER[count.index],
                                           var.naming.resource_suffixes.pip
                                         )
  allocation_method                    = "Static"
  sku                                  = "Standard"
  resource_group_name                  = var.infrastructure.resource_group.exists ? (
                                           data.azurerm_resource_group.deployer[0].name) : (
                                           azurerm_resource_group.deployer[0].name
                                         )
  location                             = var.infrastructure.resource_group.exists ? (
                                           data.azurerm_resource_group.deployer[0].location) : (
                                           azurerm_resource_group.deployer[0].location
                                         )
  # zones                                      = [1,2,3] - optional property.
  ip_tags                              = var.deployer.deployer_public_ip_tags
  lifecycle                            {
                                              ignore_changes = [
                                                ip_tags
                                              ]
                                              create_before_destroy = true
                                        }
  tags                                 = var.infrastructure.tags
}

resource "azurerm_network_interface" "deployer" {
  count                                = var.deployer_vm_count
  name                                 = format("%s%s%s%s%s",
                                         var.naming.resource_prefixes.nic,
                                         local.prefix,
                                         var.naming.separator,
                                         var.naming.virtualmachine_names.DEPLOYER[count.index],
                                         var.naming.resource_suffixes.nic
                                       )
  resource_group_name                  = var.infrastructure.resource_group.exists ? (
                                           data.azurerm_resource_group.deployer[0].name) : (
                                           azurerm_resource_group.deployer[0].name
                                         )
  location                             = var.infrastructure.resource_group.exists ? (
                                           data.azurerm_resource_group.deployer[0].location) : (
                                           azurerm_resource_group.deployer[0].location
                                         )

  ip_configuration                       {
                                           name                          = "ipconfig1"
                                           subnet_id                     = var.infrastructure.virtual_network.management.subnet_mgmt.exists ? (
                                                                            data.azurerm_subnet.subnet_mgmt[0].id) : (
                                                                            azurerm_subnet.subnet_mgmt[0].id
                                                                          )
                                           private_ip_address            = try(var.deployer.private_ip_address[count.index], var.deployer.use_DHCP ? (
                                                                             null) : (
                                                                             cidrhost(
                                                                               var.infrastructure.virtual_network.management.subnet_mgmt.prefix,
                                                                               tonumber(count.index) + 4
                                                                             )
                                                                             )
                                                                           )
                                           private_ip_address_allocation = length(try(var.deployer.private_ip_address[count.index], "")) > 0 ? (
                                                                             "Static") : (
                                                                             "Dynamic"
                                                                           )

                                                                                  public_ip_address_id          = local.enable_deployer_public_ip ? azurerm_public_ip.deployer[count.index].id : null
                                         }
  tags                                 = var.infrastructure.tags
}

// User defined identity for all Deployers, assign contributor to the current subscription
resource "azurerm_user_assigned_identity" "deployer" {
  count                                = length(var.deployer.user_assigned_identity_id) == 0 ? 1 : 0
  name                                 = format("%s%s%s", var.naming.resource_prefixes.msi, local.prefix, var.naming.resource_suffixes.msi)
  resource_group_name                  = var.infrastructure.resource_group.exists ? data.azurerm_resource_group.deployer[0].name : azurerm_resource_group.deployer[0].name
  location                             = var.infrastructure.resource_group.exists ? data.azurerm_resource_group.deployer[0].location : azurerm_resource_group.deployer[0].location
  tags                                 = var.infrastructure.tags
}

// User defined identity for all Deployers, assign contributor to the current subscription
data "azurerm_user_assigned_identity" "deployer" {
  count                                = length(var.deployer.user_assigned_identity_id) > 0 ? 1 : 0
  name                                 = split("/", var.deployer.user_assigned_identity_id)[8]
  resource_group_name                  = split("/", var.deployer.user_assigned_identity_id)[4]
}

// Linux Virtual Machine for Deployer
resource "azurerm_linux_virtual_machine" "deployer" {
  count                                = var.deployer_vm_count
  depends_on                           = [ azurerm_key_vault.kv_user ]

  name                                 = format("%s%s%s%s%s",
                                           var.naming.resource_prefixes.vm,
                                           local.prefix,
                                           var.naming.separator,
                                           var.naming.virtualmachine_names.DEPLOYER[count.index],
                                           var.naming.resource_suffixes.vm
                                         )
  computer_name                        = var.naming.virtualmachine_names.DEPLOYER[count.index]
  resource_group_name                  = var.infrastructure.resource_group.exists ? (
                                           data.azurerm_resource_group.deployer[0].name) : (
                                           azurerm_resource_group.deployer[0].name
                                         )
  location                             = var.infrastructure.resource_group.exists ? (
                                           data.azurerm_resource_group.deployer[0].location) : (
                                           azurerm_resource_group.deployer[0].location
                                         )

  network_interface_ids                = [azurerm_network_interface.deployer[count.index].id]

  license_type                         = length(var.deployer.license_type) > 0 ? var.deployer.license_type : null
  size                                 = var.deployer.size
  admin_username                       = local.username
  admin_password                       = var.deployer.authentication.type != "password" ? null: local.password
  disable_password_authentication      = var.deployer.authentication.type != "password" ? true : false

  source_image_id                      = var.deployer.os.source_image_id != "" ? var.deployer.os.source_image_id : null

  encryption_at_host_enabled           = var.deployer.encryption_at_host_enabled

  os_disk                                {
                                            name                   = format("%s%s%s%s%s",
                                                                       var.naming.resource_prefixes.osdisk,
                                                                       local.prefix,
                                                                       var.naming.separator,
                                                                       var.naming.virtualmachine_names.DEPLOYER[count.index],
                                                                       var.naming.resource_suffixes.osdisk
                                                                     )
                                            caching                = "ReadWrite"
                                            storage_account_type   = var.deployer.disk_type
                                            disk_encryption_set_id = try(var.options.disk_encryption_set_id, null)
                                            disk_size_gb           = 128
                                          }


  dynamic "source_image_reference"        {
                                            for_each = range(var.deployer.os.type == "marketplace" || var.deployer.os.type == "marketplace_with_plan" ? 1 : 0)
                                            content {
                                                      publisher = var.deployer.os.publisher
                                                      offer     = var.deployer.os.offer
                                                      sku       = var.deployer.os.sku
                                                      version   = var.deployer.os.version
                                                    }
                                          }
  dynamic "plan"                          {
                                            for_each = range(var.deployer.os.type == "marketplace_with_plan" ? 1 : 0)
                                            content {
                                                      name      = var.deployer.os.sku
                                                      publisher = var.deployer.os.publisher
                                                      product   = var.deployer.os.offer
                                                    }
                                          }

  identity                                {
                                            type         = var.deployer.add_system_assigned_identity ? "SystemAssigned, UserAssigned" : "UserAssigned"
                                            identity_ids = [length(var.deployer.user_assigned_identity_id) == 0 ? azurerm_user_assigned_identity.deployer[0].id : data.azurerm_user_assigned_identity.deployer[0].id ]
                                          }

  dynamic "admin_ssh_key"                 {
                                            for_each = range(local.public_key == null ? 0 : 1)
                                            content {
                                                      username   = local.username
                                                      public_key = local.public_key
                                                    }
                                          }

  boot_diagnostics                        {
                                            storage_account_uri = length(var.deployer.deployer_diagnostics_account_arm_id) > 0 ? (
                                              data.azurerm_storage_account.deployer[0].primary_blob_endpoint) : (
                                              azurerm_storage_account.deployer[0].primary_blob_endpoint
                                            )
                                          }
  connection                              {
                                            type        = "ssh"
                                            host        = azurerm_public_ip.deployer[count.index].ip_address
                                            user        = local.username
                                            private_key = var.deployer.authentication.type == "key" ? local.private_key : null
                                            password    = lookup(var.deployer.authentication, "password", null)
                                            timeout     = var.ssh-timeout
                                          }

  tags                                 = local.tags

  lifecycle                                {
                                             ignore_changes = [ identity ]
                                           }
}


#Private endpoint tend to take a while to be created, so we need to wait for it to be ready before we can use it
resource "time_sleep" "wait_for_VM" {

  create_duration                      = var.deployer_vm_count > 0 ? "60s" : "5s"

  depends_on                           = [
                                           azurerm_linux_virtual_machine.deployer
                                         ]
}

resource "azurerm_virtual_machine_extension" "configure" {
  count                                = var.auto_configure_deployer ? var.deployer_vm_count : 0

  depends_on                           = [
                                           time_sleep.wait_for_VM,
                                           azurerm_virtual_machine_extension.monitoring_extension_deployer_lnx,
                                           azurerm_virtual_machine_extension.monitoring_defender_deployer_lnx
                                         ]

  name                                 = "configure_deployer"
  virtual_machine_id                   = azurerm_linux_virtual_machine.deployer[count.index].id
  publisher                            = "Microsoft.Azure.Extensions"
  type                                 = "CustomScript"
  type_handler_version                 = "2.1"
  protected_settings                   = jsonencode(
                                           {
                                             "script" = base64encode(
                                               templatefile(
                                                 format(
                                                 "%s/templates/configure_deployer.sh.tmpl", path.module),
                                                 {
                                                   terraform_version    = var.infrastructure.devops.tf_version,
                                                   rg_name              = local.resourcegroup_name,
                                                   client_id            = length(var.deployer.user_assigned_identity_id) == 0 ? azurerm_user_assigned_identity.deployer[0].client_id : data.azurerm_user_assigned_identity.deployer[0].client_id,
                                                   subscription_id      = data.azurerm_subscription.primary.subscription_id,
                                                   tenant_id            = data.azurerm_subscription.primary.tenant_id,
                                                   local_user           = local.username
                                                   pool                 = var.infrastructure.devops.agent_pool
                                                   pat                  = var.infrastructure.devops.agent_pat
                                                   ado_repo             = var.infrastructure.devops.agent_ado_url
                                                   use_webapp           = var.app_service.use
                                                   ansible_core_version = var.infrastructure.devops.ansible_core_version
                                                 }
                                               )
                                             )
                                           }
                                         )
  tags                                 = var.infrastructure.tags
}

resource "azurerm_virtual_machine_extension" "monitoring_extension_deployer_lnx" {
  provider                             = azurerm.main
  count                                = var.infrastructure.deploy_monitoring_extension   ? (
                                           var.deployer_vm_count) : (
                                           0                                           )
  virtual_machine_id                   = azurerm_linux_virtual_machine.deployer[count.index].id
  name                                 = "AzureMonitorLinuxAgent"
  publisher                            = "Microsoft.Azure.Monitor"
  type                                 = "AzureMonitorLinuxAgent"
  type_handler_version                 = "1.0"
  auto_upgrade_minor_version           = true
  tags                                 = var.infrastructure.tags
}


resource "azurerm_virtual_machine_extension" "monitoring_defender_deployer_lnx" {
  provider                             = azurerm.main
  count                                = var.infrastructure.deploy_defender_extension ? (
                                           var.deployer_vm_count) : (
                                           0                                           )
  virtual_machine_id                   = azurerm_linux_virtual_machine.deployer[count.index].id
  name                                 = "AzureSecurityLinuxAgent"
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
                                              "authentication" = {
                                                "managedIdentity" = {
                                                  "identifier-name" : "mi_res_id",
                                                  "identifier-value" : (var.deployer.user_assigned_identity_id) == 0 ? (
                                                    azurerm_user_assigned_identity.deployer[0].id) : (
                                                    data.azurerm_user_assigned_identity.deployer[0].id)
                                                }
                                                }
                                            }
                                          )
  tags                                 = var.infrastructure.tags
}
