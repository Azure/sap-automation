
# Create the Linux App Service Plan
resource "azurerm_service_plan" "appserviceplan" {
  count               = var.use_webapp ? 1 : 0
  name                = lower(format("%s%s%s", local.prefix, local.resource_suffixes.app_service_plan, substr(random_id.deployer.hex, 0, 3)))
  resource_group_name = local.rg_name
  location            = local.rg_appservice_location
  os_type             = "Windows"
  sku_name            = "S1"
}


# Create the app service with AD authentication and storage account connection string
resource "azurerm_windows_web_app" "webapp" {
  count               = var.use_webapp ? (var.configure ? 1 : 0) : 0
  name                = lower(format("%s%s%s", local.prefix, local.resource_suffixes.webapp_url, substr(random_id.deployer.hex, 0, 3)))
  resource_group_name = local.rg_name
  location            = local.rg_appservice_location
  service_plan_id     = azurerm_service_plan.appserviceplan[0].id

  auth_settings {
    enabled = true
    issuer  = "https://sts.windows.net/${data.azurerm_client_config.deployer.tenant_id}/v2.0"
    default_provider = "AzureActiveDirectory"
    active_directory {
      client_id     = var.app_registration_app_id
      client_secret = var.webapp_client_secret
    }
    unauthenticated_client_action = "RedirectToLoginPage"
  }

  site_config {
    # ip_restriction = [{
    #   action                    = "Allow"
    #   name                      = "Allow subnet access"
    #   virtual_network_subnet_id = azurerm_subnet.subnet_mgmt[0].id
    #   priority                  = 1
    #   headers                   = []
    #   ip_address                = null
    #   service_tag               = null
    # }]
    # scm_use_main_ip_restriction = true
  }

  identity {
    type = "SystemAssigned"
  }
  connection_string {
    name  = "sa_tfstate_conn_str"
    type  = "Custom"
    value = var.sa_connection_string
  }
}

# Set up Vnet integration for webapp and storage account interaction
resource "azurerm_app_service_virtual_network_swift_connection" "webapp_vnet_connection" {
  count          = var.use_webapp ? (var.configure ? 1 : 0) : 0
  app_service_id = azurerm_windows_web_app.webapp[0].id
  subnet_id      = local.management_subnet_exists ? data.azurerm_subnet.subnet_mgmt[0].id : azurerm_subnet.subnet_mgmt[0].id
}
