// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.

using System.ComponentModel;
using System.ComponentModel.DataAnnotations;
using static SDAFWebApp.Models.CustomValidators;

namespace SDAFWebApp.Models
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

        public string LastModified { get; set; }

        // BASIC

        public bool IsDefault { get; set; } = false;

        /*---------------------------------------------------------------------------8
        |                                                                            |
        |                         Generic information                                |
        |                                                                            |
        +------------------------------------4--------------------------------------*/

        [RequiredIfNotDefault]
        [DisplayName("Environment")]
        public string environment { get; set; }

        [RequiredIfNotDefault]
        [DisplayName("Location")]
        [LocationValidator(ErrorMessage = "Location is not a valid Azure region")]
        public string location { get; set; }

        public string Description { get; set; }

        public string name_override_file { get; set; }

        public bool? save_naming_information { get; set; }

        public bool? place_delete_lock_on_resources { get; set; } = false;

        public string controlPlaneLocation { get; set; }

        public Tag[] tags { get; set; }

        public string custom_random_id { get; set; }


        public bool? deploy_monitoring_extension { get; set; } = true;

        public bool? deploy_defender_extension { get; set; } = false;

        /*---------------------------------------------------------------------------8
        |                                                                            |
        |                       Networking information                               |
        |                                                                            |
        +------------------------------------4--------------------------------------*/

        [RequiredIfNotDefault]
        [DisplayName("Network name")]
        [RegularExpression(@"^\w{0,7}$", ErrorMessage = "Logical network name cannot exceed seven characters")]
        public string network_logical_name { get; set; }

        [VnetRequired]
        [DisplayName("Network address")]
        [AddressPrefixValidator(ErrorMessage = "Network address space must be a valid RFC 1918 address")]
        public string[] network_address_space { get; set; }
        public string network_name { get; set; }

        [NetworkAddressValidator(ErrorMessage = "Invalid network address arm id")]
        public string network_arm_id { get; set; }

        public int? network_flow_timeout_in_minutes { get; set; }

        public bool? network_enable_route_propagation { get; set; }

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

        [AddressPrefixValidator(ErrorMessage = "ANF subnet address space must be a valid RFC 1918 address")]
        public string anf_subnet_address_prefix { get; set; }

        public string anf_subnet_name { get; set; }

        [NsgArmIdValidator(ErrorMessage = "Invalid anf subnet nsg arm id")]
        public string anf_subnet_nsg_arm_id { get; set; }

        public string anf_subnet_nsg_name { get; set; }

        public bool? register_virtual_network_to_dns { get; set; } = true;

        public bool? use_private_endpoint { get; set; } = true;

        public bool? use_service_endpoint { get; set; } = true;

        public bool? peer_with_control_plane_vnet { get; set; } = true;

        [SubnetArmIdValidator(ErrorMessage = "Invalid AMS subnet arm id")]
        public string ams_subnet_arm_id { get; set; }

        //[Required]
        [AddressPrefixValidator(ErrorMessage = "AMS subnet address space must be a valid RFC 1918 address")]
        public string ams_subnet_address_prefix { get; set; }

        public string ams_subnet_name { get; set; }

        [NsgArmIdValidator(ErrorMessage = "Invalid AMS subnet nsg arm id")]
        public string ams_subnet_nsg_arm_id { get; set; }

        public string ams_subnet_nsg_name { get; set; }

        [SubnetArmIdValidator(ErrorMessage = "Invalid Storage subnet arm id")]
        public string storage_subnet_arm_id { get; set; }

        //[Required]
        [AddressPrefixValidator(ErrorMessage = "Storage subnet address space must be a valid RFC 1918 address")]
        public string storage_subnet_address_prefix { get; set; }

        public string storage_subnet_name { get; set; }

        [NsgArmIdValidator(ErrorMessage = "Invalid storage subnet nsg arm id")]
        public string storage_subnet_nsg_arm_id { get; set; }

        public string storage_subnet_nsg_name { get; set; }


        /*---------------------------------------------------------------------------8
        |                                                                            |
        |                       Miscallaneous information                            |
        |                                                                            |
        +------------------------------------4--------------------------------------*/

        public string automation_username { get; set; } = "azureadm";

        public string deployer_tfstate_key { get; set; }

        public string tfstate_resource_id { get; set; }

        [SubscriptionIdValidator(ErrorMessage = "Invalid subscription")]
        public string subscription { get; set; }

        public string subscription_id { get; set; }

        /*---------------------------------------------------------------------------8
        |                                                                            |
        |                       Resource Group information                           |
        |                                                                            |
        +------------------------------------4--------------------------------------*/

        [RgArmIdValidator(ErrorMessage = "Invalid resource group arm id")]
        public string resourcegroup_arm_id { get; set; }

        public string resourcegroup_name { get; set; }

        public bool? prevent_deletion_if_contains_resources { get; set; } = true;

        /*---------------------------------------------------------------------------8
        |                                                                            |
        |                       Azure NetApp Files information                       |
        |                                                                            |
        +------------------------------------4--------------------------------------*/
        public string ANF_account_arm_id { get; set; }

        public string ANF_account_name { get; set; }

        public string ANF_service_level { get; set; }

        public int? ANF_pool_size { get; set; }

        public string ANF_qos_type { get; set; }

        public bool? enable_firewall_for_keyvaults_and_storage { get; set; } = true;

        public bool? public_network_access_enabled { get; set; } = false;

        public bool? ANF_use_existing_pool { get; set; }

        public string ANF_pool_name { get; set; }

        public bool? ANF_transport_volume_use_existing { get; set; }

        public string ANF_transport_volume_name { get; set; }

        public int? ANF_transport_volume_throughput { get; set; }

        public int? ANF_transport_volume_size { get; set; }

        public string[] ANF_transport_volume_zone { get; set; }

        public bool? ANF_install_volume_use_existing { get; set; }

        public string ANF_install_volume_name { get; set; }

        public int? ANF_install_volume_throughput { get; set; }

        public int? ANF_install_volume_size { get; set; }

        public string[] ANF_install_volume_zone { get; set; }


        /*---------------------------------------------------------------------------8
        |                                                                            |
        |                              DNS information                               |
        |                                                                            |
        +------------------------------------4--------------------------------------*/

        public string management_dns_resourcegroup_name { get; set; }

        public string management_dns_subscription_id { get; set; }

        public string privatelink_dns_resourcegroup_name { get; set; }

        public string privatelink_dns_subscription_id { get; set; }

        public bool? use_custom_dns_a_registration { get; set; } = false;

        public string dns_label { get; set; }

        public string dns_resource_group_name { get; set; }

        [IpAddressValidator]
        public string[] dns_server_list { get; set; }

        public bool? register_endpoints_with_dns { get; set; } = true;


        /*---------------------------------------------------------------------------8
        |                                                                            |
        |                              Key vault information                         |
        |                                                                            |
        +------------------------------------4--------------------------------------*/

        [KeyvaultIdValidator]
        public string user_keyvault_id { get; set; }

        public bool? enable_purge_control_for_keyvaults { get; set; } = false;

        [KeyvaultIdValidator]
        public string spn_keyvault_id { get; set; }

        public string automation_password { get; set; }

        public string automation_path_to_public_key { get; set; }

        public string automation_path_to_private_key { get; set; }

        [GuidValidator]
        public string[] additional_users_to_add_to_keyvault_policies { get; set; }

        public bool? enable_rbac_authorization_for_keyvault { get; set; } = false;

        public int? soft_delete_retention_days { get; set; } = 7;

        public bool? set_secret_expiry { get; set; } = false;

        /*---------------------------------------------------------------------------8
        |                                                                            |
        |                                  NFS information                           |
        |                                                                            |
        +------------------------------------4--------------------------------------*/

        public string NFS_provider { get; set; }

        public bool? use_AFS_for_installation_media { get; set; } = true;

        public bool? use_AFS_for_shared_storage { get; set; } = true;

        public bool? create_transport_storage { get; set; } = true;

        public int? transport_volume_size { get; set; }

        /*---------------------------------------------------------------------------8
        |                                                                            |
        |                        Storage Account information                         |
        |                                                                            |
        +------------------------------------4--------------------------------------*/

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

        public int? install_volume_size { get; set; } = 1024;

        [PrivateEndpointIdValidator]
        public string install_private_endpoint_id { get; set; }

        public bool? shared_access_key_enabled { get; set; } = false;

        public bool? shared_access_key_enabled_nfs { get; set; } = false;

        public bool? install_always_create_fileshares { get; set; } = true;

        public bool? install_create_smb_shares { get; set; } = true;



        /*---------------------------------------------------------------------------8
        |                                                                            |
        |                             VM patch information                           |
        |                                                                            |
        +------------------------------------4--------------------------------------*/

        public string patch_mode { get; set; } = "ImageDefault";
        public string patch_assessment_mode { get; set; } = "ImageDefault";


        /*---------------------------------------------------------------------------8
        |                                                                            |
        |                         Utility VM information                             |
        |                                                                            |
        +------------------------------------4--------------------------------------*/

        public int? utility_vm_count { get; set; } = 0;

        public string utility_vm_size { get; set; }

        public string utility_vm_os_disk_size { get; set; } = "128";

        public string utility_vm_os_disk_type { get; set; } = "Premium_LRS";

        public bool? utility_vm_useDHCP { get; set; } = true;

        public Image utility_vm_image { get; set; }

        [IpAddressValidator]
        public string[] utility_vm_nic_ips { get; set; }

        public string storage_account_replication_type { get; set; } = "LRS";

        public string controlPlaneEnvironment { get; set; }

        /*---------------------------------------------------------------------------8
        |                                                                            |
        |                            iSCSI information                               |
        |                                                                            |
        +------------------------------------4--------------------------------------*/

        public int? iscsi_count { get; set; } = 0;

        public string iscsi_size { get; set; } = "Standard_D2s_v3";

        public bool? iscsi_useDHCP { get; set; } = true;

        public Image iscsi_image { get; set; }

        public string iscsi_authentication_type { get; set; } = "key";
        public string iscsi_authentication_username { get; set; } = "azureadm";

        public string[] iscsi_vm_zones { get; set; }

        public string[] iscsi_nic_ips { get; set; }

        /*---------------------------------------------------------------------------8
        |                                                                            |
        |                               Identity                                     |
        |                                                                            |
        +------------------------------------4--------------------------------------*/

        [UserAssignedIdentityIdValidator(ErrorMessage = "Invalid User Assigned id")]
        public string user_assigned_identity_id { get; set; }


        /*---------------------------------------------------------------------------8
        |                                                                            |
        |                               Deployment                                   |
        |                                                                            |
        +------------------------------------4--------------------------------------*/

        public bool? use_spn { get; set; } = false;


        /*---------------------------------------------------------------------------8
        |                                                                            |
        |                              AMS information                               |
        |                                                                            |
        +------------------------------------4--------------------------------------*/

        public bool? create_ams_instance { get; set; } = false;

        public string ams_instance_name { get; set; }

        [AMSIdValidator(ErrorMessage = "Invalid Workspace id")]
        public string ams_laws_arm_id { get; set; }


        /*---------------------------------------------------------------------------8
        |                                                                            |
        |                           NAT Gateway information                          |
        |                                                                            |
        +------------------------------------4--------------------------------------*/

        public bool? deploy_nat_gateway { get; set; } = false;

        public string nat_gateway_name { get; set; }


        [NATIdValidator(ErrorMessage = "Invalid NAT Gateway id")]
        public string nat_gateway_arm_id { get; set; }

        public string[] nat_gateway_public_ip_zones { get; set; }

        [PIPIdValidator(ErrorMessage = "Invalid Public IP id")]
        public string nat_gateway_public_ip_arm_id { get; set; }

        public int? nat_gateway_idle_timeout_in_minutes { get; set; }

        public Tag[] nat_gateway_public_ip_tags { get; set; }

        


#pragma warning restore IDE1006 // Naming Styles

    }
}
