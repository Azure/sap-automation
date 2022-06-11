/*
Description:

  Output from sap_deployer module.
*/

###############################################################################
#                                                                             # 
#                             Resource Group                                  # 
#                                                                             # 
###############################################################################

output "created_resource_group_id" {
  description = "Created resource group ID"
  value = local.resource_group_exists ? data.azurerm_resource_group.deployer[0].id : azurerm_resource_group.deployer[0].id
}

output "created_resource_group_subscription_id" {
  description = "Created resource group' subscription ID"
  value = local.resource_group_exists ? (
    split("/",data.azurerm_resource_group.deployer[0].id))[2] : (
    split("/",azurerm_resource_group.deployer[0].id)[2]
  )
}

// Deployer resource group name
output "deployer_rg_name" {
  value = local.resource_group_exists ? data.azurerm_resource_group.deployer[0].name : azurerm_resource_group.deployer[0].name
}

// Unique ID for deployer
output "deployer_id" {
  value = random_id.deployer
}

// Details of management vnet that is deployed/imported
output "vnet_mgmt_id" {
  value = local.vnet_mgmt_exists ? data.azurerm_virtual_network.vnet_mgmt[0].id : azurerm_virtual_network.vnet_mgmt[0].id
}

// Details of management subnet that is deployed/imported
output "subnet_mgmt_id" {
  value = local.management_subnet_exists ? data.azurerm_subnet.subnet_mgmt[0].id : azurerm_subnet.subnet_mgmt[0].id
}

// Details of the management vnet NSG that is deployed/imported
output "nsg_mgmt" {
  value = local.management_subnet_nsg_exists ? data.azurerm_network_security_group.nsg_mgmt[0] : azurerm_network_security_group.nsg_mgmt[0]
}

// Details of the user assigned identity for deployer(s)
output "deployer_uai" {
  value = azurerm_user_assigned_identity.deployer
}

// Details of deployer pip(s)
output "deployer_pip" {
  value = azurerm_public_ip.deployer
}

output "random_id" {
  value = random_id.deployer.hex
}

output "user_vault_name" {
  value = local.user_keyvault_exist ? data.azurerm_key_vault.kv_user[0].name : azurerm_key_vault.kv_user[0].name
}

# TODO Add this back when we separate the usage
# output "prvt_vault_name" {
#   value = local.automation_keyvault_exist ? data.azurerm_key_vault.kv_prvt[0].name : azurerm_key_vault.kv_prvt[0].name
# }

// output the secret name of private key
output "ppk_secret_name" {
  value = local.enable_key ? local.ppk_secret_name : ""
}

// output the secret name of public key
output "pk_secret_name" {
  value = local.enable_key ? local.pk_secret_name : ""
}

output "username_secret_name" {
  value = local.username
}

output "pwd_secret_name" {
  value = local.enable_password ? local.pwd_secret_name : ""
}

// Comment out code with users.object_id for the time being.
/*
output "deployer_user" {
  value = local.deployer_users_id_list
}
*/

output "deployer_keyvault_user_arm_id" {
  value = local.user_keyvault_exist ? data.azurerm_key_vault.kv_user[0].id : azurerm_key_vault.kv_user[0].id
}

output "deployer_public_ip_address" {
  value = local.enable_deployer_public_ip ? azurerm_public_ip.deployer[0].ip_address : ""
}

output "deployer_private_ip_address" {
  value = azurerm_network_interface.deployer[*].private_ip_address
}

output "firewall_ip" {
  value = var.firewall_deployment ? azurerm_firewall.firewall[0].ip_configuration[0].private_ip_address : ""
}

output "firewall_id" {
  value = var.firewall_deployment ? azurerm_firewall.firewall[0].id : ""
}
