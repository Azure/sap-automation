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
  database_use_avset = true
  database_use_ppg   = false

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


run "cross_sub_deployer_subscription_resolves_from_spn_kv" {
  command = apply

  variables {
    subscription_id  = "AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA"
    spn_keyvault_id  = "/subscriptions/CCCCCCCC-CCCC-CCCC-CCCC-CCCCCCCCCCCC/resourceGroups/rg-shared/providers/Microsoft.KeyVault/vaults/kv-spn"
    user_keyvault_id = "/subscriptions/AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA/resourceGroups/rg-kv/providers/Microsoft.KeyVault/vaults/kv-user"
  }

  assert {
    condition     = output.resolved_deployer_subscription_id == "CCCCCCCC-CCCC-CCCC-CCCC-CCCCCCCCCCCC"
    error_message = "When spn_keyvault_id is in subscription C, resolved_deployer_subscription_id must resolve to that subscription (extracted from ARM ID split)."
  }

  assert {
    condition     = output.resolved_deployer_subscription_id != "AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA"
    error_message = "The deployer subscription must differ from the system subscription_id when the SPN KV is in a different subscription, proving cross-subscription resolution."
  }
}

run "cross_sub_deployer_subscription_falls_back_to_landscape_spn_kv" {
  command = apply

  variables {
    subscription_id  = "AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA"
    spn_keyvault_id  = ""
    user_keyvault_id = "/subscriptions/AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA/resourceGroups/rg-kv/providers/Microsoft.KeyVault/vaults/kv-user"
  }

  assert {
    condition     = output.resolved_deployer_subscription_id == "00000000-0000-0000-0000-000000000000"
    error_message = "When spn_keyvault_id is empty, deployer_subscription_id must fall back to the landscape's landscape_key_vault_spn_arm_id subscription (00000000... from the shared fixture)."
  }
}

run "cross_sub_management_dns_subscription_resolves_from_variable" {
  command = apply

  variables {
    subscription_id                = "AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA"
    management_dns_subscription_id = "BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBBBB"
  }

  assert {
    condition     = output.resolved_management_dns_subscription_id == "BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBBBB"
    error_message = "When management_dns_subscription_id is set to sub B, the resolved output must equal that value."
  }
}

run "cross_sub_privatelink_dns_subscription_resolves_from_variable" {
  command = apply

  variables {
    subscription_id                 = "AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA"
    privatelink_dns_subscription_id = "CCCCCCCC-CCCC-CCCC-CCCC-CCCCCCCCCCCC"
  }

  assert {
    condition     = output.resolved_privatelink_dns_subscription_id == "CCCCCCCC-CCCC-CCCC-CCCC-CCCCCCCCCCCC"
    error_message = "When privatelink_dns_subscription_id is set to sub C, the resolved output must equal that value."
  }
}

run "cross_sub_privatelink_dns_falls_back_to_management_dns" {
  command = apply

  variables {
    subscription_id                 = "AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA"
    management_dns_subscription_id  = "BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBBBB"
    privatelink_dns_subscription_id = ""
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
        iSCSI_server_ips                             = []
        iSCSI_server_names                           = []
        iSCSI_servers                                = []
        dns_info_iscsi                               = []
        dns_label                                    = ""
        dns_resource_group_name                      = "rg-landscape"
        management_dns_resourcegroup_name            = ""
        management_dns_subscription_id               = "BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBBBB"
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
    condition     = output.resolved_privatelink_dns_subscription_id == ""
    error_message = "When privatelink_dns_subscription_id is empty and no root-level fallback is provided, the resolved privatelink DNS subscription remains empty."
  }
}

run "cross_sub_all_three_resolution_locals_distinct" {
  command = apply

  variables {
    subscription_id                 = "AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA"
    management_dns_subscription_id  = "BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBBBB"
    privatelink_dns_subscription_id = "CCCCCCCC-CCCC-CCCC-CCCC-CCCCCCCCCCCC"
    spn_keyvault_id                 = "/subscriptions/DDDDDDDD-DDDD-DDDD-DDDD-DDDDDDDDDDDD/resourceGroups/rg-deployer/providers/Microsoft.KeyVault/vaults/kv-spn-deployer"
    user_keyvault_id                = "/subscriptions/AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA/resourceGroups/rg-kv/providers/Microsoft.KeyVault/vaults/kv-user"
  }

  assert {
    condition     = output.resolved_management_dns_subscription_id == "BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBBBB"
    error_message = "Management DNS subscription must resolve to sub B."
  }

  assert {
    condition     = output.resolved_privatelink_dns_subscription_id == "CCCCCCCC-CCCC-CCCC-CCCC-CCCCCCCCCCCC"
    error_message = "Private link DNS subscription must resolve to sub C."
  }

  assert {
    condition     = output.resolved_deployer_subscription_id == "DDDDDDDD-DDDD-DDDD-DDDD-DDDDDDDDDDDD"
    error_message = "Deployer subscription (from SPN KV ARM ID) must resolve to sub D."
  }

  assert {
    condition     = output.resolved_management_dns_subscription_id != output.resolved_privatelink_dns_subscription_id
    error_message = "Management DNS and Private Link DNS subscriptions must be distinct when both are explicitly set."
  }

  assert {
    condition     = output.resolved_deployer_subscription_id != output.resolved_management_dns_subscription_id
    error_message = "Deployer and Management DNS subscriptions must be distinct in a 4-subscription topology."
  }
}
