mock_provider "azurerm" {
}
mock_provider "azurerm" {
  alias           = "workload"
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
mock_provider "azurerm" {
  alias           = "peering"
}
mock_provider "azuread" {
}
mock_provider "azapi" {
  alias           = "api"
}

override_data {
  target = data.azurerm_client_config.current
  values = {
    subscription_id = "00000000-0000-0000-0000-000000000000"
    tenant_id       = "11111111-1111-1111-1111-111111111111"
    client_id       = "22222222-2222-2222-2222-222222222222"
    object_id       = "33333333-3333-3333-3333-333333333333"
  }
}

override_data {
  target = module.sap_landscape.data.azurerm_client_config.current
  values = {
    subscription_id = "00000000-0000-0000-0000-000000000000"
    tenant_id       = "11111111-1111-1111-1111-111111111111"
    client_id       = "22222222-2222-2222-2222-222222222222"
    object_id       = "33333333-3333-3333-3333-333333333333"
  }
}

override_data {
  target = data.terraform_remote_state.deployer
  values = {
    outputs = {
      created_resource_group_subscription_id = "00000000-0000-0000-0000-000000000000"
      environment                            = "DEV"
      additional_network_id                  = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mgmt/providers/Microsoft.Network/virtualNetworks/vnet-agent"
      application_configuration_id           = ""
      control_plane_name                     = "DEV-WEEU-DEP00"
      deployer_kv_user_arm_id                = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mgmt/providers/Microsoft.KeyVault/vaults/kv-deployer"
      deployer_kv_user_name                  = "kv-deployer"
      deployer_public_ip_address             = "198.51.100.10"
      deployer_uai = {
        principal_id = "33333333-3333-3333-3333-333333333333"
        tenant_id    = "11111111-1111-1111-1111-111111111111"
      }
      firewall_id                                           = ""
      firewall_ip                                           = ""
      network_security_access_mode                          = "Learning"
      network_security_perimeter_deployment                 = false
      network_security_perimeter_id                         = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mgmt/providers/Microsoft.Network/networkSecurityPerimeters/nsp-dev"
      subnet_bastion_address_prefixes                       = ["10.0.1.0/26"]
      subnet_mgmt_address_prefixes                          = ["10.0.0.0/24"]
      subnet_mgmt_id                                        = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mgmt/providers/Microsoft.Network/virtualNetworks/vnet-mgmt/subnets/snet-mgmt"
      subnets_to_add_to_firewall_for_key_vaults_and_storage = []
      vnet_mgmt_id                                          = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mgmt/providers/Microsoft.Network/virtualNetworks/vnet-mgmt"
    }
  }
}

override_data {
  target = module.sap_landscape.data.azurerm_resource_group.resource_group
  values = {
    id       = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-sap-dev"
    name     = "rg-sap-dev"
    location = "westeurope"
  }
}

override_data {
  target = module.sap_landscape.data.azurerm_virtual_network.vnet_sap
  values = {
    id                  = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-sap-dev/providers/Microsoft.Network/virtualNetworks/vnet-sap01"
    name                = "vnet-sap01"
    resource_group_name = "rg-sap-dev"
    location            = "westeurope"
    address_space       = ["10.10.0.0/16"]
  }
}

override_data {
  target = module.sap_landscape.data.azurerm_subnet.admin
  values = {
    id               = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-sap-dev/providers/Microsoft.Network/virtualNetworks/vnet-sap01/subnets/admin"
    address_prefixes = ["10.10.0.0/24"]
  }
}

override_data {
  target = module.sap_landscape.data.azurerm_subnet.db
  values = {
    id               = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-sap-dev/providers/Microsoft.Network/virtualNetworks/vnet-sap01/subnets/db"
    address_prefixes = ["10.10.1.0/24"]
  }
}

override_data {
  target = module.sap_landscape.data.azurerm_subnet.app
  values = {
    id               = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-sap-dev/providers/Microsoft.Network/virtualNetworks/vnet-sap01/subnets/app"
    address_prefixes = ["10.10.2.0/24"]
  }
}

override_data {
  target = module.sap_landscape.data.azurerm_subnet.web
  values = {
    id               = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-sap-dev/providers/Microsoft.Network/virtualNetworks/vnet-sap01/subnets/web"
    address_prefixes = ["10.10.3.0/24"]
  }
}

override_data {
  target = module.sap_landscape.data.azurerm_subnet.storage
  values = {
    id               = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-sap-dev/providers/Microsoft.Network/virtualNetworks/vnet-sap01/subnets/storage"
    address_prefixes = ["10.10.4.0/24"]
  }
}

override_data {
  target = module.sap_landscape.data.azurerm_subnet.anf
  values = {
    id               = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-sap-dev/providers/Microsoft.Network/virtualNetworks/vnet-sap01/subnets/anf"
    address_prefixes = ["10.10.5.0/28"]
  }
}

override_data {
  target = module.sap_landscape.data.azurerm_subnet.iscsi
  values = {
    id               = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-sap-dev/providers/Microsoft.Network/virtualNetworks/vnet-sap01/subnets/iscsi"
    address_prefixes = ["10.10.6.0/24"]
  }
}

override_data {
  target = module.sap_landscape.data.azurerm_subnet.ams
  values = {
    id               = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-sap-dev/providers/Microsoft.Network/virtualNetworks/vnet-sap01/subnets/ams"
    address_prefixes = ["10.10.7.0/24"]
  }
}

override_data {
  target = module.sap_landscape.data.azurerm_network_security_group.iscsi
  values = {
    id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-sap-dev/providers/Microsoft.Network/networkSecurityGroups/nsg-iscsi"
  }
}

override_data {
  target = module.sap_landscape.data.azurerm_key_vault.kv_user
  values = {
    id   = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-sap-dev/providers/Microsoft.KeyVault/vaults/kv-sap-user"
    name = "kv-sap-user"
  }
}

variables {
  environment                                  = "DEV"
  location                                     = "westeurope"
  network_logical_name                         = "SAP01"
  network_name                                 = "vnet-sap01"
  network_address_space                        = ["10.10.0.0/16"]
  resourcegroup_arm_id                         = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-sap-dev"
  network_arm_id                               = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-sap-dev/providers/Microsoft.Network/virtualNetworks/vnet-sap01"
  admin_subnet_arm_id                          = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-sap-dev/providers/Microsoft.Network/virtualNetworks/vnet-sap01/subnets/admin"
  admin_subnet_nsg_arm_id                      = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-sap-dev/providers/Microsoft.Network/networkSecurityGroups/nsg-admin"
  db_subnet_arm_id                             = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-sap-dev/providers/Microsoft.Network/virtualNetworks/vnet-sap01/subnets/db"
  db_subnet_nsg_arm_id                         = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-sap-dev/providers/Microsoft.Network/networkSecurityGroups/nsg-db"
  app_subnet_arm_id                            = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-sap-dev/providers/Microsoft.Network/virtualNetworks/vnet-sap01/subnets/app"
  app_subnet_nsg_arm_id                        = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-sap-dev/providers/Microsoft.Network/networkSecurityGroups/nsg-app"
  web_subnet_arm_id                            = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-sap-dev/providers/Microsoft.Network/virtualNetworks/vnet-sap01/subnets/web"
  web_subnet_nsg_arm_id                        = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-sap-dev/providers/Microsoft.Network/networkSecurityGroups/nsg-web"
  storage_subnet_arm_id                        = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-sap-dev/providers/Microsoft.Network/virtualNetworks/vnet-sap01/subnets/storage"
  storage_subnet_nsg_arm_id                    = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-sap-dev/providers/Microsoft.Network/networkSecurityGroups/nsg-storage"
  anf_subnet_arm_id                            = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-sap-dev/providers/Microsoft.Network/virtualNetworks/vnet-sap01/subnets/anf"
  anf_subnet_nsg_arm_id                        = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-sap-dev/providers/Microsoft.Network/networkSecurityGroups/nsg-anf"
  iscsi_subnet_arm_id                          = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-sap-dev/providers/Microsoft.Network/virtualNetworks/vnet-sap01/subnets/iscsi"
  iscsi_subnet_nsg_arm_id                      = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-sap-dev/providers/Microsoft.Network/networkSecurityGroups/nsg-iscsi"
  ams_subnet_arm_id                            = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-sap-dev/providers/Microsoft.Network/virtualNetworks/vnet-sap01/subnets/ams"
  ams_subnet_nsg_arm_id                        = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-sap-dev/providers/Microsoft.Network/networkSecurityGroups/nsg-ams"
  user_keyvault_id                             = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-sap-dev/providers/Microsoft.KeyVault/vaults/kv-sap-user"
  tfstate_resource_id                          = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-tfstate/providers/Microsoft.Storage/storageAccounts/tfstatesa"
  deployer_tfstate_key                         = "DEV-WEEU-DEP00.terraform.tfstate"
  subscription_id                              = "00000000-0000-0000-0000-000000000000"
  management_subscription_id                   = "00000000-0000-0000-0000-000000000000"
  management_dns_subscription_id               = "00000000-0000-0000-0000-000000000000"
  privatelink_dns_subscription_id              = "00000000-0000-0000-0000-000000000000"
  use_spn                                      = false
  use_private_endpoint                         = false
  register_endpoints_with_dns                  = false
  register_virtual_network_to_dns              = false
  register_storage_accounts_keyvaults_with_dns = false
  create_transport_storage                     = false
  assign_permissions                           = false
  public_network_access_enabled                = true
  tags = {
    Environment = "DEV"
    Role        = "workload-zone"
  }
}


run "valid_user_assigned_identity_id" {
  command = plan

  variables {
    user_assigned_identity_id = ""
  }

  assert {
    condition     = output.workload_zone_name == "DEV-WEEU-SAP01"
    error_message = "A valid user_assigned_identity_id value must keep the baseline plan healthy."
  }
}

run "invalid_user_assigned_identity_id" {
  command = plan

  variables {
    user_assigned_identity_id = "not-a-valid-value"
  }

  expect_failures = [
    var.user_assigned_identity_id,
  ]
}

run "valid_diagnostics_storage_account_arm_id" {
  command = plan

  variables {
    diagnostics_storage_account_arm_id = ""
  }

  assert {
    condition     = output.workload_zone_name == "DEV-WEEU-SAP01"
    error_message = "A valid diagnostics_storage_account_arm_id value must keep the baseline plan healthy."
  }
}

run "invalid_diagnostics_storage_account_arm_id" {
  command = plan

  variables {
    diagnostics_storage_account_arm_id = "not-a-valid-value"
  }

  expect_failures = [
    var.diagnostics_storage_account_arm_id,
  ]
}

run "valid_witness_storage_account_arm_id" {
  command = plan

  variables {
    witness_storage_account_arm_id = ""
  }

  assert {
    condition     = output.workload_zone_name == "DEV-WEEU-SAP01"
    error_message = "A valid witness_storage_account_arm_id value must keep the baseline plan healthy."
  }
}

run "invalid_witness_storage_account_arm_id" {
  command = plan

  variables {
    witness_storage_account_arm_id = "not-a-valid-value"
  }

  expect_failures = [
    var.witness_storage_account_arm_id,
  ]
}

run "valid_transport_storage_account_id" {
  command = plan

  variables {
    transport_storage_account_id = ""
  }

  assert {
    condition     = output.workload_zone_name == "DEV-WEEU-SAP01"
    error_message = "A valid transport_storage_account_id value must keep the baseline plan healthy."
  }
}

run "invalid_transport_storage_account_id" {
  command = plan

  variables {
    transport_storage_account_id = "not-a-valid-value"
  }

  expect_failures = [
    var.transport_storage_account_id,
  ]
}

run "valid_transport_private_endpoint_id" {
  command = plan

  variables {
    transport_private_endpoint_id = ""
  }

  assert {
    condition     = output.workload_zone_name == "DEV-WEEU-SAP01"
    error_message = "A valid transport_private_endpoint_id value must keep the baseline plan healthy."
  }
}

run "invalid_transport_private_endpoint_id" {
  command = plan

  variables {
    transport_private_endpoint_id = "not-a-valid-value"
  }

  expect_failures = [
    var.transport_private_endpoint_id,
  ]
}

run "valid_install_storage_account_id" {
  command = plan

  variables {
    install_storage_account_id = ""
  }

  assert {
    condition     = output.workload_zone_name == "DEV-WEEU-SAP01"
    error_message = "A valid install_storage_account_id value must keep the baseline plan healthy."
  }
}

run "invalid_install_storage_account_id" {
  command = plan

  variables {
    install_storage_account_id = "not-a-valid-value"
  }

  expect_failures = [
    var.install_storage_account_id,
  ]
}

run "valid_install_private_endpoint_id" {
  command = plan

  variables {
    install_private_endpoint_id = ""
  }

  assert {
    condition     = output.workload_zone_name == "DEV-WEEU-SAP01"
    error_message = "A valid install_private_endpoint_id value must keep the baseline plan healthy."
  }
}

run "invalid_install_private_endpoint_id" {
  command = plan

  variables {
    install_private_endpoint_id = "not-a-valid-value"
  }

  expect_failures = [
    var.install_private_endpoint_id,
  ]
}

run "valid_management_dns_subscription_id" {
  command = plan

  variables {
    management_dns_subscription_id = "00000000-0000-0000-0000-000000000000"
  }

  assert {
    condition     = output.management_dns_subscription_id == "00000000-0000-0000-0000-000000000000"
    error_message = "A valid management_dns_subscription_id value must keep the baseline plan healthy."
  }
}

run "invalid_management_dns_subscription_id" {
  command = plan

  variables {
    management_dns_subscription_id = "short-guid"
  }

  expect_failures = [
    var.management_dns_subscription_id,
  ]
}

run "valid_privatelink_dns_subscription_id" {
  command = plan

  variables {
    privatelink_dns_subscription_id = "00000000-0000-0000-0000-000000000000"
  }

  assert {
    condition     = output.privatelink_dns_subscription_id == "00000000-0000-0000-0000-000000000000"
    error_message = "A valid privatelink_dns_subscription_id value must keep the baseline plan healthy."
  }
}

run "invalid_privatelink_dns_subscription_id" {
  command = plan

  variables {
    privatelink_dns_subscription_id = "short-guid"
  }

  expect_failures = [
    var.privatelink_dns_subscription_id,
  ]
}

run "valid_privatelink_file_id" {
  command = plan

  variables {
    privatelink_file_id = ""
  }

  assert {
    condition     = output.workload_zone_name == "DEV-WEEU-SAP01"
    error_message = "A valid privatelink_file_id value must keep the baseline plan healthy."
  }
}

run "invalid_privatelink_file_id" {
  command = plan

  variables {
    privatelink_file_id = "not-a-valid-value"
  }

  expect_failures = [
    var.privatelink_file_id,
  ]
}

run "valid_privatelink_storage_id" {
  command = plan

  variables {
    privatelink_storage_id = ""
  }

  assert {
    condition     = output.workload_zone_name == "DEV-WEEU-SAP01"
    error_message = "A valid privatelink_storage_id value must keep the baseline plan healthy."
  }
}

run "invalid_privatelink_storage_id" {
  command = plan

  variables {
    privatelink_storage_id = "not-a-valid-value"
  }

  expect_failures = [
    var.privatelink_storage_id,
  ]
}

run "valid_privatelink_keyvault_id" {
  command = plan

  variables {
    privatelink_keyvault_id = ""
  }

  assert {
    condition     = output.workload_zone_name == "DEV-WEEU-SAP01"
    error_message = "A valid privatelink_keyvault_id value must keep the baseline plan healthy."
  }
}

run "invalid_privatelink_keyvault_id" {
  command = plan

  variables {
    privatelink_keyvault_id = "not-a-valid-value"
  }

  expect_failures = [
    var.privatelink_keyvault_id,
  ]
}

run "valid_ANF_account_arm_id" {
  command = plan

  variables {
    ANF_account_arm_id = ""
  }

  assert {
    condition     = output.workload_zone_name == "DEV-WEEU-SAP01"
    error_message = "A valid ANF_account_arm_id value must keep the baseline plan healthy."
  }
}

run "invalid_ANF_account_arm_id" {
  command = plan

  variables {
    ANF_account_arm_id = "not-a-valid-value"
  }

  expect_failures = [
    var.ANF_account_arm_id,
  ]
}

run "valid_iscsi_subnet_arm_id" {
  command = plan

  variables {
    iscsi_subnet_arm_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-sap-dev/providers/Microsoft.Network/virtualNetworks/vnet-sap01/subnets/iscsi"
  }

  assert {
    condition     = output.workload_zone_name == "DEV-WEEU-SAP01"
    error_message = "A valid iscsi_subnet_arm_id value must keep the baseline plan healthy."
  }
}

run "invalid_iscsi_subnet_arm_id" {
  command = plan

  variables {
    iscsi_subnet_arm_id = "not-a-valid-value"
  }

  expect_failures = [
    var.iscsi_subnet_arm_id,
  ]
}

run "valid_iscsi_subnet_nsg_arm_id" {
  command = plan

  variables {
    iscsi_subnet_nsg_arm_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-sap-dev/providers/Microsoft.Network/networkSecurityGroups/nsg-iscsi"
  }

  assert {
    condition     = output.workload_zone_name == "DEV-WEEU-SAP01"
    error_message = "A valid iscsi_subnet_nsg_arm_id value must keep the baseline plan healthy."
  }
}

run "invalid_iscsi_subnet_nsg_arm_id" {
  command = plan

  variables {
    iscsi_subnet_nsg_arm_id = "not-a-valid-value"
  }

  expect_failures = [
    var.iscsi_subnet_nsg_arm_id,
  ]
}

run "valid_ams_laws_arm_id" {
  command = plan

  variables {
    ams_laws_arm_id = ""
  }

  assert {
    condition     = output.workload_zone_name == "DEV-WEEU-SAP01"
    error_message = "A valid ams_laws_arm_id value must keep the baseline plan healthy."
  }
}

run "invalid_ams_laws_arm_id" {
  command = plan

  variables {
    ams_laws_arm_id = "not-a-valid-value"
  }

  expect_failures = [
    var.ams_laws_arm_id,
  ]
}

run "valid_nat_gateway_arm_id" {
  command = plan

  variables {
    nat_gateway_arm_id = ""
  }

  assert {
    condition     = output.workload_zone_name == "DEV-WEEU-SAP01"
    error_message = "A valid nat_gateway_arm_id value must keep the baseline plan healthy."
  }
}

run "invalid_nat_gateway_arm_id" {
  command = plan

  variables {
    nat_gateway_arm_id = "not-a-valid-value"
  }

  expect_failures = [
    var.nat_gateway_arm_id,
  ]
}

run "valid_nat_gateway_public_ip_arm_id" {
  command = plan

  variables {
    nat_gateway_public_ip_arm_id = ""
  }

  assert {
    condition     = output.workload_zone_name == "DEV-WEEU-SAP01"
    error_message = "A valid nat_gateway_public_ip_arm_id value must keep the baseline plan healthy."
  }
}

run "invalid_nat_gateway_public_ip_arm_id" {
  command = plan

  variables {
    nat_gateway_public_ip_arm_id = "not-a-valid-value"
  }

  expect_failures = [
    var.nat_gateway_public_ip_arm_id,
  ]
}

run "valid_tfstate_resource_id" {
  command = plan

  variables {
    tfstate_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-tfstate/providers/Microsoft.Storage/storageAccounts/tfstatesa"
  }

  assert {
    condition     = output.dns_resource_group_name == "rg-tfstate"
    error_message = "A valid tfstate_resource_id value must keep the baseline plan healthy."
  }
}

run "invalid_tfstate_resource_id" {
  command = plan

  variables {
    tfstate_resource_id = "not-a-valid-value"
  }

  expect_failures = [
    var.tfstate_resource_id,
  ]
}

run "valid_additional_network_id" {
  command = plan

  variables {
    additional_network_id = ""
  }

  assert {
    condition     = output.workload_zone_name == "DEV-WEEU-SAP01"
    error_message = "A valid additional_network_id value must keep the baseline plan healthy."
  }
}

run "invalid_additional_network_id" {
  command = plan

  variables {
    additional_network_id = "not-a-valid-value"
  }

  expect_failures = [
    var.additional_network_id,
  ]
}

run "valid_additional_subnet_id" {
  command = plan

  variables {
    additional_subnet_id = ""
  }

  assert {
    condition     = output.workload_zone_name == "DEV-WEEU-SAP01"
    error_message = "A valid additional_subnet_id value must keep the baseline plan healthy."
  }
}

run "invalid_additional_subnet_id" {
  command = plan

  variables {
    additional_subnet_id = "not-a-valid-value"
  }

  expect_failures = [
    var.additional_subnet_id,
  ]
}

run "valid_spn_id" {
  command = plan

  variables {
    spn_id = ""
  }

  assert {
    condition     = output.workload_zone_name == "DEV-WEEU-SAP01"
    error_message = "A valid spn_id value must keep the baseline plan healthy."
  }
}

run "invalid_spn_id" {
  command = plan

  variables {
    spn_id = "short-guid"
  }

  expect_failures = [
    var.spn_id,
  ]
}

run "valid_application_configuration_id" {
  command = plan

  variables {
    application_configuration_id = ""
  }

  assert {
    condition     = output.application_configuration_id == ""
    error_message = "A valid application_configuration_id value must keep the baseline plan healthy."
  }
}

run "invalid_application_configuration_id" {
  command = plan

  variables {
    application_configuration_id = "not-a-valid-value"
  }

  expect_failures = [
    var.application_configuration_id,
  ]
}

run "valid_private_endpoint_network_policies" {
  command = plan

  variables {
    private_endpoint_network_policies = "NetworkSecurityGroupEnabled"
  }

  assert {
    condition     = var.private_endpoint_network_policies == "NetworkSecurityGroupEnabled"
    error_message = "A supported private endpoint network policy value must keep the baseline plan healthy."
  }
}

run "invalid_private_endpoint_network_policies" {
  command = plan

  variables {
    private_endpoint_network_policies = "Invalid"
  }

  expect_failures = [
    var.private_endpoint_network_policies,
  ]
}

run "invalid_utility_container_immutability_period_below_minimum" {
  command = plan

  variables {
    utility_storage_accounts = [
      {
        name         = "utilsv201"
        account_kind = "StorageV2"
        blob_containers = [{
          name                = "archive"
          immutability_policy = { immutability_period_in_days = 0 }
        }]
      },
    ]
  }

  expect_failures = [
    var.utility_storage_accounts,
  ]
}

run "invalid_utility_container_immutability_period_above_maximum" {
  command = plan

  variables {
    utility_storage_accounts = [
      {
        name         = "utilsv201"
        account_kind = "StorageV2"
        blob_containers = [{
          name                = "archive"
          immutability_policy = { immutability_period_in_days = 146001 }
        }]
      },
    ]
  }

  expect_failures = [
    var.utility_storage_accounts,
  ]
}

run "invalid_utility_container_protected_append_mode" {
  command = plan

  variables {
    utility_storage_accounts = [
      {
        name         = "utilsv201"
        account_kind = "StorageV2"
        blob_containers = [{
          name                = "archive"
          immutability_policy = { protected_append_writes = "invalid" }
        }]
      },
    ]
  }

  expect_failures = [
    var.utility_storage_accounts,
  ]
}

run "locked_utility_container_policy_requires_irreversible_acknowledgement" {
  command = plan

  variables {
    utility_storage_accounts = [
      {
        name         = "utilsv201"
        account_kind = "StorageV2"
        blob_containers = [{
          name = "archive"
          immutability_policy = {
            locked = true
          }
        }]
      },
    ]
  }

  expect_failures = [
    var.utility_storage_accounts,
  ]
}

run "utility_container_policy_requires_explicit_names" {
  command = plan

  variables {
    utility_storage_accounts = [
      {
        account_kind = "StorageV2"
        blob_containers = [{
          immutability_policy = {}
        }]
      },
    ]
  }

  expect_failures = [
    var.utility_storage_accounts,
  ]
}

run "utility_container_policy_identity_must_be_unique" {
  command = plan

  variables {
    utility_storage_accounts = [
      {
        name         = "utilsv201"
        account_kind = "StorageV2"
        blob_containers = [
          {
            name                = "archive"
            immutability_policy = {}
          },
          {
            name                = "archive"
            immutability_policy = {}
          },
        ]
      },
    ]
  }

  expect_failures = [
    var.utility_storage_accounts,
  ]
}

run "utility_container_policy_rejected_on_file_storage_account" {
  command = plan

  variables {
    utility_storage_accounts = [
      {
        name         = "utilfile01"
        account_kind = "FileStorage"
        blob_containers = [
          {
            name                = "archive"
            immutability_policy = {}
          },
        ]
      },
    ]
  }

  expect_failures = [
    var.utility_storage_accounts,
  ]
}
