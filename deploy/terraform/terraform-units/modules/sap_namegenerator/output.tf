output "naming" {
  value = {
    prefix = {
      DEPLOYER = trimspace(length(var.custom_prefix) > 0 ? var.custom_prefix : local.deployer_name)
      SDU      = trimspace(length(var.custom_prefix) > 0 ? var.custom_prefix : local.sdu_name)
      VNET     = trimspace(length(var.custom_prefix) > 0 ? var.custom_prefix : local.landscape_name)
      LIBRARY  = trimspace(length(var.custom_prefix) > 0 ? var.custom_prefix : local.library_name)
    }
    storageaccount_names = {
      DEPLOYER = local.deployer_storageaccount_name
      SDU      = local.sdu_storageaccount_name
      VNET = {
        landscape_storageaccount_name                   = local.landscape_storageaccount_name
        witness_storageaccount_name                     = local.witness_storageaccount_name
        landscape_shared_transport_storage_account_name = local.landscape_shared_transport_storage_account_name
      }

      LIBRARY = {
        library_storageaccount_name        = local.library_storageaccount_name
        terraformstate_storageaccount_name = local.terraformstate_storageaccount_name
      }
    }
    keyvault_names = {
      DEPLOYER = {
        private_access = local.deployer_private_keyvault_name
        user_access    = local.deployer_user_keyvault_name
      }
      LIBRARY = {
        private_access = local.library_private_keyvault_name
        user_access    = local.library_user_keyvault_name
      }
      SDU = {
        private_access = local.sdu_private_keyvault_name
        user_access    = local.sdu_user_keyvault_name
      }
      VNET = {
        private_access = local.landscape_private_keyvault_name
        user_access    = local.landscape_user_keyvault_name
      }
    }
    virtualmachine_names = {
      APP_COMPUTERNAME         = local.app_computer_names
      APP_SECONDARY_DNSNAME    = local.app_secondary_dnsnames
      APP_VMNAME               = local.app_server_vm_names
      ANCHOR_COMPUTERNAME      = local.anchor_computer_names
      ANCHOR_SECONDARY_DNSNAME = local.anchor_secondary_dnsnames
      ANCHOR_VMNAME            = local.anchor_vm_names
      ANYDB_COMPUTERNAME       = var.database_high_availability ? concat(local.anydb_computer_names, local.anydb_computer_names_ha) : local.anydb_computer_names
      ANYDB_SECONDARY_DNSNAME  = concat(local.anydb_secondary_dnsnames, local.anydb_secondary_dnsnames_ha)
      ANYDB_VMNAME             = var.database_high_availability ? concat(local.anydb_vm_names, local.anydb_vm_names_ha) : local.anydb_vm_names
      DEPLOYER                 = local.deployer_vm_names
      HANA_COMPUTERNAME        = var.database_high_availability ? concat(local.hana_computer_names, local.hana_computer_names_ha) : local.hana_computer_names
      HANA_SECONDARY_DNSNAME   = var.database_high_availability ? concat(local.hana_secondary_dnsnames, local.hana_secondary_dnsnames_ha) : local.hana_secondary_dnsnames
      HANA_VMNAME              = var.database_high_availability ? concat(local.hana_server_vm_names, local.hana_server_vm_names_ha) : local.hana_server_vm_names
      ISCSI_COMPUTERNAME       = local.iscsi_server_names
      OBSERVER_COMPUTERNAME    = local.observer_computer_names
      OBSERVER_VMNAME          = local.observer_vm_names
      SCS_COMPUTERNAME         = local.scs_computer_names
      SCS_SECONDARY_DNSNAME    = local.scs_secondary_dnsnames
      SCS_VMNAME               = local.scs_server_vm_names
      WEB_COMPUTERNAME         = local.web_computer_names
      WEB_SECONDARY_DNSNAME    = local.web_secondary_dnsnames
      WEB_VMNAME               = local.web_server_vm_names
    }

    ppg_names = local.ppg_names

    app_avset_names = local.app_avset_names
    scs_avset_names = local.scs_avset_names
    web_avset_names = local.web_avset_names
    db_avset_names  = local.db_avset_names

    resource_suffixes = var.resource_suffixes

    separator = length(var.custom_prefix) > 0 ? "" : local.separator
  }
}
