// AVAILABILITY SET
resource "azurerm_availability_set" "hdb" {
  count                        = local.enable_deployment && local.use_avset && !local.availabilitysets_exist ? max(length(local.zones), 1) : 0
  name                         = format("%s%s%s", local.prefix, var.naming.separator, var.naming.db_avset_names[count.index])
  location                     = var.resource_group[0].location
  resource_group_name          = var.resource_group[0].name
  platform_update_domain_count = 20
  platform_fault_domain_count  = local.faultdomain_count
  proximity_placement_group_id = local.zonal_deployment ? (
    null) : (
    local.no_ppg ? (
      null) : (
      var.ppg[0].id
    )
  )
  managed                      = true
}

data "azurerm_availability_set" "hdb" {
  provider            = azurerm.main
  count               = local.enable_deployment && local.use_avset && local.availabilitysets_exist ? max(length(local.zones), 1) : 0
  name                = split("/", local.availabilityset_arm_ids[count.index])[8]
  resource_group_name = split("/", local.availabilityset_arm_ids[count.index])[4]
}

// LOAD BALANCER ===============================================================
/*-----------------------------------------------------------------------------8
Load balancer front IP address range: .4 - .9
+--------------------------------------4--------------------------------------*/

resource "azurerm_lb" "hdb" {
  provider            = azurerm.main
  count               = local.enable_db_lb_deployment ? 1 : 0
  name                = format("%s%s%s", local.prefix, var.naming.separator, local.resource_suffixes.db_alb)
  resource_group_name = var.resource_group[0].name
  location            = var.resource_group[0].location
  sku                 = "Standard"

  frontend_ip_configuration {
    name                          = format("%s%s%s", local.prefix, var.naming.separator, local.resource_suffixes.db_alb_feip)
    subnet_id                     = var.db_subnet.id
    private_ip_address            = var.databases[0].use_DHCP ? null : try(var.databases[0].loadbalancer.frontend_ip, cidrhost(var.db_subnet.address_prefixes[0], tonumber(count.index) + local.hdb_ip_offsets.hdb_lb))
    private_ip_address_allocation = var.databases[0].use_DHCP ? "Dynamic" : "Static"
  }

}

resource "azurerm_lb_backend_address_pool" "hdb" {
  provider        = azurerm.main
  count           = local.enable_db_lb_deployment ? 1 : 0
  name            = format("%s%s%s", local.prefix, var.naming.separator, local.resource_suffixes.db_alb_bepool)
  loadbalancer_id = azurerm_lb.hdb[count.index].id

}

resource "azurerm_lb_probe" "hdb" {
  provider            = azurerm.main
  count               = local.enable_db_lb_deployment ? 1 : 0
  resource_group_name = var.resource_group[0].name
  loadbalancer_id     = azurerm_lb.hdb[count.index].id
  name                = format("%s%s%s", local.prefix, var.naming.separator, local.resource_suffixes.db_alb_hp)
  port                = "625${var.databases[0].instance.instance_number}"
  protocol            = "Tcp"
  interval_in_seconds = 5
  number_of_probes    = 2
}

# TODO:
# Current behavior, it will try to add all VMs in the cluster into the backend pool, which would not work since we do not have availability sets created yet.
# In a scale-out scenario, we need to rewrite this code according to the scale-out + HA reference architecture.
resource "azurerm_network_interface_backend_address_pool_association" "hdb" {
  count                   = local.enable_db_lb_deployment ? var.database_server_count : 0
  network_interface_id    = azurerm_network_interface.nics_dbnodes_db[count.index].id
  ip_configuration_name   = azurerm_network_interface.nics_dbnodes_db[count.index].ip_configuration[0].name
  backend_address_pool_id = azurerm_lb_backend_address_pool.hdb[0].id
}

resource "azurerm_lb_rule" "hdb" {
  provider                       = azurerm.main
  count                          = local.enable_db_lb_deployment ? 1 : 0
  resource_group_name            = var.resource_group[0].name
  loadbalancer_id                = azurerm_lb.hdb[0].id
  name                           = format("%s%s%s", local.prefix, var.naming.separator, local.resource_suffixes.db_alb_rule)
  protocol                       = "All"
  frontend_port                  = 0
  backend_port                   = 0
  frontend_ip_configuration_name = format("%s%s%s", local.prefix, var.naming.separator, local.resource_suffixes.db_alb_feip)
  probe_id                       = azurerm_lb_probe.hdb[0].id
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.hdb[0].id]
  enable_floating_ip             = true
  idle_timeout_in_minutes        = 30
}
resource "azurerm_private_dns_a_record" "db" {
  provider            = azurerm.deployer
  count               = local.enable_db_lb_deployment && length(local.dns_label) > 0 ? 1 : 0
  name                = lower(format("%sdb%scl", local.hdb_sid, local.hdb_nr))
  resource_group_name = local.dns_resource_group_name
  zone_name           = local.dns_label
  ttl                 = 300
  records             = [try(azurerm_lb.hdb[0].frontend_ip_configuration[0].private_ip_address, "")]
}

