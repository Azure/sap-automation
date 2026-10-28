# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

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
mock_provider "random" {}

override_resource {
  target = azurerm_resource_group.library
  values = {
    id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-library"
  }
}

variables {
  bootstrap                      = false
  place_delete_lock_on_resources = false
  naming                         = {}
  infrastructure = {
    environment        = "DEV"
    region             = "westeurope"
    resource_group     = { name = "rg-library", id = "", exists = false }
    tags               = {}
    assign_permissions = false
    spn_id             = ""
  }
  deployer = {
    use                          = false
    application_configuration_id = ""
    control_plane_name           = "DEV-WEEU-DEP01"
    management_network_id        = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-network/providers/Microsoft.Network/virtualNetworks/vnet-management"
  }
  key_vault = { id = "" }
  dns_settings = {
    dns_label                                    = ""
    create_privatelink_dns_zones                  = false
    register_storage_accounts_keyvaults_with_dns  = false
    register_endpoints_with_dns                   = false
    management_dns_resourcegroup_name             = ""
    privatelink_dns_resourcegroup_name            = ""
  }
  storage_account_tfstate = {
    id                                        = ""
    exists                                    = false
    name                                      = "sttfstatenetworktest"
    account_tier                              = "Standard"
    account_replication_type                  = "LRS"
    account_kind                              = "StorageV2"
    public_network_access_enabled             = false
    enable_firewall_for_keyvaults_and_storage  = false
    routing_preference_enabled                = false
    tfstate_blob_container                     = { name = "tfstate", is_existing = false }
  }
  storage_account_sapbits = {
    id                                        = ""
    exists                                    = false
    name                                      = "stsapbitsnetworktest"
    account_tier                              = "Standard"
    account_replication_type                  = "LRS"
    account_kind                              = "StorageV2"
    public_network_access_enabled             = false
    enable_firewall_for_keyvaults_and_storage  = false
    routing_preference_enabled                = false
    shared_access_key_enabled                 = false
    sapbits_blob_container                     = { name = "sapbits", is_existing = false }
    file_share                                = { name = "sapbits", is_existing = false }
  }
}

run "public_access_disabled_without_firewalls" {
  command = plan

  assert {
    condition     = !azurerm_storage_account.storage_tfstate[0].public_network_access_enabled && !azurerm_storage_account.storage_sapbits[0].public_network_access_enabled
    error_message = "Both public endpoints must stay disabled when public access and both firewall flags are false."
  }

  assert {
    condition     = length(azurerm_storage_account_network_rules.storage_tfstate) == 0 && length(azurerm_storage_account_network_rules.storage_sapbits) == 0
    error_message = "Disabled firewalls must not create network-rule resources."
  }
}

run "firewalls_preserve_tfstate_public_access_setting" {
  command = plan

  variables {
    storage_account_tfstate = merge(var.storage_account_tfstate, { enable_firewall_for_keyvaults_and_storage = true })
    storage_account_sapbits = merge(var.storage_account_sapbits, { enable_firewall_for_keyvaults_and_storage = true })
  }

  assert {
    condition     = !azurerm_storage_account.storage_tfstate[0].public_network_access_enabled && azurerm_storage_account.storage_sapbits[0].public_network_access_enabled
    error_message = "Firewalls must preserve disabled tfstate public access while enabling the SAPBits public endpoint."
  }

  assert {
    condition     = azurerm_storage_account_network_rules.storage_tfstate[0].default_action == "Deny" && azurerm_storage_account_network_rules.storage_sapbits[0].default_action == "Deny"
    error_message = "Both accounts must have deny-by-default network rules outside bootstrap, regardless of public access."
  }
}

run "tfstate_firewall_does_not_enable_public_access" {
  command = plan

  variables {
    storage_account_tfstate = merge(var.storage_account_tfstate, { enable_firewall_for_keyvaults_and_storage = true })
  }

  assert {
    condition     = !azurerm_storage_account.storage_tfstate[0].public_network_access_enabled && !azurerm_storage_account.storage_sapbits[0].public_network_access_enabled
    error_message = "The tfstate firewall must not enable public access for either storage account."
  }

  assert {
    condition     = azurerm_storage_account_network_rules.storage_tfstate[0].default_action == "Deny" && length(azurerm_storage_account_network_rules.storage_sapbits) == 0
    error_message = "Only tfstate must receive deny-by-default network rules when only its firewall flag is enabled."
  }
}

