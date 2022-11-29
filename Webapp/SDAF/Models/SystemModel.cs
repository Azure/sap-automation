using System.ComponentModel;
using System.ComponentModel.DataAnnotations;
using static AutomationForm.Models.CustomValidators;

namespace AutomationForm.Models
{
    public class SystemModel
    {
        public bool IsValid()
        {
            return
                environment != null &&
                location != null &&
                network_logical_name != null &&
                sid != null
                ;
        }

        [DisplayName("System ID")]
        public string Id { get; set; }

        // BASIC

        public bool IsDefault { get; set; } = false;

        [DisplayName("Workload zone")]
        public string workload_zone { get; set; }

        [RequiredIfNotDefault]
        [DisplayName("Environment")]
        public string environment { get; set; }

        [RequiredIfNotDefault]
        [DisplayName("Location")]
        [LocationValidator(ErrorMessage = "Location is not a valid Azure region")]
        public string location { get; set; }

        [RequiredIfNotDefault]
        [DisplayName("Network name")]
        [RegularExpression(@"^\w{0,7}$", ErrorMessage = "Logical network name cannot exceed seven characters")]
        public string network_logical_name { get; set; }

        [RequiredIfNotDefault]
        [DisplayName("System ID")]
        public string sid { get; set; }

        //[Required]
        [AddressPrefixValidator(ErrorMessage = "Admin subnet address space must be a valid RFC 1918 address")]
        public string admin_subnet_address_prefix { get; set; }

        //[Required]
        [AddressPrefixValidator(ErrorMessage = "DB subnet address space must be a valid RFC 1918 address")]
        public string db_subnet_address_prefix { get; set; }

        //[Required]
        [AddressPrefixValidator(ErrorMessage = "App subnet address space must be a valid RFC 1918 address")]
        public string app_subnet_address_prefix { get; set; }

        //[Required]
        [AddressPrefixValidator(ErrorMessage = "Web subnet address space must be a valid RFC 1918 address")]
        public string web_subnet_address_prefix { get; set; }

        public string automation_username { get; set; }

        public bool? use_service_endpoint { get; set; }


        // ======= EXPERT =======

        // Common Infrastructure

        [SubscriptionIdValidator(ErrorMessage = "Invalid subscription")]
        public string subscription { get; set; }

        [RgArmIdValidator(ErrorMessage = "Invalid resource group arm id")]
        public string resourcegroup_arm_id { get; set; }

        public string resourcegroup_name { get; set; }

        public string custom_prefix { get; set; }

        public bool? use_prefix { get; set; } = true;
        public bool? use_secondary_ips { get; set; }

        public bool? use_zonal_markers { get; set; } = true;

        public bool? use_msi_for_clusters { get; set; } = true;

        public string fencing_role_name { get; set; }

        public string[] proximityplacementgroup_names { get; set; }

        [PpgIdValidator]
        public string[] proximityplacementgroup_arm_ids { get; set; }

        [NetworkAddressValidator]
        public string network_arm_id { get; set; }

        // Admin Subnet

        [SubnetArmIdValidator(ErrorMessage = "Invalid admin subnet arm id")]
        public string admin_subnet_arm_id { get; set; }

        public string admin_subnet_name { get; set; }

        [NsgArmIdValidator(ErrorMessage = "Invalid admin subnet nsg arm id")]
        public string admin_subnet_nsg_arm_id { get; set; }

        public string admin_subnet_nsg_name { get; set; }

        // Database subnet

        [SubnetArmIdValidator(ErrorMessage = "Invalid db subnet arm id")]
        public string db_subnet_arm_id { get; set; }
        public string db_subnet_name { get; set; }

        [NsgArmIdValidator(ErrorMessage = "Invalid db subnet nsg arm id")]
        public string db_subnet_nsg_arm_id { get; set; }

        public string db_subnet_nsg_name { get; set; }

        // Application Subnet

        [SubnetArmIdValidator(ErrorMessage = "Invalid app subnet arm id")]
        public string app_subnet_arm_id { get; set; }

        public string app_subnet_name { get; set; }

        [NsgArmIdValidator(ErrorMessage = "Invalid app subnet nsg arm id")]
        public string app_subnet_nsg_arm_id { get; set; }

