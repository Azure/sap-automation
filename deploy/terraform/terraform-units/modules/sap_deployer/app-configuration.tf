# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

#######################################4#######################################8
#                                                                              #
#                          Azure App Configuration                             #
#                                                                              #
#######################################4#######################################8


resource "azurerm_app_configuration" "app_config" {
  provider                              = azurerm.main
  count                                 = var.app_config_service.deploy ? length(var.app_config_service.id) > 0 ? 0 : 1 : 0
  name                                  = local.app_config_name
  resource_group_name                   = var.infrastructure.resource_group.exists ? (
                                            data.azurerm_resource_group.deployer[0].name) : (
                                            azurerm_resource_group.deployer[0].name
                                          )
  location                              = var.infrastructure.resource_group.exists ? (
                                            data.azurerm_resource_group.deployer[0].location) : (
                                            azurerm_resource_group.deployer[0].location
                                          )
  local_auth_enabled                   = false
  data_plane_proxy_authentication_mode = "Pass-through"
  purge_protection_enabled             = var.enable_purge_control_for_keyvaults

  sku                                  = "standard"
  tags                                 = var.infrastructure.tags
}

data "azurerm_app_configuration" "app_config" {
  provider                             = azurerm.main
  count                                = var.app_config_service.deploy ? length(var.app_config_service.id) > 0 ? 1 : 0 : 0
  name                                 = local.app_config_name
  resource_group_name                  = local.app_config_resource_group_name
}


resource "time_sleep" "wait_for_appconfig_data_owner_assignment" {
  create_duration                      = "60s"
  count                                = var.app_config_service.deploy ? 1 : 0
  triggers                             = {
                                           role_assignment = try(azurerm_role_assignment.appconfig_data_owner_msi[0].id, "")
                                         }

}

resource "time_sleep" "wait_for_appconfig_private_endpoint" {
  create_duration                      = "60s"
  count                                = var.app_config_service.deploy ? 1 : 0

  triggers                           = {
                                           endpoint = try(azurerm_private_endpoint.app_config[0].id, "")
                                       }

}
resource "azurerm_app_configuration_key" "deployer_state_file_name" {
  provider                             = azurerm.main
  count                                = var.app_config_service.deploy ? 1 : 0
  depends_on                           = [
                                            time_sleep.wait_for_appconfig_data_owner_assignment,
                                            time_sleep.wait_for_appconfig_private_endpoint
                                         ]

  configuration_store_id               = length(var.app_config_service.id) == 0 ? azurerm_app_configuration.app_config[0].id : data.azurerm_app_configuration.app_config[0].id

  key                                  = format("%s_StateFileName", var.app_config_service.control_plane_name)
  label                                = var.app_config_service.control_plane_name
  value                                = format("%s-INFRASTRUCTURE.terraform.tfstate",var.app_config_service.control_plane_name)
  content_type                         = "text/plain"
  type                                 = "kv"
  tags                                 = merge(var.infrastructure.tags, {
                                           "source" = "Deployer"
                                         })

  timeouts                             {
                                          read = "2m"
                                          create = "5m"
                                          update = "5m"

                                       }
  lifecycle {
              ignore_changes = [
                configuration_store_id,
                etag,
                id
              ]
            }
}

resource "azurerm_app_configuration_key" "deployer_keyvault_name" {
  provider                             = azurerm.main
  count                                = var.app_config_service.deploy ? 1 : 0
  depends_on                           = [
                                            time_sleep.wait_for_appconfig_data_owner_assignment,
                                            time_sleep.wait_for_appconfig_private_endpoint
                                         ]

  configuration_store_id               = length(var.app_config_service.id) == 0 ? azurerm_app_configuration.app_config[0].id : data.azurerm_app_configuration.app_config[0].id

  key                                  = format("%s_KeyVaultName", var.app_config_service.control_plane_name)
  label                                = var.app_config_service.control_plane_name
  value                                = var.key_vault.exists ? data.azurerm_key_vault.kv_user[0].name : azurerm_key_vault.kv_user[0].name
  content_type                         = "text/plain"
  type                                 = "kv"
  tags                                 = merge(var.infrastructure.tags, {
                                           "source" = "Deployer"
                                         })
  timeouts                             {
                                          read = "2m"
                                          create = "5m"
                                          update = "5m"

                                       }
  lifecycle {
              ignore_changes = [
                configuration_store_id,
                etag,
                id
              ]
            }

}

