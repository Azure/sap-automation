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

    /*---------------------------------------------------------------------------8
    |                                                                            |
    |                         Generic information                                |
    |                                                                            |
    +------------------------------------4--------------------------------------*/


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


    // Common Infrastructure

    [SubscriptionIdValidator(ErrorMessage = "Invalid subscription")]
    public string subscription { get; set; }

    public string custom_disk_sizes_filename { get; set; }

    public bool? save_naming_information { get; set; } = false;

    public string name_override_file { get; set; }

    public bool? use_loadbalancers_for_standalone_deployments { get; set; } = true;

    public bool? dual_nics { get; set; } = true;

    public bool? deploy_application_security_groups { get; set; } = true;

    public bool? deploy_v1_monitoring_extension { get; set; } = true;

    public bool? use_scalesets_for_deployment { get; set; } = false;

    public bool? database_use_premium_v2_storage { get; set; } = false;

    public Tag[] tags { get; set; }

    [UserAssignedIdentityIdValidator(ErrorMessage = "Invalid User Assigned id")]
    public string user_assigned_identity_id { get; set; }

    [ScaleSetIdValidator(ErrorMessage = "Invalid Scaleset id")]
    public string scaleset_id { get; set; }

    /*---------------------------------------------------------------------------8
    |                                                                            |
    |                       Networking information                               |
    |                       provides override capabilities                       |
    |                                                                            |
    +------------------------------------4--------------------------------------*/
    [NetworkAddressValidator]
    public string network_arm_id { get; set; }

    // Admin Subnet

    [AddressPrefixValidator(ErrorMessage = "Admin subnet address space must be a valid RFC 1918 address")]
    public string admin_subnet_address_prefix { get; set; }

    [SubnetArmIdValidator(ErrorMessage = "Invalid admin subnet arm id")]
    public string admin_subnet_arm_id { get; set; }

    public string admin_subnet_name { get; set; }

    [NsgArmIdValidator(ErrorMessage = "Invalid admin subnet nsg arm id")]
    public string admin_subnet_nsg_arm_id { get; set; }

    public string admin_subnet_nsg_name { get; set; }

    // Database subnet

    //[Required]
    [AddressPrefixValidator(ErrorMessage = "DB subnet address space must be a valid RFC 1918 address")]
    public string db_subnet_address_prefix { get; set; }

    [SubnetArmIdValidator(ErrorMessage = "Invalid db subnet arm id")]
    public string db_subnet_arm_id { get; set; }
    public string db_subnet_name { get; set; }

    [NsgArmIdValidator(ErrorMessage = "Invalid db subnet nsg arm id")]
    public string db_subnet_nsg_arm_id { get; set; }

    public string db_subnet_nsg_name { get; set; }

    // Application Subnet

    //[Required]
    [AddressPrefixValidator(ErrorMessage = "App subnet address space must be a valid RFC 1918 address")]
    public string app_subnet_address_prefix { get; set; }

    [SubnetArmIdValidator(ErrorMessage = "Invalid app subnet arm id")]
    public string app_subnet_arm_id { get; set; }

    public string app_subnet_name { get; set; }

    [NsgArmIdValidator(ErrorMessage = "Invalid app subnet nsg arm id")]
    public string app_subnet_nsg_arm_id { get; set; }

    public string app_subnet_nsg_name { get; set; }

    // Web subnet

    //[Required]
    [AddressPrefixValidator(ErrorMessage = "Web subnet address space must be a valid RFC 1918 address")]
    public string web_subnet_address_prefix { get; set; }

    [SubnetArmIdValidator(ErrorMessage = "Invalid web subnet arm id")]
    public string web_subnet_arm_id { get; set; }

    public string web_subnet_name { get; set; }

    [NsgArmIdValidator(ErrorMessage = "Invalid web subnet nsg arm id")]
    public string web_subnet_nsg_arm_id { get; set; }

    public string web_subnet_nsg_name { get; set; }

    public bool? use_service_endpoint { get; set; }

    public bool? nsg_asg_with_vnet { get; set; } = false;

    /*---------------------------------------------------------------------------8
    |                                                                            |
    |                       Miscallaneous information                            |
    |                                                                            |
    +------------------------------------4--------------------------------------*/

    public string automation_username { get; set; }

    /*---------------------------------------------------------------------------8
    |                                                                            |
    |                       Resource Group information                           |
    |                                                                            |
    +------------------------------------4--------------------------------------*/

    [RgArmIdValidator(ErrorMessage = "Invalid resource group arm id")]
    public string resourcegroup_arm_id { get; set; }

    public string resourcegroup_name { get; set; }

    /*---------------------------------------------------------------------------8
    |                                                                            |
    |                       Miscallaneous information                            |
    |                                                                            |
    +------------------------------------4--------------------------------------*/

    public string custom_prefix { get; set; }

    public bool? use_prefix { get; set; } = true;

    public bool? use_secondary_ips { get; set; } = false;

    public bool? use_zonal_markers { get; set; } = true;

    public bool? upgrade_packages { get; set; } = false;

    public string bom_name { get; set; }

    public Tag[] configuration_settings { get; set; }

    public bool? dns_a_records_for_secondary_names { get; set; } = true;
    public bool? use_private_endpoint { get; set; }

    /*---------------------------------------------------------------------------8
    |                                                                            |
    |                       Cluster information                                  |
    |                                                                            |
    +------------------------------------4--------------------------------------*/

    public string fencing_role_name { get; set; }

    public bool? use_msi_for_clusters { get; set; } = true;

    public bool? use_simple_mount { get; set; } = false;

    public string database_cluster_type { get; set; } = "AFA";
    public string scs_cluster_type { get; set; } = "AFA";

    /*---------------------------------------------------------------------------8
    |                                                                            |
    |                          PPG information                                   |
    |                                                                            |
    +------------------------------------4--------------------------------------*/


    public string[] proximityplacementgroup_names { get; set; }

    [PpgIdValidator]
    public string[] proximityplacementgroup_arm_ids { get; set; }

    public bool? use_app_proximityplacementgroups { get; set; } = false;

    public string[] app_proximityplacementgroup_names { get; set; }

    [PpgIdValidator]
    public string[] app_proximityplacementgroup_arm_ids { get; set; }


    /*---------------------------------------------------------------------------8
    |                                                                            |
    |                            Database information                            |
    |                                                                            |
    +------------------------------------4--------------------------------------*/

    [DatabasePlatformValidator]
    public string database_platform { get; set; }

    public bool? database_high_availability { get; set; } = false;

    public int? database_server_count { get; set; } = 1;

    public bool? database_dual_nics { get; set; }

    public string database_size { get; set; }

    public string database_vm_sku { get; set; }

    public string database_sid { get; set; }

    public string database_instance_number { get; set; }

    public bool? database_vm_use_DHCP { get; set; } = true;

    public Image database_vm_image { get; set; }

    public string[] database_vm_zones { get; set; }

    public string database_vm_authentication_type { get; set; }

    [AvSetIdValidator]
    public string[] database_vm_avset_arm_ids { get; set; }

    public bool? database_use_ppg { get; set; } = false;

    public bool? database_use_avset { get; set; } = false;

    public bool? database_no_ppg { get; set; }

    public bool? database_no_avset { get; set; }

    public Tag[] database_tags { get; set; }

    [IpAddressValidator]
    public string[] database_loadbalancer_ips { get; set; }

    [IpAddressValidator]
    public string[] database_vm_db_nic_ips { get; set; }


    [IpAddressValidator]
    public string[] database_vm_db_nic_secondary_ips { get; set; }

    [IpAddressValidator]
    public string[] database_vm_admin_nic_ips { get; set; }

    [IpAddressValidator]
    public string[] database_vm_storage_nic_ips { get; set; }

    /*---------------------------------------------------------------------------8
    |                                                                            |
    |                          App Tier information                              |
    |                                                                            |
    +------------------------------------4--------------------------------------*/
    // Application Tier

    public bool? enable_app_tier_deployment { get; set; } = true;

    public string app_tier_authentication_type { get; set; }

    public bool? app_tier_use_DHCP { get; set; } = true;

    public bool? app_tier_dual_nics { get; set; } = false;

    public string app_tier_sizing_dictionary_key { get; set; } = "Optimized";

    /*---------------------------------------------------------------------------8
    |                                                                            |
    |                    Application Server information                          |
    |                                                                            |
    +------------------------------------4--------------------------------------*/

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

    [AvSetIdValidator]
    public string[] application_server_vm_avset_arm_ids { get; set; }

    public bool? application_server_no_avset { get; set; }

    public bool? application_server_use_avset { get; set; } = true;

    public bool? application_server_no_ppg { get; set; } = false;

    public bool? application_server_use_ppg { get; set; } = true;

    /*---------------------------------------------------------------------------8
    |                                                                            |
    |                   SAP Central Services information                         |
    |                                                                            |
    +------------------------------------4--------------------------------------*/

    public int? scs_server_count { get; set; } = 1;

    public string scs_server_sku { get; set; }

    public bool? scs_high_availability { get; set; } = false;

    public string scs_instance_number { get; set; } = "00";

    public string ers_instance_number { get; set; } = "01";

    public string pas_instance_number { get; set; } = "00";

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

    public bool? scs_server_use_avset { get; set; } = false;

    public bool? scs_server_no_avset { get; set; }

    public bool? scs_server_use_ppg { get; set; } = true;

    public bool? scs_server_no_ppg { get; set; }

    /*---------------------------------------------------------------------------8
    |                                                                            |
    |                 Web Dispatcher Tier information                            |
    |                                                                            |
    +------------------------------------4--------------------------------------*/

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

    public bool? webdispatcher_server_use_avset { get; set; } = true;

    public bool? webdispatcher_server_use_ppg { get; set; } = false;

    public bool? webdispatcher_server_no_avset { get; set; }

    public bool? webdispatcher_server_no_ppg { get; set; }

    [DisplayName("Web SID")]
    public string web_sid { get; set; }

    public string web_instance_number { get; set; } = "00";

    /*---------------------------------------------------------------------------8
    |                                                                            |
    |                            Authentication                                  |
    |                                                                            |
    +------------------------------------4--------------------------------------*/

    public string automation_password { get; set; }

    public string automation_path_to_public_key { get; set; }

    public string automation_path_to_private_key { get; set; }

    public int? resource_offset { get; set; }

    public string vm_disk_encryption_set_id { get; set; }

    /*---------------------------------------------------------------------------8
    |                                                                            |
    |                               NFS Support                                  |
    |                                                                            |
    +------------------------------------4--------------------------------------*/

    public string NFS_provider { get; set; }

    public int? sapmnt_volume_size { get; set; }

    public string azure_files_sapmnt_id { get; set; }

    public bool? use_random_id_for_storageaccounts { get; set; } = true;

    [PrivateEndpointIdValidator]
    public string sapmnt_private_endpoint_id { get; set; }

    /*---------------------------------------------------------------------------8
    |                                                                            |
    |                               ANF Support                                  |
    |                                                                            |
    +------------------------------------4--------------------------------------*/

    public bool? ANF_HANA_use_AVG { get; set; } = false;

    public bool? ANF_HANA_use_Zones { get; set; } = true;

    /*---------------------------------------------------------------------------8
    |                                                                            |
    |                                     Data                                   |
    |                                                                            |
    +------------------------------------4--------------------------------------*/

    public bool? ANF_HANA_data { get; set; }

    public int? ANF_HANA_data_volume_size { get; set; }

    public bool? ANF_HANA_data_use_existing_volume { get; set; }

    public string ANF_HANA_data_volume_name { get; set; }

    public int? ANF_HANA_data_volume_throughput { get; set; }

    public int? ANF_HANA_data_volume_count { get; set; } = 1;

    /*---------------------------------------------------------------------------8
    |                                                                            |
    |                                     Log                                    |
    |                                                                            |
    +------------------------------------4--------------------------------------*/
    public bool? ANF_HANA_log { get; set; }

    public int? ANF_HANA_log_volume_size { get; set; }

    public bool? ANF_HANA_log_use_existing { get; set; }

    public string ANF_HANA_log_volume_name { get; set; }

    public int? ANF_HANA_log_volume_throughput { get; set; }

    public int? ANF_HANA_log_volume_count { get; set; } = 1;

    /*---------------------------------------------------------------------------8
    |                                                                            |
    |                                   Shared                                   |
    |                                                                            |
    +------------------------------------4--------------------------------------*/
    public bool? ANF_HANA_shared { get; set; }

    public int? ANF_HANA_shared_volume_size { get; set; }

    public bool? ANF_HANA_shared_use_existing { get; set; }

    public string ANF_HANA_shared_volume_name { get; set; }

    public int? ANF_HANA_shared_volume_throughput { get; set; }

    /*---------------------------------------------------------------------------8
    |                                                                            |
    |                                  /usr/sap                                  |
    |                                                                            |
    +------------------------------------4--------------------------------------*/
    public bool? ANF_usr_sap { get; set; }

    public int? ANF_usr_sap_volume_size { get; set; }

    public bool? ANF_usr_sap_use_existing { get; set; }

    public string ANF_usr_sap_volume_name { get; set; }

    public int? ANF_usr_sap_throughput { get; set; }

    /*---------------------------------------------------------------------------8
    |                                                                            |
    |                                   sapmnt                                   |
    |                                                                            |
    +------------------------------------4--------------------------------------*/

    public bool? ANF_sapmnt { get; set; }

    public string ANF_sapmnt_volume_name { get; set; }

    public int? ANF_sapmnt_volume_size { get; set; }

    public int? ANF_sapmnt_volume_throughput { get; set; }

    public bool? ANF_sapmnt_use_clone_in_secondary_zone { get; set; }


    /*---------------------------------------------------------------------------8
    |                                                                            |
    |                            Anchor Support                                  |
    |                                                                            |
    +------------------------------------4--------------------------------------*/

    public string anchor_vm_authentication_username { get; set; }

    public bool? deploy_anchor_vm { get; set; }

    public string anchor_vm_sku { get; set; }

    public string anchor_vm_authentication_type { get; set; }

    public bool? anchor_vm_accelerated_networking { get; set; }

    public Image anchor_vm_image { get; set; }

    [IpAddressValidator]
    public string[] anchor_vm_nic_ips { get; set; }

    public bool? anchor_vm_use_DHCP { get; set; }

    /*---------------------------------------------------------------------------8
    |                                                                            |
    |                           Key Vault Support                                |
    |                                                                            |
    +------------------------------------4--------------------------------------*/

    [KeyvaultIdValidator]
    public string user_keyvault_id { get; set; }

    [KeyvaultIdValidator]
    public string spn_keyvault_id { get; set; }

    public bool? enable_purge_control_for_keyvaults { get; set; } = false;

    /*---------------------------------------------------------------------------8
    |                                                                            |
    |                               Deployment                                   |
    |                                                                            |
    +------------------------------------4--------------------------------------*/
    public bool? use_spn { get; set; } = true;

    /*---------------------------------------------------------------------------8
    |                                                                            |
    |                               HANA Scale Out                               |
    |                                                                            |
    +------------------------------------4--------------------------------------*/

    public bool? database_HANA_use_ANF_scaleout_scenario { get; set; } = false;

    public int? stand_by_node_count { get; set; } = 0;


    /*---------------------------------------------------------------------------8
    |                                                                            |
    |                               AMS Parameters                               |
    |                                                                            |
    +------------------------------------4--------------------------------------*/

    public bool? enable_ha_monitoring { get; set; } = false;

    public bool? enable_os_monitoring { get; set; } = false;

    [AMSIdValidator(ErrorMessage = "Invalid AMS Resource id")]
    public string ams_resource_id { get; set; }

    /*---------------------------------------------------------------------------8
    |                                                                            |
    |                              KDump Parameters                              |
    |                                                                            |
    +------------------------------------4--------------------------------------*/

    public bool? use_fence_kdump { get; set; } = false;

    public int? use_fence_kdump_size_gb_db { get; set; } = 128;

    public int? use_fence_kdump_lun_db { get; set; } = 8;

    public int? use_fence_kdump_size_gb_scs { get; set; } = 64;

    public int? use_fence_kdump_lun_scs { get; set; } = 4;

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
