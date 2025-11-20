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

variable "subscription_id"                       {
                                                   description = "Defines the Azure subscription_id"
                                                   type        = string
                                                   default     = null
                                                   validation {
                                                     condition     = length(var.subscription_id) == 0 ? true : length(var.subscription_id) == 36
                                                     error_message = "If specified the 'subscription_id' variable must be a correct subscription ID."
                                                   }

                                                 }

variable "prevent_deletion_if_contains_resources" {
                                                    description = "Controls if resource groups are deleted even if they contain resources"
                                                    type        = bool
                                                    default     = true
                                                  }

variable "recover"                                {
                                                   description = "Boolean flag indicating if the deployer should be recovered"
                                                   default     = false
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
                                                  validation {
                                                    condition     = length(var.resourcegroup_arm_id) == 0 ? true : can(provider::azurerm::parse_resource_id(var.resourcegroup_arm_id))
                                                    error_message = "If specified the 'resourcegroup_arm_id' variable must be a correct Azure resource identifier."
                                                  }
                                                }

variable "resourcegroup_tags"                   {
                                                                                                  description = "Tags to be applied to the resource group"
                                                  default     = {}
                                                }

variable "place_delete_lock_on_resources"       {
                                                  description = "If defined, a delete lock will be placed on the key resources"
                                                  default     = false
                                                }

#######################################4#######################################8
#                                                                              #
#                     Virtual Network variables                                #
#                                                                              #
#######################################4#######################################8

variable "management_network_name"              {
                                                  description = "If provided, the name of the VNet into which the deployer will be deployed"
                                                  default     = ""
                                                }

variable "management_network_logical_name"      {
                                                  description = "The logical name of the VNet, used for naming purposes"
                                                  default     = ""
                                                }

variable "management_network_arm_id"            {
                                                  description = "Azure resource identifier for the existing VNet into which the deployer will be deployed"
                                                  default     = ""
                                                  validation {
                                                    condition     = length(var.management_network_arm_id) == 0 ? true : can(provider::azurerm::parse_resource_id(var.management_network_arm_id))
                                                    error_message = "If specified the 'management_network_arm_id' variable must be a correct Azure resource identifier."
                                                  }
                                                }

variable "management_network_address_space"     {
                                                  description = "The address space of the VNet into which the deployer will be deployed"
                                                  default     = ""
                                                }

variable "management_network_flow_timeout_in_minutes"      {
                                                  description = "The flow timeout in minutes of the virtual network"
                                                  type = number
                                                  nullable = true
                                                  default = null
                                                  validation {
                                                    condition     = var.management_network_flow_timeout_in_minutes == null ? true : (var.management_network_flow_timeout_in_minutes >= 4 && var.management_network_flow_timeout_in_minutes <= 30)
                                                    error_message = "The flow timeout in minutes must be between 4 and 30 if set."
                                                  }
                                                }

#######################################4#######################################8
#                                                                              #
#                          Management Subnet variables                         #
#                                                                              #
#######################################4#######################################8

variable "management_subnet_name"               {
                                                  description = "The name of the subnet into which the deployer will be deployed"
                                                  default     = ""
                                                }

variable "management_subnet_arm_id"             {
                                                  description = "Azure resource identifier for the existing subnet into which the deployer will be deployed"
                                                  default     = ""
                                                  validation {
                                                    condition     = length(var.management_subnet_arm_id) == 0 ? true : can(provider::azurerm::parse_resource_id(var.management_subnet_arm_id))
                                                    error_message = "If specified the 'management_subnet_arm_id' variable must be a correct Azure resource identifier."
                                                  }
                                                }

variable "management_subnet_address_prefix"     {
                                                  description = "The address prefix of the subnet into which the deployer will be deployed"
                                                  default     = ""
                                                }

#######################################4#######################################8
#                                                                              #
#                            Firewall Subnet variables                         #
#                                                                              #
#######################################4#######################################8

