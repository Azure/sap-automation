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

run "resource_group_name_matches_namegenerator_sdu_prefix" {
  command = plan

  assert {
    condition     = can(regex("^DEV-WEEU-SAP01-ABC$", output.created_resource_group_name))
    error_message = "created_resource_group_name must match the sap_namegenerator SDU naming contract (ENV-LOCATION-VNET-SID), proving run/sap_system wired its naming output into common_infrastructure's resource group."
  }
}

run "tags_propagate_to_resource_group" {
  command = plan

  assert {
    condition     = module.common_infrastructure.resource_group[0].tags["Workload"] == "sap-system"
    error_message = "The 'tags' input variable must propagate through run/sap_system's composition into the created resource group's tags."
  }
}

run "created_resource_group_name_output_matches_internal_resource" {
  command = plan

  assert {
    condition     = output.created_resource_group_name == module.common_infrastructure.resource_group[0].name
    error_message = "The created_resource_group_name output must match the name of the resource group resource actually planned by common_infrastructure."
  }
}

run "composition_uses_generator_naming_when_name_override_file_absent" {
  command = plan

  variables {
    name_override_file = ""
  }

  assert {
    condition     = can(regex("^DEV-WEEU-SAP01-ABC$", output.created_resource_group_name))
    error_message = "When name_override_file is absent, run/sap_system must resolve naming.prefix.SDU from module.sap_namegenerator's generator_as_lists composition branch (variables_local.tf Line 85)."
  }
}

run "composition_honors_custom_prefix_when_present" {
  command = plan

  variables {
    custom_prefix = "CUSTOMPFX"
  }

  assert {
    condition     = output.created_resource_group_name == "CUSTOMPFX"
    error_message = "When custom_prefix is set, run/sap_system must pass it through as the resource group's naming prefix instead of the sap_namegenerator-derived SDU prefix."
  }
}

run "non_ha_database_deploys_single_node_set" {
  command = plan

  variables {
    database_high_availability = false
    database_server_count      = 1
    database_platform          = "HANA"
  }

  assert {
    condition     = length(output.db_vm_ips) == 1
    error_message = "Non-HA HANA deployments must size the hdb_node database_server_count to var.database_server_count (no doubling), observed via db_vm_ips cardinality."
  }

  assert {
    condition     = length(output.hanadb_vm_ids) == 1
    error_message = "Non-HA HANA with database_server_count=1 must produce exactly 1 HANA VM ID (no HA partner)."
  }
}

run "ha_database_doubles_node_count" {
  command = plan

  variables {
    database_high_availability = true
    database_server_count      = 1
    database_platform          = "HANA"
    NFS_provider               = "AFS"
  }

  assert {
    condition     = length(output.db_vm_ips) == 2
    error_message = "HA HANA deployments must double the hdb_node database_server_count (2 * var.database_server_count), observed via db_vm_ips cardinality."
  }

  assert {
    condition     = length(output.hanadb_vm_ids) == 2
    error_message = "HA HANA deployments must produce 2 HANA VM IDs (primary + HA partner), observed via hanadb_vm_ids cardinality."
  }
}

run "app_tier_deployment_disabled_by_feature_flag" {
  command = plan

  variables {
    enable_app_tier_deployment = false
    application_server_count   = 0
    scs_server_count           = 0
    webdispatcher_server_count = 0
  }

  assert {
    condition     = output.app_vm_ips == null || length(output.app_vm_ips) == 0
    error_message = "When enable_app_tier_deployment is false, no application-tier VM IPs should be produced."
  }

  assert {
    condition     = output.scs_vm_ids == null || length(output.scs_vm_ids) == 0
    error_message = "When enable_app_tier_deployment is false with scs_server_count=0, no SCS VM IDs should be produced."
  }
}

run "app_tier_receives_composed_sap_sid" {
  command = plan

  assert {
    condition     = output.sid == "ABC"
    error_message = "run/sap_system's composed local.sap_sid must be wired through to the app_tier/hdb_node/anydb_node submodules and reflected in the sid output."
  }
}

