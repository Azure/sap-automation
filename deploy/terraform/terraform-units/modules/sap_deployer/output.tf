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
  description                          = "Created resource group ID"
  value                                = local.resource_group_exists ? (
                                           data.azurerm_resource_group.deployer[0].id) : (
                                           azurerm_resource_group.deployer[0].id
                                         )
}

output "created_resource_group_subscription_id" {
  description                          = "Created resource group' subscription ID"
  value                                = local.resource_group_exists ? (
                                           split("/", data.azurerm_resource_group.deployer[0].id))[2] : (
                                           split("/", azurerm_resource_group.deployer[0].id)[2]
                                         )
}

// Deployer resource group name
output "created_resource_group_name" {
  description                          = "Created resource group name"
  value                                = local.resource_group_exists ? (
                                           data.azurerm_resource_group.deployer[0].name) : (
                                           azurerm_resource_group.deployer[0].name
                                         )
}

output "created_resource_group_location" {
  description                          = "Created resource group's location"
  value                                = local.resource_group_exists ? (
                                           data.azurerm_resource_group.deployer[0].location) : (
                                           azurerm_resource_group.deployer[0].location
                                         )
}


###############################################################################
#                                                                             #
#                                 Deployer                                    #
#                                                                             #
###############################################################################

// Unique ID for deployer
output "deployer_id" {
  description                          = "Random ID for deployer"
    value                              = random_id.deployer
}

// Details of the user assigned identity for deployer(s)
output "deployer_uai" {
  description                          = "Deployer User Assigned Identity"
  value                                = length(var.deployer.user_assigned_identity_id) == 0 ? azurerm_user_assigned_identity.deployer[0] : data.azurerm_user_assigned_identity.deployer[0]
}

output "deployer_public_ip_address" {
  description                          = "Deployer Public IP Address"
  value                                = local.enable_deployer_public_ip ? azurerm_public_ip.deployer[0].ip_address : ""
}

output "deployer_private_ip_address" {
  description                          = "Deployer private IP Addresses"
  value                                = azurerm_network_interface.deployer[*].private_ip_address
}

output "deployer_system_assigned_identity" {
  description                          = "Deployer System Assigned Identity"
  value                                = azurerm_linux_virtual_machine.deployer[*].identity[0].principal_id
}


###############################################################################
#                                                                             #
#                                  Network                                    #
#                                                                             #
###############################################################################

// Details of management vnet that is deployed/imported
output "vnet_mgmt_id" {
  description                          = "Management VNet ID"
  value                                = local.vnet_mgmt_exists ? data.azurerm_virtual_network.vnet_mgmt[0].id : azurerm_virtual_network.vnet_mgmt[0].id
}

// Details of management subnet that is deployed/imported
output "subnet_mgmt_id" {
  description                          = "Management Subnet ID"
  value                                = local.management_subnet_exists ? data.azurerm_subnet.subnet_mgmt[0].id : azurerm_subnet.subnet_mgmt[0].id
}

// Details of management subnet that is deployed/imported
output "subnet_mgmt_address_prefixes" {
  description                          = "Management Subnet Address Prefixes"
  value                                = local.management_subnet_exists ? data.azurerm_subnet.subnet_mgmt[0].address_prefixes : azurerm_subnet.subnet_mgmt[0].address_prefixes
}

// Deatils of webapp subnet that is deployed/imported
output "subnet_webapp_id" {
  description                          = "Webapp Subnet ID"
  value                                = var.use_webapp ? (local.webapp_subnet_exists ? data.azurerm_subnet.webapp[0].id : azurerm_subnet.webapp[0].id) : ""
}

// Details of the management vnet NSG that is deployed/imported
output "nsg_mgmt" {
  description                          = "Management VNet NSG"
  value                                = local.management_subnet_nsg_exists ? data.azurerm_network_security_group.nsg_mgmt[0] : azurerm_network_security_group.nsg_mgmt[0]
}


output "random_id" {
  description                          = "Random ID for deployer"
  value                                = random_id.deployer.hex
}

output "random_id_b64" {
  description                          = "Random ID for deployer"
  value                                = random_id.deployer.b64_url
}


output "user_vault_name" {
  description                          = "Key Vault Name"
  value                                = var.key_vault.kv_exists ? data.azurerm_key_vault.kv_user[0].name : azurerm_key_vault.kv_user[0].name
}

###############################################################################
#                                                                             #
#                                 Key Vault                                   #
#                                                                             #
###############################################################################

// output the secret name of private key
output "ppk_secret_name" {
  description                          = "Private Key Secret Name"
  value                                = local.enable_key ? local.ppk_secret_name : ""
}

// output the secret name of public key
output "pk_secret_name" {
  description                          = "Public Key Secret Name"
  value                                = local.enable_key ? local.pk_secret_name : ""
}

output "username_secret_name" {
  description                          = "Username Secret Name"
  value = local.username
}

output "pwd_secret_name" {
  description                          = "Password Secret Name"
  value                                = local.enable_password ? local.pwd_secret_name : ""
}

// Comment out code with users.object_id for the time being.
/*
output "deployer_user" {
  value = local.deployer_users_id_list
}
*/

output "deployer_keyvault_user_arm_id" {
  description                          = "Azure resource ID of the deployer key vault"
  value                                = var.key_vault.kv_exists ? data.azurerm_key_vault.kv_user[0].id : azurerm_key_vault.kv_user[0].id
}


###############################################################################
#                                                                             #
#                                   Firewall                                  #
#                                                                             #
###############################################################################

output "firewall_ip" {
  description                          = "Firewall private IP address"
  value                                = var.firewall_deployment ? azurerm_firewall.firewall[0].ip_configuration[0].private_ip_address : ""
}

output "firewall_id" {
  description                          = "Firewall ID"
  value                                = var.firewall_deployment ? azurerm_firewall.firewall[0].id : ""
}


###############################################################################
#                                                                             #
#                                App Service                                  #
#                                                                             #
###############################################################################


output "webapp_url_base" {
  description                          = "Webapp URL Base"
  value                                = var.use_webapp ? (var.configure ? try(azurerm_windows_web_app.webapp[0].name, "") : "") : ""
}

output "webapp_identity" {
  description                          = "Webapp Identity"
  value                                = var.use_webapp ? (var.configure ? try(azurerm_windows_web_app.webapp[0].identity[0].principal_id, "") : "") : ""
}

output "webapp_id" {
  description                          = "Webapp ID"
  value                                = var.use_webapp ? (
                                           var.configure ? try(azurerm_windows_web_app.webapp[0].id, "") : "") : (
                                           ""
                                         )
}

###############################################################################
#                                                                             #
#                                VM Extension                                 #
#                                                                             #
###############################################################################

output "extension_ids" {
  description                          = "Virtual machine extension id"
  value                                = azurerm_virtual_machine_extension.configure[*].id
}

###############################################################################
#                                                                             #
#                                   Bastion                                   #
#                                                                             #
###############################################################################


output "subnet_bastion_address_prefixes" {
  description                          = "Bastion Subnet Address Prefixes"
  value                                = var.bastion_deployment ? (
                                          length(var.infrastructure.vnets.management.subnet_bastion.arm_id) == 0 ? (
                                            azurerm_subnet.bastion[0].address_prefixes) : (
                                            data.azurerm_subnet.bastion[0].address_prefixes
                                          )) : (
                                          [""]
                                        )
}


