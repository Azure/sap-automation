using MongoDB.Bson;
using MongoDB.Bson.Serialization.Attributes;
using System;
using System.ComponentModel;
using System.ComponentModel.DataAnnotations;
using static AutomationForm.Models.CustomValidators;

namespace AutomationForm.Models
{
    [BsonIgnoreExtraElements]
    public class LandscapeModel
    {
        [BsonId]
        [DisplayName("Workload zone ID")]
        public string Id { get; set; }

        // BASIC

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

        [VnetRequired]
        [BsonIgnoreIfNull]
        [DisplayName("Network address")]
        [IpAddressValidator(ErrorMessage = "Network address space must be a valid RFC 1918 address")]
        public string network_address_space { get; set; }

        // ADVANCED

        [SubnetRequired(subnetType: "admin")]
        [BsonIgnoreIfNull]
        [IpAddressValidator(ErrorMessage = "Admin subnet address space must be a valid RFC 1918 address")]
        public string admin_subnet_address_prefix { get; set; }

        [SubnetRequired(subnetType: "db")]
        [BsonIgnoreIfNull]
        [IpAddressValidator(ErrorMessage = "DB subnet address space must be a valid RFC 1918 address")]
        public string db_subnet_address_prefix { get; set; }

        [SubnetRequired(subnetType: "app")]
        [BsonIgnoreIfNull]
        [IpAddressValidator(ErrorMessage = "App subnet address space must be a valid RFC 1918 address")]
        public string app_subnet_address_prefix { get; set; }

        [SubnetRequired(subnetType: "web")]
        [BsonIgnoreIfNull]
        [IpAddressValidator(ErrorMessage = "Web subnet address space must be a valid RFC 1918 address")]
        public string web_subnet_address_prefix { get; set; }

        [BsonIgnoreIfNull]
        public string automation_username { get; set; }

        // EXPERT 

        [BsonIgnoreIfNull]
        public string deployer_tfstate_key { get; set; }

        [BsonIgnoreIfNull]
        public string tfstate_resource_id { get; set; }

        [BsonIgnoreIfNull]
        [SubscriptionIdValidator(ErrorMessage = "Invalid subscription")]
        public string subscription { get; set; }

        [BsonIgnoreIfNull]
        [RgArmIdValidator(ErrorMessage = "Invalid resource group arm id")]
        public string resourcegroup_arm_id { get; set; }

        [BsonIgnoreIfNull]
        public string resourcegroup_name { get; set; }

        
        [BsonIgnoreIfNull]
        [NetworkAddressValidator(ErrorMessage = "Invalid network address arm id")]
        public string network_arm_id { get; set; }

        [BsonIgnoreIfNull]
        public string network_name { get; set; }

        
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


        [BsonIgnoreIfNull]
        [SubnetArmIdValidator(ErrorMessage = "Invalid ISCSI subnet arm id")]
        public string iscsi_subnet_arm_id { get; set; }

        //[Required]
        [BsonIgnoreIfNull]
        [IpAddressValidator(ErrorMessage = "ISCSI subnet address space must be a valid RFC 1918 address")]
        public string iscsi_subnet_address_prefix { get; set; }

        [BsonIgnoreIfNull]
        public string iscsi_subnet_name { get; set; }

        [BsonIgnoreIfNull]
        [NsgArmIdValidator(ErrorMessage = "Invalid ISCSI subnet nsg arm id")]
        public string iscsi_subnet_nsg_arm_id { get; set; }

        [BsonIgnoreIfNull]
        public string iscsi_subnet_nsg_name { get; set; }


        [BsonIgnoreIfNull]
        [SubnetArmIdValidator(ErrorMessage = "Invalid ANF subnet arm id")]
        public string anf_subnet_arm_id { get; set; }

        //[Required]
        [BsonIgnoreIfNull]
        [IpAddressValidator(ErrorMessage = "ANF subnet address space must be a valid RFC 1918 address")]
        public string anf_subnet_address_prefix { get; set; }

