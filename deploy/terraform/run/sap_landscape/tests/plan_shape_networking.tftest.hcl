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


run "workload_zone_prefix_matches_namegenerator" {
  command = plan

  assert {
    condition     = output.workload_zone_prefix == module.sap_namegenerator.naming.prefix.WORKLOAD_ZONE
    error_message = "run/sap_landscape must surface the same workload-zone prefix that sap_namegenerator computed."
  }
}

run "greenfield_vnet_creates_network_and_propagates_tags" {
  command = plan

  variables {
    network_arm_id                = ""
    admin_subnet_arm_id           = ""
    admin_subnet_nsg_arm_id       = ""
    admin_subnet_address_prefix   = "10.10.0.0/24"
    db_subnet_arm_id              = ""
    db_subnet_nsg_arm_id          = ""
    db_subnet_address_prefix      = "10.10.1.0/24"
    app_subnet_arm_id             = ""
    app_subnet_nsg_arm_id         = ""
    app_subnet_address_prefix     = "10.10.2.0/24"
    web_subnet_arm_id             = ""
    web_subnet_nsg_arm_id         = ""
    web_subnet_address_prefix     = "10.10.3.0/24"
    storage_subnet_arm_id         = ""
    storage_subnet_nsg_arm_id     = ""
    storage_subnet_address_prefix = "10.10.4.0/24"
  }

  assert {
    condition     = module.sap_landscape.network_resource_counts.vnet == 1
    error_message = "Without network_arm_id, sap_landscape must create the workload VNet."
  }

  assert {
    condition     = module.sap_landscape.network_resource_counts.route_table == 1
    error_message = "A greenfield VNet should also create the route table when NAT gateway deployment is disabled."
  }

  assert {
    condition     = module.sap_landscape.vnet_tags["Role"] == "workload-zone"
    error_message = "Input tags must propagate to the created workload VNet."
  }
}

run "brownfield_vnet_reuses_existing_network" {
  command = plan

  assert {
    condition     = module.sap_landscape.network_resource_counts.vnet == 0
    error_message = "With network_arm_id supplied, sap_landscape must reuse the existing VNet instead of creating a new one."
  }

  assert {
    condition     = output.vnet_sap_arm_id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-sap-dev/providers/Microsoft.Network/virtualNetworks/vnet-sap01"
    error_message = "With network_arm_id supplied, sap_landscape must resolve the existing VNet through a data source."
  }
}

run "greenfield_keyvault_creates_named_vault" {
  command = plan

  variables {
    user_keyvault_id = ""
  }

  assert {
    condition     = module.sap_landscape.network_resource_counts.keyvault == 1
    error_message = "Without user_keyvault_id, sap_landscape must create the workload-zone user Key Vault."
  }
}

run "brownfield_keyvault_reuses_existing_vault" {
  command = plan

  assert {
    condition     = module.sap_landscape.network_resource_counts.keyvault == 0
    error_message = "With user_keyvault_id supplied, sap_landscape must reuse the existing Key Vault instead of creating a new one."
  }

  assert {
    condition     = output.landscape_key_vault_user_arm_id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-sap-dev/providers/Microsoft.KeyVault/vaults/kv-sap-user"
    error_message = "With user_keyvault_id supplied, sap_landscape must resolve the existing Key Vault through a data source."
  }
}

run "greenfield_admin_subnet_creates_resources" {
  command = plan

  variables {
    admin_subnet_arm_id         = ""
    admin_subnet_address_prefix = "10.10.10.0/24"
    admin_subnet_nsg_arm_id     = ""
  }

  assert {
    condition     = module.sap_landscape.network_resource_counts.admin_subnet == 1
    error_message = "Without admin_subnet_arm_id and with admin_subnet_address_prefix supplied, sap_landscape must create the admin subnet."
  }
  assert {
    condition     = module.sap_landscape.network_resource_counts.admin_nsg == 1
    error_message = "The greenfield admin subnet must be paired with a module-created NSG."
  }
}

