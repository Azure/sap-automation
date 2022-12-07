
variable "infrastructure" {}
variable "options" {}
variable "ssh-timeout" {}
variable "authentication" {}

#########################################################################################
#                                                                                       #
#  KeyVault                                                                             #
#                                                                                       #
#########################################################################################

variable "key_vault" {
  description = "The user brings existing Azure Key Vaults"
  default     = ""
}

variable "additional_users_to_add_to_keyvault_policies" {
  description = "List of object IDs to add to key vault policies"
}


variable "enable_purge_control_for_keyvaults" {
  description = "Disables the purge protection for Azure keyvaults."
}

#########################################################################################
#                                                                                       #
#  Web App                                                                              #
#                                                                                       #
#########################################################################################

variable "use_webapp" {
  default = false
}
variable "app_registration_app_id" {}
variable "sa_connection_string" {}
variable "webapp_client_secret" {}


variable "naming" {
  description = "naming convention"
}

variable "firewall_deployment" {
  description = "Boolean flag indicating if an Azure Firewall should be deployed"
  type        = bool
}

variable "assign_subscription_permissions" {
  description = "Assign permissions on the subscription"
  type        = bool
}

variable "bootstrap" {
  description = "Which phase of deployment"
  type        = bool

}

variable "use_private_endpoint" {
  description = "Boolean value indicating if private endpoint should be used for the deployment"
  default     = false
  type        = bool
}

variable "use_service_endpoint" {
  description = "Boolean value indicating if service endpoints should be used for the deployment"
  default     = false
  type        = bool
}


variable "enable_firewall_for_keyvaults_and_storage" {
  description = "Boolean value indicating if firewall should be enabled for key vaults and storage"
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

variable "configure" {
  description = "Value indicating if deployer should be configured"
  default     = false
}

variable "tf_version" {
  description = "Terraform version to install on deployer"
  default     = ""
}

variable "bastion_deployment" {
  description = "Value indicating if Azure Bastion should be deployed"
  default     = false
}

###############################################################################
#                                                                             #
#                            Deployer Information                             #
#                                                                             #
###############################################################################

variable "deployer" {}


variable "auto_configure_deployer" {
  description = "Value indicating if the deployer should be configured automatically"
  default     = true
}


variable "deployer_vm_count" {
  description = "Number of deployer VMs to create"
  type        = number
  default     = 1
}

variable "arm_client_id" {
  default = ""
}

#########################################################################################
#                                                                                       #
#  ADO definitioms                                                                      #
#                                                                                       #
#########################################################################################

variable "agent_pool" {
  description = "If provided, contains the name of the agent pool to be used"
}

variable "agent_pat" {
  description = "If provided, contains the Personal Access Token to be used"
}

variable "agent_ado_url" {
  description = "If provided, contains the Url to the ADO repository"
}

variable "ansible_core_version" {
  description = "If provided, the version of ansible core to be installed"
  default     = "2.13"
}

variable "Agent_IP" {
  description = "If provided, contains the IP address of the agent"
  type    = string
  default = ""
}
