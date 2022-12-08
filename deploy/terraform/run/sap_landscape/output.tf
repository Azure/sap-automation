
###############################################################################
#                                                                             #
#                             Resource Group                                  #
#                                                                             #
###############################################################################

output "created_resource_group_id" {
  description = "Created resource group ID"
  value       = module.sap_landscape.created_resource_group_id
}

output "created_resource_group_subscription_id" {
  description = "Created resource group' subscription ID"
  value       = module.sap_landscape.created_resource_group_subscription_id
}

output "created_resource_group_name" {
  description = "Created resource group name"
  value       = module.sap_landscape.created_resource_group_name
}

output "workload_zone_prefix" {
  description = "Workload zone prefix"
  value       = module.sap_namegenerator.naming.prefix.WORKLOAD_ZONE
}

###############################################################################
#                                                                             #
#                            Network                                          #
#                                                                             #
###############################################################################

output "vnet_sap_arm_id" {
  description = "Azure resource identifier for the Virtual Network"

  value       = length(var.network_arm_id) > 0 ? var.network_arm_id : module.sap_landscape.vnet_sap_id
}

output "route_table_id" {
  description = "Azure resource identifier for the route table"
  value       = module.sap_landscape.route_table_id
}

output "admin_subnet_id" {
  description = "Azure resource identifier for the admin subnet"
  value       = length(var.admin_subnet_arm_id) > 0 ? var.admin_subnet_arm_id : module.sap_landscape.admin_subnet_id
}

output "app_subnet_id" {
  description = "Azure resource identifier for the app subnet"
  value       = length(var.app_subnet_arm_id) > 0 ? var.app_subnet_arm_id : module.sap_landscape.app_subnet_id
}

output "db_subnet_id" {
  description = "Azure resource identifier for the db subnet"
  value       = length(var.db_subnet_arm_id) > 0 ? var.db_subnet_arm_id : module.sap_landscape.db_subnet_id
}

output "web_subnet_id" {
  description = "Azure resource identifier for the web subnet"
  value       = length(var.web_subnet_arm_id) > 0 ? var.web_subnet_arm_id : module.sap_landscape.web_subnet_id
}


output "admin_nsg_id" {
  description = "Azure resource identifier for the admin subnet network security group"
  value       = module.sap_landscape.admin_nsg_id
}

output "app_nsg_id" {
  description = "Azure resource identifier for the app subnet network security group"
  value       = module.sap_landscape.app_nsg_id
}

output "db_nsg_id" {
  description = "Azure resource identifier for the database subnet network security group"
  value       = module.sap_landscape.db_nsg_id
}

output "web_nsg_id" {
  description = "Azure resource identifier for the web subnet network security group"
  value       = module.sap_landscape.web_nsg_id
}

output "subnet_mgmt_id" {
  value = module.sap_landscape.subnet_mgmt_id
}


###############################################################################
#                                                                             #
#                            Key Vault                                        #
#                                                                             #
###############################################################################


output "landscape_key_vault_user_arm_id" {
  description = "Azure resource identifier for the user credential keyvault"
  value       = length(var.user_keyvault_id) > 0 ? var.user_keyvault_id : try(module.sap_landscape.kv_user, "")
}

output "spn_kv_id" {
  value = local.spn_key_vault_arm_id
}

output "workloadzone_kv_name" {
  description = "User credential keyvault name"
  value       = length(var.user_keyvault_id) > 0 ? split("/", var.user_keyvault_id)[8] : try(split("/", module.sap_landscape.kv_user)[8], "")
}

output "landscape_key_vault_private_arm_id" {
  description = "Not used at this time"
  value       = try(module.sap_landscape.kv_prvt, "")
}

output "landscape_key_vault_spn_arm_id" {
  description = "Azure resource identifier for the deployment credential keyvault"
  value       = local.spn_key_vault_arm_id
}

output "sid_public_key_secret_name" {
  value = try(module.sap_landscape.sid_public_key_secret_name, "")
}

output "sid_username_secret_name" {
  value = module.sap_landscape.sid_username_secret_name
}
output "sid_password_secret_name" {
  value = try(module.sap_landscape.sid_password_secret_name, "")
}

###############################################################################
#                                                                             #
#                            iSCSI                                            #
#                                                                             #
###############################################################################

output "iscsi_authentication_type" {
  value = try(module.sap_landscape.iscsi_authentication_type, "")
}

output "iscsi_authentication_username" {
  value = try(module.sap_landscape.iscsi_authentication_username, "")
}

output "iscsi_private_ip" {
  value = try(module.sap_landscape.nics_iscsi[*].private_ip_address, [])
}

###############################################################################
#                                                                             #
#                            DNS                                 #
#                                                                             #
###############################################################################
output "dns_info_iscsi" {
  description = "value"
  value = module.sap_landscape.dns_info_vms
}

output "use_custom_dns_a_registration" {
  description = "Defines if custom DNS is used"
  value = var.use_custom_dns_a_registration
}

output "management_dns_subscription_id" {
  description = "custom DNS subscription"
  value = var.management_dns_subscription_id
}


output "management_dns_resourcegroup_name" {
  description = "custom DNS resource group"
  value = var.management_dns_resourcegroup_name
}

output "dns_label" {
  description = "DNS label"
  value = var.dns_label
}


output "dns_resource_group_name" {
  description = "DNS resource group"
  value = length(var.dns_resource_group_name) > 0 ? var.dns_resource_group_name : local.saplib_resource_group_name
}


###############################################################################
#                                                                             #
#                            Storage accounts                                 #
#                                                                             #
###############################################################################

output "storageaccount_name" {
  description = "Diagnostics storage account name"
  value       = try(module.sap_landscape.storageaccount_name, "")
}

output "storageaccount_rg_name" {
  description = "Diagnostics storage account resource group name"
  value       = try(module.sap_landscape.storageaccount_rg_name, "")
}


output "transport_storage_account_id" {
  value = module.sap_landscape.transport_storage_account_id
}

output "automation_version" {
  value = local.version_label
}

//Witness
output "witness_storage_account" {

  value = module.sap_landscape.witness_storage_account
}

output "witness_storage_account_key" {
  sensitive = true
  value     = module.sap_landscape.witness_storage_account_key
}


###############################################################################
#                                                                             #
#                            ANF                                              #
#                                                                             #
###############################################################################

output "ANF_pool_settings" {
  value = module.sap_landscape.ANF_pool_settings
}

###############################################################################
#                                                                             #
#                            Mount info                                       #
#                                                                             #
###############################################################################

output "saptransport_path" {
  description = "Mount point for transport volume"
  value       = module.sap_landscape.saptransport_path
}

output "install_path" {
  description = "Mount point for install volume"
  value       = module.sap_landscape.install_path
}

