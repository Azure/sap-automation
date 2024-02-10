#######################################4#######################################8
#                                                                              #
#                          Resource group definitioms                          #
#                                                                              #
#######################################4#######################################8

output "created_resource_group_id"               {
                                                   description = "Created resource group ID"
                                                   value       = module.sap_deployer.created_resource_group_id
                                                 }

output "created_resource_group_name"             {
                                                   description = "Created resource group name"
                                                   value       = module.sap_deployer.created_resource_group_name
                                                 }

output "created_resource_group_subscription_id"  {
                                                   description = "Created resource group' subscription ID"
                                                   value       = module.sap_deployer.created_resource_group_subscription_id
                                                 }

output "environment"                             {
                                                   description = "Deployer environment name"
                                                   value       = var.environment
                                                 }


output "created_resource_group_location"         {
                                                   description = "Created resource group's location"
                                                   value       = module.sap_deployer.created_resource_group_location
                                                 }

###############################################################################
#                                                                             #
#                                 Deployer                                    #
#                                                                             #
###############################################################################

output "add_system_assigned_identity"            {
                                                   description = "Define if a system assigned identity should be added to the deployer"
                                                   value = var.add_system_assigned_identity
                                                 }

output "deployer_id"                             {
                                                   description = "Random ID for deployer"
                                                   sensitive = false
                                                   value     = module.sap_deployer.deployer_id
                                                 }

output "deployer_msi_id"                         {
                                                   description = "The ID of the deployer MSI"
                                                   value = module.sap_deployer.deployer_uai.principal_id
                                                 }

output "deployer_public_ip_address"              {
                                                   description = "Public IP address of the deployer"
                                                   value = module.sap_deployer.deployer_public_ip_address
                                                 }

output "deployer_system_assigned_identity"       {
                                                   description = "value of the system assigned identity for the deployer"
                                                   value = module.sap_deployer.deployer_system_assigned_identity
                                                 }

output "deployer_uai"                            {
                                                   description = "Information about the deployer user assigned identity"
                                                   value = {
                                                             principal_id = module.sap_deployer.deployer_uai.principal_id
                                                             tenant_id    = module.sap_deployer.deployer_uai.tenant_id
                                                           }
                                                 }

output "deployer_sshkey"                         {
                                                   description = "Name of the secreet containing the deployer ssh key"
                                                   value       = module.sap_deployer.ppk_secret_name
                                                 }

###############################################################################
#                                                                             #
#                                  Network                                    #
#                                                                             #
###############################################################################

output "vnet_mgmt_id"                            {
                                                   description = "The resource ID for the management VNet"
                                                   value       = module.sap_deployer.vnet_mgmt_id
                                                 }

output "subnet_mgmt_id"                          {
                                                   description = "The resource ID for the management subnet"
                                                   value       = module.sap_deployer.subnet_mgmt_id
                                                 }


output "subnet_mgmt_address_prefixes"            {
                                                   description = "The address prefices for the management subnet"
                                                   value       = module.sap_deployer.subnet_mgmt_address_prefixes
                                                 }

output "subnet_bastion_address_prefixes"         {
                                                   description = "The address prefices for the bastion subnet"
                                                   value       = module.sap_deployer.subnet_bastion_address_prefixes
                                                 }


output "subnet_webapp_id"                        {
                                                   description = "The resource ID for the WebApp subnet"
                                                   value       = module.sap_deployer.subnet_webapp_id
                                                 }

output "subnets_to_add_to_firewall_for_keyvaults_and_storage" {
                                                                description = "List of subnets to add to the firewall for keyvaults and storage"
                                                                value       = var.subnets_to_add_to_firewall_for_keyvaults_and_storage
                                                              }

###############################################################################
#                                                                             #
#                                 Key Vault                                   #
#                                                                             #
###############################################################################

output "deployer_kv_user_arm_id"                 {
                                                   description = "Azure resource identifier for the key vault containing the deployment credentials"
                                                   sensitive   = false
                                                   value       = module.sap_deployer.deployer_keyvault_user_arm_id
                                                 }

output "deployer_kv_user_name"                   {
                                                   description = "Name of the key vault containing the deployment credentials"
                                                   value       = module.sap_deployer.user_vault_name
                                                 }

output "set_secret_expiry"                       {
                                                   description = "Defines if key vault secrets should be set to expire"
                                                   value       = var.set_secret_expiry
                                                 }

output "deployer_sshkey_secret_name"             {
                                                   description = "Defines the name of the secret in the Azure Key Vault that contains the private key"
                                                   value       = module.sap_deployer.ppk_secret_name
                                                 }



###############################################################################
#                                                                             #
#                                 Firewall                                    #
#                                                                             #
###############################################################################


output "firewall_ip"                             {
                                                   description = "The IP address of the firewall"
                                                   value       = module.sap_deployer.firewall_ip
                                                 }

output "firewall_id"                             {
                                                   description = "The Azure resource ID of the firewall"
                                                   value       = module.sap_deployer.firewall_id
                                                 }

output "enable_firewall_for_keyvaults_and_storage" {
                                                     description = "Defines if the firewall should be enabled for keyvaults and storage"
                                                     value       = var.enable_firewall_for_keyvaults_and_storage
                                                   }

output "public_network_access_enabled"           {
                                                   description = "Defines if the public access should be enabled for keyvaults and storage"
                                                   value       = var.public_network_access_enabled
                                                 }


output "automation_version"                      {
                                                   description = "Defines the version of the automation templates used"
                                                   value       = local.version_label
                                                 }

###############################################################################
#                                                                             #
#                                App Service                                  #
#                                                                             #
###############################################################################


output "webapp_url_base"                         {
                                                   description = "The URL of the configuration Web Application"
                                                   value       = var.use_webapp ? module.sap_deployer.webapp_url_base : ""
                                                 }

output "webapp_identity"                         {
                                                   description = "The identity of the configuration Web Application"
                                                   value       = var.use_webapp ? module.sap_deployer.webapp_identity : ""
                                                 }

output "webapp_id"                               {
                                                   description = "The Azure resource ID of the configuration Web Application"
                                                   value = var.use_webapp ? module.sap_deployer.webapp_id : ""
                                                 }

###############################################################################
#                                                                             #
#                                VM Extension                                 #
#                                                                             #
###############################################################################

output "deployer_extension_ids"                  {
                                                   description = "List of extension IDs"
                                                   value = module.sap_deployer.extension_ids
                                                 }

###############################################################################
#                                                                             #
#                                    Random                                   #
#                                                                             #
###############################################################################

output "random_id_b64"                           {
                                                   description = "The random ID used for the naming of resources"
                                                   value = module.sap_deployer.random_id_b64
                                                 }

output "Agent_IP"                                {
                                                    description = "The IP address of the agent"
                                                    value = var.Agent_IP
                                                  }
