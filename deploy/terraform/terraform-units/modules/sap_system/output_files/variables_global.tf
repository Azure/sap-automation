variable "ansible_user"                         {
                                                  description = "The ansible remote user account to use"
                                                  default     = "azureadm"
                                                }
variable "app_instance_number"                  {
                                                  description = "Instance number for Additional Application Server"
                                                  default     = "00"
                                                }
variable "app_server_count"                     {
                                                  description = "Number of Application Servers"
                                                  type    = number
                                                }
variable "app_subnet_netmask"                   { description = "netmask for the SAP application subnet" }
variable "app_tier_os_types"                    { description = "Defines the app tier os types" }
variable "app_vm_names"                         { description = "List of VM names for the Application Servers" }
variable "application_server_ips"               { description = "List of IP addresses for the Application Servers" }
variable "application_server_secondary_ips"     { description = "List of secondary IP addresses for the Application Servers" }
variable "authentication_type"                  {
                                                  description = "VM Authentication type"
                                                  default     = "key"
                                                }
variable "authentication"                       { description = "Dictionary with authentication details" }
variable "bom_name"                             {
                                                  description = "Name of Bill of Materials file"
                                                  default     = ""
                                                }
variable "configuration_settings"               { description = "This is a dictionary that will contain values persisted to the sap-parameters.file" }
variable "database_admin_ips"                   { description = "List of Admin NICs for the DB VMs" }
variable "database_cluster_type"                {
                                                  description   = "Cluster quorum type; AFA (Azure Fencing Agent), ASD (Azure Shared Disk), ISCSI"
                                                  type          = string
                                                }
variable "database_high_availability"           {
                                                  description = "If true, the database tier will be configured for high availability"
                                                  default     = false
                                                }
variable "database"                             { description = "Dictionary with information on the database tier"}
variable "database_authentication_type"         {
                                                  description = "Platform to use"
                                                  default = "key"
                                                }
variable "database_cluster_ip"                  { description = "This is a Cluster IP address for Windows load balancer for the database" }
variable "database_loadbalancer_ip"             {
                                                  description = "DB Load Balancer IP"
                                                  default     = ""
                                                }
variable "db_server_count"                      {
                                                  description = "Number of Database Servers"
                                                  type    = number
                                                }
variable "database_server_ips"                  { description = "List of IP addresses for the database servers" }
variable "database_server_secondary_ips"        { description = "List of secondary IP addresses for the database servers" }
variable "database_shared_disks"                { description = "Database Azure Shared Disk" }
variable "database_server_vm_names"             { description = "List of VM names for the database servers" }
variable "is_use_fence_kdump"                   { description = "Use fence kdump for optional stonith configuration on RHEL" }
variable "db_sid"                               { description = "Database SID" }
variable "database_subnet_netmask"              { description = "netmask for the database subnet" }
variable "disks"                                { description = "List of disks" }
variable "dns_zone_names"                       {
                                                  description = "Private DNS zone names"
                                                  type        = map(string)
                                                  default = {
                                                              "file_dns_zone_name"   = "privatelink.file.core.windows.net"
                                                              "blob_dns_zone_name"   = "privatelink.blob.core.windows.net"
                                                              "table_dns_zone_name"  = "privatelink.table.core.windows.net"
                                                              "vault_dns_zone_name"  = "privatelink.vaultcore.azure.net"
                                                            }
                                                }
variable "dns"                                  {
                                                  description = "The DNS label"
                                                  default     = ""
                                                }
variable "dns_a_records_for_secondary_names"    { description = "Boolean value indicating if dns a records should be created for the secondary DNS names"}
variable "ers_instance_number"                  {
                                                  description = "Instance number for ERS"
                                                  default     = "02"
                                                }
variable "ers_server_loadbalancer_ip"                            {
                                                  description = "ERS Load Balancer IP"
                                                  default     = ""
                                                }
variable "hana_data"                            { description = "If defined provides the mount point for HANA data on ANF" }
variable "hana_log"                             { description = "If defined provides the mount point for HANA log on ANF" }
variable "hana_shared"                          { description = "If defined provides the mount point for HANA shared on ANF" }
variable "infrastructure"                       { description = "Dictionary with infrastructure details" }
variable "install_path"                         {
                                                  description = "Defines the install path for mounting /usr/sap/install"
                                                  default     = ""
                                                }
variable "iSCSI_server_ips"                     {
                                                  description = "List of IP addresses for the iSCSI Servers"
                                                  default     = []
                                                }
variable "iSCSI_server_names"                   {
                                                  description = "List of host names for the iSCSI Servers"
                                                  default     = []
                                                }
variable "iSCSI_servers"                        {
                                                  description = "List of host names and IPs for the iSCSI Servers"
                                                  default     = []
                                                }
