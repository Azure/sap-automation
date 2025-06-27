# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

/*
  Description:
  Setup common infrastructure
*/

module "sap_landscape" {
  source                                       = "../../terraform-units/modules/sap_landscape"
  depends_on                                   = [ module.sap_namegenerator ]
  providers                                    = {
                                                   azurerm.main                     = azurerm.workload
                                                   azurerm.deployer                 = azurerm.deployer
                                                   azurerm.dnsmanagement            = azurerm.dnsmanagement
                                                   azurerm.peering                  = azurerm.peering
                                                   azurerm.privatelinkdnsmanagement = azurerm.privatelinkdnsmanagement
                                                   azapi.api                        = azapi.api
                                                 }

  additional_users_to_add_to_keyvault_policies = var.additional_users_to_add_to_keyvault_policies
  Agent_IP                                     = var.add_Agent_IP ? var.Agent_IP : ""
  ANF_settings                                 = local.ANF_settings
  authentication                               = local.authentication
  create_transport_storage                     = var.create_transport_storage
  deployer_tfstate                             = try(data.terraform_remote_state.deployer[0].outputs, [])
  diagnostics_storage_account                  = local.diagnostics_storage_account
  enable_firewall_for_keyvaults_and_storage    = var.enable_firewall_for_keyvaults_and_storage
  enable_purge_control_for_keyvaults           = var.enable_purge_control_for_keyvaults
  enable_rbac_authorization_for_keyvault       = var.enable_rbac_authorization_for_keyvault
  infrastructure                               = local.infrastructure
  install_always_create_fileshares             = var.install_always_create_fileshares
  install_create_smb_shares                    = var.install_create_smb_shares
  install_private_endpoint_id                  = var.install_private_endpoint_id
  install_storage_account_id                   = var.install_storage_account_id
  install_volume_size                          = var.install_volume_size
  key_vault                                    = local.key_vault
  keyvault_private_endpoint_id                 = var.keyvault_private_endpoint_id
  naming                                       = length(var.name_override_file) > 0 ? (
                                                   local.custom_names) : (
                                                   module.sap_namegenerator.naming
                                                 )
  NFS_provider                                 = var.NFS_provider
  options                                      = local.options
  peer_with_control_plane_vnet                 = var.use_deployer ? var.peer_with_control_plane_vnet : false
  place_delete_lock_on_resources               = var.place_delete_lock_on_resources
  public_network_access_enabled                = var.public_network_access_enabled
  soft_delete_retention_days                   = var.soft_delete_retention_days
  storage_account_replication_type             = var.storage_account_replication_type
  tags                                         = var.tags
  terraform_template_version                   = local.version_label
  transport_private_endpoint_id                = var.transport_private_endpoint_id
  transport_storage_account_id                 = var.transport_storage_account_id
  transport_volume_size                        = var.transport_volume_size
  use_AFS_for_shared_storage                   = var.use_AFS_for_shared_storage
  use_deployer                                 = length(var.deployer_tfstate_key) > 0
  use_private_endpoint                         = var.use_private_endpoint
  use_service_endpoint                         = var.use_service_endpoint
  vm_settings                                  = local.vm_settings
  witness_storage_account                      = local.witness_storage_account
  dns_settings                                 = local.dns_settings
  data_plane_available                         = var.data_plane_available
}

module "sap_namegenerator" {
  source                                       = "../../terraform-units/modules/sap_namegenerator"
  codename                                     = lower(try(var.codename, ""))
  environment                                  = var.environment
  iscsi_server_count                           = var.iscsi_count
  location                                     = lower(var.location)
  random_id                                    = var.custom_random_id
  sap_vnet_name                                = var.network_logical_name
  utility_vm_count                             = var.utility_vm_count
}