resource "azurerm_app_configuration_key" "deployer_keyvault_id" {
  provider                             = azurerm.main
  count                                = var.app_config_service.deploy ? 1 : 0
  depends_on                           = [
                                            time_sleep.wait_for_appconfig_data_owner_assignment,
                                            time_sleep.wait_for_appconfig_private_endpoint
                                         ]

  configuration_store_id               = length(var.app_config_service.id) == 0 ? azurerm_app_configuration.app_config[0].id : data.azurerm_app_configuration.app_config[0].id
  key                                  = format("%s_KeyVaultResourceId", var.app_config_service.control_plane_name)
  label                                = var.app_config_service.control_plane_name
  value                                = var.key_vault.exists ? data.azurerm_key_vault.kv_user[0].id : azurerm_key_vault.kv_user[0].id
  content_type                         = "text/id"
  type                                 = "kv"
  tags                                 = merge(var.infrastructure.tags, {
                                           "source" = "Deployer"
                                         })
  timeouts                             {
                                          create = "5m"
                                          update = "5m"
                                       }
  lifecycle {
              ignore_changes = [
                configuration_store_id,
                etag,
                id
              ]
            }

}

resource "azurerm_app_configuration_key" "deployer_resourcegroup_name" {
  provider                             = azurerm.main
  count                                = var.app_config_service.deploy ? 1 : 0
  depends_on                           = [
                                            time_sleep.wait_for_appconfig_data_owner_assignment,
                                            time_sleep.wait_for_appconfig_private_endpoint
                                         ]

  configuration_store_id               = length(var.app_config_service.id) == 0 ? azurerm_app_configuration.app_config[0].id : data.azurerm_app_configuration.app_config[0].id
  key                                  = format("%s_ResourceGroupName", var.app_config_service.control_plane_name)
  label                                = var.app_config_service.control_plane_name
  value                                = local.resourcegroup_name
  content_type                         = "text/plain"
  type                                 = "kv"
  tags                                 = merge(var.infrastructure.tags, {
                                           "source" = "Deployer"
                                         })
  timeouts                             {
                                          create = "5m"
                                          update = "5m"
                                       }
  lifecycle {
              ignore_changes = [
                configuration_store_id,
                etag,
                id
              ]
            }
}

resource "azurerm_app_configuration_key" "deployer_subscription_id" {
  provider                             = azurerm.main
  count                                = var.app_config_service.deploy ? 1 : 0
  depends_on                           = [
                                            time_sleep.wait_for_appconfig_data_owner_assignment,
                                            time_sleep.wait_for_appconfig_private_endpoint
                                         ]

  configuration_store_id               = length(var.app_config_service.id) == 0 ? azurerm_app_configuration.app_config[0].id : data.azurerm_app_configuration.app_config[0].id
  key                                  = format("%s_SubscriptionId", var.app_config_service.control_plane_name)
  label                                = var.app_config_service.control_plane_name
  value                                = data.azurerm_subscription.primary.subscription_id
  content_type                         = "text/id"
  type                                 = "kv"
  tags                                 = merge(var.infrastructure.tags, {
                                           "source" = "Deployer"
                                         })
  timeouts                             {
                                          create = "5m"
                                          update = "5m"
                                       }
  lifecycle {
              ignore_changes = [
                configuration_store_id,
                etag,
                id
              ]
            }
}

