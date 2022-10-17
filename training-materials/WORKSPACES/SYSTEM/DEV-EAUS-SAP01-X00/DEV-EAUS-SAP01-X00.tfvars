##########################################################################################
#                                                                                        #
# Deployment topologies                                                                  #
#                                                                                        #
# Standard (All roles on same server)                                                    #
#  Define the database tier values and set enable_app_tier_deployment to false           #
#                                                                                        #
# Distributed (1+1 or 1+1+N)                                                             #
#  Define the database tier values and define scs_server_count = 1,                      #
#  application_server_count >= 1                                                         #
#                                                                                        #
# High Availability                                                                      #
#  Define the database tier values and database_high_availability = true                 #
#  scs_server_count = 1 and scs_high_availability = true                                 #
#  application_server_count >= 1                                                         #
#                                                                                        #
##########################################################################################

##########################################################################################
#                                                                                        #
# This sample defines an Distributed deployment                                          #
#                                                                                        #
##########################################################################################

# The automation supports both creating resources (greenfield) or using existing resources (brownfield)
# For the greenfield scenario the automation defines default names for resources, 
# if there is a XXXXname variable then the name is customizable 
# for the brownfield scenario the Azure resource identifiers for the resources must be specified

#########################################################################################
#                                                                                       #
#  Environment definitions                                                              #
#                                                                                       #
#########################################################################################

# The environment value is a mandatory field, it is used for partitioning the environments, for example (PROD and NP)
environment = "DEV"

# The location value is a mandatory field, it is used to control where the resources are deployed
location = "eastus"

#If you want to customize the disk sizes for VMs use the following parameter to specify the custom sizing file.
#custom_disk_sizes_filename = ""

#If you want to provide a custom naming json use the following parameter.
#name_override_file = ""

# save_naming_information,defines that a json formatted file defining the resource names will be created
#save_naming_information = false

# custom_prefix defines the prefix that will be added to the resource names
#custom_prefix = ""

# use_prefix defines if a prefix will be added to the resource names
use_prefix = true

# use_secondary_ips controls if the virtual machines should be deployed with two IP addresses. Required for SAP Virtual Hostname support
use_secondary_ips = false

# subscription is the subscription in which the system will be deployed (informational only)
#subscription = ""

# bom_name is the name of the SAP Bill of Materials file
#bom_name = ""


#########################################################################################
#                                                                                       #
#  Networking                                                                           #
#  By default the networking is defined in the workload zone                            #
#  Only use this section if the SID needs unique subnets/NSGs                           #
#                                                                                       #
# The deployment automation supports two ways of providing subnet information.          #
# 1. Subnets are defined as part of the workload zone  deployment                       #
#    In this model multiple SAP System share the subnets                                #
# 2. Subnets are deployed as part of the SAP system                                     #
#    In this model each SAP system has its own sets of subnets                          # 
#                                                                                       #
# The automation supports both creating the subnets (greenfield)                        #
# or using existing subnets (brownfield)                                                #
# For the greenfield scenario the subnet address prefix must be specified whereas       #
# for the brownfield scenario the Azure resource identifier for the subnet must         #
# be specified                                                                          #
#                                                                                       #
#########################################################################################

# The network logical name is mandatory - it is used in the naming convention and should map to the workload virtual network logical name 
network_logical_name = "SAP01"

# use_loadbalancers_for_standalone_deployments is a boolean flag that can be used to control if standalone deployments (non HA) will have load balancers
#use_loadbalancers_for_standalone_deployments = false

# use_private_endpoint is a boolean flag controlling if the key vaults and storage accounts have private endpoints
#use_private_endpoint = false

#########################################################################################
#                                                                                       #
#  Database tier                                                                        #                                                                                       #
#                                                                                       #
#########################################################################################

database_sid = "HDB"

# database_platform defines the database backend, supported values are
# - HANA
# - DB2
# - ORACLE
# - ASE
# - SQLSERVER
# - NONE (in this case no database tier is deployed)
database_platform = "HANA"

# Defines the number of database servers
database_server_count = 1

# database_high_availability is a boolean flag controlling if the database tier is deployed highly available (more than 1 node)
#database_high_availability = false

# For M series VMs use the SKU name for instance "M32ts"
# If using a custom disk sizing populate with the node name for Database you have used in the file custom_disk_sizes_filename
database_size = "S4Demo"

# database_instance_number if provided defines the instance number of the HANA database
#database_instance_number = ""

