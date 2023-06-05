variable "database" {}
variable "infrastructure" {}
variable "authentication" {}


variable "nics_dbnodes_admin" {
  description = "Admin NICs of HANA database nodes"
}


variable "loadbalancers" {
  description = "List of LoadBalancers created for HANA Databases"
}

variable "sap_sid" {
  description = "SAP SID"
}

variable "db_sid" {
  description = "Database SID"
}

variable "scs_server_ips" {
  description = "List of IP addresses for the SCS Servers"
}

variable "scs_server_secondary_ips" {
  description = "List of secondary IP addresses for the SCS Servers"
}

variable "application_server_ips" {
  description = "List of IP addresses for the Application Servers"
}

variable "application_server_secondary_ips" {
  description = "List of secondary IP addresses for the Application Servers"
}

variable "webdispatcher_server_ips" {
  description = "List of IP addresses for the Web dispatchers"
}

variable "webdispatcher_server_secondary_ips" {
  description = "List of secondary IP addresses for the Web dispatchers"
}

variable "db_server_ips" {
  description = "List of IP addresses for the database servers"
}

variable "db_server_secondary_ips" {
  description = "List of secondary IP addresses for the database servers"
}

variable "db_subnet_netmask" {
  description = "netmask for the database subnet"
}

variable "app_subnet_netmask" {
  description = "netmask for the SAP application subnet"
}

variable "nics_scs_admin" {
  description = "List of NICs for the SCS Application VMs"
}

variable "nics_app_admin" {
  description = "List of NICs for the Application Instance VMs"
}

variable "nics_web_admin" {
  description = "List of NICs for the Web dispatcher VMs"
}

// Any DB
variable "nics_anydb_admin" {
  description = "List of Admin NICs for the anyDB VMs"
}

variable "random_id" {
  description = "Random hex string"
}

variable "anydb_loadbalancers" {
  description = "List of LoadBalancers created for HANA Databases"
}

variable "software" {
  description = "Contain information about downloader, sapbits, etc."
  default     = {}
}

variable "landscape_tfstate" {
  description = "Landscape remote tfstate file"
}

variable "tfstate_resource_id" {
  description = "Resource ID for tf state file"
}

variable "app_tier_os_types" {
  description = "Defines the app tier os types"
}

variable "naming" {
  description = "Defines the names for the resources"
}

variable "sid_keyvault_user_id" {
  description = "Defines the names for the resources"
}

variable "disks" {
  description = "List of disks"
}

variable "use_local_credentials" {
  description = "SDU has unique credentials"
}

variable "authentication_type" {
  description = "VM Authentication type"
  default     = "key"

}

variable "db_ha" {
  description = "Is the DB deployment highly available"
  default     = false
}

variable "scs_ha" {
  description = "Is the SCS deployment highly available"
  default     = false
}

variable "ansible_user" {
  description = "The ansible remote user account to use"
  default     = "azureadm"
}

variable "db_lb_ip" {
  description = "DB Load Balancer IP"
  default     = ""
}

variable "scs_lb_ip" {
  description = "SCS Load Balancer IP"
  default     = ""
}

variable "ers_lb_ip" {
  description = "ERS Load Balancer IP"
  default     = ""
}

variable "sap_mnt" {
  description = "ANF Volume for SAP mount"
  default     = ""
}

variable "sap_transport" {
  description = "ANF Volume for SAP Transport"
  default     = ""
}

variable "database_admin_ips" {
  description = "List of Admin NICs for the DB VMs"
}

variable "bom_name" {
  default = ""
}

variable "scs_instance_number" {
  default = "00"
}

variable "ers_instance_number" {
  default = "02"
}

variable "pas_instance_number" {
  default = "00"
}

variable "platform" {
  default = "HANA"
}


variable "db_auth_type" {
  default = "key"
}


variable "install_path" {
  description = "Defines the install path for mounting /usr/sap/install"
  default     = ""
}

variable "NFS_provider" {
  description = "Defines the NFS provider"
  type        = string
}

variable "observer_ips" {
  description = "List of NICs for the Observer VMs"
}

variable "observer_vms" {
  description = "List of Observer VMs"
}

variable "shared_home" {
  description = "If defined provides shared-home support"
}

variable "hana_data" {
  description = "If defined provides the mount point for HANA data on ANF"
}

variable "hana_shared" {
  description = "If defined provides the mount point for HANA shared on ANF"
}

variable "hana_log" {
  description = "If defined provides the mount point for HANA log on ANF"
}

variable "usr_sap" {
  description = "If defined provides the mount point for /usr/sap on ANF"
}


variable "save_naming_information" {
  description = "If defined, will save the naming information for the resources"
  default     = false
}

variable "use_secondary_ips" {
  description = "Use secondary IPs for the SAP System"
}

variable "web_sid" {
  description = "The sid of the web dispatchers"
  default     = ""
}

variable "web_instance_number" {
  description = "The Instance number for Web Dispatcher"
  default     = "00"
}


variable "use_msi_for_clusters" {
  description = "If true, the Pacemaker cluser will use a managed identity"
}

variable "dns" {
  description = "The DNS label"
  default     = ""
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

variable "configuration_settings" {
  description = "This is a dictionary that will contain values persisted to the sap-parameters.file"
}

variable "db_clst_lb_ip" {
  description = "This is a Cluster IP address for Windows load balancer for the database"
}

variable "scs_clst_lb_ip" {
  description = "This is a Cluster IP address for Windows load balancer for central services"
}

variable "app_server_count" {
  description = "Number of Application Servers"
  type    = number
}

variable "scs_server_count" {
  description = "Number of SCS Servers"
  type    = number
}

variable "web_server_count" {
  description = "Number of Web Dispatchers"
  type    = number
}


variable "db_server_count" {
  description = "Number of Database Servers"
  type    = number
}
