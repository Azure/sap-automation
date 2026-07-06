# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.
#
# Scenario Categories 3, 4, and 5 for run/sap_library:
# - greenfield/brownfield toggles for the resource group and both storage accounts
# - root-module conditional data-source counts (remote-state-derived credentials, azuread SP)
# - DNS/private-link composition across management, agent, and additional networks
# - tag propagation and naming consistency against sap_namegenerator outputs

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
      application_configuration_id           = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-appconfig/providers/Microsoft.AppConfiguration/configurationStores/appconfiglib"
      control_plane_name                     = "DEP01"
      deployer_kv_user_arm_id                = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-kv/providers/Microsoft.KeyVault/vaults/kv-deployer"
      network_security_perimeter_deployment  = false
      deployer_msi_id                        = "55555555-5555-5555-5555-555555555555"
      additional_network_id                  = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-net/providers/Microsoft.Network/virtualNetworks/vnet-agent-remote"
      vnet_mgmt_id                           = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-net/providers/Microsoft.Network/virtualNetworks/vnet-mgmt"
      subnet_mgmt_id                         = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-net/providers/Microsoft.Network/virtualNetworks/vnet-mgmt/subnets/snet-mgmt"
      subnet_webapp_id                       = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-net/providers/Microsoft.Network/virtualNetworks/vnet-mgmt/subnets/snet-webapp"
      deployer_public_ip_address             = "198.51.100.10"
      subnets_to_add_to_firewall_for_keyvaults_and_storage = [
        "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-net/providers/Microsoft.Network/virtualNetworks/vnet-mgmt/subnets/snet-extra"
      ]
      enable_firewall_for_keyvaults_and_storage            = true
      set_secret_expiry                      = false
      network_security_access_mode           = "Learning"
      network_security_perimeter_id          = ""
    }
  }
}

override_data {
  target = module.sap_library.data.azurerm_private_dns_zone.storage
  values = {
    id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-privatelink/providers/Microsoft.Network/privateDnsZones/privatelink.blob.core.windows.net"
  }
}

override_data {
  target = module.sap_library.data.azurerm_private_dns_zone.table
  values = {
    id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-privatelink/providers/Microsoft.Network/privateDnsZones/privatelink.table.core.windows.net"
  }
}

override_data {
  target = module.sap_library.data.azurerm_private_dns_zone.vault
  values = {
    id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-privatelink/providers/Microsoft.Network/privateDnsZones/privatelink.vaultcore.azure.net"
  }
}

override_data {
  target = module.sap_library.data.azurerm_private_dns_zone.appconfig
  values = {
    id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-privatelink/providers/Microsoft.Network/privateDnsZones/privatelink.azconfig.io"
  }
}

override_data {
  target = module.sap_library.data.azurerm_app_configuration.app_config
  values = {
    id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-appconfig/providers/Microsoft.AppConfiguration/configurationStores/appconfiglib"
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
  use_private_endpoint                      = true
  register_storage_accounts_keyvaults_with_dns = true
  create_privatelink_dns_zones              = false
  management_dns_resourcegroup_name         = "rg-mgmt-dns"
  privatelink_dns_resourcegroup_name        = "rg-privatelink"
  additional_network_id                     = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-net/providers/Microsoft.Network/virtualNetworks/vnet-agent-extra"
  application_configuration_id              = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-appconfig/providers/Microsoft.AppConfiguration/configurationStores/appconfiglib"
  application_configuration_deployment      = true
  public_network_access_enabled             = false
  tags = {
    Environment = "DEV"
    Workload    = "sap-library"
    Owner       = "terraform-test"
  }
}

run "greenfield_resource_group_creates_expected_name" {
  command = plan

  assert {
    condition     = module.sap_library.resource_creation_counts.resource_group == 1
    error_message = "With resourcegroup_arm_id unset, run/sap_library must create exactly one resource group through the greenfield branch."
  }

  assert {
    condition     = output.created_resource_group_name == format("%s%s%s", module.sap_namegenerator.naming.resource_prefixes.library_rg, module.sap_namegenerator.naming.prefix.LIBRARY, module.sap_namegenerator.naming.resource_suffixes.library_rg)
    error_message = "The greenfield resource-group name must come from sap_namegenerator's LIBRARY naming contract, not a hard-coded string."
  }
}

run "brownfield_resource_group_reuses_existing_group" {
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
      tags = {
        Environment = "DEV"
        Workload    = "sap-library"
      }
    }
  }

  assert {
    condition     = module.sap_library.resource_creation_counts.resource_group == 0
    error_message = "With resourcegroup_arm_id provided, the module must not create a new resource group."
  }

  assert {
    condition     = output.created_resource_group_name == "rg-existing-library"
    error_message = "The brownfield resource-group branch must surface the looked-up existing group name from data.azurerm_resource_group.library."
  }
}

