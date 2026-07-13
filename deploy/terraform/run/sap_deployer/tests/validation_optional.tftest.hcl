mock_provider "azurerm" {
}
mock_provider "azurerm" {
  alias           = "main"
}
mock_provider "azurerm" {
  alias           = "dnsmanagement"
}
mock_provider "azurerm" {
  alias           = "privatelinkdnsmanagement"
}
mock_provider "azapi" {
  alias           = "restapi"
}
mock_provider "azuread" {
}

override_data {
  target = module.sap_deployer.data.azurerm_subscription.primary
  values = {
    id              = "/subscriptions/00000000-0000-0000-0000-000000000000"
    subscription_id = "00000000-0000-0000-0000-000000000000"
    tenant_id       = "00000000-0000-0000-0000-000000000000"
  }
}

override_data {
  target = module.sap_deployer.data.azurerm_client_config.current
  values = {
    subscription_id = "00000000-0000-0000-0000-000000000000"
    tenant_id       = "00000000-0000-0000-0000-000000000000"
    client_id       = "00000000-0000-0000-0000-000000000000"
    object_id       = "00000000-0000-0000-0000-000000000000"
  }
}

override_data {
  target = module.sap_deployer.data.azurerm_client_config.deployer
  values = {
    subscription_id = "00000000-0000-0000-0000-000000000000"
    tenant_id       = "00000000-0000-0000-0000-000000000000"
    client_id       = "00000000-0000-0000-0000-000000000000"
    object_id       = "00000000-0000-0000-0000-000000000000"
  }
}

override_data {
  target = module.sap_deployer.data.azurerm_resource_group.deployer
  values = {
    id       = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-existing"
    name     = "rg-existing"
    location = "westeurope"
  }
}

override_data {
  target = module.sap_deployer.data.azurerm_virtual_network.vnet_mgmt
  values = {
    id                  = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-net/providers/Microsoft.Network/virtualNetworks/vnet-existing"
    name                = "vnet-existing"
    resource_group_name = "rg-net"
    location            = "westeurope"
    address_space       = ["10.50.0.0/16"]
  }
}

override_data {
  target = module.sap_deployer.data.azurerm_subnet.subnet_mgmt
  values = {
    id                   = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-net/providers/Microsoft.Network/virtualNetworks/vnet-existing/subnets/deployer"
    name                 = "deployer"
    resource_group_name  = "rg-net"
    virtual_network_name = "vnet-existing"
    address_prefixes     = ["10.50.1.0/24"]
  }
}

override_data {
  target = module.sap_deployer.data.azurerm_subnet.firewall
  values = {
    id                   = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-net/providers/Microsoft.Network/virtualNetworks/vnet-existing/subnets/AzureFirewallSubnet"
    name                 = "AzureFirewallSubnet"
    resource_group_name  = "rg-net"
    virtual_network_name = "vnet-existing"
    address_prefixes     = ["10.50.2.0/24"]
  }
}

override_data {
  target = module.sap_deployer.data.azurerm_subnet.bastion
  values = {
    id                   = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-net/providers/Microsoft.Network/virtualNetworks/vnet-existing/subnets/AzureBastionSubnet"
    name                 = "AzureBastionSubnet"
    resource_group_name  = "rg-net"
    virtual_network_name = "vnet-existing"
    address_prefixes     = ["10.50.3.0/24"]
  }
}

override_data {
  target = module.sap_deployer.data.azurerm_subnet.webapp
  values = {
    id                   = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-net/providers/Microsoft.Network/virtualNetworks/vnet-existing/subnets/AzureWebappSubnet"
    name                 = "AzureWebappSubnet"
    resource_group_name  = "rg-net"
    virtual_network_name = "vnet-existing"
    address_prefixes     = ["10.50.4.0/24"]
  }
}

override_data {
  target = module.sap_deployer.data.azurerm_subnet.subnet_agent
  values = {
    id                   = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-net/providers/Microsoft.Network/virtualNetworks/vnet-existing/subnets/agent"
    name                 = "agent"
    resource_group_name  = "rg-net"
    virtual_network_name = "vnet-existing"
    address_prefixes     = ["10.50.5.0/24"]
  }
}

override_data {
  target = module.sap_deployer.data.azurerm_network_security_group.nsg_mgmt
  values = {
    id                  = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-net/providers/Microsoft.Network/networkSecurityGroups/nsg-deployer"
    name                = "nsg-deployer"
    resource_group_name = "rg-net"
  }
}

override_data {
  target = module.sap_deployer.data.azurerm_storage_account.deployer
  values = {
    id                            = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-diag/providers/Microsoft.Storage/storageAccounts/diagstore"
    name                          = "diagstore"
    resource_group_name           = "rg-diag"
    primary_blob_endpoint         = "https://diagstore.blob.core.windows.net/"
    public_network_access_enabled = true
    tags = {
      Component = "deployer"
      Role      = "control-plane"
    }
  }
}

