# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

locals {

  infrastructure =                  {
    environment                        = coalesce(
                                          var.environment,
                                          try(var.infrastructure.environment, "")
                                          )
    region                             = coalesce(var.location, try(var.infrastructure.region, ""))
    codename                           = try(var.codename, try(var.infrastructure.codename, ""))
    resource_group                     = {
                                            name = var.resourcegroup_name,
                                            id = var.resourcegroup_arm_id
                                            exists = length(var.resourcegroup_arm_id) > 0
                                          }
    tags                               = merge(
                                            var.tags, var.resourcegroup_tags
                                        )

    virtual_network                   = {
                                            logical_name            = var.management_network_logical_name
                                            management = {
                                              name                    = var.management_network_name,
                                              id                      = var.management_network_arm_id,
                                              exists                  = length(var.management_network_arm_id) > 0
                                              address_space           = var.management_network_address_space
                                              flow_timeout_in_minutes = var.management_network_flow_timeout_in_minutes
                                              subnet_mgmt = {
                                                name   = var.management_subnet_name,
                                                exists = length(var.management_subnet_arm_id) > 0
                                                id     = var.management_subnet_arm_id
                                                prefix = var.management_subnet_address_prefix
                                                nsg = {
                                                  name        = var.management_subnet_nsg_name
                                                  exists      = length(var.management_subnet_nsg_arm_id) > 0
                                                  id          = var.management_subnet_nsg_arm_id
                                                  allowed_ips = var.management_subnet_nsg_allowed_ips
                                                }
                                              }

                                              subnet_firewall = {
                                                                  id     = var.management_firewall_subnet_arm_id
                                                                  exists = length(var.management_firewall_subnet_arm_id) > 0
                                                                  prefix = var.management_firewall_subnet_address_prefix
                                                                }
                                              subnet_firewall = {
                                                                  id     = var.management_firewall_subnet_arm_id
                                                                  exists = length(var.management_firewall_subnet_arm_id) > 0 ? true : false
                                                                  prefix = var.management_firewall_subnet_address_prefix
                                                                }
                                              subnet_bastion =  {
                                                                  id     = var.management_bastion_subnet_arm_id
                                                                  exists = length(var.management_bastion_subnet_arm_id) > 0
                                                                  prefix = var.management_bastion_subnet_address_prefix
                                                                }
                                              subnet_webapp =   {
                                                                  id     = var.webapp_subnet_arm_id
                                                                  exists = length(var.webapp_subnet_arm_id) > 0
                                                                  prefix = var.webapp_subnet_address_prefix
                                                                }
                                              subnet_agent =    {
                                                                  name   = var.agent_subnet_name,
                                                                  id     = var.agent_subnet_arm_id
                                                                  exists = length(var.agent_subnet_arm_id) > 0
                                                                  prefix = var.agent_subnet_address_prefix
                                                                }
                                            }
                                          }

    deploy_monitoring_extension        = var.deploy_monitoring_extension
    deploy_defender_extension          = var.deploy_defender_extension

    custom_random_id                   = var.custom_random_id
    bastion_public_ip_tags             = try(var.bastion_public_ip_tags, {})

    dev_center_deployment              = var.dev_center_deployment
    devops                             = {
                                           agent_ado_url                  = var.agent_ado_url
                                           agent_ado_project              = var.agent_ado_project
                                           agent_pat                      = var.agent_pat
                                           agent_pool                     = var.agent_pool
                                           ansible_core_version           = var.ansible_core_version
                                           tf_version                     = var.tf_version
                                           DevOpsInfrastructure_object_id = var.DevOpsInfrastructure_object_id
                                           app_token                      = var.github_app_token
                                           repository                     = var.github_repository
                                           server_url                     = var.github_server_url
                                           api_url                        = var.github_api_url
                                           platform                       = var.devops_platform
                                         }
    tfstate_resource_id                = ""
    tfstate_storage_account_name       = ""

  }
  deployer                             = {
                                           size = try(
                                             coalesce(
                                               var.deployer_size,
                                               try(var.deployers[0].size, "")
                                             ),
                                             "Standard_D4ds_v4"
                                           )
                                           disk_type = coalesce(
                                             var.deployer_disk_type,
                                             try(var.deployers[0].disk_type, "")
                                           )
                                           use_DHCP = var.deployer_use_DHCP || try(var.deployers[0].use_DHCP, false)
                                           authentication = {
                                             type = coalesce(
                                               var.deployer_authentication_type,
                                               try(var.deployers[0].authentication.type, "")
                                             )
                                           }
                                           add_system_assigned_identity = var.add_system_assigned_identity
                                           os = {
                                                   os_type         = "LINUX"
                                                   type            = try(var.deployer_image.type, "marketplace")
                                                   source_image_id = try(coalesce(
                                                                       var.deployer_image.source_image_id,
                                                                       try(var.deployers[0].os.source_image_id, "")
                                                                       ),
                                                                       ""
                                                                     )
                                                   publisher       = try(coalesce(
                                                                       var.deployer_image.publisher,
                                                                       try(var.deployers[0].os.publisher, "")
                                                                     ), "")
                                                   offer           = try(coalesce(
                                                                       var.deployer_image.offer,
                                                                       try(var.deployers[0].os.offer, "")
                                                                     ), "")
                                                   sku             = try(coalesce(
                                                                       var.deployer_image.sku,
                                                                       try(var.deployers[0].os.sku, "")
                                                                     ), "")
                                                   version         = try(coalesce(
                                                                       var.deployer_image.version,
                                                                       try(var.deployers[0].sku, "")
                                                                     ), "")
                                                 }

                                           private_ip_address = try(coalesce(
                                                                  var.deployer_private_ip_address,
                                                                  try(var.deployers[0].private_ip_address, "")
                                                                ), "")

                                           deployer_diagnostics_account_arm_id = var.deployer_diagnostics_account_arm_id
                                           app_service_SKU                     = var.app_service_SKU_name
                                           user_assigned_identity_id           = var.user_assigned_identity_id
                                           shared_access_key_enabled           = var.shared_access_key_enabled
                                           devops_authentication_type          = var.app_service_devops_authentication_type
                                           encryption_at_host_enabled          = var.encryption_at_host_enabled
                                           deployer_public_ip_tags             = try(var.deployer_public_ip_tags, {})
                                           license_type                        = var.license_type
                                         }

  authentication                       = {
                                            username            = var.deployer_authentication_username
                                            password            = var.deployer_authentication_password
                                            path_to_public_key  = var.deployer_authentication_path_to_public_key
                                            path_to_private_key = var.deployer_authentication_path_to_private_key

                                          }
  key_vault                            = {
                                           id                        = var.user_keyvault_id
                                           exists                    = length(var.user_keyvault_id) > 0
                                           private_key_secret_name   = var.deployer_private_key_secret_name
                                           public_key_secret_name    = var.deployer_public_key_secret_name
                                           username_secret_name      = var.deployer_username_secret_name
                                           password_secret_name      = var.deployer_password_secret_name
                                           enable_rbac_authorization = var.enable_rbac_authorization

                                        }
  options                              = {
                                            enable_deployer_public_ip       = var.deployer_enable_public_ip || try(var.options.enable_deployer_public_ip, false)
                                            use_spn                         = var.use_spn
                                            assign_resource_permissions     = var.deployer_assign_resource_permissions
                                            assign_subscription_permissions = var.deployer_assign_subscription_permissions
                                         }

  firewall                             = {
                                           deployment           = var.firewall_deployment
                                           rule_subnets         = var.firewall_rule_subnets
                                           allowed_ipaddresses  = var.firewall_allowed_ipaddresses
                                           ip_tags              = try(var.firewall_public_ip_tags, {})
                                         }



  app_service                          = {
                                           use                 = var.app_service_deployment
                                           app_registration_id = var.app_registration_app_id
                                           client_secret       = var.webapp_client_secret
                                           use                 = var.app_service_deployment
                                           app_registration_id = var.app_registration_app_id
                                           client_secret       = var.webapp_client_secret
                                         }

  dns_settings                         = {
                                           use_custom_dns_a_registration                = var.use_custom_dns_a_registration
                                           register_storage_accounts_keyvaults_with_dns = var.register_storage_accounts_keyvaults_with_dns
                                           register_endpoints_with_dns                  = var.register_endpoints_with_dns
                                           register_storage_accounts_keyvaults_with_dns = var.register_storage_accounts_keyvaults_with_dns
                                           register_endpoints_with_dns                  = var.register_endpoints_with_dns
                                           dns_zone_names                               = var.dns_zone_names

                                           local_dns_resourcegroup_name                 = ""

                                           local_dns_resourcegroup_name                 = ""

                                           management_dns_resourcegroup_name            = trimspace(var.management_dns_resourcegroup_name)
                                           management_dns_subscription_id               = var.management_dns_subscription_id
                                           management_dns_subscription_id               = var.management_dns_subscription_id

                                           privatelink_dns_subscription_id              = var.privatelink_dns_subscription_id != var.management_dns_subscription_id ? var.privatelink_dns_subscription_id : var.management_dns_subscription_id
                                           privatelink_dns_resourcegroup_name           = var.management_dns_resourcegroup_name != var.privatelink_dns_resourcegroup_name ? var.privatelink_dns_resourcegroup_name : var.management_dns_resourcegroup_name

                                         }
  app_config_service                   = {
                                           name                                        = coalesce(var.application_configuration_name,module.sap_namegenerator.naming_new.appconfig_name)
                                           id                                          = var.application_configuration_id
                                           exists                                      = length(var.application_configuration_id) > 0 ? true : false
                                           deploy                                      = var.application_configuration_deployment
                                           control_plane_name                          = module.sap_namegenerator.naming.prefix.DEPLOYER
                                         }


}
