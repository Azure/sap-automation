# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

#######################################4#######################################8
#                                                                              #
#                           Environment definitions                            #
#                                                                              #
#######################################4#######################################8


variable "environment"                           {
                                                   description = "This is the environment name of the deployer"
                                                   type        = string
                                                   default     = ""
                                                 }

variable "codename"                              {
                                                   description = "Additional component for naming the resources"
                                                   default     = ""
                                                   type        = string
                                                 }

variable "location"                              {
                                                   description = "Defines the Azure location where the resources will be deployed"
                                                   type        = string
                                                 }

variable "name_override_file"                    {
                                                   description = "If provided, contains a json formatted file defining the name overrides"
                                                   default     = ""
                                                 }

variable "use_deployer"                          {
                                                   description = "Use deployer to deploy the resources"
                                                   default     = true
                                                 }

variable "place_delete_lock_on_resources"        {
                                                   description = "If defined, a delete lock will be placed on the key resources"
                                                   default     = false
                                                 }

variable "prevent_deletion_if_contains_resources" {
                                                    description = "Controls if resource groups are deleted even if they contain resources"
                                                    type        = bool
                                                    default     = true
                                                  }


variable "short_named_endpoints_nics"            {
                                                   description = "If defined, uses short names for private endpoints nics"
                                                   default     = false
                                                 }


variable "use_spn"                               {
                                                  description = "Log in using a service principal when performing the deployment"

                                                 }

variable "spn_id"                                {
                                                   description = "SPN ID to be used for the deployment"
                                                   nullable    = true
                                                 }

variable "subscription_id"                       {
                                                   description = "Defines the Azure subscription_id"
                                                   type        = string
                                                   default     = null
                                                 }

variable "deployer_prefix"                       {
                                                    description = "Defines the prefix for the deployer"
                                                    type        = string
                                                    default     = ""
                                                 }

variable "assign_permissions"                    {
                                                    description = "Boolean value indicating if permissions should be assigned to the storage accounts"
                                                    default     = true
                                                    type        = bool
                                                  }

#######################################4#######################################8
#                                                                              #
#                          Resource group definitions                          #
#                                                                              #
#######################################4#######################################8

variable "resourcegroup_name"                   {
                                                  description = "If provided, the name of the resource group to be created"
                                                  default     = ""
                                                }

variable "resourcegroup_arm_id"                 {
                                                  description = "If provided, the Azure resource group id"
                                                  default     = ""
                                                }

variable "resourcegroup_tags"                   {
                                                  description = "Tags to be applied to the resource group"
                                                  default     = {}
                                                }


#########################################################################################
#                                                                                       #
#  SAPBits storage account                                                              #
#                                                                                       #
#########################################################################################


variable "library_sapmedia_arm_id"               {
                                                   description = "Optional Azure resource identifier for the storage account where the SAP bits will be stored"
                                                   default     = ""
                                                 }

variable "library_sapmedia_name"                 {
                                                   description = "If defined, the name of the storage account where the SAP bits will be stored"
                                                   default     = ""
                                                 }

variable "library_sapmedia_account_tier"         {
                                                   description = "The storage account tier"
                                                   default     = "Standard"
                                                 }

variable "library_sapmedia_account_replication_type" {
                                                        description = "The replication type for the storage account"
                                                        default     = "LRS"
                                                      }

variable "library_sapmedia_account_kind"         {
                                                   description = "The storage account kind"
                                                   default     = "StorageV2"
                                                 }

variable "library_sapmedia_file_share_enable_deployment" {
                                                            description = "If true, the file share will be created"
                                                            default     = true
                                                         }

variable "library_sapmedia_file_share_is_existing" {
                                                      description = "If defined use an existing file share"
                                                      default     = false
                                                    }

variable "library_sapmedia_file_share_name"      {
                                                   description = "If defined, the name of the file share"
                                                   default     = "sapbits"
                                                 }