run "hdb_node_wiring_produces_database_loadbalancer_output" {
  command = plan

  variables {
    database_platform = "HANA"
  }

  assert {
    condition     = output.database_loadbalancer_ip != null
    error_message = "output.database_loadbalancer_ip must be populated from module.hdb_node when database_platform is HANA, proving run/sap_system wired the composed database local into hdb_node."
  }
}

run "anydb_node_wiring_used_for_non_hana_platform" {
  command = plan

  variables {
    database_platform = "SQLSERVER"
    database_sid      = "SQL"
    database_vm_zones = ["1"]
  }

  assert {
    condition     = length(output.database_server_vm_ids) == 1
    error_message = "Non-HANA database_platform values must route composition through anydb_node (database_server_vm_ids populated with one VM id per var.database_server_count)."
  }

  assert {
    condition     = length(output.hanadb_vm_ids) == 0
    error_message = "Non-HANA database_platform must NOT produce HANA VM IDs (hdb_node must be inactive when using anydb_node)."
  }
}

run "output_files_wiring_receives_naming_and_infrastructure_locals" {
  command = plan

  assert {
    condition     = output.sapmnt_path != null
    error_message = "output.sapmnt_path (sourced from module.output_files/common_infrastructure composition) must be populated, proving output_files was wired with run/sap_system's composed locals."
  }
}

