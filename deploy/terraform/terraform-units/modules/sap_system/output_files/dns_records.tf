resource "azurerm_private_dns_a_record" "app_secondary" {
  count               = var.use_secondary_ips && !var.use_custom_dns_a_registration && length(var.dns) > 0 ? length(var.naming.virtualmachine_names.APP_SECONDARY_DNSNAME) : 0
  name                = var.naming.virtualmachine_names.APP_SECONDARY_DNSNAME[count.index]
  zone_name           = var.dns
  resource_group_name = var.management_dns_resourcegroup_name
  ttl                 = 3600
  records             = [var.application_server_secondary_ips[count.index]]

  provider = azurerm.dnsmanagement

  lifecycle {
    ignore_changes = [tags]
  }
}

resource "azurerm_private_dns_a_record" "scs_secondary" {
  count               = var.use_secondary_ips && !var.use_custom_dns_a_registration && length(var.dns) > 0 ? length(var.naming.virtualmachine_names.SCS_SECONDARY_DNSNAME) : 0
  name                = var.naming.virtualmachine_names.SCS_SECONDARY_DNSNAME[count.index]
  zone_name           = var.dns
  resource_group_name = var.management_dns_resourcegroup_name
  ttl                 = 3600
  records             = [var.scs_server_secondary_ips[count.index]]

  provider = azurerm.dnsmanagement

  lifecycle {
    ignore_changes = [tags]
  }
}

resource "azurerm_private_dns_a_record" "web_secondary" {
  count               = var.use_secondary_ips && !var.use_custom_dns_a_registration && length(var.dns) > 0 ? length(var.naming.virtualmachine_names.WEB_SECONDARY_DNSNAME) : 0
  name                = var.naming.virtualmachine_names.WEB_SECONDARY_DNSNAME[count.index]
  zone_name           = var.dns
  resource_group_name = var.management_dns_resourcegroup_name
  ttl                 = 3600
  records             = [var.webdispatcher_server_secondary_ips[count.index]]

  provider = azurerm.dnsmanagement

  lifecycle {
    ignore_changes = [tags]
  }
}

resource "azurerm_private_dns_a_record" "db_secondary" {
  count               = var.use_secondary_ips && !var.use_custom_dns_a_registration && length(var.dns) > 0 ? length(local.db_secondary_dns_names) : 0
  name                = local.db_secondary_dns_names[count.index]
  zone_name           = var.dns
  resource_group_name = var.management_dns_resourcegroup_name
  ttl                 = 3600
  records             = [var.db_server_secondary_ips[count.index]]

  provider = azurerm.dnsmanagement

  lifecycle {
    ignore_changes = [tags]
  }
}
