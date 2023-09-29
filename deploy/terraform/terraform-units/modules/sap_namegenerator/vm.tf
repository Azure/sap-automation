locals {

  db_oscode     = upper(var.db_ostype) == "LINUX" ? "l" : "w"
  app_oscode    = upper(var.app_ostype) == "LINUX" ? "l" : "w"
  anchor_oscode = upper(var.anchor_ostype) == "LINUX" ? "l" : "w"

  ha_zones = reverse(var.db_zones)

  anchor_computer_names = [for idx in range(length(local.zones)) :
    format("%sanchorz%s%02d%s%s", lower(var.sap_sid), local.zones[idx % max(length(local.zones), 1)], idx + var.resource_offset, local.anchor_oscode, local.random_id_vm_verified)
  ]

  anchor_vm_names = [for idx in range(length(local.zones)) :
    format("%sanchor_z%s_%02d%s%s", lower(var.sap_sid), local.zones[idx % max(length(local.zones), 1)], idx + var.resource_offset, local.anchor_oscode, local.random_id_vm_verified)
  ]

  deployer_vm_names = [for idx in range(var.deployer_vm_count) :
    lower(format("%s%s%sdeploy%02d", local.env_verified, local.location_short, local.dep_vnet_verified, idx + var.resource_offset))
  ]

  anydb_computer_names = [for idx in range(var.db_server_count) :
    format("%sdb%02d%s%d%s", lower(var.sap_sid), idx + var.resource_offset, local.db_oscode, 0, local.random_id_vm_verified)
  ]

  anydb_computer_names_ha = [for idx in range(var.db_server_count) :
    format("%sdb%02d%s%d%s", lower(var.sap_sid), idx + var.resource_offset, local.db_oscode, 1, local.random_id_vm_verified)
  ]

  anydb_vm_names = [for idx in range(var.db_server_count) :
    length(var.db_zones) > 0 && var.use_zonal_markers ? (
      format("%sdb%sz%s%s%02d%s%d%s", lower(var.sap_sid), local.separator, var.db_zones[idx % max(length(var.db_zones), 1)], local.separator, idx + var.resource_offset, local.db_oscode, 0, local.random_id_vm_verified)) : (
      format("%sdb%02d%s%d%s", lower(var.sap_sid), idx + var.resource_offset, local.db_oscode, 0, local.random_id_vm_verified)
    )
  ]

  anydb_vm_names_ha = [for idx in range(var.db_server_count) :
    length(var.db_zones) > 0 && var.use_zonal_markers ? (
      format("%sdb%sz%s%s%02d%s%d%s", lower(var.sap_sid), local.separator, local.ha_zones[idx % max(length(local.ha_zones), 1)], local.separator, idx + var.resource_offset, local.db_oscode, 1, local.random_id_vm_verified)) : (
      format("%sdb%02d%s%d%s", lower(var.sap_sid), idx + var.resource_offset, local.db_oscode, 1, local.random_id_vm_verified)
    )
  ]

  app_computer_names = [for idx in range(var.app_server_count) :
    format("%sapp%02d%s%s", lower(var.sap_sid), idx + var.resource_offset, local.app_oscode, local.random_id_vm_verified)
  ]

  app_server_vm_names = [for idx in range(var.app_server_count) :
    length(var.app_zones) > 0 && var.use_zonal_markers ? (
      format("%sapp%sz%s%s%02d%s%s", lower(var.sap_sid), local.separator, var.app_zones[idx % max(length(var.app_zones), 1)], local.separator, idx + var.resource_offset, local.app_oscode, local.random_id_vm_verified)) : (
      format("%sapp%02d%s%s", lower(var.sap_sid), idx + var.resource_offset, local.app_oscode, local.random_id_vm_verified)
    )
  ]

  iscsi_server_names = [for idx in range(var.iscsi_server_count) :
    lower(format("%s%s%siscsi%02d", lower(local.env_verified), local.sap_vnet_verified, local.location_short, idx))
  ]

  hana_computer_names = [for idx in range(var.db_server_count) :
    format("%sd%s%02dl%d%s", lower(var.sap_sid), lower(var.db_sid), idx + var.resource_offset, 0, substr(local.random_id_vm_verified, 0, 2))
  ]

  hana_computer_names_ha = [for idx in range(var.db_server_count) :
    format("%sd%s%02dl%d%s", lower(var.sap_sid), lower(var.db_sid), idx + var.resource_offset, 1, substr(local.random_id_vm_verified, 0, 2))
  ]

  hana_server_vm_names = [for idx in range(var.db_server_count) :
    length(var.db_zones) > 0 && var.use_zonal_markers ? (
      format("%sd%s%sz%s%s%02dl%d%s", lower(var.sap_sid), lower(var.db_sid), local.separator, var.db_zones[idx % max(length(var.db_zones), 1)], local.separator, idx + var.resource_offset, 0, local.random_id_vm_verified)) : (
      format("%sd%s%02dl%d%s", lower(var.sap_sid), lower(var.db_sid), idx + var.resource_offset, 0, local.random_id_vm_verified)
    )
  ]

  hana_server_vm_names_ha = [for idx in range(var.db_server_count) :
    length(var.db_zones) > 0 && var.use_zonal_markers ? (
      format("%sd%s%sz%s%s%02dl%d%s", lower(var.sap_sid), lower(var.db_sid), local.separator, local.ha_zones[idx % max(length(local.ha_zones), 1)], local.separator, idx + var.resource_offset, 1, local.random_id_vm_verified)) : (
      format("%sd%s%02dl%d%s", lower(var.sap_sid), lower(var.db_sid), idx + var.resource_offset, 1, local.random_id_vm_verified)
    )
  ]

  scs_computer_names = [for idx in range(var.scs_server_count) :
    format("%sscs%02d%s%s", lower(var.sap_sid), idx + var.resource_offset, local.app_oscode, local.random_id_vm_verified)
  ]

  scs_server_vm_names = [for idx in range(var.scs_server_count) :
    length(var.scs_zones) > 0 && var.use_zonal_markers ? (
      format("%sscs%sz%s%s%02d%s%s", lower(var.sap_sid), local.separator, var.scs_zones[idx % max(length(var.scs_zones), 1)], local.separator, idx + var.resource_offset, local.app_oscode, local.random_id_vm_verified)) : (
      format("%sscs%02d%s%s", lower(var.sap_sid), idx + var.resource_offset, local.app_oscode, local.random_id_vm_verified)
    )
  ]

  web_computer_names = [for idx in range(var.web_server_count) :
    format("%sweb%02d%s%s", lower(var.sap_sid), idx + var.resource_offset, local.app_oscode, local.random_id_vm_verified)
  ]

  web_server_vm_names = [for idx in range(var.web_server_count) :
    length(var.web_zones) > 0 && var.use_zonal_markers ? (
      format("%sweb%sz%s%s%02d%s%s", lower(var.web_sid), local.separator, var.web_zones[idx % max(length(var.web_zones), 1)], local.separator, idx + var.resource_offset, local.app_oscode, local.random_id_vm_verified)) : (
      format("%sweb%02d%s%s", lower(var.web_sid), idx + var.resource_offset, local.app_oscode, local.random_id_vm_verified)
    )
  ]

  observer_computer_names = [for idx in range(max(length(local.zones), 1)) :
    format("%sobserver%02d%s%s", lower(var.sap_sid), idx + var.resource_offset, local.db_oscode, local.random_id_vm_verified)
  ]

  observer_vm_names = [for idx in range(max(length(local.zones), 1)) :
    local.zonal_deployment && var.use_zonal_markers ? (
      format("%sobserver_z%s_%02d%s%s", lower(var.sap_sid), local.zones[idx % length(local.zones)], idx + var.resource_offset, local.db_oscode, local.random_id_vm_verified)) : (
      format("%sobserver%02d%s%s", lower(var.sap_sid), idx + var.resource_offset, local.db_oscode, local.random_id_vm_verified)
    )
  ]

  //For customer who want to have an alternative name for the second IP address
  app_secondary_dnsnames = [for idx in range(var.app_server_count) :
    format("v%sa%02d%s%s", lower(var.sap_sid), idx + var.resource_offset, local.app_oscode, substr(local.random_id_vm_verified, 0, 2))
  ]

  anchor_secondary_dnsnames = [for idx in range(length(local.zones)) :
    format("%sanchorz%s%02d%s%s", lower(var.sap_sid), local.zones[idx % max(length(local.zones), 1)], idx + var.resource_offset, local.anchor_oscode, local.random_id_vm_verified)
  ]

  anydb_secondary_dnsnames = [for idx in range(var.db_server_count) :
    format("v%sd%02dl%d%s", lower(var.sap_sid), idx + var.resource_offset, 0, substr(local.random_id_vm_verified, 0, 2))
  ]

  anydb_secondary_dnsnames_ha = [for idx in range(var.db_server_count) :
    format("v%sd%s%02dl%d%s", lower(var.sap_sid), lower(var.db_sid), idx + var.resource_offset, 1, substr(local.random_id_vm_verified, 0, 2))
  ]

  hana_secondary_dnsnames = [for idx in range(var.db_server_count) :
    format("v%sd%s%02dl%d%s", lower(var.sap_sid), lower(var.db_sid), idx + var.resource_offset, 0, substr(local.random_id_vm_verified, 0, 2))
  ]

  hana_secondary_dnsnames_ha = [for idx in range(var.db_server_count) :
    format("v%sd%s%02dl%d%s", lower(var.sap_sid), lower(var.db_sid), idx + var.resource_offset, 1, local.random_id_virt_vm_verified)
  ]

  scs_secondary_dnsnames = [for idx in range(var.scs_server_count) :
    format("v%ss%02d%s%s", lower(var.sap_sid), idx + var.resource_offset, local.app_oscode, local.random_id_virt_vm_verified)
  ]

  web_secondary_dnsnames = [for idx in range(var.web_server_count) :
    format("v%sw%02d%s%s", lower(var.web_sid), idx + var.resource_offset, local.app_oscode, local.random_id_virt_vm_verified)
  ]

  utility_vm_names = [for idx in range(var.utility_vm_count) :
    lower(format("wz-vm%02d", idx + var.resource_offset))
  ]

}
