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


run "utility_storage_empty_entries_filtered_out" {
  command = plan

  variables {
    utility_storage_accounts = [
      {
        name                     = ""
        account_kind             = "StorageV2"
        account_tier             = "Standard"
        account_replication_type = "LRS"
        file_shares              = []
        blob_containers          = []
      },
      {
        name                     = "utilityacct1"
        account_kind             = "StorageV2"
        account_tier             = "Standard"
        account_replication_type = "LRS"
        file_shares              = []
        blob_containers          = [{ name = "sapbits" }]
      },
      {
        name                     = "utilityacct2"
        account_kind             = "FileStorage"
        account_tier             = "Premium"
        account_replication_type = "LRS"
        file_shares              = [{ name = "trans", quota = 100, protocol = "SMB" }]
        blob_containers          = []
      },
    ]
  }

  assert {
    condition     = module.sap_landscape.network_resource_counts.utility_storage_account == 2
    error_message = "utility_storage_settings must drop empty entries before planning storage accounts."
  }

  assert {
    condition     = length(output.utility_storage_account_names) == length(module.sap_namegenerator.naming.storageaccount_names.WORKLOAD_ZONE.landscape_utility_storage_account_names)
    error_message = "sap_namegenerator's utility_storage_count wiring must match the filtered utility storage account-name cardinality exactly."
  }
}

run "utility_storage_all_empty_entries_yield_no_resources" {
  command = plan

  variables {
    utility_storage_accounts = [
      {
        name                     = ""
        account_kind             = "StorageV2"
        account_tier             = "Standard"
        account_replication_type = "LRS"
        file_shares              = []
        blob_containers          = []
      },
    ]
  }

  assert {
    condition     = module.sap_landscape.network_resource_counts.utility_storage_account == 0
    error_message = "utility_storage_settings must plan no storage accounts when every entry is empty after filtering."
  }

  assert {
    condition     = length(output.utility_storage_account_names) == 0
    error_message = "When all utility storage entries are empty, utility_storage_account_names output must be an empty list."
  }
}

run "anf_feature_disabled_plans_no_netapp_resources" {
  command = plan

  assert {
    condition     = module.sap_landscape.netapp_resource_counts.account == 0
    error_message = "When NFS_provider is not ANF, sap_landscape must not plan NetApp account resources."
  }

  assert {
    condition     = module.sap_landscape.netapp_resource_counts.pool == 0
    error_message = "When NFS_provider is not ANF, sap_landscape must not plan NetApp pool resources."
  }
}

run "anf_feature_enabled_plans_netapp_resources" {
  command = plan

  variables {
    NFS_provider              = "ANF"
    anf_subnet_arm_id         = ""
    anf_subnet_nsg_arm_id     = ""
    anf_subnet_address_prefix = "10.10.18.0/28"
  }

  assert {
    condition     = module.sap_landscape.netapp_resource_counts.account == 1
    error_message = "When NFS_provider is ANF and no ANF account ARM ID is supplied, sap_landscape must create a NetApp account."
  }

  assert {
    condition     = module.sap_landscape.netapp_resource_counts.pool == 1
    error_message = "When NFS_provider is ANF and no existing pool is requested, sap_landscape must create a NetApp pool."
  }
}

run "diagnostics_storage_account_greenfield_creates_account" {
  command = apply

  variables {
    diagnostics_storage_account_arm_id = ""
    witness_storage_account_arm_id     = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-sap-dev/providers/Microsoft.Storage/storageAccounts/sawitness01"
  }

  assert {
    condition     = output.storageaccount_name != ""
    error_message = "Without diagnostics_storage_account_arm_id, sap_landscape must create the diagnostics storage account."
  }

  assert {
    condition     = output.storageaccount_rg_name != ""
    error_message = "Without diagnostics_storage_account_arm_id, the diagnostics storage account resource group name must be non-empty."
  }
}

run "diagnostics_storage_account_brownfield_reuses_existing" {
  command = plan

  variables {
    diagnostics_storage_account_arm_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-sap-dev/providers/Microsoft.Storage/storageAccounts/sadiag01"
  }

  assert {
    condition     = output.storageaccount_name != ""
    error_message = "With diagnostics_storage_account_arm_id supplied, sap_landscape must resolve the existing storage account via data source."
  }
}

run "witness_storage_account_greenfield_creates_account" {
  command = plan

  variables {
    witness_storage_account_arm_id = ""
  }

  assert {
    condition     = output.witness_storage_account != ""
    error_message = "Without witness_storage_account_arm_id, sap_landscape must create the witness storage account."
  }
}

