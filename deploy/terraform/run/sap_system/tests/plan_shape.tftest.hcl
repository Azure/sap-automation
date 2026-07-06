# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.
#
# Scenario Categories 3 (plan-shape logic), 4 (cross-module naming consistency),
# and 5 (run/sap_system's own transform.tf/variables_local.tf composition-branch logic).
#
# Zero real Azure/Azure AD API calls: every azurerm/azuread interaction below is
# satisfied by mock_provider, and the only external data lookups (terraform_remote_state)
# are satisfied via override_data so no network access is required.
#
# The root module's own `providers.tf` declares real `provider "azurerm"` blocks for the
# default (unaliased) slot plus the "deployer"/"system"/"dnsmanagement"/"privatelinkdnsmanagement"
# aliases; all five are mocked below. `imports.tf` originally declared two
# `ephemeral "azurerm_key_vault_secret"` resources on the default provider, which made the
# default provider unmockable (Terraform's mock_provider mechanism refuses to mock ANY
# provider referenced by an `ephemeral` resource, regardless of that resource's `count` value
# - confirmed upstream limitation https://github.com/hashicorp/terraform/issues/38608, "No
# ephemeral resource types in mock providers"). Those two resources were converted to regular
# `data "azurerm_key_vault_secret"` resources (see Planning Log ID-02) specifically so the
# default provider could be mocked here like every other provider in this file, restoring full
# test coverage; this accepts the security trade-off that the SPN client secret value is no
# longer write-only/ephemeral in real applies (it is now persisted in Terraform state/plan
# output like any other `data` source, same as this module's other KV-secret lookups).
mock_provider "azurerm" {}
mock_provider "azurerm" {
  alias = "deployer"
}
mock_provider "azurerm" {
  alias = "system"
}
mock_provider "azurerm" {
  alias = "dnsmanagement"
}
mock_provider "azurerm" {
  alias = "privatelinkdnsmanagement"
}
mock_provider "azuread" {}

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

  # spn_keyvault_id/user_keyvault_id are set here so transform.tf's two `coalesce()`-based
  # "exists" checks (for the SPN and user/workload credential vaults respectively - each
  # checking var.*_keyvault_id / the mocked landscape output's *_credential_vault_id /
  # the app-configuration data source) always have at least one non-empty candidate; the
  # mocked landscape output below intentionally returns empty strings for those outputs to
  # mirror a real "no landscape-provided vault" topology, so these variables must supply the
  # fallback in every baseline run.
  spn_keyvault_id  = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-kv/providers/Microsoft.KeyVault/vaults/kv-spn"
  user_keyvault_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-kv/providers/Microsoft.KeyVault/vaults/kv-user"

  database_platform  = "HANA"
  database_use_avset = true
  database_use_ppg   = false

  scs_server_use_avset           = true
  scs_server_use_ppg             = false
  application_server_use_avset   = true
  application_server_use_ppg     = false

  application_server_count     = 1
  scs_server_count              = 1
  webdispatcher_server_count   = 0
  database_server_count        = 1
  database_high_availability   = false

  tags = {
    Environment = "DEV"
    Workload    = "sap-system"
  }
}

