variable "infrastructure" {
  description = "Details of the Azure infrastructure to deploy the SAP landscape into"
  default     = {}
  validation {
    condition = (
      length(trimspace(try(var.infrastructure.region, ""))) != 0
    )
    error_message = "The region must be specified in the infrastructure.region field."
  }

  validation {
    condition = (
      length(trimspace(try(var.infrastructure.environment, ""))) != 0
    )
    error_message = "The environment must be specified in the infrastructure.environment field."
  }

  validation {
    condition = (
      length(trimspace(try(var.infrastructure.vnets.sap.logical_name, ""))) != 0
    )
    error_message = "Please specify the logical VNet identifier in the infrastructure.vnets.sap.name field. For deployments prior to version '2.3.3.1' please use the identifier 'sap'."
  }

  validation {
    condition = (
      length(trimspace(try(var.infrastructure.vnets.sap.arm_id, ""))) != 0 || length(trimspace(try(var.infrastructure.vnets.sap.address_space, ""))) != 0
    )
    error_message = "Either the arm_id or (name and address_space) of the Virtual Network must be specified in the infrastructure.vnets.sap block."
  }
}

variable "options" {
  description = "Configuration options"
  default     = {}
}

variable "authentication" {
  description = "Details of ssh key pair"
  default = {
    username            = "azureadm",
    password            = ""
    path_to_public_key  = "",
    path_to_private_key = ""

  }

  validation {
    condition = (
      length(var.authentication) >= 1
    )
    error_message = "Either ssh keys or user credentials must be specified."
  }
  validation {
    condition = (
      length(trimspace(var.authentication.username)) != 0
    )
    error_message = "The default username for the Virtual machines must be specified."
  }
}

variable "key_vault" {
  description = "The user brings existing Azure Key Vaults"
  default = {
  }
  validation {
    condition = (
      contains(keys(var.key_vault), "kv_spn_id") ? (
        length(split("/", var.key_vault.kv_spn_id)) == 9) : (
        true
      )
    )
    error_message = "If specified, the kv_spn_id needs to be a correctly formed Azure resource ID."
  }
  validation {
    condition = (
      contains(keys(var.key_vault), "kv_user_id") ? (
        length(split("/", var.key_vault.kv_user_id)) == 9) : (
        true
      )
    )
    error_message = "If specified, the kv_user_id needs to be a correctly formed Azure resource ID."
  }

  validation {
    condition = (
      contains(keys(var.key_vault), "kv_prvt_id") ? (
        length(split("/", var.key_vault.kv_prvt_id)) == 9) : (
        true
      )
    )
    error_message = "If specified, the kv_prvt_id needs to be a correctly formed Azure resource ID."
  }


}

variable "diagnostics_storage_account" {
  description = "Storage account information for diagnostics account"
  default = {
    arm_id = ""
  }
}

variable "witness_storage_account" {
  description = "Storage account information for witness storage account"
  default = {
    arm_id = ""
  }
}

variable "deployment" {
  description = "The type of deployment"
  default     = "update"
}

variable "terraform_template_version" {
  description = "The version of Terraform templates that were identified in the state file"
  default     = ""
}

variable "deployer_tfstate" {
  description = "Deployer remote tfstate file"
}

variable "service_principal" {
  description = "Current service principal used to authenticate to Azure"
}

variable "naming" {
  description = "Defines the names for the resources"
}

variable "use_deployer" {
  description = "Use the deployer"
}

variable "ANF_settings" {
  description = "ANF settings"
  default = {
    use           = false
    name          = ""
    arm_id        = ""
    service_level = "Standard"
    size_in_tb    = 4

  }
}

variable "enable_purge_control_for_keyvaults" {
  description = "Allow the deployment to control the purge protection"
}

variable "dns_label" {
  description = "DNS label"
  default     = ""
}

variable "dns_resource_group_name" {
  description = "DNS resource group name"
  default     = ""
}

variable "use_private_endpoint" {
  type        = bool
  description = "Private endpoint"
  default     = false
}

variable "transport_volume_size" {
  description = "The volume size in GB for transport volume"
}

variable "install_volume_size" {
  description = "The volume size in GB for install volume"
}


variable "transport_storage_account_id" {
  description = "Azure Resource Identifier for an existing storage account"
  type        = string
}

variable "transport_private_endpoint_id" {
  description = "Azure Resource Identifier for an private endpoint connection"
  type        = string
}

variable "install_storage_account_id" {
  description = "Azure Resource Identifier for an existing storage account"
  type        = string
}

variable "install_private_endpoint_id" {
  description = "Azure Resource Identifier for an private endpoint connection"
  type        = string
  default = ""
}

variable "NFS_provider" {
  description = "Describes the NFS solution used"
  type        = string
}

variable "Agent_IP" {
  type    = string
  default = ""
}

variable "enable_rbac_authorization_for_keyvault" {
  description = "Enables RBAC authorization for Azure keyvault"
}
