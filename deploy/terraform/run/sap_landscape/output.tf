
#######################################4#######################################8
#                                                                              #
#                             Resource Group                                   #
#                                                                              #
#######################################4#######################################8

output "created_resource_group_id"              {
                                                  description = "Created resource group ID"
                                                  value       = module.sap_landscape.created_resource_group_id
                                                }

output "created_resource_group_subscription_id" {
                                                  description = "Created resource group' subscription ID"
                                                  value       = module.sap_landscape.created_resource_group_subscription_id
                                                }

output "created_resource_group_name"            {
                                                  description = "Created resource group name"
                                                  value       = module.sap_landscape.created_resource_group_name
                                                }

output "workload_zone_prefix"                   {
                                                  description = "Workload zone prefix"
                                                  value       = module.sap_namegenerator.naming.prefix.WORKLOAD_ZONE
                                                }

output "public_network_access_enabled"          {
                                                  description = "Defines if the public access should be enabled for keyvaults and storage"
                                                  value = var.public_network_access_enabled || !var.use_private_endpoint
                                                }

###############################################################################
#                                                                             #
#                            Network                                          #
#                                                                             #
###############################################################################

output "admin_subnet_id"                         {
                                                    description = "Azure resource identifier for the admin subnet"
                                                    value       = length(var.admin_subnet_arm_id) > 0 ? var.admin_subnet_arm_id : module.sap_landscape.admin_subnet_id
                                                 }

output "admin_nsg_id"                            {
                                                   description = "Azure resource identifier for the admin subnet network security group"
                                                   value       = module.sap_landscape.admin_nsg_id
                                                 }

output "app_subnet_id"                           {
                                                   description = "Azure resource identifier for the app subnet"
                                                   value       = length(var.app_subnet_arm_id) > 0 ? var.app_subnet_arm_id : module.sap_landscape.app_subnet_id
                                                 }

output "app_nsg_id"                              {
                                                   description = "Azure resource identifier for the app subnet network security group"
                                                   value       = module.sap_landscape.app_nsg_id
                                                 }

output "db_subnet_id"                            {
                                                   description = "Azure resource identifier for the db subnet"
                                                   value       = length(var.db_subnet_arm_id) > 0 ? var.db_subnet_arm_id : module.sap_landscape.db_subnet_id
                                                 }

output "db_nsg_id"                               {
                                                   description = "Azure resource identifier for the database subnet network security group"
                                                   value       = module.sap_landscape.db_nsg_id
                                                 }

output "ams_subnet_id"                           {
                                                   description = "Azure resource identifier for the AMS subnet"
                                                   value       = length(var.ams_subnet_arm_id) > 0 ? var.ams_subnet_arm_id : module.sap_landscape.ams_subnet_id
                                                 }

output "route_table_id"                          {
                                                   description = "Azure resource identifier for the route table"
                                                   value       = module.sap_landscape.route_table_id
                                                 }

output "subnet_mgmt_id"                          {
                                                   description = "Azure resource identifier for the management subnet"
                                                   value       = module.sap_landscape.subnet_mgmt_id
                                                 }

output "vnet_sap_arm_id"                         {
                                                   description = "Azure resource identifier for the Virtual Network"
                                                   value = length(var.network_arm_id) > 0 ? var.network_arm_id : module.sap_landscape.vnet_sap_id
                                                 }

output "web_subnet_id"                           {
                                                   description = "Azure resource identifier for the web subnet"
                                                   value       = length(var.web_subnet_arm_id) > 0 ? var.web_subnet_arm_id : module.sap_landscape.web_subnet_id
                                                 }

output "web_nsg_id"                              {
                                                   description = "Azure resource identifier for the web subnet network security group"
                                                   value       = module.sap_landscape.web_nsg_id
                                                 }

###############################################################################
#                                                                             #
#                            Key Vault                                        #
#                                                                             #
###############################################################################


output "landscape_key_vault_private_arm_id"      {
                                                   description = "Not used at this time"
                                                   value       = try(module.sap_landscape.kv_prvt, "")
                                                 }

output "landscape_key_vault_spn_arm_id"          {
                                                   description = "Azure resource identifier for the deployment credential keyvault"
                                                   value       = local.spn_key_vault_arm_id
                                                 }

output "landscape_key_vault_user_arm_id"         {
                                                   description = "Azure resource identifier for the user credential keyvault"
                                                   value       = length(var.user_keyvault_id) > 0 ? var.user_keyvault_id : module.sap_landscape.kv_user
                                                 }

output "sid_password_secret_name"                {
                                                   description = "Name of key vault secret containing the password for the infrastructure"
                                                   value       = try(module.sap_landscape.sid_password_secret_name, "")
                                                 }

output "sid_public_key_secret_name"              {
                                                   description = "Name of key vault secret containing the public ssh key for the infrastructure"
                                                   value       = try(module.sap_landscape.sid_public_key_secret_name, "")
                                                 }

output "sid_username_secret_name"                {
                                                   description = "Name of key vault secret containing the user name for logging on to the infrastructure"
                                                   value       = module.sap_landscape.sid_username_secret_name
                                                 }

output "spn_kv_id"                               {
                                                   description = "Name of key vault secret containing deployment credentials"
                                                   value       = local.spn_key_vault_arm_id
                                                 }

output "workloadzone_kv_name"                    {
                                                   description = "Workload zone keyvault name"
                                                   value       = length(var.user_keyvault_id) > 0 ? split("/", var.user_keyvault_id)[8] : try(split("/", module.sap_landscape.kv_user)[8], "")
                                                 }

###############################################################################
#                                                                             #
#                            iSCSI                                            #
#                                                                             #
###############################################################################

