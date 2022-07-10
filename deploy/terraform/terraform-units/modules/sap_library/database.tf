resource "azurerm_cosmosdb_account" "cmdb" {
    count = var.use_webapp ? 1 : 0
    name = lower(format("%s%s%s", local.prefix, var.naming.resource_suffixes.cosmos_account, substr(random_id.post_fix.hex, 0, 3)))
    location = local.resource_group_library_location
    resource_group_name = local.resource_group_name
    offer_type = "Standard"
    kind = "MongoDB"

    # Allow access from virtual network
    is_virtual_network_filter_enabled = true

    virtual_network_rule {
      id = try(var.deployer_tfstate.subnet_mgmt_id, "")
    }

    virtual_network_rule {
      id = try(var.deployer_tfstate.subnet_cmdb_id, "")
    }

    # Allow access from Azure portal
    ip_range_filter = "51.4.229.218,139.217.8.252,52.244.48.71,104.42.195.92,40.76.54.131,52.176.6.30,52.169.50.45,52.187.184.26"

    capabilities {
        name = "EnableMongo"
    }

    consistency_policy {
        consistency_level = "Session"
    }

    geo_location {
        location = local.resource_group_library_location
        failover_priority = 0
    }
}

resource "azurerm_cosmosdb_mongo_database" "mgdb" {
    count = var.use_webapp ? 1 : 0
    name = format("%s%s", lower(local.prefix), var.naming.resource_suffixes.deployment_objects)
    resource_group_name = local.resource_group_name
    account_name = azurerm_cosmosdb_account.cmdb[0].name
}
