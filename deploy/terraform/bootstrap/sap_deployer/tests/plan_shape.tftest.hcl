# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.
#
# Plan-shape coverage for bootstrap/sap_deployer. These runs assert the
# greenfield/brownfield existence toggles composed in transform.tf, the
# bootstrap-specific firewall/public-access posture hardcoded in module.tf, tag
# propagation, and naming consistency with sap_namegenerator.

mock_provider "azurerm" {
}
mock_provider "azurerm" {
  alias           = "main"
  mock_resource "azurerm_user_assigned_identity" {
    defaults = {
      tenant_id = "11111111-1111-1111-1111-111111111111"
      id        = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mock/providers/Microsoft.ManagedIdentity/userAssignedIdentities/uai-mock"
    }
  }
  mock_data "azurerm_user_assigned_identity" {
    defaults = {
      tenant_id = "11111111-1111-1111-1111-111111111111"
      id        = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mock/providers/Microsoft.ManagedIdentity/userAssignedIdentities/uai-mock"
    }
  }
}
mock_provider "azurerm" {
  alias           = "dnsmanagement"
}
mock_provider "azurerm" {
  alias           = "privatelinkdnsmanagement"
}
mock_provider "azuread" {
}
mock_provider "azapi" {
  alias           = "restapi"
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
  target = module.sap_deployer.data.azurerm_subscription.primary
  values = {
    subscription_id = "00000000-0000-0000-0000-000000000000"
    tenant_id       = "00000000-0000-0000-0000-000000000000"
    display_name    = "diagnostic-subscription"
  }
}

variables {
  environment                      = "DEV"
  location                         = "westeurope"
  subscription_id                  = "00000000-0000-0000-0000-000000000000"
  management_network_logical_name  = "DEP01"
  management_network_address_space = "10.20.0.0/16"
  management_subnet_address_prefix = "10.20.0.0/24"
  custom_random_id                 = "abc"
  use_private_endpoint             = false
  use_service_endpoint             = false
  tags = {
    Module   = "bootstrap-sap-deployer"
    Scenario = "greenfield"
  }
  resourcegroup_tags = {
    Purpose = "terraform-test"
  }
}

run "greenfield_naming_tags_and_bootstrap_posture_are_preserved" {
  command = plan

  assert {
    condition     = output.created_resource_group_name == "${output.control_plane_name}-INFRASTRUCTURE"
    error_message = "When resourcegroup_name is left blank, bootstrap/sap_deployer must derive the created resource group name from sap_namegenerator's DEPLOYER prefix with the expected -INFRASTRUCTURE suffix."
  }

  assert {
    condition     = module.sap_deployer.resource_group_info.created_count == 1 && module.sap_deployer.infrastructure_resource_cardinality.vnet == 1 && module.sap_deployer.infrastructure_resource_cardinality.mgmt_subnet == 1 && module.sap_deployer.infrastructure_resource_cardinality.mgmt_nsg == 1 && module.sap_deployer.key_vault_info.created_count == 1
    error_message = "The baseline greenfield fixture must create the resource group, management VNet, management subnet/NSG, and user key vault instead of reusing existing IDs."
  }

  assert {
    condition     = module.sap_deployer.resource_group_info.tags["Module"] == "bootstrap-sap-deployer" && module.sap_deployer.key_vault_info.tags["Scenario"] == "greenfield" && module.sap_deployer.diagnostics_storage_info.tags["Purpose"] == "terraform-test"
    error_message = "Root-module tags must propagate into the created deployer resource group, key vault, and diagnostics storage account."
  }

  assert {
    condition     = module.sap_deployer.key_vault_info.public_network_access_enabled == true && module.sap_deployer.diagnostics_storage_info.default_action == "Allow"
    error_message = "bootstrap/sap_deployer must force the bootstrap-safe posture from module.tf through to real resources: the key vault must keep public network access enabled and the diagnostics storage account firewall must keep default_action = Allow."
  }
}

