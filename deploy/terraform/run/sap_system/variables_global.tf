variable "application_tier" {
  description = "Details of the Application layer"
  default = {
    enable_deployment        = true
    use_DHCP                 = false
    application_server_count = 0
    dual_nics                = false
  }

}

variable "databases" {
  description = "Details of the database node"
  default = [
    {
      use_DHCP = false

    }
  ]

}

variable "infrastructure" {
  description = "Details of the Azure infrastructure to deploy the SAP landscape into"
  default     = {}

}

variable "options" {
  description = "Configuration options"
  default = {
    resource_offset   = 0
    nsg_asg_with_vnet = false
    legacy_nic_order  = false
  }
}

variable "ssh-timeout" {
  description = "Timeout for connection that is used by provisioner"
  default     = "30s"
}

variable "key_vault" {
  description = "Details of keyvault"
  default     = {}

}

variable "authentication" {
  description = "Defining the SDU credentials"
  default = {
  }
}

variable "api-version" {
  description = "IMDS API Version"
  default     = "2019-04-30"
}

variable "auto-deploy-version" {
  description = "Version for automated deployment"
  default     = "v2"
}

variable "scenario" {
  description = "Deployment Scenario"
  default     = "HANA Database"
}

variable "tfstate_resource_id" {
  description = "Resource id of tfstate storage account"
  validation {
    condition = (
      length(split("/", var.tfstate_resource_id)) == 9
    )
    error_message = "The Azure Resource ID for the storage account containing the Terraform state files must be provided and be in correct format."
  }

}

variable "deployer_tfstate_key" {
  description = "The key of deployer's remote tfstate file"
  default     = ""
}

variable "landscape_tfstate_key" {
  description = "The key of sap landscape's remote tfstate file"

  validation {
    condition = (
      length(trimspace(try(var.landscape_tfstate_key, ""))) != 0
    )
    error_message = "The Landscape state file name must be specified."
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

variable "license_type" {
  description = "Specifies the license type for the OS"
  default     = ""
}

variable "use_zonal_markers" {
  type    = bool
  default = true
}
