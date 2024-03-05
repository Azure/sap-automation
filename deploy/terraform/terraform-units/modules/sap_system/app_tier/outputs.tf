
#######################################4#######################################8
#                                                                              #
#                            SAP Central Services                              #
#                                                                              #
#######################################4#######################################8

output "scs_server_ips"                {
                                         description = "Central Services Server IPs"
                                         value       = try(azurerm_network_interface.scs[*].private_ip_addresses[0], [])
                                       }

output "scs_server_secondary_ips"      {
                                         description = "Central Services Server secondary IPs"
                                         value       = var.use_secondary_ips ? try(azurerm_network_interface.scs[*].private_ip_addresses[1], []) : []
                                       }

output "scs_server_admin_ips"          {
                                         description = "Central Services Server Admin IPs"
                                         value       = azurerm_network_interface.scs_admin[*].private_ip_address
                                       }

output "scs_server_loadbalancer_id"    {
                                         description = "Central Services Server Loadbalancer id"
                                         value       = local.enable_scs_lb_deployment ? (
                                                         try(azurerm_lb.scs[0].id, "")
                                                         ) : (
                                                         ""
                                                       )
                                       }

output "scs_server_loadbalancer_ips"   {
                                         description = "Central Services Server Load balancer All IPS"
                                         value       = local.enable_scs_lb_deployment ? (
                                                          try(azurerm_lb.scs[0].frontend_ip_configuration[*].private_ip_address, [""])
                                                          ) : (
                                                          [""]
                                                        )
                                       }
output "scs_server_loadbalancer_ip"    {
                                         description = "Central Services Server Load balancer IP"
                                         value       = local.enable_scs_lb_deployment ? (
                                                          try(azurerm_lb.scs[0].frontend_ip_configuration[0].private_ip_address, "")
                                                          ) : (
                                                          ""
                                                        )
                                       }
output "ers_server_loadbalancer_ip"    {
                                         description = "Central Services Server Load balancer IP"
                                         value       = local.enable_scs_lb_deployment && var.application_tier.scs_high_availability ? (
                                                         try(azurerm_lb.scs[0].frontend_ip_configuration[1].private_ip_address, "")
                                                         ) : (
                                                         ""
                                                       )
                                       }

output "cluster_loadbalancer_ip"       {
                                         description = "Central Services Server ClusterLoad balancer IP"
                                         value       = local.enable_scs_lb_deployment && (var.application_tier.scs_high_availability && upper(var.application_tier.scs_os.os_type) == "WINDOWS") ? (
                                                         try(azurerm_lb.scs[0].frontend_ip_configuration[2].private_ip_address, "")) : (
                                                         ""
                                                       )
                                       }

output "fileshare_loadbalancer_ip"     {
                                         description = "Central Services Server ClusterLoad File Share IP"
                                         value       = local.enable_scs_lb_deployment && (var.application_tier.scs_high_availability && upper(var.application_tier.scs_os.os_type) == "WINDOWS") ? (
                                                         try(azurerm_lb.scs[0].frontend_ip_configuration[3].private_ip_address, "")) : (
                                                         ""
                                                       )
                                       }

output "app_subnet_netmask"            {
                                         description = "Application subnet netmask"
                                         value       = local.enable_deployment ? (
                                                         local.application_subnet_exists ? (
                                                           split("/", data.azurerm_subnet.subnet_sap_app[0].address_prefixes[0])[1]) : (
                                                           split("/", azurerm_subnet.subnet_sap_app[0].address_prefixes[0])[1]
                                                         )) : (
                                                         null
                                                       )
                                       }

output "scs_vm_ids"                    {
                                         description = "SCS virtual machine resource IDs"
                                         value       = local.enable_deployment ? (
                                                         concat(
                                                           azurerm_windows_virtual_machine.scs[*].id,
                                                           azurerm_linux_virtual_machine.scs[*].id
                                                         )
                                                         ) : (
                                                         []
                                                       )
                                       }

output "scs_vm_names"                  {
                                         description = "SCS virtual machine names"
                                         value       = local.enable_deployment ? (
                                                         concat(
                                                           azurerm_windows_virtual_machine.scs[*].name,
                                                           azurerm_linux_virtual_machine.scs[*].name
                                                         )
                                                         ) : (
                                                         []
                                                       )
                                       }

###############################################################################
#                                                                             #
#                            Application Servers                              #
#                                                                             #
###############################################################################

output "application_server_ips"        {
                                         description = "Application Server IPs"
                                         value       = try(azurerm_network_interface.app[*].private_ip_addresses[0], [])
                                       }
output "application_server_secondary_ips" {
                                             description = "Application Server secondary IPs"
                                             value       = var.use_secondary_ips ? try(azurerm_network_interface.app[*].private_ip_addresses[1], []) : []
                                           }