        public string app_subnet_nsg_name { get; set; }

        // Web subnet

        [SubnetArmIdValidator(ErrorMessage = "Invalid web subnet arm id")]
        public string web_subnet_arm_id { get; set; }

        public string web_subnet_name { get; set; }

        [NsgArmIdValidator(ErrorMessage = "Invalid web subnet nsg arm id")]
        public string web_subnet_nsg_arm_id { get; set; }

        public string web_subnet_nsg_name { get; set; }

        // Database Tier

        [DatabasePlatformValidator]
        public string database_platform { get; set; }

        public bool? database_high_availability { get; set; }

        public int? database_server_count { get; set; } = 1;

        public bool? database_dual_nics { get; set; }

        public string database_size { get; set; }

        public string database_sid { get; set; }

        public string database_instance_number { get; set; }

        public string custom_disk_sizes_filename { get; set; }

        public bool? database_vm_use_DHCP { get; set; }

        public Image database_vm_image { get; set; }

        public string[] database_vm_zones { get; set; }

        public string database_vm_authentication_type { get; set; }

        [AvSetIdValidator]
        public string[] database_vm_avset_arm_ids { get; set; }

        public bool? database_no_ppg { get; set; } = false;

        public bool? database_no_avset { get; set; } = false;

        public Tag[] database_tags { get; set; }

        [IpAddressValidator]
        public string[] database_loadbalancer_ips { get; set; }

        [IpAddressValidator]
        public string[] database_vm_db_nic_ips { get; set; }

        public string database_HANA_use_ANF_scaleout_scenario { get; set; }

        public bool? dual_nics { get; set; } = true;

        [IpAddressValidator]
        public string[] database_vm_db_nic_secondary_ips { get; set; }

        [IpAddressValidator]
        public string[] database_vm_admin_nic_ips { get; set; }

        [IpAddressValidator]
        public string[] database_vm_storage_nic_ips { get; set; }

        // Application Tier

        public bool? enable_app_tier_deployment { get; set; } = true;

        public string app_tier_authentication_type { get; set; }

        public bool? app_tier_use_DHCP { get; set; } = true;

        public bool? app_tier_dual_nics { get; set; } = false;

        public string app_tier_sizing_dictionary_key { get; set; } = "Optimized";

        public bool? save_naming_information { get; set; } = false;

        public string name_override_file { get; set; }

        public bool? use_loadbalancers_for_standalone_deployments { get; set; } = true;

        // Application Servers

        public int? application_server_count { get; set; } = 1;

        public string application_server_sku { get; set; }

        public Image application_server_image { get; set; }

        public string[] application_server_zones { get; set; }

        [IpAddressValidator]
        public string[] application_server_admin_nic_ips { get; set; }

        public Tag[] application_server_tags { get; set; }

        [IpAddressValidator]
        public string[] application_server_app_nic_ips { get; set; }

        [IpAddressValidator]
        public string[] application_server_nic_secondary_ips { get; set; }

        public bool? application_server_no_avset { get; set; } = false;

        [AvSetIdValidator]
        public string[] application_server_vm_avset_arm_ids { get; set; }

        public bool? application_server_no_ppg { get; set; } = false;

        // SAP Central Services

        public int? scs_server_count { get; set; } = 1;

        public string scs_server_sku { get; set; }

        public bool? scs_high_availability { get; set; } = false;

        public string scs_instance_number { get; set; }

        public string ers_instance_number { get; set; }

        public Image scs_server_image { get; set; }

        public string[] scs_server_zones { get; set; }

        [IpAddressValidator]
        public string[] scs_server_app_nic_ips { get; set; }

        [IpAddressValidator]
        public string[] scs_server_admin_nic_ips { get; set; }

        [IpAddressValidator]
        public string[] scs_server_loadbalancer_ips { get; set; }

        public Tag[] scs_server_tags { get; set; }

        [IpAddressValidator]
        public string[] scs_server_nic_secondary_ips { get; set; }

        public bool? scs_server_no_avset { get; set; } = false;

        public bool? scs_server_no_ppg { get; set; } = false;

        // Web Dispatchers

        public int? webdispatcher_server_count { get; set; } = 0;

        public string webdispatcher_server_sku { get; set; }

        [IpAddressValidator]
        public string[] webdispatcher_server_app_nic_ips { get; set; }

