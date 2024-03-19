#######################################4#######################################8
#                                                                              #
#                           Environment definitioms                            #
#                                                                              #
#######################################4#######################################8


variable "environment"                           {
                                                   description = "This is the environment name for the deployment"
                                                   type        = string
                                                   default     = ""
                                                 }

variable "codename"                              {
                                                   description = "This is the code name name for the deployment"
                                                   type        = string
                                                   default     = ""
                                                 }

variable "location"                              {
                                                  description = "The Azure region for the resources"
                                                  type        = string
                                                  default     = ""
                                                }

variable "name_override_file"                   {
                                                  description = "If provided, contains a json formatted file defining the name overrides"
                                                  default     = ""
                                                }

variable "custom_prefix"                        {
                                                  description = "Optional custom prefix for the deployment"
                                                  type        = string
                                                  default     = ""
                                                }

variable "use_prefix"                           {
                                                  description = "Defines if the resources are to be prefixed"
                                                  default     = true
                                                }


variable "custom_disk_sizes_filename"           {
                                                  description = "Custom disk configuration json file for Virtual machines"
                                                  default     = ""
}

variable "use_scalesets_for_deployment"         {
                                                  description = "Use Flexible Virtual Machine Scale Sets for the deployment"
                                                  default     = false
                                                }

variable "scaleset_id"                          {
                                                  description = "If defined the Flexible Virtual Machine Scale Sets for the deployment"
                                                  default     = ""
                                                }


#########################################################################################
#                                                                                       #
#  Resource Group variables                                                             #
#                                                                                       #
#########################################################################################

variable "resourcegroup_name"                   {
                                                  description = "If provided, the name of the resource group to be created"
                                                  default     = ""
                                                }

variable "resourcegroup_arm_id"                 {
                                                  description = "If provided, the Azure resource group id"
                                                  default     = ""
                                                }

variable "resourcegroup_tags"                   {
                                                  description = "If provided, tags for the resource group"
                                                  default     = {}
                                                }

#########################################################################################
#                                                                                       #
#  Infrastructure variables                                                             #
#                                                                                       #
#########################################################################################


variable "proximityplacementgroup_names"        {
                                                  description = "If provided, names of the proximity placement groups"
                                                  default     = []
                                                }

variable "proximityplacementgroup_arm_ids"      {
                                                  description = "If provided, azure resource ids for the proximity placement groups"
                                                  default     = []
                                                }

variable "use_app_proximityplacementgroups"     {
                                                  description = "Boolean value indicating if an proximity placement group should be used for the app tier VMs"
                                                  default     = false
                                                  type        = bool
                                                }

variable "app_proximityplacementgroup_names"    {
                                                  description = "If provided, names of the application proximity placement groups"
                                                  default     = []
                                                }

variable "app_proximityplacementgroup_arm_ids"  {
                                                  description = "If provided, azure resource ids for the application proximity placement groups"
                                                  default     = []
                                                }


variable "use_private_endpoint"                 {
                                                  description = "Boolean value indicating if private endpoint should be used for the deployment"
                                                  default     = false
                                                  type        = bool
                                                }


#########################################################################################
#                                                                                       #
#  Virtual Network variables                                                            #
#                                                                                       #
#########################################################################################

variable "network_logical_name"                 {
                                                  description = "The logical name of the virtual network, used for resource naming"
                                                  default     = ""
                                                }

variable "use_secondary_ips"                    {
                                                  description = "Defines if secondary IPs are used for the SAP Systems virtual machines"
                                                  default     = false
                                                }


#######################################4#######################################8
#                                                                              #
#                        Admin Subnet variables                                #
#                                                                              #
#######################################4#######################################8

variable "admin_subnet_address_prefix"          {
                                                  description = "The address prefix for the admin subnet"
                                                  default     = ""
                                                }

variable "admin_subnet_name"                    {
                                                  description = "If provided, the name of the admin subnet"
                                                  default     = ""
                                                }

variable "admin_subnet_arm_id"                  {
                                                  description = "If provided, Azure resource id for the admin subnet"
                                                  default     = ""
                                                }

variable "admin_subnet_nsg_name"                {
                                                  description = "If provided, the name of the admin subnet NSG"
                                                  default     = ""
                                                }

variable "admin_subnet_nsg_arm_id"              {
                                                  description = "If provided, Azure resource id for the admin subnet NSG"
                                                  default     = ""
                                                }


#######################################4#######################################8
#                                                                              #
#                      Database Subnet variables                               #
#                                                                              #
#######################################4#######################################8

variable "db_subnet_name"                       {
                                                  description = "If provided, the name of the db subnet"
                                                  default     = ""
                                                }

variable "db_subnet_arm_id"                     {
                                                  description = "If provided, Azure resource id for the db subnet"
                                                  default     = ""
                                                }

