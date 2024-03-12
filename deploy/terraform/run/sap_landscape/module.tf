/*
  Description:
  Setup common infrastructure
*/

module "sap_landscape" {
  source                                       = "../../terraform-units/modules/sap_landscape"
  providers                                    = {
                                                   azurerm.main          = azurerm.workload
                                                   azurerm.deployer      = azurerm
                                                   azurerm.dnsmanagement = azurerm.dnsmanagement
                                                   azurerm.peering       = azurerm.peering
                                                   azapi.api             = azapi.api
                                                 }

  additional_users_to_add_to_keyvault_policies = var.additional_users_to_add_to_keyvault_policies
  Agent_IP                                     = var.add_Agent_IP ? var.Agent_IP : ""
  ANF_settings                                 = local.ANF_settings
  authentication                               = local.authentication
  create_transport_storage                     = var.create_transport_storage
  deployer_tfstate                             = try(data.terraform_remote_state.deployer[0].outputs, [])
  diagnostics_storage_account                  = local.diagnostics_storage_account
  dns_label                                    = var.dns_label
  dns_server_list                              = var.dns_server_list
  dns_zone_names                               = var.dns_zone_names
  enable_firewall_for_keyvaults_and_storage    = var.enable_firewall_for_keyvaults_and_storage
  enable_purge_control_for_keyvaults           = var.enable_purge_control_for_keyvaults
  enable_rbac_authorization_for_keyvault       = var.enable_rbac_authorization_for_keyvault
  infrastructure                               = local.infrastructure
  install_always_create_fileshares             = var.install_always_create_fileshares
  install_private_endpoint_id                  = var.install_private_endpoint_id
  install_storage_account_id                   = var.install_storage_account_id
  install_volume_size                          = var.install_volume_size
  key_vault                                    = local.key_vault
  keyvault_private_endpoint_id                 = var.keyvault_private_endpoint_id
  management_dns_subscription_id               = try(var.management_dns_subscription_id, local.saplib_subscription_id)
  management_dns_resourcegroup_name            = lower(length(var.management_dns_resourcegroup_name) > 0 ? (
                                                   var.management_dns_resourcegroup_name) : (
                                                   local.saplib_resource_group_name
                                                 ))
  naming                                       = length(var.name_override_file) > 0 ? (
                                                   local.custom_names) : (
                                                   module.sap_namegenerator.naming
                                                 )
  NFS_provider                                 = var.NFS_provider
  options                                      = local.options
  peer_with_control_plane_vnet                 = var.peer_with_control_plane_vnet
  place_delete_lock_on_resources               = var.place_delete_lock_on_resources
  public_network_access_enabled                = var.public_network_access_enabled
  register_virtual_network_to_dns              = var.register_virtual_network_to_dns
  service_principal                            = var.use_spn ? local.service_principal : local.account
  soft_delete_retention_days                   = var.soft_delete_retention_days
  storage_account_replication_type             = var.storage_account_replication_type
  tags                                         = var.tags
  terraform_template_version                   = local.version_label
  transport_private_endpoint_id                = var.transport_private_endpoint_id
  transport_storage_account_id                 = var.transport_storage_account_id
  transport_volume_size                        = var.transport_volume_size
  use_AFS_for_shared_storage                   = var.use_AFS_for_shared_storage
  use_custom_dns_a_registration                = var.use_custom_dns_a_registration
  use_deployer                                 = length(var.deployer_tfstate_key) > 0
  use_private_endpoint                         = var.use_private_endpoint
  use_service_endpoint                         = var.use_service_endpoint
  vm_settings                                  = local.vm_settings
  witness_storage_account                      = local.witness_storage_account

}

module "sap_namegenerator" {
  source                                       = "../../terraform-units/modules/sap_namegenerator"
  codename                                     = lower(try(local.infrastructure.codename, ""))
  environment                                  = local.infrastructure.environment
  iscsi_server_count                           = try(local.infrastructure.iscsi.iscsi_count, 0)
  location                                     = local.infrastructure.region
  random_id                                    = module.sap_landscape.random_id
  sap_vnet_name                                = local.infrastructure.vnets.sap.logical_name
  utility_vm_count                             = var.utility_vm_count
}

