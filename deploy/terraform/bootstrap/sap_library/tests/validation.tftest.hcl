# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.
#
# Variable-contract coverage for every validation block declared in
# bootstrap/sap_library/tfvar_variables.tf. Each validated variable gets a
# positive-path plan run and a negative-path expect_failures run.

mock_provider "azurerm" {}
mock_provider "azurerm" {
  alias = "main"
}
mock_provider "azurerm" {
  alias = "deployer"
}
mock_provider "azurerm" {
  alias = "dnsmanagement"
}
mock_provider "azurerm" {
  alias = "privatelinkdnsmanagement"
}
mock_provider "azuread" {}

override_data {
  target = data.azurerm_client_config.current
  values = {
    subscription_id = "00000000-0000-0000-0000-000000000000"
    tenant_id       = "00000000-0000-0000-0000-000000000000"
    client_id       = "00000000-0000-0000-0000-000000000000"
    object_id       = "00000000-0000-0000-0000-000000000000"
  }
}

override_data {
  target = data.terraform_remote_state.deployer
  values = {
    outputs = {
      application_configuration_id = ""
      control_plane_name           = "DEV-WEEU-DEP01"
      deployer_kv_user_arm_id      = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-kv/providers/Microsoft.KeyVault/vaults/kv-bootstrap"
      additional_network_id        = ""
      subnet_mgmt_id               = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-net/providers/Microsoft.Network/virtualNetworks/vnet-mgmt/subnets/snet-management"
      environment                  = "DEV"
    }
  }
}

variables {
  environment                               = "DEV"
  location                                  = "westeurope"
  subscription_id                           = "00000000-0000-0000-0000-000000000000"
  use_spn                                   = false
  resourcegroup_name                        = "rg-bootstrap-library"
  deployer_statefile_foldername             = "."
  use_deployer                              = false
  use_private_endpoint                      = false
  register_storage_accounts_keyvaults_with_dns = false
  create_privatelink_dns_zones              = false
  management_network_id                     = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-net/providers/Microsoft.Network/virtualNetworks/vnet-mgmt"
  spn_keyvault_id                           = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-kv/providers/Microsoft.KeyVault/vaults/kv-bootstrap"
}

run "baseline_variables_are_accepted" {
  command = plan

  assert {
    condition     = output.saplibrary_environment == "DEV"
    error_message = "The shared bootstrap/sap_library fixture must plan successfully before any variable-specific assertions are meaningful."
  }
}

run "accepts_valid_environment" {
  command = plan

  variables {
    environment = "QA1"
  }

  assert {
    condition     = output.saplibrary_environment == "QA1"
    error_message = "A non-empty environment value up to five characters long must be accepted."
  }
}

run "rejects_empty_environment" {
  command = plan

  variables {
    environment = ""
  }

  expect_failures = [var.environment]
}

run "accepts_valid_spn_id" {
  command = plan

  variables {
    spn_id = "11111111-1111-1111-1111-111111111111"
  }

  assert {
    condition     = output.saplibrary_environment == "DEV"
    error_message = "A 36-character SPN ID must be accepted."
  }
}

run "rejects_spn_id_of_wrong_length" {
  command = plan

  variables {
    spn_id = "short-guid"
  }

  expect_failures = [var.spn_id]
}

run "accepts_valid_subscription_id" {
  command = plan

  variables {
    subscription_id = "11111111-1111-1111-1111-111111111111"
  }

  assert {
    condition     = output.saplibrary_environment == "DEV"
    error_message = "A 36-character subscription_id GUID must be accepted."
  }
}

run "rejects_subscription_id_of_wrong_length" {
  command = plan

  variables {
    subscription_id = "short-guid"
  }

  expect_failures = [var.subscription_id]
}

run "accepts_valid_resourcegroup_arm_id" {
  command = plan

  variables {
    resourcegroup_arm_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-bootstrap"
  }

  override_data {
    target = module.sap_library.data.azurerm_resource_group.library
    values = {
      id       = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-bootstrap"
      name     = "rg-bootstrap"
      location = "westeurope"
      tags     = {}
    }
  }

  assert {
    condition     = output.created_resource_group_id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-bootstrap"
    error_message = "A parseable resourcegroup_arm_id must be accepted and surfaced verbatim through the created_resource_group_id output."
  }
}

run "rejects_malformed_resourcegroup_arm_id" {
  command = plan

  variables {
    resourcegroup_arm_id = "not-a-valid-resource-id"
  }

  expect_failures = [var.resourcegroup_arm_id]
}

