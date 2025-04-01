# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.


#######################################4#######################################8
#                                                                              #
#                           Azure Key Vault secrets                            #
#                                                                              #
#######################################4#######################################8

#Private endpoint tend to take a while to be created, so we need to wait for it to be ready before we can use it
resource "time_sleep" "wait_for_private_endpoints" {
  create_duration                      = "120s"
}
## Add an expiry date to the secrets
resource "time_offset" "secret_expiry_date" {
  offset_months                        = 12
}

resource "azurerm_key_vault_secret" "saplibrary_access_key" {
  provider                             = azurerm.deployer
  count                                = var.storage_account_sapbits.shared_access_key_enabled && length(try(var.key_vault.keyvault_id_for_deployment_credentials, "")) > 0 ? 1 : 0
  depends_on                           = [
                                            azurerm_storage_account.storage_tfstate,
                                            azurerm_private_dns_zone.vault,
                                            azurerm_private_dns_zone_virtual_network_link.vault,
                                            azurerm_private_dns_zone_virtual_network_link.vault_agent,
                                            azurerm_private_endpoint.kv_user,
                                            time_sleep.wait_for_private_endpoints
                                         ]
  content_type                         = "secret"
  name                                 = "sapbits-access-key"
  value                                = local.sa_sapbits_exists ? (
                                           data.azurerm_storage_account.storage_sapbits[0].primary_access_key) : (
                                           azurerm_storage_account.storage_sapbits[0].primary_access_key
                                         )
  key_vault_id                         = var.key_vault.keyvault_id_for_deployment_credentials

  expiration_date                      = try(var.deployer_tfstate.set_secret_expiry, false) ? (
                                          time_offset.secret_expiry_date.rfc3339) : (
                                          null
                                        )

}

resource "azurerm_key_vault_secret" "sapbits_location_base_path" {
  provider                             = azurerm.deployer
  count                                = length(try(var.key_vault.keyvault_id_for_deployment_credentials, "")) > 0 ? 1 : 0
  depends_on                           = [
                                            azurerm_storage_account.storage_tfstate,
                                            azurerm_private_dns_zone.vault,
                                            azurerm_private_dns_zone_virtual_network_link.vault,
                                            azurerm_private_dns_zone_virtual_network_link.vault_agent,
                                            azurerm_private_endpoint.kv_user,
                                            time_sleep.wait_for_private_endpoints
                                         ]
  content_type                         = "configuration"
  name                                 = "sapbits-location-base-path"
  value                                = format("https://%s.blob.core.windows.net/%s", length(var.storage_account_sapbits.arm_id) > 0 ?
                                              split("/", var.storage_account_sapbits.arm_id)[8] : local.sa_sapbits_name,
                                            var.storage_account_sapbits.sapbits_blob_container.name
                                          )


  key_vault_id                         = var.key_vault.keyvault_id_for_deployment_credentials
  expiration_date                      = try(var.deployer_tfstate.set_secret_expiry, false) ? (
                                           time_offset.secret_expiry_date.rfc3339) : (
                                           null
                                         )
}

resource "azurerm_key_vault_secret" "sa_connection_string" {
  provider                             = azurerm.deployer
  depends_on                           = [
                                            azurerm_storage_account.storage_tfstate,
                                            azurerm_private_dns_zone.vault,
                                            azurerm_private_dns_zone_virtual_network_link.vault,
                                            azurerm_private_dns_zone_virtual_network_link.vault_agent,
                                            azurerm_private_endpoint.kv_user,
                                            time_sleep.wait_for_private_endpoints
                                         ]
  count                                = length(try(var.key_vault.keyvault_id_for_deployment_credentials, "")) > 0 ? 1 : 0
  content_type                         = "secret"
  name                                 = "sa-connection-string"
  value                                = local.sa_tfstate_exists ? (
                                           data.azurerm_storage_account.storage_tfstate[0].primary_connection_string) : (
                                           azurerm_storage_account.storage_tfstate[0].primary_connection_string
                                         )
  key_vault_id                         = var.key_vault.keyvault_id_for_deployment_credentials
  expiration_date                      = try(var.deployer_tfstate.set_secret_expiry, false) ? (
                                           time_offset.secret_expiry_date.rfc3339) : (
                                           null
                                         )
}

resource "azurerm_key_vault_secret" "tfstate" {
  provider                             = azurerm.deployer
  depends_on                           = [
                                            azurerm_storage_account.storage_tfstate,
                                            azurerm_private_dns_zone.vault,
                                            azurerm_private_dns_zone_virtual_network_link.vault,
                                            azurerm_private_dns_zone_virtual_network_link.vault_agent,
                                            azurerm_private_endpoint.kv_user,
                                            time_sleep.wait_for_private_endpoints
                                         ]
  count                                = length(try(var.key_vault.keyvault_id_for_deployment_credentials, "")) > 0 ? 1 : 0
  content_type                         = "configuration"
  name                                 = "tfstate"
  value                                = format("https://%s.blob.core.windows.net", local.sa_tfstate_exists ? (data.azurerm_storage_account.storage_tfstate[0].name) : (azurerm_storage_account.storage_tfstate[0].name))
  key_vault_id                         = var.key_vault.keyvault_id_for_deployment_credentials
  expiration_date                      = try(var.deployer_tfstate.set_secret_expiry, false) ? (
                                           time_offset.secret_expiry_date.rfc3339) : (
                                           null
                                         )
}



# resource "azurerm_private_dns_a_record" "kv_user" {
#   provider                             = azurerm.privatelinkdnsmanagement
#   count                                = var.dns_settings.register_storage_accounts_keyvaults_with_dns ? 1 : 0
#   name                                 = lower(split("/", var.key_vault.keyvault_id_for_deployment_credentials)[8])
#   zone_name                            = var.dns_settings.dns_zone_names.vault_dns_zone_name
#   resource_group_name                  = coalesce(
#                                            var.dns_settings.privatelink_dns_resourcegroup_name,
#                                            var.dns_settings.management_dns_resourcegroup_name,
#                                            local.resource_group_name
#                                            )
#   ttl                                  = 3600
#   records                              = [azurerm_private_endpoint.kv_user[0].private_service_connection[0].private_ip_address]

#   lifecycle {
#     ignore_changes = [tags]
#   }
# }