run "brownfield_admin_subnet_reuses_existing_resources" {
  command = plan
  assert {
    condition     = module.sap_landscape.network_resource_counts.admin_subnet == 0
    error_message = "With admin_subnet_arm_id supplied by the fixture, sap_landscape must reuse the existing admin subnet instead of creating one."
  }
  assert {
    condition     = module.sap_landscape.network_resource_counts.admin_nsg == 0
    error_message = "With admin_subnet_nsg_arm_id supplied by the fixture, sap_landscape must not create a new admin NSG."
  }
}

run "greenfield_db_subnet_creates_resources" {
  command = plan

  variables {
    db_subnet_arm_id         = ""
    db_subnet_address_prefix = "10.10.11.0/24"
    db_subnet_nsg_arm_id     = ""
  }

  assert {
    condition     = module.sap_landscape.network_resource_counts.db_subnet == 1
    error_message = "Without db_subnet_arm_id and with db_subnet_address_prefix supplied, sap_landscape must create the db subnet."
  }
  assert {
    condition     = module.sap_landscape.network_resource_counts.db_nsg == 1
    error_message = "The greenfield db subnet must be paired with a module-created NSG."
  }
}

run "brownfield_db_subnet_reuses_existing_resources" {
  command = plan
  assert {
    condition     = module.sap_landscape.network_resource_counts.db_subnet == 0
    error_message = "With db_subnet_arm_id supplied by the fixture, sap_landscape must reuse the existing db subnet instead of creating one."
  }
  assert {
    condition     = module.sap_landscape.network_resource_counts.db_nsg == 0
    error_message = "With db_subnet_nsg_arm_id supplied by the fixture, sap_landscape must not create a new db NSG."
  }
}

run "greenfield_app_subnet_creates_resources" {
  command = plan

  variables {
    app_subnet_arm_id         = ""
    app_subnet_address_prefix = "10.10.12.0/24"
    app_subnet_nsg_arm_id     = ""
  }

  assert {
    condition     = module.sap_landscape.network_resource_counts.app_subnet == 1
    error_message = "Without app_subnet_arm_id and with app_subnet_address_prefix supplied, sap_landscape must create the app subnet."
  }
  assert {
    condition     = module.sap_landscape.network_resource_counts.app_nsg == 1
    error_message = "The greenfield app subnet must be paired with a module-created NSG."
  }
}

run "brownfield_app_subnet_reuses_existing_resources" {
  command = plan
  assert {
    condition     = module.sap_landscape.network_resource_counts.app_subnet == 0
    error_message = "With app_subnet_arm_id supplied by the fixture, sap_landscape must reuse the existing app subnet instead of creating one."
  }
  assert {
    condition     = module.sap_landscape.network_resource_counts.app_nsg == 0
    error_message = "With app_subnet_nsg_arm_id supplied by the fixture, sap_landscape must not create a new app NSG."
  }
}

run "greenfield_web_subnet_creates_resources" {
  command = plan

  variables {
    web_subnet_arm_id         = ""
    web_subnet_address_prefix = "10.10.13.0/24"
    web_subnet_nsg_arm_id     = ""
  }

  assert {
    condition     = module.sap_landscape.network_resource_counts.web_subnet == 1
    error_message = "Without web_subnet_arm_id and with web_subnet_address_prefix supplied, sap_landscape must create the web subnet."
  }
  assert {
    condition     = module.sap_landscape.network_resource_counts.web_nsg == 1
    error_message = "The greenfield web subnet must be paired with a module-created NSG."
  }
}

run "brownfield_web_subnet_reuses_existing_resources" {
  command = plan
  assert {
    condition     = module.sap_landscape.network_resource_counts.web_subnet == 0
    error_message = "With web_subnet_arm_id supplied by the fixture, sap_landscape must reuse the existing web subnet instead of creating one."
  }
  assert {
    condition     = module.sap_landscape.network_resource_counts.web_nsg == 0
    error_message = "With web_subnet_nsg_arm_id supplied by the fixture, sap_landscape must not create a new web NSG."
  }
}

