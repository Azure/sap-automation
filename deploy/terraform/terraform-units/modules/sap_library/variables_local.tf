
locals {

  #  storageaccount_names = var.naming.storageaccount_names.LIBRARY
  #  resource_suffixes    = var.naming.resource_suffixes

  // Infrastructure
  var_infra = try(var.infrastructure, {})

  // Region
  region = try(local.var_infra.region, "")
  prefix = length(local.var_infra.resource_group.name) > 0 ? (
    local.var_infra.resource_group.name) : (
    trimspace(var.naming.prefix.LIBRARY)
  )

  // Resource group
  resource_group_exists = length(var.infrastructure.resource_group.arm_id) > 0

  resource_group_name = local.resource_group_exists ? (
    try(split("/", var.infrastructure.resource_group.arm_id)[4], "")) : (
    length(local.var_infra.resource_group.name) > 0 ? (
      local.var_infra.resource_group.name) : (
      format("%s%s%s",
        var.naming.resource_prefixes.library_rg,
        local.prefix,
        var.naming.resource_suffixes.library_rg
      )
    )
  )
  resource_group_library_location = local.resource_group_exists ? (
    data.azurerm_resource_group.library[0].location) : (
    azurerm_resource_group.library[0].location
  )

  // Storage account for sapbits
  sa_sapbits_exists = length(var.storage_account_sapbits.arm_id) > 0
  sa_sapbits_name = local.sa_sapbits_exists ? (
    split("/", var.storage_account_sapbits.arm_id)[8]) : (
    var.naming.storageaccount_names.LIBRARY.library_storageaccount_name
  )

  // Storage account for tfstate
  sa_tfstate_arm_id = try(var.storage_account_tfstate.arm_id, "")
  sa_tfstate_exists = length(local.sa_tfstate_arm_id) > 0


  // Comment out code with users.object_id for the time being.
  // deployer_users_id = try(local.deployer.users.object_id, [])

  // Current service principal
  service_principal = try(var.service_principal, {})

  deployer_public_ip_address = try(var.deployer_tfstate.deployer_public_ip_address, "")

  enable_firewall_for_keyvaults_and_storage = try(var.deployer_tfstate.enable_firewall_for_keyvaults_and_storage, false)


}
