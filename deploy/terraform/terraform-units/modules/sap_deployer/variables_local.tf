
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

  resource_group_exists                = length(var.infrastructure.resource_group.arm_id) > 0
  // If resource ID is specified extract the resourcegroup name from it otherwise read it either from input of create using the naming convention
  resourcegroup_name                   = local.resource_group_exists ? (
                                           split("/", var.infrastructure.resource_group.arm_id)[4]) : (
                                           length(var.infrastructure.resource_group.name) > 0 ? (
                                             var.infrastructure.resource_group.name) : (
                                             format("%s%s%s",
                                               var.naming.resource_prefixes.deployer_rg,
                                               local.prefix,
                                               var.naming.resource_suffixes.deployer_rg
                                             )
                                           )
                                         )
  rg_appservice_location               = local.resource_group_exists ? data.azurerm_resource_group.deployer[0].location : azurerm_resource_group.deployer[0].location

  // Post fix for all deployed resources
  postfix                              = random_id.deployer.hex

  // Management vnet
  vnet_mgmt_arm_id                     = try(var.infrastructure.vnets.management.arm_id, "")
  vnet_mgmt_exists                     = length(local.vnet_mgmt_arm_id) > 0

  // If resource ID is specified extract the vnet name from it otherwise read it either from input of create using the naming convention
  vnet_mgmt_name                      = local.vnet_mgmt_exists ? (
                                          split("/", local.vnet_mgmt_arm_id)[8]) : (
                                          length(var.infrastructure.vnets.management.name) > 0 ? (
                                            var.infrastructure.vnets.management.name) : (
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

  vnet_mgmt_addr                       = local.vnet_mgmt_exists ? "" : try(var.infrastructure.vnets.management.address_space, "")

  // Management subnet
  management_subnet_arm_id             = try(var.infrastructure.vnets.management.subnet_mgmt.arm_id, "")
  management_subnet_exists             = length(local.management_subnet_arm_id) > 0

  // If resource ID is specified extract the subnet name from it otherwise read it either from input of create using the naming convention
  management_subnet_name               = local.management_subnet_exists ? (
                                           split("/", var.infrastructure.vnets.management.subnet_mgmt.arm_id)[10]) : (
                                           length(var.infrastructure.vnets.management.subnet_mgmt.name) > 0 ? (
                                             var.infrastructure.vnets.management.subnet_mgmt.name) : (
                                             format("%s%s%s",
                                               var.naming.resource_prefixes.deployer_subnet,
                                               length(local.prefix) > 0 ? (
                                                 local.prefix) : (
                                                 var.infrastructure.environment
                                               ),
                                               var.naming.resource_suffixes.deployer_subnet
                                             )
                                         ))

  management_subnet_prefix             = local.management_subnet_exists ? (
                                           "") : (
                                           try(var.infrastructure.vnets.management.subnet_mgmt.prefix, "")
                                         )
  management_subnet_deployed_prefixes  = local.management_subnet_exists ? (
                                           data.azurerm_subnet.subnet_mgmt[0].address_prefixes) : (
                                           try(azurerm_subnet.subnet_mgmt[0].address_prefixes, [])
                                         )

  // Management NSG
  management_subnet_nsg_arm_id         = try(var.infrastructure.vnets.management.subnet_mgmt.nsg.arm_id, "")
  management_subnet_nsg_exists         = length(local.management_subnet_nsg_arm_id) > 0
  // If resource ID is specified extract the nsg name from it otherwise read it either from input of create using the naming convention
  management_subnet_nsg_name           = local.management_subnet_nsg_exists ? (
                                           split("/", local.management_subnet_nsg_arm_id)[8]) : (
                                           length(var.infrastructure.vnets.management.subnet_mgmt.nsg.name) > 0 ? (
                                             var.infrastructure.vnets.management.subnet_mgmt.nsg.name) : (
                                             format("%s%s%s",
                                               var.naming.resource_prefixes.deployer_subnet_nsg,
                                               length(local.prefix) > 0 ? (
                                                 local.prefix) : (
                                                 var.infrastructure.environment
                                               ),
                                               var.naming.resource_suffixes.deployer_subnet_nsg
                                             )
                                         ))

  management_subnet_nsg_allowed_ips    = local.management_subnet_nsg_exists ? (
                                           []) : (
                                           length(var.infrastructure.vnets.management.subnet_mgmt.nsg.allowed_ips) > 0 ? (
                                             var.infrastructure.vnets.management.subnet_mgmt.nsg.allowed_ips) : (
                                             ["0.0.0.0/0"]
                                           )
                                         )

  // Firewall subnet
  firewall_subnet_arm_id               = try(var.infrastructure.vnets.management.subnet_fw.arm_id, "")
  firewall_subnet_exists               = length(local.firewall_subnet_arm_id) > 0
  firewall_subnet_name                 = "AzureFirewallSubnet"
  firewall_subnet_prefix               = local.firewall_subnet_exists ? (
                                           "") : (
                                           try(var.infrastructure.vnets.management.subnet_fw.prefix, "")
                                         )

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
  management_bastion_subnet_arm_id     = try(var.infrastructure.vnets.management.subnet_bastion.arm_id, "")
  bastion_subnet_exists                = length(local.management_bastion_subnet_arm_id) > 0
  bastion_subnet_name                  = "AzureBastionSubnet"
  bastion_subnet_prefix                = local.bastion_subnet_exists ? (
                                           "") : (
                                           try(var.infrastructure.vnets.management.subnet_bastion.prefix, "")
                                         )

  // Webapp subnet
  webapp_subnet_arm_id                 = try(var.infrastructure.vnets.management.subnet_webapp.arm_id, "")
  webapp_subnet_exists                 = length(local.webapp_subnet_arm_id) > 0
  webapp_subnet_name                   = "AzureWebappSubnet"
  webapp_subnet_prefix                 = local.webapp_subnet_exists ? "" : try(var.infrastructure.vnets.management.subnet_webapp.prefix, "")

  enable_password                      = try(var.deployer.authentication.type, "key") == "password"
  enable_key                           = !local.enable_password

  username                             = local.username_exist ? (
                                           data.azurerm_key_vault_secret.username[0].value) : (
                                           try(var.authentication.username, "azureadm")
                                         )

  // By default use generated password. Provide password under authentication overides it
  password                             = local.enable_password ? (
                                           local.pwd_exist ? (
                                             data.azurerm_key_vault_secret.pwd[0].value) : (
                                             coalesce(var.authentication.password, random_password.deployer[0].result)
                                           )) : (
                                           ""
                                         )

  // By default use generated public key. Provide authentication.path_to_public_key and path_to_private_key overides it
  public_key                           = local.enable_key ? (
                                           local.key_exist ? (
                                             data.azurerm_key_vault_secret.pk[0].value) : (
                                             try(file(var.authentication.path_to_public_key), tls_private_key.deployer[0].public_key_openssh)
                                           )) : (
                                           null
                                         )

  private_key                          = local.enable_key ? (
                                           local.key_exist ? (
                                             data.azurerm_key_vault_secret.ppk[0].value) : (
                                             try(file(var.authentication.path_to_private_key), tls_private_key.deployer[0].private_key_pem)
                                           )) : (
                                           null
                                         )

  // If the user specifies arm id of key vaults in input, the key vault will be imported instead of creating new key vaults
  prvt_key_vault_id                    = try(var.key_vault.kv_prvt_id, "")
  automation_keyvault_exist            = length(local.prvt_key_vault_id) > 0

  // If the user specifies the secret name of key pair/password in input, the secrets will be imported instead of creating new secrets
  input_public_key_secret_name         = try(var.key_vault.kv_sshkey_pub, "")
  input_private_key_secret_name        = try(var.key_vault.kv_sshkey_prvt, "")
  input_password_secret_name           = try(var.key_vault.kv_pwd, "")
  input_username_secret_name           = try(var.key_vault.kv_username, "")

  // If public key secret name is provided, need to provide private key secret name as well, otherwise fail with error.
  key_exist                            = try(length(local.input_public_key_secret_name) > 0, false)
  pwd_exist                            = try(length(local.input_password_secret_name) > 0, false)
  username_exist                       = try(length(local.input_username_secret_name) > 0, false)

  ppk_secret_name                      = local.key_exist ? (
                                           local.input_private_key_secret_name) : (
                                           replace(
                                             format("%s-sshkey",
                                               length(local.prefix) > 0 ? (
                                                 local.prefix) : (
                                                 var.infrastructure.environment
                                             )),
                                             "/[^A-Za-z0-9-]/"
                                           , "")
                                         )
  pk_secret_name                       = local.key_exist ? (
                                           local.input_public_key_secret_name) : (
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
  pwd_secret_name                      = local.pwd_exist ? (
                                           local.input_password_secret_name) : (
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
  username_secret_name                 = local.username_exist ? (
                                           local.input_username_secret_name) : (
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
  user_keyvault_name                   = var.key_vault.kv_exists ? split("/", var.key_vault.kv_user_id)[8] : local.keyvault_names.user_access
  # user_keyvault_resourcegroup_name     = var.key_vault.kv_exists ? split("/", var.key_vault.kv_user_id)[4] : ""

  automation_keyvault_name             = local.automation_keyvault_exist ? split("/", local.prvt_key_vault_id)[8] : local.keyvault_names.private_access
  # automation_keyvault_resourcegroup_name = local.automation_keyvault_exist ? split("/", local.prvt_key_vault_id)[4] : ""

  // Tags
  tags                                 = try(var.deployer.tags, { "Role" = "Deployer" })

}