        [BsonIgnoreIfNull]
        public string anf_subnet_name { get; set; }

        [BsonIgnoreIfNull]
        [NsgArmIdValidator(ErrorMessage = "Invalid anf subnet nsg arm id")]
        public string anf_subnet_nsg_arm_id { get; set; }

        [BsonIgnoreIfNull]
        public string anf_subnet_nsg_name { get; set; }

        [BsonIgnoreIfNull]
        public string ANF_account_arm_id { get; set; }
        
        [BsonIgnoreIfNull]
        public string ANF_account_name { get; set; }

        [BsonIgnoreIfNull]
        public string ANF_service_level { get; set; }

        [BsonIgnoreIfNull]
        public int? ANF_pool_size { get; set; }

        [BsonIgnoreIfNull]
        public bool? use_private_endpoint { get; set; }

        
        [BsonIgnoreIfNull]
        public bool? ANF_use_existing_pool { get; set; }

        [BsonIgnoreIfNull]
        public string ANF_pool_name { get; set; }
        
        [BsonIgnoreIfNull]
        public bool? ANF_use_existing_transport_volume { get; set; }

        [BsonIgnoreIfNull]
        public string ANF_transport_volume_name { get; set; }

        [BsonIgnoreIfNull]
        public int? ANF_transport_volume_throughput { get; set; }

        [BsonIgnoreIfNull]
        public int? ANF_transport_volume_size { get; set; }

        [BsonIgnoreIfNull]
        public bool? ANF_use_existing_install_volume { get; set; }

        [BsonIgnoreIfNull]
        public string ANF_install_volume_name { get; set; }

        [BsonIgnoreIfNull]
        public int? ANF_install_volume_throughput { get; set; }

        [BsonIgnoreIfNull]
        public int? ANF_install_volume_size { get; set; }


        [BsonIgnoreIfNull]
        [KeyvaultIdValidator]
        public string user_keyvault_id { get; set; }

        [BsonIgnoreIfNull]
        [KeyvaultIdValidator]
        public string automation_keyvault_id { get; set; }

        [BsonIgnoreIfNull]
        public bool? enable_purge_control_for_keyvaults { get; set; }

        [BsonIgnoreIfNull]
        [KeyvaultIdValidator]
        public string spn_keyvault_id { get; set; }

        [BsonIgnoreIfNull]
        public string automation_password { get; set; }

        [BsonIgnoreIfNull]
        public string automation_path_to_public_key { get; set; }

        [BsonIgnoreIfNull]
        public string automation_path_to_private_key { get; set; }
        

        [BsonIgnoreIfNull]
        public string dns_label { get; set; }

        [BsonIgnoreIfNull]
        public string dns_resource_group_name { get; set; }


        [BsonIgnoreIfNull]
        public string NFS_provider { get; set; }

        [BsonIgnoreIfNull]
        public int? transport_volume_size { get; set; }


        [BsonIgnoreIfNull]
        [StorageAccountIdValidator]
        public string diagnostics_storage_account_arm_id { get; set; }
        
        [BsonIgnoreIfNull]
        [StorageAccountIdValidator]
        public string witness_storage_account_arm_id { get; set; }

        [BsonIgnoreIfNull]
        [StorageAccountIdValidator]
        public string transport_storage_account_id { get; set; }

        [BsonIgnoreIfNull]
        [PrivateEndpointIdValidator]
        public string transport_private_endpoint_id { get; set; }

        [BsonIgnoreIfNull]
        [StorageAccountIdValidator]
        public string install_storage_account_id { get; set; }

        [BsonIgnoreIfNull]
        public int? install_volume_size { get; set; }

        [BsonIgnoreIfNull]
        [PrivateEndpointIdValidator]
        public string install_private_endpoint_id { get; set; }
    }
}
