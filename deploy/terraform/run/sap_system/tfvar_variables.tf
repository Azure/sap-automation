#########################################################################################
#                                                                                       #
#  Environment definitioms                                                              #
#                                                                                       #
#########################################################################################

variable "environment" {
  type        = string
  description = "This is the environment name of the deployment"
  default     = ""
}

variable "codename" {
  description = "Optipnal code name for the deployment"
  type        = string
  default     = ""
}

variable "custom_prefix" {
  description = "Optional custom prefix for the deployment"
  type        = string
  default     = ""
}

variable "use_prefix" {
  description = "Use the prefix for the resources"
  default     = true
}

variable "location" {
  description = "The Azure region for the resources"
  type        = string
  default     = ""
}

variable "name_override_file" {
  description = "If provided, contains a json formatted file defining the name overrides"
  default     = ""
}

variable "custom_disk_sizes_filename" {
  description = "Custom disk configuration json file for Virtual machines"
  default     = ""
}

#########################################################################################
#                                                                                       #
#  Resource Group variables                                                             #
#                                                                                       #
#########################################################################################

variable "resourcegroup_name" {
  description = "If provided, the name of the resource group to be created"
  default     = ""
}

variable "resourcegroup_arm_id" {
  description = "If provided, the Azure resource group id"
  default     = ""
}

variable "resourcegroup_tags" {
  description = "Tags for the resource group"
  default     = {}
}

#########################################################################################
#                                                                                       #
#  Infrastructure variables                                                             #
#                                                                                       #
#########################################################################################


variable "proximityplacementgroup_names" {
  description = "Names of the proximity placement groups"
  default     = []
}

variable "proximityplacementgroup_arm_ids" {
  description = "Azure resource group ids for the proximity placement groups"
  default     = []
}

#########################################################################################
#                                                                                       #
#  Virtual Network variables                                                            #
#                                                                                       #
#########################################################################################

variable "network_logical_name" {
  description = "The logical name of the virtual network, used for resource naming"
  default     = ""
}

variable "use_secondary_ips" {
  description = "Use secondary IPs for the SAP System"
  default     = false
}


#########################################################################################
#                                                                                       #
#  Admin Subnet variables                                                               #
#                                                                                       #
#########################################################################################

variable "admin_subnet_name" {
  description = "If provided, the name of the admin subnet"
  default     = ""
}

variable "admin_subnet_arm_id" {
  description = "If provided, Azure resource id for the admin subnet"
  default     = ""
}

variable "admin_subnet_address_prefix" {
  description = "The address prefix for the admin subnet"
  default     = ""
}

variable "admin_subnet_nsg_name" {
  description = "If provided, the name of the admin subnet NSG"
  default     = ""
}

variable "admin_subnet_nsg_arm_id" {
  description = "If provided, Azure resource id for the admin subnet NSG"
  default     = ""
}


#########################################################################################
#                                                                                       #
#  DB Subnet variables                                                               #
#                                                                                       #
#########################################################################################

variable "db_subnet_name" {
  description = "If provided, the name of the db subnet"
  default     = ""
}

variable "db_subnet_arm_id" {
  description = "If provided, Azure resource id for the db subnet"
  default     = ""
}

variable "db_subnet_address_prefix" {
  description = "The address prefix for the db subnet"
  default     = ""
}

variable "db_subnet_nsg_name" {
  description = "If provided, the name of the db subnet NSG"
  default     = ""
}

variable "db_subnet_nsg_arm_id" {
  description = "If provided, Azure resource id for the db subnet NSG"
  default     = ""
}


#########################################################################################
#                                                                                       #
#  App Subnet variables                                                                 #
#                                                                                       #
#########################################################################################

variable "app_subnet_name" {
  description = "If provided, the name of the app subnet"
  default     = ""
}

variable "app_subnet_arm_id" {
  description = "If provided, Azure resource id for the app subnet"
  default     = ""
}

variable "app_subnet_address_prefix" {
  description = "The address prefix for the app subnet"
  default     = ""
}

variable "app_subnet_nsg_name" {
  description = "If provided, the name of the app subnet NSG"
  default     = ""
}

variable "app_subnet_nsg_arm_id" {
  description = "If provided, Azure resource id for the app subnet NSG"
  default     = ""
}


#########################################################################################
#                                                                                       #
#  Web Subnet variables                                                                 #
#                                                                                       #
#########################################################################################

variable "web_subnet_name" {
  description = "If provided, the name of the web subnet"
  default     = ""
}

variable "web_subnet_arm_id" {
  description = "If provided, Azure resource id for the web subnet"
  default     = ""
}

