
###############################################################################
#                                                                             #
#                            SAP Central Services                             #
#                                                                             #
###############################################################################

output "nics_scs" {
  value = azurerm_network_interface.scs
}

output "nics_scs_admin" {
  value = azurerm_network_interface.scs_admin
}

output "scs_server_ips" {
  value = try(azurerm_network_interface.scs[*].private_ip_addresses[0], [])
}

output "scs_server_secondary_ips" {
  value = var.use_secondary_ips ? try(azurerm_network_interface.scs[*].private_ip_addresses[1], []) : []
}

output "scs_admin_ip" {
  value = azurerm_network_interface.scs_admin[*].private_ip_address
}

output "scs_lb_ip" {
  value = local.enable_scs_lb_deployment ? (
    try(azurerm_lb.scs[0].frontend_ip_configuration[0].private_ip_address, "")
    ) : (
    ""
  )
}

output "scs_lb_id" {
  value = local.enable_scs_lb_deployment ? (
    try(azurerm_lb.scs[0].id, "")
    ) : (
    ""
  )
}

output "ers_lb_ip" {
  value = local.enable_scs_lb_deployment && var.application_tier.scs_high_availability ? (
    try(azurerm_lb.scs[0].frontend_ip_configuration[1].private_ip_address, "")
    ) : (
    ""
  )
}

output "cluster_lb_ip" {
  value = local.enable_scs_lb_deployment && (var.application_tier.scs_high_availability && upper(var.application_tier.scs_os.os_type) == "WINDOWS") ? (
    try(azurerm_lb.scs[0].frontend_ip_configuration[2].private_ip_address, "")) : (
    ""
  )
}

output "fileshare_lb_ip" {
  value = local.enable_scs_lb_deployment && (var.application_tier.scs_high_availability && upper(var.application_tier.scs_os.os_type) == "WINDOWS") ? (
    try(azurerm_lb.scs[0].frontend_ip_configuration[3].private_ip_address, "")) : (
    ""
  )
}

output "scs_loadbalancer_ips" {
  value = local.enable_scs_lb_deployment ? (
    try(azurerm_lb.scs[0].frontend_ip_configuration[*].private_ip_address, [""])
    ) : (
    [""]
  )
}

output "app_subnet_netmask" {
  value = local.enable_deployment ? (
    local.application_subnet_exists ? (
      split("/", data.azurerm_subnet.subnet_sap_app[0].address_prefixes[0])[1]) : (
      split("/", azurerm_subnet.subnet_sap_app[0].address_prefixes[0])[1]
    )) : (
    null
  )
}

output "scs_vm_ids" {
  description = "SCS virtual machine resource IDs"
  value = local.enable_deployment ? (
    concat(
      azurerm_windows_virtual_machine.scs[*].id,
      azurerm_linux_virtual_machine.scs[*].id
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

output "nics_app" {
  value = azurerm_network_interface.app
}

output "nics_app_admin" {
  value = azurerm_network_interface.app_admin
}

output "application_server_ips" {
  value = try(azurerm_network_interface.app[*].private_ip_addresses[0], [])
}

output "application_server_secondary_ips" {
  value = var.use_secondary_ips ? try(azurerm_network_interface.app[*].private_ip_addresses[1], []) : []
}

output "app_admin_ip" {
  value = azurerm_network_interface.app_admin[*].private_ip_address
}

output "app_vm_ids" {
  description = "Application tier virtual machine resource IDs"
  value = local.enable_deployment ? (
    concat(
      azurerm_windows_virtual_machine.app[*].id,
      azurerm_linux_virtual_machine.app[*].id
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


output "nics_web" {
  value = azurerm_network_interface.web
}

output "nics_web_admin" {
  value = azurerm_network_interface.web_admin
}

output "webdispatcher_server_ips" {
  value = try(azurerm_network_interface.web[*].private_ip_addresses[0], [])
}

output "webdispatcher_server_secondary_ips" {
  value = var.use_secondary_ips ? try(azurerm_network_interface.web[*].private_ip_addresses[1], []) : []
}

output "web_admin_ip" {
  value = azurerm_network_interface.web_admin[*].private_ip_address
}

output "web_lb_ip" {
  value = local.enable_web_lb_deployment ? (
    try(azurerm_lb.web[0].frontend_ip_configuration[0].private_ip_address, "")
    ) : (
    ""
  )
}

output "web_vm_ids" {
  description = "Web dispatcher virtual machine resource IDs"
  value = local.enable_deployment ? (
    concat(
      azurerm_windows_virtual_machine.web[*].id,
      azurerm_linux_virtual_machine.web[*].id
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

output "dns_info_vms" {
  description = "DNS information for the application tier"
  value = local.enable_deployment ? (
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

output "dns_info_loadbalancers" {
  description = "DNS information for the application tier load balancers"

  value = try(zipmap(
    [
      slice(local.load_balancer_IP_names, 0, try(length(azurerm_lb.scs[0].private_ip_addresses), 0)),
      slice(local.web_load_balancer_IP_names, 0, try(length(azurerm_lb.web[0].private_ip_addresses), 0))
    ],
    [
      azurerm_lb.scs[0].private_ip_addresses,
      azurerm_lb.web[0].private_ip_addresses
    ]
  ), null)


}


output "app_tier_os_types" {
  value = zipmap(["app", "scs", "web"], [var.application_tier.app_os.os_type, var.application_tier.scs_os.os_type, var.application_tier.web_os.os_type])
}


###############################################################################
#                                                                             #
#                            Generic (internal)                               #
#                                                                             #
###############################################################################

output "apptier_disks" {
  value = local.enable_deployment ? (
    compact(
      concat(local.app_disks_ansible, local.scs_disks_ansible, local.web_disks_ansible)
    )
    ) : (
    []
  )
}

output "scs_ha" {
  description = "Defines if high availability is used"
  value       = var.application_tier.scs_high_availability
}
