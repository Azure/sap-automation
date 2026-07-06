# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.
#
# Scenario Category 2 (variable validation coverage) for every validation block
# declared directly on run/sap_library inputs. This module currently declares 13
# validation blocks across tfvar_variables.tf (research originally said 12, but
# direct inspection shows an additional validation on management_network_id).
#
# The file-level fixture keeps plan-time behavior simple (no private endpoints,
# no DNS registration, no App Configuration by default) while still running a
# real `plan` under mocked azurerm/azuread providers so provider-defined
# functions such as provider::azurerm::parse_resource_id() are available.

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
  target = module.sap_library.data.azurerm_client_config.current
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
      environment                            = "DEP01"
      application_configuration_id           = ""
      control_plane_name                     = "DEP01"
      deployer_kv_user_arm_id                = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-kv/providers/Microsoft.KeyVault/vaults/kv-deployer"
      network_security_perimeter_deployment  = false
      deployer_msi_id                        = ""
      additional_network_id                  = ""
      vnet_mgmt_id                           = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-net/providers/Microsoft.Network/virtualNetworks/vnet-mgmt"
      subnet_mgmt_id                         = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-net/providers/Microsoft.Network/virtualNetworks/vnet-mgmt/subnets/snet-mgmt"
      subnet_webapp_id                       = ""
      deployer_public_ip_address             = ""
      subnets_to_add_to_firewall_for_keyvaults_and_storage = []
      enable_firewall_for_keyvaults_and_storage            = false
      set_secret_expiry                      = false
      network_security_access_mode           = "Learning"
      network_security_perimeter_id          = ""
    }
  }
}

variables {
  environment                               = "DEV"
  location                                  = "westeurope"
  subscription_id                           = "00000000-0000-0000-0000-000000000000"
  use_deployer                              = true
  deployer_tfstate_key                      = "DEP01.terraform.tfstate"
  use_spn                                   = false
  custom_random_id                          = "abc"
  tfstate_resource_id                       = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-tfstate/providers/Microsoft.Storage/storageAccounts/tfstatesa"
  use_private_endpoint                      = false
  register_storage_accounts_keyvaults_with_dns = false
  create_privatelink_dns_zones              = false
  public_network_access_enabled             = false
}

run "baseline_variables_are_accepted" {
  command = plan

  assert {
    condition     = output.saplibrary_environment == "DEV"
    error_message = "The shared validation fixture must itself plan successfully so every variable-specific positive/negative run below starts from a known-good baseline."
  }
}

run "accepts_valid_environment" {
  command = plan

  variables {
    environment = "TST"
  }

  assert {
    condition     = output.saplibrary_environment == "TST"
    error_message = "A non-empty environment value with at most five characters must be accepted and surfaced through output.saplibrary_environment."
  }
}

run "rejects_empty_environment" {
  command = plan

  variables {
    environment = ""
  }

  expect_failures = [
    var.environment,
  ]
}

run "accepts_valid_spn_id" {
  command = plan

  variables {
    spn_id = "11111111-1111-1111-1111-111111111111"
  }

  assert {
    condition     = output.saplibrary_environment == "DEV"
    error_message = "A 36-character service principal identifier must be accepted for spn_id without tripping its validation block."
  }
}

run "rejects_invalid_spn_id" {
  command = plan

  variables {
    spn_id = "short-guid"
  }

  expect_failures = [
    var.spn_id,
  ]
}

run "accepts_valid_subscription_id" {
  command = plan

  variables {
    subscription_id = "22222222-2222-2222-2222-222222222222"
  }

  assert {
    condition     = output.saplibrary_environment == "DEV"
    error_message = "A 36-character subscription_id must be accepted when it matches the module's GUID-length contract."
  }
}

run "rejects_invalid_subscription_id" {
  command = plan

  variables {
    subscription_id = "bad-guid"
  }

  expect_failures = [
    var.subscription_id,
  ]
}

run "accepts_valid_resourcegroup_arm_id" {
  command = plan

  variables {
    resourcegroup_arm_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-existing-library"
  }

  override_data {
    target = module.sap_library.data.azurerm_resource_group.library
    values = {
      id       = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-existing-library"
      name     = "rg-existing-library"
      location = "westeurope"
    }
  }

  assert {
    condition     = output.created_resource_group_name == "rg-existing-library"
    error_message = "A valid existing resourcegroup_arm_id must be accepted and flip the module to the brownfield resource-group path."
  }
}

