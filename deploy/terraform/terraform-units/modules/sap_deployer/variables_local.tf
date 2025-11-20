# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.


###############################################################################
#                                                                             #
#                            Local Variables                                  #
#                                                                             #
###############################################################################


locals {

  storageaccount_names                 = var.naming.storageaccount_names.DEPLOYER
  virtualmachine_names                 = var.naming.virtualmachine_names.DEPLOYER
  keyvault_names                       = var.naming.keyvault_names.DEPLOYER

  // Default option(s):
  enable_secure_transfer               = try(var.options.enable_secure_transfer, true)
  enable_deployer_public_ip            = try(var.options.enable_deployer_public_ip, false)
  Agent_IP                             = try(var.Agent_IP, "")

  // Resource group
  prefix                               = var.naming.prefix.DEPLOYER

  // If resource ID is specified extract the resourcegroup name from it otherwise read it either from input of create using the naming convention
  resourcegroup_name                   = var.infrastructure.resource_group.exists ? (
                                           split("/", var.infrastructure.resource_group.id)[4]) : (
                                           length(var.infrastructure.resource_group.name) > 0 ? (
                                             var.infrastructure.resource_group.name) : (
                                             format("%s%s%s",
                                               var.naming.resource_prefixes.deployer_rg,
                                               local.prefix,
                                               var.naming.resource_suffixes.deployer_rg
                                             )
                                           )
                                         )

  // Post fix for all deployed resources
  postfix                              = random_id.deployer.hex
  // If resource ID is specified extract the vnet name from it otherwise read it either from input of create using the naming convention
  vnet_mgmt_name                      = var.infrastructure.virtual_network.management.exists ? (
                                          split("/", var.infrastructure.virtual_network.management.id)[8]) : (
                                          length(var.infrastructure.virtual_network.management.name) > 0 ? (
                                            var.infrastructure.virtual_network.management.name) : (
                                            format("%s%s%s",
                                              var.naming.resource_prefixes.vnet,
                                              length(local.prefix) > 0 ? (
                                                local.prefix) : (
                                                var.infrastructure.environment
                                              ),
                                              var.naming.resource_suffixes.vnet
                                            )
                                          )
                                        )

  // Management subnet
  // If resource ID is specified extract the subnet name from it otherwise read it either from input of create using the naming convention
  management_subnet_name               = var.infrastructure.virtual_network.management.subnet_mgmt.exists ? (
                                           split("/", var.infrastructure.virtual_network.management.subnet_mgmt.id)[10]) : (
                                           length(var.infrastructure.virtual_network.management.subnet_mgmt.name) > 0 ? (
                                             var.infrastructure.virtual_network.management.subnet_mgmt.name) : (
                                             format("%s%s%s",
                                               var.naming.resource_prefixes.deployer_subnet,
                                               length(local.prefix) > 0 ? (
                                                 local.prefix) : (
                                                 var.infrastructure.environment
                                               ),
                                               var.naming.resource_suffixes.deployer_subnet
                                             )
                                         ))


  // Management NSG
  // If resource ID is specified extract the nsg name from it otherwise read it either from input of create using the naming convention
  management_subnet_nsg_name           = var.infrastructure.virtual_network.management.subnet_mgmt.nsg.exists ? (
                                           split("/", var.infrastructure.virtual_network.management.subnet_mgmt.nsg.id)[8]) : (
                                           length(var.infrastructure.virtual_network.management.subnet_mgmt.nsg.name) > 0 ? (
                                             var.infrastructure.virtual_network.management.subnet_mgmt.nsg.name) : (
                                             format("%s%s%s",
                                               var.naming.resource_prefixes.deployer_subnet_nsg,
                                               length(local.prefix) > 0 ? (
                                                 local.prefix) : (
                                                 var.infrastructure.environment
                                               ),
                                               var.naming.resource_suffixes.deployer_subnet_nsg
                                             )
                                         ))

  management_subnet_nsg_allowed_ips    = var.infrastructure.virtual_network.management.subnet_mgmt.nsg.exists ? (
                                           []) : (
                                           length(var.infrastructure.virtual_network.management.subnet_mgmt.nsg.allowed_ips) > 0 ? (
                                             var.infrastructure.virtual_network.management.subnet_mgmt.nsg.allowed_ips) : (
                                             ["0.0.0.0/0"]
                                           )
                                         )

  // Agent subnet
  // If resource ID is specified extract the subnet name from it otherwise read it either from input of create using the naming convention
  agent_subnet_name               = var.infrastructure.virtual_network.management.subnet_agent.exists ? (
                                           split("/", var.infrastructure.virtual_network.management.subnet_agent.id)[10]) : (
                                           length(var.infrastructure.virtual_network.management.subnet_agent.name) > 0 ? (
                                             var.infrastructure.virtual_network.management.subnet_agent.name) : (
                                             format("%s%s%s",
                                               var.naming.resource_prefixes.agent_subnet,
                                               length(local.prefix) > 0 ? (
                                                 local.prefix) : (
                                                 var.infrastructure.environment
                                               ),
                                               var.naming.resource_suffixes.agent_subnet
                                             )
                                         ))



  // Firewall subnet
  firewall_subnet_name                 = "AzureFirewallSubnet"

  # Not all region names are the same as their service tags
  # https://docs.microsoft.com/en-us/azure/virtual-network/service-tags-overview#available-service-tags
  regioncode_exceptions                = {
                                           "francecentral"      = "centralfrance"
                                           "francesouth"        = "southfrance"
                                           "germanynorth"       = "germanyn"
                                           "germanywestcentral" = "germanywc"
                                           "norwayeast"         = "norwaye"
                                           "norwaywest"         = "norwayw"
                                           "southcentralus"     = "usstagee"
                                           "southcentralusstg"  = "usstagec"
                                           "switzerlandnorth"   = "switzerlandn"
                                           "switzerlandwest"    = "switzerlandw"
                                         }

  firewall_service_tags                = format("AzureCloud.%s", lookup(local.regioncode_exceptions, var.infrastructure.region, var.infrastructure.region))

  // Bastion subnet
  bastion_subnet_name                  = "AzureBastionSubnet"

  // Webapp subnet
  webapp_subnet_name                   = "AzureWebappSubnet"

  enable_password                      = try(var.deployer.authentication.type, "key") == "password"
  enable_key                           = !local.enable_password

  username                             = try(var.authentication.username, "azureadm")

  // By default use generated password. Provide password under authentication overides it
  password                             = local.enable_password ? (
                                           coalesce(var.authentication.password, random_password.deployer[0].result)
                                           ) : (
                                           ""
                                         )

  // By default use generated public key. Provide authentication.path_to_public_key and path_to_private_key overrides it

  public_key                           = local.enable_key ? try(file(var.authentication.path_to_public_key), tls_private_key.deployer[0].public_key_openssh) : ( null )

  private_key                          = local.enable_key ? (try(file(var.authentication.path_to_private_key), tls_private_key.deployer[0].private_key_pem)  ) : ( null )

  // If the user specifies arm id of key vaults in input, the key vault will be imported instead of creating new key vaults

  automation_keyvault_exist            = var.key_vault.exists

  private_key_secret_name              = coalesce(
                                           var.key_vault.private_key_secret_name,
                                           replace(
                                             format("%s-sshkey",
                                               length(local.prefix) > 0 ? (
                                                 local.prefix) : (
                                                 var.infrastructure.environment
                                             )),
                                             "/[^A-Za-z0-9-]/"
                                           , "")
                                         )
  public_key_secret_name               = coalesce(
                                           var.key_vault.public_key_secret_name,
                                           replace(
                                             format("%s-sshkey-pub",
                                               length(local.prefix) > 0 ? (
                                                 local.prefix) : (
                                                 var.infrastructure.environment
                                               ),
                                             ),
                                             "/[^A-Za-z0-9-]/",
                                             ""
                                           )
                                         )
  pwd_secret_name                      = coalesce(var.key_vault.password_secret_name,
                                           replace(
                                             format("%s-password",
                                               length(local.prefix) > 0 ? (
                                                 local.prefix) : (
                                                 var.infrastructure.environment
                                               ),
                                             ),
                                             "/[^A-Za-z0-9-]/"
                                           , "")
                                         )
  username_secret_name                 = coalesce(var.key_vault.username_secret_name,
                                           replace(
                                             format("%s-username",
                                               length(local.prefix) > 0 ? (
                                                 local.prefix) : (
                                                 var.infrastructure.environment
                                               ),
                                             ),
                                             "/[^A-Za-z0-9-]/"
                                           , "")
                                         )

  // Extract information from the specified key vault arm ids
  user_keyvault_name                   = var.key_vault.exists ? split("/", var.key_vault.id)[8] : local.keyvault_names.user_access

  // Tags
  tags                                 = merge(var.infrastructure.tags,try(var.deployer.tags, { "Role" = "Deployer" }))

  parsed_id                            = var.app_config_service.exists ? try(provider::azurerm::parse_resource_id(var.app_config_service.id), "") : null
  app_config_name                      = var.app_config_service.exists ? local.parsed_id["resource_name"] : var.app_config_service.name
  app_config_resource_group_name       = var.app_config_service.exists ? local.parsed_id["resource_group_name"] : ""


}