output "app_admin_ip"                  {
                                         description = "Application Server admin IPs"
                                         value       = azurerm_network_interface.app_admin[*].private_ip_address
                                       }

output "app_vm_ids"                    {
                                         description = "Application tier virtual machine resource IDs"
                                         value       = local.enable_deployment ? (
                                                         concat(
                                                           azurerm_windows_virtual_machine.app[*].id,
                                                           azurerm_linux_virtual_machine.app[*].id
                                                         )
                                                         ) : (
                                                         []
                                                       )
                                       }

output "app_vm_names"                  {
                                         description = "Application virtual machine names"
                                         value       = local.enable_deployment ? (
                                                         concat(
                                                           azurerm_windows_virtual_machine.app[*].name,
                                                           azurerm_linux_virtual_machine.app[*].name
                                                         )
                                                         ) : (
                                                         []
                                                       )
                                       }


###############################################################################
#                                                                             #
#                            Web Dispatchers                                  #
#                                                                             #
###############################################################################

output "webdispatcher_server_ips"      {
                                         description = "Web dispatcher IPs"
                                         value       = try(azurerm_network_interface.web[*].private_ip_addresses[0], [])
                                       }

output "webdispatcher_server_secondary_ips" {
                                              description = "Web dispatcher secondary IPs"
                                              value       = var.use_secondary_ips ? try(azurerm_network_interface.web[*].private_ip_addresses[1], []) : []
                                            }

output "webdispatcher_loadbalancer_ip" {
                                         description = "Central Services Server Load balancer IP"
                                         value       = local.enable_web_lb_deployment ? (
                                                         try(azurerm_lb.web[0].frontend_ip_configuration[0].private_ip_address, "")
                                                         ) : (
                                                         ""
                                                       )
                                       }

output "webdispatcher_server_vm_ids"   {
                                         description = "Web dispatcher virtual machine resource IDs"
                                         value       = local.enable_deployment ? (
                                                         concat(
                                                           azurerm_windows_virtual_machine.web[*].id,
                                                           azurerm_linux_virtual_machine.web[*].id
                                                         )
                                                         ) : (
                                                         []
                                                       )
                                       }

output "webdispatcher_server_vm_names" {
                                         description = "Web dispatcher virtual machine resource names"
                                         value       = local.enable_deployment ? (
                                                         concat(
                                                           azurerm_windows_virtual_machine.web[*].name,
                                                           azurerm_linux_virtual_machine.web[*].name
                                                         )
                                                         ) : (
                                                         []
                                                       )
                                       }

###############################################################################
#                                                                             #
#                            DNS Information                                  #
#                                                                             #
###############################################################################

output "dns_info_vms"                  {
                                         description = "DNS information for the application tier"
                                         value       = local.enable_deployment ? (
                                                         var.application_tier.dual_nics ? (
                                                           zipmap(
                                                             compact(concat(
                                                               slice(local.full_appserver_names, 0, length(azurerm_linux_virtual_machine.app) + length(azurerm_windows_virtual_machine.app)),
                                                               slice(var.naming.virtualmachine_names.APP_SECONDARY_DNSNAME, 0, length(azurerm_linux_virtual_machine.app) + length(azurerm_windows_virtual_machine.app)),
                                                               slice(local.full_scsserver_names, 0, length(azurerm_linux_virtual_machine.scs) + length(azurerm_windows_virtual_machine.scs)),
                                                               slice(var.naming.virtualmachine_names.SCS_SECONDARY_DNSNAME, 0, length(azurerm_linux_virtual_machine.scs) + length(azurerm_windows_virtual_machine.scs)),
                                                               slice(local.full_webserver_names, 0, length(azurerm_linux_virtual_machine.web) + length(azurerm_windows_virtual_machine.web)),
                                                               slice(var.naming.virtualmachine_names.WEB_SECONDARY_DNSNAME, 0, length(azurerm_linux_virtual_machine.web) + length(azurerm_windows_virtual_machine.web)),
                                                             )),
                                                             compact(concat(
                                                               slice(azurerm_network_interface.app_admin[*].private_ip_address, 0, length(azurerm_linux_virtual_machine.app) + length(azurerm_windows_virtual_machine.app)),
                                                               slice(azurerm_network_interface.app[*].private_ip_address, 0, length(azurerm_linux_virtual_machine.app) + length(azurerm_windows_virtual_machine.app)),
                                                               slice(azurerm_network_interface.scs_admin[*].private_ip_address, 0, length(azurerm_linux_virtual_machine.scs) + length(azurerm_windows_virtual_machine.scs)),
                                                               slice(azurerm_network_interface.scs[*].private_ip_address, 0, length(azurerm_linux_virtual_machine.scs) + length(azurerm_windows_virtual_machine.scs)),
                                                               slice(azurerm_network_interface.web_admin[*].private_ip_address, 0, length(azurerm_linux_virtual_machine.web) + length(azurerm_windows_virtual_machine.web)),
                                                               slice(azurerm_network_interface.web[*].private_ip_address, 0, length(azurerm_linux_virtual_machine.web) + length(azurerm_windows_virtual_machine.web))
                                                           )))) : (
                                                           zipmap(
                                                             compact(concat(
                                                               slice(local.full_appserver_names, 0, length(azurerm_linux_virtual_machine.app) + length(azurerm_windows_virtual_machine.app)),
                                                               slice(local.full_scsserver_names, 0, length(azurerm_linux_virtual_machine.scs) + length(azurerm_windows_virtual_machine.scs)),
                                                               slice(local.full_webserver_names, 0, length(azurerm_linux_virtual_machine.web) + length(azurerm_windows_virtual_machine.web)),
                                                             )),
                                                             compact(concat(
                                                               slice(azurerm_network_interface.app[*].private_ip_address, 0, length(azurerm_linux_virtual_machine.app) + length(azurerm_windows_virtual_machine.app)),
                                                               slice(azurerm_network_interface.scs[*].private_ip_address, 0, length(azurerm_linux_virtual_machine.scs) + length(azurerm_windows_virtual_machine.scs)),
                                                               slice(azurerm_network_interface.web[*].private_ip_address, 0, length(azurerm_linux_virtual_machine.web) + length(azurerm_windows_virtual_machine.web))
                                                         ))))
                                                         ) : (
                                                         null
                                                       )
                                       }

