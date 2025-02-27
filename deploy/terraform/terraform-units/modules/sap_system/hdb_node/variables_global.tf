# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

variable "admin_subnet"                                 { description = "Information about SAP admin subnet" }
variable "anchor_vm"                                    {
                                                          description = "Deployed anchor VM"
                                                          default     = null
                                                        }
variable "cloudinit_growpart_config"                    { description = "A cloud-init config that configures automatic growpart expansion of root partition" }
variable "custom_disk_sizes_filename"                   {
                                                          description = "Disk size json file"
                                                          default     = ""
                                                          type        = string
                                                        }
variable "database"                                     {}

variable "database_dual_nics"                           {
                                                          description = "Defines if the HANA DB uses dual network interfaces"
                                                          default     = true
                                                        }
variable "enable_storage_nic"                           {
                                                          description = "Boolean to determine if a storage nic should be used when scale out is enabled"
                                                          default     = true
                                                        }
variable "database_server_count"                        {
                                                          description = "The number of database servers"
                                                          default     = 1
                                                        }
variable "database_use_premium_v2_storage"              {
                                                          description = "If true, the database tier will use premium storage"
                                                          type        = bool
                                                        }
variable "database_active_active"                       {
                                                          description = "If true, database will deployed with Active/Active (read enabled) configuration"
                                                          type        = bool
                                                        }
variable "database_vm_admin_nic_ips"                    { description = "If provided, the database tier will be configured with the specified IPs (admin subnet)" }
variable "database_vm_db_nic_ips"                       { description = "If provided, the database tier will be configured with the specified IPs" }
variable "database_vm_db_nic_secondary_ips"             { description = "If provided, the database tier will be configured with the specified IPs as secondary IPs" }
variable "database_vm_storage_nic_ips"                  { description = "If provided, the database tier will be configured with the specified IPs (srorage subnet)" }
variable "db_asg_id"                                    { description = "Database Application Security Group" }
variable "db_subnet"                                    { description = "Information about SAP db subnet" }
variable "deploy_application_security_groups"           { description = "Defines if application security groups should be deployed" }
variable "deployment"                                   { description = "The type of deployment" }
variable "fencing_role_name"                            { description = "If specified the role name to use for the fencing" }
variable "infrastructure"                               { description = "Dictionary with infrastructure settings" }
variable "landscape_tfstate"                            { description = "Landscape remote tfstate file" }
variable "license_type"                                 {
                                                          description = "Specifies the license type for the OS"
                                                          default     = ""
                                                        }
variable "naming"                                       { description = "Defines the names for the resources" }
variable "NFS_provider"                                 {
                                                          description = "Describes the NFS solution used"
                                                          type        = string
                                                        }
variable "options"                                      {}
variable "ppg"                                          { description = "Details of the proximity placement group" }
variable "resource_group"                               { description = "Details of the resource group" }
variable "sdu_public_key"                               { description = "Public key used for authentication" }
variable "sap_sid"                                      { description = "The SID of the application" }
variable "sid_keyvault_user_id"                         { description = "Details of the user keyvault for sap_system" }
variable "sid_password"                                 { description = "SDU password" }
variable "sid_username"                                 { description = "SDU username" }
variable "storage_bootdiag_endpoint"                    { description = "Details of the boot diagnostics storage account" }
variable "storage_subnet"                               { description = "Information about storage subnet" }
variable "terraform_template_version"                   { description = "The version of Terraform templates that were identified in the state file" }
variable "use_loadbalancers_for_standalone_deployments" {
                                                          description = "Defines if load balancers are used even for standalone deployments"
                                                          default     = true
                                                        }
variable "use_msi_for_clusters"                         { description = "If true, the Pacemaker cluser will use a managed identity" }
variable "use_observer"                                 { description = "Use Observer VM" }
variable "observer_vm_size"                             {}
variable "use_secondary_ips"                            {
                                                          description = "Use secondary IPs for the SAP System"
                                                          default     = false
                                                        }

variable "enable_firewall_for_keyvaults_and_storage"    {
                                                          description = "Boolean value indicating if firewall should be enabled for key vaults and storage"
                                                          type        = bool
                                                        }
#########################################################################################
#                                                                                       #
#  DNS settings                                                                         #
#                                                                                       #
#########################################################################################


variable "dns_settings"                                 {
                                                          description = "DNS Settings"
                                                        }

#########################################################################################
#                                                                                       #
#  ANF settings                                                                         #
#                                                                                       #
#########################################################################################

variable "hana_ANF_volumes"                           { description = "Defines HANA ANF volumes" }

#########################################################################################
#                                                                                       #
#  Tags                                                                                 #
#                                                                                       #
#########################################################################################

variable "tags"                                       { description = "If provided, tags for all resources" }

#########################################################################################
#                                                                                       #
#  Scale Set                                                                            #
#                                                                                       #
#########################################################################################

variable "use_scalesets_for_deployment"               { description = "Use Flexible Virtual Machine Scale Sets for the deployment" }

variable "scale_set_id"                               { description = "Azure resource identifier for scale set" }


#########################################################################################
#                                                                                       #
#  Scale Out                                                                            #
#                                                                                       #
#########################################################################################


variable "hanashared_volume_size"                     {
                                                        description = "The volume size in GB for hana shared"
                                                        default     = 128
                                                      }

variable "hanashared_id"                             {
                                                       description = "Azure Resource Identifier for an storage account"
                                                       default     = [""]
                                                     }

variable "use_single_hana_shared"                    {
                                                       description = "Boolean indicating wether to use a single storage account for all HANA file shares"
                                                       default     = false
                                                     }


variable "use_private_endpoint"                       {
                                                         description = "Boolean value indicating if private endpoint should be used for the deployment"
                                                         default     = false
                                                         type        = bool
                                                      }

variable "hanashared_private_endpoint_id"            {
                                                       description = "Azure Resource Identifier for an private endpoint connection"
                                                       default     = [""]
                                                     }
variable "Agent_IP"                                  {
                                                       description = "The IP address of the agent"
                                                       default     = [""]
                                                     }

variable "random_id"                                 { description = "Random hex string" }