        [IpAddressValidator]
        public string[] webdispatcher_server_admin_nic_ips { get; set; }

        [IpAddressValidator]
        public string[] webdispatcher_server_loadbalancer_ips { get; set; }

        public Tag[] webdispatcher_server_tags { get; set; }

        public string[] webdispatcher_server_zones { get; set; }

        public Image webdispatcher_server_image { get; set; }

        [IpAddressValidator]
        public string[] webdispatcher_server_nic_secondary_ips { get; set; }

        public bool? webdispatcher_server_no_avset { get; set; }

        public bool? webdispatcher_server_no_ppg { get; set; }

        // Authentication

        public string automation_password { get; set; }

        public string automation_path_to_public_key { get; set; }

        public string automation_path_to_private_key { get; set; }

        public int? resource_offset { get; set; }

        public string vm_disk_encryption_set_id { get; set; }

        public bool? nsg_asg_with_vnet { get; set; } = false;

        // NFS Support

        public string NFS_provider { get; set; }

        public int? sapmnt_volume_size { get; set; }

        public string azure_files_sapmnt_id { get; set; }

        [PrivateEndpointIdValidator]
        public string sapmnt_private_endpoint_id { get; set; }

        // ANF Settings

        public bool? ANF_HANA_data { get; set; }

        public int? ANF_HANA_data_volume_size { get; set; }

        public bool? ANF_HANA_data_use_existing_volume { get; set; }

        public string ANF_HANA_data_volume_name { get; set; }

        public int? ANF_HANA_data_volume_throughput { get; set; }

        public bool? ANF_HANA_log { get; set; }

        public int? ANF_HANA_log_volume_size { get; set; }

        public bool? ANF_HANA_log_use_existing { get; set; }

        public string ANF_HANA_log_volume_name { get; set; }

        public int? ANF_HANA_log_volume_throughput { get; set; }

        public bool? ANF_HANA_shared { get; set; }

        public int? ANF_HANA_shared_volume_size { get; set; }

        public bool? ANF_HANA_shared_use_existing { get; set; }

        public string ANF_HANA_shared_volume_name { get; set; }

        public int? ANF_HANA_shared_volume_throughput { get; set; }

        public bool? ANF_usr_sap { get; set; }

        public int? ANF_usr_sap_volume_size { get; set; }

        public bool? ANF_usr_sap_use_existing { get; set; }

        public string ANF_usr_sap_volume_name { get; set; }

        public int? ANF_usr_sap_throughput { get; set; }

        public bool? use_private_endpoint { get; set; }

        public bool? ANF_sapmnt { get; set; }

        public string ANF_sapmnt_volume_name { get; set; }

        public int? ANF_sapmnt_volume_size { get; set; }

        public int? ANF_sapmnt_volume_throughput { get; set; }

        // Anchor VM

        public string anchor_vm_authentication_username { get; set; }

        public bool? deploy_anchor_vm { get; set; }

        public string anchor_vm_sku { get; set; }

        public string anchor_vm_authentication_type { get; set; }

        public bool? anchor_vm_accelerated_networking { get; set; }

        public Image anchor_vm_image { get; set; }

        [IpAddressValidator]
        public string[] anchor_vm_nic_ips { get; set; }

        public bool? anchor_vm_use_DHCP { get; set; }

        public string bom_name { get; set; }


        [KeyvaultIdValidator]
        public string user_keyvault_id { get; set; }

        [KeyvaultIdValidator]
        public string spn_keyvault_id { get; set; }

        public bool? enable_purge_control_for_keyvaults { get; set; } = false;

        public bool? deploy_application_security_groups { get; set; } = true;
    }

    public class Tag
    {
        public string Key { get; set; }
        public string Value { get; set; }
    }

    public class Image
    {
        public string os_type { get; set; }

        public string source_image_id { get; set; }

        public string publisher { get; set; }

        public string offer { get; set; }

        public string sku { get; set; }

        public string version { get; set; }

        public string type { get; set; }
        public bool IsInitialized
        {
            get
            {
                return (os_type != null
                    || source_image_id != null
                    || publisher != null
                    || offer != null
                    || sku != null
                    || version != null
                    || type != null);
            }
        }
    }
}
