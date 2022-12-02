#########################################################################################
#                                                                                       #
#  Environment definitioms                                                              #
#                                                                                       #
#########################################################################################

variable "environment" {
  type        = string
  description = "This is the environment name of the deployer"
  default     = ""
}

variable "codename" {
  type    = string
  default = ""
}

variable "location" {
  description = "The Azure region for the resources"
  type        = string
  default     = ""
}

variable "name_override_file" {
  description = "If provided, contains a json formatted file defining the name overrides"
  default     = ""
}

#########################################################################################
#                                                                                       #
#  Resource Group variables                                                             #
#                                                                                       #
#########################################################################################

variable "resourcegroup_name" {
  description = "If provided, the name of the resource group to be created"
  default     = ""
}

variable "resourcegroup_arm_id" {
  description = "If provided, the Azure resource group id"
  default     = ""
}

variable "resourcegroup_tags" {
  description = "Tags to be applied to the resource group"
  default     = {}
}

#########################################################################################
#                                                                                       #
#  Virtual Network variables                                                            #
#                                                                                       #
#########################################################################################

variable "network_name" {
  description = "If provided, the name of the Virtual network"
  default     = ""
}

variable "network_logical_name" {
  description = "The logical name of the virtual network, used for resource naming"
  default     = ""
}

variable "network_address_space" {
  description = "The address space of the virtual network"
  default     = ""
}

