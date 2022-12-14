
locals {

  enable_app_tier_deployment = var.enable_app_tier_deployment && try(var.application_tier.enable_deployment, true)

  temp_infrastructure = {
    environment = coalesce(var.environment, try(var.infrastructure.environment, ""))
    region      = lower(coalesce(var.location, try(var.infrastructure.region, "")))
    codename    = try(var.codename, try(var.infrastructure.codename, ""))
    tags        = try(merge(var.resourcegroup_tags, try(var.infrastructure.tags, {})), {})
  }


  resource_group = {
    name   = try(coalesce(var.resourcegroup_name, try(var.infrastructure.resource_group.name, "")), "")
    arm_id = try(coalesce(var.resourcegroup_arm_id, try(var.infrastructure.resource_group.arm_id, "")), "")
  }

  resource_group_defined = (
    length(local.resource_group.name) +
    length(local.resource_group.arm_id)
  ) > 0

  ppg = {
    arm_ids = distinct(concat(var.proximityplacementgroup_arm_ids, try(var.infrastructure.ppg.arm_ids, [])))
    names   = distinct(concat(var.proximityplacementgroup_names, try(var.infrastructure.ppg.names, [])))
  }
  ppg_defined = (length(local.ppg.names) + length(local.ppg.arm_ids)) > 0

  deploy_anchor_vm = var.deploy_anchor_vm || length(try(var.infrastructure.anchor_vms, {})) > 0

  anchor_vms = local.deploy_anchor_vm ? ({
    deploy                 = var.deploy_anchor_vm || length(try(var.infrastructure.anchor_vms, {})) > 0
    use_DHCP               = var.anchor_vm_use_DHCP || try(var.infrastructure.anchor_vms.use_DHCP, false)
    accelerated_networking = var.anchor_vm_accelerated_networking || try(var.infrastructure.anchor_vms.accelerated_networking, false)
    sku                    = try(coalesce(var.anchor_vm_sku, try(var.infrastructure.anchor_vms.sku, "Standard_D2s_v3")), "Standard_D2s_v3")
    os = {
      os_type         = try(coalesce(var.anchor_vm_image.os_type, try(var.infrastructure.anchor_vms.os.os_type, "")), "LINUX")
      source_image_id = try(coalesce(var.anchor_vm_image.source_image_id, try(var.infrastructure.anchor_vms.os.source_image_id, "")), "")
      publisher       = try(coalesce(var.anchor_vm_image.publisher, try(var.infrastructure.anchor_vms.os.publisher, "")), "")
      offer           = try(coalesce(var.anchor_vm_image.offer, try(var.infrastructure.anchor_vms.os.offer, "")), "")
      sku             = try(coalesce(var.anchor_vm_image.sku, try(var.infrastructure.anchor_vms.os.sku, "")), "")
      version         = try(coalesce(var.anchor_vm_image.version, try(var.infrastructure.anchor_vms.version, "")), "")
    }

    authentication = {
      type     = try(coalesce(var.anchor_vm_authentication_type, try(var.infrastructure.anchor_vms.authentication.type, "key")), "key")
      username = try(coalesce(var.anchor_vm_authentication_username, try(var.authentication.username, "azureadm")), "azureadm")
    }
    nic_ips = distinct(concat(var.anchor_vm_nic_ips, try(var.infrastructure.anchor_vms.nic_ips, [])))
    }
    ) : (
    null
  )


  authentication_temp = {
  }

  options_temp = {
    enable_secure_transfer = true
    resource_offset        = max(var.resource_offset, try(var.options.resource_offset, 0))
    nsg_asg_with_vnet      = var.nsg_asg_with_vnet || try(var.options.nsg_asg_with_vnet, false)
    legacy_nic_order       = var.legacy_nic_order || try(var.options.legacy_nic_order, false)
  }

  key_vault_temp = {
  }

  db_authentication = {
    type     = try(coalesce(var.database_vm_authentication_type, try(var.databases[0].authentication.type, "")), "")
    username = try(coalesce(var.automation_username, try(var.databases[0].authentication.username, "")), "")
  }
  db_authentication_defined = (length(local.db_authentication.type) + length(local.db_authentication.username)) > 3
  avset_arm_ids             = distinct(concat(var.database_vm_avset_arm_ids, try(var.databases[0].avset_arm_ids, [])))
  db_avset_arm_ids_defined  = length(local.avset_arm_ids) > 0
  frontend_ips              = try(coalesce(var.database_loadbalancer_ips, try(var.databases[0].loadbalancer.frontend_ip, [])), [])
  db_tags                   = try(coalesce(var.database_tags, try(var.databases[0].tags, {})), {})

  databases_temp = {
    high_availability = var.database_high_availability || try(var.databases[0].high_availability, false)
    use_DHCP          = var.database_vm_use_DHCP || try(var.databases[0].use_DHCP, false)

    platform      = var.database_platform
    db_sizing_key = coalesce(var.db_sizing_dictionary_key, var.database_size, try(var.databases[0].size, ""))

    use_ANF   = var.database_HANA_use_ANF_scaleout_scenario || try(var.databases[0].use_ANF, false)
    dual_nics = var.database_dual_nics || try(var.databases[0].dual_nics, false)
    no_ppg    = var.database_no_ppg || try(var.databases[0].no_ppg, false)
    no_avset  = var.database_no_avset || try(var.databases[0].no_avset, false)

  }

  db_os = {
    os_type = length(var.database_vm_image.source_image_id) == 0 ? (
      upper(var.database_vm_image.publisher) == "MICROSOFTWINDOWSSERVER") ? "WINDOWS" : try(var.database_vm_image.os_type, "LINUX)") : (
      length(var.database_vm_image.os_type) == 0 ? "LINUX" : var.database_vm_image.os_type
    )
    source_image_id = try(var.database_vm_image.source_image_id, "")
    publisher       = try(var.database_vm_image.publisher, "")
    offer           = try(var.database_vm_image.offer, "")
    sku             = try(var.database_vm_image.sku, "")
    version         = try(var.database_vm_image.version, "")
    type            = try(var.database_vm_image.type, "marketplace")
  }

  db_os_specified = (length(local.db_os.source_image_id) + length(local.db_os.publisher)) > 0

  db_sid_specified = (length(var.database_sid) + length(try(var.databases[0].sid, ""))) > 0

  instance = {
    sid = upper(try(coalesce(
      var.database_sid,
      try(var.databases[0].sid, "")),
      upper(var.database_platform) == "HANA" ? (
        "HDB"
        ) : (
      substr(var.database_platform, 0, 3))
    ))
    instance_number = upper(local.databases_temp.platform) == "HANA" ? (
      coalesce(var.database_instance_number, try(var.databases[0].instance_number, "00"))
      ) : (
      "00"
    )
  }

  app_authentication = {
    type     = try(coalesce(var.app_tier_authentication_type, try(var.application_tier.authentication.type, "")), "")
    username = try(coalesce(var.automation_username, try(var.application_tier.authentication.username, "")), "")
  }
  app_authentication_defined = (length(local.app_authentication.type) + length(local.app_authentication.username)) > 3

  application_temp = {
    sid = try(coalesce(var.sid, try(var.application_tier.sid, "")), "")

    enable_deployment        = local.enable_app_tier_deployment
    use_DHCP                 = var.app_tier_use_DHCP || try(var.application_tier.use_DHCP, false)
    dual_nics                = var.app_tier_dual_nics || try(var.application_tier.dual_nics, false)
    vm_sizing_dictionary_key = try(coalesce(var.app_tier_sizing_dictionary_key, var.app_tier_vm_sizing, try(var.application_tier.vm_sizing, "")), "Optimized")

    application_server_count = local.enable_app_tier_deployment ? (
      max(var.application_server_count, try(var.application_tier.application_server_count, 0))
      ) : (
      0
    )
    app_sku       = try(coalesce(var.application_server_sku, var.application_tier.app_sku), "")
    app_no_ppg    = var.application_server_no_ppg || try(var.application_tier.app_no_ppg, false)
    app_no_avset  = var.application_server_no_avset || try(var.application_tier.app_no_avset, false)
    avset_arm_ids = var.application_server_vm_avset_arm_ids

    scs_server_count = local.enable_app_tier_deployment ? (
      max(var.scs_server_count, try(var.application_tier.scs_server_count, 0))
      ) : (
      0
    )
    scs_high_availability = local.enable_app_tier_deployment ? (
      var.scs_high_availability || try(var.application_tier.scs_high_availability, false)
      ) : (
      false
    )
    scs_instance_number = coalesce(var.scs_instance_number, try(var.application_tier.scs_instance_number, "00"))
    ers_instance_number = coalesce(var.ers_instance_number, try(var.application_tier.ers_instance_number, "02"))

    scs_sku      = try(coalesce(var.scs_server_sku, var.application_tier.scs_sku), "")
    scs_no_ppg   = var.scs_server_no_ppg || try(var.application_tier.scs_no_ppg, false)
    scs_no_avset = var.scs_server_no_avset || try(var.application_tier.scs_no_avset, false)

    webdispatcher_count = local.enable_app_tier_deployment ? (
      max(var.webdispatcher_server_count, try(var.application_tier.webdispatcher_count, 0))
      ) : (
      0
    )
    web_sku      = try(coalesce(var.webdispatcher_server_sku, var.application_tier.web_sku), "")
    web_no_ppg   = var.webdispatcher_server_no_ppg || try(var.application_tier.web_no_ppg, false)
    web_no_avset = var.webdispatcher_server_no_avset || try(var.application_tier.web_no_avset, false)

  }

  app_zones_temp = distinct(concat(var.application_server_zones, try(var.application_tier.app_zones, [])))
  scs_zones_temp = distinct(concat(var.scs_server_zones, try(var.application_tier.scs_zones, [])))
  web_zones_temp = distinct(concat(var.webdispatcher_server_zones, try(var.application_tier.web_zones, [])))

  app_tags = try(coalesce(var.application_server_tags, try(var.application_tier.app_tags, {})), {})
  scs_tags = try(coalesce(var.scs_server_tags, try(var.application_tier.scs_tags, {})), {})
  web_tags = try(coalesce(var.webdispatcher_server_tags, try(var.application_tier.web_tags, {})), {})

  app_os = {
    os_type = length(var.application_server_image.source_image_id) == 0 ? (
      upper(var.application_server_image.publisher) == "MICROSOFTWINDOWSSERVER") ? "WINDOWS" : try(var.application_server_image.os_type, "LINUX") : (
      length(var.application_server_image.os_type) == 0 ? "LINUX" : var.application_server_image.os_type
    )
    source_image_id = try(var.application_server_image.source_image_id, "")
    publisher       = try(var.application_server_image.publisher, "SUSE")
    offer           = try(var.application_server_image.offer, "sles-sap-15-sp3")
    sku             = try(var.application_server_image.sku, "gen2")
    version         = try(var.application_server_image.version, "latest")
    type            = try(var.database_vm_image.type, "marketplace")
  }

  app_os_specified = (length(local.app_os.source_image_id) + length(local.app_os.publisher)) > 0

  scs_os = {
    os_type         = try(coalesce(var.scs_server_image.os_type, var.application_server_image.os_type, "LINUX"), "LINUX")
    source_image_id = try(coalesce(var.scs_server_image.source_image_id, try(var.application_tier.scs_os.source_image_id, "")), "")
    publisher       = try(coalesce(var.scs_server_image.publisher, try(var.application_tier.scs_os.publisher, "SUSE")), "SUSE")
    offer           = try(coalesce(var.scs_server_image.offer, try(var.application_tier.scs_os.offer, "sles-sap-15-sp3")), "sles-sap-15-sp3")
    sku             = try(coalesce(var.scs_server_image.sku, try(var.application_tier.scs_os.sku, "gen2")), "gen2")
    version         = try(coalesce(var.scs_server_image.version, try(var.application_tier.scs_os.version, "latest")), "latest")
    type            = try(var.database_vm_image.type, "marketplace")
  }
  scs_os_specified = (length(local.scs_os.source_image_id) + length(local.scs_os.publisher)) > 0

  web_os = {
    os_type         = try(coalesce(var.webdispatcher_server_image.os_type, var.application_server_image.os_type, "LINUX"), "LINUX")
    source_image_id = try(coalesce(var.webdispatcher_server_image.source_image_id, try(var.application_tier.web_os.source_image_id, "")), "")
    publisher       = try(coalesce(var.webdispatcher_server_image.publisher, try(var.application_tier.web_os.publisher, "SUSE")), "SUSE")
    offer           = try(coalesce(var.webdispatcher_server_image.offer, try(var.application_tier.web_os.offer, "sles-sap-15-sp3")), "sles-sap-15-sp3")
    sku             = try(coalesce(var.webdispatcher_server_image.sku, try(var.application_tier.web_os.sku, "gen2")), "gen2")
    version         = try(coalesce(var.webdispatcher_server_image.version, try(var.application_tier.web_os.version, "latest")), "latest")
    type            = try(var.database_vm_image.type, "marketplace")
  }
  web_os_specified = (length(local.web_os.source_image_id) + length(local.web_os.publisher)) > 0

  vnets = {
  }

  sap = {
    logical_name = try(coalesce(var.network_logical_name, try(var.infrastructure.vnets.sap.logical_name, "")), "")
  }

  subnet_admin_defined = (
    length(var.admin_subnet_address_prefix) +
    length(try(var.infrastructure.vnets.sap.subnet_admin.prefix, "")) +
    length(var.admin_subnet_arm_id) +
    length(try(var.infrastructure.vnets.sap.subnet_admin.arm_id, ""))
  ) > 0

  subnet_admin_arm_id_defined = (
    length(var.admin_subnet_arm_id) +
    length(try(var.infrastructure.vnets.sap.subnet_admin.arm_id, ""))
  ) > 0

  subnet_admin_nsg_defined = (
    length(var.admin_subnet_nsg_name) +
    length(try(var.infrastructure.vnets.sap.subnet_admin.nsg.name, "")) +
    length(var.admin_subnet_nsg_arm_id) +
    length(try(var.infrastructure.vnets.sap.subnet_admin.nsg.arm_id, ""))
  ) > 0

  subnet_db_defined = (
    length(var.db_subnet_address_prefix) +
    length(try(var.infrastructure.vnets.sap.subnet_db.prefix, "")) +
    length(var.db_subnet_arm_id) +
    length(try(var.infrastructure.vnets.sap.subnet_db.arm_id, ""))
  ) > 0

  subnet_db_arm_id_defined = (
    length(var.db_subnet_arm_id) +
    length(try(var.infrastructure.vnets.sap.subnet_db.arm_id, ""))
  ) > 0

  subnet_db_nsg_defined = (
    length(var.db_subnet_nsg_name) +
    length(try(var.infrastructure.vnets.sap.subnet_db.nsg.name, "")) +
    length(var.db_subnet_nsg_arm_id) +
    length(try(var.infrastructure.vnets.sap.subnet_db.nsg.arm_id, ""))
  ) > 0

  subnet_app_defined = (
    length(var.app_subnet_address_prefix) +
    length(try(var.infrastructure.vnets.sap.subnet_app.prefix, "")) +
    length(var.app_subnet_arm_id) +
    length(try(var.infrastructure.vnets.sap.subnet_app.arm_id, ""))
  ) > 0

  subnet_app_arm_id_defined = (
    length(var.app_subnet_arm_id) +
    length(try(var.infrastructure.vnets.sap.subnet_app.arm_id, ""))
  ) > 0

  subnet_app_nsg_defined = (
    length(var.app_subnet_nsg_name) +
    length(try(var.infrastructure.vnets.sap.subnet_app.nsg.name, "")) +
    length(var.app_subnet_nsg_arm_id) +
    length(try(var.infrastructure.vnets.sap.subnet_app.nsg.arm_id, ""))
  ) > 0

  subnet_web_defined = (
    length(var.web_subnet_address_prefix) +
    length(try(var.infrastructure.vnets.sap.subnet_web.prefix, "")) +
    length(var.web_subnet_arm_id) +
    length(try(var.infrastructure.vnets.sap.subnet_web.arm_id, ""))
  ) > 0

  subnet_web_arm_id_defined = (
    length(var.web_subnet_arm_id) +
    length(try(var.infrastructure.vnets.sap.subnet_web.arm_id, ""))
  ) > 0

  subnet_web_nsg_defined = (
    length(var.web_subnet_nsg_name) +
    length(try(var.infrastructure.vnets.sap.subnet_web.nsg.name, "")) +
    length(var.web_subnet_nsg_arm_id) +
    length(try(var.infrastructure.vnets.sap.subnet_web.nsg.arm_id, ""))
  ) > 0

  app_nic_ips           = distinct(concat(var.application_server_app_nic_ips, try(var.application_tier.app_nic_ips, [])))
  app_nic_secondary_ips = distinct(var.application_server_app_nic_ips)
  app_admin_nic_ips     = distinct(concat(var.application_server_admin_nic_ips, try(var.application_tier.app_admin_nic_ips, [])))

  scs_nic_ips       = distinct(concat(var.scs_server_app_nic_ips, try(var.application_tier.scs_nic_ips, [])))
  scs_admin_nic_ips = distinct(concat(var.scs_server_admin_nic_ips, try(var.application_tier.scs_admin_nic_ips, [])))
  scs_lb_ips        = distinct(concat(var.scs_server_loadbalancer_ips, try(var.application_tier.scs_lb_ips, [])))

  web_nic_ips       = distinct(concat(var.webdispatcher_server_app_nic_ips, try(var.application_tier.web_nic_ips, [])))
  web_admin_nic_ips = distinct(concat(var.webdispatcher_server_admin_nic_ips, try(var.application_tier.web_admin_nic_ips, [])))
  web_lb_ips        = distinct(concat(var.webdispatcher_server_loadbalancer_ips, try(var.application_tier.web_lb_ips, [])))

  subnet_admin = merge((
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

  subnet_db = merge(
    (
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
  subnet_app = merge(
    (
      {
        "name" = try(var.infrastructure.vnets.sap.subnet_app.name, var.app_subnet_name)
      }
      ), (
      local.subnet_app_arm_id_defined ? (
        {
          "arm_id" = try(var.infrastructure.vnets.sap.subnet_app.arm_id, var.app_subnet_arm_id)
        }
        ) : (
        null
      )), (
      {
        "prefix" = try(var.infrastructure.vnets.sap.subnet_app.prefix, var.app_subnet_address_prefix)
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
  subnet_web = merge(
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

  all_subnets = merge(local.sap, (
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

  temp_vnet = merge(local.vnets, { sap = local.all_subnets })

  db_zones_temp = distinct(concat(var.database_vm_zones, try(var.databases[0].zones, [])))

  user_keyvault_specified = (
    length(var.user_keyvault_id) +
    length(try(var.key_vault.kv_user_id, ""))
  ) > 0
  user_keyvault = local.user_keyvault_specified ? (
    try(coalesce(var.user_keyvault_id, try(var.key_vault.kv_user_id, "")), "")) : (
    ""
  )

  spn_keyvault_specified = (
    length(var.spn_keyvault_id) +
    length(try(var.key_vault.kv_spn_id, ""))
  ) > 0
  spn_kv = local.spn_keyvault_specified ? try(coalesce(var.spn_keyvault_id, try(var.key_vault.kv_spn_id, "")), "") : ""

  username_specified            = (length(var.automation_username) + length(try(var.authentication.username, ""))) > 0
  username                      = try(coalesce(var.automation_username, try(var.authentication.username, "")), "")
  password_specified            = (length(var.automation_password) + length(try(var.authentication.password, ""))) > 0
  password                      = try(coalesce(var.automation_password, try(var.authentication.password, "")), "")
  path_to_public_key_specified  = (length(var.automation_path_to_public_key) + length(try(var.authentication.path_to_public_key, ""))) > 0
  path_to_public_key            = try(coalesce(var.automation_path_to_public_key, try(var.authentication.path_to_public_key, "")), "")
  path_to_private_key_specified = (length(var.automation_path_to_private_key) + length(try(var.authentication.path_to_private_key, ""))) > 0
  path_to_private_key           = try(coalesce(var.automation_path_to_private_key, try(var.authentication.path_to_private_key, "")), "")

  disk_encryption_set_defined = (length(var.vm_disk_encryption_set_id) + length(try(var.options.disk_encryption_set_id, ""))) > 0
  disk_encryption_set_id      = try(coalesce(var.vm_disk_encryption_set_id, try(var.options.disk_encryption_set_id, null)), null)

  infrastructure = merge(local.temp_infrastructure, (
    local.resource_group_defined ? { resource_group = local.resource_group } : null), (
    local.ppg_defined ? { ppg = local.ppg } : null), (
    local.deploy_anchor_vm ? { anchor_vms = local.anchor_vms } : null),
    { vnets = local.temp_vnet }
  )

  application_tier = merge(local.application_temp, (
    local.app_authentication_defined ? { authentication = local.app_authentication } : null), (
    local.app_os_specified ? { app_os = local.app_os } : null), (
    local.scs_os_specified ? { scs_os = local.scs_os } : (local.app_os_specified ? { scs_os = local.app_os } : null)), (
    local.web_os_specified ? { web_os = local.web_os } : (local.app_os_specified ? { web_os = local.app_os } : null)), (
    length(local.app_zones_temp) > 0 ? { app_zones = local.app_zones_temp } : null), (
    length(local.scs_zones_temp) > 0 ? { scs_zones = local.scs_zones_temp } : null), (
    length(local.web_zones_temp) > 0 ? { web_zones = local.web_zones_temp } : null), (
    length(local.app_nic_ips) > 0 ? { app_nic_ips = local.app_nic_ips } : null), (
    length(var.application_server_nic_secondary_ips) > 0 ? { app_nic_secondary_ips = var.application_server_nic_secondary_ips } : null), (
    length(local.app_admin_nic_ips) > 0 ? { app_admin_nic_ips = local.app_admin_nic_ips } : null), (
    length(local.scs_nic_ips) > 0 ? { scs_nic_ips = local.scs_nic_ips } : null), (
    length(var.scs_server_nic_secondary_ips) > 0 ? { scs_nic_secondary_ips = var.scs_server_nic_secondary_ips } : null), (
    length(local.scs_admin_nic_ips) > 0 ? { scs_admin_nic_ips = local.scs_admin_nic_ips } : null), (
    length(local.scs_lb_ips) > 0 ? { scs_lb_ips = local.scs_lb_ips } : null), (
    length(local.web_nic_ips) > 0 ? { web_nic_ips = local.web_nic_ips } : null), (
    length(var.webdispatcher_server_nic_secondary_ips) > 0 ? { web_nic_secondary_ips = var.webdispatcher_server_nic_secondary_ips } : null), (
    length(local.web_admin_nic_ips) > 0 ? { web_admin_nic_ips = local.web_admin_nic_ips } : null), (
    length(local.web_lb_ips) > 0 ? { web_lb_ips = local.web_lb_ips } : null), (
    length(local.app_tags) > 0 ? { app_tags = local.app_tags } : null), (
    length(local.scs_tags) > 0 ? { scs_tags = local.scs_tags } : null), (
    length(local.web_tags) > 0 ? { web_tags = local.web_tags } : null
    )
  )

  database = merge(local.databases_temp, (
    local.db_os_specified ? { os = local.db_os } : null), (
    local.db_authentication_defined ? { authentication = local.db_authentication } : null), (
    local.db_avset_arm_ids_defined ? { avset_arm_ids = local.avset_arm_ids } : null), (
    length(local.db_zones_temp) > 0 ? { zones = local.db_zones_temp } : null), (
    length(local.frontend_ips) > 0 ? { loadbalancer = { frontend_ips = local.frontend_ips } } : { loadbalancer = { frontend_ips = [] } }), (
    length(local.db_tags) > 0 ? { tags = local.db_tags } : null), (
    local.db_sid_specified ? { instance = local.instance } : null)
  )


  authentication = merge(local.authentication_temp, (
    local.username_specified ? { username = local.username } : null), (
    local.password_specified ? { password = local.password } : null), (
    local.path_to_public_key_specified ? { path_to_public_key = local.path_to_public_key } : null), (
    local.path_to_private_key_specified ? { path_to_private_key = local.path_to_private_key } : null
    )
  )

  key_vault = merge(local.key_vault_temp, (
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

  options = merge(local.options_temp, (local.disk_encryption_set_defined ? (
    {
      disk_encryption_set_id = local.disk_encryption_set_id
    }
  ) : null))

}
