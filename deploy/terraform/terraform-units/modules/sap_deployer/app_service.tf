# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

#######################################4#######################################8
#                                                                              #
#              Web App subnet - Check if locally provided                      #
#                                                                              #
#######################################4#######################################8

resource "azurerm_subnet" "webapp" {
  depends_on                                    = [
                                                    azurerm_subnet.subnet_mgmt
                                                  ]

  count                                         = var.app_service.use ? var.infrastructure.virtual_network.management.subnet_webapp.exists ? 0 : 1 : 0
  name                                          = local.webapp_subnet_name
  resource_group_name                           = var.infrastructure.virtual_network.management.exists ? (
                                                    data.azurerm_virtual_network.vnet_mgmt[0].resource_group_name) : (
                                                    azurerm_virtual_network.vnet_mgmt[0].resource_group_name
                                                  )
  virtual_network_name                          = var.infrastructure.virtual_network.management.exists ? (
                                                    data.azurerm_virtual_network.vnet_mgmt[0].name) : (
                                                    azurerm_virtual_network.vnet_mgmt[0].name
                                                  )

  address_prefixes                              = [var.infrastructure.virtual_network.management.subnet_webapp.prefix]

  private_endpoint_network_policies             = var.use_private_endpoint ? "Enabled" : "Disabled"

  service_endpoints                             = var.use_service_endpoint ? (
                                                    var.app_service.use ? (
                                                      ["Microsoft.Storage", "Microsoft.KeyVault", "Microsoft.Web"]) : (
                                                      ["Microsoft.Storage", "Microsoft.KeyVault"]
                                                    )) : (
                                                    null
                                                  )

  dynamic "delegation" {
                        for_each = range(var.app_service.use ? 1 : 0)
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
  count                                         = var.app_service.use ? var.infrastructure.virtual_network.management.subnet_webapp.exists ? 1 : 0 : 0
  name                                          = split("/", var.infrastructure.virtual_network.management.subnet_webapp.id)[10]
  resource_group_name                           = split("/", var.infrastructure.virtual_network.management.subnet_webapp.id)[4]
  virtual_network_name                          = split("/", var.infrastructure.virtual_network.management.subnet_webapp.id)[8]
}



# Create the Windows App Service Plan
resource "azurerm_service_plan" "appserviceplan" {
  count                                         = var.app_service.use ? 1 : 0
  name                                          = lower(format("%s%s%s%s",
                                                    var.naming.resource_prefixes.app_service_plan,
                                                    var.naming.prefix.DEPLOYER,
                                                    var.naming.resource_suffixes.app_service_plan,
                                                    coalesce(try(var.infrastructure.custom_random_id, ""), substr(random_id.deployer.hex, 0, 3)))
                                                  )
  resource_group_name                           = var.infrastructure.resource_group.exists ? data.azurerm_resource_group.deployer[0].name : azurerm_resource_group.deployer[0].name
  location                                      = var.infrastructure.resource_group.exists ? data.azurerm_resource_group.deployer[0].location : azurerm_resource_group.deployer[0].location
  os_type                                       = "Windows"
  sku_name                                      = var.deployer.app_service_SKU
  tags                                          = var.infrastructure.tags
}


# Create the app service with AD authentication and storage account connection string
resource "azurerm_windows_web_app" "webapp" {
  count                                          = var.app_service.use ? 1 : 0
  name                                           = lower(format("%s%s%s%s",
                                                    var.naming.resource_prefixes.app_service_plan,
                                                    var.naming.prefix.LIBRARY,
                                                    var.naming.resource_suffixes.webapp_url,
                                                    coalesce(try(var.infrastructure.custom_random_id, ""), substr(random_id.deployer.hex, 0, 3)))
                                                    )
  resource_group_name                            = var.infrastructure.resource_group.exists ? data.azurerm_resource_group.deployer[0].name : azurerm_resource_group.deployer[0].name
  location                                       = var.infrastructure.resource_group.exists ? data.azurerm_resource_group.deployer[0].location : azurerm_resource_group.deployer[0].location
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
    "CollectionUri"                            = var.agent_ado_url
    "IS_PIPELINE_DEPLOYMENT"                   = false
    "ASPNETCORE_ENVIRONMENT"                   = "PRODUCTION"
    "OVERRIDE_USE_MI_FIC_ASSERTION_CLIENTID"   = length(var.deployer.user_assigned_identity_id) > 0 ? data.azurerm_user_assigned_identity.deployer[0].client_id : azurerm_user_assigned_identity.deployer[0].client_id
    "WEBSITE_AUTH_CUSTOM_AUTHORIZATION"        = true
    "WHICH_ENV"                                = length(var.deployer.user_assigned_identity_id) > 0 ? "DATA" : "LOCAL"
    "AZURE_TENANT_ID"                          = data.azurerm_client_config.deployer.tenant_id
    "AUTHENTICATION_TYPE"                      = var.deployer.devops_authentication_type
    "PAT"                                      = var.use_private_endpoint ? (
                                                  format("@Microsoft.KeyVault(SecretUri=https://%s.privatelink.vaultcore.azure.net/secrets/PAT/)", local.keyvault_names.user_access)): (
                                                  format("@Microsoft.KeyVault(SecretUri=https://%s.vault.azure.net/secrets/PAT/)", local.keyvault_names.user_access)
                                                 )
  }

  sticky_settings {
    app_setting_names                          = ["OVERRIDE_USE_MI_FIC_ASSERTION_CLIENTID"]
    connection_string_names                    = ["sa_tfstate_conn_str"]
  }

  auth_settings_v2 {
    auth_enabled                               = true
    unauthenticated_action                     = "RedirectToLoginPage"
    default_provider                           = "AzureActiveDirectory"
    active_directory_v2 {
      client_id                                = var.app_service.app_registration_id
      tenant_auth_endpoint                     = "https://login.microsoftonline.com/${data.azurerm_client_config.deployer.tenant_id}/v2.0"
      www_authentication_disabled              = false
      client_secret_setting_name               = "OVERRIDE_USE_MI_FIC_ASSERTION_CLIENTID"
      allowed_applications                     = [var.app_service.app_registration_id]
      allowed_audiences                        = []
      allowed_groups                           = []
      allowed_identities                       = []
    }
    login {
      token_store_enabled = false
    }
  }



  virtual_network_subnet_id = var.infrastructure.virtual_network.management.subnet_webapp.exists ? data.azurerm_subnet.webapp[0].id : azurerm_subnet.webapp[0].id
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

  identity                                   {
    # type                                        = length(var.deployer.user_assigned_identity_id) == 0 ? (
    #                                                 "SystemAssigned") : (
    #                                                 "SystemAssigned, UserAssigned"
    #                                               )
    # for now set the identity type to "SystemAssigned, UserAssigned" as assigning identities
    # is not supported by the provider when type is "SystemAssigned"
    type                                        = "SystemAssigned, UserAssigned"
    identity_ids                                = [length(var.deployer.user_assigned_identity_id) == 0 ? azurerm_user_assigned_identity.deployer[0].id : data.azurerm_user_assigned_identity.deployer[0].id ]
                                             }
  connection_string                          {
    name                                        = "tfstate"
    type                                        = "Custom"
    value                                       = var.use_private_endpoint ? (
                                                    format("@Microsoft.KeyVault(SecretUri=https://%s.privatelink.vaultcore.azure.net/secrets/tfstate/)", local.user_keyvault_name)) : (
                                                    format("@Microsoft.KeyVault(SecretUri=https://%s.vault.azure.net/secrets/tfstate/)", local.user_keyvault_name)
                                                  )
                                             }

  lifecycle                                  {
    ignore_changes                              = [
                                                    zip_deploy_file,
                                                    tags
                                                  ]
                                             }

}


# Set up Vnet integration for webapp and storage account interaction
resource "azurerm_app_service_virtual_network_swift_connection" "webapp_vnet_connection" {
  count          = var.app_service.use ? 1 : 0
  app_service_id = azurerm_windows_web_app.webapp[0].id
  subnet_id      = var.infrastructure.virtual_network.management.subnet_webapp.exists ? data.azurerm_subnet.webapp[0].id : azurerm_subnet.webapp[0].id
}


# resource "azurerm_role_assignment" "app_service_contributor" {
#   provider             = azurerm.main
#   count                = var.app_service.use && var.deployer.add_system_assigned_identity ? var.deployer_vm_count : 0
#   scope                = azurerm_windows_web_app.webapp[0].id
#   role_definition_name = "Website Contributor"
#   principal_id         = azurerm_linux_virtual_machine.deployer[count.index].identity[0].principal_id
# }

# resource "azurerm_role_assignment" "app_service_contributor_msi" {
#   provider             = azurerm.main
#   count                = var.app_service.use ? 1 : 0
#   scope                = azurerm_windows_web_app.webapp[0].id
#   role_definition_name = "Website Contributor"
#   principal_id         = azurerm_user_assigned_identity.deployer.principal_id
# }