# This mock mirrors the FULL real output interface of run/sap_landscape/output.tf (65
# attributes as of writing) rather than a hand-picked subset. Root-module code (e.g.
# common_infrastructure/infrastructure.tf, key_vault_sap_system.tf) reads several of these
# attributes directly off var.landscape_tfstate without try()/optional wrapping, so any
# real attribute this map omits produces a hard "Unsupported attribute" plan error - not a
# code bug, but a mock-completeness gap. Values below reflect a realistic "existing
# landscape, no SPN/app-configuration reuse, no iSCSI/ANF" workload zone topology.
override_data {
  target = data.terraform_remote_state.landscape
  values = {
    outputs = {
      # Control plane / identity
      automation_version              = "5.0.0"
      control_plane_name              = "DEV-WEEU-DEP01"
      controlplane_environment        = "DEV"
      workload_zone_name              = "DEV-WEEU-SAP01"
      workload_zone_prefix            = "DEV-WEEU-SAP01"
      workloadzone_kv_name            = "kv-user"
      random_id                       = "abc"
      use_spn                         = true
      public_network_access_enabled   = true

      # Resource group
      created_resource_group_id             = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-landscape"
      created_resource_group_name           = "rg-landscape"
      created_resource_group_subscription_id = "00000000-0000-0000-0000-000000000000"

      # Network
      vnet_sap_arm_id      = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-landscape/providers/Microsoft.Network/virtualNetworks/vnet-sap01"
      admin_subnet_id      = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-landscape/providers/Microsoft.Network/virtualNetworks/vnet-sap01/subnets/admin"
      admin_nsg_id         = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-landscape/providers/Microsoft.Network/networkSecurityGroups/nsg-admin"
      db_subnet_id         = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-landscape/providers/Microsoft.Network/virtualNetworks/vnet-sap01/subnets/db"
      db_nsg_id            = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-landscape/providers/Microsoft.Network/networkSecurityGroups/nsg-db"
      app_subnet_id        = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-landscape/providers/Microsoft.Network/virtualNetworks/vnet-sap01/subnets/app"
      app_nsg_id           = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-landscape/providers/Microsoft.Network/networkSecurityGroups/nsg-app"
      web_subnet_id        = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-landscape/providers/Microsoft.Network/virtualNetworks/vnet-sap01/subnets/web"
      web_nsg_id           = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-landscape/providers/Microsoft.Network/networkSecurityGroups/nsg-web"
      storage_subnet_id    = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-landscape/providers/Microsoft.Network/virtualNetworks/vnet-sap01/subnets/storage"
      storage_nsg_id       = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-landscape/providers/Microsoft.Network/networkSecurityGroups/nsg-storage"
      ams_subnet_id        = ""
      route_table_id       = ""
      subnet_mgmt_id       = ""
      use_separate_storage_subnet = true

      # Key vaults / credentials
      landscape_key_vault_private_arm_id = ""
      landscape_key_vault_spn_arm_id     = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-landscape/providers/Microsoft.KeyVault/vaults/kv-landscape-spn"
      landscape_key_vault_user_arm_id    = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-landscape/providers/Microsoft.KeyVault/vaults/kv-user"
      user_credential_vault_id           = ""
      spn_credential_vault_id            = ""
      spn_kv_id                          = ""
      sid_password_secret_name           = "sid-password"
      sid_public_key_secret_name         = "sid-public-key"
      sid_username_secret_name           = "sid-username"

      # iSCSI
      iscsi_authentication_username = ""
      iscsi_authentication_type     = ""
      iscsi_private_ip              = []
      iSCSI_server_ips              = []
      iSCSI_server_names            = []
      iSCSI_servers                 = []

      # DNS
      dns_info_iscsi                     = []
      dns_label                          = ""
      dns_resource_group_name            = "rg-landscape"
      management_dns_resourcegroup_name  = ""
      management_dns_subscription_id     = ""
      privatelink_dns_resourcegroup_name = ""
      privatelink_dns_subscription_id    = ""
      privatelink_file_id                = ""
      register_virtual_network_to_dns    = false
      register_storage_accounts_keyvaults_with_dns = false
      use_custom_dns_a_registration      = false

      # Storage accounts
      storageaccount_name           = "stlandscapediag"
      storageaccount_rg_name        = "rg-landscape"
      transport_storage_account_id  = ""
      witness_storage_account       = ""
      witness_storage_account_key   = ""
      utility_storage_account_ids   = []
      utility_storage_account_names = []

      # ANF / mount points
      ANF_pool_settings = {}
      install_path      = ""
      saptransport_path = ""

      # Application configuration (mocked as unused so use_application_configuration = false)
      application_configuration_id   = ""
      application_configuration_name = ""

      ams_resource_id = ""
    }
  }
}

# The landscape override above supplies admin/db/storage subnet ARM IDs, which flips
# infrastructure.virtual_networks.sap.subnet_*.exists_in_workload to true and causes the
# module to look up the existing subnets via `data.azurerm_subnet` (on the mocked "main"/
# "system" provider alias). Mock providers return zero-value computed attributes for data
# sources unless overridden, so outputs.tf's `address_prefixes[0]` / vm-anchor.tf's `.id`
# indexing would otherwise fail against an empty list - these overrides supply realistic
# values, mirroring what a real Azure subnet lookup would return.
override_data {
  target = module.common_infrastructure.data.azurerm_subnet.admin
  values = {
    id                = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-landscape/providers/Microsoft.Network/virtualNetworks/vnet-sap01/subnets/admin"
    address_prefixes  = ["10.1.0.0/24"]
  }
}

override_data {
  target = module.common_infrastructure.data.azurerm_subnet.db
  values = {
    id                = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-landscape/providers/Microsoft.Network/virtualNetworks/vnet-sap01/subnets/db"
    address_prefixes  = ["10.1.1.0/24"]
  }
}

override_data {
  target = module.common_infrastructure.data.azurerm_subnet.storage
  values = {
    id                = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-landscape/providers/Microsoft.Network/virtualNetworks/vnet-sap01/subnets/storage"
    address_prefixes  = ["10.1.2.0/24"]
  }
}

# `user_keyvault_id` being set triggers the "existing user Key Vault" lookup path
# (`data.azurerm_key_vault.sid_keyvault_user`), whose mocked `.id` attribute would otherwise
# be a meaningless mock-generated string, failing downstream `key_vault_id` ARM-ID parsing in
# `key_vault_sap_system.tf`. Overriding it to a well-formed Key Vault ARM ID mirrors what a
# real "existing Key Vault" lookup would return for the `user_keyvault_id` fixture value above.
override_data {
  target = module.common_infrastructure.data.azurerm_key_vault.sid_keyvault_user
  values = {
    id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-kv/providers/Microsoft.KeyVault/vaults/kv-user"
  }
}

