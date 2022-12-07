variable "application_tier" {}
variable "infrastructure" {}
variable "options" {}

variable "resource_group" {
  description = "Details of the resource group"
}

variable "storage_bootdiag_endpoint" {
  description = "Details of the boot diagnostic storage device"
}

variable "ppg" {
  description = "Details of the proximity placement group"
}

variable "naming" {
  description = "Defines the names for the resources"
}

variable "custom_disk_sizes_filename" {
  type        = string
  description = "Disk size json file"
  default     = ""
}

variable "admin_subnet" {
  description = "Information about SAP admin subnet"
}

variable "deployer_user" {
  description = "Details of the users"
  default     = []
}

variable "sid_keyvault_user_id" {
  description = "Details of the user keyvault for sap_system"
}

variable "sdu_public_key" {
  description = "Public key used for authentication"
}

variable "route_table_id" {
  description = "Route table (if any) id"
}

variable "firewall_id" {
  description = "Firewall (if any) id"
}

variable "sid_password" {
  description = "SDU password"
}

variable "sid_username" {
  description = "SDU username"
}

variable "sap_sid" {
  description = "The SID of the application"
}
variable "landscape_tfstate" {
  description = "Landscape remote tfstate file"
}

variable "deployment" {
  description = "The type of deployment"
}

variable "terraform_template_version" {
  description = "The version of Terraform templates that were identified in the state file"
}

variable "cloudinit_growpart_config" {
  description = "A cloud-init config that configures automatic growpart expansion of root partition"
}

variable "license_type" {
  description = "Specifies the license type for the OS"
  default     = ""
}

variable "use_loadbalancers_for_standalone_deployments" {
  description = "Defines if load balancers are used even for standalone deployments"
  default     = true
}

variable "idle_timeout_scs_ers" {
  description = "Sets the idle timeout setting for the SCS and ERS loadbalancer"
  default     = 4
}

variable "network_location" {
  description = "Location of the Virtual Network"
  default     = ""
}

variable "network_resource_group" {
  description = "Resource Group of the Virtual Network"
  default     = ""
}

variable "order_deployment" {
  description = "psuedo condition for ordering deployment"
  default     = ""
}

variable "use_secondary_ips" {
  description = "Use secondary IPs for the SAP System"
  default     = false
}

variable "deploy_application_security_groups" {
  description = "Defines if application security groups should be deployed"
}

variable "use_msi_for_clusters" {
  description = "If true, the Pacemaker cluser will use a managed identity"
}

variable "fencing_role_name" {
  description = "If specified the role name to use for the fencing"
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