run "witness_storage_account_brownfield_reuses_existing" {
  command = plan

  variables {
    witness_storage_account_arm_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-sap-dev/providers/Microsoft.Storage/storageAccounts/sawitness01"
  }

  assert {
    condition     = output.witness_storage_account == "sawitness01"
    error_message = "With witness_storage_account_arm_id supplied, sap_landscape must resolve the witness storage account name from the ARM ID."
  }
}

run "transport_storage_account_greenfield_creates_account" {
  command = plan

  variables {
    create_transport_storage     = true
    NFS_provider                 = "AFS"
    transport_storage_account_id = ""
  }

  assert {
    condition     = module.sap_landscape.storage_account_counts.transport == 1
    error_message = "With create_transport_storage=true, NFS_provider=AFS, and no ARM ID, sap_landscape must create the transport storage account."
  }
}

run "transport_storage_account_brownfield_reuses_existing" {
  command = plan

  variables {
    create_transport_storage     = true
    NFS_provider                 = "AFS"
    transport_storage_account_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-sap-dev/providers/Microsoft.Storage/storageAccounts/satransport01"
  }

  assert {
    condition     = output.transport_storage_account_id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-sap-dev/providers/Microsoft.Storage/storageAccounts/satransport01"
    error_message = "With transport_storage_account_id supplied, sap_landscape must reuse the existing transport storage account."
  }
}

run "install_storage_account_greenfield_creates_account" {
  command = plan

  variables {
    NFS_provider               = "AFS"
    install_storage_account_id = ""
  }

  assert {
    condition     = output.install_path != ""
    error_message = "With NFS_provider=AFS and no install_storage_account_id, sap_landscape must create the install storage account and expose the install path."
  }
}

run "install_storage_account_brownfield_reuses_existing" {
  command = plan

  variables {
    NFS_provider               = "AFS"
    install_storage_account_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-sap-dev/providers/Microsoft.Storage/storageAccounts/sainstall01"
  }

  assert {
    condition     = output.install_path != ""
    error_message = "With install_storage_account_id supplied, sap_landscape must resolve the install storage account and expose the install path."
  }
}

run "anf_existing_pool_reuse_skips_pool_creation" {
  command = plan

  variables {
    NFS_provider              = "ANF"
    ANF_account_arm_id        = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-sap-dev/providers/Microsoft.NetApp/netAppAccounts/anf-dev"
    ANF_use_existing_pool     = true
    ANF_pool_name             = "pool-existing"
    anf_subnet_arm_id         = ""
    anf_subnet_nsg_arm_id     = ""
    anf_subnet_address_prefix = "10.10.18.0/28"
  }

  assert {
    condition     = module.sap_landscape.netapp_resource_counts.pool == 0
    error_message = "With ANF_use_existing_pool=true, sap_landscape must not create a NetApp pool."
  }

  assert {
    condition     = module.sap_landscape.netapp_resource_counts.account == 0
    error_message = "With ANF_account_arm_id supplied, sap_landscape must not create a NetApp account (data source used)."
  }
}

run "anf_transport_volume_reuse_skips_volume_creation" {
  command = plan

  variables {
    NFS_provider                      = "ANF"
    create_transport_storage          = true
    ANF_account_arm_id                = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-sap-dev/providers/Microsoft.NetApp/netAppAccounts/anf-dev"
    ANF_use_existing_pool             = true
    ANF_pool_name                     = "pool-existing"
    ANF_transport_volume_use_existing = true
    ANF_transport_volume_name         = "vol-transport"
    anf_subnet_arm_id                 = ""
    anf_subnet_nsg_arm_id             = ""
    anf_subnet_address_prefix         = "10.10.18.0/28"
  }

  override_data {
    target = module.sap_landscape.data.azurerm_netapp_volume.transport
    values = {
      mount_ip_addresses = ["10.10.18.4"]
      volume_path        = "vol-transport"
    }
  }

  assert {
    condition     = module.sap_landscape.netapp_resource_counts.pool == 0
    error_message = "With ANF_use_existing_pool=true, pool must not be created."
  }

  assert {
    condition     = output.saptransport_path != ""
    error_message = "With ANF transport volume reuse, the transport path must still be exposed via data source lookup."
  }
}

