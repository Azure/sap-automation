# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

/*
Description:

  Example to deploy deployer(s) using local backend.
*/
module "sap_deployer" {
  source                                        = "../../terraform-units/modules/sap_deployer"
  providers                                     = {
                                                   azurerm.main                     = azurerm.main
                                                   azurerm.dnsmanagement            = azurerm.dnsmanagement
                                                   azurerm.privatelinkdnsmanagement = azurerm.privatelinkdnsmanagement
                                                   azapi.restapi                    = azapi.restapi
                                                   azuread.main                     = azuread
                                                   }
  naming                                        = length(var.name_override_file) > 0 ? (
                                                     local.custom_names) : (
                                                     module.sap_namegenerator.naming
                                                   )
  naming_new                                    = module.sap_namegenerator.naming_new


  Agent_IP                                      = var.add_Agent_IP ? var.Agent_IP : ""
  additional_network_id                         = var.additional_network_id
  additional_users_to_add_to_keyvault_policies  = var.additional_users_to_add_to_keyvault_policies
  app_config_service                            = local.app_config_service
  app_service                                   = local.app_service
  arm_client_id                                 = var.arm_client_id
  assign_subscription_permissions               = var.deployer_assign_subscription_permissions
  authentication                                = local.authentication
  auto_configure_deployer                       = var.auto_configure_deployer
  bastion_deployment                            = var.bastion_deployment
  bastion_sku                                   = var.bastion_sku
  bootstrap                                     = false
  configure                                     = true
  deployer                                      = local.deployer
  deployer_vm_count                             = var.dev_center_deployment ? 0 : var.deployer_count
  dns_settings                                  = local.dns_settings
  enable_firewall_for_keyvaults_and_storage     = var.enable_firewall_for_keyvaults_and_storage
  enable_purge_control_for_keyvaults            = var.enable_purge_control_for_keyvaults
  firewall                                      = local.firewall
  infrastructure                                = local.infrastructure
  key_vault                                     = local.key_vault
  network_logical_name                          = var.management_network_logical_name
  options                                       = local.options
  place_delete_lock_on_resources                = var.place_delete_lock_on_resources
  public_network_access_enabled                 = var.recover ? true : var.public_network_access_enabled
  sa_connection_string                          = var.sa_connection_string
  set_secret_expiry                             = var.set_secret_expiry
  soft_delete_retention_days                    = var.soft_delete_retention_days
  spn_id                                        = var.use_spn ? coalesce(var.spn_id, data.azurerm_key_vault_secret.client_id[0].value) : ""
  ssh-timeout                                   = var.ssh-timeout
  subnets_to_add                                = var.subnets_to_add_to_firewall_for_keyvaults_and_storage
  use_private_endpoint                          = var.use_private_endpoint
  use_service_endpoint                          = var.use_service_endpoint
  webapp_client_secret                          = var.webapp_client_secret
}

module "sap_namegenerator" {
  source                                               = "../../terraform-units/modules/sap_namegenerator"
  codename                                             = lower(local.infrastructure.codename)
  deployer_environment                                 = lower(local.infrastructure.environment)
  deployer_vm_count                                    = var.deployer_count
  environment                                          = lower(local.infrastructure.environment)
  location                                             = lower(local.infrastructure.region)
  management_vnet_name                                 = coalesce(
                                                          var.management_network_logical_name,
                                                          local.vnet_mgmt_name_part
                                                        )
  random_id                                            = coalesce(var.custom_random_id, module.sap_deployer.random_id)

}
