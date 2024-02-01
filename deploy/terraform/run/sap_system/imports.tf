
/*
    Description:
    Retrieve remote tfstate file of Deployer and current environment's SPN
*/


data "azurerm_client_config" "current" {}

data "terraform_remote_state" "deployer"             {
                                                       backend       = "azurerm"
                                                       count         = length(try(var.deployer_tfstate_key, "")) > 0 ? 1 : 0
                                                       config        = {
                                                                         resource_group_name  = local.saplib_resource_group_name
                                                                         storage_account_name = local.tfstate_storage_account_name
                                                                         container_name       = local.tfstate_container_name
                                                                         key                  = var.deployer_tfstate_key
                                                                         subscription_id      = local.saplib_subscription_id
                                                                         use_msi              = var.use_spn ? false : true
                                                                       }
}

data "terraform_remote_state" "landscape"            {
                                                       backend       = "azurerm"
                                                       config        = {
                                                                         resource_group_name  = local.saplib_resource_group_name
                                                                         storage_account_name = local.tfstate_storage_account_name
                                                                         container_name       = "tfstate"
                                                                         key                  = var.landscape_tfstate_key
                                                                         subscription_id      = local.saplib_subscription_id
                                                                         use_msi              = var.use_spn ? false : true
                                                                       }
                                                     }

data "azurerm_key_vault_secret" "subscription_id"    {
                                                        name         = format("%s-subscription-id", local.environment)
                                                        key_vault_id = local.spn_key_vault_arm_id
                                                      }

data "azurerm_key_vault_secret" "client_id"          {
                                                        count        = try(data.terraform_remote_state.landscape.outputs.use_spn, true) && var.use_spn ? 1 : 0
                                                        name         = format("%s-client-id", local.environment)
                                                        key_vault_id = local.spn_key_vault_arm_id
                                                      }

data "azurerm_key_vault_secret" "client_secret"       {
                                                        count        = try(data.terraform_remote_state.landscape.outputs.use_spn, true) && var.use_spn ? 1 : 0
                                                        name         = format("%s-client-secret", local.environment)
                                                        key_vault_id = local.spn_key_vault_arm_id
                                                      }

data "azurerm_key_vault_secret" "tenant_id"           {
                                                        count        = try(data.terraform_remote_state.landscape.outputs.use_spn, true) && var.use_spn ? 1 : 0
                                                        name         = format("%s-tenant-id", local.environment)
                                                        key_vault_id = local.spn_key_vault_arm_id
                                                      }

data "azurerm_key_vault_secret" "cp_subscription_id"  {
                                                        count        = length(try(data.terraform_remote_state.deployer[0].outputs.environment, "")) > 0 ? (try(data.terraform_remote_state.landscape.outputs.use_spn, true) && var.use_spn ? 1 : 0) : 0
                                                        name         = format("%s-subscription-id", data.terraform_remote_state.deployer[0].outputs.environment)
                                                        key_vault_id = local.spn_key_vault_arm_id
                                                      }

data "azurerm_key_vault_secret" "cp_client_id"        {
                                                        count        = length(try(data.terraform_remote_state.deployer[0].outputs.environment, "")) > 0 ? (try(data.terraform_remote_state.landscape.outputs.use_spn, true) && var.use_spn ? 1 : 0) : 0
                                                        name         = format("%s-client-id", data.terraform_remote_state.deployer[0].outputs.environment)
                                                        key_vault_id = local.spn_key_vault_arm_id
                                                      }

data "azurerm_key_vault_secret" "cp_client_secret"    {
                                                        count        = length(try(data.terraform_remote_state.deployer[0].outputs.environment, "")) > 0 ? (try(data.terraform_remote_state.landscape.outputs.use_spn, true) && var.use_spn ? 1 : 0) : 0
                                                        name         = format("%s-client-secret", data.terraform_remote_state.deployer[0].outputs.environment)
                                                        key_vault_id = local.spn_key_vault_arm_id
                                                      }

data "azurerm_key_vault_secret" "cp_tenant_id"        {
                                                        count        = length(try(data.terraform_remote_state.deployer[0].outputs.environment, "")) > 0 ? (try(data.terraform_remote_state.landscape.outputs.use_spn, true) && var.use_spn ? 1 : 0) : 0
                                                        name         = format("%s-tenant-id", data.terraform_remote_state.deployer[0].outputs.environment)
                                                        key_vault_id = local.spn_key_vault_arm_id
                                                      }

// Import current service principal
data "azuread_service_principal" "sp"                 {
                                                        count        = try(data.terraform_remote_state.landscape.outputs.use_spn, true) && var.use_spn ? 1 : 0
                                                        client_id    = local.spn.client_id
                                                      }