variable "web_subnet_address_prefix" {
  description = "The address prefix for the web subnet"
  default     = ""
}

variable "web_subnet_nsg_name" {
  description = "If provided, the name of the web subnet NSG"
  default     = ""
}

variable "web_subnet_nsg_arm_id" {
  description = "If provided, Azure resource id for the web subnet NSG"
  default     = ""
}

variable "use_observer" {
  description = "value to determine if an observer virtual machine is used"
  default     = true
}

#########################################################################################
#                                                                                       #
#  Key Vault variables                                                                  #
#                                                                                       #
#########################################################################################

variable "user_keyvault_id" {
  description = "If provided, the Azure resource identifier of the credentials keyvault"
  default     = ""
}

variable "spn_keyvault_id" {
  description = "If provided, the Azure resource identifier of the deployment credential keyvault"
  default     = ""
}

variable "enable_purge_control_for_keyvaults" {
  description = "Disables the purge protection for Azure keyvaults."
  default     = false
  type        = bool
}

#########################################################################################
#                                                                                       #
#  Authentication variables, use these if you want to have SID specific credentials     #
#                                                                                       #
#########################################################################################

variable "automation_username" {
  description = "The username for the automation account"
  default     = ""
}

variable "automation_password" {
  description = "If provided, the password for the automation account"
  default     = ""
}

variable "automation_path_to_public_key" {
  description = "If provided, the path to the existing public key for the automation account"
  default     = ""
}

variable "automation_path_to_private_key" {
  description = "If provided, the path to the existing private key for the automation account"
  default     = ""
}

variable "use_spn" {
  description = "Log in using a service principal when performing the deployment"
  default     = true
}


#########################################################################################
#                                                                                       #
#  Database tier variables                                                              #
#                                                                                       #
#########################################################################################

variable "database_platform" {
  description = "Database platform, supported values are HANA, DB2, ORACLE, ASE, SQLSERVER or NONE (in this case no database tier is deployed)"
  default     = ""
}

variable "database_sid" {
  description = "The database SID"
  default     = "HDB"
}

variable "database_server_count" {
  description = "The number of database servers"
  default     = 1
}

variable "database_high_availability" {
  description = "If true, the database tier will be configured for high availability"
  default     = false
}

variable "use_msi_for_clusters" {
  description = "If true, the Pacemaker cluser will use a managed identity"
  default     = false
}

variable "fencing_role_name" {
  description = "If specified the role name to use for the fencing agent"
  default     = "Virtual Machine Contributor"
}


variable "database_vm_zones" {
  description = "If provided, the database tier will be deployed in the specified zones"
  default     = []
}

variable "database_size" {
  description = "Dictionary value to sizing json"
  default     = ""
}

variable "db_sizing_dictionary_key" {
  description = "Dictionary value to sizing json"
  default     = ""
}

variable "db_disk_sizes_filename" {
  description = "Custom disk configuration json file for database tier"
  default     = ""
}

variable "database_vm_image" {
  description = "Virtual machine image to use for the database server"
  default = {
    "os_type"         = "LINUX"
    "source_image_id" = ""
    "publisher"       = ""
    "offer"           = ""
    "sku"             = ""
    "version"         = ""
    "type"            = "custom"
  }
}

variable "database_vm_authentication_type" {
  description = "Authentication type for the database server"
  default     = "key"
}

variable "database_vm_avset_arm_ids" {
  description = "If provided, Azure resource ids for the availability sets to use for the database servers"
  default     = []
}

variable "database_vm_use_DHCP" {
  description = "If true, the database server will use Azure Provided IP addresses"
  default     = false
}

variable "database_instance_number" {
  description = "The Instance number for the database server"
  default     = "00"
}
variable "database_no_avset" {
  description = "If true, the database tier will not use an availability set"
  default     = false
}

variable "database_dual_nics" {
  description = "If true, the database tier will have two NICs"
  default     = false
}

variable "database_no_ppg" {
  description = "If provided, the database tier will not use a proximity placement group"
  default     = false
}

variable "database_loadbalancer_ips" {
  description = "If provided, the database tier will be configured with the specified load balancer IP"
  default     = []
}

variable "database_tags" {
  description = "If provided, the database tier will be configured with the specified tags"
  default     = {}
}

variable "database_vm_db_nic_ips" {
  description = "If provided, the database tier will be configured with the specified IPs"
  default     = [""]
}

variable "database_vm_db_nic_secondary_ips" {
  description = "If provided, the database tier will be configured with the specified IPs as secondary IPs"
  default     = [""]
}

variable "database_vm_admin_nic_ips" {
  description = "If provided, the database tier will be configured with the specified IPs (admin subnet)"
  default     = [""]
}

