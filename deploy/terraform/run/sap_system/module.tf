
#########################################################################################
#                                                                                       #
#  Name generator                                                                       #
#                                                                                       #
#########################################################################################

module "sap_namegenerator" {
  source        = "../../terraform-units/modules/sap_namegenerator"
  environment   = local.infrastructure.environment
  location      = local.infrastructure.region
  codename      = lower(try(local.infrastructure.codename, ""))
  random_id     = module.common_infrastructure.random_id
  sap_vnet_name = local.vnet_logical_name
  sap_sid       = local.sap_sid
  db_sid        = local.db_sid
  web_sid       = local.web_sid

  app_ostype    = upper(try(local.application_tier.app_os.os_type, "LINUX"))
  anchor_ostype = upper(try(local.anchor_vms.os.os_type, "LINUX"))
  db_ostype     = upper(try(local.database.os.os_type, "LINUX"))

  db_server_count  = var.database_server_count
  app_server_count = try(local.application_tier.application_server_count, 0)
  web_server_count = try(local.application_tier.webdispatcher_count, 0)
  scs_server_count = local.application_tier.scs_high_availability ? (
    2 * local.application_tier.scs_server_count) : (
    local.application_tier.scs_server_count
  )

  app_zones = try(local.application_tier.app_zones, [])
  scs_zones = try(local.application_tier.scs_zones, [])
  web_zones = try(local.application_tier.web_zones, [])
  db_zones  = try(local.database.zones, [])

  resource_offset            = try(var.resource_offset, 0)
  custom_prefix              = var.custom_prefix
  database_high_availability = local.database.high_availability
  scs_high_availability      = local.application_tier.scs_high_availability
  use_zonal_markers          = var.use_zonal_markers
}

#########################################################################################
#                                                                                       #
#  Common Infrastructure                                                                #
#                                                                                       #
#########################################################################################

module "common_infrastructure" {
  source = "../../terraform-units/modules/sap_system/common_infrastructure"
  providers = {
    azurerm.deployer      = azurerm
    azurerm.main          = azurerm.system
    azurerm.dnsmanagement = azurerm.dnsmanagement
  }
  is_single_node_hana                = "true"
  application_tier                   = local.application_tier
  database                           = local.database
  infrastructure                     = local.infrastructure
  options                            = local.options
  key_vault                          = local.key_vault
  naming                             = length(var.name_override_file) > 0 ? local.custom_names : module.sap_namegenerator.naming
  service_principal                  = var.use_spn ? local.service_principal : local.account
  deployer_tfstate                   = length(var.deployer_tfstate_key) > 0 ? data.terraform_remote_state.deployer[0].outputs : null
  landscape_tfstate                  = data.terraform_remote_state.landscape.outputs
  custom_disk_sizes_filename         = try(coalesce(var.custom_disk_sizes_filename, var.db_disk_sizes_filename), "")
  authentication                     = local.authentication
  terraform_template_version         = var.terraform_template_version
  deployment                         = var.deployment
  license_type                       = var.license_type
  enable_purge_control_for_keyvaults = var.enable_purge_control_for_keyvaults
  sapmnt_volume_size                 = var.sapmnt_volume_size
  NFS_provider                       = var.NFS_provider
  custom_prefix                      = var.use_prefix ? var.custom_prefix : " "
  ha_validator = format("%d%d-%s",
    local.application_tier.scs_high_availability ? 1 : 0,
    local.database.high_availability ? 1 : 0,
    upper(try(local.application_tier.app_os.os_type, "LINUX")) == "LINUX" ? var.NFS_provider : "WINDOWS"
  )
  Agent_IP             = var.Agent_IP
  use_private_endpoint = var.use_private_endpoint

  use_custom_dns_a_registration     = try(data.terraform_remote_state.landscape.outputs.use_custom_dns_a_registration, true)
  management_dns_subscription_id    = try(data.terraform_remote_state.landscape.outputs.management_dns_subscription_id, null)
  management_dns_resourcegroup_name = coalesce(data.terraform_remote_state.landscape.outputs.management_dns_resourcegroup_name, local.saplib_resource_group_name)

  database_dual_nics = var.database_dual_nics

  azure_files_sapmnt_id             = var.azure_files_sapmnt_id
  use_random_id_for_storageaccounts = var.use_random_id_for_storageaccounts

