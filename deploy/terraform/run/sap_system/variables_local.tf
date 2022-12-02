
locals {

  version_label = trimspace(file("${path.module}/../../../configs/version.txt"))
  // The environment of sap landscape and sap system
  environment     = upper(local.infrastructure.environment)
  vnet_sap_arm_id = try(data.terraform_remote_state.landscape.outputs.vnet_sap_arm_id, "")

  vnet_logical_name = local.infrastructure.vnets.sap.logical_name
  vnet_sap_exists   = length(local.vnet_sap_arm_id) > 0 ? true : false


  db_sid  = upper(try(local.database.instance.sid, "HDB"))
  sap_sid = upper(try(local.application_tier.sid, local.db_sid))

  enable_db_deployment = length(local.database.platform) > 0

  db_zonal_deployment = length(try(local.database.zones, [])) > 0

  // Locate the tfstate storage account
  saplib_subscription_id       = split("/", var.tfstate_resource_id)[2]
  saplib_resource_group_name   = split("/", var.tfstate_resource_id)[4]
  tfstate_storage_account_name = split("/", var.tfstate_resource_id)[8]
  tfstate_container_name       = module.sap_namegenerator.naming.resource_suffixes.tfstate

  // Retrieve the arm_id of deployer's Key Vault
  spn_key_vault_arm_id = trimspace(coalesce(
    try(local.key_vault.kv_spn_id, ""),
    try(data.terraform_remote_state.landscape.outputs.landscape_key_vault_spn_arm_id, ""),
    try(data.terraform_remote_state.deployer[0].outputs.deployer_kv_user_arm_id, ""),
    " "
  ))

  deployer_subscription_id = length(local.spn_key_vault_arm_id) > 0 ? split("/", local.spn_key_vault_arm_id)[2] : ""

  spn = {
    subscription_id = data.azurerm_key_vault_secret.subscription_id.value,
    client_id       = var.use_spn ? data.azurerm_key_vault_secret.client_id[0].value : null,
    client_secret   = var.use_spn ? data.azurerm_key_vault_secret.client_secret[0].value : null,
    tenant_id       = var.use_spn ? data.azurerm_key_vault_secret.tenant_id[0].value : null
  }

  service_principal = {
    subscription_id = local.spn.subscription_id,
    tenant_id       = local.spn.tenant_id,
    object_id       = var.use_spn ? data.azuread_service_principal.sp[0].id : null
  }

  account = {
    subscription_id = data.azurerm_key_vault_secret.subscription_id.value,
    tenant_id       = data.azurerm_client_config.current.tenant_id,
    object_id       = data.azurerm_client_config.current.object_id
  }

  custom_names = length(var.name_override_file) > 0 ? (
    jsondecode(file(format("%s/%s", path.cwd, var.name_override_file)))) : (
    null
  )

  hana_ANF_volumes = {
    use_for_data             = var.ANF_HANA_data
    data_volume_size         = var.ANF_HANA_data_volume_size
    use_existing_data_volume = var.ANF_HANA_data_use_existing_volume
    data_volume_name         = var.ANF_HANA_data_volume_name
    data_volume_throughput   = var.ANF_HANA_data_volume_throughput

    use_for_log             = var.ANF_HANA_log
    log_volume_size         = var.ANF_HANA_log_volume_size
    use_existing_log_volume = var.ANF_HANA_log_use_existing
    log_volume_name         = var.ANF_HANA_log_volume_name
    log_volume_throughput   = var.ANF_HANA_log_volume_throughput

    use_for_shared             = var.ANF_HANA_shared
    shared_volume_size         = var.ANF_HANA_shared_volume_size
    use_existing_shared_volume = var.ANF_HANA_shared_use_existing
    shared_volume_name         = var.ANF_HANA_shared_volume_name
    shared_volume_throughput   = var.ANF_HANA_shared_volume_throughput

    use_for_usr_sap             = var.ANF_usr_sap
    usr_sap_volume_size         = var.ANF_usr_sap_volume_size
    use_existing_usr_sap_volume = var.ANF_usr_sap_use_existing
    usr_sap_volume_name         = var.ANF_usr_sap_volume_name
    usr_sap_volume_throughput   = var.ANF_usr_sap_throughput

    sapmnt_volume_size         = var.sapmnt_volume_size
    use_existing_sapmnt_volume = var.ANF_sapmnt
    sapmnt_volume_name         = var.ANF_sapmnt_volume_name
    sapmnt_volume_throughput   = var.ANF_sapmnt_volume_throughput

  }

}