output "iscsi_authentication_username"           {
                                                   description = "User name for authentication to the iSCSI target"
                                                   value       = try(module.sap_landscape.iscsi_authentication_username, "")
                                                 }

output "iscsi_authentication_type"               {
                                                   description = "Authentication type for the iSCSI devices"
                                                   value       = try(module.sap_landscape.iscsi_authentication_type, "")
                                                 }

output "iscsi_private_ip"                        {
                                                   description = "IP addresses for the iSCSI devices"
                                                   value       = try(module.sap_landscape.nics_iscsi[*].private_ip_address, [])
                                                 }

###############################################################################
#                                                                             #
#                            DNS                                 #
#                                                                             #
###############################################################################
output "dns_info_iscsi"                          {
                                                   description = "DNS information for the iSCSI devices"
                                                   value       = module.sap_landscape.dns_info_vms
                                                 }

output "dns_label"                               {
                                                   description = "DNS suffix for the SAP Systems"
                                                   value       = var.dns_label
                                                 }

output "dns_resource_group_name"                 {
                                                   description = "Resource group name for the resource group containing the local Private DNS Zone"
                                                   value = local.saplib_resource_group_name
                                                 }

output "management_dns_resourcegroup_name"       {
                                                   description = "Resource group name for the resource group containing the public Private DNS Zone"
                                                   value       = coalesce(var.management_dns_resourcegroup_name, local.saplib_resource_group_name)
                                                 }

output "management_dns_subscription_id"          {
                                                   description = "Subscription ID for the public Private DNS Zone"
                                                   value       = var.management_dns_subscription_id
                                                 }

output "privatelink_file_id"                     {
                                                   description = "Azure resource identifier for the zone for the file resources"
                                                   value       = module.sap_landscape.privatelink_file_id
                                                 }

output "register_virtual_network_to_dns"         {
                                                   description = "Boolean flag to indicate if the SAP virtual network are registered to DNS"
                                                   value       = var.register_virtual_network_to_dns
                                                 }

output "use_custom_dns_a_registration"           {
                                                   description = "Defines if custom DNS is used"
                                                   value       = var.use_custom_dns_a_registration
                                                 }

###############################################################################
#                                                                             #
#                            Storage accounts                                 #
#                                                                             #
###############################################################################

output "storageaccount_name"                     {
                                                   description = "Diagnostics storage account name"
                                                   value       = try(module.sap_landscape.storageaccount_name, "")
                                                 }

output "storageaccount_rg_name"                  {
                                                   description = "Diagnostics storage account resource group name"
                                                   value       = module.sap_landscape.storageaccount_resourcegroup_name
                                                 }

output "transport_storage_account_id"            {
                                                   description = "Transport storage account resource group name"
                                                   value       = module.sap_landscape.transport_storage_account_id
                                                 }

//Witness
output "witness_storage_account"                 {
                                                   description = "Transport storage account resource group name"
                                                   value       = module.sap_landscape.witness_storage_account
                                                 }

output "witness_storage_account_key"             {
                                                   description = "Witness storage account account key"
                                                   sensitive   = true
                                                   value       = module.sap_landscape.witness_storage_account_key
                                                 }

###############################################################################
#                                                                             #
#                            ANF                                              #
#                                                                             #
###############################################################################

output "ANF_pool_settings"                       {
                                                   description = "Dictionary with information pertinent to the ANF deployment"
                                                   value       = module.sap_landscape.ANF_pool_settings
                                                 }

###############################################################################
#                                                                             #
#                            Mount info                                       #
#                                                                             #
###############################################################################

output "install_path"                            {
                                                   description = "Mount point for install volume"
                                                   value       = var.export_install_path ? module.sap_landscape.install_path : ""
                                                 }

output "saptransport_path"                       {
                                                   description = "Mount point for transport volume"
                                                   value       = var.export_transport_path && var.create_transport_storage ? module.sap_landscape.saptransport_path : ""
                                                 }

###############################################################################
#                                                                             #
#                            Control Plane                                    #
#                                                                             #
###############################################################################


output "automation_version"                      {
                                                   description = "Returns the version of the automation templated used to deploy the landscape"
                                                   value       = local.version_label
                                                 }

output "controlplane_environment"                {
                                                   description = "Control plane environment"
                                                   value       = try(data.terraform_remote_state.deployer[0].outputs.environment, "")
                                                 }

output "use_spn"                                 {
                                                   description = "Perform deployments using a service principal"
                                                   value       = var.use_spn
                                                 }

###############################################################################
#                                                                             #
#                                 iSCSI                                       #
#                                                                             #
###############################################################################

output "iSCSI_server_ips"                        {
                                                  description = "IP addesses for the iSCSI Servers"
                                                  value = var.iscsi_count > 0 ? (
                                                    module.sap_landscape.iSCSI_server_ips) : (
                                                    []
                                                  )
                                                }

output "iSCSI_server_names"                     {
                                                  value = var.iscsi_count > 0 ? (
                                                    length(var.name_override_file) > 0 ? local.custom_names.virtualmachine_names.ISCSI_COMPUTERNAME : module.sap_namegenerator.naming.virtualmachine_names.ISCSI_COMPUTERNAME
                                                    ) :    []
                                                }

output "iSCSI_servers"                          {
                                                  value = var.iscsi_count > 0 ? (
                                                    module.sap_landscape.iSCSI_servers) : (
                                                    []
                                                  )
                                                }

###############################################################################
#                                                                             #
#                                 AMS Resource                                #
#                                                                             #
###############################################################################
output ams_resource_id                          {
                                                  description = "AMS resource ID"
                                                  value = module.sap_landscape.ams_resource_id
                                                }