# database_vm_use_DHCP is a boolean flag controlling if Azure subnet provided IP addresses should be used (true)
database_vm_use_DHCP = true

# Optional, Defines if the database server will have two network interfaces
#database_dual_nics = false

# database_vm_db_nic_ips, if provided provides the static IP addresses 
# for the network interface cards connected to the database subnet
#database_vm_db_nic_ips = []

# database_vm_db_nic_secondary_ips, if provided provides the secondary static IP addresses 
# for the network interface cards connected to the application subnet
#database_vm_db_nic_secondary_ips = []

# database_vm_admin_nic_ips, if provided provides the static IP addresses 
# for the network interface cards connected to the admin subnet
#database_vm_admin_nic_ips = []

# database_loadbalancer_ips defines the load balancer IP addresses for the database tier's load balancer.
#database_loadbalancer_ips = []

# database_vm_admin_nic_ips, if provided provides the static IP addresses 
# for the network interface cards connected to the storage subnet
#database_vm_storage_nic_ips = []

# Sample Images for different database backends

# Oracle
#database_vm_image={
#  source_image_id=""
#  publisher="Oracle"
#  offer= "Oracle-Linux",
#  sku= "82-gen2",
#  version="latest"
#  type = "source_image" # [custom, marketplace, source_image]
#}

#SUSE 15 SP3
#database_vm_image = {
#  os_type         = ""
#  source_image_id = ""
#  publisher       = "SUSE"
#  offer           = "sles-sap-15-sp3"
#  sku             = "gen2"
#  version         = "latest"
#  type = "source_image" # [custom, marketplace, source_image]
#}

#RedHat
#database_vm_image={
#  os_type="linux"
#  source_image_id=""
#  publisher="RedHat"
#  offer="RHEL-SAP-HA"
#  sku="82sapha-gen2"
#  version="8.2.2021040902"
#  type = "source_image" # [custom, marketplace, source_image]
#}

# The vm_image defines the Virtual machine image to use, 
# if source_image_id is specified the deployment will use the custom image provided, 
# in this case os_type must also be specified

database_vm_image = {
  os_type         = "linux",
  source_image_id = "",
  publisher       = "SUSE",
  offer           = "sles-sap-15-sp3",
  sku             = "gen2",
  version         = "latest"
  type            = "source_image" # [custom, marketplace, source_image]
}

# database_vm_zones is an optional list defining the availability zones to deploy the database servers
database_vm_zones = ["1"]

# Optional, Defines the default authentication model for the Database VMs (key/password)
#database_vm_authentication_type = ""

# Optional, Defines the list of availability sets to deployt the Database VMs in
#database_vm_avset_arm_ids = []

# Optional, Defines the that the database virtual machines will not be placed in a proximity placement group
#database_no_ppg = false

# Optional, Defines the that the database virtual machines will not be placed in an availability set
#database_no_avset = false

# Optional, Defines if the tags for the database virtual machines
#database_tags = null

#database_HANA_use_ANF_scaleout_scenario = ""

#########################################################################################
#                                                                                       #
#  Application tier                                                                        #                                                                                       #
#                                                                                       #
#########################################################################################
# app_tier_sizing_dictionary_key defines the VM SKU and the disk layout for the application tier servers.
app_tier_sizing_dictionary_key = "Optimized"

# enable_app_tier_deployment is a boolean flag controlling if the application tier should be deployed
enable_app_tier_deployment = true

# app_tier_use_DHCP is a boolean flag controlling if Azure subnet provided IP addresses should be used (true)
app_tier_use_DHCP = true

# sid is a mandatory field that defines the SAP Application SID
sid = "X00"

#########################################################################################
#                                                                                       #
#  SAP Central Services                                                                 #
#                                                                                       #
#########################################################################################

# scs_server_count defines how many SCS servers to deploy
scs_server_count = 1

# scs_high_availability is a boolean flag controlling if SCS should be highly available
scs_high_availability = false

# scs_instance_number
#scs_instance_number = ""

# ers_instance_number
#ers_instance_number = ""

# scs_server_zones is an optional list defining the availability zones to which deploy the SCS servers
scs_server_zones = ["1"]

# scs_server_sku, if defined provides the SKU to use for the SCS servers
#scs_server_sku = ""