run "greenfield_sapmedia_storage_creates_expected_account" {
  command = plan

  assert {
    condition     = module.sap_library.resource_creation_counts.sapbits_storage_account == 1
    error_message = "With library_sapmedia_arm_id unset, the module must create exactly one SAP media storage account."
  }

  assert {
    condition     = output.sapbits_storage_account_name == module.sap_namegenerator.naming.storageaccount_names.LIBRARY.library_storageaccount_name
    error_message = "The greenfield SAP media storage account name must come from sap_namegenerator's LIBRARY storage-account naming output."
  }
}

run "brownfield_sapmedia_storage_reuses_existing_account" {
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
      tags = {
        Environment = "DEV"
        Workload    = "sap-library"
      }
    }
  }

  assert {
    condition     = module.sap_library.resource_creation_counts.sapbits_storage_account == 0
    error_message = "With library_sapmedia_arm_id provided, the module must not create a new SAP media storage account."
  }

  assert {
    condition     = output.sapbits_storage_account_name == "stsapbitsexisting"
    error_message = "The brownfield SAP media path must surface the existing storage-account name from the imported ARM ID."
  }
}

run "greenfield_tfstate_storage_creates_expected_account" {
  command = plan

  assert {
    condition     = module.sap_library.resource_creation_counts.tfstate_storage_account == 1
    error_message = "With library_terraform_state_arm_id unset, the module must create exactly one tfstate storage account."
  }

  assert {
    condition     = output.remote_state_storage_account_name == module.sap_namegenerator.naming.storageaccount_names.LIBRARY.terraformstate_storageaccount_name
    error_message = "The greenfield tfstate storage account name must come from sap_namegenerator's LIBRARY terraform-state storage naming output."
  }
}

run "brownfield_tfstate_storage_reuses_existing_account" {
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
      tags = {
        Environment = "DEV"
        Workload    = "sap-library"
      }
    }
  }

  assert {
    condition     = module.sap_library.resource_creation_counts.tfstate_storage_account == 0
    error_message = "With library_terraform_state_arm_id provided, the module must not create a new tfstate storage account."
  }

  assert {
    condition     = output.remote_state_storage_account_name == "sttfstateexisting"
    error_message = "The brownfield tfstate path must surface the existing storage-account name from the imported ARM ID."
  }
}

run "spn_enabled_retrieves_control_plane_credentials_and_service_principal" {
  command = plan

  variables {
    use_spn = true
  }

  override_data {
    target = data.azurerm_key_vault_secret.subscription_id
    values = {
      value = "00000000-0000-0000-0000-000000000000"
    }
  }

  override_data {
    target = data.azurerm_key_vault_secret.client_id
    values = {
      value = "66666666-6666-6666-6666-666666666666"
    }
  }

  override_data {
    target = data.azurerm_key_vault_secret.client_secret
    values = {
      value = "diagnostic-client-secret"
    }
  }

  override_data {
    target = data.azurerm_key_vault_secret.tenant_id
    values = {
      value = "77777777-7777-7777-7777-777777777777"
    }
  }

  override_data {
    target = data.azuread_service_principal.sp
    values = {
      object_id = "88888888-8888-8888-8888-888888888888"
      client_id = "66666666-6666-6666-6666-666666666666"
    }
  }

  assert {
    condition     = length(data.azurerm_key_vault_secret.client_id) == 1 && length(data.azurerm_key_vault_secret.client_secret) == 1 && length(data.azurerm_key_vault_secret.tenant_id) == 1
    error_message = "When retrieve_cp_credentials is true (use_spn=true with a resolved control-plane name), all three control-plane credential Key Vault lookups must be present."
  }

  assert {
    condition     = length(data.azuread_service_principal.sp) == 1
    error_message = "When local.use_spn resolves true, the azuread_service_principal data source must be instantiated exactly once."
  }
}