variable "database_vm_storage_nic_ips" {
  description = "If provided, the database tier will be configured with the specified IPs (storage subnet)"
  default     = [""]
}

variable "database_HANA_use_ANF_scaleout_scenario" {
  default = false
}


#########################################################################################
#                                                                                       #
#  Application tier variables                                                           #
#                                                                                       #
#########################################################################################

variable "enable_app_tier_deployment" {
  description = "If true, the application tier will be deployed"
  default     = true
}

variable "app_tier_authentication_type" {
  description = "App tier authentication type"
  default     = "key"
}

variable "sid" {
  description = "Application SID"
  default     = ""
}

variable "app_tier_use_DHCP" {
  description = "If true, the application tier will use Azure Provided IP addresses"
  default     = false
}

variable "app_tier_dual_nics" {
  description = "If true, the application tier will have two NICs"
  default     = false
}

variable "app_tier_vm_sizing" {
  description = "Dictionary value to sizing json"
  default     = ""
}

variable "app_tier_sizing_dictionary_key" {
  description = "Dictionary value to sizing json"
  default     = ""
}


variable "app_disk_sizes_filename" {
  description = "Custom disk configuration json file for application tier"
  default     = ""
}

#########################################################################################
#                                                                                       #
#  SAP Central Services tier variables                                                  #
#                                                                                       #
#########################################################################################

variable "scs_server_count" {
  description = "The number of SAP Central Services servers"
  default     = 0
}

variable "scs_high_availability" {
  description = "If true, the SAP Central Services tier will be configured for high availability"
  default     = false
}

variable "scs_server_zones" {
  description = "If provided, the SAP Central Services tier will be deployed in the specified zones"
  default     = []
}

variable "scs_server_image" {
  description = "Virtual machine image to use for the SAP Central Services server(s)"
  default = {
    "os_type"         = "LINUX"
    "source_image_id" = ""
    "publisher"       = ""
    "offer"           = ""
    "sku"             = ""
    "version"         = ""
  }
}

variable "scs_instance_number" {
  description = "The Instance number for SCS"
  default     = "00"
}

variable "ers_instance_number" {
  description = "The Instance number for ERS"
  default     = "02"
}

variable "scs_server_app_nic_ips" {
  description = "If provided, the SAP Central Services tier will be configured with the specified IPs"
  default     = []
}

variable "scs_server_nic_secondary_ips" {
  description = "If provided, the SAP Central Services tier will be configured with the specified IPs as secondary IPs"
  default     = []
}

variable "scs_server_admin_nic_ips" {
  description = "If provided, the SAP Central Services tier will be configured with the specified IPs  (admin subnet)"
  default     = []
}

variable "scs_server_loadbalancer_ips" {
  description = "If provided, the SAP Central Services tier will be configured with the specified load balancer IPs"
  default     = []
}

variable "scs_server_sku" {
  description = "The Virtual Machine SKU to use"
  default     = ""
}

variable "scs_server_tags" {
  description = "If provided, the SAP Central Services tier will be configured with the specified tags"
  default     = {}
}

variable "scs_server_no_avset" {
  description = "If true, the SAP Central Services tier will not use an availability set"
  default     = false
}

variable "scs_server_no_ppg" {
  description = "If provided, the Central Services will not be placed in a proximity placement group"
  default     = false
}

#########################################################################################
#                                                                                       #
#  Application Server variables                                                         #
#                                                                                       #
#########################################################################################

variable "application_server_count" {
  description = "The number of application servers"
  default     = 0
}

variable "application_server_app_nic_ips" {
  description = "IP addresses for the application servers"
  default     = []
}

variable "application_server_nic_secondary_ips" {
  description = "IP addresses for the application servers"
  default     = []
}

variable "application_server_admin_nic_ips" {
  description = "IP addresses for the application servers (admin subnet)"
  default     = []
}

variable "application_server_sku" {
  description = "The SKU for the application servers"
  default     = ""
}

variable "application_server_tags" {
  description = "The tags for the application servers"
  default     = {}
}

variable "application_server_zones" {
  description = "The zones for the application servers"
  default     = []
}

variable "application_server_no_avset" {
  description = "If true, the application tier will not use an availability set"
  default     = false
}

variable "application_server_vm_avset_arm_ids" {
  description = "If provided, Azure resource ids for the availability sets to use for the application servers"
  default     = []
}

variable "application_server_no_ppg" {
  description = "If provided, the application servers will not be placed in a proximity placement group"
  default     = false
}

