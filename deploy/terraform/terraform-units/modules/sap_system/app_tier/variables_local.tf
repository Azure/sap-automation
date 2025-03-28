# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

#######################################4#######################################8
#                                                                              #
#                            Local variables                                   #
#                                                                              #
#######################################4#######################################8

locals {
  // Imports Disk sizing sizing information

  default_filepath                     = format("%s%s", path.module, "/../../../../../configs/app_sizes.json")
  custom_sizing                        = length(var.custom_disk_sizes_filename) > 0

  // Imports application tier sizing information
  file_name                            = local.custom_sizing ? (
                                           fileexists(var.custom_disk_sizes_filename) ? (
                                             var.custom_disk_sizes_filename) : (
                                             format("%s/%s", path.cwd, var.custom_disk_sizes_filename)
                                           )) : (
                                           local.default_filepath
                                         )

  sizes                                = jsondecode(file(local.file_name))

  faults                               = jsondecode(file(format("%s%s", path.module, "/../../../../../configs/max_fault_domain_count.json")))
  resource_suffixes                    = var.naming.resource_suffixes

  //Allowing changing the base for indexing, default is zero-based indexing, if customers want the first disk to start with 1 they would change this
  offset                               = var.options.resource_offset

  faultdomain_count                    = try(tonumber(compact(
                                           [for pair in local.faults :
                                             upper(pair.Location) == upper(var.infrastructure.region) ? pair.MaximumFaultDomainCount : ""
                                         ])[0]), 2)

  sid                                  = upper(var.application_tier.sid)
  prefix                               = trimspace(var.naming.prefix.SDU)
  // Resource group
  resource_group_exists                = length(try(var.infrastructure.resource_group.arm_id, "")) > 0

  sid_auth_type                        = upper(var.application_tier.app_os.os_type) == "LINUX" ? (
                                           try(var.application_tier.authentication.type, "key")) : (
                                           "password"
                                         )
  enable_auth_password                 = local.enable_deployment && local.sid_auth_type == "password"
  enable_auth_key                      = local.enable_deployment && local.sid_auth_type == "key"

  authentication                       = {
                                           "type"     = local.sid_auth_type
                                           "username" = var.sid_username
                                           "password" = var.sid_password
                                         }

  ##############################################################################################
  #
  #  App subnet - Check if locally provided or if defined in workload zone state file
  #
  ##############################################################################################

  application_subnet_prefix            = var.infrastructure.virtual_networks.sap.subnet_app.prefix

  application_subnet_arm_id            = var.infrastructure.virtual_networks.sap.subnet_app.arm_id
  application_subnet_exists            = length(var.infrastructure.virtual_networks.sap.subnet_app.arm_id) > 0

  application_subnet_name              = var.infrastructure.virtual_networks.sap.subnet_app.defined ? coalesce(
                                            var.infrastructure.virtual_networks.sap.subnet_app.name,
                                            format("%s%s%s%s",
                                              var.naming.resource_prefixes.app_subnet,
                                              length(local.prefix) > 0 ? (
                                                local.prefix) : (
                                                var.infrastructure.environment
                                              ),
                                              var.naming.separator,
                                              local.resource_suffixes.app_subnet
                                            )
                                         ) : ""

  ##############################################################################################
  #
  #  Application subnet NSG - Check if locally provided or if defined in workload zone state file
  #
  ##############################################################################################

  application_subnet_nsg_defined       = length(try(var.infrastructure.virtual_networks.sap.subnet_app.nsg, {})) > 0

  application_subnet_nsg_arm_id        = local.application_subnet_nsg_defined ? (
                                           try(var.infrastructure.virtual_networks.sap.subnet_app.nsg.arm_id, "")) : (
                                           var.landscape_tfstate.app_nsg_id
                                         )

  application_subnet_nsg_exists        = length(local.application_subnet_nsg_arm_id) > 0
  application_subnet_nsg_name          = local.application_subnet_nsg_defined ? (
                                           local.application_subnet_nsg_exists ? (
                                             split("/", var.infrastructure.virtual_networks.sap.subnet_app.nsg.arm_id)[8]) : (
                                             length(var.infrastructure.virtual_networks.sap.subnet_app.nsg.name) > 0 ? (
                                               var.infrastructure.virtual_networks.sap.subnet_app.nsg.name) : (
                                               format("%s%s%s%s",
                                                 var.naming.resource_prefixes.app_subnet_nsg,
                                                 length(local.prefix) > 0 ? (
                                                   local.prefix) : (
                                                   var.infrastructure.environment
                                                 ),
                                                 var.naming.separator,
                                                 local.resource_suffixes.app_subnet_nsg
                                               )
                                           ))) : (
                                           ""
                                         )

  ##############################################################################################
  #
  #  Web subnet - Check if locally provided or if defined in workload zone state file
  #
  ##############################################################################################

  web_subnet_prefix                    = var.infrastructure.virtual_networks.sap.subnet_web.prefix

  web_subnet_arm_id                    = var.infrastructure.virtual_networks.sap.subnet_web.arm_id
  web_subnet_exists                    = length(local.web_subnet_arm_id) > 0

  web_subnet_name                      = var.infrastructure.virtual_networks.sap.subnet_web.defined ? coalesce(
                                           var.infrastructure.virtual_networks.sap.subnet_web.name,
                                           format("%s%s%s%s",
                                             var.naming.resource_prefixes.web_subnet,
                                             length(local.prefix) > 0 ? (
                                               local.prefix) : (
                                               var.infrastructure.environment
                                             ),
                                             var.naming.separator,
                                             local.resource_suffixes.web_subnet
                                           )
                                         ) : ""

  web_subnet_deployed_id               = local.enable_deployment ? ( local.web_subnet_exists ? (
                                             data.azurerm_subnet.subnet_sap_web[0].id) : (
                                             azurerm_subnet.subnet_sap_web[0].id
                                         )) : (
                                            ""
                                         )

  ##############################################################################################
  #
  #  Web subnet NSG - Check if locally provided or if defined in workload zone state file
  #
  ##############################################################################################

  web_subnet_nsg_defined               = length(try(var.infrastructure.virtual_networks.sap.subnet_web.nsg, {})) > 0
  web_subnet_nsg_arm_id                = local.web_subnet_nsg_defined ? (
                                           coalesce(var.infrastructure.virtual_networks.sap.subnet_web.nsg.arm_id, var.landscape_tfstate.web_nsg_id, "")) : (
                                           ""
                                         )

  web_subnet_nsg_exists                = length(local.web_subnet_nsg_arm_id) > 0
  web_subnet_nsg_name                  = local.web_subnet_nsg_defined ? (
                                           local.web_subnet_nsg_exists ? (
                                             split("/", var.infrastructure.virtual_networks.sap.subnet_web.nsg.arm_id)[8]) : (
                                             length(var.infrastructure.virtual_networks.sap.subnet_web.nsg.name) > 0 ? (
                                               var.infrastructure.virtual_networks.sap.subnet_web.nsg.name) : (
                                               format("%s%s%s%s",
                                                 var.naming.resource_prefixes.web_subnet_nsg,
                                                 length(local.prefix) > 0 ? (
                                                   local.prefix) : (
                                                   var.infrastructure.environment
                                                 ),
                                                 var.naming.separator,
                                                 local.resource_suffixes.web_subnet_nsg
                                               )
                                           ))) : (
                                           ""
                                         )

  web_subnet_nsg_deployed              = try(var.infrastructure.virtual_networks.sap.subnet_web.defined ? (
                                           local.web_subnet_nsg_exists ? (
                                             data.azurerm_network_security_group.nsg_web[0]) : (
                                             azurerm_network_security_group.nsg_web[0]
                                           )) : (
                                           local.application_subnet_nsg_exists ? (
                                             data.azurerm_network_security_group.nsg_app[0]) : (
                                             azurerm_network_security_group.nsg_app[0]
                                           )), null
                                         )
#--------------------------------------+---------------------------------------8
  scs_server_count                     = var.application_tier.scs_server_count * (var.application_tier.scs_high_availability ? 2 : 1)
  firewall_exists                      = length(var.firewall_id) > 0
  enable_deployment                    = var.application_tier.enable_deployment
  scs_instance_number                  = var.application_tier.scs_instance_number
  ers_instance_number                  = var.application_tier.ers_instance_number
  application_server_count             = var.application_tier.application_server_count
  enable_scs_lb_deployment             = local.enable_deployment ? (
                                           (
                                             local.scs_server_count > 0 &&
                                             (var.use_loadbalancers_for_standalone_deployments || local.scs_server_count > 1)
                                           )) : (
                                           false
                                         )

  webdispatcher_count                  = var.application_tier.webdispatcher_count
  enable_web_lb_deployment             = (
                                           local.webdispatcher_count > 0 &&
                                           (var.use_loadbalancers_for_standalone_deployments || local.webdispatcher_count > 1)
                                         )

  app_nic_ips                          = try(var.application_tier.app_nic_ips, [])
  app_nic_secondary_ips                = try(var.application_tier.app_nic_secondary_ips, [])
  app_admin_nic_ips                    = try(var.application_tier.app_admin_nic_ips, [])

  scs_server_loadbalancer_ips          = try(var.application_tier.scs_server_loadbalancer_ips, [])
  scs_nic_ips                          = try(var.application_tier.scs_nic_ips, [])
  scs_nic_secondary_ips                = try(var.application_tier.scs_nic_secondary_ips, [])
  scs_admin_nic_ips                    = try(var.application_tier.scs_admin_nic_ips, [])

  webdispatcher_loadbalancer_ips       = try(var.application_tier.webdispatcher_loadbalancer_ips, [])
  web_nic_ips                          = try(var.application_tier.web_nic_ips, [])
  web_nic_secondary_ips                = try(var.application_tier.web_nic_secondary_ips, [])
  web_admin_nic_ips                    = try(var.application_tier.web_admin_nic_ips, [])

  app_size                             = var.application_tier.app_sku
  scs_size                             = length(var.application_tier.scs_sku) > 0 ? var.application_tier.scs_sku : local.app_size
  web_size                             = length(var.application_tier.web_sku) > 0 ? var.application_tier.web_sku : local.app_size

  vm_sizing_dictionary_key             = length(var.application_tier.vm_sizing_dictionary_key) > 0 ? (
                                           var.application_tier.vm_sizing_dictionary_key) : (
                                           length(local.app_size) > 0 ? (
                                             "Optimized") : (
                                             "Default"
                                           )
                                         )


  // Subnet IP Offsets
  // Note: First 4 IP addresses in a subnet are reserved by Azure
  linux_ip_offsets                     = {
                                           scs_lb = 4
                                           scs_vm = 6
                                           app_vm = 10
                                           web_lb = var.infrastructure.virtual_networks.sap.subnet_web.defined ? (4 + 1) : 6
                                           web_vm = var.infrastructure.virtual_networks.sap.subnet_web.defined ? (10) : 50
                                         }

  windows_ip_offsets                   = {
                                           scs_lb = 4
                                           scs_vm = 6 + 2 # Windows HA SCS may require 4 IPs
                                           app_vm = 10 + 2
                                           web_lb = var.infrastructure.virtual_networks.sap.subnet_web.defined ? (4 + 1) : 6 + 2
                                           web_vm = var.infrastructure.virtual_networks.sap.subnet_web.defined ? (10) : 50
                                         }

  win_ha_scs                           = local.scs_server_count > 0 && (var.application_tier.scs_high_availability && upper(var.application_tier.scs_os.os_type) == "WINDOWS")

  ip_offsets                           = var.application_tier.scs_os.type == "WINDOWS" ? local.windows_ip_offsets : local.linux_ip_offsets

  admin_ip_offsets                     = {
                                           app_vm = 14
                                           scs_vm = 10
                                           web_vm = 50
                                         }


  // Default VM config should be merged with any the user passes in
  app_sizing                           = local.enable_deployment  ? (
                                           lookup(local.sizes.app, local.vm_sizing_dictionary_key)) : (
                                           null
                                         )

  scs_sizing                           = local.enable_deployment ? (
                                            var.application_tier.scs_high_availability ? (
                                              try(
                                                lookup(local.sizes.scsha, local.vm_sizing_dictionary_key),
                                                lookup(local.sizes.scs, local.vm_sizing_dictionary_key)
                                              )) : (
                                              lookup(local.sizes.scs, local.vm_sizing_dictionary_key)
                                            )
                                            ) : (
                                            null
                                          )


  web_sizing                           = local.enable_deployment && local.webdispatcher_count > 0 ? (
                                           lookup(local.sizes.web, local.vm_sizing_dictionary_key)) : (
                                           null
                                         )

  // Ports used for specific ASCS, ERS and Web dispatcher
  lb_ports                             = {
                                           "scs" = [
                                                     3200 + tonumber(var.application_tier.scs_instance_number),          // e.g. 3201
                                                     3600 + tonumber(var.application_tier.scs_instance_number),          // e.g. 3601
                                                     3900 + tonumber(var.application_tier.scs_instance_number),          // e.g. 3901
                                                     8100 + tonumber(var.application_tier.scs_instance_number),          // e.g. 8101
                                                     50013 + (tonumber(var.application_tier.scs_instance_number) * 100), // e.g. 50113
                                                     50014 + (tonumber(var.application_tier.scs_instance_number) * 100), // e.g. 50114
                                                     50016 + (tonumber(var.application_tier.scs_instance_number) * 100), // e.g. 50116
                                                   ]

                                                          "ers" = [
                                                     3200 + tonumber(var.application_tier.ers_instance_number),          // e.g. 3202
                                                     3300 + tonumber(var.application_tier.ers_instance_number),          // e.g. 3302
                                                     50013 + (tonumber(var.application_tier.ers_instance_number) * 100), // e.g. 50213
                                                     50014 + (tonumber(var.application_tier.ers_instance_number) * 100), // e.g. 50214
                                                     50016 + (tonumber(var.application_tier.ers_instance_number) * 100), // e.g. 50216
                                                   ]

                                                          "web" = [
                                                     80,
                                                     3200
                                                   ]
                                         }

  // Ports used for ASCS, ERS and Web dispatcher NSG rules
  nsg_ports                            = {
                                         "web" = [
                                                   {
                                                     "priority" = "101",
                                                     "name"     = "SSH",
                                                     "port"     = "22"
                                                   },
                                                   {
                                                     "priority" = "102",
                                                     "name"     = "HTTP",
                                                     "port"     = "80"
                                                   },
                                                   {
                                                     "priority" = "103",
                                                     "name"     = "HTTPS",
                                                     "port"     = "443"
                                                   },
                                                   {
                                                     "priority" = "104",
                                                     "name"     = "sapinst",
                                                     "port"     = "4237"
                                                   },
                                                   {
                                                     "priority" = "105",
                                                     "name"     = "WebDispatcher",
                                                     "port"     = "44300"
                                                   }
                                                 ]
                                         }

  // Ports used for the health probes.
  // Where Instance Number is nn:
  // SCS (index 0) - 620nn
  // ERS (index 1) - 621nn
  hp_ports                             = [
                                           62000 + tonumber(var.application_tier.scs_instance_number),
                                           62100 + tonumber(var.application_tier.ers_instance_number)
                                         ]


  // Zones
  app_zones                            = try(var.application_tier.app_zones, [])
  app_zonal_deployment                 = length(local.app_zones) > 0 ? true : false
  app_zone_count                       = length(local.app_zones)
  //If we deploy more than one server in zone put them in an availability set unless specified otherwise
  use_app_avset                        = var.application_tier.app_use_avset

  scs_zones                            = try(var.application_tier.scs_zones, [])
  scs_zonal_deployment                 = length(local.scs_zones) > 0 ? true : false
  scs_zone_count                       = length(local.scs_zones)
  //If we deploy more than one server in zone put them in an availability set
  use_scs_avset                        = var.application_tier.scs_use_avset

  web_zones                            = try(var.application_tier.web_zones, [])
  web_zonal_deployment                 = length(local.web_zones) > 0 ? true : false
  web_zone_count                       = length(local.web_zones)
  //If we deploy more than one server in zone put them in an availability set
  use_web_avset                        = local.webdispatcher_count > 0 && var.application_tier.web_use_avset ? (
                                           local.enable_deployment && (!local.web_zonal_deployment || local.webdispatcher_count != local.web_zone_count)) : (
                                           false
                                         )

  winha_ips                            = upper(var.application_tier.scs_os.os_type) == "WINDOWS" ? [
                                           {
                                             name = format("%s%s%s%s",
                                               var.naming.resource_prefixes.scs_clst_feip,
                                               local.prefix,
                                               var.naming.separator,
                                               local.resource_suffixes.scs_clst_feip
                                             )
                                             subnet_id = local.enable_deployment ? (
                                               local.application_subnet_exists ? (
                                                 data.azurerm_subnet.subnet_sap_app[0].id) : (
                                                 azurerm_subnet.subnet_sap_app[0].id
                                               )) : (
                                               ""
                                             )
                                             private_ip_address = length(try(local.scs_server_loadbalancer_ips[2], "")) > 0 ? (
                                               local.scs_server_loadbalancer_ips[2]) : (
                                               var.application_tier.use_DHCP ? (
                                               null) : (cidrhost(data.azurerm_subnet.subnet_sap_app[0].address_prefixes[0], 2 + local.ip_offsets.scs_lb))
                                             )
                                             private_ip_address_allocation = length(try(local.scs_server_loadbalancer_ips[2], "")) > 0 ? "Static" : "Dynamic"

                                           },
                                           {
                                             name = format("%s%s%s%s",
                                               var.naming.resource_prefixes.scs_fs_feip,
                                               local.prefix,
                                               var.naming.separator,
                                               local.resource_suffixes.scs_fs_feip
                                             )
                                             subnet_id = local.enable_deployment ? (
                                               local.application_subnet_exists ? (
                                                 data.azurerm_subnet.subnet_sap_app[0].id) : (
                                                 azurerm_subnet.subnet_sap_app[0].id
                                               )) : (
                                               ""
                                             )
                                             private_ip_address = length(try(local.scs_server_loadbalancer_ips[3], "")) > 0 ? (
                                               local.scs_server_loadbalancer_ips[3]) : (
                                               var.application_tier.use_DHCP ? (
                                               null) : (cidrhost(data.azurerm_subnet.subnet_sap_app[0].address_prefixes[0], 3 + local.ip_offsets.scs_lb))
                                             )
                                             private_ip_address_allocation = length(try(local.scs_server_loadbalancer_ips[3], "")) > 0 ? "Static" : "Dynamic"
                                           }
                                         ] : []

  standard_ips                         = [
                                           {
                                             name = format("%s%s%s%s",
                                                       var.naming.resource_prefixes.scs_alb_feip,
                                                       local.prefix,
                                                       var.naming.separator,
                                                       local.resource_suffixes.scs_alb_feip
                                                     )
                                             subnet_id = local.enable_deployment ? (
                                                           local.application_subnet_exists ? (
                                                             data.azurerm_subnet.subnet_sap_app[0].id) : (
                                                             azurerm_subnet.subnet_sap_app[0].id
                                                           )) : (
                                                           ""
                                                         )
                                             private_ip_address = length(try(local.scs_server_loadbalancer_ips[0], "")) > 0 ? (
                                                                    local.scs_server_loadbalancer_ips[0]) : (
                                                                    var.application_tier.use_DHCP ? (
                                                                    null) : (cidrhost(data.azurerm_subnet.subnet_sap_app[0].address_prefixes[0], 0 + local.ip_offsets.scs_lb))
                                                                  )
                                             private_ip_address_allocation = length(try(local.scs_server_loadbalancer_ips[0], "")) > 0 ? "Static" : "Dynamic"
                                           },
                                           {
                                             name = format("%s%s%s%s",
                                                      var.naming.resource_prefixes.scs_ers_feip,
                                                      local.prefix,
                                                      var.naming.separator,
                                                      local.resource_suffixes.scs_ers_feip
                                                    )
                                             subnet_id = local.enable_deployment ? (
                                                           local.application_subnet_exists ? (
                                                             data.azurerm_subnet.subnet_sap_app[0].id) : (
                                                             azurerm_subnet.subnet_sap_app[0].id
                                                           )) : (
                                                           ""
                                                         )
                                             private_ip_address = length(try(local.scs_server_loadbalancer_ips[1], "")) > 0 ? (
                                                                    local.scs_server_loadbalancer_ips[1]) : (
                                                                    var.application_tier.use_DHCP ? (
                                                                    null) : (cidrhost(data.azurerm_subnet.subnet_sap_app[0].address_prefixes[0], 1 + local.ip_offsets.scs_lb))
                                                                  )
                                             private_ip_address_allocation = length(try(local.scs_server_loadbalancer_ips[1], "")) > 0 ? "Static" : "Dynamic"
                                           },
                                         ]

  frontend_ips                         = (var.application_tier.scs_high_availability && upper(var.application_tier.scs_os.os_type) == "WINDOWS") ? (
                                           concat(local.standard_ips, local.winha_ips)) : (
                                           local.standard_ips
                                         )

  dns_label                            = try(var.landscape_tfstate.dns_label, "")

  deploy_route_table                   = local.enable_deployment && length(var.route_table_id) > 0

  application_primary_ips              = [
                                           {
                                             name = "IPConfig1"
                                             subnet_id = local.enable_deployment ? (
                                                           local.application_subnet_exists ? (
                                                             data.azurerm_subnet.subnet_sap_app[0].id) : (
                                                             azurerm_subnet.subnet_sap_app[0].id
                                                           )) : (
                                                           ""
                                                         )
                                             nic_ips                       = local.app_nic_ips
                                             private_ip_address_allocation = var.application_tier.use_DHCP ? "Dynamic" : "Static"
                                             offset                        = 0
                                             primary                       = true
                                           }
                                         ]

  application_secondary_ips            = [
                                           {
                                             name = "IPConfig2"
                                             subnet_id = local.enable_deployment ? (
                                                           local.application_subnet_exists ? (
                                                             data.azurerm_subnet.subnet_sap_app[0].id) : (
                                                             azurerm_subnet.subnet_sap_app[0].id
                                                           )) : (
                                                           ""
                                                         )
                                             nic_ips                       = local.app_nic_secondary_ips
                                             private_ip_address_allocation = var.application_tier.use_DHCP ? "Dynamic" : "Static"
                                             offset                        = local.application_server_count
                                             primary                       = false
                                           }
                                         ]

  application_ips                      = (var.use_secondary_ips) ? (
                                           flatten(concat(local.application_primary_ips, local.application_secondary_ips))) : (
                                           local.application_primary_ips
                                         )

  scs_primary_ips                      = [
                                           {
                                             name = "IPConfig1"
                                             subnet_id = local.enable_deployment ? (
                                                           local.application_subnet_exists ? (
                                                             data.azurerm_subnet.subnet_sap_app[0].id) : (
                                                             azurerm_subnet.subnet_sap_app[0].id
                                                           )) : (
                                                           ""
                                                         )
                                             nic_ips                       = local.scs_nic_ips
                                             private_ip_address_allocation = var.application_tier.use_DHCP ? "Dynamic" : "Static"
                                             offset                        = 0
                                             primary                       = true
                                           }
                                         ]

  scs_secondary_ips                    = [
                                           {
                                             name = "IPConfig2"
                                             subnet_id = local.enable_deployment ? (
                                                           local.application_subnet_exists ? (
                                                             data.azurerm_subnet.subnet_sap_app[0].id) : (
                                                             azurerm_subnet.subnet_sap_app[0].id
                                                           )) : (
                                                           ""
                                                         )
                                             nic_ips                       = local.scs_nic_secondary_ips
                                             private_ip_address_allocation = var.application_tier.use_DHCP ? "Dynamic" : "Static"
                                             offset                        = local.scs_server_count
                                             primary                       = false
                                           }
                                         ]

  scs_ips                              = (var.use_secondary_ips) ? (
                                           flatten(concat(local.scs_primary_ips, local.scs_secondary_ips))) : (
                                           local.scs_primary_ips
                                         )

  web_dispatcher_primary_ips           = [
                                           {
                                             name      = "IPConfig1"
                                             subnet_id = local.enable_deployment && local.webdispatcher_count > 0 ? local.web_subnet_deployed_id : ""

                                             nic_ips                       = local.web_nic_ips
                                             private_ip_address_allocation = var.application_tier.use_DHCP ? "Dynamic" : "Static"
                                             offset                        = 0
                                             primary                       = true
                                           }
                                         ]

  web_dispatcher_secondary_ips         = [
                                           {
                                             name                          = "IPConfig2"
                                             subnet_id                     = local.enable_deployment && local.webdispatcher_count > 0 ? local.web_subnet_deployed_id : ""
                                             nic_ips                       = local.web_nic_secondary_ips
                                             private_ip_address_allocation = var.application_tier.use_DHCP ? "Dynamic" : "Static"
                                             offset                        = local.webdispatcher_count
                                             primary                       = false
                                           }
                                         ]

  web_dispatcher_ips                   = (var.use_secondary_ips) ? (
                                           flatten(concat(local.web_dispatcher_primary_ips, local.web_dispatcher_secondary_ips))) : (
                                           local.web_dispatcher_primary_ips
                                         )

  load_balancer_IP_names               = [
                                           format("%s%s%s", local.prefix, var.naming.separator, "scs"),
                                           format("%s%s%s", local.prefix, var.naming.separator, "ers"),
                                           format("%s%s%s", local.prefix, var.naming.separator, "clst"),
                                           format("%s%s%s", local.prefix, var.naming.separator, "fs")
                                         ]

  web_load_balancer_IP_names           = local.enable_web_lb_deployment ? (
                                           [
                                             format("%s%s%s", local.prefix, var.naming.separator, local.resource_suffixes.web_alb)
                                           ]
                                           ) : (
                                           [""]
                                         )

  extension_settings                   =  length(var.application_tier.user_assigned_identity_id) > 0 ? [{
                                           "key" = "msi_res_id"
                                           "value" = var.application_tier.user_assigned_identity_id
                                         }] : []

  deploy_monitoring_extension          = local.enable_deployment && var.infrastructure.deploy_monitoring_extension && length(var.application_tier.user_assigned_identity_id) > 0


}