output "dns_info_loadbalancers"        {
                                         description = "DNS information for the application tier load balancers"
                                         value       = try(
                                                         zipmap(
                                                           concat(
                                                             slice(local.load_balancer_IP_names, 0, try(length(azurerm_lb.scs[0].private_ip_addresses), 0)),
                                                             slice(local.web_load_balancer_IP_names, 0, try(length(azurerm_lb.web[0].private_ip_addresses), 0))
                                                           ),
                                                           concat(
                                                             try(azurerm_lb.scs[0].private_ip_addresses, []),
                                                             try(azurerm_lb.web[0].private_ip_addresses, [])
                                                           )
                                                         ),
                                                         null
                                                       )
                                       }


output "app_tier_os_types"            {
                                         description = "List of operating systems used in the application tier"
                                         value       = zipmap(["app", "scs", "web"], [var.application_tier.app_os.os_type, var.application_tier.scs_os.os_type, var.application_tier.web_os.os_type])
                                       }


###############################################################################
#                                                                             #
#                            Generic (internal)                               #
#                                                                             #
###############################################################################

output "apptier_disks"                 {
                                         description = "List of disks used in the application tier"
                                         value       = local.enable_deployment ? (
                                                         compact(
                                                           concat(local.app_disks_ansible, local.scs_disks_ansible, local.web_disks_ansible)
                                                         )
                                                         ) : (
                                                         []
                                                       )
                                       }

output "scs_high_availability"         {
                                         description = "Defines if high availability is used"
                                         value       = var.application_tier.scs_high_availability
                                       }

output "iscsiservers"                  {
                                         description = "Defines if high availability is used"
                                         value       = var.application_tier.scs_cluster_type == "ISCSI" ? [for vm in ["ascs1", "ascs2", "ascs3"] :
                                                          format("{ iscsi_host: '%s', iqn: '%s', type: 'scs' }", vm, format("iqn.2006-04.ascs%s.local:ascs%s", var.sap_sid, var.sap_sid))
                                                        ] : []
                                       }

output "scs_asd"                       {
                                         description = "List of Azure shared disks"
                                         value       = distinct(
                                                         flatten(
                                                           [for vm in var.naming.virtualmachine_names.SCS_COMPUTERNAME :
                                                             [for idx, disk in azurerm_virtual_machine_data_disk_attachment.cluster :
                                                               format("{ host: '%s', LUN: %d, type: 'ASD' }", vm, disk.lun)
                                                             ]
                                                           ]
                                                         )
                                                       )
                                       }
output "scs_kdump_disks"               {
                                         description = "List of kdump disks"
                                         value       = distinct(
                                                         flatten(
                                                           [for vm in var.naming.virtualmachine_names.SCS_COMPUTERNAME :
                                                             [for idx, disk in azurerm_virtual_machine_data_disk_attachment.kdump :
                                                               format("{ host: '%s', LUN: %d, type: 'kdump' }", vm, disk.lun)
                                                             ]
                                                           ]
                                                         )
                                                       )
                                       }
