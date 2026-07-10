mock_provider "azurerm" {
  override_during = plan
}
mock_provider "azurerm" {
  alias           = "workload"
  override_during = plan

  mock_resource "azurerm_key_vault" {
    defaults = {
      id   = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-sap-dev/providers/Microsoft.KeyVault/vaults/kv-mock"
      name = "kv-mock"
    }
  }
  mock_resource "azurerm_storage_account" {
    defaults = {
      id   = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-sap-dev/providers/Microsoft.Storage/storageAccounts/stmock"
      name = "stmock"
    }
  }
}
mock_provider "azurerm" {
  alias           = "deployer"
  override_during = plan
}
mock_provider "azurerm" {
  alias           = "dnsmanagement"
  override_during = plan
}
mock_provider "azurerm" {
  alias           = "privatelinkdnsmanagement"
  override_during = plan
}
mock_provider "azurerm" {
  alias           = "peering"
  override_during = plan
}
mock_provider "azuread" {
  override_during = plan
}
mock_provider "azapi" {
  alias           = "api"
  override_during = plan
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

  assert {
    condition     = output.workloadzone_kv_name != ""
    error_message = "Without user_keyvault_id, the workloadzone_kv_name output must be non-empty after keyvault creation."
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
}

run "diagnostics_storage_account_greenfield_creates_account" {
  command = plan

  variables {
    diagnostics_storage_account_arm_id = ""
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
    condition     = output.transport_storage_account_id != ""
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
}

run "dns_fallback_privatelink_equals_management_uses_same_subscription" {
  command = plan

  variables {
    management_dns_subscription_id  = "AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA"
    privatelink_dns_subscription_id = "AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA"
  }

  assert {
    condition     = output.management_dns_subscription_id == output.privatelink_dns_subscription_id
    error_message = "When privatelink_dns_subscription_id equals management_dns_subscription_id, both outputs must resolve to the same value."
  }
}

run "dns_fallback_privatelink_differs_from_management_uses_separate" {
  command = plan

  variables {
    management_dns_subscription_id  = "AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA"
    privatelink_dns_subscription_id = "BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBBBB"
  }

  assert {
    condition     = output.management_dns_subscription_id != output.privatelink_dns_subscription_id
    error_message = "When privatelink_dns_subscription_id differs from management_dns_subscription_id, they must resolve to different values."
  }

  assert {
    condition     = output.privatelink_dns_subscription_id == "BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBBBB"
    error_message = "privatelink_dns_subscription_id output must reflect the explicit input value."
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
    condition     = output.ng_resource_id != ""
    error_message = "With deploy_nat_gateway=true, sap_landscape must create a NAT gateway and expose its resource ID."
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
    condition     = output.public_network_access_enabled == false
    error_message = "When use_private_endpoint=true, public_network_access_enabled output must be false."
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
    condition     = length(output.iscsi_private_ip) == 2
    error_message = "With static IPs provided, iscsi_private_ip output must have exactly 2 entries."
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

  assert {
    condition     = output.ams_resource_id != ""
    error_message = "With create_ams_instance=true, ams_resource_id output must be non-empty."
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

run "cross_subscription_dns_and_keyvault_resolution" {
  command = plan

  variables {
    subscription_id                              = "AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA"
    management_dns_subscription_id               = "BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBBBB"
    privatelink_dns_subscription_id              = "CCCCCCCC-CCCC-CCCC-CCCC-CCCCCCCCCCCC"
    user_keyvault_id                             = "/subscriptions/CCCCCCCC-CCCC-CCCC-CCCC-CCCCCCCCCCCC/resourceGroups/rg-shared/providers/Microsoft.KeyVault/vaults/kv-user-shared"
    register_storage_accounts_keyvaults_with_dns = true
    use_private_endpoint                         = true
  }

  override_data {
    target = data.terraform_remote_state.deployer
    values = {
      outputs = {
        created_resource_group_subscription_id = "DDDDDDDD-DDDD-DDDD-DDDD-DDDDDDDDDDDD"
        environment                            = "DEV"
        additional_network_id                  = ""
        application_configuration_id           = ""
        control_plane_name                     = "DEV-WEEU-DEP00"
        deployer_kv_user_arm_id                = "/subscriptions/DDDDDDDD-DDDD-DDDD-DDDD-DDDDDDDDDDDD/resourceGroups/rg-mgmt/providers/Microsoft.KeyVault/vaults/kv-deployer"
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
        network_security_perimeter_id                         = ""
        subnet_bastion_address_prefixes                       = ["10.0.1.0/26"]
        subnet_mgmt_address_prefixes                          = ["10.0.0.0/24"]
        subnet_mgmt_id                                        = "/subscriptions/DDDDDDDD-DDDD-DDDD-DDDD-DDDDDDDDDDDD/resourceGroups/rg-mgmt/providers/Microsoft.Network/virtualNetworks/vnet-mgmt/subnets/snet-mgmt"
        subnets_to_add_to_firewall_for_key_vaults_and_storage = []
        vnet_mgmt_id                                          = "/subscriptions/DDDDDDDD-DDDD-DDDD-DDDD-DDDDDDDDDDDD/resourceGroups/rg-mgmt/providers/Microsoft.Network/virtualNetworks/vnet-mgmt"
      }
    }
  }

  override_data {
    target = module.sap_landscape.data.azurerm_key_vault.kv_user
    values = {
      id   = "/subscriptions/CCCCCCCC-CCCC-CCCC-CCCC-CCCCCCCCCCCC/resourceGroups/rg-shared/providers/Microsoft.KeyVault/vaults/kv-user-shared"
      name = "kv-user-shared"
    }
  }

  assert {
    condition     = output.management_dns_subscription_id == "BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBBBB"
    error_message = "management_dns_subscription_id must resolve to the explicit input (sub B)."
  }

  assert {
    condition     = output.privatelink_dns_subscription_id == "CCCCCCCC-CCCC-CCCC-CCCC-CCCCCCCCCCCC"
    error_message = "privatelink_dns_subscription_id must resolve to the explicit input (sub C)."
  }

  assert {
    condition     = output.landscape_key_vault_user_arm_id == "/subscriptions/CCCCCCCC-CCCC-CCCC-CCCC-CCCCCCCCCCCC/resourceGroups/rg-shared/providers/Microsoft.KeyVault/vaults/kv-user-shared"
    error_message = "landscape_key_vault_user_arm_id must preserve the sub C prefix from the input ARM ID."
  }
}

run "full_four_subscription_topology_resolves_all_distinct" {
  command = plan

  variables {
    subscription_id                              = "AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA"
    management_subscription_id                   = "AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA"
    management_dns_subscription_id               = "BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBBBB"
    privatelink_dns_subscription_id              = "CCCCCCCC-CCCC-CCCC-CCCC-CCCCCCCCCCCC"
    peer_with_control_plane_vnet                 = true
    register_storage_accounts_keyvaults_with_dns = true
    register_virtual_network_to_dns              = true
    use_private_endpoint                         = true
    user_keyvault_id                             = "/subscriptions/CCCCCCCC-CCCC-CCCC-CCCC-CCCCCCCCCCCC/resourceGroups/rg-shared/providers/Microsoft.KeyVault/vaults/kv-user"
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
    dns_label                                    = "corp.contoso.internal"
  }

  override_data {
    target = data.terraform_remote_state.deployer
    values = {
      outputs = {
        created_resource_group_subscription_id = "DDDDDDDD-DDDD-DDDD-DDDD-DDDDDDDDDDDD"
        environment                            = "DEV"
        additional_network_id                  = ""
        application_configuration_id           = ""
        control_plane_name                     = "DEV-WEEU-DEP00"
        deployer_kv_user_arm_id                = "/subscriptions/DDDDDDDD-DDDD-DDDD-DDDD-DDDDDDDDDDDD/resourceGroups/rg-mgmt/providers/Microsoft.KeyVault/vaults/kv-deployer"
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
        network_security_perimeter_id                         = ""
        subnet_bastion_address_prefixes                       = ["10.0.1.0/26"]
        subnet_mgmt_address_prefixes                          = ["10.0.0.0/24"]
        subnet_mgmt_id                                        = "/subscriptions/DDDDDDDD-DDDD-DDDD-DDDD-DDDDDDDDDDDD/resourceGroups/rg-mgmt/providers/Microsoft.Network/virtualNetworks/vnet-mgmt/subnets/snet-mgmt"
        subnets_to_add_to_firewall_for_key_vaults_and_storage = []
        vnet_mgmt_id                                          = "/subscriptions/DDDDDDDD-DDDD-DDDD-DDDD-DDDDDDDDDDDD/resourceGroups/rg-mgmt/providers/Microsoft.Network/virtualNetworks/vnet-mgmt"
      }
    }
  }

  override_data {
    target = module.sap_landscape.data.azurerm_key_vault.kv_user
    values = {
      id   = "/subscriptions/CCCCCCCC-CCCC-CCCC-CCCC-CCCCCCCCCCCC/resourceGroups/rg-shared/providers/Microsoft.KeyVault/vaults/kv-user"
      name = "kv-user"
    }
  }

  assert {
    condition     = output.management_dns_subscription_id == "BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBBBB"
    error_message = "In 4-sub topology, management_dns_subscription_id must resolve to sub B."
  }

  assert {
    condition     = output.privatelink_dns_subscription_id == "CCCCCCCC-CCCC-CCCC-CCCC-CCCCCCCCCCCC"
    error_message = "In 4-sub topology, privatelink_dns_subscription_id must resolve to sub C."
  }

  assert {
    condition     = output.management_dns_subscription_id != output.privatelink_dns_subscription_id
    error_message = "In 4-sub topology, management and privatelink DNS subscriptions must be distinct."
  }

  assert {
    condition     = module.sap_landscape.network_resource_counts.vnet == 1
    error_message = "In 4-sub topology with greenfield VNet, the VNet must be created."
  }

  assert {
    condition     = module.sap_landscape.dns_link_counts.vnet_sap == 1
    error_message = "In 4-sub topology with DNS registration enabled, VNet DNS link must be planned."
  }

  assert {
    condition     = output.landscape_key_vault_user_arm_id == "/subscriptions/CCCCCCCC-CCCC-CCCC-CCCC-CCCCCCCCCCCC/resourceGroups/rg-shared/providers/Microsoft.KeyVault/vaults/kv-user"
    error_message = "In 4-sub topology, user keyvault ARM ID must preserve the sub C prefix."
  }
}

run "privatelink_dns_fallback_explicit_value_takes_priority" {
  command = plan

  variables {
    management_dns_subscription_id  = "BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBBBB"
    privatelink_dns_subscription_id = "CCCCCCCC-CCCC-CCCC-CCCC-CCCCCCCCCCCC"
  }

  assert {
    condition     = output.privatelink_dns_subscription_id == "CCCCCCCC-CCCC-CCCC-CCCC-CCCCCCCCCCCC"
    error_message = "When privatelink_dns_subscription_id is non-empty, it must take priority over all fallbacks."
  }

  assert {
    condition     = output.management_dns_subscription_id == "BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBBBB"
    error_message = "When management_dns_subscription_id is non-empty, it must resolve to the explicit input value."
  }
}

run "privatelink_dns_fallback_empty_uses_management_dns" {
  command = plan

  variables {
    management_dns_subscription_id  = "BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBBBB"
    privatelink_dns_subscription_id = ""
  }

  assert {
    condition     = output.privatelink_dns_subscription_id == "BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBBBB"
    error_message = "When privatelink_dns_subscription_id is empty, it must fall back to management_dns_subscription_id."
  }

  assert {
    condition     = output.management_dns_subscription_id == "BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBBBB"
    error_message = "When management_dns_subscription_id is explicitly set, it must resolve to that value."
  }
}

run "privatelink_dns_fallback_both_empty_uses_tfstate_subscription" {
  command = plan

  variables {
    management_dns_subscription_id  = ""
    privatelink_dns_subscription_id = ""
  }

  assert {
    condition     = output.privatelink_dns_subscription_id == "00000000-0000-0000-0000-000000000000"
    error_message = "When both DNS subscription IDs are empty, privatelink_dns_subscription_id must fall back to the tfstate storage account subscription."
  }

  assert {
    condition     = output.management_dns_subscription_id == "00000000-0000-0000-0000-000000000000"
    error_message = "When management_dns_subscription_id is empty, it must fall back to the tfstate storage account subscription."
  }
}

run "cross_sub_full_4_subscription_topology" {
  command = plan

  variables {
    subscription_id                              = "AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA"
    management_dns_subscription_id               = "BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBBBB"
    privatelink_dns_subscription_id              = "CCCCCCCC-CCCC-CCCC-CCCC-CCCCCCCCCCCC"
    user_keyvault_id                             = "/subscriptions/CCCCCCCC-CCCC-CCCC-CCCC-CCCCCCCCCCCC/resourceGroups/rg-shared/providers/Microsoft.KeyVault/vaults/kv-user"
    spn_keyvault_id                              = "/subscriptions/CCCCCCCC-CCCC-CCCC-CCCC-CCCCCCCCCCCC/resourceGroups/rg-shared/providers/Microsoft.KeyVault/vaults/kv-spn"
    peer_with_control_plane_vnet                 = true
    register_storage_accounts_keyvaults_with_dns = true
    use_private_endpoint                         = true
  }

  override_data {
    target = data.terraform_remote_state.deployer
    values = {
      outputs = {
        created_resource_group_subscription_id = "DDDDDDDD-DDDD-DDDD-DDDD-DDDDDDDDDDDD"
        environment                            = "DEV"
        additional_network_id                  = "/subscriptions/DDDDDDDD-DDDD-DDDD-DDDD-DDDDDDDDDDDD/resourceGroups/rg-mgmt/providers/Microsoft.Network/virtualNetworks/vnet-agent"
        application_configuration_id           = ""
        control_plane_name                     = "DEV-WEEU-DEP00"
        deployer_kv_user_arm_id                = "/subscriptions/DDDDDDDD-DDDD-DDDD-DDDD-DDDDDDDDDDDD/resourceGroups/rg-mgmt/providers/Microsoft.KeyVault/vaults/kv-deployer"
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
        network_security_perimeter_id                         = "/subscriptions/DDDDDDDD-DDDD-DDDD-DDDD-DDDDDDDDDDDD/resourceGroups/rg-mgmt/providers/Microsoft.Network/networkSecurityPerimeters/nsp-dev"
        subnet_bastion_address_prefixes                       = ["10.0.1.0/26"]
        subnet_mgmt_address_prefixes                          = ["10.0.0.0/24"]
        subnet_mgmt_id                                        = "/subscriptions/DDDDDDDD-DDDD-DDDD-DDDD-DDDDDDDDDDDD/resourceGroups/rg-mgmt/providers/Microsoft.Network/virtualNetworks/vnet-mgmt/subnets/snet-mgmt"
        subnets_to_add_to_firewall_for_key_vaults_and_storage = []
        vnet_mgmt_id                                          = "/subscriptions/DDDDDDDD-DDDD-DDDD-DDDD-DDDDDDDDDDDD/resourceGroups/rg-mgmt/providers/Microsoft.Network/virtualNetworks/vnet-mgmt"
      }
    }
  }

  assert {
    condition     = output.resolved_deployer_subscription_id == "DDDDDDDD-DDDD-DDDD-DDDD-DDDDDDDDDDDD"
    error_message = "Deployer subscription must resolve to sub D (from deployer remote state created_resource_group_subscription_id)."
  }

  assert {
    condition     = output.resolved_management_dns_subscription_id == "BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBBBB"
    error_message = "Management DNS subscription must resolve to sub B (explicitly set)."
  }

  assert {
    condition     = output.resolved_privatelink_dns_subscription_id == "CCCCCCCC-CCCC-CCCC-CCCC-CCCCCCCCCCCC"
    error_message = "Private Link DNS subscription must resolve to sub C (explicitly set)."
  }

  assert {
    condition     = output.resolved_management_dns_subscription_id != output.resolved_privatelink_dns_subscription_id
    error_message = "Management DNS and Private Link DNS subscriptions must be distinct when both are explicitly set."
  }

  assert {
    condition     = output.resolved_deployer_subscription_id != output.resolved_management_dns_subscription_id
    error_message = "Deployer and Management DNS subscriptions must be distinct in a 4-subscription topology."
  }

  assert {
    condition     = output.resolved_deployer_subscription_id != output.resolved_privatelink_dns_subscription_id
    error_message = "Deployer and Private Link DNS subscriptions must be distinct in a 4-subscription topology."
  }

  assert {
    condition     = startswith(output.landscape_key_vault_spn_arm_id, "/subscriptions/CCCCCCCC-CCCC-CCCC-CCCC-CCCCCCCCCCCC/") || startswith(output.landscape_key_vault_spn_arm_id, "/subscriptions/DDDDDDDD-DDDD-DDDD-DDDD-DDDDDDDDDDDD/")
    error_message = "SPN key vault ARM ID must preserve the cross-subscription prefix from the coalesce() resolution."
  }
}

run "cross_sub_privatelink_dns_explicit_value" {
  command = plan

  variables {
    subscription_id                 = "AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA"
    management_dns_subscription_id  = "BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBBBB"
    privatelink_dns_subscription_id = "CCCCCCCC-CCCC-CCCC-CCCC-CCCCCCCCCCCC"
  }

  assert {
    condition     = output.resolved_privatelink_dns_subscription_id == "CCCCCCCC-CCCC-CCCC-CCCC-CCCCCCCCCCCC"
    error_message = "When privatelink_dns_subscription_id is explicitly set to sub C, the resolved output must equal that value."
  }

  assert {
    condition     = output.resolved_management_dns_subscription_id == "BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBBBB"
    error_message = "Management DNS subscription must independently resolve to sub B."
  }
}

run "cross_sub_privatelink_dns_falls_back_to_management_dns" {
  command = plan

  variables {
    subscription_id                 = "AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA"
    management_dns_subscription_id  = "BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBBBB"
    privatelink_dns_subscription_id = ""
  }

  assert {
    condition     = output.resolved_privatelink_dns_subscription_id == "BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBBBB"
    error_message = "When privatelink_dns_subscription_id is empty, it must fall back to management_dns_subscription_id (sub B)."
  }

  assert {
    condition     = output.resolved_management_dns_subscription_id == "BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBBBB"
    error_message = "Management DNS subscription must still resolve to sub B regardless of privatelink fallback."
  }
}

run "cross_sub_both_dns_empty_falls_back_to_tfstate" {
  command = plan

  variables {
    subscription_id                 = "AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA"
    management_dns_subscription_id  = ""
    privatelink_dns_subscription_id = ""
    tfstate_resource_id             = "/subscriptions/DDDDDDDD-DDDD-DDDD-DDDD-DDDDDDDDDDDD/resourceGroups/rg-tfstate/providers/Microsoft.Storage/storageAccounts/tfstatesa"
  }

  assert {
    condition     = output.resolved_privatelink_dns_subscription_id == "DDDDDDDD-DDDD-DDDD-DDDD-DDDDDDDDDDDD"
    error_message = "When both DNS subscription IDs are empty, privatelink must fall back to tfstate subscription (sub D)."
  }

  assert {
    condition     = output.resolved_management_dns_subscription_id == "DDDDDDDD-DDDD-DDDD-DDDD-DDDDDDDDDDDD"
    error_message = "When management_dns_subscription_id is empty, it must fall back to tfstate subscription (sub D)."
  }

  assert {
    condition     = output.resolved_privatelink_dns_subscription_id != "AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA"
    error_message = "DNS subscription fallback must NOT resolve to the workload subscription_id when tfstate is in a different subscription."
  }
}

run "cross_sub_privatelink_prefers_management_over_tfstate" {
  command = plan

  variables {
    subscription_id                 = "AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA"
    management_dns_subscription_id  = "BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBBBB"
    privatelink_dns_subscription_id = ""
    tfstate_resource_id             = "/subscriptions/DDDDDDDD-DDDD-DDDD-DDDD-DDDDDDDDDDDD/resourceGroups/rg-tfstate/providers/Microsoft.Storage/storageAccounts/tfstatesa"
  }

  assert {
    condition     = output.resolved_privatelink_dns_subscription_id == "BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBBBB"
    error_message = "When privatelink is empty but management_dns is set, privatelink must prefer management_dns (sub B) over tfstate (sub D)."
  }

  assert {
    condition     = output.resolved_privatelink_dns_subscription_id != "DDDDDDDD-DDDD-DDDD-DDDD-DDDDDDDDDDDD"
    error_message = "The coalesce() chain must pick management_dns_subscription_id before falling through to tfstate."
  }
}

run "apply_cross_sub_storage_creation_with_brownfield_dns" {
  command = apply

  variables {
    subscription_id                              = "AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA"
    management_dns_subscription_id               = "BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBBBB"
    privatelink_dns_subscription_id              = "BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBBBB"
    privatelink_dns_resourcegroup_name           = "rg-dns-central"
    management_dns_resourcegroup_name            = "rg-dns-central"
    user_keyvault_id                             = "/subscriptions/CCCCCCCC-CCCC-CCCC-CCCC-CCCCCCCCCCCC/resourceGroups/rg-shared/providers/Microsoft.KeyVault/vaults/kv-user-shared"
    spn_keyvault_id                              = "/subscriptions/CCCCCCCC-CCCC-CCCC-CCCC-CCCCCCCCCCCC/resourceGroups/rg-shared/providers/Microsoft.KeyVault/vaults/kv-spn-shared"
    diagnostics_storage_account_arm_id           = ""
    witness_storage_account_arm_id               = ""
    create_transport_storage                     = true
    NFS_provider                                 = "AFS"
    transport_storage_account_id                 = ""
    use_private_endpoint                         = true
    register_storage_accounts_keyvaults_with_dns = true
  }

  override_data {
    target = data.terraform_remote_state.deployer
    values = {
      outputs = {
        created_resource_group_subscription_id = "DDDDDDDD-DDDD-DDDD-DDDD-DDDDDDDDDDDD"
        environment                            = "DEV"
        additional_network_id                  = ""
        application_configuration_id           = ""
        control_plane_name                     = "DEV-WEEU-DEP00"
        deployer_kv_user_arm_id                = "/subscriptions/DDDDDDDD-DDDD-DDDD-DDDD-DDDDDDDDDDDD/resourceGroups/rg-mgmt/providers/Microsoft.KeyVault/vaults/kv-deployer"
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
        network_security_perimeter_id                         = ""
        subnet_bastion_address_prefixes                       = ["10.0.1.0/26"]
        subnet_mgmt_address_prefixes                          = ["10.0.0.0/24"]
        subnet_mgmt_id                                        = "/subscriptions/DDDDDDDD-DDDD-DDDD-DDDD-DDDDDDDDDDDD/resourceGroups/rg-mgmt/providers/Microsoft.Network/virtualNetworks/vnet-mgmt/subnets/snet-mgmt"
        subnets_to_add_to_firewall_for_key_vaults_and_storage = []
        vnet_mgmt_id                                          = "/subscriptions/DDDDDDDD-DDDD-DDDD-DDDD-DDDDDDDDDDDD/resourceGroups/rg-mgmt/providers/Microsoft.Network/virtualNetworks/vnet-mgmt"
      }
    }
  }

  override_data {
    target = module.sap_landscape.data.azurerm_key_vault.kv_user
    values = {
      id   = "/subscriptions/CCCCCCCC-CCCC-CCCC-CCCC-CCCCCCCCCCCC/resourceGroups/rg-shared/providers/Microsoft.KeyVault/vaults/kv-user-shared"
      name = "kv-user-shared"
    }
  }

  assert {
    condition     = output.storageaccount_name != ""
    error_message = "After apply, the diagnostics storage account name must be a resolved non-empty string."
  }

  assert {
    condition     = output.witness_storage_account != ""
    error_message = "After apply, the witness storage account name must be a resolved non-empty string."
  }

  assert {
    condition     = output.transport_storage_account_id != ""
    error_message = "After apply, the transport storage account ID must be a resolved non-empty string."
  }

  assert {
    condition     = output.resolved_management_dns_subscription_id == "BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBBBB"
    error_message = "After apply, management DNS subscription must resolve to sub B (brownfield DNS zone subscription)."
  }

  assert {
    condition     = output.resolved_privatelink_dns_subscription_id == "BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBBBB"
    error_message = "After apply, privatelink DNS subscription must resolve to sub B (same as management DNS in this scenario)."
  }

  assert {
    condition     = output.resolved_deployer_subscription_id == "DDDDDDDD-DDDD-DDDD-DDDD-DDDDDDDDDDDD"
    error_message = "After apply, deployer subscription must resolve to sub D from remote state."
  }
}

run "apply_cross_sub_keyvault_reuse_with_brownfield_dns_zone" {
  command = apply

  variables {
    subscription_id                              = "AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA"
    management_dns_subscription_id               = "BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBBBB"
    privatelink_dns_subscription_id              = "BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBBBB"
    user_keyvault_id                             = "/subscriptions/CCCCCCCC-CCCC-CCCC-CCCC-CCCCCCCCCCCC/resourceGroups/rg-shared/providers/Microsoft.KeyVault/vaults/kv-user-shared"
    spn_keyvault_id                              = "/subscriptions/CCCCCCCC-CCCC-CCCC-CCCC-CCCCCCCCCCCC/resourceGroups/rg-shared/providers/Microsoft.KeyVault/vaults/kv-spn-shared"
    use_private_endpoint                         = true
    register_storage_accounts_keyvaults_with_dns = true
  }

  override_data {
    target = data.terraform_remote_state.deployer
    values = {
      outputs = {
        created_resource_group_subscription_id = "DDDDDDDD-DDDD-DDDD-DDDD-DDDDDDDDDDDD"
        environment                            = "DEV"
        additional_network_id                  = ""
        application_configuration_id           = ""
        control_plane_name                     = "DEV-WEEU-DEP00"
        deployer_kv_user_arm_id                = "/subscriptions/DDDDDDDD-DDDD-DDDD-DDDD-DDDDDDDDDDDD/resourceGroups/rg-mgmt/providers/Microsoft.KeyVault/vaults/kv-deployer"
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
        network_security_perimeter_id                         = ""
        subnet_bastion_address_prefixes                       = ["10.0.1.0/26"]
        subnet_mgmt_address_prefixes                          = ["10.0.0.0/24"]
        subnet_mgmt_id                                        = "/subscriptions/DDDDDDDD-DDDD-DDDD-DDDD-DDDDDDDDDDDD/resourceGroups/rg-mgmt/providers/Microsoft.Network/virtualNetworks/vnet-mgmt/subnets/snet-mgmt"
        subnets_to_add_to_firewall_for_key_vaults_and_storage = []
        vnet_mgmt_id                                          = "/subscriptions/DDDDDDDD-DDDD-DDDD-DDDD-DDDDDDDDDDDD/resourceGroups/rg-mgmt/providers/Microsoft.Network/virtualNetworks/vnet-mgmt"
      }
    }
  }

  override_data {
    target = module.sap_landscape.data.azurerm_key_vault.kv_user
    values = {
      id   = "/subscriptions/CCCCCCCC-CCCC-CCCC-CCCC-CCCCCCCCCCCC/resourceGroups/rg-shared/providers/Microsoft.KeyVault/vaults/kv-user-shared"
      name = "kv-user-shared"
    }
  }

  assert {
    condition     = output.landscape_key_vault_user_arm_id == "/subscriptions/CCCCCCCC-CCCC-CCCC-CCCC-CCCCCCCCCCCC/resourceGroups/rg-shared/providers/Microsoft.KeyVault/vaults/kv-user-shared"
    error_message = "After apply, user keyvault ARM ID must preserve the sub C prefix and not silently fall back."
  }

  assert {
    condition     = output.landscape_key_vault_spn_arm_id == "/subscriptions/CCCCCCCC-CCCC-CCCC-CCCC-CCCCCCCCCCCC/resourceGroups/rg-shared/providers/Microsoft.KeyVault/vaults/kv-spn-shared"
    error_message = "After apply, SPN keyvault ARM ID must preserve the sub C prefix from the explicit input."
  }

  assert {
    condition     = output.resolved_management_dns_subscription_id == "BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBBBB"
    error_message = "After apply, management DNS subscription must resolve to sub B (brownfield DNS zone)."
  }

  assert {
    condition     = output.resolved_management_dns_subscription_id != "CCCCCCCC-CCCC-CCCC-CCCC-CCCCCCCCCCCC"
    error_message = "After apply, DNS subscription (B) must not silently collapse to keyvault subscription (C)."
  }
}

run "apply_cross_sub_anf_with_multi_subscription_topology" {
  command = apply

  variables {
    subscription_id                              = "AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA"
    management_dns_subscription_id               = "BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBBBB"
    privatelink_dns_subscription_id              = "CCCCCCCC-CCCC-CCCC-CCCC-CCCCCCCCCCCC"
    user_keyvault_id                             = "/subscriptions/CCCCCCCC-CCCC-CCCC-CCCC-CCCCCCCCCCCC/resourceGroups/rg-shared/providers/Microsoft.KeyVault/vaults/kv-user"
    spn_keyvault_id                              = "/subscriptions/CCCCCCCC-CCCC-CCCC-CCCC-CCCCCCCCCCCC/resourceGroups/rg-shared/providers/Microsoft.KeyVault/vaults/kv-spn"
    NFS_provider                                 = "ANF"
    anf_subnet_arm_id                            = ""
    anf_subnet_nsg_arm_id                        = ""
    anf_subnet_address_prefix                    = "10.10.18.0/28"
    use_private_endpoint                         = true
    register_storage_accounts_keyvaults_with_dns = true
    peer_with_control_plane_vnet                 = true
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
  }

  override_data {
    target = data.terraform_remote_state.deployer
    values = {
      outputs = {
        created_resource_group_subscription_id = "DDDDDDDD-DDDD-DDDD-DDDD-DDDDDDDDDDDD"
        environment                            = "DEV"
        additional_network_id                  = "/subscriptions/DDDDDDDD-DDDD-DDDD-DDDD-DDDDDDDDDDDD/resourceGroups/rg-mgmt/providers/Microsoft.Network/virtualNetworks/vnet-agent"
        application_configuration_id           = ""
        control_plane_name                     = "DEV-WEEU-DEP00"
        deployer_kv_user_arm_id                = "/subscriptions/DDDDDDDD-DDDD-DDDD-DDDD-DDDDDDDDDDDD/resourceGroups/rg-mgmt/providers/Microsoft.KeyVault/vaults/kv-deployer"
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
        network_security_perimeter_id                         = ""
        subnet_bastion_address_prefixes                       = ["10.0.1.0/26"]
        subnet_mgmt_address_prefixes                          = ["10.0.0.0/24"]
        subnet_mgmt_id                                        = "/subscriptions/DDDDDDDD-DDDD-DDDD-DDDD-DDDDDDDDDDDD/resourceGroups/rg-mgmt/providers/Microsoft.Network/virtualNetworks/vnet-mgmt/subnets/snet-mgmt"
        subnets_to_add_to_firewall_for_key_vaults_and_storage = []
        vnet_mgmt_id                                          = "/subscriptions/DDDDDDDD-DDDD-DDDD-DDDD-DDDDDDDDDDDD/resourceGroups/rg-mgmt/providers/Microsoft.Network/virtualNetworks/vnet-mgmt"
      }
    }
  }

  override_data {
    target = module.sap_landscape.data.azurerm_key_vault.kv_user
    values = {
      id   = "/subscriptions/CCCCCCCC-CCCC-CCCC-CCCC-CCCCCCCCCCCC/resourceGroups/rg-shared/providers/Microsoft.KeyVault/vaults/kv-user"
      name = "kv-user"
    }
  }

  assert {
    condition     = output.ANF_pool_settings != null
    error_message = "After apply with NFS_provider=ANF, ANF_pool_settings output must be populated."
  }

  assert {
    condition     = output.vnet_sap_arm_id != ""
    error_message = "After apply with greenfield VNet, vnet_sap_arm_id must be a resolved non-empty string."
  }

  assert {
    condition     = output.resolved_management_dns_subscription_id == "BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBBBB"
    error_message = "After apply in ANF multi-sub topology, management DNS must resolve to sub B."
  }

  assert {
    condition     = output.resolved_privatelink_dns_subscription_id == "CCCCCCCC-CCCC-CCCC-CCCC-CCCCCCCCCCCC"
    error_message = "After apply in ANF multi-sub topology, privatelink DNS must resolve to sub C."
  }

  assert {
    condition     = output.resolved_deployer_subscription_id == "DDDDDDDD-DDDD-DDDD-DDDD-DDDDDDDDDDDD"
    error_message = "After apply in ANF multi-sub topology, deployer subscription must resolve to sub D."
  }

  assert {
    condition     = output.resolved_management_dns_subscription_id != output.resolved_privatelink_dns_subscription_id
    error_message = "After apply, management DNS (B) and privatelink DNS (C) subscriptions must remain distinct."
  }
}


run "apply_greenfield_admin_subnet_resolves_arm_id" {
  command = apply

  variables {
    network_arm_id              = ""
    admin_subnet_arm_id         = ""
    admin_subnet_address_prefix = "10.10.10.0/24"
    admin_subnet_nsg_arm_id     = ""
    db_subnet_arm_id            = ""
    db_subnet_nsg_arm_id        = ""
    db_subnet_address_prefix    = "10.10.11.0/24"
    app_subnet_arm_id           = ""
    app_subnet_nsg_arm_id       = ""
    app_subnet_address_prefix   = "10.10.12.0/24"
  }

  assert {
    condition     = output.admin_subnet_id != ""
    error_message = "After apply, greenfield admin subnet must produce a resolved non-empty ARM ID string."
  }

  assert {
    condition     = output.admin_nsg_id != ""
    error_message = "After apply, greenfield admin NSG must produce a resolved non-empty ARM ID string."
  }

  assert {
    condition     = output.vnet_sap_arm_id != ""
    error_message = "After apply, greenfield VNet must produce a resolved non-empty ARM ID string."
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
