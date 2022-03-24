using AutomationForm.Controllers;
using MongoDB.Bson;
using MongoDB.Bson.Serialization.Attributes;
using System;
using System.ComponentModel;
using System.ComponentModel.DataAnnotations;
using static AutomationForm.Models.CustomValidators;

namespace AutomationForm.Models
{
    [BsonIgnoreExtraElements]
    public class SystemModel
    {
        [BsonId]
        [DisplayName("System ID")]
        public string Id { get; set; }

        // BASIC

        [BsonIgnoreIfNull]
        [DisplayName("Workload zone")]
        public string workload_zone { get; set; }
        
        [Required]
        [DisplayName("Environment")]
        public string environment { get; set; }

        [Required]
        [DisplayName("Location")]
        [LocationValidator(ErrorMessage = "Location is not a valid Azure region")]
        public string location { get; set; }

        [Required]
        [DisplayName("Network name")]
        [RegularExpression(@"^\w{0,7}$", ErrorMessage = "Logical network name cannot exceed seven characters")]
        public string network_logical_name { get; set; }

        [Required]
        [DisplayName("System ID")]
        public string sid { get; set; }

        // ADVANCED

        [BsonIgnoreIfNull]
        public string tfstate_resource_id { get; set; }

        [BsonIgnoreIfNull]
        public string deployer_tfstate_key { get; set; }

        [BsonIgnoreIfNull]
        public string landscape_tfstate_key { get; set; }

        //[Required]
        [BsonIgnoreIfNull]
        [IpAddressValidator(ErrorMessage = "Admin subnet address space must be a valid RFC 1918 address")]
        public string admin_subnet_address_prefix { get; set; }

        //[Required]
        [BsonIgnoreIfNull]
        [IpAddressValidator(ErrorMessage = "DB subnet address space must be a valid RFC 1918 address")]
        public string db_subnet_address_prefix { get; set; }

        //[Required]
        [BsonIgnoreIfNull]
        [IpAddressValidator(ErrorMessage = "App subnet address space must be a valid RFC 1918 address")]
        public string app_subnet_address_prefix { get; set; }

        //[Required]
        [BsonIgnoreIfNull]
        [IpAddressValidator(ErrorMessage = "Web subnet address space must be a valid RFC 1918 address")]
        public string web_subnet_address_prefix { get; set; }

        [BsonIgnoreIfNull]
        public string automation_username { get; set; }

        // ======= EXPERT =======

        // Common Infrastructure

        [BsonIgnoreIfNull]
        [SubscriptionIdValidator(ErrorMessage = "Invalid subscription")]
        public string subscription { get; set; }

        [BsonIgnoreIfNull]
        [RgArmIdValidator(ErrorMessage = "Invalid resource group arm id")]
        public string resourcegroup_arm_id { get; set; }

        [BsonIgnoreIfNull]
        public string resourcegroup_name { get; set; }

        [BsonIgnoreIfNull]
        public string custom_prefix { get; set; }

        [BsonIgnoreIfNull]
        public bool? use_prefix { get; set; }
        
        [BsonIgnoreIfNull]
        public string[] proximityplacementgroup_names { get; set; }
        
        [BsonIgnoreIfNull]
        public string[] proximityplacementgroup_arm_ids { get; set; }

        // Network

        [BsonIgnoreIfNull]
        [NetworkAddressValidator(ErrorMessage = "Invalid network address arm id")]
        public string network_address_arm_id { get; set; }

        // Admin Subnet

        [BsonIgnoreIfNull]
        [SubnetArmIdValidator(ErrorMessage = "Invalid admin subnet arm id")]
        public string admin_subnet_arm_id { get; set; }

        [BsonIgnoreIfNull]
        public string admin_subnet_name { get; set; }

        [BsonIgnoreIfNull]
        [NsgArmIdValidator(ErrorMessage = "Invalid admin subnet nsg arm id")]
        public string admin_subnet_nsg_arm_id { get; set; }

        [BsonIgnoreIfNull]
        public string admin_subnet_nsg_name { get; set; }

        // Database subnet

