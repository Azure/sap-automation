###############################################################################
#                                                                             #
#                             Resource Group                                  #
#                                                                             #
###############################################################################

output "created_resource_group_id" {
  description = "Created resource group ID"
  value       = module.sap_deployer.created_resource_group_id
}

output "created_resource_group_subscription_id" {
  description = "Created resource group' subscription ID"
  value       = module.sap_deployer.created_resource_group_subscription_id
}

output "created_resource_group_name" {
  description = "Created resource group name"
  value       = module.sap_deployer.created_resource_group_name
}

output "environment" {
  description = "Deployer environment name"
  value = var.environment
}

###############################################################################
#                                                                             #
#                                 Deployer                                    #
#                                                                             #
###############################################################################

output "deployer_id" {
  sensitive = true
  value     = module.sap_deployer.deployer_id
}

output "deployer_uai" {
  sensitive = true
  value = {
    principal_id = module.sap_deployer.deployer_uai.principal_id
    tenant_id    = module.sap_deployer.deployer_uai.tenant_id
  }
}


output "deployer_public_ip_address" {
  value = module.sap_deployer.deployer_public_ip_address
}

###############################################################################
#                                                                             #
#                                  Network                                    #
#                                                                             #
###############################################################################

output "vnet_mgmt_id" {
  value = module.sap_deployer.vnet_mgmt_id
}

output "subnet_mgmt_id" {
  value = module.sap_deployer.subnet_mgmt_id
}

output "subnet_webapp_id" {
  value = module.sap_deployer.subnet_webapp_id
}

###############################################################################
#                                                                             #
#                                 Key Vault                                   #
#                                                                             #
###############################################################################

output "deployer_kv_user_arm_id" {
  sensitive = true
  value     = module.sap_deployer.deployer_keyvault_user_arm_id
}

output "deployer_kv_user_name" {
  value = module.sap_deployer.user_vault_name
}


###############################################################################
#                                                                             #
#                                 Firewall                                    #
#                                                                             #
###############################################################################


output "firewall_ip" {
  value = module.sap_deployer.firewall_ip
}

output "firewall_id" {
  value = module.sap_deployer.firewall_id
}


output "enable_firewall_for_keyvaults_and_storage" {
  value = var.enable_firewall_for_keyvaults_and_storage
}

output "automation_version" {
  value = local.version_label
}

###############################################################################
#                                                                             #
#                                App Service                                  #
#                                                                             #
###############################################################################


output "webapp_url_base" {
  value = var.use_webapp ? module.sap_deployer.webapp_url_base : ""
}

output "webapp_identity" {
  value = var.use_webapp ? module.sap_deployer.webapp_identity : ""
}

output "webapp_id" {
  value = var.use_webapp ? module.sap_deployer.webapp_id : ""
}

###############################################################################
#                                                                             #
#                                VM Extension                                 #
#                                                                             #
###############################################################################

output "deployer_extension_ids" {
  value = module.sap_deployer.extension_ids
}

