# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.


###############################################################################
#                                                                             #
#                            Local Variables                                  #
#                                                                             #
###############################################################################


locals {

  version_label                        = trimspace(file("${path.module}/../../../configs/version.txt"))
  deployer_prefix                      = module.sap_namegenerator.naming.prefix.DEPLOYER

  use_spn                              = !var.use_deployer ? false : var.use_spn

  // If custom names are used for deployer, providing resource_group_name and msi_name will override the naming convention
  deployer_rg_name                     = coalesce(local.deployer.resource_group_name, format("%s-INFRASTRUCTURE", var.control_plane_name))

  // Locate the tfstate storage account
  parsed_id                           = provider::azurerm::parse_resource_id(var.tfstate_resource_id)

  SAPLibrary_subscription_id          = local.parsed_id["subscription_id"]
  SAPLibrary_resource_group_name      = local.parsed_id["resource_group_name"]
  tfstate_storage_account_name        = local.parsed_id["resource_name"]
  tfstate_container_name              = module.sap_namegenerator.naming.resource_suffixes.tfstate


  // Retrieve the arm_id of deployer's Key Vault from deployer's terraform.tfstate
  spn_key_vault_arm_id                 = var.use_deployer ?  coalesce(var.spn_keyvault_id, try(data.terraform_remote_state.deployer[0].outputs.deployer_kv_user_arm_id, "")) : ""

  custom_names                         = length(var.name_override_file) > 0 ? (
                                           jsondecode(file(format("%s/%s", path.cwd, var.name_override_file)))) : (
                                           null
                                         )

}
