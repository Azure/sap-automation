using System.ComponentModel;
using System.ComponentModel.DataAnnotations;
using static AutomationForm.Models.CustomValidators;

namespace AutomationForm.Models
{
    public class LandscapeModel
    {
        public bool IsValid()
        {
            return
                environment != null &&
                location != null &&
                network_logical_name != null
                ;
        }

        [DisplayName("Workload zone ID")]
        public string Id { get; set; }

        // BASIC

        public bool IsDefault { get; set; } = false;

        [RequiredIfNotDefault]
        [DisplayName("Environment")]
        public string environment { get; set; }

        [RequiredIfNotDefault]
        [DisplayName("Location")]
        [LocationValidator(ErrorMessage = "Location is not a valid Azure region")]
        public string location { get; set; }

        public string name_override_file { get; set; }
        public bool? save_naming_information { get; set; }

        [RequiredIfNotDefault]
        [DisplayName("Network name")]
        [RegularExpression(@"^\w{0,7}$", ErrorMessage = "Logical network name cannot exceed seven characters")]
        public string network_logical_name { get; set; }

        [VnetRequired]
        [DisplayName("Network address")]
        [AddressPrefixValidator(ErrorMessage = "Network address space must be a valid RFC 1918 address")]
        public string network_address_space { get; set; }

        // ADVANCED

        //[SubnetRequired(subnetType: "admin")]
        [AddressPrefixValidator(ErrorMessage = "Admin subnet address space must be a valid RFC 1918 address")]
        public string admin_subnet_address_prefix { get; set; }

        [SubnetRequired(subnetType: "db")]
        [AddressPrefixValidator(ErrorMessage = "DB subnet address space must be a valid RFC 1918 address")]
        public string db_subnet_address_prefix { get; set; }

        [SubnetRequired(subnetType: "app")]
        [AddressPrefixValidator(ErrorMessage = "App subnet address space must be a valid RFC 1918 address")]
        public string app_subnet_address_prefix { get; set; }

        //[SubnetRequired(subnetType: "web")]
        [AddressPrefixValidator(ErrorMessage = "Web subnet address space must be a valid RFC 1918 address")]
        public string web_subnet_address_prefix { get; set; }

        public string automation_username { get; set; } = "azureadm";

        // EXPERT 

        public string deployer_tfstate_key { get; set; }

        public string tfstate_resource_id { get; set; }

        [SubscriptionIdValidator(ErrorMessage = "Invalid subscription")]
        public string subscription { get; set; }

        [RgArmIdValidator(ErrorMessage = "Invalid resource group arm id")]
        public string resourcegroup_arm_id { get; set; }

        public string resourcegroup_name { get; set; }


        [NetworkAddressValidator(ErrorMessage = "Invalid network address arm id")]
        public string network_arm_id { get; set; }

        public string network_name { get; set; }


        [SubnetArmIdValidator(ErrorMessage = "Invalid admin subnet arm id")]
        public string admin_subnet_arm_id { get; set; }

        public string admin_subnet_name { get; set; }

        [NsgArmIdValidator(ErrorMessage = "Invalid admin subnet nsg arm id")]
        public string admin_subnet_nsg_arm_id { get; set; }

        public string admin_subnet_nsg_name { get; set; }


        [SubnetArmIdValidator(ErrorMessage = "Invalid db subnet arm id")]
        public string db_subnet_arm_id { get; set; }
        public string db_subnet_name { get; set; }

        [NsgArmIdValidator(ErrorMessage = "Invalid db subnet nsg arm id")]
        public string db_subnet_nsg_arm_id { get; set; }

        public string db_subnet_nsg_name { get; set; }


        [SubnetArmIdValidator(ErrorMessage = "Invalid app subnet arm id")]
        public string app_subnet_arm_id { get; set; }

        public string app_subnet_name { get; set; }

        [NsgArmIdValidator(ErrorMessage = "Invalid app subnet nsg arm id")]
        public string app_subnet_nsg_arm_id { get; set; }

        public string app_subnet_nsg_name { get; set; }


        [SubnetArmIdValidator(ErrorMessage = "Invalid web subnet arm id")]
        public string web_subnet_arm_id { get; set; }

        public string web_subnet_name { get; set; }