run "greenfield_storage_subnet_creates_resources" {
  command = plan

  variables {
    storage_subnet_arm_id         = ""
    storage_subnet_address_prefix = "10.10.14.0/24"
    storage_subnet_nsg_arm_id     = ""
  }

  assert {
    condition     = module.sap_landscape.network_resource_counts.storage_subnet == 1
    error_message = "Without storage_subnet_arm_id and with storage_subnet_address_prefix supplied, sap_landscape must create the storage subnet."
  }
  assert {
    condition     = module.sap_landscape.network_resource_counts.storage_nsg == 1
    error_message = "The greenfield storage subnet must be paired with a module-created NSG."
  }
}

run "brownfield_storage_subnet_reuses_existing_resources" {
  command = plan
  assert {
    condition     = module.sap_landscape.network_resource_counts.storage_subnet == 0
    error_message = "With storage_subnet_arm_id supplied by the fixture, sap_landscape must reuse the existing storage subnet instead of creating one."
  }
  assert {
    condition     = module.sap_landscape.network_resource_counts.storage_nsg == 0
    error_message = "With storage_subnet_nsg_arm_id supplied by the fixture, sap_landscape must not create a new storage NSG."
  }
}

run "greenfield_anf_subnet_creates_resources" {
  command = plan

  variables {
    NFS_provider              = "ANF"
    anf_subnet_arm_id         = ""
    anf_subnet_address_prefix = "10.10.15.0/28"
    anf_subnet_nsg_arm_id     = ""
  }

  assert {
    condition     = module.sap_landscape.network_resource_counts.anf_subnet == 1
    error_message = "Without anf_subnet_arm_id and with anf_subnet_address_prefix supplied, sap_landscape must create the anf subnet."
  }
  assert {
    condition     = module.sap_landscape.network_resource_counts.anf_nsg == 1
    error_message = "The greenfield anf subnet must be paired with a module-created NSG."
  }
}

run "brownfield_anf_subnet_reuses_existing_resources" {
  command = plan
  variables {
    NFS_provider = "ANF"
  }

  assert {
    condition     = module.sap_landscape.network_resource_counts.anf_subnet == 0
    error_message = "With anf_subnet_arm_id supplied by the fixture, sap_landscape must reuse the existing anf subnet instead of creating one."
  }
  assert {
    condition     = module.sap_landscape.network_resource_counts.anf_nsg == 0
    error_message = "With anf_subnet_nsg_arm_id supplied by the fixture, sap_landscape must not create a new anf NSG."
  }
}

run "greenfield_iscsi_subnet_creates_resources" {
  command = plan

  variables {
    iscsi_subnet_arm_id         = ""
    iscsi_subnet_address_prefix = "10.10.16.0/24"
    iscsi_subnet_nsg_arm_id     = ""
  }

  assert {
    condition     = module.sap_landscape.network_resource_counts.iscsi_subnet == 1
    error_message = "Without iscsi_subnet_arm_id and with iscsi_subnet_address_prefix supplied, sap_landscape must create the iscsi subnet."
  }
  assert {
    condition     = module.sap_landscape.network_resource_counts.iscsi_nsg == 1
    error_message = "The greenfield iscsi subnet must be paired with a module-created NSG."
  }
}

run "brownfield_iscsi_subnet_reuses_existing_resources" {
  command = plan
  assert {
    condition     = module.sap_landscape.network_resource_counts.iscsi_subnet == 0
    error_message = "With iscsi_subnet_arm_id supplied by the fixture, sap_landscape must reuse the existing iscsi subnet instead of creating one."
  }
  assert {
    condition     = module.sap_landscape.network_resource_counts.iscsi_nsg == 0
    error_message = "With iscsi_subnet_nsg_arm_id supplied by the fixture, sap_landscape must not create a new iscsi NSG."
  }
}

run "greenfield_ams_subnet_creates_resources" {
  command = plan

  variables {
    create_ams_instance       = true
    ams_subnet_arm_id         = ""
    ams_subnet_address_prefix = "10.10.17.0/24"
    ams_subnet_nsg_arm_id     = ""
  }

  assert {
    condition     = module.sap_landscape.network_resource_counts.ams_subnet == 1
    error_message = "Without ams_subnet_arm_id and with ams_subnet_address_prefix supplied, sap_landscape must create the ams subnet."
  }
  assert {
    condition     = module.sap_landscape.ams_instance_created_count == 1
    error_message = "When create_ams_instance is true and the AMS subnet is defined greenfield, sap_landscape must plan the AMS azapi_resource."
  }
}

