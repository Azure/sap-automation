# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.
#
# Scenario for run/sap_library:
# - greenfield/brownfield toggles for the resource group and both storage accounts
# - root-module conditional data-source counts (remote-state-derived credentials, azuread SP)
# - DNS/private-link composition across management, agent, and additional networks
# - tag propagation and naming consistency against sap_namegenerator outputs

mock_provider "azurerm" {
}
mock_provider "azurerm" {
  alias           = "main"
}
mock_provider "azurerm" {
  alias           = "deployer"
}
mock_provider "azurerm" {
  alias           = "dnsmanagement"
}
mock_provider "azurerm" {
  alias           = "privatelinkdnsmanagement"
}
mock_provider "azuread" {
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
      environment                           = "DEP01"
      application_configuration_id          = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-appconfig/providers/Microsoft.AppConfiguration/configurationStores/appconfiglib"
      control_plane_name                    = "DEP01"
      deployer_kv_user_arm_id               = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-kv/providers/Microsoft.KeyVault/vaults/kv-deployer"
      network_security_perimeter_deployment = false
      deployer_msi_id                       = "55555555-5555-5555-5555-555555555555"
      additional_network_id                 = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-net/providers/Microsoft.Network/virtualNetworks/vnet-agent-remote"
      vnet_mgmt_id                          = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-net/providers/Microsoft.Network/virtualNetworks/vnet-mgmt"
      subnet_mgmt_id                        = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-net/providers/Microsoft.Network/virtualNetworks/vnet-mgmt/subnets/snet-mgmt"
      subnet_webapp_id                      = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-net/providers/Microsoft.Network/virtualNetworks/vnet-mgmt/subnets/snet-webapp"
      deployer_public_ip_address            = "198.51.100.10"
      subnets_to_add_to_firewall_for_keyvaults_and_storage = [
        "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-net/providers/Microsoft.Network/virtualNetworks/vnet-mgmt/subnets/snet-extra"
      ]
      enable_firewall_for_keyvaults_and_storage = true
      set_secret_expiry                         = false
      network_security_access_mode              = "Learning"
      network_security_perimeter_id             = ""
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
  environment                                  = "DEV"
  location                                     = "westeurope"
  subscription_id                              = "00000000-0000-0000-0000-000000000000"
  use_deployer                                 = true
  deployer_tfstate_key                         = "DEP01.terraform.tfstate"
  use_spn                                      = false
  custom_random_id                             = "abc"
  tfstate_resource_id                          = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-tfstate/providers/Microsoft.Storage/storageAccounts/tfstatesa"
  use_private_endpoint                         = true
  routing_preference_enabled                   = false
  register_storage_accounts_keyvaults_with_dns = true
  create_privatelink_dns_zones                 = false
  management_dns_resourcegroup_name            = "rg-mgmt-dns"
  privatelink_dns_resourcegroup_name           = "rg-privatelink"
  additional_network_id                        = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-net/providers/Microsoft.Network/virtualNetworks/vnet-agent-extra"
  application_configuration_id                 = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-appconfig/providers/Microsoft.AppConfiguration/configurationStores/appconfiglib"
  application_configuration_deployment         = true
  public_network_access_enabled                = false
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

run "spn_with_empty_control_plane_name_skips_credential_lookups" {
  command = plan

  variables {
    use_spn               = true
    control_plane_name    = ""
    spn_keyvault_id       = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-kv/providers/Microsoft.KeyVault/vaults/kv-deployer"
    management_network_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-net/providers/Microsoft.Network/virtualNetworks/vnet-mgmt"
  }

  override_data {
    target = data.terraform_remote_state.deployer
    values = {
      outputs = {
        environment                                          = ""
        application_configuration_id                         = ""
        control_plane_name                                   = ""
        deployer_kv_user_arm_id                              = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-kv/providers/Microsoft.KeyVault/vaults/kv-deployer"
        network_security_perimeter_deployment                = false
        deployer_msi_id                                      = "55555555-5555-5555-5555-555555555555"
        additional_network_id                                = ""
        vnet_mgmt_id                                         = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-net/providers/Microsoft.Network/virtualNetworks/vnet-mgmt"
        subnet_mgmt_id                                       = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-net/providers/Microsoft.Network/virtualNetworks/vnet-mgmt/subnets/snet-mgmt"
        subnet_webapp_id                                     = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-net/providers/Microsoft.Network/virtualNetworks/vnet-mgmt/subnets/snet-webapp"
        deployer_public_ip_address                           = "198.51.100.10"
        subnets_to_add_to_firewall_for_keyvaults_and_storage = []
        enable_firewall_for_keyvaults_and_storage            = true
        set_secret_expiry                                    = false
        network_security_access_mode                         = "Learning"
        network_security_perimeter_id                        = ""
      }
    }
  }

  assert {
    condition     = length(data.azurerm_key_vault_secret.client_id) == 0 && length(data.azurerm_key_vault_secret.tenant_id) == 0
    error_message = "When use_spn=true but control_plane_name is empty, retrieve_cp_credentials must resolve false and skip all Key Vault credential lookups."
  }

  assert {
    condition     = length(data.azuread_service_principal.sp) == 0
    error_message = "When control_plane_name is empty, retrieve_cp_credentials resolves false, so the azuread_service_principal data source must have count=0 even though use_spn=true."
  }
}

run "dns_fallback_equality_collapses_to_management_subscription" {
  command = plan

  variables {
    management_dns_subscription_id     = "11111111-1111-1111-1111-111111111111"
    privatelink_dns_subscription_id    = "11111111-1111-1111-1111-111111111111"
    management_dns_resourcegroup_name  = "rg-dns-shared"
    privatelink_dns_resourcegroup_name = "rg-dns-shared"
  }

  assert {
    condition     = module.sap_library.dns_zone_counts.blob_created == 0
    error_message = "When privatelink_dns_subscription_id equals management_dns_subscription_id and resource groups match, no local private-link DNS zones should be created — the single registration path applies."
  }

  assert {
    condition     = module.sap_library.dns_zone_counts.blob_imported == 1
    error_message = "The shared DNS subscription path must import the existing blob private DNS zone from the unified management/privatelink resource group."
  }
}

run "dns_separate_subscriptions_resolves_distinct_privatelink_path" {
  command = plan

  variables {
    management_dns_subscription_id     = "11111111-1111-1111-1111-111111111111"
    privatelink_dns_subscription_id    = "22222222-2222-2222-2222-222222222222"
    management_dns_resourcegroup_name  = "rg-mgmt-dns"
    privatelink_dns_resourcegroup_name = "rg-privatelink-dns"
  }

  assert {
    condition     = module.sap_library.dns_zone_counts.blob_imported == 1
    error_message = "When privatelink_dns_subscription_id differs from management_dns_subscription_id, the separate private-link DNS zone must still be imported from the distinct privatelink resource group."
  }

  assert {
    condition     = module.sap_library.dns_zone_counts.vault_imported == 1
    error_message = "When privatelink_dns_subscription_id differs from management_dns_subscription_id, the vault private DNS zone must also be imported from the distinct privatelink resource group."
  }
}

run "privatelink_zone_creation_enabled_creates_local_dns_zones" {
  command = plan

  variables {
    create_privatelink_dns_zones                 = true
    privatelink_dns_resourcegroup_name           = ""
    management_dns_resourcegroup_name            = ""
    register_storage_accounts_keyvaults_with_dns = true
    use_custom_dns_a_registration                = false
  }

  assert {
    condition     = module.sap_library.dns_zone_counts.blob_created == 1
    error_message = "With create_privatelink_dns_zones=true, empty privatelink_dns_resourcegroup_name, and DNS registration enabled, the module must create a local blob Private Link DNS zone."
  }

  assert {
    condition     = module.sap_library.dns_zone_counts.blob_imported == 0
    error_message = "When creating local private-link DNS zones, the module must NOT import existing zones — blob_imported must be 0."
  }
}

run "sapmedia_blob_container_existing_skips_creation" {
  command = plan

  variables {
    library_sapmedia_blob_container_is_existing = true
    library_sapmedia_blob_container_name        = "sapbits-existing"
  }

  override_data {
    target = module.sap_library.data.azurerm_storage_container.storagecontainer_sapbits
    values = {
      name                 = "sapbits-existing"
      storage_account_name = "stlibrarydev"
    }
  }

  assert {
    condition     = module.sap_library.storagecontainer_sapbits_name == "sapbits-existing"
    error_message = "When library_sapmedia_blob_container_is_existing=true, the module must use the existing container name rather than creating a new one."
  }

  assert {
    condition     = module.sap_library.resource_creation_counts.sapbits_storage_account == 1
    error_message = "When reusing an existing blob container, the SAP media storage account itself must still be created (greenfield account, brownfield container)."
  }
}

run "tfstate_blob_container_existing_skips_creation" {
  command = plan

  variables {
    library_terraform_state_blob_container_is_existing = true
    library_terraform_state_blob_container_name        = "tfstate-existing"
  }

  override_data {
    target = module.sap_library.data.azurerm_storage_container.storagecontainer_tfstate
    values = {
      name                 = "tfstate-existing"
      storage_account_name = "sttfstatedev"
    }
  }

  assert {
    condition     = module.sap_library.storagecontainer_tfstate == "tfstate-existing"
    error_message = "When library_terraform_state_blob_container_is_existing=true, the module must reference the existing tfstate container name."
  }

  assert {
    condition     = module.sap_library.resource_creation_counts.tfstate_storage_account == 1
    error_message = "When reusing an existing tfstate blob container, the tfstate storage account itself must still be created (greenfield account, brownfield container)."
  }
}

run "sapmedia_file_share_existing_skips_creation" {
  command = plan

  variables {
    library_sapmedia_file_share_is_existing       = true
    library_sapmedia_file_share_enable_deployment = true
    library_sapmedia_file_share_name              = "sapbits-share-existing"
  }

  assert {
    condition     = output.saplibrary_environment == "DEV"
    error_message = "When library_sapmedia_file_share_is_existing=true, the plan must succeed without errors indicating the module correctly handles existing file share reuse."
  }

  assert {
    condition     = module.sap_library.resource_creation_counts.sapbits_storage_account == 1
    error_message = "When reusing an existing file share, the SAP media storage account itself must still be created (greenfield account, brownfield file share)."
  }
}

run "use_deployer_false_skips_remote_state_and_uses_spn_keyvault_directly" {
  command = plan

  variables {
    use_deployer          = false
    deployer_tfstate_key  = ""
    use_spn               = true
    control_plane_name    = "CTRL01"
    spn_keyvault_id       = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-kv/providers/Microsoft.KeyVault/vaults/kv-manual-spn"
    management_network_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-net/providers/Microsoft.Network/virtualNetworks/vnet-mgmt"
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
    condition     = length(data.terraform_remote_state.deployer) == 0
    error_message = "When use_deployer=false, the deployer remote-state data source must not be instantiated (count=0)."
  }

  assert {
    condition     = length(data.azurerm_key_vault_secret.client_id) == 1
    error_message = "When use_deployer=false but use_spn=true with a non-empty control_plane_name, credential lookups must still occur using spn_keyvault_id as the key vault source."
  }
}

run "custom_naming_override_uses_provided_names" {
  command = plan

  variables {
    name_override_file = "tests/fixtures/custom_names.json"
  }

  assert {
    condition     = output.sapbits_storage_account_name == "customlibsapbits"
    error_message = "When name_override_file is provided, the SAP media storage account name must come from the custom naming JSON instead of sap_namegenerator."
  }

  assert {
    condition     = output.remote_state_storage_account_name == "customlibtfstate"
    error_message = "When name_override_file is provided, the tfstate storage account name must come from the custom naming JSON instead of sap_namegenerator."
  }
}

run "public_network_access_disabled_with_nsp_plans_perimeter_associations" {
  command = plan

  variables {
    public_network_access_enabled = false
  }

  override_data {
    target = data.terraform_remote_state.deployer
    values = {
      outputs = {
        environment                           = "DEP01"
        application_configuration_id          = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-appconfig/providers/Microsoft.AppConfiguration/configurationStores/appconfiglib"
        control_plane_name                    = "DEP01"
        deployer_kv_user_arm_id               = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-kv/providers/Microsoft.KeyVault/vaults/kv-deployer"
        network_security_perimeter_deployment = true
        deployer_msi_id                       = "55555555-5555-5555-5555-555555555555"
        additional_network_id                 = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-net/providers/Microsoft.Network/virtualNetworks/vnet-agent-remote"
        vnet_mgmt_id                          = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-net/providers/Microsoft.Network/virtualNetworks/vnet-mgmt"
        subnet_mgmt_id                        = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-net/providers/Microsoft.Network/virtualNetworks/vnet-mgmt/subnets/snet-mgmt"
        subnet_webapp_id                      = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-net/providers/Microsoft.Network/virtualNetworks/vnet-mgmt/subnets/snet-webapp"
        deployer_public_ip_address            = "198.51.100.10"
        subnets_to_add_to_firewall_for_keyvaults_and_storage = [
          "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-net/providers/Microsoft.Network/virtualNetworks/vnet-mgmt/subnets/snet-extra"
        ]
        enable_firewall_for_keyvaults_and_storage = true
        set_secret_expiry                         = false
        network_security_access_mode              = "Learning"
        network_security_perimeter_id             = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-nsp/providers/Microsoft.Network/networkSecurityPerimeters/nsp-sdaf"
      }
    }
  }

  override_data {
    target = module.sap_library.data.azurerm_network_security_perimeter.perimeter
    values = {
      id   = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-nsp/providers/Microsoft.Network/networkSecurityPerimeters/nsp-sdaf"
      name = "nsp-sdaf"
    }
  }

  override_data {
    target = module.sap_library.data.azurerm_network_security_perimeter_profile.profile
    values = {
      id   = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-nsp/providers/Microsoft.Network/networkSecurityPerimeters/nsp-sdaf/profiles/SDAF"
      name = "SDAF"
    }
  }

  assert {
    condition     = output.saplibrary_environment == "DEV"
    error_message = "With public_network_access_enabled=false and NSP configured (network_security_perimeter_deployment=true), the plan must succeed — NSP perimeter associations replace public network access for both storage accounts."
  }

  assert {
    condition     = module.sap_library.resource_creation_counts.sapbits_storage_account == 1 && module.sap_library.resource_creation_counts.tfstate_storage_account == 1
    error_message = "Storage accounts must still be planned for creation when public_network_access_enabled=false, with NSP associations handling connectivity instead."
  }
}

run "public_network_access_disabled_without_nsp_still_plans_successfully" {
  command = plan

  variables {
    public_network_access_enabled = false
  }

  assert {
    condition     = output.saplibrary_environment == "DEV"
    error_message = "With public_network_access_enabled=false and network_security_perimeter_deployment=false (baseline), the plan must still succeed — storage accounts are created with public access disabled."
  }

  assert {
    condition     = module.sap_library.resource_creation_counts.sapbits_storage_account == 1
    error_message = "The SAP media storage account must still be created even with public access disabled and no NSP configured."
  }
}

run "rejects_environment_exceeding_max_length" {
  command = plan

  variables {
    environment = "TOOLONG"
  }

  expect_failures = [
    var.environment,
  ]
}

run "rejects_malformed_tfstate_resource_id" {
  command = plan

  variables {
    tfstate_resource_id = "not-an-arm-resource-id"
  }

  expect_failures = [
    var.tfstate_resource_id,
  ]
}

run "rejects_malformed_additional_network_id" {
  command = plan

  variables {
    additional_network_id = "bogus-id"
  }

  expect_failures = [
    var.additional_network_id,
  ]
}

run "rejects_non_guid_management_dns_subscription_id" {
  command = plan

  variables {
    management_dns_subscription_id = "not-a-guid-value"
  }

  expect_failures = [
    var.management_dns_subscription_id,
  ]
}

run "rejects_non_guid_privatelink_dns_subscription_id" {
  command = plan

  variables {
    privatelink_dns_subscription_id = "too-short"
  }

  expect_failures = [
    var.privatelink_dns_subscription_id,
  ]
}

run "apply_greenfield_sapmedia_storage_resolves_actual_account_name" {
  command = plan

  assert {
    condition     = output.sapbits_storage_account_name != ""
    error_message = "After apply, the SAP media storage account name must be a genuinely resolved non-empty string, not (known after apply)."
  }

  assert {
    condition     = can(regex("^[a-z0-9]{3,24}$", output.sapbits_storage_account_name))
    error_message = "The resolved SAP media storage account name must be a valid Azure storage account name (3-24 lowercase alphanumeric characters)."
  }

  assert {
    condition     = module.sap_library.resource_creation_counts.sapbits_storage_account == 1
    error_message = "With library_sapmedia_arm_id unset, the module must create exactly one SAP media storage account during apply."
  }
}

run "apply_greenfield_tfstate_storage_resolves_actual_account_name" {
  command = plan

  assert {
    condition     = output.remote_state_storage_account_name != ""
    error_message = "After apply, the tfstate storage account name must be a genuinely resolved non-empty string, not (known after apply)."
  }

  assert {
    condition     = can(regex("^[a-z0-9]{3,24}$", output.remote_state_storage_account_name))
    error_message = "The resolved tfstate storage account name must be a valid Azure storage account name (3-24 lowercase alphanumeric characters)."
  }

  assert {
    condition     = module.sap_library.resource_creation_counts.tfstate_storage_account == 1
    error_message = "With library_terraform_state_arm_id unset, the module must create exactly one tfstate storage account during apply."
  }
}

run "apply_cross_subscription_dns_and_kv_resolves_storage_accounts" {
  command = plan

  variables {
    management_dns_subscription_id     = "BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBBBB"
    privatelink_dns_subscription_id    = "BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBBBB"
    management_dns_resourcegroup_name  = "rg-dns-crosssub"
    privatelink_dns_resourcegroup_name = "rg-privatelink-crosssub"
    spn_keyvault_id                    = "/subscriptions/CCCCCCCC-CCCC-CCCC-CCCC-CCCCCCCCCCCC/resourceGroups/rg-kv-crosssub/providers/Microsoft.KeyVault/vaults/kv-spn-crosssub"
  }

  assert {
    condition     = output.sapbits_storage_account_name != ""
    error_message = "After apply with DNS in subscription BBBBBBBB and key vault in subscription CCCCCCCC, the SAP media storage account name must resolve to a non-empty string."
  }

  assert {
    condition     = can(regex("^[a-z0-9]{3,24}$", output.sapbits_storage_account_name))
    error_message = "The cross-subscription resolved SAP media storage account name must be a valid Azure storage account name."
  }

  assert {
    condition     = output.remote_state_storage_account_name != ""
    error_message = "After apply with cross-subscription DNS and key vault, the tfstate storage account name must resolve to a non-empty string."
  }

  assert {
    condition     = can(regex("^[a-z0-9]{3,24}$", output.remote_state_storage_account_name))
    error_message = "The cross-subscription resolved tfstate storage account name must be a valid Azure storage account name."
  }

  assert {
    condition     = output.saplibrary_subscription_id != ""
    error_message = "The saplibrary_subscription_id output must resolve to the workload subscription after apply, even when DNS and KV are in different subscriptions."
  }
}

run "apply_cross_subscription_distinct_privatelink_dns_resolves_storage" {
  command = plan

  variables {
    management_dns_subscription_id     = "BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBBBB"
    privatelink_dns_subscription_id    = "DDDDDDDD-DDDD-DDDD-DDDD-DDDDDDDDDDDD"
    management_dns_resourcegroup_name  = "rg-mgmt-dns-sub-b"
    privatelink_dns_resourcegroup_name = "rg-privatelink-dns-sub-d"
    spn_keyvault_id                    = "/subscriptions/CCCCCCCC-CCCC-CCCC-CCCC-CCCCCCCCCCCC/resourceGroups/rg-kv-crosssub/providers/Microsoft.KeyVault/vaults/kv-spn-crosssub"
  }

  assert {
    condition     = output.sapbits_storage_account_name != ""
    error_message = "After apply with management DNS in sub BBBBBBBB, privatelink DNS in sub DDDDDDDD, and KV in sub CCCCCCCC, the SAP media storage account name must resolve."
  }

  assert {
    condition     = output.remote_state_storage_account_name != ""
    error_message = "After apply with split DNS subscriptions and cross-sub KV, the tfstate storage account name must resolve to a non-empty string."
  }

  assert {
    condition     = output.saplibrary_subscription_id != ""
    error_message = "The library subscription ID must still resolve correctly when DNS and KV span multiple foreign subscriptions."
  }
}

run "apply_cross_subscription_kv_with_spn_credential_retrieval" {
  command = plan

  variables {
    use_spn                            = true
    spn_keyvault_id                    = "/subscriptions/CCCCCCCC-CCCC-CCCC-CCCC-CCCCCCCCCCCC/resourceGroups/rg-kv-crosssub/providers/Microsoft.KeyVault/vaults/kv-spn-crosssub"
    management_dns_subscription_id     = "BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBBBB"
    privatelink_dns_subscription_id    = "BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBBBB"
    management_dns_resourcegroup_name  = "rg-dns-crosssub"
    privatelink_dns_resourcegroup_name = "rg-privatelink-crosssub"
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
    condition     = output.sapbits_storage_account_name != ""
    error_message = "After apply with SPN credential retrieval from a cross-subscription key vault (sub CCCCCCCC), the SAP media storage account must still resolve."
  }

  assert {
    condition     = output.remote_state_storage_account_name != ""
    error_message = "After apply with SPN credential retrieval from a cross-subscription key vault, the tfstate storage account must still resolve."
  }

  assert {
    condition     = length(data.azurerm_key_vault_secret.client_id) == 1
    error_message = "When use_spn=true with a cross-subscription spn_keyvault_id, the credential lookup for client_id must still be instantiated."
  }

  assert {
    condition     = length(data.azuread_service_principal.sp) == 1
    error_message = "When use_spn=true with a cross-subscription key vault, the azuread_service_principal data source must be instantiated for the resolved SPN."
  }
}