variable "management_firewall_subnet_arm_id"    {
                                                  description = "Azure resource identifier for the existing subnet into which the firewall will be deployed"
                                                  default     = ""
                                                  validation {
                                                    condition     = length(var.management_firewall_subnet_arm_id) == 0 ? true : can(provider::azurerm::parse_resource_id(var.management_firewall_subnet_arm_id))
                                                    error_message = "If specified the 'management_firewall_subnet_arm_id' variable must be a correct Azure resource identifier."
                                                  }
                                                }

variable "management_firewall_subnet_address_prefix" {
                                                       description = "value of the address prefix of the subnet into which the firewall will be deployed"
                                                       default     = ""
                                                     }


variable "firewall_deployment"                  {
                                                  description = "Boolean flag indicating if an Azure Firewall should be deployed"
                                                  default     = false
                                                  type        = bool
                                                }

variable "firewall_rule_subnets"                {
                                                  description = "List of subnets that are part of the firewall rule"
                                                  default     = []
                                                }

variable "firewall_allowed_ipaddresses"         {
                                                  description = "List of allowed IP addresses to be part of the firewall rule"
                                                  default     = []
                                                }

variable "firewall_public_ip_tags"              {
                                                  description = "Tags for the public_ip resource attached to firewall"
                                                  type        = map(string)
                                                  default     = null
                                                }

#######################################4#######################################8
#                                                                              #
#                             Bastion Subnet variables                         #
#                                                                              #
#######################################4#######################################8

variable "management_bastion_subnet_arm_id"     {
                                                  description = "Azure resource identifier Azure Bastion subnet"
                                                  default     = ""
                                                  validation {
                                                    condition     = length(var.management_bastion_subnet_arm_id) == 0 ? true : can(provider::azurerm::parse_resource_id(var.management_bastion_subnet_arm_id))
                                                    error_message = "If specified the 'management_bastion_subnet_arm_id' variable must be a correct Azure resource identifier."
                                                  }
                                                }

variable "management_bastion_subnet_address_prefix" {
                                                      description = "Subnet adress range for the bastion subnet"
                                                      default     = ""
                                                    }


variable "bastion_deployment"                   {
                                                  description = "Boolean flag indicating if an Azure bastion should be deployed"
                                                  default     = false
                                                }

variable "bastion_sku"                          {
                                                  description = "The SKU of the Bastion Host. Accepted values are Basic or Standard"
                                                  default     = "Basic"
                                                }

variable "bastion_public_ip_tags"              {
                                                  description = "Tags for the public_ip resource attached to bastion"
                                                  type        = map(string)
                                                  default     = null
                                                }
#######################################4#######################################8
#                                                                              #
#                           App Service Subnet variables                       #
#                                                                              #
#######################################4#######################################8


variable "webapp_subnet_arm_id"                 {
                                                  description = "Azure resource identifier Web App subnet"
                                                  default     = ""
                                                  validation {
                                                    condition     = length(var.webapp_subnet_arm_id) == 0 ? true : can(provider::azurerm::parse_resource_id(var.webapp_subnet_arm_id))
                                                    error_message = "If specified the 'webapp_subnet_arm_id' variable must be a correct Azure resource identifier."
                                                  }
                                                }

variable "webapp_subnet_address_prefix"        {
                                                  description = "Subnet address range for the Web App subnet"
                                                  default     = ""
                                                }


###############################################################################
#                                                                             #
#                            Management NSG                                   #
#                                                                             #
###############################################################################

variable "management_subnet_nsg_name"           {
                                                  description = "The name of the network security group"
                                                  default     = ""
                                                }

variable "management_subnet_nsg_arm_id"         {
                                                  description = "value of the Azure resource identifier for the network security group"
                                                  default     = ""
                                                  validation {
                                                    condition     = length(var.management_subnet_nsg_arm_id) == 0 ? true : can(provider::azurerm::parse_resource_id(var.management_subnet_nsg_arm_id))
                                                    error_message = "If specified the 'management_subnet_nsg_arm_id' variable must be a correct Azure resource identifier."
                                                  }
                                                }

variable "management_subnet_nsg_allowed_ips"    {
                                                  description = "IP allowed to access the deployer"
                                                  default = []
                                                }

variable "deployer_enable_public_ip"            {
                                                  description = "value to enable/disable public ip"
                                                  default     = false
                                                  type        = bool
                                                }

