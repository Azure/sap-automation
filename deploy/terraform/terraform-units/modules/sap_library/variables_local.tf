/*
Description:

  Define local variables.
*/

// Input arguments 
variable "naming" {
  description = "naming convention"
}

variable "deployer_tfstate" {
  description = "terraform.tfstate of deployer"
}

variable "service_principal" {
  description = "Current service principal used to authenticate to Azure"
}

variable "use_private_endpoint" {
  default = false
}

locals {

  storageaccount_names = var.naming.storageaccount_names.LIBRARY
  resource_suffixes    = var.naming.resource_suffixes

  // Infrastructure
  var_infra = try(var.infrastructure, {})

  // Region
  region = try(local.var_infra.region, "")
  prefix = length(local.var_infra.resource_group.name) > 0 ? (
    local.var_infra.resource_group.name) : (
    trimspace(var.naming.prefix.LIBRARY)
  )

  // Resource group
  rg_exists = length(var.infrastructure.resource_group.arm_id) > 0

  rg_name = local.rg_exists ? (
    try(split("/", var.infrastructure.resource_group.arm_id)[4], "")) : (
    length(local.var_infra.resource_group.name) > 0 ? (
      local.var_infra.resource_group.name) : (
      format("%s%s%s",
        var.naming.resource_prefixes.library_rg,
        local.prefix,
        local.resource_suffixes.library_rg
      )
    )
  )
  rg_library_location = local.rg_exists ? (
    data.azurerm_resource_group.library[0].location) : (
    azurerm_resource_group.library[0].location
  )

  // Storage account for sapbits
  sa_sapbits_exists = length(var.storage_account_sapbits.arm_id) > 0
  sa_sapbits_name = local.sa_sapbits_exists ? (
    split("/", var.storage_account_sapbits.arm_id)[8]) : (
    local.storageaccount_names.library_storageaccount_name
  )

  // Storage account for tfstate
  sa_tfstate_arm_id = try(var.storage_account_tfstate.arm_id, "")
  sa_tfstate_exists = length(local.sa_tfstate_arm_id) > 0

  // deployer
  deployer      = try(var.deployer, {})
  deployer_vnet = try(var.deployer.vnet, "")

  // Comment out code with users.object_id for the time being.
  // deployer_users_id = try(local.deployer.users.object_id, [])

  // Current service principal
  service_principal = try(var.service_principal, {})

  // deployer terraform.tfstate
  deployer_tfstate = var.deployer_tfstate
  deployer_defined = length(var.deployer_tfstate) > 0
  deployer_msi_principal_id = local.deployer_defined ? (
    try(
      local.deployer_tfstate.deployer_uai.principal_id,
      local.deployer_tfstate.deployer_uai
    )) : (
    ""
  )

  subnet_management_id = local.deployer_defined ? local.deployer_tfstate.subnet_mgmt_id : ""

  deployer_public_ip_address = local.deployer_defined ? (
    local.deployer_tfstate.deployer_public_ip_address) : (
      ""
      )
  
  deployer_keyvault_user_arm_id = local.deployer_defined ? try(local.deployer_tfstate.deployer_keyvault_user_arm_id, "") : ""

}
