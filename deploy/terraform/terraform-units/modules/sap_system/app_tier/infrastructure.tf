// In brownfield scenarios the subnets are often defined in the workload
// If subnet information is specified in the parameter file use it
// As either of the arm_id or the prefix need to be specified to create
// a subnet the lack of both indicate that the subnet is to be created in the
// SAP Infrastructure Deployment

#######################################4#######################################8
#                                                                              #
#              Application subnet - Check if locally provided                  #
#                                                                              #
#######################################4#######################################8

resource "azurerm_subnet" "subnet_sap_app" {
  provider                             = azurerm.main
  count                                = local.enable_deployment ? (local.application_subnet_exists ? 0 : 1) : 0
  name                                 = local.application_subnet_name
  resource_group_name                  = split("/", var.landscape_tfstate.vnet_sap_arm_id)[4]
  virtual_network_name                 = split("/", var.landscape_tfstate.vnet_sap_arm_id)[8]
  address_prefixes                     = [local.application_subnet_prefix]
}

data "azurerm_subnet" "subnet_sap_app" {
  provider                             = azurerm.main
  count                                = local.enable_deployment ? (local.application_subnet_exists ? 1 : 0) : 0
  name                                 = split("/", local.application_subnet_arm_id)[10]
  resource_group_name                  = split("/", local.application_subnet_arm_id)[4]
  virtual_network_name                 = split("/", local.application_subnet_arm_id)[8]
}

#######################################4#######################################8
#                                                                              #
#             Route table association - application subnet                     #
#                                                                              #
#######################################4#######################################8
resource "azurerm_subnet_route_table_association" "app" {
  provider                             = azurerm.main
  count                                = (
                                           local.application_subnet_defined && !local.application_subnet_exists && length(var.landscape_tfstate.route_table_id) > 0
                                           ) ? (
                                           1) : (
                                           0
                                         )
  subnet_id                            = azurerm_subnet.subnet_sap_app[0].id
  route_table_id                       = var.landscape_tfstate.route_table_id
}

// In brownfield scenarios the subnets are often defined in the workload
// If subnet information is specified in the parameter file use it
// As either of the arm_id or the prefix need to be specified to create
// a subnet the lack of both indicate that the subnet is to be created in the
// SAP Infrastructure Deployment

#######################################4#######################################8
#                                                                              #
#                       Web subnet - Check if locally provided                 #
#                                                                              #
#######################################4#######################################8
resource "azurerm_subnet" "subnet_sap_web" {
  provider                             = azurerm.main
  count                                = local.enable_deployment && local.web_subnet_defined ? (local.web_subnet_exists ? 0 : 1) : 0
  name                                 = local.web_subnet_name
  resource_group_name                  = split("/", var.landscape_tfstate.vnet_sap_arm_id)[4]
  virtual_network_name                 = split("/", var.landscape_tfstate.vnet_sap_arm_id)[8]
  address_prefixes                     = [local.web_subnet_prefix]
}

# Imports data of existing SAP web dispatcher subnet
data "azurerm_subnet" "subnet_sap_web" {
  provider                             = azurerm.main
  count                                = local.enable_deployment ? (local.web_subnet_exists ? 1 : 0) : 0
  name                                 = split("/", local.web_subnet_arm_id)[10]
  resource_group_name                  = split("/", local.web_subnet_arm_id)[4]
  virtual_network_name                 = split("/", local.web_subnet_arm_id)[8]
}

#######################################4#######################################8
#                                                                              #
#                   Create the SCS Load Balancer                               #
#                                                                              #
#######################################4#######################################8

resource "azurerm_lb" "scs" {
  provider                             = azurerm.main
  count                                = local.enable_scs_lb_deployment ? 1 : 0
  name                                 = format("%s%s%s%s",
                                           var.naming.resource_prefixes.scs_alb,
                                           local.prefix,
                                           var.naming.separator,
                                           local.resource_suffixes.scs_alb
                                         )
  resource_group_name                  = var.resource_group[0].name
  location                             = var.resource_group[0].location
  sku                                  = "Standard"
  tags                                 = var.tags

  dynamic "frontend_ip_configuration" {
                                        iterator = pub
                                        for_each = local.frontend_ips
                                        content {
                                          name                          = pub.value.name
                                          subnet_id                     = pub.value.subnet_id
                                          private_ip_address            = pub.value.private_ip_address
                                          private_ip_address_allocation = pub.value.private_ip_address_allocation
                                          zones                         = ["1", "2", "3"]
                                        }
                                      }
}

resource "azurerm_lb_backend_address_pool" "scs" {
  provider                             = azurerm.main
  count                                = local.enable_scs_lb_deployment ? 1 : 0
  name = format("%s%s%s%s",
           var.naming.resource_prefixes.scs_alb_bepool,
           local.prefix,
           var.naming.separator,
           local.resource_suffixes.scs_alb_bepool
         )
  loadbalancer_id                      = azurerm_lb.scs[0].id
}

