
###############################################################################
#                                                                             #
#                             Environment settings                            #
#                                                                             #
###############################################################################

output "region" {
  description = "Azure region"
  value = local.infrastructure.region
}

output "environment" {
  description = "Name of environment"
  value = local.infrastructure.environment
}


###############################################################################
#                                                                             #
#                             Automation version                              #
#                                                                             #
###############################################################################

output "automation_version" {
  description = "Defines the version of the terraform templates used in the deloyment"
  value = local.version_label
}

###############################################################################
#                                                                             #
#                             Resource Group                                  #
#                                                                             #
###############################################################################

output "created_resource_group_id" {
  description = "Created resource group ID"
  value       = module.common_infrastructure.created_resource_group_id
}

output "created_resource_group_name" {
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


output "dns_information_anydb" {
  description = "DNS information for the anydb servers"
  value       = module.anydb_node.dns_info_vms
}

output "dns_information_loadbalancers_anydb" {
  description = "DNS information for the anydb loadbalancer  "
  value       = module.anydb_node.dns_info_loadbalancers
}

output "dns_information_hanadb" {
  description = "DNS information for the HANA servers"
  value       = module.hdb_node.dns_info_vms
}

output "dns_information_loadbalancers_hanadb" {
  description = "DNS information for the HANA load balancer"
  value       = module.hdb_node.dns_info_loadbalancers
}

output "dns_information_app" {
  value = module.app_tier.dns_info_vms
}

output "dns_information_loadbalancers_app" {
  description = "DNS information for the application servers"
  value       = module.app_tier.dns_info_loadbalancers
}

output "database_loadbalancer_ip" {
  value = upper(try(local.database.platform, "HANA")) == "HANA" ? module.hdb_node.db_lb_ip : module.anydb_node.db_lb_ip
}

output "scs_loadbalancer_ips" {
  description = "SCS Loadbalancer IP"
  value       = tolist(module.app_tier.scs_loadbalancer_ips)
}

output "database_loadbalancer_id" {
  value = upper(try(local.database.platform, "HANA")) == "HANA" ? module.hdb_node.db_lb_id : module.anydb_node.db_lb_id
}

output "scs_loadbalancer_id" {
  description = "SCS Loadbalancer ID"
  value       = module.app_tier.scs_lb_id
}


###############################################################################
#                                                                             #
#                           Virtual Machine IDs                               #
#                                                                             #
###############################################################################


output "app_vm_ids" {
  description = "Virtual Machine IDs for the application servers"
  value       = module.app_tier.app_vm_ids
}

output "scs_vm_ids" {
  description = "Virtual Machine IDs for the Central Services servers"
  value       = module.app_tier.scs_vm_ids
}

output "web_vm_ids" {
  description = "Virtual Machine IDs for the Web Dispatcher servers"
  value       = module.app_tier.web_vm_ids
}

output "hanadb_vm_ids" {
  value = module.hdb_node.hanadb_vm_ids
}

output "anydb_vm_ids" {
  value = module.anydb_node.anydb_vm_ids
}

output "sid" {
  value = local.application_tier.sid
}


###############################################################################
#                                                                             #
#                           Virtual Machine IDs                               #
#                                                                             #
###############################################################################


output "disks" {
  description = "Disks attached to the virtual machines"
  value = compact(concat(module.hdb_node.dbtier_disks, module.anydb_node.dbtier_disks, module.app_tier.apptier_disks))

}

output "sapmnt_path" {
  description = "Path to the sapmnt folder"
  value = module.common_infrastructure.sapmnt_path
}