variable "application_server_image" {
  description = "Virtual machine image to use for the application server"
  default = {
    "os_type"         = "LINUX"
    "source_image_id" = ""
    "publisher"       = ""
    "offer"           = ""
    "sku"             = ""
    "version"         = ""
  }
}

#########################################################################################
#                                                                                       #
#  Web Dispatcher variables                                                             #
#                                                                                       #
#########################################################################################

variable "webdispatcher_server_count" {
  description = "The number of web dispatchers"
  default     = 0
}

variable "web_sid" {
  description = "The sid of the web dispatchers"
  default     = ""
}


variable "webdispatcher_server_zones" {
  description = "The zones for the web dispatchers"
  default     = []
}

variable "webdispatcher_server_image" {
  description = "Virtual machine image to use for the web dispatchers"
  default = {
    "os_type"         = "LINUX"
    "source_image_id" = ""
    "publisher"       = ""
    "offer"           = ""
    "sku"             = ""
    "version"         = ""
  }
}

variable "webdispatcher_server_app_nic_ips" {
  description = "The IP addresses for the web dispatchers"
  default     = []
}

variable "webdispatcher_server_nic_secondary_ips" {
  description = "If provided, the Web Dispatchers will be configured with the specified IPs as secondary IPs"
  default     = []
}

variable "webdispatcher_server_admin_nic_ips" {
  description = "The IP addresses for the web dispatchers (admin subnet)"
  default     = []
}

variable "webdispatcher_server_loadbalancer_ips" {
  description = "If provided, the Web Dispatcher tier will be configured with the specified load balancer IPs"
  default     = []
}

variable "webdispatcher_server_sku" {
  description = "The SKU for the web dispatchers"
  default     = ""
}

variable "webdispatcher_server_tags" {
  description = "The tags for the web dispatchers"
  default     = {}
}

variable "webdispatcher_server_no_avset" {
  description = "If true, the Web Dispatcher tier will not use an availability set"
  default     = false
}

variable "webdispatcher_server_no_ppg" {
  description = "If provided, the web dispatchers will not be placed in a proximity placement group"
  default     = false
}

#########################################################################################
#                                                                                       #
#  Miscallaneous settings                                                               #
#                                                                                       #
#########################################################################################

variable "resource_offset" {
  description = "Provides an offset for the resource names (Server00 vs Server01)"
  default     = 0
}

variable "vm_disk_encryption_set_id" {
  description = "If provided, the VM disks will be encrypted with the specified disk encryption set"
  default     = ""
}

variable "nsg_asg_with_vnet" {
  description = "If true, the NSG will be placed in the resource group containing the VNet"
  default     = false
}

variable "legacy_nic_order" {
  description = "If defined, will reverse the order of the NICs"
  default     = false
}

variable "use_loadbalancers_for_standalone_deployments" {
  description = "If defined, will use load balancers for standalone deployments"
  default     = true
}

variable "idle_timeout_scs_ers" {
  description = "Sets the idle timeout setting for the SCS and ERS loadbalancer"
  default     = 4
}

variable "bom_name" {
  description = "NAme of the SAP Application Bill of Material file"
  default     = ""
}

variable "Agent_IP" {
  description = "If provided, contains the IP address of the agent"
  type    = string
  default = ""
}

variable "shared_home" {
  description = "If defined provides shared-home support"
  default     = false
}

variable "save_naming_information" {
  description = "If defined, will save the naming information for the resources"
  default     = false
}

variable "deploy_application_security_groups" {
  description = "Defines if application security groups should be deployed"
  default     = true
}

variable "use_private_endpoint" {
  description = "Boolean value indicating if private endpoint should be used for the deployment"
  default     = false
  type        = bool
}

variable "use_custom_dns_a_registration" {
  description = "Boolean value indicating if a custom dns a record should be created when using private endpoints"
  default     = false
  type        = bool
}

variable "management_dns_subscription_id" {
  description = "String value giving the possibility to register custom dns a records in a separate subscription"
  default     = null
  type        = string
}

variable "management_dns_resourcegroup_name" {
  description = "String value giving the possibility to register custom dns a records in a separate resourcegroup"
  default     = null
  type        = string
}
#########################################################################################
#                                                                                       #
#  NFS and Shared Filed settings                                                        #
#                                                                                       #
#########################################################################################

variable "NFS_provider" {
  description = "NFS Provider, valid values are 'AFS', 'ANF' or 'NONE'"
  type        = string
  default     = "NONE"
}

variable "sapmnt_volume_size" {
  description = "sapmnt volume size in GB"
  default     = 128
}

variable "azure_files_sapmnt_id" {
  description = "Azure File Share ID for SAPMNT"
  default     = ""
}

