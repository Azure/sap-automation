# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.
#
# Scenario Categories plan-shape logic, cross-module naming consistency,
# and run/sap_system's own transform.tf/variables_local.tf composition-branch logic.
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
      use_separate_storage_subnet = false

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

      ANF_pool_settings = {
        resource_group_name = "rg-landscape"
        location            = "westeurope"
        account_name        = "anf-dev"
        account_id          = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-landscape/providers/Microsoft.NetApp/netAppAccounts/anf-dev"
        pool_name           = "pool-dev"
        service_level       = "Premium"
        subnet_id           = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-landscape/providers/Microsoft.Network/virtualNetworks/vnet-sap01/subnets/anf"
        qos_type            = "Manual"
      }
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
  target = module.app_tier.data.azurerm_subnet.subnet_sap_app
  values = {
    id               = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-landscape/providers/Microsoft.Network/virtualNetworks/vnet-sap01/subnets/app"
    address_prefixes = ["10.1.0.0/24"]
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

run "greenfield_endpoint_subnet_creates_nsg_and_association" {
  command = plan

  override_resource {
    target = module.common_infrastructure.azurerm_subnet.endpoint
    override_during = plan
    values = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-landscape/providers/Microsoft.Network/virtualNetworks/vnet-sap01/subnets/new-endpoint"
    }
  }

  variables {
    endpoint_subnet_address_prefix = "10.1.5.0/24"
    endpoint_subnet_nsg_name       = "endpoint-nsg"
    NFS_provider                  = "AFS"
    use_private_endpoint          = true
  }

  assert {
    condition     = module.common_infrastructure.database_tier_resource_creation_counts.endpoint_subnet == 1 && module.common_infrastructure.database_tier_resource_creation_counts.endpoint_nsg == 1 && module.common_infrastructure.database_tier_resource_creation_counts.endpoint_nsg_association == 1
    error_message = "A system endpoint prefix must create a subnet, NSG and association."
  }
  assert {
    condition     = module.common_infrastructure.sapmnt_private_endpoint_subnet_ids[0] == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-landscape/providers/Microsoft.Network/virtualNetworks/vnet-sap01/subnets/new-endpoint"
    error_message = "SAP mount private endpoints must use a newly created system endpoint subnet even with old landscape state."
  }
}

run "greenfield_endpoint_subnet_associates_existing_nsg" {
  command = plan

  override_data {
    target = module.common_infrastructure.data.azurerm_network_security_group.endpoint
    values = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-landscape/providers/Microsoft.Network/networkSecurityGroups/endpoint-nsg"
    }
  }

  variables {
    endpoint_subnet_address_prefix = "10.1.5.0/24"
    endpoint_subnet_nsg_arm_id     = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-landscape/providers/Microsoft.Network/networkSecurityGroups/endpoint-nsg"
  }

  assert {
    condition     = module.common_infrastructure.database_tier_resource_creation_counts.endpoint_subnet == 1 && module.common_infrastructure.database_tier_resource_creation_counts.endpoint_nsg == 0 && module.common_infrastructure.database_tier_resource_creation_counts.endpoint_nsg_association == 1
    error_message = "The existing endpoint NSG must be associated with the new system subnet."
  }
}

run "brownfield_endpoint_id_overrides_prefix" {
  command = plan

  variables {
    endpoint_subnet_address_prefix = "10.1.5.0/24"
    endpoint_subnet_arm_id         = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-landscape/providers/Microsoft.Network/virtualNetworks/vnet-sap01/subnets/endpoint"
    NFS_provider                  = "AFS"
    use_private_endpoint          = true
  }

  assert {
    condition     = module.common_infrastructure.database_tier_resource_creation_counts.endpoint_subnet == 0 && module.common_infrastructure.database_tier_resource_creation_counts.endpoint_nsg == 0 && module.common_infrastructure.database_tier_resource_creation_counts.endpoint_nsg_association == 0
    error_message = "An endpoint ARM ID must prevent duplicate creation when a prefix is also supplied."
  }
  assert {
    condition     = module.common_infrastructure.sapmnt_private_endpoint_subnet_ids[0] == var.endpoint_subnet_arm_id
    error_message = "SAP mount private endpoints must use the explicitly supplied endpoint subnet."
  }
}

