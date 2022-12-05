
###############################################################################
#                                                                             #
#                            Local Variables                                  #
#                                                                             #
###############################################################################

locals {

  version_label = trimspace(file("${path.module}/../../../configs/version.txt"))

  // The environment of sap landscape and sap system
  environment = upper(local.infrastructure.environment)

  vnet_logical_name = local.infrastructure.vnets.sap.logical_name


  // Locate the tfstate storage account
  saplib_subscription_id       = split("/", var.tfstate_resource_id)[2]
  saplib_resource_group_name   = split("/", var.tfstate_resource_id)[4]
  tfstate_storage_account_name = split("/", var.tfstate_resource_id)[8]
  tfstate_container_name       = module.sap_namegenerator.naming.resource_suffixes.tfstate

  // Retrieve the arm_id of deployer's Key Vault from deployer's terraform.tfstate
  spn_key_vault_arm_id = try(local.key_vault.kv_spn_id,
    try(data.terraform_remote_state.deployer[0].outputs.deployer_kv_user_arm_id,
    "")
  )

  deployer_subscription_id = length(local.spn_key_vault_arm_id) > 0 ? (
    split("/", local.spn_key_vault_arm_id)[2]) : (
    ""
  )

  spn = {
    subscription_id = data.azurerm_key_vault_secret.subscription_id.value,
    client_id       = var.use_spn ? data.azurerm_key_vault_secret.client_id[0].value : null,
    client_secret   = var.use_spn ? data.azurerm_key_vault_secret.client_secret[0].value : null,
    tenant_id       = var.use_spn ? data.azurerm_key_vault_secret.tenant_id[0].value : null
  }

  cp_spn = {
    subscription_id = try(data.azurerm_key_vault_secret.cp_subscription_id[0].value, null)
    client_id       = var.use_spn ? data.azurerm_key_vault_secret.cp_client_id[0].value : null,
    client_secret   = var.use_spn ? data.azurerm_key_vault_secret.cp_client_secret[0].value : null,
    tenant_id       = var.use_spn ? data.azurerm_key_vault_secret.cp_tenant_id[0].value : null
  }

  service_principal = {
    subscription_id = local.spn.subscription_id,
    tenant_id       = local.spn.tenant_id,
    object_id       = var.use_spn ? try(data.azuread_service_principal.sp[0].id, null) : null
  }

  account = {
    subscription_id = data.azurerm_key_vault_secret.subscription_id.value,
    tenant_id       = data.azurerm_client_config.current.tenant_id,
    object_id       = data.azurerm_client_config.current.object_id
  }

  ANF_settings = {
    use               = var.NFS_provider == "ANF"
    name              = var.ANF_account_name
    arm_id            = var.ANF_account_arm_id
    pool_name         = var.ANF_pool_name
    use_existing_pool = var.ANF_use_existing_pool
    service_level     = var.ANF_service_level
    size_in_tb        = var.ANF_pool_size
    qos_type          = var.ANF_qos_type

    use_existing_transport_volume = var.ANF_transport_volume_use_existing
    transport_volume_name         = var.ANF_transport_volume_name
    transport_volume_size         = var.ANF_transport_volume_size
    transport_volume_throughput   = var.ANF_transport_volume_throughput

    use_existing_install_volume = var.ANF_install_volume_use_existing
    install_volume_name         = var.ANF_install_volume_name
    install_volume_size         = var.ANF_install_volume_size
    install_volume_throughput   = var.ANF_install_volume_throughput

  }

  custom_names = length(var.name_override_file) > 0 ? (
    jsondecode(file(format("%s/%s", path.cwd, var.name_override_file)))
    ) : (
    null
  )

  vm_settings = {
    count              = var.utility_vm_count
    size               = var.utility_vm_size
    use_DHCP           = var.utility_vm_useDHCP
    image              = var.utility_vm_image
    private_ip_address = var.utility_vm_nic_ips

  }

}
