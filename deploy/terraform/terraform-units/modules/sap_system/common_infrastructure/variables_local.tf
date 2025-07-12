# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

/*
  Description:
  Define local variables
*/


locals {
  //Region and metadata
  anchor_computer_names                = var.naming.virtualmachine_names.ANCHOR_COMPUTERNAME
  anchor_virtualmachine_names          = var.naming.virtualmachine_names.ANCHOR_VMNAME
  resource_suffixes                    = var.naming.resource_suffixes
  sid_keyvault_names                   = var.naming.keyvault_names.SDU
  vnet_prefix                          = trimspace(var.naming.prefix.WORKLOAD_ZONE)
  region                               = var.infrastructure.region
  sid                                  = upper(var.application_tier.sid)
  prefix                               = length(trimspace(var.custom_prefix)) > 0 ? (
                                            trimspace(var.custom_prefix)) : (
                                            trimspace(var.naming.prefix.SDU)
                                          )
  resource_group_exists                = length(try(var.infrastructure.resource_group.arm_id, "")) > 0
  // Resource group
  resourcegroup_name                   = local.resource_group_exists ? (
                                           try(split("/", var.infrastructure.resource_group.arm_id)[4], "")) : (
                                           coalesce(
                                             try(var.infrastructure.resource_group.name, ""),
                                             format("%s%s%s",
                                               var.naming.resource_prefixes.sdu_rg,
                                               local.prefix,
                                               local.resource_suffixes.sdu_rg
                                             )
                                           )
                                         )

  app_zones                            = try(var.application_tier.app_zones, [])
  db_zones                             = try(var.database.zones, [])
  scs_zones                            = try(var.application_tier.scs_zones, [])
  web_zones                            = try(var.application_tier.web_zones, [])
  zones                                = var.application_tier.app_use_ppg ? local.db_zones : distinct(concat(local.db_zones, local.app_zones, local.scs_zones, local.web_zones))
  zonal_deployment                     = length(local.zones) > 0 ? true : false

  //Flag to control if nsg is creates in virtual network resource group
  nsg_asg_with_vnet                    = var.options.nsg_asg_with_vnet

  // If the environment deployment created a route table use it to populate a route
  route_table_name                     = try(split("/", var.landscape_tfstate.route_table_id)[8], "")

  db_ha = try(var.database.high_availability, "false")

  //If custom image is used, we do not overwrite os reference with default value
  db_custom_image = try(var.database.os.source_image_id, "") != "" ? true : false

  db_os = {
    "source_image_id"                  = local.db_custom_image ? var.database.os.source_image_id : ""
    "publisher"                        = try(var.database.os.publisher, local.db_custom_image ? "" : "SUSE")
    "offer"                            = try(var.database.os.offer, local.db_custom_image ? "" : "sles-sap-15-sp5")
    "sku"                              = try(var.database.os.sku, local.db_custom_image ? "" : "gen1")
    "version"                          = try(var.database.os.version, local.db_custom_image ? "" : "latest")
  }

  db_ostype                            = upper(try(var.database.os.os_type, "LINUX"))

  db_auth                              = try(var.database.authentication,
                                              {
                                                "type" = "key"
                                              }
                                            )


  enable_hdb_deployment                = var.database.platform == "HANA"
  enable_xdb_deployment                = contains(["ORACLE", "ORACLE-ASM", "DB2", "SQLSERVER", "SYBASE"], upper(var.database.platform))
  enable_db_deployment                 = local.enable_xdb_deployment || local.enable_hdb_deployment

  dbnode_per_site                      = length(try(var.database.dbnodes, [{}]))

  default_filepath                     = format("%s%s",
                                           path.module,
                                           format("/../../../../../configs/%s_sizes.json", lower(var.database.platform))
                                         )

  custom_sizing                        = length(var.custom_disk_sizes_filename) > 0

  // Imports database sizing information
  file_name                            = local.custom_sizing ? (
                                           fileexists(var.custom_disk_sizes_filename) ? (
                                             var.custom_disk_sizes_filename) : (
                                             format("%s/%s", path.cwd, var.custom_disk_sizes_filename)
                                           )) : (
                                           local.default_filepath
                                         )


  //Enable APP deployment
  enable_app_deployment                = try(var.application_tier.enable_deployment, false)

  //Enable SID deployment
  enable_sid_deployment                = local.enable_db_deployment || local.enable_app_deployment

  sizes                                = jsondecode(file(local.file_name))

  db_sizing                            = local.enable_sid_deployment ? (
                                           lookup(local.sizes.db, var.database.db_sizing_key).storage) : (
                                           []
                                         )

  enable_ultradisk                     = try(
                                           compact(
                                             [
                                               for storage in local.db_sizing : storage.disk_type == "UltraSSD_LRS" ? true : ""
                                             ]
                                           )[0],
                                           false
                                         )

  //ANF support
  use_ANF                              = try(var.database.use_ANF, false)
  //Scalout subnet is needed if ANF is used and there are more than one hana node

  //Anchor VM
  deploy_anchor                        = try(var.infrastructure.anchor_vms.deploy, false)
  anchor_auth_type                     = try(var.infrastructure.anchor_vms.authentication.type, "key")
  enable_anchor_auth_password          = local.anchor_auth_type == "password"
  enable_anchor_auth_key               = !local.enable_anchor_auth_password

  //If the db uses ultra disks ensure that the anchore sets the ultradisk flag but only for the zones that will contain db servers
  enable_anchor_ultra                  = [
                                           for zone in local.zones :
                                           try(contains(var.database.zones, zone) ? local.enable_ultradisk : false, false)
                                         ]

  anchor_custom_image                  = length(
                                           try(var.infrastructure.anchor_vms.os.source_image_id, "")
                                         ) > 0

  anchor_os = local.deploy_anchor ? (
                 {
                   "source_image_id" = local.anchor_custom_image ? (
                     var.infrastructure.anchor_vms.os.source_image_id) : (
                     ""
                   )
                   "publisher" = try(var.infrastructure.anchor_vms.os.publisher,
                     local.anchor_custom_image ? (
                       "") : (
                       local.db_os.publisher
                     )
                   )
                   "offer" = try(var.infrastructure.anchor_vms.os.offer,
                     local.anchor_custom_image ? (
                       "") : (
                     local.db_os.offer)
                   )
                   "sku" = try(var.infrastructure.anchor_vms.os.sku,
                     local.anchor_custom_image ? (
                       "") : (
                     local.db_os.sku)
                   )
                   "version" = try(var.infrastructure.anchor_vms.os.version,
                     local.anchor_custom_image ? (
                       "") : (
                     local.db_os.version)
                   )
                 }) : (
                 null
               )

  anchor_ostype                        = upper(try(var.infrastructure.anchor_vms.os.os_type, local.db_ostype))

  //PPG
  var_ppg                              = try(var.infrastructure.ppg, {})
  ppg_arm_ids                          = try(var.infrastructure.ppg.arm_ids, [])
  ppg_exists                           = length(local.ppg_arm_ids) > 0 ? true : false
  ppg_names                            = try(local.var_ppg.names, [
                                           format("%s%s%s",
                                             var.naming.resource_prefixes.ppg,
                                             local.prefix,
                                             local.resource_suffixes.ppg
                                           )
                                         ])

  app_ppg_exists                       = try(length(var.infrastructure.app_ppg.arm_ids) > 0 ? true : false, false)
  isHANA                               = try(upper(var.database.platform), "NONE") == "HANA"

  ##############################################################################################
  #
  #  Admin subnet - Check if locally provided or if defined in workload zone state file
  #
  ##############################################################################################

  enable_admin_subnet                  = (var.infrastructure.virtual_networks.sap.subnet_admin.defined &&
                                          (
                                            var.application_tier.dual_nics ||
                                            var.database.dual_nics
                                          )
                                        )

  admin_subnet_name                    = var.infrastructure.virtual_networks.sap.subnet_admin.defined ? (
                                           coalesce(split("/", var.infrastructure.virtual_networks.sap.subnet_admin.id)[10],
                                                    var.infrastructure.virtual_networks.sap.subnet_admin.name,
                                                    format("%s%s%s%s",
                                                      var.naming.resource_prefixes.admin_subnet,
                                                      length(local.prefix) > 0 ? (
                                                        local.prefix) : (
                                                        var.infrastructure.environment
                                                      ),
                                                      var.naming.separator,
                                                      local.resource_suffixes.admin_subnet))): (
                                           coalesce(try(split("/", var.infrastructure.virtual_networks.sap.subnet_admin.id)[10],""),
                                                    split("/", var.infrastructure.virtual_networks.sap.subnet_admin.id_in_workload)[10])
                                                      )

  ##############################################################################################
  #
  #  Admin subnet NSG - Check if locally provided or if defined in workload zone state file
  #
  ##############################################################################################

  admin_subnet_nsg_name                           = var.infrastructure.virtual_networks.sap.subnet_admin.nsg.exists || var.infrastructure.virtual_networks.sap.subnet_admin.nsg.exists_in_workload ? (
                                                    split("/",coalesce(var.infrastructure.virtual_networks.sap.subnet_admin.nsg.id, var.infrastructure.virtual_networks.sap.subnet_admin.nsg.id_in_workload)))[8] : (
                                                    coalesce(var.infrastructure.virtual_networks.sap.subnet_admin.nsg.name,
                                                             format("%s%s%s%s",
                                                               var.naming.resource_prefixes.admin_subnet_nsg,
                                                               length(local.prefix) > 0 ? (
                                                                 local.prefix) : (
                                                                 var.infrastructure.environment
                                                                ),
                                                               var.naming.separator,
                                                               local.resource_suffixes.admin_subnet_nsg)
                                                    )
                                                  )

  ##############################################################################################
  #
  #  DB subnet - Check if locally provided or if defined in workload zone state file
  #
  ##############################################################################################


  database_subnet_name                    = var.infrastructure.virtual_networks.sap.subnet_db.defined ? (
                                           coalesce(split("/", var.infrastructure.virtual_networks.sap.subnet_db.id)[10],
                                                    var.infrastructure.virtual_networks.sap.subnet_db.name,
                                                    format("%s%s%s%s",
                                                      var.naming.resource_prefixes.db_subnet,
                                                      length(local.prefix) > 0 ? (
                                                        local.prefix) : (
                                                        var.infrastructure.environment
                                                      ),
                                                      var.naming.separator,
                                                      local.resource_suffixes.db_subnet))): (
                                           coalesce(try(split("/", var.infrastructure.virtual_networks.sap.subnet_db.id)[10],""),
                                                    split("/", var.infrastructure.virtual_networks.sap.subnet_db.id_in_workload)[10])
                                                      )

  ##############################################################################################
  #
  #  DB subnet NSG - Check if locally provided or if defined in workload zone state file
  #
  ##############################################################################################

  database_subnet_nsg_name                        = var.infrastructure.virtual_networks.sap.subnet_db.nsg.exists || var.infrastructure.virtual_networks.sap.subnet_db.nsg.exists_in_workload ? (
                                                    split("/",coalesce(var.infrastructure.virtual_networks.sap.subnet_db.nsg.id, var.infrastructure.virtual_networks.sap.subnet_db.nsg.id_in_workload)))[8] : (
                                                    coalesce(var.infrastructure.virtual_networks.sap.subnet_db.nsg.name,
                                                             format("%s%s%s%s",
                                                               var.naming.resource_prefixes.db_subnet_nsg,
                                                               length(local.prefix) > 0 ? (
                                                                 local.prefix) : (
                                                                 var.infrastructure.environment
                                                                ),
                                                               var.naming.separator,
                                                               local.resource_suffixes.db_subnet_nsg)
                                                    )
                                                  )


  # ##############################################################################################
  # #
  # #  App subnet NSG - Check if locally provided or if defined in workload zone state file
  # #
  # ##############################################################################################

  # application_subnet_defined = length(try(var.infrastructure.virtual_networks.sap.subnet_app, {})) > 0
  # application_subnet_prefix  = local.application_subnet_defined ? try(var.infrastructure.virtual_networks.sap.subnet_app.prefix, "") : ""
  # application_subnet_arm_id = local.application_subnet_defined ? (
  #   try(var.infrastructure.virtual_networks.sap.subnet_app.arm_id, "")) : (
  #   var.landscape_tfstate.app_subnet_id
  # )

  # application_subnet_exists = length(local.application_subnet_arm_id) > 0

  # application_subnet_name = local.application_subnet_defined ? (
  #   local.application_subnet_exists ? (
  #     split("/", var.infrastructure.virtual_networks.sap.subnet_app.arm_id)[10]) : (
  #     length(var.infrastructure.virtual_networks.sap.subnet_app.name) > 0 ? (
  #       var.infrastructure.virtual_networks.sap.subnet_app.arm_id) : (
  #       format("%s%s%s",
  #         local.prefix,
  #         var.naming.separator,
  #         local.resource_suffixes.app_subnet
  #       )
  #   ))) : (
  #   ""
  # )

  # sub_app_nsg_arm_id = try(var.infrastructure.virtual_networks.sap.subnet_app.nsg.arm_id, try(var.landscape_tfstate.app_nsg_id, ""))
  # sub_app_nsg_exists = length(local.application_subnet_nsg_arm_id) > 0
  # sub_app_nsg_name = local.application_subnet_nsg_exists ? (
  #   try(split("/", local.application_subnet_nsg_arm_id)[8], "")) : (
  #   length(try(var.infrastructure.virtual_networks.sap.subnet_app.nsg.name, "")) > 0 ? (
  #     var.infrastructure.virtual_networks.sap.subnet_app.nsg.name) : (
  #     format("%s%s%s",
  #       local.prefix,
  #       var.naming.separator,
  #       local.resource_suffixes.app_subnet_nsg
  #     )
  #   )
  # )

  //Storage subnet

  storage_subnet_name                    = var.infrastructure.virtual_networks.sap.subnet_storage.defined ? (
                                           coalesce(split("/", var.infrastructure.virtual_networks.sap.subnet_storage.id)[10],
                                                    var.infrastructure.virtual_networks.sap.subnet_storage.name,
                                                    format("%s%s%s%s",
                                                      var.naming.resource_prefixes.db_subnet,
                                                      length(local.prefix) > 0 ? (
                                                        local.prefix) : (
                                                        var.infrastructure.environment
                                                      ),
                                                      var.naming.separator,
                                                      local.resource_suffixes.db_subnet))): (
                                           trimspace(coalesce(try(split("/", var.infrastructure.virtual_networks.sap.subnet_storage.id)[10],""),
                                                    try(split("/", var.infrastructure.virtual_networks.sap.subnet_storage.id_in_workload)[10], " "))
                                                      ))


  storage_subnet_nsg_name                = var.infrastructure.virtual_networks.sap.subnet_storage.nsg.exists || var.infrastructure.virtual_networks.sap.subnet_storage.nsg.exists_in_workload ? (
                                            split("/",coalesce(var.infrastructure.virtual_networks.sap.subnet_storage.nsg.id, var.infrastructure.virtual_networks.sap.subnet_storage.nsg.id_in_workload)))[8] : (
                                            coalesce(var.infrastructure.virtual_networks.sap.subnet_storage.nsg.name,
                                                     format("%s%s%s%s",
                                                       var.naming.resource_prefixes.storage_subnet_nsg,
                                                       length(local.prefix) > 0 ? (
                                                         local.prefix) : (
                                                         var.infrastructure.environment
                                                        ),
                                                       var.naming.separator,
                                                       local.resource_suffixes.storage_subnet_nsg)
                                            )
                                          )

  // If the user specifies arm id of key vaults in input,
  // the key vault will be imported instead of using the landscape key vault
  user_key_vault_id                    = length(try(var.key_vault.keyvault_id_for_system_credentials, "")) > 0 ? (
                                           var.key_vault.keyvault_id_for_system_credentials) : (
                                           try(var.landscape_tfstate.landscape_key_vault_user_arm_id, "")
                                         )

  // Extract information from the specified key vault arm ids
  user_keyvault_name                   = length(local.user_key_vault_id) > 0 ? (
                                           split("/", local.user_key_vault_id)[8]) : (
                                           local.sid_keyvault_names.user_access
                                         )

  user_keyvault_resourcegroup_name     = length(local.user_key_vault_id) > 0 ? (
                                           split("/", local.user_key_vault_id)[4]) : (
                                           local.resourcegroup_name
                                         )

  use_local_credentials                = length(var.authentication) > 0

  // If local credentials are used then try the parameter file.
  // If the username is empty retrieve it from the keyvault
  // If password or sshkeys are empty create them
  sid_auth_username                    = coalesce(
                                           try(var.authentication.username, ""),
                                           try(data.azurerm_key_vault_secret.sid_username[0].value, "azureadm")
                                         )

  sid_auth_password                    = coalesce(
                                           try(var.authentication.password, ""),
                                           try(
                                             data.azurerm_key_vault_secret.sid_password[0].value,
                                             random_password.password[0].result
                                           )
                                         )

  sid_public_key                       = local.use_local_credentials ? (
                                           try(
                                             file(var.authentication.path_to_public_key),
                                             tls_private_key.sdu[0].public_key_openssh
                                           )) : (
                                           data.azurerm_key_vault_secret.sid_pk[0].value
                                         )

  sid_private_key                      = local.use_local_credentials ? (
                                           try(
                                             file(var.authentication.path_to_private_key),
                                             try(tls_private_key.sdu[0].private_key_pem, "")
                                           )) : (
                                           ""
                                         )

  password_required                    = (
                                           try(var.database.authentication.type, "key") == "password" ||
                                           try(var.application_tier.authentication.type, "key") == "password"
                                         )


  ANF_pool_settings                    = var.NFS_provider == "ANF" ? (
                                           try(var.landscape_tfstate.ANF_pool_settings, null)
                                           ) : (
                                           null
                                         )


  # This needs more though as changing of it is a destructive action
  # try(data.template_cloudinit_config.config_growpart.rendered, "Cg==")
  // 'Cg==` is empty string, base64 encoded.
  cloudinit_growpart_config            = null

  app_tier_os                          = upper(try(var.application_tier.app_os.os_type, "LINUX"))

  create_ppg                           = var.infrastructure.use_app_proximityplacementgroups ? (
                                           var.database.use_ppg) : (
                                           var.application_tier.app_use_ppg || var.application_tier.scs_use_ppg || var.application_tier.web_use_ppg || var.database.use_ppg
                                         )
deployment_type                        = var.application_tier.enable_deployment ? (
                                           (
                                             var.database.scale_out ? (
                                               "SCALEOUT") : (
                                               (var.application_tier.scs_high_availability || var.database.high_availability) ? (
                                                 "HA") : (
                                                 "DISTRIBUTED"
                                               )
                                             )
                                           )
                                           ) : (
                                           (
                                             "STANDALONE"
                                           )
                                         )

}
