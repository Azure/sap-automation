// Create private KV with access policy
data "azurerm_client_config" "deployer" {
  provider = azurerm.main
}


// Create user KV with access policy
resource "azurerm_key_vault" "kv_user" {
  count = (var.key_vault.kv_exists) ? 0 : 1
  name  = local.keyvault_names.user_access
  resource_group_name = local.resource_group_exists ? (
    data.azurerm_resource_group.deployer[0].name) : (
    azurerm_resource_group.deployer[0].name
  )
  location = local.resource_group_exists ? (
    data.azurerm_resource_group.deployer[0].location) : (
    azurerm_resource_group.deployer[0].location
  )
  tenant_id                  = azurerm_user_assigned_identity.deployer.tenant_id
  soft_delete_retention_days = 7
  purge_protection_enabled   = var.enable_purge_control_for_keyvaults

  sku_name = "standard"

  dynamic "network_acls" {
    for_each = range(var.enable_firewall_for_keyvaults_and_storage ? 1 : 0)
    content {

      bypass         = "AzureServices"
      default_action = local.management_subnet_exists ? "Allow" : "Deny"

      ip_rules = compact(
        [
          local.enable_deployer_public_ip ? (
            azurerm_public_ip.deployer[0].ip_address) : (
          ""),
          length(var.Agent_IP) > 0 ? var.Agent_IP : ""
        ]
      )

      virtual_network_subnet_ids = compact(local.management_subnet_exists ? (var.use_webapp ? (
        [data.azurerm_subnet.subnet_mgmt[0].id, data.azurerm_subnet.webapp[0].id]) : (
        [data.azurerm_subnet.subnet_mgmt[0].id])
        ) : (var.use_webapp ? (
          compact([azurerm_subnet.subnet_mgmt[0].id, try(azurerm_subnet.webapp[0].id, null)])) : (
          [azurerm_subnet.subnet_mgmt[0].id]
        )
      ))
    }
  }

}

resource "azurerm_private_dns_a_record" "kv_user" {
  provider            = azurerm.dnsmanagement
  count               = var.use_private_endpoint && var.use_custom_dns_a_registration ? 1 : 0
  name                = lower(local.keyvault_names.user_access)
  zone_name           = "privatelink.vaultcore.azure.net"
  resource_group_name = var.management_dns_resourcegroup_name
  ttl                 = 3600
  records             = [data.azurerm_network_interface.keyvault[0].ip_configuration[0].private_ip_address]

  lifecycle {
    ignore_changes = [tags]
  }
}

#Errors can occure when the dns record has not properly been activated, add a wait timer to give
#it just a little bit more time
resource "time_sleep" "wait_for_dns_refresh" {
  count           = var.use_private_endpoint && var.use_custom_dns_a_registration ? 1 : 0
  create_duration = "120s"

  depends_on = [azurerm_private_dns_a_record.kv_user]
}

// Import an existing user Key Vault
data "azurerm_key_vault" "kv_user" {
  count               = var.key_vault.kv_exists ? 1 : 0
  name                = split("/", var.key_vault.kv_user_id)[8]
  resource_group_name = split("/", var.key_vault.kv_user_id)[4]
}


