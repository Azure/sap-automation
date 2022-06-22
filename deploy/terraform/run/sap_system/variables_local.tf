
locals {

  version_label = trimspace(file("${path.module}/../../../configs/version.txt"))
  // The environment of sap landscape and sap system
  environment     = upper(local.infrastructure.environment)
  vnet_sap_arm_id = try(data.terraform_remote_state.landscape.outputs.vnet_sap_arm_id, "")

  vnet_logical_name = local.infrastructure.vnets.sap.logical_name
  vnet_sap_exists   = length(local.vnet_sap_arm_id) > 0 ? true : false

  //SID determination

  hana-databases = [
    for db in local.databases : db
    if try(db.platform, "NONE") == "HANA"
  ]

  // Filter the list of databases to only AnyDB platform entries
  // Supported databases: Oracle, DB2, SQLServer, ASE 
  anydb-databases = [
    for database in local.databases : database
    if contains(["ORACLE", "DB2", "SQLSERVER", "ASE"], upper(try(database.platform, "NONE")))
  ]

  hdb            = try(local.hana-databases[0], {})
  hdb_ins        = try(local.hdb.instance, {})
  hanadb_sid     = try(local.hdb_ins.sid, "HDB") // HANA database sid from the Databases array for use as reference to LB/AS
  anydb_platform = try(local.anydb-databases[0].platform, "NONE")
  anydb_sid = (length(local.anydb-databases) > 0) ? (
    try(local.anydb-databases[0].instance.sid, lower(substr(local.anydb_platform, 0, 3)))) : (
    lower(substr(local.anydb_platform, 0, 3))
  )
  db_sid  = length(local.hana-databases) > 0 ? local.hanadb_sid : local.anydb_sid
  sap_sid = upper(try(local.application.sid, local.db_sid))

  enable_db_deployment = (
    length(local.hana-databases) > 0
    || length(local.anydb-databases) > 0
  )

  db_zonal_deployment = length(try(local.databases[0].zones, [])) > 0

  // Locate the tfstate storage account
  saplib_subscription_id       = split("/", var.tfstate_resource_id)[2]
  saplib_resource_group_name   = split("/", var.tfstate_resource_id)[4]
  tfstate_storage_account_name = split("/", var.tfstate_resource_id)[8]
  tfstate_container_name       = module.sap_namegenerator.naming.resource_suffixes.tfstate

  // Retrieve the arm_id of deployer's Key Vault from deployer's terraform.tfstate
  spn_key_vault_arm_id = coalesce(
    try(local.key_vault.kv_spn_id, ""),
    try(data.terraform_remote_state.landscape.outputs.landscape_key_vault_spn_arm_id, ""),
    try(data.terraform_remote_state.deployer[0].outputs.deployer_keyvault_user_arm_id, "")
  )

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
    use_for_data             = var.ANF_use_for_HANA_data
    data_volume_size         = var.ANF_HANA_data_volume_size
    use_existing_data_volume = var.ANF_use_existing_data_volume
    data_volume_name         = var.ANF_data_volume_name
    data_volume_throughput   = var.ANF_HANA_data_volume_throughput

    use_for_log             = var.ANF_use_for_HANA_log
    log_volume_size         = var.ANF_HANA_log_volume_size
    use_existing_log_volume = var.ANF_use_existing_log_volume
    log_volume_name         = var.ANF_log_volume_name
    log_volume_throughput   = var.ANF_HANA_log_volume_throughput

    use_for_shared             = var.ANF_use_for_HANA_shared
    shared_volume_size         = var.ANF_HANA_shared_volume_size
    use_existing_shared_volume = var.ANF_use_existing_shared_volume
    shared_volume_name         = var.ANF_HANA_shared_volume_name
    shared_volume_throughput   = var.ANF_HANA_shared_volume_throughput

    use_for_usr_sap             = var.ANF_use_for_usr_sap
    usr_sap_volume_size         = var.ANF_usr_sap_volume_size
    use_existing_usr_sap_volume = var.ANF_use_existing_usr_sap_volume
    usr_sap_volume_name         = var.ANF_HANA_usr_sap_volume_name
    usr_sap_volume_throughput   = var.ANF_HANA_usr_sap_throughput

    sapmnt_volume_size         = var.sapmnt_volume_size
    use_existing_sapmnt_volume = var.ANF_use_existing_sapmnt_volume
    sapmnt_volume_name         = var.ANF_sapmnt_volume_name
    sapmnt_volume_throughput   = var.ANF_HANA_sapmnt_volume_throughput

  }

}
