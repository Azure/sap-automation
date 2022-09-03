/*

This block describes the variable for the infrastructure block 

*/

variable "environment" {
  type        = string
  description = "This is the environment name of the library"
  default     = ""
}


variable "codename" {
  type    = string
  default = ""
}

variable "location" {
  type    = string
  default = ""
}

variable "resourcegroup_name" {
  default = ""
}

variable "resourcegroup_arm_id" {
  default = ""
}

variable "resourcegroup_tags" {
  default = {}
}

/*

/*

This block describes the variable for the deployer block 

*/

variable "deployer_environment" {
  type        = string
  description = "This is the environment name of the deployer"
  default     = ""
}

variable "deployer_location" {
  type    = string
  default = ""
}

variable "deployer_vnet" {
  type    = string
  default = ""
}

variable "use_deployer" {
  default = true
}

/*
This block describes the variables for the key_vault section
*/

variable "spn_keyvault_id" {
  default = ""
}

/*
This block describes the variables for the "SAPBits" storage account
*/


variable "library_sapmedia_arm_id" {
  default = ""
}

variable "library_sapmedia_name" {
  default = ""
}

variable "library_sapmedia_account_tier" {
  default = "Standard"
}

variable "library_sapmedia_account_replication_type" {
  default = "LRS"
}

variable "library_sapmedia_account_kind" {
  default = "StorageV2"
}

variable "library_sapmedia_file_share_enable_deployment" {
  default = true
}

variable "library_sapmedia_file_share_is_existing" {
  default = false
}

variable "library_sapmedia_file_share_name" {
  default = "sapbits"
}
variable "library_sapmedia_blob_container_enable_deployment" {
  default = true
}

variable "library_sapmedia_blob_container_is_existing" {
  default = false
}

variable "library_sapmedia_blob_container_name" {
  default = "sapbits"
}


/*
This block describes the variables for the "TFState" storage account
*/


variable "library_terraform_state_arm_id" {
  default = ""
}

variable "library_terraform_state_name" {
  default = ""
}

variable "library_terraform_state_account_tier" {
  default = "Standard"
}

variable "library_terraform_state_account_replication_type" {
  default = "LRS"
}

variable "library_terraform_state_account_kind" {
  default = "StorageV2"
}

variable "library_terraform_state_blob_container_is_existing" {
  default = false
}

variable "library_terraform_state_blob_container_name" {
  default = "tfstate"
}

variable "library_ansible_blob_container_is_existing" {
  default = false
}

variable "library_ansible_blob_container_name" {
  default = "ansible"
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

variable "use_webapp" {
  default = false
}

variable "name_override_file" {
  description = "If provided, contains a json formatted file defining the name overrides"
  default     = ""
}

variable "enable_purge_control_for_keyvaults" {
  description = "Disables the purge protection for Azure keyvaults. USE THIS ONLY FOR TEST ENVIRONMENTS"
  default     = true
  type        = bool
}