override_data {
  target = module.sap_deployer.data.azurerm_key_vault.kv_user
  values = {
    id   = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-kv/providers/Microsoft.KeyVault/vaults/kv-user"
    name = "kv-user"
    tags = {
      Component = "deployer"
      Role      = "control-plane"
    }
  }
}

override_data {
  target = module.sap_deployer.data.azurerm_user_assigned_identity.deployer
  values = {
    id                  = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-id/providers/Microsoft.ManagedIdentity/userAssignedIdentities/deployer-uai"
    name                = "deployer-uai"
    resource_group_name = "rg-id"
    principal_id        = "66666666-6666-6666-6666-666666666666"
    client_id           = "77777777-7777-7777-7777-777777777777"
    tenant_id           = "00000000-0000-0000-0000-000000000000"
  }
}

variables {
  environment                              = "DEV"
  location                                 = "westeurope"
  subscription_id                          = "00000000-0000-0000-0000-000000000000"
  resourcegroup_name                       = "rg-deployer"
  management_network_logical_name          = "MGMT1"
  management_network_name                  = "vnet-mgmt"
  management_network_address_space         = "10.0.0.0/16"
  management_subnet_name                   = "AzureDeployerSubnet"
  management_subnet_address_prefix         = "10.0.0.0/24"
  tfstate_resource_id                      = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-tfstate/providers/Microsoft.Storage/storageAccounts/tfstatesa"
  use_private_endpoint                     = false
  deployer_enable_public_ip                = true
  deployer_assign_resource_permissions     = false
  deployer_assign_subscription_permissions = false
  use_spn                                  = false
  tags = {
    Component = "deployer"
    Role      = "control-plane"
  }
}

run "rejects_management_firewall_subnet_arm_id" {
  command = plan

  variables {
    management_firewall_subnet_arm_id = "not-a-valid-resource-id"
  }

  expect_failures = [
    var.management_firewall_subnet_arm_id,
  ]
}

# management_bastion_subnet_arm_id should accept a well-formed bastion subnet ARM ID.
run "accepts_management_bastion_subnet_arm_id" {
  command = plan

  variables {
    management_bastion_subnet_arm_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-net/providers/Microsoft.Network/virtualNetworks/vnet-existing/subnets/AzureBastionSubnet"
  }
}

# Malformed management_bastion_subnet_arm_id values must be rejected.
run "rejects_management_bastion_subnet_arm_id" {
  command = plan

  variables {
    management_bastion_subnet_arm_id = "not-a-valid-resource-id"
  }

  expect_failures = [
    var.management_bastion_subnet_arm_id,
  ]
}

# webapp_subnet_arm_id should accept a well-formed webapp subnet ARM ID.
run "accepts_webapp_subnet_arm_id" {
  command = plan

  variables {
    webapp_subnet_arm_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-net/providers/Microsoft.Network/virtualNetworks/vnet-existing/subnets/AzureWebappSubnet"
  }
}

# Malformed webapp_subnet_arm_id values must be rejected.
run "rejects_webapp_subnet_arm_id" {
  command = plan

  variables {
    webapp_subnet_arm_id = "not-a-valid-resource-id"
  }

  expect_failures = [
    var.webapp_subnet_arm_id,
  ]
}

# management_subnet_nsg_arm_id should accept a well-formed NSG ARM ID.
run "accepts_management_subnet_nsg_arm_id" {
  command = plan

  variables {
    management_subnet_nsg_arm_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-net/providers/Microsoft.Network/networkSecurityGroups/nsg-deployer"
  }
}

# Malformed management_subnet_nsg_arm_id values must be rejected.
run "rejects_management_subnet_nsg_arm_id" {
  command = plan

  variables {
    management_subnet_nsg_arm_id = "not-a-valid-resource-id"
  }

  expect_failures = [
    var.management_subnet_nsg_arm_id,
  ]
}

# spn_keyvault_id should accept a well-formed Key Vault ARM ID.
run "accepts_spn_keyvault_id" {
  command = plan

  variables {
    spn_keyvault_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-kv/providers/Microsoft.KeyVault/vaults/kv-spn"
  }
}

# Malformed spn_keyvault_id values must be rejected.
run "rejects_spn_keyvault_id" {
  command = plan

  variables {
    spn_keyvault_id = "not-a-valid-resource-id"
  }

  expect_failures = [
    var.spn_keyvault_id,
  ]
}

# user_keyvault_id should accept a well-formed Key Vault ARM ID.
run "accepts_user_keyvault_id" {
  command = plan

  variables {
    user_keyvault_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-kv/providers/Microsoft.KeyVault/vaults/kv-user"
  }
}

# Malformed user_keyvault_id values must be rejected.
run "rejects_user_keyvault_id" {
  command = plan

  variables {
    user_keyvault_id = "not-a-valid-resource-id"
  }

  expect_failures = [
    var.user_keyvault_id,
  ]
}

