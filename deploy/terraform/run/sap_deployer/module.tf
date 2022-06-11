/*
Description:

  Example to deploy deployer(s) using local backend.
*/
module "sap_deployer" {
  source         = "../../terraform-units/modules/sap_deployer/"
  infrastructure = local.infrastructure
  deployer       = local.deployer
  options        = local.options
  ssh-timeout    = var.ssh-timeout
  authentication = local.authentication
  key_vault      = local.key_vault
  naming = length(var.name_override_file) > 0 ? (
    local.custom_names) : (
    module.sap_namegenerator.naming
  )
  firewall_deployment                = local.firewall_deployment
  assign_subscription_permissions    = local.assign_subscription_permissions
  bootstrap                          = false
  enable_purge_control_for_keyvaults = var.enable_purge_control_for_keyvaults
  arm_client_id                      = var.arm_client_id
  use_private_endpoint               = var.use_private_endpoint
  configure                          = true
  tf_version                         = var.tf_version
  bastion_deployment                 = var.bastion_deployment
  auto_configure_deployer            = var.auto_configure_deployer
  deployer_vm_count                  = var.deployer_count
  agent_pool                         = var.agent_pool
  agent_pat                          = var.agent_pat
  agent_ado_url                      = var.agent_ado_url

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