// Using TF tls to generate SSH key pair and store in user KV
resource "tls_private_key" "deployer" {
  count = (
    local.enable_key
    && !local.key_exist
    && (try(file(var.authentication.path_to_public_key), "") == "")
  ) ? 1 : 0
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "azurerm_key_vault_secret" "ppk" {
  depends_on = [
    azurerm_key_vault_access_policy.kv_user_pre_deployer[0],
    azurerm_key_vault_access_policy.kv_user_msi,
    azurerm_key_vault_access_policy.kv_user_systemidentity,
    time_sleep.wait_for_dns_refresh
  ]
  count        = (local.enable_key && !local.key_exist) ? 1 : 0
  name         = local.ppk_secret_name
  value        = local.private_key
  key_vault_id = var.key_vault.kv_exists ? var.key_vault.kv_user_id : azurerm_key_vault.kv_user[0].id
}

resource "azurerm_key_vault_secret" "pk" {
  depends_on = [
    azurerm_key_vault_access_policy.kv_user_pre_deployer[0],
    azurerm_key_vault_access_policy.kv_user_msi,
    azurerm_key_vault_access_policy.kv_user_systemidentity,
    time_sleep.wait_for_dns_refresh
  ]
  count = (local.enable_key && !local.key_exist) ? (
    (
      !var.bootstrap || !var.key_vault.kv_exists) ? (
      1) : (
      0
    )) : (
    0
  )

  name         = local.pk_secret_name
  value        = local.public_key
  key_vault_id = var.key_vault.kv_exists ? var.key_vault.kv_user_id : azurerm_key_vault.kv_user[0].id
}

resource "azurerm_key_vault_secret" "username" {
  depends_on = [
    azurerm_key_vault_access_policy.kv_user_pre_deployer[0],
    azurerm_key_vault_access_policy.kv_user_msi,
    azurerm_key_vault_access_policy.kv_user_systemidentity,
    time_sleep.wait_for_dns_refresh
  ]
  count = (local.enable_key && !local.key_exist) ? (
    (
      !var.bootstrap || !var.key_vault.kv_exists) ? (
      1) : (
      0
    )) : (
    0
  )
  name         = local.username_secret_name
  value        = local.username
  key_vault_id = var.key_vault.kv_exists ? var.key_vault.kv_user_id : azurerm_key_vault.kv_user[0].id
}

resource "azurerm_key_vault_secret" "pat" {
  depends_on = [
    azurerm_key_vault_access_policy.kv_user_pre_deployer[0],
    azurerm_key_vault_access_policy.kv_user_msi,
    azurerm_key_vault_access_policy.kv_user_systemidentity,
    time_sleep.wait_for_dns_refresh
  ]
  count = (local.enable_key && !local.key_exist) ? (
    (
      !var.bootstrap || !var.key_vault.kv_exists) ? (
      1) : (
      0
    )) : (
    0
  )

  name         = "PAT"
  value        = var.agent_pat
  key_vault_id = var.key_vault.kv_exists ? var.key_vault.kv_user_id : azurerm_key_vault.kv_user[0].id
}

resource "azurerm_key_vault_secret" "web_pwd" {
  depends_on = [
    azurerm_key_vault_access_policy.kv_user_pre_deployer[0],
    azurerm_key_vault_access_policy.kv_user_msi,
    azurerm_key_vault_access_policy.kv_user_systemidentity,
    time_sleep.wait_for_dns_refresh
  ]
  count = (local.enable_key && !local.key_exist) ? (
    (
      !var.bootstrap || !var.key_vault.kv_exists) ? (
      1) : (
      0
    )) : (
    0
  )

  name         = "WEB-PWD"
  value        = var.webapp_client_secret
  key_vault_id = var.key_vault.kv_exists ? var.key_vault.kv_user_id : azurerm_key_vault.kv_user[0].id
}


// Generate random password if password is set as authentication type, and save in KV
resource "random_password" "deployer" {
  count = (
    local.enable_password
    && !local.pwd_exist
    && try(var.authentication.password, "") == ""
  ) ? 1 : 0

  length           = 32
  min_upper        = 2
  min_lower        = 2
  min_numeric      = 2
  special          = true
  override_special = "_%@"
}

resource "azurerm_key_vault_secret" "pwd" {
  depends_on = [
    azurerm_key_vault_access_policy.kv_user_pre_deployer[0],
    azurerm_key_vault_access_policy.kv_user_msi,
    azurerm_key_vault_access_policy.kv_user_systemidentity,
    time_sleep.wait_for_dns_refresh
  ]
  count = (local.enable_password && !local.pwd_exist) ? (
    (
      !var.bootstrap || !var.key_vault.kv_exists) ? (
      1) : (
      0
    )) : (
    0
  )
  name  = local.pwd_secret_name
  value = local.password
  key_vault_id = var.key_vault.kv_exists ? (
    var.key_vault.kv_user_id) : (
    azurerm_key_vault.kv_user[0].id
  )
}

data "azurerm_key_vault_secret" "pk" {
  depends_on = [
    time_sleep.wait_for_dns_refresh
  ]
  count        = (local.enable_key && local.key_exist) ? 1 : 0
  name         = local.pk_secret_name
  key_vault_id = var.key_vault.kv_user_id
}

data "azurerm_key_vault_secret" "ppk" {
  depends_on = [
    time_sleep.wait_for_dns_refresh
  ]
  count        = (local.enable_key && local.key_exist) ? 1 : 0
  name         = local.ppk_secret_name
  key_vault_id = var.key_vault.kv_user_id
}

data "azurerm_key_vault_secret" "username" {
  depends_on = [
    time_sleep.wait_for_dns_refresh
  ]
  count        = (local.username_exist) ? 1 : 0
  name         = local.username_secret_name
  key_vault_id = var.key_vault.kv_user_id
}

data "azurerm_key_vault_secret" "pwd" {
  depends_on = [
    time_sleep.wait_for_dns_refresh
  ]
  count        = (local.enable_password && local.pwd_exist) ? 1 : 0
  name         = local.pwd_secret_name
  key_vault_id = var.key_vault.kv_user_id
}


resource "azurerm_private_endpoint" "kv_user" {
  provider = azurerm.main
  count    = var.use_private_endpoint && !var.key_vault.kv_exists ? 1 : 0
  name = format("%s%s%s",
    var.naming.resource_prefixes.keyvault_private_link,
    local.prefix,
    var.naming.resource_suffixes.keyvault_private_link
  )
  resource_group_name = local.resource_group_exists ? (
    data.azurerm_resource_group.deployer[0].name) : (
    azurerm_resource_group.deployer[0].name
  )
  location = local.resource_group_exists ? (
    data.azurerm_resource_group.deployer[0].location) : (
    azurerm_resource_group.deployer[0].location
  )
  subnet_id = local.management_subnet_exists ? (
    data.azurerm_subnet.subnet_mgmt[0].id) : (
    azurerm_subnet.subnet_mgmt[0].id
  )

  private_service_connection {
    name = format("%s%s%s",
      var.naming.resource_prefixes.keyvault_private_svc,
      local.prefix,
      var.naming.resource_suffixes.keyvault_private_svc
    )
    is_manual_connection = false
    private_connection_resource_id = var.key_vault.kv_exists ? (
      data.azurerm_key_vault.kv_user[0].id) : (
      azurerm_key_vault.kv_user[0].id
    )
    subresource_names = [
      "Vault"
    ]
  }

  custom_network_interface_name = format("%s%s%s%s",
    var.naming.resource_prefixes.keyvault_private_link,
    local.prefix,
    var.naming.resource_suffixes.keyvault_private_link,
    var.naming.resource_suffixes.nic
  )

  dynamic "private_dns_zone_group" {
    for_each = range(var.use_private_endpoint && !var.use_custom_dns_a_registration && !var.bootstrap ? 1 : 0)
    content {
      name                 = "privatelink.vaultcore.azure.net"
      private_dns_zone_ids = [data.azurerm_private_dns_zone.keyvault[0].id]
    }

  }
}

data "azurerm_private_dns_zone" "keyvault" {
  count               = var.use_private_endpoint && !var.use_custom_dns_a_registration && !var.bootstrap ? 1 : 0
  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = var.management_dns_resourcegroup_name
  provider            = azurerm.dnsmanagement

}

resource "azurerm_private_dns_zone_virtual_network_link" "vault" {
  provider = azurerm.dnsmanagement
  count    = (!local.vnet_mgmt_exists) && !var.use_custom_dns_a_registration && !var.bootstrap && var.use_private_endpoint ? 1 : 0
  name = format("%s%s%s%s",
    var.naming.resource_prefixes.dns_link,
    local.prefix,
    var.naming.separator,
    "vault"
  )
  resource_group_name   = var.management_dns_resourcegroup_name
  private_dns_zone_name = "privatelink.vaultcore.azure.net"
  virtual_network_id    = azurerm_virtual_network.vnet_mgmt[0].id
  registration_enabled  = false
}

###############################################################################
#                                                                             #
#                         Policies and Additional Users                       #
#                                                                             #
###############################################################################

resource "azurerm_key_vault_access_policy" "kv_user_msi" {
  provider = azurerm.main

  key_vault_id = var.key_vault.kv_exists ? data.azurerm_key_vault.kv_user[0].id : azurerm_key_vault.kv_user[0].id
  tenant_id    = azurerm_user_assigned_identity.deployer.tenant_id
  object_id    = azurerm_user_assigned_identity.deployer.principal_id

  secret_permissions = [
    "Get",
    "List",
    "Set",
    "Delete",
    "Recover",
    "Backup",
    "Restore",
    "Purge"
  ]
}

resource "azurerm_key_vault_access_policy" "kv_user_systemidentity" {
  provider = azurerm.main
  count    = var.deployer.add_system_assigned_identity ? var.deployer_vm_count : 0

  key_vault_id = var.key_vault.kv_exists ? data.azurerm_key_vault.kv_user[0].id : azurerm_key_vault.kv_user[0].id
  tenant_id    = azurerm_linux_virtual_machine.deployer[count.index].identity[0].tenant_id
  object_id    = azurerm_linux_virtual_machine.deployer[count.index].identity[0].principal_id

  secret_permissions = [
    "Get",
    "List",
    "Set",
    "Delete",
    "Recover",
    "Backup",
    "Restore",
    "Purge"
  ]
}

resource "azurerm_key_vault_access_policy" "kv_user_pre_deployer" {
  provider = azurerm.main
  count    = var.key_vault.kv_exists && length(var.spn_id) > 0 ? 0 : 1

  key_vault_id = azurerm_key_vault.kv_user[0].id
  tenant_id    = azurerm_user_assigned_identity.deployer.tenant_id
  # If running as a normal user use the object ID of the user otherwise use the object_id from AAD
  object_id = coalesce(data.azurerm_client_config.deployer.object_id,
    var.spn_id,
    var.arm_client_id
  )
  #application_id = data.azurerm_client_config.deployer.client_id

  secret_permissions = [
    "Get",
    "List",
    "Set",
    "Delete",
    "Recover",
    "Backup",
    "Restore",
    "Purge"
  ]

}


resource "azurerm_key_vault_access_policy" "kv_user_additional_users" {
  provider = azurerm.main
  count = !var.key_vault.kv_exists && length(compact(var.additional_users_to_add_to_keyvault_policies)) > 0 ? (
    length(compact(var.additional_users_to_add_to_keyvault_policies))) : (
    0
  )
  key_vault_id = azurerm_key_vault.kv_user[0].id

  tenant_id = azurerm_user_assigned_identity.deployer.tenant_id
  object_id = var.additional_users_to_add_to_keyvault_policies[count.index]
  secret_permissions = [
    "Get",
    "List",
    "Set",
    "Recover"
  ]

}

# resource "azurerm_key_vault_access_policy" "webapp" {
#   provider = azurerm.main
#   count = var.use_webapp ? 1 : 0

#   key_vault_id = var.key_vault.kv_exists ? (
#     var.key_vault.kv_user_id) : (
#     azurerm_key_vault.kv_user[0].id
#   )

#   tenant_id = azurerm_windows_web_app.webapp[0].identity[0].tenant_id
#   object_id = azurerm_windows_web_app.webapp[0].identity[0].principal_id
#   secret_permissions = [
#     "Get",
#     "List",
#     "Set",
#     "Recover"
#   ]

# }

data "azurerm_network_interface" "keyvault" {
  count = var.use_private_endpoint && !var.key_vault.kv_exists ? 1 : 0
  name  = azurerm_private_endpoint.kv_user[count.index].network_interface[0].name

  resource_group_name = split("/", azurerm_private_endpoint.kv_user[count.index].network_interface[0].id)[4]
}


resource "azurerm_management_lock" "keyvault" {
  provider   = azurerm.main
  count      = (var.key_vault.kv_exists) ? 0 : var.place_delete_lock_on_resources ? 1 : 0
  name       = format("%s-lock", local.keyvault_names.user_access)
  scope      = azurerm_key_vault.kv_user[0].id
  lock_level = "CanNotDelete"
  notes      = "Locked because it's needed by the Control Plane"
  lifecycle {
    prevent_destroy = false
  }
}