variable "db_subnet_address_prefix"             {
                                                  description = "The address prefix for the db subnet"
                                                  default     = ""
                                                }

variable "db_subnet_nsg_name"                   {
                                                  description = "If provided, the name of the db subnet NSG"
                                                  default     = ""
                                                }

variable "db_subnet_nsg_arm_id"                 {
                                                  description = "If provided, Azure resource id for the db subnet NSG"
                                                  default     = ""
                                                }


#######################################4#######################################8
#                                                                              #
#               Application Subnet variables                                   #
#                                                                              #
#######################################4#######################################8

variable "app_subnet_name"                      {
                                                  description = "If provided, the name of the app subnet"
                                                  default     = ""
                                                }

variable "app_subnet_arm_id"                    {
                                                  description = "If provided, Azure resource id for the app subnet"
                                                  default     = ""
                                                }

variable "app_subnet_address_prefix"            {
                                                  description = "The address prefix for the app subnet"
                                                  default     = ""
                                                }

variable "app_subnet_nsg_name"                  {
                                                  description = "If provided, the name of the app subnet NSG"
                                                  default     = ""
                                                }

variable "app_subnet_nsg_arm_id"                {
                                                  description = "If provided, Azure resource id for the app subnet NSG"
                                                  default     = ""
                                                }


#########################################################################################
#                                                                                       #
#  Web Subnet variables                                                                 #
#                                                                                       #
#########################################################################################

variable "web_subnet_name"                      {
                                                  description = "If provided, the name of the web subnet"
                                                  default     = ""
                                                }

variable "web_subnet_arm_id"                    {
                                                  description = "If provided, Azure resource id for the web subnet"
                                                  default     = ""
                                                }

variable "web_subnet_address_prefix"            {
                                                  description = "The address prefix for the web subnet"
                                                  default     = ""
                                                }

variable "web_subnet_nsg_name"                  {
                                                  description = "If provided, the name of the web subnet NSG"
                                                  default     = ""
                                                }

variable "web_subnet_nsg_arm_id"                {
                                                  description = "If provided, Azure resource id for the web subnet NSG"
                                                  default     = ""
                                                }



#########################################################################################
#                                                                                       #
#  Key Vault variables                                                                  #
#                                                                                       #
#########################################################################################

variable "user_keyvault_id"                     {
                                                  description = "If provided, the Azure resource identifier of the credentials keyvault"
                                                  default     = ""
                                                }

variable "spn_keyvault_id"                      {
                                                  description = "If provided, the Azure resource identifier of the deployment credential keyvault"
                                                  default     = ""
                                                }

variable "enable_purge_control_for_keyvaults"   {
                                                  description = "Disables the purge protection for Azure keyvaults."
                                                  default     = false
                                                  type        = bool
                                                }

#########################################################################################
#                                                                                       #
#  Authentication variables, use these if you want to have SID specific credentials     #
#                                                                                       #
#########################################################################################

variable "automation_username"                  {
                                                  description = "The username for the automation account"
                                                  default     = ""
                                                }

variable "automation_password"                  {
                                                  description = "If provided, the password for the automation account"
                                                  default     = ""
                                                }

variable "automation_path_to_public_key"        {
                                                  description = "If provided, the path to the existing public key for the automation account"
                                                  default     = ""
                                                }

variable "automation_path_to_private_key"       {
                                                  description = "If provided, the path to the existing private key for the automation account"
                                                  default     = ""
                                                }

variable "use_spn"                              {
                                                  description = "Log in using a service principal when performing the deployment"
                                                  default     = true
                                                }


#########################################################################################
#                                                                                       #
#  Cluster settings                                                                     #
#                                                                                       #
#########################################################################################

variable "use_msi_for_clusters"                 {
                                                  description = "If true, the Pacemaker cluser will use a managed identity"
                                                  default     = false
                                                }

variable "fencing_role_name"                    {
                                                  description = "If specified the role name to use for the fencing agent"
                                                  default     = "Virtual Machine Contributor"
                                                }

variable "use_simple_mount"                     {
                                                  description = "Determine if simple mount needs to be added for SCS and DB clusters"
                                                  default     = false
                                                }

variable "use_fence_kdump"                      {
                                                  description = "Configure fencing device based on the fence agent fence_kdump for both SCS and DB clusters"
                                                  default     = false
                                                }

variable "use_fence_kdump_size_gb_db"           {
                                                  description = "Default size of the kdump disk which will be attached to the VMs which are part DB cluster"
                                                  default     = 128
                                                }

variable "use_fence_kdump_size_gb_scs"          {
                                                  description = "Default size of the kdump disk which will be attached to the VMs which are part of SCS cluster"
                                                  default     = 64
                                                }

