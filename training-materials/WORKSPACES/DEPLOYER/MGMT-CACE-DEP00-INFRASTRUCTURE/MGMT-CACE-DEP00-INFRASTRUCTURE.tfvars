##########################################################################################
#                                                                                        #
# This sample defines an standard control plane deployment with                          #
#      1 Deployer (deployer_count = 1)                                                   #
#      Azure Firewall (firewall_deployment = true)                                       #
#      Azure Bastion (bastion_deployment = true)                                         #
#                                                                                        #
##########################################################################################

# The automation supports both creating resources (greenfield) or using existing resources (brownfield)
# For the greenfield scenario the automation defines default names for resources, 
# if there is a XXXXname variable then the name is customizable 
# for the brownfield scenario the Azure resource identifiers for the resources must be specified

#########################################################################################
#                                                                                       #
#  Environment definitioms                                                              #
#                                                                                       #
#########################################################################################
environment = "MGMT"
# The location/region value is a mandatory field, it is used to control where the resources are deployed
location = "canadacentral"

# RESOURCEGROUP
# The two resource group name and arm_id can be used to control the naming and the creation of the resource group
# The resourcegroup_name value is optional, it can be used to override the name of the resource group that will be provisioned
# The resourcegroup_name arm_id is optional, it can be used to provide an existing resource group for the deployment
#resourcegroup_name=""
#resourcegroup_arm_id=""

resourcegroup_tags = {
  Control_plane = "Canada Central"
}

#########################################################################################
#                                                                                       #
#  Networking                                                                           #
#                                                                                       #
#########################################################################################
# The deployment automation supports two ways of providing subnet information.
# 1. Subnets are defined as part of the workload zone  deployment
#    In this model multiple SAP System share the subnets
# 2. Subnets are deployed as part of the SAP system
#    In this model each SAP system has its own sets of subnets
#
# The automation supports both creating the subnets (greenfield) or using existing subnets (brownfield)
# For the greenfield scenario the subnet address prefix must be specified whereas
# for the brownfield scenario the Azure resource identifier for the subnet must be specified


#management_network_name=""
management_network_logical_name = "DEP00"
#management_network_arm_id=""
management_network_address_space = "10.17.20.0/24"

# management subnet
# If defined these parameters control the subnet name and the subnet prefix
# management_subnet_name is an optional parameter and should only be used if the default naming is not acceptable 
#management_subnet_name=""

# management_subnet_address_prefix is a mandatory parameter if the subnets are not defined in the workload or if existing subnets are not used
management_subnet_address_prefix = "10.17.20.64/28"
# management_subnet_arm_id is an optional parameter that if provided specifies Azure resource identifier for the existing subnet to use
#management_subnet_arm_id="/subscriptions/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx/resourceGroups/MGMT-WEEU-MGMT01-INFRASTRUCTURE/providers/Microsoft.Network/virtualNetworks/MGMT-WEEU-MGMT01-vnet/subnets/MGMT-WEEU-MGMT01-subnet_management"

# management_subnet_nsg_arm_id is an optional parameter that if provided specifies Azure resource identifier for the existing network security group to use
#management_subnet_nsg_arm_id="/subscriptions/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx/resourceGroups/MGMT-WEEU-MGMT01-INFRASTRUCTURE/providers/Microsoft.Network/networkSecurityGroups/MGMT-WEEU-SAP01_managementSubnet-nsg"

# management_subnet_nsg_allowed_ips is an optional parameter that if provided specifies a list of allowed IP ranges for the NSG

#########################################################################################
#                                                                                       #
#                                   Azure Firewall                                      #
#                                                                                       #
#########################################################################################

# firewall_deployment is a boolean flag controlling if an Azure firewall is to be deployed in the deployer VNet
firewall_deployment = true

# management_firewall_subnet_arm_id is an optional parameter that if provided specifies 
# Azure resource identifier for the existing firewall subnet
# management_firewall_subnet_arm_id= ""

# management_firewall_subnet_address_prefix is a mandatory parameter 
management_firewall_subnet_address_prefix = "10.17.20.0/26"

# firewall_rule_subnets is an optional list of subnets to be added to the Azure firewall
#firewall_rule_subnets=[]