run "anf_install_volume_reuse_skips_volume_creation" {
  command = plan

  variables {
    NFS_provider                    = "ANF"
    ANF_account_arm_id              = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-sap-dev/providers/Microsoft.NetApp/netAppAccounts/anf-dev"
    ANF_use_existing_pool           = true
    ANF_pool_name                   = "pool-existing"
    ANF_install_volume_use_existing = true
    ANF_install_volume_name         = "vol-install"
    anf_subnet_arm_id               = ""
    anf_subnet_nsg_arm_id           = ""
    anf_subnet_address_prefix       = "10.10.18.0/28"
  }

  override_data {
    target = module.sap_landscape.data.azurerm_netapp_volume.install
    values = {
      mount_ip_addresses = ["10.10.18.5"]
      volume_path        = "vol-install"
    }
  }

  assert {
    condition     = output.install_path != ""
    error_message = "With ANF install volume reuse, the install path must still be exposed via data source lookup."
  }

  assert {
    condition     = module.sap_landscape.netapp_resource_counts.account == 0
    error_message = "With ANF_account_arm_id supplied, sap_landscape must not create a NetApp account (data source used)."
  }
}

run "utility_storage_filestorage_forces_premium_tier_and_drops_blobs" {
  command = plan

  variables {
    utility_storage_accounts = [
      {
        name                     = "utilfs01"
        account_kind             = "FileStorage"
        account_tier             = "Standard"
        account_replication_type = "LRS"
        file_shares              = [{ name = "share01", quota = 100, protocol = "NFS" }]
        blob_containers          = [{ name = "should-be-dropped" }]
      },
    ]
  }

  assert {
    condition     = module.sap_landscape.network_resource_counts.utility_storage_account == 1
    error_message = "FileStorage utility account with file_shares must be planned."
  }

  assert {
    condition     = module.sap_landscape.network_resource_counts.utility_container_immutability_policy == 0
    error_message = "FileStorage utility accounts must not plan container immutability policies."
  }
}

run "utility_storage_storagev2_uses_standard_tier_and_keeps_blobs" {
  command = plan

  variables {
    utility_storage_accounts = [
      {
        name                     = "utilsv201"
        account_kind             = "StorageV2"
        account_tier             = "Standard"
        account_replication_type = "LRS"
        file_shares              = []
        blob_containers          = [{ name = "container01" }]
      },
    ]
  }

  assert {
    condition     = module.sap_landscape.network_resource_counts.utility_storage_account == 1
    error_message = "StorageV2 utility account with blob_containers must be planned."
  }

  assert {
    condition     = module.sap_landscape.network_resource_counts.utility_blob_container == 1
    error_message = "StorageV2 utility account with one blob container must plan one container."
  }

  assert {
    condition     = module.sap_landscape.network_resource_counts.utility_container_immutability_policy == 0
    error_message = "A utility blob container without an immutability_policy block must not plan a policy."
  }
}

