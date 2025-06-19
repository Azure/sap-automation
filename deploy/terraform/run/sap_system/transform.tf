# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.


locals {

  enable_app_tier_deployment           = var.enable_app_tier_deployment && try(var.application_tier.enable_deployment, true)

  temp_infrastructure                  = {
                                            environment                      = coalesce(var.environment, try(var.infrastructure.environment, ""))
                                            region                           = lower(coalesce(var.location, try(var.infrastructure.region, "")))
                                            codename                         = try(var.codename, try(var.infrastructure.codename, ""))
                                            tags                             = try(merge(var.resourcegroup_tags, try(var.infrastructure.tags, {})), {})
                                            use_app_proximityplacementgroups = var.use_app_proximityplacementgroups
                                            deploy_monitoring_extension      = var.deploy_monitoring_extension
                                            deploy_defender_extension        = var.deploy_defender_extension
                                            patch_mode                       = var.patch_mode
                                            patch_assessment_mode            = var.patch_assessment_mode
                                            platform_updates                 = var.platform_updates
                                            shared_access_key_enabled        = var.shared_access_key_enabled
                                            shared_access_key_enabled_nfs    = var.shared_access_key_enabled_nfs
                                            encryption_at_host_enabled       = var.encryption_at_host_enabled
                                         }


  resource_group                       = {
    name                                    = var.resourcegroup_name
    arm_id                                  = var.resourcegroup_arm_id
                                         }

  resource_group_defined               = (length(local.resource_group.name) + length(local.resource_group.arm_id) ) > 0

  ppg                                  = {
                                           arm_ids = distinct(var.proximityplacementgroup_arm_ids)
                                           names   = distinct(var.proximityplacementgroup_names)
                                         }
  ppg_defined                          = (length(local.ppg.names) + length(local.ppg.arm_ids)) > 0

  app_ppg                              = {
                                           arm_ids = distinct(var.app_proximityplacementgroup_arm_ids)
                                           names   = distinct(var.app_proximityplacementgroup_names)
                                         }
  app_ppg_defined                      = var.use_app_proximityplacementgroups ? (length(local.app_ppg.names) + length(local.app_ppg.arm_ids)) > 0 : false

  deploy_anchor_vm                     = var.deploy_anchor_vm || length(try(var.infrastructure.anchor_vms, {})) > 0

  anchor_vms                           = local.deploy_anchor_vm ? (
                                           {
                                             deploy                 = var.deploy_anchor_vm
                                             use_DHCP               = var.anchor_vm_use_DHCP
                                             accelerated_networking = var.anchor_vm_accelerated_networking
                                             sku                    = var.anchor_vm_sku
                                             os                     = var.anchor_vm_image

                                             authentication = {
                                               type             = var.anchor_vm_authentication_type
                                               username         = var.anchor_vm_authentication_username
                                             }
                                             nic_ips            = var.anchor_vm_nic_ips
                                           }
                                           ) : (
                                           null
                                         )

  authentication_temp                   = {  }

  options_temp                          = {
                                            enable_secure_transfer = true
                                            resource_offset        = var.resource_offset
                                            nsg_asg_with_vnet      = var.nsg_asg_with_vnet
                                            legacy_nic_order       = var.legacy_nic_order
                                          }

  key_vault_temp                        = { }

  db_authentication                     = {
                                            type     = var.database_vm_authentication_type
                                            username = var.automation_username
                                          }
  db_authentication_defined             = (length(local.db_authentication.type) + length(local.db_authentication.username)) > 3

  avset_arm_ids                         = var.database_vm_avset_arm_ids
  db_avset_arm_ids_defined              = length(local.avset_arm_ids) > 0

  frontend_ips                          = var.database_loadbalancer_ips
  db_tags                               = var.database_tags

  databases_temp                       = {
                                           database_cluster_type           = var.database_cluster_type
                                           database_server_count           = var.database_high_availability ? 2 * var.database_server_count : var.database_server_count
                                           database_vm_sku                 = var.database_vm_sku
                                           db_sizing_key                   = coalesce(var.db_sizing_dictionary_key, var.database_size, "Optimized")
                                           deploy_v1_monitoring_extension  = var.deploy_v1_monitoring_extension
                                           dual_nics                       = var.database_dual_nics
                                           high_availability               = var.database_high_availability
                                           database_cluster_disk_lun       = var.database_cluster_disk_lun
                                           database_cluster_disk_size      = var.database_cluster_disk_size
                                           database_cluster_disk_type      = var.database_cluster_disk_type
                                           observer_vm_ips                 = var.observer_nic_ips

                                           platform                        = var.database_platform
                                           use_ANF                         = var.database_HANA_use_scaleout_scenario || try(var.databases[0].use_ANF, false)
                                           use_avset                       = var.database_server_count == 0 || var.use_scalesets_for_deployment || length(var.database_vm_zones) > 0 || var.database_platform == "NONE" ? (
                                                                               false) : (
                                                                               var.database_use_avset
                                                                             )
                                           use_DHCP                        = var.database_vm_use_DHCP || try(var.databases[0].use_DHCP, false)
                                           use_ppg                         = var.database_server_count == 0 || var.use_scalesets_for_deployment || var.database_platform == "NONE" ? (
                                                                               false) : (
                                                                               var.database_use_ppg
                                                                             )
                                           user_assigned_identity_id       = var.user_assigned_identity_id
                                           scale_out                       = var.database_HANA_use_scaleout_scenario
                                           stand_by_node_count             = var.stand_by_node_count
                                           zones                           = var.database_vm_zones
                                           database_hana_use_saphanasr_angi =  upper(var.database_platform) == "HANA" ? (
                                                                                 var.database_high_availability ? (
                                                                                     var.use_sles_saphanasr_angi
                                                                                     ) : (
                                                                                       false
                                                                                     )
                                                                                 ) : (
                                                                                   false
                                                                                 )
                                         }

  db_os                             = {
                                        source_image_id                 = try(var.database_vm_image.source_image_id,  "")
                                        publisher                       = try(var.database_vm_image.publisher,        "")
                                        offer                           = try(var.database_vm_image.offer,            "")
                                        sku                             = try(var.database_vm_image.sku,              "")
                                        version                         = try(var.database_vm_image.version,          "")
                                        type                            = try(var.database_vm_image.type,             "marketplace")
                                        # os_type                         = length(var.database_vm_image.source_image_id) == 0 ? (
                                        #                                     upper(var.database_vm_image.publisher) == "MICROSOFTWINDOWSSERVER") ? "WINDOWS" : try(var.database_vm_image.os_type, "LINUX)") : (
                                        #                                     length(var.database_vm_image.os_type) == 0 ? "LINUX" : var.database_vm_image.os_type
                                        #                                   )
                                        os_type                         = (length(var.database_vm_image.source_image_id) == 0                                                 # - if true
                                                                          ) ? (                                                                                               # - then
                                                                            (upper(var.database_vm_image.publisher) == "MICROSOFTWINDOWSSERVER"                               # --  if true
                                                                            ) ? (                                                                                             # --  then
                                                                              "WINDOWS"
                                                                            ) : (                                                                                             # --  else
                                                                              (length(var.database_vm_image.os_type) == 0                                                     # ---   if true
                                                                              ) ? (                                                                                           # ---   then
                                                                                "LINUX"
                                                                              ) : (                                                                                           # ---   else
                                                                                try(var.database_vm_image.os_type, "LINUX")
                                                                              )                                                                                               # ---   end if
                                                                            )                                                                                                 # --  end if
                                                                          ) : (                                                                                               # - else
                                                                            (length(var.database_vm_image.os_type) == 0                                                       # -- if true
                                                                            ) ? (                                                                                             # -- then
                                                                              "LINUX"
                                                                            ) : (                                                                                             # -- else
                                                                              var.database_vm_image.os_type
                                                                            )                                                                                                 # -- end if
                                                                          )                                                                                                   # - end if
                                      }

  db_os_specified                   = (length(local.db_os.source_image_id) + length(local.db_os.publisher)) > 0
  db_sid_specified                  = (length(var.database_sid) + length(try(var.databases[0].sid, ""))) > 0

  instance                          = {
                                        sid = upper(try(coalesce(
                                           var.database_sid,
                                           try(var.databases[0].sid, "")),
                                           upper(var.database_platform) == "HANA" ? (
                                             "HDB"
                                             ) : (
                                           substr(var.database_platform, 0, 3))
                                        ))
                                        number = upper(local.databases_temp.platform) == "HANA" ? (
                                           var.database_instance_number
                                           ) : (
                                           "00"
                                          )
                                       }

  app_authentication                = {
                                        type     = var.app_tier_authentication_type
                                        username = var.automation_username
                                      }
  app_authentication_defined        = (length(local.app_authentication.type) + length(local.app_authentication.username)) > 3

  app_zones_temp                    = var.application_server_count > 0 ? distinct(var.application_server_zones) : []
  scs_zones_temp                    = var.scs_server_count > 0 ? distinct(var.scs_server_zones) : []
  web_zones_temp                    = var.webdispatcher_server_count > 0 ? distinct(var.webdispatcher_server_zones) : []


  application_temp                  = {
                                        sid                             = var.sid
                                        enable_deployment               = local.enable_app_tier_deployment
                                        use_DHCP                        = var.app_tier_use_DHCP
                                        dual_nics                       = var.app_tier_dual_nics
                                        vm_sizing_dictionary_key        = coalesce(var.app_tier_sizing_dictionary_key, var.application_size, "Optimized")
                                        app_instance_number             = coalesce(var.app_instance_number, "00")
                                        application_server_count        = local.enable_app_tier_deployment ? (
                                                                            var.application_server_count
                                                                            ) : (
                                                                            0
                                                                          )
                                        app_sku                         = var.application_server_sku
                                        app_use_ppg                     = var.application_server_count == 0 || var.use_scalesets_for_deployment || !local.enable_app_tier_deployment ? (
                                                                            false) : (
                                                                            var.application_server_use_ppg
                                                                          )
                                        app_use_avset                   = var.application_server_count == 0 || var.use_scalesets_for_deployment || !local.enable_app_tier_deployment ? (
                                                                            false) : (
                                                                            var.application_server_use_avset
                                                                          )

                                        avset_arm_ids                   = var.application_server_vm_avset_arm_ids
                                        avset_arm_ids_count             = length(var.application_server_vm_avset_arm_ids)
                                        app_zone_count                  = length(local.app_zones_temp)
                                        scs_server_count                = local.enable_app_tier_deployment ? (
                                                                            var.scs_server_count
                                                                            ) : (
                                                                            0
                                                                          )
                                        scs_high_availability           = local.enable_app_tier_deployment ? (
                                                                            var.scs_high_availability
                                                                            ) : (
                                                                            false
                                                                          )
                                        scs_cluster_type                = var.scs_cluster_type
                                        scs_instance_number             = coalesce(var.scs_instance_number, "00")
                                        ers_instance_number             = coalesce(var.ers_instance_number, "02")
                                        scs_sku                         = var.scs_server_sku
                                        scs_use_ppg                     = var.scs_server_count > 0 ? var.use_scalesets_for_deployment ? (
                                                                            false) : (
                                                                            var.scs_server_use_ppg
                                                                          ) : false
                                        scs_use_avset                   = var.scs_server_count == 0 || var.use_scalesets_for_deployment || !local.enable_app_tier_deployment ? (
                                                                            false) : (
                                                                            var.scs_server_use_avset
                                                                          )
                                        scs_zone_count                  = length(local.scs_zones_temp)
                                        scs_cluster_disk_lun            = var.scs_cluster_disk_lun
                                        scs_cluster_disk_size           = var.scs_cluster_disk_size
                                        scs_cluster_disk_type           = var.scs_cluster_disk_type

                                        webdispatcher_count             = local.enable_app_tier_deployment ? (
                                                                            var.webdispatcher_server_count
                                                                            ) : (
                                                                            0
                                                                          )
                                        web_instance_number             = var.web_instance_number
                                        web_sid                         = upper(var.web_sid)
                                        web_sku                         = try(coalesce(var.webdispatcher_server_sku, var.application_tier.web_sku), "")
                                        web_use_ppg                     = (var.webdispatcher_server_count) > 0 ? var.use_scalesets_for_deployment ? (
                                                                            false) : (
                                                                            var.webdispatcher_server_use_ppg
                                                                          ) : false
                                        web_use_avset                   = var.webdispatcher_server_count == 0 || var.use_scalesets_for_deployment || length(var.webdispatcher_server_zones) > 0 || !local.enable_app_tier_deployment ? (
                                                                            false) : (
                                                                            var.webdispatcher_server_use_avset
                                                                          )
                                        web_zone_count                  = length(local.web_zones_temp)

                                        deploy_v1_monitoring_extension  = var.deploy_v1_monitoring_extension
                                        user_assigned_identity_id       = var.user_assigned_identity_id
                                      }

  app_tags                          = var.application_server_tags
  scs_tags                          = var.scs_server_tags
  web_tags                          = var.webdispatcher_server_tags

  app_os = {
    source_image_id                 = try(var.application_server_image.source_image_id, "")
    publisher                       = try(var.application_server_image.publisher,       "SUSE")
    offer                           = try(var.application_server_image.offer,           "sles-sap-15-sp5")
    sku                             = try(var.application_server_image.sku,             "gen2")
    version                         = try(var.application_server_image.version,         "latest")
    type                            = try(var.database_vm_image.type,                   "marketplace")
    # os_type = length(var.application_server_image.source_image_id) == 0 ? (
    #   upper(var.application_server_image.publisher) == "MICROSOFTWINDOWSSERVER") ? "WINDOWS" : try(var.application_server_image.os_type, "LINUX") : (
    #   length(var.application_server_image.os_type) == 0 ? "LINUX" : var.application_server_image.os_type
    # )
    os_type                         = (length(var.application_server_image.source_image_id) == 0                                          # - if true
                                      ) ? (                                                                                               # - then
                                        (upper(var.application_server_image.publisher) == "MICROSOFTWINDOWSSERVER"                        # --  if true
                                        ) ? (                                                                                             # --  then
                                          "WINDOWS"
                                        ) : (                                                                                             # --  else
                                          (length(var.application_server_image.os_type) == 0                                              # ---   if true
                                          ) ? (                                                                                           # ---   then
                                            "LINUX"
                                          ) : (                                                                                           # ---   else
                                            try(var.application_server_image.os_type, "LINUX")
                                          )                                                                                               # ---   end if
                                        )                                                                                                 # --  end if
                                      ) : (                                                                                               # - else
                                        (length(var.application_server_image.os_type) == 0                                                # -- if true
                                        ) ? (                                                                                             # -- then
                                          "LINUX"
                                        ) : (                                                                                             # -- else
                                          var.application_server_image.os_type
                                        )                                                                                                 # -- end if
                                      )                                                                                                   # - end if
  }

  app_os_specified                  = (length(local.app_os.source_image_id) + length(local.app_os.publisher)) > 0

  scs_os                            = {
                                        os_type         = coalesce(var.scs_server_image.os_type, var.application_server_image.os_type, "LINUX")
                                        source_image_id = trimspace(coalesce(var.scs_server_image.source_image_id, var.application_server_image.source_image_id, " "))
                                        publisher       = coalesce(var.scs_server_image.publisher, var.application_server_image.publisher, "SUSE")
                                        offer           = coalesce(var.scs_server_image.offer, var.application_server_image.offer, "sles-sap-15-sp5")
                                        sku             = coalesce(var.scs_server_image.sku, var.application_server_image.sku, "gen2")
                                        version         = coalesce(var.scs_server_image.version, var.application_server_image.version, "latest")
                                        type            = coalesce(var.database_vm_image.type, "marketplace")
                                      }

  scs_os_specified                  = (length(local.scs_os.source_image_id) + length(local.scs_os.publisher)) > 0

  validated_use_simple_mount        = var.use_simple_mount ? (
                                        upper(local.scs_os.publisher) != "SUSE" || !(var.scs_high_availability) ? (
                                         false) : (
                                         contains(["sles-sap-15-sp3", "sles-sap-15-sp4", "sles-sap-15-sp5", "sles-sap-15-sp6"], local.scs_os.offer) ? (
                                           var.use_simple_mount) : (
                                           false
                                         )
                                       )) : (
                                       false
                                       )

  web_os                            = {
                                        os_type         = coalesce(var.webdispatcher_server_image.os_type, var.application_server_image.os_type, "LINUX")
                                        source_image_id = coalesce(var.webdispatcher_server_image.source_image_id, var.application_server_image.source_image_id, " ")
                                        publisher       = coalesce(var.webdispatcher_server_image.publisher, var.application_server_image.publisher, "SUSE")
                                        offer           = coalesce(var.webdispatcher_server_image.offer, var.application_server_image.offer, "sles-sap-15-sp5")
                                        sku             = coalesce(var.webdispatcher_server_image.sku, var.application_server_image.sku, "gen2")
                                        version         = coalesce(var.webdispatcher_server_image.version, var.application_server_image.version, "latest")
                                        type            = coalesce(var.database_vm_image.type, "marketplace")
                                      }
  web_os_specified                     = (length(local.web_os.source_image_id) + length(local.web_os.publisher)) > 0

  virtual_networks                     = {  }

  sap                                  = {
                                           logical_name = var.network_logical_name
                                         }

  app_nic_ips                          = distinct(var.application_server_app_nic_ips)
  app_nic_secondary_ips                = distinct(var.application_server_app_nic_ips)
  app_admin_nic_ips                    = distinct(var.application_server_admin_nic_ips)

  scs_nic_ips                          = distinct(var.scs_server_app_nic_ips)
  scs_admin_nic_ips                    = distinct(var.scs_server_admin_nic_ips)
  scs_server_loadbalancer_ips          = distinct(var.scs_server_loadbalancer_ips)

  web_nic_ips                          = concat(var.webdispatcher_server_app_nic_ips)
  web_admin_nic_ips                    = concat(var.webdispatcher_server_admin_nic_ips)
  webdispatcher_loadbalancer_ips       = concat(var.webdispatcher_server_loadbalancer_ips)

  subnet_admin_arm_id                  = try(coalesce(var.admin_subnet_arm_id, data.terraform_remote_state.landscape.outputs.admin_subnet_id), "")
  subnet_admin_nsg_arm_id              = try(coalesce(var.admin_subnet_nsg_arm_id, data.terraform_remote_state.landscape.outputs.admin_nsg_id), "")

  subnet_admin                         = {
                                            "name"    = length(local.subnet_admin_arm_id) > 0 ? (
                                                           split("/",local.subnet_admin_arm_id)[10]) : (
                                                           var.admin_subnet_name),
                                            "arm_id"  = local.subnet_admin_arm_id
                                            "prefix"  = length(local.subnet_admin_arm_id) > 0 ? "" : var.admin_subnet_address_prefix
                                            "defined" = length(var.admin_subnet_address_prefix) > 0
                                            "nsg" = {
                                                        "name"    = length(local.subnet_admin_nsg_arm_id) > 0 ? (
                                                                      split("/",local.subnet_admin_nsg_arm_id)[8]) : (
                                                                      var.admin_subnet_nsg_name),
                                                        "arm_id"  = local.subnet_admin_nsg_arm_id
                                                      }
                                         }

  subnet_db_arm_id                     = try(coalesce(var.db_subnet_arm_id, data.terraform_remote_state.landscape.outputs.db_subnet_id), "")
  subnet_db_nsg_arm_id                 = try(coalesce(var.db_subnet_nsg_arm_id, data.terraform_remote_state.landscape.outputs.db_nsg_id), "")

  subnet_db                            = {
                                            "name"    = length(local.subnet_db_arm_id) > 0 ? (
                                                           split("/",local.subnet_db_arm_id)[10]) : (
                                                           var.db_subnet_name),
                                            "arm_id"  = local.subnet_db_arm_id
                                            "prefix"  = length(local.subnet_db_arm_id) > 0 ? "" : var.db_subnet_address_prefix
                                            "defined" = length(var.db_subnet_address_prefix) > 0
                                            "nsg" = {
                                                        "name"    = length(local.subnet_db_nsg_arm_id) > 0 ? (
                                                                      split("/",local.subnet_db_nsg_arm_id)[8]) : (
                                                                      var.db_subnet_nsg_name),
                                                        "arm_id"  = local.subnet_db_nsg_arm_id
                                                      }
                                         }
  subnet_app_arm_id                     = try(coalesce(var.app_subnet_arm_id, data.terraform_remote_state.landscape.outputs.app_subnet_id), "")
  subnet_app_nsg_arm_id                 = try(coalesce(var.app_subnet_nsg_arm_id, data.terraform_remote_state.landscape.outputs.app_nsg_id), "")

  subnet_app                            = {
                                            "name"    = length(local.subnet_app_arm_id) > 0 ? (
                                                           split("/",local.subnet_app_arm_id)[10]) : (
                                                           var.app_subnet_name),
                                            "arm_id"  = local.subnet_app_arm_id
                                            "prefix"  = length(local.subnet_app_arm_id) > 0 ? "" : var.app_subnet_address_prefix
                                            "defined" = length(var.app_subnet_address_prefix) > 0
                                            "nsg" = {
                                                        "name"    = length(local.subnet_app_nsg_arm_id) > 0 ? (
                                                                      split("/",local.subnet_app_nsg_arm_id)[8]) : (
                                                                      var.app_subnet_nsg_name),
                                                        "arm_id"  = local.subnet_app_nsg_arm_id
                                                      }
                                         }


  subnet_web_arm_id                     = try(coalesce(var.web_subnet_arm_id, data.terraform_remote_state.landscape.outputs.web_subnet_id), "")
  subnet_web_nsg_arm_id                 = try(coalesce(var.web_subnet_nsg_arm_id, data.terraform_remote_state.landscape.outputs.web_nsg_id), "")

  subnet_web                            = {
                                            "name"    = length(local.subnet_web_arm_id) > 0 ? (
                                                           split("/",local.subnet_web_arm_id)[10]) : (
                                                           var.web_subnet_name),
                                            "arm_id"  = local.subnet_web_arm_id
                                            "prefix"  = length(local.subnet_web_arm_id) > 0 ? "" : var.db_subnet_address_prefix
                                            "defined" = length(var.web_subnet_address_prefix) > 0
                                            "nsg" = {
                                                        "name"    = length(local.subnet_web_nsg_arm_id) > 0 ? (
                                                                      split("/",local.subnet_web_nsg_arm_id)[8]) : (
                                                                      var.web_subnet_nsg_name),
                                                        "arm_id"  = local.subnet_web_nsg_arm_id
                                                      }
                                         }

  subnet_storage_arm_id                     = try(coalesce(var.storage_subnet_arm_id, data.terraform_remote_state.landscape.outputs.storage_subnet_id), "")
  subnet_storage_nsg_arm_id                 = try(coalesce(var.storage_subnet_nsg_arm_id, data.terraform_remote_state.landscape.outputs.storage_nsg_id), "")

  subnet_storage                            = {
                                                "name"    = length(local.subnet_storage_arm_id) > 0 ? (
                                                              split("/",local.subnet_storage_arm_id)[10]) : (
                                                              var.storage_subnet_name),
                                                "arm_id"  = local.subnet_storage_arm_id
                                                "prefix"  = length(local.subnet_storage_arm_id) > 0 ? "" : var.db_subnet_address_prefix
                                                "defined" = length(var.storage_subnet_address_prefix) > 0
                                                "nsg" = {
                                                            "name"    = length(local.subnet_storage_nsg_arm_id) > 0 ? (
                                                                          split("/",local.subnet_storage_nsg_arm_id)[8]) : (
                                                                          var.storage_subnet_nsg_name),
                                                            "arm_id"  = local.subnet_storage_nsg_arm_id
                                                          }
                                         }

all_subnets                          = merge(local.sap, (
                                           {
                                             "subnet_admin"   = local.subnet_admin
                                             "subnet_db"      = local.subnet_db
                                             "subnet_app"     = local.subnet_app
                                             "subnet_web"     = local.subnet_web
                                             "subnet_storage" = local.subnet_storage
                                           }
                                           ))

  user_keyvault_specified              = (length(var.user_keyvault_id) ) > 0
  user_keyvault                        = local.user_keyvault_specified ? (
                                           var.user_keyvault_id
                                         ) : ""

  spn_keyvault_specified               = length(var.spn_keyvault_id) > 0
  spn_kv                               = local.spn_keyvault_specified ? var.spn_keyvault_id : ""

  username_specified                   = (length(var.automation_username)) > 0
  username                             = var.automation_username
  password_specified                   = (length(var.automation_password) ) > 0
  password                             = var.automation_password
  path_to_public_key_specified         = (length(var.automation_path_to_public_key) ) > 0
  path_to_public_key                   = var.automation_path_to_public_key
  path_to_private_key_specified        = (length(var.automation_path_to_private_key)) > 0
  path_to_private_key                  = var.automation_path_to_private_key

  disk_encryption_set_defined          = (length(var.vm_disk_encryption_set_id) ) > 0
  disk_encryption_set_id               = var.vm_disk_encryption_set_id

  infrastructure                       = merge(local.temp_infrastructure, (
                                           local.resource_group_defined ? { resource_group = local.resource_group } : null), (
                                           local.app_ppg_defined        ? { app_ppg = local.app_ppg } : null), (
                                           local.ppg_defined            ? { ppg = local.ppg } : null), (
                                           local.deploy_anchor_vm       ? { anchor_vms = local.anchor_vms } : null),
                                           { virtual_networks = merge(local.virtual_networks, { sap = local.all_subnets }) }
                                         )

  application_tier                     = merge(local.application_temp, (
                                           local.app_authentication_defined                       ? { authentication = local.app_authentication } : null), (
                                           local.app_os_specified                                 ? { app_os = local.app_os } : null), (
                                           local.scs_os_specified                                 ? { scs_os = local.scs_os } : (local.app_os_specified ? { scs_os = local.app_os } : null)), (
                                           local.web_os_specified                                 ? { web_os = local.web_os } : (local.app_os_specified ? { web_os = local.app_os } : null)), (
                                           length(local.app_zones_temp) > 0                       ? { app_zones = local.app_zones_temp } : null), (
                                           length(local.scs_zones_temp) > 0                       ? { scs_zones = local.scs_zones_temp } : null), (
                                           length(local.web_zones_temp) > 0                       ? { web_zones = local.web_zones_temp } : null), (
                                           length(local.app_nic_ips) > 0                          ? { app_nic_ips = local.app_nic_ips } : null), (
                                           length(var.application_server_nic_secondary_ips) > 0   ? { app_nic_secondary_ips = var.application_server_nic_secondary_ips } : null), (
                                           length(local.app_admin_nic_ips) > 0                    ? { app_admin_nic_ips = local.app_admin_nic_ips } : null), (
                                           length(local.scs_nic_ips) > 0                          ? { scs_nic_ips = local.scs_nic_ips } : null), (
                                           length(var.scs_server_nic_secondary_ips) > 0           ? { scs_nic_secondary_ips = var.scs_server_nic_secondary_ips } : null), (
                                           length(local.scs_admin_nic_ips) > 0                    ? { scs_admin_nic_ips = local.scs_admin_nic_ips } : null), (
                                           length(local.scs_server_loadbalancer_ips) > 0          ? { scs_server_loadbalancer_ips = local.scs_server_loadbalancer_ips } : null), (
                                           length(local.web_nic_ips) > 0                          ? { web_nic_ips = local.web_nic_ips } : null), (
                                           length(var.webdispatcher_server_nic_secondary_ips) > 0 ? { web_nic_secondary_ips = var.webdispatcher_server_nic_secondary_ips } : null), (
                                           length(local.web_admin_nic_ips) > 0                    ? { web_admin_nic_ips = local.web_admin_nic_ips } : null), (
                                           length(local.webdispatcher_loadbalancer_ips) > 0       ? { webdispatcher_loadbalancer_ips = local.webdispatcher_loadbalancer_ips } : null), (
                                           length(local.app_tags) > 0                             ? { app_tags = local.app_tags } : { app_tags = local.app_tags }), (
                                           length(local.scs_tags) > 0                             ? { scs_tags = local.scs_tags } : { scs_tags = local.scs_tags }), (
                                           length(local.web_tags) > 0                             ? { web_tags = local.web_tags } : { web_tags = local.web_tags }), (
                                           var.use_fence_kdump && var.scs_high_availability       ? { fence_kdump_disk_size = var.use_fence_kdump_size_gb_scs } : { fence_kdump_disk_size = 0 } ), (
                                           var.use_fence_kdump && var.scs_high_availability       ? { fence_kdump_lun_number = var.use_fence_kdump_lun_scs } : { fence_kdump_lun_number = -1 }
                                           )
                                         )

  database                             = merge(
                                            local.databases_temp,
                                           (local.db_os_specified                                 ? { os             = local.db_os }                           : null),
                                           (local.db_authentication_defined                       ? { authentication = local.db_authentication }               : null),
                                           (local.db_avset_arm_ids_defined                        ? { avset_arm_ids  = local.avset_arm_ids }                   : null),
                                           (length(local.frontend_ips)      > 0                   ? { loadbalancer   = { frontend_ips = local.frontend_ips } } : { loadbalancer = { frontend_ips = [] } }),
                                           (length(local.db_tags)           > 0                   ? { tags           = local.db_tags }                         : null),
                                           (local.db_sid_specified                                ? { instance       = local.instance }                        : null), (
                                           ( var.use_fence_kdump &&
                                             var.database_high_availability )                     ? { fence_kdump_disk_size = var.use_fence_kdump_size_gb_db } : { fence_kdump_disk_size = 0 } ), (
                                           ( var.use_fence_kdump &&
                                             var.database_high_availability )                     ? { fence_kdump_lun_number = var.use_fence_kdump_lun_db } : { fence_kdump_lun_number = -1 }
                                           )
                                         )


  authentication                       = merge(local.authentication_temp, (
                                           local.username_specified            ? { username = local.username } : null), (
                                           local.password_specified            ? { password = local.password } : null), (
                                           local.path_to_public_key_specified  ? { path_to_public_key = local.path_to_public_key } : null), (
                                           local.path_to_private_key_specified ? { path_to_private_key = local.path_to_private_key } : null
                                           )
                                         )

  key_vault                            = merge(local.key_vault_temp, (
                                           local.user_keyvault_specified ? (
                                             {
                                               kv_user_id = local.user_keyvault
                                             }
                                           ) : null), (
                                           local.spn_keyvault_specified ? (
                                             {
                                               keyvault_id_for_deployment_credentials = local.spn_kv
                                             }
                                           ) : null
                                           )
                                         )

  options                              = merge(local.options_temp, (local.disk_encryption_set_defined ? (
                                           {
                                             disk_encryption_set_id = local.disk_encryption_set_id
                                           }
                                         ) : null))

  hana_ANF_volumes                     = {
                                            use_for_data                       = var.ANF_HANA_data
                                            data_volume_size                   = var.ANF_HANA_data_volume_size
                                            use_existing_data_volume           = var.ANF_HANA_data_use_existing_volume
                                            data_volume_name                   = var.ANF_HANA_data_volume_name
                                            data_volume_throughput             = var.ANF_HANA_data_volume_throughput
                                            data_volume_count                  = var.ANF_HANA_data_volume_count

                                            use_for_log                        = var.ANF_HANA_log
                                            log_volume_size                    = var.ANF_HANA_log_volume_size
                                            use_existing_log_volume            = var.ANF_HANA_log_use_existing
                                            log_volume_name                    = var.ANF_HANA_log_volume_name
                                            log_volume_throughput              = var.ANF_HANA_log_volume_throughput
                                            log_volume_count                   = var.ANF_HANA_log_volume_count

                                            use_for_shared                     = var.ANF_HANA_shared
                                            shared_volume_size                 = var.ANF_HANA_shared_volume_size
                                            use_existing_shared_volume         = var.ANF_HANA_shared_use_existing
                                            shared_volume_name                 = var.ANF_HANA_shared_volume_name
                                            shared_volume_throughput           = var.ANF_HANA_shared_volume_throughput

                                            use_for_usr_sap                    = var.ANF_usr_sap
                                            usr_sap_volume_size                = var.ANF_usr_sap_volume_size
                                            use_existing_usr_sap_volume        = var.ANF_usr_sap_use_existing
                                            usr_sap_volume_name                = var.ANF_usr_sap_volume_name
                                            usr_sap_volume_throughput          = var.ANF_usr_sap_throughput

                                            sapmnt_volume_size                 = var.sapmnt_volume_size
                                            use_for_sapmnt                     = var.ANF_sapmnt
                                            use_existing_sapmnt_volume         = var.ANF_sapmnt_use_existing
                                            sapmnt_volume_name                 = var.ANF_sapmnt_volume_name
                                            sapmnt_volume_throughput           = var.ANF_sapmnt_volume_throughput
                                            sapmnt_use_clone_in_secondary_zone = var.ANF_sapmnt_use_clone_in_secondary_zone

                                            use_AVG_for_data                   = var.ANF_HANA_use_AVG
                                            use_zones                          = var.ANF_HANA_use_Zones

                                          }

    dns_settings                         = {
                                            use_custom_dns_a_registration                = var.use_custom_dns_a_registration
                                            dns_zone_names                               = var.dns_zone_names
                                            management_dns_resourcegroup_name            = trimspace(coalesce(var.management_dns_resourcegroup_name, try(data.terraform_remote_state.landscape.outputs.management_dns_resourcegroup_name, local.saplib_resource_group_name)," "))
                                            management_dns_subscription_id               = trimspace(coalesce(var.management_dns_subscription_id, try(data.terraform_remote_state.landscape.outputs.management_dns_subscription_id, " ")," "))


                                            privatelink_dns_resourcegroup_name           = trimspace(coalesce(var.privatelink_dns_resourcegroup_name,
                                                                                             try(data.terraform_remote_state.landscape.outputs.privatelink_dns_resourcegroup_name,
                                                                                               try(data.terraform_remote_state.landscape.outputs.management_dns_resourcegroup_name, local.saplib_resource_group_name)
                                                                                             ),
                                                                                             " "
                                                                                           ))
                                            privatelink_dns_subscription_id              = trimspace(coalesce(var.privatelink_dns_subscription_id,
                                                                                              try(data.terraform_remote_state.landscape.outputs.privatelink_dns_subscription_id,
                                                                                                try(data.terraform_remote_state.landscape.outputs.management_dns_subscription_id, "")
                                                                                              ), " "
                                                                                            ))

                                            register_storage_accounts_keyvaults_with_dns = var.register_storage_accounts_keyvaults_with_dns
                                            register_endpoints_with_dns                  = var.register_endpoints_with_dns

                                            register_virtual_network_to_dns              = try(data.terraform_remote_state.landscape.outputs.register_virtual_network_to_dns, false)
                                          }

}