# The vm_image defines the Virtual machine image to use for the application servers, 
# if source_image_id is specified the deployment will use the custom image provided, 
# in this case os_type must also be specified
scs_server_image = {
  os_type         = "linux",
  source_image_id = "",
  publisher       = "SUSE",
  offer           = "sles-sap-15-sp3",
  sku             = "gen2",
  version         = "latest"
  type            = "source_image" # [custom, marketplace, source_image]
}

# scs_server_no_ppg defines the that the SCS virtual machines will not be placed in a proximity placement group
#scs_server_no_ppg = false

# scs_server_no_avset defines the that the SCS virtual machines will not be placed in an availability set
#scs_server_no_avset = false

# scs_server_app_nic_ips, if provided provides the static IP addresses 
# for the network interface cards connected to the application subnet
#scs_server_app_nic_ips = []

# scs_server_nic_secondary_ips, if provided provides the secondary static IP addresses 
# for the network interface cards connected to the application subnet
#scs_server_nic_secondary_ips = []

# scs_server_app_admin_nic_ips, if provided provides the static IP addresses 
# for the network interface cards connected to the application subnet
#scs_server_admin_nic_ips = []

# scs_server_loadbalancer_ips, if provided provides the static IP addresses for the load balancer
# for the network interface cards connected to the application subnet
#scs_server_loadbalancer_ips = []

# scs_server_tags, if defined provides the tags to be associated to the application servers
#scs_server_tags = null

#########################################################################################
#                                                                                       #
#  Application Servers                                                                  #
#                                                                                       #
#########################################################################################

# application_server_count defines how many application servers to deploy
application_server_count = 2

# application_server_zones is an optional list defining the availability zones to which deploy the application servers
#application_server_zones = []

# application_server_sku, if defined provides the SKU to use for the application servers
#application_server_sku = ""

# app_tier_dual_nics is a boolean flag controlling if the application tier servers should have two network cards
#app_tier_dual_nics = false

# application_server_app_nic_ips, if provided provides the static IP addresses 
# for the network interface cards connected to the application subnet
#application_server_app_nic_ips = []

# application_server_nic_secondary_ips, if provided provides the secondary static IP addresses 
# for the network interface cards connected to the application subnet
#application_server_nic_secondary_ips = []

# application_server_app_admin_nic_ips, if provided provides the static IP addresses 
# for the network interface cards connected to the admin subnet
#application_server_admin_nic_ips = []

#If you want to customise the disk sizes for application tier use the following parameter.
#app_disk_sizes_filename = null

# Optional, Defines the default authentication model for the Applicatiuon tier VMs (key/password)
#app_tier_authentication_type = ""

# application_server_no_ppg defines the that the application server virtual machines will not be placed in a proximity placement group
#application_server_no_ppg = false

# application_server_no_avset defines the that the application server virtual machines will not be placed in an availability set
#application_server_no_avset = false

# application_server_tags, if defined provides the tags to be associated to the application servers
#application_server_tags = null

# The vm_image defines the Virtual machine image to use for the application servers, 
# if source_image_id is specified the deployment will use the custom image provided, 
# in this case os_type must also be specified
application_server_image = {
  os_type         = "linux",
  source_image_id = "",
  publisher       = "SUSE",
  offer           = "sles-sap-15-sp3",
  sku             = "gen2",
  version         = "latest"
  type            = "source_image" # [custom, marketplace, source_image]
}

#application_server_vm_avset_arm_ids = []

############################################################################################
#                                                                                          #
#                                  Web Dispatchers                                         #
#                                                                                          #
############################################################################################

# webdispatcher_server_count defines how many web dispatchers to deploy
webdispatcher_server_count = 0

# webdispatcher_server_app_nic_ips, if provided provides the static IP addresses 
# for the network interface cards connected to the application subnet
#webdispatcher_server_app_nic_ips = []

# webdispatcher_server_nic_secondary_ips, if provided provides the secondary static IP addresses 
# for the network interface cards connected to the application subnet
#webdispatcher_server_nic_secondary_ips = []

# webdispatcher_server_app_admin_nic_ips, if provided provides the static IP addresses 
# for the network interface cards connected to the application subnet
#webdispatcher_server_admin_nic_ips = []

# webdispatcher_server_loadbalancer_ips, if provided provides the static IP addresses for the load balancer
# for the network interface cards connected to the application subnet
#webdispatcher_server_loadbalancer_ips = []

# webdispatcher_server_sku, if defined provides the SKU to use for the web dispatchers
#webdispatcher_server_sku = ""

