# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.


#######################################4#######################################8
#                                                                              #
#                             Environment settings                             #
#                                                                              #
#######################################4#######################################8

output "region"                        {
                                         description = "Azure region"
                                         value       = local.infrastructure.region
                                       }

output "environment"                   {
                                         description = "Name of environment"
                                         value       = local.infrastructure.environment
                                       }


#######################################4#######################################8
#                                                                              #
#                             Automation version                               #
#                                                                              #
#######################################4#######################################8

output "automation_version"            {
                                         description = "Defines the version of the terraform templates used in the deloyment"
                                         value       = local.version_label
                                       }

output "random_id"                     {
                                         description = "Random ID for system"
                                         value       = substr(coalesce(var.custom_random_id, module.common_infrastructure.random_id), 0, 3)
                                       }

#######################################4#######################################8
#                                                                             #
#                             Resource Group                                  #
#                                                                             #
#######################################4#######################################8

output "created_resource_group_id"     {
                                         description = "Created resource group ID"
                                         value       = module.common_infrastructure.created_resource_group_id
                                       }

output "created_resource_group_name"   {
                                         description = "Created resource group name"
                                         value       = module.common_infrastructure.created_resource_group_name
                                       }

output "created_resource_group_subscription_id" {
                                                  description = "Created resource group' subscription ID"
                                                  value       = module.common_infrastructure.created_resource_group_subscription_id
                                                }

###############################################################################
#                                                                             #
#                                     DNS                                     #
#                                                                             #
###############################################################################


output "dns_information_anydb"         {
                                         description = "DNS information for the anydb servers"
                                         value       = module.anydb_node.dns_info_vms
                                       }

output "dns_information_loadbalancers_anydb" {
                                               description = "DNS information for the anydb loadbalancer  "
                                               value       = module.anydb_node.dns_info_loadbalancers
                                             }

output "dns_information_hanadb"        {
                                         description = "DNS information for the HANA servers"
                                         value       = module.hdb_node.dns_info_vms
                                       }

output "dns_information_loadbalancers_hanadb" {
                                                description = "DNS information for the HANA load balancer"
                                                value       = module.hdb_node.dns_info_loadbalancers
                                              }

output "dns_information_app"           {
                                         description = "DNS information for the app tier servers"
                                         value = module.app_tier.dns_info_vms
                                       }

output "dns_information_loadbalancers_app" {
                                             description = "DNS information for the application servers"
                                             value       = module.app_tier.dns_info_loadbalancers
                                           }

output "database_loadbalancer_ip"      {
                                         description = "DNS information for the database load balancer"
                                         value       = upper(try(local.database.platform, "HANA")) == "HANA" ? module.hdb_node.database_loadbalancer_ip : module.anydb_node.database_loadbalancer_ip
                                       }

output "scs_loadbalancer_ips"         {
                                         description = "SCS Loadbalancer IP"
                                         value       = [module.app_tier.scs_server_loadbalancer_ips]
                                       }

output "database_loadbalancer_id"      {
                                         description = "Database Loadbalancer Id"
                                         value       = upper(try(local.database.platform, "HANA")) == "HANA" ? module.hdb_node.database_loadbalancer_id : module.anydb_node.database_loadbalancer_id
                                       }

output "scs_loadbalancer_id"           {
                                         description = "SCS Loadbalancer Id"
                                         value       = module.app_tier.scs_server_loadbalancer_id
                                       }

output "use_custom_dns_a_registration" {
                                         description = "Use custom DNS registration"
                                         value       = try(data.terraform_remote_state.landscape.outputs.use_custom_dns_a_registration, true)
                                       }
output "management_dns_subscription_id" {
                                         description = "Subscription Id for DNS resource group"
                                         value       = try(data.terraform_remote_state.landscape.outputs.management_dns_subscription_id, null)
                                        }
output "management_dns_resourcegroup_name" {
                                             description = "Resource group name for DNS resource group"
                                             value       = try(data.terraform_remote_state.landscape.outputs.management_dns_resourcegroup_name, local.saplib_resource_group_name)
                                           }


###############################################################################
#                                                                             #
#                           Virtual Machine IDs                               #
#                                                                             #
###############################################################################

output "app_vm_ips"                    {
                                         description = "Application Virtual Machine IPs"
                                         value       = module.app_tier.application_server_ips
                                       }

output "app_vm_ids"                    {
                                         description = "Virtual Machine IDs for the application servers"
                                         value       = module.app_tier.app_vm_ids
                                       }

output "scs_vm_ids" {
                                         description = "Virtual Machine IDs for the Central Services servers"
                                         value       = module.app_tier.scs_vm_ids
                                       }

output "web_vm_ids" {
                                         description = "Virtual Machine IDs for the Web Dispatcher servers"
                                         value       = module.app_tier.webdispatcher_server_vm_ids
                                       }

output "hanadb_vm_ids" {
                                         description = "VM IDs for the HANA Servers"
                                         value = module.hdb_node.hanadb_vm_ids
}

output "database_server_vm_ids"        {
                                         description = "VM IDs for the AnyDB Servers"
                                         value = module.anydb_node.database_server_vm_ids
                                       }

output "db_vm_ips"                     {
                                         description = "Database Virtual Machine IPs"
                                         value = upper(try(local.database.platform, "HANA")) == "HANA" ? (
                                                   module.hdb_node.database_server_ips) : (
                                                   module.anydb_node.database_server_ips
                                                 ) #TODO Change to use Admin IP
                                       }

output "db_vm_secondary_ips"           {
                                         description = "Database Virtual Machine secondary IPs"
                                         value       = upper(try(local.database.platform, "HANA")) == "HANA" ? (
                                                         module.hdb_node.database_server_secondary_ips) : (
                                                         module.anydb_node.database_server_secondary_ips
                                                       )
                                       }

output "sid"                           {
                                         description = "SID of the system"
                                         value = local.application_tier.sid
                                       }

output "asg_ids"                       {
                                         description = "A list of Application Security Group IDs"
                                         value = coalesce([
                                           try(module.common_infrastructure.db_asg_id, ""),
                                           try(module.app_tier.app_asg_id, ""),
                                           try(module.app_tier.web_asg_id, ""),
                                         ])
}

###############################################################################
#                                                                             #
#                           Disks                                             #
#                                                                             #
###############################################################################


output "disks"                         {
                                         description = "Disks attached to the virtual machines"
                                         value       = compact(concat(module.hdb_node.database_disks, module.anydb_node.database_disks, module.app_tier.apptier_disks))
                                       }

output "sapmnt_path"                   {
                                         description = "Path to the sapmnt folder"
                                         value       = module.common_infrastructure.sapmnt_path
                                       }

output "hana_shared_afs_path"          {
                                         description = "Path to the hanashare folder"
                                         value       = module.hdb_node.hana_shared_afs_path
                                       }

output "configuration_settings"        {
                                         description = "Additional configuration settings"
                                         value       = var.configuration_settings
                                       }


###############################################################################
#                                                                             #
#                                     SPN                                     #
#                                                                             #
###############################################################################


output "app_id_used"                   {
                                         description = "The App ID used in the deployment"
                                         value       = local.spn.client_id
                                         sensitive   = true
                                       }

output "subscription_id_used"          {
                                         description = "The Subscription ID configured in the key vault"
                                         value       = local.spn.subscription_id
                                         sensitive   = true
                                       }
