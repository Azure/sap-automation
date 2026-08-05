# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.
#
# Scenario Category (variable contract/validation logic) for every `validation` block
# declared on run/sap_system's own variables (variables_global.tf Lines 70, 85;
# tfvar_variables.tf - environment, location, network_logical_name, database_platform,
# sid, resourcegroup_arm_id, the 12 *_subnet_arm_id/*_subnet_nsg_arm_id/user_keyvault_id/
# spn_keyvault_id/user_assigned_identity_id/application_configuration_id ARM-ID variables,
# the 6 *_use_avset/*_use_ppg tobool-required variables, and the 3 *_subscription_id
# GUID-length variables). Every validated variable below has at least one positive-path
# run block (accepts valid input) and one negative-path run block using expect_failures
# (rejects invalid input), per the plan's Acceptance Criteria Principles.

mock_provider "azurerm" {
}
mock_provider "azurerm" {
  alias           = "deployer"
}
mock_provider "azurerm" {
  alias           = "system"
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

variables {
  environment           = "DEV"
  location              = "westeurope"
  network_logical_name  = "SAP01"
  sid                   = "ABC"
  tfstate_resource_id   = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-tfstate/providers/Microsoft.Storage/storageAccounts/tfstatesa"
  landscape_tfstate_key = "LAND-WEEU-SAP01-INFRASTRUCTURE.terraform.tfstate"
  subscription_id       = "00000000-0000-0000-0000-000000000000"

  spn_keyvault_id  = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-kv/providers/Microsoft.KeyVault/vaults/kv-spn"
  user_keyvault_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-kv/providers/Microsoft.KeyVault/vaults/kv-user"

  database_platform  = "HANA"
  database_size      = "Default"
  database_use_avset = true
  database_use_ppg   = false
  database_vm_image = {
    os_type         = "LINUX"
    source_image_id = null
    publisher       = "SUSE"
    offer           = "sles-sap-15-sp5"
    sku             = "gen2"
    version         = "latest"
    type            = "marketplace"
  }

  scs_server_use_avset         = true
  scs_server_use_ppg           = false
  application_server_use_avset = true
  application_server_use_ppg   = false
}

override_data {
  target = data.terraform_remote_state.landscape
  values = {
    outputs = {
      automation_version            = "5.0.0"
      control_plane_name            = "DEV-WEEU-DEP01"
      controlplane_environment      = "DEV"
      workload_zone_name            = "DEV-WEEU-SAP01"
      workload_zone_prefix          = "DEV-WEEU-SAP01"
      workloadzone_kv_name          = "kv-user"
      random_id                     = "abc"
      use_spn                       = true
      public_network_access_enabled = true

      created_resource_group_id              = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-landscape"
      created_resource_group_name            = "rg-landscape"
      created_resource_group_subscription_id = "00000000-0000-0000-0000-000000000000"

      vnet_sap_arm_id             = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-landscape/providers/Microsoft.Network/virtualNetworks/vnet-sap01"
      admin_subnet_id             = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-landscape/providers/Microsoft.Network/virtualNetworks/vnet-sap01/subnets/admin"
      admin_nsg_id                = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-landscape/providers/Microsoft.Network/networkSecurityGroups/nsg-admin"
      db_subnet_id                = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-landscape/providers/Microsoft.Network/virtualNetworks/vnet-sap01/subnets/db"
      db_nsg_id                   = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-landscape/providers/Microsoft.Network/networkSecurityGroups/nsg-db"
      app_subnet_id               = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-landscape/providers/Microsoft.Network/virtualNetworks/vnet-sap01/subnets/app"
      app_nsg_id                  = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-landscape/providers/Microsoft.Network/networkSecurityGroups/nsg-app"
      web_subnet_id               = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-landscape/providers/Microsoft.Network/virtualNetworks/vnet-sap01/subnets/web"
      web_nsg_id                  = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-landscape/providers/Microsoft.Network/networkSecurityGroups/nsg-web"
      storage_subnet_id           = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-landscape/providers/Microsoft.Network/virtualNetworks/vnet-sap01/subnets/storage"
      storage_nsg_id              = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-landscape/providers/Microsoft.Network/networkSecurityGroups/nsg-storage"
      ams_subnet_id               = ""
      route_table_id              = ""
      subnet_mgmt_id              = ""
      use_separate_storage_subnet = true

      landscape_key_vault_private_arm_id = ""
      landscape_key_vault_spn_arm_id     = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-landscape/providers/Microsoft.KeyVault/vaults/kv-landscape-spn"
      landscape_key_vault_user_arm_id    = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-landscape/providers/Microsoft.KeyVault/vaults/kv-user"
      user_credential_vault_id           = ""
      spn_credential_vault_id            = ""
      spn_kv_id                          = ""
      sid_password_secret_name           = "sid-password"
      sid_public_key_secret_name         = "sid-public-key"
      sid_username_secret_name           = "sid-username"

      iscsi_authentication_username = ""
      iscsi_authentication_type     = ""
      iscsi_private_ip              = []
      iSCSI_server_ips              = []
      iSCSI_server_names            = []
      iSCSI_servers                 = []

      dns_info_iscsi                               = []
      dns_label                                    = ""
      dns_resource_group_name                      = "rg-landscape"
      management_dns_resourcegroup_name            = ""
      management_dns_subscription_id               = ""
      privatelink_dns_resourcegroup_name           = ""
      privatelink_dns_subscription_id              = ""
      privatelink_file_id                          = ""
      register_virtual_network_to_dns              = false
      register_storage_accounts_keyvaults_with_dns = false
      use_custom_dns_a_registration                = false

      storageaccount_name           = "stlandscapediag"
      storageaccount_rg_name        = "rg-landscape"
      transport_storage_account_id  = ""
      witness_storage_account       = ""
      witness_storage_account_key   = ""
      utility_storage_account_ids   = []
      utility_storage_account_names = []

      ANF_pool_settings = {}
      install_path      = ""
      saptransport_path = ""

      application_configuration_id   = ""
      application_configuration_name = ""

      ams_resource_id = ""
    }
  }
}

override_data {
  target = module.common_infrastructure.data.azurerm_subnet.admin
  values = {
    id               = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-landscape/providers/Microsoft.Network/virtualNetworks/vnet-sap01/subnets/admin"
    address_prefixes = ["10.1.0.0/24"]
  }
}

override_data {
  target = module.common_infrastructure.data.azurerm_subnet.db
  values = {
    id               = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-landscape/providers/Microsoft.Network/virtualNetworks/vnet-sap01/subnets/db"
    address_prefixes = ["10.1.1.0/24"]
  }
}

override_data {
  target = module.common_infrastructure.data.azurerm_subnet.storage
  values = {
    id               = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-landscape/providers/Microsoft.Network/virtualNetworks/vnet-sap01/subnets/storage"
    address_prefixes = ["10.1.2.0/24"]
  }
}

override_data {
  target = module.common_infrastructure.data.azurerm_key_vault.sid_keyvault_user
  values = {
    id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-kv/providers/Microsoft.KeyVault/vaults/kv-user"
  }
}

override_data {
  target = data.azurerm_app_configuration_key.media_path
  values = {
    value = ""
  }
}

override_data {
  target = data.azurerm_app_configuration_key.credentials_vault
  values = {
    value = ""
  }
}

override_data {
  target = data.azurerm_app_configuration_key.workload_credentials_vault
  values = {
    value = ""
  }
}

override_data {
  target = module.common_infrastructure.data.azurerm_key_vault_secret.sid_pk
  values = {
    value = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCU51GUHdJHlxNoZrvt4bYCSX20Umzij0faob4Ud13/JG6tHbCjgUUVNgmYbAfEHJT0/Vox72Wo4OezrdDdnwhMY+RmRGkcUZq1HE/x5g7yJpPvzCmrvxv25f4w3Er2B6tPeOSStA+eA42vmVbJh20hXveqmA7SsybuYRRd1SZh1VfuWNdfHIAYZQarA169XELRWR0XO8bylT17HLNNWSYiOcOzGEHftMJ7CWlpxU54n9X6hIZ8fmDrLoFBaCb8SIM7VC3dGpRA8g6HJke/ge+MdEkQtSszo0IxcAxeNRGdyIMG/4Ns/mnveudk+7IwoVvuNwn4M1SY9ApGu8RK05Jl diagnostic-only"
  }
}


run "baseline_variables_are_accepted" {
  command = plan

  assert {
    condition     = output.environment == "DEV"
    error_message = "The baseline fixture used for all positive-path validation assertions must itself plan successfully."
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

run "rejects_environment_over_five_characters" {
  command = plan

  variables {
    environment = "TOOLONGENV"
  }

  expect_failures = [
    var.environment,
  ]
}

run "rejects_empty_location" {
  command = plan

  variables {
    location = ""
  }

  expect_failures = [
    var.location,
  ]
}

run "rejects_empty_network_logical_name" {
  command = plan

  variables {
    network_logical_name = ""
  }

  expect_failures = [
    var.network_logical_name,
  ]
}

run "rejects_empty_database_platform" {
  command = plan

  variables {
    database_platform = ""
  }

  expect_failures = [
    var.database_platform,
  ]
}

run "rejects_sid_not_exactly_three_characters" {
  command = plan

  variables {
    sid = "ABCD"
  }

  expect_failures = [
    var.sid,
  ]
}

run "rejects_blank_landscape_tfstate_key" {
  command = plan

  variables {
    landscape_tfstate_key = "   "
  }

  expect_failures = [
    var.landscape_tfstate_key,
  ]
}

run "rejects_malformed_tfstate_resource_id" {
  command = plan

  variables {
    tfstate_resource_id = "not-a-valid-resource-id"
  }

  expect_failures = [
    var.tfstate_resource_id,
  ]
}

run "accepts_valid_arm_ids_for_all_optional_resource_id_variables" {
  command = plan

  variables {
    resourcegroup_arm_id         = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-sap"
    admin_subnet_arm_id          = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-net/providers/Microsoft.Network/virtualNetworks/vnet/subnets/admin"
    admin_subnet_nsg_arm_id      = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-net/providers/Microsoft.Network/networkSecurityGroups/nsg-admin"
    db_subnet_arm_id             = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-net/providers/Microsoft.Network/virtualNetworks/vnet/subnets/db"
    db_subnet_nsg_arm_id         = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-net/providers/Microsoft.Network/networkSecurityGroups/nsg-db"
    app_subnet_arm_id            = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-net/providers/Microsoft.Network/virtualNetworks/vnet/subnets/app"
    app_subnet_nsg_arm_id        = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-net/providers/Microsoft.Network/networkSecurityGroups/nsg-app"
    web_subnet_arm_id            = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-net/providers/Microsoft.Network/virtualNetworks/vnet/subnets/web"
    web_subnet_nsg_arm_id        = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-net/providers/Microsoft.Network/networkSecurityGroups/nsg-web"
    storage_subnet_arm_id        = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-net/providers/Microsoft.Network/virtualNetworks/vnet/subnets/storage"
    storage_subnet_nsg_arm_id    = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-net/providers/Microsoft.Network/networkSecurityGroups/nsg-storage"
    user_keyvault_id             = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-kv/providers/Microsoft.KeyVault/vaults/kv-user"
    spn_keyvault_id              = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-kv/providers/Microsoft.KeyVault/vaults/kv-spn"
    user_assigned_identity_id    = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-id/providers/Microsoft.ManagedIdentity/userAssignedIdentities/uami"
    application_configuration_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-appconfig/providers/Microsoft.AppConfiguration/configurationStores/appconfig"
  }

  assert {
    condition     = output.environment == "DEV"
    error_message = "Valid Azure resource IDs must be accepted for every optional *_arm_id/*_id variable without tripping any validation block."
  }
}

run "rejects_malformed_resourcegroup_arm_id" {
  command = plan

  variables {
    resourcegroup_arm_id = "not-a-valid-resource-id"
  }

  expect_failures = [
    var.resourcegroup_arm_id,
  ]
}

run "rejects_malformed_admin_subnet_arm_id" {
  command = plan

  variables {
    admin_subnet_arm_id = "not-a-valid-resource-id"
  }

  expect_failures = [
    var.admin_subnet_arm_id,
  ]
}

run "rejects_malformed_admin_subnet_nsg_arm_id" {
  command = plan

  variables {
    admin_subnet_nsg_arm_id = "not-a-valid-resource-id"
  }

  expect_failures = [
    var.admin_subnet_nsg_arm_id,
  ]
}

run "rejects_malformed_db_subnet_arm_id" {
  command = plan

  variables {
    db_subnet_arm_id = "not-a-valid-resource-id"
  }

  expect_failures = [
    var.db_subnet_arm_id,
  ]
}

run "rejects_malformed_db_subnet_nsg_arm_id" {
  command = plan

  variables {
    db_subnet_nsg_arm_id = "not-a-valid-resource-id"
  }

  expect_failures = [
    var.db_subnet_nsg_arm_id,
  ]
}

run "rejects_malformed_app_subnet_arm_id" {
  command = plan

  variables {
    app_subnet_arm_id = "not-a-valid-resource-id"
  }

  expect_failures = [
    var.app_subnet_arm_id,
  ]
}

run "rejects_malformed_app_subnet_nsg_arm_id" {
  command = plan

  variables {
    app_subnet_nsg_arm_id = "not-a-valid-resource-id"
  }

  expect_failures = [
    var.app_subnet_nsg_arm_id,
  ]
}

run "rejects_malformed_web_subnet_arm_id" {
  command = plan

  variables {
    web_subnet_arm_id = "not-a-valid-resource-id"
  }

  expect_failures = [
    var.web_subnet_arm_id,
  ]
}

run "rejects_malformed_web_subnet_nsg_arm_id" {
  command = plan

  variables {
    web_subnet_nsg_arm_id = "not-a-valid-resource-id"
  }

  expect_failures = [
    var.web_subnet_nsg_arm_id,
  ]
}

run "rejects_malformed_storage_subnet_arm_id" {
  command = plan

  variables {
    storage_subnet_arm_id = "not-a-valid-resource-id"
  }

  expect_failures = [
    var.storage_subnet_arm_id,
  ]
}

run "rejects_malformed_storage_subnet_nsg_arm_id" {
  command = plan

  variables {
    storage_subnet_nsg_arm_id = "not-a-valid-resource-id"
  }

  expect_failures = [
    var.storage_subnet_nsg_arm_id,
  ]
}

run "rejects_malformed_user_keyvault_id" {
  command = plan

  variables {
    user_keyvault_id = "not-a-valid-resource-id"
  }

  expect_failures = [
    var.user_keyvault_id,
  ]
}

run "rejects_malformed_spn_keyvault_id" {
  command = plan

  variables {
    spn_keyvault_id = "not-a-valid-resource-id"
  }

  expect_failures = [
    var.spn_keyvault_id,
  ]
}

run "rejects_malformed_user_assigned_identity_id" {
  command = plan

  variables {
    user_assigned_identity_id = "not-a-valid-resource-id"
  }

  expect_failures = [
    var.user_assigned_identity_id,
  ]
}

run "rejects_malformed_application_configuration_id" {
  command = plan

  variables {
    application_configuration_id = "not-a-valid-resource-id"
  }

  expect_failures = [
    var.application_configuration_id,
  ]
}

run "rejects_undefined_database_use_avset" {
  command = plan

  variables {
    database_use_avset = null
  }

  expect_failures = [
    var.database_use_avset,
  ]
}

run "rejects_undefined_database_use_ppg" {
  command = plan

  variables {
    database_use_ppg = null
  }

  expect_failures = [
    var.database_use_ppg,
  ]
}

run "rejects_undefined_scs_server_use_avset" {
  command = plan

  variables {
    scs_server_use_avset = null
  }

  expect_failures = [
    var.scs_server_use_avset,
  ]
}

run "rejects_undefined_scs_server_use_ppg" {
  command = plan

  variables {
    scs_server_use_ppg = null
  }

  expect_failures = [
    var.scs_server_use_ppg,
  ]
}

run "rejects_undefined_application_server_use_avset" {
  command = plan

  variables {
    application_server_use_avset = null
  }

  expect_failures = [
    var.application_server_use_avset,
  ]
}

run "rejects_undefined_application_server_use_ppg" {
  command = plan

  variables {
    application_server_use_ppg = null
  }

  expect_failures = [
    var.application_server_use_ppg,
  ]
}


run "accepts_valid_subscription_id_guids" {
  command = plan

  variables {
    management_dns_subscription_id  = "11111111-1111-1111-1111-111111111111"
    privatelink_dns_subscription_id = "22222222-2222-2222-2222-222222222222"
    subscription_id                 = "33333333-3333-3333-3333-333333333333"
  }

  assert {
    condition     = output.environment == "DEV"
    error_message = "36-character subscription ID GUIDs must be accepted for management_dns_subscription_id, privatelink_dns_subscription_id, and subscription_id."
  }
}

run "rejects_management_dns_subscription_id_of_wrong_length" {
  command = plan

  variables {
    management_dns_subscription_id = "not-a-guid"
  }

  expect_failures = [
    var.management_dns_subscription_id,
  ]
}

run "rejects_privatelink_dns_subscription_id_of_wrong_length" {
  command = plan

  variables {
    privatelink_dns_subscription_id = "not-a-guid"
  }

  expect_failures = [
    var.privatelink_dns_subscription_id,
  ]
}

run "rejects_subscription_id_of_wrong_length" {
  command = plan

  variables {
    subscription_id = "not-a-guid"
  }

  expect_failures = [
    var.subscription_id,
  ]
}
