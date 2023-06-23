/*
  Description:
  Setup common infrastructure
*/

module "sap_landscape" {
  providers = {
    azurerm.main          = azurerm.workload
    azurerm.deployer      = azurerm
    azurerm.dnsmanagement = azurerm.dnsmanagement
    azurerm.peering       = azurerm.peering
  }
  source         = "../../terraform-units/modules/sap_landscape"
  infrastructure = local.infrastructure
  options        = local.options
  authentication = local.authentication
  naming = length(var.name_override_file) > 0 ? (
    local.custom_names) : (
    module.sap_namegenerator.naming
  )
  service_principal           = var.use_spn ? local.service_principal : local.account
  key_vault                   = local.key_vault
  deployer_tfstate            = try(data.terraform_remote_state.deployer[0].outputs, [])
  diagnostics_storage_account = local.diagnostics_storage_account
  witness_storage_account     = local.witness_storage_account
  use_deployer                = length(var.deployer_tfstate_key) > 0
  ANF_settings                = local.ANF_settings

  dns_label                          = var.dns_label
  dns_server_list                    = var.dns_server_list
  enable_purge_control_for_keyvaults = var.enable_purge_control_for_keyvaults
  use_private_endpoint               = var.use_private_endpoint
  use_service_endpoint               = var.use_service_endpoint
  keyvault_private_endpoint_id       = var.keyvault_private_endpoint_id

  create_vaults_and_storage_dns_a_records = var.create_vaults_and_storage_dns_a_records
  use_custom_dns_a_registration           = var.use_custom_dns_a_registration
  management_dns_subscription_id          = coalesce(var.management_dns_subscription_id, local.saplib_subscription_id)
  management_dns_resourcegroup_name = lower(length(var.management_dns_resourcegroup_name) > 0 ? (
    var.management_dns_resourcegroup_name) : (
    local.saplib_resource_group_name
  ))

  Agent_IP = var.Agent_IP

  NFS_provider = var.NFS_provider

  transport_volume_size         = var.transport_volume_size
  transport_storage_account_id  = var.transport_storage_account_id
  transport_private_endpoint_id = var.transport_private_endpoint_id

  install_volume_size         = var.install_volume_size
  install_storage_account_id  = var.install_storage_account_id
  install_private_endpoint_id = var.install_private_endpoint_id

  enable_rbac_authorization_for_keyvault       = var.enable_rbac_authorization_for_keyvault
  additional_users_to_add_to_keyvault_policies = var.additional_users_to_add_to_keyvault_policies

  vm_settings = local.vm_settings

  peer_with_control_plane_vnet = var.peer_with_control_plane_vnet

  enable_firewall_for_keyvaults_and_storage = var.enable_firewall_for_keyvaults_and_storage

  install_always_create_fileshares = var.install_always_create_fileshares
  storage_account_replication_type = var.storage_account_replication_type

  place_delete_lock_on_resources = var.place_delete_lock_on_resources

}

module "sap_namegenerator" {
  source             = "../../terraform-units/modules/sap_namegenerator"
  environment        = local.infrastructure.environment
  location           = local.infrastructure.region
  iscsi_server_count = try(local.infrastructure.iscsi.iscsi_count, 0)
  codename           = lower(try(local.infrastructure.codename, ""))
  random_id          = module.sap_landscape.random_id
  sap_vnet_name      = local.infrastructure.vnets.sap.logical_name
  utility_vm_count   = var.utility_vm_count
}