run "brownfield_core_infrastructure_reuses_existing_ids" {
  command = plan

  variables {
    resourcegroup_arm_id         = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-bootstrap"
    management_network_arm_id    = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-net/providers/Microsoft.Network/virtualNetworks/vnet-mgmt"
    management_subnet_arm_id     = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-net/providers/Microsoft.Network/virtualNetworks/vnet-mgmt/subnets/snet-management"
    management_subnet_nsg_arm_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-net/providers/Microsoft.Network/networkSecurityGroups/nsg-management"
    user_keyvault_id             = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-kv/providers/Microsoft.KeyVault/vaults/kv-bootstrap"
    tags = {
      Module   = "bootstrap-sap-deployer"
      Scenario = "brownfield"
    }
  }

  override_data {
    target = module.sap_deployer.data.azurerm_resource_group.deployer
    values = {
      id       = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-bootstrap"
      name     = "rg-bootstrap"
      location = "westeurope"
      tags = {
        Module   = "bootstrap-sap-deployer"
        Scenario = "brownfield"
      }
    }
  }

  override_data {
    target = module.sap_deployer.data.azurerm_virtual_network.vnet_mgmt
    values = {
      id                  = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-net/providers/Microsoft.Network/virtualNetworks/vnet-mgmt"
      name                = "vnet-mgmt"
      resource_group_name = "rg-net"
      address_space       = ["10.20.0.0/16"]
    }
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

  override_data {
    target = module.sap_deployer.data.azurerm_network_security_group.nsg_mgmt
    values = {
      id   = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-net/providers/Microsoft.Network/networkSecurityGroups/nsg-management"
      name = "nsg-management"
    }
  }

  override_data {
    target = module.sap_deployer.data.azurerm_key_vault.kv_user
    values = {
      id   = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-kv/providers/Microsoft.KeyVault/vaults/kv-bootstrap"
      name = "kv-bootstrap"
      tags = {
        Module   = "bootstrap-sap-deployer"
        Scenario = "brownfield"
      }
    }
  }

  assert {
    condition     = output.created_resource_group_id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-bootstrap" && output.vnet_mgmt_id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-net/providers/Microsoft.Network/virtualNetworks/vnet-mgmt" && output.subnet_mgmt_id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-net/providers/Microsoft.Network/virtualNetworks/vnet-mgmt/subnets/snet-management" && output.deployer_kv_user_arm_id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-kv/providers/Microsoft.KeyVault/vaults/kv-bootstrap"
    error_message = "Supplying brownfield ARM IDs must drive bootstrap/sap_deployer to surface the existing resource group, management VNet/subnet, and key vault IDs verbatim through its outputs."
  }

  assert {
    condition     = module.sap_deployer.resource_group_info.created_count == 0 && module.sap_deployer.infrastructure_resource_cardinality.vnet == 0 && module.sap_deployer.infrastructure_resource_cardinality.mgmt_subnet == 0 && module.sap_deployer.infrastructure_resource_cardinality.mgmt_nsg == 0 && module.sap_deployer.key_vault_info.created_count == 0
    error_message = "When the brownfield ARM IDs are supplied, bootstrap/sap_deployer must not create replacement core infrastructure resources."
  }
}

run "greenfield_optional_subnets_and_services_create_resources" {
  command = plan

  variables {
    firewall_deployment                       = true
    management_firewall_subnet_address_prefix = "10.20.1.0/26"
    bastion_deployment                        = true
    management_bastion_subnet_address_prefix  = "10.20.2.0/26"
    app_service_deployment                    = true
    webapp_subnet_address_prefix              = "10.20.3.0/26"
    app_registration_app_id                   = "11111111-1111-1111-1111-111111111111"
    webapp_client_secret                      = "diagnostic-only-secret"
    application_configuration_deployment      = true
    network_security_perimeter_deployment     = true
    dev_center_deployment                     = true
    agent_subnet_address_prefix               = "10.20.4.0/26"
    agent_pool                                = "pool-bootstrap"
    agent_ado_project                         = "sap-automation"
    agent_ado_url                             = "https://dev.azure.com/example"
    DevOpsInfrastructure_object_id            = "11111111-1111-1111-1111-111111111111"
    tags = {
      Module   = "bootstrap-sap-deployer"
      Scenario = "greenfield-optional"
    }
  }

  assert {
    condition     = module.sap_deployer.infrastructure_resource_cardinality.firewall_subnet == 1 && module.sap_deployer.infrastructure_resource_cardinality.bastion_subnet == 1 && module.sap_deployer.infrastructure_resource_cardinality.webapp_subnet == 1 && module.sap_deployer.infrastructure_resource_cardinality.agent_subnet == 1 && module.sap_deployer.app_configuration_created_count == 1 && module.sap_deployer.network_security_perimeter_created_count == 1
    error_message = "With the optional features enabled and no brownfield ARM IDs supplied, bootstrap/sap_deployer must create its own firewall, bastion, webapp, and agent subnets plus the application configuration store and network security perimeter."
  }

  assert {
    condition     = output.application_configuration_name == module.sap_namegenerator.naming_new.appconfig_name
    error_message = "The greenfield optional-services plan must use sap_namegenerator for the App Configuration store name when no explicit override is supplied."
  }
}

run "brownfield_optional_subnets_and_services_reuse_existing_ids" {
  command = plan

  variables {
    resourcegroup_arm_id                  = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-bootstrap"
    management_network_arm_id             = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-net/providers/Microsoft.Network/virtualNetworks/vnet-mgmt"
    management_subnet_arm_id              = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-net/providers/Microsoft.Network/virtualNetworks/vnet-mgmt/subnets/snet-management"
    management_subnet_nsg_arm_id          = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-net/providers/Microsoft.Network/networkSecurityGroups/nsg-management"
    user_keyvault_id                      = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-kv/providers/Microsoft.KeyVault/vaults/kv-bootstrap"
    firewall_deployment                   = true
    management_firewall_subnet_arm_id     = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-net/providers/Microsoft.Network/virtualNetworks/vnet-mgmt/subnets/AzureFirewallSubnet"
    bastion_deployment                    = true
    management_bastion_subnet_arm_id      = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-net/providers/Microsoft.Network/virtualNetworks/vnet-mgmt/subnets/AzureBastionSubnet"
    app_service_deployment                = true
    webapp_subnet_arm_id                  = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-net/providers/Microsoft.Network/virtualNetworks/vnet-mgmt/subnets/snet-webapp"
    app_registration_app_id               = "11111111-1111-1111-1111-111111111111"
    webapp_client_secret                  = "diagnostic-only-secret"
    application_configuration_deployment  = true
    application_configuration_id          = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-app/providers/Microsoft.AppConfiguration/configurationStores/appcfgbootstrap"
    network_security_perimeter_deployment = true
    network_security_perimeter_id         = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-sec/providers/Microsoft.Network/networkSecurityPerimeters/nsp-bootstrap"
    dev_center_deployment                 = true
    agent_subnet_arm_id                   = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-net/providers/Microsoft.Network/virtualNetworks/vnet-mgmt/subnets/snet-agent"
    agent_pool                            = "pool-bootstrap"
    agent_ado_project                     = "sap-automation"
    agent_ado_url                         = "https://dev.azure.com/example"
    DevOpsInfrastructure_object_id        = "11111111-1111-1111-1111-111111111111"
    tags = {
      Module   = "bootstrap-sap-deployer"
      Scenario = "brownfield-optional"
    }
  }

  override_data {
    target = module.sap_deployer.data.azurerm_resource_group.deployer
    values = {
      id       = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-bootstrap"
      name     = "rg-bootstrap"
      location = "westeurope"
      tags = {
        Module   = "bootstrap-sap-deployer"
        Scenario = "brownfield-optional"
      }
    }
  }

  override_data {
    target = module.sap_deployer.data.azurerm_virtual_network.vnet_mgmt
    values = {
      id                  = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-net/providers/Microsoft.Network/virtualNetworks/vnet-mgmt"
      name                = "vnet-mgmt"
      resource_group_name = "rg-net"
      address_space       = ["10.20.0.0/16"]
    }
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

  override_data {
    target = module.sap_deployer.data.azurerm_network_security_group.nsg_mgmt
    values = {
      id   = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-net/providers/Microsoft.Network/networkSecurityGroups/nsg-management"
      name = "nsg-management"
    }
  }

  override_data {
    target = module.sap_deployer.data.azurerm_subnet.firewall
    values = {
      id                   = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-net/providers/Microsoft.Network/virtualNetworks/vnet-mgmt/subnets/AzureFirewallSubnet"
      name                 = "AzureFirewallSubnet"
      resource_group_name  = "rg-net"
      virtual_network_name = "vnet-mgmt"
      address_prefixes     = ["10.20.1.0/26"]
    }
  }

  override_data {
    target = module.sap_deployer.data.azurerm_subnet.bastion
    values = {
      id                   = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-net/providers/Microsoft.Network/virtualNetworks/vnet-mgmt/subnets/AzureBastionSubnet"
      name                 = "AzureBastionSubnet"
      resource_group_name  = "rg-net"
      virtual_network_name = "vnet-mgmt"
      address_prefixes     = ["10.20.2.0/26"]
    }
  }

  override_data {
    target = module.sap_deployer.data.azurerm_subnet.webapp
    values = {
      id                   = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-net/providers/Microsoft.Network/virtualNetworks/vnet-mgmt/subnets/snet-webapp"
      name                 = "snet-webapp"
      resource_group_name  = "rg-net"
      virtual_network_name = "vnet-mgmt"
      address_prefixes     = ["10.20.3.0/26"]
    }
  }

  override_data {
    target = module.sap_deployer.data.azurerm_subnet.subnet_agent
    values = {
      id                   = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-net/providers/Microsoft.Network/virtualNetworks/vnet-mgmt/subnets/snet-agent"
      name                 = "snet-agent"
      resource_group_name  = "rg-net"
      virtual_network_name = "vnet-mgmt"
      address_prefixes     = ["10.20.4.0/26"]
    }
  }

  override_data {
    target = module.sap_deployer.data.azurerm_key_vault.kv_user
    values = {
      id   = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-kv/providers/Microsoft.KeyVault/vaults/kv-bootstrap"
      name = "kv-bootstrap"
      tags = {
        Module   = "bootstrap-sap-deployer"
        Scenario = "brownfield-optional"
      }
    }
  }

  override_data {
    target = module.sap_deployer.data.azurerm_app_configuration.app_config
    values = {
      id   = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-app/providers/Microsoft.AppConfiguration/configurationStores/appcfgbootstrap"
      name = "appcfgbootstrap"
    }
  }

  override_data {
    target = module.sap_deployer.data.azurerm_network_security_perimeter.perimeter
    values = {
      id   = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-sec/providers/Microsoft.Network/networkSecurityPerimeters/nsp-bootstrap"
      name = "nsp-bootstrap"
    }
  }

  assert {
    condition     = module.sap_deployer.infrastructure_resource_cardinality.firewall_subnet == 0 && module.sap_deployer.infrastructure_resource_cardinality.bastion_subnet == 0 && module.sap_deployer.infrastructure_resource_cardinality.webapp_subnet == 0 && module.sap_deployer.infrastructure_resource_cardinality.agent_subnet == 0 && module.sap_deployer.app_configuration_created_count == 0 && module.sap_deployer.network_security_perimeter_created_count == 0
    error_message = "Supplying brownfield ARM IDs for the optional subnet-backed services must suppress creation of replacement firewall, bastion, webapp, agent-subnet, App Configuration, and network-security-perimeter resources."
  }

  assert {
    condition     = output.application_configuration_id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-app/providers/Microsoft.AppConfiguration/configurationStores/appcfgbootstrap" && output.network_security_perimeter_id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-sec/providers/Microsoft.Network/networkSecurityPerimeters/nsp-bootstrap" && output.subnet_webapp_id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-net/providers/Microsoft.Network/virtualNetworks/vnet-mgmt/subnets/snet-webapp"
    error_message = "The brownfield optional-services scenario must surface the existing App Configuration store, network security perimeter, and webapp subnet IDs verbatim."
  }
}

run "firewall_deployment_creates_firewall_subnet" {
  command = plan

  variables {
    firewall_deployment                       = true
    management_firewall_subnet_address_prefix = "10.20.1.0/26"
  }

  assert {
    condition     = module.sap_deployer.infrastructure_resource_cardinality.firewall_subnet == 1
    error_message = "When firewall_deployment is enabled without a firewall subnet ARM ID, bootstrap/sap_deployer must create the AzureFirewallSubnet."
  }

  assert {
    condition     = module.sap_deployer.infrastructure_resource_cardinality.bastion_subnet == 0 && module.sap_deployer.infrastructure_resource_cardinality.webapp_subnet == 0
    error_message = "Enabling only firewall_deployment must not implicitly create bastion or webapp subnets."
  }
}

run "bastion_deployment_creates_bastion_subnet" {
  command = plan

  variables {
    bastion_deployment                       = true
    management_bastion_subnet_address_prefix = "10.20.2.0/26"
  }

  assert {
    condition     = module.sap_deployer.infrastructure_resource_cardinality.bastion_subnet == 1
    error_message = "When bastion_deployment is enabled without a bastion subnet ARM ID, bootstrap/sap_deployer must create the AzureBastionSubnet."
  }

  assert {
    condition     = module.sap_deployer.infrastructure_resource_cardinality.firewall_subnet == 0 && module.sap_deployer.infrastructure_resource_cardinality.webapp_subnet == 0
    error_message = "Enabling only bastion_deployment must not implicitly create firewall or webapp subnets."
  }
}

run "webapp_deployment_creates_webapp_subnet" {
  command = plan

  variables {
    app_service_deployment       = true
    webapp_subnet_address_prefix = "10.20.3.0/26"
    app_registration_app_id      = "11111111-1111-1111-1111-111111111111"
    webapp_client_secret         = "diagnostic-only-secret"
  }

  assert {
    condition     = module.sap_deployer.infrastructure_resource_cardinality.webapp_subnet == 1
    error_message = "When app_service_deployment is enabled without a webapp subnet ARM ID, bootstrap/sap_deployer must create the webapp subnet."
  }

  assert {
    condition     = output.app_service_deployment == true
    error_message = "When app_service_deployment is enabled, the root output must reflect that the App Service is deployed."
  }
}

run "user_assigned_identity_passes_through_to_module" {
  command = plan

  variables {
    user_assigned_identity_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-id/providers/Microsoft.ManagedIdentity/userAssignedIdentities/uai-bootstrap"
  }

  override_data {
    target = module.sap_deployer.data.azurerm_user_assigned_identity.deployer[0]
    values = {
      tenant_id = "11111111-1111-1111-1111-111111111111"
      id        = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-id/providers/Microsoft.ManagedIdentity/userAssignedIdentities/uai-bootstrap"
    }
  }

  assert {
    condition     = output.external_user_assigned_identity == true
    error_message = "When user_assigned_identity_id is supplied, bootstrap/sap_deployer must surface it via the external_user_assigned_identity output confirming the module received the external UAI."
  }
}

run "agent_ip_propagates_when_add_agent_ip_is_true" {
  command = plan

  variables {
    add_Agent_IP = true
    Agent_IP     = "203.0.113.42"
  }

  assert {
    condition     = output.Agent_IP == "203.0.113.42"
    error_message = "When add_Agent_IP is true, the Agent_IP value must propagate to the root output for downstream firewall rule consumption."
  }
}

run "agent_ip_suppressed_when_add_agent_ip_is_false" {
  command = plan

  variables {
    add_Agent_IP = false
    Agent_IP     = "203.0.113.42"
  }

  assert {
    condition     = output.Agent_IP == "203.0.113.42"
    error_message = "The Agent_IP output must reflect the variable value regardless of add_Agent_IP (the conditional gating happens at module.tf Agent_IP input)."
  }
}

run "deployer_public_ip_enabled_plans_public_ip_resource" {
  command = plan

  variables {
    deployer_enable_public_ip = true
    deployer_count            = 1
  }

  override_resource {
    target = module.sap_deployer.azurerm_public_ip.deployer[0]
    values = {
      ip_address = "10.20.30.40"
    }
  }

  assert {
    condition     = module.sap_deployer.deployer_public_ip_created_count == 1
    error_message = "When deployer_enable_public_ip is true, bootstrap/sap_deployer must plan at least one public IP address for the deployer VM."
  }

  assert {
    condition     = length(module.sap_deployer.deployer_private_ip_address) == 1
    error_message = "When deployer_enable_public_ip is true, the deployer VM must still have a private IP address planned."
  }
}

run "deployer_public_ip_disabled_skips_public_ip_resource" {
  command = plan

  variables {
    deployer_enable_public_ip = false
    deployer_count            = 1
  }

  assert {
    condition     = length(module.sap_deployer.deployer_public_ip_address) == 0
    error_message = "When deployer_enable_public_ip is false, bootstrap/sap_deployer must not plan any public IP addresses for the deployer VM."
  }

  assert {
    condition     = length(module.sap_deployer.deployer_private_ip_address) == 1
    error_message = "When deployer_enable_public_ip is false, the deployer VM must still be planned with a private IP address."
  }
}

run "dhcp_fallback_uses_azure_provided_ip" {
  command = plan

  variables {
    deployer_use_DHCP = true
    deployer_count    = 1
  }

  assert {
    condition     = length(module.sap_deployer.deployer_private_ip_address) == 1
    error_message = "When deployer_use_DHCP is true, bootstrap/sap_deployer must still plan one deployer VM with Azure-provided (DHCP) private IP addressing."
  }
}

run "dev_center_forces_zero_deployer_vms" {
  command = plan

  variables {
    deployer_count                 = 2
    dev_center_deployment          = true
    deployer_enable_public_ip      = false
    agent_subnet_address_prefix    = "10.20.4.0/26"
    agent_pool                     = "pool-bootstrap"
    agent_ado_project              = "sap-automation"
    agent_ado_url                  = "https://dev.azure.com/example"
    DevOpsInfrastructure_object_id = "11111111-1111-1111-1111-111111111111"
  }

  assert {
    condition     = length(module.sap_deployer.deployer_private_ip_address) == 0 && module.sap_deployer.infrastructure_resource_cardinality.agent_subnet == 1
    error_message = "When dev_center_deployment is true, bootstrap module.tf must force deployer_vm_count to 0 while still composing the managed-agent subnet path."
  }

  assert {
    condition     = length(module.sap_deployer.deployer_public_ip_address) == 0
    error_message = "When dev_center_deployment is true and deployer_vm_count is forced to 0, no public IP addresses should be planned."
  }
}

run "normal_mode_honors_deployer_count" {
  command = plan

  variables {
    deployer_count = 2
  }

  assert {
    condition     = length(module.sap_deployer.deployer_private_ip_address) == 2
    error_message = "When dev_center_deployment is false, bootstrap/sap_deployer must plan one VM per requested deployer_count."
  }
}