        [BsonIgnoreIfNull]
        [SubnetArmIdValidator(ErrorMessage = "Invalid db subnet arm id")]
        public string db_subnet_arm_id { get; set; }
        [BsonIgnoreIfNull]
        public string db_subnet_name { get; set; }

        [BsonIgnoreIfNull]
        [NsgArmIdValidator(ErrorMessage = "Invalid db subnet nsg arm id")]
        public string db_subnet_nsg_arm_id { get; set; }

        [BsonIgnoreIfNull]
        public string db_subnet_nsg_name { get; set; }

        // Application Subnet

        [BsonIgnoreIfNull]
        [SubnetArmIdValidator(ErrorMessage = "Invalid app subnet arm id")]
        public string app_subnet_arm_id { get; set; }

        [BsonIgnoreIfNull]
        public string app_subnet_name { get; set; }

        [BsonIgnoreIfNull]
        [NsgArmIdValidator(ErrorMessage = "Invalid app subnet nsg arm id")]
        public string app_subnet_nsg_arm_id { get; set; }

        [BsonIgnoreIfNull]
        public string app_subnet_nsg_name { get; set; }

        // Web subnet

        [BsonIgnoreIfNull]
        [SubnetArmIdValidator(ErrorMessage = "Invalid web subnet arm id")]
        public string web_subnet_arm_id { get; set; }

        [BsonIgnoreIfNull]
        public string web_subnet_name { get; set; }

        [BsonIgnoreIfNull]
        [NsgArmIdValidator(ErrorMessage = "Invalid web subnet nsg arm id")]
        public string web_subnet_nsg_arm_id { get; set; }

        [BsonIgnoreIfNull]
        public string web_subnet_nsg_name { get; set; }

        // Database Tier 

        [BsonIgnoreIfNull]
        public string database_platform { get; set; }

        [BsonIgnoreIfNull]
        public bool? database_high_availability { get; set; }

        [BsonIgnoreIfNull]
        public string database_size { get; set; }

        [BsonIgnoreIfNull]
        public string database_sid { get; set; }

        [BsonIgnoreIfNull]
        public string database_instance_number { get; set; }

        [BsonIgnoreIfNull]
        public string db_disk_sizes_filename { get; set; }

        [BsonIgnoreIfNull]
        public bool? database_vm_use_DHCP { get; set; }

        [BsonIgnoreIfNull]
        public Image database_vm_image { get; set; }

        [BsonIgnoreIfNull]
        public string[] database_vm_zones { get; set; }

        [BsonIgnoreIfNull]
        public string database_vm_authentication_type { get; set; }

        [BsonIgnoreIfNull]
        public string[] database_vm_avset_arm_ids { get; set; }
        
        [BsonIgnoreIfNull]
        public string database_no_ppg { get; set; }

        [BsonIgnoreIfNull]
        public string database_no_avset { get; set; }

        [BsonIgnoreIfNull]
        public string[] database_tags { get; set; }

        [BsonIgnoreIfNull]
        public string database_HANA_use_ANF_scaleout_scenario { get; set; }

        [BsonIgnoreIfNull]
        public string dual_nics { get; set; }

        // Application Tier

        [BsonIgnoreIfNull]
        public bool? enable_app_tier_deployment { get; set; }

        [BsonIgnoreIfNull]
        public string app_tier_authentication_type { get; set; }

        [BsonIgnoreIfNull]
        public bool? app_tier_use_DHCP { get; set; }

        [BsonIgnoreIfNull]
        public bool? app_tier_dual_nics { get; set; }

        [BsonIgnoreIfNull]
        public string app_tier_vm_sizing { get; set; }

        [BsonIgnoreIfNull]
        public string app_disk_sizes_filename { get; set; }
        
        [BsonIgnoreIfNull]
        public bool? use_loadbalancers_for_standalone_deployments { get; set; }

        // Application Servers

        [BsonIgnoreIfNull]
        public int? application_server_count { get; set; }

        [BsonIgnoreIfNull]
        public string application_server_sku { get; set; }

        [BsonIgnoreIfNull]
        public Image application_server_image { get; set; }

        [BsonIgnoreIfNull]
        public string[] application_server_zones { get; set; }

        [BsonIgnoreIfNull]
        public string[] application_server_app_nic_ips { get; set; }

