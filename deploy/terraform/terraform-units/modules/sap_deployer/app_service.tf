resource "azurerm_subnet" "webapp" {
  depends_on = [
    azurerm_subnet.subnet_mgmt
  ]

  count = var.use_webapp ? local.webapp_subnet_exists ? 0 : 1 : 0
  name  = local.webapp_subnet_name
  resource_group_name = local.vnet_mgmt_exists ? (
    data.azurerm_virtual_network.vnet_mgmt[0].resource_group_name) : (
    azurerm_virtual_network.vnet_mgmt[0].resource_group_name
  )
  virtual_network_name = local.vnet_mgmt_exists ? (
    data.azurerm_virtual_network.vnet_mgmt[0].name) : (
    azurerm_virtual_network.vnet_mgmt[0].name
  )
  address_prefixes = [local.webapp_subnet_prefix]

  private_endpoint_network_policies_enabled     = var.use_private_endpoint
  private_link_service_network_policies_enabled = false

  service_endpoints = var.use_service_endpoint ? (
    var.use_webapp ? (
      ["Microsoft.Storage", "Microsoft.KeyVault", "Microsoft.Web"]) : (
      ["Microsoft.Storage", "Microsoft.KeyVault"]
    )) : (
    null
  )

  dynamic "delegation" {
    for_each = range(var.use_webapp ? 1 : 0)
    content {
      name = "delegation"
      service_delegation {
        actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
        name    = "Microsoft.Web/serverFarms"
      }
    }
  }

}

data "azurerm_subnet" "webapp" {
  count                = var.use_webapp ? local.webapp_subnet_exists ? 1 : 0 : 0
  name                 = split("/", local.webapp_subnet_arm_id)[10]
  resource_group_name  = split("/", local.webapp_subnet_arm_id)[4]
  virtual_network_name = split("/", local.webapp_subnet_arm_id)[8]
}



# Create the Windows App Service Plan
resource "azurerm_service_plan" "appserviceplan" {
  count               = var.use_webapp ? 1 : 0
  name                = lower(format("%s%s%s%s", var.naming.resource_prefixes.app_service_plan, var.naming.prefix.LIBRARY, var.naming.resource_suffixes.app_service_plan, substr(random_id.deployer.hex, 0, 3)))
  resource_group_name = local.rg_name
  location            = local.rg_appservice_location
  os_type             = "Windows"
  sku_name            = "S1"
}


# Create the app service with AD authentication and storage account connection string
resource "azurerm_windows_web_app" "webapp" {
  count               = var.use_webapp ? 1 : 0
  name                = lower(format("%s%s%s%s", var.naming.resource_prefixes.app_service_plan, var.naming.prefix.LIBRARY, var.naming.resource_suffixes.webapp_url, substr(random_id.deployer.hex, 0, 3)))
  resource_group_name = local.rg_name
  location            = local.rg_appservice_location
  service_plan_id     = azurerm_service_plan.appserviceplan[0].id

  auth_settings {
    enabled          = true
    issuer           = "https://sts.windows.net/${data.azurerm_client_config.deployer.tenant_id}/v2.0"
    default_provider = "AzureActiveDirectory"
    active_directory {
      client_id     = var.app_registration_app_id
      client_secret = var.webapp_client_secret
    }
    unauthenticated_client_action = "RedirectToLoginPage"
  }

  app_settings = {
    "PAT"                    = format("@Microsoft.KeyVault(SecretUri=https://%s.vault.azure.net/secrets/PAT/)", local.keyvault_names.user_access)
    "CollectionUri"          = var.agent_ado_url
    "IS_PIPELINE_DEPLOYMENT" = false
  }

  virtual_network_subnet_id = local.webapp_subnet_exists ? data.azurerm_subnet.webapp[0].id : azurerm_subnet.webapp[0].id
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
    value = format("@Microsoft.KeyVault(SecretUri=https://%s.vault.azure.net/secrets/sa-connection-string/)", local.user_keyvault_name)
  }

  lifecycle {
    ignore_changes = [
      app_settings,
      zip_deploy_file,
      tags
    ]
  }

}


# Set up Vnet integration for webapp and storage account interaction
resource "azurerm_app_service_virtual_network_swift_connection" "webapp_vnet_connection" {
  count          = var.use_webapp ? 1 : 0
  app_service_id = azurerm_windows_web_app.webapp[0].id
  subnet_id      = local.webapp_subnet_exists ? data.azurerm_subnet.webapp[0].id : azurerm_subnet.webapp[0].id
}
