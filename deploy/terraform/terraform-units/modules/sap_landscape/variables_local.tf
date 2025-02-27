# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.


###############################################################################
#                                                                             #
#                            Local Variables                                  #
#                                                                             #
###############################################################################

locals {
  // Resources naming
  landscape_keyvault_names                        = var.naming.keyvault_names.WORKLOAD_ZONE
  landscape_shared_install_storage_account_name   = var.naming.storageaccount_names.WORKLOAD_ZONE.landscape_shared_install_storage_account_name
  landscape_shared_transport_storage_account_name = var.naming.storageaccount_names.WORKLOAD_ZONE.landscape_shared_transport_storage_account_name
  resource_suffixes                               = var.naming.resource_suffixes
  sid_keyvault_names                              = var.naming.keyvault_names.SDU
  storageaccount_name                             = var.naming.storageaccount_names.WORKLOAD_ZONE.landscape_storageaccount_name
  virtualmachine_names                            = var.naming.virtualmachine_names.ISCSI_COMPUTERNAME
  witness_storageaccount_name                     = var.naming.storageaccount_names.WORKLOAD_ZONE.witness_storageaccount_name


  // Region and metadata
  prefix                                          = trimspace(var.naming.prefix.WORKLOAD_ZONE)
  region                                          = var.infrastructure.region

  // Firewall
  firewall_exists                                 = length(local.firewall_id) > 0
  firewall_id                                     = try(var.deployer_tfstate.firewall_id, "")
  firewall_ip                                     = try(var.deployer_tfstate.firewall_ip, "")
  firewall_name                                   = local.firewall_exists ? try(split("/", local.firewall_id)[8], "") : ""
  firewall_rgname                                 = local.firewall_exists ? try(split("/", local.firewall_id)[4], "") : ""
  firewall_service_tags                           = format("AzureCloud.%s", local.region)

  deployer_public_ip_address                      = try(var.deployer_tfstate.deployer_public_ip_address, "")
  deployer_subnet_management_id                   = try(var.deployer_tfstate.subnet_mgmt_id, "")
  deployer_virtualnetwork_id                      = try(var.deployer_tfstate.vnet_mgmt_id, "")
  management_subnet_exists                        = length(local.deployer_subnet_management_id) > 0


  // Resource group
  resource_group_exists                           = length(try(var.infrastructure.resource_group.arm_id, "")) > 0
  resourcegroup_name                              = local.resource_group_exists ? (
                                                      try(split("/", var.infrastructure.resource_group.arm_id)[4], "")) : (
                                                      length(try(var.infrastructure.resource_group.name, "")) > 0 ? (
                                                        var.infrastructure.resource_group.name) : (
                                                        format("%s%s%s",
                                                          var.naming.resource_prefixes.vnet_rg,
                                                          local.prefix,
                                                          local.resource_suffixes.vnet_rg
                                                        )
                                                      )
                                                    )
  // AMS instance
  create_ams_instance                             = var.infrastructure.ams_instance.create_ams_instance
  ams_instance_name                               = length(var.infrastructure.ams_instance.name) > 0 ? (
                                                      var.infrastructure.ams_instance.name) : (
                                                        format("%s%s%s%s",
                                                          var.naming.resource_prefixes.vnet_rg,
                                                          local.prefix,
                                                          local.resource_suffixes.vnet_rg,
                                                          local.resource_suffixes.ams_instance
                                                        )
                                                      )
  ams_laws_arm_id                                 = length(var.infrastructure.ams_instance.ams_laws_arm_id) > 0 ? (
                                                      var.infrastructure.ams_instance.ams_laws_arm_id) : ""

  // NAT Gateway
  create_nat_gateway                              = var.infrastructure.nat_gateway.create_nat_gateway
  nat_gateway_name                                = length(var.infrastructure.nat_gateway.name) > 0 ? (
                                                      var.infrastructure.nat_gateway.name) : (
                                                      format("%s%s%s",
                                                        var.naming.resource_prefixes.nat_gateway,
                                                        local.prefix,
                                                        local.resource_suffixes.nat_gateway
                                                      )
                                                    )
  nat_gateway_arm_id                              = length(var.infrastructure.nat_gateway.arm_id) > 0 ? (
                                                      var.infrastructure.nat_gateway.arm_id) : ""
  nat_gateway_public_ip_arm_id                    = length(var.infrastructure.nat_gateway.public_ip_arm_id) > 0 ? (
                                                      var.infrastructure.nat_gateway.public_ip_arm_id) : ""
  nat_gateway_public_ip_zones                     = length(var.infrastructure.nat_gateway.public_ip_zones) > 0 ? (
                                                      var.infrastructure.nat_gateway.public_ip_zones) : []
  nat_gateway_idle_timeout_in_minutes             = var.infrastructure.nat_gateway.idle_timeout_in_minutes
  nat_gateway_public_ip_tags                      = var.infrastructure.nat_gateway.ip_tags

  // SAP vnet
  SAP_virtualnetwork_id                           = try(var.infrastructure.virtual_networks.sap.arm_id, "")
  SAP_virtualnetwork_exists                       = length(local.SAP_virtualnetwork_id) > 0
  SAP_virtualnetwork_name                         = local.SAP_virtualnetwork_exists ? (
                                                      try(split("/", local.SAP_virtualnetwork_id)[8], "")) : (
                                                      coalesce(
                                                        var.infrastructure.virtual_networks.sap.name,
                                                        format("%s%s%s", var.naming.resource_prefixes.vnet, local.prefix, local.resource_suffixes.vnet)
                                                      )
                                                    )

  network_address_space                           = local.SAP_virtualnetwork_exists ? [""] : var.infrastructure.virtual_networks.sap.address_space

  network_flow_timeout_in_minutes                 = var.infrastructure.virtual_networks.sap.flow_timeout_in_minutes

  network_enable_route_propagation                = var.infrastructure.virtual_networks.sap.enable_route_propagation

  // By default, Ansible ssh key for SID uses generated public key.
  // Provide sshkey.path_to_public_key and path_to_private_key overides it

  sid_public_key                                  = local.sid_key_exist ? (
                                                      data.azurerm_key_vault_secret.sid_pk[0].value) : (
                                                      try(file(var.authentication.path_to_public_key), try(tls_private_key.sid[0].public_key_openssh, ""))
                                                    )
  sid_private_key                                 = local.sid_key_exist ? (
                                                      data.azurerm_key_vault_secret.sid_ppk[0].value) : (
                                                      try(file(var.authentication.path_to_private_key), try(tls_private_key.sid[0].private_key_pem, ""))
                                                    )

  // Current service principal
  service_principal                               = try(var.service_principal, {})

  // If the user specifies arm id of key vaults in input,
  // the key vault will be imported instead of creating new key vaults

  user_key_vault_id                               = try(var.key_vault.kv_user_id, "")
  user_keyvault_exist                             = length(local.user_key_vault_id) > 0

  create_workloadzone_keyvault                    = !local.user_keyvault_exist

  // If the user specifies the secret name of key pair/password in input,
  // the secrets will be imported instead of creating new secrets
  input_sid_public_key_secret_name                = try(var.key_vault.kv_sid_sshkey_pub, "")
  input_sid_private_key_secret_name               = try(var.key_vault.kv_sid_sshkey_prvt, "")
  sid_key_exist                                   = try(length(local.input_sid_public_key_secret_name) > 0, false)

  input_sid_username                              = try(var.authentication.username, "azureadm")
  input_sid_password                              = length(try(var.authentication.password, "")) > 0 ? (
                                                      var.authentication.password) : (
                                                      random_password.created_password.result
                                                    )

  sid_ppk_name                                    = local.sid_key_exist ? (
                                                      local.input_sid_private_key_secret_name) : (
                                                      trimprefix(
                                                        format("%s-sid-sshkey",
                                                          length(local.prefix) > 0 ? (
                                                            local.prefix) : (
                                                            var.infrastructure.environment
                                                          )
                                                        ),
                                                        "-"
                                                      )
                                                    )

  sid_pk_name                                     = local.sid_key_exist ? (
                                                      local.input_sid_public_key_secret_name) : (
                                                      trimprefix(
                                                        format("%s-sid-sshkey-pub",
                                                          length(local.prefix) > 0 ? (
                                                            local.prefix) : (
                                                            var.infrastructure.environment
                                                          )
                                                        ),
                                                        "-"
                                                      )
                                                    )

  input_sid_username_secret_name                  = try(var.key_vault.kv_sid_username, "")
  input_sid_password_secret_name                  = try(var.key_vault.kv_sid_pwd, "")
  sid_credentials_secret_exist                    = length(local.input_sid_username_secret_name) > 0

  sid_username_secret_name                        = local.sid_credentials_secret_exist ? (
                                                      local.input_sid_username_secret_name) : (
                                                      trimprefix(
                                                        format("%s-sid-username",
                                                          length(local.prefix) > 0 ? (
                                                            local.prefix) : (
                                                            var.infrastructure.environment
                                                          )
                                                        ),
                                                        "-"
                                                      )
                                                    )
  sid_password_secret_name                        = local.sid_credentials_secret_exist ? (
                                                      local.input_sid_password_secret_name) : (
                                                      trimprefix(
                                                        format("%s-sid-password",
                                                          length(local.prefix) > 0 ? (
                                                            local.prefix) : (
                                                            var.infrastructure.environment
                                                          )
                                                        ),
                                                        "-"
                                                      )
                                                    )

  // Extract information from the specified key vault arm ids
  user_keyvault_name                              = local.user_keyvault_exist ? (
                                                      split("/", local.user_key_vault_id)[8]) : (
                                                      local.landscape_keyvault_names.user_access
                                                    )

  user_keyvault_resourcegroup_name                = local.user_keyvault_exist ? (
                                                      split("/", local.user_key_vault_id)[4]) : (
                                                      ""
                                                    )
  # Store the Deployer KV in workload zone KV
  deployer_keyvault_user_name                     = try(var.deployer_tfstate.deployer_kv_user_name, "")

  // In brownfield scenarios the subnets are often defined in the workload
  // If subnet information is specified in the parameter file use it
  // As either of the arm_id or the prefix need to be specified to create
  // a subnet the lack of both indicate that the subnet is to be created in the
  // SAP Infrastructure Deployment

  ##############################################################################################
  #
  #  Admin subnet - Check if locally provided
  #
  ##############################################################################################

  admin_subnet_defined                            = (
                                                      length(try(var.infrastructure.virtual_networks.sap.subnet_admin.arm_id, "")) +
                                                      length(try(var.infrastructure.virtual_networks.sap.subnet_admin.prefix, ""))
                                                    ) > 0
  admin_subnet_arm_id                             = local.admin_subnet_defined ? (
                                                      try(var.infrastructure.virtual_networks.sap.subnet_admin.arm_id, "")) : (
                                                      ""
                                                    )
  admin_subnet_existing                           = length(local.admin_subnet_arm_id) > 0
  admin_subnet_name                               = local.admin_subnet_existing ? (
                                                      try(split("/", local.admin_subnet_arm_id)[10], "")) : (
                                                      length(try(var.infrastructure.virtual_networks.sap.subnet_admin.name, "")) > 0 ? (
                                                        var.infrastructure.virtual_networks.sap.subnet_admin.name) : (
                                                        format("%s%s%s%s",
                                                          var.naming.resource_prefixes.admin_subnet,
                                                          length(local.prefix) > 0 ? (
                                                            local.prefix) : (
                                                            var.infrastructure.environment
                                                          ),
                                                          var.naming.separator,
                                                          local.resource_suffixes.admin_subnet
                                                        )
                                                      )
                                                    )
  admin_subnet_prefix                             = local.admin_subnet_defined ? (
                                                      try(var.infrastructure.virtual_networks.sap.subnet_admin.prefix, "")) : (
                                                      ""
                                                    )

  ##############################################################################################
  #
  #  Admin subnet NSG - Check if locally provided
  #
  ##############################################################################################

  admin_subnet_nsg_arm_id                         = local.admin_subnet_defined ? (
                                                      try(var.infrastructure.virtual_networks.sap.subnet_admin.nsg.arm_id, "")) : (
                                                      ""
                                                    )
  admin_subnet_nsg_exists                         = length(local.admin_subnet_nsg_arm_id) > 0
  admin_subnet_nsg_name                           = local.admin_subnet_nsg_exists ? (
                                                    try(split("/", local.admin_subnet_nsg_arm_id)[8], "")) : (
                                                    length(try(var.infrastructure.virtual_networks.sap.subnet_admin.nsg.name, "")) > 0 ? (
                                                      var.infrastructure.virtual_networks.sap.subnet_admin.nsg.name) : (
                                                      format("%s%s%s%s",
                                                        var.naming.resource_prefixes.admin_subnet_nsg,
                                                        length(local.prefix) > 0 ? (
                                                          local.prefix) : (
                                                          var.infrastructure.environment
                                                        ),
                                                        var.naming.separator,
                                                        local.resource_suffixes.admin_subnet_nsg
                                                      )
                                                    )
                                                  )

  ##############################################################################################
  #
  #  Database subnet - Check if locally provided
  #
  ##############################################################################################

  database_subnet_defined                         = (
                                                      length(try(var.infrastructure.virtual_networks.sap.subnet_db.arm_id, "")) +
                                                      length(try(var.infrastructure.virtual_networks.sap.subnet_db.prefix, ""))
                                                    ) > 0
  database_subnet_arm_id                          = local.database_subnet_defined ? (
                                                      try(var.infrastructure.virtual_networks.sap.subnet_db.arm_id, "")) : (
                                                      ""
                                                    )
  database_subnet_existing                        = length(local.database_subnet_arm_id) > 0
  database_subnet_name                            = local.database_subnet_existing ? (
                                                      try(split("/", local.database_subnet_arm_id)[10], "")) : (
                                                      length(try(var.infrastructure.virtual_networks.sap.subnet_db.name, "")) > 0 ? (
                                                        var.infrastructure.virtual_networks.sap.subnet_db.name) : (
                                                        format("%s%s%s%s",
                                                          var.naming.resource_prefixes.db_subnet,
                                                          length(local.prefix) > 0 ? (
                                                            local.prefix) : (
                                                            var.infrastructure.environment
                                                          ),
                                                          var.naming.separator,
                                                          local.resource_suffixes.db_subnet
                                                        )
                                                      )
                                                    )

  database_subnet_prefix                          = local.database_subnet_defined ? (
                                                      try(var.infrastructure.virtual_networks.sap.subnet_db.prefix, "")) : (
                                                      ""
                                                    )

  ##############################################################################################
  #
  #  Database subnet NSG - Check if locally provided
  #
  ##############################################################################################


  database_subnet_nsg_arm_id                      = local.database_subnet_defined ? (
                                                      try(var.infrastructure.virtual_networks.sap.subnet_db.nsg.arm_id, "")) : (
                                                      ""
                                                    )
  database_subnet_nsg_exists                      = length(local.database_subnet_nsg_arm_id) > 0
  database_subnet_nsg_name                        = local.database_subnet_nsg_exists ? (
                                                      try(split("/", local.database_subnet_nsg_arm_id)[8], "")) : (
                                                      length(try(var.infrastructure.virtual_networks.sap.subnet_db.nsg.name, "")) > 0 ? (
                                                        var.infrastructure.virtual_networks.sap.subnet_db.nsg.name) : (
                                                        format("%s%s%s%s",
                                                          var.naming.resource_prefixes.db_subnet_nsg,
                                                          length(local.prefix) > 0 ? (
                                                            local.prefix) : (
                                                            var.infrastructure.environment
                                                          ),
                                                          var.naming.separator,
                                                          local.resource_suffixes.db_subnet_nsg
                                                        )
                                                      )
                                                    )

  ##############################################################################################
  #
  #  Application subnet - Check if locally provided
  #
  ##############################################################################################

  application_subnet_defined                      = (
                                                     length(try(var.infrastructure.virtual_networks.sap.subnet_app.arm_id, "")) +
                                                     length(try(var.infrastructure.virtual_networks.sap.subnet_app.prefix, ""))
                                                   ) > 0
  application_subnet_arm_id                       = local.application_subnet_defined ? (
                                                      try(var.infrastructure.virtual_networks.sap.subnet_app.arm_id, "")) : (
                                                      ""
                                                    )
  application_subnet_existing                     = length(local.application_subnet_arm_id) > 0
  application_subnet_name                         = local.application_subnet_existing ? (
                                                      try(split("/", local.application_subnet_arm_id)[10], "")) : (
                                                      length(try(var.infrastructure.virtual_networks.sap.subnet_app.name, "")) > 0 ? (
                                                        var.infrastructure.virtual_networks.sap.subnet_app.name) : (
                                                        format("%s%s%s%s",
                                                          var.naming.resource_prefixes.app_subnet,
                                                          length(local.prefix) > 0 ? (
                                                            local.prefix) : (
                                                            var.infrastructure.environment
                                                          ),
                                                          var.naming.separator,
                                                          local.resource_suffixes.app_subnet
                                                        )
                                                      )

                                                    )
  application_subnet_prefix                       = local.application_subnet_defined ? (
                                                      try(var.infrastructure.virtual_networks.sap.subnet_app.prefix, "")) : (
                                                      ""
                                                    )

  create_application_subnet                       = local.application_subnet_defined && !local.application_subnet_existing

  ##############################################################################################
  #
  #  Application subnet NSG - Check if locally provided
  #
  ##############################################################################################

  application_subnet_nsg_arm_id                   = local.application_subnet_defined ? (
                                                      try(var.infrastructure.virtual_networks.sap.subnet_app.nsg.arm_id, "")) : (
                                                      ""
                                                    )
  application_subnet_nsg_exists                   = length(local.application_subnet_nsg_arm_id) > 0
  application_subnet_nsg_name                     = local.application_subnet_nsg_exists ? (
                                                      try(split("/", local.application_subnet_nsg_arm_id)[8], "")) : (
                                                      length(try(var.infrastructure.virtual_networks.sap.subnet_app.nsg.name, "")) > 0 ? (
                                                        var.infrastructure.virtual_networks.sap.subnet_app.nsg.name) : (
                                                        format("%s%s%s%s",
                                                          var.naming.resource_prefixes.app_subnet_nsg,
                                                          length(local.prefix) > 0 ? (
                                                            local.prefix) : (
                                                            var.infrastructure.environment
                                                          ),
                                                          var.naming.separator,
                                                          local.resource_suffixes.app_subnet_nsg
                                                        )
                                                      )
                                                    )

  ##############################################################################################
  #
  #  Web subnet - Check if locally provided
  #
  ##############################################################################################

  web_subnet_defined                              = (
                                                      length(try(var.infrastructure.virtual_networks.sap.subnet_web.arm_id, "")) +
                                                      length(try(var.infrastructure.virtual_networks.sap.subnet_web.prefix, ""))
                                                    ) > 0
  web_subnet_arm_id                               = local.web_subnet_defined ? (
                                                       try(var.infrastructure.virtual_networks.sap.subnet_web.arm_id, "")) : (
                                                       ""
                                                     )
  web_subnet_existing                             = length(local.web_subnet_arm_id) > 0
  web_subnet_name                                 = local.web_subnet_existing ? (
                                                      try(split("/", local.web_subnet_arm_id)[10], "")) : (
                                                      length(try(var.infrastructure.virtual_networks.sap.subnet_web.name, "")) > 0 ? (
                                                        var.infrastructure.virtual_networks.sap.subnet_web.name) : (
                                                        format("%s%s%s%s",
                                                          var.naming.resource_prefixes.web_subnet,
                                                          length(local.prefix) > 0 ? (
                                                            local.prefix) : (
                                                            var.infrastructure.environment
                                                          ),
                                                          var.naming.separator,
                                                          local.resource_suffixes.web_subnet
                                                        )
                                                      )
                                                    )
  web_subnet_prefix                               = local.web_subnet_defined ? (
                                                       try(var.infrastructure.virtual_networks.sap.subnet_web.prefix, "")) : (
                                                       ""
                                                     )

  ##############################################################################################
  #
  #  Web subnet NSG - Check if locally provided
  #
  ##############################################################################################

  web_subnet_nsg_arm_id                           = local.web_subnet_defined ? (
                                                      try(var.infrastructure.virtual_networks.sap.subnet_web.nsg.arm_id, "")) : (
                                                      ""
                                                    )
  web_subnet_nsg_exists                           = length(local.web_subnet_nsg_arm_id) > 0

  web_subnet_nsg_name                             = local.web_subnet_nsg_exists ? (
                                                      try(split("/", local.web_subnet_nsg_arm_id)[8], "")) : (
                                                      length(try(var.infrastructure.virtual_networks.sap.subnet_web.nsg.name, "")) > 0 ? (
                                                        var.infrastructure.virtual_networks.sap.subnet_web.nsg.name) : (
                                                        format("%s%s%s%s",
                                                          var.naming.resource_prefixes.web_subnet_nsg,
                                                          length(local.prefix) > 0 ? (
                                                            local.prefix) : (
                                                            var.infrastructure.environment
                                                          ),
                                                          var.naming.separator,
                                                          local.resource_suffixes.web_subnet_nsg
                                                        )
                                                      )
                                                    )

  ##############################################################################################
  #
  #  storage subnet - Check if locally provided
  #
  ##############################################################################################

  storage_subnet_defined                          = (
                                                      length(try(var.infrastructure.virtual_networks.sap.subnet_storage.arm_id, "")) +
                                                      length(try(var.infrastructure.virtual_networks.sap.subnet_storage.prefix, ""))
                                                    ) > 0
  storage_subnet_arm_id                           = local.storage_subnet_defined ? (
                                                       try(var.infrastructure.virtual_networks.sap.subnet_storage.arm_id, "")) : (
                                                       ""
                                                     )
  storage_subnet_existing                         = length(local.storage_subnet_arm_id) > 0
  storage_subnet_name                             = local.storage_subnet_existing ? (
                                                      try(split("/", local.storage_subnet_arm_id)[10], "")) : (
                                                      length(try(var.infrastructure.virtual_networks.sap.subnet_storage.name, "")) > 0 ? (
                                                        var.infrastructure.virtual_networks.sap.subnet_storage.name) : (
                                                        format("%s%s%s%s",
                                                          var.naming.resource_prefixes.storage_subnet,
                                                          length(local.prefix) > 0 ? (
                                                            local.prefix) : (
                                                            var.infrastructure.environment
                                                          ),
                                                          var.naming.separator,
                                                          local.resource_suffixes.storage_subnet
                                                        )
                                                      )
                                                    )
  subnet_cidr_storage                           = local.storage_subnet_defined ? (
                                                       try(var.infrastructure.virtual_networks.sap.subnet_storage.prefix, "")) : (
                                                       ""
                                                     )

  ##############################################################################################
  #
  #  storage subnet NSG - Check if locally provided
  #
  ##############################################################################################

  storage_subnet_nsg_arm_id                       = local.storage_subnet_defined ? (
                                                      try(var.infrastructure.virtual_networks.sap.subnet_storage.nsg.arm_id, "")) : (
                                                      ""
                                                    )
  storage_subnet_nsg_exists                       = length(local.storage_subnet_nsg_arm_id) > 0

  storage_subnet_nsg_name                         = local.storage_subnet_nsg_exists ? (
                                                      try(split("/", local.storage_subnet_nsg_arm_id)[8], "")) : (
                                                      length(try(var.infrastructure.virtual_networks.sap.subnet_storage.nsg.name, "")) > 0 ? (
                                                        var.infrastructure.virtual_networks.sap.subnet_storage.nsg.name) : (
                                                        format("%s%s%s%s",
                                                          var.naming.resource_prefixes.storage_subnet_nsg,
                                                          length(local.prefix) > 0 ? (
                                                            local.prefix) : (
                                                            var.infrastructure.environment
                                                          ),
                                                          var.naming.separator,
                                                          local.resource_suffixes.storage_subnet_nsg
                                                        )
                                                      )
                                                    )

  ##############################################################################################
  #
  #  ANF subnet - Check if locally provided
  #
  ##############################################################################################


  ANF_subnet_defined                              = (
                                                      length(try(var.infrastructure.virtual_networks.sap.subnet_anf.arm_id, "")) +
                                                      length(try(var.infrastructure.virtual_networks.sap.subnet_anf.prefix, ""))
                                                    ) > 0
  ANF_subnet_arm_id                               = local.ANF_subnet_defined ? (
                                                       try(var.infrastructure.virtual_networks.sap.subnet_anf.arm_id, "")) : (
                                                       ""
                                                     )
  ANF_subnet_existing                             = length(local.ANF_subnet_arm_id) > 0
  ANF_subnet_name                                 = local.ANF_subnet_existing ? (
                                                      try(split("/", local.ANF_subnet_arm_id)[10], "")) : (
                                                      length(try(var.infrastructure.virtual_networks.sap.subnet_anf.name, "")) > 0 ? (
                                                        var.infrastructure.virtual_networks.sap.subnet_anf.name) : (
                                                        format("%s%s%s%s",
                                                          var.naming.resource_prefixes.anf_subnet,
                                                          length(local.prefix) > 0 ? (
                                                            local.prefix) : (
                                                            var.infrastructure.environment
                                                          ),
                                                          var.naming.separator,
                                                          local.resource_suffixes.anf_subnet
                                                        )
                                                      )
                                                    )
  ANF_subnet_prefix                               = local.ANF_subnet_defined ? (
                                                      try(var.infrastructure.virtual_networks.sap.subnet_anf.prefix, "")) : (
                                                      ""
                                                    )
  ANF_subnet_nsg_arm_id                           = local.ANF_subnet_defined ? (
                                                       try(var.infrastructure.virtual_networks.sap.subnet_anf.nsg.arm_id, "")) : (
                                                       ""
                                                     )
  ANF_subnet_nsg_exists                           = length(local.ANF_subnet_nsg_arm_id) > 0

  ANF_subnet_nsg_name                             = local.ANF_subnet_nsg_exists ? (
                                                      try(split("/", local.ANF_subnet_nsg_arm_id)[8], "")) : (
                                                      length(try(var.infrastructure.virtual_networks.sap.subnet_anf.nsg.name, "")) > 0 ? (
                                                        var.infrastructure.virtual_networks.sap.subnet_anf.nsg.name) : (
                                                        format("%s%s%s%s",
                                                          var.naming.resource_prefixes.anf_subnet_nsg,
                                                          length(local.prefix) > 0 ? (
                                                            local.prefix) : (
                                                            var.infrastructure.environment
                                                          ),
                                                          var.naming.separator,
                                                          local.resource_suffixes.anf_subnet_nsg
                                                        )
                                                      )
                                                    )

  ##############################################################################################
  #
  #  AMS subnet - Check if locally provided
  #
  ##############################################################################################


  ams_subnet_defined                              = (
                                                      length(try(var.infrastructure.virtual_networks.sap.subnet_ams.arm_id, "")) +
                                                      length(try(var.infrastructure.virtual_networks.sap.subnet_ams.prefix, ""))
                                                    ) > 0
  ams_subnet_arm_id                               = local.ams_subnet_defined ? (
                                                       try(var.infrastructure.virtual_networks.sap.subnet_ams.arm_id, "")) : (
                                                       ""
                                                     )
  ams_subnet_existing                             = length(local.ams_subnet_arm_id) > 0
  ams_subnet_name                                 = local.ams_subnet_existing ? (
                                                      try(split("/", local.ams_subnet_arm_id)[10], "")) : (
                                                      length(try(var.infrastructure.virtual_networks.sap.subnet_ams.name, "")) > 0 ? (
                                                        var.infrastructure.virtual_networks.sap.subnet_ams.name) : (
                                                        format("%s%s%s%s",
                                                          var.naming.resource_prefixes.ams_subnet,
                                                          length(local.prefix) > 0 ? (
                                                            local.prefix) : (
                                                            var.infrastructure.environment
                                                          ),
                                                          var.naming.separator,
                                                          local.resource_suffixes.ams_subnet
                                                        )
                                                      )
                                                    )
  ams_subnet_prefix                               = local.ams_subnet_defined ? (
                                                      try(var.infrastructure.virtual_networks.sap.subnet_ams.prefix, "")) : (
                                                      ""
                                                    )

  ##############################################################################################
  #
  # Private DNS zones  - Check if locally provided
  #
  ##############################################################################################

  privatelink_file_defined                        = length(try(var.dns_settings.privatelink_file_id, "")) > 0
  privatelink_keyvault_defined                    = length(try(var.dns_settings.privatelink_keyvault_id, "")) > 0
  privatelink_storage_defined                     = length(try(var.dns_settings.privatelink_storage_id, "")) > 0


  #########################################################################################
  #                                                                                       #
  #  iSCSI definitioms                                                                    #
  #                                                                                       #
  #########################################################################################
  iscsi_count                                     = try(var.infrastructure.iscsi.iscsi_count, 0)
  enable_iscsi                                    = local.iscsi_count > 0
  iscsi_size                                      = try(var.infrastructure.iscsi.size, "Standard_D2s_v3")

  use_DHCP                                        = try(var.infrastructure.iscsi.use_DHCP, true)

  iscsi_os                                        = try(var.infrastructure.iscsi.os,
                                                     {
                                                       "publisher" = try(var.infrastructure.iscsi.os.publisher, "SUSE")
                                                       "offer"     = try(var.infrastructure.iscsi.os.offer, "sles-sap-15-sp5")
                                                       "sku"       = try(var.infrastructure.iscsi.os.sku, "gen2")
                                                       "version"   = try(var.infrastructure.iscsi.os.version, "latest")
                                                     }
  )

  iscsi_auth_type                                 = local.enable_iscsi ? (
                                                      try(var.infrastructure.iscsi.authentication.type, "key")) : (
                                                      ""
                                                    )
  iscsi_auth_username                             = local.enable_iscsi ? (
                                                      local.iscsi_username_exist ? (
                                                        data.azurerm_key_vault_secret.iscsi_username[0].value) : (
                                                        try(var.authentication.username, "azureadm")
                                                      )) : (
                                                      ""
                                                    )
  iscsi_nic_ips                                   = try(var.infrastructure.iscsi.iscsi_nic_ips, [])

  // By default, ssh key for iSCSI uses generated public key.
  // Provide sshkey.path_to_public_key and path_to_private_key overides it
  enable_iscsi_auth_key                           = local.enable_iscsi && local.iscsi_auth_type == "key"
  iscsi_public_key                                = local.enable_iscsi_auth_key ? (
                                                      local.iscsi_key_exist ? (
                                                        data.azurerm_key_vault_secret.iscsi_pk[0].value) : (
                                                        try(file(var.authentication.path_to_public_key), tls_private_key.sid[0].public_key_openssh)
                                                      )) : (
                                                      null
                                                    )
  iscsi_private_key                               = local.enable_iscsi_auth_key ? (
                                                      local.iscsi_key_exist ? (
                                                        data.azurerm_key_vault_secret.iscsi_ppk[0].value) : (
                                                        try(file(var.authentication.path_to_private_key), tls_private_key.sid[0].private_key_pem)
                                                      )) : (
                                                      null
                                                    )

  // By default, authentication type of iSCSI target is ssh key pair but using username/password is a potential usecase.
  enable_iscsi_auth_password                      = local.enable_iscsi && local.iscsi_auth_type == "password"
  iscsi_auth_password                             = local.enable_iscsi_auth_password ? (
                                                      local.iscsi_pwd_exist ? (
                                                        data.azurerm_key_vault_secret.iscsi_password[0].value) : (
                                                        try(var.infrastructure.iscsi.authentication.password, random_password.iscsi_password[0].result)
                                                      )) : (
                                                      null
                                                    )

  iscsi                                           = local.enable_iscsi ? merge(var.infrastructure.iscsi,
                                                      {
                                                        iscsi_count = local.iscsi_count,
                                                        size        = local.iscsi_size,
                                                        os          = local.iscsi_os,
                                                        authentication = {
                                                          type     = local.iscsi_auth_type,
                                                          username = local.iscsi_auth_username
                                                        },
                                                        iscsi_nic_ips = local.iscsi_nic_ips
                                                      }
                                                    ) : null

  // iSCSI subnet
  enable_sub_iscsi                                = (
                                                      length(try(var.infrastructure.virtual_networks.sap.subnet_iscsi.arm_id, "")) +
                                                      length(try(var.infrastructure.virtual_networks.sap.subnet_iscsi.prefix, ""))
                                                    ) > 0
  sub_iscsi_arm_id                                = try(var.infrastructure.virtual_networks.sap.subnet_iscsi.arm_id, "")
  sub_iscsi_exists                                = length(local.sub_iscsi_arm_id) > 0
  sub_iscsi_name                                  = local.sub_iscsi_exists ? (
                                                      try(split("/", local.sub_iscsi_arm_id)[10], "")) : (
                                                      length(try(var.infrastructure.virtual_networks.sap.subnet_iscsi.name, "")) > 0 ? (
                                                        var.infrastructure.virtual_networks.sap.subnet_iscsi.name) : (
                                                        format("%s%s%s%s",
                                                          var.naming.resource_prefixes.iscsi_subnet,
                                                          length(local.prefix) > 0 ? (
                                                            local.prefix) : (
                                                            var.infrastructure.environment
                                                          ),
                                                          var.naming.separator,
                                                          local.resource_suffixes.iscsi_subnet
                                                        )
                                                      )
                                                    )
  sub_iscsi_prefix                                = local.sub_iscsi_exists ? "" : try(var.infrastructure.virtual_networks.sap.subnet_iscsi.prefix, "")

  // iSCSI NSG
  var_sub_iscsi_nsg                               = try(var.infrastructure.virtual_networks.sap.subnet_iscsi.nsg, {arm_id=""})
  sub_iscsi_nsg_arm_id                            = try(var.infrastructure.virtual_networks.sap.subnet_iscsi.nsg.arm_id, "")
  sub_iscsi_nsg_exists                            = length(local.sub_iscsi_nsg_arm_id) > 0
  sub_iscsi_nsg_name                              = local.sub_iscsi_nsg_exists ? (
                                                      try(split("/", local.sub_iscsi_nsg_arm_id)[8], "")) : (
                                                      length(try(var.infrastructure.virtual_networks.sap.subnet_iscsi.nsg.name, "")) > 0 ? (
                                                        var.infrastructure.virtual_networks.sap.subnet_iscsi.nsg.name ) : (
                                                        format("%s%s%s%s",
                                                          var.naming.resource_prefixes.iscsi_subnet_nsg,
                                                          length(local.prefix) > 0 ? (
                                                            local.prefix) : (
                                                            var.infrastructure.environment
                                                          ),
                                                          var.naming.separator,
                                                        local.resource_suffixes.iscsi_subnet_nsg)
                                                      )
                                                    )

  input_iscsi_public_key_secret_name              = try(var.key_vault.kv_iscsi_sshkey_pub, "")
  input_iscsi_private_key_secret_name             = try(var.key_vault.kv_iscsi_sshkey_prvt, "")
  input_iscsi_password_secret_name                = try(var.key_vault.kv_iscsi_pwd, "")
  input_iscsi_username_secret_name                = try(var.key_vault.kv_iscsi_username, "")
  iscsi_key_exist                                 = try(length(local.input_iscsi_public_key_secret_name) > 0, false)
  iscsi_pwd_exist                                 = try(length(local.input_iscsi_password_secret_name) > 0, false)
  iscsi_username_exist                            = try(length(local.input_iscsi_username_secret_name) > 0, false)

  iscsi_pk_name                                   = local.iscsi_key_exist ? (
                                                      local.input_iscsi_public_key_secret_name) : (
                                                      trimprefix(
                                                        format("%s-iscsi-sshkey-pub",
                                                          length(local.prefix) > 0 ? (
                                                            local.prefix) : (
                                                            var.infrastructure.environment
                                                          )
                                                        ),
                                                        "-"
                                                      )
                                                    )

  iscsi_ppk_name                                  = local.iscsi_key_exist ? (
                                                      local.input_iscsi_private_key_secret_name) : (
                                                      trimprefix(
                                                        format("%s-iscsi-sshkey",
                                                          length(local.prefix) > 0 ? (
                                                            local.prefix) : (
                                                            var.infrastructure.environment
                                                          )
                                                        ),
                                                        "-"
                                                      )
                                                    )


  iscsi_pwd_name                                  = local.iscsi_pwd_exist ? (
                                                      local.input_iscsi_password_secret_name) : (
                                                      trimprefix(
                                                        format("%s-iscsi-password",
                                                          length(local.prefix) > 0 ? (
                                                            local.prefix) : (
                                                            var.infrastructure.environment
                                                          )
                                                        ),
                                                        "-"
                                                      )
                                                    )

  iscsi_username_name                             = local.iscsi_username_exist ? (
                                                      local.input_iscsi_username_secret_name) : (
                                                      trimprefix(
                                                        format("%s-iscsi-username",
                                                          length(local.prefix) > 0 ? (
                                                            local.prefix) : (
                                                            var.infrastructure.environment
                                                          )
                                                        ),
                                                        "-"
                                                      )
                                                    )

  full_iscsiserver_names                          = flatten([for vm in local.virtualmachine_names :
                                                      format("%s%s%s%s%s",
                                                        var.naming.resource_prefixes.vm,
                                                        local.prefix,
                                                        var.naming.separator,
                                                        vm,
                                                        local.resource_suffixes.vm
                                                      )]
                                                    )

  use_Azure_native_DNS                            = length(var.dns_settings.dns_label) > 0 && !var.dns_settings.use_custom_dns_a_registration && !local.SAP_virtualnetwork_exists


  use_AFS_for_shared                             = (var.NFS_provider == "ANF" && var.use_AFS_for_shared_storage) || var.NFS_provider == "AFS"


  deploy_monitoring_extension                    = var.infrastructure.deploy_monitoring_extension && length(try(var.infrastructure.user_assigned_identity_id,"")) > 0

}