variable "sapmnt_private_endpoint_id" {
  description = "Azure Resource Identifier for an private endpoint connection"
  type        = string
  default     = ""
}


#########################################################################################
#                                                                                       #
#  ANF settings                                                                         #
#                                                                                       #
#########################################################################################


variable "ANF_HANA_data" {
  description = "If defined, will create ANF volumes for HANA data"
  default     = false
}

variable "ANF_HANA_data_volume_size" {
  description = "If defined provides the size of the HANA data volume"
  default     = 512
}

variable "ANF_HANA_data_use_existing_volume" {
  description = "Use existing data volume"
  default     = false
}

variable "ANF_HANA_data_volume_name" {
  description = "Data volume name"
  default     = [""]
}

variable "ANF_HANA_data_volume_throughput" {
  description = "If defined provides the throughput of the data volume"
  default     = 128
}

variable "ANF_HANA_log" {
  description = "If defined, will create ANF volumes for HANA log"
  default     = false
}

variable "ANF_HANA_log_volume_size" {
  description = "If defined provides the size of the HANA log volume"
  default     = 512
}

variable "ANF_HANA_log_use_existing" {
  description = "Use existing log volume"
  default     = false
}

variable "ANF_HANA_log_volume_name" {
  description = "Log volume name"
  default     = [""]
}

variable "ANF_HANA_log_volume_throughput" {
  description = "If defined provides the throughput of the log volume"
  default     = 128
}

variable "ANF_HANA_shared" {
  description = "If defined, will create ANF volumes for HANA shared"
  default     = false
}

variable "ANF_HANA_shared_volume_size" {
  description = "If defined provides the size of the HANA shared volume"
  default     = 512
}

variable "ANF_HANA_shared_use_existing" {
  description = "Use existing shared volume"
  default     = false
}

variable "ANF_HANA_shared_volume_name" {
  description = "If defined provides the name of the HANA shared volume"
  default     = 512
}

variable "ANF_HANA_shared_volume_throughput" {
  description = "If defined provides the throughput of the /shared volume"
  default     = 128
}


variable "ANF_usr_sap" {
  description = "If defined, will create ANF volumes for /usr/sap"
  default     = false
}

variable "ANF_usr_sap_volume_size" {
  description = "If defined provides the size of the  /usr/sap volume"
  default     = 512
}

variable "ANF_usr_sap_use_existing" {
  description = "Use existing  /usr/sap volume"
  default     = false
}

variable "ANF_usr_sap_volume_name" {
  description = "If defined provides the name of the /usr/sap volume"
  default     = ""
}

variable "ANF_usr_sap_throughput" {
  description = "If defined provides the throughput of the /usr/sap volume"
  default     = 128
}

variable "use_service_endpoint" {
  description = "Boolean value indicating if service endpoints should be used for the deployment"
  default     = false
  type        = bool
}

variable "ANF_sapmnt" {
  description = "Use existing sapmnt volume"
  default     = false
}

variable "ANF_sapmnt_volume_name" {
  description = "sapmnt volume name"
  default     = ""
}

variable "ANF_sapmnt_volume_size" {
  description = "If defined provides the size of the sapmnt volume"
  default     = 64
}

variable "ANF_sapmnt_volume_throughput" {
  description = "If defined provides the throughput of the sapmnt volume"
  default     = 64
}


#########################################################################################
#                                                                                       #
#  Anchor VM variables                                                                  #
#                                                                                       #
#########################################################################################

variable "deploy_anchor_vm" {
  description = "If defined, will deploy the Anchor VM to anchor the PPG"
  default     = false
}

variable "anchor_vm_sku" {
  description = "SKU of the Anchor VM"
  default     = ""
}

variable "anchor_vm_use_DHCP" {
  description = "If defined, will use Azure provided IP addresses for the Anchor VM"
  default     = false
}

variable "anchor_vm_image" {
  description = "Image of the Anchor VM"
  default = {
    "os_type"         = ""
    "source_image_id" = ""
    "publisher"       = "SUSE"
    "offer"           = "sles-sap-15-sp3"
    "sku"             = "gen2"
    "version"         = ""
  }
}

variable "anchor_vm_authentication_type" {
  description = "Authentication type of the Anchor VM"
  default     = "key"
}

variable "anchor_vm_authentication_username" {
  description = "value of the username for the Anchor VM"
  default     = "azureadm"
}


variable "anchor_vm_nic_ips" {
  description = "IP addresses of the NICs for the Anchor VM"
  default     = []
}

variable "anchor_vm_accelerated_networking" {
  description = "If defined, will enable accelerated networking for the Anchor VM"
  default     = true
}

variable "subscription" {
  description = "Target subscription"
  default     = ""
}
