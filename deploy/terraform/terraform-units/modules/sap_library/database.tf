resource "azurerm_cosmosdb_account" "cmdb" {
    name = "webapp-cmdb-${var.random_int}" # Could be a variable
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
    name = "Deployment-Objects"
    resource_group_name = local.rg_name
    account_name = azurerm_cosmosdb_account.cmdb.name
}
