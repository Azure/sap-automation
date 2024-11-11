
locals {
  subnet_admin_defined                 = (
                                          length(var.admin_subnet_address_prefix) +
                                          length(try(var.infrastructure.vnets.sap.subnet_admin.prefix, "")) +
                                          length(var.admin_subnet_arm_id) +
                                          length(try(var.infrastructure.vnets.sap.subnet_admin.arm_id, ""))
                                        ) > 0

  subnet_admin_arm_id_defined          = (
                                            length(var.admin_subnet_arm_id) +
                                            length(try(var.infrastructure.vnets.sap.subnet_admin.arm_id, ""))
                                          ) > 0

  subnet_admin_nsg_defined             = (
                                          length(var.admin_subnet_nsg_name) +
                                          length(try(var.infrastructure.vnets.sap.subnet_admin.nsg.name, "")) +
                                          length(var.admin_subnet_nsg_arm_id) +
                                          length(try(var.infrastructure.vnets.sap.subnet_admin.nsg.arm_id, ""))
                                        ) > 0

  subnet_db_defined                    = (
                                           length(var.db_subnet_address_prefix) +
                                           length(try(var.infrastructure.vnets.sap.subnet_db.prefix, "")) +
                                           length(var.db_subnet_arm_id) +
                                           length(try(var.infrastructure.vnets.sap.subnet_db.arm_id, ""))
                                         ) > 0

  subnet_db_arm_id_defined             = (
                                           length(var.db_subnet_arm_id) +
                                           length(try(var.infrastructure.vnets.sap.subnet_db.arm_id, ""))
                                         ) > 0

  subnet_db_nsg_defined                = (
                                           length(var.db_subnet_nsg_name) +
                                           length(try(var.infrastructure.vnets.sap.subnet_db.nsg.name, "")) +
                                           length(var.db_subnet_nsg_arm_id) +
                                           length(try(var.infrastructure.vnets.sap.subnet_db.nsg.arm_id, ""))
                                         ) > 0

  subnet_app_defined                   = (
                                            length(var.app_subnet_address_prefix) +
                                            length(try(var.infrastructure.vnets.sap.subnet_app.prefix, "")) +
                                            length(var.app_subnet_arm_id) +
                                            length(try(var.infrastructure.vnets.sap.subnet_app.arm_id, ""))
                                          ) > 0

  subnet_app_arm_id_defined            = (
                                           length(var.app_subnet_arm_id) +
                                           length(try(var.infrastructure.vnets.sap.subnet_app.arm_id, ""))
                                         ) > 0

  subnet_app_nsg_defined               = (
                                           length(var.app_subnet_nsg_name) +
                                           length(try(var.infrastructure.vnets.sap.subnet_app.nsg.name, "")) +
                                           length(var.app_subnet_nsg_arm_id) +
                                           length(try(var.infrastructure.vnets.sap.subnet_app.nsg.arm_id, ""))
                                         ) > 0

  subnet_web_defined                   = (
                                           length(var.web_subnet_address_prefix) +
                                           length(try(var.infrastructure.vnets.sap.subnet_web.prefix, "")) +
                                           length(var.web_subnet_arm_id) +
                                           length(try(var.infrastructure.vnets.sap.subnet_web.arm_id, ""))
                                         ) > 0

  subnet_web_arm_id_defined            = (
                                           length(var.web_subnet_arm_id) +
                                           length(try(var.infrastructure.vnets.sap.subnet_web.arm_id, ""))
                                         ) > 0

  subnet_web_nsg_defined               = (
                                           length(var.web_subnet_nsg_name) +
                                           length(try(var.infrastructure.vnets.sap.subnet_web.nsg.name, "")) +
                                           length(var.web_subnet_nsg_arm_id) +
                                           length(try(var.infrastructure.vnets.sap.subnet_web.nsg.arm_id, ""))
                                         ) > 0

  subnet_storage_defined                 = (
                                           length(var.storage_subnet_address_prefix) +
                                           length(try(var.infrastructure.vnets.sap.subnet_storage.prefix, "")) +
                                           length(var.storage_subnet_arm_id) +
                                           length(try(var.infrastructure.vnets.sap.subnet_storage.arm_id, ""))
                                         ) > 0

  subnet_storage_arm_id_defined          = (
                                           length(var.storage_subnet_arm_id) +
                                           length(try(var.infrastructure.vnets.sap.subnet_storage.arm_id, ""))
                                         ) > 0

  subnet_storage_nsg_defined             = (
                                           length(var.storage_subnet_nsg_name) +
                                           length(try(var.infrastructure.vnets.sap.subnet_storage.nsg.name, "")) +
                                           length(var.web_subnet_nsg_arm_id) +
                                           length(try(var.infrastructure.vnets.sap.subnet_storage.nsg.arm_id, ""))
                                         ) > 0

  subnet_iscsi_defined                 = (
                                           length(var.iscsi_subnet_address_prefix) +
                                           length(try(var.infrastructure.vnets.sap.subnet_iscsi.prefix, "")) +
                                           length(var.iscsi_subnet_arm_id) +
                                           length(try(var.infrastructure.vnets.sap.subnet_iscsi.arm_id, ""))
                                         ) > 0

  subnet_iscsi_arm_id_defined          = (
                                           length(var.iscsi_subnet_arm_id) +
                                           length(try(var.infrastructure.vnets.sap.subnet_iscsi.arm_id, ""))
                                         ) > 0

  subnet_iscsi_nsg_defined             = (
                                           length(var.iscsi_subnet_nsg_name) +
                                           length(try(var.infrastructure.vnets.sap.subnet_iscsi.nsg.name, "")) +
                                           length(var.iscsi_subnet_nsg_arm_id) +
                                           length(try(var.infrastructure.vnets.sap.subnet_iscsi.nsg.arm_id, ""))
                                         ) > 0

  subnet_anf_defined                   = (
                                           length(var.anf_subnet_address_prefix) +
                                           length(try(var.infrastructure.vnets.sap.subnet_anf.prefix, "")) +
                                           length(var.anf_subnet_arm_id) +
                                           length(try(var.infrastructure.vnets.sap.subnet_anf.arm_id, ""))
                                         ) > 0

  subnet_anf_arm_id_defined            = (
                                           length(var.anf_subnet_arm_id) +
                                           length(try(var.infrastructure.vnets.sap.subnet_anf.arm_id, ""))
                                         ) > 0

  subnet_anf_nsg_defined               = (
                                           length(var.anf_subnet_nsg_name) +
                                           length(try(var.infrastructure.vnets.sap.subnet_anf.nsg.name, "")) +
                                           length(var.anf_subnet_nsg_arm_id) +
                                           length(try(var.infrastructure.vnets.sap.subnet_anf.nsg.arm_id, ""))
                                         ) > 0

  subnet_ams_defined                   = (
                                           length(var.ams_subnet_address_prefix) +
                                           length(try(var.infrastructure.vnets.sap.subnet_ams.prefix, "")) +
                                           length(var.ams_subnet_arm_id) +
                                           length(try(var.infrastructure.vnets.sap.subnet_ams.arm_id, ""))
                                         ) > 0

  subnet_ams_arm_id_defined            = (
                                           length(var.ams_subnet_arm_id) +
                                           length(try(var.infrastructure.vnets.sap.subnet_ams.arm_id, ""))
                                         ) > 0

  subnet_ams_nsg_defined               = (
                                           length(var.ams_subnet_nsg_name) +
                                           length(try(var.infrastructure.vnets.sap.subnet_ams.nsg.name, "")) +
                                           length(var.ams_subnet_nsg_arm_id) +
                                           length(try(var.infrastructure.vnets.sap.subnet_ams.nsg.arm_id, ""))
                                         ) > 0

  resource_group                       = {
                                            name   = try(var.infrastructure.resource_group.name, var.resourcegroup_name)
                                            arm_id = try(var.infrastructure.resource_group.arm_id, var.resourcegroup_arm_id)
                                         }
  resource_group_defined               = (
                                           length(local.resource_group.name) +
                                           length(local.resource_group.arm_id)
                                         ) > 0

  ams_instance                        = {
                                           name                    = var.ams_instance_name
                                           create_ams_instance     = var.create_ams_instance
                                           ams_laws_arm_id         = var.ams_laws_arm_id
                                        }

  nat_gateway                         = {
                                           create_nat_gateway      = var.deploy_nat_gateway
                                           name                    = var.nat_gateway_name
                                           arm_id                  = try(var.nat_gateway_arm_id, "")
                                           region                  = lower(coalesce(var.location, try(var.infrastructure.region, "")))
                                           public_ip_zones         = try(var.nat_gateway_public_ip_zones, ["1", "2", "3"])
                                           public_ip_arm_id        = try(var.nat_gateway_public_ip_arm_id, "")
                                           idle_timeout_in_minutes = var.nat_gateway_idle_timeout_in_minutes
                                           ip_tags                 = try(var.nat_gateway_public_ip_tags, {})
                                         }

  temp_infrastructure                  = {
                                           environment                   = var.environment
                                           region                        = lower(var.location)
                                           codename                      = var.codename
                                           tags                          = var.resourcegroup_tags
                                           deploy_monitoring_extension   = var.deploy_monitoring_extension
                                           deploy_defender_extension     = var.deploy_defender_extension
                                           user_assigned_identity_id     = var.user_assigned_identity_id
                                           patch_mode                    = var.patch_mode
                                           patch_assessment_mode         = var.patch_assessment_mode
                                           shared_access_key_enabled     = var.shared_access_key_enabled
                                           shared_access_key_enabled_nfs = var.shared_access_key_enabled_nfs
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
                                         }
  key_vault_temp =                       {
                                           exists                 = length(var.user_keyvault_id) > 0
                                           set_secret_expiry      = var.set_secret_expiry
                                         }

  user_keyvault_specified              = length(var.user_keyvault_id) > 0

  user_keyvault                        = var.user_keyvault_id

  spn_keyvault_specified               = (
                                           length(var.spn_keyvault_id) +
                                           length(try(var.key_vault.kv_spn_id, ""))
                                         ) > 0

  spn_kv                               = local.spn_keyvault_specified ? (
                                           var.spn_keyvault_id
                                           ) : (
                                           ""
                                         )

  key_vault                            = merge(local.key_vault_temp, (
                                          local.user_keyvault_specified ? (
                                            {
                                              kv_user_id = local.user_keyvault
                                            }
                                          ) : null), (
                                          local.spn_keyvault_specified ? (
                                            {
                                              kv_spn_id = local.spn_kv
                                            }
                                          ) : null
                                          )
                                        )

  diagnostics_storage_account          = {
                                           arm_id = var.diagnostics_storage_account_arm_id
                                         }
  witness_storage_account              = {
                                           arm_id = var.witness_storage_account_arm_id
                                         }

  vnets                                = {  }
  sap                                  = {
                                           name          = var.network_name
                                           logical_name  = var.network_logical_name
                                           flow_timeout_in_minutes = var.network_flow_timeout_in_minutes
                                           enable_route_propagation = var.network_enable_route_propagation
                                           arm_id        = var.network_arm_id
                                           address_space = tolist(split(",", var.network_address_space))
                                         }

  subnet_admin                         = merge((
                                           {
                                             "name" = var.admin_subnet_name
                                           }
                                           ), (
                                           local.subnet_admin_arm_id_defined ?
                                           (
                                             {
                                               "arm_id" = var.admin_subnet_arm_id
                                             }
                                             ) : (
                                             null
                                           )), (
                                           {
                                             "prefix" = var.admin_subnet_address_prefix
                                           }
                                           ), (
                                           local.subnet_admin_nsg_defined ? (
                                             {
                                               "nsg" = {
                                                 "name"   = var.admin_subnet_nsg_name
                                                 "arm_id" = var.admin_subnet_nsg_arm_id
                                               }
                                             }
                                             ) : (
                                             null
                                           )
                                           )
                                         )

  subnet_db                            = merge(
                                           (
                                             {
                                               "name" = var.db_subnet_name
                                             }
                                             ), (
                                             local.subnet_db_arm_id_defined ? (
                                               {
                                                 "arm_id" = var.db_subnet_arm_id
                                               }
                                               ) : (
                                             null)
                                             ), (
                                             {
                                               "prefix" = var.db_subnet_address_prefix
                                             }
                                             ), (
                                             local.subnet_db_nsg_defined ? (
                                               {
                                                 "nsg" = {
                                                   "name"   = var.db_subnet_nsg_name
                                                   "arm_id" = var.db_subnet_nsg_arm_id
                                                 }
                                               }
                                             ) : null
                                           )
                                         )

  subnet_app                           = merge(
                                           (
                                             {
                                               "name" = var.app_subnet_name
                                             }
                                             ), (
                                             local.subnet_app_arm_id_defined ? (
                                               {
                                                 "arm_id" = var.app_subnet_arm_id
                                               }
                                               ) : (
                                               null
                                             )), (
                                             {
                                               "prefix" = var.app_subnet_address_prefix
                                             }
                                             ), (
                                             local.subnet_app_nsg_defined ? (
                                               {
                                                 "nsg" = {
                                                   "name"   = var.app_subnet_nsg_name
                                                   "arm_id" = var.app_subnet_nsg_arm_id
                                                 }
                                               }
                                             ) : null
                                           )
                                         )

  subnet_web                           = merge(
                                           (
                                             {
                                               "name" = var.web_subnet_name
                                             }
                                             ), (
                                             local.subnet_web_arm_id_defined ? (
                                               {
                                                 "arm_id" = var.web_subnet_arm_id
                                               }
                                               ) : (
                                               null
                                             )), (
                                             {
                                               "prefix" = var.web_subnet_address_prefix
                                             }
                                             ), (
                                             local.subnet_web_nsg_defined ? (
                                               {
                                                 "nsg" = {
                                                   "name"   = var.web_subnet_nsg_name
                                                   "arm_id" = var.web_subnet_nsg_arm_id
                                                 }
                                               }
                                             ) : null
                                           )
                                         )

  subnet_storage                       = merge(
                                           (
                                             {
                                               "name" = var.storage_subnet_name
                                             }
                                             ), (
                                             local.subnet_storage_arm_id_defined ? (
                                               {
                                                 "arm_id" = var.storage_subnet_arm_id
                                               }
                                               ) : (
                                               null
                                             )), (
                                             {
                                               "prefix" = var.storage_subnet_address_prefix
                                             }
                                             ), (
                                             local.subnet_storage_nsg_defined ? (
                                               {
                                                 "nsg" = {
                                                   "name"   = var.storage_subnet_nsg_name
                                                   "arm_id" = var.storage_subnet_nsg_arm_id
                                                 }
                                               }
                                             ) : null
                                           )
                                         )

  subnet_anf                           = merge(
                                          (
                                            {
                                              "name" = var.anf_subnet_name
                                            }
                                            ), (
                                            local.subnet_anf_arm_id_defined ? (
                                              {
                                                "arm_id" = var.anf_subnet_arm_id
                                              }
                                              ) : (
                                              null
                                            )), (
                                            {
                                              "prefix" = var.anf_subnet_address_prefix
                                            }
                                            ), (
                                            local.subnet_anf_nsg_defined ? (
                                              {
                                                "nsg" = {
                                                  "name"   = var.anf_subnet_nsg_name
                                                  "arm_id" = var.anf_subnet_nsg_arm_id
                                                }
                                              }
                                              ) : (
                                              null
                                            )
                                          )
                                        )

  subnet_iscsi                         = merge(
                                          (
                                            {
                                              "name" = var.iscsi_subnet_name
                                            }
                                            ), (
                                            local.subnet_iscsi_arm_id_defined ? (
                                              {
                                                "arm_id" = var.iscsi_subnet_arm_id
                                              }
                                              ) : (
                                              null
                                            )), (
                                            {
                                              "prefix" = var.iscsi_subnet_address_prefix
                                            }
                                            ), (
                                            local.subnet_iscsi_nsg_defined ? (
                                              {
                                                "nsg" = {
                                                  "name"   = var.iscsi_subnet_nsg_name
                                                  "arm_id" = var.iscsi_subnet_nsg_arm_id
                                                }
                                              }
                                              ) : (
                                              null
                                            )
                                          )
                                        )

  subnet_ams                         = merge(
                                          (
                                            {
                                              "name" = var.ams_subnet_name
                                            }
                                            ), (
                                            local.subnet_ams_arm_id_defined ? (
                                              {
                                                "arm_id" = var.ams_subnet_arm_id
                                              }
                                              ) : (
                                              null
                                            )), (
                                            {
                                              "prefix" = var.ams_subnet_address_prefix
                                            }
                                            ), (
                                            local.subnet_web_nsg_defined ? (
                                              {
                                                "nsg" = {
                                                  "name"   = var.ams_subnet_nsg_name
                                                  "arm_id" = var.ams_subnet_nsg_arm_id
                                                }
                                              }
                                              ) : (
                                              null
                                            )
                                          )
                                        )

  all_subnets                          = merge(local.sap, (
                                         local.subnet_admin_defined ? (
                                           {
                                             "subnet_admin" = local.subnet_admin
                                           }
                                           ) : (
                                           null
                                         )), (
                                         local.subnet_db_defined ? (
                                           {
                                             "subnet_db" = local.subnet_db
                                           }
                                           ) : (
                                           null
                                         )), (
                                         local.subnet_app_defined ? (
                                           {
                                             "subnet_app" = local.subnet_app
                                           }
                                           ) : (
                                           null
                                         )), (
                                         local.subnet_web_defined ? (
                                           {
                                             "subnet_web" = local.subnet_web
                                           }
                                           ) : (
                                           null
                                         )), (
                                         local.subnet_storage_defined ? (
                                           {
                                             "subnet_storage" = local.subnet_storage
                                           }
                                           ) : (
                                           null
                                         )), (
                                         local.subnet_anf_defined ? (
                                           {
                                             "subnet_anf" = local.subnet_anf
                                           }
                                           ) : (
                                           null
                                         )), (
                                         local.subnet_ams_defined ? (
                                           {
                                             "subnet_ams" = local.subnet_ams
                                           }
                                           ) : (
                                           null
                                         )), (
                                         local.subnet_iscsi_defined ? (
                                           {
                                             "subnet_iscsi" = local.subnet_iscsi
                                           }
                                           ) : (
                                           null
                                         )
                                         )
                                       )

  temp_vnet                            = merge(local.vnets, { "sap" = local.all_subnets })


  iscsi                                = {
                                           iscsi_count    = var.iscsi_count
                                           use_DHCP       = length(var.iscsi_nic_ips) > 0 ? false : var.iscsi_useDHCP
                                           iscsi_nic_ips  = var.iscsi_nic_ips
                                           size           = try(coalesce(var.iscsi_size, try(var.infrastructure.iscsi.size, "Standard_D2s_v3")), "Standard_D2s_v3")
                                           os             = {
                                                             source_image_id = try(coalesce(var.iscsi_image.source_image_id, try(var.infrastructure.iscsi.os.source_image_id, "")), "")
                                                             publisher       = try(coalesce(var.iscsi_image.publisher, try(var.infrastructure.iscsi.os.publisher, "")), "")
                                                             offer           = try(coalesce(var.iscsi_image.offer, try(var.infrastructure.iscsi.os.offer, "")), "")
                                                             sku             = try(coalesce(var.iscsi_image.sku, try(var.infrastructure.iscsi.os.sku, "")), "")
                                                             version         = try(coalesce(var.iscsi_image.version, try(var.infrastructure.iscsi.sku, "")), "")
                                                           }

                                           authentication = {
                                                              type     = try(coalesce(var.iscsi_authentication_type, try(var.infrastructure.iscsi.authentication.type, "key")), "key")
                                                              username = try(coalesce(var.iscsi_authentication_username, try(var.authentication.username, "azureadm")), "azureadm")
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
                                            "vnets" = local.temp_vnet
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
                                          arm_id            = var.ANF_account_arm_id
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

                                           management_dns_resourcegroup_name            =  coalesce(var.management_dns_resourcegroup_name, local.saplib_resource_group_name)
                                           management_dns_subscription_id               =  coalesce(var.management_dns_subscription_id, local.saplib_subscription_id)

                                           privatelink_dns_resourcegroup_name           = coalesce(var.privatelink_dns_resourcegroup_name, var.management_dns_resourcegroup_name, local.saplib_resource_group_name)
                                           privatelink_dns_subscription_id              = coalesce(var.privatelink_dns_subscription_id, var.management_dns_subscription_id, local.saplib_subscription_id)

                                           register_storage_accounts_keyvaults_with_dns = var.register_storage_accounts_keyvaults_with_dns
                                           register_endpoints_with_dns                  = var.register_endpoints_with_dns
                                           register_virtual_network_to_dns              = var.register_virtual_network_to_dns
                                         }

}