        [NsgArmIdValidator(ErrorMessage = "Invalid web subnet nsg arm id")]
        public string web_subnet_nsg_arm_id { get; set; }

        public string web_subnet_nsg_name { get; set; }


        [SubnetArmIdValidator(ErrorMessage = "Invalid ISCSI subnet arm id")]
        public string iscsi_subnet_arm_id { get; set; }

        //[Required]
        [AddressPrefixValidator(ErrorMessage = "ISCSI subnet address space must be a valid RFC 1918 address")]
        public string iscsi_subnet_address_prefix { get; set; }

        public string iscsi_subnet_name { get; set; }

        [NsgArmIdValidator(ErrorMessage = "Invalid ISCSI subnet nsg arm id")]
        public string iscsi_subnet_nsg_arm_id { get; set; }

        public string iscsi_subnet_nsg_name { get; set; }


        [SubnetArmIdValidator(ErrorMessage = "Invalid ANF subnet arm id")]
        public string anf_subnet_arm_id { get; set; }

        //[Required]
        [AddressPrefixValidator(ErrorMessage = "ANF subnet address space must be a valid RFC 1918 address")]
        public string anf_subnet_address_prefix { get; set; }

        public string anf_subnet_name { get; set; }

        [NsgArmIdValidator(ErrorMessage = "Invalid anf subnet nsg arm id")]
        public string anf_subnet_nsg_arm_id { get; set; }

        public string anf_subnet_nsg_name { get; set; }

        public string ANF_account_arm_id { get; set; }

        public string ANF_account_name { get; set; }

        public string ANF_service_level { get; set; }

        public int? ANF_pool_size { get; set; }

        public string ANF_qos_type { get; set; }

        public bool? use_private_endpoint { get; set; }

        public bool? use_service_endpoint { get; set; } = true;

        public bool? peer_with_control_plane_vnet { get; set; } = true;

        public bool? enable_firewall_for_keyvaults_and_storage { get; set; }

        public bool? ANF_use_existing_pool { get; set; }

        public string ANF_pool_name { get; set; }

        public bool? ANF_transport_volume_use_existing { get; set; }

        public string ANF_transport_volume_name { get; set; }

        public int? ANF_transport_volume_throughput { get; set; }

        public int? ANF_transport_volume_size { get; set; }

        public bool? ANF_install_volume_use_existing { get; set; }

        public string ANF_install_volume_name { get; set; }

        public int? ANF_install_volume_throughput { get; set; }

        public int? ANF_install_volume_size { get; set; }

        public string management_dns_resourcegroup_name { get; set; }

        public string management_dns_subscription_id { get; set; }

        public bool? use_custom_dns_a_registration { get; set; }


        [KeyvaultIdValidator]
        public string user_keyvault_id { get; set; }

        public bool? enable_purge_control_for_keyvaults { get; set; }

        [KeyvaultIdValidator]
        public string spn_keyvault_id { get; set; }

        public string automation_password { get; set; }

        public string automation_path_to_public_key { get; set; }

        public string automation_path_to_private_key { get; set; }


        public string dns_label { get; set; }

        public string dns_resource_group_name { get; set; }


        public string NFS_provider { get; set; }

        public int? transport_volume_size { get; set; }

        [GuidValidator]
        public string[] additional_users_to_add_to_keyvault_policies { get; set; }

        [StorageAccountIdValidator]
        public string diagnostics_storage_account_arm_id { get; set; }

        [StorageAccountIdValidator]
        public string witness_storage_account_arm_id { get; set; }

        [StorageAccountIdValidator]
        public string transport_storage_account_id { get; set; }

        [PrivateEndpointIdValidator]
        public string transport_private_endpoint_id { get; set; }

        [StorageAccountIdValidator]
        public string install_storage_account_id { get; set; }

        public int? install_volume_size { get; set; }

        [PrivateEndpointIdValidator]
        public string install_private_endpoint_id { get; set; }

        public int? utility_vm_count { get; set; } = 0;

        public string utility_vm_size { get; set; }

        public bool? utility_vm_useDHCP { get; set; }

        public Image utility_vm_image { get; set; }

        [IpAddressValidator]
        public string[] utility_vm_nic_ips { get; set; }
    }
}
