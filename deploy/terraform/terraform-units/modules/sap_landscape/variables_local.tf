/*
  Description:
  Define local variables
*/

variable "deployer_tfstate" {
  description = "Deployer remote tfstate file"
}

variable "service_principal" {
  description = "Current service principal used to authenticate to Azure"
}

variable "naming" {
  description = "Defines the names for the resources"
}

variable "use_deployer" {
  description = "Use the deployer"
}

variable "ANF_settings" {
  description = "ANF settings"
  default = {
    use           = false
    name          = ""
    arm_id        = ""
    service_level = "Standard"
    size_in_tb    = 4

  }
}

variable "enable_purge_control_for_keyvaults" {
  description = "Allow the deployment to control the purge protection"
}

variable "dns_label" {
  description = "DNS label"
  default     = ""
}

variable "dns_resource_group_name" {
  description = "DNS resource group name"
  default     = ""
}

variable "use_private_endpoint" {
  type        = bool
  description = "Private endpoint"
  default     = false
}

variable "transport_volume_size" {
  description = "The volume size in GB for shared"
}

variable "azure_files_transport_storage_account_id" {
  description = "Azure Resource Identifier for an existing storage account"
  type        = string
}

variable "azure_files_storage_account_id" {
  description = "Azure Resource Identifier for an existing storage account"
  type        = string
}

variable "NFS_provider" {
  description = "Describes the NFS solution used"
  type        = string
}

variable "Agent_IP" {
  type    = string
  default = ""
}

locals {
  // Resources naming
  storageaccount_name                             = var.naming.storageaccount_names.WORKLOAD_ZONE.landscape_storageaccount_name
  witness_storageaccount_name                     = var.naming.storageaccount_names.WORKLOAD_ZONE.witness_storageaccount_name
  landscape_shared_transport_storage_account_name = var.naming.storageaccount_names.WORKLOAD_ZONE.landscape_shared_transport_storage_account_name
  landscape_keyvault_names                        = var.naming.keyvault_names.WORKLOAD_ZONE
  sid_keyvault_names                              = var.naming.keyvault_names.SDU
  resource_suffixes                               = var.naming.resource_suffixes
  virtualmachine_names                            = var.naming.virtualmachine_names.ISCSI_COMPUTERNAME

}