variable "network_arm_id" {
  description = "If provided, the Azure resource id of the virtual network"
  default     = ""
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

variable "peer_with_control_plane_vnet" {
  description = "Defines in the SAP VNet will be peered with the controlplane VNet"
  type        = bool
  default     = true
}


#########################################################################################
#                                                                                       #
#  Admin Subnet variables                                                               #
#                                                                                       #
#########################################################################################

variable "admin_subnet_name" {
  description = "If provided, the name of the admin subnet"
  default     = ""
}

variable "admin_subnet_arm_id" {
  description = "If provided, Azure resource id for the admin subnet"
  default     = ""
}

variable "admin_subnet_address_prefix" {
  description = "The address prefix for the admin subnet"
  default     = ""
}

variable "admin_subnet_nsg_name" {
  description = "If provided, the name of the admin subnet NSG"
  default     = ""
}

variable "admin_subnet_nsg_arm_id" {
  description = "If provided, Azure resource id for the admin subnet NSG"
  default     = ""
}


#########################################################################################
#                                                                                       #
#  DB Subnet variables                                                               #
#                                                                                       #
#########################################################################################

variable "db_subnet_name" {
  description = "If provided, the name of the db subnet"
  default     = ""
}

variable "db_subnet_arm_id" {
  description = "If provided, Azure resource id for the db subnet"
  default     = ""
}

variable "db_subnet_address_prefix" {
  description = "The address prefix for the db subnet"
  default     = ""
}

variable "db_subnet_nsg_name" {
  description = "If provided, the name of the db subnet NSG"
  default     = ""
}

variable "db_subnet_nsg_arm_id" {
  description = "If provided, Azure resource id for the db subnet NSG"
  default     = ""
}


#########################################################################################
#                                                                                       #
#  App Subnet variables                                                                 #
#                                                                                       #
#########################################################################################

variable "app_subnet_name" {
  description = "If provided, the name of the app subnet"
  default     = ""
}

variable "app_subnet_arm_id" {
  description = "If provided, Azure resource id for the app subnet"
  default     = ""
}

variable "app_subnet_address_prefix" {
  description = "The address prefix for the app subnet"
  default     = ""
}

variable "app_subnet_nsg_name" {
  description = "If provided, the name of the app subnet NSG"
  default     = ""
}

variable "app_subnet_nsg_arm_id" {
  description = "If provided, Azure resource id for the app subnet NSG"
  default     = ""
}


#########################################################################################
#                                                                                       #
#  Web Subnet variables                                                                 #
#                                                                                       #
#########################################################################################

variable "web_subnet_name" {
  description = "If provided, the name of the web subnet"
  default     = ""
}

variable "web_subnet_arm_id" {
  description = "If provided, Azure resource id for the web subnet"
  default     = ""
}

variable "web_subnet_address_prefix" {
  description = "The address prefix for the web subnet"
  default     = ""
}

variable "web_subnet_nsg_name" {
  description = "If provided, the name of the web subnet NSG"
  default     = ""
}

variable "web_subnet_nsg_arm_id" {
  description = "If provided, Azure resource id for the web subnet NSG"
  default     = ""
}


#########################################################################################
#                                                                                       #
#  ANF Subnet variables                                                                 #
#                                                                                       #
#########################################################################################

variable "anf_subnet_name" {
  description = "If provided, the name of the ANF subnet"
  default     = ""
}

variable "anf_subnet_arm_id" {
  description = "If provided, Azure resource id for the ANF subnet"
  default     = ""
}

variable "anf_subnet_address_prefix" {
  description = "The address prefix for the ANF subnet"
  default     = ""
}

variable "anf_subnet_nsg_name" {
  default = ""
}

variable "anf_subnet_nsg_arm_id" {
  default = ""
}

#########################################################################################
#                                                                                       #
#  Key Vault variables                                                                  #
#                                                                                       #
#########################################################################################

variable "user_keyvault_id" {
  description = "If provided, the Azure resource identifier of the credentials keyvault"
  default     = ""
}

variable "spn_keyvault_id" {
  description = "If provided, the Azure resource identifier of the deployment credential keyvault"
  default     = ""
}

variable "enable_purge_control_for_keyvaults" {
  description = "Disables the purge protection for Azure keyvaults."
  default     = false
  type        = bool
}

variable "enable_rbac_authorization_for_keyvault" {
  description = "Enables RBAC authorization for Azure keyvault"
  default     = false
}

variable "additional_users_to_add_to_keyvault_policies" {
  description = "List of object IDs to add to key vault policies"
  default     = [""]
}

#########################################################################################
#                                                                                       #
#  Authentication variables                                                             #
#                                                                                       #
#########################################################################################

variable "automation_username" {
  description = "The username for the automation account"
  default     = "azureadm"
}

variable "automation_password" {
  description = "If provided, the password for the automation account"
  default     = ""
}

variable "automation_path_to_public_key" {
  description = "If provided, the path to the existing public key for the automation account"
  default     = ""
}

variable "automation_path_to_private_key" {
  description = "If provided, the path to the existing private key for the automation account"
  default     = ""
}

variable "use_spn" {
  description = "Log in using a service principal when performing the deployment"
  default     = true
}

#########################################################################################
#                                                                                       #
#  Storage Account variables                                                            #
#                                                                                       #
#########################################################################################

variable "diagnostics_storage_account_arm_id" {
  description = "If provided, Azure resource id for the diagnostics storage account"
  default     = ""
}

variable "witness_storage_account_arm_id" {
  description = "If provided, Azure resource id for the witness storage account"
  default     = ""
}


variable "transport_storage_account_id" {
  description = "Azure Resource Identifier for the Transport media storage account"
  type        = string
  default     = ""
}

variable "transport_private_endpoint_id" {
  description = "Azure Resource Identifier for an private endpoint connection"
  type        = string
  default     = ""
}

variable "transport_volume_size" {
  description = "The volume size in GB for the transport share"
  default     = 128
}

variable "install_storage_account_id" {
  description = "Azure Resource Identifier for the Installation media storage account"
  type        = string
  default     = ""
}

variable "install_volume_size" {
  description = "The volume size in GB for the transport share"
  default     = 1024
}

variable "install_private_endpoint_id" {
  description = "Azure Resource Identifier for an private endpoint connection"
  type        = string
  default     = ""
}

variable "Agent_IP" {
  description = "If provided, contains the IP address of the agent"
  type    = string
  default = ""
}


#########################################################################################
#                                                                                       #
#  DNS settings                                                                         #
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
  default     = ""
  type        = string
}


#########################################################################################
#                                                                                       #
#  ANF variables                                                                        #
#                                                                                       #
#########################################################################################

variable "ANF_account_arm_id" {
  description = "If provided, The resource identifier for the NetApp account"
  default     = ""
}

variable "ANF_account_name" {
  description = "If provided, the NetApp account name"
  default     = ""
}

variable "ANF_use_existing_pool" {
  description = "Use existing storage pool"
  default     = false
}