variable "library_sapmedia_blob_container_enable_deployment" {
                                                               description = "If true, the blob container will be created"
                                                               default     = true
                                                             }

variable "library_sapmedia_blob_container_is_existing" {
                                                         description = "If defined use an existing blob container"
                                                         default     = false
                                                       }

variable "library_sapmedia_blob_container_name" {
                                                  description = "If defined, the name of the blob container"
                                                  default     = "sapbits"
}


#########################################################################################
#                                                                                       #
#  Terraform state storage account                                                              #
#                                                                                       #
#########################################################################################



variable "library_terraform_state_arm_id"        {
                                                   description = "Optional Azure resource identifier for the storage account where the terraform state will be stored"
                                                   default     = ""
                                                 }

variable "library_terraform_state_name"          {
                                                    description = "Optional name for the storage account where the terraform state will be stored"
                                                    default     = ""
                                                 }

variable "library_terraform_state_account_tier" {
                                                  description = "The storage account tier"
                                                  default     = "Standard"
}

variable "library_terraform_state_account_replication_type" {
                                                              description = "The replication type for the storage account"
                                                              default     = "LRS"
                                                            }

variable "library_terraform_state_account_kind"  {
                                                   description = "The storage account kind"
                                                   default     = "StorageV2"
                                                 }

variable "library_terraform_state_blob_container_is_existing" {
                                                                 description = "If defined use an existing blob container"
                                                                 default     = false
                                                              }

variable "library_terraform_state_blob_container_name" {
                                                          description = "If defined, the blob container name to create"
                                                          default     = "tfstate"
                                                       }

variable "library_ansible_blob_container_is_existing" {
                                                        description = "If defined use an existing blob container"
                                                        default     = false
                                                      }

variable "library_ansible_blob_container_name"   {
                                                    description = "If defined, the blob container name to create"
                                                    default     = "ansible"
                                                 }

variable "library_terraform_vars_blob_container_is_existing"  {
                                                                description = "If defined use an existing blob container for terraform vars"
                                                                default     = false
                                                              }

variable "library_terraform_vars_blob_container_name" {
                                                        description = "If defined, the blob container name to create"
                                                        default     = "tfvars"
                                                      }

variable "use_private_endpoint"                  {
                                                   description = "Boolean value indicating if private endpoint should be used for the deployment"
                                                   default     = false
                                                   type        = bool
                                                 }

variable "public_network_access_enabled"              {
                                                        description = "Boolean value indicating if public access should be enabled for key vaults and storage"
                                                        default     = true
                                                        type        = bool
                                                      }
#########################################################################################
#                                                                                       #
#  Miscallaneous definitions                                                            #
#                                                                                       #
#########################################################################################

variable "spn_keyvault_id"                      {
                                                  description = "Azure resource identifier for the keyvault where the spn will be stored"
                                                  default = ""
                                                }

variable "deployment"                           {
                                                  description = "The type of deployment"
                                                  default     = "update"
                                                }

variable "shared_access_key_enabled"            {
                                                  description = "Indicates whether the storage account permits requests to be authorized with the account access key via Shared Key."
                                                  default     = false
                                                  type        = bool
                                                }

variable "data_plane_available"                 {
                                                  description = "Boolean value indicating if storage account access is via data plane"
                                                  default     = true
                                                  type        = bool
                                                }

variable "custom_random_id"                     {
                                                  description = "If provided, the value of the custom random id"
                                                  default     = ""
                                                }

#########################################################################################
#                                                                                       #
#  Web App definitions                                                                  #
#                                                                                       #
#########################################################################################

variable "use_webapp"                            {
                                                   description = "Boolean value indicating if a webapp should be created"
                                                   default     = false
                                                 }

variable "application_configuration_deployment"                         {
                                                        description = "Boolean value indicating if a webapp should be deployed"
                                                        default     = false
                                                      }

