<!-- BEGIN_TF_DOCS -->


## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | 4.80.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_azurerm.dnsmanagement"></a> [azurerm.dnsmanagement](#provider\_azurerm.dnsmanagement) | 4.80.0 |
| <a name="provider_azurerm.main"></a> [azurerm.main](#provider\_azurerm.main) | 4.80.0 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [azurerm_application_security_group.app](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/application_security_group) | resource |
| [azurerm_application_security_group.web](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/application_security_group) | resource |
| [azurerm_availability_set.app](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/availability_set) | resource |
| [azurerm_availability_set.scs](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/availability_set) | resource |
| [azurerm_availability_set.web](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/availability_set) | resource |
| [azurerm_lb.scs](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/lb) | resource |
| [azurerm_lb.web](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/lb) | resource |
| [azurerm_lb_backend_address_pool.scs](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/lb_backend_address_pool) | resource |
| [azurerm_lb_backend_address_pool.web](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/lb_backend_address_pool) | resource |
| [azurerm_lb_probe.clst](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/lb_probe) | resource |
| [azurerm_lb_probe.fs](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/lb_probe) | resource |
| [azurerm_lb_probe.scs](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/lb_probe) | resource |
| [azurerm_lb_probe.web](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/lb_probe) | resource |
| [azurerm_lb_rule.clst](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/lb_rule) | resource |
| [azurerm_lb_rule.ers](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/lb_rule) | resource |
| [azurerm_lb_rule.fs](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/lb_rule) | resource |
| [azurerm_lb_rule.scs](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/lb_rule) | resource |
| [azurerm_lb_rule.web](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/lb_rule) | resource |
| [azurerm_linux_virtual_machine.app](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/linux_virtual_machine) | resource |
| [azurerm_linux_virtual_machine.scs](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/linux_virtual_machine) | resource |
| [azurerm_linux_virtual_machine.web](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/linux_virtual_machine) | resource |
| [azurerm_managed_disk.app](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/managed_disk) | resource |
| [azurerm_managed_disk.cluster](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/managed_disk) | resource |
| [azurerm_managed_disk.kdump](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/managed_disk) | resource |
| [azurerm_managed_disk.scs](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/managed_disk) | resource |
| [azurerm_managed_disk.web](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/managed_disk) | resource |
| [azurerm_network_interface.app](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/network_interface) | resource |
| [azurerm_network_interface.app_admin](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/network_interface) | resource |
| [azurerm_network_interface.scs](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/network_interface) | resource |
| [azurerm_network_interface.scs_admin](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/network_interface) | resource |
| [azurerm_network_interface.web](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/network_interface) | resource |
| [azurerm_network_interface.web_admin](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/network_interface) | resource |
| [azurerm_network_interface_application_security_group_association.app](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/network_interface_application_security_group_association) | resource |
| [azurerm_network_interface_application_security_group_association.scs](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/network_interface_application_security_group_association) | resource |
| [azurerm_network_interface_application_security_group_association.web](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/network_interface_application_security_group_association) | resource |
| [azurerm_network_interface_backend_address_pool_association.scs](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/network_interface_backend_address_pool_association) | resource |
| [azurerm_network_interface_backend_address_pool_association.web](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/network_interface_backend_address_pool_association) | resource |
| [azurerm_network_security_group.nsg_app](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/network_security_group) | resource |
| [azurerm_network_security_group.nsg_web](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/network_security_group) | resource |
| [azurerm_network_security_rule.webRule_internet](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/network_security_rule) | resource |
| [azurerm_private_dns_a_record.ers](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/private_dns_a_record) | resource |
| [azurerm_private_dns_a_record.scs](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/private_dns_a_record) | resource |
| [azurerm_private_dns_a_record.web](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/private_dns_a_record) | resource |
| [azurerm_role_assignment.scs](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/role_assignment) | resource |
| [azurerm_role_assignment.scs_ha](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/role_assignment) | resource |
| [azurerm_subnet.subnet_sap_app](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/subnet) | resource |
| [azurerm_subnet.subnet_sap_web](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/subnet) | resource |
| [azurerm_subnet_network_security_group_association.Associate_nsg_app](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/subnet_network_security_group_association) | resource |
| [azurerm_subnet_network_security_group_association.Associate_nsg_web](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/subnet_network_security_group_association) | resource |
| [azurerm_subnet_route_table_association.app](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/subnet_route_table_association) | resource |
| [azurerm_subnet_route_table_association.subnet_sap_app](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/subnet_route_table_association) | resource |
| [azurerm_subnet_route_table_association.subnet_sap_web](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/subnet_route_table_association) | resource |
| [azurerm_virtual_machine_data_disk_attachment.app](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/virtual_machine_data_disk_attachment) | resource |
| [azurerm_virtual_machine_data_disk_attachment.cluster](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/virtual_machine_data_disk_attachment) | resource |
| [azurerm_virtual_machine_data_disk_attachment.kdump](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/virtual_machine_data_disk_attachment) | resource |
| [azurerm_virtual_machine_data_disk_attachment.scs](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/virtual_machine_data_disk_attachment) | resource |
| [azurerm_virtual_machine_data_disk_attachment.web](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/virtual_machine_data_disk_attachment) | resource |
| [azurerm_virtual_machine_extension.configure_ansible_app](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/virtual_machine_extension) | resource |
| [azurerm_virtual_machine_extension.configure_ansible_scs](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/virtual_machine_extension) | resource |
| [azurerm_virtual_machine_extension.configure_ansible_web](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/virtual_machine_extension) | resource |
| [azurerm_virtual_machine_extension.monitoring_defender_app_lnx](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/virtual_machine_extension) | resource |
| [azurerm_virtual_machine_extension.monitoring_defender_app_win](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/virtual_machine_extension) | resource |
| [azurerm_virtual_machine_extension.monitoring_defender_scs_lnx](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/virtual_machine_extension) | resource |
| [azurerm_virtual_machine_extension.monitoring_defender_scs_win](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/virtual_machine_extension) | resource |
| [azurerm_virtual_machine_extension.monitoring_defender_web_lnx](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/virtual_machine_extension) | resource |
| [azurerm_virtual_machine_extension.monitoring_defender_web_win](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/virtual_machine_extension) | resource |
| [azurerm_virtual_machine_extension.monitoring_extension_app_lnx](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/virtual_machine_extension) | resource |
| [azurerm_virtual_machine_extension.monitoring_extension_app_win](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/virtual_machine_extension) | resource |
| [azurerm_virtual_machine_extension.monitoring_extension_scs_lnx](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/virtual_machine_extension) | resource |
| [azurerm_virtual_machine_extension.monitoring_extension_scs_win](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/virtual_machine_extension) | resource |
| [azurerm_virtual_machine_extension.monitoring_extension_web_lnx](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/virtual_machine_extension) | resource |
| [azurerm_virtual_machine_extension.monitoring_extension_web_win](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/virtual_machine_extension) | resource |
| [azurerm_windows_virtual_machine.app](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/windows_virtual_machine) | resource |
| [azurerm_windows_virtual_machine.scs](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/windows_virtual_machine) | resource |
| [azurerm_windows_virtual_machine.web](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/windows_virtual_machine) | resource |
| [azurerm_network_security_group.nsg_app](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/data-sources/network_security_group) | data source |
| [azurerm_network_security_group.nsg_web](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/data-sources/network_security_group) | data source |
| [azurerm_subnet.subnet_sap_app](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/data-sources/subnet) | data source |
| [azurerm_subnet.subnet_sap_web](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/data-sources/subnet) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_NFS_provider"></a> [NFS\_provider](#input\_NFS\_provider) | NFS provider *(AFS, ANF, NONE)*) | `any` | n/a | yes |
| <a name="input_admin_subnet"></a> [admin\_subnet](#input\_admin\_subnet) | Information about the admin subnet | `any` | n/a | yes |
| <a name="input_application_tier"></a> [application\_tier](#input\_application\_tier) | Dictionary of information about the application tier | `any` | n/a | yes |
| <a name="input_cloudinit_growpart_config"></a> [cloudinit\_growpart\_config](#input\_cloudinit\_growpart\_config) | A cloud-init config that configures automatic growpart expansion of root partition | `any` | n/a | yes |
| <a name="input_custom_disk_sizes_filename"></a> [custom\_disk\_sizes\_filename](#input\_custom\_disk\_sizes\_filename) | Disk size json file | `any` | n/a | yes |
| <a name="input_deploy_application_security_groups"></a> [deploy\_application\_security\_groups](#input\_deploy\_application\_security\_groups) | Defines if application security groups should be deployed | `any` | n/a | yes |
| <a name="input_deployment"></a> [deployment](#input\_deployment) | The type of deployment | `any` | n/a | yes |
| <a name="input_dns_settings"></a> [dns\_settings](#input\_dns\_settings) | DNS Settings | `any` | n/a | yes |
| <a name="input_fencing_role_name"></a> [fencing\_role\_name](#input\_fencing\_role\_name) | If specified the role name to use for the fencing | `any` | n/a | yes |
| <a name="input_firewall_id"></a> [firewall\_id](#input\_firewall\_id) | Firewall (if any) id | `any` | n/a | yes |
| <a name="input_infrastructure"></a> [infrastructure](#input\_infrastructure) | Dictionary of information about the common infrastructure | `any` | n/a | yes |
| <a name="input_landscape_tfstate"></a> [landscape\_tfstate](#input\_landscape\_tfstate) | Terraform output from the workload zone | `any` | n/a | yes |
| <a name="input_license_type"></a> [license\_type](#input\_license\_type) | Specifies the license type for the OS | `any` | n/a | yes |
| <a name="input_naming"></a> [naming](#input\_naming) | Defines the names for the resources | `any` | n/a | yes |
| <a name="input_network_location"></a> [network\_location](#input\_network\_location) | Location of the Virtual Network | `any` | n/a | yes |
| <a name="input_network_resource_group"></a> [network\_resource\_group](#input\_network\_resource\_group) | Resource Group of the Virtual Network | `any` | n/a | yes |
| <a name="input_options"></a> [options](#input\_options) | Dictionary of miscallaneous parameters | `any` | n/a | yes |
| <a name="input_order_deployment"></a> [order\_deployment](#input\_order\_deployment) | psuedo condition for ordering deployment | `any` | n/a | yes |
| <a name="input_ppg"></a> [ppg](#input\_ppg) | Details of the proximity placement group | `any` | n/a | yes |
| <a name="input_resource_group"></a> [resource\_group](#input\_resource\_group) | Details of the resource group | `any` | n/a | yes |
| <a name="input_route_table_id"></a> [route\_table\_id](#input\_route\_table\_id) | Route table (if any) id | `any` | n/a | yes |
| <a name="input_sap_sid"></a> [sap\_sid](#input\_sap\_sid) | The SID of the application | `any` | n/a | yes |
| <a name="input_scale_set_id"></a> [scale\_set\_id](#input\_scale\_set\_id) | Azure resource identifier for scale set | `any` | n/a | yes |
| <a name="input_sdu_public_key"></a> [sdu\_public\_key](#input\_sdu\_public\_key) | Public key used for authentication | `any` | n/a | yes |
| <a name="input_sid_keyvault_user_id"></a> [sid\_keyvault\_user\_id](#input\_sid\_keyvault\_user\_id) | Details of the user keyvault for the sap system | `any` | n/a | yes |
| <a name="input_sid_password"></a> [sid\_password](#input\_sid\_password) | SDU password | `any` | n/a | yes |
| <a name="input_sid_username"></a> [sid\_username](#input\_sid\_username) | SDU username | `any` | n/a | yes |
| <a name="input_storage_bootdiag_endpoint"></a> [storage\_bootdiag\_endpoint](#input\_storage\_bootdiag\_endpoint) | Details of the boot diagnostic storage device | `any` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | If provided, tags for all resources | `any` | n/a | yes |
| <a name="input_terraform_template_version"></a> [terraform\_template\_version](#input\_terraform\_template\_version) | The version of Terraform templates that were identified in the state file | `any` | n/a | yes |
| <a name="input_use_admin_nic_for_asg"></a> [use\_admin\_nic\_for\_asg](#input\_use\_admin\_nic\_for\_asg) | If true, the admin nic will be assigned to the ASG instead of the second nic | `any` | n/a | yes |
| <a name="input_use_msi_for_clusters"></a> [use\_msi\_for\_clusters](#input\_use\_msi\_for\_clusters) | If true, the Pacemaker cluser will use a managed identity | `any` | n/a | yes |
| <a name="input_use_scalesets_for_deployment"></a> [use\_scalesets\_for\_deployment](#input\_use\_scalesets\_for\_deployment) | Use Flexible Virtual Machine Scale Sets for the deployment | `any` | n/a | yes |
| <a name="input_deployer_user"></a> [deployer\_user](#input\_deployer\_user) | Details of the users | `list` | `[]` | no |
| <a name="input_idle_timeout_scs_ers"></a> [idle\_timeout\_scs\_ers](#input\_idle\_timeout\_scs\_ers) | Sets the idle timeout setting for the SCS and ERS loadbalancer | `number` | `4` | no |
| <a name="input_use_loadbalancers_for_standalone_deployments"></a> [use\_loadbalancers\_for\_standalone\_deployments](#input\_use\_loadbalancers\_for\_standalone\_deployments) | Defines if load balancers are used even for standalone deployments | `bool` | `true` | no |
| <a name="input_use_secondary_ips"></a> [use\_secondary\_ips](#input\_use\_secondary\_ips) | Use secondary IPs for the SAP System | `bool` | `false` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_app_admin_ip"></a> [app\_admin\_ip](#output\_app\_admin\_ip) | Application Server admin IPs |
| <a name="output_app_asg_id"></a> [app\_asg\_id](#output\_app\_asg\_id) | IDs of the application security group for the application VMs |
| <a name="output_app_subnet_netmask"></a> [app\_subnet\_netmask](#output\_app\_subnet\_netmask) | Application subnet netmask |
| <a name="output_app_tier_os_types"></a> [app\_tier\_os\_types](#output\_app\_tier\_os\_types) | List of operating systems used in the application tier |
| <a name="output_app_tier_resource_creation_counts"></a> [app\_tier\_resource\_creation\_counts](#output\_app\_tier\_resource\_creation\_counts) | Cardinality (creation count) of app-tier network resources for terraform test diagnostics. 1 = created (greenfield), 0 = looked up (brownfield). |
| <a name="output_app_vm_ids"></a> [app\_vm\_ids](#output\_app\_vm\_ids) | Application tier virtual machine resource IDs |
| <a name="output_app_vm_names"></a> [app\_vm\_names](#output\_app\_vm\_names) | Application virtual machine names |
| <a name="output_application_server_ips"></a> [application\_server\_ips](#output\_application\_server\_ips) | Application Server IPs |
| <a name="output_application_server_secondary_ips"></a> [application\_server\_secondary\_ips](#output\_application\_server\_secondary\_ips) | Application Server secondary IPs |
| <a name="output_apptier_disks"></a> [apptier\_disks](#output\_apptier\_disks) | List of disks used in the application tier |
| <a name="output_cluster_loadbalancer_ip"></a> [cluster\_loadbalancer\_ip](#output\_cluster\_loadbalancer\_ip) | Central Services Server ClusterLoad balancer IP |
| <a name="output_dns_info_loadbalancers"></a> [dns\_info\_loadbalancers](#output\_dns\_info\_loadbalancers) | DNS information for the application tier load balancers |
| <a name="output_dns_info_vms"></a> [dns\_info\_vms](#output\_dns\_info\_vms) | DNS information for the application tier |
| <a name="output_ers_server_loadbalancer_ip"></a> [ers\_server\_loadbalancer\_ip](#output\_ers\_server\_loadbalancer\_ip) | Central Services Server Load balancer IP |
| <a name="output_fileshare_loadbalancer_ip"></a> [fileshare\_loadbalancer\_ip](#output\_fileshare\_loadbalancer\_ip) | Central Services Server ClusterLoad File Share IP |
| <a name="output_iscsiservers"></a> [iscsiservers](#output\_iscsiservers) | Defines if high availability is used |
| <a name="output_scs_asd"></a> [scs\_asd](#output\_scs\_asd) | List of Azure shared disks |
| <a name="output_scs_high_availability"></a> [scs\_high\_availability](#output\_scs\_high\_availability) | Defines if high availability is used |
| <a name="output_scs_kdump_disks"></a> [scs\_kdump\_disks](#output\_scs\_kdump\_disks) | List of kdump disks |
| <a name="output_scs_server_admin_ips"></a> [scs\_server\_admin\_ips](#output\_scs\_server\_admin\_ips) | Central Services Server Admin IPs |
| <a name="output_scs_server_ips"></a> [scs\_server\_ips](#output\_scs\_server\_ips) | Central Services Server IPs |
| <a name="output_scs_server_loadbalancer_id"></a> [scs\_server\_loadbalancer\_id](#output\_scs\_server\_loadbalancer\_id) | Central Services Server Loadbalancer id |
| <a name="output_scs_server_loadbalancer_ip"></a> [scs\_server\_loadbalancer\_ip](#output\_scs\_server\_loadbalancer\_ip) | Central Services Server Load balancer IP |
| <a name="output_scs_server_loadbalancer_ips"></a> [scs\_server\_loadbalancer\_ips](#output\_scs\_server\_loadbalancer\_ips) | Central Services Server Load balancer All IPS |
| <a name="output_scs_server_secondary_ips"></a> [scs\_server\_secondary\_ips](#output\_scs\_server\_secondary\_ips) | Central Services Server secondary IPs |
| <a name="output_scs_vm_ids"></a> [scs\_vm\_ids](#output\_scs\_vm\_ids) | SCS virtual machine resource IDs |
| <a name="output_scs_vm_names"></a> [scs\_vm\_names](#output\_scs\_vm\_names) | SCS virtual machine names |
| <a name="output_subnet_cidr_app"></a> [subnet\_cidr\_app](#output\_subnet\_cidr\_app) | App subnet prefix |
| <a name="output_web_asg_id"></a> [web\_asg\_id](#output\_web\_asg\_id) | IDs of the application security group for the web VMs |
| <a name="output_webdispatcher_loadbalancer_ip"></a> [webdispatcher\_loadbalancer\_ip](#output\_webdispatcher\_loadbalancer\_ip) | Central Services Server Load balancer IP |
| <a name="output_webdispatcher_server_ips"></a> [webdispatcher\_server\_ips](#output\_webdispatcher\_server\_ips) | Web dispatcher IPs |
| <a name="output_webdispatcher_server_secondary_ips"></a> [webdispatcher\_server\_secondary\_ips](#output\_webdispatcher\_server\_secondary\_ips) | Web dispatcher secondary IPs |
| <a name="output_webdispatcher_server_vm_ids"></a> [webdispatcher\_server\_vm\_ids](#output\_webdispatcher\_server\_vm\_ids) | Web dispatcher virtual machine resource IDs |
| <a name="output_webdispatcher_server_vm_names"></a> [webdispatcher\_server\_vm\_names](#output\_webdispatcher\_server\_vm\_names) | Web dispatcher virtual machine resource names |

<!-- END_TF_DOCS -->