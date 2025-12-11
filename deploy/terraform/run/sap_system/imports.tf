# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

#
# Remote State Data Sources
# Retrieve configuration from Deployer and Landscape deployments
#

data "azurerm_client_config" "current" {}

data "terraform_remote_state" "deployer" {
  backend = "azurerm"
  count   = length(try(var.deployer_tfstate_key, "")) > 0 ? 1 : 0

  config = {
    resource_group_name  = local.SAPLibrary_resource_group_name
    storage_account_name = local.tfstate_storage_account_name
    container_name       = local.tfstate_container_name
    key                  = var.deployer_tfstate_key
    subscription_id      = local.SAPLibrary_subscription_id
  }
}

data "terraform_remote_state" "landscape" {
  backend = "azurerm"

  config = {
    resource_group_name  = local.SAPLibrary_resource_group_name
    storage_account_name = local.tfstate_storage_account_name
    container_name       = local.tfstate_container_name
    key                  = var.landscape_tfstate_key
    subscription_id      = local.SAPLibrary_subscription_id
  }
}

#
# Local Variables for Credential Retrieval
#

locals {
  # Determine effective naming based on configuration
  use_workload_zone_naming = length(trimspace(var.workload_zone_name)) > 0
  environment_name         = local.use_workload_zone_naming ? var.workload_zone_name : local.environment

  # Control plane naming resolution
  control_plane_name_resolved = coalesce(
    var.control_plane_name,
    try(data.terraform_remote_state.deployer[0].outputs.environment, ""),
    try(data.terraform_remote_state.landscape.outputs.control_plane_name, "")
  )

  workload_zone_name_resolved = coalesce(
    var.workload_zone_name,
    try(data.terraform_remote_state.landscape.outputs.workload_zone_name, "")
  )

  # Conditions for credential retrieval
  retrieve_subscription_from_kv = length(var.subscription_id) == 0 && var.use_spn
  retrieve_cp_credentials       = var.use_spn && length(local.control_plane_name_resolved) > 0
}

#
# Workload Zone Service Principal Credentials
# Retrieved from Key Vault when use_spn is enabled
#

data "azurerm_key_vault_secret" "subscription_id" {
  count        = local.retrieve_subscription_from_kv ? 1 : 0
  name         = format("%s-subscription-id", local.environment_name)
  key_vault_id = local.key_vault.spn.id

  timeouts {
    read = "1m"
  }
}

data "azurerm_key_vault_secret" "client_id" {
  count        = var.use_spn ? 1 : 0
  name         = format("%s-client-id", local.environment_name)
  key_vault_id = local.key_vault.spn.id

  timeouts {
    read = "1m"
  }
}

ephemeral "azurerm_key_vault_secret" "client_secret" {
  count        = var.use_spn ? 1 : 0
  name         = format("%s-client-secret", local.environment_name)
  key_vault_id = local.key_vault.spn.id
}

data "azurerm_key_vault_secret" "tenant_id" {
  count        = var.use_spn ? 1 : 0
  name         = format("%s-tenant-id", local.environment_name)
  key_vault_id = local.key_vault.spn.id

  timeouts {
    read = "1m"
  }
}

#
# Control Plane Service Principal Credentials
# Used for accessing shared control plane resources
#

data "azurerm_key_vault_secret" "cp_subscription_id" {
  count        = local.retrieve_cp_credentials ? 1 : 0
  name         = format("%s-subscription-id", local.control_plane_name_resolved)
  key_vault_id = local.key_vault.spn.id

  timeouts {
    read = "1m"
  }
}

data "azurerm_key_vault_secret" "cp_client_id" {
  count        = local.retrieve_cp_credentials ? 1 : 0
  name         = format("%s-client-id", local.control_plane_name_resolved)
  key_vault_id = local.key_vault.spn.id

  timeouts {
    read = "1m"
  }
}

ephemeral "azurerm_key_vault_secret" "cp_client_secret" {
  count        = local.retrieve_cp_credentials ? 1 : 0
  name         = format("%s-client-secret", local.control_plane_name_resolved)
  key_vault_id = local.key_vault.spn.id
}

data "azurerm_key_vault_secret" "cp_tenant_id" {
  count        = local.retrieve_cp_credentials ? 1 : 0
  name         = format("%s-tenant-id", local.control_plane_name_resolved)
  key_vault_id = local.key_vault.spn.id

  timeouts {
    read = "1m"
  }
}

#
# Azure App Configuration Integration
# Retrieves shared configuration when App Configuration is enabled
#

data "azurerm_app_configuration_key" "media_path" {
  count                  = local.infrastructure.use_application_configuration ? 1 : 0
  configuration_store_id = local.infrastructure.application_configuration_id
  key                    = format("%s_SAPMediaPath", local.control_plane_name_resolved)
  label                  = local.control_plane_name_resolved
}

data "azurerm_app_configuration_key" "credentials_vault" {
  count                  = local.infrastructure.use_application_configuration ? 1 : 0
  configuration_store_id = local.infrastructure.application_configuration_id
  key                    = format("%s_KeyVaultResourceId", local.control_plane_name_resolved)
  label                  = local.control_plane_name_resolved
}

data "azurerm_app_configuration_key" "workload_credentials_vault" {
  count                  = local.infrastructure.use_application_configuration ? 1 : 0
  configuration_store_id = local.infrastructure.application_configuration_id
  key                    = format("%s_KeyVaultResourceId", local.workload_zone_name_resolved)
  label                  = local.workload_zone_name_resolved
}
