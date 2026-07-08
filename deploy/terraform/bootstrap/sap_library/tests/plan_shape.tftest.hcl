# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.
#
# Plan-shape coverage for bootstrap/sap_library. These runs assert the
# greenfield/brownfield storage-account and resource-group toggles from
# transform.tf plus tag propagation and naming consistency with sap_namegenerator.

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
      application_configuration_id = ""
      control_plane_name           = "DEV-WEEU-DEP01"
      deployer_kv_user_arm_id      = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-kv/providers/Microsoft.KeyVault/vaults/kv-bootstrap"
      additional_network_id        = ""
      subnet_mgmt_id               = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-net/providers/Microsoft.Network/virtualNetworks/vnet-mgmt/subnets/snet-management"
      environment                  = "DEV"
      network_security_perimeter_deployment = false
    }
  }
}

variables {
  environment                               = "DEV"
  location                                  = "westeurope"
  subscription_id                           = "00000000-0000-0000-0000-000000000000"
  use_spn                                   = false
  deployer_statefile_foldername             = "."
  use_deployer                              = false
  use_private_endpoint                      = false
  register_storage_accounts_keyvaults_with_dns = false
  create_privatelink_dns_zones              = false
  management_network_id                     = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-net/providers/Microsoft.Network/virtualNetworks/vnet-mgmt"
  spn_keyvault_id                           = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-kv/providers/Microsoft.KeyVault/vaults/kv-bootstrap"
  custom_random_id                          = "abc"
  tags = {
    Module   = "bootstrap-sap-library"
    Scenario = "greenfield"
  }
  resourcegroup_tags = {
    Purpose = "terraform-test"
  }
}

run "greenfield_naming_and_tags_flow_to_created_resources" {
  command = plan

  assert {
    condition     = module.sap_library.resource_creation_counts.resource_group == 1 && module.sap_library.resource_creation_counts.sapbits_storage_account == 1 && module.sap_library.resource_creation_counts.tfstate_storage_account == 1
    error_message = "With no brownfield ARM IDs supplied, bootstrap/sap_library must create its resource group plus both storage accounts."
  }

  assert {
    condition     = can(regex(module.sap_namegenerator.naming.prefix.LIBRARY, output.created_resource_group_name)) && output.sapbits_storage_account_name == module.sap_namegenerator.naming.storageaccount_names.LIBRARY.library_storageaccount_name && output.remote_state_storage_account_name == module.sap_namegenerator.naming.storageaccount_names.LIBRARY.terraformstate_storageaccount_name
    error_message = "bootstrap/sap_library must embed the sap_namegenerator LIBRARY prefix in the greenfield resource-group name and use sap_namegenerator's default storage-account names."
  }

  assert {
    condition     = module.sap_library.resource_tags.resource_group["Purpose"] == "terraform-test" && module.sap_library.resource_tags.sapbits_storage_account["Purpose"] == "terraform-test" && module.sap_library.resource_tags.tfstate_storage_account["Purpose"] == "terraform-test"
    error_message = "The effective infrastructure tags (resourcegroup_tags taking precedence over tags) must propagate into the created library resource group and both created storage accounts."
  }
}

run "brownfield_resource_group_and_storage_accounts_are_reused" {
  command = plan

  variables {
    resourcegroup_arm_id          = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-bootstrap"
    library_sapmedia_arm_id       = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-lib/providers/Microsoft.Storage/storageAccounts/stsapbitsboot"
    library_terraform_state_arm_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-lib/providers/Microsoft.Storage/storageAccounts/sttfstateboot"
    tags = {
      Module   = "bootstrap-sap-library"
      Scenario = "brownfield"
    }
  }

  override_data {
    target = module.sap_library.data.azurerm_resource_group.library
    values = {
      id       = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-bootstrap"
      name     = "rg-bootstrap"
      location = "westeurope"
      tags = {
        Module   = "bootstrap-sap-library"
        Scenario = "brownfield"
      }
    }
  }

  override_data {
    target = module.sap_library.data.azurerm_storage_account.storage_sapbits
    values = {
      id                         = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-lib/providers/Microsoft.Storage/storageAccounts/stsapbitsboot"
      name                       = "stsapbitsboot"
      resource_group_name        = "rg-lib"
      primary_connection_string  = "UseDevelopmentStorage=true;sapbits"
      tags = {
        Module   = "bootstrap-sap-library"
        Scenario = "brownfield"
      }
    }
  }

  override_data {
    target = module.sap_library.data.azurerm_storage_account.storage_tfstate
    values = {
      id                         = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-lib/providers/Microsoft.Storage/storageAccounts/sttfstateboot"
      name                       = "sttfstateboot"
      resource_group_name        = "rg-lib"
      primary_connection_string  = "UseDevelopmentStorage=true;tfstate"
      tags = {
        Module   = "bootstrap-sap-library"
        Scenario = "brownfield"
      }
    }
  }

  assert {
    condition     = module.sap_library.resource_creation_counts.resource_group == 0 && module.sap_library.resource_creation_counts.sapbits_storage_account == 0 && module.sap_library.resource_creation_counts.tfstate_storage_account == 0
    error_message = "Supplying brownfield ARM IDs for the resource group and both storage accounts must suppress creation of replacement library infrastructure."
  }

  assert {
    condition     = output.created_resource_group_id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-bootstrap" && output.tfstate_resource_id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-lib/providers/Microsoft.Storage/storageAccounts/sttfstateboot" && output.sapbits_storage_account_name == "stsapbitsboot" && output.remote_state_storage_account_name == "sttfstateboot"
    error_message = "The brownfield library scenario must surface the existing resource-group and storage-account identities verbatim through the root outputs."
  }

  assert {
    condition     = module.sap_library.resource_tags.resource_group["Scenario"] == "brownfield" && module.sap_library.resource_tags.sapbits_storage_account["Module"] == "bootstrap-sap-library" && module.sap_library.resource_tags.tfstate_storage_account["Scenario"] == "brownfield"
    error_message = "Tag assertions must stay concrete in the brownfield branch too: the looked-up resource group and both looked-up storage accounts must expose the supplied brownfield tag values."
  }
}