run "greenfield_app_tier_creates_own_subnet_and_nsg" {
  command = plan

  variables {
    app_subnet_address_prefix = "10.9.9.0/26"
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
        app_subnet_id               = ""
        app_nsg_id                  = ""
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

  assert {
    condition     = output.app_tier_resource_creation_counts.app_subnet == 1
    error_message = "With app_subnet_id/app_nsg_id absent from the workload zone and app_subnet_address_prefix supplied, app_tier must create its own azurerm_subnet.subnet_sap_app (greenfield), not rely on a data-source lookup."
  }

  assert {
    condition     = output.app_tier_resource_creation_counts.app_nsg == 1
    error_message = "The greenfield app subnet must be paired with a module-created NSG (azurerm_network_security_group.nsg_app), not a looked-up existing one."
  }
}

run "brownfield_app_tier_reuses_existing_subnet_and_nsg" {
  command = plan

  assert {
    condition     = output.app_tier_resource_creation_counts.app_subnet == 0
    error_message = "With app_subnet_id supplied by the workload zone (the shared fixture's default), app_tier must reuse the existing subnet via a data-source lookup, not create a new one."
  }

  assert {
    condition     = output.app_tier_resource_creation_counts.app_nsg == 0
    error_message = "With app_nsg_id supplied by the workload zone and no app_subnet_address_prefix set, app_tier must not create its own NSG."
  }
}

run "greenfield_web_tier_creates_own_subnet_and_nsg" {
  command = plan

  variables {
    web_subnet_address_prefix = "10.9.10.0/26"
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
        web_subnet_id               = ""
        web_nsg_id                  = ""
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

  assert {
    condition     = output.app_tier_resource_creation_counts.web_subnet == 1
    error_message = "With web_subnet_id/web_nsg_id absent from the workload zone and web_subnet_address_prefix supplied, the module must create its own azurerm_subnet.subnet_sap_web (greenfield), not rely on a data-source lookup."
  }

  assert {
    condition     = output.app_tier_resource_creation_counts.web_nsg == 1
    error_message = "The greenfield web subnet must be paired with a module-created NSG (azurerm_network_security_group.nsg_web), not a looked-up existing one."
  }
}


run "brownfield_web_tier_reuses_existing_subnet_and_nsg" {
  command = plan

  assert {
    condition     = output.app_tier_resource_creation_counts.web_subnet == 0
    error_message = "With web_subnet_id supplied by the workload zone (the shared fixture's default), the module must reuse the existing subnet via a data-source lookup, not create a new one."
  }

  assert {
    condition     = output.app_tier_resource_creation_counts.web_nsg == 0
    error_message = "With web_nsg_id supplied by the workload zone and no web_subnet_address_prefix set, the module must not create its own NSG."
  }
}


run "greenfield_admin_tier_creates_own_subnet_and_nsg" {
  command = plan

  variables {
    admin_subnet_address_prefix = "10.9.11.0/26"
    app_tier_dual_nics          = true
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
        admin_subnet_id             = ""
        admin_nsg_id                = ""
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

  assert {
    condition     = output.admin_tier_resource_creation_counts.subnet == 1
    error_message = "With admin_subnet_id/admin_nsg_id absent from the workload zone and admin_subnet_address_prefix supplied, the module must create its own azurerm_subnet.admin (greenfield), not rely on a data-source lookup."
  }

  assert {
    condition     = output.admin_tier_resource_creation_counts.nsg == 1
    error_message = "The greenfield admin subnet must be paired with a module-created NSG (azurerm_network_security_group.admin), not a looked-up existing one."
  }
}


run "brownfield_admin_tier_reuses_existing_subnet_and_nsg" {
  command = plan

  variables {
    app_tier_dual_nics = true
  }

  assert {
    condition     = output.admin_tier_resource_creation_counts.subnet == 0
    error_message = "With admin_subnet_id supplied by the workload zone (the shared fixture's default) and dual-NIC mode enabled (making the admin subnet eligible for creation), the module must reuse the existing subnet via a data-source lookup, not create a new one."
  }

  assert {
    condition     = output.admin_tier_resource_creation_counts.nsg == 0
    error_message = "With admin_nsg_id supplied by the workload zone and no admin_subnet_address_prefix set, the module must not create its own NSG."
  }
}


run "greenfield_database_tier_creates_own_subnet_and_nsg" {
  command = plan

  variables {
    db_subnet_address_prefix = "10.9.12.0/26"
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
        db_subnet_id                = ""
        db_nsg_id                   = ""
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

  assert {
    condition     = output.database_tier_resource_creation_counts.database_subnet == 1
    error_message = "With db_subnet_id/db_nsg_id absent from the workload zone and db_subnet_address_prefix supplied, the module must create its own azurerm_subnet.db (greenfield), not rely on a data-source lookup."
  }

  assert {
    condition     = output.database_tier_resource_creation_counts.database_nsg == 1
    error_message = "The greenfield database subnet must be paired with a module-created NSG (azurerm_network_security_group.db), not a looked-up existing one."
  }
}


run "brownfield_database_tier_reuses_existing_subnet_and_nsg" {
  command = plan

  assert {
    condition     = output.database_tier_resource_creation_counts.database_subnet == 0
    error_message = "With db_subnet_id supplied by the workload zone (the shared fixture's default), the module must reuse the existing subnet via a data-source lookup, not create a new one."
  }

  assert {
    condition     = output.database_tier_resource_creation_counts.database_nsg == 0
    error_message = "With db_nsg_id supplied by the workload zone and no db_subnet_address_prefix set, the module must not create its own NSG."
  }
}


run "greenfield_storage_tier_creates_own_subnet" {
  command = plan

  variables {
    storage_subnet_address_prefix = "10.9.13.0/26"
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
        storage_subnet_id           = ""
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

  assert {
    condition     = output.database_tier_resource_creation_counts.storage_subnet == 1
    error_message = "With storage_subnet_id absent from the workload zone and storage_subnet_address_prefix supplied, the module must create its own azurerm_subnet.storage (greenfield), not rely on a data-source lookup."
  }
}


run "brownfield_storage_tier_reuses_existing_subnet" {
  command = plan

  assert {
    condition     = output.database_tier_resource_creation_counts.storage_subnet == 0
    error_message = "With storage_subnet_id supplied by the workload zone (the shared fixture's default), the module must reuse the existing subnet via a data-source lookup, not create a new one."
  }

  assert {
    condition     = output.database_tier_resource_creation_counts.database_subnet == 0
    error_message = "The brownfield storage scenario (shared fixture) must also keep the database subnet in brownfield mode (db_subnet_id supplied by the workload zone)."
  }
}