run "rejects_invalid_resourcegroup_arm_id" {
  command = plan

  variables {
    resourcegroup_arm_id = "not-a-valid-resource-id"
  }

  expect_failures = [
    var.resourcegroup_arm_id,
  ]
}

run "accepts_valid_library_sapmedia_arm_id" {
  command = plan

  variables {
    library_sapmedia_arm_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-existing-library/providers/Microsoft.Storage/storageAccounts/stsapbitsexisting"
  }

  override_data {
    target = module.sap_library.data.azurerm_storage_account.storage_sapbits
    values = {
      id                        = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-existing-library/providers/Microsoft.Storage/storageAccounts/stsapbitsexisting"
      name                      = "stsapbitsexisting"
      resource_group_name       = "rg-existing-library"
      primary_access_key        = "diagnostic-access-key"
      primary_connection_string = "DefaultEndpointsProtocol=https;AccountName=stsapbitsexisting;AccountKey=diagnostic-access-key;EndpointSuffix=core.windows.net"
    }
  }

  assert {
    condition     = output.sapbits_storage_account_name == "stsapbitsexisting"
    error_message = "A valid library_sapmedia_arm_id must be accepted and drive the existing SAP media storage-account path."
  }
}

run "rejects_invalid_library_sapmedia_arm_id" {
  command = plan

  variables {
    library_sapmedia_arm_id = "not-a-valid-resource-id"
  }

  expect_failures = [
    var.library_sapmedia_arm_id,
  ]
}

run "accepts_valid_library_terraform_state_arm_id" {
  command = plan

  variables {
    library_terraform_state_arm_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-existing-library/providers/Microsoft.Storage/storageAccounts/sttfstateexisting"
  }

  override_data {
    target = module.sap_library.data.azurerm_storage_account.storage_tfstate
    values = {
      id                        = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-existing-library/providers/Microsoft.Storage/storageAccounts/sttfstateexisting"
      name                      = "sttfstateexisting"
      resource_group_name       = "rg-existing-library"
      primary_connection_string = "DefaultEndpointsProtocol=https;AccountName=sttfstateexisting;AccountKey=diagnostic-access-key;EndpointSuffix=core.windows.net"
    }
  }

  assert {
    condition     = output.remote_state_storage_account_name == "sttfstateexisting"
    error_message = "A valid library_terraform_state_arm_id must be accepted and drive the existing tfstate storage-account path."
  }
}

run "rejects_invalid_library_terraform_state_arm_id" {
  command = plan

  variables {
    library_terraform_state_arm_id = "not-a-valid-resource-id"
  }

  expect_failures = [
    var.library_terraform_state_arm_id,
  ]
}

run "accepts_valid_spn_keyvault_id" {
  command = plan

  variables {
    spn_keyvault_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-kv/providers/Microsoft.KeyVault/vaults/kv-override"
  }

  assert {
    condition     = output.saplibrary_environment == "DEV"
    error_message = "A correctly formed spn_keyvault_id must be accepted so deployer/user Key Vault resolution can use an explicit override."
  }
}

run "rejects_invalid_spn_keyvault_id" {
  command = plan

  variables {
    spn_keyvault_id = "not-a-valid-resource-id"
  }

  expect_failures = [
    var.spn_keyvault_id,
  ]
}

run "accepts_valid_tfstate_resource_id" {
  command = plan

  variables {
    tfstate_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-alt-tfstate/providers/Microsoft.Storage/storageAccounts/tfstatesa02"
  }

  assert {
    condition     = output.saplibrary_subscription_id == "00000000-0000-0000-0000-000000000000"
    error_message = "A well-formed tfstate_resource_id must be accepted so the module can parse the remote-state storage-account subscription and names."
  }
}

run "rejects_invalid_tfstate_resource_id" {
  command = plan

  variables {
    tfstate_resource_id = "not-a-valid-resource-id"
  }

  expect_failures = [
    var.tfstate_resource_id,
  ]
}

