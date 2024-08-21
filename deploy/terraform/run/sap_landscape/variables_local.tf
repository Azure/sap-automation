
#######################################4#######################################8
#                                                                              #
#                            Local Variables                                   #
#                                                                              #
#######################################4#######################################8

locals {

  version_label                        = trimspace(file("${path.module}/../../../configs/version.txt"))

  // The environment of sap landscape and sap system
  environment                          = upper(local.infrastructure.environment)

  vnet_logical_name                    = local.infrastructure.vnets.sap.logical_name


  // Locate the tfstate storage account
  saplib_subscription_id               = split("/", var.tfstate_resource_id)[2]
  saplib_resource_group_name           = split("/", var.tfstate_resource_id)[4]
  tfstate_storage_account_name         = split("/", var.tfstate_resource_id)[8]
  tfstate_container_name               = module.sap_namegenerator.naming.resource_suffixes.tfstate

  // Retrieve the arm_id of deployer's Key Vault from deployer's terraform.tfstate
  spn_key_vault_arm_id                 = try("/subscriptions/8d52cb5d-c5bb-4273-b81d-bb0da5ff6e8e/resourceGroups/MGMT-WEEU-SAP_LIBRARY1/providers/Microsoft.KeyVault/vaults/MGMTWEEUDEP01user536",
                                           try(data.terraform_remote_state.deployer[0].outputs.deployer_kv_user_arm_id,
                                           "")
                                         )

  deployer_subscription_id             = length(local.spn_key_vault_arm_id) > 0 ? (
                                           split("/", local.spn_key_vault_arm_id)[2]) : (
                                           ""
                                         )

  spn                                  = {
                                           subscription_id = "8d52cb5d-c5bb-4273-b81d-bb0da5ff6e8e",
                                           client_id           = ""
                                           client_secret       = ""
                                           tenant_id           = ""
                                         }

  cp_spn                               = {
                                           subscription_id = try(data.azurerm_key_vault_secret.cp_subscription_id[0].value, null)
                                           client_id           = ""
                                           client_secret       = ""
                                           tenant_id           = ""
                                         }

  service_principal                    = {
                                           subscription_id = local.spn.subscription_id,
                                           tenant_id       = "",
                                           object_id       = var.use_spn ? try(data.azuread_service_principal.sp[0].id, null) : null
                                         }

  account                              = {
                                          subscription_id = "",
                                          tenant_id       = "",
                                          object_id       = data.azurerm_client_config.current.object_id
                                        }

  custom_names                         = length(var.name_override_file) > 0 ? (
                                           jsondecode(file(format("%s/%s", path.cwd, var.name_override_file)))
                                          ) : (
                                          null
                                        )

  is_DNS_info_different                = (
                                           var.management_dns_subscription_id != "8d52cb5d-c5bb-4273-b81d-bb0da5ff6e8e"
                                           ) || (
                                           var.management_dns_resourcegroup_name != (local.saplib_resource_group_name)
                                         )

}
