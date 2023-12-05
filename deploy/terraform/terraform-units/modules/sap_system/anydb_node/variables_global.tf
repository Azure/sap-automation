#######################################4#######################################8
#                                                                              #
#                                Parameters                                    #
#                                                                              #
#######################################4#######################################8

variable "admin_subnet"                                 { description = "Information about SAP admin subnet" }
variable "anchor_vm"                                    { description = "Deployed anchor VM" }
variable "cloudinit_growpart_config"                    { description = "A cloud-init config that configures automatic growpart expansion of root partition" }
variable "custom_disk_sizes_filename"                   { description = "Disk size json file" }
variable "database_server_count"                        {
                                                          description = "The number of database servers"
                                                          default     = 1
                                                        }
variable "database_cluster_disk_size"                   { description = "The size of the shared disk for the Database cluster" }
variable "database_cluster_disk_lun"                    { description = "The LUN of the shared disk for the Database cluster" }
variable "database_vm_admin_nic_ips"                    { description = "If provided, the database tier will be configured with the specified IPs (admin subnet)" }
variable "database_vm_db_nic_ips"                       { description = "If provided, the database tier will be configured with the specified IPs" }
variable "database_vm_db_nic_secondary_ips"             { description = "If provided, the database tier will be configured with the specified IPs as secondary IPs" }
variable "database"                                     { description = "Dictionary of information about the database tier" }
variable "db_asg_id"                                    { description = "Database Application Security Group" }
variable "db_subnet"                                    { description = "Information about SAP db subnet" }
variable "deploy_application_security_groups"           { description = "Defines if application security groups should be deployed" }
variable "deployment"                                   { description = "The type of deployment" }
variable "fencing_role_name"                            { description = "If specified the role name to use for the fencing" }
variable "infrastructure"                               { description = "Dictionary of information about the common infrastructure" }
variable "landscape_tfstate"                            { description = "Terraform output from the workload zone" }
variable "license_type"                                 { description = "Specifies the license type for the OS" }
variable "naming"                                       { description = "Defines the names for the resources" }
variable "options"                                      { description = "Dictionary of miscallaneous parameters" }
variable "order_deployment"                             { description = "psuedo condition for ordering deployment" }
variable "ppg"                                          { description = "Details of the proximity placement group" }
variable "resource_group"                               { description = "Details of the resource group" }
variable "sap_sid"                                      { description = "The SID of the application" }
variable "sdu_public_key"                               { description = "Public key used for authentication" }
variable "sid_keyvault_user_id"                         { description = "ID of the user keyvault for sap_system" }
variable "sid_password"                                 { description = "SDU password" }
variable "sid_username"                                 { description = "SDU username" }
variable "storage_bootdiag_endpoint"                    { description = "Details of the boot diagnostics storage account" }
variable "terraform_template_version"                   { description = "The version of Terraform templates that were identified in the state file" }
variable "use_loadbalancers_for_standalone_deployments" { description = "Defines if load balancers are used even for standalone deployments" }
variable "use_msi_for_clusters"                         { description = "If true, the Pacemaker cluser will use a managed identity" }
variable "use_observer"                                 { description = "If true, the observer will be deployed" }
variable "use_secondary_ips"                            {
                                                          description = "Use secondary IPs for the SAP System"
                                                          default     = false
                                                        }


#########################################################################################
#                                                                                       #
#  DNS settings                                                                         #
#                                                                                       #
#########################################################################################

variable "use_custom_dns_a_registration"                {
                                                          description = "Boolean value indicating if a custom dns a record should be created when using private endpoints"
                                                          default     = false
                                                          type        = bool
                                                        }
variable "management_dns_subscription_id"               {
                                                          description = "String value giving the possibility to register custom dns a records in a separate subscription"
                                                          default     = null
                                                          type        = string
                                                        }
variable "management_dns_resourcegroup_name"            {
                                                          description = "String value giving the possibility to register custom dns a records in a separate resourcegroup"
                                                          default     = null
                                                          type        = string
                                                        }
variable "register_virtual_network_to_dns"              {
                                                          description = "Boolean value indicating if the vnet should be registered to the dns zone"
                                                          type        = bool
                                                        }

#########################################################################################
#                                                                                       #
#  Scale Set                                                                            #
#                                                                                       #
#########################################################################################

variable "use_scalesets_for_deployment"                 { description = "Use Flexible Virtual Machine Scale Sets for the deployment" }
variable "scale_set_id"                                 { description = "Azure resource identifier for scale set" }

#########################################################################################
#                                                                                       #
#  Tags                                                                                 #
#                                                                                       #
#########################################################################################

variable "tags"                                         { description = "If provided, tags for all resources" }
