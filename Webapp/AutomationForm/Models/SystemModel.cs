using MongoDB.Bson;
using MongoDB.Bson.Serialization.Attributes;
using System;
using System.ComponentModel;
using System.ComponentModel.DataAnnotations;

namespace AutomationForm.Models
{
    public class SystemModel
    {
        [BsonId]
        [DisplayName("System ID")]
        public string Id { get; set; }

        //[Required]
        [BsonIgnoreIfNull]
        [DisplayName("Workload Zone")]
        public string workload_zone { get; set; }
        
        //[Required]
        [BsonIgnoreIfNull]
        [DisplayName("System ID")]
        public string sid { get; set; }
        
        //[Required]
        [BsonIgnoreIfNull]
        [DisplayName("Environment")]
        public string environment { get; set; }

        //[Required]
        [BsonIgnoreIfNull]
        [DisplayName("Location")]
        public string location { get; set; }
        
        //[Required]
        [BsonIgnoreIfNull]
        [DisplayName("Network Name")]
        public string network_name { get; set; }

        // ADVANCED

        //[Required]
        [BsonIgnoreIfNull]
        public string deployer_tfstate_key { get; set; }

        //[Required]
        [BsonIgnoreIfNull]
        public string tfstate_resource_id { get; set; }

        //[Required]
        [BsonIgnoreIfNull]
        [RegularExpression(@"^\d+\.\d+\.\d+\.\d+\/\d+$", ErrorMessage = "Admin subnet address space must be a valid RFC 1918 address")]
        public string admin_subnet_address_prefix { get; set; }

        //[Required]
        [BsonIgnoreIfNull]
        [RegularExpression(@"^\d+\.\d+\.\d+\.\d+\/\d+$", ErrorMessage = "DB subnet address space must be a valid RFC 1918 address")]
        public string db_subnet_address_prefix { get; set; }

        //[Required]
        [BsonIgnoreIfNull]
        [RegularExpression(@"^\d+\.\d+\.\d+\.\d+\/\d+$", ErrorMessage = "App subnet address space must be a valid RFC 1918 address")]
        public string app_subnet_address_prefix { get; set; }

        [BsonIgnoreIfNull]
        public string automation_username { get; set; }

        // EXPERT

        [BsonIgnoreIfNull]
        [RegularExpression(@"^\/subscriptions\/\w{8}-\w{4}-\w{4}-\w{4}-\w{12}\/resourceGroups\/[a-zA-Z0-9-_]+$", ErrorMessage = "Invalid resource group arm id")]
        public string resource_group_arm_id { get; set; }

        [BsonIgnoreIfNull]
        public string resource_group_name { get; set; }
        
        [BsonIgnoreIfNull]
        public string[] proximityplacementgroup_names { get; set; }
        
        [BsonIgnoreIfNull]
        public string[] proximityplacementgroup_arm_ids { get; set; }

        [BsonIgnoreIfNull]
        [RegularExpression(@"^\/subscriptions\/\w{8}-\w{4}-\w{4}-\w{4}-\w{12}\/resourceGroups\/[a-zA-Z0-9-_]+\/providers\/Microsoft.Network\/virtualNetworks\/[a-zA-Z0-9-_]+\/subnets\/[a-zA-Z0-9-_]+$", ErrorMessage = "Invalid admin subnet arm id")]
        public string admin_subnet_arm_id { get; set; }

        [BsonIgnoreIfNull]
        public string admin_subnet_name { get; set; }

        [BsonIgnoreIfNull]
        [RegularExpression(@"^\/subscriptions\/\w{8}-\w{4}-\w{4}-\w{4}-\w{12}\/resourceGroups\/[a-zA-Z0-9-_]+\/providers\/Microsoft.Network\/networkSecurityGroups\/[a-zA-Z0-9-_]+$", ErrorMessage = "Invalid admin subnet nsg arm id")]
        public string admin_subnet_nsg_arm_id { get; set; }

        [BsonIgnoreIfNull]
        public string admin_subnet_nsg_name { get; set; }