# The default mock_provider zeroes out string attributes, so
# `data.azurerm_key_vault_secret.sid_pk.value` returns "" unless overridden here, which fails
# the azurerm_linux_virtual_machine `admin_ssh_key.public_key` provider-side format validation
# ("is not a complete SSH2 Public Key"). Supplying a realistic (fake, non-functional) SSH
# public key mirrors what a real Key Vault secret lookup would return.
override_data {
  target = module.common_infrastructure.data.azurerm_key_vault_secret.sid_pk
  values = {
    value = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCU51GUHdJHlxNoZrvt4bYCSX20Umzij0faob4Ud13/JG6tHbCjgUUVNgmYbAfEHJT0/Vox72Wo4OezrdDdnwhMY+RmRGkcUZq1HE/x5g7yJpPvzCmrvxv25f4w3Er2B6tPeOSStA+eA42vmVbJh20hXveqmA7SsybuYRRd1SZh1VfuWNdfHIAYZQarA169XELRWR0XO8bylT17HLNNWSYiOcOzGEHftMJ7CWlpxU54n9X6hIZ8fmDrLoFBaCb8SIM7VC3dGpRA8g6HJke/ge+MdEkQtSszo0IxcAxeNRGdyIMG/4Ns/mnveudk+7IwoVvuNwn4M1SY9ApGu8RK05Jl diagnostic-only"
  }
}

# The default mock_provider zeroes out string attributes, so
# `data.azurerm_key_vault_secret.sid_password.value` returns "" unless overridden here, which
# fails azurerm_windows_virtual_machine's provider-side admin_password complexity validation
# (needs 3-of-4: lower/upper/digit/special) when a run block exercises the Windows-based
# anydb_node path (e.g. database_platform = "SQLSERVER"). Supplying a realistic (fake) complex
# password mirrors what a real Key Vault secret lookup would return.
override_data {
  target = module.common_infrastructure.data.azurerm_key_vault_secret.sid_password
  values = {
    value = "P@ssw0rd-diagnostic-only!"
  }
}

# Scenario Category 4 + wiring proof for common_infrastructure (module.tf Lines 54-101):
# the created resource group's name must embed the sap_namegenerator SDU prefix
# (env-location_short-vnet-sid), proving run/sap_system passed its composed naming
# contract through to the resource_group resource address inside common_infrastructure.
run "resource_group_name_matches_namegenerator_sdu_prefix" {
  command = plan

  assert {
    condition     = can(regex("^DEV-WEEU-SAP01-ABC$", output.created_resource_group_name))
    error_message = "created_resource_group_name must match the sap_namegenerator SDU naming contract (ENV-LOCATION-VNET-SID), proving run/sap_system wired its naming output into common_infrastructure's resource group."
  }
}

# Scenario Category 3 (tag propagation): var.tags must reach the resource_group resource
# created inside common_infrastructure (terraform-units/modules/sap_system/common_infrastructure/infrastructure.tf Line 16).
run "tags_propagate_to_resource_group" {
  command = plan

  assert {
    condition     = module.common_infrastructure.resource_group[0].tags["Workload"] == "sap-system"
    error_message = "The 'tags' input variable must propagate through run/sap_system's composition into the created resource group's tags."
  }
}

# Scenario Category 3 (output correctness): the root's created_resource_group_name output
# must reflect the exact same value used internally by common_infrastructure's own resource.
run "created_resource_group_name_output_matches_internal_resource" {
  command = plan

  assert {
    condition     = output.created_resource_group_name == module.common_infrastructure.resource_group[0].name
    error_message = "The created_resource_group_name output must match the name of the resource group resource actually planned by common_infrastructure."
  }
}

# Scenario Category 5 (composition branch: name_override_file absent -> generator_as_lists path,
# variables_local.tf Line 53/60/85). Proven indirectly via the SDU naming prefix appearing in the
# created resource group name (locals are not directly assertable by terraform test).
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

# Scenario Category 5 (composition branch: custom_prefix present -> overrides the generator-derived
# SDU prefix used for the resource group name, module.tf Line 68 / common_infrastructure/variables_local.tf Lines 15-19).
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

# Scenario Category 3 (resource cardinality: non-HA topology deploys a single HANA DB node's
# worth of IPs, hdb_node module.tf Lines 108-181, database_server_count computed from HA flag,
# observed via the root's db_vm_ips output since terraform test cannot assert on locals).
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
}