variable "use_fence_kdump_lun_db"               {
                                                  description = "Default lun number of the kdump disk which will be attached to the VMs which are part of DB cluster"
                                                  default     = 8
                                                }

variable "use_fence_kdump_lun_scs"              {
                                                  description = "Default lun number of the kdump disk which will be attached to the VMs which are part of SCS cluster"
                                                  default     = 4
                                                }

#########################################################################################
#                                                                                       #
#  Database tier variables                                                              #
#                                                                                       #
#########################################################################################

variable "database_cluster_disk_lun"            {
                                                  description = "The LUN of the shared disk for the Database cluster"
                                                  default     = 8
                                                }

variable "database_cluster_disk_size"           {
                                                  description = "The size of the shared disk for the Database cluster"
                                                  default     = 128
                                                }

variable "database_platform"                    {
                                                  description = "Database platform, supported values are HANA, DB2, ORACLE, ORACLE-ASM, ASE, SQLSERVER or NONE (in this case no database tier is deployed)"
                                                  default     = ""
                                                }

variable "database_sid"                         {
                                                  description = "The database SID"
                                                  default     = "HDB"
                                                }

variable "database_server_count"                {
                                                  description = "The number of database servers"
                                                  default     = 1
                                                }

variable "database_high_availability"           {
                                                  description = "If true, the database tier will be configured for high availability"
                                                  default     = false
                                                }

variable "database_cluster_type"                {
                                                  description   = "Cluster quorum type; AFA (Azure Fencing Agent), ASD (Azure Shared Disk), ISCSI"
                                                  default       = "AFA"
                                                }

variable "use_observer"                         {
                                                  description = "If true, an observer virtual machine will be used"
                                                  default     = true
                                                }

variable "database_vm_zones"                    {
                                                  description = "If provided, the database tier will be deployed in the specified zones"
                                                  default     = []
                                                }

variable "database_size"                        {
                                                  description = "Dictionary key value to sizing json"
                                                  default     = ""
                                                }

variable "database_vm_sku"                      {
                                                  description = "The Virtual Machine SKU to use for the database virtual machines"
                                                  default     = ""
                                                }

variable "db_sizing_dictionary_key"             {
                                                  description = "Dictionary value to sizing json"
                                                  default     = ""
                                                }

variable "db_disk_sizes_filename"               {
                                                  description = "Custom disk configuration json file for database tier"
                                                  default     = ""
                                                }

variable "database_vm_image"                    {
                                                  description = "Virtual machine image to use for the database server"
                                                  default = {
                                                              "os_type"         = "LINUX"
                                                              "source_image_id" = ""
                                                              "publisher"       = ""
                                                              "offer"           = ""
                                                              "sku"             = ""
                                                              "version"         = ""
                                                              "type"            = "custom"
                                                            }
                                                }

variable "database_vm_authentication_type"      {
                                                  description = "Authentication type for the database server"
                                                  default     = "key"
                                                }

variable "database_vm_avset_arm_ids"            {
                                                  description = "If provided, Azure resource ids for the availability sets to use for the database servers"
                                                  default     = []
                                                }

variable "database_vm_use_DHCP"                 {
                                                  description = "If true, the database server will use Azure provided IP addresses"
                                                  default     = false
                                                }

variable "database_instance_number"             {
                                                  description = "The Instance number for the database server"
                                                  default     = "00"
                                                }

variable "database_no_avset"                    {
                                                  description = "[Obsolete] If true, the database tier will not use an availability set"
                                                  default     = null
                                                }

variable "database_use_avset"                   {
                                                  description = "If true, the database tier will use an availability set"
                                                  default     = null
                                                  validation {
                                                               condition = (
                                                                 tobool(var.database_use_avset) != null
                                                               )
                                                               error_message = "database_use_avset is not defined, please define it in your tfvars file."
                                                             }
                                                }

variable "database_dual_nics"                   {
                                                  description = "If true, the database tier will have be deployed with two network interfaces"
                                                  default     = false
                                                }

variable "database_no_ppg"                      {
                                                  description = "[Obsolete] If provided, the database tier will not be placed in a proximity placement group"
                                                  default     = null
                                                }

variable "database_use_ppg"                     {
                                                  description = "If provided, the database tier will be placed in a proximity placement group"
                                                  default     = null
                                                  validation {
                                                               condition = (
                                                                 tobool(var.database_use_ppg) != null
                                                               )
                                                               error_message = "database_use_ppg is not defined, please define it in your tfvars file."
                                                             }
                                                }

variable "database_loadbalancer_ips"            {
                                                  description = "If provided, the database tier's load balancer will be configured with the specified load balancer IPs"
                                                  default     = []
                                                }

variable "database_tags"                        {
                                                  description = "If provided, the database tier virtual machines will be configured with the specified tags"
                                                  default     = {}
                                                }