  hana_ANF_volumes                   = local.hana_ANF_volumes
  sapmnt_private_endpoint_id         = var.sapmnt_private_endpoint_id
  deploy_application_security_groups = var.deploy_application_security_groups
  use_service_endpoint               = var.use_service_endpoint

  use_scalesets_for_deployment = var.use_scalesets_for_deployment

}


#########################################################################################
#                                                                                       #
#  HANA Infrastructure                                                                  #
#                                                                                       #
#########################################################################################

module "hdb_node" {
  source = "../../terraform-units/modules/sap_system/hdb_node"
  providers = {
    azurerm.deployer      = azurerm
    azurerm.main          = azurerm.system
    azurerm.dnsmanagement = azurerm.dnsmanagement
    azapi.api             = azapi.api

  }

  depends_on = [module.common_infrastructure]
  order_deployment = local.enable_db_deployment ? (
    local.db_zonal_deployment && local.application_tier.enable_deployment ? (
      try(module.app_tier.scs_vm_ids[0], null)
    ) : (null)
  ) : (null)
  database                                     = local.database
  infrastructure                               = local.infrastructure
  options                                      = local.options
  resource_group                               = module.common_infrastructure.resource_group
  storage_bootdiag_endpoint                    = module.common_infrastructure.storage_bootdiag_endpoint
  ppg                                          = module.common_infrastructure.ppg
  sid_keyvault_user_id                         = module.common_infrastructure.sid_keyvault_user_id
  naming                                       = length(var.name_override_file) > 0 ? local.custom_names : module.sap_namegenerator.naming
  custom_disk_sizes_filename                   = try(coalesce(var.custom_disk_sizes_filename, var.db_disk_sizes_filename), "")
  admin_subnet                                 = module.common_infrastructure.admin_subnet
  db_subnet                                    = module.common_infrastructure.db_subnet
  storage_subnet                               = module.common_infrastructure.storage_subnet
  anchor_vm                                    = module.common_infrastructure.anchor_vm // Workaround to create dependency from anchor to db to app
  sid_password                                 = module.common_infrastructure.sid_password
  sid_username                                 = module.common_infrastructure.sid_username
  sdu_public_key                               = module.common_infrastructure.sdu_public_key
  sap_sid                                      = local.sap_sid
  db_asg_id                                    = module.common_infrastructure.db_asg_id
  terraform_template_version                   = var.terraform_template_version
  deployment                                   = var.deployment
  cloudinit_growpart_config                    = null # This needs more consideration module.common_infrastructure.cloudinit_growpart_config
  license_type                                 = var.license_type
  use_loadbalancers_for_standalone_deployments = var.use_loadbalancers_for_standalone_deployments
  database_dual_nics                           = try(module.common_infrastructure.admin_subnet, null) == null ? false : var.database_dual_nics
  database_vm_db_nic_ips                       = var.database_vm_db_nic_ips
  database_vm_db_nic_secondary_ips             = var.database_vm_db_nic_secondary_ips
  database_vm_admin_nic_ips                    = var.database_vm_admin_nic_ips
  database_vm_storage_nic_ips                  = var.database_vm_storage_nic_ips
  database_server_count = upper(try(local.database.platform, "HANA")) == "HANA" ? (
    local.database.high_availability ? (
      2 * var.database_server_count) : (
      var.database_server_count
    )) : (
    0
  )
  landscape_tfstate                  = data.terraform_remote_state.landscape.outputs
  hana_ANF_volumes                   = local.hana_ANF_volumes
  NFS_provider                       = var.NFS_provider
  use_secondary_ips                  = var.use_secondary_ips
  deploy_application_security_groups = var.deploy_application_security_groups
  use_msi_for_clusters               = var.use_msi_for_clusters
  fencing_role_name                  = var.fencing_role_name

  use_custom_dns_a_registration     = data.terraform_remote_state.landscape.outputs.use_custom_dns_a_registration
  management_dns_subscription_id    = try(data.terraform_remote_state.landscape.outputs.management_dns_subscription_id, null)
  management_dns_resourcegroup_name = coalesce(data.terraform_remote_state.landscape.outputs.management_dns_resourcegroup_name, local.saplib_resource_group_name)

  use_scalesets_for_deployment = var.use_scalesets_for_deployment
  scale_set_id                 = try(module.common_infrastructure.scale_set_id, null)

  database_use_premium_v2_storage = var.database_use_premium_v2_storage

}


#########################################################################################
#                                                                                       #
#  App Tier Infrastructure                                                              #
#                                                                                       #
#########################################################################################

