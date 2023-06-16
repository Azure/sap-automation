
locals {
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

  subnet_iscsi_defined = (
    length(var.iscsi_subnet_address_prefix) +
    length(try(var.infrastructure.vnets.sap.subnet_iscsi.prefix, "")) +
    length(var.iscsi_subnet_arm_id) +
    length(try(var.infrastructure.vnets.sap.subnet_iscsi.arm_id, ""))
  ) > 0

  subnet_iscsi_arm_id_defined = (
    length(var.iscsi_subnet_arm_id) +
    length(try(var.infrastructure.vnets.sap.subnet_iscsi.arm_id, ""))
  ) > 0

  subnet_iscsi_nsg_defined = (
    length(var.iscsi_subnet_nsg_name) +
    length(try(var.infrastructure.vnets.sap.subnet_iscsi.nsg.name, "")) +
    length(var.iscsi_subnet_nsg_arm_id) +
    length(try(var.infrastructure.vnets.sap.subnet_iscsi.nsg.arm_id, ""))
  ) > 0

  subnet_anf_defined = (
    length(var.anf_subnet_address_prefix) +
    length(try(var.infrastructure.vnets.sap.subnet_anf.prefix, "")) +
    length(var.anf_subnet_arm_id) +
    length(try(var.infrastructure.vnets.sap.subnet_anf.arm_id, ""))
  ) > 0

  subnet_anf_arm_id_defined = (
    length(var.anf_subnet_arm_id) +
    length(try(var.infrastructure.vnets.sap.subnet_anf.arm_id, ""))
  ) > 0

  subnet_anf_nsg_defined = (
    length(var.anf_subnet_nsg_name) +
    length(try(var.infrastructure.vnets.sap.subnet_anf.nsg.name, "")) +
    length(var.anf_subnet_nsg_arm_id) +
    length(try(var.infrastructure.vnets.sap.subnet_anf.nsg.arm_id, ""))
  ) > 0


  resource_group = {
    name   = try(var.infrastructure.resource_group.name, var.resourcegroup_name)
    arm_id = try(var.infrastructure.resource_group.arm_id, var.resourcegroup_arm_id)
  }
  resource_group_defined = (
    length(local.resource_group.name) +
    length(local.resource_group.arm_id)
  ) > 0

  temp_infrastructure = {
    environment = coalesce(var.environment, try(var.infrastructure.environment, ""))
    region      = lower(coalesce(var.location, try(var.infrastructure.region, "")))
    codename    = try(var.infrastructure.codename, var.codename)
    tags        = try(merge(var.resourcegroup_tags, try(var.infrastructure.tags, {})), {})
  }

  authentication = {
    username            = coalesce(var.automation_username, try(var.authentication.username, "azureadm"))
    password            = try(coalesce(var.automation_password, try(var.authentication.password, "")), "")
    path_to_public_key  = try(coalesce(var.automation_path_to_public_key, try(var.authentication.path_to_public_key, "")), "")
    path_to_private_key = try(coalesce(var.automation_path_to_private_key, try(var.authentication.path_to_private_key, "")), "")
  }
  options = {
    enable_secure_transfer = true
    use_spn                = var.use_spn || try(var.options.use_spn, true)
  }
  key_vault_temp = {
    exists = length(var.user_keyvault_id) > 0
  }

  user_keyvault_specified = length(var.user_keyvault_id) > 0

  user_keyvault = var.user_keyvault_id

  spn_keyvault_specified = (
    length(var.spn_keyvault_id) +
    length(try(var.key_vault.kv_spn_id, ""))
  ) > 0
  spn_kv = local.spn_keyvault_specified ? (
    try(var.key_vault.kv_spn_id, var.spn_keyvault_id)
    ) : (
    ""
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

  diagnostics_storage_account = {
    arm_id = try(coalesce(var.diagnostics_storage_account_arm_id, try(var.diagnostics_storage_account.arm_id, "")), "")
  }
  witness_storage_account = {
    arm_id = try(coalesce(var.witness_storage_account_arm_id, try(var.witness_storage_account.arm_id, "")), "")
  }

  vnets = {
  }
  sap = {
    name         = try(var.infrastructure.vnets.sap.name, var.network_name)
    logical_name = coalesce(var.network_logical_name, try(var.infrastructure.vnets.sap.logical_name, ""))

    arm_id        = try(var.infrastructure.vnets.sap.arm_id, var.network_arm_id)
    address_space = try(var.infrastructure.vnets.sap.address_space, var.network_address_space)
  }

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
  subnet_anf = merge(
    (
      {
        "name" = try(var.infrastructure.vnets.sap.subnet_anf.name, var.anf_subnet_name)
      }
      ), (
      local.subnet_anf_arm_id_defined ? (
        {
          "arm_id" = try(var.infrastructure.vnets.sap.subnet_anf.arm_id, var.anf_subnet_arm_id)
        }
        ) : (
        null
      )), (
      {
        "prefix" = try(var.infrastructure.vnets.sap.subnet_anf.prefix, var.anf_subnet_address_prefix)
      }
      ), (
      local.subnet_anf_nsg_defined ? (
        {
          "nsg" = {
            "name"   = try(var.infrastructure.vnets.sap.subnet_anf.nsg.name, var.anf_subnet_nsg_name)
            "arm_id" = try(var.infrastructure.vnets.sap.subnet_anf.nsg.arm_id, var.anf_subnet_nsg_arm_id)
          }
        }
        ) : (
        null
      )
    )
  )


  subnet_iscsi = merge(
    (
      {
        "name" = try(var.infrastructure.vnets.sap.subnet_iscsi.name, var.iscsi_subnet_name)
      }
      ), (
      local.subnet_iscsi_arm_id_defined ? (
        {
          "arm_id" = try(var.infrastructure.vnets.sap.subnet_iscsi.arm_id, var.iscsi_subnet_arm_id)
        }
        ) : (
        null
      )), (
      {
        "prefix" = try(var.infrastructure.vnets.sap.subnet_iscsi.prefix, var.iscsi_subnet_address_prefix)
      }
      ), (
      local.subnet_web_nsg_defined ? (
        {
          "nsg" = {
            "name"   = try(var.infrastructure.vnets.sap.subnet_iscsi.nsg.name, var.iscsi_subnet_nsg_name)
            "arm_id" = try(var.infrastructure.vnets.sap.subnet_iscsi.nsg.arm_id, var.iscsi_subnet_nsg_arm_id)
          }
        }
        ) : (
        null
      )
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
    )), (
    local.subnet_anf_defined ? (
      {
        "subnet_anf" = local.subnet_anf
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

  temp_vnet = merge(local.vnets, { "sap" = local.all_subnets })


  iscsi = {
    iscsi_count = max(var.iscsi_count, try(var.infrastructure.iscsi.iscsi_count, 0))
    use_DHCP    = try(coalesce(var.iscsi_useDHCP, try(var.infrastructure.iscsi.use_DHCP, false)), "")
    size        = try(coalesce(var.iscsi_size, try(var.infrastructure.iscsi.size, "Standard_D2s_v3")), "Standard_D2s_v3")
    os = {
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
  }


  infrastructure = merge(local.temp_infrastructure, (
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
    local.iscsi.iscsi_count > 0 ? (
      {
        "iscsi" = local.iscsi
      }
    ) : null)
  )

}
