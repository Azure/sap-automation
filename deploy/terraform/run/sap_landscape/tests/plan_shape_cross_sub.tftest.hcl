mock_provider "azurerm" {
}
mock_provider "azurerm" {
  alias           = "workload"

  mock_resource "azurerm_key_vault" {
    defaults = {
      id   = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-sap-dev/providers/Microsoft.KeyVault/vaults/kv-mock"
      name = "kv-mock"
    }
  }
  mock_resource "azurerm_virtual_network" {
    defaults = {
      id   = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-sap-dev/providers/Microsoft.Network/virtualNetworks/vnet-sap01"
      name = "vnet-sap01"
    }
  }
  mock_resource "azurerm_subnet" {
    defaults = {
      id   = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-sap-dev/providers/Microsoft.Network/virtualNetworks/vnet-sap01/subnets/snet-mock"
      name = "snet-mock"
    }
  }
  mock_resource "azurerm_network_security_group" {
    defaults = {
      id   = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-sap-dev/providers/Microsoft.Network/networkSecurityGroups/nsg-mock"
      name = "nsg-mock"
    }
  }
  mock_resource "azurerm_route_table" {
    defaults = {
      id   = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-sap-dev/providers/Microsoft.Network/routeTables/rt-mock"
      name = "rt-mock"
    }
  }
  mock_resource "azurerm_storage_account" {
    defaults = {
      id                            = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-sap-dev/providers/Microsoft.Storage/storageAccounts/stmock"
      name                          = "stmock"
      primary_location              = "westeurope"
      secondary_location            = ""
      primary_blob_endpoint         = "https://stmock.blob.core.windows.net/"
      primary_blob_host             = "stmock.blob.core.windows.net"
      primary_blob_internet_endpoint = "https://stmock.blob.core.windows.net/"
      primary_blob_internet_host    = "stmock.blob.core.windows.net"
      primary_blob_microsoft_endpoint = "https://stmock.blob.core.windows.net/"
      primary_blob_microsoft_host   = "stmock.blob.core.windows.net"
      secondary_blob_endpoint       = ""
      secondary_blob_host           = ""
      secondary_blob_internet_endpoint = ""
      secondary_blob_internet_host = ""
      secondary_blob_microsoft_endpoint = ""
      secondary_blob_microsoft_host = ""
      primary_queue_endpoint        = "https://stmock.queue.core.windows.net/"
      primary_queue_host            = "stmock.queue.core.windows.net"
      primary_queue_microsoft_endpoint = "https://stmock.queue.core.windows.net/"
      primary_queue_microsoft_host  = "stmock.queue.core.windows.net"
      secondary_queue_endpoint      = ""
      secondary_queue_host          = ""
      secondary_queue_microsoft_endpoint = ""
      secondary_queue_microsoft_host = ""
      primary_table_endpoint        = "https://stmock.table.core.windows.net/"
      primary_table_host            = "stmock.table.core.windows.net"
      primary_table_microsoft_endpoint = "https://stmock.table.core.windows.net/"
      primary_table_microsoft_host  = "stmock.table.core.windows.net"
      secondary_table_endpoint      = ""
      secondary_table_host          = ""
      secondary_table_microsoft_endpoint = ""
      secondary_table_microsoft_host = ""
      primary_file_endpoint         = "https://stmock.file.core.windows.net/"
      primary_file_host             = "stmock.file.core.windows.net"
      primary_file_internet_endpoint = "https://stmock.file.core.windows.net/"
      primary_file_internet_host    = "stmock.file.core.windows.net"
      primary_file_microsoft_endpoint = "https://stmock.file.core.windows.net/"
      primary_file_microsoft_host   = "stmock.file.core.windows.net"
      secondary_file_endpoint       = ""
      secondary_file_host           = ""
      secondary_file_internet_endpoint = ""
      secondary_file_internet_host = ""
      secondary_file_microsoft_endpoint = ""
      secondary_file_microsoft_host = ""
      primary_dfs_endpoint          = "https://stmock.dfs.core.windows.net/"
      primary_dfs_host              = "stmock.dfs.core.windows.net"
      primary_dfs_internet_endpoint = "https://stmock.dfs.core.windows.net/"
      primary_dfs_internet_host     = "stmock.dfs.core.windows.net"
      primary_dfs_microsoft_endpoint = "https://stmock.dfs.core.windows.net/"
      primary_dfs_microsoft_host    = "stmock.dfs.core.windows.net"
      secondary_dfs_endpoint        = ""
      secondary_dfs_host            = ""
      secondary_dfs_internet_endpoint = ""
      secondary_dfs_internet_host = ""
      secondary_dfs_microsoft_endpoint = ""
      secondary_dfs_microsoft_host = ""
      primary_web_endpoint          = "https://stmock.z6.web.core.windows.net/"
      primary_web_host              = "stmock.z6.web.core.windows.net"
      primary_web_internet_endpoint = "https://stmock.z6.web.core.windows.net/"
      primary_web_internet_host     = "stmock.z6.web.core.windows.net"
      primary_web_microsoft_endpoint = "https://stmock.z6.web.core.windows.net/"
      primary_web_microsoft_host    = "stmock.z6.web.core.windows.net"
      secondary_web_endpoint        = ""
      secondary_web_host            = ""
      secondary_web_internet_endpoint = ""
      secondary_web_internet_host = ""
      secondary_web_microsoft_endpoint = ""
      secondary_web_microsoft_host = ""
      primary_access_key            = "mockprimaryaccesskey=="
      secondary_access_key          = "mocksecondaryaccesskey=="
      primary_connection_string     = "DefaultEndpointsProtocol=https;AccountName=stmock;AccountKey=mockprimaryaccesskey==;EndpointSuffix=core.windows.net"
      secondary_connection_string   = "DefaultEndpointsProtocol=https;AccountName=stmock;AccountKey=mocksecondaryaccesskey==;EndpointSuffix=core.windows.net"
      primary_blob_connection_string   = "DefaultEndpointsProtocol=https;AccountName=stmock;AccountKey=mockprimaryaccesskey==;EndpointSuffix=core.windows.net"
      secondary_blob_connection_string = "DefaultEndpointsProtocol=https;AccountName=stmock;AccountKey=mocksecondaryaccesskey==;EndpointSuffix=core.windows.net"
      access_tier                      = "Hot"
      large_file_share_enabled         = false
    }
  }
  mock_resource "azurerm_netapp_volume" {
    defaults = {
      id                  = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-sap-dev/providers/Microsoft.NetApp/netAppAccounts/anf-dev/capacityPools/pool-existing/volumes/vol-mock"
      mount_ip_addresses  = ["10.10.18.4"]
      volume_path         = "vol-mock"
    }
  }
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


run "dns_fallback_privatelink_equals_management_uses_same_subscription" {
  command = plan

  variables {
    management_dns_subscription_id  = "AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA"
    privatelink_dns_subscription_id = "AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA"
  }

  assert {
    condition     = output.management_dns_subscription_id == output.privatelink_dns_subscription_id
    error_message = "When privatelink_dns_subscription_id equals management_dns_subscription_id, both outputs must resolve to the same value."
  }
}

run "dns_fallback_privatelink_differs_from_management_uses_separate" {
  command = plan

  variables {
    management_dns_subscription_id  = "AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA"
    privatelink_dns_subscription_id = "BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBBBB"
  }

  assert {
    condition     = output.management_dns_subscription_id != output.privatelink_dns_subscription_id
    error_message = "When privatelink_dns_subscription_id differs from management_dns_subscription_id, they must resolve to different values."
  }

  assert {
    condition     = output.privatelink_dns_subscription_id == "BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBBBB"
    error_message = "privatelink_dns_subscription_id output must reflect the explicit input value."
  }
}

run "cross_subscription_dns_and_keyvault_resolution" {
  command = plan

  variables {
    subscription_id                              = "AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA"
    management_dns_subscription_id               = "BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBBBB"
    privatelink_dns_subscription_id              = "CCCCCCCC-CCCC-CCCC-CCCC-CCCCCCCCCCCC"
    user_keyvault_id                             = "/subscriptions/CCCCCCCC-CCCC-CCCC-CCCC-CCCCCCCCCCCC/resourceGroups/rg-shared/providers/Microsoft.KeyVault/vaults/kv-user-shared"
    register_storage_accounts_keyvaults_with_dns = true
    use_private_endpoint                         = true
  }

  override_data {
    target = data.terraform_remote_state.deployer
    values = {
      outputs = {
        created_resource_group_subscription_id = "DDDDDDDD-DDDD-DDDD-DDDD-DDDDDDDDDDDD"
        environment                            = "DEV"
        additional_network_id                  = ""
        application_configuration_id           = ""
        control_plane_name                     = "DEV-WEEU-DEP00"
        deployer_kv_user_arm_id                = "/subscriptions/DDDDDDDD-DDDD-DDDD-DDDD-DDDDDDDDDDDD/resourceGroups/rg-mgmt/providers/Microsoft.KeyVault/vaults/kv-deployer"
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
        network_security_perimeter_id                         = ""
        subnet_bastion_address_prefixes                       = ["10.0.1.0/26"]
        subnet_mgmt_address_prefixes                          = ["10.0.0.0/24"]
        subnet_mgmt_id                                        = "/subscriptions/DDDDDDDD-DDDD-DDDD-DDDD-DDDDDDDDDDDD/resourceGroups/rg-mgmt/providers/Microsoft.Network/virtualNetworks/vnet-mgmt/subnets/snet-mgmt"
        subnets_to_add_to_firewall_for_key_vaults_and_storage = []
        vnet_mgmt_id                                          = "/subscriptions/DDDDDDDD-DDDD-DDDD-DDDD-DDDDDDDDDDDD/resourceGroups/rg-mgmt/providers/Microsoft.Network/virtualNetworks/vnet-mgmt"
      }
    }
  }

  override_data {
    target = module.sap_landscape.data.azurerm_key_vault.kv_user
    values = {
      id   = "/subscriptions/CCCCCCCC-CCCC-CCCC-CCCC-CCCCCCCCCCCC/resourceGroups/rg-shared/providers/Microsoft.KeyVault/vaults/kv-user-shared"
      name = "kv-user-shared"
    }
  }

  assert {
    condition     = output.management_dns_subscription_id == "BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBBBB"
    error_message = "management_dns_subscription_id must resolve to the explicit input (sub B)."
  }

  assert {
    condition     = output.privatelink_dns_subscription_id == "CCCCCCCC-CCCC-CCCC-CCCC-CCCCCCCCCCCC"
    error_message = "privatelink_dns_subscription_id must resolve to the explicit input (sub C)."
  }

  assert {
    condition     = output.landscape_key_vault_user_arm_id == "/subscriptions/CCCCCCCC-CCCC-CCCC-CCCC-CCCCCCCCCCCC/resourceGroups/rg-shared/providers/Microsoft.KeyVault/vaults/kv-user-shared"
    error_message = "landscape_key_vault_user_arm_id must preserve the sub C prefix from the input ARM ID."
  }
}

run "full_four_subscription_topology_resolves_all_distinct" {
  command = plan

  variables {
    subscription_id                              = "AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA"
    management_subscription_id                   = "AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA"
    management_dns_subscription_id               = "BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBBBB"
    privatelink_dns_subscription_id              = "CCCCCCCC-CCCC-CCCC-CCCC-CCCCCCCCCCCC"
    peer_with_control_plane_vnet                 = true
    register_storage_accounts_keyvaults_with_dns = true
    register_virtual_network_to_dns              = true
    use_private_endpoint                         = true
    user_keyvault_id                             = "/subscriptions/CCCCCCCC-CCCC-CCCC-CCCC-CCCCCCCCCCCC/resourceGroups/rg-shared/providers/Microsoft.KeyVault/vaults/kv-user"
    network_arm_id                               = ""
    admin_subnet_arm_id                          = ""
    admin_subnet_nsg_arm_id                      = ""
    admin_subnet_address_prefix                  = "10.20.0.0/24"
    db_subnet_arm_id                             = ""
    db_subnet_nsg_arm_id                         = ""
    db_subnet_address_prefix                     = "10.20.1.0/24"
    app_subnet_arm_id                            = ""
    app_subnet_nsg_arm_id                        = ""
    app_subnet_address_prefix                    = "10.20.2.0/24"
    storage_subnet_arm_id                        = ""
    storage_subnet_nsg_arm_id                    = ""
    storage_subnet_address_prefix                = "10.20.3.0/24"
    dns_label                                    = "corp.contoso.internal"
  }

  override_data {
    target = data.terraform_remote_state.deployer
    values = {
      outputs = {
        created_resource_group_subscription_id = "DDDDDDDD-DDDD-DDDD-DDDD-DDDDDDDDDDDD"
        environment                            = "DEV"
        additional_network_id                  = ""
        application_configuration_id           = ""
        control_plane_name                     = "DEV-WEEU-DEP00"
        deployer_kv_user_arm_id                = "/subscriptions/DDDDDDDD-DDDD-DDDD-DDDD-DDDDDDDDDDDD/resourceGroups/rg-mgmt/providers/Microsoft.KeyVault/vaults/kv-deployer"
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
        network_security_perimeter_id                         = ""
        subnet_bastion_address_prefixes                       = ["10.0.1.0/26"]
        subnet_mgmt_address_prefixes                          = ["10.0.0.0/24"]
        subnet_mgmt_id                                        = "/subscriptions/DDDDDDDD-DDDD-DDDD-DDDD-DDDDDDDDDDDD/resourceGroups/rg-mgmt/providers/Microsoft.Network/virtualNetworks/vnet-mgmt/subnets/snet-mgmt"
        subnets_to_add_to_firewall_for_key_vaults_and_storage = []
        vnet_mgmt_id                                          = "/subscriptions/DDDDDDDD-DDDD-DDDD-DDDD-DDDDDDDDDDDD/resourceGroups/rg-mgmt/providers/Microsoft.Network/virtualNetworks/vnet-mgmt"
      }
    }
  }

  override_data {
    target = module.sap_landscape.data.azurerm_key_vault.kv_user
    values = {
      id   = "/subscriptions/CCCCCCCC-CCCC-CCCC-CCCC-CCCCCCCCCCCC/resourceGroups/rg-shared/providers/Microsoft.KeyVault/vaults/kv-user"
      name = "kv-user"
    }
  }

  assert {
    condition     = output.management_dns_subscription_id == "BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBBBB"
    error_message = "In 4-sub topology, management_dns_subscription_id must resolve to sub B."
  }

  assert {
    condition     = output.privatelink_dns_subscription_id == "CCCCCCCC-CCCC-CCCC-CCCC-CCCCCCCCCCCC"
    error_message = "In 4-sub topology, privatelink_dns_subscription_id must resolve to sub C."
  }

  assert {
    condition     = output.management_dns_subscription_id != output.privatelink_dns_subscription_id
    error_message = "In 4-sub topology, management and privatelink DNS subscriptions must be distinct."
  }

  assert {
    condition     = module.sap_landscape.network_resource_counts.vnet == 1
    error_message = "In 4-sub topology with greenfield VNet, the VNet must be created."
  }

  assert {
    condition     = module.sap_landscape.dns_link_counts.vnet_sap == 1
    error_message = "In 4-sub topology with DNS registration enabled, VNet DNS link must be planned."
  }

  assert {
    condition     = output.landscape_key_vault_user_arm_id == "/subscriptions/CCCCCCCC-CCCC-CCCC-CCCC-CCCCCCCCCCCC/resourceGroups/rg-shared/providers/Microsoft.KeyVault/vaults/kv-user"
    error_message = "In 4-sub topology, user keyvault ARM ID must preserve the sub C prefix."
  }
}

run "privatelink_dns_fallback_explicit_value_takes_priority" {
  command = plan

  variables {
    management_dns_subscription_id  = "BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBBBB"
    privatelink_dns_subscription_id = "CCCCCCCC-CCCC-CCCC-CCCC-CCCCCCCCCCCC"
  }

  assert {
    condition     = output.privatelink_dns_subscription_id == "CCCCCCCC-CCCC-CCCC-CCCC-CCCCCCCCCCCC"
    error_message = "When privatelink_dns_subscription_id is non-empty, it must take priority over all fallbacks."
  }

  assert {
    condition     = output.management_dns_subscription_id == "BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBBBB"
    error_message = "When management_dns_subscription_id is non-empty, it must resolve to the explicit input value."
  }
}

run "privatelink_dns_fallback_empty_uses_management_dns" {
  command = plan

  variables {
    management_dns_subscription_id  = "BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBBBB"
    privatelink_dns_subscription_id = ""
  }

  assert {
    condition     = output.privatelink_dns_subscription_id == "BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBBBB"
    error_message = "When privatelink_dns_subscription_id is empty, it must fall back to management_dns_subscription_id."
  }

  assert {
    condition     = output.management_dns_subscription_id == "BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBBBB"
    error_message = "When management_dns_subscription_id is explicitly set, it must resolve to that value."
  }
}

run "privatelink_dns_fallback_both_empty_uses_tfstate_subscription" {
  command = plan

  variables {
    management_dns_subscription_id  = ""
    privatelink_dns_subscription_id = ""
  }

  assert {
    condition     = output.privatelink_dns_subscription_id == "00000000-0000-0000-0000-000000000000"
    error_message = "When both DNS subscription IDs are empty, privatelink_dns_subscription_id must fall back to the tfstate storage account subscription."
  }

  assert {
    condition     = output.management_dns_subscription_id == "00000000-0000-0000-0000-000000000000"
    error_message = "When management_dns_subscription_id is empty, it must fall back to the tfstate storage account subscription."
  }
}

run "cross_sub_full_4_subscription_topology" {
  command = plan

  variables {
    subscription_id                              = "AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA"
    management_dns_subscription_id               = "BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBBBB"
    privatelink_dns_subscription_id              = "CCCCCCCC-CCCC-CCCC-CCCC-CCCCCCCCCCCC"
    user_keyvault_id                             = "/subscriptions/CCCCCCCC-CCCC-CCCC-CCCC-CCCCCCCCCCCC/resourceGroups/rg-shared/providers/Microsoft.KeyVault/vaults/kv-user"
    spn_keyvault_id                              = "/subscriptions/CCCCCCCC-CCCC-CCCC-CCCC-CCCCCCCCCCCC/resourceGroups/rg-shared/providers/Microsoft.KeyVault/vaults/kv-spn"
    peer_with_control_plane_vnet                 = true
    register_storage_accounts_keyvaults_with_dns = true
    use_private_endpoint                         = true
  }

  override_data {
    target = data.terraform_remote_state.deployer
    values = {
      outputs = {
        created_resource_group_subscription_id = "DDDDDDDD-DDDD-DDDD-DDDD-DDDDDDDDDDDD"
        environment                            = "DEV"
        additional_network_id                  = "/subscriptions/DDDDDDDD-DDDD-DDDD-DDDD-DDDDDDDDDDDD/resourceGroups/rg-mgmt/providers/Microsoft.Network/virtualNetworks/vnet-agent"
        application_configuration_id           = ""
        control_plane_name                     = "DEV-WEEU-DEP00"
        deployer_kv_user_arm_id                = "/subscriptions/DDDDDDDD-DDDD-DDDD-DDDD-DDDDDDDDDDDD/resourceGroups/rg-mgmt/providers/Microsoft.KeyVault/vaults/kv-deployer"
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
        network_security_perimeter_id                         = "/subscriptions/DDDDDDDD-DDDD-DDDD-DDDD-DDDDDDDDDDDD/resourceGroups/rg-mgmt/providers/Microsoft.Network/networkSecurityPerimeters/nsp-dev"
        subnet_bastion_address_prefixes                       = ["10.0.1.0/26"]
        subnet_mgmt_address_prefixes                          = ["10.0.0.0/24"]
        subnet_mgmt_id                                        = "/subscriptions/DDDDDDDD-DDDD-DDDD-DDDD-DDDDDDDDDDDD/resourceGroups/rg-mgmt/providers/Microsoft.Network/virtualNetworks/vnet-mgmt/subnets/snet-mgmt"
        subnets_to_add_to_firewall_for_key_vaults_and_storage = []
        vnet_mgmt_id                                          = "/subscriptions/DDDDDDDD-DDDD-DDDD-DDDD-DDDDDDDDDDDD/resourceGroups/rg-mgmt/providers/Microsoft.Network/virtualNetworks/vnet-mgmt"
      }
    }
  }

  assert {
    condition     = output.resolved_deployer_subscription_id == "DDDDDDDD-DDDD-DDDD-DDDD-DDDDDDDDDDDD"
    error_message = "Deployer subscription must resolve to sub D (from deployer remote state created_resource_group_subscription_id)."
  }

  assert {
    condition     = output.resolved_management_dns_subscription_id == "BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBBBB"
    error_message = "Management DNS subscription must resolve to sub B (explicitly set)."
  }

  assert {
    condition     = output.resolved_privatelink_dns_subscription_id == "CCCCCCCC-CCCC-CCCC-CCCC-CCCCCCCCCCCC"
    error_message = "Private Link DNS subscription must resolve to sub C (explicitly set)."
  }

  assert {
    condition     = output.resolved_management_dns_subscription_id != output.resolved_privatelink_dns_subscription_id
    error_message = "Management DNS and Private Link DNS subscriptions must be distinct when both are explicitly set."
  }

  assert {
    condition     = output.resolved_deployer_subscription_id != output.resolved_management_dns_subscription_id
    error_message = "Deployer and Management DNS subscriptions must be distinct in a 4-subscription topology."
  }

  assert {
    condition     = output.resolved_deployer_subscription_id != output.resolved_privatelink_dns_subscription_id
    error_message = "Deployer and Private Link DNS subscriptions must be distinct in a 4-subscription topology."
  }

  assert {
    condition     = startswith(output.landscape_key_vault_spn_arm_id, "/subscriptions/CCCCCCCC-CCCC-CCCC-CCCC-CCCCCCCCCCCC/") || startswith(output.landscape_key_vault_spn_arm_id, "/subscriptions/DDDDDDDD-DDDD-DDDD-DDDD-DDDDDDDDDDDD/")
    error_message = "SPN key vault ARM ID must preserve the cross-subscription prefix from the coalesce() resolution."
  }
}

run "cross_sub_privatelink_dns_explicit_value" {
  command = plan

  variables {
    subscription_id                 = "AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA"
    management_dns_subscription_id  = "BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBBBB"
    privatelink_dns_subscription_id = "CCCCCCCC-CCCC-CCCC-CCCC-CCCCCCCCCCCC"
  }

  assert {
    condition     = output.resolved_privatelink_dns_subscription_id == "CCCCCCCC-CCCC-CCCC-CCCC-CCCCCCCCCCCC"
    error_message = "When privatelink_dns_subscription_id is explicitly set to sub C, the resolved output must equal that value."
  }

  assert {
    condition     = output.resolved_management_dns_subscription_id == "BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBBBB"
    error_message = "Management DNS subscription must independently resolve to sub B."
  }
}

run "cross_sub_privatelink_dns_falls_back_to_management_dns" {
  command = plan

  variables {
    subscription_id                 = "AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA"
    management_dns_subscription_id  = "BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBBBB"
    privatelink_dns_subscription_id = ""
  }

  assert {
    condition     = output.resolved_privatelink_dns_subscription_id == "BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBBBB"
    error_message = "When privatelink_dns_subscription_id is empty, it must fall back to management_dns_subscription_id (sub B)."
  }

  assert {
    condition     = output.resolved_management_dns_subscription_id == "BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBBBB"
    error_message = "Management DNS subscription must still resolve to sub B regardless of privatelink fallback."
  }
}

run "cross_sub_both_dns_empty_falls_back_to_tfstate" {
  command = plan

  variables {
    subscription_id                 = "AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA"
    management_dns_subscription_id  = ""
    privatelink_dns_subscription_id = ""
    tfstate_resource_id             = "/subscriptions/DDDDDDDD-DDDD-DDDD-DDDD-DDDDDDDDDDDD/resourceGroups/rg-tfstate/providers/Microsoft.Storage/storageAccounts/tfstatesa"
  }

  assert {
    condition     = output.resolved_privatelink_dns_subscription_id == "DDDDDDDD-DDDD-DDDD-DDDD-DDDDDDDDDDDD"
    error_message = "When both DNS subscription IDs are empty, privatelink must fall back to tfstate subscription (sub D)."
  }

  assert {
    condition     = output.resolved_management_dns_subscription_id == "DDDDDDDD-DDDD-DDDD-DDDD-DDDDDDDDDDDD"
    error_message = "When management_dns_subscription_id is empty, it must fall back to tfstate subscription (sub D)."
  }

  assert {
    condition     = output.resolved_privatelink_dns_subscription_id != "AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA"
    error_message = "DNS subscription fallback must NOT resolve to the workload subscription_id when tfstate is in a different subscription."
  }
}

run "cross_sub_privatelink_prefers_management_over_tfstate" {
  command = plan

  variables {
    subscription_id                 = "AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA"
    management_dns_subscription_id  = "BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBBBB"
    privatelink_dns_subscription_id = ""
    tfstate_resource_id             = "/subscriptions/DDDDDDDD-DDDD-DDDD-DDDD-DDDDDDDDDDDD/resourceGroups/rg-tfstate/providers/Microsoft.Storage/storageAccounts/tfstatesa"
  }

  assert {
    condition     = output.resolved_privatelink_dns_subscription_id == "BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBBBB"
    error_message = "When privatelink is empty but management_dns is set, privatelink must prefer management_dns (sub B) over tfstate (sub D)."
  }

  assert {
    condition     = output.resolved_privatelink_dns_subscription_id != "DDDDDDDD-DDDD-DDDD-DDDD-DDDDDDDDDDDD"
    error_message = "The coalesce() chain must pick management_dns_subscription_id before falling through to tfstate."
  }
}

run "apply_cross_sub_storage_creation_with_brownfield_dns" {
  command = apply

  variables {
    subscription_id                              = "AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA"
    management_dns_subscription_id               = "BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBBBB"
    privatelink_dns_subscription_id              = "BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBBBB"
    privatelink_dns_resourcegroup_name           = "rg-dns-central"
    management_dns_resourcegroup_name            = "rg-dns-central"
    user_keyvault_id                             = "/subscriptions/CCCCCCCC-CCCC-CCCC-CCCC-CCCCCCCCCCCC/resourceGroups/rg-shared/providers/Microsoft.KeyVault/vaults/kv-user-shared"
    spn_keyvault_id                              = "/subscriptions/CCCCCCCC-CCCC-CCCC-CCCC-CCCCCCCCCCCC/resourceGroups/rg-shared/providers/Microsoft.KeyVault/vaults/kv-spn-shared"
    diagnostics_storage_account_arm_id           = ""
    witness_storage_account_arm_id               = ""
    create_transport_storage                     = true
    NFS_provider                                 = "AFS"
    transport_storage_account_id                 = ""
    use_private_endpoint                         = true
    register_storage_accounts_keyvaults_with_dns = true
  }

  override_data {
    target = data.terraform_remote_state.deployer
    values = {
      outputs = {
        created_resource_group_subscription_id = "DDDDDDDD-DDDD-DDDD-DDDD-DDDDDDDDDDDD"
        environment                            = "DEV"
        additional_network_id                  = ""
        application_configuration_id           = ""
        control_plane_name                     = "DEV-WEEU-DEP00"
        deployer_kv_user_arm_id                = "/subscriptions/DDDDDDDD-DDDD-DDDD-DDDD-DDDDDDDDDDDD/resourceGroups/rg-mgmt/providers/Microsoft.KeyVault/vaults/kv-deployer"
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
        network_security_perimeter_id                         = ""
        subnet_bastion_address_prefixes                       = ["10.0.1.0/26"]
        subnet_mgmt_address_prefixes                          = ["10.0.0.0/24"]
        subnet_mgmt_id                                        = "/subscriptions/DDDDDDDD-DDDD-DDDD-DDDD-DDDDDDDDDDDD/resourceGroups/rg-mgmt/providers/Microsoft.Network/virtualNetworks/vnet-mgmt/subnets/snet-mgmt"
        subnets_to_add_to_firewall_for_key_vaults_and_storage = []
        vnet_mgmt_id                                          = "/subscriptions/DDDDDDDD-DDDD-DDDD-DDDD-DDDDDDDDDDDD/resourceGroups/rg-mgmt/providers/Microsoft.Network/virtualNetworks/vnet-mgmt"
      }
    }
  }

  override_data {
    target = module.sap_landscape.data.azurerm_key_vault.kv_user
    values = {
      id   = "/subscriptions/CCCCCCCC-CCCC-CCCC-CCCC-CCCCCCCCCCCC/resourceGroups/rg-shared/providers/Microsoft.KeyVault/vaults/kv-user-shared"
      name = "kv-user-shared"
    }
  }

  assert {
    condition     = output.storageaccount_name != ""
    error_message = "After apply, the diagnostics storage account name must be a resolved non-empty string."
  }

  assert {
    condition     = output.witness_storage_account != ""
    error_message = "After apply, the witness storage account name must be a resolved non-empty string."
  }

  assert {
    condition     = output.transport_storage_account_id != ""
    error_message = "After apply, the transport storage account ID must be a resolved non-empty string."
  }

  assert {
    condition     = output.resolved_management_dns_subscription_id == "BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBBBB"
    error_message = "After apply, management DNS subscription must resolve to sub B (brownfield DNS zone subscription)."
  }

  assert {
    condition     = output.resolved_privatelink_dns_subscription_id == "BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBBBB"
    error_message = "After apply, privatelink DNS subscription must resolve to sub B (same as management DNS in this scenario)."
  }

  assert {
    condition     = output.resolved_deployer_subscription_id == "DDDDDDDD-DDDD-DDDD-DDDD-DDDDDDDDDDDD"
    error_message = "After apply, deployer subscription must resolve to sub D from remote state."
  }
}

run "apply_cross_sub_keyvault_reuse_with_brownfield_dns_zone" {
  command = apply

  variables {
    subscription_id                              = "AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA"
    management_dns_subscription_id               = "BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBBBB"
    privatelink_dns_subscription_id              = "BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBBBB"
    user_keyvault_id                             = "/subscriptions/CCCCCCCC-CCCC-CCCC-CCCC-CCCCCCCCCCCC/resourceGroups/rg-shared/providers/Microsoft.KeyVault/vaults/kv-user-shared"
    spn_keyvault_id                              = "/subscriptions/CCCCCCCC-CCCC-CCCC-CCCC-CCCCCCCCCCCC/resourceGroups/rg-shared/providers/Microsoft.KeyVault/vaults/kv-spn-shared"
    use_private_endpoint                         = true
    register_storage_accounts_keyvaults_with_dns = true
  }

  override_data {
    target = data.terraform_remote_state.deployer
    values = {
      outputs = {
        created_resource_group_subscription_id = "DDDDDDDD-DDDD-DDDD-DDDD-DDDDDDDDDDDD"
        environment                            = "DEV"
        additional_network_id                  = ""
        application_configuration_id           = ""
        control_plane_name                     = "DEV-WEEU-DEP00"
        deployer_kv_user_arm_id                = "/subscriptions/DDDDDDDD-DDDD-DDDD-DDDD-DDDDDDDDDDDD/resourceGroups/rg-mgmt/providers/Microsoft.KeyVault/vaults/kv-deployer"
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
        network_security_perimeter_id                         = ""
        subnet_bastion_address_prefixes                       = ["10.0.1.0/26"]
        subnet_mgmt_address_prefixes                          = ["10.0.0.0/24"]
        subnet_mgmt_id                                        = "/subscriptions/DDDDDDDD-DDDD-DDDD-DDDD-DDDDDDDDDDDD/resourceGroups/rg-mgmt/providers/Microsoft.Network/virtualNetworks/vnet-mgmt/subnets/snet-mgmt"
        subnets_to_add_to_firewall_for_key_vaults_and_storage = []
        vnet_mgmt_id                                          = "/subscriptions/DDDDDDDD-DDDD-DDDD-DDDD-DDDDDDDDDDDD/resourceGroups/rg-mgmt/providers/Microsoft.Network/virtualNetworks/vnet-mgmt"
      }
    }
  }

  override_data {
    target = module.sap_landscape.data.azurerm_key_vault.kv_user
    values = {
      id   = "/subscriptions/CCCCCCCC-CCCC-CCCC-CCCC-CCCCCCCCCCCC/resourceGroups/rg-shared/providers/Microsoft.KeyVault/vaults/kv-user-shared"
      name = "kv-user-shared"
    }
  }

  assert {
    condition     = output.landscape_key_vault_user_arm_id == "/subscriptions/CCCCCCCC-CCCC-CCCC-CCCC-CCCCCCCCCCCC/resourceGroups/rg-shared/providers/Microsoft.KeyVault/vaults/kv-user-shared"
    error_message = "After apply, user keyvault ARM ID must preserve the sub C prefix and not silently fall back."
  }

  assert {
    condition     = output.landscape_key_vault_spn_arm_id == "/subscriptions/CCCCCCCC-CCCC-CCCC-CCCC-CCCCCCCCCCCC/resourceGroups/rg-shared/providers/Microsoft.KeyVault/vaults/kv-spn-shared"
    error_message = "After apply, SPN keyvault ARM ID must preserve the sub C prefix from the explicit input."
  }

  assert {
    condition     = output.resolved_management_dns_subscription_id == "BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBBBB"
    error_message = "After apply, management DNS subscription must resolve to sub B (brownfield DNS zone)."
  }

  assert {
    condition     = output.resolved_management_dns_subscription_id != "CCCCCCCC-CCCC-CCCC-CCCC-CCCCCCCCCCCC"
    error_message = "After apply, DNS subscription (B) must not silently collapse to keyvault subscription (C)."
  }
}

run "apply_cross_sub_anf_with_multi_subscription_topology" {
  command = apply

  variables {
    subscription_id                              = "AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA"
    management_dns_subscription_id               = "BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBBBB"
    privatelink_dns_subscription_id              = "CCCCCCCC-CCCC-CCCC-CCCC-CCCCCCCCCCCC"
    user_keyvault_id                             = "/subscriptions/CCCCCCCC-CCCC-CCCC-CCCC-CCCCCCCCCCCC/resourceGroups/rg-shared/providers/Microsoft.KeyVault/vaults/kv-user"
    spn_keyvault_id                              = "/subscriptions/CCCCCCCC-CCCC-CCCC-CCCC-CCCCCCCCCCCC/resourceGroups/rg-shared/providers/Microsoft.KeyVault/vaults/kv-spn"
    NFS_provider                                 = "ANF"
    anf_subnet_arm_id                            = ""
    anf_subnet_nsg_arm_id                        = ""
    anf_subnet_address_prefix                    = "10.10.18.0/28"
    use_private_endpoint                         = true
    register_storage_accounts_keyvaults_with_dns = true
    peer_with_control_plane_vnet                 = true
    network_arm_id                               = ""
    admin_subnet_arm_id                          = ""
    admin_subnet_nsg_arm_id                      = ""
    admin_subnet_address_prefix                  = "10.20.0.0/24"
    db_subnet_arm_id                             = ""
    db_subnet_nsg_arm_id                         = ""
    db_subnet_address_prefix                     = "10.20.1.0/24"
    app_subnet_arm_id                            = ""
    app_subnet_nsg_arm_id                        = ""
    app_subnet_address_prefix                    = "10.20.2.0/24"
    storage_subnet_arm_id                        = ""
    storage_subnet_nsg_arm_id                    = ""
    storage_subnet_address_prefix                = "10.20.3.0/24"
  }

  override_data {
    target = data.terraform_remote_state.deployer
    values = {
      outputs = {
        created_resource_group_subscription_id = "DDDDDDDD-DDDD-DDDD-DDDD-DDDDDDDDDDDD"
        environment                            = "DEV"
        additional_network_id                  = "/subscriptions/DDDDDDDD-DDDD-DDDD-DDDD-DDDDDDDDDDDD/resourceGroups/rg-mgmt/providers/Microsoft.Network/virtualNetworks/vnet-agent"
        application_configuration_id           = ""
        control_plane_name                     = "DEV-WEEU-DEP00"
        deployer_kv_user_arm_id                = "/subscriptions/DDDDDDDD-DDDD-DDDD-DDDD-DDDDDDDDDDDD/resourceGroups/rg-mgmt/providers/Microsoft.KeyVault/vaults/kv-deployer"
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
        network_security_perimeter_id                         = ""
        subnet_bastion_address_prefixes                       = ["10.0.1.0/26"]
        subnet_mgmt_address_prefixes                          = ["10.0.0.0/24"]
        subnet_mgmt_id                                        = "/subscriptions/DDDDDDDD-DDDD-DDDD-DDDD-DDDDDDDDDDDD/resourceGroups/rg-mgmt/providers/Microsoft.Network/virtualNetworks/vnet-mgmt/subnets/snet-mgmt"
        subnets_to_add_to_firewall_for_key_vaults_and_storage = []
        vnet_mgmt_id                                          = "/subscriptions/DDDDDDDD-DDDD-DDDD-DDDD-DDDDDDDDDDDD/resourceGroups/rg-mgmt/providers/Microsoft.Network/virtualNetworks/vnet-mgmt"
      }
    }
  }

  override_data {
    target = module.sap_landscape.data.azurerm_key_vault.kv_user
    values = {
      id   = "/subscriptions/CCCCCCCC-CCCC-CCCC-CCCC-CCCCCCCCCCCC/resourceGroups/rg-shared/providers/Microsoft.KeyVault/vaults/kv-user"
      name = "kv-user"
    }
  }

  assert {
    condition     = output.ANF_pool_settings != null
    error_message = "After apply with NFS_provider=ANF, ANF_pool_settings output must be populated."
  }

  assert {
    condition     = output.vnet_sap_arm_id != ""
    error_message = "After apply with greenfield VNet, vnet_sap_arm_id must be a resolved non-empty string."
  }

  assert {
    condition     = output.resolved_management_dns_subscription_id == "BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBBBB"
    error_message = "After apply in ANF multi-sub topology, management DNS must resolve to sub B."
  }

  assert {
    condition     = output.resolved_privatelink_dns_subscription_id == "CCCCCCCC-CCCC-CCCC-CCCC-CCCCCCCCCCCC"
    error_message = "After apply in ANF multi-sub topology, privatelink DNS must resolve to sub C."
  }

  assert {
    condition     = output.resolved_deployer_subscription_id == "DDDDDDDD-DDDD-DDDD-DDDD-DDDDDDDDDDDD"
    error_message = "After apply in ANF multi-sub topology, deployer subscription must resolve to sub D."
  }

  assert {
    condition     = output.resolved_management_dns_subscription_id != output.resolved_privatelink_dns_subscription_id
    error_message = "After apply, management DNS (B) and privatelink DNS (C) subscriptions must remain distinct."
  }
}

run "apply_greenfield_admin_subnet_resolves_arm_id" {
  command = apply

  variables {
    network_arm_id              = ""
    admin_subnet_arm_id         = ""
    admin_subnet_address_prefix = "10.10.10.0/24"
    admin_subnet_nsg_arm_id     = ""
    db_subnet_arm_id            = ""
    db_subnet_nsg_arm_id        = ""
    db_subnet_address_prefix    = "10.10.11.0/24"
    app_subnet_arm_id           = ""
    app_subnet_nsg_arm_id       = ""
    app_subnet_address_prefix   = "10.10.12.0/24"
  }

  assert {
    condition     = output.admin_subnet_id != ""
    error_message = "After apply, greenfield admin subnet must produce a resolved non-empty ARM ID string."
  }

  assert {
    condition     = output.admin_nsg_id != ""
    error_message = "After apply, greenfield admin NSG must produce a resolved non-empty ARM ID string."
  }

  assert {
    condition     = output.vnet_sap_arm_id != ""
    error_message = "After apply, greenfield VNet must produce a resolved non-empty ARM ID string."
  }
}
