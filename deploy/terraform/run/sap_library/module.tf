/*
  Description:
  Setup sap library
*/
module "sap_library" {
  source                            = "../../terraform-units/modules/sap_library"
  providers                         = {
                                       azurerm.main          = azurerm.main
                                       azurerm.deployer      = azurerm.deployer
                                       azurerm.dnsmanagement = azurerm.dnsmanagement
                                     }
  Agent_IP                          = var.add_Agent_IP ? var.Agent_IP : ""
  bootstrap                         = true
  deployer                          = local.deployer
  deployer_tfstate                  = try(data.terraform_remote_state.deployer[0].outputs, [])
  dns_label                         = var.dns_label
  dns_zone_names                    = var.dns_zone_names
  infrastructure                    = local.infrastructure
  key_vault                         = local.key_vault
  management_dns_resourcegroup_name = var.management_dns_resourcegroup_name
  management_dns_subscription_id    = var.management_dns_subscription_id
  naming                            = length(var.name_override_file) > 0 ? local.custom_names : module.sap_namegenerator.naming
  place_delete_lock_on_resources    = var.place_delete_lock_on_resources
  service_principal                 = var.use_deployer ? local.service_principal : local.account
  short_named_endpoints_nics        = var.short_named_endpoints_nics
  storage_account_sapbits           = local.storage_account_sapbits
  storage_account_tfstate           = local.storage_account_tfstate
  use_custom_dns_a_registration     = var.use_custom_dns_a_registration
  use_private_endpoint              = var.use_private_endpoint
  use_webapp                        = var.use_webapp || length(try(data.terraform_remote_state.deployer[0].outputs.webapp_id,"")) > 0
}

module "sap_namegenerator" {
  source                            = "../../terraform-units/modules/sap_namegenerator"
  codename                          = try(local.infrastructure.codename, "")
  deployer_environment              = try(local.deployer.environment, local.infrastructure.environment)
  deployer_location                 = try(local.deployer.region, local.infrastructure.region)
  environment                       = local.infrastructure.environment
  location                          = local.infrastructure.region
  management_vnet_name              = ""
  random_id                         = module.sap_library.random_id
}