module "app_tier" {
  source = "../../terraform-units/modules/sap_system/app_tier"
  providers = {
    azurerm.deployer      = azurerm
    azurerm.main          = azurerm.system
    azurerm.dnsmanagement = azurerm.dnsmanagement
  }
  depends_on       = [module.common_infrastructure]
  order_deployment = null

  application_tier = local.application_tier
  sap_sid          = local.sap_sid
  infrastructure   = local.infrastructure
  options          = local.options

  custom_disk_sizes_filename = try(coalesce(var.custom_disk_sizes_filename, var.app_disk_sizes_filename), "")

  resource_group            = module.common_infrastructure.resource_group
  storage_bootdiag_endpoint = module.common_infrastructure.storage_bootdiag_endpoint
  ppg                       = module.common_infrastructure.ppg
  sid_keyvault_user_id      = module.common_infrastructure.sid_keyvault_user_id
  naming                    = length(var.name_override_file) > 0 ? local.custom_names : module.sap_namegenerator.naming
  network_location          = module.common_infrastructure.network_location
  network_resource_group    = module.common_infrastructure.network_resource_group
  admin_subnet              = module.common_infrastructure.admin_subnet
  use_secondary_ips         = var.use_secondary_ips

  sid_password   = module.common_infrastructure.sid_password
  sid_username   = module.common_infrastructure.sid_username
  sdu_public_key = module.common_infrastructure.sdu_public_key

  route_table_id                               = module.common_infrastructure.route_table_id
  firewall_id                                  = module.common_infrastructure.firewall_id
  landscape_tfstate                            = data.terraform_remote_state.landscape.outputs
  deployment                                   = var.deployment
  cloudinit_growpart_config                    = null # This needs more consideration module.common_infrastructure.cloudinit_growpart_config
  license_type                                 = var.license_type
  use_loadbalancers_for_standalone_deployments = var.use_loadbalancers_for_standalone_deployments
  idle_timeout_scs_ers                         = var.idle_timeout_scs_ers
  deploy_application_security_groups           = var.deploy_application_security_groups
  terraform_template_version                   = var.terraform_template_version

  fencing_role_name = var.fencing_role_name

  use_custom_dns_a_registration     = data.terraform_remote_state.landscape.outputs.use_custom_dns_a_registration
  management_dns_subscription_id    = try(data.terraform_remote_state.landscape.outputs.management_dns_subscription_id, null)
  management_dns_resourcegroup_name = coalesce(data.terraform_remote_state.landscape.outputs.management_dns_resourcegroup_name, local.saplib_resource_group_name)

  use_msi_for_clusters = var.use_msi_for_clusters
  scs_shared_disk_lun  = var.scs_shared_disk_lun
  scs_shared_disk_size = var.scs_shared_disk_size

  use_scalesets_for_deployment = var.use_scalesets_for_deployment
  scale_set_id                 = try(module.common_infrastructure.scale_set_id, null)
}

#########################################################################################
#                                                                                       #
#  AnyDB Infrastructure                                                                 #
#                                                                                       #
#########################################################################################