# Scenario Category 3 (resource cardinality: HA topology doubles the HANA DB node count,
# module.tf Lines 125-131), observed via the root's db_vm_ips output cardinality.
run "ha_database_doubles_node_count" {
  command = plan

  variables {
    database_high_availability = true
    database_server_count      = 1
    database_platform          = "HANA"
    # An HA HANA scenario requires an NFS provider for /hana/shared (variables_global.tf
    # Line 147 validation); the file-level default of "NONE" only holds for non-HA runs.
    NFS_provider                = "AFS"
  }

  assert {
    condition     = length(output.db_vm_ips) == 2
    error_message = "HA HANA deployments must double the hdb_node database_server_count (2 * var.database_server_count), observed via db_vm_ips cardinality."
  }
}

# Scenario Category 3 (conditional resource creation: app tier is skipped entirely when
# enable_app_tier_deployment resolves to false, transform.tf Line 7).
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
}

# Wiring-proof signal for app_tier (module.tf Lines 189-237): app_tier must receive the same
# sap_sid derived by run/sap_system's own local.sap_sid composition, not a hardcoded default.
run "app_tier_receives_composed_sap_sid" {
  command = plan

  assert {
    condition     = output.sid == "ABC"
    error_message = "run/sap_system's composed local.sap_sid must be wired through to the app_tier/hdb_node/anydb_node submodules and reflected in the sid output."
  }
}

# Wiring-proof signal for hdb_node (module.tf Lines 108-181): the HANA loadbalancer IP output,
# sourced exclusively from module.hdb_node, proves hdb_node was invoked with the composed database local.
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

# Wiring-proof signal for anydb_node (module.tf Lines 245-307): switching database_platform away
# from HANA must route the database loadbalancer output through anydb_node instead of hdb_node.
run "anydb_node_wiring_used_for_non_hana_platform" {
  command = plan

  variables {
    database_platform = "SQLSERVER"
    database_sid      = "SQL"
  }

  assert {
    condition     = length(output.database_server_vm_ids) == 1
    error_message = "Non-HANA database_platform values must route composition through anydb_node (database_server_vm_ids populated with one VM id per var.database_server_count)."
  }
}

# Wiring-proof signal for output_files (module.tf Lines 315-343): the module's own
# save_naming_information passthrough proves run/sap_system wired its variable into output_files.
run "output_files_wiring_receives_naming_and_infrastructure_locals" {
  command = plan

  assert {
    condition     = output.sapmnt_path != null
    error_message = "output.sapmnt_path (sourced from module.output_files/common_infrastructure composition) must be populated, proving output_files was wired with run/sap_system's composed locals."
  }
}