        [BsonIgnoreIfNull]
        public string[] application_server_app_admin_nic_ips { get; set; }

        [BsonIgnoreIfNull]
        public string[] application_server_tags { get; set; } // change data structure

        // SAP Central Services

        [BsonIgnoreIfNull]
        public int? scs_server_count { get; set; }

        [BsonIgnoreIfNull]
        public string scs_server_sku { get; set; }

        [BsonIgnoreIfNull]
        public bool? scs_high_availability { get; set; }

        [BsonIgnoreIfNull]
        public string scs_instance_number { get; set; }

        [BsonIgnoreIfNull]
        public string ers_instance_number { get; set; }

        [BsonIgnoreIfNull]
        public Image scs_server_image { get; set; }

        [BsonIgnoreIfNull]
        public string[] scs_server_zones { get; set; }

        [BsonIgnoreIfNull]
        public string[] scs_server_app_nic_ips { get; set; }

        [BsonIgnoreIfNull]
        public string[] scs_server_app_admin_nic_ips { get; set; }

        [BsonIgnoreIfNull]
        public string[] scs_server_loadbalancer_ips { get; set; }

        [BsonIgnoreIfNull]
        public string[] scs_server_tags { get; set; } // change data structure

        // Web Dispatchers

        [BsonIgnoreIfNull]
        public int? webdispatcher_server_count { get; set; }

        [BsonIgnoreIfNull]
        public string webdispatcher_server_sku { get; set; }

        [BsonIgnoreIfNull]
        public string[] webdispatcher_server_app_nic_ips { get; set; }

        [BsonIgnoreIfNull]
        public string[] webdispatcher_server_app_admin_nic_ips { get; set; }

        [BsonIgnoreIfNull]
        public string[] webdispatcher_server_loadbalancer_ips { get; set; }

        [BsonIgnoreIfNull]
        public string[] webdispatcher_server_tags { get; set; } // change data structure

        [BsonIgnoreIfNull]
        public string[] webdispatcher_server_zones { get; set; }

        [BsonIgnoreIfNull]
        public Image webdispatcher_server_image { get; set; }

        // Authentication

        [BsonIgnoreIfNull]
        public string automation_password { get; set; }

        [BsonIgnoreIfNull]
        public string automation_path_to_public_key { get; set; }

        [BsonIgnoreIfNull]
        public string automation_path_to_private_key { get; set; }

        [BsonIgnoreIfNull]
        public int? resource_offset { get; set; }

        [BsonIgnoreIfNull]
        public string vm_disk_encryption_set_id { get; set; }

        [BsonIgnoreIfNull]
        public bool? nsg_asg_with_vnet { get; set; }

        // NFS Support

        [BsonIgnoreIfNull]
        public string NFS_provider { get; set; }

        [BsonIgnoreIfNull]
        public int? sapmnt_volume_size { get; set; }

        // Anchor VM

        [BsonIgnoreIfNull]
        public bool? deploy_anchor_vm { get; set; }

        [BsonIgnoreIfNull]
        public string anchor_vm_sku { get; set; }

        [BsonIgnoreIfNull]
        public string anchor_vm_authentication_type { get; set; }

        [BsonIgnoreIfNull]
        public bool? anchor_vm_accelerated_networking { get; set; }

        [BsonIgnoreIfNull]
        public Image anchor_vm_image { get; set; }

        [BsonIgnoreIfNull]
        public string[] anchor_vm_nic_ips { get; set; }

        [BsonIgnoreIfNull]
        public bool? anchor_vm_use_DHCP { get; set; }

        [BsonIgnoreIfNull]
        public string bom_base { get; set; }
    }

    public class Image
    {
        [BsonIgnoreIfNull]
        public string os_type { get; set; }

        [BsonIgnoreIfNull]
        public string source_image_id { get; set; }

        [BsonIgnoreIfNull]
        public string publisher { get; set; }

        [BsonIgnoreIfNull]
        public string offer { get; set; }

        [BsonIgnoreIfNull]
        public string sku { get; set; }
        
        [BsonIgnoreIfNull]
        public string version { get; set; }
    }
}
