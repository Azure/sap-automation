#######################################4#######################################8
#                                                                              #
#              Web App subnet - Check if locally provided                      #
#                                                                              #
#######################################4#######################################8

resource "azurerm_subnet" "webapp" {
  depends_on                                    = [
                                                    azurerm_subnet.subnet_mgmt
                                                  ]

  count                                         = var.use_webapp ? local.webapp_subnet_exists ? 0 : 1 : 0
  name                                          = local.webapp_subnet_name
  resource_group_name                           = local.vnet_mgmt_exists ? (
                                                    data.azurerm_virtual_network.vnet_mgmt[0].resource_group_name) : (
                                                    azurerm_virtual_network.vnet_mgmt[0].resource_group_name
                                                  )
  virtual_network_name                          = local.vnet_mgmt_exists ? (
                                                    data.azurerm_virtual_network.vnet_mgmt[0].name) : (
                                                    azurerm_virtual_network.vnet_mgmt[0].name
                                                  )

  address_prefixes                              = [local.webapp_subnet_prefix]

  private_endpoint_network_policies_enabled     = var.use_private_endpoint

  service_endpoints                             = var.use_service_endpoint ? (
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
  count                                         = var.use_webapp ? local.webapp_subnet_exists ? 1 : 0 : 0
  name                                          = split("/", local.webapp_subnet_arm_id)[10]
  resource_group_name                           = split("/", local.webapp_subnet_arm_id)[4]
  virtual_network_name                          = split("/", local.webapp_subnet_arm_id)[8]
}



# Create the Windows App Service Plan
resource "azurerm_service_plan" "appserviceplan" {
  count                                         = var.use_webapp ? 1 : 0
  name                                          = lower(format("%s%s%s%s", var.naming.resource_prefixes.app_service_plan, var.naming.prefix.LIBRARY, var.naming.resource_suffixes.app_service_plan, substr(random_id.deployer.hex, 0, 3)))
  resource_group_name                           = local.resourcegroup_name
  location                                      = local.rg_appservice_location
  os_type                                       = "Windows"
  sku_name                                      = var.deployer.app_service_SKU
}


# Create the app service with AD authentication and storage account connection string
resource "azurerm_windows_web_app" "webapp" {
  count                                          = var.use_webapp ? 1 : 0
  name                                           = lower(format("%s%s%s%s", var.naming.resource_prefixes.app_service_plan, var.naming.prefix.LIBRARY, var.naming.resource_suffixes.webapp_url, substr(random_id.deployer.hex, 0, 3)))
  resource_group_name                            = local.resourcegroup_name
  location                                       = local.rg_appservice_location
  service_plan_id                                = azurerm_service_plan.appserviceplan[0].id
  https_only                                     = true
  webdeploy_publish_basic_authentication_enabled = false
  ftp_publish_basic_authentication_enabled       = false

  # auth_settings {
  #   enabled          = true
  #   issuer           = "https://sts.windows.net/${data.azurerm_client_config.deployer.tenant_id}/v2.0"
  #   default_provider = "AzureActiveDirectory"
  #   active_directory {
  #     client_id     = var.app_registration_app_id
  #     client_secret = var.webapp_client_secret
  #   }
  #   unauthenticated_client_action = "RedirectToLoginPage"
  # }

  app_settings = {
    "PAT"                                      = var.use_private_endpoint ? format("@Microsoft.KeyVault(SecretUri=https://%s.privatelink.vaultcore.azure.net/secrets/PAT/)", local.keyvault_names.user_access) : format("@Microsoft.KeyVault(SecretUri=https://%s.vault.azure.net/secrets/PAT/)", local.keyvault_names.user_access)
    "CollectionUri"                            = var.agent_ado_url
    "IS_PIPELINE_DEPLOYMENT"                   = false
    "MICROSOFT_PROVIDER_AUTHENTICATION_SECRET" = var.use_private_endpoint ? format("@Microsoft.KeyVault(SecretUri=https://%s.privatelink.vaultcore.azure.net/secrets/WEB-PWD/)", local.keyvault_names.user_access) : format("@Microsoft.KeyVault(SecretUri=https://%s.vault.azure.net/secrets/WEB-PWD/)", local.keyvault_names.user_access)
    "WEBSITE_AUTH_CUSTOM_AUTHORIZATION"        = true
  }

  sticky_settings {
    app_setting_names                          = ["MICROSOFT_PROVIDER_AUTHENTICATION_SECRET"]
    connection_string_names                    = ["sa_tfstate_conn_str"]
  }

  auth_settings_v2 {
    auth_enabled                               = true
    unauthenticated_action                     = "RedirectToLoginPage"
    default_provider                           = "AzureActiveDirectory"
    active_directory_v2 {
      client_id                                = var.app_registration_app_id
      tenant_auth_endpoint                     = "https://sts.windows.net/${data.azurerm_client_config.deployer.tenant_id}/v2.0"
      www_authentication_disabled              = false
      client_secret_setting_name               = "MICROSOFT_PROVIDER_AUTHENTICATION_SECRET"
      allowed_applications                     = [var.app_registration_app_id]
      allowed_audiences                        = []
      allowed_groups                           = []
      allowed_identities                       = []
    }
    login {
      token_store_enabled = false
    }
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

  key_vault_reference_identity_id = length(var.deployer.user_assigned_identity_id) == 0 ? azurerm_user_assigned_identity.deployer[0].id : data.azurerm_user_assigned_identity.deployer[0].id

  identity {
    type         = "SystemAssigned, UserAssigned"
    identity_ids = [length(var.deployer.user_assigned_identity_id) == 0 ? azurerm_user_assigned_identity.deployer[0].id : data.azurerm_user_assigned_identity.deployer[0].id ]
  }
  connection_string {
    name  = "tfstate"
    type  = "Custom"
    value = var.use_private_endpoint ? format("@Microsoft.KeyVault(SecretUri=https://%s.privatelink.vaultcore.azure.net/secrets/tfstate/)", local.user_keyvault_name) : format("@Microsoft.KeyVault(SecretUri=https://%s.vault.azure.net/secrets/tfstate/)", local.user_keyvault_name)
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


# resource "azurerm_role_assignment" "app_service_contributor" {
#   provider             = azurerm.main
#   count                = var.use_webapp && var.deployer.add_system_assigned_identity ? var.deployer_vm_count : 0
#   scope                = azurerm_windows_web_app.webapp[0].id
#   role_definition_name = "Website Contributor"
#   principal_id         = azurerm_linux_virtual_machine.deployer[count.index].identity[0].principal_id
# }

# resource "azurerm_role_assignment" "app_service_contributor_msi" {
#   provider             = azurerm.main
#   count                = var.use_webapp ? 1 : 0
#   scope                = azurerm_windows_web_app.webapp[0].id
#   role_definition_name = "Website Contributor"
#   principal_id         = azurerm_user_assigned_identity.deployer.principal_id
# }
