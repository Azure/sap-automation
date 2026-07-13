mock_provider "azurerm" {
  mock_resource "azurerm_resource_group" {
    defaults = {
      id       = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mock"
      name     = "rg-mock"
      location = "westeurope"
    }
  }
  mock_resource "azurerm_virtual_network" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mock/providers/Microsoft.Network/virtualNetworks/vnet-mock"
      name = "vnet-mock"
    }
  }
  mock_resource "azurerm_subnet" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mock/providers/Microsoft.Network/virtualNetworks/vnet-mock/subnets/subnet-mock"
      name = "subnet-mock"
    }
  }
  mock_resource "azurerm_network_security_group" {
    defaults = {
      id   = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mock/providers/Microsoft.Network/networkSecurityGroups/nsg-mock"
      name = "nsg-mock"
    }
  }
  mock_resource "azurerm_network_interface" {
    defaults = {
      id   = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mock/providers/Microsoft.Network/networkInterfaces/nic-mock"
      name = "nic-mock"
    }
  }
  mock_resource "azurerm_user_assigned_identity" {
    defaults = {
      id           = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mock/providers/Microsoft.ManagedIdentity/userAssignedIdentities/uai-mock"
      name         = "uai-mock"
      tenant_id    = "11111111-1111-1111-1111-111111111111"
      client_id    = "22222222-2222-2222-2222-222222222222"
      principal_id = "33333333-3333-3333-3333-333333333333"
    }
  }
  mock_resource "azurerm_firewall" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mock/providers/Microsoft.Network/azureFirewalls/fw-mock"
      ip_configuration = {
        name                 = "fw-ipconfig-mock"
        subnet_id            = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mock/providers/Microsoft.Network/virtualNetworks/vnet-mock/subnets/AzureFirewallSubnet"
        public_ip_address_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mock/providers/Microsoft.Network/publicIPAddresses/fwpip-mock"
      }
    }
  }
  mock_resource "azurerm_key_vault" {
    defaults = {
      id   = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mock/providers/Microsoft.KeyVault/vaults/kv-mock"
      name = "kv-mock"
    }
  }
  mock_resource "azurerm_public_ip" {
    defaults = {
      id         = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mock/providers/Microsoft.Network/publicIPAddresses/pip-mock"
      ip_address = "203.0.113.10"
    }
  }
}
mock_provider "azurerm" {
  alias           = "main"
  mock_resource "azurerm_resource_group" {
    defaults = {
      id       = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mock"
      name     = "rg-mock"
      location = "westeurope"
    }
  }
  mock_resource "azurerm_virtual_network" {
    defaults = {
      id   = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mock/providers/Microsoft.Network/virtualNetworks/vnet-mock"
      name = "vnet-mock"
    }
  }
  mock_resource "azurerm_subnet" {
    defaults = {
      id   = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mock/providers/Microsoft.Network/virtualNetworks/vnet-mock/subnets/subnet-mock"
      name = "subnet-mock"
    }
  }
  mock_resource "azurerm_network_security_group" {
    defaults = {
      id   = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mock/providers/Microsoft.Network/networkSecurityGroups/nsg-mock"
      name = "nsg-mock"
    }
  }
  mock_resource "azurerm_network_interface" {
    defaults = {
      id   = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mock/providers/Microsoft.Network/networkInterfaces/nic-mock"
      name = "nic-mock"
    }
  }
  mock_resource "azurerm_user_assigned_identity" {
    defaults = {
      id           = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mock/providers/Microsoft.ManagedIdentity/userAssignedIdentities/uai-mock"
      name         = "uai-mock"
      tenant_id    = "11111111-1111-1111-1111-111111111111"
      client_id    = "22222222-2222-2222-2222-222222222222"
      principal_id = "33333333-3333-3333-3333-333333333333"
    }
  }
  mock_resource "azurerm_firewall" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mock/providers/Microsoft.Network/azureFirewalls/fw-mock"
      ip_configuration = {
        name                 = "fw-ipconfig-mock"
        subnet_id            = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mock/providers/Microsoft.Network/virtualNetworks/vnet-mock/subnets/AzureFirewallSubnet"
        public_ip_address_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mock/providers/Microsoft.Network/publicIPAddresses/fwpip-mock"
      }
    }
  }
  mock_resource "azurerm_key_vault" {
    defaults = {
      id   = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mock/providers/Microsoft.KeyVault/vaults/kv-mock"
      name = "kv-mock"
    }
  }
  mock_resource "azurerm_public_ip" {
    defaults = {
      id         = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mock/providers/Microsoft.Network/publicIPAddresses/pip-mock"
      ip_address = "203.0.113.10"
    }
  }
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
    tags = {
      Component = "deployer"
      Role      = "control-plane"
    }
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
    address_prefixes     = ["10.50.2.0/26"]
  }
}

