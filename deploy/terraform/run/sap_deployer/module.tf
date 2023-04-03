/*
Description:

  Example to deploy deployer(s) using local backend.
*/
module "sap_deployer" {
  source = "../../terraform-units/modules/sap_deployer/"
  providers = {
    azurerm.dnsmanagement = azurerm.dnsmanagement
    azurerm.main          = azurerm.main
  }
  infrastructure = local.infrastructure
  deployer       = local.deployer
  options        = local.options
  ssh-timeout    = var.ssh-timeout
  authentication = local.authentication

  naming = length(var.name_override_file) > 0 ? (
    local.custom_names) : (
    module.sap_namegenerator.naming
  )
  key_vault                                 = local.key_vault
  enable_firewall_for_keyvaults_and_storage = var.enable_firewall_for_keyvaults_and_storage

  firewall_deployment                = local.firewall_deployment
  assign_subscription_permissions    = var.deployer_assign_subscription_permissions
  bootstrap                          = false
  enable_purge_control_for_keyvaults = var.enable_purge_control_for_keyvaults
  arm_client_id                      = var.arm_client_id

  use_private_endpoint = var.use_private_endpoint
  use_service_endpoint = var.use_service_endpoint

  use_custom_dns_a_registration = var.use_custom_dns_a_registration || !(
    (var.management_dns_subscription_id != local.saplib_subscription_id) || (var.management_dns_resourcegroup_name != local.saplib_resource_group_name)
  )

  management_dns_subscription_id    = var.management_dns_subscription_id
  management_dns_resourcegroup_name = coalesce(var.management_dns_resourcegroup_name, local.saplib_resource_group_name)

  use_webapp              = var.use_webapp
  configure               = true
  tf_version              = var.tf_version
  app_registration_app_id = var.app_registration_app_id
  sa_connection_string    = var.sa_connection_string
  webapp_client_secret    = var.webapp_client_secret

  additional_users_to_add_to_keyvault_policies = var.additional_users_to_add_to_keyvault_policies

  bastion_deployment = var.bastion_deployment
  bastion_sku        = var.bastion_sku

  auto_configure_deployer = var.auto_configure_deployer
  deployer_vm_count       = var.deployer_count
  agent_pool              = var.agent_pool
  agent_pat               = var.agent_pat
  agent_ado_url           = var.agent_ado_url

  ansible_core_version = var.ansible_core_version

  spn_id = var.spn_id

}

module "sap_namegenerator" {
  source               = "../../terraform-units/modules/sap_namegenerator"
  environment          = lower(local.infrastructure.environment)
  deployer_environment = lower(local.infrastructure.environment)
  location             = lower(local.infrastructure.region)
  codename             = lower(local.infrastructure.codename)
  management_vnet_name = coalesce(
    var.management_network_logical_name,
    local.vnet_mgmt_name_part
  )
  random_id         = module.sap_deployer.random_id
  deployer_vm_count = var.deployer_count
}

