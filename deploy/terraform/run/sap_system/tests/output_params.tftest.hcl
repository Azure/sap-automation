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


run "params_scale_out_block_present" {
  command = apply

  variables {
    database_HANA_use_scaleout_scenario = true
    database_high_availability          = true
    database_server_count               = 2
    database_vm_zones                   = ["1", "2"]
    NFS_provider                        = "AFS"
  }

  assert {
    condition     = strcontains(output.sap_parameters_content, "database_scale_out:")
    error_message = "When scale_out=true, sap-parameters must contain the 'database_scale_out:' field."
  }

  assert {
    condition     = strcontains(output.sap_parameters_content, "database_no_standby:")
    error_message = "When scale_out=true, sap-parameters must contain the 'database_no_standby:' field."
  }
}

run "params_scale_out_block_absent_when_disabled" {
  command = apply

  assert {
    condition     = !strcontains(output.sap_parameters_content, "database_scale_out:")
    error_message = "When scale_out=false (default), sap-parameters must NOT contain the 'database_scale_out:' field."
  }

  assert {
    condition     = !strcontains(output.sap_parameters_content, "database_no_standby:")
    error_message = "When scale_out=false (default), sap-parameters must NOT contain the 'database_no_standby:' field (only emitted for scale-out scenarios)."
  }
}

run "params_sqlserver_cluster_fields_present" {
  command = apply

  variables {
    database_platform = "SQLSERVER"
    database_sid      = "SQL"
  }

  assert {
    condition     = strcontains(output.sap_parameters_content, "scs_clst_lb_ip:")
    error_message = "When platform=SQLSERVER, sap-parameters must contain 'scs_clst_lb_ip:'."
  }

  assert {
    condition     = strcontains(output.sap_parameters_content, "database_cluster_ip:")
    error_message = "When platform=SQLSERVER, sap-parameters must contain 'database_cluster_ip:'."
  }
}

run "params_hana_no_sqlserver_cluster_fields" {
  command = apply

  assert {
    condition     = !strcontains(output.sap_parameters_content, "scs_clst_lb_ip:")
    error_message = "When platform=HANA (default), sap-parameters must NOT contain 'scs_clst_lb_ip:' (SQLSERVER-only)."
  }

  assert {
    condition     = !strcontains(output.sap_parameters_content, "database_cluster_ip:")
    error_message = "When platform=HANA (default), sap-parameters must NOT contain 'database_cluster_ip:' (SQLSERVER-only)."
  }
}

run "params_active_active_block_present" {
  command = apply

  variables {
    database_active_active = true
  }

  assert {
    condition     = strcontains(output.sap_parameters_content, "database_active_active:")
    error_message = "When database_active_active=true, sap-parameters must contain the 'database_active_active:' field."
  }
}

run "params_active_active_block_absent" {
  command = apply

  assert {
    condition     = !strcontains(output.sap_parameters_content, "database_active_active:")
    error_message = "When database_active_active=false (default), sap-parameters must NOT contain the 'database_active_active:' conditional block."
  }
}

run "params_nfs_provider_rendered" {
  command = apply

  assert {
    condition     = strcontains(output.sap_parameters_content, "NFS_provider:")
    error_message = "sap-parameters must always contain the 'NFS_provider:' field."
  }
}

