# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.
#
# Tests for hosts-file content (ansible_inventory.tmpl), sap-parameters content
# (sap-parameters.tmpl), and cross-subscription local variable resolution.
#
# Zero real Azure/Azure AD API calls: every azurerm/azuread interaction below is
# satisfied by mock_provider, and the only external data lookups (terraform_remote_state)
# are satisfied via override_data so no network access is required.

mock_provider "azurerm" {
  mock_resource "azurerm_resource_group" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mock-sap-system"
    }
  }
  mock_resource "azurerm_storage_account" {
    defaults = {
      id   = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mock-sap-system/providers/Microsoft.Storage/storageAccounts/stmock"
      name = "stmock"
    }
  }
  mock_resource "azurerm_lb" {
    defaults = {
      id   = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mock-sap-system/providers/Microsoft.Network/loadBalancers/lb-mock"
      name = "lb-mock"
    }
  }
  mock_resource "azurerm_lb_backend_address_pool" {
    defaults = {
      id   = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mock-sap-system/providers/Microsoft.Network/loadBalancers/lb-mock/backendAddressPools/be-mock"
      name = "be-mock"
    }
  }
  mock_resource "azurerm_network_interface" {
    defaults = {
      id                   = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mock-sap-system/providers/Microsoft.Network/networkInterfaces/nic-mock"
      name                 = "nic-mock"
      private_ip_addresses = ["10.1.1.4"]
    }
  }
  mock_resource "azurerm_application_security_group" {
    defaults = {
      id   = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mock-sap-system/providers/Microsoft.Network/applicationSecurityGroups/asg-mock"
      name = "asg-mock"
    }
  }
  mock_resource "azurerm_availability_set" {
    defaults = {
      id   = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mock-sap-system/providers/Microsoft.Compute/availabilitySets/avset-mock"
      name = "avset-mock"
    }
  }
  mock_resource "azurerm_managed_disk" {
    defaults = {
      id   = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mock-sap-system/providers/Microsoft.Compute/disks/disk-mock"
      name = "disk-mock"
    }
  }
  mock_resource "azurerm_linux_virtual_machine" {
    defaults = {
      id   = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mock-sap-system/providers/Microsoft.Compute/virtualMachines/vm-linux-mock"
      name = "vm-linux-mock"
    }
  }
  mock_resource "azurerm_windows_virtual_machine" {
    defaults = {
      id   = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mock-sap-system/providers/Microsoft.Compute/virtualMachines/vm-windows-mock"
      name = "vm-windows-mock"
    }
  }
}
mock_provider "azurerm" {
  alias           = "deployer"
}
mock_provider "azurerm" {
  alias           = "system"
  mock_resource "azurerm_resource_group" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mock-sap-system"
    }
  }
  mock_resource "azurerm_storage_account" {
    defaults = {
      id   = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mock-sap-system/providers/Microsoft.Storage/storageAccounts/stmock"
      name = "stmock"
    }
  }
  mock_resource "azurerm_lb" {
    defaults = {
      id   = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mock-sap-system/providers/Microsoft.Network/loadBalancers/lb-mock"
      name = "lb-mock"
    }
  }
  mock_resource "azurerm_lb_backend_address_pool" {
    defaults = {
      id   = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mock-sap-system/providers/Microsoft.Network/loadBalancers/lb-mock/backendAddressPools/be-mock"
      name = "be-mock"
    }
  }
  mock_resource "azurerm_network_interface" {
    defaults = {
      id                   = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mock-sap-system/providers/Microsoft.Network/networkInterfaces/nic-mock"
      name                 = "nic-mock"
      private_ip_addresses = ["10.1.1.4"]
    }
  }
  mock_resource "azurerm_application_security_group" {
    defaults = {
      id   = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mock-sap-system/providers/Microsoft.Network/applicationSecurityGroups/asg-mock"
      name = "asg-mock"
    }
  }
  mock_resource "azurerm_availability_set" {
    defaults = {
      id   = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mock-sap-system/providers/Microsoft.Compute/availabilitySets/avset-mock"
      name = "avset-mock"
    }
  }
  mock_resource "azurerm_managed_disk" {
    defaults = {
      id   = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mock-sap-system/providers/Microsoft.Compute/disks/disk-mock"
      name = "disk-mock"
    }
  }
  mock_resource "azurerm_linux_virtual_machine" {
    defaults = {
      id   = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mock-sap-system/providers/Microsoft.Compute/virtualMachines/vm-linux-mock"
      name = "vm-linux-mock"
    }
  }
  mock_resource "azurerm_windows_virtual_machine" {
    defaults = {
      id   = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mock-sap-system/providers/Microsoft.Compute/virtualMachines/vm-windows-mock"
      name = "vm-windows-mock"
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

override_data {
  target = data.azurerm_client_config.current
  values = {
    subscription_id = "00000000-0000-0000-0000-000000000000"
    tenant_id       = "00000000-0000-0000-0000-000000000000"
    client_id       = "00000000-0000-0000-0000-000000000000"
    object_id       = "00000000-0000-0000-0000-000000000000"
  }
}

variables {
  environment           = "DEV"
  location              = "westeurope"
  network_logical_name  = "SAP01"
  sid                   = "ABC"
  tfstate_resource_id   = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-tfstate/providers/Microsoft.Storage/storageAccounts/tfstatesa"
  landscape_tfstate_key = "LAND-WEEU-SAP01-INFRASTRUCTURE.terraform.tfstate"
  subscription_id       = "00000000-0000-0000-0000-000000000000"

  spn_keyvault_id  = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-kv/providers/Microsoft.KeyVault/vaults/kv-spn"
  user_keyvault_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-kv/providers/Microsoft.KeyVault/vaults/kv-user"

  database_platform  = "HANA"
  database_size      = "Default"
  database_use_avset = true
  database_use_ppg   = false
  database_vm_image = {
    os_type         = "LINUX"
    source_image_id = null
    publisher       = "SUSE"
    offer           = "sles-sap-15-sp5"
    sku             = "gen2"
    version         = "latest"
    type            = "marketplace"
  }

  scs_server_use_avset         = true
  scs_server_use_ppg           = false
  application_server_use_avset = true
  application_server_use_ppg   = false

  application_server_count   = 1
  scs_server_count           = 1
  webdispatcher_server_count = 0
  database_server_count      = 1
  database_high_availability = false

  tags = {
    Environment = "DEV"
    Workload    = "sap-system"
  }
}

override_data {
  target = data.terraform_remote_state.landscape
  values = {
    outputs = {
      automation_version            = "5.0.0"
      control_plane_name            = "DEV-WEEU-DEP01"
      controlplane_environment      = "DEV"
      workload_zone_name            = "DEV-WEEU-SAP01"
      workload_zone_prefix          = "DEV-WEEU-SAP01"
      workloadzone_kv_name          = "kv-user"
      random_id                     = "abc"
      use_spn                       = true
      public_network_access_enabled = true

      created_resource_group_id              = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-landscape"
      created_resource_group_name            = "rg-landscape"
      created_resource_group_subscription_id = "00000000-0000-0000-0000-000000000000"

      vnet_sap_arm_id             = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-landscape/providers/Microsoft.Network/virtualNetworks/vnet-sap01"
      admin_subnet_id             = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-landscape/providers/Microsoft.Network/virtualNetworks/vnet-sap01/subnets/admin"
      admin_nsg_id                = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-landscape/providers/Microsoft.Network/networkSecurityGroups/nsg-admin"
      db_subnet_id                = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-landscape/providers/Microsoft.Network/virtualNetworks/vnet-sap01/subnets/db"
      db_nsg_id                   = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-landscape/providers/Microsoft.Network/networkSecurityGroups/nsg-db"
      app_subnet_id               = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-landscape/providers/Microsoft.Network/virtualNetworks/vnet-sap01/subnets/app"
      app_nsg_id                  = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-landscape/providers/Microsoft.Network/networkSecurityGroups/nsg-app"
      web_subnet_id               = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-landscape/providers/Microsoft.Network/virtualNetworks/vnet-sap01/subnets/web"
      web_nsg_id                  = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-landscape/providers/Microsoft.Network/networkSecurityGroups/nsg-web"
      storage_subnet_id           = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-landscape/providers/Microsoft.Network/virtualNetworks/vnet-sap01/subnets/storage"
      storage_nsg_id              = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-landscape/providers/Microsoft.Network/networkSecurityGroups/nsg-storage"
      ams_subnet_id               = ""
      route_table_id              = ""
      subnet_mgmt_id              = ""
      use_separate_storage_subnet = true

      landscape_key_vault_private_arm_id = ""
      landscape_key_vault_spn_arm_id     = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-landscape/providers/Microsoft.KeyVault/vaults/kv-landscape-spn"
      landscape_key_vault_user_arm_id    = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-landscape/providers/Microsoft.KeyVault/vaults/kv-user"
      user_credential_vault_id           = ""
      spn_credential_vault_id            = ""
      spn_kv_id                          = ""
      sid_password_secret_name           = "sid-password"
      sid_public_key_secret_name         = "sid-public-key"
      sid_username_secret_name           = "sid-username"

      iscsi_authentication_username = ""
      iscsi_authentication_type     = ""
      iscsi_private_ip              = []
      iSCSI_server_ips              = []
      iSCSI_server_names            = []
      iSCSI_servers                 = []

      dns_info_iscsi                               = []
      dns_label                                    = ""
      dns_resource_group_name                      = "rg-landscape"
      management_dns_resourcegroup_name            = ""
      management_dns_subscription_id               = ""
      privatelink_dns_resourcegroup_name           = ""
      privatelink_dns_subscription_id              = ""
      privatelink_file_id                          = ""
      register_virtual_network_to_dns              = false
      register_storage_accounts_keyvaults_with_dns = false
      use_custom_dns_a_registration                = false

      storageaccount_name           = "stlandscapediag"
      storageaccount_rg_name        = "rg-landscape"
      transport_storage_account_id  = ""
      witness_storage_account       = ""
      witness_storage_account_key   = ""
      utility_storage_account_ids   = []
      utility_storage_account_names = []

      ANF_pool_settings = {}
      install_path      = ""
      saptransport_path = ""

      application_configuration_id   = ""
      application_configuration_name = ""

      ams_resource_id = ""
    }
  }
}

override_data {
  target = module.common_infrastructure.data.azurerm_subnet.admin
  values = {
    id               = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-landscape/providers/Microsoft.Network/virtualNetworks/vnet-sap01/subnets/admin"
    address_prefixes = ["10.1.0.0/24"]
  }
}

override_data {
  target = module.common_infrastructure.data.azurerm_subnet.db
  values = {
    id               = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-landscape/providers/Microsoft.Network/virtualNetworks/vnet-sap01/subnets/db"
    address_prefixes = ["10.1.1.0/24"]
  }
}

override_data {
  target = module.hdb_node.data.azurerm_subnet.storage
  values = {
    id               = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-landscape/providers/Microsoft.Network/virtualNetworks/vnet-sap01/subnets/storage"
    address_prefixes = ["10.1.2.0/24"]
  }
}

override_data {
  target = module.hdb_node.data.azurerm_subnet.ANF
  values = {
    id               = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-landscape/providers/Microsoft.Network/virtualNetworks/vnet-sap01/subnets/anf"
    address_prefixes = ["10.1.3.0/24"]
  }
}

override_data {
  target = module.common_infrastructure.data.azurerm_subnet.storage
  values = {
    id               = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-landscape/providers/Microsoft.Network/virtualNetworks/vnet-sap01/subnets/storage"
    address_prefixes = ["10.1.2.0/24"]
  }
}

override_data {
  target = module.common_infrastructure.data.azurerm_key_vault.sid_keyvault_user
  values = {
    id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-kv/providers/Microsoft.KeyVault/vaults/kv-user"
  }
}

override_data {
  target = module.common_infrastructure.data.azurerm_key_vault_secret.sid_pk
  values = {
    value = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCU51GUHdJHlxNoZrvt4bYCSX20Umzij0faob4Ud13/JG6tHbCjgUUVNgmYbAfEHJT0/Vox72Wo4OezrdDdnwhMY+RmRGkcUZq1HE/x5g7yJpPvzCmrvxv25f4w3Er2B6tPeOSStA+eA42vmVbJh20hXveqmA7SsybuYRRd1SZh1VfuWNdfHIAYZQarA169XELRWR0XO8bylT17HLNNWSYiOcOzGEHftMJ7CWlpxU54n9X6hIZ8fmDrLoFBaCb8SIM7VC3dGpRA8g6HJke/ge+MdEkQtSszo0IxcAxeNRGdyIMG/4Ns/mnveudk+7IwoVvuNwn4M1SY9ApGu8RK05Jl diagnostic-only"
  }
}

override_data {
  target = module.common_infrastructure.data.azurerm_key_vault_secret.sid_password
  values = {
    value = "P@ssw0rd-diagnostic-only!"
  }
}

override_data {
  target = module.app_tier.data.azurerm_subnet.subnet_sap_app
  values = {
    id               = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-landscape/providers/Microsoft.Network/virtualNetworks/vnet-sap01/subnets/app"
    address_prefixes = ["10.10.2.0/24"]
  }
}


run "hosts_default_topology_content" {
  command = apply

  assert {
    condition     = strcontains(output.hosts_file_content, "ABC_DB:")
    error_message = "The default hosts file must contain the SID-prefixed DB group header."
  }

  assert {
    condition     = strcontains(output.hosts_file_content, "node_tier             : hana")
    error_message = "When database_platform=HANA, the hosts file DB group must contain 'node_tier : hana' (from the platform variable mapped to lower(var.platform))."
  }

  assert {
    condition     = !strcontains(output.hosts_file_content, "ansible_connection  : winrm")
    error_message = "When database_platform=HANA (Linux), the hosts file must NOT contain WinRM connection settings (mutually exclusive with ssh)."
  }

  assert {
    condition     = strcontains(output.hosts_file_content, "ansible_connection  : ssh")
    error_message = "When database_platform=HANA, the hosts file DB group must use 'ansible_connection : ssh'."
  }

  assert {
    condition     = !strcontains(output.hosts_file_content, "ansible_winrm_transport")
    error_message = "When database_platform=HANA, the hosts file must NOT contain WinRM transport settings."
  }

  assert {
    condition     = !strcontains(output.hosts_file_content, "virtual_host        : v")
    error_message = "When use_secondary_ips is false (default), the hosts file must NOT contain virtual_host entries with 'v' prefix (SECONDARY_DNSNAME)."
  }

  assert {
    condition     = !strcontains(output.hosts_file_content, "      site")
    error_message = "When scale_out=false (default), the hosts file DB group must NOT contain a 'site' field."
  }

  assert {
    condition     = strcontains(output.hosts_file_content, "supported_tiers       : [hana]")
    error_message = "When app tier servers exist, the DB group's supported_tiers must be narrow (just the platform name)."
  }

  assert {
    condition     = strcontains(output.hosts_file_content, "ABC_PAS:")
    error_message = "When application_server_count >= 1, the hosts file must contain the PAS group header."
  }

  assert {
    condition     = !strcontains(output.hosts_file_content, "node_tier             : hana-multi-sid")
    error_message = "When shared_home=false, node_tier must NOT contain 'multi-sid'."
  }

  assert {
    condition     = strcontains(output.hosts_file_content, "use_nvme_disks      : false")
    error_message = "With default (SCSI) disk controller, the hosts file must contain 'use_nvme_disks : false'."
  }
}

run "hosts_anydb_platform_uses_anydb_hostnames" {
  command = apply

  variables {
    database_platform = "ORACLE"
    database_sid      = "ORA"
    database_size     = "512"
    database_vm_zones = ["1"]
  }

  assert {
    condition     = strcontains(output.hosts_file_content, "node_tier             : oracle")
    error_message = "When database_platform=ORACLE, the hosts file DB group must contain 'node_tier : oracle' (from lower(var.platform))."
  }

  assert {
    condition     = !strcontains(output.hosts_file_content, "node_tier             : hana")
    error_message = "When database_platform=ORACLE, the hosts file must NOT contain 'node_tier : hana' (mutually exclusive platform)."
  }
}

run "hosts_use_secondary_ips_true_injects_v_prefix" {
  command = apply

  variables {
    use_secondary_ips = true
  }

  assert {
    condition     = strcontains(output.hosts_file_content, "virtual_host        : v")
    error_message = "When use_secondary_ips=true, the hosts file must contain virtual_host entries with 'v' prefix (from SECONDARY_DNSNAME naming)."
  }

  assert {
    condition     = strcontains(output.hosts_file_content, "ansible_connection  : ssh")
    error_message = "When use_secondary_ips=true with HANA platform, the hosts file must still contain 'ansible_connection : ssh' (confirming the full template rendered)."
  }
}

run "hosts_sqlserver_platform_uses_winrm_connection" {
  command = apply

  variables {
    database_platform = "SQLSERVER"
    database_sid      = "SQL"
  }

  assert {
    condition     = strcontains(output.hosts_file_content, "ansible_connection  : winrm")
    error_message = "When database_platform=SQLSERVER, the hosts file DB group must use 'ansible_connection : winrm'."
  }

  assert {
    condition     = strcontains(output.hosts_file_content, "ansible_winrm_server_cert_validation : ignore")
    error_message = "When database_platform=SQLSERVER, the hosts file must contain the WinRM cert validation setting."
  }

  assert {
    condition     = strcontains(output.hosts_file_content, "ansible_winrm_transport              : credssp")
    error_message = "When database_platform=SQLSERVER, the hosts file must contain the WinRM transport setting."
  }
}

run "hosts_scale_out_injects_site_field" {
  command = apply

  variables {
    database_HANA_use_scaleout_scenario = true
    database_high_availability          = true
    database_server_count               = 2
    database_vm_zones                   = ["1", "2"]
    NFS_provider                        = "AFS"
  }

  assert {
    condition     = strcontains(output.hosts_file_content, "site")
    error_message = "When scale_out=true (database_HANA_use_scaleout_scenario), the hosts file DB group must contain a 'site' field for each node."
  }
}

run "hosts_observer_group_populated_with_scale_out_ha" {
  command = apply

  variables {
    database_HANA_use_scaleout_scenario = true
    database_high_availability          = true
    database_server_count               = 1
    database_vm_zones                   = ["1", "2"]
    NFS_provider                        = "AFS"
    use_observer                        = true
  }

  assert {
    condition     = strcontains(output.hosts_file_content, "ABC_OBSERVER_DB:")
    error_message = "The hosts file must contain the observer group header (ABC_OBSERVER_DB:) which is always rendered regardless of observer_ips population."
  }
}

run "hosts_single_server_broadened_db_tiers" {
  command = apply

  variables {
    application_server_count   = 0
    scs_server_count           = 0
    webdispatcher_server_count = 0
    database_server_count      = 1
  }

  assert {
    condition     = strcontains(output.hosts_file_content, "supported_tiers       : [hana, scs, pas, web]")
    error_message = "When no app tier servers exist (single-server topology), the DB group's supported_tiers must be broadened to include scs, pas, web."
  }
}

run "hosts_ers_group_populated_with_ha_scs" {
  command = apply

  variables {
    scs_server_count      = 2
    scs_high_availability = true
    NFS_provider          = "AFS"
  }

  assert {
    condition     = strcontains(output.hosts_file_content, "ABC_ERS:")
    error_message = "The hosts file must always contain the ERS group header (ABC_ERS:)."
  }

  assert {
    condition     = strcontains(output.hosts_file_content, "node_tier             : ers")
    error_message = "The ERS group vars must contain 'node_tier : ers'."
  }
}

run "hosts_pas_app_split_with_multiple_app_servers" {
  command = apply

  variables {
    application_server_count = 3
  }

  assert {
    condition     = strcontains(output.hosts_file_content, "ABC_PAS:")
    error_message = "The hosts file must contain the PAS group header."
  }

  assert {
    condition     = strcontains(output.hosts_file_content, "ABC_APP:")
    error_message = "The hosts file must contain the APP group header."
  }

  assert {
    condition     = strcontains(output.hosts_file_content, "node_tier             : pas")
    error_message = "The PAS group vars must contain 'node_tier : pas'."
  }

  assert {
    condition     = strcontains(output.hosts_file_content, "node_tier             : app")
    error_message = "The APP group vars must contain 'node_tier : app'."
  }
}

run "hosts_shared_home_multi_sid_platform" {
  command = apply

  variables {
    shared_home = true
  }

  assert {
    condition     = strcontains(output.hosts_file_content, "node_tier             : hana-multi-sid")
    error_message = "When shared_home=true, the DB group's node_tier must be 'hana-multi-sid' (format('%s-multi-sid', lower(platform)))."
  }
}

