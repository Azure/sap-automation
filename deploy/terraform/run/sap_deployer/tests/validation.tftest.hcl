mock_provider "azurerm" {
  override_during = plan
}
mock_provider "azurerm" {
  alias           = "main"
  override_during = plan
}
mock_provider "azurerm" {
  alias           = "dnsmanagement"
  override_during = plan
}
mock_provider "azurerm" {
  alias           = "privatelinkdnsmanagement"
  override_during = plan
}
mock_provider "azapi" {
  alias           = "restapi"
  override_during = plan
}
mock_provider "azuread" {
  override_during = plan
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

run "baseline_variables_are_accepted" {
  command = plan

  assert {
    condition     = output.environment == "DEV"
    error_message = "The shared sap_deployer validation fixture must remain a realistic, fully-planable baseline for every positive-path validation run."
  }
}

# Infrastructure.region should allow a non-empty Azure region name.
run "accepts_infrastructure_region" {
  command = plan

  variables {
    infrastructure = {
      region = "northeurope"
    }
  }
}

# Whitespace-only infrastructure.region must be rejected.
run "rejects_infrastructure_region" {
  command = plan

  variables {
    infrastructure = {
      region = "   "
    }
  }

  expect_failures = [
    var.infrastructure,
  ]
}

# Infrastructure.environment should allow a non-empty environment code.
run "accepts_infrastructure_environment" {
  command = plan

  variables {
    infrastructure = {
      environment = "QAS"
    }
  }
}

# Empty infrastructure.environment must be rejected.
run "rejects_infrastructure_environment" {
  command = plan

  variables {
    infrastructure = {
      environment = ""
    }
  }

  expect_failures = [
    var.infrastructure,
  ]
}

# Infrastructure.virtual_network.management should accept an existing VNet ARM ID.
run "accepts_infrastructure_management_vnet_arm_id" {
  command = plan

  variables {
    infrastructure = {
      virtual_network = {
        management = {
          arm_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-net/providers/Microsoft.Network/virtualNetworks/vnet-brownfield"
          subnet_mgmt = {
            prefix = "10.50.1.0/24"
          }
        }
      }
    }
  }
}

# When infrastructure.virtual_network.management is provided, it must include either arm_id or address_space.
run "rejects_infrastructure_management_vnet_arm_id" {
  command = plan

  variables {
    infrastructure = {
      virtual_network = {
        management = {
          subnet_mgmt = {
            prefix = "10.50.1.0/24"
          }
        }
      }
    }
  }

  expect_failures = [
    var.infrastructure,
  ]
}

# Infrastructure.virtual_network.management should accept a greenfield address_space when no VNet ID is supplied.
run "accepts_infrastructure_management_vnet_address_space" {
  command = plan

  variables {
    infrastructure = {
      virtual_network = {
        management = {
          address_space = "10.50.0.0/16"
          subnet_mgmt = {
            prefix = "10.50.1.0/24"
          }
        }
      }
    }
  }
}

# An explicitly-empty management arm_id and address_space pair must be rejected.
run "rejects_infrastructure_management_vnet_address_space" {
  command = plan

  variables {
    infrastructure = {
      virtual_network = {
        management = {
          arm_id        = ""
          address_space = ""
          subnet_mgmt = {
            prefix = "10.50.1.0/24"
          }
        }
      }
    }
  }

  expect_failures = [
    var.infrastructure,
  ]
}

# Infrastructure.virtual_network.management.subnet_mgmt should accept an existing subnet ARM ID.
run "accepts_infrastructure_management_subnet_arm_id" {
  command = plan

  variables {
    infrastructure = {
      virtual_network = {
        management = {
          address_space = "10.50.0.0/16"
          subnet_mgmt = {
            arm_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-net/providers/Microsoft.Network/virtualNetworks/vnet-brownfield/subnets/deployer"
          }
        }
      }
    }
  }
}

# When infrastructure.virtual_network.management.subnet_mgmt is provided, it must include either arm_id or prefix.
run "rejects_infrastructure_management_subnet_arm_id" {
  command = plan

  variables {
    infrastructure = {
      virtual_network = {
        management = {
          address_space = "10.50.0.0/16"
          subnet_mgmt   = {}
        }
      }
    }
  }

  expect_failures = [
    var.infrastructure,
  ]
}

# Infrastructure.virtual_network.management.subnet_mgmt should accept a greenfield subnet prefix when no subnet ID is supplied.
run "accepts_infrastructure_management_subnet_prefix" {
  command = plan

  variables {
    infrastructure = {
      virtual_network = {
        management = {
          address_space = "10.50.0.0/16"
          subnet_mgmt = {
            prefix = "10.50.1.0/24"
          }
        }
      }
    }
  }
}

# An explicitly-empty management subnet arm_id and prefix pair must be rejected.
run "rejects_infrastructure_management_subnet_prefix" {
  command = plan

  variables {
    infrastructure = {
      virtual_network = {
        management = {
          address_space = "10.50.0.0/16"
          subnet_mgmt = {
            arm_id = ""
            prefix = ""
          }
        }
      }
    }
  }

  expect_failures = [
    var.infrastructure,
  ]
}

# The authentication object should accept a populated map.
run "accepts_authentication_object" {
  command = plan

  variables {
    authentication = {
      username            = "opsadmin"
      path_to_public_key  = ""
      path_to_private_key = ""
    }
  }
}

# An empty authentication object must be rejected.
run "rejects_authentication_object" {
  command = plan

  variables {
    authentication = {}
  }

  expect_failures = [
    var.authentication,
  ]
}

# Authentication.username should accept a non-empty VM admin name.
run "accepts_authentication_username" {
  command = plan

  variables {
    authentication = {
      username = "deployadmin"
    }
  }
}

# An empty authentication.username must be rejected.
run "rejects_authentication_username" {
  command = plan

  variables {
    authentication = {
      username = ""
    }
  }

  expect_failures = [
    var.authentication,
  ]
}

# The optional key_vault.keyvault_id_for_deployment_credentials value should accept a well-formed ARM ID.
run "accepts_key_vault_keyvault_id_for_deployment_credentials" {
  command = plan

  variables {
    key_vault = {
      keyvault_id_for_deployment_credentials = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-kv/providers/Microsoft.KeyVault/vaults/kv-deployment"
    }
  }
}

# Malformed key_vault.keyvault_id_for_deployment_credentials values must be rejected.
run "rejects_key_vault_keyvault_id_for_deployment_credentials" {
  command = plan

  variables {
    key_vault = {
      keyvault_id_for_deployment_credentials = "not-a-valid-resource-id"
    }
  }

  expect_failures = [
    var.key_vault,
  ]
}

# The root environment variable should accept a short, non-empty control-plane code.
run "accepts_environment" {
  command = plan

  variables {
    environment = "QAS"
  }
}

# Environment values longer than five characters must be rejected.
run "rejects_environment" {
  command = plan

  variables {
    environment = "TOOLONG"
  }

  expect_failures = [
    var.environment,
  ]
}

# Subscription IDs should accept a 36-character GUID string.
run "accepts_subscription_id" {
  command = plan

  variables {
    subscription_id = "11111111-1111-1111-1111-111111111111"
  }
}

# Malformed subscription IDs must be rejected.
run "rejects_subscription_id" {
  command = plan

  variables {
    subscription_id = "short-guid"
  }

  expect_failures = [
    var.subscription_id,
  ]
}

# resourcegroup_arm_id should accept a well-formed resource-group ARM ID.
run "accepts_resourcegroup_arm_id" {
  command = plan

  variables {
    resourcegroup_arm_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-existing"
  }
}

# Malformed resourcegroup_arm_id values must be rejected.
run "rejects_resourcegroup_arm_id" {
  command = plan

  variables {
    resourcegroup_arm_id = "not-a-valid-resource-id"
  }

  expect_failures = [
    var.resourcegroup_arm_id,
  ]
}

# management_network_arm_id should accept a well-formed VNet ARM ID.
run "accepts_management_network_arm_id" {
  command = plan

  variables {
    management_network_arm_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-net/providers/Microsoft.Network/virtualNetworks/vnet-existing"
  }
}

# Malformed management_network_arm_id values must be rejected.
run "rejects_management_network_arm_id" {
  command = plan

  variables {
    management_network_arm_id = "not-a-valid-resource-id"
  }

  expect_failures = [
    var.management_network_arm_id,
  ]
}

# management_network_flow_timeout_in_minutes should accept values inside Azure's 4-30 minute range.
run "accepts_management_network_flow_timeout_in_minutes" {
  command = plan

  variables {
    management_network_flow_timeout_in_minutes = 10
  }
}

# management_network_flow_timeout_in_minutes values below 4 must be rejected.
run "rejects_management_network_flow_timeout_in_minutes" {
  command = plan

  variables {
    management_network_flow_timeout_in_minutes = 2
  }

  expect_failures = [
    var.management_network_flow_timeout_in_minutes,
  ]
}

# management_subnet_arm_id should accept a well-formed subnet ARM ID.
run "accepts_management_subnet_arm_id" {
  command = plan

  variables {
    management_subnet_arm_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-net/providers/Microsoft.Network/virtualNetworks/vnet-existing/subnets/deployer"
  }
}

# Malformed management_subnet_arm_id values must be rejected.
run "rejects_management_subnet_arm_id" {
  command = plan

  variables {
    management_subnet_arm_id = "not-a-valid-resource-id"
  }

  expect_failures = [
    var.management_subnet_arm_id,
  ]
}

# management_firewall_subnet_arm_id should accept a well-formed firewall subnet ARM ID.
run "accepts_management_firewall_subnet_arm_id" {
  command = plan

  variables {
    management_firewall_subnet_arm_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-net/providers/Microsoft.Network/virtualNetworks/vnet-existing/subnets/AzureFirewallSubnet"
  }
}

# Malformed management_firewall_subnet_arm_id values must be rejected.
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