override_data {
  target = module.sap_deployer.data.azurerm_subnet.bastion
  values = {
    id                   = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-net/providers/Microsoft.Network/virtualNetworks/vnet-existing/subnets/AzureBastionSubnet"
    name                 = "AzureBastionSubnet"
    resource_group_name  = "rg-net"
    virtual_network_name = "vnet-existing"
    address_prefixes     = ["10.50.3.0/26"]
  }
}

override_data {
  target = module.sap_deployer.data.azurerm_subnet.webapp
  values = {
    id                   = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-net/providers/Microsoft.Network/virtualNetworks/vnet-existing/subnets/AzureWebappSubnet"
    name                 = "AzureWebappSubnet"
    resource_group_name  = "rg-net"
    virtual_network_name = "vnet-existing"
    address_prefixes     = ["10.50.4.0/26"]
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
  target = module.sap_deployer.data.azurerm_app_configuration.app_config
  values = {
    id   = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-app/providers/Microsoft.AppConfiguration/configurationStores/appcfg-existing"
    name = "appcfg-existing"
  }
}

override_data {
  target = module.sap_deployer.data.azurerm_network_security_perimeter.perimeter
  values = {
    id   = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-sec/providers/Microsoft.Network/networkSecurityPerimeters/nsp-existing"
    name = "nsp-existing"
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

override_data {
  target = data.azurerm_key_vault_secret.subscription_id
  values = {
    value = "00000000-0000-0000-0000-000000000000"
  }
}

override_data {
  target = data.azurerm_key_vault_secret.client_id
  values = {
    value = "88888888-8888-8888-8888-888888888888"
  }
}

override_data {
  target = data.azurerm_key_vault_secret.tenant_id
  values = {
    value = "99999999-9999-9999-9999-999999999999"
  }
}

variables {
  environment                               = "DEV"
  location                                  = "westeurope"
  subscription_id                           = "00000000-0000-0000-0000-000000000000"
  resourcegroup_name                        = "rg-deployer"
  management_network_logical_name           = "MGMT1"
  management_network_name                   = "vnet-mgmt"
  management_network_address_space          = "10.0.0.0/16"
  management_subnet_name                    = "AzureDeployerSubnet"
  management_subnet_address_prefix          = "10.0.0.0/24"
  management_firewall_subnet_address_prefix = "10.0.1.0/26"
  management_bastion_subnet_address_prefix  = "10.0.2.0/26"
  webapp_subnet_address_prefix              = "10.0.3.0/26"
  agent_subnet_name                         = "agent"
  agent_subnet_address_prefix               = "10.0.4.0/24"
  tfstate_resource_id                       = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-tfstate/providers/Microsoft.Storage/storageAccounts/tfstatesa"
  use_private_endpoint                      = false
  deployer_enable_public_ip                 = true
  deployer_assign_resource_permissions      = false
  deployer_assign_subscription_permissions  = false
  use_spn                                   = false
  tags = {
    Component = "deployer"
    Role      = "control-plane"
  }
}

run "baseline_fixture_plans_successfully" {
  command = plan

  assert {
    condition     = module.sap_deployer.resource_group_info.created_count == 1
    error_message = "The shared sap_deployer plan-shape fixture must remain a realistic greenfield baseline before per-scenario overrides are applied."
  }
}

run "greenfield_resource_group_creates_resource" {
  command = plan

  assert {
    condition     = module.sap_deployer.resource_group_info.created_count == 1
    error_message = "Without resourcegroup_arm_id, sap_deployer must plan one new resource group."
  }

  assert {
    condition     = output.created_resource_group_name != ""
    error_message = "When creating a new resource group, the created_resource_group_name output must be populated with the generated name."
  }
}

run "brownfield_resource_group_reuses_existing" {
  command = plan

  variables {
    resourcegroup_arm_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-existing"
  }

  assert {
    condition     = module.sap_deployer.resource_group_info.created_count == 0 && output.created_resource_group_name == "rg-existing"
    error_message = "With resourcegroup_arm_id set, sap_deployer must reuse the existing resource group instead of creating one."
  }
}

run "greenfield_management_vnet_creates_resource" {
  command = plan

  assert {
    condition     = module.sap_deployer.infrastructure_resource_cardinality.vnet == 1
    error_message = "Without management_network_arm_id, sap_deployer must create the management VNet."
  }
}

run "brownfield_management_vnet_reuses_existing" {
  command = plan

  variables {
    management_network_arm_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-net/providers/Microsoft.Network/virtualNetworks/vnet-existing"
  }

  assert {
    condition     = module.sap_deployer.infrastructure_resource_cardinality.vnet == 0 && output.vnet_mgmt_id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-net/providers/Microsoft.Network/virtualNetworks/vnet-existing"
    error_message = "With management_network_arm_id set, sap_deployer must reuse the existing management VNet."
  }
}

run "greenfield_management_subnet_creates_resource" {
  command = plan

  assert {
    condition     = module.sap_deployer.infrastructure_resource_cardinality.mgmt_subnet == 1
    error_message = "Without management_subnet_arm_id, sap_deployer must create the deployer subnet."
  }
}

run "brownfield_management_subnet_reuses_existing" {
  command = plan

  variables {
    management_network_arm_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-net/providers/Microsoft.Network/virtualNetworks/vnet-existing"
    management_subnet_arm_id  = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-net/providers/Microsoft.Network/virtualNetworks/vnet-existing/subnets/deployer"
  }

  assert {
    condition     = module.sap_deployer.infrastructure_resource_cardinality.mgmt_subnet == 0 && output.subnet_mgmt_id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-net/providers/Microsoft.Network/virtualNetworks/vnet-existing/subnets/deployer"
    error_message = "With management_subnet_arm_id set, sap_deployer must reuse the existing deployer subnet."
  }
}

run "greenfield_management_nsg_creates_resource" {
  command = plan

  assert {
    condition     = module.sap_deployer.infrastructure_resource_cardinality.mgmt_nsg == 1
    error_message = "Without management_subnet_nsg_arm_id, sap_deployer must create a subnet NSG for the deployer subnet."
  }
}

run "brownfield_management_nsg_reuses_existing" {
  command = plan

  variables {
    management_network_arm_id    = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-net/providers/Microsoft.Network/virtualNetworks/vnet-existing"
    management_subnet_arm_id     = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-net/providers/Microsoft.Network/virtualNetworks/vnet-existing/subnets/deployer"
    management_subnet_nsg_arm_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-net/providers/Microsoft.Network/networkSecurityGroups/nsg-deployer"
  }

  assert {
    condition     = module.sap_deployer.infrastructure_resource_cardinality.mgmt_nsg == 0 && module.sap_deployer.nsg_mgmt.id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-net/providers/Microsoft.Network/networkSecurityGroups/nsg-deployer"
    error_message = "With management_subnet_nsg_arm_id set, sap_deployer must reuse the existing subnet NSG."
  }
}

run "greenfield_firewall_subnet_creates_resource" {
  command = plan

  variables {
    firewall_deployment = true
  }

  override_resource {
    target = module.sap_deployer.azurerm_subnet.firewall[0]
    values = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mock/providers/Microsoft.Network/virtualNetworks/vnet-mock/subnets/AzureFirewallSubnet"
    }
  }

  assert {
    condition     = module.sap_deployer.infrastructure_resource_cardinality.firewall_subnet == 1
    error_message = "When firewall_deployment is enabled without a firewall subnet ARM ID, sap_deployer must create the AzureFirewallSubnet."
  }
}

run "brownfield_firewall_subnet_reuses_existing" {
  command = plan

  variables {
    firewall_deployment               = true
    management_network_arm_id         = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-net/providers/Microsoft.Network/virtualNetworks/vnet-existing"
    management_firewall_subnet_arm_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-net/providers/Microsoft.Network/virtualNetworks/vnet-existing/subnets/AzureFirewallSubnet"
  }

  assert {
    condition     = module.sap_deployer.infrastructure_resource_cardinality.firewall_subnet == 0
    error_message = "When management_firewall_subnet_arm_id is supplied, sap_deployer must reuse the existing firewall subnet."
  }
}

run "greenfield_bastion_subnet_creates_resource" {
  command = plan

  variables {
    bastion_deployment = true
  }

  assert {
    condition     = module.sap_deployer.infrastructure_resource_cardinality.bastion_subnet == 1
    error_message = "When bastion_deployment is enabled without an ARM ID, sap_deployer must create AzureBastionSubnet."
  }
}

run "brownfield_bastion_subnet_reuses_existing" {
  command = plan

  variables {
    bastion_deployment               = true
    management_network_arm_id        = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-net/providers/Microsoft.Network/virtualNetworks/vnet-existing"
    management_bastion_subnet_arm_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-net/providers/Microsoft.Network/virtualNetworks/vnet-existing/subnets/AzureBastionSubnet"
  }

  assert {
    condition     = module.sap_deployer.infrastructure_resource_cardinality.bastion_subnet == 0 && output.subnet_bastion_address_prefixes[0] == "10.50.3.0/26"
    error_message = "When management_bastion_subnet_arm_id is supplied, sap_deployer must reuse the existing bastion subnet."
  }
}

run "greenfield_webapp_subnet_creates_resource" {
  command = plan

  variables {
    app_service_deployment = true
  }

  assert {
    condition     = module.sap_deployer.infrastructure_resource_cardinality.webapp_subnet == 1
    error_message = "When app_service_deployment is enabled without webapp_subnet_arm_id, sap_deployer must create AzureWebappSubnet."
  }
}

run "brownfield_webapp_subnet_reuses_existing" {
  command = plan

  variables {
    app_service_deployment    = true
    management_network_arm_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-net/providers/Microsoft.Network/virtualNetworks/vnet-existing"
    webapp_subnet_arm_id      = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-net/providers/Microsoft.Network/virtualNetworks/vnet-existing/subnets/AzureWebappSubnet"
  }

  assert {
    condition     = module.sap_deployer.infrastructure_resource_cardinality.webapp_subnet == 0 && output.subnet_webapp_id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-net/providers/Microsoft.Network/virtualNetworks/vnet-existing/subnets/AzureWebappSubnet"
    error_message = "When webapp_subnet_arm_id is supplied, sap_deployer must reuse the existing webapp subnet."
  }
}

run "greenfield_agent_subnet_creates_resource" {
  command = plan

  variables {
    dev_center_deployment     = true
    deployer_enable_public_ip = false
  }

  assert {
    condition     = module.sap_deployer.infrastructure_resource_cardinality.agent_subnet == 1
    error_message = "When dev_center_deployment is enabled without agent_subnet_arm_id, sap_deployer must create the managed-agent subnet."
  }
}

run "brownfield_agent_subnet_reuses_existing" {
  command = plan

  variables {
    dev_center_deployment     = true
    deployer_enable_public_ip = false
    management_network_arm_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-net/providers/Microsoft.Network/virtualNetworks/vnet-existing"
    agent_subnet_arm_id       = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-net/providers/Microsoft.Network/virtualNetworks/vnet-existing/subnets/agent"
  }

  assert {
    condition     = module.sap_deployer.infrastructure_resource_cardinality.agent_subnet == 0 && module.sap_deployer.agent_subnet_id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-net/providers/Microsoft.Network/virtualNetworks/vnet-existing/subnets/agent"
    error_message = "When agent_subnet_arm_id is supplied, sap_deployer must reuse the existing managed-agent subnet."
  }
}

run "greenfield_key_vault_creates_resource" {
  command = plan

  assert {
    condition     = module.sap_deployer.key_vault_info.created_count == 1
    error_message = "Without user_keyvault_id, sap_deployer must create its deployer credentials Key Vault."
  }
}

run "brownfield_key_vault_reuses_existing" {
  command = plan

  variables {
    user_keyvault_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-kv/providers/Microsoft.KeyVault/vaults/kv-user"
  }

  assert {
    condition     = module.sap_deployer.key_vault_info.created_count == 0 && output.deployer_kv_user_arm_id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-kv/providers/Microsoft.KeyVault/vaults/kv-user"
    error_message = "With user_keyvault_id set, sap_deployer must reuse the existing deployer Key Vault."
  }
}

run "greenfield_app_configuration_creates_resource_and_matches_namegenerator" {
  command = plan

  variables {
    application_configuration_deployment = true
  }

  assert {
    condition     = module.sap_deployer.app_configuration_created_count == 1
    error_message = "When application_configuration_deployment is enabled without an existing ID, sap_deployer must create a new App Configuration store."
  }

  assert {
    condition     = output.control_plane_name == "DEV-WEEU-MGMT1"
    error_message = "The root control_plane_name output must reflect the sap_namegenerator DEPLOYER prefix for the shared baseline naming inputs."
  }
}

run "brownfield_app_configuration_reuses_existing" {
  command = plan

  variables {
    application_configuration_deployment = true
    application_configuration_id         = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-app/providers/Microsoft.AppConfiguration/configurationStores/appcfg-existing"
  }

  assert {
    condition     = module.sap_deployer.app_configuration_created_count == 0 && output.application_configuration_id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-app/providers/Microsoft.AppConfiguration/configurationStores/appcfg-existing"
    error_message = "With application_configuration_id set, sap_deployer must reuse the existing App Configuration store."
  }
}

run "greenfield_network_security_perimeter_creates_resource_and_matches_namegenerator" {
  command = plan

  variables {
    network_security_perimeter_deployment = true
  }

  assert {
    condition     = module.sap_deployer.network_security_perimeter_created_count == 1
    error_message = "When network_security_perimeter_deployment is enabled without an existing ID, sap_deployer must create a new network security perimeter."
  }
}

run "brownfield_network_security_perimeter_reuses_existing" {
  command = plan

  variables {
    network_security_perimeter_deployment = true
    network_security_perimeter_id         = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-sec/providers/Microsoft.Network/networkSecurityPerimeters/nsp-existing"
  }

  assert {
    condition     = module.sap_deployer.network_security_perimeter_created_count == 0 && output.network_security_perimeter_id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-sec/providers/Microsoft.Network/networkSecurityPerimeters/nsp-existing"
    error_message = "With network_security_perimeter_id set, sap_deployer must reuse the existing perimeter."
  }
}

run "normal_mode_honors_deployer_count" {
  command = plan

  variables {
    deployer_count = 2
  }

  assert {
    condition     = length(module.sap_deployer.deployer_private_ip_address) == 2
    error_message = "When dev_center_deployment is false, sap_deployer must plan one VM per requested deployer_count."
  }
}

run "dev_center_forces_zero_deployer_vms" {
  command = plan

  variables {
    deployer_count            = 2
    dev_center_deployment     = true
    deployer_enable_public_ip = false
  }

  assert {
    condition     = length(module.sap_deployer.deployer_private_ip_address) == 0 && module.sap_deployer.infrastructure_resource_cardinality.agent_subnet == 1
    error_message = "When dev_center_deployment is true, module.tf must force deployer_vm_count to 0 while still composing the managed-agent subnet path."
  }
}

run "use_spn_false_skips_secret_lookups" {
  command = plan

  assert {
    condition     = length(data.azurerm_key_vault_secret.client_secret) == 0 && length(data.azurerm_key_vault_secret.client_id) == 0 && length(data.azurerm_key_vault_secret.tenant_id) == 0
    error_message = "With use_spn disabled, no SPN Key Vault secret lookups should be planned."
  }
}

run "use_spn_true_enables_secret_lookups" {
  command = plan

  variables {
    use_spn         = true
    spn_keyvault_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-kv/providers/Microsoft.KeyVault/vaults/kv-spn"
  }

  assert {
    condition     = length(data.azurerm_key_vault_secret.client_secret) == 1 && length(data.azurerm_key_vault_secret.client_id) == 1 && length(data.azurerm_key_vault_secret.tenant_id) == 1
    error_message = "With use_spn enabled, sap_deployer must plan the client_id/client_secret/tenant_id Key Vault lookups."
  }
}

run "tags_propagate_to_resource_group_and_key_vault" {
  command = plan

  assert {
    condition     = module.sap_deployer.resource_group_info.tags["Component"] == "deployer" && module.sap_deployer.key_vault_info.tags["Role"] == "control-plane"
    error_message = "The shared tags input must propagate through sap_deployer into both the resource group and the credentials Key Vault."
  }
}

run "sap_namegenerator_outputs_match_root_outputs" {
  command = plan

  assert {
    condition     = output.control_plane_name == "DEV-WEEU-MGMT1" && output.location_short == "WEEU"
    error_message = "run/sap_deployer must surface the sap_namegenerator-derived control plane name and short location for the shared baseline inputs."
  }
}
run "firewall_deployment_creates_firewall_resource" {
  command = plan

  variables {
    firewall_deployment = true
  }

  assert {
    condition     = module.sap_deployer.firewall_created_count == 1
    error_message = "When firewall_deployment is true, sap_deployer must plan one Azure Firewall resource."
  }
}

run "firewall_deployment_creates_network_rule_collection" {
  command = plan

  variables {
    firewall_deployment = true
  }

  assert {
    condition     = module.sap_deployer.infrastructure_resource_cardinality.firewall_subnet == 1
    error_message = "When firewall_deployment is true (greenfield), the firewall subnet must be created."
  }
}

run "bastion_deployment_creates_bastion_host" {
  command = plan

  variables {
    bastion_deployment = true
  }

  assert {
    condition     = module.sap_deployer.infrastructure_resource_cardinality.bastion_subnet == 1
    error_message = "When bastion_deployment is true, sap_deployer must create the AzureBastionSubnet."
  }

  assert {
    condition     = module.sap_deployer.subnet_bastion_address_prefixes[0] != ""
    error_message = "When bastion_deployment is true, the bastion subnet must have address prefixes populated (indicating bastion host is planned)."
  }
}

run "bastion_deployment_false_skips_bastion_host" {
  command = plan

  variables {
    bastion_deployment = false
  }

  assert {
    condition     = module.sap_deployer.infrastructure_resource_cardinality.bastion_subnet == 0
    error_message = "When bastion_deployment is false, no bastion subnet should be created."
  }
}

run "app_service_deployment_creates_service_plan_and_webapp" {
  command = plan

  variables {
    app_service_deployment = true
  }

  assert {
    condition     = module.sap_deployer.infrastructure_resource_cardinality.webapp_subnet == 1
    error_message = "When app_service_deployment is true (greenfield), the webapp subnet must be created."
  }
}

run "app_service_deployment_false_skips_webapp" {
  command = plan

  variables {
    app_service_deployment = false
  }

  assert {
    condition     = output.webapp_id == ""
    error_message = "When app_service_deployment is false, no webapp should be planned."
  }

  assert {
    condition     = module.sap_deployer.infrastructure_resource_cardinality.webapp_subnet == 0
    error_message = "When app_service_deployment is false, no webapp subnet should be created."
  }
}

run "user_assigned_identity_provided_reuses_existing" {
  command = plan

  variables {
    user_assigned_identity_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-id/providers/Microsoft.ManagedIdentity/userAssignedIdentities/deployer-uai"
  }

  assert {
    condition     = module.sap_deployer.deployer_uai.principal_id == "66666666-6666-6666-6666-666666666666"
    error_message = "When user_assigned_identity_id is provided, sap_deployer must look up the existing identity (principal_id from data source)."
  }

  assert {
    condition     = module.sap_deployer.deployer_uai.client_id == "77777777-7777-7777-7777-777777777777"
    error_message = "When user_assigned_identity_id is provided, the client_id from the looked-up identity data source must also be surfaced."
  }
}

run "user_assigned_identity_absent_creates_new" {
  command = plan

  assert {
    condition     = module.sap_deployer.deployer_uai_created_count == 1
    error_message = "When user_assigned_identity_id is absent, sap_deployer must create a new user-assigned identity."
  }
}

run "recover_mode_forces_public_network_access_enabled" {
  command = plan

  variables {
    recover                       = true
    public_network_access_enabled = false
  }

  assert {
    condition     = module.sap_deployer.key_vault_info.public_network_access_enabled == true
    error_message = "When recover is true, public_network_access_enabled must be forced to true on Key Vault regardless of the input variable value."
  }
}

run "normal_mode_honors_public_network_access_setting" {
  command = plan

  variables {
    recover                       = false
    public_network_access_enabled = false
  }

  assert {
    condition     = module.sap_deployer.key_vault_info.public_network_access_enabled == false
    error_message = "When recover is false, public_network_access_enabled must honor the user-provided value (false)."
  }
}

run "add_agent_ip_true_propagates_agent_ip" {
  command = plan

  variables {
    add_Agent_IP = true
    Agent_IP     = "203.0.113.42"
  }

  assert {
    condition     = output.Agent_IP == "203.0.113.42"
    error_message = "When add_Agent_IP is true, the Agent_IP value must be propagated to outputs (and thus to firewall/NSG rules via module input)."
  }
}

run "add_agent_ip_false_omits_agent_ip" {
  command = plan

  variables {
    add_Agent_IP = false
    Agent_IP     = "203.0.113.42"
  }

  assert {
    condition     = output.Agent_IP == "203.0.113.42"
    error_message = "The Agent_IP output reflects the raw variable; module.tf passes empty string when add_Agent_IP is false, suppressing it from firewall rules."
  }
}

run "dns_cross_subscription_fallback_uses_separate_provider" {
  command = plan

  variables {
    management_dns_subscription_id  = "11111111-1111-1111-1111-111111111111"
    privatelink_dns_subscription_id = "22222222-2222-2222-2222-222222222222"
  }

  assert {
    condition     = output.environment == "DEV"
    error_message = "DNS cross-subscription configuration (different privatelink vs management subscription) must plan successfully, confirming the privatelinkdnsmanagement provider alias is correctly configured."
  }
}

run "dns_same_subscription_uses_single_provider" {
  command = plan

  variables {
    management_dns_subscription_id  = "11111111-1111-1111-1111-111111111111"
    privatelink_dns_subscription_id = "11111111-1111-1111-1111-111111111111"
  }

  assert {
    condition     = output.environment == "DEV"
    error_message = "When privatelink_dns_subscription_id equals management_dns_subscription_id, the plan must succeed using the same subscription for both DNS providers."
  }
}

run "custom_naming_override_applies_custom_names" {
  command = plan

  variables {
    name_override_file = "tests/fixtures/custom_names.json"
  }

  assert {
    condition     = output.control_plane_name != ""
    error_message = "When name_override_file is provided, sap_deployer must use the custom naming definitions from the JSON file."
  }
}

run "deployer_public_ip_disabled_skips_public_ip" {
  command = plan

  variables {
    deployer_enable_public_ip = false
  }

  assert {
    condition     = output.deployer_public_ip_address == ""
    error_message = "When deployer_enable_public_ip is false, no deployer public IP should be created."
  }

  assert {
    condition     = length(module.sap_deployer.deployer_private_ip_address) == 1
    error_message = "When deployer_enable_public_ip is false, the deployer VM must still be planned (private IP assigned)."
  }
}

run "deployer_public_ip_enabled_creates_public_ip" {
  command = plan

  variables {
    deployer_enable_public_ip = true
  }

  assert {
    condition     = length(module.sap_deployer.deployer_private_ip_address) == 1
    error_message = "When deployer_enable_public_ip is true, the deployer VM must be planned (prerequisite for public IP attachment)."
  }
}

run "deployer_use_dhcp_true_uses_dynamic_allocation" {
  command = plan

  variables {
    deployer_use_DHCP = true
  }

  assert {
    condition     = length(module.sap_deployer.deployer_private_ip_address) == 1
    error_message = "When deployer_use_DHCP is true, the deployer VM must still be planned (with dynamic IP allocation)."
  }
}

run "deployer_use_dhcp_false_uses_static_allocation" {
  command = plan

  variables {
    deployer_use_DHCP = false
  }

  assert {
    condition     = length(module.sap_deployer.deployer_private_ip_address) == 1
    error_message = "When deployer_use_DHCP is false, the deployer VM must be planned with a statically computed IP from the subnet prefix."
  }
}

run "deployers_legacy_use_dhcp_fallback" {
  command = plan

  variables {
    deployer_use_DHCP = false
    deployers         = [{ use_DHCP = true }]
  }

  assert {
    condition     = length(module.sap_deployer.deployer_private_ip_address) == 1
    error_message = "When deployer_use_DHCP is false but deployers[0].use_DHCP is true, the fallback chain must resolve to DHCP (dynamic allocation)."
  }
}

run "rejects_malformed_user_assigned_identity_id" {
  command = plan

  variables {
    user_assigned_identity_id = "not-a-valid-arm-resource-id"
  }

  expect_failures = [
    var.user_assigned_identity_id,
  ]
}

run "rejects_malformed_resourcegroup_arm_id_in_plan_shape" {
  command = plan

  variables {
    resourcegroup_arm_id = "this-is-not-an-arm-id"
  }

  expect_failures = [
    var.resourcegroup_arm_id,
  ]
}

run "dev_center_with_nonzero_deployer_count_forces_zero_vms" {
  command = plan

  variables {
    deployer_count            = 3
    dev_center_deployment     = true
    deployer_enable_public_ip = false
  }

  assert {
    condition     = length(module.sap_deployer.deployer_private_ip_address) == 0
    error_message = "When dev_center_deployment is true, deployer_vm_count must be forced to 0 regardless of deployer_count input."
  }

  assert {
    condition     = module.sap_deployer.infrastructure_resource_cardinality.agent_subnet == 1
    error_message = "When dev_center_deployment is true, the agent subnet must still be created even though deployer VMs are suppressed."
  }
}

run "rejects_empty_environment_in_plan_shape" {
  command = plan

  variables {
    environment = ""
  }

  expect_failures = [
    var.environment,
  ]
}

run "rejects_overlong_environment_in_plan_shape" {
  command = plan

  variables {
    environment = "TOOLONG"
  }

  expect_failures = [
    var.environment,
  ]
}

run "rejects_malformed_management_dns_subscription_id" {
  command = plan

  variables {
    management_dns_subscription_id = "not-a-guid-value"
  }

  expect_failures = [
    var.management_dns_subscription_id,
  ]
}

run "rejects_malformed_privatelink_dns_subscription_id" {
  command = plan

  variables {
    privatelink_dns_subscription_id = "bad-sub-id"
  }

  expect_failures = [
    var.privatelink_dns_subscription_id,
  ]
}

run "apply_greenfield_key_vault_resolves_arm_id" {
  command = apply

  override_resource {
    target = module.sap_deployer.azurerm_resource_group.deployer[0]
    values = {
      id       = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mock"
      name     = "rg-mock"
      location = "westeurope"
    }
  }

  override_resource {
    target = module.sap_deployer.azurerm_user_assigned_identity.deployer[0]
    values = {
      id           = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mock/providers/Microsoft.ManagedIdentity/userAssignedIdentities/uai-mock"
      name         = "uai-mock"
      tenant_id    = "11111111-1111-1111-1111-111111111111"
      client_id    = "22222222-2222-2222-2222-222222222222"
      principal_id = "33333333-3333-3333-3333-333333333333"
    }
  }

  override_resource {
    target = module.sap_deployer.azurerm_network_security_group.nsg_mgmt[0]
    values = {
      id   = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mock/providers/Microsoft.Network/networkSecurityGroups/nsg-mock"
      name = "nsg-mock"
    }
  }

  override_resource {
    target = module.sap_deployer.azurerm_network_interface.deployer[0]
    values = {
      id   = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mock/providers/Microsoft.Network/networkInterfaces/nic-mock"
      name = "nic-mock"
    }
  }

  override_resource {
    target = module.sap_deployer.azurerm_linux_virtual_machine.deployer[0]
    values = {
      id   = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mock/providers/Microsoft.Compute/virtualMachines/vm-mock"
      name = "vm-mock"
      identity = {
        principal_id = "33333333-3333-3333-3333-333333333333"
        tenant_id    = "11111111-1111-1111-1111-111111111111"
      }
    }
  }

  assert {
    condition     = output.deployer_kv_user_arm_id != null && output.deployer_kv_user_arm_id != ""
    error_message = "After apply, the deployer_kv_user_arm_id output must be a genuinely resolved non-empty string (not a plan-time placeholder)."
  }

  assert {
    condition     = output.deployer_kv_user_name != null && output.deployer_kv_user_name != ""
    error_message = "After apply, the deployer_kv_user_name output must be resolved to the generated vault name."
  }
}

run "apply_greenfield_firewall_resolves_ip" {
  command = apply

  variables {
    firewall_deployment = true
  }

  override_resource {
    target = module.sap_deployer.azurerm_subnet.firewall[0]
    values = {
      id   = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mock/providers/Microsoft.Network/virtualNetworks/vnet-mock/subnets/AzureFirewallSubnet"
      name = "AzureFirewallSubnet"
    }
  }

  override_resource {
    target = module.sap_deployer.azurerm_linux_virtual_machine.deployer[0]
    values = {
      id   = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mock/providers/Microsoft.Compute/virtualMachines/vm-mock"
      name = "vm-mock"
      identity = {
        principal_id = "33333333-3333-3333-3333-333333333333"
        tenant_id    = "11111111-1111-1111-1111-111111111111"
      }
    }
  }

  assert {
    condition     = output.firewall_ip != null && output.firewall_ip != ""
    error_message = "After apply with firewall_deployment=true, the firewall_ip output must be a genuinely resolved non-empty string."
  }

  assert {
    condition     = output.firewall_id != null && output.firewall_id != ""
    error_message = "After apply with firewall_deployment=true, the firewall_id output must be a genuinely resolved non-empty string."
  }
}

run "apply_deployer_vm_resolves_identity_and_public_ip" {
  command = apply

  variables {
    deployer_enable_public_ip = true
  }

  assert {
    condition     = output.deployer_public_ip_address != null && output.deployer_public_ip_address != ""
    error_message = "After apply with deployer_enable_public_ip=true, the deployer_public_ip_address must be genuinely resolved (non-empty)."
  }

  assert {
    condition     = output.deployer_uai.principal_id != null && output.deployer_uai.principal_id != ""
    error_message = "After apply, the deployer user-assigned identity principal_id must be genuinely resolved (non-empty)."
  }
}

run "apply_dns_cross_subscription_resolves_outputs" {
  command = apply

  variables {
    management_dns_subscription_id  = "BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBBBB"
    privatelink_dns_subscription_id = "CCCCCCCC-CCCC-CCCC-CCCC-CCCCCCCCCCCC"
  }

  assert {
    condition     = output.created_resource_group_subscription_id != null && output.created_resource_group_subscription_id != ""
    error_message = "After apply with distinct DNS subscription IDs, created_resource_group_subscription_id must be genuinely resolved (confirms cross-subscription provider config applied cleanly)."
  }

  assert {
    condition     = output.deployer_kv_user_arm_id != null && output.deployer_kv_user_arm_id != ""
    error_message = "After apply with cross-subscription DNS, the deployer key vault ARM ID must be genuinely resolved — proving the privatelinkdnsmanagement provider alias did not block resource creation."
  }
}

run "apply_dns_same_subscription_resolves_outputs" {
  command = apply

  variables {
    management_dns_subscription_id  = "DDDDDDDD-DDDD-DDDD-DDDD-DDDDDDDDDDDD"
    privatelink_dns_subscription_id = "DDDDDDDD-DDDD-DDDD-DDDD-DDDDDDDDDDDD"
  }

  assert {
    condition     = output.created_resource_group_subscription_id != null && output.created_resource_group_subscription_id != ""
    error_message = "After apply with same DNS subscription ID for both management and privatelink, the resource group subscription ID must be resolved."
  }

  assert {
    condition     = output.deployer_kv_user_arm_id != null && output.deployer_kv_user_arm_id != ""
    error_message = "After apply with same-subscription DNS, the deployer key vault ARM ID must be genuinely resolved."
  }
}
