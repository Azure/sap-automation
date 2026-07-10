<!-- BEGIN_TF_DOCS -->


## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | 4.80.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | 4.80.0 |
| <a name="provider_azurerm.deployer"></a> [azurerm.deployer](#provider\_azurerm.deployer) | 4.80.0 |
| <a name="provider_azurerm.dnsmanagement"></a> [azurerm.dnsmanagement](#provider\_azurerm.dnsmanagement) | 4.80.0 |
| <a name="provider_local"></a> [local](#provider\_local) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [azurerm_private_dns_a_record.app_secondary](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/private_dns_a_record) | resource |
| [azurerm_private_dns_a_record.db_secondary](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/private_dns_a_record) | resource |
| [azurerm_private_dns_a_record.scs_secondary](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/private_dns_a_record) | resource |
| [azurerm_private_dns_a_record.web_secondary](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/private_dns_a_record) | resource |
| [azurerm_storage_blob.ansible_inventory_yaml](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/storage_blob) | resource |
| [azurerm_storage_blob.readme](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/storage_blob) | resource |
| [azurerm_storage_blob.sap_parameters_yaml](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/storage_blob) | resource |
| [azurerm_storage_blob.tfvars_state](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/storage_blob) | resource |
| [azurerm_storage_blob.tfvarsfile](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/storage_blob) | resource |
| [local_file.ansible_inventory_new_yml](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) | resource |
| [local_file.naming](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) | resource |
| [local_file.sap-parameters_yml](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) | resource |
| [local_file.sap_inventory_for_wiki_md](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) | resource |
| [local_file.sap_inventory_md](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) | resource |
| [local_file.sap_vms_resource_id](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) | resource |
| [azurerm_client_config.current](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/data-sources/client_config) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_NFS_provider"></a> [NFS\_provider](#input\_NFS\_provider) | Defines the NFS provider | `string` | n/a | yes |
| <a name="input_ams_resource_id"></a> [ams\_resource\_id](#input\_ams\_resource\_id) | Resource ID for AMS | `any` | n/a | yes |
| <a name="input_app_server_count"></a> [app\_server\_count](#input\_app\_server\_count) | Number of Application Servers | `number` | n/a | yes |
| <a name="input_app_subnet_netmask"></a> [app\_subnet\_netmask](#input\_app\_subnet\_netmask) | netmask for the SAP application subnet | `any` | n/a | yes |
| <a name="input_app_tier_os_types"></a> [app\_tier\_os\_types](#input\_app\_tier\_os\_types) | Defines the app tier os types | `any` | n/a | yes |
| <a name="input_app_vm_names"></a> [app\_vm\_names](#input\_app\_vm\_names) | List of VM names for the Application Servers | `any` | n/a | yes |
| <a name="input_application_server_ips"></a> [application\_server\_ips](#input\_application\_server\_ips) | List of IP addresses for the Application Servers | `any` | n/a | yes |
| <a name="input_application_server_secondary_ips"></a> [application\_server\_secondary\_ips](#input\_application\_server\_secondary\_ips) | List of secondary IP addresses for the Application Servers | `any` | n/a | yes |
| <a name="input_authentication"></a> [authentication](#input\_authentication) | Dictionary with authentication details | `any` | n/a | yes |
| <a name="input_configuration_settings"></a> [configuration\_settings](#input\_configuration\_settings) | This is a dictionary that will contain values persisted to the sap-parameters.file | `any` | n/a | yes |
| <a name="input_created_resource_group_name"></a> [created\_resource\_group\_name](#input\_created\_resource\_group\_name) | Name of the resource group | `any` | n/a | yes |
| <a name="input_created_resource_group_subscription_id"></a> [created\_resource\_group\_subscription\_id](#input\_created\_resource\_group\_subscription\_id) | Subscription ID of the resource group | `any` | n/a | yes |
| <a name="input_database"></a> [database](#input\_database) | Dictionary with information on the database tier | `any` | n/a | yes |
| <a name="input_database_active_active"></a> [database\_active\_active](#input\_database\_active\_active) | If true, database will deployed with Active/Active (read enabled) configuration (HANA only) | `any` | n/a | yes |
| <a name="input_database_admin_ips"></a> [database\_admin\_ips](#input\_database\_admin\_ips) | List of Admin NICs for the DB VMs | `any` | n/a | yes |
| <a name="input_database_cluster_ip"></a> [database\_cluster\_ip](#input\_database\_cluster\_ip) | This is a Cluster IP address for Windows load balancer for the database | `any` | n/a | yes |
| <a name="input_database_cluster_type"></a> [database\_cluster\_type](#input\_database\_cluster\_type) | Cluster quorum type; AFA (Azure Fencing Agent), ASD (Azure Shared Disk), ISCSI | `string` | n/a | yes |
| <a name="input_database_server_ips"></a> [database\_server\_ips](#input\_database\_server\_ips) | List of IP addresses for the database servers | `any` | n/a | yes |
| <a name="input_database_server_secondary_ips"></a> [database\_server\_secondary\_ips](#input\_database\_server\_secondary\_ips) | List of secondary IP addresses for the database servers | `any` | n/a | yes |
| <a name="input_database_server_vm_names"></a> [database\_server\_vm\_names](#input\_database\_server\_vm\_names) | List of VM names for the database servers | `any` | n/a | yes |
| <a name="input_database_shared_disks"></a> [database\_shared\_disks](#input\_database\_shared\_disks) | Database Azure Shared Disk | `any` | n/a | yes |
| <a name="input_database_subnet_netmask"></a> [database\_subnet\_netmask](#input\_database\_subnet\_netmask) | netmask for the database subnet | `any` | n/a | yes |
| <a name="input_db_server_count"></a> [db\_server\_count](#input\_db\_server\_count) | Number of Database Servers | `number` | n/a | yes |
| <a name="input_db_sid"></a> [db\_sid](#input\_db\_sid) | Database SID | `any` | n/a | yes |
| <a name="input_deploy_monitoring_extension"></a> [deploy\_monitoring\_extension](#input\_deploy\_monitoring\_extension) | Deploy the Azure Extended monitoring for SAP solution | `any` | n/a | yes |
| <a name="input_disks"></a> [disks](#input\_disks) | List of disks | `any` | n/a | yes |
| <a name="input_dns_a_records_for_secondary_names"></a> [dns\_a\_records\_for\_secondary\_names](#input\_dns\_a\_records\_for\_secondary\_names) | Boolean value indicating if dns a records should be created for the secondary DNS names | `any` | n/a | yes |
| <a name="input_enable_ha_monitoring"></a> [enable\_ha\_monitoring](#input\_enable\_ha\_monitoring) | Enable HA monitoring | `any` | n/a | yes |
| <a name="input_enable_os_monitoring"></a> [enable\_os\_monitoring](#input\_enable\_os\_monitoring) | Enable OS monitoring | `any` | n/a | yes |
| <a name="input_hana_data"></a> [hana\_data](#input\_hana\_data) | If defined provides the mount point for HANA data on ANF | `any` | n/a | yes |
| <a name="input_hana_log"></a> [hana\_log](#input\_hana\_log) | If defined provides the mount point for HANA log on ANF | `any` | n/a | yes |
| <a name="input_hana_shared"></a> [hana\_shared](#input\_hana\_shared) | If defined provides the mount point for HANA shared on ANF | `any` | n/a | yes |
| <a name="input_infrastructure"></a> [infrastructure](#input\_infrastructure) | Dictionary with infrastructure details | `any` | n/a | yes |
| <a name="input_is_use_fence_kdump"></a> [is\_use\_fence\_kdump](#input\_is\_use\_fence\_kdump) | Use fence kdump for optional stonith configuration on RHEL | `any` | n/a | yes |
| <a name="input_landscape_tfstate"></a> [landscape\_tfstate](#input\_landscape\_tfstate) | Landscape remote tfstate file | `any` | n/a | yes |
| <a name="input_loadbalancers"></a> [loadbalancers](#input\_loadbalancers) | List of LoadBalancers created for HANA Databases | `any` | n/a | yes |
| <a name="input_naming"></a> [naming](#input\_naming) | Defines the names for the resources | `any` | n/a | yes |
| <a name="input_observer_ips"></a> [observer\_ips](#input\_observer\_ips) | List of NICs for the Observer VMs | `any` | n/a | yes |
| <a name="input_observer_shared_disks"></a> [observer\_shared\_disks](#input\_observer\_shared\_disks) | Observer Azure Shared Disk | `any` | n/a | yes |
| <a name="input_observer_vms"></a> [observer\_vms](#input\_observer\_vms) | List of Observer VMs | `any` | n/a | yes |
| <a name="input_random_id"></a> [random\_id](#input\_random\_id) | Random hex string | `any` | n/a | yes |
| <a name="input_sap_sid"></a> [sap\_sid](#input\_sap\_sid) | SAP SID | `any` | n/a | yes |
| <a name="input_scale_out"></a> [scale\_out](#input\_scale\_out) | If true, the SAP System will be scale out | `any` | n/a | yes |
| <a name="input_scale_out_no_standby_role"></a> [scale\_out\_no\_standby\_role](#input\_scale\_out\_no\_standby\_role) | If true, the SAP Scale out system will not have a standby-node. Only applicable for shared storage based deployment | `any` | n/a | yes |
| <a name="input_scs_cluster_loadbalancer_ip"></a> [scs\_cluster\_loadbalancer\_ip](#input\_scs\_cluster\_loadbalancer\_ip) | This is a Cluster IP address for Windows load balancer for central services | `any` | n/a | yes |
| <a name="input_scs_cluster_type"></a> [scs\_cluster\_type](#input\_scs\_cluster\_type) | Cluster quorum type; AFA (Azure Fencing Agent), ASD (Azure Shared Disk), ISCSI | `string` | n/a | yes |
| <a name="input_scs_server_count"></a> [scs\_server\_count](#input\_scs\_server\_count) | Number of SCS Servers | `number` | n/a | yes |
| <a name="input_scs_server_ips"></a> [scs\_server\_ips](#input\_scs\_server\_ips) | List of IP addresses for the SCS Servers | `any` | n/a | yes |
| <a name="input_scs_server_secondary_ips"></a> [scs\_server\_secondary\_ips](#input\_scs\_server\_secondary\_ips) | List of secondary IP addresses for the SCS Servers | `any` | n/a | yes |
| <a name="input_scs_server_vm_resource_ids"></a> [scs\_server\_vm\_resource\_ids](#input\_scs\_server\_vm\_resource\_ids) | List of Virtual Machine resource IDs for the SCS servers | `any` | n/a | yes |
| <a name="input_scs_shared_disks"></a> [scs\_shared\_disks](#input\_scs\_shared\_disks) | SCS Azure Shared Disk | `any` | n/a | yes |
| <a name="input_scs_vm_names"></a> [scs\_vm\_names](#input\_scs\_vm\_names) | List of VM names for the SCS Servers | `any` | n/a | yes |
| <a name="input_shared_home"></a> [shared\_home](#input\_shared\_home) | If defined provides shared-home support | `any` | n/a | yes |
| <a name="input_sid_keyvault_user_id"></a> [sid\_keyvault\_user\_id](#input\_sid\_keyvault\_user\_id) | Defines the names for the resources | `any` | n/a | yes |
| <a name="input_site_information"></a> [site\_information](#input\_site\_information) | Site information | `any` | n/a | yes |
| <a name="input_subnet_cidr_anf"></a> [subnet\_cidr\_anf](#input\_subnet\_cidr\_anf) | address prefix for the ANF subnet | `any` | n/a | yes |
| <a name="input_subnet_cidr_app"></a> [subnet\_cidr\_app](#input\_subnet\_cidr\_app) | address prefix for the app subnet | `any` | n/a | yes |
| <a name="input_subnet_cidr_client"></a> [subnet\_cidr\_client](#input\_subnet\_cidr\_client) | address prefix for the client subnet | `any` | n/a | yes |
| <a name="input_subnet_cidr_db"></a> [subnet\_cidr\_db](#input\_subnet\_cidr\_db) | address prefix for the db subnet | `any` | n/a | yes |
| <a name="input_subnet_cidr_storage"></a> [subnet\_cidr\_storage](#input\_subnet\_cidr\_storage) | address prefix for the storage subnet | `any` | n/a | yes |
| <a name="input_tfstate_resource_id"></a> [tfstate\_resource\_id](#input\_tfstate\_resource\_id) | Resource ID for tf state file | `any` | n/a | yes |
| <a name="input_upgrade_packages"></a> [upgrade\_packages](#input\_upgrade\_packages) | Upgrade packages | `any` | n/a | yes |
| <a name="input_use_AFS_encryption_in_transit"></a> [use\_AFS\_encryption\_in\_transit](#input\_use\_AFS\_encryption\_in\_transit) | Indicates if Encryption in transit is enabled for AFS shares | `any` | n/a | yes |
| <a name="input_use_local_credentials"></a> [use\_local\_credentials](#input\_use\_local\_credentials) | SDU has unique credentials | `any` | n/a | yes |
| <a name="input_use_msi_for_clusters"></a> [use\_msi\_for\_clusters](#input\_use\_msi\_for\_clusters) | If true, the Pacemaker cluser will use a managed identity | `any` | n/a | yes |
| <a name="input_use_secondary_ips"></a> [use\_secondary\_ips](#input\_use\_secondary\_ips) | Use secondary IPs for the SAP System | `any` | n/a | yes |
| <a name="input_user_assigned_identity_id"></a> [user\_assigned\_identity\_id](#input\_user\_assigned\_identity\_id) | User assigned managed identity | `any` | n/a | yes |
| <a name="input_usr_sap"></a> [usr\_sap](#input\_usr\_sap) | If defined provides the mount point for /usr/sap on ANF | `any` | n/a | yes |
| <a name="input_web_server_count"></a> [web\_server\_count](#input\_web\_server\_count) | Number of Web Dispatchers | `number` | n/a | yes |
| <a name="input_webdispatcher_server_ips"></a> [webdispatcher\_server\_ips](#input\_webdispatcher\_server\_ips) | List of IP addresses for the Web dispatchers | `any` | n/a | yes |
| <a name="input_webdispatcher_server_secondary_ips"></a> [webdispatcher\_server\_secondary\_ips](#input\_webdispatcher\_server\_secondary\_ips) | List of secondary IP addresses for the Web dispatchers | `any` | n/a | yes |
| <a name="input_webdispatcher_server_vm_names"></a> [webdispatcher\_server\_vm\_names](#input\_webdispatcher\_server\_vm\_names) | List of VM names for the Web dispatchers | `any` | n/a | yes |
| <a name="input_ansible_user"></a> [ansible\_user](#input\_ansible\_user) | The ansible remote user account to use | `string` | `"azureadm"` | no |
| <a name="input_app_instance_number"></a> [app\_instance\_number](#input\_app\_instance\_number) | Instance number for Additional Application Server | `string` | `"00"` | no |
| <a name="input_authentication_type"></a> [authentication\_type](#input\_authentication\_type) | VM Authentication type | `string` | `"key"` | no |
| <a name="input_bom_name"></a> [bom\_name](#input\_bom\_name) | Name of Bill of Materials file | `string` | `""` | no |
| <a name="input_database_active_active_loadbalancer_ip"></a> [database\_active\_active\_loadbalancer\_ip](#input\_database\_active\_active\_loadbalancer\_ip) | DB Active Active Load Balancer IP | `string` | `""` | no |
| <a name="input_database_authentication_type"></a> [database\_authentication\_type](#input\_database\_authentication\_type) | Platform to use | `string` | `"key"` | no |
| <a name="input_database_high_availability"></a> [database\_high\_availability](#input\_database\_high\_availability) | If true, the database tier will be configured for high availability | `bool` | `false` | no |
| <a name="input_database_loadbalancer_ip"></a> [database\_loadbalancer\_ip](#input\_database\_loadbalancer\_ip) | DB Load Balancer IP | `string` | `""` | no |
| <a name="input_dns"></a> [dns](#input\_dns) | The DNS label | `string` | `""` | no |
| <a name="input_dns_zone_names"></a> [dns\_zone\_names](#input\_dns\_zone\_names) | Private DNS zone names | `map(string)` | <pre>{<br/>  "appconfig_dns_zone_name": "privatelink.azconfig.io",<br/>  "blob_dns_zone_name": "privatelink.blob.core.windows.net",<br/>  "file_dns_zone_name": "privatelink.file.core.windows.net",<br/>  "table_dns_zone_name": "privatelink.table.core.windows.net",<br/>  "vault_dns_zone_name": "privatelink.vaultcore.azure.net"<br/>}</pre> | no |
| <a name="input_ers_instance_number"></a> [ers\_instance\_number](#input\_ers\_instance\_number) | Instance number for ERS | `string` | `"02"` | no |
| <a name="input_ers_server_loadbalancer_ip"></a> [ers\_server\_loadbalancer\_ip](#input\_ers\_server\_loadbalancer\_ip) | ERS Load Balancer IP | `string` | `""` | no |
| <a name="input_iSCSI_server_ips"></a> [iSCSI\_server\_ips](#input\_iSCSI\_server\_ips) | List of IP addresses for the iSCSI Servers | `list` | `[]` | no |
| <a name="input_iSCSI_server_names"></a> [iSCSI\_server\_names](#input\_iSCSI\_server\_names) | List of host names for the iSCSI Servers | `list` | `[]` | no |
| <a name="input_iSCSI_servers"></a> [iSCSI\_servers](#input\_iSCSI\_servers) | List of host names and IPs for the iSCSI Servers | `list` | `[]` | no |
| <a name="input_install_path"></a> [install\_path](#input\_install\_path) | Defines the install path for mounting /usr/sap/install | `string` | `""` | no |
| <a name="input_management_dns_resourcegroup_name"></a> [management\_dns\_resourcegroup\_name](#input\_management\_dns\_resourcegroup\_name) | String value giving the possibility to register custom dns a records in a separate resourcegroup | `string` | `null` | no |
| <a name="input_management_dns_subscription_id"></a> [management\_dns\_subscription\_id](#input\_management\_dns\_subscription\_id) | String value giving the possibility to register custom dns a records in a separate subscription | `string` | `null` | no |
| <a name="input_pas_instance_number"></a> [pas\_instance\_number](#input\_pas\_instance\_number) | Instance number for Primary Application Server | `string` | `"00"` | no |
| <a name="input_platform"></a> [platform](#input\_platform) | Platform to use | `string` | `"HANA"` | no |
| <a name="input_sap_mnt"></a> [sap\_mnt](#input\_sap\_mnt) | ANF Volume for SAP mount | `string` | `""` | no |
| <a name="input_sap_transport"></a> [sap\_transport](#input\_sap\_transport) | ANF Volume for SAP Transport | `string` | `""` | no |
| <a name="input_save_naming_information"></a> [save\_naming\_information](#input\_save\_naming\_information) | If defined, will save the naming information for the resources | `bool` | `false` | no |
| <a name="input_scs_high_availability"></a> [scs\_high\_availability](#input\_scs\_high\_availability) | If true, the SAP Central Services tier will be configured for high availability | `bool` | `false` | no |
| <a name="input_scs_instance_number"></a> [scs\_instance\_number](#input\_scs\_instance\_number) | Instance number for SCS | `string` | `"00"` | no |
| <a name="input_scs_server_loadbalancer_ip"></a> [scs\_server\_loadbalancer\_ip](#input\_scs\_server\_loadbalancer\_ip) | SCS Load Balancer IP | `string` | `""` | no |
| <a name="input_suse_subscription_id"></a> [suse\_subscription\_id](#input\_suse\_subscription\_id) | SUSE registration code for BYOS/BYOL images | `string` | `""` | no |
| <a name="input_use_custom_dns_a_registration"></a> [use\_custom\_dns\_a\_registration](#input\_use\_custom\_dns\_a\_registration) | Boolean value indicating if a custom dns a record should be created when using private endpoints | `bool` | `false` | no |
| <a name="input_use_simple_mount"></a> [use\_simple\_mount](#input\_use\_simple\_mount) | Use simple mount | `bool` | `true` | no |
| <a name="input_web_instance_number"></a> [web\_instance\_number](#input\_web\_instance\_number) | The Instance number for Web Dispatcher | `string` | `"00"` | no |
| <a name="input_web_sid"></a> [web\_sid](#input\_web\_sid) | The sid of the web dispatchers | `string` | `""` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_hosts_file_content"></a> [hosts\_file\_content](#output\_hosts\_file\_content) | Raw content of the generated Ansible inventory hosts YAML file (for plan-time test assertions) |
| <a name="output_sap_parameters_content"></a> [sap\_parameters\_content](#output\_sap\_parameters\_content) | Raw content of the generated sap-parameters YAML file (for plan-time test assertions) |

<!-- END_TF_DOCS -->