module "anydb_node" {
  source = "../../terraform-units/modules/sap_system/anydb_node"
  providers = {
    azurerm.deployer      = azurerm
    azurerm.main          = azurerm.system
    azurerm.dnsmanagement = azurerm.dnsmanagement
  }
  depends_on = [module.common_infrastructure]
  order_deployment = local.enable_db_deployment ? (
    local.db_zonal_deployment && local.application_tier.enable_deployment ? (
      try(module.app_tier.scs_vm_ids[0], null)
    ) : (null)
  ) : (null)
  database                                     = local.database
  infrastructure                               = local.infrastructure
  options                                      = local.options
  resource_group                               = module.common_infrastructure.resource_group
  storage_bootdiag_endpoint                    = module.common_infrastructure.storage_bootdiag_endpoint
  ppg                                          = module.common_infrastructure.ppg
  landscape_tfstate                            = data.terraform_remote_state.landscape.outputs
  sid_keyvault_user_id                         = module.common_infrastructure.sid_keyvault_user_id
  naming                                       = length(var.name_override_file) > 0 ? local.custom_names : module.sap_namegenerator.naming
  custom_disk_sizes_filename                   = try(coalesce(var.custom_disk_sizes_filename, var.db_disk_sizes_filename), "")
  admin_subnet                                 = try(module.common_infrastructure.admin_subnet, null)
  db_subnet                                    = module.common_infrastructure.db_subnet
  anchor_vm                                    = module.common_infrastructure.anchor_vm // Workaround to create dependency from anchor to db to app
  sid_password                                 = module.common_infrastructure.sid_password
  sid_username                                 = module.common_infrastructure.sid_username
  sdu_public_key                               = module.common_infrastructure.sdu_public_key
  sap_sid                                      = local.sap_sid
  db_asg_id                                    = module.common_infrastructure.db_asg_id
  terraform_template_version                   = var.terraform_template_version
  deployment                                   = var.deployment
  cloudinit_growpart_config                    = null # This needs more consideration module.common_infrastructure.cloudinit_growpart_config
  license_type                                 = var.license_type
  use_loadbalancers_for_standalone_deployments = var.use_loadbalancers_for_standalone_deployments
  database_vm_db_nic_ips                       = var.database_vm_db_nic_ips
  database_vm_db_nic_secondary_ips             = var.database_vm_db_nic_secondary_ips
  database_vm_admin_nic_ips                    = var.database_vm_admin_nic_ips
  database_server_count = upper(try(local.database.platform, "HANA")) == "HANA" ? (
    0) : (
    local.database.high_availability ? 2 * var.database_server_count : var.database_server_count
  )
  use_observer                       = var.use_observer
  use_secondary_ips                  = var.use_secondary_ips
  deploy_application_security_groups = var.deploy_application_security_groups
  use_msi_for_clusters               = var.use_msi_for_clusters
  fencing_role_name                  = var.fencing_role_name

  use_custom_dns_a_registration     = data.terraform_remote_state.landscape.outputs.use_custom_dns_a_registration
  management_dns_subscription_id    = try(data.terraform_remote_state.landscape.outputs.management_dns_subscription_id, null)
  management_dns_resourcegroup_name = coalesce(data.terraform_remote_state.landscape.outputs.management_dns_resourcegroup_name, local.saplib_resource_group_name)

  use_scalesets_for_deployment = var.use_scalesets_for_deployment
  scale_set_id                 = try(module.common_infrastructure.scale_set_id, null)
}

#########################################################################################
#                                                                                       #
#  Output files                                                                         #
#                                                                                       #
#########################################################################################

module "output_files" {
  depends_on = [module.anydb_node, module.common_infrastructure, module.app_tier, module.hdb_node]
  source     = "../../terraform-units/modules/sap_system/output_files"
  providers = {
    azurerm.deployer      = azurerm
    azurerm.main          = azurerm.system
    azurerm.dnsmanagement = azurerm.dnsmanagement
  }
  database            = local.database
  infrastructure      = local.infrastructure
  authentication      = local.authentication
  authentication_type = try(local.application_tier.authentication.type, "key")
  tfstate_resource_id = var.tfstate_resource_id
  landscape_tfstate   = data.terraform_remote_state.landscape.outputs
  naming = length(var.name_override_file) > 0 ? (
    local.custom_names) : (
    module.sap_namegenerator.naming
  )
  save_naming_information = var.save_naming_information
  configuration_settings  = var.configuration_settings
  random_id               = module.common_infrastructure.random_id

  #########################################################################################
  #  Database tier                                                                        #
  #########################################################################################

  nics_anydb_admin   = module.anydb_node.nics_anydb_admin
  nics_dbnodes_admin = module.hdb_node.nics_dbnodes_admin
  db_server_ips = upper(try(local.database.platform, "HANA")) == "HANA" ? (module.hdb_node.db_server_ips
    ) : (module.anydb_node.db_server_ips
  )
  db_server_secondary_ips = upper(try(local.database.platform, "HANA")) == "HANA" ? (module.hdb_node.db_server_secondary_ips
    ) : (module.anydb_node.db_server_secondary_ips
  )
  disks = distinct(compact(concat(module.hdb_node.dbtier_disks,
    module.anydb_node.dbtier_disks,
    module.app_tier.apptier_disks
  )))

  anydb_loadbalancers = module.anydb_node.anydb_loadbalancers
  loadbalancers       = module.hdb_node.loadbalancers

