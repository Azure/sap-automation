using MongoDB.Bson;
using MongoDB.Bson.Serialization.Attributes;
using System;
using System.ComponentModel;
using System.ComponentModel.DataAnnotations;

namespace AutomationForm.Models
{
    public class LandscapeModel
    {
        [BsonId]
        [DisplayName("Workload Zone ID")]
        public string Id { get; set; }

        // BASIC

        [Required]
        [DisplayName("Environment")]
        public string environment { get; set; }

        [Required]
        [DisplayName("Location")]
        public string location { get; set; }

        [Required]
        [DisplayName("Logical Network Name")]
        [RegularExpression(@"^\w{0,7}$", ErrorMessage = "Logical network name cannot exceed seven characters")]
        public string network_logical_name { get; set; }

        //[Required]
        [BsonIgnoreIfNull]
        [DisplayName("Network Address")]
        [RegularExpression(@"^\d+\.\d+\.\d+\.\d+\/\d+$", ErrorMessage = "Network address space must be a valid RFC 1918 address")]
        public string network_address_space { get; set; }

        // ADVANCED

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
        public string deployer_tfstate_key { get; set; }

        [BsonIgnoreIfNull]
        public string tfstate_resource_id { get; set; }

        [BsonIgnoreIfNull]
        [RegularExpression(@"^\/subscriptions\/\w{8}-\w{4}-\w{4}-\w{4}-\w{12}$", ErrorMessage = "Invalid subscription")]
        public string subscription { get; set; }

        [BsonIgnoreIfNull]
        [RegularExpression(@"^\/subscriptions\/\w{8}-\w{4}-\w{4}-\w{4}-\w{12}\/resourceGroups\/[a-zA-Z0-9-_]+$", ErrorMessage = "Invalid resource group arm id")]
        public string resource_group_arm_id { get; set; }

        [BsonIgnoreIfNull]
        public string resource_group_name { get; set; }

        
        [BsonIgnoreIfNull]
        [RegularExpression(@"^\/subscriptions\/\w{8}-\w{4}-\w{4}-\w{4}-\w{12}\/resourceGroups\/[a-zA-Z0-9-_]+\/providers\/Microsoft.Network\/virtualNetworks\/[a-zA-Z0-9-_]+$", ErrorMessage = "Invalid network address arm id")]
        public string network_address_arm_id { get; set; }

        
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
        [RegularExpression(@"^\/subscriptions\/\w{8}-\w{4}-\w{4}-\w{4}-\w{12}\/resourceGroups\/[a-zA-Z0-9-_]+\/providers\/Microsoft.Network\/virtualNetworks\/[a-zA-Z0-9-_]+\/subnets\/[a-zA-Z0-9-_]+$", ErrorMessage = "Invalid ISCSI subnet arm id")]
        public string iscsi_subnet_arm_id { get; set; }

        //[Required]
        [BsonIgnoreIfNull]
        [RegularExpression(@"^\d+\.\d+\.\d+\.\d+\/\d+$", ErrorMessage = "ISCSI subnet address space must be a valid RFC 1918 address")]
        public string iscsi_subnet_address_prefix { get; set; }

        [BsonIgnoreIfNull]
        public string iscsi_subnet_name { get; set; }

        [BsonIgnoreIfNull]
        [RegularExpression(@"^\/subscriptions\/\w{8}-\w{4}-\w{4}-\w{4}-\w{12}\/resourceGroups\/[a-zA-Z0-9-_]+\/providers\/Microsoft.Network\/networkSecurityGroups\/[a-zA-Z0-9-_]+$", ErrorMessage = "Invalid ISCSI subnet nsg arm id")]
        public string iscsi_subnet_nsg_arm_id { get; set; }

        [BsonIgnoreIfNull]
        public string iscsi_subnet_nsg_name { get; set; }


        [BsonIgnoreIfNull]
        [RegularExpression(@"^\/subscriptions\/\w{8}-\w{4}-\w{4}-\w{4}-\w{12}\/resourceGroups\/[a-zA-Z0-9-_]+\/providers\/Microsoft.Network\/virtualNetworks\/[a-zA-Z0-9-_]+\/subnets\/[a-zA-Z0-9-_]+$", ErrorMessage = "Invalid ANF subnet arm id")]
        public string anf_subnet_arm_id { get; set; }

        //[Required]
        [BsonIgnoreIfNull]
        [RegularExpression(@"^\d+\.\d+\.\d+\.\d+\/\d+$", ErrorMessage = "ANF subnet address space must be a valid RFC 1918 address")]
        public string anf_subnet_address_prefix { get; set; }

        [BsonIgnoreIfNull]
        public string anf_subnet_name { get; set; }

        [BsonIgnoreIfNull]
        [RegularExpression(@"^\/subscriptions\/\w{8}-\w{4}-\w{4}-\w{4}-\w{12}\/resourceGroups\/[a-zA-Z0-9-_]+\/providers\/Microsoft.Network\/networkSecurityGroups\/[a-zA-Z0-9-_]+$", ErrorMessage = "Invalid anf subnet nsg arm id")]
        public string anf_subnet_nsg_arm_id { get; set; }

        [BsonIgnoreIfNull]
        public string anf_subnet_nsg_name { get; set; }


        [BsonIgnoreIfNull]
        public string user_keyvault_id { get; set; }

        [BsonIgnoreIfNull]
        public string automation_keyvault_id { get; set; }

        [BsonIgnoreIfNull]
        public string spn_keyvault_id { get; set; }

        [BsonIgnoreIfNull]
        public string automation_password { get; set; }

        [BsonIgnoreIfNull]
        public string automation_path_to_public_key { get; set; }

        [BsonIgnoreIfNull]
        public string automation_path_to_private_key { get; set; }
    }
}
