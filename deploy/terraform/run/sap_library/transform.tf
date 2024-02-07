
locals {
  infrastructure                       = {
                                           environment = coalesce(var.environment, try(var.infrastructure.environment, ""))
                                           region      = coalesce(var.location, try(var.infrastructure.region, ""))
                                           codename    = try(var.codename, try(var.infrastructure.codename, ""))
                                           resource_group = {
                                             name   = try(coalesce(var.resourcegroup_name, try(var.infrastructure.resource_group.name, "")), "")
                                             arm_id = try(coalesce(var.resourcegroup_arm_id, try(var.infrastructure.resource_group.arm_id, "")), "")
                                           }
                                           tags = try(coalesce(var.resourcegroup_tags, try(var.infrastructure.tags, {})), {})
                                         }
  deployer                             = {
                                           use = var.use_deployer
                                         }
  key_vault                            = {
                                           kv_spn_id = try(coalesce(local.spn_key_vault_arm_id, var.spn_keyvault_id, try(var.key_vault.kv_spn_id, "")), "")
                                         }
  storage_account_sapbits              = {
                                            arm_id = try(coalesce(var.library_sapmedia_arm_id, try(var.storage_account_sapbits.arm_id, "")), "")
                                            name   = var.library_sapmedia_name
                                            account_tier = coalesce(
                                              var.library_sapmedia_account_tier,
                                              try(var.storage_account_sapbits.account_tier, "Standard")
                                            )
                                            account_replication_type = coalesce(
                                              var.library_sapmedia_account_replication_type,
                                              try(var.storage_account_sapbits.account_replication_type, "ZRS")
                                            )
                                            account_kind = coalesce(
                                              var.library_sapmedia_account_kind,
                                              try(var.storage_account_sapbits.account_kind, "StorageV2")
                                            )
                                            file_share = {
                                              enable_deployment = (
                                                var.library_sapmedia_file_share_enable_deployment ||
                                                try(var.storage_account_sapbits.file_share.enable_deployment, true)
                                              )
                                              is_existing = (
                                                var.library_sapmedia_file_share_is_existing ||
                                                try(var.storage_account_sapbits.file_share.is_existing, false)
                                              )
                                              name = coalesce(
                                                var.library_sapmedia_file_share_name,
                                                try(
                                                  var.storage_account_sapbits.file_share.name,
                                                  module.sap_namegenerator.naming.resource_suffixes.sapbits
                                                )
                                              )
                                            }
                                            sapbits_blob_container = {
                                              enable_deployment = (
                                                var.library_sapmedia_blob_container_enable_deployment ||
                                                try(var.storage_account_sapbits.sapbits_blob_container.enable_deployment, true)
                                              )
                                              is_existing = (
                                                var.library_sapmedia_blob_container_is_existing ||
                                                try(var.storage_account_sapbits.sapbits_blob_container.is_existing, false)
                                              )
                                              name = coalesce(
                                                var.library_sapmedia_blob_container_name,
                                                try(
                                                  var.storage_account_sapbits.sapbits_blob_container.name,
                                                  module.sap_namegenerator.naming.resource_suffixes.sapbits
                                                )
                                              )
                                            }
                                           shared_access_key_enabled = var.shared_access_key_enabled
                                           public_network_access_enabled = var.public_network_access_enabled
                                         }

  storage_account_tfstate              = {
                                           arm_id = try(
                                             coalesce(
                                               var.library_terraform_state_arm_id,
                                             try(var.storage_account_tfstate.arm_id, ""))
                                             , ""
                                           )
                                           name = var.library_terraform_state_name
                                           account_tier = coalesce(
                                             var.library_terraform_state_account_tier,
                                             try(var.storage_account_tfstate.account_tier, "Standard")
                                           )
                                           account_replication_type = coalesce(
                                             var.library_terraform_state_account_replication_type,
                                             try(var.storage_account_tfstate.account_replication_type, "ZRS")
                                           )
                                           account_kind = coalesce(
                                             var.library_terraform_state_account_kind,
                                             try(var.storage_account_tfstate.account_kind, "StorageV2")
                                           )
                                           tfstate_blob_container = {
                                             is_existing = (
                                               var.library_terraform_state_blob_container_is_existing ||
                                               try(var.storage_account_tfstate.tfstate_blob_container.is_existing, false)
                                             )
                                             name = coalesce(
                                               var.library_terraform_state_blob_container_name,
                                               try(var.storage_account_tfstate.tfstate_blob_container.name, "tfstate")
                                             )
                                           }

                                           tfvars_blob_container = {
                                             is_existing = var.library_terraform_vars_blob_container_is_existing
                                             name        = var.library_terraform_vars_blob_container_name
                                           }

                                           ansible_blob_container = {
                                             is_existing = (
                                               var.library_ansible_blob_container_is_existing ||
                                               try(var.storage_account_tfstate.ansible_blob_container.is_existing, false)
                                             )
                                             name = coalesce(
                                               var.library_ansible_blob_container_name,
                                               try(var.storage_account_tfstate.ansible_blob_container.name, "ansible")
                                             )
                                           }

                                           shared_access_key_enabled = var.shared_access_key_enabled
                                           public_network_access_enabled = var.public_network_access_enabled
                                         }

}