run "brownfield_ams_subnet_reuses_existing_resources" {
  command = plan
  variables {
    create_ams_instance = true
  }

  assert {
    condition     = module.sap_landscape.network_resource_counts.ams_subnet == 0
    error_message = "With ams_subnet_arm_id supplied by the fixture, sap_landscape must reuse the existing ams subnet instead of creating one."
  }
  assert {
    condition     = output.ams_subnet_id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-sap-dev/providers/Microsoft.Network/virtualNetworks/vnet-sap01/subnets/ams"
    error_message = "With ams_subnet_arm_id supplied, sap_landscape must resolve the existing AMS subnet through a data source."
  }
}

run "dns_registration_disabled_plans_no_dns_links" {
  command = plan

  assert {
    condition     = module.sap_landscape.dns_link_counts.vnet_sap == 0 && module.sap_landscape.dns_link_counts.file == 0 && module.sap_landscape.dns_link_counts.storage == 0 && module.sap_landscape.dns_link_counts.vault == 0
    error_message = "With DNS registration disabled in the shared fixture, sap_landscape must not plan any private DNS VNet links."
  }
}

run "dns_registration_enabled_plans_all_dns_links" {
  command = plan

  variables {
    network_arm_id                  = ""
    admin_subnet_arm_id             = ""
    admin_subnet_nsg_arm_id         = ""
    admin_subnet_address_prefix     = "10.20.0.0/24"
    db_subnet_arm_id                = ""
    db_subnet_nsg_arm_id            = ""
    db_subnet_address_prefix        = "10.20.1.0/24"
    app_subnet_arm_id               = ""
    app_subnet_nsg_arm_id           = ""
    app_subnet_address_prefix       = "10.20.2.0/24"
    storage_subnet_arm_id           = ""
    storage_subnet_nsg_arm_id       = ""
    storage_subnet_address_prefix   = "10.20.3.0/24"
    user_keyvault_id                = ""
    dns_label                       = "corp.contoso.internal"
    register_virtual_network_to_dns = true
  }

  assert {
    condition     = module.sap_landscape.dns_link_counts.vnet_sap == 1
    error_message = "When Azure-native DNS registration is enabled, sap_landscape must plan the workload-zone VNet link."
  }

  assert {
    condition     = module.sap_landscape.dns_link_counts.file == 1 && module.sap_landscape.dns_link_counts.storage == 1 && module.sap_landscape.dns_link_counts.vault == 1
    error_message = "When Azure-native DNS registration is enabled, sap_landscape must plan the file/blob/vault Private DNS VNet links together."
  }
}

run "nat_gateway_deployment_enabled_creates_nat_resources" {
  command = plan

  variables {
    deploy_nat_gateway          = true
    network_arm_id              = ""
    admin_subnet_arm_id         = ""
    admin_subnet_nsg_arm_id     = ""
    admin_subnet_address_prefix = "10.20.0.0/24"
    db_subnet_arm_id            = ""
    db_subnet_nsg_arm_id        = ""
    db_subnet_address_prefix    = "10.20.1.0/24"
    app_subnet_arm_id           = ""
    app_subnet_nsg_arm_id       = ""
    app_subnet_address_prefix   = "10.20.2.0/24"
  }

  assert {
    condition     = module.sap_landscape.network_resource_counts.nat_gateway == 1
    error_message = "With deploy_nat_gateway=true, sap_landscape must create a NAT gateway."
  }

  assert {
    condition     = module.sap_landscape.network_resource_counts.vnet == 1
    error_message = "With deploy_nat_gateway=true and no network_arm_id, sap_landscape must create the workload VNet."
  }
}

run "nat_gateway_deployment_disabled_creates_no_nat_resources" {
  command = plan

  variables {
    deploy_nat_gateway = false
  }

  assert {
    condition     = output.ng_resource_id == ""
    error_message = "With deploy_nat_gateway=false, sap_landscape must not create a NAT gateway."
  }
}