run "utility_storage_container_immutability_policy_is_optional_and_container_scoped" {
  command = plan

  variables {
    utility_storage_accounts = [
      {
        name                     = "utilsv201"
        account_kind             = "StorageV2"
        account_tier             = "Standard"
        account_replication_type = "LRS"
        file_shares              = []
        blob_containers = [
          {
            name = "unprotected"
          },
          {
            name                = "defaults"
            immutability_policy = {}
          },
          {
            name = "archive"
            immutability_policy = {
              immutability_period_in_days = 90
              locked                      = false
              protected_append_writes     = "append_blobs"
            }
          },
          {
            name = "audit"
            immutability_policy = {
              immutability_period_in_days = 365
              locked                      = true
              allow_irreversible_lock     = true
              protected_append_writes     = "all"
            }
          },
        ]
      },
    ]
  }

  assert {
    condition     = module.sap_landscape.network_resource_counts.utility_blob_container == 4
    error_message = "All four configured utility blob containers must be planned."
  }

  assert {
    condition     = module.sap_landscape.network_resource_counts.utility_container_immutability_policy == 3
    error_message = "Only the three containers with immutability_policy blocks must plan policies."
  }

  assert {
    condition     = module.sap_landscape.utility_container_immutability_policy_settings["utilsv201/defaults"].container_index == 1
    error_message = "The default policy must retain its stable account/container key and source index."
  }

  assert {
    condition     = module.sap_landscape.utility_container_immutability_policy_settings["utilsv201/defaults"].immutability_period_in_days == 30 && !module.sap_landscape.utility_container_immutability_policy_settings["utilsv201/defaults"].locked
    error_message = "An empty policy block must resolve to a 30-day unlocked policy."
  }

  assert {
    condition     = !module.sap_landscape.utility_container_immutability_policy_settings["utilsv201/defaults"].protected_append_writes_enabled && !module.sap_landscape.utility_container_immutability_policy_settings["utilsv201/defaults"].protected_append_writes_all_enabled
    error_message = "An empty policy block must disable both protected append modes."
  }

  assert {
    condition     = module.sap_landscape.utility_container_immutability_policy_settings["utilsv201/archive"].container_index == 2 && module.sap_landscape.utility_container_immutability_policy_settings["utilsv201/archive"].immutability_period_in_days == 90 && !module.sap_landscape.utility_container_immutability_policy_settings["utilsv201/archive"].locked
    error_message = "The archive container must retain its 90-day unlocked immutability settings."
  }

  assert {
    condition     = module.sap_landscape.utility_container_immutability_policy_settings["utilsv201/archive"].protected_append_writes_enabled && !module.sap_landscape.utility_container_immutability_policy_settings["utilsv201/archive"].protected_append_writes_all_enabled
    error_message = "The archive container must enable append-blob writes only."
  }

  assert {
    condition     = module.sap_landscape.utility_container_immutability_policy_settings["utilsv201/audit"].container_index == 3 && module.sap_landscape.utility_container_immutability_policy_settings["utilsv201/audit"].immutability_period_in_days == 365 && module.sap_landscape.utility_container_immutability_policy_settings["utilsv201/audit"].locked
    error_message = "The acknowledged audit policy must retain its 365-day locked settings."
  }

  assert {
    condition     = !module.sap_landscape.utility_container_immutability_policy_settings["utilsv201/audit"].protected_append_writes_enabled && module.sap_landscape.utility_container_immutability_policy_settings["utilsv201/audit"].protected_append_writes_all_enabled
    error_message = "The audit container must enable all protected append writes only."
  }
}

run "register_endpoints_with_dns_enabled_plans_dns_records" {
  command = plan

  variables {
    register_endpoints_with_dns                  = true
    register_storage_accounts_keyvaults_with_dns = true
    register_virtual_network_to_dns              = true
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
    user_keyvault_id                             = ""
    dns_label                                    = "corp.contoso.internal"
  }

  assert {
    condition     = module.sap_landscape.dns_link_counts.vnet_sap == 1
    error_message = "When register_endpoints_with_dns is true, VNet DNS link must be planned."
  }

  assert {
    condition     = module.sap_landscape.dns_link_counts.file == 1
    error_message = "When register_storage_accounts_keyvaults_with_dns is true, file DNS link must be planned."
  }

  assert {
    condition     = module.sap_landscape.dns_link_counts.storage == 1
    error_message = "When register_storage_accounts_keyvaults_with_dns is true, storage DNS link must be planned."
  }

  assert {
    condition     = module.sap_landscape.dns_link_counts.vault == 1
    error_message = "When register_storage_accounts_keyvaults_with_dns is true, vault DNS link must be planned."
  }
}

run "vnet_peering_enabled_with_greenfield_vnet_creates_peering" {
  command = plan

  variables {
    peer_with_control_plane_vnet = true
    network_arm_id               = ""
    admin_subnet_arm_id          = ""
    admin_subnet_nsg_arm_id      = ""
    admin_subnet_address_prefix  = "10.20.0.0/24"
    db_subnet_arm_id             = ""
    db_subnet_nsg_arm_id         = ""
    db_subnet_address_prefix     = "10.20.1.0/24"
    app_subnet_arm_id            = ""
    app_subnet_nsg_arm_id        = ""
    app_subnet_address_prefix    = "10.20.2.0/24"
  }

  assert {
    condition     = module.sap_landscape.network_resource_counts.vnet == 1
    error_message = "Greenfield VNet must be created for peering to be established."
  }

  assert {
    condition     = module.sap_landscape.network_resource_counts.route_table == 1
    error_message = "A greenfield VNet with peering enabled must also create the route table."
  }
}

run "apply_greenfield_diagnostics_storage_resolves_name" {
  command = apply

  variables {
    diagnostics_storage_account_arm_id = ""
    witness_storage_account_arm_id     = ""
  }

  assert {
    condition     = output.storageaccount_name != ""
    error_message = "After apply, greenfield diagnostics storage account name must be a resolved non-empty string."
  }

  assert {
    condition     = output.storageaccount_rg_name != ""
    error_message = "After apply, greenfield diagnostics storage account resource group name must be resolved."
  }

  assert {
    condition     = output.witness_storage_account != ""
    error_message = "After apply, greenfield witness storage account name must be a resolved non-empty string."
  }
}

