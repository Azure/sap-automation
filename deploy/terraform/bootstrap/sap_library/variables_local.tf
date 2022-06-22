locals {
  version_label   = trimspace(file("${path.module}/../../../configs/version.txt"))
  deployer_prefix = module.sap_namegenerator.naming.prefix.DEPLOYER

  // If custom names are used for deployer, providing resource_group_name and msi_name will override the naming convention
  deployer_rg_name = try(local.deployer.resource_group_name,
    format("%s%s",
      local.deployer_prefix,
      module.sap_namegenerator.naming.resource_suffixes.deployer_rg
    )
  )
  // Retrieve the arm_id of deployer's Key Vault from deployer's terraform.tfstate
  spn_key_vault_arm_id = try(data.terraform_remote_state.deployer[0].outputs.deployer_kv_user_arm_id, "")

  spn = {
    subscription_id = var.use_deployer ? data.azurerm_key_vault_secret.subscription_id[0].value : null,
    client_id       = var.use_deployer ? data.azurerm_key_vault_secret.client_id[0].value : null,
    client_secret   = var.use_deployer ? data.azurerm_key_vault_secret.client_secret[0].value : null,
    tenant_id       = var.use_deployer ? data.azurerm_key_vault_secret.tenant_id[0].value : null
  }

  service_principal = {
    subscription_id = local.spn.subscription_id,
    tenant_id       = local.spn.tenant_id,
    object_id       = var.use_deployer ? data.azuread_service_principal.sp[0].id : null
  }

  account = {
    subscription_id = var.use_deployer ? data.azurerm_key_vault_secret.subscription_id[0].value : null,
    tenant_id       = data.azurerm_client_config.current.tenant_id,
    object_id       = data.azurerm_client_config.current.object_id
  }

  custom_names = length(var.name_override_file) > 0 ? (
    jsondecode(file(format("%s/%s", path.cwd, var.name_override_file)))) : (
    null
  )

}
