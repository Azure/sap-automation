#######################################4#######################################8
#                                                                              #
# This file contains the input variables for the SAP landscape module          #
#                                                                              #
#######################################4#######################################8



#######################################4#######################################8
#                                                                              #
#                             Azure NetApp Volumes                             #
#                                                                              #
#######################################4#######################################8

variable "infrastructure"                               {
                                                           description = "Details of the Azure infrastructure to deploy the SAP landscape into"
                                                           default     = {}
                                                           validation {
                                                             condition = (
                                                               length(trimspace(try(var.infrastructure.region, ""))) != 0
                                                             )
                                                             error_message = "The region must be specified in the infrastructure.region field."
                                                           }

                                                           validation {
                                                             condition = (
                                                               length(trimspace(try(var.infrastructure.environment, ""))) != 0
                                                             )
                                                             error_message = "The environment must be specified in the infrastructure.environment field."
                                                           }

                                                           validation {
                                                             condition = (
                                                               length(trimspace(try(var.infrastructure.vnets.sap.logical_name, ""))) != 0
                                                             )
                                                             error_message = "Please specify the logical VNet identifier in the infrastructure.vnets.sap.name field. For deployments prior to version '2.3.3.1' please use the identifier 'sap'."
                                                           }

                                                           validation {
                                                             condition = (
                                                               length(trimspace(try(var.infrastructure.vnets.sap.arm_id, ""))) != 0 || length(var.infrastructure.vnets.sap.address_space[0]) != 0
                                                             )
                                                             error_message = "Either the arm_id or (name and address_space) of the Virtual Network must be specified in the infrastructure.vnets.sap block."
                                                           }
                                                        }

variable "options"                                      { description = "Configuration options" }

variable "authentication"                               {
                                                          description = "Details of ssh key pair"
                                                          default = {
                                                                      username            = "azureadm",
                                                                      password            = ""
                                                                      path_to_public_key  = "",
                                                                      path_to_private_key = ""
                                                                    }

                                                          validation {
                                                                       condition = (
                                                                         length(var.authentication) >= 1
                                                                       )
                                                                       error_message = "Either ssh keys or user credentials must be specified."
                                                                     }
                                                          validation {
                                                                       condition = (
                                                                         length(trimspace(var.authentication.username)) != 0
                                                                       )
                                                                       error_message = "The default username for the Virtual machines must be specified."
                                                                     }
                                                        }

#######################################4#######################################8
#                                                                              #
#  Key Vault variables                                                         #
#                                                                              #
#######################################4#######################################8

variable "key_vault"                                    {
                                                          description = "The user brings existing Azure Key Vaults"
                                                          default = {}
                                                          validation {
                                                                       condition = (
                                                                         contains(keys(var.key_vault), "kv_spn_id") ? (
                                                                           length(split("/", var.key_vault.kv_spn_id)) == 9) : (
                                                                           true
                                                                         )
                                                                       )
                                                                       error_message = "If specified, the kv_spn_id needs to be a correctly formed Azure resource ID."
                                                                     }
                                                          validation {
                                                                       condition = (
                                                                         contains(keys(var.key_vault), "kv_user_id") ? (
                                                                           length(split("/", var.key_vault.kv_user_id)) == 9) : (
                                                                           true
                                                                         )
                                                                       )
                                                                       error_message = "If specified, the kv_user_id needs to be a correctly formed Azure resource ID."
                                                                     }

                                                          validation {
                                                                       condition = (
                                                                         contains(keys(var.key_vault), "kv_prvt_id") ? (
                                                                           length(split("/", var.key_vault.kv_prvt_id)) == 9) : (
                                                                           true
                                                                         )
                                                                       )
                                                                       error_message = "If specified, the kv_prvt_id needs to be a correctly formed Azure resource ID."
                                                                     }

                                                        }

variable "additional_users_to_add_to_keyvault_policies" { description = "Additional users to add to the key vault policies" }

variable "enable_purge_control_for_keyvaults"           { description = "Disables the purge protection for Azure keyvaults." }


variable "enable_rbac_authorization_for_keyvault"       { description = "Enables RBAC authorization for Azure keyvault" }

variable "keyvault_private_endpoint_id"                 { description = "Existing private endpoint for key vault" }

variable "soft_delete_retention_days"                   { description = "The number of days that items should be retained in the soft delete period" }


#########################################################################################
#                                                                                       #
#  Storage Account Variables                                                            #
#                                                                                       #
#########################################################################################


variable "diagnostics_storage_account"                  {
                                                          description = "Storage account information for diagnostics account"
                                                          default = {
                                                                      arm_id = ""
                                                                    }
                                                        }

variable "witness_storage_account"                      {
                                                          description = "Storage account information for witness storage account"
                                                          default = {
                                                                      arm_id = ""
                                                                    }
                                                        }

variable "create_transport_storage"                     { description = "Boolean file indicating if storage should be created for SAP transport" }

variable "transport_volume_size"                        { description = "The volume size in GB for transport volume" }

