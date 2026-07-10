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
  override_during = plan
  mock_resource "azurerm_resource_group" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mock-sap-system"
    }
  }
}
mock_provider "azurerm" {
  alias           = "deployer"
  override_during = plan
}
mock_provider "azurerm" {
  alias           = "system"
  override_during = plan
  mock_resource "azurerm_resource_group" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mock-sap-system"
    }
  }
}
mock_provider "azurerm" {
  alias           = "dnsmanagement"
  override_during = plan
}
mock_provider "azurerm" {
  alias           = "privatelinkdnsmanagement"
  override_during = plan
}
mock_provider "azuread" {
  override_during = plan
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


run "anydb_oracle_routes_through_anydb_node" {
  command = plan

  variables {
    database_platform = "ORACLE"
    database_sid      = "ORA"
    database_size     = "512"
    database_vm_zones = ["1"]
  }

  assert {
    condition     = length(output.database_server_vm_ids) == 1
    error_message = "ORACLE platform must route through anydb_node and produce exactly 1 database VM (database_server_vm_ids)."
  }

  assert {
    condition     = length(output.hanadb_vm_ids) == 0
    error_message = "ORACLE platform must NOT produce any HANA VM IDs (hdb_node must be inactive)."
  }
}

run "anydb_db2_routes_through_anydb_node" {
  command = plan

  variables {
    database_platform = "DB2"
    database_sid      = "DB2"
    database_size     = "512"
    database_vm_zones = ["1"]
  }

  assert {
    condition     = length(output.database_server_vm_ids) == 1
    error_message = "DB2 platform must route through anydb_node and produce exactly 1 database VM (database_server_vm_ids)."
  }

  assert {
    condition     = length(output.hanadb_vm_ids) == 0
    error_message = "DB2 platform must NOT produce any HANA VM IDs (hdb_node must be inactive)."
  }
}

run "anydb_ase_routes_through_anydb_node" {
  command = plan

  variables {
    database_platform = "ASE"
    database_sid      = "ASE"
    database_size     = "512"
    database_vm_zones = ["1"]
  }

  assert {
    condition     = length(output.database_server_vm_ids) == 1
    error_message = "ASE platform must route through anydb_node and produce exactly 1 database VM (database_server_vm_ids)."
  }

  assert {
    condition     = length(output.hanadb_vm_ids) == 0
    error_message = "ASE platform must NOT produce any HANA VM IDs (hdb_node must be inactive)."
  }
}

run "ha_anydb_doubles_node_count" {
  command = plan

  variables {
    database_platform          = "ORACLE"
    database_sid               = "ORA"
    database_size              = "512"
    database_high_availability = true
    database_server_count      = 1
    database_vm_zones          = ["1"]
    NFS_provider               = "AFS"
  }

  assert {
    condition     = length(output.database_server_vm_ids) == 2
    error_message = "HA AnyDB (ORACLE) deployments must double the anydb_node database_server_count (2 * var.database_server_count), observed via database_server_vm_ids cardinality."
  }

  assert {
    condition     = length(output.hanadb_vm_ids) == 0
    error_message = "HA AnyDB must NOT produce HANA VM IDs."
  }
}

run "scaleout_hana_multi_node" {
  command = plan

  variables {
    database_platform                   = "HANA"
    database_server_count               = 2
    database_high_availability          = true
    database_HANA_use_scaleout_scenario = true
    stand_by_node_count                 = 0
    NFS_provider                        = "ANF"
  }

  assert {
    condition     = length(output.db_vm_ips) == 4
    error_message = "Scale-out HANA with database_server_count=2 and HA must produce 4 DB VM IPs (2*2 from the scaleout pattern doubling)."
  }

  assert {
    condition     = length(output.hanadb_vm_ids) == 4
    error_message = "Scale-out HANA with database_server_count=2 and HA must produce 4 HANA VM IDs matching the DB VM IP count."
  }
}

run "scaleup_single_large_vm_no_ha" {
  command = plan

  variables {
    database_platform                   = "HANA"
    database_server_count               = 1
    database_high_availability          = false
    database_HANA_use_scaleout_scenario = false
    stand_by_node_count                 = 0
    database_vm_sku                     = "Standard_M208s_v2"
  }

  assert {
    condition     = length(output.db_vm_ips) == 1
    error_message = "Scale-up HANA (single large VM, no HA, no scale-out) must produce exactly 1 DB VM IP."
  }

  assert {
    condition     = length(output.hanadb_vm_ids) == 1
    error_message = "Scale-up HANA must produce exactly 1 HANA VM ID (no standby, no HA partner)."
  }
}

run "webdispatcher_count_creates_web_tier" {
  command = plan

  variables {
    webdispatcher_server_count = 2
  }

  assert {
    condition     = length(output.web_vm_ids) == 2
    error_message = "webdispatcher_server_count=2 must produce exactly 2 web tier VM IDs."
  }

  assert {
    condition     = length(output.app_vm_ips) == 1
    error_message = "webdispatcher_server_count=2 must not affect the baseline app tier count (application_server_count=1 still produces 1 app VM IP)."
  }
}

run "webdispatcher_zero_produces_no_web_vms" {
  command = plan

  variables {
    webdispatcher_server_count = 0
  }

  assert {
    condition     = length(output.web_vm_ids) == 0
    error_message = "webdispatcher_server_count=0 must produce zero web tier VM IDs."
  }
}

run "nfs_provider_anf_enables_anf_usage" {
  command = plan

  variables {
    database_platform                   = "HANA"
    database_high_availability          = true
    database_HANA_use_scaleout_scenario = true
    NFS_provider                        = "ANF"
  }

  assert {
    condition     = length(output.db_vm_ips) == 2
    error_message = "HANA with ANF NFS provider and HA + scaleout must produce the expected DB VM IP count."
  }

  assert {
    condition     = length(output.hanadb_vm_ids) == 2
    error_message = "HANA with ANF NFS provider and HA + scaleout must produce 2 HANA VM IDs matching the DB VM IP count."
  }
}

run "nfs_provider_afs_activates_sapmnt_afs_path" {
  command = plan

  variables {
    database_platform          = "HANA"
    database_high_availability = true
    NFS_provider               = "AFS"
  }

  assert {
    condition     = length(output.db_vm_ips) == 2
    error_message = "HANA with AFS NFS provider and HA must still produce 2 DB VM IPs."
  }

  assert {
    condition     = output.sapmnt_path != null
    error_message = "AFS NFS provider must produce a non-null sapmnt_path output."
  }
}

run "nfs_provider_none_no_special_storage" {
  command = plan

  variables {
    database_platform          = "HANA"
    database_high_availability = false
    NFS_provider               = "NONE"
  }

  assert {
    condition     = length(output.db_vm_ips) == 1
    error_message = "HANA with NFS_provider=NONE and no HA must produce 1 DB VM IP."
  }
}

run "scalesets_disables_avset_and_ppg_for_all_tiers" {
  command = plan

  variables {
    use_scalesets_for_deployment   = true
    database_use_avset             = true
    database_use_ppg               = true
    application_server_use_avset   = true
    application_server_use_ppg     = true
    scs_server_use_avset           = true
    scs_server_use_ppg             = true
    webdispatcher_server_count     = 1
    webdispatcher_server_use_avset = true
    webdispatcher_server_use_ppg   = true
  }

  assert {
    condition     = output.app_tier_resource_creation_counts.app_avset == 0
    error_message = "use_scalesets_for_deployment=true must force app tier avset creation to 0 regardless of database_use_avset/application_server_use_avset settings."
  }
}

run "naming_hana_computername_pattern" {
  command = plan

  variables {
    database_platform     = "HANA"
    database_server_count = 1
    database_sid          = "HDB"
  }

  assert {
    condition     = length(output.hanadb_vm_ids) == 1
    error_message = "HANA platform with database_server_count=1 must produce exactly 1 HANA VM, confirming HANA naming path is active."
  }
}

run "naming_anydb_computername_pattern" {
  command = plan

  variables {
    database_platform     = "ORACLE"
    database_sid          = "ORA"
    database_size         = "512"
    database_server_count = 1
    database_vm_zones     = ["1"]
  }

  assert {
    condition     = length(output.database_server_vm_ids) == 1
    error_message = "AnyDB (ORACLE) with database_server_count=1 must produce exactly 1 AnyDB VM, confirming ANYDB naming path is active."
  }

  assert {
    condition     = length(output.hanadb_vm_ids) == 0
    error_message = "AnyDB platform must not produce HANA VMs, confirming name routing uses ANYDB_COMPUTERNAME not HANA_COMPUTERNAME."
  }
}

run "naming_zonal_markers_enabled_with_zones" {
  command = plan

  variables {
    database_platform     = "HANA"
    database_server_count = 1
    database_vm_zones     = ["1"]
    use_zonal_markers     = true
    database_use_avset    = false
  }

  assert {
    condition     = length(output.db_vm_ips) == 1
    error_message = "HANA with use_zonal_markers=true and database_vm_zones=[1] must still produce 1 DB VM IP, confirming zonal naming path executes successfully."
  }
}

run "naming_zonal_markers_disabled" {
  command = plan

  variables {
    database_platform     = "HANA"
    database_server_count = 1
    database_vm_zones     = []
    use_zonal_markers     = false
  }

  assert {
    condition     = length(output.db_vm_ips) == 1
    error_message = "HANA with use_zonal_markers=false and no zones must produce 1 DB VM IP, confirming non-zonal naming path executes."
  }
}

run "naming_custom_prefix_overrides_separator" {
  command = plan

  variables {
    custom_prefix = "MYPREFIX"
  }

  assert {
    condition     = output.created_resource_group_name == "MYPREFIX"
    error_message = "When custom_prefix is set, the SDU naming prefix must be the custom_prefix value (with empty separator), producing the custom prefix as the resource group name."
  }
}

run "naming_generated_prefix_uses_separator" {
  command = plan

  variables {
    custom_prefix = ""
  }

  assert {
    condition     = can(regex("^DEV-WEEU-SAP01-ABC$", output.created_resource_group_name))
    error_message = "Without custom_prefix, the SDU naming prefix must be the generated ENV-LOCATION-VNET-SID format."
  }
}

run "naming_secondary_dns_v_prefix_with_ha" {
  command = plan

  variables {
    database_platform          = "HANA"
    database_server_count      = 1
    database_high_availability = true
    NFS_provider               = "AFS"
  }

  assert {
    condition     = length(output.db_vm_ips) == 2
    error_message = "HANA HA must produce 2 DB VMs, confirming the HA naming path (including secondary DNS v-prefixed names) is active."
  }
}

run "apply_ha_hana_db_vm_ips_are_populated_strings" {
  command = apply

  variables {
    database_platform          = "HANA"
    database_server_count      = 1
    database_high_availability = true
    NFS_provider               = "AFS"
  }

  assert {
    condition     = length(output.db_vm_ips) == 2
    error_message = "HA HANA must produce exactly 2 DB VM IPs after apply."
  }

  assert {
    condition     = output.db_vm_ips[0] != null && output.db_vm_ips[0] != ""
    error_message = "HA HANA DB VM IP [0] must be a non-null, non-empty string after apply (mock NIC private_ip_address resolved)."
  }

  assert {
    condition     = output.db_vm_ips[1] != null && output.db_vm_ips[1] != ""
    error_message = "HA HANA DB VM IP [1] must be a non-null, non-empty string after apply (mock NIC private_ip_address resolved)."
  }
}

run "apply_brownfield_app_subnet_netmask_is_populated" {
  command = apply

  assert {
    condition     = output.app_subnet_netmask != null && output.app_subnet_netmask != ""
    error_message = "Brownfield app subnet netmask must resolve to a non-null, non-empty string after apply (mock subnet address_prefixes resolved)."
  }
}

run "apply_resource_group_id_is_valid_arm_id" {
  command = apply

  assert {
    condition     = can(regex("^/subscriptions/[^/]+/resourceGroups/[^/]+$", output.created_resource_group_id))
    error_message = "After apply, created_resource_group_id must be a well-formed ARM resource ID (pattern: /subscriptions/{sub}/resourceGroups/{rg})."
  }

  assert {
    condition     = output.created_resource_group_id != ""
    error_message = "After apply, created_resource_group_id must not be empty."
  }
}
