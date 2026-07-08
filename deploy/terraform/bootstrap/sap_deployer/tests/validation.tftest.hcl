# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.
#
# Variable-contract coverage for every validation block declared in
# bootstrap/sap_deployer/tfvar_variables.tf. Each validated variable gets a
# positive-path plan run and a negative-path expect_failures run.

mock_provider "azurerm" {}
mock_provider "azurerm" {
  alias = "main"
}
mock_provider "azurerm" {
  alias = "dnsmanagement"
}
mock_provider "azurerm" {
  alias = "privatelinkdnsmanagement"
}
mock_provider "azuread" {}
mock_provider "azapi" {
  alias = "restapi"
}

override_data {
  target = data.azurerm_client_config.current
  values = {
    subscription_id = "00000000-0000-0000-0000-000000000000"
    tenant_id       = "00000000-0000-0000-0000-000000000000"
    client_id       = "00000000-0000-0000-0000-000000000000"
    object_id       = "00000000-0000-0000-0000-000000000000"
  }
}

variables {
  environment                         = "DEV"
  location                            = "westeurope"
  subscription_id                     = "00000000-0000-0000-0000-000000000000"
  resourcegroup_name                  = "rg-bootstrap-deployer"
  management_network_name             = "vnet-mgmt"
  management_network_logical_name     = "DEP01"
  management_network_address_space    = "10.20.0.0/16"
  management_subnet_name              = "snet-management"
  management_subnet_address_prefix    = "10.20.0.0/24"
  management_dns_subscription_id      = "00000000-0000-0000-0000-000000000000"
  privatelink_dns_subscription_id     = "00000000-0000-0000-0000-000000000000"
  use_private_endpoint                = false
  use_service_endpoint                = false
}

run "baseline_variables_are_accepted" {
  command = plan

  assert {
    condition     = output.environment == "DEV"
    error_message = "The shared bootstrap/sap_deployer fixture must plan successfully before any variable-specific assertions are meaningful."
  }
}