run "workload_endpoint_subnet_overrides_system_prefix" {
  command = plan

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
        admin_subnet_id             = "/subscriptions/00000000-0000-0000-000000000000/resourceGroups/rg-landscape/providers/Microsoft.Network/virtualNetworks/vnet-sap01/subnets/admin"
        admin_nsg_id                = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-landscape/providers/Microsoft.Network/networkSecurityGroups/nsg-admin"
        db_subnet_id                = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-landscape/providers/Microsoft.Network/virtualNetworks/vnet-sap01/subnets/db"
        db_nsg_id                   = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-landscape/providers/Microsoft.Network/networkSecurityGroups/nsg-db"
        app_subnet_id               = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-landscape/providers/Microsoft.Network/virtualNetworks/vnet-sap01/subnets/app"
        app_nsg_id                  = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-landscape/providers/Microsoft.Network/networkSecurityGroups/nsg-app"
        web_subnet_id               = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-landscape/providers/Microsoft.Network/virtualNetworks/vnet-sap01/subnets/web"
        web_nsg_id                  = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-landscape/providers/Microsoft.Network/networkSecurityGroups/nsg-web"
        storage_subnet_id           = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-landscape/providers/Microsoft.Network/virtualNetworks/vnet-sap01/subnets/storage"
        storage_nsg_id              = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-landscape/providers/Microsoft.Network/networkSecurityGroups/nsg-storage"
        endpoint_subnet_id          = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-landscape/providers/Microsoft.Network/virtualNetworks/vnet-sap01/subnets/workload-endpoint"
        endpoint_nsg_id             = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-landscape/providers/Microsoft.Network/networkSecurityGroups/workload-endpoint-nsg"
        ams_subnet_id               = ""
        route_table_id              = ""
        subnet_mgmt_id              = ""
        use_separate_storage_subnet = false

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
        install_path                   = ""
        saptransport_path              = ""
        application_configuration_id   = ""
        application_configuration_name = ""
        ams_resource_id                 = ""
      }
    }
  }

  variables {
    endpoint_subnet_address_prefix = "10.1.5.0/24"
    NFS_provider                  = "AFS"
    use_private_endpoint          = true
  }

  assert {
    condition     = module.common_infrastructure.database_tier_resource_creation_counts.endpoint_subnet == 0 && module.common_infrastructure.database_tier_resource_creation_counts.endpoint_nsg == 0 && module.common_infrastructure.database_tier_resource_creation_counts.endpoint_nsg_association == 0
    error_message = "A workload-state endpoint subnet must prevent duplicate system subnet and NSG creation."
  }
  assert {
    condition     = module.common_infrastructure.sapmnt_private_endpoint_subnet_ids[0] == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-landscape/providers/Microsoft.Network/virtualNetworks/vnet-sap01/subnets/workload-endpoint"
    error_message = "SAP mount private endpoints must use the workload-state endpoint subnet."
  }
}

run "nfs_provider_afs_activates_sapmnt_afs_path" {
  command = plan

  variables {
    database_platform          = "HANA"
    database_high_availability = true
    NFS_provider               = "AFS"
    use_private_endpoint       = true
  }

  assert {
    condition     = length(output.db_vm_ips) == 2
    error_message = "HANA with AFS NFS provider and HA must still produce 2 DB VM IPs."
  }
  assert {
    condition     = module.common_infrastructure.sapmnt_private_endpoint_subnet_ids[0] == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-landscape/providers/Microsoft.Network/virtualNetworks/vnet-sap01/subnets/app"
    error_message = "Old landscape state without an endpoint subnet must retain the application-subnet fallback."
  }
}