variable "database_vm_db_nic_ips"               {
                                                  description = "If provided, the database tier virtual machines will be configured using the specified IPs"
                                                  default     = [""]
                                                }

variable "database_vm_db_nic_secondary_ips"     {
                                                  description = "If provided, the database tier virtual machines will be configured using the specified IPs as secondary IPs"
                                                  default     = [""]
                                                }

variable "database_vm_admin_nic_ips"            {
                                                  description = "If provided, the database tier virtual machines will be configured with the specified IPs (admin subnet)"
                                                  default     = [""]
                                                }

variable "database_vm_storage_nic_ips"          {
                                                  description = "If provided, the database tier virtual machines will be configured with the specified IPs (storage subnet)"
                                                  default     = [""]
                                                }


variable "database_use_premium_v2_storage"      {
                                                  description = "If true, the database tier will use premium storage v2"
                                                  default     = false
                                                }

#########################################################################################
#                                                                                       #
#  Application tier variables                                                           #
#                                                                                       #
#########################################################################################

variable "enable_app_tier_deployment"           {
                                                  description = "If true, the application tier will be deployed"
                                                  default     = true
                                                }

variable "app_tier_authentication_type"         {
                                                  description = "App tier authentication type"
                                                  default     = "key"
                                                }

variable "sid"                                  {
                                                  description = "Application SID"
                                                  default     = ""
                                                }

variable "app_tier_use_DHCP"                    {
                                                  description = "If true, the application tier virtual machines will use Azure provided IP addresses"
                                                  default     = false
                                                }

variable "app_tier_dual_nics"                   {
                                                  description = "If true, the application tier virtual machines will have two NICs"
                                                  default     = false
                                                }

variable "app_tier_vm_sizing"                   {
                                                  description = "Dictionary value to sizing json"
                                                  default     = ""
                                                }

variable "app_tier_sizing_dictionary_key"       {
                                                  description = "Dictionary value to sizing json"
                                                  default     = ""
                                                }


variable "app_disk_sizes_filename"              {
                                                  description = "Custom disk configuration json file for application tier"
                                                  default     = ""
                                                }

#########################################################################################
#                                                                                       #
#  SAP Central Services tier variables                                                  #
#                                                                                       #
#########################################################################################

variable "scs_server_count"                     {
                                                  description = "The number of SAP Central Services servers to deploy"
                                                  default     = 0
                                                }

variable "scs_high_availability"                {
                                                  description = "If true, the SAP Central Services tier will be configured for high availability"
                                                  default     = false
                                                }

variable "scs_cluster_type"                     {
                                                  description   = "Cluster quorum type; AFA (Azure Fencing Agent), ASD (Azure Shared Disk), ISCSI"
                                                  default       = "AFA"
                                                }

variable "scs_server_zones"                     {
                                                  description = "If provided, the SAP Central Services tier will be deployed in the specified zones"
                                                  default     = []
                                                }

variable "scs_server_image"                     {
                                                  description = "Virtual machine image to use for the SAP Central Services server(s)"
                                                  default = {
                                                              "os_type"         = "LINUX"
                                                              "source_image_id" = ""
                                                              "publisher"       = ""
                                                              "offer"           = ""
                                                              "sku"             = ""
                                                              "version"         = ""
                                                              "type"            = "Custom"
                                                            }
                                                }

variable "scs_instance_number"                  {
                                                  description = "The instance number for SCS"
                                                  default     = "00"
                                                }

variable "ers_instance_number"                  {
                                                  description = "The instance number for ERS"
                                                  default     = "02"
                                                }

variable "scs_server_app_nic_ips"               {
                                                  description = "If provided, the SAP Central Services virtual machines will be configured with the specified IPs"
                                                  default     = []
                                                }

variable "scs_server_nic_secondary_ips"         {
                                                  description = "If provided, the SAP Central Services virtual machines will be configured with the specified IPs as secondary IPs"
                                                  default     = []
                                                }

variable "scs_server_admin_nic_ips"             {
                                                  description = "If provided, the SAP Central Services virtual machines will be configured with the specified IPs  (admin subnet)"
                                                  default     = []
                                                }

variable "scs_server_loadbalancer_ips"          {
                                                  description = "If provided, the SAP Central Services virtual machines will be configured with the specified load balancer IPs"
                                                  default     = []
                                                }

variable "scs_server_sku"                       {
                                                  description = "The Virtual Machine SKU to use for the SAP Central Services virtual machines"
                                                  default     = ""
                                                }

variable "scs_server_tags"                      {
                                                  description = "If provided, the SAP Central Services tier will be configured with the specified tags"
                                                  default     = {}
                                                }

variable "scs_server_no_avset"                  {
                                                  description = "[Obsolete] If true, the SAP Central Services tier will not use an availability set"
                                                  default     = null
                                                }

