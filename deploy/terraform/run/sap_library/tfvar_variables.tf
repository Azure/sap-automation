#########################################################################################
#                                                                                       #
#  Environment definitioms                                                              #
#                                                                                       #
#########################################################################################


variable "environment" {
  description = "This is the environment name of the deployer"
  type        = string
}

variable "codename" {
  description = "Additional component for naming the resources"
  default     = ""
  type        = string
}

variable "location" {
  description = "Defines the Azure location where the resources will be deployed"
  type        = string
}

variable "name_override_file" {
  description = "If provided, contains a json formatted file defining the name overrides"
  default     = ""
}

variable "use_deployer" {
  description = "Use deployer to deploy the resources"
  default     = true
}

###############################################################################
#                                                                             #
#                             Resource Group                                  #
#                                                                             #
###############################################################################


variable "resourcegroup_name" {
  description = "If defined, the name of the resource group into which the resources will be deployed"
  default     = ""
}

variable "resourcegroup_arm_id" {
  description = "Azure resource identifier for the resource group into which the resources will be deployed"
  default     = ""
}

variable "resourcegroup_tags" {
  description = "tags to be added to the resource group"
  default     = {}
}


variable "spn_keyvault_id" {
  default = ""
}

#########################################################################################
#                                                                                       #
#  SAPBits storage account                                                              #
#                                                                                       #
#########################################################################################


variable "library_sapmedia_arm_id" {
  description = "Optional Azure resource identifier for the storage account where the SAP bits will be stored"
  default     = ""
}

variable "library_sapmedia_name" {
  description = "If defined, the name of the storage account where the SAP bits will be stored"
  default     = ""
}

variable "library_sapmedia_account_tier" {
  description = "The storage account tier"
  default     = "Standard"
}

variable "library_sapmedia_account_replication_type" {
  description = "The replication type for the storage account"
  default     = "LRS"
}

variable "library_sapmedia_account_kind" {
  description = "The storage account kind"
  default     = "StorageV2"
}

variable "library_sapmedia_file_share_enable_deployment" {
  description = "If true, the file share will be created"
  default     = true
}

variable "library_sapmedia_file_share_is_existing" {
  description = "If defined use an existing file share"
  default     = false
}

variable "library_sapmedia_file_share_name" {
  description = "If defined, the name of the file share"
  default     = "sapbits"
}
variable "library_sapmedia_blob_container_enable_deployment" {
  description = "If true, the blob container will be created"
  default     = true
}

variable "library_sapmedia_blob_container_is_existing" {
  description = "If defined use an existing blob container"
  default     = false
}

variable "library_sapmedia_blob_container_name" {
  description = "If defined, the name of the blob container"
  default     = "sapbits"
}


#########################################################################################
#                                                                                       #
#  Terraform state storage account                                                              #
#                                                                                       #
#########################################################################################



variable "library_terraform_state_arm_id" {
  description = "Optional Azure resource identifier for the storage account where the terraform state will be stored"
  default     = ""
}

variable "library_terraform_state_name" {
  description = "Optional name for the storage account where the terraform state will be stored"
  default     = ""
}

variable "library_terraform_state_account_tier" {
  description = "The storage account tier"
  default     = "Standard"
}

variable "library_terraform_state_account_replication_type" {
  description = "The replication type for the storage account"
  default     = "LRS"
}

variable "library_terraform_state_account_kind" {
  description = "The storage account kind"
  default     = "StorageV2"
}

variable "library_terraform_state_blob_container_is_existing" {
  description = "If defined use an existing blob container"
  default     = false
}

variable "library_terraform_state_blob_container_name" {
  description = "If defined, the blob container name to create"
  default     = "tfstate"
}

variable "library_ansible_blob_container_is_existing" {
  description = "If defined use an existing blob container"
  default     = false
}

variable "library_ansible_blob_container_name" {
  description = "If defined, the blob container name to create"
  default     = "ansible"
}


variable "use_private_endpoint" {
  description = "Boolean value indicating if private endpoint should be used for the deployment"
  default     = false
  type        = bool
}

#########################################################################################
#                                                                                       #
#  Miscallaneous definitioms                                                            #
#                                                                                       #
#########################################################################################


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
#  Web App definitioms                                                                  #
#                                                                                       #
#########################################################################################

variable "use_webapp" {
  description = "Boolean value indicating if a webapp should be created"
  default     = false
}


variable "Agent_IP" {
  description = "If provided, contains the IP address of the agent"
  type        = string
  default     = ""
}