variable "deployer_public_ip_tags"              {
                                                  description = "Tags for the public_ip resource attached to deployer"
                                                  type        = map(string)
                                                  default     = null
                                                }
###############################################################################
#                                                                             #
#                            Deployer Information                             #
#                                                                             #
###############################################################################

variable "deployer_size"                        {
                                                  description = "The size of the deployer VM"
                                                  default     = "Standard_D4ds_v4"
                                                }

variable "deployer_count"                       {
                                                  description = "Number of deployer VMs to be created"
                                                  default     = 1
                                                }

variable "deployer_disk_type"                   {
                                                  description = "The type of the disk for the deployer VM"
                                                  default     = "Premium_LRS"
                                                }

variable "deployer_use_DHCP"                    {
                                                  description = "If true, the deployers will use Azure Provided IP addresses"
                                                  default     = false
                                                }

variable "deployer_image"                       {
                                                  description = "The image to be used for the deployer VM"
                                                  default     = {
                                                                  os_type         = "LINUX"
                                                                  source_image_id = ""
                                                                  type            = "marketplace"
                                                                  publisher       = "Canonical"
                                                                  offer           = "0001-com-ubuntu-server-jammy"
                                                                  sku             = "22_04-lts-gen2"
                                                                  version         = "latest"
                                                                  type            = "marketplace"
                                                                }
                                                }

variable "license_type"                         {
                                                  description = "The type of the image to be used for the deployer VM"
                                                  default     = ""
                                                }


variable "deployer_private_ip_address"          {
                                                  description = "If provides, the value of the deployer Virtual machine IPs"
                                                  default = [""]
                                                }


variable "shared_access_key_enabled"            {
                                                  description = "Indicates whether the storage account permits requests to be authorized with the account access key via Shared Key."
                                                  default     = false
                                                  type        = bool
                                                }

