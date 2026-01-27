# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

#######################################4#######################################8
#                                                                              #
#                           Environment definitions                            #
#                                                                              #
#######################################4#######################################8


variable "environment"                          {
                                                  description = "This is the environment name for the deployment"
                                                  type        = string
                                                  default     = ""
                                                  validation {
                                                     condition     = length(var.environment) <= 5 && length(var.environment) > 0
                                                     error_message = "The 'environment' variable must be specified and at most 5 characters long."
                                                   }
                                                }

variable "codename"                             {
                                                  description = "This is the code name name for the deployment"
                                                  type        = string
                                                  default     = ""
                                                }

variable "location"                             {
                                                 description = "The Azure region for the resources"
                                                 type        = string
                                                 default     = ""
                                                }

variable "name_override_file"                   {
                                                  description = "If provided, contains a json formatted file defining the name overrides"
                                                  default     = ""
                                                }

variable "place_delete_lock_on_resources"       {
                                                  description = "If defined, a delete lock will be placed on the key resources"
                                                  default     = false
                                                }

variable "prevent_deletion_if_contains_resources" {
                                                    description = "Controls if resource groups are deleted even if they contain resources"
                                                    type        = bool
                                                    default     = true
                                                  }

variable "encryption_at_host_enabled"             {
                                                    description = "Enables host encryption for sap landscape vms"
                                                    default     = false
                                                    type        = bool
                                                  }
variable "Description"                          {
                                                  description = "This is the description for the deployment"
                                                  type        = string
                                                  default     = ""
                                                }

variable "subscription_id"                      {
                                                  description = "This is the target subscription for the deployment"
                                                  type        = string
                                                   validation {
                                                     condition     = length(var.subscription_id) == 0 ? true : length(var.subscription_id) == 36
                                                     error_message = "If specified the 'subscription_id' variable must be a correct subscription ID."
                                                   }

                                                }
variable "management_subscription_id"           {
                                                  description = "This is the management subscription used by the deployment"
                                                  type        = string
                                                  default     = ""
                                                  validation {
                                                    condition     = length(var.management_subscription_id) == 0 ? true : length(var.management_subscription_id) == 36
                                                    error_message = "If specified the 'management_subscription_id' variable must be a correct subscription ID."
                                                  }
                                                }