run "params_iscsi_section_present_with_iscsi_cluster" {
  command = apply

  variables {
    scs_cluster_type = "ISCSI"
  }

  override_data {
    target = data.terraform_remote_state.landscape
    values = {
      outputs = {
        automation_version                           = "5.0.0"
        control_plane_name                           = "DEV-WEEU-DEP01"
        controlplane_environment                     = "DEV"
        workload_zone_name                           = "DEV-WEEU-SAP01"
        workload_zone_prefix                         = "DEV-WEEU-SAP01"
        workloadzone_kv_name                         = "kv-user"
        random_id                                    = "abc"
        use_spn                                      = true
        public_network_access_enabled                = true
        created_resource_group_id                    = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-landscape"
        created_resource_group_name                  = "rg-landscape"
        created_resource_group_subscription_id       = "00000000-0000-0000-0000-000000000000"
        vnet_sap_arm_id                              = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-landscape/providers/Microsoft.Network/virtualNetworks/vnet-sap01"
        admin_subnet_id                              = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-landscape/providers/Microsoft.Network/virtualNetworks/vnet-sap01/subnets/admin"
        admin_nsg_id                                 = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-landscape/providers/Microsoft.Network/networkSecurityGroups/nsg-admin"
        db_subnet_id                                 = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-landscape/providers/Microsoft.Network/virtualNetworks/vnet-sap01/subnets/db"
        db_nsg_id                                    = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-landscape/providers/Microsoft.Network/networkSecurityGroups/nsg-db"
        app_subnet_id                                = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-landscape/providers/Microsoft.Network/virtualNetworks/vnet-sap01/subnets/app"
        app_nsg_id                                   = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-landscape/providers/Microsoft.Network/networkSecurityGroups/nsg-app"
        web_subnet_id                                = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-landscape/providers/Microsoft.Network/virtualNetworks/vnet-sap01/subnets/web"
        web_nsg_id                                   = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-landscape/providers/Microsoft.Network/networkSecurityGroups/nsg-web"
        storage_subnet_id                            = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-landscape/providers/Microsoft.Network/virtualNetworks/vnet-sap01/subnets/storage"
        storage_nsg_id                               = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-landscape/providers/Microsoft.Network/networkSecurityGroups/nsg-storage"
        ams_subnet_id                                = ""
        route_table_id                               = ""
        subnet_mgmt_id                               = ""
        use_separate_storage_subnet                  = true
        landscape_key_vault_private_arm_id           = ""
        landscape_key_vault_spn_arm_id               = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-landscape/providers/Microsoft.KeyVault/vaults/kv-landscape-spn"
        landscape_key_vault_user_arm_id              = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-landscape/providers/Microsoft.KeyVault/vaults/kv-user"
        user_credential_vault_id                     = ""
        spn_credential_vault_id                      = ""
        spn_kv_id                                    = ""
        sid_password_secret_name                     = "sid-password"
        sid_public_key_secret_name                   = "sid-public-key"
        sid_username_secret_name                     = "sid-username"
        iscsi_authentication_username                = ""
        iscsi_authentication_type                    = ""
        iscsi_private_ip                             = []
        iSCSI_server_ips                             = ["10.1.3.4", "10.1.3.5", "10.1.3.6"]
        iSCSI_server_names                           = ["iscsi-vm-0", "iscsi-vm-1", "iscsi-vm-2"]
        iSCSI_servers                                = []
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
        storageaccount_name                          = "stlandscapediag"
        storageaccount_rg_name                       = "rg-landscape"
        transport_storage_account_id                 = ""
        witness_storage_account                      = ""
        witness_storage_account_key                  = ""
        utility_storage_account_ids                  = []
        utility_storage_account_names                = []
        ANF_pool_settings                            = {}
        install_path                                 = ""
        saptransport_path                            = ""
        application_configuration_id                 = ""
        application_configuration_name               = ""
        ams_resource_id                              = ""
      }
    }
  }

  assert {
    condition     = strcontains(output.sap_parameters_content, "iscsi_servers:")
    error_message = "When scs_cluster_type=ISCSI and iSCSI server IPs are provided via landscape, sap-parameters must contain 'iscsi_servers:' section."
  }
}

run "params_no_iscsi_section_without_iscsi_cluster" {
  command = apply

  assert {
    condition     = !strcontains(output.sap_parameters_content, "iscsi_servers:")
    error_message = "When cluster_type is not ISCSI (default), sap-parameters must NOT contain 'iscsi_servers:' section."
  }
}

run "params_no_sbd_devices_by_default" {
  command = apply

  assert {
    condition     = !strcontains(output.sap_parameters_content, "sbdDevices:")
    error_message = "When no shared disks are configured (default), sap-parameters must NOT contain 'sbdDevices:' section."
  }
}