variable "ANF_pool_name" {
  description = "If provided, the NetApp capacity pool name (if any)"
  default     = ""
}

variable "ANF_service_level" {
  description = "The NetApp Service Level"
  default     = "Premium"
}

variable "ANF_pool_size" {
  description = "The NetApp Pool size in TB"
  default     = 4
}

variable "ANF_qos_type" {
  description = "The Quality of Service type of the pool (Auto or Manual)"
  default     = "Manual"
}
variable "ANF_transport_volume_use_existing" {
  description = "Use existing transport volume"
  default     = false
}

variable "ANF_transport_volume_name" {
  description = "If defined provides the Transport volume name"
  default     = false
}

variable "ANF_transport_volume_throughput" {
  description = "If defined provides the throughput of the transport volume"
  default     = 128
}

variable "ANF_transport_volume_size" {
  description = "If defined provides the size of the transport volume"
  default     = 128
}

variable "ANF_install_volume_use_existing" {
  description = "Use existing install volume"
  default     = false
}

variable "ANF_install_volume_name" {
  description = "Install volume name"
  default     = ""
}

variable "ANF_install_volume_throughput" {
  description = "If defined provides the throughput of the install volume"
  default     = 128
}

variable "ANF_install_volume_size" {
  description = "If defined provides the size of the install volume"
  default     = 1024
}

#########################################################################################
#                                                                                       #
#  iSCSI definitioms                                                                    #
#                                                                                       #
#########################################################################################

variable "iscsi_subnet_name" {
  description = "If provided, the name of the iSCSI subnet"
  default     = ""
}

variable "iscsi_subnet_arm_id" {
  description = "If provided, Azure resource id for the iSCSI subnet"
  default     = ""
}

variable "iscsi_subnet_address_prefix" {
  description = "The address prefix for the iSCSI subnet"
  default     = ""
}

variable "iscsi_subnet_nsg_name" {
  description = "If provided, the name of the iSCSI subnet NSG"
  default     = ""
}

variable "iscsi_subnet_nsg_arm_id" {
  description = "If provided, Azure resource id for the iSCSI subnet NSG"
  default     = ""
}

variable "iscsi_count" {
  description = "The number of iSCSI Virtual Machines to create"
  default     = 0
}

variable "iscsi_size" {
  description = "The size of the iSCSI Virtual Machine"
  default     = ""
}

variable "iscsi_useDHCP" {
  description = "value indicating if iSCSI Virtual Machine should use DHCP"
  default     = false
}

variable "iscsi_image" {
  description = "The virtual machine image for the iSCSI Virtual Machine"
  default = {
    "source_image_id" = ""
    "publisher"       = "SUSE"
    "offer"           = "sles-sap-15-sp3"
    "sku"             = "gen1"
    "version"         = "latest"
  }
}

variable "iscsi_authentication_type" {
  description = "iSCSI Virtual Machine authentication type"
  default     = "key"
}

variable "iscsi_authentication_username" {
  description = "User name for iSCSI Virtual Machine"
  default     = "azureadm"
}


variable "iscsi_nic_ips" {
  description = "IP addresses for the iSCSI Virtual Machine NICs"
  default     = []
}


#########################################################################################
#                                                                                       #
#  Workload VM definitions                                                              #
#                                                                                       #
#########################################################################################


variable "utility_vm_count" {
  description = "The number of utility_vmes to create"
  default     = 0
}

variable "utility_vm_size" {
  description = "The size of the utility_vm Virtual Machine"
  default     = "Standard_D4ds_v4"
}

variable "utility_vm_useDHCP" {
  description = "value indicating if utility_vm should use DHCP"
  default     = true
}

variable "utility_vm_image" {
  description = "The virtual machine image for the utility_vm Virtual Machine"
  default = {
    "os_type"         = "WINDOWS"
    "source_image_id" = ""
    "publisher"       = "MicrosoftWindowsServer"
    "offer"           = "windowsserver"
    "sku"             = "2019-datacenter"
    "version"         = "latest"
  }
}

variable "utility_vm_nic_ips" {
  description = "IP addresses for the utility_vm Virtual Machine NICs"
  default     = []
}