  db_ha = upper(try(local.database.platform, "HANA")) == "HANA" ? (
    module.hdb_node.db_ha) : (
    module.anydb_node.db_ha
  )
  db_lb_ip = upper(try(local.database.platform, "HANA")) == "HANA" ? (
    module.hdb_node.db_lb_ip[0]) : (
    module.anydb_node.db_lb_ip[0]
  )
  database_admin_ips = upper(try(local.database.platform, "HANA")) == "HANA" ? (
    module.hdb_node.db_admin_ip) : (
    module.anydb_node.anydb_admin_ip
  ) #TODO Change to use Admin IP

  db_auth_type = try(local.database.authentication.type, "key")

  db_clst_lb_ip = module.anydb_node.db_clst_lb_ip

  db_subnet_netmask = module.common_infrastructure.db_subnet_netmask

  #########################################################################################
  #  SAP Application information                                                          #
  #########################################################################################

  sap_sid             = local.sap_sid
  db_sid              = local.db_sid
  bom_name            = var.bom_name
  platform            = upper(try(local.database.platform, "HANA"))
  web_sid             = var.web_sid
  web_instance_number = var.web_instance_number

  observer_ips = module.anydb_node.observer_ips
  observer_vms = module.anydb_node.observer_vms

  #########################################################################################
  #  Application tier                                                                     #
  #########################################################################################

  app_tier_os_types    = module.app_tier.app_tier_os_types
  use_secondary_ips    = var.use_secondary_ips
  use_msi_for_clusters = var.use_msi_for_clusters

  scs_server_ips           = module.app_tier.scs_server_ips
  scs_server_secondary_ips = module.app_tier.scs_server_secondary_ips
  nics_scs_admin           = module.app_tier.nics_scs_admin
  scs_instance_number      = var.scs_instance_number
  ers_instance_number      = var.ers_instance_number

  application_server_ips           = module.app_tier.application_server_ips
  application_server_secondary_ips = module.app_tier.application_server_secondary_ips
  nics_app_admin                   = module.app_tier.nics_app_admin
  pas_instance_number              = var.pas_instance_number

  webdispatcher_server_ips           = module.app_tier.webdispatcher_server_ips
  webdispatcher_server_secondary_ips = module.app_tier.webdispatcher_server_secondary_ips
  nics_web_admin                     = module.app_tier.nics_web_admin

  scs_ha                = module.app_tier.scs_ha
  scs_lb_ip             = module.app_tier.scs_lb_ip
  ers_lb_ip             = module.app_tier.ers_lb_ip
  scs_clst_lb_ip        = module.app_tier.cluster_lb_ip
  app_subnet_netmask    = module.app_tier.app_subnet_netmask
  use_local_credentials = module.common_infrastructure.use_local_credentials

  sid_keyvault_user_id = module.common_infrastructure.sid_keyvault_user_id
  ansible_user         = module.common_infrastructure.sid_username

  #########################################################################################
  #  Mounting information                                                                 #
  #########################################################################################

  NFS_provider  = var.NFS_provider
  sap_mnt       = module.common_infrastructure.sapmnt_path
  sap_transport = try(data.terraform_remote_state.landscape.outputs.saptransport_path, "")
  install_path  = try(data.terraform_remote_state.landscape.outputs.install_path, "")

  shared_home = var.shared_home
  hana_data   = [module.hdb_node.hana_data_primary, module.hdb_node.hana_data_secondary]
  hana_log    = [module.hdb_node.hana_log_primary, module.hdb_node.hana_log_secondary]
  hana_shared = [module.hdb_node.hana_shared_primary, module.hdb_node.hana_shared_secondary]
  usr_sap     = module.common_infrastructure.usrsap_path

  #########################################################################################
  #  DNS information                                                                      #
  #########################################################################################
  dns                               = try(data.terraform_remote_state.landscape.outputs.dns_label, "")
  use_custom_dns_a_registration     = data.terraform_remote_state.landscape.outputs.use_custom_dns_a_registration
  management_dns_subscription_id    = try(data.terraform_remote_state.landscape.outputs.management_dns_subscription_id, null)
  management_dns_resourcegroup_name = coalesce(data.terraform_remote_state.landscape.outputs.management_dns_resourcegroup_name, local.saplib_resource_group_name)


  #########################################################################################
  #  Server counts                                                                        #
  #########################################################################################

  db_server_count  = var.database_server_count
  app_server_count = try(local.application_tier.application_server_count, 0)
  web_server_count = try(local.application_tier.webdispatcher_count, 0)
  scs_server_count = local.application_tier.scs_high_availability ? (
    2 * local.application_tier.scs_server_count) : (
    local.application_tier.scs_server_count
  )

}
