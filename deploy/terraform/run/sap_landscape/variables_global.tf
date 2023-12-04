#######################################4#######################################8
#                                                                              #
#                              Variable definitioms                            #
#                                                                              #
#######################################4#######################################8

variable "tfstate_resource_id"         {
                                         description = "Resource id of tfstate storage account"
                                         validation {
                                                      condition     = (
                                                                        length(split("/", var.tfstate_resource_id)) == 9
                                                                      )
                                                      error_message = "The Azure Resource ID for the storage account containing the Terraform state files must be provided and be in correct format."
                                                    }
                                       }

variable "deployer_tfstate_key"        { description                          = "The key of deployer's remote tfstate file" }

variable "NFS_provider"                {
                                         type    = string
                                         default = "NONE"
                                       }

variable "infrastructure"              {
                                         description = "Details of the Azure infrastructure to deploy the SAP landscape into"
                                         default     = {}
                                       }

variable "options"                     {
                                         description = "Configuration options"
                                         default     = {}
                                       }

variable "authentication"              {
                                         description = "Details of ssh key pair"
                                         default = {
                                                     username            = "azureadm",
                                                     path_to_public_key  = "",
                                                     path_to_private_key = ""
                                                   }
                                       }

variable "key_vault"                   {
                                         description = "The user brings existing Azure Key Vaults"
                                         default     = { }
                                       }

variable "diagnostics_storage_account" {
                                         description = "Storage account information for diagnostics account"
                                        default      = {
                                                         arm_id = ""
                                                       }
                                       }

variable "witness_storage_account"     {
                                        description = "Storage account information for witness storage account"
                                        default     = {
                                                        arm_id = ""
                                                      }
                                       }

variable "deployment"                  {
                                         description = "The type of deployment"
                                         default     = "update"
                                       }

variable "terraform_template_version"  {
                                         description = "The version of Terraform templates that were identified in the state file"
                                         default     = ""
                                       }

variable "dns_label"                   {
                                         description = "DNS label"
                                         default     = ""
                                       }
