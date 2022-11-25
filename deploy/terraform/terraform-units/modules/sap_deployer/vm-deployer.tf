/*
Description:

  The deployer will be used to run Terraform and Ansible tasks to create the SAP environments

  Define 0..n Deployer(s).
*/

data "azurerm_subscription" "primary" {}
data "azurerm_client_config" "current" {}

// Public IP addresse and nic for Deployer
resource "azurerm_public_ip" "deployer" {
  count = local.enable_deployer_public_ip ? var.deployer_vm_count : 0
  name = format("%s%s%s%s%s",
    var.naming.resource_prefixes.pip,
    local.prefix,
    var.naming.separator,
    var.naming.virtualmachine_names.DEPLOYER[count.index],
    var.naming.resource_suffixes.pip
  )
  resource_group_name = local.resource_group_exists ? (
    data.azurerm_resource_group.deployer[0].name) : (
    azurerm_resource_group.deployer[0].name
  )
  location = local.resource_group_exists ? (
    data.azurerm_resource_group.deployer[0].location) : (
    azurerm_resource_group.deployer[0].location
  )
  allocation_method = "Static"
  sku               = "Standard"
}

resource "azurerm_network_interface" "deployer" {
  count = var.deployer_vm_count
  name = format("%s%s%s%s%s",
    var.naming.resource_prefixes.nic,
    local.prefix,
    var.naming.separator,
    var.naming.virtualmachine_names.DEPLOYER[count.index],
    var.naming.resource_suffixes.nic
  )
  resource_group_name = local.resource_group_exists ? (
    data.azurerm_resource_group.deployer[0].name) : (
    azurerm_resource_group.deployer[0].name
  )
  location = local.resource_group_exists ? (
    data.azurerm_resource_group.deployer[0].location) : (
    azurerm_resource_group.deployer[0].location
  )

  ip_configuration {
    name = "ipconfig1"
    subnet_id = local.management_subnet_exists ? (
      data.azurerm_subnet.subnet_mgmt[0].id) : (
      azurerm_subnet.subnet_mgmt[0].id
    )
    private_ip_address = try(var.deployer.private_ip_address[count.index], var.deployer.use_DHCP ? (
      null) : (
      cidrhost(
        local.management_subnet_deployed_prefixes[0],
        tonumber(count.index) + 4
      )
      )
    )
    private_ip_address_allocation = length(try(var.deployer.private_ip_address[count.index], "")) > 0 ? (
      "Static") : (
      "Dynamic"
    )

    public_ip_address_id = local.enable_deployer_public_ip ? azurerm_public_ip.deployer[count.index].id : ""
  }
}

// User defined identity for all Deployer, assign contributor to the current subscription
resource "azurerm_user_assigned_identity" "deployer" {
  resource_group_name = local.resource_group_exists ? data.azurerm_resource_group.deployer[0].name : azurerm_resource_group.deployer[0].name
  location            = local.resource_group_exists ? data.azurerm_resource_group.deployer[0].location : azurerm_resource_group.deployer[0].location
  name                = format("%s%s%s", var.naming.resource_prefixes.msi, local.prefix, var.naming.resource_suffixes.msi)
}

# // Add role to be able to deploy resources
resource "azurerm_role_assignment" "sub_contributor" {
  count                = var.assign_subscription_permissions ? 1 : 0
  scope                = data.azurerm_subscription.primary.id
  role_definition_name = "Contributor"
  principal_id         = azurerm_user_assigned_identity.deployer.principal_id
}

// Linux Virtual Machine for Deployer
resource "azurerm_linux_virtual_machine" "deployer" {
  count = var.deployer_vm_count
  name = format("%s%s%s%s%s",
    var.naming.resource_prefixes.vm,
    local.prefix,
    var.naming.separator,
    var.naming.virtualmachine_names.DEPLOYER[count.index],
    var.naming.resource_suffixes.vm
  )
  computer_name = var.naming.virtualmachine_names.DEPLOYER[count.index]
  resource_group_name = local.resource_group_exists ? (
    data.azurerm_resource_group.deployer[0].name) : (
    azurerm_resource_group.deployer[0].name
  )
  location = local.resource_group_exists ? (
    data.azurerm_resource_group.deployer[0].location) : (
    azurerm_resource_group.deployer[0].location
  )
  network_interface_ids           = [azurerm_network_interface.deployer[count.index].id]
  size                            = var.deployer.size
  admin_username                  = local.username
  admin_password                  = lookup(var.deployer.authentication, "password", null)
  disable_password_authentication = var.deployer.authentication.type != "password" ? true : false

  os_disk {
    name = format("%s%s%s%s%s",
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

  source_image_id = var.deployer.os.source_image_id != "" ? var.deployer.os.source_image_id : null

  dynamic "source_image_reference" {
    for_each = range(var.deployer.os.type == "marketplace" ? 1 : 0)
    content {
      publisher = var.deployer.os.publisher
      offer     = var.deployer.os.offer
      sku       = var.deployer.os.sku
      version   = var.deployer.os.version
    }
  }

  dynamic "plan" {
    for_each = range(var.deployer.os.type == "marketplace_with_plan" ? 1 : 0)
    content {
      name      = var.deployer.os.offer
      publisher = var.deployer.os.publisher
      product   = var.deployer.os.sku
    }
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.deployer.id]
  }

  dynamic "admin_ssh_key" {
    for_each = range(local.public_key == null ? 0 : 1)
    content {
      username   = local.username
      public_key = local.public_key
    }
  }

  boot_diagnostics {
    storage_account_uri = length(var.deployer.deployer_diagnostics_account_arm_id) > 0 ? (
      data.azurerm_storage_account.deployer[0].primary_blob_endpoint) : (
      azurerm_storage_account.deployer[0].primary_blob_endpoint
    )
  }
  connection {
    type        = "ssh"
    host        = azurerm_public_ip.deployer[count.index].ip_address
    user        = local.username
    private_key = var.deployer.authentication.type == "key" ? local.private_key : null
    password    = lookup(var.deployer.authentication, "password", null)
    timeout     = var.ssh-timeout
  }

  tags = local.tags
}

resource "azurerm_virtual_machine_extension" "configure" {

  count = var.auto_configure_deployer ? var.deployer_vm_count : 0

  name                 = "configure_deployer"
  virtual_machine_id   = azurerm_linux_virtual_machine.deployer[count.index].id
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.1"
  settings = jsonencode(
    {
      "script" = base64encode(
        templatefile(
          format(
          "%s/templates/configure_deployer.sh.tmpl", path.module),
          {
            tfversion            = var.tf_version,
            rg_name              = local.rg_name,
            client_id            = azurerm_user_assigned_identity.deployer.client_id,
            subscription_id      = data.azurerm_subscription.primary.subscription_id,
            tenant_id            = data.azurerm_subscription.primary.tenant_id,
            local_user           = local.username
            pool                 = var.agent_pool
            pat                  = var.agent_pat
            ado_repo             = var.agent_ado_url
            use_webapp           = var.use_webapp
            ansible_core_version = var.ansible_core_version
          }
        )
      )
    }
  )

}