# Scenario Category 3 (plan-shape logic) - WI-24: greenfield vs. brownfield app-subnet
# coverage. The shared fixture above simulates a brownfield topology exclusively
# (app_subnet_id/app_nsg_id supplied by the landscape workload zone, so the module
# only ever looks the subnet/NSG up via data sources). This never exercised the
# "module creates its own subnet/NSG" branch of app_tier - exactly the code path
# WI-18 (missing `.exists_in_workload`) lived in, undetected, until this scenario
# was added. This run block blanks out app_subnet_id/app_nsg_id in the landscape
# fixture (so exists_in_workload = false) and supplies an app_subnet_address_prefix
# (so subnet_app.defined = true), forcing the greenfield "create" branch.
run "greenfield_app_tier_creates_own_subnet_and_nsg" {
  command = plan

  variables {
    app_subnet_address_prefix = "10.9.9.0/26"
  }

override_data {
  target = data.terraform_remote_state.landscape
  values = {
    outputs = {
      # Control plane / identity
      automation_version              = "5.0.0"
      control_plane_name              = "DEV-WEEU-DEP01"
      controlplane_environment        = "DEV"
      workload_zone_name              = "DEV-WEEU-SAP01"
      workload_zone_prefix            = "DEV-WEEU-SAP01"
      workloadzone_kv_name            = "kv-user"
      random_id                       = "abc"
      use_spn                         = true
      public_network_access_enabled   = true

      # Resource group
      created_resource_group_id             = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-landscape"
      created_resource_group_name           = "rg-landscape"
      created_resource_group_subscription_id = "00000000-0000-0000-0000-000000000000"

      # Network
      vnet_sap_arm_id      = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-landscape/providers/Microsoft.Network/virtualNetworks/vnet-sap01"
      admin_subnet_id      = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-landscape/providers/Microsoft.Network/virtualNetworks/vnet-sap01/subnets/admin"
      admin_nsg_id         = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-landscape/providers/Microsoft.Network/networkSecurityGroups/nsg-admin"
      db_subnet_id         = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-landscape/providers/Microsoft.Network/virtualNetworks/vnet-sap01/subnets/db"
      db_nsg_id            = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-landscape/providers/Microsoft.Network/networkSecurityGroups/nsg-db"
      app_subnet_id        = ""
      app_nsg_id           = ""
      web_subnet_id        = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-landscape/providers/Microsoft.Network/virtualNetworks/vnet-sap01/subnets/web"
      web_nsg_id           = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-landscape/providers/Microsoft.Network/networkSecurityGroups/nsg-web"
      storage_subnet_id    = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-landscape/providers/Microsoft.Network/virtualNetworks/vnet-sap01/subnets/storage"
      storage_nsg_id       = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-landscape/providers/Microsoft.Network/networkSecurityGroups/nsg-storage"
      ams_subnet_id        = ""
      route_table_id       = ""
      subnet_mgmt_id       = ""
      use_separate_storage_subnet = true

      # Key vaults / credentials
      landscape_key_vault_private_arm_id = ""
      landscape_key_vault_spn_arm_id     = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-landscape/providers/Microsoft.KeyVault/vaults/kv-landscape-spn"
      landscape_key_vault_user_arm_id    = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-landscape/providers/Microsoft.KeyVault/vaults/kv-user"
      user_credential_vault_id           = ""
      spn_credential_vault_id            = ""
      spn_kv_id                          = ""
      sid_password_secret_name           = "sid-password"
      sid_public_key_secret_name         = "sid-public-key"
      sid_username_secret_name           = "sid-username"

      # iSCSI
      iscsi_authentication_username = ""
      iscsi_authentication_type     = ""
      iscsi_private_ip              = []
      iSCSI_server_ips              = []
      iSCSI_server_names            = []
      iSCSI_servers                 = []

      # DNS
      dns_info_iscsi                     = []
      dns_label                          = ""
      dns_resource_group_name            = "rg-landscape"
      management_dns_resourcegroup_name  = ""
      management_dns_subscription_id     = ""
      privatelink_dns_resourcegroup_name = ""
      privatelink_dns_subscription_id    = ""
      privatelink_file_id                = ""
      register_virtual_network_to_dns    = false
      register_storage_accounts_keyvaults_with_dns = false
      use_custom_dns_a_registration      = false

      # Storage accounts
      storageaccount_name           = "stlandscapediag"
      storageaccount_rg_name        = "rg-landscape"
      transport_storage_account_id  = ""
      witness_storage_account       = ""
      witness_storage_account_key   = ""
      utility_storage_account_ids   = []
      utility_storage_account_names = []

      # ANF / mount points
      ANF_pool_settings = {}
      install_path      = ""
      saptransport_path = ""

      # Application configuration (mocked as unused so use_application_configuration = false)
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

# Companion assertion: the shared/default fixture (brownfield: app_subnet_id/app_nsg_id
# supplied by the workload zone, no app_subnet_address_prefix) must NOT create its own
# subnet/NSG - proving the greenfield and brownfield branches are mutually exclusive and
# both provably exercised by this suite, not just the greenfield branch in isolation.
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

# Greenfield vs. brownfield coverage for the web tier (same duality proven for app in Phase 7).
run "greenfield_web_tier_creates_own_subnet_and_nsg" {
  command = plan

  variables {
    web_subnet_address_prefix = "10.9.10.0/26"
  }

override_data {
  target = data.terraform_remote_state.landscape
  values = {
    outputs = {
      # Control plane / identity
      automation_version              = "5.0.0"
      control_plane_name              = "DEV-WEEU-DEP01"
      controlplane_environment        = "DEV"
      workload_zone_name              = "DEV-WEEU-SAP01"
      workload_zone_prefix            = "DEV-WEEU-SAP01"
      workloadzone_kv_name            = "kv-user"
      random_id                       = "abc"
      use_spn                         = true
      public_network_access_enabled   = true

      # Resource group
      created_resource_group_id             = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-landscape"
      created_resource_group_name           = "rg-landscape"
      created_resource_group_subscription_id = "00000000-0000-0000-0000-000000000000"

      # Network
      vnet_sap_arm_id      = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-landscape/providers/Microsoft.Network/virtualNetworks/vnet-sap01"
      admin_subnet_id      = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-landscape/providers/Microsoft.Network/virtualNetworks/vnet-sap01/subnets/admin"
      admin_nsg_id         = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-landscape/providers/Microsoft.Network/networkSecurityGroups/nsg-admin"
      db_subnet_id         = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-landscape/providers/Microsoft.Network/virtualNetworks/vnet-sap01/subnets/db"
      db_nsg_id            = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-landscape/providers/Microsoft.Network/networkSecurityGroups/nsg-db"
      app_subnet_id        = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-landscape/providers/Microsoft.Network/virtualNetworks/vnet-sap01/subnets/app"
      app_nsg_id           = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-landscape/providers/Microsoft.Network/networkSecurityGroups/nsg-app"
      web_subnet_id        = ""
      web_nsg_id           = ""
      storage_subnet_id    = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-landscape/providers/Microsoft.Network/virtualNetworks/vnet-sap01/subnets/storage"
      storage_nsg_id       = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-landscape/providers/Microsoft.Network/networkSecurityGroups/nsg-storage"
      ams_subnet_id        = ""
      route_table_id       = ""
      subnet_mgmt_id       = ""
      use_separate_storage_subnet = true

      # Key vaults / credentials
      landscape_key_vault_private_arm_id = ""
      landscape_key_vault_spn_arm_id     = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-landscape/providers/Microsoft.KeyVault/vaults/kv-landscape-spn"
      landscape_key_vault_user_arm_id    = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-landscape/providers/Microsoft.KeyVault/vaults/kv-user"
      user_credential_vault_id           = ""
      spn_credential_vault_id            = ""
      spn_kv_id                          = ""
      sid_password_secret_name           = "sid-password"
      sid_public_key_secret_name         = "sid-public-key"
      sid_username_secret_name           = "sid-username"

      # iSCSI
      iscsi_authentication_username = ""
      iscsi_authentication_type     = ""
      iscsi_private_ip              = []
      iSCSI_server_ips              = []
      iSCSI_server_names            = []
      iSCSI_servers                 = []

      # DNS
      dns_info_iscsi                     = []
      dns_label                          = ""
      dns_resource_group_name            = "rg-landscape"
      management_dns_resourcegroup_name  = ""
      management_dns_subscription_id     = ""
      privatelink_dns_resourcegroup_name = ""
      privatelink_dns_subscription_id    = ""
      privatelink_file_id                = ""
      register_virtual_network_to_dns    = false
      register_storage_accounts_keyvaults_with_dns = false
      use_custom_dns_a_registration      = false

      # Storage accounts
      storageaccount_name           = "stlandscapediag"
      storageaccount_rg_name        = "rg-landscape"
      transport_storage_account_id  = ""
      witness_storage_account       = ""
      witness_storage_account_key   = ""
      utility_storage_account_ids   = []
      utility_storage_account_names = []

      # ANF / mount points
      ANF_pool_settings = {}
      install_path      = ""
      saptransport_path = ""

      # Application configuration (mocked as unused so use_application_configuration = false)
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


# Greenfield vs. brownfield coverage for the admin tier (same duality proven for app in Phase 7).
run "greenfield_admin_tier_creates_own_subnet_and_nsg" {
  command = plan

  variables {
    admin_subnet_address_prefix = "10.9.11.0/26"
    app_tier_dual_nics           = true
  }

override_data {
  target = data.terraform_remote_state.landscape
  values = {
    outputs = {
      # Control plane / identity
      automation_version              = "5.0.0"
      control_plane_name              = "DEV-WEEU-DEP01"
      controlplane_environment        = "DEV"
      workload_zone_name              = "DEV-WEEU-SAP01"
      workload_zone_prefix            = "DEV-WEEU-SAP01"
      workloadzone_kv_name            = "kv-user"
      random_id                       = "abc"
      use_spn                         = true
      public_network_access_enabled   = true

      # Resource group
      created_resource_group_id             = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-landscape"
      created_resource_group_name           = "rg-landscape"
      created_resource_group_subscription_id = "00000000-0000-0000-0000-000000000000"

      # Network
      vnet_sap_arm_id      = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-landscape/providers/Microsoft.Network/virtualNetworks/vnet-sap01"
      admin_subnet_id      = ""
      admin_nsg_id         = ""
      db_subnet_id         = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-landscape/providers/Microsoft.Network/virtualNetworks/vnet-sap01/subnets/db"
      db_nsg_id            = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-landscape/providers/Microsoft.Network/networkSecurityGroups/nsg-db"
      app_subnet_id        = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-landscape/providers/Microsoft.Network/virtualNetworks/vnet-sap01/subnets/app"
      app_nsg_id           = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-landscape/providers/Microsoft.Network/networkSecurityGroups/nsg-app"
      web_subnet_id        = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-landscape/providers/Microsoft.Network/virtualNetworks/vnet-sap01/subnets/web"
      web_nsg_id           = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-landscape/providers/Microsoft.Network/networkSecurityGroups/nsg-web"
      storage_subnet_id    = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-landscape/providers/Microsoft.Network/virtualNetworks/vnet-sap01/subnets/storage"
      storage_nsg_id       = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-landscape/providers/Microsoft.Network/networkSecurityGroups/nsg-storage"
      ams_subnet_id        = ""
      route_table_id       = ""
      subnet_mgmt_id       = ""
      use_separate_storage_subnet = true

      # Key vaults / credentials
      landscape_key_vault_private_arm_id = ""
      landscape_key_vault_spn_arm_id     = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-landscape/providers/Microsoft.KeyVault/vaults/kv-landscape-spn"
      landscape_key_vault_user_arm_id    = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-landscape/providers/Microsoft.KeyVault/vaults/kv-user"
      user_credential_vault_id           = ""
      spn_credential_vault_id            = ""
      spn_kv_id                          = ""
      sid_password_secret_name           = "sid-password"
      sid_public_key_secret_name         = "sid-public-key"
      sid_username_secret_name           = "sid-username"

      # iSCSI
      iscsi_authentication_username = ""
      iscsi_authentication_type     = ""
      iscsi_private_ip              = []
      iSCSI_server_ips              = []
      iSCSI_server_names            = []
      iSCSI_servers                 = []

      # DNS
      dns_info_iscsi                     = []
      dns_label                          = ""
      dns_resource_group_name            = "rg-landscape"
      management_dns_resourcegroup_name  = ""
      management_dns_subscription_id     = ""
      privatelink_dns_resourcegroup_name = ""
      privatelink_dns_subscription_id    = ""
      privatelink_file_id                = ""
      register_virtual_network_to_dns    = false
      register_storage_accounts_keyvaults_with_dns = false
      use_custom_dns_a_registration      = false

      # Storage accounts
      storageaccount_name           = "stlandscapediag"
      storageaccount_rg_name        = "rg-landscape"
      transport_storage_account_id  = ""
      witness_storage_account       = ""
      witness_storage_account_key   = ""
      utility_storage_account_ids   = []
      utility_storage_account_names = []

      # ANF / mount points
      ANF_pool_settings = {}
      install_path      = ""
      saptransport_path = ""

      # Application configuration (mocked as unused so use_application_configuration = false)
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


# Greenfield vs. brownfield coverage for the database tier (same duality proven for app in Phase 7).
run "greenfield_database_tier_creates_own_subnet_and_nsg" {
  command = plan

  variables {
    db_subnet_address_prefix = "10.9.12.0/26"
  }

override_data {
  target = data.terraform_remote_state.landscape
  values = {
    outputs = {
      # Control plane / identity
      automation_version              = "5.0.0"
      control_plane_name              = "DEV-WEEU-DEP01"
      controlplane_environment        = "DEV"
      workload_zone_name              = "DEV-WEEU-SAP01"
      workload_zone_prefix            = "DEV-WEEU-SAP01"
      workloadzone_kv_name            = "kv-user"
      random_id                       = "abc"
      use_spn                         = true
      public_network_access_enabled   = true

      # Resource group
      created_resource_group_id             = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-landscape"
      created_resource_group_name           = "rg-landscape"
      created_resource_group_subscription_id = "00000000-0000-0000-0000-000000000000"

      # Network
      vnet_sap_arm_id      = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-landscape/providers/Microsoft.Network/virtualNetworks/vnet-sap01"
      admin_subnet_id      = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-landscape/providers/Microsoft.Network/virtualNetworks/vnet-sap01/subnets/admin"
      admin_nsg_id         = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-landscape/providers/Microsoft.Network/networkSecurityGroups/nsg-admin"
      db_subnet_id         = ""
      db_nsg_id            = ""
      app_subnet_id        = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-landscape/providers/Microsoft.Network/virtualNetworks/vnet-sap01/subnets/app"
      app_nsg_id           = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-landscape/providers/Microsoft.Network/networkSecurityGroups/nsg-app"
      web_subnet_id        = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-landscape/providers/Microsoft.Network/virtualNetworks/vnet-sap01/subnets/web"
      web_nsg_id           = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-landscape/providers/Microsoft.Network/networkSecurityGroups/nsg-web"
      storage_subnet_id    = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-landscape/providers/Microsoft.Network/virtualNetworks/vnet-sap01/subnets/storage"
      storage_nsg_id       = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-landscape/providers/Microsoft.Network/networkSecurityGroups/nsg-storage"
      ams_subnet_id        = ""
      route_table_id       = ""
      subnet_mgmt_id       = ""
      use_separate_storage_subnet = true

      # Key vaults / credentials
      landscape_key_vault_private_arm_id = ""
      landscape_key_vault_spn_arm_id     = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-landscape/providers/Microsoft.KeyVault/vaults/kv-landscape-spn"
      landscape_key_vault_user_arm_id    = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-landscape/providers/Microsoft.KeyVault/vaults/kv-user"
      user_credential_vault_id           = ""
      spn_credential_vault_id            = ""
      spn_kv_id                          = ""
      sid_password_secret_name           = "sid-password"
      sid_public_key_secret_name         = "sid-public-key"
      sid_username_secret_name           = "sid-username"

      # iSCSI
      iscsi_authentication_username = ""
      iscsi_authentication_type     = ""
      iscsi_private_ip              = []
      iSCSI_server_ips              = []
      iSCSI_server_names            = []
      iSCSI_servers                 = []

      # DNS
      dns_info_iscsi                     = []
      dns_label                          = ""
      dns_resource_group_name            = "rg-landscape"
      management_dns_resourcegroup_name  = ""
      management_dns_subscription_id     = ""
      privatelink_dns_resourcegroup_name = ""
      privatelink_dns_subscription_id    = ""
      privatelink_file_id                = ""
      register_virtual_network_to_dns    = false
      register_storage_accounts_keyvaults_with_dns = false
      use_custom_dns_a_registration      = false

      # Storage accounts
      storageaccount_name           = "stlandscapediag"
      storageaccount_rg_name        = "rg-landscape"
      transport_storage_account_id  = ""
      witness_storage_account       = ""
      witness_storage_account_key   = ""
      utility_storage_account_ids   = []
      utility_storage_account_names = []

      # ANF / mount points
      ANF_pool_settings = {}
      install_path      = ""
      saptransport_path = ""

      # Application configuration (mocked as unused so use_application_configuration = false)
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


# Greenfield vs. brownfield coverage for the storage tier (same duality proven for app in Phase 7).
run "greenfield_storage_tier_creates_own_subnet" {
  command = plan

  variables {
    storage_subnet_address_prefix = "10.9.13.0/26"
  }

override_data {
  target = data.terraform_remote_state.landscape
  values = {
    outputs = {
      # Control plane / identity
      automation_version              = "5.0.0"
      control_plane_name              = "DEV-WEEU-DEP01"
      controlplane_environment        = "DEV"
      workload_zone_name              = "DEV-WEEU-SAP01"
      workload_zone_prefix            = "DEV-WEEU-SAP01"
      workloadzone_kv_name            = "kv-user"
      random_id                       = "abc"
      use_spn                         = true
      public_network_access_enabled   = true

      # Resource group
      created_resource_group_id             = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-landscape"
      created_resource_group_name           = "rg-landscape"
      created_resource_group_subscription_id = "00000000-0000-0000-0000-000000000000"

      # Network
      vnet_sap_arm_id      = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-landscape/providers/Microsoft.Network/virtualNetworks/vnet-sap01"
      admin_subnet_id      = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-landscape/providers/Microsoft.Network/virtualNetworks/vnet-sap01/subnets/admin"
      admin_nsg_id         = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-landscape/providers/Microsoft.Network/networkSecurityGroups/nsg-admin"
      db_subnet_id         = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-landscape/providers/Microsoft.Network/virtualNetworks/vnet-sap01/subnets/db"
      db_nsg_id            = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-landscape/providers/Microsoft.Network/networkSecurityGroups/nsg-db"
      app_subnet_id        = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-landscape/providers/Microsoft.Network/virtualNetworks/vnet-sap01/subnets/app"
      app_nsg_id           = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-landscape/providers/Microsoft.Network/networkSecurityGroups/nsg-app"
      web_subnet_id        = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-landscape/providers/Microsoft.Network/virtualNetworks/vnet-sap01/subnets/web"
      web_nsg_id           = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-landscape/providers/Microsoft.Network/networkSecurityGroups/nsg-web"
      storage_subnet_id    = ""
      storage_nsg_id       = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-landscape/providers/Microsoft.Network/networkSecurityGroups/nsg-storage"
      ams_subnet_id        = ""
      route_table_id       = ""
      subnet_mgmt_id       = ""
      use_separate_storage_subnet = true

      # Key vaults / credentials
      landscape_key_vault_private_arm_id = ""
      landscape_key_vault_spn_arm_id     = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-landscape/providers/Microsoft.KeyVault/vaults/kv-landscape-spn"
      landscape_key_vault_user_arm_id    = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-landscape/providers/Microsoft.KeyVault/vaults/kv-user"
      user_credential_vault_id           = ""
      spn_credential_vault_id            = ""
      spn_kv_id                          = ""
      sid_password_secret_name           = "sid-password"
      sid_public_key_secret_name         = "sid-public-key"
      sid_username_secret_name           = "sid-username"

      # iSCSI
      iscsi_authentication_username = ""
      iscsi_authentication_type     = ""
      iscsi_private_ip              = []
      iSCSI_server_ips              = []
      iSCSI_server_names            = []
      iSCSI_servers                 = []

      # DNS
      dns_info_iscsi                     = []
      dns_label                          = ""
      dns_resource_group_name            = "rg-landscape"
      management_dns_resourcegroup_name  = ""
      management_dns_subscription_id     = ""
      privatelink_dns_resourcegroup_name = ""
      privatelink_dns_subscription_id    = ""
      privatelink_file_id                = ""
      register_virtual_network_to_dns    = false
      register_storage_accounts_keyvaults_with_dns = false
      use_custom_dns_a_registration      = false

      # Storage accounts
      storageaccount_name           = "stlandscapediag"
      storageaccount_rg_name        = "rg-landscape"
      transport_storage_account_id  = ""
      witness_storage_account       = ""
      witness_storage_account_key   = ""
      utility_storage_account_ids   = []
      utility_storage_account_names = []

      # ANF / mount points
      ANF_pool_settings = {}
      install_path      = ""
      saptransport_path = ""

      # Application configuration (mocked as unused so use_application_configuration = false)
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
}