# deployer_diagnostics_account_arm_id should accept a well-formed storage-account ARM ID.
run "accepts_deployer_diagnostics_account_arm_id" {
  command = plan

  variables {
    deployer_diagnostics_account_arm_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-diag/providers/Microsoft.Storage/storageAccounts/diagstore"
  }
}

# Malformed deployer_diagnostics_account_arm_id values must be rejected.
run "rejects_deployer_diagnostics_account_arm_id" {
  command = plan

  variables {
    deployer_diagnostics_account_arm_id = "not-a-valid-resource-id"
  }

  expect_failures = [
    var.deployer_diagnostics_account_arm_id,
  ]
}

# tfstate_resource_id should accept a well-formed storage-account ARM ID.
run "accepts_tfstate_resource_id" {
  command = plan

  variables {
    tfstate_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-state/providers/Microsoft.Storage/storageAccounts/stateacct"
  }
}

# Malformed tfstate_resource_id values must be rejected.
run "rejects_tfstate_resource_id" {
  command = plan

  variables {
    tfstate_resource_id = "not-a-valid-resource-id"
  }

  expect_failures = [
    var.tfstate_resource_id,
  ]
}

# spn_id should accept a 36-character GUID string.
run "accepts_spn_id" {
  command = plan

  variables {
    spn_id = "22222222-2222-2222-2222-222222222222"
  }
}

# Malformed spn_id values must be rejected.
run "rejects_spn_id" {
  command = plan

  variables {
    spn_id = "short-guid"
  }

  expect_failures = [
    var.spn_id,
  ]
}

# management_dns_subscription_id should accept a 36-character GUID string.
run "accepts_management_dns_subscription_id" {
  command = plan

  variables {
    management_dns_subscription_id = "33333333-3333-3333-3333-333333333333"
  }
}

# Malformed management_dns_subscription_id values must be rejected.
run "rejects_management_dns_subscription_id" {
  command = plan

  variables {
    management_dns_subscription_id = "short-guid"
  }

  expect_failures = [
    var.management_dns_subscription_id,
  ]
}

# privatelink_dns_subscription_id should accept a 36-character GUID string.
run "accepts_privatelink_dns_subscription_id" {
  command = plan

  variables {
    privatelink_dns_subscription_id = "44444444-4444-4444-4444-444444444444"
  }
}

# Malformed privatelink_dns_subscription_id values must be rejected.
run "rejects_privatelink_dns_subscription_id" {
  command = plan

  variables {
    privatelink_dns_subscription_id = "short-guid"
  }

  expect_failures = [
    var.privatelink_dns_subscription_id,
  ]
}

# agent_subnet_arm_id should accept a well-formed subnet ARM ID.
run "accepts_agent_subnet_arm_id" {
  command = plan

  variables {
    agent_subnet_arm_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-net/providers/Microsoft.Network/virtualNetworks/vnet-existing/subnets/agent"
  }
}

# Malformed agent_subnet_arm_id values must be rejected.
run "rejects_agent_subnet_arm_id" {
  command = plan

  variables {
    agent_subnet_arm_id = "not-a-valid-resource-id"
  }

  expect_failures = [
    var.agent_subnet_arm_id,
  ]
}

# app_registration_app_id should accept a 36-character application registration GUID.
run "accepts_app_registration_app_id" {
  command = plan

  variables {
    app_registration_app_id = "55555555-5555-5555-5555-555555555555"
  }
}

# Malformed app_registration_app_id values must be rejected.
run "rejects_app_registration_app_id" {
  command = plan

  variables {
    app_registration_app_id = "short-guid"
  }

  expect_failures = [
    var.app_registration_app_id,
  ]
}

# user_assigned_identity_id should accept a well-formed user-assigned identity ARM ID.
run "accepts_user_assigned_identity_id" {
  command = plan

  variables {
    user_assigned_identity_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-id/providers/Microsoft.ManagedIdentity/userAssignedIdentities/deployer-uai"
  }
}

# Malformed user_assigned_identity_id values must be rejected.
run "rejects_user_assigned_identity_id" {
  command = plan

  variables {
    user_assigned_identity_id = "not-a-valid-resource-id"
  }

  expect_failures = [
    var.user_assigned_identity_id,
  ]
}

# network_security_perimeter_id should accept a well-formed perimeter ARM ID.
run "accepts_network_security_perimeter_id" {
  command = plan

  variables {
    network_security_perimeter_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-sec/providers/Microsoft.Network/networkSecurityPerimeters/nsp-deployer"
  }
}

# Malformed network_security_perimeter_id values must be rejected.
run "rejects_network_security_perimeter_id" {
  command = plan

  variables {
    network_security_perimeter_id = "not-a-valid-resource-id"
  }

  expect_failures = [
    var.network_security_perimeter_id,
  ]
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

run "rejects_management_network_flow_timeout_over_thirty" {
  command = plan

  variables {
    management_network_flow_timeout_in_minutes = 31
  }

  expect_failures = [
    var.management_network_flow_timeout_in_minutes,
  ]
}
