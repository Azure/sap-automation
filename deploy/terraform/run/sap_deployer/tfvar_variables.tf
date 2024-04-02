#######################################4#######################################8
#                                                                              #
#                           Environment definitioms                            #
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

#######################################4#######################################8
#                                                                              #
#                          Resource group definitioms                          #
#                                                                              #
#######################################4#######################################8

variable "resourcegroup_name"                   {
                                                  description = "If provided, the name of the resource group to be created"
                                                  default     = ""
                                                }

variable "resourcegroup_arm_id"                 {
                                                  description = "If provid, the Azure resource group id"
                                                  default     = ""
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
                                                }

variable "management_network_address_space"     {
                                                  description = "The address space of the VNet into which the deployer will be deployed"
                                                  default     = ""
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

#######################################4#######################################8
#                                                                              #
#                             Bastion Subnet variables                         #
#                                                                              #
#######################################4#######################################8

variable "management_bastion_subnet_arm_id"     {
                                                  description = "Azure resource identifier Azure Bastion subnet"
                                                  default     = ""
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

#######################################4#######################################8
#                                                                              #
#                           App Service Subnet variables                       #
#                                                                              #
#######################################4#######################################8


variable "webapp_subnet_arm_id"                 {
                                                  description = "Azure resource identifier Web App subnet"
                                                  default     = ""
                                                }

variable "webapp_subnet_address_prefix"        {
                                                  description = "Subnet adress range for the Web App subnet"
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

variable "plan"                                 {
                                                  description = "The plan for the marketplace item"
                                                  default = {
                                                              use         = false
                                                              "name"      = ""
                                                              "publisher" = ""
                                                              "product"   = ""
                                                            }
                                                }

variable "deployer_private_ip_address"          {
                                                  description = "If provides, the value of the deployer Virtual machine IPs"
                                                  default = [""]
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
                                                      }


variable "deployer_kv_user_arm_id"                    {
                                                        description = "Azure resource identifier for the deployer user Azure Key Vault"
                                                        default     = ""
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

variable "additional_users_to_add_to_keyvault_policies" {
                                                          description = "List of object IDs to add to key vault policies"
                                                          default     = [""]
                                                        }

variable "set_secret_expiry"                          {
                                                        description = "Set expiry date for secrets"
                                                        default     = false
                                                        type        = bool
                                                      }

variable "soft_delete_retention_days"                 {
                                                        description = "The number of days that items should be retained in the soft delete period"
                                                        default     = 7
                                                      }

#######################################4#######################################8
#                                                                              #
#  Miscallaneous settings                                                      #
#                                                                              #
#######################################4#######################################8

variable "deployer_assign_subscription_permissions"   {
                                                        description = "Boolean flag indicating if the subscription permissions should be assigned"
                                                        default     = false
                                                        type        = bool
                                                      }

variable "use_private_endpoint"                       {
                                                        description = "Boolean value indicating if private endpoint should be used for the deployment"
                                                        default     = false
                                                        type        = bool
                                                      }

variable "use_service_endpoint"                       {
                                                        description = "Boolean value indicating if service endpoints should be used for the deployment"
                                                        default     = false
                                                        type        = bool
                                                      }


variable "deployer_diagnostics_account_arm_id"        {
                                                        description = "Azure resource identifier for an existing storage accout that will be used for diagnostic logs"
                                                        default     = ""
                                                      }


variable "tf_version"                                 {
                                                        description = "Terraform version to install on deployer"
                                                        default     = "1.7.0"
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
                                                        default     = ""
                                                      }

variable "public_network_access_enabled"              {
                                                        description = "Boolean value indicating if public access should be enabled for key vaults and storage"
                                                        default     = true
                                                        type        = bool
                                                      }


variable "subnets_to_add_to_firewall_for_keyvaults_and_storage" {
                                                                  description = "List of subnets to add to storage account and keyvaults firewall"
                                                                  default     = []
                                                                }

variable "shared_access_key_enabled"            {
                                                  description = "Indicates whether the storage account permits requests to be authorized with the account access key via Shared Key."
                                                  default     = true
                                                  type        = bool
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
                                                        default     = null
                                                        type        = string
                                                      }

variable "management_dns_resourcegroup_name"          {
                                                        description = "String value giving the possibility to register custom dns a records in a separate resourcegroup"
                                                        default     = null
                                                        type        = string
                                                      }
variable "dns_zone_names"                             {
                                                        description = "Private DNS zone names"
                                                        type        = map(string)

                                                        default = {
                                                          "file_dns_zone_name"   = "privatelink.file.core.windows.net"
                                                          "blob_dns_zone_name"   = "privatelink.blob.core.windows.net"
                                                          "table_dns_zone_name"  = "privatelink.table.core.windows.net"
                                                          "vault_dns_zone_name"  = "privatelink.vaultcore.azure.net"
                                                        }
                                                      }

#########################################################################################
#                                                                                       #
#  ADO definitioms                                                                      #
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

variable "ansible_core_version"                       {
                                                        description = "If provided, the version of ansible core to be installed"
                                                        default     = "2.15"
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

variable "app_registration_app_id"                    {
                                                        description = "The app registration id to be used for the webapp"
                                                        default     = ""
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

variable "tfstate_resource_id"                       {
                                                       description = "Resource id of tfstate storage account"
                                                       validation {
                                                                    condition = (
                                                                      length(split("/", var.tfstate_resource_id)) == 9
                                                                    )
                                                                    error_message = "The Azure Resource ID for the storage account containing the Terraform state files must be provided and be in correct format."
                                                                  }

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

variable "add_system_assigned_identity"         {
                                                  description = "Boolean flag indicating if a system assigned identity should be added to the deployer"
                                                  default     = false
                                                  type        = bool
                                                }

variable "use_spn"                              {
                                                  description = "Log in using a service principal when performing the deployment"
                                                  default     = true
                                                }

