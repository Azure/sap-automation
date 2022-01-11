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
  default = "70000000-0000-0000-0000-000000000000"
}
variable "app_registration_app_id" {}
variable "random_int" {}
variable "cmdb_connection_string" {}