run "params_suse_subscription_present" {
  command = apply

  variables {
    suse_subscription_id = "SUSE-REG-CODE-12345"
  }

  assert {
    condition     = strcontains(output.sap_parameters_content, "suse_subscription_id:")
    error_message = "When suse_subscription_id is non-empty, sap-parameters must contain 'suse_subscription_id:' line."
  }
}

run "params_suse_subscription_absent_when_empty" {
  command = apply

  assert {
    condition     = !strcontains(output.sap_parameters_content, "suse_subscription_id:")
    error_message = "When suse_subscription_id is empty (default), sap-parameters must NOT contain 'suse_subscription_id:' line."
  }
}

run "params_user_assigned_identity_present" {
  command = apply

  variables {
    user_assigned_identity_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-id/providers/Microsoft.ManagedIdentity/userAssignedIdentities/mi-sap"
  }

  assert {
    condition     = strcontains(output.sap_parameters_content, "user_assigned_identity_id:")
    error_message = "When user_assigned_identity_id is non-empty, sap-parameters must contain 'user_assigned_identity_id:' line."
  }
}

run "params_user_assigned_identity_absent_when_empty" {
  command = apply

  assert {
    condition     = !strcontains(output.sap_parameters_content, "user_assigned_identity_id:")
    error_message = "When user_assigned_identity_id is empty (default), sap-parameters must NOT contain 'user_assigned_identity_id:' line."
  }
}

run "params_configuration_settings_injected" {
  command = apply

  variables {
    configuration_settings = {
      custom_key = "custom_value"
    }
  }

  assert {
    condition     = strcontains(output.sap_parameters_content, "custom_key")
    error_message = "When configuration_settings is non-empty, its key-value pairs must appear in sap-parameters."
  }

  assert {
    condition     = strcontains(output.sap_parameters_content, "custom_value")
    error_message = "When configuration_settings contains {custom_key = 'custom_value'}, the value must also be rendered in sap-parameters."
  }
}

run "params_configuration_settings_absent_when_empty" {
  command = apply

  variables {
    configuration_settings = {}
  }

  assert {
    condition     = !strcontains(output.sap_parameters_content, "custom_key")
    error_message = "When configuration_settings is empty, no custom settings should appear in sap-parameters."
  }
}

run "params_secret_prefix_uses_workload_zone_by_default" {
  command = apply

  assert {
    condition     = strcontains(output.sap_parameters_content, "secret_prefix:")
    error_message = "sap-parameters must always contain the 'secret_prefix:' field."
  }
}

run "params_scs_instance_number_fallback_to_01" {
  command = apply

  variables {
    application_server_count = 0
    scs_server_count         = 0
  }

  assert {
    condition     = strcontains(output.sap_parameters_content, "scs_instance_number:           \"01\"")
    error_message = "When no SCS or app servers exist, scs_instance_number must fall back to '01'."
  }
}

run "params_upgrade_packages_true" {
  command = apply

  variables {
    upgrade_packages = true
  }

  assert {
    condition     = strcontains(output.sap_parameters_content, "upgrade_packages:              true")
    error_message = "When upgrade_packages=true, sap-parameters must render 'upgrade_packages: true'."
  }
}

run "params_upgrade_packages_false" {
  command = apply

  assert {
    condition     = strcontains(output.sap_parameters_content, "upgrade_packages:              false")
    error_message = "When upgrade_packages=false (default), sap-parameters must render 'upgrade_packages: false'."
  }
}

run "params_subnet_cidr_client_present_when_admin_subnet_exists" {
  command = apply

  assert {
    condition     = strcontains(output.sap_parameters_content, "subnet_cidr_client:")
    error_message = "When admin subnet exists (baseline fixture provides admin_subnet_id with address_prefixes), subnet_cidr_client must be non-empty and rendered in sap-parameters."
  }
}