resource "azurerm_lb_probe" "scs" {
  provider                             = azurerm.main
  count                                = local.enable_scs_lb_deployment ? (var.application_tier.scs_high_availability ? 2 : 1) : 0
  loadbalancer_id                      = azurerm_lb.scs[0].id
  name = format("%s%s%s%s",
           var.naming.resource_prefixes[count.index == 0 ? "scs_alb_hp" : "scs_ers_hp"],
           local.prefix,
           var.naming.separator,
           local.resource_suffixes[count.index == 0 ? "scs_alb_hp" : "scs_ers_hp"]
         )
  port                                 = local.hp_ports[count.index]
  protocol                             = "Tcp"
  interval_in_seconds                  = 5
  number_of_probes                     = var.application_tier.scs_high_availability && upper(var.application_tier.scs_os.os_type) == "WINDOWS" ? 4 : 2
  probe_threshold                      = 2
}

resource "azurerm_lb_probe" "clst" {
  provider                             = azurerm.main
  count                                = var.application_tier.scs_high_availability && upper(var.application_tier.scs_os.os_type) == "WINDOWS" ? 1 : 0
  loadbalancer_id                      = azurerm_lb.scs[0].id
  name                                 = format("%s%s%s%s",
                                           var.naming.resource_prefixes.scs_clst_hp,
                                           local.prefix,
                                           var.naming.separator,
                                           local.resource_suffixes.scs_clst_hp
                                         )
  port                                 = local.hp_ports[count.index]
  protocol                             = "Tcp"
  interval_in_seconds                  = 5
  number_of_probes                     = var.application_tier.scs_high_availability && upper(var.application_tier.scs_os.os_type) == "WINDOWS" ? 4 : 2
  probe_threshold                      = 2
}

resource "azurerm_lb_probe" "fs" {
  provider                             = azurerm.main
  count                                = var.application_tier.scs_high_availability && upper(var.application_tier.scs_os.os_type) == "WINDOWS" ? 1 : 0
  loadbalancer_id                      = azurerm_lb.scs[0].id
  name                                 = format("%s%s%s",
                                           local.prefix,
                                           var.naming.separator,
                                           local.resource_suffixes.scs_fs_hp
                                         )
  port                                 = local.hp_ports[count.index]
  protocol                             = "Tcp"
  interval_in_seconds                  = 5
  number_of_probes                     = var.application_tier.scs_high_availability && upper(var.application_tier.scs_os.os_type) == "WINDOWS" ? 4 : 2
  probe_threshold                      = 2
}

# Create the SCS Load Balancer Rules
resource "azurerm_lb_rule" "scs" {
  provider                             = azurerm.main
  count                                = local.enable_scs_lb_deployment ? 1 : 0
  loadbalancer_id                      = azurerm_lb.scs[0].id
  name                                 = length(local.prefix) > 0 ? (
                                           format("%s%s%s%s",
                                             var.naming.resource_prefixes.scs_scs_rule,
                                             local.prefix,
                                             var.naming.separator,
                                             local.resource_suffixes.scs_scs_rule
                                           )) : (
                                           format("%s%s",
                                             var.naming.resource_prefixes.scs_scs_rule,
                                             local.resource_suffixes.scs_scs_rule
                                           )

                                          )
  protocol                             = "All"
  frontend_port                        = 0
  backend_port                         = 0
  frontend_ip_configuration_name       = format("%s%s%s%s",
                                           var.naming.resource_prefixes.scs_alb_feip,
                                           local.prefix,
                                           var.naming.separator,
                                           local.resource_suffixes.scs_alb_feip
                                         )
  backend_address_pool_ids             = [azurerm_lb_backend_address_pool.scs[0].id]
  probe_id                             = azurerm_lb_probe.scs[0].id
  enable_floating_ip                   = true
  enable_tcp_reset                     = true
  idle_timeout_in_minutes              = var.idle_timeout_scs_ers
}

