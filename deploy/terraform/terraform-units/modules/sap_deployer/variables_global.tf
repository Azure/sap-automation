/*
Description:

  Define input variables.
*/

variable "infrastructure" {}
variable "deployer" {}
variable "options" {}
variable "ssh-timeout" {}
variable "authentication" {}
variable "key_vault" {
  description = "The user brings existing Azure Key Vaults"
  default     = ""
}


variable "arm_client_id" {
  default = ""
}