run "spn_disabled_skips_control_plane_credentials_and_service_principal" {
  command = plan

  assert {
    condition     = length(data.azurerm_key_vault_secret.client_id) == 0 && length(data.azurerm_key_vault_secret.client_secret) == 0 && length(data.azurerm_key_vault_secret.tenant_id) == 0
    error_message = "When retrieve_cp_credentials is false (the baseline use_spn=false path), no control-plane credential Key Vault lookups should be instantiated."
  }

  assert {
    condition     = length(data.azuread_service_principal.sp) == 0
    error_message = "When local.use_spn resolves false, the azuread_service_principal data source must have count = 0."
  }
}

run "dns_and_private_link_settings_compose_across_all_networks" {
  command = plan

  assert {
    condition     = module.sap_library.dns_zone_counts.blob_created == 0 && module.sap_library.dns_zone_counts.blob_imported == 1 && module.sap_library.dns_zone_counts.vault_imported == 1
    error_message = "With create_privatelink_dns_zones=false and DNS registration enabled, the module must import existing blob/vault Private Link zones instead of creating local replacements."
  }

  assert {
    condition     = module.sap_library.private_endpoint_counts.storage_tfstate == 1
    error_message = "With use_private_endpoint=true and the tfstate storage account greenfield, the module must create exactly one blob private endpoint for tfstate."
  }

  assert {
    condition     = module.sap_library.private_endpoint_counts.storage_sapbits == 1
    error_message = "With use_private_endpoint=true and the SAP media storage account greenfield, the module must create exactly one blob private endpoint for SAP media."
  }

  assert {
    condition     = module.sap_library.private_endpoint_counts.table_tfstate == 1
    error_message = "With application_configuration_deployment=true, the module must create exactly one table private endpoint for the tfstate storage account."
  }

  assert {
    condition     = module.sap_library.dns_link_counts.vault_additional == 1 && module.sap_library.dns_link_counts.blob_agent == 1 && module.sap_library.dns_link_counts.appconfig_management == 1 && module.sap_library.dns_link_counts.appconfig_additional == 1 && module.sap_library.dns_link_counts.appconfig_agent == 1
    error_message = "The baseline fixture's management, agent, and additional-network inputs must each contribute the expected DNS-link resources for vault/blob/appconfig registration."
  }
}

run "tags_and_namegenerator_contract_propagate_to_created_resources" {
  command = plan

  assert {
    condition     = module.sap_library.resource_tags.resource_group["Workload"] == "sap-library" && module.sap_library.resource_tags.sapbits_storage_account["Workload"] == "sap-library" && module.sap_library.resource_tags.tfstate_storage_account["Workload"] == "sap-library"
    error_message = "The tags input map must propagate from run/sap_library into the created resource group and both created storage accounts."
  }

  assert {
    condition     = output.created_resource_group_name == format("%s%s%s", module.sap_namegenerator.naming.resource_prefixes.library_rg, module.sap_namegenerator.naming.prefix.LIBRARY, module.sap_namegenerator.naming.resource_suffixes.library_rg) && output.sapbits_storage_account_name == module.sap_namegenerator.naming.storageaccount_names.LIBRARY.library_storageaccount_name && output.remote_state_storage_account_name == module.sap_namegenerator.naming.storageaccount_names.LIBRARY.terraformstate_storageaccount_name
    error_message = "run/sap_library must consistently pass sap_namegenerator's LIBRARY naming outputs through to the resource group, SAP media storage account, and tfstate storage account."
  }
}
