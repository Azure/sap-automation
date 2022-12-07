variable "infrastructure" {
  description = "Details of the Azure infrastructure to deploy the SAP library into"
  default     = {}
}

variable "storage_account_sapbits" {
  description = "Details of the Storage account for storing sap bits"
  default     = {}
}
variable "storage_account_tfstate" {
  description = "Details of the Storage account for storing tfstate"
  default     = {}
}
variable "software" {
  description = "Details of software, downloader etc."
  default     = {}
}
variable "deployer" {
  description = "Details of deployer"
  default     = {}
}

variable "key_vault" {
  description = "Import existing Azure Key Vaults"
  default     = {}
}

variable "deployer_tfstate_key" {
  description = "The key of deployer's remote tfstate file"
  default     = ""
}

variable "deployment" {
  description = "The type of deployment"
  default     = "update"
}

variable "terraform_template_version" {
  description = "The version of Terraform templates that were identified in the state file"
  default     = ""
}

variable "dns_label" {
  description = "DNS label"
  default     = ""
}


variable "tfstate_resource_id" {
  description = "The resource id of tfstate storage account"
  validation {
    condition = (
      length(split("/", var.tfstate_resource_id)) == 9
    )
    error_message = "The Azure Resource ID for the storage account containing the Terraform state files must be provided and be in correct format."
  }

}