# webdispatcher_server_no_ppg defines the that the Web dispatcher virtual machines will not be placed in a proximity placement group
#webdispatcher_server_no_ppg = false

#webdispatcher_server_no_avset defines the that the Web dispatcher virtual machines will not be placed in an availability set
#webdispatcher_server_no_avset = false

# webdispatcher_server_tags, if defined provides the tags to be associated to the web dispatchers
#webdispatcher_server_tags = null

# webdispatcher_server_zones is an optional list defining the availability zones to which deploy the web dispatchers
#webdispatcher_server_zones = []

# The vm_image defines the Virtual machine image to use for the web dispatchers, 
# if source_image_id is specified the deployment will use the custom image provided, 
# in this case os_type must also be specified
#webdispatcher_server_image = {}

#########################################################################################
#                                                                                       #
#  Miscellaneous settings                                                               #
#                                                                                       #
#########################################################################################

# resource_offset can be used to provide an offset for resource naming
# server#, disk# 
resource_offset = 1

# vm_disk_encryption_set_id if defined defines the custom encryption key 
#vm_disk_encryption_set_id = ""

# deploy_application_security_groups if defined will create application security groups
deploy_application_security_groups = true

#########################################################################################
#                                                                                       #
#  NFS support                                                                          #
#                                                                                       #
#########################################################################################

# NFS_Provider defines how NFS services are provided to the SAP systems, valid options are "ANF", "AFS", "NFS" or "NONE"
# AFS indicates that Azure Files for NFS is used
# ANF indicates that Azure NetApp Files is used
# NFS indicates that a custom solution is used for NFS
NFS_provider = "NONE"

sapmnt_volume_size = 128

#azure_files_sapmnt_id = ""

#sapmnt_private_endpoint_id = ""

#########################################################################################
#                                                                                       #
#  HANA Data                                                                            #
#                                                                                       #
#########################################################################################

# ANF_HANA_data, if defined, will create Azure NetApp Files volume(s) for HANA data.
#ANF_HANA_data = false

# ANF_HANA_data_volume_size, if defined, provides the size of the HANA data volume(s).
#ANF_HANA_data_volume_size = 0

# ANF_HANA_data_volume_throughput, if defined, provides the throughput of the HANA data volume(s).
#ANF_HANA_data_volume_throughput = 0

# Use existing Azure NetApp volumes for HANA data.
#ANF_HANA_data_use_existing_volume = false

# ANF_HANA_data_volume_name, if defined, provides the name of the HANA data volume(s).
#ANF_HANA_data_volume_name = ""


#########################################################################################
#                                                                                       #
#  HANA Log                                                                            #
#                                                                                       #
#########################################################################################

# ANF_HANA_log, if defined, will create Azure NetApp Files volume(s) for HANA log.
#ANF_HANA_log = false

# ANF_HANA_log_volume_size, if defined, provides the size of the HANA log volume(s).
#ANF_HANA_log_volume_size = 0

# ANF_HANA_log_volume_throughput, if defined, provides the throughput of the HANA log volume(s).
#ANF_HANA_log_volume_throughput = 0

# Use existing Azure NetApp volumes for HANA log.
#ANF_HANA_log_use_existing = false

# ANF_HANA_log_volume_name, if defined, provides the name of the HANA log volume(s).
#ANF_HANA_log_volume_name = ""


#########################################################################################
#                                                                                       #
#  HANA Log                                                                            #
#                                                                                       #
#########################################################################################

# ANF_HANA_shared, if defined, will create Azure NetApp Files volume(s) for HANA shared.
#ANF_HANA_shared = false

# ANF_HANA_shared_volume_size, if defined, provides the size of the HANA shared volume(s).
#ANF_HANA_shared_volume_size = 0

# ANF_HANA_shared_volume_throughput, if defined, provides the throughput of the HANA shared volume(s).
#ANF_HANA_shared_volume_throughput = 0

# Use existing Azure NetApp volumes for HANA shared.
#ANF_HANA_shared_use_existing = false

# ANF_HANA_shared_volume_name, if defined, provides the name of the HANA shared volume(s).
#ANF_HANA_shared_volume_name = ""


#########################################################################################
#                                                                                       #
#  HANA Log                                                                            #
#                                                                                       #
#########################################################################################

# ANF_usr_sap, if defined, will create Azure NetApp Files volume /usr/sap
#ANF_usr_sap = false

# ANF_usr_sap_volume_size, if defined, provides the size of the /usr/sap volume.
#ANF_usr_sap_volume_size = 0

