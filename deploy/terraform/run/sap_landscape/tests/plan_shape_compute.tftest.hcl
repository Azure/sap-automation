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


run "iscsi_count_zero_skips_vm_resources" {
  command = plan

  assert {
    condition     = module.sap_landscape.iscsi_vm_count == 0
    error_message = "When iscsi_count is zero, sap_landscape must not plan any iSCSI VMs."
  }

  assert {
    condition     = length(output.iSCSI_server_names) == 0
    error_message = "When iscsi_count is zero, iSCSI_server_names output must be an empty list."
  }
}

run "iscsi_count_positive_creates_vms_and_uses_namegenerator_counts" {
  command = plan

  variables {
    iscsi_count   = 2
    iscsi_useDHCP = true
  }

  assert {
    condition     = module.sap_landscape.iscsi_vm_count == 2
    error_message = "When iscsi_count is two, sap_landscape must plan two iSCSI VMs."
  }

  assert {
    condition     = length(output.iSCSI_server_names) == length(module.sap_namegenerator.naming.virtualmachine_names.ISCSI_COMPUTERNAME)
    error_message = "sap_namegenerator's iscsi_server_count wiring must drive the iSCSI server-name cardinality exactly."
  }
}

run "utility_vm_count_drives_windows_vm_names" {
  command = plan

  variables {
    utility_vm_count = 2
  }

  assert {
    condition     = module.sap_landscape.utility_vm_count == 2
    error_message = "utility_vm_count must control the number of planned utility VMs."
  }

  assert {
    condition     = module.sap_landscape.utility_vm_computer_names[0] == module.sap_namegenerator.naming.virtualmachine_names.WORKLOAD_VMNAME[0]
    error_message = "sap_namegenerator's utility_vm_count wiring must drive the planned utility VM computer names."
  }

  assert {
    condition     = alltrue([for zone in module.sap_landscape.utility_vm_zones : zone == null])
    error_message = "Utility VMs must remain non-zonal when utility_vm_zones is not provided."
  }
}

run "utility_vm_zones_distribute_windows_vms" {
  command = plan

  variables {
    utility_vm_count = 3
    utility_vm_zones = ["1", "2"]
  }

  assert {
    condition     = module.sap_landscape.utility_vm_zones == ["1", "2", "1"]
    error_message = "Utility VMs must be distributed round-robin across the configured zones."
  }
}

run "utility_vm_zones_distribute_linux_vms" {
  command = plan

  variables {
    utility_vm_count = 3
    utility_vm_zones = ["1", "2"]
    utility_vm_image = {
      os_type         = "LINUX"
      source_image_id = ""
      publisher       = "Canonical"
      offer           = "ubuntu-24_04-lts"
      sku             = "server"
      version         = "latest"
    }
  }

  assert {
    condition     = module.sap_landscape.utility_vm_zones == ["1", "2", "1"]
    error_message = "Linux utility VMs must be distributed round-robin across the configured zones."
  }
}

run "private_endpoint_enabled_with_keyvault_plans_endpoint" {
  command = plan

  variables {
    use_private_endpoint          = true
    user_keyvault_id              = ""
    network_arm_id                = ""
    admin_subnet_arm_id           = ""
    admin_subnet_nsg_arm_id       = ""
    admin_subnet_address_prefix   = "10.20.0.0/24"
    db_subnet_arm_id              = ""
    db_subnet_nsg_arm_id          = ""
    db_subnet_address_prefix      = "10.20.1.0/24"
    app_subnet_arm_id             = ""
    app_subnet_nsg_arm_id         = ""
    app_subnet_address_prefix     = "10.20.2.0/24"
    storage_subnet_arm_id         = ""
    storage_subnet_nsg_arm_id     = ""
    storage_subnet_address_prefix = "10.20.3.0/24"
  }

  assert {
    condition     = module.sap_landscape.network_resource_counts.keyvault_private_endpoint == 1
    error_message = "When use_private_endpoint=true and no existing key vault is supplied, the key vault private endpoint must be planned."
  }
}

run "private_endpoint_disabled_allows_public_access" {
  command = plan

  variables {
    use_private_endpoint          = false
    public_network_access_enabled = true
  }

  assert {
    condition     = output.public_network_access_enabled == true
    error_message = "When use_private_endpoint=false and public_network_access_enabled=true, public access must remain enabled."
  }
}

run "firewall_enabled_for_keyvaults_and_storage" {
  command = plan

  variables {
    enable_firewall_for_keyvaults_and_storage = true
    user_keyvault_id                          = ""
    network_arm_id                            = ""
    admin_subnet_arm_id                       = ""
    admin_subnet_nsg_arm_id                   = ""
    admin_subnet_address_prefix               = "10.20.0.0/24"
    db_subnet_arm_id                          = ""
    db_subnet_nsg_arm_id                      = ""
    db_subnet_address_prefix                  = "10.20.1.0/24"
    app_subnet_arm_id                         = ""
    app_subnet_nsg_arm_id                     = ""
    app_subnet_address_prefix                 = "10.20.2.0/24"
    storage_subnet_arm_id                     = ""
    storage_subnet_nsg_arm_id                 = ""
    storage_subnet_address_prefix             = "10.20.3.0/24"
  }

  assert {
    condition     = module.sap_landscape.network_resource_counts.keyvault == 1
    error_message = "With firewall enabled and no existing keyvault, the keyvault must be created with network rules."
  }
}

