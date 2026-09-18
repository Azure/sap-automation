# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.
#
# Focused unit test for the sap_landscape module's tfvars storage container
# lookup and the blob resources that depend on it (outputs.tf).
#
# Zero real Azure API calls: every azurerm/azapi interaction is satisfied by
# mock_provider.

mock_provider "azurerm" {}

mock_provider "azurerm" {
  alias = "main"

  mock_data "azurerm_client_config" {
    defaults = {
      tenant_id       = "44444444-4444-4444-4444-444444444444"
      object_id       = "55555555-5555-5555-5555-555555555555"
      subscription_id = "33333333-3333-3333-3333-333333333333"
    }
  }
}

mock_provider "azurerm" {
  alias = "dnsmanagement"
}

mock_provider "azurerm" {
  alias = "privatelinkdnsmanagement"
}

mock_provider "azurerm" {
  alias = "peering"
}

mock_provider "azurerm" {
  alias = "deployer"

  mock_data "azurerm_storage_container" {
    defaults = {
      id = "/subscriptions/33333333-3333-3333-3333-333333333333/resourceGroups/rg-tfstate/providers/Microsoft.Storage/storageAccounts/sttfstate001/blobServices/default/containers/tfvars"
    }
  }
}

mock_provider "azapi" {
  alias = "api"
}

