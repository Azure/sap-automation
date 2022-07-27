
# Create the Linux App Service Plan
resource "azurerm_service_plan" "appserviceplan" {
  count               = var.use_webapp ? 1 : 0
  name                = lower(format("%s%s%s", local.prefix, local.resource_suffixes.app_service_plan, substr(random_id.deployer.hex, 0, 3)))
  resource_group_name = local.rg_name
  location            = local.rg_appservice_location
  os_type             = "Windows"
  sku_name            = "S1"
}


# Create the app service with AD authentication and CMDB connection string
resource "azurerm_windows_web_app" "webapp" {
  count               = var.use_webapp ? (var.configure ? 1 : 0) : 0
  name                = lower(format("%s%s%s", local.prefix, local.resource_suffixes.webapp_url, substr(random_id.deployer.hex, 0, 3)))
  resource_group_name = local.rg_name
  location            = local.rg_appservice_location
  service_plan_id     = azurerm_service_plan.appserviceplan[0].id

  auth_settings {
    enabled = true
    issuer  = "https://sts.windows.net/${data.azurerm_client_config.deployer.tenant_id}/v2.0"
    active_directory {
      client_id     = var.app_registration_app_id
      client_secret = var.webapp_client_secret
    }
  }

  site_config {
    ip_restriction = [{
      action                    = "Allow"
      name                      = "Allow subnet access"
      virtual_network_subnet_id = azurerm_subnet.subnet_mgmt[0].id
      priority                  = 1
      headers                   = []
      ip_address                = null
      service_tag               = null
    }]
    scm_use_main_ip_restriction = true
  }

  connection_string {
    name  = "CMDB"
    type  = "Custom"
    value = var.cmdb_connection_string
  }
}

// Create/Import cmdb subnet
resource "azurerm_subnet" "cmdb" {
  count                = var.use_webapp && !local.cmdb_subnet_exists ? 1 : 0
  name                 = local.cmdb_subnet_name
  resource_group_name  = local.vnet_mgmt_exists ? data.azurerm_virtual_network.vnet_mgmt[0].resource_group_name : azurerm_virtual_network.vnet_mgmt[0].resource_group_name
  virtual_network_name = local.vnet_mgmt_exists ? data.azurerm_virtual_network.vnet_mgmt[0].name : azurerm_virtual_network.vnet_mgmt[0].name
  address_prefixes     = [local.cmdb_subnet_prefix]

  delegation {
    name = "webapp-delegation"

    service_delegation {
      name    = "Microsoft.Web/serverFarms"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }

  service_endpoints = ["Microsoft.Storage", "Microsoft.KeyVault", "Microsoft.Web", "Microsoft.AzureCosmosDB"]
}

data "azurerm_subnet" "cmdb" {
  count                = var.use_webapp && local.cmdb_subnet_exists ? 1 : 0
  name                 = split("/", local.cmdb_subnet_arm_id)[10]
  resource_group_name  = split("/", local.cmdb_subnet_arm_id)[4]
  virtual_network_name = split("/", local.cmdb_subnet_arm_id)[8]
}

# Set up Vnet integration for webapp and cmdb interaction
resource "azurerm_app_service_virtual_network_swift_connection" "webapp_vnet_connection" {
  count          = var.use_webapp ? (var.configure ? 1 : 0) : 0
  app_service_id = azurerm_windows_web_app.webapp[0].id
  subnet_id      = local.cmdb_subnet_exists ? data.azurerm_subnet.cmdb[0].id : azurerm_subnet.cmdb[0].id
}