# ANF_usr_sap_throughput, if defined, provides the throughput of the /usr/sap volume.
#ANF_usr_sap_throughput = 0

# Use existing Azure NetApp volumes for /usr/sap.
#ANF_usr_sap_use_existing = false

# ANF_usr_sap_volume_name, if defined, provides the name of the /usr/sap volume.
#ANF_usr_sap_volume_name = ""


#########################################################################################
#                                                                                       #
#  HANA Log                                                                            #
#                                                                                       #
#########################################################################################

# ANF_sapmnt, if defined, will create Azure NetApp Files volume for /sapmnt
#ANF_sapmnt = false

# ANF_sapmnt_volume_size, if defined, provides the size of the /sapmnt volume.
#ANF_sapmnt_volume_size = 0

# ANF_sapmnt_volume_throughput, if defined, provides the throughput of the /sapmnt volume.
#ANF_sapmnt_volume_throughput = 0

# ANF_sapmnt_volume_name, if defined, provides the name of the /sapmnt volume.
#ANF_sapmnt_volume_name = ""



#########################################################################################
#                                                                                       #
#  Credentials.                                                                         #
#  By default the credentials are defined in the workload zone                          #
#  Only use this section if the SID needs unique credentials                            #
#                                                                                       #
#########################################################################################

# The automation_username defines the user account used by the automation
#automation_username = ""

# The automation_password is an optional parameter that can be used to provide a password for the automation user
# If empty Terraform will create a password and persist it in keyvault
#automation_password = ""

# The automation_path_to_public_key is an optional parameter that can be used to provide a path to an existing ssh public key file
# If empty Terraform will create the ssh key and persist it in keyvault
#automation_path_to_public_key = ""

# The automation_path_to_private_key is an optional parameter that can be used to provide a path to an existing ssh private key file
# If empty Terraform will create the ssh key and persist it in keyvault
#automation_path_to_private_key = ""

# vm_disk_encryption_set_id if defined defines the custom encryption key 
#vm_disk_encryption_set_id = ""

# nsg_asg_with_vnet if set controls where the Application Security Groups are created
#nsg_asg_with_vnet = false

# RESOURCEGROUP
# The two resource group name and arm_id can be used to control the naming and the creation of the resource group
# The resourcegroup_name value is optional, it can be used to override the name of the resource group that will be provisioned
# The resourcegroup_name arm_id is optional, it can be used to provide an existing resource group for the deployment

#resourcegroup_name = ""

#resourcegroup_arm_id = ""

# PPG
# The proximity placement group names and arm_ids are optional can be used to 
# control the naming and the creation of the proximity placement groups
# The proximityplacementgroup_names list value is optional, 
# it can be used to override the name of the proximity placement groups that will be provisioned
# The proximityplacementgroup_arm_ids list value is optional, 
# it can be used to provide an existing proximity placement groups for the deployment

#proximityplacementgroup_names = []

#proximityplacementgroup_arm_ids = []

#########################################################################################
#                                                                                       #
#  Key Vault variables                                                                  #
#                                                                                       #
#########################################################################################

#user_keyvault_id = ""

#spn_keyvault_id = ""

#enable_purge_control_for_keyvaults = false

#########################################################################################
#                                                                                       #
#  Admin Subnet variables                                                               #
#                                                                                       #
#########################################################################################

# If defined these parameters control the subnet name and the subnet prefix
# admin_subnet_name is an optional parameter and should only be used if the default naming is not acceptable 
#admin_subnet_name = ""

# admin_subnet_address_prefix is a mandatory parameter if the subnets are not defined in the workload or if existing subnets are not used
#admin_subnet_address_prefix = ""

# admin_subnet_arm_id is an optional parameter that if provided specifies Azure resource identifier for the existing subnet to use
#admin_subnet_arm_id = ""

# admin_subnet_nsg_name is an optional parameter and should only be used if the default naming is not acceptable for the network security group name 
#admin_subnet_nsg_name = ""

# admin_subnet_nsg_arm_id is an optional parameter that if provided specifies Azure resource identifier for the existing network security group to use
#admin_subnet_nsg_arm_id = ""

#########################################################################################
#                                                                                       #
#  DB Subnet variables                                                                  #
#                                                                                       #
#########################################################################################

# If defined these parameters control the subnet name and the subnet prefix
# db_subnet_name is an optional parameter and should only be used if the default naming is not acceptable 
#db_subnet_name = ""

