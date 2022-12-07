variable "database" {}
variable "infrastructure" {}
variable "options" {}

variable "anchor_vm" {
  description = "Deployed anchor VM"
}

variable "resource_group" {
  description = "Details of the resource group"
}

variable "storage_bootdiag_endpoint" {
  description = "Details of the boot diagnostics storage account"
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

variable "db_subnet" {
  description = "Information about SAP db subnet"
}

variable "storage_subnet" {
  description = "Information about storage subnet"
}

variable "sid_keyvault_user_id" {
  description = "Details of the user keyvault for sap_system"
}

variable "sdu_public_key" {
  description = "Public key used for authentication"
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


variable "db_asg_id" {
  description = "Database Application Security Group"
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

variable "database_dual_nics" {
  description = "Defines if the HANA DB uses dual network interfaces"
  default     = true
}

variable "database_vm_db_nic_ips" {
  description = "If provided, the database tier will be configured with the specified IPs"
}

variable "database_vm_db_nic_secondary_ips" {
  description = "If provided, the database tier will be configured with the specified IPs as secondary IPs"
}

variable "database_vm_admin_nic_ips" {
  description = "If provided, the database tier will be configured with the specified IPs (admin subnet)"
}

variable "database_vm_storage_nic_ips" {
  description = "If provided, the database tier will be configured with the specified IPs (srorage subnet)"
}

variable "database_server_count" {
  description = "The number of database servers"
  default     = 1
}

variable "order_deployment" {
  description = "psuedo condition for ordering deployment"
  default     = ""
}

variable "landscape_tfstate" {
  description = "Landscape remote tfstate file"
}

variable "hana_ANF_volumes" {
  description = "Defines HANA ANF volumes"
}

variable "NFS_provider" {
  description = "Describes the NFS solution used"
  type        = string
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