run "accepts_valid_library_sapmedia_arm_id" {
  command = plan

  variables {
    library_sapmedia_arm_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-lib/providers/Microsoft.Storage/storageAccounts/stsapbitsboot"
  }

  override_data {
    target = module.sap_library.data.azurerm_storage_account.storage_sapbits
    values = {
      id                        = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-lib/providers/Microsoft.Storage/storageAccounts/stsapbitsboot"
      name                      = "stsapbitsboot"
      resource_group_name       = "rg-lib"
      primary_connection_string = "UseDevelopmentStorage=true;sapbits"
      tags                      = {}
    }
  }

  assert {
    condition     = output.saplibrary_environment == "DEV"
    error_message = "A parseable library_sapmedia_arm_id must be accepted."
  }
}

run "rejects_malformed_library_sapmedia_arm_id" {
  command = plan

  variables {
    library_sapmedia_arm_id = "not-a-valid-resource-id"
  }

  expect_failures = [var.library_sapmedia_arm_id]
}

run "accepts_valid_library_terraform_state_arm_id" {
  command = plan

  variables {
    library_terraform_state_arm_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-lib/providers/Microsoft.Storage/storageAccounts/sttfstateboot"
  }

  override_data {
    target = module.sap_library.data.azurerm_storage_account.storage_tfstate
    values = {
      id                        = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-lib/providers/Microsoft.Storage/storageAccounts/sttfstateboot"
      name                      = "sttfstateboot"
      resource_group_name       = "rg-lib"
      primary_connection_string = "UseDevelopmentStorage=true;tfstate"
      tags                      = {}
    }
  }

  assert {
    condition     = output.saplibrary_environment == "DEV"
    error_message = "A parseable library_terraform_state_arm_id must be accepted."
  }
}

run "rejects_malformed_library_terraform_state_arm_id" {
  command = plan

  variables {
    library_terraform_state_arm_id = "not-a-valid-resource-id"
  }

  expect_failures = [var.library_terraform_state_arm_id]
}

run "accepts_valid_spn_keyvault_id" {
  command = plan

  variables {
    spn_keyvault_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-kv/providers/Microsoft.KeyVault/vaults/kv-bootstrap"
  }

  assert {
    condition     = output.saplibrary_environment == "DEV"
    error_message = "A parseable spn_keyvault_id must be accepted."
  }
}

run "rejects_malformed_spn_keyvault_id" {
  command = plan

  variables {
    spn_keyvault_id = "not-a-valid-resource-id"
  }

  expect_failures = [var.spn_keyvault_id]
}

run "accepts_valid_additional_network_id" {
  command = plan

  variables {
    additional_network_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-net/providers/Microsoft.Network/virtualNetworks/vnet-mgmt"
  }

  assert {
    condition     = output.saplibrary_environment == "DEV"
    error_message = "A parseable additional_network_id must be accepted."
  }
}

run "rejects_malformed_additional_network_id" {
  command = plan

  variables {
    additional_network_id = "not-a-valid-resource-id"
  }

  expect_failures = [var.additional_network_id]
}

run "accepts_valid_management_network_id" {
  command = plan

  variables {
    management_network_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-net/providers/Microsoft.Network/virtualNetworks/vnet-mgmt"
  }

  assert {
    condition     = output.saplibrary_environment == "DEV"
    error_message = "A parseable management_network_id must be accepted."
  }
}

run "rejects_malformed_management_network_id" {
  command = plan

  variables {
    management_network_id = "not-a-valid-resource-id"
  }

  expect_failures = [var.management_network_id]
}

run "accepts_valid_application_configuration_id" {
  command = plan

  variables {
    application_configuration_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-app/providers/Microsoft.AppConfiguration/configurationStores/appcfgbootstrap"
  }

  override_data {
    target = module.sap_library.data.azurerm_app_configuration.app_config
    values = {
      id   = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-app/providers/Microsoft.AppConfiguration/configurationStores/appcfgbootstrap"
      name = "appcfgbootstrap"
    }
  }

  assert {
    condition     = output.saplibrary_environment == "DEV"
    error_message = "A parseable application_configuration_id must be accepted."
  }
}

run "rejects_malformed_application_configuration_id" {
  command = plan

  variables {
    application_configuration_id = "not-a-valid-resource-id"
  }

  expect_failures = [var.application_configuration_id]
}