run "utility_storage_account_version_level_immutability_is_optional" {
  command = plan

  variables {
    utility_storage_accounts = [
      {
        name                     = "utilsv210"
        account_kind             = "StorageV2"
        account_tier             = "Standard"
        account_replication_type = "LRS"
        file_shares              = []
        blob_containers          = [{ name = "container01" }]
      },
    ]
  }

  assert {
    condition     = !module.sap_landscape.utility_account_version_level_immutability_settings["0"].versioning_enabled
    error_message = "A utility account that does not request versioning must not plan blob versioning."
  }

  assert {
    condition     = module.sap_landscape.utility_account_version_level_immutability_settings["0"].state == null
    error_message = "A utility account without version_level_immutability must not plan an account immutability policy."
  }
}

run "utility_storage_account_versioning_can_be_enabled_without_immutability" {
  command = plan

  variables {
    utility_storage_accounts = [
      {
        name                     = "utilsv211"
        account_kind             = "StorageV2"
        account_tier             = "Standard"
        account_replication_type = "LRS"
        versioning_enabled       = true
        file_shares              = []
        blob_containers          = [{ name = "container01" }]
      },
    ]
  }

  assert {
    condition     = module.sap_landscape.utility_account_version_level_immutability_settings["0"].versioning_enabled
    error_message = "Blob versioning must be planned when versioning_enabled is true."
  }

  assert {
    condition     = module.sap_landscape.utility_account_version_level_immutability_settings["0"].state == null
    error_message = "Enabling versioning alone must not plan an account immutability policy."
  }
}

run "utility_storage_account_version_level_immutability_defaults_and_overrides" {
  command = plan

  variables {
    utility_storage_accounts = [
      {
        name                       = "utilsv212"
        account_kind               = "StorageV2"
        account_tier               = "Standard"
        account_replication_type   = "LRS"
        versioning_enabled         = true
        version_level_immutability = {}
        file_shares                = []
        blob_containers            = [{ name = "container01" }]
      },
      {
        name                     = "utilsv213"
        account_kind             = "StorageV2"
        account_tier             = "Standard"
        account_replication_type = "LRS"
        versioning_enabled       = true
        version_level_immutability = {
          immutability_period_in_days   = 90
          state                         = "Unlocked"
          allow_protected_append_writes = true
        }
        file_shares     = []
        blob_containers = [{ name = "container01" }]
      },
    ]
  }

  assert {
    condition     = module.sap_landscape.utility_account_version_level_immutability_settings["0"].immutability_period_in_days == 30 && module.sap_landscape.utility_account_version_level_immutability_settings["0"].state == "Unlocked"
    error_message = "An empty version_level_immutability block must resolve to a 30-day Unlocked policy."
  }

  assert {
    condition     = !module.sap_landscape.utility_account_version_level_immutability_settings["0"].allow_protected_append_writes
    error_message = "An empty version_level_immutability block must not allow protected append writes."
  }

  assert {
    condition     = module.sap_landscape.utility_account_version_level_immutability_settings["1"].immutability_period_in_days == 90 && module.sap_landscape.utility_account_version_level_immutability_settings["1"].allow_protected_append_writes
    error_message = "Per-account version_level_immutability overrides must reach only the matching account."
  }

  assert {
    condition     = module.sap_landscape.utility_account_version_level_immutability_settings["0"].immutability_period_in_days == 30
    error_message = "An override on one utility account must not change the defaults resolved for another."
  }
}

run "utility_storage_filestorage_account_drops_version_level_immutability" {
  command = plan

  variables {
    utility_storage_accounts = [
      {
        name                     = "utilfs10"
        account_kind             = "FileStorage"
        account_tier             = "Standard"
        account_replication_type = "LRS"
        file_shares              = [{ name = "share01", quota = 100, protocol = "NFS" }]
        blob_containers          = []
      },
    ]
  }

  assert {
    condition     = !module.sap_landscape.utility_account_version_level_immutability_settings["0"].versioning_enabled
    error_message = "FileStorage utility accounts must never plan blob versioning."
  }

  assert {
    condition     = module.sap_landscape.utility_account_version_level_immutability_settings["0"].state == null
    error_message = "FileStorage utility accounts must never plan an account immutability policy."
  }
}