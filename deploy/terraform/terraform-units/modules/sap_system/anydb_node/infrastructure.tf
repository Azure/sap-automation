
#######################################4#######################################8
#                                                                              #
#                            Load Balancer                                     #
#                                                                              #
#######################################4#######################################8

resource "azurerm_lb" "anydb" {
  provider                             = azurerm.main
  count                                = local.enable_db_lb_deployment ? 1 : 0
  name                                 = format("%s%s%s%s",
                                          var.naming.resource_prefixes.db_alb,
                                          local.prefix,
                                          var.naming.separator,
                                          local.resource_suffixes.db_alb
                                        )
  sku                                  = "Standard"

  resource_group_name                  = var.resource_group[0].name
  location                             = var.resource_group[0].location

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

  tags                                 = var.tags

}

resource "azurerm_lb_backend_address_pool" "anydb" {
  provider                             = azurerm.main
  count                                = local.enable_db_lb_deployment ? 1 : 0
  name                                 = format("%s%s%s%s",
                                           var.naming.resource_prefixes.db_alb_bepool,
                                           local.prefix,
                                           var.naming.separator,
                                           local.resource_suffixes.db_alb_bepool
                                         )
  loadbalancer_id                      = azurerm_lb.anydb[count.index].id
}

resource "azurerm_lb_probe" "anydb" {
  provider                             = azurerm.main
  count                                = local.enable_db_lb_deployment ? 1 : 0
  name                                 = format("%s%s%s%s",
                                           var.naming.resource_prefixes.db_alb_hp,
                                           local.prefix,
                                           var.naming.separator,
                                           local.resource_suffixes.db_alb_hp
                                         )
  loadbalancer_id                      = azurerm_lb.anydb[count.index].id
  port                                 = local.loadbalancer_ports[0].port
  protocol                             = "Tcp"
  interval_in_seconds                  = 5
  number_of_probes                     = 2
  probe_threshold                      = 2
}

#######################################4#######################################8
#                                                                              #
#                         Load Balancer rules                                  #
#                                                                              #
#######################################4#######################################8
resource "azurerm_lb_rule" "anydb" {
  provider                             = azurerm.main
  count                                = local.enable_db_lb_deployment && var.database_server_count > 0 ? 1 : 0
  loadbalancer_id                      = azurerm_lb.anydb[0].id
  name                                 = format("%s%s%s%s",
                                           var.naming.resource_prefixes.db_alb_rule,
                                           local.prefix,
                                           var.naming.separator,
                                           local.resource_suffixes.db_alb_rule
                                         )
  protocol                             = "All"
  frontend_port                        = 0
  backend_port                         = 0
  frontend_ip_configuration_name       = format("%s%s%s%s",
                                           var.naming.resource_prefixes.db_alb_feip,
                                           local.prefix,
                                           var.naming.separator,
                                           local.resource_suffixes.db_alb_feip
                                         )
  probe_id                             = azurerm_lb_probe.anydb[0].id
  backend_address_pool_ids             = [azurerm_lb_backend_address_pool.anydb[0].id]
  enable_floating_ip                   = true
  idle_timeout_in_minutes              = 30

}


resource "azurerm_network_interface_backend_address_pool_association" "anydb" {
  provider                             = azurerm.main
  count                                = local.enable_db_lb_deployment ? var.database_server_count : 0
  network_interface_id                 = azurerm_network_interface.anydb_db[count.index].id
  ip_configuration_name                = azurerm_network_interface.anydb_db[count.index].ip_configuration[0].name
  backend_address_pool_id              = azurerm_lb_backend_address_pool.anydb[0].id
}

#######################################4#######################################8
#                                                                              #
#                            Availability Set                                  #
#                                                                              #
#######################################4#######################################8

resource "azurerm_availability_set" "anydb" {
  provider                             = azurerm.main
  count                                = local.enable_deployment && !var.use_scalesets_for_deployment  ? (
                                            var.database.use_avset && !local.availabilitysets_exist ? max(length(local.zones), 1) : 0) : (
                                            0
                                          )
  name                                 = format("%s%s%s",
                                           local.prefix,
                                           var.naming.separator,
                                           var.naming.availabilityset_names.db[count.index]
                                         )
  location                             = var.resource_group[0].location
  resource_group_name                  = var.resource_group[0].name
  platform_update_domain_count         = 20
  platform_fault_domain_count          = local.faultdomain_count
  proximity_placement_group_id         = try(var.database.use_ppg ? (
                                           var.ppg[count.index % max(local.db_zone_count, 1)]) : (
                                           null
                                         ), null)
  managed                              = true
  tags                                 = var.tags
}

data "azurerm_availability_set" "anydb" {
  provider                             = azurerm.main
  count                                = local.enable_deployment && !var.use_scalesets_for_deployment  ? (
                                           local.use_avset && local.availabilitysets_exist? max(length(local.zones), 1) : 0) : (
                                           0
                                         )
  name                                 = split("/", local.availabilityset_arm_ids[count.index])[8]
  resource_group_name                  = split("/", local.availabilityset_arm_ids[count.index])[4]
}

#######################################4#######################################8
#                                                                              #
#                                 DNS Record                                   #
#                                                                              #
#######################################4#######################################8

resource "azurerm_private_dns_a_record" "db" {
  provider                             = azurerm.dnsmanagement
  count                                = local.enable_db_lb_deployment && length(local.dns_label) > 0 && var.register_virtual_network_to_dns ? 1 : 0
  name                                 = lower(format("%s%sdb%scl", var.sap_sid, local.anydb_sid, "00"))
  resource_group_name                  = coalesce(var.management_dns_resourcegroup_name, var.landscape_tfstate.dns_resource_group_name)
  zone_name                            = local.dns_label
  ttl                                  = 300
  records                              = [azurerm_lb.anydb[0].frontend_ip_configuration[0].private_ip_address]
  tags                                 = var.tags
}
