#######################################4#######################################8
#                                                                              #
#                                Parameters                                    #
#                                                                              #
#######################################4#######################################8

variable "admin_subnet"                                 { description = "Information about the admin subnet" }
variable "application_tier"                             { description = "Dictionary of information about the application tier" }
variable "cloudinit_growpart_config"                    { description = "A cloud-init config that configures automatic growpart expansion of root partition" }
variable "custom_disk_sizes_filename"                   { description = "Disk size json file" }
variable "deploy_application_security_groups"           { description = "Defines if application security groups should be deployed" }
variable "deployer_user"                                {
                                                          description = "Details of the users"
                                                          default     = []
                                                        }
variable "deployment"                                   { description = "The type of deployment" }
variable "fencing_role_name"                            { description = "If specified the role name to use for the fencing" }
variable "firewall_id"                                  { description = "Firewall (if any) id" }
variable "idle_timeout_scs_ers"                         {
                                                          description = "Sets the idle timeout setting for the SCS and ERS loadbalancer"
                                                          default     = 4
                                                        }
variable "infrastructure"                               { description = "Dictionary of information about the common infrastructure" }
variable "landscape_tfstate"                            { description = "Terraform output from the workload zone" }
variable "license_type"                                 { description = "Specifies the license type for the OS" }
variable "naming"                                       { description = "Defines the names for the resources" }
variable "network_location"                             { description = "Location of the Virtual Network" }
variable "network_resource_group"                       { description = "Resource Group of the Virtual Network" }
variable "options"                                      { description = "Dictionary of miscallaneous parameters" }
variable "order_deployment"                             { description = "psuedo condition for ordering deployment" }
variable "ppg"                                          { description = "Details of the proximity placement group" }
variable "register_virtual_network_to_dns"              { description = "Boolean value indicating if the vnet should be registered to the dns zone" }
variable "resource_group"                               { description = "Details of the resource group" }
variable "route_table_id"                               { description = "Route table (if any) id" }
variable "sap_sid"                                      { description = "The SID of the application" }
variable "sdu_public_key"                               { description = "Public key used for authentication" }
variable "sid_keyvault_user_id"                         { description = "Details of the user keyvault for the sap system" }
variable "sid_password"                                 { description = "SDU password" }
variable "sid_username"                                 { description = "SDU username" }
variable "storage_bootdiag_endpoint"                    { description = "Details of the boot diagnostic storage device" }
variable "terraform_template_version"                   { description = "The version of Terraform templates that were identified in the state file" }
variable "use_loadbalancers_for_standalone_deployments" {
                                                          description = "Defines if load balancers are used even for standalone deployments"
                                                          default     = true
                                                        }
variable "use_secondary_ips"                            {
                                                          description = "Use secondary IPs for the SAP System"
                                                          default     = false
                                                        }
variable "use_msi_for_clusters"                         { description = "If true, the Pacemaker cluser will use a managed identity" }

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

variable "scs_cluster_disk_lun"                         { description = "The LUN of the shared disk for the SAP Central Services cluster" }
variable "scs_cluster_disk_size"                        { description = "The size of the shared disk for the SAP Central Services cluster" }

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
