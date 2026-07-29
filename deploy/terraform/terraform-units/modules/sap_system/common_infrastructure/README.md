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
| <a name="provider_azurerm.main"></a> [azurerm.main](#provider\_azurerm.main) | 4.80.0 |
| <a name="provider_random"></a> [random](#provider\_random) | n/a |
| <a name="provider_template"></a> [template](#provider\_template) | n/a |
| <a name="provider_time"></a> [time](#provider\_time) | n/a |
| <a name="provider_tls"></a> [tls](#provider\_tls) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [azurerm_application_security_group.db](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/application_security_group) | resource |
| [azurerm_key_vault.sid_keyvault_user](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/key_vault) | resource |
| [azurerm_key_vault_secret.auth_password](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/key_vault_secret) | resource |
| [azurerm_key_vault_secret.auth_username](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/key_vault_secret) | resource |
| [azurerm_key_vault_secret.sdu_private_key](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/key_vault_secret) | resource |
| [azurerm_key_vault_secret.sdu_public_key](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/key_vault_secret) | resource |
| [azurerm_linux_virtual_machine.anchor](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/linux_virtual_machine) | resource |
| [azurerm_netapp_volume.sapmnt](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/netapp_volume) | resource |
| [azurerm_netapp_volume.sapmnt_secondary](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/netapp_volume) | resource |
| [azurerm_netapp_volume.usrsap](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/netapp_volume) | resource |
| [azurerm_network_interface.anchor](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/network_interface) | resource |
| [azurerm_network_security_group.admin](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/network_security_group) | resource |
| [azurerm_network_security_group.db](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/network_security_group) | resource |
| [azurerm_network_security_perimeter_association.sapmnt](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/network_security_perimeter_association) | resource |
| [azurerm_network_security_rule.nsr_external_db](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/network_security_rule) | resource |
| [azurerm_network_security_rule.nsr_internal_db](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/network_security_rule) | resource |
| [azurerm_orchestrated_virtual_machine_scale_set.scale_set](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/orchestrated_virtual_machine_scale_set) | resource |
| [azurerm_private_endpoint.sapmnt](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/private_endpoint) | resource |
| [azurerm_proximity_placement_group.app_ppg](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/proximity_placement_group) | resource |
| [azurerm_proximity_placement_group.ppg](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/proximity_placement_group) | resource |
| [azurerm_resource_group.resource_group](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/resource_group) | resource |
| [azurerm_resource_group_template_deployment.sap_system](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/resource_group_template_deployment) | resource |
| [azurerm_storage_account.sapmnt](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/storage_account) | resource |
| [azurerm_storage_share.sapmnt](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/storage_share) | resource |
| [azurerm_storage_share.sapmnt_smb](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/storage_share) | resource |
| [azurerm_subnet.admin](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/subnet) | resource |
| [azurerm_subnet.db](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/subnet) | resource |
| [azurerm_subnet.storage](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/subnet) | resource |
| [azurerm_subnet_network_security_group_association.admin](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/subnet_network_security_group_association) | resource |
| [azurerm_subnet_network_security_group_association.db](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/subnet_network_security_group_association) | resource |
| [azurerm_subnet_route_table_association.admin](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/subnet_route_table_association) | resource |
| [azurerm_subnet_route_table_association.db](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/subnet_route_table_association) | resource |
| [azurerm_windows_virtual_machine.anchor](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/windows_virtual_machine) | resource |
| [random_id.random_id](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/id) | resource |
| [random_id.sapsystem](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/id) | resource |
| [random_password.password](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |
| [time_offset.secret_expiry_date](https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/offset) | resource |
| [time_sleep.wait_for_private_endpoints](https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/sleep) | resource |
| [tls_private_key.sdu](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/private_key) | resource |
| [azurerm_client_config.current](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/data-sources/client_config) | data source |
| [azurerm_key_vault.sid_keyvault_user](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/data-sources/key_vault) | data source |
| [azurerm_key_vault_secret.sid_password](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/data-sources/key_vault_secret) | data source |
| [azurerm_key_vault_secret.sid_pk](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/data-sources/key_vault_secret) | data source |
| [azurerm_key_vault_secret.sid_username](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/data-sources/key_vault_secret) | data source |
| [azurerm_netapp_volume.sapmnt](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/data-sources/netapp_volume) | data source |
| [azurerm_netapp_volume.usrsap](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/data-sources/netapp_volume) | data source |
| [azurerm_network_security_group.admin](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/data-sources/network_security_group) | data source |
| [azurerm_network_security_group.db](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/data-sources/network_security_group) | data source |
| [azurerm_network_security_perimeter.perimeter](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/data-sources/network_security_perimeter) | data source |
| [azurerm_network_security_perimeter_profile.profile](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/data-sources/network_security_perimeter_profile) | data source |
| [azurerm_orchestrated_virtual_machine_scale_set.scale_set](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/data-sources/orchestrated_virtual_machine_scale_set) | data source |
| [azurerm_private_endpoint_connection.sapmnt](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/data-sources/private_endpoint_connection) | data source |
| [azurerm_proximity_placement_group.app_ppg](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/data-sources/proximity_placement_group) | data source |
| [azurerm_proximity_placement_group.ppg](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/data-sources/proximity_placement_group) | data source |
| [azurerm_resource_group.resource_group](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/data-sources/resource_group) | data source |
| [azurerm_storage_account.sapmnt](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/data-sources/storage_account) | data source |
| [azurerm_storage_account.storage_bootdiag](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/data-sources/storage_account) | data source |
| [azurerm_subnet.admin](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/data-sources/subnet) | data source |
| [azurerm_subnet.db](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/data-sources/subnet) | data source |
| [azurerm_subnet.storage](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/data-sources/subnet) | data source |
| [azurerm_virtual_network.vnet_sap](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/data-sources/virtual_network) | data source |
| [template_cloudinit_config.config_growpart](https://registry.terraform.io/providers/hashicorp/template/latest/docs/data-sources/cloudinit_config) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_application_tier"></a> [application\_tier](#input\_application\_tier) | n/a | `any` | n/a | yes |
| <a name="input_authentication"></a> [authentication](#input\_authentication) | n/a | `any` | n/a | yes |
| <a name="input_database"></a> [database](#input\_database) | n/a | `any` | n/a | yes |
| <a name="input_deploy_application_security_groups"></a> [deploy\_application\_security\_groups](#input\_deploy\_application\_security\_groups) | Defines if application security groups should be deployed | `any` | n/a | yes |
| <a name="input_deployer_tfstate"></a> [deployer\_tfstate](#input\_deployer\_tfstate) | Deployer remote tfstate file | `any` | n/a | yes |
| <a name="input_deployment"></a> [deployment](#input\_deployment) | The type of deployment | `any` | n/a | yes |
| <a name="input_dns_settings"></a> [dns\_settings](#input\_dns\_settings) | DNS Settings | `any` | n/a | yes |
| <a name="input_enable_firewall_for_keyvaults_and_storage"></a> [enable\_firewall\_for\_keyvaults\_and\_storage](#input\_enable\_firewall\_for\_keyvaults\_and\_storage) | Boolean value indicating if firewall should be enabled for key vaults and storage | `bool` | n/a | yes |
| <a name="input_enable_purge_control_for_keyvaults"></a> [enable\_purge\_control\_for\_keyvaults](#input\_enable\_purge\_control\_for\_keyvaults) | Allow the deployment to control the purge protection | `any` | n/a | yes |
| <a name="input_ha_validator"></a> [ha\_validator](#input\_ha\_validator) | n/a | `any` | n/a | yes |
| <a name="input_hana_ANF_volumes"></a> [hana\_ANF\_volumes](#input\_hana\_ANF\_volumes) | Defines HANA ANF  volumes | `any` | n/a | yes |
| <a name="input_infrastructure"></a> [infrastructure](#input\_infrastructure) | n/a | `any` | n/a | yes |
| <a name="input_key_vault"></a> [key\_vault](#input\_key\_vault) | n/a | `any` | n/a | yes |
| <a name="input_landscape_tfstate"></a> [landscape\_tfstate](#input\_landscape\_tfstate) | Landscape remote tfstate file | `any` | n/a | yes |
| <a name="input_naming"></a> [naming](#input\_naming) | Defines the names for the resources | `any` | n/a | yes |
| <a name="input_options"></a> [options](#input\_options) | n/a | `any` | n/a | yes |
| <a name="input_sapmnt_volume_size"></a> [sapmnt\_volume\_size](#input\_sapmnt\_volume\_size) | The volume size in GB for sapmnt | `any` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | If provided, tags for all resources | `any` | n/a | yes |
| <a name="input_terraform_template_version"></a> [terraform\_template\_version](#input\_terraform\_template\_version) | The version of Terraform templates that were identified in the state file | `any` | n/a | yes |
| <a name="input_use_random_id_for_storageaccounts"></a> [use\_random\_id\_for\_storageaccounts](#input\_use\_random\_id\_for\_storageaccounts) | If true, will use random id for storage accounts | `any` | n/a | yes |
| <a name="input_use_scalesets_for_deployment"></a> [use\_scalesets\_for\_deployment](#input\_use\_scalesets\_for\_deployment) | Use Flexible Virtual Machine Scale Sets for the deployment | `any` | n/a | yes |
| <a name="input_AFS_enable_encryption_in_transit"></a> [AFS\_enable\_encryption\_in\_transit](#input\_AFS\_enable\_encryption\_in\_transit) | Enable encryption in transit for Azure Files | `bool` | `false` | no |
| <a name="input_Agent_IP"></a> [Agent\_IP](#input\_Agent\_IP) | If provided, contains the IP address of the agent | `string` | `""` | no |
| <a name="input_NFS_provider"></a> [NFS\_provider](#input\_NFS\_provider) | NFS provider *(AFS, ANF, NONE)*) | `string` | `"NONE"` | no |
| <a name="input_application_tier_ppg_names"></a> [application\_tier\_ppg\_names](#input\_application\_tier\_ppg\_names) | Application tier proximity placement group names | `list(string)` | `[]` | no |
| <a name="input_azure_files_sapmnt_id"></a> [azure\_files\_sapmnt\_id](#input\_azure\_files\_sapmnt\_id) | Azure resource id for the Azure Files sapmnt storage account | `string` | `""` | no |
| <a name="input_custom_disk_sizes_filename"></a> [custom\_disk\_sizes\_filename](#input\_custom\_disk\_sizes\_filename) | Custom disk sizing file | `string` | `""` | no |
| <a name="input_custom_prefix"></a> [custom\_prefix](#input\_custom\_prefix) | Custom prefix | `string` | `""` | no |
| <a name="input_is_single_node_hana"></a> [is\_single\_node\_hana](#input\_is\_single\_node\_hana) | Checks if single node hana architecture scenario is being deployed | `bool` | `false` | no |
| <a name="input_license_type"></a> [license\_type](#input\_license\_type) | Specifies the license type for the OS | `string` | `""` | no |
| <a name="input_sapmnt_private_endpoint_id"></a> [sapmnt\_private\_endpoint\_id](#input\_sapmnt\_private\_endpoint\_id) | Azure Resource Identifier for an private endpoint connection | `string` | `""` | no |
| <a name="input_scaleset_id"></a> [scaleset\_id](#input\_scaleset\_id) | If defined the Flexible Virtual Machine Scale Sets for the deployment | `string` | `""` | no |
| <a name="input_use_AFS_for_shared_storage"></a> [use\_AFS\_for\_shared\_storage](#input\_use\_AFS\_for\_shared\_storage) | If true, use Azure Files Shares (AFS) for SAP shared storage (for example sapmnt), in addition to or instead of ANF as configured. | `bool` | `false` | no |
| <a name="input_use_private_endpoint"></a> [use\_private\_endpoint](#input\_use\_private\_endpoint) | Boolean value indicating if private endpoint should be used for the deployment | `bool` | `false` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_admin_subnet"></a> [admin\_subnet](#output\_admin\_subnet) | Admin subnet object |
| <a name="output_admin_tier_resource_creation_counts"></a> [admin\_tier\_resource\_creation\_counts](#output\_admin\_tier\_resource\_creation\_counts) | Cardinality (creation count) of admin-tier network resources for terraform test diagnostics. 1 = created (greenfield), 0 = looked up (brownfield). |
| <a name="output_anchor_vm"></a> [anchor\_vm](#output\_anchor\_vm) | Defines the Anchor VM ID |
| <a name="output_app_ppg"></a> [app\_ppg](#output\_app\_ppg) | Proximity placement group Id for application tier |
| <a name="output_cloudinit_growpart_config"></a> [cloudinit\_growpart\_config](#output\_cloudinit\_growpart\_config) | Cloudinit |
| <a name="output_created_resource_group_id"></a> [created\_resource\_group\_id](#output\_created\_resource\_group\_id) | Created resource group ID |
| <a name="output_created_resource_group_name"></a> [created\_resource\_group\_name](#output\_created\_resource\_group\_name) | Created resource group name |
| <a name="output_created_resource_group_subscription_id"></a> [created\_resource\_group\_subscription\_id](#output\_created\_resource\_group\_subscription\_id) | Created resource group' subscription ID |
| <a name="output_database_tier_resource_creation_counts"></a> [database\_tier\_resource\_creation\_counts](#output\_database\_tier\_resource\_creation\_counts) | Cardinality (creation count) of database/storage-tier network resources for terraform test diagnostics. Storage tier has no dedicated NSG resource. |
| <a name="output_db_asg_id"></a> [db\_asg\_id](#output\_db\_asg\_id) | Database application security group |
| <a name="output_db_subnet"></a> [db\_subnet](#output\_db\_subnet) | Database subnet object |
| <a name="output_db_subnet_netmask"></a> [db\_subnet\_netmask](#output\_db\_subnet\_netmask) | Database subnet netmask |
| <a name="output_firewall_id"></a> [firewall\_id](#output\_firewall\_id) | Azure resource ID of the firewall |
| <a name="output_network_location"></a> [network\_location](#output\_network\_location) | Location of the network |
| <a name="output_network_resource_group"></a> [network\_resource\_group](#output\_network\_resource\_group) | Resource group of the Network |
| <a name="output_ppg"></a> [ppg](#output\_ppg) | Proximity placement group Id |
| <a name="output_random_id"></a> [random\_id](#output\_random\_id) | Random ID |
| <a name="output_resource_group"></a> [resource\_group](#output\_resource\_group) | Created resource group |
| <a name="output_route_table_id"></a> [route\_table\_id](#output\_route\_table\_id) | Azure resource ID of the route table |
| <a name="output_sapmnt_path"></a> [sapmnt\_path](#output\_sapmnt\_path) | Defines the sapmnt mount path |
| <a name="output_sapmnt_path_secondary"></a> [sapmnt\_path\_secondary](#output\_sapmnt\_path\_secondary) | Defines the sapmnt mount path |
| <a name="output_scale_set_id"></a> [scale\_set\_id](#output\_scale\_set\_id) | Defines the Scaleset ID |
| <a name="output_sdu_public_key"></a> [sdu\_public\_key](#output\_sdu\_public\_key) | User public key |
| <a name="output_sid_keyvault_user_id"></a> [sid\_keyvault\_user\_id](#output\_sid\_keyvault\_user\_id) | User credentials keyvault |
| <a name="output_sid_password"></a> [sid\_password](#output\_sid\_password) | User password |
| <a name="output_sid_username"></a> [sid\_username](#output\_sid\_username) | User name |
| <a name="output_storage_bootdiag_endpoint"></a> [storage\_bootdiag\_endpoint](#output\_storage\_bootdiag\_endpoint) | Blob endpoint value |
| <a name="output_storage_subnet_id"></a> [storage\_subnet\_id](#output\_storage\_subnet\_id) | Storage subnet |
| <a name="output_subnet_cidr_client"></a> [subnet\_cidr\_client](#output\_subnet\_cidr\_client) | Admin Storage subnet prefix |
| <a name="output_subnet_cidr_db"></a> [subnet\_cidr\_db](#output\_subnet\_cidr\_db) | DB subnet prefix |
| <a name="output_subnet_cidr_storage"></a> [subnet\_cidr\_storage](#output\_subnet\_cidr\_storage) | Storage subnet prefix |
| <a name="output_use_AFS_encryption_in_transit"></a> [use\_AFS\_encryption\_in\_transit](#output\_use\_AFS\_encryption\_in\_transit) | Indicates if Encryption in transit is enabled for AFS shares |
| <a name="output_use_local_credentials"></a> [use\_local\_credentials](#output\_use\_local\_credentials) | Use specific credentials for the deployment |
| <a name="output_usrsap_path"></a> [usrsap\_path](#output\_usrsap\_path) | Defines the /usr/sap mount path (if used) |

<!-- END_TF_DOCS -->