variable "scs_server_use_avset"                 {
                                                  description = "If true, the SAP Central Services tier will be placed in an availability set"
                                                  default     = null
                                                  validation {
                                                               condition = (
                                                                 tobool(var.scs_server_use_avset) != null
                                                               )
                                                               error_message = "scs_server_use_avset is not defined, please define it in your tfvars file."
                                                             }
                                                }

variable "scs_server_no_ppg"                    {
                                                  description = "[Obsolete] If provided, the Central Services will not be placed in a proximity placement group"
                                                  default     = null
                                                }

variable "scs_server_use_ppg"                   {
                                                  description = "If provided, the Central Services will be placed in a proximity placement group"
                                                  default     = null
                                                  validation {
                                                               condition = (
                                                                 tobool(var.scs_server_use_ppg) != null
                                                               )
                                                               error_message = "scs_server_use_ppg is not defined, please define it in your tfvars file."
                                                             }
                                                }

variable "scs_cluster_disk_lun"                 {
                                                  description = "The LUN of the shared disk for the SAP Central Services cluster"
                                                  default     = 5
                                                }

variable "scs_cluster_disk_size"                {
                                                  description = "The size of the shared disk for the SAP Central Services cluster"
                                                  default     = 128
                                                }

#########################################################################################
#                                                                                       #
#  Application Server variables                                                         #
#                                                                                       #
#########################################################################################

variable "application_server_count"             {
                                                  description = "The number of application servers"
                                                  default     = 0
                                                }

variable "pas_instance_number"                  {
                                                  description = "The Instance number for the Primary Application Server"
                                                  default     = "00"
                                                }

variable "app_instance_number"                  {
                                                  description = "The Instance number for the Application Server Imnstance"
                                                  default     = "00"
                                                }

variable "application_server_app_nic_ips"       {
                                                  description = "IP addresses for the application servers"
                                                  default     = []
                                                }

variable "application_server_nic_secondary_ips" {
                                                  description = "IP addresses for the application servers"
                                                  default     = []
                                                }

variable "application_server_admin_nic_ips"     {
                                                  description = "IP addresses for the application servers (admin subnet)"
                                                  default     = []
                                                }

variable "application_server_sku"               {
                                                  description = "The SKU for the application servers"
                                                  default     = ""
}

variable "application_server_tags"              {
                                                  description = "The tags for the application servers"
                                                  default     = {}
                                                }

variable "application_server_zones"             {
                                                  description = "The zones for the application servers"
                                                  default     = []
                                                }


variable "application_server_vm_avset_arm_ids" {
                                                  description = "If provided, Azure resource ids for the availability sets to use for the application servers"
                                                  default     = []
                                                }

variable "application_server_no_avset"          {
                                                  description = "[Obsolete]If true, the application tier will not be placed availability set"
                                                  default     = null
                                                }

variable "application_server_use_avset"         {
                                                  description = "If true, the application tier will be placed in an availability set"
                                                  default     = null
                                                  validation {
                                                               condition = (
                                                                 tobool(var.application_server_use_avset) != null
                                                               )
                                                               error_message = "application_server_use_avset is not defined, please define it in your tfvars file."
                                                             }
                                                }

variable "application_server_no_ppg"            {
                                                  description = "[Obsolete]If provided, the application servers will not be placed in a proximity placement group"
                                                  default     = null
                                                }

variable "application_server_use_ppg"           {
                                                  description = "If provided, the application servers will be placed in a proximity placement group"
                                                  default     = null
                                                  validation {
                                                               condition = (
                                                                 tobool(var.application_server_use_ppg) != null
                                                               )
                                                               error_message = "application_server_use_ppg is not defined, please define it in your tfvars file."
                                                             }
                                                }

variable "application_server_image"             {
                                                  description = "Virtual machine image to use for the application server"
                                                  default = {
                                                              "os_type"         = "LINUX"
                                                              "source_image_id" = ""
                                                              "publisher"       = ""
                                                              "offer"           = ""
                                                              "sku"             = ""
                                                              "version"         = ""
                                                            }
                                                 }

#########################################################################################
#                                                                                       #
#  Web Dispatcher variables                                                             #
#                                                                                       #
#########################################################################################

variable "webdispatcher_server_count"           {
                                                  description = "The number of web dispatchers"
                                                  default     = 0
                                                }

variable "web_sid"                              {
                                                  description = "The sid of the web dispatchers"
                                                  default     = ""
                                                }

variable "web_instance_number"                  {
                                                  description = "The Instance number for the Web dispatcher"
                                                  default     = "00"
                                                }

variable "webdispatcher_server_zones"           {
                                                  description = "The zones for the web dispatchers"
                                                  default     = []
                                                }

