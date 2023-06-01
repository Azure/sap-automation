/*
  Description:
  Setup sap library
*/
module "sap_library" {
  providers = {
    azurerm.main          = azurerm.main
    azurerm.deployer      = azurerm.deployer
    azurerm.dnsmanagement = azurerm.dnsmanagement
  }
  source                  = "../../terraform-units/modules/sap_library"
  infrastructure          = local.infrastructure
  storage_account_sapbits = local.storage_account_sapbits
  storage_account_tfstate = local.storage_account_tfstate
  software                = var.software
  deployer                = local.deployer
  key_vault               = local.key_vault
  service_principal       = var.use_deployer ? local.service_principal : local.account
  deployer_tfstate        = try(data.terraform_remote_state.deployer[0].outputs, [])
  naming                  = length(var.name_override_file) > 0 ? local.custom_names : module.sap_namegenerator.naming
  dns_label               = var.dns_label
  use_private_endpoint    = var.use_private_endpoint
  use_custom_dns_a_registration = var.use_custom_dns_a_registration || !(
    (var.management_dns_subscription_id != local.saplib_subscription_id) || (var.management_dns_resourcegroup_name != local.saplib_resource_group_name)
  )
  management_dns_subscription_id    = trimspace(var.management_dns_subscription_id)
  management_dns_resourcegroup_name = trimspace(var.management_dns_resourcegroup_name)
  use_webapp                        = var.use_webapp

  place_delete_lock_on_resources = var.place_delete_lock_on_resources


}

module "sap_namegenerator" {
  source               = "../../terraform-units/modules/sap_namegenerator"
  environment          = local.infrastructure.environment
  codename             = try(local.infrastructure.codename, "")
  location             = local.infrastructure.region
  deployer_environment = try(local.deployer.environment, local.infrastructure.environment)
  deployer_location    = try(local.deployer.region, local.infrastructure.region)
  management_vnet_name = ""
  random_id            = module.sap_library.random_id
}