# Create the ERS Load balancer rules only in High Availability configurations
resource "azurerm_lb_rule" "ers" {
  provider                             = azurerm.main
  count                                = local.enable_scs_lb_deployment && var.application_tier.scs_high_availability ? 1 : 0
  loadbalancer_id                      = azurerm_lb.scs[0].id
  name                                 = length(local.prefix) > 0 ? (
                                           format("%s%s%s%s",
                                             var.naming.resource_prefixes.scs_ers_rule,
                                             local.prefix,
                                             var.naming.separator,
                                             local.resource_suffixes.scs_ers_rule
                                           )) : (
                                           format("%s%s",
                                             var.naming.resource_prefixes.scs_ers_rule,
                                             local.resource_suffixes.scs_ers_rule
                                         ))
  protocol                             = "All"
  frontend_port                        = 0
  backend_port                         = 0
  frontend_ip_configuration_name       = format("%s%s%s%s",
                                           var.naming.resource_prefixes.scs_ers_feip,
                                           local.prefix,
                                           var.naming.separator,
                                           local.resource_suffixes.scs_ers_feip
                                         )
  backend_address_pool_ids             = [azurerm_lb_backend_address_pool.scs[0].id]
  probe_id                             = azurerm_lb_probe.scs[1].id
  enable_floating_ip                   = true
  enable_tcp_reset                     = true
  idle_timeout_in_minutes              = var.idle_timeout_scs_ers
}

resource "azurerm_lb_rule" "clst" {
  provider                             = azurerm.main
  count                                = local.enable_scs_lb_deployment && local.win_ha_scs ? 0 : 0
  loadbalancer_id                      = azurerm_lb.scs[0].id
  name                                 = length(local.prefix) > 0 ? (
                                           format("%s%s%s%s",
                                             var.naming.resource_prefixes.scs_clst_rule,
                                             local.prefix,
                                             var.naming.separator,
                                             local.resource_suffixes.scs_clst_rule
                                           )) : (
                                           format("%s%s",
                                             var.naming.resource_prefixes.scs_clst_rule,
                                             local.resource_suffixes.scs_clst_rule
                                         ))
  protocol                             = "All"
  frontend_port                        = 0
  backend_port                         = 0
  frontend_ip_configuration_name       = format("%s%s%s%s",
                                           var.naming.resource_prefixes.scs_clst_feip,
                                           local.prefix,
                                           var.naming.separator,
                                           local.resource_suffixes.scs_clst_feip
                                         )
  backend_address_pool_ids             = [azurerm_lb_backend_address_pool.scs[0].id]
  probe_id                             = azurerm_lb_probe.clst[0].id
  enable_floating_ip                   = true
}

resource "azurerm_lb_rule" "fs" {
  provider                             = azurerm.main
  count                                = local.enable_scs_lb_deployment && local.win_ha_scs ? 0 : 0
  loadbalancer_id                      = azurerm_lb.scs[0].id
  name                                 = length(local.prefix) > 0 ? (
                                           format("%s%s%s%s",
                                             var.naming.resource_prefixes.scs_fs_rule,
                                             local.prefix,
                                             var.naming.separator,
                                             local.resource_suffixes.scs_fs_rule
                                           )) : (
                                           format("%s%s",
                                             var.naming.resource_prefixes.scs_fs_rule,
                                             local.resource_suffixes.scs_fs_rule
                                         ))
  protocol                             = "All"
  frontend_port                        = 0
  backend_port                         = 0
  frontend_ip_configuration_name       = format("%s%s%s%s",
                                           local.prefix,
                                           var.naming.resource_prefixes.scs_fs_feip,
                                           var.naming.separator,
                                           local.resource_suffixes.scs_fs_feip
                                         )
  backend_address_pool_ids             = [azurerm_lb_backend_address_pool.scs[0].id]
  probe_id                             = azurerm_lb_probe.fs[0].id
  enable_floating_ip                   = true
}

#######################################4#######################################8
#                                                                              #
#                   Create the SCS Availability Set                            #
#                                                                              #
#######################################4#######################################8
resource "azurerm_availability_set" "scs" {
  provider                             = azurerm.main
  count                                = local.enable_deployment && local.use_scs_avset ? (
                                           length(var.ppg)) : (
                                           0
                                         )
  name                                 = format("%s%s%s",
                                           local.prefix,
                                           var.naming.separator,
                                           var.naming.availabilityset_names.scs[count.index]
                                         )
  location                             = var.resource_group[0].location
  resource_group_name                  = var.resource_group[0].name
  platform_update_domain_count         = 20
  platform_fault_domain_count          = local.faultdomain_count
  proximity_placement_group_id         = var.ppg[count.index]
  managed                              = true
  tags                                 = var.tags
}

#######################################4#######################################8
#                                                                              #
#             Create the Application Server Availability Set                   #
#                                                                              #
#######################################4#######################################8
resource "azurerm_availability_set" "app" {
  provider                             = azurerm.main
  count                                = local.use_app_avset && length(var.application_tier.avset_arm_ids) == 0 ? (
                                           length(var.ppg)) : (
                                           0
                                         )
  name                                 = format("%s%s%s",
                                           local.prefix,
                                           var.naming.separator,
                                           var.naming.availabilityset_names.app[count.index]
                                         )
  location                             = var.resource_group[0].location
  resource_group_name                  = var.resource_group[0].name
  platform_update_domain_count         = 20
  platform_fault_domain_count          = local.faultdomain_count
  proximity_placement_group_id         = var.ppg[count.index]
  managed                              = true
  tags                                 = var.tags
}