variable "encryption_at_host_enabled"           {
                                                  description = "Enable or disable host encryption for the deployer"
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

###############################################################################
#                                                                             #
#                            Deployer authentication                          #
#                                                                             #
###############################################################################

variable "deployer_authentication_type"         {
                                                  description = "value to define the authentication type for the deployer"
                                                  default = "key"
                                                }

variable "deployer_authentication_username"     {
                                                  description = "value to define the username for the deployer"
                                                  default = "azureadm"
                                                }

variable "deployer_authentication_password"     {
                                                  description = "value to define the password for the deployer"
                                                  default = ""
                                                }

variable "deployer_authentication_path_to_public_key" {
                                                        description = "The path to an existing ssh public key, on the deployer"
                                                        default = ""
                                                      }

variable "deployer_authentication_path_to_private_key" {
                                                        description = "The path to an existing ssh private key, on the deployer"
                                                        default = ""
                                                      }


#######################################4#######################################8
#                                                                              #
#                            Key Vault Information                             #
#                                                                              #
#######################################4#######################################8

variable "user_keyvault_id"                           {
                                                        description = "Azure resource identifier for the Azure Key Vault containing the deployment credentials"
                                                        default     = ""
                                                        validation {
                                                          condition     = length(var.user_keyvault_id) == 0 ? true : can(provider::azurerm::parse_resource_id(var.user_keyvault_id))
                                                          error_message = "If specified the 'user_keyvault_id' variable must be a correct Azure resource identifier."
                                                        }
                                                      }

variable "deployer_private_key_secret_name"           {
                                                        description = "Defines the name of the secret in the Azure Key Vault that contains the private key"
                                                        default     = ""
                                                      }
variable "deployer_public_key_secret_name"            {
                                                        description = "Defines the name of the secret in the Azure Key Vault that contains the public key"
                                                        default     = ""
                                                      }

variable "deployer_username_secret_name" {
                                                        description = "Defines the name of the secret in the Azure Key Vault that contains the user name"
                                                        default     = ""
                                                      }

variable "deployer_password_secret_name"              {
                                                        description = "Defines the name of the secret in the Azure Key Vault that contains the password"
                                                        default     = ""
                                                      }

variable "enable_purge_control_for_keyvaults"         {
                                                        description = "Disables the purge protection for Azure keyvaults."
                                                        type        = bool
                                                        default     = false
                                                      }

variable "soft_delete_retention_days"                 {
                                                        description = "The number of days that items should be retained in the soft delete period"
                                                        default     = 7
                                                      }

variable "additional_users_to_add_to_keyvault_policies" {
                                                          description = "List of object IDs to add to key vault policies"
                                                          default     = [""]
                                                        }

variable "set_secret_expiry"                         {
                                                       description = "Set expiry date for secrets"
                                                       default     = false
                                                       type        = bool
                                                     }

variable "enable_rbac_authorization"                 {
                                                       description = "Enables RBAC authorization for Azure keyvault"
                                                       default     = true
                                                     }

#######################################4#######################################8
#                                                                              #
#  Miscellaneous settings                                                      #
#                                                                              #
#######################################4#######################################8

variable "deployer_assign_subscription_permissions"   {
                                                        description = "Boolean flag indicating if the subscription permissions should be assigned"
                                                        default     = false
                                                        type        = bool
                                                      }


variable "deployer_assign_resource_permissions"   {
                                                        description = "Boolean flag indicating if the resource permissions should be assigned"
                                                        default     = true
                                                        type        = bool
                                                      }


variable "use_private_endpoint"                       {
                                                        description = "Boolean value indicating if private endpoint should be used for the deployment"
                                                        default     = true
                                                        type        = bool
                                                      }

variable "use_service_endpoint"                       {
                                                        description = "Boolean value indicating if service endpoints should be used for the deployment"
                                                        default     = true
                                                        type        = bool
                                                      }


variable "deployer_diagnostics_account_arm_id"        {
                                                        description = "Azure resource identifier for an existing storage account that will be used for diagnostic logs"
                                                        default     = ""
                                                        validation {
                                                          condition     = length(var.deployer_diagnostics_account_arm_id) == 0 ? true : can(provider::azurerm::parse_resource_id(var.deployer_diagnostics_account_arm_id))
                                                          error_message = "If specified the 'deployer_diagnostics_account_arm_id' variable must be a correct Azure resource identifier."
                                                        }
                                                      }


variable "tf_version"                                 {
                                                        description = "Terraform version to install on deployer"
                                                        default     = ""
                                                      }

variable "tfstate_resource_id"                       {
                                                       description = "Resource id of tfstate storage account"
                                                       validation {
                                                                    condition = can(provider::azurerm::parse_resource_id(var.tfstate_resource_id)
                                                                    )
                                                                    error_message = "The Azure Resource ID for the storage account containing the Terraform state files must be provided and be in correct format."
                                                                  }

                                                     }


variable "name_override_file"                         {
                                                        description = "If provided, contains a json formatted file defining the name overrides"
                                                        default     = ""
                                                      }

variable "auto_configure_deployer"                    {
                                                        description = "Value indicating if the deployer should be configured automatically"
                                                        default     = true
                                                      }

variable "spn_id"                                     {
                                                        description = "SPN ID to be used for the deployment"
                                                        nullable    = true
                                                        default     = ""

                                                        validation {
                                                          condition     = length(var.spn_id) == 0 ? true : length(var.spn_id) == 36
                                                          error_message = "If specified the 'spn_id' variable must be a correct subscription ID."
                                                        }

                                                      }

variable "public_network_access_enabled"              {
                                                        description = "Boolean value indicating if public access should be enabled for key vaults and storage"
                                                        default     = false
                                                        type        = bool
                                                      }


variable "subnets_to_add_to_firewall_for_keyvaults_and_storage" {
                                                                  description = "List of subnets to add to storage account and keyvaults firewall"
                                                                  default     = []
                                                                }

variable "tags"                                       {
                                                        description = "If provided, tags for all resources"
                                                        default     = {}
                                                      }

variable "additional_network_id"                     {
                                                       description = "Agent Network resource ID"
                                                       default     = ""
                                                     }

#########################################################################################
#                                                                                       #
#  DNS settings                                                                         #
#                                                                                       #
#########################################################################################

variable "use_custom_dns_a_registration"              {
                                                        description = "Boolean value indicating if a custom dns a record should be created when using private endpoints"
                                                        default     = false
                                                        type        = bool
                                                      }

variable "management_dns_subscription_id"             {
                                                        description = "String value giving the possibility to register custom dns a records in a separate subscription"
                                                        default     = ""
                                                        type        = string

                                                        validation {
                                                          condition     = length(var.management_dns_subscription_id) == 0 ? true : length(var.management_dns_subscription_id) == 36
                                                          error_message = "If specified the 'management_dns_subscription_id' variable must be a correct subscription ID."
                                                        }
                                                      }
variable "management_dns_resourcegroup_name"          {
                                                        description = "String value giving the possibility to register custom dns a records in a separate resourcegroup"
                                                        default     = ""
                                                        type        = string
                                                      }

variable "dns_zone_names"                             {
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

variable "privatelink_dns_subscription_id"            {
                                                        description = "String value giving the possibility to register custom PrivateLink DNS A records in a separate subscription"
                                                        default     = ""
                                                        type        = string
                                                        validation {
                                                          condition     = length(var.privatelink_dns_subscription_id) == 0 ? true : length(var.privatelink_dns_subscription_id) == 36
                                                          error_message = "If specified the 'privatelink_dns_subscription_id' variable must be a correct subscription ID."
                                                        }
                                                      }


variable "privatelink_dns_resourcegroup_name"         {
                                                        description = "String value giving the possibility to register custom PrivateLink DNS A records in a separate resourcegroup"
                                                        default     = ""
                                                        type        = string
                                                      }

variable "register_endpoints_with_dns"             {
                                                     description = "Boolean value indicating if endpoints should be registered to the dns zone"
                                                     default     = true
                                                     type        = bool
                                                   }

variable "register_storage_accounts_keyvaults_with_dns" {
                                                     description = "Boolean value indicating if storage accounts and key vaults should be registered to the corresponding dns zones"
                                                     default     = true
                                                     type        = bool
                                                   }


#########################################################################################
#                                                                                       #
#  ADO definitions                                                                      #
#                                                                                       #
#########################################################################################

variable "agent_pool"                                 {
                                                        description = "If provided, contains the name of the agent pool to be used"
                                                        default     = ""
                                                      }

variable "agent_pat" {
                                                        description = "If provided, contains the Personal Access Token to be used"
                                                        default     = ""
                                                      }

variable "agent_ado_url"                              {
                                                        description = "If provided, contains the Url to the ADO repository"
                                                        default     = ""
                                                      }

variable "agent_ado_project"                         {
                                                        description = "If provided, contains the project name ADO repository"
                                                        default     = ""
                                                      }

variable "ansible_core_version"                       {
                                                        description = "If provided, the version of ansible core to be installed"
                                                        default     = ""
                                                      }

variable "dev_center_deployment"                      {
                                                        description = "Boolean flag indicating if a Dev Center should be deployed"
                                                        default     = false
                                                      }

variable "DevOpsInfrastructure_object_id"             {
                                                        description = "Service principal object id for the DevOps Infrastructure"
                                                        default     = ""
                                                      }

variable "devops_platform"                            {
                                                        description = "Type of agent to be used"
                                                        type        = string
                                                        default     = ""
                                                      }
variable "github_app_token"                           {
                                                        description = "If provided, contains token to access github"
                                                        default     = ""
                                                      }
variable "github_server_url"                          {
                                                        description = "If provided, contains the Server Url of the GitHub instance"
                                                        default     = "https://github.com"
                                                      }
variable "github_api_url"                             {
                                                        description = "If provided, contains the API Url of the GitHub instance"
                                                        default     = "https://api.github.com"
                                                      }
variable "github_repository"                          {
                                                        description = "If provided, contains the Reference to the repositry (e.g. owner/repository)"
                                                        default     = ""
                                                      }

#######################################4#######################################8
#                                                                              #
#                              Agent Subnet variables                          #
#                                                                              #
#######################################4#######################################8

variable "agent_subnet_name"                    {
                                                  description = "The name of the subnet into which the managed agents will be deployed"
                                                  default     = ""
                                                }

variable "agent_subnet_arm_id"                  {
                                                  description = "Azure resource identifier for the existing subnet into which the managed agents will be deployed"
                                                  default     = ""
                                                  validation {
                                                    condition     = length(var.agent_subnet_arm_id) == 0 ? true : can(provider::azurerm::parse_resource_id(var.agent_subnet_arm_id))
                                                    error_message = "If specified the 'agent_subnet_arm_id' variable must be a correct Azure resource identifier."
                                                  }
                                                }

variable "agent_subnet_address_prefix"          {
                                                  description = "The address prefix of the subnet into which the managed agents will be deployed"
                                                  default     = ""
                                                }


#########################################################################################
#                                                                                       #
#  Web Application settings                                                             #
#                                                                                       #
#########################################################################################

variable "use_webapp"                                 {
                                                        description = "Boolean value indicating if a webapp should be deployed"
                                                        default     = false
                                                      }

variable "app_service_deployment"                     {
                                                        description = "Boolean value indicating if a webapp should be deployed"
                                                        default     = false
                                                      }


variable "app_registration_app_id"                    {
                                                        description = "The app registration id to be used for the webapp"
                                                        default     = ""
                                                        validation {
                                                          condition     = length(var.app_registration_app_id) == 0 ? true : length(var.app_registration_app_id) == 36
                                                          error_message = "If specified the 'app_registration_app_id' variable must be a correct Azure resource identifier."
                                                        }
                                                      }

variable "sa_connection_string"                       {
                                                        description = "value to define the connection string for the Terraform state storage account"
                                                        type        = string
                                                        default     = ""
                                                      }

variable "webapp_client_secret"                       {
                                                        description = "value to define the client secret for the webapp"
                                                        type        = string
                                                        default     = ""
                                                      }

variable "app_service_devops_authentication_type"     {
                                                        description = "The Authentication to use when calling Azure DevOps, MSI/PAT"
                                                        default     = "MSI"
                                                      }

variable "app_service_SKU_name"                       {
                                                        description = "The SKU of the App Service Plan"
                                                        default     = "S1"
                                                      }

variable "enable_firewall_for_keyvaults_and_storage" {
                                                       description = "[OBSOLETE]Boolean value indicating if firewall should be enabled for key vaults and storage"
                                                       default     = false
                                                       type        = bool
                                                     }

variable "Agent_IP"                                  {
                                                       description = "IP address of the agent"
                                                       default     = ""
                                                     }

variable "add_Agent_IP"                              {
                                                        description = "Boolean value indicating if the Agent IP should be added to the storage and key vault firewalls"
                                                        default     = true
                                                        type        = bool
                                                      }

###############################################################################
#                                                                             #
#                                  Identity                                   #
#                                                                             #
###############################################################################

variable "user_assigned_identity_id"                {
                                                       description = "User assigned Identity resource Id"
                                                       default     = ""
                                                     }

variable "add_system_assigned_identity"              {
                                                       description = "Boolean flag indicating if a system assigned identity should be added to the deployer"
                                                       default     = false
                                                       type        = bool
                                                     }

variable "use_spn"                                   {
                                                       description = "Log in using a service principal when performing the deployment"

                                                     }

#########################################################################################
#                                                                                       #
#  Extension variables                                                                  #
#                                                                                       #
#########################################################################################


variable "deploy_monitoring_extension"          {
                                                  description = "If defined, will add the Microsoft.Azure.Monitor.AzureMonitorLinuxAgent extension to the virtual machines"
                                                  default     = false
                                                }

variable "deploy_defender_extension"            {
                                                  description = "If defined, will add the Microsoft.Azure.Security.Monitoring extension to the virtual machines"
                                                  default     = false
                                                }

#########################################################################################
#                                                                                       #
#  Application configuration variables                                                  #
#                                                                                       #
#########################################################################################

variable "application_configuration_id"          {
                                                    description = "Defines the Azure application configuration Resource id"
                                                    type        = string
                                                    default     = ""
                                                 }
variable "application_configuration_deployment"  {
                                                    description = "If defined, will add the Microsoft.Azure.ApplicationConfiguration extension to the virtual machines"
                                                    default     = false
                                                 }

variable "application_configuration_name"          {
                                                    description = "Defines the Azure application configuration name"
                                                    type        = string
                                                    default     = ""
                                                 }
