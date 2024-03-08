/*
Description:

  Example to deploy deployer(s) using local backend.
*/
module "sap_deployer" {
  source                                        = "../../terraform-units/modules/sap_deployer"
  providers                                     = {
                                                     azurerm.dnsmanagement = azurerm.dnsmanagement
                                                     azurerm.main          = azurerm.main
                                                   }
  naming                                        = length(var.name_override_file) > 0 ? (
                                                     local.custom_names) : (
                                                     module.sap_namegenerator.naming
                                                   )
  additional_users_to_add_to_keyvault_policies  = var.additional_users_to_add_to_keyvault_policies
  agent_ado_url                                 = var.agent_ado_url
  Agent_IP                                      = var.add_Agent_IP ? var.Agent_IP : ""
  agent_pat                                     = var.agent_pat
  agent_pool                                    = var.agent_pool
  ansible_core_version                          = var.ansible_core_version
  app_registration_app_id                       = var.use_webapp ? var.app_registration_app_id : ""
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
  deployer_vm_count                             = var.deployer_count
  dns_zone_names                                = var.dns_zone_names
  enable_firewall_for_keyvaults_and_storage     = var.enable_firewall_for_keyvaults_and_storage
  enable_purge_control_for_keyvaults            = var.enable_purge_control_for_keyvaults
  firewall_deployment                           = local.firewall_deployment
  firewall_rule_subnets                         = local.firewall_rule_subnets
  firewall_allowed_ipaddresses                  = local.firewall_allowed_ipaddresses
  infrastructure                                = local.infrastructure
  key_vault                                     = local.key_vault
  management_dns_resourcegroup_name             = var.management_dns_resourcegroup_name
  management_dns_subscription_id                = var.management_dns_subscription_id
  options                                       = local.options
  place_delete_lock_on_resources                = var.place_delete_lock_on_resources
  public_network_access_enabled                 = var.public_network_access_enabled
  sa_connection_string                          = var.sa_connection_string
  set_secret_expiry                             = var.set_secret_expiry
  soft_delete_retention_days                    = var.soft_delete_retention_days
  spn_id                                        = var.spn_id
  ssh-timeout                                   = var.ssh-timeout
  subnets_to_add                                = var.subnets_to_add_to_firewall_for_keyvaults_and_storage
  tf_version                                    = var.tf_version
  use_custom_dns_a_registration                 = var.use_custom_dns_a_registration
  use_private_endpoint                          = var.use_private_endpoint
  use_service_endpoint                          = var.use_service_endpoint
  use_webapp                                    = var.use_webapp
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
  random_id                                            = module.sap_deployer.random_id
}