run "iscsi_dhcp_mode_when_no_static_ips_provided" {
  command = plan

  variables {
    iscsi_count   = 2
    iscsi_useDHCP = true
    iscsi_nic_ips = []
  }

  assert {
    condition     = module.sap_landscape.iscsi_vm_count == 2
    error_message = "With iscsi_count=2 and DHCP enabled, two iSCSI VMs must be planned."
  }

  assert {
    condition     = length(output.iSCSI_server_names) == 2
    error_message = "With iscsi_count=2, iSCSI_server_names output must contain exactly 2 entries."
  }
}

run "iscsi_static_ips_override_dhcp_setting" {
  command = plan

  variables {
    iscsi_count   = 2
    iscsi_useDHCP = true
    iscsi_nic_ips = ["10.10.6.4", "10.10.6.5"]
  }

  assert {
    condition     = module.sap_landscape.iscsi_vm_count == 2
    error_message = "With static IPs provided, two iSCSI VMs must still be planned."
  }

  assert {
    condition     = module.sap_landscape.resolved_iscsi_nic_ips == ["10.10.6.4", "10.10.6.5"]
    error_message = "With static IPs provided, the iSCSI NIC IP input list must be preserved."
  }
}

run "ams_instance_creation_enabled_plans_ams_resource" {
  command = plan

  variables {
    create_ams_instance       = true
    ams_subnet_arm_id         = ""
    ams_subnet_address_prefix = "10.10.17.0/24"
    ams_subnet_nsg_arm_id     = ""
  }

  assert {
    condition     = module.sap_landscape.ams_instance_created_count == 1
    error_message = "With create_ams_instance=true, the AMS azapi_resource must be planned."
  }
}

run "ams_instance_creation_disabled_plans_no_ams_resource" {
  command = plan

  variables {
    create_ams_instance = false
  }

  assert {
    condition     = module.sap_landscape.ams_instance_created_count == 0
    error_message = "With create_ams_instance=false, no AMS resource must be planned."
  }

  assert {
    condition     = output.ams_resource_id == ""
    error_message = "With create_ams_instance=false, ams_resource_id output must be empty."
  }
}

run "application_configuration_id_provided_surfaces_in_output" {
  command = plan

  variables {
    application_configuration_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-sap-dev/providers/Microsoft.AppConfiguration/configurationStores/appconfig-dev"
  }

  override_data {
    target = module.sap_landscape.data.azurerm_app_configuration.app_config

    values = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-sap-dev/providers/Microsoft.AppConfiguration/configurationStores/appconfig-dev"
    }
  }

  assert {
    condition     = output.application_configuration_id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-sap-dev/providers/Microsoft.AppConfiguration/configurationStores/appconfig-dev"
    error_message = "When application_configuration_id is provided, it must be surfaced verbatim in the output."
  }
}

run "application_configuration_id_empty_falls_back_to_deployer_state" {
  command = plan

  variables {
    application_configuration_id = ""
  }

  assert {
    condition     = output.application_configuration_id == ""
    error_message = "When application_configuration_id is empty and deployer state has empty value, the output must be empty."
  }
}

run "spn_keyvault_id_provided_reuses_existing_vault" {
  command = plan

  variables {
    spn_keyvault_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-sap-dev/providers/Microsoft.KeyVault/vaults/kv-spn-existing"
  }

  assert {
    condition     = output.spn_kv_id != ""
    error_message = "With spn_keyvault_id supplied, the SPN keyvault ID must be non-empty."
  }

  assert {
    condition     = output.landscape_key_vault_spn_arm_id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-sap-dev/providers/Microsoft.KeyVault/vaults/kv-spn-existing"
    error_message = "With spn_keyvault_id supplied, landscape_key_vault_spn_arm_id must reflect the input value."
  }
}

run "spn_keyvault_id_empty_derives_from_deployer_remote_state" {
  command = plan

  variables {
    spn_keyvault_id = ""
  }

  assert {
    condition     = output.spn_kv_id != ""
    error_message = "Without spn_keyvault_id, the SPN keyvault ID must be derived from the deployer remote state."
  }

  assert {
    condition     = output.spn_kv_id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mgmt/providers/Microsoft.KeyVault/vaults/kv-deployer"
    error_message = "Without spn_keyvault_id, sap_landscape must fall back to deployer_kv_user_arm_id from the deployer remote state."
  }
}

run "no_custom_naming_override_uses_namegenerator_for_iscsi" {
  command = plan

  variables {
    iscsi_count        = 1
    iscsi_useDHCP      = true
    name_override_file = ""
  }

  assert {
    condition     = length(output.iSCSI_server_names) == 1
    error_message = "With empty name_override_file and iscsi_count=1, sap_namegenerator must drive the iSCSI server name."
  }

  assert {
    condition     = output.iSCSI_server_names[0] == module.sap_namegenerator.naming.virtualmachine_names.ISCSI_COMPUTERNAME[0]
    error_message = "With empty name_override_file, iSCSI server names must come from sap_namegenerator."
  }
}