variable "webdispatcher_server_image"           {
                                                  description = "Virtual machine image to use for the web dispatchers"
                                                  default = {
                                                              "os_type"         = "LINUX"
                                                              "source_image_id" = ""
                                                              "publisher"       = ""
                                                              "offer"           = ""
                                                              "sku"             = ""
                                                              "version"         = ""
                                                            }
                                                }

variable "webdispatcher_server_app_nic_ips"     {
                                                  description = "The IP addresses for the web dispatchers"
                                                  default     = []
                                                }

variable "webdispatcher_server_nic_secondary_ips" {
                                                  description = "If provided, the Web Dispatchers will be configured with the specified IPs as secondary IPs"
                                                  default     = []
                                                }

variable "webdispatcher_server_admin_nic_ips"   {
                                                  description = "The IP addresses for the web dispatchers (admin subnet)"
                                                  default     = []
                                                }

variable "webdispatcher_server_loadbalancer_ips" {
                                                  description = "If provided, the Web Dispatcher tier will be configured with the specified load balancer IPs"
                                                  default     = []
                                                }

variable "webdispatcher_server_sku"             {
                                                  description = "The SKU for the web dispatchers"
                                                  default     = ""
                                                }

variable "webdispatcher_server_tags"            {
                                                  description = "The tags for the web dispatchers"
                                                  default     = {}
                                                }

variable "webdispatcher_server_no_avset"        {
                                                  description = "[OBSOLUTE]If true, the Web Dispatcher tier will not use an availability set"
                                                  default     = null
                                                }

variable "webdispatcher_server_use_avset"       {
                                                  description = "If true, the Web Dispatcher tier will will be placed in an availability set"
                                                  default     = false
                                                }

variable "webdispatcher_server_no_ppg"          {
                                                  description = "[OBSOLUTE]If provided, the web dispatchers will not be placed in a proximity placement group"
                                                  default     = null
                                                }

variable "webdispatcher_server_use_ppg"         {
                                                  description = "If provided, the web dispatchers will be placed in a proximity placement group"
                                                  default     = null
                                                }

#########################################################################################
#                                                                                       #
#  Miscallaneous settings                                                               #
#                                                                                       #
#########################################################################################

variable "resource_offset"                      {
                                                  description = "Provides an offset for the resource names (Server00 vs Server01)"
                                                  default     = 0
                                                }

variable "deploy_v1_monitoring_extension"       {
                                                  description = "Defines if the Microsoft.AzureCAT.AzureEnhancedMonitoring extension will be deployed"
                                                  default     = true
                                                }

variable "vm_disk_encryption_set_id"            {
                                                  description = "If provided, the VM disks will be encrypted with the specified disk encryption set"
                                                  default     = ""
                                                }

variable "nsg_asg_with_vnet"                    {
                                                  description = "If true, the network security group will be placed in the resource group containing the VNet"
                                                  default     = false
                                                }

variable "legacy_nic_order"                     {
                                                  description = "If defined, will reverse the order of the NICs"
                                                  default     = false
                                                }

variable "use_loadbalancers_for_standalone_deployments" {
                                                           description = "If defined, will use load balancers for standalone deployments"
                                                           default     = true
                                                        }

variable "idle_timeout_scs_ers"                 {
                                                  description = "Sets the idle timeout setting for the SCS and ERS loadbalancer"
                                                  default     = 30
                                                }

variable "bom_name"                             {
                                                  description = "Name of the SAP Application Bill of Material file"
                                                  default     = ""
                                                }

variable "Agent_IP"                             {
                                                  description = "If provided, contains the IP address of the agent"
                                                  type        = string
                                                  default     = ""
                                                }
variable "add_Agent_IP"                         {
                                                  description = "Boolean value indicating if the Agent IP should be added to the storage and key vault firewalls"
                                                  default     = true
                                                  type        = bool
                                                }

variable "shared_home"                          {
                                                  description = "If defined provides shared-home support"
                                                  default     = false
                                                }

variable "save_naming_information"              {
                                                  description = "If defined, will save the naming information for the resources"
                                                  default     = false
                                                }

variable "deploy_application_security_groups"   {
                                                  description = "Defines if application security groups should be deployed"
                                                  default     = true
                                                }

variable "user_assigned_identity_id"            {
                                                  description = "If provided defines the user assigned identity to assign to the virtual machines"
                                                  default     = ""
                                                }



#########################################################################################
#                                                                                       #
#  DNS settings                                                                         #
#                                                                                       #
#########################################################################################


variable "use_custom_dns_a_registration"        {
                                                  description = "Boolean value indicating if a custom dns a record should be created when using private endpoints"
                                                  default     = false
                                                  type        = bool
                                                }

variable "management_dns_subscription_id"       {
                                                  description = "String value giving the possibility to register custom dns a records in a separate subscription"
                                                  default     = ""
                                                  type        = string
                                                }