run "sapbits_firewall_does_not_enable_tfstate_public_access" {
  command = plan

  variables {
    storage_account_sapbits = merge(var.storage_account_sapbits, { enable_firewall_for_keyvaults_and_storage = true })
  }

  assert {
    condition     = !azurerm_storage_account.storage_tfstate[0].public_network_access_enabled && azurerm_storage_account.storage_sapbits[0].public_network_access_enabled
    error_message = "The SAPBits firewall must enable only SAPBits public access, independently of the tfstate firewall."
  }

  assert {
    condition     = length(azurerm_storage_account_network_rules.storage_tfstate) == 0 && azurerm_storage_account_network_rules.storage_sapbits[0].default_action == "Deny"
    error_message = "Only SAPBits must receive deny-by-default network rules when only its firewall flag is enabled."
  }
}

run "explicit_public_access_without_firewalls" {
  command = plan

  variables {
    storage_account_tfstate = merge(var.storage_account_tfstate, { public_network_access_enabled = true })
    storage_account_sapbits = merge(var.storage_account_sapbits, { public_network_access_enabled = true })
  }

  assert {
    condition     = azurerm_storage_account.storage_tfstate[0].public_network_access_enabled && azurerm_storage_account.storage_sapbits[0].public_network_access_enabled
    error_message = "Explicit public access must remain enabled for both accounts without requiring firewalls."
  }

  assert {
    condition     = length(azurerm_storage_account_network_rules.storage_tfstate) == 0 && length(azurerm_storage_account_network_rules.storage_sapbits) == 0
    error_message = "Explicit public access must not implicitly enable network-rule resources."
  }
}

run "tfstate_public_access_is_independent" {
  command = plan

  variables {
    storage_account_tfstate = merge(var.storage_account_tfstate, { public_network_access_enabled = true })
  }

  assert {
    condition     = azurerm_storage_account.storage_tfstate[0].public_network_access_enabled && !azurerm_storage_account.storage_sapbits[0].public_network_access_enabled
    error_message = "The tfstate public-access flag must affect only the tfstate storage account."
  }
}

run "explicit_public_access_with_firewalls" {
  command = plan

  variables {
    storage_account_tfstate = merge(var.storage_account_tfstate, {
      public_network_access_enabled            = true
      enable_firewall_for_keyvaults_and_storage = true
    })
    storage_account_sapbits = merge(var.storage_account_sapbits, {
      public_network_access_enabled            = true
      enable_firewall_for_keyvaults_and_storage = true
    })
  }

  assert {
    condition     = azurerm_storage_account.storage_tfstate[0].public_network_access_enabled && azurerm_storage_account.storage_sapbits[0].public_network_access_enabled
    error_message = "Explicit public access must remain enabled when firewalls are enabled."
  }

  assert {
    condition     = azurerm_storage_account_network_rules.storage_tfstate[0].default_action == "Deny" && azurerm_storage_account_network_rules.storage_sapbits[0].default_action == "Deny"
    error_message = "Explicit public access must not bypass either account's deny-by-default firewall."
  }
}

run "sapbits_public_access_is_independent" {
  command = plan

  variables {
    storage_account_sapbits = merge(var.storage_account_sapbits, { public_network_access_enabled = true })
  }

  assert {
    condition     = !azurerm_storage_account.storage_tfstate[0].public_network_access_enabled && azurerm_storage_account.storage_sapbits[0].public_network_access_enabled
    error_message = "The SAPBits public-access flag must not enable tfstate public access."
  }
}

run "bootstrap_preserves_allow_rules" {
  command = plan

  variables {
    bootstrap               = true
    storage_account_tfstate = merge(var.storage_account_tfstate, { enable_firewall_for_keyvaults_and_storage = true })
    storage_account_sapbits = merge(var.storage_account_sapbits, { enable_firewall_for_keyvaults_and_storage = true })
  }

  assert {
    condition     = !azurerm_storage_account.storage_tfstate[0].public_network_access_enabled && azurerm_storage_account.storage_sapbits[0].public_network_access_enabled
    error_message = "Bootstrap must preserve disabled tfstate public access while the SAPBits firewall enables its public endpoint."
  }

  assert {
    condition     = azurerm_storage_account_network_rules.storage_tfstate[0].default_action == "Allow" && azurerm_storage_account_network_rules.storage_sapbits[0].default_action == "Allow"
    error_message = "Bootstrap's existing allow-by-default behavior must be preserved for both accounts."
  }
}
