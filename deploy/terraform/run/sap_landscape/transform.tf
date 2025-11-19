# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.


locals {

  resource_group                       = {
                                            name   = try(var.infrastructure.resource_group.name, var.resourcegroup_name)
                                            id     = try(var.infrastructure.resource_group.arm_id, var.resourcegroup_arm_id)
                                         }
  resource_group_defined               = (
                                           length(local.resource_group.name) +
                                           length(local.resource_group.id)
                                         ) > 0

  ams_instance                        = {
                                           name                    = var.ams_instance_name
                                           create_ams_instance     = var.create_ams_instance
                                           ams_laws_id             = var.ams_laws_arm_id
                                        }

  nat_gateway                         = {
                                           create_nat_gateway      = var.deploy_nat_gateway
                                           name                    = var.nat_gateway_name
                                           id                      = try(var.nat_gateway_arm_id, "")
                                           region                  = lower(coalesce(var.location, try(var.infrastructure.region, "")))
                                           public_ip_zones         = try(var.nat_gateway_public_ip_zones, lower(coalesce(var.location, try(var.infrastructure.region, ""))) == "eastus2euap" ? ["1", "2", "3", "4"] : ["1", "2", "3"])
                                           public_ip_id            = try(var.nat_gateway_public_ip_arm_id, "")
                                           idle_timeout_in_minutes = var.nat_gateway_idle_timeout_in_minutes
                                           ip_tags                 = try(var.nat_gateway_public_ip_tags, {})
                                         }

  temp_infrastructure                  = {
                                           additional_network_id         = length(var.additional_network_id) > 0 ? (
                                                                            var.additional_network_id) : (
                                                                            try(length(data.terraform_remote_state.deployer[0].outputs.additional_network_id) > 0, false) ? (
                                                                              data.terraform_remote_state.deployer[0].outputs.additional_network_id) : (
                                                                              ""))
                                           additional_subnet_id          = var.additional_subnet_id
                                           codename                      = var.codename
                                           deploy_defender_extension     = var.deploy_defender_extension
                                           deploy_monitoring_extension   = var.deploy_monitoring_extension
                                           encryption_at_host_enabled    = var.encryption_at_host_enabled
                                           environment                   = var.environment
                                           patch_assessment_mode         = var.patch_assessment_mode
                                           patch_mode                    = var.patch_mode
                                           platform_updates              = var.platform_updates
                                           region                        = lower(var.location)
                                           shared_access_key_enabled     = var.shared_access_key_enabled
                                           shared_access_key_enabled_nfs = var.shared_access_key_enabled_nfs
                                           tags                          = var.resourcegroup_tags
                                           user_assigned_identity_id     = var.user_assigned_identity_id
                                           application_configuration_id  = try(coalesce(
                                                                             var.application_configuration_id,
                                                                             try(data.terraform_remote_state.deployer[0].outputs.application_configuration_id, "")
                                                                           ), "")

                                           use_application_configuration = length(try(coalesce(
                                                                             var.application_configuration_id,
                                                                             try(data.terraform_remote_state.deployer[0].outputs.application_configuration_id, "")
                                                                           ), "")) > 0 ? true : false
                                           workload_zone_name            = local.workload_zone_name
                                           control_plane_name            = var.control_plane_name
                                         }

  authentication                       = {
                                           username            = coalesce(var.automation_username,  "azureadm")
                                           password            = var.automation_password
                                           path_to_public_key  = var.automation_path_to_public_key
                                           path_to_private_key = var.automation_path_to_private_key
                                         }
  options                              = {
                                           enable_secure_transfer = true
                                           use_spn                = var.use_spn
                                           assign_permissions     = var.assign_permissions
                                           spn_id                 = coalesce(data.azurerm_client_config.current_main.object_id, var.spn_id)
                                         }
  key_vault_temp =                       {
                                           exists                 = length(var.user_keyvault_id) > 0
                                           set_secret_expiry      = var.set_secret_expiry
                                         }

  user_keyvault_specified              = length(var.user_keyvault_id) > 0

  user_keyvault                        = var.user_keyvault_id

  spn_keyvault_specified               = length(var.spn_keyvault_id) > 0

  keyvault_containing_the_spns         = local.spn_keyvault_specified ? (
                                           var.spn_keyvault_id
                                           ) : (
                                           ""
                                         )
  key_vault                            = {
                                           user                                   = {
                                                                                      id     = var.user_keyvault_id
                                                                                      exists = length(var.user_keyvault_id) > 0
                                                                                    }
                                           spn                                    = {

                                                                                      id     = trimspace(coalesce(
                                                                                                         contains(keys(data.terraform_remote_state.deployer[0].outputs), "deployer_kv_user_arm_id") ? data.terraform_remote_state.deployer[0].outputs.deployer_kv_user_arm_id : "",
                                                                                                         var.spn_keyvault_id,
                                                                                                         " ")
                                                                                                         )
                                                                                      exists = length(trimspace(coalesce(
                                                                                                         contains(keys(data.terraform_remote_state.deployer[0].outputs), "deployer_kv_user_arm_id") ? data.terraform_remote_state.deployer[0].outputs.deployer_kv_user_arm_id : "",
                                                                                                         var.spn_keyvault_id,
                                                                                                         " ")
                                                                                                         )) > 0
                                                                                    }
                                           private_key_secret_name    = var.workload_zone_private_key_secret_name
                                           public_key_secret_name     = var.workload_zone_public_key_secret_name
                                           username_secret_name       = var.workload_zone_username_secret_name
                                           password_secret_name       = var.workload_zone_password_secret_name
                                           enable_rbac_authorization  = var.enable_rbac_authorization_for_keyvault
                                           set_secret_expiry          = var.set_secret_expiry
                                           exists                     = length(var.user_keyvault_id) > 0
                                           set_secret_expiry          = var.set_secret_expiry
                                           enable_purge_control       = var.enable_purge_control_for_keyvaults
                                           soft_delete_retention_days = var.soft_delete_retention_days
                                        }


  diagnostics_storage_account          = {
                                           id = var.diagnostics_storage_account_arm_id
                                         }
  witness_storage_account              = {
                                           id = var.witness_storage_account_arm_id
                                         }

  virtual_networks                     = {  }
  sap                                  = {
                                           name                     = var.network_name
                                           logical_name             = var.network_logical_name
                                           flow_timeout_in_minutes  = var.network_flow_timeout_in_minutes
                                           enable_route_propagation = var.network_enable_route_propagation
                                           id                       = var.network_arm_id
                                           exists                   = length(var.network_arm_id) > 0
                                           address_space            = flatten(can(tostring(var.network_address_space)) ? tolist(split(",", var.network_address_space)) : [var.network_address_space])


                                         }

  subnet_admin                         = {
                                             name                   = var.admin_subnet_name
                                             id                     = var.admin_subnet_arm_id
                                             prefix                 = var.admin_subnet_address_prefix
                                             defined                = length(var.admin_subnet_arm_id) > 0 ? false : length(var.admin_subnet_address_prefix) > 0
                                             exists                 = length(var.admin_subnet_arm_id) > 0
                                             nsg                    = {
                                                                        name   = var.admin_subnet_nsg_name
                                                                        id     = var.admin_subnet_nsg_arm_id
                                                                        exists = length(var.admin_subnet_nsg_arm_id) > 0
                                                                      }
                                         }

  subnet_db                            = {
                                             name                   = var.db_subnet_name
                                             id                     = var.db_subnet_arm_id
                                             prefix                 = var.db_subnet_address_prefix
                                             defined                = length(var.db_subnet_arm_id) > 0 ? false : length(var.db_subnet_address_prefix) > 0
                                             exists                 = length(var.db_subnet_arm_id) > 0
                                             nsg                    = {
                                                                        name   = var.db_subnet_nsg_name
                                                                        id     = var.db_subnet_nsg_arm_id
                                                                        exists = length(var.db_subnet_nsg_arm_id) > 0
                                                                      }
                                         }

  subnet_app                           = {
                                             name                   = var.app_subnet_name
                                             id                     = var.app_subnet_arm_id
                                             prefix                 = var.app_subnet_address_prefix
                                             defined                = length(var.app_subnet_arm_id) > 0 ? false : length(var.app_subnet_address_prefix) > 0
                                             exists                 = length(var.app_subnet_arm_id) > 0
                                             nsg                    = {
                                                                        name   = var.app_subnet_nsg_name
                                                                        id     = var.app_subnet_nsg_arm_id
                                                                        exists = length(var.app_subnet_nsg_arm_id) > 0
                                                                      }
                                         }

  subnet_web                           = {
                                             name                   = var.web_subnet_name
                                             id                     = var.web_subnet_arm_id
                                             prefix                 = var.web_subnet_address_prefix
                                             defined                = length(var.web_subnet_arm_id) > 0 ? false : length(var.web_subnet_address_prefix) > 0
                                             exists                 = length(var.web_subnet_arm_id) > 0
                                             nsg                    = {
                                                                        name   = var.web_subnet_nsg_name
                                                                        id     = var.web_subnet_nsg_arm_id
                                                                        exists = length(var.web_subnet_nsg_arm_id) > 0
                                                                      }
                                         }

  subnet_storage                       = {
                                             name                   = var.storage_subnet_name
                                             id                     = var.storage_subnet_arm_id
                                             prefix                 = var.storage_subnet_address_prefix
                                             defined                = length(var.storage_subnet_arm_id) > 0 ? false : length(var.storage_subnet_address_prefix) > 0
                                             exists                 = length(var.storage_subnet_arm_id) > 0
                                             nsg                    = {
                                                                        name   = var.storage_subnet_nsg_name
                                                                        id     = var.storage_subnet_nsg_arm_id
                                                                        exists = length(var.storage_subnet_nsg_arm_id) > 0
                                                                      }
                                          }

  subnet_anf                           = {
                                             name                   = var.anf_subnet_name
                                             id                     = var.anf_subnet_arm_id
                                             prefix                 = var.anf_subnet_address_prefix
                                             defined                = length(var.anf_subnet_arm_id) > 0  ? false : length(var.anf_subnet_address_prefix) > 0
                                             exists                 = length(var.anf_subnet_arm_id) > 0
                                             nsg                    = {
                                                                        name   = var.anf_subnet_nsg_name
                                                                        id     = var.anf_subnet_nsg_arm_id
                                                                        exists = length(var.anf_subnet_nsg_arm_id) > 0
                                                                      }
                                         }

  subnet_iscsi                         = {
                                             name                   = var.iscsi_subnet_name
                                             id                     = var.iscsi_subnet_arm_id
                                             prefix                 = var.iscsi_subnet_address_prefix
                                             defined                = length(var.iscsi_subnet_arm_id) > 0 ? false : length(var.iscsi_subnet_address_prefix) > 0
                                             exists                 = length(var.iscsi_subnet_arm_id) > 0
                                             nsg                    = {
                                                                        name   = var.iscsi_subnet_nsg_name
                                                                        id     = var.iscsi_subnet_nsg_arm_id
                                                                        exists = length(var.iscsi_subnet_nsg_arm_id) > 0
                                                                      }
                                         }
  subnet_ams                         =   {
                                             name                   = var.ams_subnet_name
                                             id                     = var.ams_subnet_arm_id
                                             prefix                 = var.ams_subnet_address_prefix
                                             defined                = length(var.ams_subnet_arm_id) > 0 ? false : length(var.ams_subnet_address_prefix) > 0
                                             exists                 = length(var.ams_subnet_arm_id) > 0
                                             nsg                    = {
                                                                        name   = var.ams_subnet_nsg_name
                                                                        id     = var.ams_subnet_nsg_arm_id
                                                                        exists = length(var.ams_subnet_nsg_arm_id) > 0
                                                                      }
                                         }

  all_subnets                          = merge(local.sap, {
                                             subnet_admin           = local.subnet_admin,
                                             subnet_db              = local.subnet_db,
                                             subnet_app             = local.subnet_app,
                                             subnet_web             = local.subnet_web,
                                             subnet_storage         = local.subnet_storage,
                                             subnet_anf             = local.subnet_anf,
                                             subnet_ams             = local.subnet_ams,
                                             subnet_iscsi           = local.subnet_iscsi
  }
                                       )


  iscsi                                = {
                                           iscsi_count    = var.iscsi_count
                                           use_DHCP       = length(var.iscsi_nic_ips) > 0 ? false : var.iscsi_useDHCP
                                           iscsi_nic_ips  = var.iscsi_nic_ips
                                           size           = try(coalesce(var.iscsi_size, try(var.infrastructure.iscsi.size, "Standard_D2s_v3")), "Standard_D2s_v3")
                                           os             = {
                                                             source_image_id = try(var.iscsi_image.source_image_id, "")
                                                             publisher       = try(var.iscsi_image.publisher,  "")
                                                             offer           = try(var.iscsi_image.offer, "")
                                                             sku             = try(var.iscsi_image.sku, "")
                                                             version         = try(var.iscsi_image.version, "")
                                                           }

                                           authentication = {
                                                              type     = try(var.iscsi_authentication_type, "key")
                                                              username = try(var.iscsi_authentication_username,  "azureadm")
                                                            }
                                           zones                       = try(var.iscsi_vm_zones, [])
                                           user_assigned_identity_id   = var.user_assigned_identity_id
                                         }


  infrastructure                       = merge(local.temp_infrastructure, (
                                          local.resource_group_defined ? (
                                            {
                                              "resource_group" = local.resource_group
                                            }
                                            ) : (
                                            null
                                          )), (
                                          {
                                            "virtual_networks" = merge(local.virtual_networks, { "sap" = local.all_subnets })
                                          }
                                          ), (
                                          {
                                            "ams_instance" = local.ams_instance
                                          }
                                          ), (
                                          {
                                            "nat_gateway" = local.nat_gateway
                                          }
                                          ),(
                                          local.iscsi.iscsi_count > 0 ? (
                                            {
                                              "iscsi" = local.iscsi
                                            }
                                          ) : null)
                                        )

  vm_settings                          = {
                                           count              = var.utility_vm_count
                                           size               = var.utility_vm_size
                                           use_DHCP           = var.utility_vm_useDHCP
                                           image              = var.utility_vm_image
                                           private_ip_address = var.utility_vm_nic_ips
                                           disk_size          = var.utility_vm_os_disk_size
                                           disk_type          = var.utility_vm_os_disk_type
                                         }

  ANF_settings                         = {
                                          use               = var.NFS_provider == "ANF"
                                          name              = var.ANF_account_name
                                          id                = var.ANF_account_arm_id
                                          pool_name         = var.ANF_pool_name
                                          use_existing_pool = var.ANF_use_existing_pool
                                          service_level     = var.ANF_service_level
                                          size_in_tb        = var.ANF_pool_size
                                          qos_type          = var.ANF_qos_type

                                          use_existing_transport_volume = var.ANF_transport_volume_use_existing
                                          transport_volume_name         = var.ANF_transport_volume_name
                                          transport_volume_size         = var.ANF_transport_volume_size
                                          transport_volume_throughput   = var.ANF_transport_volume_throughput
                                          transport_volume_zone         = var.ANF_transport_volume_zone[0]

                                          use_existing_install_volume = var.ANF_install_volume_use_existing
                                          install_volume_name         = var.ANF_install_volume_name
                                          install_volume_size         = var.ANF_install_volume_size
                                          install_volume_throughput   = var.ANF_install_volume_throughput
                                          install_volume_zone         = var.ANF_install_volume_zone[0]

                                         }

dns_settings                         = {
                                           use_custom_dns_a_registration                = var.use_custom_dns_a_registration
                                           dns_label                                    = var.dns_label
                                           dns_zone_names                               = var.dns_zone_names
                                           dns_server_list                              = var.dns_server_list

                                           management_dns_resourcegroup_name            =  coalesce(var.management_dns_resourcegroup_name, local.SAPLibrary_resource_group_name)
                                           management_dns_subscription_id               =  coalesce(var.management_dns_subscription_id, local.SAPLibrary_subscription_id)

                                           privatelink_dns_resourcegroup_name           = coalesce(var.privatelink_dns_resourcegroup_name, var.management_dns_resourcegroup_name, local.SAPLibrary_resource_group_name)
                                           privatelink_dns_subscription_id              = coalesce(var.privatelink_dns_subscription_id, var.management_dns_subscription_id, local.SAPLibrary_subscription_id)

                                           register_storage_accounts_keyvaults_with_dns = var.register_storage_accounts_keyvaults_with_dns
                                           register_endpoints_with_dns                  = var.register_endpoints_with_dns
                                           register_virtual_network_to_dns              = var.register_virtual_network_to_dns
                                         }

}