variable "management_dns_resourcegroup_name"    {
                                                  description = "String value giving the possibility to register custom dns a records in a separate resourcegroup"
                                                  default     = ""
                                                  type        = string
                                                }


variable "dns_zone_names"                       {
                                                  description = "Private DNS zone names"
                                                  type        = map(string)

                                                  default = {
                                                              "file_dns_zone_name"  = "privatelink.file.core.windows.net"
                                                              "blob_dns_zone_name"  = "privatelink.blob.core.windows.net"
                                                              "vault_dns_zone_name" = "privatelink.vaultcore.azure.net"
                                                            }
                                                }

variable "dns_a_records_for_secondary_names"    {
                                                  description = "Boolean value indicating if dns a records should be created for the secondary DNS names"
                                                  default     = true
                                                  type        = bool
                                                }

#########################################################################################
#                                                                                       #
#  NFS and Shared Filed settings                                                        #
#                                                                                       #
#########################################################################################

variable "NFS_provider"                         {
                                                  description = "NFS Provider, valid values are 'AFS', 'ANF' or 'NONE'"
                                                  type        = string
                                                  default     = "NONE"
                                                }

variable "sapmnt_volume_size"                   {
                                                  description = "sapmnt volume size in GB"
                                                  default     = 128
                                                }

variable "azure_files_sapmnt_id"                {
                                                  description = "Azure File Share ID for SAPMNT"
                                                  default     = ""
                                                }

variable "use_random_id_for_storageaccounts"    {
                                                  description = "If true, will use random id for storage accounts"
                                                  default     = false
                                                }

variable "sapmnt_private_endpoint_id"           {
                                                  description = "Azure Resource Identifier for an private endpoint connection"
                                                  type        = string
                                                  default     = ""
                                                }

#########################################################################################
#                                                                                       #
#  ANF settings                                                                         #
#                                                                                       #
#########################################################################################

variable "ANF_HANA_use_AVG"                     {
                                                  description = "Use Application Volume Group for data volume"
                                                  default     = false
                                                }

variable "ANF_HANA_use_Zones"                   {
                                                  description = "Use zonal ANF deployments"
                                                  default     = false
                                                }


# Data volume

variable "ANF_HANA_data"                        {
                                                  description = "If defined, will create ANF volumes for HANA data"
                                                  default     = false
                                                }

variable "ANF_HANA_data_volume_size"            {
                                                  description = "If defined provides the size of the HANA data volume"
                                                  default     = 512
                                                }

variable "ANF_HANA_data_use_existing_volume"    {
                                                  description = "Use existing data volume"
                                                  default     = false
                                                }

variable "ANF_HANA_data_volume_name"            {
                                                  description = "Data volume name"
                                                  default     = [""]
                                                }

variable "ANF_HANA_data_volume_throughput"      {
                                                  description = "If defined provides the throughput of the data volume"
                                                  default     = 128
                                                }

variable "ANF_HANA_data_volume_count"          {
                                                  description = "If defined provides the number of data volumes"
                                                  default     = 1
                                                }

# Log volume

variable "ANF_HANA_log"                         {
                                                  description = "If defined, will create ANF volumes for HANA log"
                                                  default     = false
                                                }

variable "ANF_HANA_log_volume_size"             {
                                                  description = "If defined provides the size of the HANA log volume"
                                                  default     = 512
                                                }

variable "ANF_HANA_log_use_existing"            {
                                                  description = "Use existing log volume"
                                                  default     = false
                                                }

variable "ANF_HANA_log_volume_name"             {
                                                  description = "Log volume name"
                                                  default     = [""]
                                                }

variable "ANF_HANA_log_volume_throughput"       {
                                                  description = "If defined provides the throughput of the log volume"
                                                  default     = 128
                                                }

variable "ANF_HANA_log_volume_count"            {
                                                  description = "If defined provides the number of data volumes"
                                                  default     = 1
                                                }

# Shared volume

variable "ANF_HANA_shared"                      {
                                                  description = "If defined, will create ANF volumes for HANA shared"
                                                  default     = false
                                                }

variable "ANF_HANA_shared_volume_size"          {
                                                  description = "If defined provides the size of the HANA shared volume"
                                                  default     = 512
                                                }

variable "ANF_HANA_shared_use_existing"         {
                                                  description = "Use existing shared volume"
                                                  default     = false
                                                }

variable "ANF_HANA_shared_volume_name"          {
                                                  description = "If defined provides the name of the HANA shared volume"
                                                  default     = 512
                                                }

variable "ANF_HANA_shared_volume_throughput"    {
                                                  description = "If defined provides the throughput of the /shared volume"
                                                  default     = 128
                                                }

# /usr/sap

variable "ANF_usr_sap"                          {
                                                  description = "If defined, will create ANF volumes for /usr/sap"
                                                  default     = false
                                                }