/*
 Web dispatcher Load Balancer
 Web dispatcher Availability Set
*/



##############################################################################################
#
#  Create the Application Security Group
#
##############################################################################################

resource "azurerm_application_security_group" "app" {
  provider                             = azurerm.main
  count                                = local.enable_deployment ? (
                                            var.deploy_application_security_groups ? 1 : 0) : (
                                            0
                                          )
  name                                 = format("%s%s%s%s",
                                           var.naming.resource_prefixes.app_asg,
                                           local.prefix,
                                           var.naming.separator,
                                           local.resource_suffixes.app_asg
                                         )
  resource_group_name                  = var.options.nsg_asg_with_vnet ? (
                                          var.network_resource_group) : (
                                          var.resource_group[0].name
                                        )
  location                             = var.options.nsg_asg_with_vnet ? (
                                           var.network_location) : (
                                           var.resource_group[0].location
                                         )
  tags                                 = var.tags
}

resource "azurerm_application_security_group" "web" {
  provider                             = azurerm.main
  count                                = local.enable_deployment ? (
                                            var.deploy_application_security_groups ? 1 : 0) : (
                                            0
                                          )
  name                                 = format("%s%s%s%s",
                                           var.naming.resource_prefixes.web_asg,
                                           local.prefix,
                                           var.naming.separator,
                                           local.resource_suffixes.web_asg
                                         )
  resource_group_name                  = var.options.nsg_asg_with_vnet ? (
                                          var.network_resource_group) : (
                                          var.resource_group[0].name
                                        )
  location                             = var.options.nsg_asg_with_vnet ? (
                                           var.network_location) : (
                                           var.resource_group[0].location
                                         )
  tags                                 = var.tags
}

resource "azurerm_subnet_route_table_association" "subnet_sap_app" {
  provider                             = azurerm.main
  count                                = !local.application_subnet_exists && local.deploy_route_table ? 1 : 0
  subnet_id                            = azurerm_subnet.subnet_sap_app[0].id
  route_table_id                       = var.route_table_id
}

resource "azurerm_subnet_route_table_association" "subnet_sap_web" {
  provider                             = azurerm.main
  count                                = local.deploy_route_table && local.web_subnet_defined ? (
                                           local.web_subnet_exists ? (
                                             0) : (
                                             1
                                           )) : (
                                           0
                                         )
  subnet_id                            = azurerm_subnet.subnet_sap_web[0].id
  route_table_id                       = var.route_table_id
}


#######################################4#######################################8
#                                                                              #
#                                       DNS                                    #
#                                                                              #
#######################################4#######################################8

resource "azurerm_private_dns_a_record" "scs" {
  provider                             = azurerm.dnsmanagement
  count                                = local.enable_scs_lb_deployment && length(local.dns_label) > 0  && var.register_virtual_network_to_dns ? 1 : 0
  name                                 = lower(format("%sscs%scl1",
                                           local.sid,
                                           var.application_tier.scs_instance_number
                                         ))
  resource_group_name                  = coalesce(var.management_dns_resourcegroup_name, var.landscape_tfstate.dns_resource_group_name)
  zone_name                            = var.landscape_tfstate.dns_label
  ttl                                  = 300
  records                              = [azurerm_lb.scs[0].frontend_ip_configuration[0].private_ip_address]
}

resource "azurerm_private_dns_a_record" "ers" {
  provider                             = azurerm.dnsmanagement
  count                                = local.enable_scs_lb_deployment && length(local.dns_label) > 0 && var.register_virtual_network_to_dns ? 1 : 0
  name                                 = lower(format("%sers%scl2",
                                            local.sid,
                                            local.ers_instance_number
                                          ))
  resource_group_name                  = coalesce(var.management_dns_resourcegroup_name, var.landscape_tfstate.dns_resource_group_name)
  zone_name                            = local.dns_label
  ttl                                  = 300
  records                              = [azurerm_lb.scs[0].frontend_ip_configuration[1].private_ip_address]
}

resource "azurerm_private_dns_a_record" "web" {
  provider                             = azurerm.dnsmanagement
  count                                = local.enable_web_lb_deployment && length(local.dns_label) > 0 && var.register_virtual_network_to_dns ? 1 : 0
  name                                 = lower(format("%sweb%s",
                                           local.sid, var.application_tier.web_instance_number
                                         ))
  resource_group_name                  = coalesce(var.management_dns_resourcegroup_name, var.landscape_tfstate.dns_resource_group_name)
  zone_name                            = local.dns_label
  ttl                                  = 300
  records                              = [azurerm_lb.web[0].frontend_ip_configuration[0].private_ip_address]
}
