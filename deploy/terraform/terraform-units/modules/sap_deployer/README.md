<!-- BEGIN_TF_DOCS -->


## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_azapi"></a> [azapi](#requirement\_azapi) | 2.7.0 |
| <a name="requirement_azuread"></a> [azuread](#requirement\_azuread) | 3.8.0 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | 4.80.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_azapi"></a> [azapi](#provider\_azapi) | 2.7.0 |
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | 4.80.0 |
| <a name="provider_azurerm.main"></a> [azurerm.main](#provider\_azurerm.main) | 4.80.0 |
| <a name="provider_azurerm.privatelinkdnsmanagement"></a> [azurerm.privatelinkdnsmanagement](#provider\_azurerm.privatelinkdnsmanagement) | 4.80.0 |
| <a name="provider_local"></a> [local](#provider\_local) | n/a |
| <a name="provider_null"></a> [null](#provider\_null) | n/a |
| <a name="provider_random"></a> [random](#provider\_random) | n/a |
| <a name="provider_time"></a> [time](#provider\_time) | n/a |
| <a name="provider_tls"></a> [tls](#provider\_tls) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [azapi_resource.deployer](https://registry.terraform.io/providers/azure/azapi/2.7.0/docs/resources/resource) | resource |
| [azurerm_app_configuration.app_config](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/app_configuration) | resource |
| [azurerm_app_configuration_key.deployer_keyvault_id](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/app_configuration_key) | resource |
| [azurerm_app_configuration_key.deployer_keyvault_name](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/app_configuration_key) | resource |
| [azurerm_app_configuration_key.deployer_msi_id](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/app_configuration_key) | resource |
| [azurerm_app_configuration_key.deployer_network_id](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/app_configuration_key) | resource |
| [azurerm_app_configuration_key.deployer_resourcegroup_name](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/app_configuration_key) | resource |
| [azurerm_app_configuration_key.deployer_state_file_name](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/app_configuration_key) | resource |
| [azurerm_app_configuration_key.deployer_subnet_id](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/app_configuration_key) | resource |
| [azurerm_app_configuration_key.deployer_subscription_id](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/app_configuration_key) | resource |
| [azurerm_app_configuration_key.web_application_identity_id](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/app_configuration_key) | resource |
| [azurerm_app_configuration_key.web_application_resource_id](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/app_configuration_key) | resource |
| [azurerm_bastion_host.bastion](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/bastion_host) | resource |
| [azurerm_dev_center.deployer](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/dev_center) | resource |
| [azurerm_dev_center_dev_box_definition.deployer](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/dev_center_dev_box_definition) | resource |
| [azurerm_dev_center_network_connection.deployer](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/dev_center_network_connection) | resource |
| [azurerm_dev_center_project.deployer](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/dev_center_project) | resource |
| [azurerm_firewall.firewall](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/firewall) | resource |
| [azurerm_firewall_network_rule_collection.firewall-azure](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/firewall_network_rule_collection) | resource |
| [azurerm_key_vault.kv_user](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/key_vault) | resource |
| [azurerm_key_vault_access_policy.kv_user_additional_users](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/key_vault_access_policy) | resource |
| [azurerm_key_vault_access_policy.kv_user_msi](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/key_vault_access_policy) | resource |
| [azurerm_key_vault_access_policy.kv_user_pre_deployer](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/key_vault_access_policy) | resource |
| [azurerm_key_vault_access_policy.kv_user_systemidentity](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/key_vault_access_policy) | resource |
| [azurerm_key_vault_secret.app_token](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/key_vault_secret) | resource |
| [azurerm_key_vault_secret.github_pat](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/key_vault_secret) | resource |
| [azurerm_key_vault_secret.pat](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/key_vault_secret) | resource |
| [azurerm_key_vault_secret.pk](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/key_vault_secret) | resource |
| [azurerm_key_vault_secret.ppk](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/key_vault_secret) | resource |
| [azurerm_key_vault_secret.pwd](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/key_vault_secret) | resource |
| [azurerm_key_vault_secret.subscription](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/key_vault_secret) | resource |
| [azurerm_key_vault_secret.tenant](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/key_vault_secret) | resource |
| [azurerm_key_vault_secret.username](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/key_vault_secret) | resource |
| [azurerm_linux_virtual_machine.deployer](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/linux_virtual_machine) | resource |
| [azurerm_management_lock.keyvault](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/management_lock) | resource |
| [azurerm_network_interface.deployer](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/network_interface) | resource |
| [azurerm_network_security_group.nsg_mgmt](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/network_security_group) | resource |
| [azurerm_network_security_perimeter.perimeter](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/network_security_perimeter) | resource |
| [azurerm_network_security_perimeter_association.app_config](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/network_security_perimeter_association) | resource |
| [azurerm_network_security_perimeter_association.vault](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/network_security_perimeter_association) | resource |
| [azurerm_network_security_perimeter_association.webapp](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/network_security_perimeter_association) | resource |
| [azurerm_network_security_perimeter_profile.profile](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/network_security_perimeter_profile) | resource |
| [azurerm_network_security_rule.nsr_rdp](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/network_security_rule) | resource |
| [azurerm_network_security_rule.nsr_ssh](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/network_security_rule) | resource |
| [azurerm_network_security_rule.nsr_winrm](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/network_security_rule) | resource |
| [azurerm_private_endpoint.app_config](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/private_endpoint) | resource |
| [azurerm_private_endpoint.kv_user](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/private_endpoint) | resource |
| [azurerm_public_ip.bastion](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/public_ip) | resource |
| [azurerm_public_ip.deployer](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/public_ip) | resource |
| [azurerm_public_ip.firewall](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/public_ip) | resource |
| [azurerm_resource_group.deployer](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/resource_group) | resource |
| [azurerm_resource_group_template_deployment.sap_deployer](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/resource_group_template_deployment) | resource |
| [azurerm_role_assignment.appconfig_data_owner_current](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/role_assignment) | resource |
| [azurerm_role_assignment.appconfig_data_owner_msi](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/role_assignment) | resource |
| [azurerm_role_assignment.deployer](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/role_assignment) | resource |
| [azurerm_role_assignment.deployer_msi](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/role_assignment) | resource |
| [azurerm_role_assignment.dev_center_network_contributor](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/role_assignment) | resource |
| [azurerm_role_assignment.dev_center_reader](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/role_assignment) | resource |
| [azurerm_role_assignment.resource_group_contributor](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/role_assignment) | resource |
| [azurerm_role_assignment.resource_group_contributor_contributor_msi](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/role_assignment) | resource |
| [azurerm_role_assignment.resource_group_user_access_admin_msi](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/role_assignment) | resource |
| [azurerm_role_assignment.resource_group_user_access_admin_spn](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/role_assignment) | resource |
| [azurerm_role_assignment.role_assignment_additional_users](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/role_assignment) | resource |
| [azurerm_role_assignment.role_assignment_msi](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/role_assignment) | resource |
| [azurerm_role_assignment.role_assignment_msi_officer](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/role_assignment) | resource |
| [azurerm_role_assignment.role_assignment_msi_officer_bootstrap](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/role_assignment) | resource |
| [azurerm_role_assignment.role_assignment_spn](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/role_assignment) | resource |
| [azurerm_role_assignment.role_assignment_system_identity](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/role_assignment) | resource |
| [azurerm_role_assignment.subscription_contributor_msi](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/role_assignment) | resource |
| [azurerm_role_assignment.subscription_contributor_system_identity](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/role_assignment) | resource |
| [azurerm_role_assignment.subscription_useraccessadmin_msi](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/role_assignment) | resource |
| [azurerm_route.admin](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/route) | resource |
| [azurerm_route_table.rt](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/route_table) | resource |
| [azurerm_service_plan.appserviceplan](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/service_plan) | resource |
| [azurerm_storage_account.deployer](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/storage_account) | resource |
| [azurerm_subnet.bastion](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/subnet) | resource |
| [azurerm_subnet.firewall](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/subnet) | resource |
| [azurerm_subnet.subnet_agent](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/subnet) | resource |
| [azurerm_subnet.subnet_mgmt](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/subnet) | resource |
| [azurerm_subnet.webapp](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/subnet) | resource |
| [azurerm_subnet_network_security_group_association.associate_nsg_mgmt](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/subnet_network_security_group_association) | resource |
| [azurerm_user_assigned_identity.deployer](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/user_assigned_identity) | resource |
| [azurerm_virtual_machine_extension.configure](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/virtual_machine_extension) | resource |
| [azurerm_virtual_machine_extension.monitoring_defender_deployer_lnx](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/virtual_machine_extension) | resource |
| [azurerm_virtual_machine_extension.monitoring_extension_deployer_lnx](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/virtual_machine_extension) | resource |
| [azurerm_virtual_network.vnet_mgmt](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/virtual_network) | resource |
| [azurerm_virtual_network_peering.peering_agent_management](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/virtual_network_peering) | resource |
| [azurerm_virtual_network_peering.peering_management_agent](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/virtual_network_peering) | resource |
| [azurerm_windows_web_app.webapp](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/windows_web_app) | resource |
| [local_file.configure_deployer](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) | resource |
| [local_file.deployer_exports](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) | resource |
| [local_file.deployer_md](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) | resource |
| [null_resource.prepare-deployer](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [random_id.deployer](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/id) | resource |
| [random_integer.priority](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/integer) | resource |
| [random_password.deployer](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |
| [time_offset.secret_expiry_date](https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/offset) | resource |
| [time_sleep.wait_for_VM](https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/sleep) | resource |
| [time_sleep.wait_for_appconfig_data_owner_assignment](https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/sleep) | resource |
| [time_sleep.wait_for_appconfig_private_endpoint](https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/sleep) | resource |
| [time_sleep.wait_for_keyvault](https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/sleep) | resource |
| [time_sleep.wait_for_role_assignments](https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/sleep) | resource |
| [tls_private_key.deployer](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/private_key) | resource |
| [azurerm_app_configuration.app_config](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/data-sources/app_configuration) | data source |
| [azurerm_client_config.current](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/data-sources/client_config) | data source |
| [azurerm_client_config.deployer](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/data-sources/client_config) | data source |
| [azurerm_key_vault.kv_user](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/data-sources/key_vault) | data source |
| [azurerm_network_security_group.nsg_mgmt](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/data-sources/network_security_group) | data source |
| [azurerm_network_security_perimeter.perimeter](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/data-sources/network_security_perimeter) | data source |
| [azurerm_private_dns_zone.appconfig](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/data-sources/private_dns_zone) | data source |
| [azurerm_private_dns_zone.vault](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/data-sources/private_dns_zone) | data source |
| [azurerm_resource_group.deployer](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/data-sources/resource_group) | data source |
| [azurerm_storage_account.deployer](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/data-sources/storage_account) | data source |
| [azurerm_subnet.bastion](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/data-sources/subnet) | data source |
| [azurerm_subnet.firewall](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/data-sources/subnet) | data source |
| [azurerm_subnet.subnet_agent](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/data-sources/subnet) | data source |
| [azurerm_subnet.subnet_mgmt](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/data-sources/subnet) | data source |
| [azurerm_subnet.webapp](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/data-sources/subnet) | data source |
| [azurerm_subscription.primary](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/data-sources/subscription) | data source |
| [azurerm_user_assigned_identity.deployer](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/data-sources/user_assigned_identity) | data source |
| [azurerm_virtual_network.agent_virtual_network](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/data-sources/virtual_network) | data source |
| [azurerm_virtual_network.vnet_mgmt](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/data-sources/virtual_network) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_Agent_IP"></a> [Agent\_IP](#input\_Agent\_IP) | If provided, contains the IP address of the agent | `any` | n/a | yes |
| <a name="input_additional_network_id"></a> [additional\_network\_id](#input\_additional\_network\_id) | Additional network ID | `any` | n/a | yes |
| <a name="input_additional_users_to_add_to_keyvault_policies"></a> [additional\_users\_to\_add\_to\_keyvault\_policies](#input\_additional\_users\_to\_add\_to\_keyvault\_policies) | List of object IDs to add to key vault policies | `any` | n/a | yes |
| <a name="input_app_config_service"></a> [app\_config\_service](#input\_app\_config\_service) | Details of the Application Configuration Service | `any` | n/a | yes |
| <a name="input_app_service"></a> [app\_service](#input\_app\_service) | Details of the Application Service | `any` | n/a | yes |
| <a name="input_arm_client_id"></a> [arm\_client\_id](#input\_arm\_client\_id) | ARM client id | `any` | n/a | yes |
| <a name="input_assign_subscription_permissions"></a> [assign\_subscription\_permissions](#input\_assign\_subscription\_permissions) | Assign permissions on the subscription | `any` | n/a | yes |
| <a name="input_authentication"></a> [authentication](#input\_authentication) | Dictionary of authentication information | `any` | n/a | yes |
| <a name="input_auto_configure_deployer"></a> [auto\_configure\_deployer](#input\_auto\_configure\_deployer) | Value indicating if the deployer should be configured automatically | `any` | n/a | yes |
| <a name="input_bastion_deployment"></a> [bastion\_deployment](#input\_bastion\_deployment) | Value indicating if Azure Bastion should be deployed | `any` | n/a | yes |
| <a name="input_bastion_sku"></a> [bastion\_sku](#input\_bastion\_sku) | The SKU of the Bastion Host. Accepted values are Basic or Standard | `any` | n/a | yes |
| <a name="input_bootstrap"></a> [bootstrap](#input\_bootstrap) | Defines the phase of deployment | `any` | n/a | yes |
| <a name="input_configure"></a> [configure](#input\_configure) | Value indicating if deployer should be configured | `any` | n/a | yes |
| <a name="input_deployer"></a> [deployer](#input\_deployer) | Dictionary of information about the deployer | `any` | n/a | yes |
| <a name="input_enable_purge_control_for_keyvaults"></a> [enable\_purge\_control\_for\_keyvaults](#input\_enable\_purge\_control\_for\_keyvaults) | Disables the purge protection for Azure keyvaults. | `any` | n/a | yes |
| <a name="input_firewall"></a> [firewall](#input\_firewall) | Dictionary of Firewall settings | `any` | n/a | yes |
| <a name="input_infrastructure"></a> [infrastructure](#input\_infrastructure) | Dictionary of information about the common infrastructure | `any` | n/a | yes |
| <a name="input_key_vault"></a> [key\_vault](#input\_key\_vault) | The user brings existing Azure Key Vaults | `any` | n/a | yes |
| <a name="input_naming"></a> [naming](#input\_naming) | Defines the names for the resources | `any` | n/a | yes |
| <a name="input_naming_new"></a> [naming\_new](#input\_naming\_new) | Defines the additional names for the resources | `any` | n/a | yes |
| <a name="input_network_logical_name"></a> [network\_logical\_name](#input\_network\_logical\_name) | Logical name of the network | `any` | n/a | yes |
| <a name="input_options"></a> [options](#input\_options) | Dictionary of miscallaneous parameters | `any` | n/a | yes |
| <a name="input_place_delete_lock_on_resources"></a> [place\_delete\_lock\_on\_resources](#input\_place\_delete\_lock\_on\_resources) | If defined, a delete lock will be placed on the key resources | `any` | n/a | yes |
| <a name="input_public_network_access_enabled"></a> [public\_network\_access\_enabled](#input\_public\_network\_access\_enabled) | Defines if the public access should be enabled for keyvaults and storage accounts | `any` | n/a | yes |
| <a name="input_sa_connection_string"></a> [sa\_connection\_string](#input\_sa\_connection\_string) | Storage account connection string | `any` | n/a | yes |
| <a name="input_set_secret_expiry"></a> [set\_secret\_expiry](#input\_set\_secret\_expiry) | Set expiry date for secrets | `any` | n/a | yes |
| <a name="input_soft_delete_retention_days"></a> [soft\_delete\_retention\_days](#input\_soft\_delete\_retention\_days) | The number of days that items should be retained in the soft delete period | `any` | n/a | yes |
| <a name="input_spn_id"></a> [spn\_id](#input\_spn\_id) | SPN ID to be used for the deployment | `any` | n/a | yes |
| <a name="input_ssh-timeout"></a> [ssh-timeout](#input\_ssh-timeout) | SSH timeout | `any` | n/a | yes |
| <a name="input_use_private_endpoint"></a> [use\_private\_endpoint](#input\_use\_private\_endpoint) | Boolean value indicating if private endpoint should be used for the deployment | `any` | n/a | yes |
| <a name="input_use_service_endpoint"></a> [use\_service\_endpoint](#input\_use\_service\_endpoint) | Boolean value indicating if service endpoints should be used for the deployment | `any` | n/a | yes |
| <a name="input_webapp_client_secret"></a> [webapp\_client\_secret](#input\_webapp\_client\_secret) | App registration client secret | `any` | n/a | yes |
| <a name="input_deployer_vm_count"></a> [deployer\_vm\_count](#input\_deployer\_vm\_count) | Number of deployer VMs to create | `number` | `1` | no |
| <a name="input_dns_settings"></a> [dns\_settings](#input\_dns\_settings) | DNS details for the deployment | `map` | `{}` | no |
| <a name="input_enable_firewall_for_keyvaults_and_storage"></a> [enable\_firewall\_for\_keyvaults\_and\_storage](#input\_enable\_firewall\_for\_keyvaults\_and\_storage) | Boolean value indicating if firewall should be enabled for key vaults and storage | `bool` | `false` | no |
| <a name="input_platform"></a> [platform](#input\_platform) | Type of agent to be used | `string` | `"devops"` | no |
| <a name="input_subnets_to_add"></a> [subnets\_to\_add](#input\_subnets\_to\_add) | List of subnets to add to storage account and keyvaults firewall | `list` | `[]` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_agent_subnet_id"></a> [agent\_subnet\_id](#output\_agent\_subnet\_id) | Agent Subnet ID |
| <a name="output_app_configuration_created_count"></a> [app\_configuration\_created\_count](#output\_app\_configuration\_created\_count) | Diagnostic count of created application configuration stores (discrete optional feature; retained standalone since merging would obscure its independent on/off toggle) |
| <a name="output_application_configuration_id"></a> [application\_configuration\_id](#output\_application\_configuration\_id) | Application Configuration Resource Id |
| <a name="output_application_configuration_name"></a> [application\_configuration\_name](#output\_application\_configuration\_name) | Application Configuration Name |
| <a name="output_created_resource_group_id"></a> [created\_resource\_group\_id](#output\_created\_resource\_group\_id) | Created resource group ID |
| <a name="output_created_resource_group_location"></a> [created\_resource\_group\_location](#output\_created\_resource\_group\_location) | Created resource group's location |
| <a name="output_created_resource_group_name"></a> [created\_resource\_group\_name](#output\_created\_resource\_group\_name) | Created resource group name |
| <a name="output_created_resource_group_subscription_id"></a> [created\_resource\_group\_subscription\_id](#output\_created\_resource\_group\_subscription\_id) | Created resource group' subscription ID |
| <a name="output_deployer_client_id"></a> [deployer\_client\_id](#output\_deployer\_client\_id) | Deployer User Assigned Identity (Client Id) |
| <a name="output_deployer_id"></a> [deployer\_id](#output\_deployer\_id) | Random ID for deployer |
| <a name="output_deployer_keyvault_user_arm_id"></a> [deployer\_keyvault\_user\_arm\_id](#output\_deployer\_keyvault\_user\_arm\_id) | Azure resource ID of the deployer key vault |
| <a name="output_deployer_private_ip_address"></a> [deployer\_private\_ip\_address](#output\_deployer\_private\_ip\_address) | Deployer private IP Addresses |
| <a name="output_deployer_public_ip_address"></a> [deployer\_public\_ip\_address](#output\_deployer\_public\_ip\_address) | Deployer Public IP Address |
| <a name="output_deployer_system_assigned_identity"></a> [deployer\_system\_assigned\_identity](#output\_deployer\_system\_assigned\_identity) | Deployer System Assigned Identity |
| <a name="output_deployer_uai"></a> [deployer\_uai](#output\_deployer\_uai) | Deployer User Assigned Identity |
| <a name="output_deployer_user_assigned_identity"></a> [deployer\_user\_assigned\_identity](#output\_deployer\_user\_assigned\_identity) | Deployer System Assigned Identity |
| <a name="output_diagnostics_account_id"></a> [diagnostics\_account\_id](#output\_diagnostics\_account\_id) | Diagnostics Storage Account ID |
| <a name="output_diagnostics_storage_info"></a> [diagnostics\_storage\_info](#output\_diagnostics\_storage\_info) | Diagnostics storage account tags and network security posture for terraform test diagnostics |
| <a name="output_extension_ids"></a> [extension\_ids](#output\_extension\_ids) | Virtual machine extension id |
| <a name="output_firewall_id"></a> [firewall\_id](#output\_firewall\_id) | Firewall ID |
| <a name="output_firewall_ip"></a> [firewall\_ip](#output\_firewall\_ip) | Firewall private IP address |
| <a name="output_infrastructure_resource_cardinality"></a> [infrastructure\_resource\_cardinality](#output\_infrastructure\_resource\_cardinality) | Cardinality (creation count) of core infrastructure resources for terraform test diagnostics. 1 = created (greenfield), 0 = looked up (brownfield). |
| <a name="output_key_vault_info"></a> [key\_vault\_info](#output\_key\_vault\_info) | Deployer key vault creation status, tags, and security posture for terraform test diagnostics |
| <a name="output_network_security_perimeter_created_count"></a> [network\_security\_perimeter\_created\_count](#output\_network\_security\_perimeter\_created\_count) | Diagnostic count of created network security perimeters (discrete optional feature; retained standalone for the same reason as app\_configuration\_created\_count) |
| <a name="output_network_security_perimeter_id"></a> [network\_security\_perimeter\_id](#output\_network\_security\_perimeter\_id) | The Azure network security perimeter id |
| <a name="output_nsg_mgmt"></a> [nsg\_mgmt](#output\_nsg\_mgmt) | Management VNet NSG |
| <a name="output_pk_secret_name"></a> [pk\_secret\_name](#output\_pk\_secret\_name) | Public Key Secret Name |
| <a name="output_ppk_secret_name"></a> [ppk\_secret\_name](#output\_ppk\_secret\_name) | Private Key Secret Name |
| <a name="output_pwd_secret_name"></a> [pwd\_secret\_name](#output\_pwd\_secret\_name) | Password Secret Name |
| <a name="output_random_id"></a> [random\_id](#output\_random\_id) | Random ID for deployer |
| <a name="output_resource_group_info"></a> [resource\_group\_info](#output\_resource\_group\_info) | Deployer resource group creation status and tags for terraform test diagnostics |
| <a name="output_subnet_bastion_address_prefixes"></a> [subnet\_bastion\_address\_prefixes](#output\_subnet\_bastion\_address\_prefixes) | Bastion Subnet Address Prefixes |
| <a name="output_subnet_mgmt_address_prefixes"></a> [subnet\_mgmt\_address\_prefixes](#output\_subnet\_mgmt\_address\_prefixes) | Management Subnet Address Prefixes |
| <a name="output_subnet_mgmt_id"></a> [subnet\_mgmt\_id](#output\_subnet\_mgmt\_id) | Management Subnet ID |
| <a name="output_subnet_webapp_id"></a> [subnet\_webapp\_id](#output\_subnet\_webapp\_id) | Webapp Subnet ID |
| <a name="output_user_vault_name"></a> [user\_vault\_name](#output\_user\_vault\_name) | Key Vault Name |
| <a name="output_username_secret_name"></a> [username\_secret\_name](#output\_username\_secret\_name) | Username Secret Name |
| <a name="output_vnet_mgmt_id"></a> [vnet\_mgmt\_id](#output\_vnet\_mgmt\_id) | Management VNet ID |
| <a name="output_webapp_id"></a> [webapp\_id](#output\_webapp\_id) | Webapp ID |
| <a name="output_webapp_identity"></a> [webapp\_identity](#output\_webapp\_identity) | Webapp Identity |
| <a name="output_webapp_url_base"></a> [webapp\_url\_base](#output\_webapp\_url\_base) | Webapp URL Base |

<!-- END_TF_DOCS -->