variable "use_deployer"                          {
                                                   description = "Use deployer to deploy the resources"
                                                   default     = true
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


#######################################4#######################################8
#                                                                              #
#                     Virtual Network variables                                #
#                                                                              #
#######################################4#######################################8

variable "network_name"                         {
                                                  description = "If provided, the name of the Virtual network"
                                                  default     = ""
                                                }

variable "network_logical_name"                 {
                                                  description = "The logical name of the virtual network, used for resource naming"
                                                  default     = ""
                                                }

variable "network_address_space"                {
                                                  description = "The address space of the virtual network"
                                                  default     = [""]
                                                  type        = list(string)
                                                }

variable "network_arm_id"                       {
                                                  description = "If provided, the Azure resource id of the virtual network"
                                                  default     = ""
                                                  validation    {
                                                                  condition     = length(var.network_arm_id) == 0 ? true : can(provider::azurerm::parse_resource_id(var.network_arm_id))
                                                                  error_message = "If specified the 'network_arm_id' variable must be a correct Azure resource identifier."
                                                                }

                                                }

variable "network_flow_timeout_in_minutes"      {
                                                  description = "The flow timeout in minutes of the virtual network"
                                                  type = number
                                                  nullable = true
                                                  default = null
                                                  validation {
                                                    condition     = var.network_flow_timeout_in_minutes == null ? true : (var.network_flow_timeout_in_minutes >= 4 && var.network_flow_timeout_in_minutes <= 30)
                                                    error_message = "The flow timeout in minutes must be between 4 and 30 if set."
                                                  }
                                                }

variable "network_enable_route_propagation"     {
                                                  description = "Enable network route table propagation"
                                                  type = bool
                                                  nullable = false
                                                  default = true
                                                }

variable "use_private_endpoint"                 {
                                                  description = "Boolean value indicating if private endpoint should be used for the deployment"
                                                  default     = false
                                                  type        = bool
                                                }

variable "use_service_endpoint"                 {
                                                  description = "Boolean value indicating if service endpoints should be used for the deployment"
                                                  default     = false
                                                  type        = bool
                                                }

variable "enable_firewall_for_keyvaults_and_storage" {
                                                       description = "Boolean value indicating if firewall should be enabled for key vaults and storage"
                                                       default     = false
                                                       type        = bool
                                                     }

variable "public_network_access_enabled"        {
                                                  description = "Defines if the public access should be enabled for keyvaults and storage accounts"
                                                  default     = false
                                                  type        = bool
                                                }

variable "peer_with_control_plane_vnet"         {
                                                  description = "Defines in the SAP VNet will be peered with the controlplane VNet"
                                                  type        = bool
                                                  default     = true
                                                }


#######################################4#######################################8
#                                                                              #
#                        Admin Subnet variables                                #
#                                                                              #
#######################################4#######################################8

variable "admin_subnet_address_prefix"          {
                                                  description = "The address prefix for the admin subnet"
                                                  default     = ""
                                                }

variable "admin_subnet_name"                    {
                                                  description = "If provided, the name of the admin subnet"
                                                  default     = ""
                                                }

variable "admin_subnet_arm_id"                  {
                                                  description = "If provided, Azure resource id for the admin subnet"
                                                  default     = ""
                                                  validation    {
                                                                  condition     = length(var.admin_subnet_arm_id) == 0 ? true : can(provider::azurerm::parse_resource_id(var.admin_subnet_arm_id))
                                                                  error_message = "If specified the 'admin_subnet_arm_id' variable must be a correct Azure resource identifier."
                                                                }

                                                }

variable "admin_subnet_nsg_name"                {
                                                  description = "If provided, the name of the admin subnet NSG"
                                                  default     = ""
                                                }

variable "admin_subnet_nsg_arm_id"              {
                                                  description = "If provided, Azure resource id for the admin subnet NSG"
                                                  default     = ""
                                                  validation    {
                                                                  condition     = length(var.admin_subnet_nsg_arm_id) == 0 ? true : can(provider::azurerm::parse_resource_id(var.admin_subnet_nsg_arm_id))
                                                                  error_message = "If specified the 'admin_subnet_nsg_arm_id' variable must be a correct Azure resource identifier."
                                                                }
                                                }


#######################################4#######################################8
#                                                                              #
#                      Database Subnet variables                               #
#                                                                              #
#######################################4#######################################8

variable "db_subnet_name"                       {
                                                  description = "If provided, the name of the db subnet"
                                                  default     = ""
                                                }

variable "db_subnet_arm_id"                     {
                                                  description = "If provided, Azure resource id for the db subnet"
                                                  default     = ""
                                                  validation    {
                                                                  condition     = length(var.db_subnet_arm_id) == 0 ? true : can(provider::azurerm::parse_resource_id(var.db_subnet_arm_id))
                                                                  error_message = "If specified the 'db_subnet_arm_id' variable must be a correct Azure resource identifier."
                                                                }
                                                }

variable "db_subnet_address_prefix"             {
                                                  description = "The address prefix for the db subnet"
                                                  default     = ""
                                                }

variable "db_subnet_nsg_name"                   {
                                                  description = "If provided, the name of the db subnet NSG"
                                                  default     = ""
                                                }

variable "db_subnet_nsg_arm_id"                 {
                                                  description = "If provided, Azure resource id for the db subnet NSG"
                                                  default     = ""
                                                  validation    {
                                                                  condition     = length(var.db_subnet_nsg_arm_id) == 0 ? true : can(provider::azurerm::parse_resource_id(var.db_subnet_nsg_arm_id))
                                                                  error_message = "If specified the 'db_subnet_nsg_arm_id' variable must be a correct Azure resource identifier."
                                                                }
                                                }


#######################################4#######################################8
#                                                                              #
#               Application Subnet variables                                   #
#                                                                              #
#######################################4#######################################8

variable "app_subnet_name"                      {
                                                  description = "If provided, the name of the app subnet"
                                                  default     = ""
                                                }

variable "app_subnet_arm_id"                    {
                                                  description = "If provided, Azure resource id for the app subnet"
                                                  default     = ""
                                                  validation    {
                                                                  condition     = length(var.app_subnet_arm_id) == 0 ? true : can(provider::azurerm::parse_resource_id(var.app_subnet_arm_id))
                                                                  error_message = "If specified the 'app_subnet_arm_id' variable must be a correct Azure resource identifier."
                                                                }
                                                }

variable "app_subnet_address_prefix"            {
                                                  description = "The address prefix for the app subnet"
                                                  default     = ""
                                                }

variable "app_subnet_nsg_name"                  {
                                                  description = "If provided, the name of the app subnet NSG"
                                                  default     = ""
                                                }

variable "app_subnet_nsg_arm_id"                {
                                                  description = "If provided, Azure resource id for the app subnet NSG"
                                                  default     = ""
                                                  validation    {
                                                                  condition     = length(var.app_subnet_nsg_arm_id) == 0 ? true : can(provider::azurerm::parse_resource_id(var.app_subnet_nsg_arm_id))
                                                                  error_message = "If specified the 'app_subnet_nsg_arm_id' variable must be a correct Azure resource identifier."
                                                                }
                                                }


#########################################################################################
#                                                                                       #
#  Web Subnet variables                                                                 #
#                                                                                       #
#########################################################################################

variable "web_subnet_name"                      {
                                                  description = "If provided, the name of the web subnet"
                                                  default     = ""
                                                }

variable "web_subnet_arm_id"                    {
                                                  description = "If provided, Azure resource id for the web subnet"
                                                  default     = ""
                                                  validation    {
                                                                  condition     = length(var.web_subnet_arm_id) == 0 ? true : can(provider::azurerm::parse_resource_id(var.web_subnet_arm_id))
                                                                  error_message = "If specified the 'web_subnet_arm_id' variable must be a correct Azure resource identifier."
                                                                }
                                                }

variable "web_subnet_address_prefix"            {
                                                  description = "The address prefix for the web subnet"
                                                  default     = ""
                                                }

variable "web_subnet_nsg_name"                  {
                                                  description = "If provided, the name of the web subnet NSG"
                                                  default     = ""
                                                }

variable "web_subnet_nsg_arm_id"                {
                                                  description = "If provided, Azure resource id for the web subnet NSG"
                                                  default     = ""
                                                  validation    {
                                                                  condition     = length(var.web_subnet_nsg_arm_id) == 0 ? true : can(provider::azurerm::parse_resource_id(var.web_subnet_nsg_arm_id))
                                                                  error_message = "If specified the 'web_subnet_nsg_arm_id' variable must be a correct Azure resource identifier."
                                                                }
                                                }

#########################################################################################
#                                                                                       #
#  Storage Subnet variables - Needed only during HANA Scaleout deployments              #
#                                                                                       #
#########################################################################################

variable "use_separate_storage_subnet"          {
                                                  description = "Boolean to use a separate subnet"
                                                  default     = false
                                                }

variable "storage_subnet_name"                  {
                                                  description = "If provided, the name of the storage subnet"
                                                  default     = ""
                                                }

variable "storage_subnet_arm_id"                {
                                                  description = "If provided, Azure resource id for the storage subnet"
                                                  default     = ""
                                                  validation    {
                                                                  condition     = length(var.storage_subnet_arm_id) == 0 ? true : can(provider::azurerm::parse_resource_id(var.storage_subnet_arm_id))
                                                                  error_message = "If specified the 'storage_subnet_arm_id' variable must be a correct Azure resource identifier."
                                                                }
                                                }

variable "storage_subnet_address_prefix"        {
                                                  description = "The address prefix for the storage subnet"
                                                  default     = ""
                                                }

variable "storage_subnet_nsg_name"              {
                                                  description = "If provided, the name of the storage subnet NSG"
                                                  default     = ""
                                                }

variable "storage_subnet_nsg_arm_id"            {
                                                  description = "If provided, Azure resource id for the storage subnet NSG"
                                                  default     = ""
                                                  validation    {
                                                                  condition     = length(var.storage_subnet_nsg_arm_id) == 0 ? true : can(provider::azurerm::parse_resource_id(var.storage_subnet_nsg_arm_id))
                                                                  error_message = "If specified the 'storage_subnet_nsg_arm_id' variable must be a correct Azure resource identifier."
                                                                }
                                                }


#########################################################################################
#                                                                                       #
#  ANF Subnet variables                                                                 #
#                                                                                       #
#########################################################################################

variable "anf_subnet_name"                      {
                                                  description = "If provided, the name of the ANF subnet"
                                                  default     = ""
                                                }

variable "anf_subnet_arm_id"                    {
                                                  description = "If provided, Azure resource id for the ANF subnet"
                                                  default     = ""
                                                  validation    {
                                                                  condition     = length(var.anf_subnet_arm_id) == 0 ? true : can(provider::azurerm::parse_resource_id(var.anf_subnet_arm_id))
                                                                  error_message = "If specified the 'anf_subnet_arm_id' variable must be a correct Azure resource identifier."
                                                                }
                                                }

variable "anf_subnet_address_prefix"            {
                                                  description = "The address prefix for the ANF subnet"
                                                  default     = ""
                                                }

variable "anf_subnet_nsg_name"                  {
                                                  description = "If provided, the name of the ANF subnet NSG"
                                                  default     = ""
                                                }

variable "anf_subnet_nsg_arm_id"                {
                                                  description = "If provided, Azure resource id for the ANF subnet NSG"
                                                  default     = ""
                                                  validation    {
                                                                  condition     = length(var.anf_subnet_nsg_arm_id) == 0 ? true : can(provider::azurerm::parse_resource_id(var.anf_subnet_nsg_arm_id))
                                                                  error_message = "If specified the 'anf_subnet_nsg_arm_id' variable must be a correct Azure resource identifier."
                                                                }
                                                }


#######################################4#######################################8
#                                                                              #
#                      AMS Subnet variables                                    #
#                                                                              #
#######################################4#######################################8

variable "ams_subnet_name"                       {
                                                  description = "If provided, the name of the ams subnet"
                                                  default     = ""
                                                }

variable "ams_subnet_arm_id"                     {
                                                  description = "If provided, Azure resource id for the ams subnet"
                                                  default     = ""
                                                  validation    {
                                                                  condition     = length(var.ams_subnet_arm_id) == 0 ? true : can(provider::azurerm::parse_resource_id(var.ams_subnet_arm_id))
                                                                  error_message = "If specified the 'ams_subnet_arm_id' variable must be a correct Azure resource identifier."
                                                                }
                                                }

variable "ams_subnet_address_prefix"             {
                                                  description = "The address prefix for the ams subnet"
                                                  default     = ""
                                                }

variable "ams_subnet_nsg_name"                  {
                                                  description = "If provided, the name of the AMS subnet NSG"
                                                  default     = ""
                                                }

variable "ams_subnet_nsg_arm_id"                {
                                                  description = "If provided, Azure resource id for the AMS subnet NSG"
                                                  default     = ""
                                                  validation    {
                                                                  condition     = length(var.ams_subnet_nsg_arm_id) == 0 ? true : can(provider::azurerm::parse_resource_id(var.ams_subnet_nsg_arm_id))
                                                                  error_message = "If specified the 'ams_subnet_nsg_arm_id' variable must be a correct Azure resource identifier."
                                                                }
                                                }

#########################################################################################
#                                                                                       #
#  Key Vault variables                                                                  #
#                                                                                       #
#########################################################################################

variable "user_keyvault_id"                     {
                                                  description = "If provided, the Azure resource identifier of the credentials keyvault"
                                                  default     = ""
                                                  validation    {
                                                                  condition     = length(var.user_keyvault_id) == 0 ? true : can(provider::azurerm::parse_resource_id(var.user_keyvault_id))
                                                                  error_message = "If specified the 'user_keyvault_id' variable must be a correct Azure resource identifier."
                                                                }
                                                }

variable "spn_keyvault_id"                      {
                                                  description = "If provided, the Azure resource identifier of the deployment credential keyvault"
                                                  default     = ""
                                                  validation    {
                                                                  condition     = length(var.spn_keyvault_id) == 0 ? true : can(provider::azurerm::parse_resource_id(var.spn_keyvault_id))
                                                                  error_message = "If specified the 'spn_keyvault_id' variable must be a correct Azure resource identifier."
                                                                }
                                                }

variable "enable_purge_control_for_keyvaults"   {
                                                  description = "Disables the purge protection for Azure keyvaults."
                                                  default     = false
                                                  type        = bool
                                                }

variable "enable_rbac_authorization_for_keyvault" {
                                                    description = "Enables RBAC authorization for Azure keyvault"
                                                    default     = true
                                                  }

variable "additional_users_to_add_to_keyvault_policies" {
                                                          description = "List of object IDs to add to key vault policies"
                                                          default     = [""]
                                                        }

variable "keyvault_private_endpoint_id"         {
                                                  description = "Existing private endpoint for key vault"
                                                  default     = ""
                                                  validation    {
                                                                  condition     = length(var.keyvault_private_endpoint_id) == 0 ? true : can(provider::azurerm::parse_resource_id(var.keyvault_private_endpoint_id))
                                                                  error_message = "If specified the 'keyvault_private_endpoint_id' variable must be a correct Azure resource identifier."
                                                                }
                                                }

variable "soft_delete_retention_days"           {
                                                  description = "The number of days that items should be retained in the soft delete period"
                                                  default     = 7
                                                }

variable "set_secret_expiry"                    {
                                                  description = "Set expiry date for secrets"
                                                  default     = false
                                                  type        = bool
                                                }

variable "workload_zone_private_key_secret_name"     {
                                                        description = "Defines the name of the secret in the Azure Key Vault that contains the private key"
                                                        default     = ""
                                                      }
variable "workload_zone_public_key_secret_name"       {
                                                        description = "Defines the name of the secret in the Azure Key Vault that contains the public key"
                                                        default     = ""
                                                      }

variable "workload_zone_username_secret_name"         {
                                                        description = "Defines the name of the secret in the Azure Key Vault that contains the user name"
                                                        default     = ""
                                                      }

variable "workload_zone_password_secret_name"        {
                                                        description = "Defines the name of the secret in the Azure Key Vault that contains the password"
                                                        default     = ""
                                                      }


#########################################################################################
#                                                                                       #
#  Authentication variables                                                             #
#                                                                                       #
#########################################################################################

variable "automation_username"                 {
                                                  description = "The username for the automation account"
                                                  default     = "azureadm"
                                                }

variable "automation_password"                  {
                                                  description = "If provided, the password for the automation account"
                                                  default     = ""
                                                }

variable "automation_path_to_public_key"        {
                                                  description = "If provided, the path to the existing public key for the automation account"
                                                  default     = ""
                                                }

variable "automation_path_to_private_key"       {
                                                  description = "If provided, the path to the existing private key for the automation account"
                                                  default     = ""
                                                }

variable "use_spn"                              {
                                                  description = "Log in using a service principal when performing the deployment"
                                                  default     = false
                                                }

variable "user_assigned_identity_id"            {
                                                  description = "If provided defines the user assigned identity to assign to the virtual machines"
                                                  default     = ""
                                                  validation    {
                                                                  condition     = length(var.user_assigned_identity_id) == 0 ? true : can(provider::azurerm::parse_resource_id(var.user_assigned_identity_id))
                                                                  error_message = "If specified the 'user_assigned_identity_id' variable must be a correct Azure resource identifier."
                                                                }
                                                }

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
#  Storage Account variables                                                            #
#                                                                                       #
#########################################################################################

variable "diagnostics_storage_account_arm_id"   {
                                                  description = "If provided, Azure resource id for the diagnostics storage account"
                                                  default     = ""
                                                  validation    {
                                                                  condition     = length(var.diagnostics_storage_account_arm_id) == 0 ? true : can(provider::azurerm::parse_resource_id(var.diagnostics_storage_account_arm_id))
                                                                  error_message = "If specified the 'diagnostics_storage_account_arm_id' variable must be a correct Azure resource identifier."
                                                                }

                                                }

variable "witness_storage_account_arm_id"       {
                                                  description = "If provided, Azure resource id for the witness storage account"
                                                  default     = ""
                                                  validation    {
                                                                  condition     = length(var.witness_storage_account_arm_id) == 0 ? true : can(provider::azurerm::parse_resource_id(var.witness_storage_account_arm_id))
                                                                  error_message = "If specified the 'witness_storage_account_arm_id' variable must be a correct Azure resource identifier."
                                                                }
                                                }

variable "create_transport_storage"             {
                                                  description = "Boolean file indicating if storage should be created for SAP transport"
                                                  type        = bool
                                                  default     = true
                                                }

variable "transport_storage_account_id"         {
                                                  description = "Azure Resource Identifier for the Transport media storage account"
                                                  type        = string
                                                  default     = ""
                                                  validation    {
                                                                  condition     = length(var.transport_storage_account_id) == 0 ? true : can(provider::azurerm::parse_resource_id(var.transport_storage_account_id))
                                                                  error_message = "If specified the 'transport_storage_account_id' variable must be a correct Azure resource identifier."
                                                                }

                                                }

variable "transport_private_endpoint_id"        {
                                                  description = "Azure Resource Identifier for an private endpoint connection"
                                                  type        = string
                                                  default     = ""
                                                  validation    {
                                                                  condition     = length(var.transport_private_endpoint_id) == 0 ? true : can(provider::azurerm::parse_resource_id(var.transport_private_endpoint_id))
                                                                  error_message = "If specified the 'transport_private_endpoint_id' variable must be a correct Azure resource identifier."
                                                                }
                                                }

variable "transport_volume_size"                {
                                                  description = "The volume size in GB for the transport share"
                                                  default     = 128
                                                }

variable "install_storage_account_id"           {
                                                  description = "Azure Resource Identifier for the Installation media storage account"
                                                  type        = string
                                                  default     = ""
                                                  validation    {
                                                                  condition     = length(var.install_storage_account_id) == 0 ? true : can(provider::azurerm::parse_resource_id(var.install_storage_account_id))
                                                                  error_message = "If specified the 'install_storage_account_id' variable must be a correct Azure resource identifier."
                                                                }
                                                }

variable "install_volume_size"                  {
                                                  description = "The volume size in GB for the transport share"
                                                  default     = 1024
                                                }

variable "install_private_endpoint_id"          {
                                                  description = "Azure Resource Identifier for an private endpoint connection"
                                                  type        = string
                                                  default     = ""
                                                  validation    {
                                                                  condition     = length(var.install_private_endpoint_id) == 0 ? true : can(provider::azurerm::parse_resource_id(var.install_private_endpoint_id))
                                                                  error_message = "If specified the 'install_private_endpoint_id' variable must be a correct Azure resource identifier."
                                                                }
                                                }

variable "install_always_create_fileshares"     {
                                                  description = "Value indicating if file shares are created when using existing storage accounts"
                                                  default     = false
                                                }

variable "install_create_smb_shares"            {
                                                  description = "Value indicating if SMB shares should be created"
                                                  default     = true
                                                }

variable "Agent_IP"                             {
                                                  description = "If provided, contains the IP address of the agent"
                                                  type        = string
                                                  default     = ""
                                                }
variable "add_Agent_IP"                         {
                                                  description = "Boolean value indicating if the Agent IP should be added to the storage and key vault firewalls"
                                                  default     = true
                                                  type        = bool
                                                }

variable "storage_account_replication_type"     {
                                                  description = "Storage account replication type"
                                                  default     = "ZRS"
                                                }

#########################################################################################
#                                                                                       #
#  DNS settings                                                                         #
#                                                                                       #
#########################################################################################


variable "use_custom_dns_a_registration"           {
                                                     description = "Boolean value indicating if a custom dns a record should be created when using private endpoints"
                                                     default     = false
                                                     type        = bool
                                                   }

variable "management_dns_subscription_id"          {
                                                     description = "String value giving the possibility to register custom dns a records in a separate subscription"
                                                     default     = ""
                                                     type        = string

                                                      validation {
                                                        condition     = length(var.management_dns_subscription_id) == 0 ? true : length(var.management_dns_subscription_id) == 36
                                                        error_message = "If specified the 'management_dns_subscription_id' variable must be a correct subscription ID."
                                                      }
                                                   }

variable "management_dns_resourcegroup_name"       {
                                                     description = "String value giving the possibility to register custom dns a records in a separate resourcegroup"
                                                     default     = ""
                                                     type        = string
                                                   }

variable "privatelink_dns_subscription_id"         {
                                                     description = "String value giving the possibility to register custom PrivateLink DNS A records in a separate subscription"
                                                     default     = ""
                                                     type        = string

                                                     validation {
                                                       condition     = length(var.privatelink_dns_subscription_id) == 0 ? true : length(var.privatelink_dns_subscription_id) == 36
                                                       error_message = "If specified the 'privatelink_dns_subscription_id' variable must be a correct subscription ID."
                                                     }
                                                   }

variable "privatelink_dns_resourcegroup_name"      {
                                                     description = "String value giving the possibility to register custom PrivateLink DNS A records in a separate resourcegroup"
                                                     default     = ""
                                                     type        = string
                                                   }

variable "privatelink_file_id"                     {
                                                     description = "ID of the private link file resource"
                                                     default = ""
                                                     type = string
                                                    validation    {
                                                                  condition     = length(var.privatelink_file_id) == 0 ? true : can(provider::azurerm::parse_resource_id(var.privatelink_file_id))
                                                                  error_message = "If specified the 'privatelink_file_id' variable must be a correct Azure resource identifier."
                                                                }
                                                   }
variable "privatelink_storage_id"                  {
                                                     description = "ID of the private link storage resource"
                                                     default = ""
                                                     type = string
                                                    validation    {
                                                                  condition     = length(var.privatelink_storage_id) == 0 ? true : can(provider::azurerm::parse_resource_id(var.privatelink_storage_id))
                                                                  error_message = "If specified the 'privatelink_storage_id' variable must be a correct Azure resource identifier."
                                                                }
                                                   }
variable "privatelink_keyvault_id"                 {
                                                     description = "ID of the private link keyvault resource"
                                                     default = ""
                                                     type = string
                                                     validation    {
                                                                  condition     = length(var.privatelink_keyvault_id) == 0 ? true : can(provider::azurerm::parse_resource_id(var.privatelink_keyvault_id))
                                                                  error_message = "If specified the 'privatelink_keyvault_id' variable must be a correct Azure resource identifier."
                                                                }
                                                   }

variable "dns_server_list"                         {
                                                     description = "DNS server list"
                                                     default     = []
                                                   }


variable "register_virtual_network_to_dns"         {
                                                     description = "Boolean value indicating if the vnet should be registered to the dns zone"
                                                     default     = true
                                                     type        = bool
                                                   }

variable "dns_zone_names"                          {
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

variable "shared_access_key_enabled"            {
                                                  description = "Indicates whether the storage account permits requests to be authorized with the account access key via Shared Key."
                                                  default     = false
                                                  type        = bool
                                                }

variable "shared_access_key_enabled_nfs"        {
                                                  description = "Indicates whether the storage account permits requests to be authorized with the account access key via Shared Key."
                                                  default     = false
                                                  type        = bool
                                                }

variable "data_plane_available"                 {
                                                  description = "Boolean value indicating if storage account access is via data plane"
                                                  default     = true
                                                  type        = bool
                                                }


#########################################################################################
#                                                                                       #
#  ANF variables                                                                        #
#                                                                                       #
#########################################################################################

variable "ANF_account_arm_id"                      {
                                                     description = "If provided, The resource identifier for the NetApp account"
                                                     default     = ""
                                                      validation    {
                                                                      condition     = length(var.ANF_account_arm_id) == 0 ? true : can(provider::azurerm::parse_resource_id(var.ANF_account_arm_id))
                                                                      error_message = "If specified the 'ANF_account_arm_id' variable must be a correct Azure resource identifier."
                                                                    }
                                                   }

variable "ANF_account_name"                        {
                                                     description = "If provided, the NetApp account name"
                                                     default     = ""
                                                   }

variable "ANF_use_existing_pool"                   {
                                                     description = "Use existing storage pool"
                                                     default     = false
                                                   }

variable "ANF_pool_name"                           {
                                                     description = "If provided, the NetApp capacity pool name (if any)"
                                                     default     = ""
                                                   }

variable "ANF_service_level"                       {
                                                     description = "The NetApp Service Level"
                                                     default     = "Premium"
                                                   }

variable "ANF_pool_size"                           {
                                                     description = "The NetApp Pool size in TB"
                                                     default     = 4
                                                   }

variable "ANF_qos_type"                            {
                                                     description = "The Quality of Service type of the pool (Auto or Manual)"
                                                     default     = "Manual"
                                                   }

variable "ANF_transport_volume_use_existing"       {
                                                     description = "Use existing transport volume"
                                                     default     = false
                                                   }

variable "ANF_transport_volume_name"               {
                                                     description = "If defined provides the Transport volume name"
                                                     default     = false
                                                   }

variable "ANF_transport_volume_throughput"         {
                                                     description = "If defined provides the throughput of the transport volume"
                                                     default     = 128
                                                   }

variable "ANF_transport_volume_size"               {
                                                     description = "If defined provides the size of the transport volume"
                                                     default     = 128
                                                   }

variable "ANF_transport_volume_zone"               {
                                                     description = "Transport volume availability zone"
                                                     default     = [""]
                                                   }

variable "ANF_install_volume_use_existing"         {
                                                     description = "Use existing install volume"
                                                     default     = false
                                                   }

variable "ANF_install_volume_name"                 {
                                                     description = "Install volume name"
                                                     default     = ""
                                                   }

variable "ANF_install_volume_throughput"           {
                                                     description = "If defined provides the throughput of the install volume"
                                                     default     = 128
                                                   }

variable "ANF_install_volume_size"                 {
                                                     description = "If defined provides the size of the install volume"
                                                     default     = 1024
                                                   }


variable "ANF_install_volume_zone"                 {
                                                     description = "Install volume availability zone"
                                                     default     = [""]
                                                   }

variable "use_AFS_for_shared_storage"              {
                                                     description = "If true, will use AFS for all shared storage."
                                                     type        = bool
                                                     default     = false
                                                   }

variable AFS_enable_encryption_in_transit          {
                                                     description = "Enable encryption in transit for Azure Files"
                                                     type        = bool
                                                     default     = false
                                                   }

#########################################################################################
#                                                                                       #
#  iSCSI definitions                                                                    #
#                                                                                       #
#########################################################################################

variable "iscsi_subnet_name"                       {
                                                     description = "If provided, the name of the iSCSI subnet"
                                                     default     = ""
                                                   }

variable "iscsi_subnet_arm_id"                     {
                                                     description = "If provided, Azure resource id for the iSCSI subnet"
                                                     default     = ""
                                                     validation    {
                                                                     condition     = length(var.iscsi_subnet_arm_id) == 0 ? true : can(provider::azurerm::parse_resource_id(var.iscsi_subnet_arm_id))
                                                                     error_message = "If specified the 'iscsi_subnet_arm_id' variable must be a correct Azure resource identifier."
                                                                   }

                                                   }

variable "iscsi_subnet_address_prefix"             {
                                                     description = "The address prefix for the iSCSI subnet"
                                                     default     = ""
                                                   }

variable "iscsi_subnet_nsg_name"                   {
                                                     description = "If provided, the name of the iSCSI subnet NSG"
                                                     default     = ""
                                                   }

variable "iscsi_subnet_nsg_arm_id"                 {
                                                     description = "If provided, Azure resource id for the iSCSI subnet NSG"
                                                     default     = ""
                                                      validation    {
                                                                      condition     = length(var.iscsi_subnet_nsg_arm_id) == 0 ? true : can(provider::azurerm::parse_resource_id(var.iscsi_subnet_nsg_arm_id))
                                                                      error_message = "If specified the 'iscsi_subnet_nsg_arm_id' variable must be a correct Azure resource identifier."
                                                                    }
                                                   }

variable "iscsi_count"                             {
                                                     description = "The number of iSCSI Virtual Machines to create"
                                                     default     = 0
                                                   }

variable "iscsi_size"                              {
                                                     description = "The size of the iSCSI Virtual Machine"
                                                     default     = ""
                                                   }

variable "iscsi_useDHCP"                           {
                                                     description = "value indicating if iSCSI Virtual Machine should use DHCP"
                                                     default     = false
                                                   }

variable "iscsi_image"                             {
                                                     description = "The virtual machine image for the iSCSI Virtual Machine"
                                                     default     = {
                                                                     "source_image_id" = ""
                                                                     "publisher"       = "SUSE"
                                                                     "offer"           = "sles-sap-15-sp5"
                                                                     "sku"             = "gen1"
                                                                     "version"         = "latest"
                                                                   }
                                                   }
variable "iscsi_authentication_type"               {
                                                     description = "SCSI Virtual Machine authentication type"
                                                     default     = "key"
                                                   }

variable "iscsi_authentication_username"           {
                                                     description = "User name for iSCSI Virtual Machine"
                                                     default     = "azureadm"
                                                   }


variable "iscsi_nic_ips"                           {
                                                     description = "P addresses for the iSCSI Virtual Machine NICs"
                                                     default     = []
                                                   }

variable "iscsi_vm_zones"                          {
                                                     description = "If provided, the iSCSI will be deployed in the specified zones"
                                                     default     = []
                                                   }


#######################################4#######################################8
#                                                                              #
#                     Workload VM definitions                                  #
#                                                                              #
#######################################4#######################################8


variable "utility_vm_count"                        {
                                                     description = "The number of utility_vmes to create"
                                                     default     = 0
                                                   }

variable "utility_vm_size"                         {
                                                     description = "The size of the utility_vm Virtual Machine"
                                                     default     = "Standard_D4ds_v4"
                                                   }
variable "utility_vm_os_disk_size"                 {
                                                     description = "The size of the OS disk for the Virtual Machine"
                                                     default     = "128"
                                                   }

variable "utility_vm_os_disk_type"                 {
                                                     description = "The type of the OS disk for the Virtual Machine"
                                                     default     = "Premium_LRS"
                                                   }


variable "utility_vm_useDHCP"                      {
                                                     description = "value indicating if utility_vm should use DHCP"
                                                     default     = true
                                                   }

variable "utility_vm_image"                        {
                                                     description = "The virtual machine image for the utility_vm Virtual Machine"
                                                     default     = {
                                                                     "os_type"         = "WINDOWS"
                                                                     "source_image_id" = ""
                                                                     "publisher"       = "MicrosoftWindowsServer"
                                                                     "offer"           = "WindowsServer"
                                                                     "sku"             = "2022-Datacenter"
                                                                     "version"         = "latest"
                                                                   }
                                                   }

variable "utility_vm_nic_ips"                      {
                                                     description = "IP addresses for the utility_vm Virtual Machine NICs"
                                                     default     = []
                                                   }

variable "patch_mode"                           {
                                                  description = "If defined, define the patch mode for the virtual machines"
                                                  default     = "ImageDefault"
                                                }

variable "patch_assessment_mode"                {
                                                  description = "If defined, define the patch mode for the virtual machines"
                                                  default     = "ImageDefault"
                                                }



#########################################################################################
#                                                                                       #
#  Tags                                                                                 #
#                                                                                       #
#########################################################################################

variable "tags"                                    {
                                                      description = "If provided, tags for all resources"
                                                      default     = {}
                                                   }


#########################################################################################
#                                                                                       #
#  Export Share Control                                                                 #
#                                                                                       #
#########################################################################################

variable "export_install_path"                     {
                                                      description = "If provided, export mount path for the installation media"
                                                      default     = true
                                                   }

variable "export_transport_path"                   {
                                                      description = "If provided, export mount path for the transport media"
                                                      default     = true
                                                   }

#######################################4#######################################8
#                                                                              #
#                      AMS Instance variables                                  #
#                                                                              #
#######################################4#######################################8

variable "create_ams_instance"                    {
                                                    description = "If true, an AMS instance will be created"
                                                    default     = false
                                                  }

variable "ams_instance_name"                      {
                                                    description = "If provided, the name of the AMS instance"
                                                    default     = ""
                                                  }
variable "ams_laws_arm_id"                        {
                                                    description = "If provided, Azure resource id for the Log analytics workspace in AMS"
                                                    default     = ""
                                                    validation    {
                                                                    condition     = length(var.ams_laws_arm_id) == 0 ? true : can(provider::azurerm::parse_resource_id(var.ams_laws_arm_id))
                                                                    error_message = "If specified the 'ams_laws_arm_id' variable must be a correct Azure resource identifier."
                                                                  }

                                                  }

#######################################4#######################################8
#                                                                              #
#                             NAT Gateway variables                            #
#                                                                              #
#######################################4#######################################8

variable "deploy_nat_gateway"                     {
                                                    description = "If true, a NAT Gateway will be deployed"
                                                    type        = bool
                                                    default     = false
                                                  }

variable "nat_gateway_name"                       {
                                                    description = "If provided, the name of the NAT Gateway"
                                                    type        = string
                                                    default     = ""
                                                  }

variable "nat_gateway_arm_id"                     {
                                                    description = "If provided, Azure resource id for the NAT Gateway"
                                                    type        = string
                                                    default     = ""
                                                    validation    {
                                                                    condition     = length(var.nat_gateway_arm_id) == 0 ? true : can(provider::azurerm::parse_resource_id(var.nat_gateway_arm_id))
                                                                    error_message = "If specified the 'nat_gateway_arm_id' variable must be a correct Azure resource identifier."
                                                                  }
                                                  }

variable "nat_gateway_public_ip_zones"            {
                                                    description = "If provided, the zones for the NAT Gateway public IP"
                                                    type        = list(string)
                                                    default     = []
                                                  }

variable "nat_gateway_public_ip_arm_id"           {
                                                    description = "If provided, Azure resource id for the NAT Gateway public IP"
                                                    type        = string
                                                    default     = ""
                                                    validation    {
                                                                    condition     = length(var.nat_gateway_public_ip_arm_id) == 0 ? true : can(provider::azurerm::parse_resource_id(var.nat_gateway_public_ip_arm_id))
                                                                    error_message = "If specified the 'nat_gateway_public_ip_arm_id' variable must be a correct Azure resource identifier."
                                                                  }
                                                  }

variable "nat_gateway_idle_timeout_in_minutes"    {
                                                    description = "The idle timeout in minutes for the NAT Gateway"
                                                    type        = number
                                                    default     = 4
                                                  }

variable "nat_gateway_public_ip_tags"             {
                                                    description = "Tags for the public_ip resource"
                                                    type        = map(string)
                                                    default     = null
                                                  }

#######################################4#######################################8
#                                                                              #
#                             Terraform variables                              #
#                                                                              #
#######################################4#######################################8

variable "tfstate_resource_id"                   {
                                                    description = "Resource id of tfstate storage account"
                                                    validation {
                                                                condition = can(provider::azurerm::parse_resource_id(var.tfstate_resource_id)
                                                                )
                                                                error_message = "The Azure Resource ID for the storage account containing the Terraform state files must be provided and be in correct format."
                                                              }
                                                  }

variable "deployer_tfstate_key"                   {
                                                    description = "The name of deployer's remote tfstate file"
                                                    type    = string
                                                    default = ""
                                                  }

variable "custom_random_id"                     {
                                                  description = "If provided, the value of the custom random id"
                                                  default     = ""
                                                }

variable "additional_network_id"                {
                                                   description = "Agent Network resource ID"
                                                   default     = ""
                                                   validation    {
                                                                 condition     = length(var.additional_network_id) == 0 ? true : can(provider::azurerm::parse_resource_id(var.additional_network_id))
                                                                 error_message = "If specified the 'additional_network_id' variable must be a correct Azure resource identifier."
                                                               }

                                                 }

variable "additional_subnet_id"                {
                                                   description = "Agent subnet resource ID"
                                                   default     = ""
                                                   validation    {
                                                                 condition     = length(var.additional_subnet_id) == 0 ? true : can(provider::azurerm::parse_resource_id(var.additional_subnet_id))
                                                                 error_message = "If specified the 'additional_subnet_id' variable must be a correct Azure resource identifier."
                                                               }

                                                 }


#######################################4#######################################8
#                                                                              #
#  Miscellaneous settings                                                      #
#                                                                              #
#######################################4#######################################8

variable "assign_permissions"                         {
                                                        description = "Boolean flag indicating if permissions should be assigned"
                                                        default     = true
                                                        type        = bool
                                                      }

variable "spn_id"                                     {
                                                        description = "Service Principal Id to be used for the deployment"
                                                        default     = ""
                                                        validation {
                                                          condition     = length(var.spn_id) == 0 ? true : length(var.spn_id) == 36
                                                          error_message = "If specified the 'spn_id' variable must be a correct service principal ID."
                                                        }
                                                      }
variable "platform_updates"                           {
                                                        description = "Specifies whether VMAgent Platform Updates is enabled"
                                                        default     = "true"
                                                      }

###############################################################################
#                                                                             #
#                            Application  configuration                       #
#                                                                             #
###############################################################################

variable "application_configuration_id"         {
                                                    description = "Defines the Azure application configuration Resource id"
                                                    type        = string
                                                    default     = ""
                                                    validation    {
                                                                  condition     = length(var.application_configuration_id) == 0 ? true : can(provider::azurerm::parse_resource_id(var.application_configuration_id))
                                                                  error_message = "If specified the 'application_configuration_id' variable must be a correct Azure resource identifier."
                                                                }

                                                 }

variable "control_plane_name"                   {
                                                  description = "The name of the control plane"
                                                  default     = ""
                                                }