locals {

  // Region and metadata
  region = var.infrastructure.region
  prefix = trimspace(var.naming.prefix.WORKLOAD_ZONE)

  vnet_mgmt_id = try(var.deployer_tfstate.vnet_mgmt_id, try(var.deployer_tfstate.vnet_mgmt.id, ""))
  firewall_ip  = try(var.deployer_tfstate.firewall_ip, "")

  // Firewall
  firewall_id     = try(var.deployer_tfstate.firewall_id, "")
  firewall_exists = length(local.firewall_id) > 0
  firewall_name   = local.firewall_exists ? try(split("/", local.firewall_id)[8], "") : ""
  firewall_rgname = local.firewall_exists ? try(split("/", local.firewall_id)[4], "") : ""

  firewall_service_tags = format("AzureCloud.%s", local.region)

  deployer_subnet_management_id = try(var.deployer_tfstate.subnet_mgmt_id, null)

  deployer_public_ip_address = try(var.deployer_tfstate.deployer_public_ip_address, null)


  // Resource group
  rg_exists = length(try(var.infrastructure.resource_group.arm_id, "")) > 0
  rg_name = local.rg_exists ? (
    try(split("/", var.infrastructure.resource_group.arm_id)[4], "")) : (
    length(try(var.infrastructure.resource_group.name, "")) > 0 ? (
      var.infrastructure.resource_group.name) : (
      format("%s%s%s",
        var.naming.resource_prefixes.vnet_rg,
        local.prefix,
        local.resource_suffixes.vnet_rg
      )
    )
  )

  // SAP vnet
  vnet_sap_arm_id = try(var.infrastructure.vnets.sap.arm_id, "")
  vnet_sap_exists = length(local.vnet_sap_arm_id) > 0
  vnet_sap_name = local.vnet_sap_exists ? (
    try(split("/", local.vnet_sap_arm_id)[8], "")) : (
    coalesce(
      var.infrastructure.vnets.sap.name,
      format("%s%s%s", var.naming.resource_prefixes.vnet, local.prefix, local.resource_suffixes.vnet)
    )
  )
  vnet_sap_addr = local.vnet_sap_exists ? "" : try(var.infrastructure.vnets.sap.address_space, "")

  // By default, Ansible ssh key for SID uses generated public key. 
  // Provide sshkey.path_to_public_key and path_to_private_key overides it

  sid_public_key = local.sid_key_exist ? (
    data.azurerm_key_vault_secret.sid_pk[0].value) : (
    try(file(var.authentication.path_to_public_key), tls_private_key.sid[0].public_key_openssh)
  )
  sid_private_key = local.sid_key_exist ? (
    data.azurerm_key_vault_secret.sid_ppk[0].value) : (
    try(file(var.authentication.path_to_private_key), tls_private_key.sid[0].private_key_pem)
  )

  // Current service principal
  service_principal = try(var.service_principal, {})

  // If the user specifies arm id of key vaults in input, 
  // the key vault will be imported instead of creating new key vaults

  user_key_vault_id         = try(var.key_vault.kv_user_id, "")
  prvt_key_vault_id         = try(var.key_vault.kv_prvt_id, "")
  user_keyvault_exist       = length(local.user_key_vault_id) > 0
  automation_keyvault_exist = length(local.prvt_key_vault_id) > 0

  enable_landscape_kv = !local.user_keyvault_exist

  // If the user specifies the secret name of key pair/password in input, 
  // the secrets will be imported instead of creating new secrets
  input_sid_public_key_secret_name  = try(var.key_vault.kv_sid_sshkey_pub, "")
  input_sid_private_key_secret_name = try(var.key_vault.kv_sid_sshkey_prvt, "")
  sid_key_exist                     = try(length(local.input_sid_public_key_secret_name) > 0, false)

  input_sid_username = try(var.authentication.username, "azureadm")
  input_sid_password = length(try(var.authentication.password, "")) > 0 ? (
    var.authentication.password) : (
    random_password.created_password.result
  )

  sid_ppk_name = local.sid_key_exist ? (
    local.input_sid_private_key_secret_name) : (
    trimprefix(
      format("%s-sid-sshkey",
        length(local.prefix) > 0 ? (
          local.prefix) : (
          var.infrastructure.environment
        )
      ),
      "-"
    )
  )

  sid_pk_name = local.sid_key_exist ? (
    local.input_sid_public_key_secret_name) : (
    trimprefix(
      format("%s-sid-sshkey-pub",
        length(local.prefix) > 0 ? (
          local.prefix) : (
          var.infrastructure.environment
        )
      ),
      "-"
    )
  )

  input_sid_username_secret_name = try(var.key_vault.kv_sid_username, "")
  input_sid_password_secret_name = try(var.key_vault.kv_sid_pwd, "")
  sid_credentials_secret_exist   = length(local.input_sid_username_secret_name) > 0

  sid_username_secret_name = local.sid_credentials_secret_exist ? (
    local.input_sid_username_secret_name) : (
    trimprefix(
      format("%s-sid-username",
        length(local.prefix) > 0 ? (
          local.prefix) : (
          var.infrastructure.environment
        )
      ),
      "-"
    )
  )
  sid_password_secret_name = local.sid_credentials_secret_exist ? (
    local.input_sid_password_secret_name) : (
    trimprefix(
      format("%s-sid-password",
        length(local.prefix) > 0 ? (
          local.prefix) : (
          var.infrastructure.environment
        )
      ),
      "-"
    )
  )

  // Extract information from the specified key vault arm ids
  user_keyvault_name = local.user_keyvault_exist ? (
    split("/", local.user_key_vault_id)[8]) : (
    local.landscape_keyvault_names.user_access
  )

  user_keyvault_rg_name = local.user_keyvault_exist ? (
    split("/", local.user_key_vault_id)[4]) : (
    ""
  )

  automation_keyvault_name = local.automation_keyvault_exist ? (
    split("/", local.prvt_key_vault_id)[8]) : (
    local.landscape_keyvault_names.private_access
  )

  automation_keyvault_rg_name = local.automation_keyvault_exist ? (
    split("/", local.prvt_key_vault_id)[4]) : (
    ""
  )

  // In brownfield scenarios the subnets are often defined in the workload
  // If subnet information is specified in the parameter file use it
  // As either of the arm_id or the prefix need to be specified to create 
  // a subnet the lack of both indicate that the subnet is to be created in the 
  // SAP Infrastructure Deployment

  ##############################################################################################
  #
  #  Admin subnet - Check if locally provided 
  #
  ##############################################################################################

  admin_subnet_defined = (
    length(try(var.infrastructure.vnets.sap.subnet_admin.arm_id, "")) +
    length(try(var.infrastructure.vnets.sap.subnet_admin.prefix, ""))
  ) > 0
  admin_subnet_arm_id = local.admin_subnet_defined ? (
    try(var.infrastructure.vnets.sap.subnet_admin.arm_id, "")) : (
    ""
  )
  admin_subnet_existing = length(local.admin_subnet_arm_id) > 0
  admin_subnet_name = local.admin_subnet_existing ? (
    try(split("/", local.admin_subnet_arm_id)[10], "")) : (
    length(try(var.infrastructure.vnets.sap.subnet_admin.name, "")) > 0 ? (
      var.infrastructure.vnets.sap.subnet_admin.name) : (
      format("%s%s%s%s",
        var.naming.resource_prefixes.admin_subnet,
        length(local.prefix) > 0 ? (
          local.prefix) : (
          var.infrastructure.environment
        ),
        var.naming.separator,
        local.resource_suffixes.admin_subnet
      )
    )
  )
  admin_subnet_prefix = local.admin_subnet_defined ? (
    try(var.infrastructure.vnets.sap.subnet_admin.prefix, "")) : (
    ""
  )

  ##############################################################################################
  #
  #  Admin subnet NSG - Check if locally provided 
  #
  ##############################################################################################

  admin_subnet_nsg_arm_id = local.admin_subnet_defined ? (
    try(var.infrastructure.vnets.sap.subnet_admin.nsg.arm_id, "")) : (
    ""
  )
  admin_subnet_nsg_exists = length(local.admin_subnet_nsg_arm_id) > 0
  admin_subnet_nsg_name = local.admin_subnet_nsg_exists ? (
    try(split("/", local.admin_subnet_nsg_arm_id)[8], "")) : (
    length(try(var.infrastructure.vnets.sap.subnet_admin.nsg.name, "")) > 0 ? (
      var.infrastructure.vnets.sap.subnet_admin.nsg.name) : (
      format("%s%s%s%s",
        var.naming.resource_prefixes.admin_subnet_nsg,
        length(local.prefix) > 0 ? (
          local.prefix) : (
          var.infrastructure.environment
        ),
        var.naming.separator,
        local.resource_suffixes.admin_subnet_nsg
      )
    )
  )

  ##############################################################################################
  #
  #  Database subnet - Check if locally provided 
  #
  ##############################################################################################

  database_subnet_defined = (
    length(try(var.infrastructure.vnets.sap.subnet_db.arm_id, "")) +
    length(try(var.infrastructure.vnets.sap.subnet_db.prefix, ""))
  ) > 0
  database_subnet_arm_id = local.database_subnet_defined ? (
    try(var.infrastructure.vnets.sap.subnet_db.arm_id, "")) : (
    ""
  )
  database_subnet_existing = length(local.database_subnet_arm_id) > 0
  database_subnet_name = local.database_subnet_existing ? (
    try(split("/", local.database_subnet_arm_id)[10], "")) : (
    length(try(var.infrastructure.vnets.sap.subnet_db.name, "")) > 0 ? (
      var.infrastructure.vnets.sap.subnet_db.name) : (
      format("%s%s%s%s",
        var.naming.resource_prefixes.db_subnet,
        length(local.prefix) > 0 ? (
          local.prefix) : (
          var.infrastructure.environment
        ),
        var.naming.separator,
        local.resource_suffixes.db_subnet
      )
    )
  )

  database_subnet_prefix = local.database_subnet_defined ? (
    try(var.infrastructure.vnets.sap.subnet_db.prefix, "")) : (
    ""
  )

  ##############################################################################################
  #
  #  Database subnet NSG - Check if locally provided 
  #
  ##############################################################################################


  database_subnet_nsg_arm_id = local.database_subnet_defined ? (
    try(var.infrastructure.vnets.sap.subnet_db.nsg.arm_id, "")) : (
    ""
  )
  database_subnet_nsg_exists = length(local.database_subnet_nsg_arm_id) > 0
  database_subnet_nsg_name = local.database_subnet_nsg_exists ? (
    try(split("/", local.database_subnet_nsg_arm_id)[8], "")) : (
    length(try(var.infrastructure.vnets.sap.subnet_db.nsg.name, "")) > 0 ? (
      var.infrastructure.vnets.sap.subnet_db.nsg.name) : (
      format("%s%s%s%s",
        var.naming.resource_prefixes.db_subnet_nsg,
        length(local.prefix) > 0 ? (
          local.prefix) : (
          var.infrastructure.environment
        ),
        var.naming.separator,
        local.resource_suffixes.db_subnet_nsg
      )
    )
  )

  ##############################################################################################
  #
  #  Application subnet - Check if locally provided 
  #
  ##############################################################################################

  application_subnet_defined = (
    length(try(var.infrastructure.vnets.sap.subnet_app.arm_id, "")) +
    length(try(var.infrastructure.vnets.sap.subnet_app.prefix, ""))
  ) > 0
  application_subnet_arm_id = local.application_subnet_defined ? (
    try(var.infrastructure.vnets.sap.subnet_app.arm_id, "")) : (
    ""
  )
  application_subnet_existing = length(local.application_subnet_arm_id) > 0
  application_subnet_name = local.application_subnet_existing ? (
    try(split("/", local.application_subnet_arm_id)[10], "")) : (
    length(try(var.infrastructure.vnets.sap.subnet_app.name, "")) > 0 ? (
      var.infrastructure.vnets.sap.subnet_app.name) : (
      format("%s%s%s%s",
        var.naming.resource_prefixes.app_subnet,
        length(local.prefix) > 0 ? (
          local.prefix) : (
          var.infrastructure.environment
        ),
        var.naming.separator,
        local.resource_suffixes.app_subnet
      )
    )

  )
  application_subnet_prefix = local.application_subnet_defined ? (
    try(var.infrastructure.vnets.sap.subnet_app.prefix, "")) : (
    ""
  )

  ##############################################################################################
  #
  #  Application subnet NSG - Check if locally provided 
  #
  ##############################################################################################

  application_subnet_nsg_arm_id = local.application_subnet_defined ? (
    try(var.infrastructure.vnets.sap.subnet_app.nsg.arm_id, "")) : (
    ""
  )
  application_subnet_nsg_exists = length(local.application_subnet_nsg_arm_id) > 0
  application_subnet_nsg_name = local.application_subnet_nsg_exists ? (
    try(split("/", local.application_subnet_nsg_arm_id)[8], "")) : (
    length(try(var.infrastructure.vnets.sap.subnet_app.nsg.name, "")) > 0 ? (
      var.infrastructure.vnets.sap.subnet_app.nsg.name) : (
      format("%s%s%s%s",
        var.naming.resource_prefixes.app_subnet_nsg,
        length(local.prefix) > 0 ? (
          local.prefix) : (
          var.infrastructure.environment
        ),
        var.naming.separator,
        local.resource_suffixes.app_subnet_nsg
      )
    )
  )

  ##############################################################################################
  #
  #  Web subnet - Check if locally provided 
  #
  ##############################################################################################

  web_subnet_defined = (
    length(try(var.infrastructure.vnets.sap.subnet_web.arm_id, "")) +
    length(try(var.infrastructure.vnets.sap.subnet_web.prefix, ""))
  ) > 0
  web_subnet_arm_id = local.web_subnet_defined ? (
    try(var.infrastructure.vnets.sap.subnet_web.arm_id, "")) : (
    ""
  )
  web_subnet_existing = length(local.web_subnet_arm_id) > 0
  web_subnet_name = local.web_subnet_existing ? (
    try(split("/", local.web_subnet_arm_id)[10], "")) : (
    length(try(var.infrastructure.vnets.sap.subnet_web.name, "")) > 0 ? (
      var.infrastructure.vnets.sap.subnet_web.name) : (
      format("%s%s%s%s",
        var.naming.resource_prefixes.web_subnet,
        length(local.prefix) > 0 ? (
          local.prefix) : (
          var.infrastructure.environment
        ),
        var.naming.separator,
        local.resource_suffixes.web_subnet
      )
    )
  )
  web_subnet_prefix = local.web_subnet_defined ? (
    try(var.infrastructure.vnets.sap.subnet_web.prefix, "")) : (
    ""
  )

  ##############################################################################################
  #
  #  Web subnet NSG - Check if locally provided 
  #
  ##############################################################################################

  web_subnet_nsg_arm_id = local.web_subnet_defined ? (
    try(var.infrastructure.vnets.sap.subnet_web.nsg.arm_id, "")) : (
    ""
  )
  web_subnet_nsg_exists = length(local.web_subnet_nsg_arm_id) > 0

  web_subnet_nsg_name = local.web_subnet_nsg_exists ? (
    try(split("/", local.web_subnet_nsg_arm_id)[8], "")) : (
    length(try(var.infrastructure.vnets.sap.subnet_web.nsg.name, "")) > 0 ? (
      var.infrastructure.vnets.sap.subnet_web.nsg.name) : (
      format("%s%s%s%s",
        var.naming.resource_prefixes.web_subnet_nsg,
        length(local.prefix) > 0 ? (
          local.prefix) : (
          var.infrastructure.environment
        ),
        var.naming.separator,
        local.resource_suffixes.web_subnet_nsg
      )
    )
  )

  ##############################################################################################
  #
  #  ANF subnet - Check if locally provided 
  #
  ##############################################################################################


  ANF_subnet_defined = (
    length(try(var.infrastructure.vnets.sap.subnet_anf.arm_id, "")) +
    length(try(var.infrastructure.vnets.sap.subnet_anf.prefix, ""))
  ) > 0
  ANF_subnet_arm_id = local.ANF_subnet_defined ? (
    try(var.infrastructure.vnets.sap.subnet_anf.arm_id, "")) : (
    ""
  )
  ANF_subnet_existing = length(local.ANF_subnet_arm_id) > 0
  ANF_subnet_name = local.ANF_subnet_existing ? (
    try(split("/", local.ANF_subnet_arm_id)[10], "")) : (
    length(try(var.infrastructure.vnets.sap.subnet_anf.name, "")) > 0 ? (
      var.infrastructure.vnets.sap.subnet_anf.name) : (
      format("%s%s%s%s",
        var.naming.resource_prefixes.anf_subnet,
        length(local.prefix) > 0 ? (
          local.prefix) : (
          var.infrastructure.environment
        ),
        var.naming.separator,
        local.resource_suffixes.anf_subnet
      )
    )
  )
  ANF_subnet_prefix = local.ANF_subnet_defined ? (
    try(var.infrastructure.vnets.sap.subnet_anf.prefix, "")) : (
    ""
  )

  # Store the Deployer KV in workload zone KV
  deployer_keyvault_user_name = try(var.deployer_tfstate.deployer_kv_user_name, "")

}
