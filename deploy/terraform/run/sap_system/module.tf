
#########################################################################################
#                                                                                       #
#  Name generator                                                                       #
#                                                                                       #
#########################################################################################

module "sap_namegenerator" {
  source           = "../../terraform-units/modules/sap_namegenerator"
  environment      = local.infrastructure.environment
  location         = local.infrastructure.region
  codename         = lower(try(local.infrastructure.codename, ""))
  random_id        = module.common_infrastructure.random_id
  sap_vnet_name    = local.vnet_logical_name
  sap_sid          = local.sap_sid
  db_sid           = local.db_sid
  app_ostype       = upper(try(local.application_tier.app_os.os_type, "LINUX"))
  anchor_ostype    = upper(try(local.anchor_vms.os.os_type, "LINUX"))
  db_ostype        = upper(try(local.database.os.os_type, "LINUX"))
  db_server_count  = var.database_server_count
  app_server_count = try(local.application_tier.application_server_count, 0)
  web_server_count = try(local.application_tier.webdispatcher_count, 0)
  scs_server_count = local.application_tier.scs_high_availability ? (
    2 * local.application_tier.scs_server_count) : (
    local.application_tier.scs_server_count
  )
  app_zones                  = []
  scs_zones                  = try(local.application_tier.scs_zones, [])
  web_zones                  = try(local.application_tier.web_zones, [])
  db_zones                   = try(local.database.zones, [])
  resource_offset            = try(var.options.resource_offset, 0)
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
    azurerm.main          = azurerm
    azurerm.deployer      = azurerm.deployer
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
    var.NFS_provider
  )
  Agent_IP             = var.Agent_IP
  use_private_endpoint = var.use_private_endpoint

  use_custom_dns_a_registration     = try(data.terraform_remote_state.landscape.outputs.use_custom_dns_a_registration, false)
  management_dns_subscription_id    = try(data.terraform_remote_state.landscape.outputs.management_dns_subscription_id, null)
  management_dns_resourcegroup_name = try(data.terraform_remote_state.landscape.outputs.management_dns_resourcegroup_name, local.saplib_resource_group_name)

  database_dual_nics                 = var.database_dual_nics
  azure_files_sapmnt_id              = var.azure_files_sapmnt_id
  hana_ANF_volumes                   = local.hana_ANF_volumes
  sapmnt_private_endpoint_id         = var.sapmnt_private_endpoint_id
  deploy_application_security_groups = var.deploy_application_security_groups
  use_service_endpoint               = var.use_service_endpoint
}


#########################################################################################
#                                                                                       #
#  HANA Infrastructure                                                                  #
#                                                                                       #
#########################################################################################