resource "azurerm_app_configuration_key" "web_application_resource_id" {
  provider                             = azurerm.main
  count                                = var.app_config_service.deploy && var.app_service.use ? 1 :0
  depends_on                           = [
                                            time_sleep.wait_for_appconfig_data_owner_assignment,
                                            time_sleep.wait_for_appconfig_private_endpoint
                                         ]

  configuration_store_id               = length(var.app_config_service.id) == 0 ? azurerm_app_configuration.app_config[0].id : data.azurerm_app_configuration.app_config[0].id
  key                                  = format("%s_AppServiceId", var.app_config_service.control_plane_name)
  label                                = var.app_config_service.control_plane_name
  value                                = try(azurerm_windows_web_app.webapp[0].id, "")
  content_type                         = "text/id"
  type                                 = "kv"
  tags                                 = merge(var.infrastructure.tags, {
                                           "source" = "Deployer"
                                         })
  timeouts                             {
                                          create = "5m"
                                          update = "5m"
                                       }
  lifecycle {
              ignore_changes = [
                configuration_store_id,
                etag,
                id
              ]
            }
}

resource "azurerm_app_configuration_key" "web_application_identity_id" {
  provider                             = azurerm.main
  count                                = var.app_config_service.deploy && var.app_service.use ? 1 :0
  depends_on                           = [
                                            time_sleep.wait_for_appconfig_data_owner_assignment,
                                            time_sleep.wait_for_appconfig_private_endpoint
                                         ]

  configuration_store_id               = length(var.app_config_service.id) == 0 ? azurerm_app_configuration.app_config[0].id : data.azurerm_app_configuration.app_config[0].id
  key                                  = format("%s_AppServiceIdentityId", var.app_config_service.control_plane_name)
  label                                = var.app_config_service.control_plane_name
  value                                = try(azurerm_windows_web_app.webapp[0].identity[0].principal_id, "")
  content_type                         = "text/id"
  type                                 = "kv"
  tags                                 = merge(var.infrastructure.tags, {
                                           "source" = "Deployer"
                                         })
  timeouts                             {
                                          create = "5m"
                                          update = "5m"
                                       }
  lifecycle {
              ignore_changes = [
                configuration_store_id,
                etag,
                id
              ]
            }
}


resource "azurerm_app_configuration_key" "deployer_msi_id" {
  provider                             = azurerm.main
  count                                = var.app_config_service.deploy ? 1 : 0
  depends_on                           = [
                                            time_sleep.wait_for_appconfig_data_owner_assignment,
                                            time_sleep.wait_for_appconfig_private_endpoint
                                         ]

  configuration_store_id               = length(var.app_config_service.id) == 0 ? azurerm_app_configuration.app_config[0].id : data.azurerm_app_configuration.app_config[0].id
  key                                  = format("%s_Deployer_MSI_id", var.app_config_service.control_plane_name)
  label                                = var.app_config_service.control_plane_name
  value                                = length(var.deployer.user_assigned_identity_id) == 0 ? azurerm_user_assigned_identity.deployer[0].principal_id : data.azurerm_user_assigned_identity.deployer[0].principal_id
  content_type                         = "text/id"
  type                                 = "kv"
  tags                                 = merge(var.infrastructure.tags, {
                                           "source" = "Deployer"
                                         })
  timeouts                             {
                                          create = "5m"
                                          update = "5m"
                                       }
  lifecycle {
              ignore_changes = [
                configuration_store_id,
                etag,
                id
              ]
            }
}

resource "azurerm_app_configuration_key" "deployer_network_id" {
  provider                             = azurerm.main
  count                                = var.app_config_service.deploy ? 1 : 0
  depends_on                           = [
                                            time_sleep.wait_for_appconfig_data_owner_assignment,
                                            time_sleep.wait_for_appconfig_private_endpoint
                                         ]

  configuration_store_id               = length(var.app_config_service.id) == 0 ? azurerm_app_configuration.app_config[0].id : data.azurerm_app_configuration.app_config[0].id
  key                                  = format("%s_Deployer_network_id", var.app_config_service.control_plane_name)
  label                                = var.app_config_service.control_plane_name
  value                                = var.infrastructure.virtual_network.management.exists ? data.azurerm_virtual_network.vnet_mgmt[0].id : azurerm_virtual_network.vnet_mgmt[0].id
  content_type                         = "text/id"
  type                                 = "kv"
  tags                                 = merge(var.infrastructure.tags, {
                                           "source" = "Deployer"
                                         })
  timeouts                             {
                                          create = "5m"
                                          update = "5m"
                                       }
  lifecycle {
              ignore_changes = [
                configuration_store_id,
                etag,
                id
              ]
            }
}