run "accepts_valid_management_dns_subscription_id" {
  command = plan

  variables {
    management_dns_subscription_id = "33333333-3333-3333-3333-333333333333"
  }

  assert {
    condition     = output.saplibrary_environment == "DEV"
    error_message = "A 36-character management_dns_subscription_id must be accepted for split-subscription DNS registration scenarios."
  }
}

run "rejects_invalid_management_dns_subscription_id" {
  command = plan

  variables {
    management_dns_subscription_id = "bad-guid"
  }

  expect_failures = [
    var.management_dns_subscription_id,
  ]
}

run "accepts_valid_privatelink_dns_subscription_id" {
  command = plan

  variables {
    privatelink_dns_subscription_id = "44444444-4444-4444-4444-444444444444"
  }

  assert {
    condition     = output.saplibrary_environment == "DEV"
    error_message = "A 36-character privatelink_dns_subscription_id must be accepted for Private Link DNS split-subscription scenarios."
  }
}

run "rejects_invalid_privatelink_dns_subscription_id" {
  command = plan

  variables {
    privatelink_dns_subscription_id = "bad-guid"
  }

  expect_failures = [
    var.privatelink_dns_subscription_id,
  ]
}

run "accepts_valid_additional_network_id" {
  command = plan

  variables {
    additional_network_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-net/providers/Microsoft.Network/virtualNetworks/vnet-agent"
  }

  assert {
    condition     = output.saplibrary_environment == "DEV"
    error_message = "A valid additional_network_id must be accepted so the module can compose optional agent-network DNS/firewall settings."
  }
}

run "rejects_invalid_additional_network_id" {
  command = plan

  variables {
    additional_network_id = "not-a-valid-resource-id"
  }

  expect_failures = [
    var.additional_network_id,
  ]
}

run "accepts_valid_management_network_id" {
  command = plan

  variables {
    management_network_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-net/providers/Microsoft.Network/virtualNetworks/vnet-mgmt"
  }

  assert {
    condition     = output.saplibrary_environment == "DEV"
    error_message = "A valid management_network_id must be accepted so the module can target the intended management VNet when deployer state is absent or overridden."
  }
}

run "rejects_invalid_management_network_id" {
  command = plan

  variables {
    management_network_id = "not-a-valid-resource-id"
  }

  expect_failures = [
    var.management_network_id,
  ]
}

run "accepts_valid_application_configuration_id" {
  command = plan

  variables {
    application_configuration_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-appconfig/providers/Microsoft.AppConfiguration/configurationStores/appconfiglib"
  }

  override_data {
    target = module.sap_library.data.azurerm_app_configuration.app_config
    values = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-appconfig/providers/Microsoft.AppConfiguration/configurationStores/appconfiglib"
    }
  }

  assert {
    condition     = output.saplibrary_environment == "DEV"
    error_message = "A valid application_configuration_id must be accepted without tripping validation so the App Configuration composition path can plan successfully."
  }
}

run "rejects_invalid_application_configuration_id" {
  command = plan

  variables {
    application_configuration_id = "not-a-valid-resource-id"
  }

  expect_failures = [
    var.application_configuration_id,
  ]
}

run "remote_state_toggle_off_skips_deployer_state_lookup" {
  command = plan

  variables {
    use_deployer                        = false
    deployer_tfstate_key                = ""
    spn_keyvault_id                     = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-kv/providers/Microsoft.KeyVault/vaults/kv-manual"
    management_network_id               = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-net/providers/Microsoft.Network/virtualNetworks/vnet-mgmt"
  }

  assert {
    condition     = length(data.terraform_remote_state.deployer) == 0
    error_message = "When use_deployer is false and deployer_tfstate_key is blank, the deployer remote-state data source must have count = 0."
  }
}

run "remote_state_toggle_on_reads_deployer_state_lookup" {
  command = plan

  variables {
    use_deployer       = true
    deployer_tfstate_key = "DEP01.terraform.tfstate"
  }

  assert {
    condition     = length(data.terraform_remote_state.deployer) == 1
    error_message = "When use_deployer is true and deployer_tfstate_key is non-empty, the deployer remote-state data source must have count = 1."
  }
}