        [BsonIgnoreIfNull]
        [RegularExpression(@"^\/subscriptions\/\w{8}-\w{4}-\w{4}-\w{4}-\w{12}\/resourceGroups\/[a-zA-Z0-9-_]+\/providers\/Microsoft.Network\/virtualNetworks\/[a-zA-Z0-9-_]+\/subnets\/[a-zA-Z0-9-_]+$", ErrorMessage = "Invalid db subnet arm id")]
        public string db_subnet_arm_id { get; set; }
        [BsonIgnoreIfNull]
        public string db_subnet_name { get; set; }

        [BsonIgnoreIfNull]
        [RegularExpression(@"^\/subscriptions\/\w{8}-\w{4}-\w{4}-\w{4}-\w{12}\/resourceGroups\/[a-zA-Z0-9-_]+\/providers\/Microsoft.Network\/networkSecurityGroups\/[a-zA-Z0-9-_]+$", ErrorMessage = "Invalid db subnet nsg arm id")]
        public string db_subnet_nsg_arm_id { get; set; }

        [BsonIgnoreIfNull]
        public string db_subnet_nsg_name { get; set; }


        [BsonIgnoreIfNull]
        [RegularExpression(@"^\/subscriptions\/\w{8}-\w{4}-\w{4}-\w{4}-\w{12}\/resourceGroups\/[a-zA-Z0-9-_]+\/providers\/Microsoft.Network\/virtualNetworks\/[a-zA-Z0-9-_]+\/subnets\/[a-zA-Z0-9-_]+$", ErrorMessage = "Invalid app subnet arm id")]
        public string app_subnet_arm_id { get; set; }

        [BsonIgnoreIfNull]
        public string app_subnet_name { get; set; }

        [BsonIgnoreIfNull]
        [RegularExpression(@"^\/subscriptions\/\w{8}-\w{4}-\w{4}-\w{4}-\w{12}\/resourceGroups\/[a-zA-Z0-9-_]+\/providers\/Microsoft.Network\/networkSecurityGroups\/[a-zA-Z0-9-_]+$", ErrorMessage = "Invalid app subnet nsg arm id")]
        public string app_subnet_nsg_arm_id { get; set; }

        [BsonIgnoreIfNull]
        public string app_subnet_nsg_name { get; set; }


        [BsonIgnoreIfNull]
        [RegularExpression(@"^\/subscriptions\/\w{8}-\w{4}-\w{4}-\w{4}-\w{12}\/resourceGroups\/[a-zA-Z0-9-_]+\/providers\/Microsoft.Network\/virtualNetworks\/[a-zA-Z0-9-_]+\/subnets\/[a-zA-Z0-9-_]+$", ErrorMessage = "Invalid web subnet arm id")]
        public string web_subnet_arm_id { get; set; }

        //[Required]
        [BsonIgnoreIfNull]
        [RegularExpression(@"^\d+\.\d+\.\d+\.\d+\/\d+$", ErrorMessage = "Web subnet address space must be a valid RFC 1918 address")]
        public string web_subnet_address_prefix { get; set; }

        [BsonIgnoreIfNull]
        public string web_subnet_name { get; set; }

        [BsonIgnoreIfNull]
        [RegularExpression(@"^\/subscriptions\/\w{8}-\w{4}-\w{4}-\w{4}-\w{12}\/resourceGroups\/[a-zA-Z0-9-_]+\/providers\/Microsoft.Network\/networkSecurityGroups\/[a-zA-Z0-9-_]+$", ErrorMessage = "Invalid web subnet nsg arm id")]
        public string web_subnet_nsg_arm_id { get; set; }

        [BsonIgnoreIfNull]
        public string web_subnet_nsg_name { get; set; }


        [BsonIgnoreIfNull]
        public string database_platform { get; set; }

        [BsonIgnoreIfNull]
        public string database_high_availability { get; set; }

        [BsonIgnoreIfNull]
        public string database_size { get; set; }

        [BsonIgnoreIfNull]
        public string database_sid { get; set; }

        [BsonIgnoreIfNull]
        public string database_instance_number { get; set; }

        [BsonIgnoreIfNull]
        public string db_disk_sizes_filename { get; set; }

        [BsonIgnoreIfNull]
        public string database_vm_use_DHCP { get; set; }

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

    }

    public class Image
    {
        public string os_type { get; set; }
        public string source_image_id { get; set; }
        public string publisher { get; set; }
        public string offer { get; set; }
        public string sku { get; set; }
    }
}