resource "azurerm_app_configuration_key" "deployer_subnet_id" {
  provider                             = azurerm.main
  count                                = var.app_config_service.deploy ? 1 : 0
  depends_on                           = [
                                            time_sleep.wait_for_appconfig_data_owner_assignment,
                                            time_sleep.wait_for_appconfig_private_endpoint
                                         ]

  configuration_store_id               = length(var.app_config_service.id) == 0 ? azurerm_app_configuration.app_config[0].id : data.azurerm_app_configuration.app_config[0].id
  key                                  = format("%s_Deployer_subnet_id", var.app_config_service.control_plane_name)
  label                                = var.app_config_service.control_plane_name
  value                                = var.infrastructure.virtual_network.management.subnet_mgmt.exists ? data.azurerm_subnet.subnet_mgmt[0].id : azurerm_subnet.subnet_mgmt[0].id
  content_type                         = "text/id"
  type                                 = "kv"
  tags                                 = merge(var.infrastructure.tags, {
                                           "source" = "Deployer"
                                         })
  timeouts                             {
                                          create = "5m"
                                          update = "5m"
                                       }
  lifecycle {
              ignore_changes = [
                configuration_store_id,
                etag,
                id
              ]
            }
}

resource "azurerm_private_endpoint" "app_config" {
  provider                             = azurerm.main
  count                                = var.bootstrap ? 0 : (var.use_private_endpoint && var.app_config_service.deploy ? 1 : 0)
  name                                 = format("%s%s%s",
                                          var.naming.resource_prefixes.appconfig_private_link,
                                          local.prefix,
                                          var.naming.resource_suffixes.appconfig_private_link
                                        )
  resource_group_name                  = var.infrastructure.resource_group.exists ? (
                                           data.azurerm_resource_group.deployer[0].name) : (
                                           azurerm_resource_group.deployer[0].name
                                         )
  location                             = var.infrastructure.resource_group.exists ? (
                                           data.azurerm_resource_group.deployer[0].location) : (
                                           azurerm_resource_group.deployer[0].location
                                         )
  subnet_id                            = var.infrastructure.virtual_network.management.subnet_mgmt.exists ? (
                                           data.azurerm_subnet.subnet_mgmt[0].id) : (
                                           azurerm_subnet.subnet_mgmt[0].id
                                                                          )
  custom_network_interface_name        = format("%s%s%s%s",
                                           var.naming.resource_prefixes.appconfig_private_link,
                                           local.prefix,
                                           var.naming.resource_suffixes.appconfig_private_link,
                                           var.naming.resource_suffixes.nic
                                         )

  private_service_connection {
                               name                           = format("%s%s%s",
                                                                  var.naming.resource_prefixes.appconfig_private_svc,
                                                                  local.prefix,
                                                                  var.naming.resource_suffixes.appconfig_private_svc
                                                                )
                               is_manual_connection           = false
                               private_connection_resource_id = length(var.app_config_service.id) == 0 ? azurerm_app_configuration.app_config[0].id : data.azurerm_app_configuration.app_config[0].id
                               subresource_names              = [
                                                                  "configurationStores"
                                                                ]
                             }

  dynamic "private_dns_zone_group" {
                                     for_each = range(var.dns_settings.register_storage_accounts_keyvaults_with_dns ? 1 : 0)
                                     content {
                                               name                 = var.dns_settings.dns_zone_names.appconfig_dns_zone_name
                                               private_dns_zone_ids = [data.azurerm_private_dns_zone.appconfig[0].id]
                                             }
                                   }
  tags                                 = var.infrastructure.tags

}


data "azurerm_private_dns_zone" "appconfig" {
  provider                             = azurerm.privatelinkdnsmanagement
  count                                = !var.bootstrap && var.dns_settings.register_storage_accounts_keyvaults_with_dns ? 1 : 0
  name                                 = var.dns_settings.dns_zone_names.appconfig_dns_zone_name
  resource_group_name                  = coalesce(
                                           var.dns_settings.privatelink_dns_resourcegroup_name,
                                           var.dns_settings.management_dns_resourcegroup_name,
                                           var.dns_settings.local_dns_resourcegroup_name)

}