variable "landscape_tfstate"                    { description = "Landscape remote tfstate file" }
variable "loadbalancers"                        { description = "List of LoadBalancers created for HANA Databases" }
variable "management_dns_resourcegroup_name"    {
                                                  description = "String value giving the possibility to register custom dns a records in a separate resourcegroup"
                                                  default     = null
                                                  type        = string
                                                }
variable "management_dns_subscription_id"       {
                                                  description = "String value giving the possibility to register custom dns a records in a separate subscription"
                                                  default     = null
                                                  type        = string
                                                }
variable "naming"                               { description = "Defines the names for the resources" }
variable "NFS_provider"                         {
                                                  description = "Defines the NFS provider"
                                                  type        = string
                                                }
variable "observer_ips"                         { description = "List of NICs for the Observer VMs" }
variable "observer_vms"                         { description = "List of Observer VMs" }
variable "pas_instance_number"                  {
                                                  description = "Instance number for Primary Application Server"
                                                  default     = "00"
                                                }
variable "platform"                             {
                                                  description = "Platform to use"
                                                  default     = "HANA"
                                                }
variable "random_id"                            { description = "Random hex string" }
variable "sap_mnt"                              {
                                                  description = "ANF Volume for SAP mount"
                                                  default     = ""
                                                }
variable "sap_sid"                              { description = "SAP SID" }
variable "sap_transport"                        {
                                                  description = "ANF Volume for SAP Transport"
                                                  default     = ""
                                                }
variable "save_naming_information"              {
                                                  description = "If defined, will save the naming information for the resources"
                                                  default     = false
                                                }
variable "scale_out"                            { description = "If true, the SAP System will be scale out" }
variable "scs_shared_disks"                     { description = "SCS Azure Shared Disk" }


variable "scs_cluster_loadbalancer_ip"          { description = "This is a Cluster IP address for Windows load balancer for central services" }
variable "scs_cluster_type"                     {
                                                  description   = "Cluster quorum type; AFA (Azure Fencing Agent), ASD (Azure Shared Disk), ISCSI"
                                                  type          = string
                                                }
variable "scs_high_availability"                {
                                                  description = "If true, the SAP Central Services tier will be configured for high availability"
                                                  default     = false
                                                }
variable "scs_instance_number"                  {
                                                  description = "Instance number for SCS"
                                                  default     = "00"
                                                }
variable "scs_server_loadbalancer_ip"           {
                                                  description = "SCS Load Balancer IP"
                                                  default     = ""
                                                }
variable "scs_server_count"                     {
                                                  description = "Number of SCS Servers"
                                                  type    = number
                                                }
variable "scs_server_ips"                       { description = "List of IP addresses for the SCS Servers" }
variable "scs_server_secondary_ips"             { description = "List of secondary IP addresses for the SCS Servers" }
variable "scs_vm_names"                         { description = "List of VM names for the SCS Servers" }
variable "shared_home"                          { description = "If defined provides shared-home support" }
variable "sid_keyvault_user_id"                 { description = "Defines the names for the resources" }
variable "tfstate_resource_id"                  { description = "Resource ID for tf state file" }
variable "upgrade_packages"                     { description = "Upgrade packages" }
variable "use_custom_dns_a_registration"        {
                                                  description = "Boolean value indicating if a custom dns a record should be created when using private endpoints"
                                                  default     = false
                                                  type        = bool
                                                }
variable "use_local_credentials"                { description = "SDU has unique credentials" }
variable "use_msi_for_clusters"                 { description = "If true, the Pacemaker cluser will use a managed identity" }
variable "use_secondary_ips"                    { description = "Use secondary IPs for the SAP System" }
variable "use_simple_mount"                     {
                                                  description = "Use simple mount"
                                                  default     = true
                                                }
variable "usr_sap"                              { description = "If defined provides the mount point for /usr/sap on ANF" }
variable "web_instance_number"                  {
                                                  description = "The Instance number for Web Dispatcher"
                                                  default     = "00"
                                                }
variable "web_server_count"                     {
                                                  description = "Number of Web Dispatchers"
                                                  type    = number
                                                }
variable "web_sid"                              {
                                                  description = "The sid of the web dispatchers"
                                                  default     = ""
                                                }
variable "webdispatcher_server_ips"             { description = "List of IP addresses for the Web dispatchers" }
variable "webdispatcher_server_secondary_ips"   { description = "List of secondary IP addresses for the Web dispatchers" }
variable "webdispatcher_server_vm_names"        { description = "List of VM names for the Web dispatchers" }

variable "ams_resource_id"                      { description = "Resource ID for AMS" }
variable "enable_os_monitoring"                 { description = "Enable OS monitoring" }
variable "enable_ha_monitoring"                 { description = "Enable HA monitoring" }