variables {
  infrastructure = {
    environment                    = "DEV"
    region                         = "westeurope"
    codename                       = ""
    additional_network_id          = ""
    additional_subnet_id           = ""
    deploy_defender_extension      = false
    deploy_monitoring_extension    = false
    encryption_at_host_enabled     = false
    patch_assessment_mode          = "ImageDefault"
    patch_mode                     = "ImageDefault"
    shared_access_key_enabled      = true
    shared_access_key_enabled_nfs  = true
    user_assigned_identity_id      = ""
    iscsi                          = {
      iscsi_count = 0
      size        = "Standard_D2s_v3"
      os          = {}
      authentication = { type = "key", username = "azureadm" }
      iscsi_nic_ips = []
    }
    tags                           = {}
    terraform_storage_account_id   = "/subscriptions/33333333-3333-3333-3333-333333333333/resourceGroups/rg-tfstate/providers/Microsoft.Storage/storageAccounts/sttfstate001"
    terraform_storage_account_name = "sttfstate001"
    control_plane_name             = "DEV-WEEU-DEP01"
    workload_zone_name             = "DEV-WEEU-SAP01"
    application_configuration_id   = ""
    use_application_configuration  = false
    ams_instance                   = {
      name                = ""
      create_ams_instance = false
      ams_laws_id         = ""
    }
    nat_gateway                    = {
      create_nat_gateway      = false
      name                    = ""
      id                      = ""
      region                  = "westeurope"
      public_ip_zones         = ["1", "2", "3"]
      public_ip_id            = ""
      idle_timeout_in_minutes = 4
      ip_tags                 = {}
    }
    resource_group                 = {
      name = "DEV-WEEU-SAP01-INFRASTRUCTURE"
      id   = ""
    }
    virtual_networks = {
      sap = {
        name                     = "SAP01"
        logical_name             = "SAP01"
        id                       = ""
        exists                   = false
        address_space            = ["10.9.0.0/16"]
        flow_timeout_in_minutes  = null
        enable_route_propagation = false
        subnet_admin = {
          name    = ""
          id      = ""
          prefix  = "10.9.0.0/26"
          defined = true
          exists  = false
          nsg     = { name = "", id = "", exists = false }
        }
        subnet_db = {
          name    = ""
          id      = ""
          prefix  = "10.9.1.0/26"
          defined = true
          exists  = false
          nsg     = { name = "", id = "", exists = false }
        }
        subnet_app = {
          name    = ""
          id      = ""
          prefix  = "10.9.2.0/26"
          defined = true
          exists  = false
          nsg     = { name = "", id = "", exists = false }
        }
        subnet_web = {
          name    = ""
          id      = ""
          prefix  = "10.9.3.0/26"
          defined = true
          exists  = false
          nsg     = { name = "", id = "", exists = false }
        }
        subnet_storage = {
          name    = ""
          id      = ""
          prefix  = ""
          defined = false
          exists  = false
          nsg     = { name = "", id = "", exists = false }
        }
        subnet_anf = {
          name    = ""
          id      = ""
          prefix  = ""
          defined = false
          exists  = false
          nsg     = { name = "", id = "", exists = false }
        }
        subnet_ams = {
          name    = ""
          id      = ""
          prefix  = ""
          defined = false
          exists  = false
          nsg     = { name = "", id = "", exists = false }
        }
        subnet_iscsi = {
          name    = ""
          id      = ""
          prefix  = ""
          defined = false
          exists  = false
          nsg     = { name = "", id = "", exists = false }
        }
      }
    }
  }

  deployer_tfstate                             = {
    application_configuration_id                         = ""
    deployer_kv_user_arm_id                              = ""
    deployer_kv_user_name                                = ""
    deployer_public_ip_address                           = ""
    deployer_uai                                         = { principal_id = "", id = "" }
    firewall_id                                          = ""
    firewall_ip                                          = ""
    network_security_access_mode                         = "Learning"
    network_security_perimeter_deployment                = false
    network_security_perimeter_id                        = ""
    subnet_bastion_address_prefixes                      = []
    subnet_mgmt_address_prefixes                         = []
    subnet_mgmt_id                                       = ""
    subnets_to_add_to_firewall_for_key_vaults_and_storage = []
    vnet_mgmt_id                                         = ""
  }
  use_deployer     = false

  options                                      = {
    zones                     = []
    user_assigned_identity_id = ""
    assign_permissions        = false
    use_spn                   = false
    spn_id                    = ""
  }
  additional_users_to_add_to_keyvault_policies = []
  keyvault_private_endpoint_id                 = ""
  create_transport_storage                     = false
  transport_volume_size                        = 128
  install_volume_size                          = 128
  transport_storage_account_id                 = ""
  transport_private_endpoint_id                = ""
  install_storage_account_id                   = ""
  install_private_endpoint_id                  = ""
  install_always_create_fileshares             = false
  terraform_template_version                   = "3.0.0"
  place_delete_lock_on_resources               = false
  dns_settings                                 = {
    use_custom_dns_a_registration                = false
    dns_label                                    = ""
    dns_server_list                              = []
    dns_zone_names                               = {
      "file_dns_zone_name"      = "privatelink.file.core.windows.net"
      "blob_dns_zone_name"      = "privatelink.blob.core.windows.net"
      "table_dns_zone_name"     = "privatelink.table.core.windows.net"
      "vault_dns_zone_name"     = "privatelink.vaultcore.azure.net"
      "appconfig_dns_zone_name" = "privatelink.azconfig.io"
    }
    management_dns_resourcegroup_name            = "rg-tfstate"
    management_dns_subscription_id               = "33333333-3333-3333-3333-333333333333"
    privatelink_dns_resourcegroup_name           = "rg-tfstate"
    privatelink_dns_subscription_id              = "33333333-3333-3333-3333-333333333333"
    register_storage_accounts_keyvaults_with_dns = false
    register_endpoints_with_dns                  = false
    register_virtual_network_to_dns              = false
  }
  key_vault                                    = {
    user                      = { id = "", exists = false }
    spn                       = { id = "", exists = false }
    private_key_secret_name   = ""
    public_key_secret_name    = ""
    username_secret_name      = ""
    password_secret_name      = ""
    enable_rbac_authorization = false
    set_secret_expiry         = false
    exists                    = false
    enable_purge_control      = false
    soft_delete_retention_days = 7
  }
  witness_storage_account                      = { arm_id = "", id = "" }
  diagnostics_storage_account                  = { arm_id = "", id = "" }
  NFS_provider                                 = "NONE"
  peer_with_control_plane_vnet                 = false
  enable_firewall_for_keyvaults_and_storage    = false
  public_network_access_enabled                = true
  tags                                         = {}
  vm_settings                                  = {
    count             = 0
    image             = { os_type = "LINUX" }
    size              = ""
    disk_type         = "Premium_LRS"
    disk_size         = 128
    use_DHCP          = true
    private_ip_address = ""
    zones             = []
  }

  # Mirrors the sap_namegenerator output shape for the keys this module reads.
  naming = {
    separator            = "-"
    prefix               = {
      WORKLOAD_ZONE = "DEV-WEEU-SAP01"
      SDU           = "DEV-WEEU-SAP01-X00"
    }
    keyvault_names       = {
      WORKLOAD_ZONE = {
        private_access = "DEVWEEUSAP01userABC"
        user_access    = "DEVWEEUSAP01userABC"
      }
      SDU           = {
        private_access = "DEVWEEUX00userABC"
        user_access    = "DEVWEEUX00userABC"
      }
    }
    storageaccount_names = {
      WORKLOAD_ZONE = {
        landscape_storageaccount_name                   = "devweeusap01diag"
        witness_storageaccount_name                     = "devweeusap01witness"
        landscape_shared_transport_storage_account_name = "devweeusap01transport"
        landscape_shared_install_storage_account_name   = "devweeusap01install"
        landscape_utility_storage_account_names         = ["devweeusap01util"]
      }
    }
    virtualmachine_names = {
      ISCSI_COMPUTERNAME = []
      WORKLOAD_VMNAME    = []
    }
    resource_prefixes    = {
      "admin_subnet"                      = ""
      "admin_subnet_nsg"                  = ""
      "ams_subnet"                        = ""
      "anf_subnet"                        = ""
      "anf_subnet_nsg"                    = ""
      "app_subnet"                        = ""
      "app_subnet_nsg"                    = ""
      "db_subnet"                         = ""
      "db_subnet_nsg"                     = ""
      "dns_link"                          = ""
      "fw_route"                          = ""
      "install_volume"                    = ""
      "iscsi_subnet"                      = ""
      "iscsi_subnet_nsg"                  = ""
      "keyvault_private_link"             = ""
      "keyvault_private_svc"              = ""
      "nat_gateway"                       = ""
      "netapp_account"                    = ""
      "netapp_pool"                       = ""
      "nic"                               = ""
      "osdisk"                            = ""
      "routetable"                        = ""
      "storage_private_link_diag"         = ""
      "storage_private_link_install"      = ""
      "storage_private_link_transport"    = ""
      "storage_private_link_utility_blob" = ""
      "storage_private_link_utility_file" = ""
      "storage_private_link_witness"      = ""
      "storage_private_svc_diag"          = ""
      "storage_private_svc_install"       = ""
      "storage_private_svc_transport"     = ""
      "storage_private_svc_utility_blob"  = ""
      "storage_private_svc_utility_file"  = ""
      "storage_private_svc_witness"       = ""
      "storage_subnet"                    = ""
      "storage_subnet_nsg"                = ""
      "transport_volume"                  = ""
      "vm"                                = ""
      "vnet"                              = ""
      "vnet_rg"                           = ""
      "web_subnet"                        = ""
      "web_subnet_nsg"                    = ""
    }
    resource_suffixes    = {
      "admin_subnet"                      = "admin-subnet"
      "admin_subnet_nsg"                  = "adminSubnet-nsg"
      "ams_instance"                      = "-AMS"
      "ams_subnet"                        = "ams-subnet"
      "anf_subnet"                        = "anf-subnet"
      "anf_subnet_nsg"                    = "anfSubnet-nsg"
      "app_subnet"                        = "app-subnet"
      "app_subnet_nsg"                    = "appSubnet-nsg"
      "db_subnet"                         = "db-subnet"
      "db_subnet_nsg"                     = "dbSubnet-nsg"
      "dns_link"                          = "dns-link"
      "fw_route"                          = "firewall-route"
      "install_volume"                    = "install"
      "install_volume_smb"                = "install-smb"
      "iscsi_subnet"                      = "iscsi-subnet"
      "iscsi_subnet_nsg"                  = "iscsiSubnet-nsg"
      "keyvault_private_link"             = "-keyvault-private-endpoint"
      "keyvault_private_svc"              = "-keyvault-private-service"
      "nat_gateway"                       = "-nat-gateway"
      "netapp_account"                    = "netapp_account"
      "netapp_pool"                       = "netapp_pool"
      "nic"                               = "-nic"
      "osdisk"                            = "-OsDisk"
      "routetable"                        = "route-table"
      "storage_private_link_diag"         = "-diag-storage-private-endpoint"
      "storage_private_link_install"      = "-install-storage-private-endpoint"
      "storage_private_link_transport"    = "-transport-storage-private-endpoint"
      "storage_private_link_utility_blob" = "-utility-blob-storage-private-endpoint"
      "storage_private_link_utility_file" = "-utility-file-storage-private-endpoint"
      "storage_private_link_witness"      = "-witness-storage-private-endpoint"
      "storage_private_svc_diag"          = "-diag-storage-private-service"
      "storage_private_svc_install"       = "-install-storage-private-service"
      "storage_private_svc_transport"     = "-transport-storage-private-service"
      "storage_private_svc_utility_blob"  = "-utility-blob-storage-private-service"
      "storage_private_svc_utility_file"  = "-utility-file-storage-private-service"
      "storage_private_svc_witness"       = "-witness-storage-private-service"
      "storage_subnet"                    = "storage-subnet"
      "storage_subnet_nsg"                = "storageSubnet-nsg"
      "transport_volume"                  = "transport"
      "vm"                                = ""
      "vnet"                              = "-vnet"
      "vnet_rg"                           = "-INFRASTRUCTURE"
      "web_subnet"                        = "web-subnet"
      "web_subnet_nsg"                    = "webSubnet-nsg"
      "witness_accesskey"                 = "-witness-accesskey"
    }
  }
}

run "tfvars_container_lookup_uses_terraform_storage_account_id" {
  command = plan


  providers = {
    azurerm                          = azurerm
    azurerm.main                     = azurerm.main
    azurerm.deployer                 = azurerm.deployer
    azurerm.dnsmanagement            = azurerm.dnsmanagement
    azurerm.privatelinkdnsmanagement = azurerm.privatelinkdnsmanagement
    azurerm.peering                  = azurerm.peering
    azapi.api                        = azapi.api
  }

  assert {
    condition     = data.azurerm_storage_container.tfvars.storage_account_id == var.infrastructure.terraform_storage_account_id
    error_message = "The tfvars container lookup must use infrastructure.terraform_storage_account_id as the storage account id."
  }

  assert {
    condition     = azurerm_storage_blob.readme.storage_container_id == data.azurerm_storage_container.tfvars.id
    error_message = "The readme blob must be attached to the tfvars container data source id."
  }

  assert {
    condition     = azurerm_storage_blob.tfvars.storage_container_id == data.azurerm_storage_container.tfvars.id
    error_message = "The tfvars blob must be attached to the tfvars container data source id."
  }
}