variable "ANF_usr_sap_volume_size"              {
                                                  description = "If defined provides the size of the  /usr/sap volume"
                                                  default     = 512
                                                }

variable "ANF_usr_sap_use_existing"             {
                                                  description = "Use existing  /usr/sap volume"
                                                  default     = false
                                                }

variable "ANF_usr_sap_volume_name"              {
                                                  description = "If defined provides the name of the /usr/sap volume"
                                                  default     = ""
                                                }

variable "ANF_usr_sap_throughput"               {
                                                  description = "If defined provides the throughput of the /usr/sap volume"
                                                  default     = 128
                                                }


# /sapmnt


variable "ANF_sapmnt_use_existing"              {
                                                  description = "Use existing sapmnt volume"
                                                  default     = false
                                                }

variable "ANF_sapmnt_use_clone_in_secondary_zone" {
                                                  description = "Create a clone in the secondary region"
                                                  default     = false
                                                }

variable "ANF_sapmnt"                           {
                                                  description = "Use existing sapmnt volume"
                                                  default     = false
                                                }

variable "ANF_sapmnt_volume_name"               {
                                                  description = "sapmnt volume name"
                                                  default     = ""
                                                }

variable "ANF_sapmnt_volume_size"               {
                                                  description = "If defined provides the size of the sapmnt volume"
                                                  default     = 64
                                                }

variable "ANF_sapmnt_volume_throughput"         {
                                                  description = "If defined provides the throughput of the sapmnt volume"
                                                  default     = 64
                                                }


#########################################################################################
#                                                                                       #
#  Anchor VM variables                                                                  #
#                                                                                       #
#########################################################################################

variable "deploy_anchor_vm"                     {
                                                  description = "If defined, will deploy the Anchor VM to anchor the PPG"
                                                  default     = false
                                                }

variable "anchor_vm_sku"                        {
                                                  description = "SKU of the Anchor VM"
                                                  default     = "Standard_D2s_v4"
                                                }

variable "anchor_vm_use_DHCP"                   {
                                                  description = "If defined, will use Azure provided IP addresses for the Anchor VM"
                                                  default     = false
                                                }

variable "anchor_vm_image" {
                                                  description = "Image of the Anchor VM"
                                                  default = {
                                                              "os_type"         = "LINUX"
                                                              "source_image_id" = ""
                                                              "publisher"       = "SUSE"
                                                              "offer"           = "sles-sap-15-sp3"
                                                              "sku"             = "gen2"
                                                              "version"         = "latest"
                                                            }
                                                }

variable "anchor_vm_authentication_type"        {
                                                  description = "Authentication type of the Anchor VM"
                                                  default     = "key"
                                                }

variable "anchor_vm_authentication_username"    {
                                                  description = "value of the username for the Anchor VM"
                                                  default     = "azureadm"
                                                }


variable "anchor_vm_nic_ips"                    {
                                                  description = "IP addresses of the NICs for the Anchor VM"
                                                  default     = []
                                                }

variable "anchor_vm_accelerated_networking"     {
                                                  description = "If defined, will enable accelerated networking for the Anchor VM"
                                                  default     = true
                                                }

variable "subscription"                         {
                                                  description = "Target subscription"
                                                  default     = ""
                                                }

#########################################################################################
#                                                                                       #
#  Azure Monitor for SAP variables                                                      #
#                                                                                       #
#########################################################################################

variable "ams_resource_id"                      {
                                                  description = "[optional] If defined, will use the specified Azure Monitor for SAP instance, else will use the AMS instance in the workload zone."
                                                  default     = ""
                                                }

variable "enable_ha_monitoring"                 {
                                                  description = "If defined, will enable prometheus high availability cluster monitoring"
                                                  default     = false
                                                }

variable "enable_os_monitoring"                 {
                                                  description = "If defined, will enable prometheus os monitoring"
                                                  default     = false
                                                }

#########################################################################################
#                                                                                       #
#  Configuration values                                                                 #
#                                                                                       #
#########################################################################################

variable "configuration_settings"               {
                                                  description = "This is a dictionary that will contain values persisted to the sap-parameters.file"
                                                  default     = {}
                                                }

variable "upgrade_packages"                     {
                                                  description = "If defined, will upgrade the packages on the virtual machines"
                                                  default     = false
                                                }

variable "tags"                                 {
                                                  description = "If provided, tags for all resources"
                                                  default     = {}
                                                }


#########################################################################################
#                                                                                       #
#  Scaleout variables                                                                   #
#                                                                                       #
#########################################################################################

variable "database_HANA_use_ANF_scaleout_scenario" {
                                                  description = "If true, the database tier will be configured for scaleout scenario"
                                                  default = false
                                                }

variable "stand_by_node_count"                  {
                                                  description = "The number of standby nodes"
                                                  default = 0
                                                }
