# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.
#
# Plan-shape coverage for bootstrap/sap_deployer. These runs assert the
# greenfield/brownfield existence toggles composed in transform.tf, the
# bootstrap-specific firewall/public-access posture hardcoded in module.tf, tag
# propagation, and naming consistency with sap_namegenerator.

mock_provider "azurerm" {}
mock_provider "azurerm" {
  alias = "main"
}
mock_provider "azurerm" {
  alias = "dnsmanagement"
}
mock_provider "azurerm" {
  alias = "privatelinkdnsmanagement"
}
mock_provider "azuread" {}
mock_provider "azapi" {
  alias = "restapi"
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
  environment                     = "DEV"
  location                        = "westeurope"
  subscription_id                 = "00000000-0000-0000-0000-000000000000"
  management_network_logical_name = "DEP01"
  management_network_address_space = "10.20.0.0/16"
  management_subnet_address_prefix = "10.20.0.0/24"
  custom_random_id                = "abc"
  use_private_endpoint            = false
  use_service_endpoint            = false
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
    resourcegroup_arm_id       = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-bootstrap"
    management_network_arm_id  = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-net/providers/Microsoft.Network/virtualNetworks/vnet-mgmt"
    management_subnet_arm_id   = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-net/providers/Microsoft.Network/virtualNetworks/vnet-mgmt/subnets/snet-management"
    management_subnet_nsg_arm_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-net/providers/Microsoft.Network/networkSecurityGroups/nsg-management"
    user_keyvault_id           = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-kv/providers/Microsoft.KeyVault/vaults/kv-bootstrap"
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
      id                  = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-net/providers/Microsoft.Network/virtualNetworks/vnet-mgmt/subnets/snet-management"
      name                = "snet-management"
      resource_group_name = "rg-net"
      virtual_network_name = "vnet-mgmt"
      address_prefixes    = ["10.20.0.0/24"]
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
    firewall_deployment                        = true
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
    resourcegroup_arm_id                       = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-bootstrap"
    management_network_arm_id                  = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-net/providers/Microsoft.Network/virtualNetworks/vnet-mgmt"
    management_subnet_arm_id                   = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-net/providers/Microsoft.Network/virtualNetworks/vnet-mgmt/subnets/snet-management"
    management_subnet_nsg_arm_id               = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-net/providers/Microsoft.Network/networkSecurityGroups/nsg-management"
    user_keyvault_id                           = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-kv/providers/Microsoft.KeyVault/vaults/kv-bootstrap"
    firewall_deployment                        = true
    management_firewall_subnet_arm_id          = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-net/providers/Microsoft.Network/virtualNetworks/vnet-mgmt/subnets/AzureFirewallSubnet"
    bastion_deployment                         = true
    management_bastion_subnet_arm_id           = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-net/providers/Microsoft.Network/virtualNetworks/vnet-mgmt/subnets/AzureBastionSubnet"
    app_service_deployment                     = true
    webapp_subnet_arm_id                       = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-net/providers/Microsoft.Network/virtualNetworks/vnet-mgmt/subnets/snet-webapp"
    app_registration_app_id                    = "11111111-1111-1111-1111-111111111111"
    webapp_client_secret                       = "diagnostic-only-secret"
    application_configuration_deployment       = true
    application_configuration_id               = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-app/providers/Microsoft.AppConfiguration/configurationStores/appcfgbootstrap"
    network_security_perimeter_deployment      = true
    network_security_perimeter_id              = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-sec/providers/Microsoft.Network/networkSecurityPerimeters/nsp-bootstrap"
    dev_center_deployment                      = true
    agent_subnet_arm_id                        = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-net/providers/Microsoft.Network/virtualNetworks/vnet-mgmt/subnets/snet-agent"
    agent_pool                                 = "pool-bootstrap"
    agent_ado_project                          = "sap-automation"
    agent_ado_url                              = "https://dev.azure.com/example"
    DevOpsInfrastructure_object_id             = "11111111-1111-1111-1111-111111111111"
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
