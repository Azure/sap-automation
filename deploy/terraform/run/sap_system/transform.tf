
locals {

  enable_app_tier_deployment           = var.enable_app_tier_deployment && try(var.application_tier.enable_deployment, true)

  temp_infrastructure                  = {
                                            environment                      = coalesce(var.environment, try(var.infrastructure.environment, ""))
                                            region                           = lower(coalesce(var.location, try(var.infrastructure.region, "")))
                                            codename                         = try(var.codename, try(var.infrastructure.codename, ""))
                                            tags                             = try(merge(var.resourcegroup_tags, try(var.infrastructure.tags, {})), {})
                                            use_app_proximityplacementgroups = var.use_app_proximityplacementgroups
                                         }


  resource_group                       = {
    name                                    = try(coalesce(var.resourcegroup_name, try(var.infrastructure.resource_group.name, "")), "")
    arm_id                                  = try(coalesce(var.resourcegroup_arm_id, try(var.infrastructure.resource_group.arm_id, "")), "")
                                         }

  resource_group_defined               = (length(local.resource_group.name) + length(local.resource_group.arm_id) ) > 0

  ppg                                  = {
                                           arm_ids = distinct(concat(var.proximityplacementgroup_arm_ids, try(var.infrastructure.ppg.arm_ids, [])))
                                           names   = distinct(concat(var.proximityplacementgroup_names, try(var.infrastructure.ppg.names, [])))
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
                                             deploy                 = var.deploy_anchor_vm || length(try(var.infrastructure.anchor_vms, {})) > 0
                                             use_DHCP               = var.anchor_vm_use_DHCP || try(var.infrastructure.anchor_vms.use_DHCP, false)
                                             accelerated_networking = var.anchor_vm_accelerated_networking || try(var.infrastructure.anchor_vms.accelerated_networking, false)
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

  frontend_ips                          = try(coalesce(var.database_loadbalancer_ips, try(var.databases[0].loadbalancer.frontend_ip, [])), [])
  db_tags                               = try(coalesce(var.database_tags, try(var.databases[0].tags, {})), {})

  databases_temp                       = {
                                           database_cluster_type           = var.database_cluster_type
                                           database_server_count           = var.database_high_availability ? 2 * var.database_server_count : var.database_server_count
                                           database_vm_sku                 = var.database_vm_sku
                                           db_sizing_key                   = coalesce(var.db_sizing_dictionary_key, var.database_size, try(var.databases[0].size, ""))
                                           deploy_v1_monitoring_extension  = var.deploy_v1_monitoring_extension
                                           dual_nics                       = var.database_dual_nics || try(var.databases[0].dual_nics, false)
                                           high_availability               = var.database_high_availability || try(var.databases[0].high_availability, false)
                                           platform                        = var.database_platform
                                           use_ANF                         = var.database_HANA_use_ANF_scaleout_scenario || try(var.databases[0].use_ANF, false)
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
                                           zones                           = var.database_vm_zones
                                           stand_by_node_count             = var.stand_by_node_count
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
                                           coalesce(var.database_instance_number, try(var.databases[0].instance_number, "00"))
                                           ) : (
                                           "00"
                                          )
                                       }

  app_authentication                = {
                                        type     = var.app_tier_authentication_type
                                        username = var.automation_username
                                      }
  app_authentication_defined        = (length(local.app_authentication.type) + length(local.app_authentication.username)) > 3

  app_zones_temp                    = distinct(var.application_server_zones)
  scs_zones_temp                    = distinct(var.scs_server_zones)
  web_zones_temp                    = distinct(var.webdispatcher_server_zones)


  application_temp                  = {
                                        sid                             = try(coalesce(var.sid, try(var.application_tier.sid, "")), "")
                                        enable_deployment               = local.enable_app_tier_deployment
                                        use_DHCP                        = var.app_tier_use_DHCP || try(var.application_tier.use_DHCP, false)
                                        dual_nics                       = var.app_tier_dual_nics || try(var.application_tier.dual_nics, false)
                                        vm_sizing_dictionary_key        = try(coalesce(var.app_tier_sizing_dictionary_key, var.app_tier_vm_sizing, try(var.application_tier.vm_sizing, "")), "Optimized")
                                        application_server_count        = local.enable_app_tier_deployment ? (
                                                                            max(var.application_server_count, try(var.application_tier.application_server_count, 0))
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
                                        scs_server_count                = local.enable_app_tier_deployment ? (
                                                                            max(var.scs_server_count, try(var.application_tier.scs_server_count, 0))
                                                                            ) : (
                                                                            0
                                                                          )
                                        scs_high_availability           = local.enable_app_tier_deployment ? (
                                                                            var.scs_high_availability || try(var.application_tier.scs_high_availability, false)
                                                                            ) : (
                                                                            false
                                                                          )
                                        scs_cluster_type                = var.scs_cluster_type
                                        scs_instance_number             = coalesce(var.scs_instance_number, try(var.application_tier.scs_instance_number, "00"))
                                        ers_instance_number             = coalesce(var.ers_instance_number, try(var.application_tier.ers_instance_number, "02"))
                                        scs_sku                         = var.scs_server_sku
                                        scs_use_ppg                     = var.scs_server_count > 0 ? var.use_scalesets_for_deployment ? (
                                                                            false) : (
                                                                            var.scs_server_use_ppg
                                                                          ) : false
                                        scs_use_avset                   = var.scs_server_count == 0 || var.use_scalesets_for_deployment || !local.enable_app_tier_deployment ? (
                                                                            false) : (
                                                                            var.scs_server_use_avset
                                                                          )
                                        webdispatcher_count             = local.enable_app_tier_deployment ? (
                                                                            max(var.webdispatcher_server_count, try(var.application_tier.webdispatcher_count, 0))
                                                                            ) : (
                                                                            0
                                                                          )
                                        web_instance_number             = var.web_instance_number
                                        web_sku                         = try(coalesce(var.webdispatcher_server_sku, var.application_tier.web_sku), "")
                                        web_use_ppg                     = (var.webdispatcher_server_count) > 0 ? var.use_scalesets_for_deployment ? (
                                                                            false) : (
                                                                            var.webdispatcher_server_use_ppg
                                                                          ) : false
                                        web_use_avset                   = var.webdispatcher_server_count == 0 || var.use_scalesets_for_deployment || length(var.webdispatcher_server_zones) > 0 || !local.enable_app_tier_deployment ? (
                                                                            false) : (
                                                                            var.webdispatcher_server_use_avset
                                                                          )
                                        deploy_v1_monitoring_extension  = var.deploy_v1_monitoring_extension
                                        user_assigned_identity_id       = var.user_assigned_identity_id
                                      }

  app_tags                          = try(coalesce(var.application_server_tags, try(var.application_tier.app_tags, {})), {})
  scs_tags                          = try(coalesce(var.scs_server_tags, try(var.application_tier.scs_tags, {})), {})
  web_tags                          = try(coalesce(var.webdispatcher_server_tags, try(var.application_tier.web_tags, {})), {})

  app_os = {
    source_image_id                 = try(var.application_server_image.source_image_id, "")
    publisher                       = try(var.application_server_image.publisher,       "SUSE")
    offer                           = try(var.application_server_image.offer,           "sles-sap-15-sp3")
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
                                        os_type         = try(coalesce(var.scs_server_image.os_type, var.application_server_image.os_type, "LINUX"), "LINUX")
                                        source_image_id = try(coalesce(var.scs_server_image.source_image_id, try(var.application_tier.scs_os.source_image_id, "")), "")
                                        publisher       = try(coalesce(var.scs_server_image.publisher, try(var.application_tier.scs_os.publisher, "SUSE")), "SUSE")
                                        offer           = try(coalesce(var.scs_server_image.offer, try(var.application_tier.scs_os.offer, "sles-sap-15-sp3")), "sles-sap-15-sp3")
                                        sku             = try(coalesce(var.scs_server_image.sku, try(var.application_tier.scs_os.sku, "gen2")), "gen2")
                                        version         = try(coalesce(var.scs_server_image.version, try(var.application_tier.scs_os.version, "latest")), "latest")
                                        type            = try(var.database_vm_image.type, "marketplace")
                                      }

  scs_os_specified                  = (length(local.scs_os.source_image_id) + length(local.scs_os.publisher)) > 0

  validated_use_simple_mount        = var.use_simple_mount ? (
                                        upper(local.scs_os.publisher) != "SUSE" || !(var.scs_high_availability) ? (
                                         false) : (
                                         contains(["sles-sap-15-sp3", "sles-sap-15-sp4", "sles-sap-15-sp5"], local.scs_os.offer) ? (
                                           var.use_simple_mount) : (
                                           false
                                         )
                                       )) : (
                                       false
                                       )

  web_os                            = {
                                        os_type         = try(coalesce(var.webdispatcher_server_image.os_type, var.application_server_image.os_type, "LINUX"), "LINUX")
                                        source_image_id = try(coalesce(var.webdispatcher_server_image.source_image_id, try(var.application_tier.web_os.source_image_id, "")), "")
                                        publisher       = try(coalesce(var.webdispatcher_server_image.publisher, try(var.application_tier.web_os.publisher, "SUSE")), "SUSE")
                                        offer           = try(coalesce(var.webdispatcher_server_image.offer, try(var.application_tier.web_os.offer, "sles-sap-15-sp3")), "sles-sap-15-sp3")
                                        sku             = try(coalesce(var.webdispatcher_server_image.sku, try(var.application_tier.web_os.sku, "gen2")), "gen2")
                                        version         = try(coalesce(var.webdispatcher_server_image.version, try(var.application_tier.web_os.version, "latest")), "latest")
                                        type            = try(var.database_vm_image.type, "marketplace")
                                      }
  web_os_specified                     = (length(local.web_os.source_image_id) + length(local.web_os.publisher)) > 0

  vnets                                = {  }

  sap                                  = {
                                           logical_name = try(coalesce(var.network_logical_name, try(var.infrastructure.vnets.sap.logical_name, "")), "")
                                         }

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

  app_nic_ips                          = distinct(concat(var.application_server_app_nic_ips, try(var.application_tier.app_nic_ips, [])))
  app_nic_secondary_ips                = distinct(var.application_server_app_nic_ips)
  app_admin_nic_ips                    = distinct(concat(var.application_server_admin_nic_ips, try(var.application_tier.app_admin_nic_ips, [])))

  scs_nic_ips                          = distinct(concat(var.scs_server_app_nic_ips, try(var.application_tier.scs_nic_ips, [])))
  scs_admin_nic_ips                    = distinct(concat(var.scs_server_admin_nic_ips, try(var.application_tier.scs_admin_nic_ips, [])))
  scs_server_loadbalancer_ips          = distinct(concat(var.scs_server_loadbalancer_ips, try(var.application_tier.scs_server_loadbalancer_ips, [])))

  web_nic_ips                          = distinct(concat(var.webdispatcher_server_app_nic_ips, try(var.application_tier.web_nic_ips, [])))
  web_admin_nic_ips                    = distinct(concat(var.webdispatcher_server_admin_nic_ips, try(var.application_tier.web_admin_nic_ips, [])))
  webdispatcher_loadbalancer_ips       = distinct(concat(var.webdispatcher_server_loadbalancer_ips, try(var.application_tier.webdispatcher_loadbalancer_ips, [])))

  subnet_admin                         = merge((
                                           {
                                             "name" = try(var.infrastructure.vnets.sap.subnet_admin.name, var.admin_subnet_name)
                                           }
                                           ), (
                                           local.subnet_admin_arm_id_defined ?
                                           (
                                             {
                                               "arm_id" = try(var.infrastructure.vnets.sap.subnet_admin.arm_id, var.admin_subnet_arm_id)
                                             }
                                             ) : (
                                             null
                                           )), (
                                           {
                                             "prefix" = try(var.infrastructure.vnets.sap.subnet_admin.prefix, var.admin_subnet_address_prefix)
                                           }
                                           ), (
                                           local.subnet_admin_nsg_defined ? (
                                             {
                                               "nsg" = {
                                                 "name"   = try(var.infrastructure.vnets.sap.subnet_admin.nsg.name, var.admin_subnet_nsg_name)
                                                 "arm_id" = try(var.infrastructure.vnets.sap.subnet_admin.nsg.arm_id, var.admin_subnet_nsg_arm_id)
                                               }
                                             }
                                             ) : (
                                             null
                                           )
                                           )
                                         )

  subnet_db                            = merge((
                                             {
                                               "name" = try(var.infrastructure.vnets.sap.subnet_db.name, var.db_subnet_name)
                                             }
                                             ), (
                                             local.subnet_db_arm_id_defined ? (
                                               {
                                                 "arm_id" = try(var.infrastructure.vnets.sap.subnet_db.arm_id, var.db_subnet_arm_id)
                                               }
                                               ) : (
                                             null)
                                             ), (
                                             {
                                               "prefix" = try(var.infrastructure.vnets.sap.subnet_db.prefix, var.db_subnet_address_prefix)
                                             }
                                             ), (
                                             local.subnet_db_nsg_defined ? (
                                               {
                                                 "nsg" = {
                                                           "name"   = try(var.infrastructure.vnets.sap.subnet_db.nsg.name, var.db_subnet_nsg_name)
                                                           "arm_id" = try(var.infrastructure.vnets.sap.subnet_db.nsg.arm_id, var.db_subnet_nsg_arm_id)
                                                         }
                                               }
                                             ) : null
                                           )
                                         )
  subnet_app                           = merge(
                                           (
                                               {
                                                 "name"     = try(var.infrastructure.vnets.sap.subnet_app.name, var.app_subnet_name)
                                               }
                                             ), (
                                             local.subnet_app_arm_id_defined ? (
                                               {
                                                 "arm_id"   = try(var.infrastructure.vnets.sap.subnet_app.arm_id, var.app_subnet_arm_id)
                                               }
                                               ) : (
                                               null
                                             )), (
                                               {
                                                 "prefix"   = try(var.infrastructure.vnets.sap.subnet_app.prefix, var.app_subnet_address_prefix)
                                               }
                                             ), (
                                             local.subnet_app_nsg_defined ? (
                                               {
                                                 "nsg" = {
                                                           "name"   = try(var.infrastructure.vnets.sap.subnet_app.nsg.name, var.app_subnet_nsg_name)
                                                           "arm_id" = try(var.infrastructure.vnets.sap.subnet_app.nsg.arm_id, var.app_subnet_nsg_arm_id)
                                                         }
                                               }
                                             ) : null
                                           )
                                         )
  subnet_web                           = merge(
                                           (
                                             {
                                               "name" = try(var.infrastructure.vnets.sap.subnet_web.name, var.web_subnet_name)
                                             }
                                             ), (
                                             local.subnet_web_arm_id_defined ? (
                                               {
                                                 "arm_id" = try(var.infrastructure.vnets.sap.subnet_web.arm_id, var.web_subnet_arm_id)
                                               }
                                               ) : (
                                               null
                                             )), (
                                             {
                                               "prefix" = try(var.infrastructure.vnets.sap.subnet_web.prefix, var.web_subnet_address_prefix)
                                             }
                                             ), (
                                             local.subnet_web_nsg_defined ? (
                                               {
                                                 "nsg" = {
                                                           "name"   = try(var.infrastructure.vnets.sap.subnet_web.nsg.name, var.web_subnet_nsg_name)
                                                           "arm_id" = try(var.infrastructure.vnets.sap.subnet_web.nsg.arm_id, var.web_subnet_nsg_arm_id)
                                                         }
                                               }
                                             ) : null
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
                                          )
                                          )
                                        )

  temp_vnet                            = merge(local.vnets, { sap = local.all_subnets })

  user_keyvault_specified              = (
                                           length(var.user_keyvault_id) +
                                           length(try(var.key_vault.kv_user_id, ""))
                                         ) > 0
  user_keyvault                        = local.user_keyvault_specified ? (
                                           try(coalesce(var.user_keyvault_id, try(var.key_vault.kv_user_id, "")), "")) : (
                                           ""
                                         )

  spn_keyvault_specified               = (
                                           length(var.spn_keyvault_id) +
                                           length(try(var.key_vault.kv_spn_id, ""))
                                         ) > 0
  spn_kv                               = local.spn_keyvault_specified ? try(coalesce(var.spn_keyvault_id, try(var.key_vault.kv_spn_id, "")), "") : ""

  username_specified                   = (length(var.automation_username) + length(try(var.authentication.username, ""))) > 0
  username                             = try(coalesce(var.automation_username, try(var.authentication.username, "")), "")
  password_specified                   = (length(var.automation_password) + length(try(var.authentication.password, ""))) > 0
  password                             = try(coalesce(var.automation_password, try(var.authentication.password, "")), "")
  path_to_public_key_specified         = (length(var.automation_path_to_public_key) + length(try(var.authentication.path_to_public_key, ""))) > 0
  path_to_public_key                   = try(coalesce(var.automation_path_to_public_key, try(var.authentication.path_to_public_key, "")), "")
  path_to_private_key_specified        = (length(var.automation_path_to_private_key) + length(try(var.authentication.path_to_private_key, ""))) > 0
  path_to_private_key                  = try(coalesce(var.automation_path_to_private_key, try(var.authentication.path_to_private_key, "")), "")

  disk_encryption_set_defined          = (length(var.vm_disk_encryption_set_id) + length(try(var.options.disk_encryption_set_id, ""))) > 0
  disk_encryption_set_id               = try(coalesce(var.vm_disk_encryption_set_id, try(var.options.disk_encryption_set_id, null)), null)

  infrastructure                       = merge(local.temp_infrastructure, (
                                           local.resource_group_defined ? { resource_group = local.resource_group } : null), (
                                           local.app_ppg_defined        ? { app_ppg = local.app_ppg } : null), (
                                           local.ppg_defined            ? { ppg = local.ppg } : null), (
                                           local.deploy_anchor_vm       ? { anchor_vms = local.anchor_vms } : null),
                                           { vnets = local.temp_vnet }
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
                                           length(local.scs_server_loadbalancer_ips) > 0                           ? { scs_server_loadbalancer_ips = local.scs_server_loadbalancer_ips } : null), (
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
                                               kv_spn_id = local.spn_kv
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


}