variable "install_volume_size"                          { description = "The volume size in GB for install volume" }


variable "transport_storage_account_id"                 { description = "Azure Resource Identifier for an existing storage account" }

variable "transport_private_endpoint_id"                { description = "Azure Resource Identifier for an private endpoint connection" }

variable "install_storage_account_id"                   { description = "Azure Resource Identifier for an existing storage account" }

variable "install_private_endpoint_id"                  { description = "Azure Resource Identifier for an private endpoint connection" }
variable "install_always_create_fileshares"             { description = "Value indicating if file shares are created ehen using existing storage accounts" }

variable "storage_account_replication_type"             {
                                                          description = "Storage account replication type"
                                                          default     = "ZRS"
                                                        }

#######################################4#######################################8
#                                                                              #
#  Miscallaneous variables                                                     #
#                                                                              #
#######################################4#######################################8

variable "deployment"                                   {
                                                          description = "The type of deployment"
                                                          default     = "update"
                                                        }

variable "terraform_template_version"                   { description = "The version of Terraform templates that were identified in the state file" }

variable "deployer_tfstate"                             { description = "Deployer remote tfstate file" }

variable "service_principal"                            { description = "Current service principal used to authenticate to Azure" }

variable "naming"                                       { description = "Defines the names for the resources" }

variable "use_deployer"                                 { description = "Use the deployer" }

variable "ANF_settings"                                 {
                                                          description = "ANF settings"
                                                          default = {
                                                                      use                           = false
                                                                      name                          = ""
                                                                      arm_id                        = ""
                                                                      pool_name                     = ""
                                                                      use_existing_pool             = false
                                                                      service_level                 = "Standard"
                                                                      size_in_tb                    = 4
                                                                      qos_type                      = "Manual"
                                                                      use_existing_transport_volume = false
                                                                      transport_volume_name         = ""
                                                                      transport_volume_size         = 32
                                                                      transport_volume_throughput   = 32

                                                                      use_existing_install_volume   = false
                                                                      install_volume_name           = ""
                                                                      install_volume_size           = 128
                                                                      install_volume_throughput     = 32
                                                                    }
                                                        }


variable "place_delete_lock_on_resources"                { description = "If defined, a delete lock will be placed on the key resources" }


#########################################################################################
#                                                                                       #
#  DNS Settings                                                                         #
#                                                                                       #
#########################################################################################


variable "dns_label"                                     { description = "DNS label for the system, for example azure.contoso.net" }

variable "dns_server_list"                               {
                                                           description = "The list of DNS Servers to associate with the VNet"
                                                           default     = []
                                                         }

variable "register_virtual_network_to_dns"               {
                                                           description = "Boolean value indicating if the vnet should be registered to the dns zone"
                                                           type        = bool
                                                         }


variable "use_custom_dns_a_registration"                 {
                                                           description = "Boolean value indicating if a custom dns a records should be created for private endpoints"
                                                           default     = false
                                                           type        = bool
                                                         }

variable "management_dns_subscription_id"                { description = "String value giving the possibility to register custom dns a records in a separate subscription" }

variable "management_dns_resourcegroup_name"             { description = "String value giving the possibility to register custom dns a records in a separate resourcegroup" }

variable "dns_zone_names"                                {
                                                           description = "Private DNS zone names"
                                                           type        = map(string)
                                                           default = {
                                                                      "file_dns_zone_name"   = "privatelink.file.core.windows.net"
                                                                      "blob_dns_zone_name"   = "privatelink.blob.core.windows.net"
                                                                      "table_dns_zone_name"  = "privatelink.table.core.windows.net"
                                                                      "vault_dns_zone_name"  = "privatelink.vaultcore.azure.net"
                                                                     }
                                                         }

variable "use_private_endpoint"                          {
                                                           description = "Boolean value indicating if private endpoint should be used for the deployment"
                                                           default     = false
                                                           type        = bool
                                                         }

variable "use_service_endpoint"                          {
                                                           description = "Boolean value indicating if service endpoints should be used for the deployment"
                                                           default     = false
                                                           type        = bool
                                                         }


variable "NFS_provider"                                  { description = "Describes the NFS solution used" }

variable "Agent_IP"                                      {
                                                           description = "If provided, contains the IP address of the agent"
                                                           type        = string
                                                           default     = ""
                                                         }

variable "vm_settings"                                   {
                                                           description = "Details of the jumpbox to deploy"
                                                           default = {
                                                             count = 0
                                                           }
                                                         }

variable "peer_with_control_plane_vnet"                  { description = "Defines in the SAP VNet will be peered with the controlplane VNet" }

variable "enable_firewall_for_keyvaults_and_storage"     { description = "Boolean value indicating if firewall should be enabled for key vaults and storage" }

variable "public_network_access_enabled"                 { description = "Defines if the public access should be enabled for keyvaults and storage accounts" }

variable "use_AFS_for_shared_storage"                    {
                                                           description = "If true, will use AFS for installation media."
                                                           default = false
                                                         }

variable "tags"                                          { description = "List of tags to associate to all resources" }
