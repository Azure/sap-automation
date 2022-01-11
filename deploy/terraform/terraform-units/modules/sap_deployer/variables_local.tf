/*
Description:

  Define local variables.
*/
variable "naming" {
  description = "naming convention"
}

variable "firewall_deployment" {
  description = "Boolean flag indicating if an Azure Firewall should be deployed"
}

variable "assign_subscription_permissions" {
  description = "Assign permissions on the subscription"
}

variable "enable_purge_control_for_keyvaults" {
  description = "Allow the deployment to control the purge protection"
}

variable "bootstrap" {}

variable "use_private_endpoint" {
  default = false
}

variable "configure" {
  default = false
}

variable "tf_version" {
  default = ""
}


// Set defaults
locals {

  storageaccount_names = var.naming.storageaccount_names.DEPLOYER
  virtualmachine_names = var.naming.virtualmachine_names.DEPLOYER
  keyvault_names       = var.naming.keyvault_names.DEPLOYER
  resource_suffixes    = var.naming.resource_suffixes

  // Default option(s):
  enable_secure_transfer    = try(var.options.enable_secure_transfer, true)
  enable_deployer_public_ip = try(var.options.enable_deployer_public_ip, false)

  // Resource group
  
  prefix = length(var.infrastructure.resource_group.name) > 0 ? var.infrastructure.resource_group.name : var.naming.prefix.DEPLOYER

  rg_arm_id = try(var.infrastructure.resource_group.arm_id, "")
  rg_exists = length(local.rg_arm_id) > 0 ? true : false
  // If resource ID is specified extract the resourcegroup name from it otherwise read it either from input of create using the naming convention
  rg_name = local.rg_exists ? (
    split("/", local.rg_arm_id)[4]) : (
    length(var.infrastructure.resource_group.name) > 0 ? (
      var.infrastructure.resource_group.name) : (
      format("%s%s", local.prefix, local.resource_suffixes.deployer_rg)
    )
  )
  rg_appservice_location = local.rg_exists ? data.azurerm_resource_group.deployer[0].location : azurerm_resource_group.deployer[0].location
  
  // Post fix for all deployed resources
  postfix = random_id.deployer.hex

  // Management vnet
  vnet_mgmt        = try(var.infrastructure.vnets.management, {})
  vnet_mgmt_arm_id = try(local.vnet_mgmt.arm_id, "")
  vnet_mgmt_exists = length(local.vnet_mgmt_arm_id) > 0

  // If resource ID is specified extract the vnet name from it otherwise read it either from input of create using the naming convention
  vnet_mgmt_name = local.vnet_mgmt_exists ? (
    split("/", local.vnet_mgmt_arm_id)[8]) : (
    length(local.vnet_mgmt.name) > 0 ? (
      local.vnet_mgmt.name) : (
      format("%s%s", local.prefix, local.resource_suffixes.vnet)
    )
  )

  vnet_mgmt_addr = local.vnet_mgmt_exists ? "" : try(local.vnet_mgmt.address_space, "")

  // Management subnet
  sub_mgmt        = try(local.vnet_mgmt.subnet_mgmt, {})
  sub_mgmt_arm_id = try(local.sub_mgmt.arm_id, "")
  sub_mgmt_exists = length(local.sub_mgmt_arm_id) > 0

  // If resource ID is specified extract the subnet name from it otherwise read it either from input of create using the naming convention
  sub_mgmt_name = local.sub_mgmt_exists ? (
    split("/", local.sub_mgmt_arm_id)[10]) : (
    length(local.sub_mgmt.name) > 0 ? (
      local.sub_mgmt.name) : (
      format("%s%s", local.prefix, local.resource_suffixes.deployer_subnet)
  ))

  sub_mgmt_prefix = local.sub_mgmt_exists ? "" : try(local.sub_mgmt.prefix, "")

  sub_mgmt_deployed = local.sub_mgmt_exists ? data.azurerm_subnet.subnet_mgmt[0] : azurerm_subnet.subnet_mgmt[0]

  // Management NSG
  sub_mgmt_nsg        = try(local.sub_mgmt.nsg, {})
  sub_mgmt_nsg_arm_id = try(local.sub_mgmt_nsg.arm_id, "")
  sub_mgmt_nsg_exists = length(local.sub_mgmt_nsg_arm_id) > 0
  // If resource ID is specified extract the nsg name from it otherwise read it either from input of create using the naming convention
  sub_mgmt_nsg_name = local.sub_mgmt_nsg_exists ? (
    split("/", local.sub_mgmt_nsg_arm_id)[8]) : (
    length(local.sub_mgmt_nsg.name) > 0 ? (
      local.sub_mgmt_nsg.name) : (
      format("%s%s", local.prefix, local.resource_suffixes.deployer_subnet_nsg)
  ))

  sub_mgmt_nsg_allowed_ips = local.sub_mgmt_nsg_exists ? (
    []) : (
    length(local.sub_mgmt_nsg.allowed_ips) > 0 ? (
      local.sub_mgmt_nsg.allowed_ips) : (
      ["0.0.0.0/0"]
    )
  )
  sub_mgmt_nsg_deployed = local.sub_mgmt_nsg_exists ? data.azurerm_network_security_group.nsg_mgmt[0] : azurerm_network_security_group.nsg_mgmt[0]

  // Firewall subnet
  sub_fw_snet        = try(local.vnet_mgmt.subnet_fw, {})
  sub_fw_snet_arm_id = try(local.sub_fw_snet.arm_id, "")
  sub_fw_snet_exists = length(local.sub_fw_snet_arm_id) > 0
  sub_fw_snet_name   = "AzureFirewallSubnet"
  sub_fw_snet_prefix = local.sub_fw_snet_exists ? "" : try(local.sub_fw_snet.prefix, "")

  firewall_service_tags = format("AzureCloud.%s", var.infrastructure.region)

  enable_password = try(var.deployer.authentication.type, "key") == "password"
  enable_key      = !local.enable_password

  username = local.username_exist ? (
      data.azurerm_key_vault_secret.username[0].value) : (
      try(var.authentication.username, "azureadm")
    )

  // By default use generated password. Provide password under authentication overides it
  password = local.enable_password ? (
    local.pwd_exist ? (
      data.azurerm_key_vault_secret.pwd[0].value) : (
      try(var.authentication.password, random_password.deployer[0].result)
    )) : (
    null
  )

  // By default use generated public key. Provide authentication.path_to_public_key and path_to_private_key overides it
  public_key = local.enable_key ? (
    local.key_exist ? (
      data.azurerm_key_vault_secret.pk[0].value) : (
      try(file(var.authentication.path_to_public_key), tls_private_key.deployer[0].public_key_openssh)
    )) : (
    null
  )

  private_key = local.enable_key ? (
    local.key_exist ? (
      data.azurerm_key_vault_secret.ppk[0].value) : (
      try(file(var.authentication.path_to_private_key), tls_private_key.deployer[0].private_key_pem)
    )) : (
    null
  )

  // If the user specifies arm id of key vaults in input, the key vault will be imported instead of creating new key vaults
  user_key_vault_id = try(var.key_vault.kv_user_id, "")
  prvt_key_vault_id = try(var.key_vault.kv_prvt_id, "")
  user_kv_exist     = length(local.user_key_vault_id) > 0
  prvt_kv_exist     = length(local.prvt_key_vault_id) > 0

  // If the user specifies the secret name of key pair/password in input, the secrets will be imported instead of creating new secrets
  input_public_key_secret_name  = try(var.key_vault.kv_sshkey_pub, "")
  input_private_key_secret_name = try(var.key_vault.kv_sshkey_prvt, "")
  input_password_secret_name    = try(var.key_vault.kv_pwd, "")
  input_username_secret_name    = try(var.key_vault.kv_username, "")

  // If public key secret name is provided, need to provide private key secret name as well, otherwise fail with error.
  key_exist      = try(length(local.input_public_key_secret_name) > 0, false)
  pwd_exist      = try(length(local.input_password_secret_name) > 0, false)
  username_exist = try(length(local.input_username_secret_name) > 0, false)

  ppk_secret_name      = local.key_exist ? local.input_private_key_secret_name : format("%s-sshkey", local.prefix)
  pk_secret_name       = local.key_exist ? local.input_public_key_secret_name : format("%s-sshkey-pub", local.prefix)
  pwd_secret_name      = local.pwd_exist ? local.input_password_secret_name : format("%s-password", local.prefix)
  username_secret_name = local.username_exist ? local.input_username_secret_name : format("%s-username", local.prefix)

  // Extract information from the specified key vault arm ids
  user_kv_name    = local.user_kv_exist ? split("/", local.user_key_vault_id)[8] : local.keyvault_names.user_access
  user_kv_rg_name = local.user_kv_exist ? split("/", local.user_key_vault_id)[4] : ""

  prvt_kv_name    = local.prvt_kv_exist ? split("/", local.prvt_key_vault_id)[8] : local.keyvault_names.private_access
  prvt_kv_rg_name = local.prvt_kv_exist ? split("/", local.prvt_key_vault_id)[4] : ""

  // Tags
  tags = try(var.deployer.tags, { "Role" = "Deployer" })


}
