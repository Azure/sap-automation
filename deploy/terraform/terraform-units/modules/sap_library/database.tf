resource "azurerm_cosmosdb_account" "cmdb" {
    name = lower(format("%s%s%s", local.prefix, local.resource_suffixes.cosmos_account, substr(random_id.post_fix.hex, 0, 3)))
    location = local.rg_library_location
    resource_group_name = local.rg_name
    offer_type = "standard"
    kind = "MongoDB"

    capabilities {
        name = "EnableMongo"
    }

    consistency_policy {
        consistency_level = "Session"
    }

    geo_location {
        location = local.rg_library_location
        failover_priority = 0
    }
}

resource "azurerm_cosmosdb_mongo_database" "mgdb" {
    name = format("%s%s", lower(local.prefix), local.resource_suffixes.deployment_objects)
    resource_group_name = local.rg_name
    account_name = azurerm_cosmosdb_account.cmdb.name
}