module "hdb_node" {
  source = "../../terraform-units/modules/sap_system/hdb_node"
  providers = {
    azurerm.main          = azurerm
    azurerm.deployer      = azurerm.deployer
    azurerm.dnsmanagement = azurerm.dnsmanagement
  }
  depends_on = [module.common_infrastructure]
  order_deployment = local.enable_db_deployment ? (
    local.db_zonal_deployment && local.application_tier.enable_deployment ? (
      module.app_tier.scs_vm_ids[0]
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
  database_dual_nics                           = module.common_infrastructure.admin_subnet == null ? false : var.database_dual_nics
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
  management_dns_resourcegroup_name = data.terraform_remote_state.landscape.outputs.management_dns_resourcegroup_name
}


#########################################################################################
#                                                                                       #
#  App Tier Infrastructure                                                              #
#                                                                                       #
#########################################################################################

module "app_tier" {
  source = "../../terraform-units/modules/sap_system/app_tier"
  providers = {
    azurerm.main          = azurerm
    azurerm.deployer      = azurerm.deployer
    azurerm.dnsmanagement = azurerm.dnsmanagement
  }
  depends_on = [module.common_infrastructure]
  order_deployment = null

  application_tier                             = local.application_tier
  infrastructure                               = local.infrastructure
  options                                      = local.options
  resource_group                               = module.common_infrastructure.resource_group
  storage_bootdiag_endpoint                    = module.common_infrastructure.storage_bootdiag_endpoint
  ppg                                          = module.common_infrastructure.ppg
  sid_keyvault_user_id                         = module.common_infrastructure.sid_keyvault_user_id
  naming                                       = length(var.name_override_file) > 0 ? local.custom_names : module.sap_namegenerator.naming
  admin_subnet                                 = module.common_infrastructure.admin_subnet
  custom_disk_sizes_filename                   = try(coalesce(var.custom_disk_sizes_filename, var.app_disk_sizes_filename), "")
  sid_password                                 = module.common_infrastructure.sid_password
  sid_username                                 = module.common_infrastructure.sid_username
  sdu_public_key                               = module.common_infrastructure.sdu_public_key
  route_table_id                               = module.common_infrastructure.route_table_id
  firewall_id                                  = module.common_infrastructure.firewall_id
  sap_sid                                      = local.sap_sid
  landscape_tfstate                            = data.terraform_remote_state.landscape.outputs
  terraform_template_version                   = var.terraform_template_version
  deployment                                   = var.deployment
  network_location                             = module.common_infrastructure.network_location
  network_resource_group                       = module.common_infrastructure.network_resource_group
  cloudinit_growpart_config                    = null # This needs more consideration module.common_infrastructure.cloudinit_growpart_config
  license_type                                 = var.license_type
  use_loadbalancers_for_standalone_deployments = var.use_loadbalancers_for_standalone_deployments
  idle_timeout_scs_ers                         = var.idle_timeout_scs_ers
  use_secondary_ips                            = var.use_secondary_ips
  deploy_application_security_groups           = var.deploy_application_security_groups
  use_msi_for_clusters                         = var.use_msi_for_clusters
  fencing_role_name                            = var.fencing_role_name
  use_custom_dns_a_registration                = data.terraform_remote_state.landscape.outputs.use_custom_dns_a_registration
  management_dns_subscription_id               = try(data.terraform_remote_state.landscape.outputs.management_dns_subscription_id, null)
  management_dns_resourcegroup_name            = data.terraform_remote_state.landscape.outputs.management_dns_resourcegroup_name

}

#########################################################################################
#                                                                                       #
#  AnyDB Infrastructure                                                                 #
#                                                                                       #
#########################################################################################

module "anydb_node" {
  source = "../../terraform-units/modules/sap_system/anydb_node"
  providers = {
    azurerm.main          = azurerm
    azurerm.deployer      = azurerm.deployer
    azurerm.dnsmanagement = azurerm.dnsmanagement
  }
  depends_on = [module.common_infrastructure]
  order_deployment = local.enable_db_deployment ? (
    local.db_zonal_deployment && local.application_tier.enable_deployment ? (
      module.app_tier.scs_vm_ids[0]
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
  admin_subnet                                 = module.common_infrastructure.admin_subnet
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
  use_custom_dns_a_registration      = data.terraform_remote_state.landscape.outputs.use_custom_dns_a_registration
  management_dns_subscription_id     = try(data.terraform_remote_state.landscape.outputs.management_dns_subscription_id, null)
  management_dns_resourcegroup_name  = data.terraform_remote_state.landscape.outputs.management_dns_resourcegroup_name

}

#########################################################################################
#                                                                                       #
#  Output files                                                                         #
#                                                                                       #
#########################################################################################

module "output_files" {
  source = "../../terraform-units/modules/sap_system/output_files"
  providers = {
    azurerm.main     = azurerm
    azurerm.deployer = azurerm.deployer
  }
  database            = local.database
  infrastructure      = local.infrastructure
  authentication      = local.authentication
  authentication_type = try(local.application_tier.authentication.type, "key")
  nics_dbnodes_admin  = module.hdb_node.nics_dbnodes_admin
  nics_dbnodes_db     = module.hdb_node.nics_dbnodes_db
  loadbalancers       = module.hdb_node.loadbalancers
  sap_sid             = local.sap_sid
  db_sid              = local.db_sid
  nics_scs            = module.app_tier.nics_scs
  nics_app            = module.app_tier.nics_app
  nics_web            = module.app_tier.nics_web
  nics_anydb          = module.anydb_node.nics_anydb
  nics_scs_admin      = module.app_tier.nics_scs_admin
  nics_app_admin      = module.app_tier.nics_app_admin
  nics_web_admin      = module.app_tier.nics_web_admin
  nics_anydb_admin    = module.anydb_node.nics_anydb_admin
  anydb_loadbalancers = module.anydb_node.anydb_loadbalancers
  random_id           = module.common_infrastructure.random_id
  landscape_tfstate   = data.terraform_remote_state.landscape.outputs
  naming = length(var.name_override_file) > 0 ? (
    local.custom_names) : (
    module.sap_namegenerator.naming
  )
  app_tier_os_types    = module.app_tier.app_tier_os_types
  sid_keyvault_user_id = module.common_infrastructure.sid_keyvault_user_id
  disks = distinct(compact(concat(module.hdb_node.dbtier_disks,
    module.anydb_node.dbtier_disks,
    module.app_tier.apptier_disks
  )))
  use_local_credentials = module.common_infrastructure.use_local_credentials
  scs_ha                = module.app_tier.scs_ha
  db_ha = upper(try(local.database.platform, "HANA")) == "HANA" ? (
    module.hdb_node.db_ha) : (
    module.anydb_node.db_ha
  )
  ansible_user = module.common_infrastructure.sid_username
  scs_lb_ip    = module.app_tier.scs_lb_ip
  db_lb_ip = upper(try(local.database.platform, "HANA")) == "HANA" ? (
    module.hdb_node.db_lb_ip[0]) : (
    module.anydb_node.db_lb_ip[0]
  )
  database_admin_ips = upper(try(local.database.platform, "HANA")) == "HANA" ? (
    module.hdb_node.db_ip) : (
    module.anydb_node.anydb_db_ip
  ) #TODO Change to use Admin IP
  sap_mnt                 = module.common_infrastructure.sapmnt_path
  sap_transport           = try(data.terraform_remote_state.landscape.outputs.saptransport_path, "")
  ers_lb_ip               = module.app_tier.ers_lb_ip
  bom_name                = var.bom_name
  scs_instance_number     = var.scs_instance_number
  ers_instance_number     = var.ers_instance_number
  platform                = upper(try(local.database.platform, "HANA"))
  db_auth_type            = try(local.database.authentication.type, "key")
  tfstate_resource_id     = var.tfstate_resource_id
  install_path            = try(data.terraform_remote_state.landscape.outputs.install_path, "")
  NFS_provider            = var.NFS_provider
  observer_ips            = module.anydb_node.observer_ips
  observer_vms            = module.anydb_node.observer_vms
  shared_home             = var.shared_home
  hana_data               = [module.hdb_node.hana_data_primary, module.hdb_node.hana_data_secondary]
  hana_log                = [module.hdb_node.hana_log_primary, module.hdb_node.hana_log_secondary]
  hana_shared             = [module.hdb_node.hana_shared_primary, module.hdb_node.hana_shared_secondary]
  usr_sap                 = module.common_infrastructure.usrsap_path
  save_naming_information = var.save_naming_information
  use_secondary_ips       = var.use_secondary_ips
  web_sid                 = var.web_sid
  use_msi_for_clusters    = var.use_msi_for_clusters
  dns                     = try(data.terraform_remote_state.landscape.outputs.dns_label, "")
}
