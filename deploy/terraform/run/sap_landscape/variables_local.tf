# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.


#######################################4#######################################8
#                                                                              #
#                            Local Variables                                   #
#                                                                              #
#######################################4#######################################8

locals {

  version_label                        = trimspace(file("${path.module}/../../../configs/version.txt"))

  // The environment of sap landscape and sap system
  environment                          = upper(local.infrastructure.environment)

  vnet_logical_name                    = local.infrastructure.virtual_networks.sap.logical_name


  // Locate the tfstate storage account
  saplib_subscription_id               = split("/", var.tfstate_resource_id)[2]
  saplib_resource_group_name           = split("/", var.tfstate_resource_id)[4]
  tfstate_storage_account_name         = split("/", var.tfstate_resource_id)[8]
  tfstate_container_name               = module.sap_namegenerator.naming.resource_suffixes.tfstate

  // Retrieve the arm_id of deployer's Key Vault from deployer's terraform.tfstate
  spn_key_vault_arm_id                 = try(local.key_vault.keyvault_id_for_deployment_credentials,
                                           try(data.terraform_remote_state.deployer[0].outputs.deployer_kv_user_arm_id,
                                           ""))

  deployer_subscription_id             = coalesce(
                                           try(data.terraform_remote_state.deployer[0].outputs.created_resource_group_subscription_id,""),
                                           length(local.spn_key_vault_arm_id) > 0 ? (split("/", local.spn_key_vault_arm_id)[2]) : (""),
                                           local.saplib_subscription_id
                                           )

  spn                                  = {
                                           subscription_id = length(var.subscription_id) > 0 ? var.subscription_id : data.azurerm_key_vault_secret.subscription_id[0].value,
                                           client_id       = var.use_spn ? data.azurerm_key_vault_secret.client_id[0].value : null,
                                           client_secret   = var.use_spn ? data.azurerm_key_vault_secret.client_secret[0].value : null,
                                           tenant_id       = var.use_spn ? data.azurerm_key_vault_secret.tenant_id[0].value : null
                                         }

  cp_spn                               = {
                                           subscription_id = try(data.azurerm_key_vault_secret.cp_subscription_id[0].value, null)
                                           client_id       = var.use_spn ? data.azurerm_key_vault_secret.cp_client_id[0].value : null,
                                           client_secret   = var.use_spn ? data.azurerm_key_vault_secret.cp_client_secret[0].value : null,
                                           tenant_id       = var.use_spn ? data.azurerm_key_vault_secret.cp_tenant_id[0].value : null
                                         }

  service_principal                    = {
                                           subscription_id = local.spn.subscription_id,
                                           tenant_id       = local.spn.tenant_id,
                                           object_id       = var.use_spn ? data.azuread_service_principal.sp[0].object_id   : null,
                                           client_id       = var.use_spn ? data.azuread_service_principal.sp[0].client_id   : null,
                                           exists          = var.use_spn
                                         }

  account                              = {
                                          subscription_id = length(var.subscription_id) > 0 ? var.subscription_id : data.azurerm_key_vault_secret.subscription_id[0].value,
                                          tenant_id       = data.azurerm_client_config.current.tenant_id,
                                          object_id       = data.azurerm_client_config.current.object_id,
                                          client_id       = data.azurerm_client_config.current.client_id ,
                                          exists          = false
                                        }

  custom_names                         = length(var.name_override_file) > 0 ? (
                                           jsondecode(file(format("%s/%s", path.cwd, var.name_override_file)))
                                          ) : (
                                          null
                                        )

  is_DNS_info_different                = (
                                           var.management_dns_subscription_id != ((length(var.subscription_id) > 0) ? var.subscription_id : data.azurerm_key_vault_secret.subscription_id[0].value)
                                           ) || (
                                           var.management_dns_resourcegroup_name != (local.saplib_resource_group_name)
                                         )


}