variable "Agent_IP"                              {
                                                   description = "IP address of the agent"
                                                   default     = ""
                                                 }

variable "add_Agent_IP"                          {
                                                    description = "Boolean value indicating if the Agent IP should be added to the storage and key vault firewalls"
                                                    default     = true
                                                    type        = bool
                                                  }


variable "tfstate_resource_id"                       {
                                                       description = "Resource id of tfstate storage account"
                                                       validation {
                                                                    condition = (
                                                                      length(split("/", var.tfstate_resource_id)) == 9
                                                                    )
                                                                    error_message = "The Azure Resource ID for the storage account containing the Terraform state files must be provided and be in correct format."
                                                                  }

                                                     }

#########################################################################################
#                                                                                       #
#  DNS settings                                                                         #
#                                                                                       #
#########################################################################################


variable "dns_label"                             {
                                                   description = "DNS label"
                                                   default     = ""
                                                 }

variable "use_custom_dns_a_registration"         {
                                                   description = "Boolean value indicating if a custom dns a record should be created when using private endpoints"
                                                   default     = false
                                                   type        = bool
                                                 }

variable "management_dns_subscription_id"        {
                                                   description = "String value giving the possibility to register custom dns a records in a separate subscription"
                                                   default     = ""
                                                   type        = string
                                                 }

variable "management_dns_resourcegroup_name"     {
                                                   description = "String value giving the possibility to register custom dns a records in a separate resourcegroup"
                                                   default     = ""
                                                   type        = string
                                                 }


variable "dns_zone_names"                        {
                                                   description = "Private DNS zone names"
                                                   type        = map(string)
                                                   default = {
                                                               "file_dns_zone_name"      = "privatelink.file.core.windows.net"
                                                               "blob_dns_zone_name"      = "privatelink.blob.core.windows.net"
                                                               "table_dns_zone_name"     = "privatelink.table.core.windows.net"
                                                               "vault_dns_zone_name"     = "privatelink.vaultcore.azure.net"
                                                               "appconfig_dns_zone_name" = "privatelink.azconfig.io"
                                                             }

                                                 }

variable "enable_firewall_for_keyvaults_and_storage" {
                                                       description = "Boolean value indicating if firewall should be enabled for key vaults and storage"
                                                       default     = true
                                                       type        = bool
                                                     }

variable "register_storage_accounts_keyvaults_with_dns" {
                                                     description = "Boolean value indicating if storage accounts and key vaults should be registered to the corresponding dns zones"
                                                     default     = true
                                                     type        = bool
                                                   }

variable "register_endpoints_with_dns"             {
                                                     description = "Boolean value indicating if endpoints should be registered to the dns zone"
                                                     default     = true
                                                     type        = bool
                                                   }

variable "privatelink_dns_subscription_id"       {
                                                   description = "String value giving the possibility to register custom PrivateLink DNS A records in a separate subscription"
                                                   default     = ""
                                                   type        = string
                                                 }

variable "privatelink_dns_resourcegroup_name"    {
                                                   description = "String value giving the possibility to register custom PrivateLink DNS A records in a separate resourcegroup"
                                                   default     = ""
                                                   type        = string
                                                 }

variable "create_privatelink_dns_zones"          {
                                                   description = "Boolean value indicating if PrivateLink DNS Zones should be created"
                                                   default     = true
                                                   type        = bool
                                                 }

#########################################################################################
#                                                                                       #
#  Miscellaneous                                                                         #
#                                                                                       #
#########################################################################################

variable "additional_network_id"                {
                                                   description = "Agent Network resource ID"
                                                   default     = ""
                                                 }


variable "tags"                                  {
                                                   description = "If provided, tags for all resources"
                                                   default     = {}
                                                 }
variable "application_configuration_id"          {
                                                    description = "Defines the Azure application configuration Resource id"
                                                    type        = string
                                                    default     = ""
                                                 }