# firewall_rule_allowed_ipaddresses is an optional list of IP Addresses to be added to the Azure firewall
#firewall_rule_allowed_ipaddresses=[]

#########################################################################################
#                                                                                       #
#                                   Azure Bastion                                       #
#                                                                                       #
#########################################################################################

# bastion_deployment is a boolean flag controlling if Azure bastion is to be deployed in the deployer VNet
bastion_deployment = true

# management_bastion_subnet_arm_id is an optional parameter that if provided specifies Azure resource 
# identifier for the existing AzureBastion subnet
# management_bastion_subnet_arm_id= ""

#management_bastion_subnet_address_prefix is a mandatory parameter if bastion is deployed and if the subnets are not defined in the workload or if existing subnets are not used
management_bastion_subnet_address_prefix = "10.17.20.128/26"

#########################################################################################
#                                                                                       #
#                            Deployer VM information                                    #
#                                                                                       #
#########################################################################################

# deployer_enable_public_ip defines if the deployers will be deployed with a public IP address
deployer_enable_public_ip = false

# deployer_count is an optional parameter that specifies the number of deployer VMs to be provisioned
#deployer_count=1

# deployer_size is optional and defines the virtual machine SKU
#deployer_size="Standard_D4ds_v4"

# deployer_disk_type is optional and defines the virtual machine disk type
#deployer_disk_type"="Premium_LRS"

# deployer_use_DHCP is a boolean flag controlling if Azure subnet provided IP addresses should be used (true)
deployer_use_DHCP = true

# private_ip_address if defined will provide the IP addresses for the network interface cards 
#private_ip_address=[""]

#
# The deployer_image defines the Virtual machine image to use, if source_image_id is specified the deployment will use the custom image provided, in this case os_type must also be specified

deployer_image = {
  "os_type"         = "Linux"
  "source_image_id" = ""
  "publisher"       = "Canonical"
  "offer"           = "0001-com-ubuntu-server-focal"
  "sku"             = "20_04-lts-gen2"
  "version"         = "latest"
}
# deployer_diagnostics_account_arm_id defines the diagnosting storage account for the deployer
# deployer_diagnostics_account_arm_id = ""

# deployer_authentication_type defines the authentication type for the deployer virtual machine 
#deployer_authentication_type="key"

# deployer_authentication_username defines the username for the deployer virtual machine
deployer_authentication_username = "azureadm"

# deployer_authentication_password if defined is the password for the deployer virtual machine
#deployer_authentication_password=""

# deployer_authentication_path_to_public_key if defined is the path to the file containing the public key for the deployer virtual machine
#deployer_authentication_path_to_public_key=""

# deployer_authentication_path_to_private_key if defined is the path to the file containing the private key for the deployer virtual machine
#deployer_authentication_path_to_private_key=""


#########################################################################################
#                                                                                       #
#                            Deployer VM information                                    #
#                                                                                       #
#########################################################################################

# These variables define the keyvault that is used to store the deployer credentials
# user_keyvault_id is the Azure resource identifier for the keyvault that will contain the credentials keys
#user_keyvault_id=""

# deployer_private_key_secret_name if provided contains the secret name for the private key 
#deployer_private_key_secret_name=""

# deployer_public_key_secret_name if provided contains the secret name for the public key 
#deployer_public_key_secret_name=""

# deployer_username_secret_name if provided contains the secret name for the username 
#deployer_username_secret_name=""

# deployer_password_secret_name if provided contains the secret name for the password 
#deployer_password_secret_name=""


#########################################################################################
#                                                                                       #
#                            Miscallaneous settings                                     #
#                                                                                       #
#########################################################################################

# deployer_assign_subscription_permissions is a boolean flag controlling if the deployment credential should be assigned Contribuor permissions on the subscription
deployer_assign_subscription_permissions=false

# use_private_endpoint is a boolean flag controlling if the keyvaults and storage accounts have private endpoints
# use_private_endpoint=false

# auto_configure_deployer is a boolean flag controlling if the automation should try to configure the deployer automatically
# set to false if outbound internet on the deployer is not available
auto_configure_deployer = true