run "accepts_valid_environment" {
  command = plan

  variables {
    environment = "QA1"
  }

  assert {
    condition     = output.environment == "QA1"
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

run "accepts_valid_subscription_id" {
  command = plan

  variables {
    subscription_id = "11111111-1111-1111-1111-111111111111"
  }

  assert {
    condition     = output.environment == "DEV"
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
    target = module.sap_deployer.data.azurerm_resource_group.deployer
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

run "accepts_valid_management_network_arm_id" {
  command = plan

  variables {
    management_network_arm_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-net/providers/Microsoft.Network/virtualNetworks/vnet-mgmt"
  }

  assert {
    condition     = output.environment == "DEV"
    error_message = "A parseable management_network_arm_id must be accepted."
  }
}

run "rejects_malformed_management_network_arm_id" {
  command = plan

  variables {
    management_network_arm_id = "not-a-valid-resource-id"
  }

  expect_failures = [var.management_network_arm_id]
}

run "accepts_valid_management_network_flow_timeout" {
  command = plan

  variables {
    management_network_flow_timeout_in_minutes = 30
  }

  assert {
    condition     = output.environment == "DEV"
    error_message = "A management network flow timeout within the documented 4-30 minute range must be accepted."
  }
}

run "rejects_management_network_flow_timeout_out_of_range" {
  command = plan

  variables {
    management_network_flow_timeout_in_minutes = 31
  }

  expect_failures = [var.management_network_flow_timeout_in_minutes]
}

run "accepts_valid_management_subnet_arm_id" {
  command = plan

  variables {
    management_subnet_arm_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-net/providers/Microsoft.Network/virtualNetworks/vnet-mgmt/subnets/snet-management"
  }

  override_data {
    target = module.sap_deployer.data.azurerm_subnet.subnet_mgmt
    values = {
      id                   = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-net/providers/Microsoft.Network/virtualNetworks/vnet-mgmt/subnets/snet-management"
      name                 = "snet-management"
      resource_group_name  = "rg-net"
      virtual_network_name = "vnet-mgmt"
      address_prefixes     = ["10.20.0.0/24"]
    }
  }

  assert {
    condition     = output.environment == "DEV"
    error_message = "A parseable management_subnet_arm_id must be accepted."
  }
}

run "rejects_malformed_management_subnet_arm_id" {
  command = plan

  variables {
    management_subnet_arm_id = "not-a-valid-resource-id"
  }

  expect_failures = [var.management_subnet_arm_id]
}

run "accepts_valid_management_firewall_subnet_arm_id" {
  command = plan

  variables {
    management_firewall_subnet_arm_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-net/providers/Microsoft.Network/virtualNetworks/vnet-mgmt/subnets/AzureFirewallSubnet"
  }

  assert {
    condition     = output.environment == "DEV"
    error_message = "A parseable management_firewall_subnet_arm_id must be accepted."
  }
}

run "rejects_malformed_management_firewall_subnet_arm_id" {
  command = plan

  variables {
    management_firewall_subnet_arm_id = "not-a-valid-resource-id"
  }

  expect_failures = [var.management_firewall_subnet_arm_id]
}

run "accepts_valid_management_bastion_subnet_arm_id" {
  command = plan

  variables {
    management_bastion_subnet_arm_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-net/providers/Microsoft.Network/virtualNetworks/vnet-mgmt/subnets/AzureBastionSubnet"
  }

  assert {
    condition     = output.environment == "DEV"
    error_message = "A parseable management_bastion_subnet_arm_id must be accepted."
  }
}

run "rejects_malformed_management_bastion_subnet_arm_id" {
  command = plan

  variables {
    management_bastion_subnet_arm_id = "not-a-valid-resource-id"
  }

  expect_failures = [var.management_bastion_subnet_arm_id]
}

run "accepts_valid_webapp_subnet_arm_id" {
  command = plan

  variables {
    webapp_subnet_arm_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-net/providers/Microsoft.Network/virtualNetworks/vnet-mgmt/subnets/snet-webapp"
  }

  assert {
    condition     = output.environment == "DEV"
    error_message = "A parseable webapp_subnet_arm_id must be accepted."
  }
}

run "rejects_malformed_webapp_subnet_arm_id" {
  command = plan

  variables {
    webapp_subnet_arm_id = "not-a-valid-resource-id"
  }

  expect_failures = [var.webapp_subnet_arm_id]
}

run "accepts_valid_management_subnet_nsg_arm_id" {
  command = plan

  variables {
    management_subnet_nsg_arm_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-net/providers/Microsoft.Network/networkSecurityGroups/nsg-management"
  }

  override_data {
    target = module.sap_deployer.data.azurerm_network_security_group.nsg_mgmt
    values = {
      id   = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-net/providers/Microsoft.Network/networkSecurityGroups/nsg-management"
      name = "nsg-management"
    }
  }

  assert {
    condition     = output.environment == "DEV"
    error_message = "A parseable management_subnet_nsg_arm_id must be accepted."
  }
}

run "rejects_malformed_management_subnet_nsg_arm_id" {
  command = plan

  variables {
    management_subnet_nsg_arm_id = "not-a-valid-resource-id"
  }

  expect_failures = [var.management_subnet_nsg_arm_id]
}

run "accepts_valid_user_keyvault_id" {
  command = plan

  variables {
    user_keyvault_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-kv/providers/Microsoft.KeyVault/vaults/kv-bootstrap"
  }

  override_data {
    target = module.sap_deployer.data.azurerm_key_vault.kv_user
    values = {
      id                          = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-kv/providers/Microsoft.KeyVault/vaults/kv-bootstrap"
      name                        = "kv-bootstrap"
      public_network_access_enabled = true
      tags                        = {}
    }
  }

  assert {
    condition     = output.environment == "DEV"
    error_message = "A parseable user_keyvault_id must be accepted."
  }
}

run "rejects_malformed_user_keyvault_id" {
  command = plan

  variables {
    user_keyvault_id = "not-a-valid-resource-id"
  }

  expect_failures = [var.user_keyvault_id]
}

run "accepts_valid_deployer_diagnostics_account_arm_id" {
  command = plan

  variables {
    deployer_diagnostics_account_arm_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-diag/providers/Microsoft.Storage/storageAccounts/stdiagbootstrap"
  }

  assert {
    condition     = output.environment == "DEV"
    error_message = "A parseable deployer_diagnostics_account_arm_id must be accepted."
  }
}

run "rejects_malformed_deployer_diagnostics_account_arm_id" {
  command = plan

  variables {
    deployer_diagnostics_account_arm_id = "not-a-valid-resource-id"
  }

  expect_failures = [var.deployer_diagnostics_account_arm_id]
}

run "accepts_valid_spn_id" {
  command = plan

  variables {
    spn_id = "11111111-1111-1111-1111-111111111111"
  }

  assert {
    condition     = output.environment == "DEV"
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

run "accepts_valid_management_dns_subscription_id" {
  command = plan

  variables {
    management_dns_subscription_id = "11111111-1111-1111-1111-111111111111"
  }

  assert {
    condition     = output.environment == "DEV"
    error_message = "A 36-character management DNS subscription ID must be accepted."
  }
}

run "rejects_management_dns_subscription_id_of_wrong_length" {
  command = plan

  variables {
    management_dns_subscription_id = "short-guid"
  }

  expect_failures = [var.management_dns_subscription_id]
}

run "accepts_valid_privatelink_dns_subscription_id" {
  command = plan

  variables {
    privatelink_dns_subscription_id = "11111111-1111-1111-1111-111111111111"
  }

  assert {
    condition     = output.environment == "DEV"
    error_message = "A 36-character PrivateLink DNS subscription ID must be accepted."
  }
}

run "rejects_privatelink_dns_subscription_id_of_wrong_length" {
  command = plan

  variables {
    privatelink_dns_subscription_id = "short-guid"
  }

  expect_failures = [var.privatelink_dns_subscription_id]
}

run "accepts_valid_devops_infrastructure_object_id" {
  command = plan

  variables {
    DevOpsInfrastructure_object_id = "11111111-1111-1111-1111-111111111111"
  }

  assert {
    condition     = output.environment == "DEV"
    error_message = "A 36-character DevOpsInfrastructure_object_id must be accepted."
  }
}

run "rejects_devops_infrastructure_object_id_of_wrong_length" {
  command = plan

  variables {
    DevOpsInfrastructure_object_id = "short-guid"
  }

  expect_failures = [var.DevOpsInfrastructure_object_id]
}

run "accepts_valid_agent_subnet_arm_id" {
  command = plan

  variables {
    agent_subnet_arm_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-net/providers/Microsoft.Network/virtualNetworks/vnet-mgmt/subnets/snet-agent"
  }

  assert {
    condition     = output.environment == "DEV"
    error_message = "A parseable agent_subnet_arm_id must be accepted."
  }
}

run "rejects_malformed_agent_subnet_arm_id" {
  command = plan

  variables {
    agent_subnet_arm_id = "not-a-valid-resource-id"
  }

  expect_failures = [var.agent_subnet_arm_id]
}

run "accepts_valid_app_registration_app_id" {
  command = plan

  variables {
    app_registration_app_id = "11111111-1111-1111-1111-111111111111"
  }

  assert {
    condition     = output.environment == "DEV"
    error_message = "A 36-character app registration ID must be accepted."
  }
}

run "rejects_app_registration_app_id_of_wrong_length" {
  command = plan

  variables {
    app_registration_app_id = "short-guid"
  }

  expect_failures = [var.app_registration_app_id]
}

run "accepts_valid_user_assigned_identity_id" {
  command = plan

  variables {
    user_assigned_identity_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-id/providers/Microsoft.ManagedIdentity/userAssignedIdentities/uami-bootstrap"
  }

  override_data {
    target = module.sap_deployer.data.azurerm_user_assigned_identity.deployer
    values = {
      id           = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-id/providers/Microsoft.ManagedIdentity/userAssignedIdentities/uami-bootstrap"
      tenant_id    = "11111111-1111-1111-1111-111111111111"
      principal_id = "22222222-2222-2222-2222-222222222222"
      client_id    = "33333333-3333-3333-3333-333333333333"
    }
  }

  assert {
    condition     = output.environment == "DEV"
    error_message = "A parseable user_assigned_identity_id must be accepted."
  }
}

run "rejects_malformed_user_assigned_identity_id" {
  command = plan

  variables {
    user_assigned_identity_id = "not-a-valid-resource-id"
  }

  expect_failures = [var.user_assigned_identity_id]
}

run "accepts_valid_network_security_perimeter_id" {
  command = plan

  variables {
    network_security_perimeter_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-sec/providers/Microsoft.Network/networkSecurityPerimeters/nsp-bootstrap"
  }

  assert {
    condition     = output.environment == "DEV"
    error_message = "A parseable network_security_perimeter_id must be accepted."
  }
}

run "rejects_malformed_network_security_perimeter_id" {
  command = plan

  variables {
    network_security_perimeter_id = "not-a-valid-resource-id"
  }

  expect_failures = [var.network_security_perimeter_id]
}
