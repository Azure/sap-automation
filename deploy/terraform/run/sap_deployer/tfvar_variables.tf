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
  default = ""
  type    = string
}

variable "location" {
  description = "Defines the Azure location where the resources will be deployed"
  type = string
}

###############################################################################
#                                                                             # 
#                             Resource Group                                  # 
#                                                                             # 
###############################################################################


variable "resourcegroup_name" {
  description = "If defined, the name of the resource group into which the resources will be deployed"
  default = ""
}

variable "resourcegroup_arm_id" {
  description = "Azure resource identifier for the resource group into which the resources will be deployed"
  default = ""
}

variable "resourcegroup_tags" {
  description = "tags to be added to the resource group"
  default = {}
}

###############################################################################
#                                                                             # 
#                            Network                                          # 
#                                                                             # 
###############################################################################

variable "management_network_name" {
  description = "The name of the VNet into which the deployer will be deployed"
  default = ""
}

variable "management_network_logical_name" {
  description = "The logical name of the VNet, used for naming purposes"
  default = ""
}

variable "management_network_arm_id" {
  description = "Azure resource identifier for the existing VNet into which the deployer will be deployed"
  default = ""
}

variable "management_network_address_space" {
  description = "The address space of the VNet into which the deployer will be deployed"
  default = ""
}

###############################################################################
#                                                                             # 
#                            Management Subnet                                # 
#                                                                             # 
###############################################################################

variable "management_subnet_name" {
  description = "The name of the subnet into which the deployer will be deployed"
  default = ""
}

variable "management_subnet_arm_id" {
  description = "Azure resource identifier for the existing subnet into which the deployer will be deployed"
  default = ""
}

variable "management_subnet_address_prefix" {
  description = "The address prefix of the subnet into which the deployer will be deployed"
  default = ""
}

###############################################################################
#                                                                             # 
#                            Firewall                                         # 
#                                                                             # 
###############################################################################

variable "management_firewall_subnet_arm_id" {
  description = "Azure resource identifier for the existing subnet into which the firewall will be deployed"
  default = ""
}

variable "management_firewall_subnet_address_prefix" {
  description = "value of the address prefix of the subnet into which the firewall will be deployed"
  default = ""
}


variable "firewall_deployment" {
  description = "Boolean flag indicating if an Azure Firewall should be deployed"
  default     = false
  type = bool
}

variable "firewall_rule_subnets" {
  description = "List of subnets that are part of the firewall rule"
  default     = null
}

variable "firewall_allowed_ipaddresses" {
  description = "List of allowed IP addresses to be part of the firewall rule"
  default     = null
}

###############################################################################
#                                                                             # 
#                            Bastion                                          # 
#                                                                             # 
###############################################################################

variable "management_bastion_subnet_arm_id" {
  description = "Azure resource identifier Azure Bastion subnet"
  default = ""
}

variable "management_bastion_subnet_address_prefix" {
  description = "Subnet adress range for the bastion subnet"
  default = ""
}


variable "bastion_deployment" {
  description = "Boolean flag indicating if an Azure bastion should be deployed"
  default     = false
}

###############################################################################
#                                                                             # 
#                            Management NSG                                   # 
#                                                                             # 
###############################################################################

variable "management_subnet_nsg_name" {
  description = "The name of the network security group"
  default = ""
}

variable "management_subnet_nsg_arm_id" {
  description = "value of the Azure resource identifier for the network security group"
  default = ""
}

variable "management_subnet_nsg_allowed_ips" {
  default = []
}

variable "deployer_enable_public_ip" {
  description = "value to enable/disable public ip"
  default = false
  type = bool
}

###############################################################################
#                                                                             # 
#                            Deployer Information                             # 
#                                                                             # 
###############################################################################

variable "deployer_size" {
  description = "The size of the deployer VM"
  default = ""
}

variable "deployer_count" {
  description = "Number of deployer VMs to be created"
  default = 1
}

variable "deployer_disk_type" {
  description = "The type of the disk for the deployer VM"
  default = "Premium_LRS"
}

variable "deployer_use_DHCP" {
  description = "If true, the deployers will use Azure Provided IP addresses"
  default = false
}

variable "deployer_image" {
  default = {
    "source_image_id" = ""
    "publisher"       = "Canonical"
    "offer"           = "UbuntuServer"
    "sku"             = "18.04-LTS"
    "version"         = "latest"
  }
}

variable "deployer_private_ip_address" {
  default = ""
}


###############################################################################
#                                                                             # 
#                            Deployer authentication                          # 
#                                                                             # 
###############################################################################

variable "deployer_authentication_type" {
  default = "key"
}

variable "deployer_authentication_username" {
  default = "azureadm"
}

variable "deployer_authentication_password" {
  default = ""
}

variable "deployer_authentication_path_to_public_key" {
  default = ""
}

variable "deployer_authentication_path_to_private_key" {
  default = ""
}

variable "user_keyvault_id" {
  description = "Azure resource identifier for the deployment credentials Azure Key Vault"
  default = ""
}

variable "deployer_private_key_secret_name" {
  description = "Defines the name of the secret in the Azure Key Vault that contains the private key"
  default = ""
}
variable "deployer_public_key_secret_name" {
  description = "Defines the name of the secret in the Azure Key Vault that contains the public key"
  default = ""
}

variable "deployer_username_secret_name" {
  description = "Defines the name of the secret in the Azure Key Vault that contains the user name"
  default = ""
}

variable "deployer_password_secret_name" {
  description = "Defines the name of the secret in the Azure Key Vault that contains the password"
  default = ""
}

variable "enable_purge_control_for_keyvaults" {
  description = "Disables the purge protection for Azure keyvaults. USE THIS ONLY FOR TEST ENVIRONMENTS"
  default = true
  type = bool
}


#########################################################################################
#                                                                                       #
#  Miscallaneous settings                                                               #
#                                                                                       #
#########################################################################################

variable "deployer_assign_subscription_permissions" {
  description = "Boolean flag indicating if the subscription permissions should be assigned"
  default = false
  type = bool
}

variable "use_private_endpoint" {
  description = "Boolean value indicating if private endpoint should be used for the deployment"
  default = false
  type = bool
}


variable "deployer_diagnostics_account_arm_id" {
  description = "Azure resource identifier for an existing storage accout that will be used for diagnostic logs"
  default = ""
}


variable "tf_version" {
  description = "Terraform version to install on deployer"
  default = "1.1.7"
}

variable "name_override_file" {
  description = "If provided, contains a json formatted file defining the name overrides"
  default     = ""
}

variable "auto_configure_deployer" {
  description = "Value indicating if the deployer should be configured automatically"
  default     = true
}


#########################################################################################
#                                                                                       #
#  ADO definitioms                                                                      #
#                                                                                       #
#########################################################################################

variable "agent_pool" {
  description = "If provided, contains the name of the agent pool to be used"
  default     = ""
}

variable "agent_pat" {
  description = "If provided, contains the Personal Access Token to be used"
  default     = ""
}

variable "agent_ado_url" {
  description = "If provided, contains the Url to the ADO repository"
  default     = ""
}