# db_subnet_address_prefix is a mandatory parameter if the subnets are not defined in the workload or if existing subnets are not used
#db_subnet_address_prefix = ""

# db_subnet_arm_id is an optional parameter that if provided specifies Azure resource identifier for the existing subnet to use
#db_subnet_arm_id = ""

# db_subnet_nsg_name is an optional parameter and should only be used if the default naming is not acceptable for the network security group name 
#db_subnet_nsg_name = ""

# db_subnet_nsg_arm_id is an optional parameter that if provided specifies Azure resource identifier for the existing network security group to use
#db_subnet_nsg_arm_id = ""

#########################################################################################
#                                                                                       #
#  App Subnet variables                                                                 #
#                                                                                       #
#########################################################################################

# If defined these parameters control the subnet name and the subnet prefix
# app_subnet_name is an optional parameter and should only be used if the default naming is not acceptable 
#app_subnet_name = ""

# app_subnet_address_prefix is an optional parameter that if provided specifies Azure resource identifier for the existing subnet to use
#app_subnet_address_prefix = ""

# app_subnet_arm_id is an optional parameter that if provided specifies Azure resource identifier for the existing subnet to use
#app_subnet_arm_id = ""

# app_subnet_nsg_name is an optional parameter and should only be used if the default naming is not acceptable for the network security group name 
#app_subnet_nsg_name = ""

# app_subnet_nsg_arm_id is an optional parameter that if provided specifies Azure resource identifier for the existing network security group to use
#app_subnet_nsg_arm_id = ""

#########################################################################################
#                                                                                       #
#  Web Subnet variables                                                                 #
#                                                                                       #
#########################################################################################

# If defined these parameters control the subnet name and the subnet prefix
# web_subnet_name is an optional parameter and should only be used if the default naming is not acceptable 
#web_subnet_name = ""

# web_subnet_address_prefix is an optional parameter that if provided specifies Azure resource identifier for the existing subnet to use
#web_subnet_address_prefix = ""

# web_subnet_arm_id is an optional parameter that if provided specifies Azure resource identifier for the existing subnet to use
#web_subnet_arm_id = ""

# web_subnet_nsg_name is an optional parameter and should only be used if the default naming is not acceptable for the network security group name 
#web_subnet_nsg_name = ""

# web_subnet_nsg_arm_id is an optional parameter that if provided specifies Azure resource identifier for the existing network security group to use
#web_subnet_nsg_arm_id = ""

#########################################################################################
#                                                                                       #
# Anchor VM                                                                             #
#                                                                                       #
# The Anchor VM can be used as the first Virtual Machine deployed by the deployment,    #
# this Virtual Machine will anchor the proximity placement group and all the            #
# subsequent virtual machines will be deployed in the same group.                       #
# It is recommended to use the same SKU for the Anchor VM as for the database VM        #
#                                                                                       #
#########################################################################################

# the deploy_anchor_vm flag controls if an anchor VM should be deployed
#deploy_anchor_vm = false

# anchor_vm_sku if used is mandatory and defines the virtual machine SKU
#anchor_vm_sku = ""

# Defines the default authentication model for the Anchor VM (key/password)
#anchor_vm_authentication_type = ""

# Defines if the anchor VM should use accelerated networking
#anchor_vm_accelerated_networking = false

# The anchor_vm_image defines the Virtual machine image to use, 
# if source_image_id is specified the deployment will use the custom image provided
# in this case os_type must also be specified
#anchor_vm_image = {}

# anchor_vm_nic_ips if defined will provide the IP addresses for the the Anchor VMs
#anchor_vm_nic_ips = []

# anchor_vm_use_DHCP is a boolean flag controlling if Azure subnet provided IP addresses should be used (true)
#anchor_vm_use_DHCP = false

# anchor_vm_authentication_username defines the username for the anchor VM
#anchor_vm_authentication_username = ""


#########################################################################################
#                                                                                       #
#  Terraform deploy parameters                                                          #
#                                                                                       #
#########################################################################################

# - tfstate_resource_id is the Azure resource identifier for the Storage account in the SAP Library
#   that will contain the Terraform state files
# - deployer_tfstate_key is the state file name for the deployer
# - landscape_tfstate_key is the state file name for the workload deployment
# These are required parameters, if using the deployment scripts they will be auto populated otherwise they need to be entered

#tfstate_resource_id = null

#deployer_tfstate_key = null

#landscape_tfstate_key = null
