resource "azurerm_private_dns_a_record" "app_secondary" {
  provider            = azurerm.dnsmanagement
  count               = var.dns_a_records_for_secondary_names && var.use_secondary_ips && !var.use_custom_dns_a_registration && length(var.dns) > 0 ? var.app_server_count : 0
  name                = var.naming.virtualmachine_names.APP_SECONDARY_DNSNAME[count.index]
  zone_name           = var.dns
  resource_group_name = var.management_dns_resourcegroup_name
  ttl                 = 3600
  records             = [try(var.application_server_secondary_ips[count.index], "")]


  lifecycle {
    ignore_changes = [tags]
  }
}

resource "azurerm_private_dns_a_record" "scs_secondary" {
  provider            = azurerm.dnsmanagement
  count               = var.dns_a_records_for_secondary_names && var.use_secondary_ips && !var.use_custom_dns_a_registration && length(var.dns) > 0 ? var.scs_server_count : 0
  name                = var.naming.virtualmachine_names.SCS_SECONDARY_DNSNAME[count.index]
  zone_name           = var.dns
  resource_group_name = var.management_dns_resourcegroup_name
  ttl                 = 3600
  records             = [try(var.scs_server_secondary_ips[count.index], "")]


  lifecycle {
    ignore_changes = [tags]
  }
}

resource "azurerm_private_dns_a_record" "web_secondary" {
  provider            = azurerm.dnsmanagement
  count               = var.dns_a_records_for_secondary_names && var.use_secondary_ips && !var.use_custom_dns_a_registration && length(var.dns) > 0 ? var.web_server_count : 0
  name                = var.naming.virtualmachine_names.WEB_SECONDARY_DNSNAME[count.index]
  zone_name           = var.dns
  resource_group_name = var.management_dns_resourcegroup_name
  ttl                 = 3600
  records             = [try(var.webdispatcher_server_secondary_ips[count.index], "")]


  lifecycle {
    ignore_changes = [tags]
  }
}

resource "azurerm_private_dns_a_record" "db_secondary" {
  provider            = azurerm.dnsmanagement
  count               = var.dns_a_records_for_secondary_names && var.use_secondary_ips && !var.use_custom_dns_a_registration && length(var.dns) > 0 ? var.db_server_count : 0
  name                = local.db_secondary_dns_names[count.index]
  zone_name           = var.dns
  resource_group_name = var.management_dns_resourcegroup_name
  ttl                 = 3600
  records             = [try(var.database_server_secondary_ips[count.index], "")]


  lifecycle {
    ignore_changes = [tags]
  }
}
