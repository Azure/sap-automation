<!-- BEGIN_TF_DOCS -->
# Module Description

This folder contains the terraform templates for the SAP landscape deployment module.

## variables\_global.tf
The file variables\_global.tf contains the input variables that are required by the module.

## outputs.tf
The file outputs.tf contains the output variables that are exposed by the module.

## variables\_local.tf
The file variables\_local.tf contains the local variables that are required by the module.

## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_azapi"></a> [azapi](#requirement\_azapi) | 2.7.0 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | 4.80.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_azapi"></a> [azapi](#provider\_azapi) | 2.7.0 |
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | 4.80.0 |
| <a name="provider_azurerm.deployer"></a> [azurerm.deployer](#provider\_azurerm.deployer) | 4.80.0 |
| <a name="provider_azurerm.dnsmanagement"></a> [azurerm.dnsmanagement](#provider\_azurerm.dnsmanagement) | 4.80.0 |
| <a name="provider_azurerm.main"></a> [azurerm.main](#provider\_azurerm.main) | 4.80.0 |
| <a name="provider_azurerm.peering"></a> [azurerm.peering](#provider\_azurerm.peering) | 4.80.0 |
| <a name="provider_azurerm.privatelinkdnsmanagement"></a> [azurerm.privatelinkdnsmanagement](#provider\_azurerm.privatelinkdnsmanagement) | 4.80.0 |
| <a name="provider_local"></a> [local](#provider\_local) | n/a |
| <a name="provider_random"></a> [random](#provider\_random) | n/a |
| <a name="provider_template"></a> [template](#provider\_template) | n/a |
| <a name="provider_time"></a> [time](#provider\_time) | n/a |
| <a name="provider_tls"></a> [tls](#provider\_tls) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [azapi_resource.ams_instance](https://registry.terraform.io/providers/azure/azapi/2.7.0/docs/resources/resource) | resource |
| [azurerm_app_configuration_key.KeyVaultName](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/app_configuration_key) | resource |
| [azurerm_app_configuration_key.KeyVaultResourceId](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/app_configuration_key) | resource |
| [azurerm_app_configuration_key.VirtualNetworkResourceId](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/app_configuration_key) | resource |
| [azurerm_app_configuration_key.witness_name](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/app_configuration_key) | resource |
| [azurerm_key_vault.kv_user](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/key_vault) | resource |
| [azurerm_key_vault_access_policy.kv_user](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/key_vault_access_policy) | resource |
| [azurerm_key_vault_access_policy.kv_user_additional_users](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/key_vault_access_policy) | resource |
| [azurerm_key_vault_access_policy.kv_user_msi](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/key_vault_access_policy) | resource |
| [azurerm_key_vault_access_policy.kv_user_spn](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/key_vault_access_policy) | resource |
| [azurerm_key_vault_secret.deployer_keyvault_user_name](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/key_vault_secret) | resource |
| [azurerm_key_vault_secret.iscsi_password](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/key_vault_secret) | resource |
| [azurerm_key_vault_secret.iscsi_pk](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/key_vault_secret) | resource |
| [azurerm_key_vault_secret.iscsi_ppk](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/key_vault_secret) | resource |
| [azurerm_key_vault_secret.iscsi_username](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/key_vault_secret) | resource |
| [azurerm_key_vault_secret.sid_password](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/key_vault_secret) | resource |
| [azurerm_key_vault_secret.sid_pk](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/key_vault_secret) | resource |
| [azurerm_key_vault_secret.sid_ppk](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/key_vault_secret) | resource |
| [azurerm_key_vault_secret.sid_username](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/key_vault_secret) | resource |
| [azurerm_key_vault_secret.subscription](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/key_vault_secret) | resource |
| [azurerm_key_vault_secret.tenant](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/key_vault_secret) | resource |
| [azurerm_key_vault_secret.witness_access_key](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/key_vault_secret) | resource |
| [azurerm_linux_virtual_machine.iscsi](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/linux_virtual_machine) | resource |
| [azurerm_linux_virtual_machine.utility_vm](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/linux_virtual_machine) | resource |
| [azurerm_management_lock.key_vault](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/management_lock) | resource |
| [azurerm_management_lock.vnet_sap](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/management_lock) | resource |
| [azurerm_nat_gateway.ng](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/nat_gateway) | resource |
| [azurerm_nat_gateway_public_ip_association.ng_pip_assoc](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/nat_gateway_public_ip_association) | resource |
| [azurerm_netapp_account.workload_netapp_account](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/netapp_account) | resource |
| [azurerm_netapp_pool.workload_netapp_pool](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/netapp_pool) | resource |
| [azurerm_netapp_volume.install](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/netapp_volume) | resource |
| [azurerm_netapp_volume.transport](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/netapp_volume) | resource |
| [azurerm_network_interface.iscsi](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/network_interface) | resource |
| [azurerm_network_interface.utility_vm](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/network_interface) | resource |
| [azurerm_network_interface_security_group_association.iscsi](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/network_interface_security_group_association) | resource |
| [azurerm_network_security_group.admin](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/network_security_group) | resource |
| [azurerm_network_security_group.anf](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/network_security_group) | resource |
| [azurerm_network_security_group.app](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/network_security_group) | resource |
| [azurerm_network_security_group.db](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/network_security_group) | resource |
| [azurerm_network_security_group.iscsi](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/network_security_group) | resource |
| [azurerm_network_security_group.storage](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/network_security_group) | resource |
| [azurerm_network_security_group.web](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/network_security_group) | resource |
| [azurerm_network_security_perimeter_association.install](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/network_security_perimeter_association) | resource |
| [azurerm_network_security_perimeter_association.kv_user](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/network_security_perimeter_association) | resource |
| [azurerm_network_security_perimeter_association.transport](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/network_security_perimeter_association) | resource |
| [azurerm_network_security_perimeter_association.witness_storage](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/network_security_perimeter_association) | resource |
| [azurerm_network_security_rule.nsr_controlplane_admin](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/network_security_rule) | resource |
| [azurerm_network_security_rule.nsr_controlplane_anf](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/network_security_rule) | resource |
| [azurerm_network_security_rule.nsr_controlplane_app](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/network_security_rule) | resource |
| [azurerm_network_security_rule.nsr_controlplane_db](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/network_security_rule) | resource |
| [azurerm_network_security_rule.nsr_controlplane_iscsi](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/network_security_rule) | resource |
| [azurerm_network_security_rule.nsr_controlplane_storage](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/network_security_rule) | resource |
| [azurerm_network_security_rule.nsr_controlplane_web](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/network_security_rule) | resource |
| [azurerm_network_security_rule.nsr_external_db](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/network_security_rule) | resource |
| [azurerm_network_security_rule.nsr_internal_db](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/network_security_rule) | resource |
| [azurerm_private_dns_zone_virtual_network_link.storage](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/private_dns_zone_virtual_network_link) | resource |
| [azurerm_private_dns_zone_virtual_network_link.vault](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/private_dns_zone_virtual_network_link) | resource |
| [azurerm_private_dns_zone_virtual_network_link.vnet_sap](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/private_dns_zone_virtual_network_link) | resource |
| [azurerm_private_dns_zone_virtual_network_link.vnet_sap_file](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/private_dns_zone_virtual_network_link) | resource |
| [azurerm_private_endpoint.install](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/private_endpoint) | resource |
| [azurerm_private_endpoint.kv_user](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/private_endpoint) | resource |
| [azurerm_private_endpoint.storage_bootdiag](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/private_endpoint) | resource |
| [azurerm_private_endpoint.transport](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/private_endpoint) | resource |
| [azurerm_private_endpoint.utility_blob](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/private_endpoint) | resource |
| [azurerm_private_endpoint.utility_file](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/private_endpoint) | resource |
| [azurerm_private_endpoint.witness_storage](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/private_endpoint) | resource |
| [azurerm_public_ip.ng_pip](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/public_ip) | resource |
| [azurerm_resource_group.resource_group](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/resource_group) | resource |
| [azurerm_resource_group_template_deployment.sap_workloadzone](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/resource_group_template_deployment) | resource |
| [azurerm_role_assignment.kv_user_additional_users](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/role_assignment) | resource |
| [azurerm_role_assignment.kv_user_msi_rbac](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/role_assignment) | resource |
| [azurerm_role_assignment.kv_user_msi_rbac_secret_officer](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/role_assignment) | resource |
| [azurerm_role_assignment.resource_group_user_access_admin](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/role_assignment) | resource |
| [azurerm_role_assignment.role_assignment_msi](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/role_assignment) | resource |
| [azurerm_role_assignment.role_assignment_msi_officer](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/role_assignment) | resource |
| [azurerm_role_assignment.role_assignment_spn](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/role_assignment) | resource |
| [azurerm_role_assignment.role_assignment_spn_officer](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/role_assignment) | resource |
| [azurerm_role_assignment.role_assignment_vault_ssi](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/role_assignment) | resource |
| [azurerm_route.admin](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/route) | resource |
| [azurerm_route_table.rt](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/route_table) | resource |
| [azurerm_storage_account.install](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/storage_account) | resource |
| [azurerm_storage_account.storage_bootdiag](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/storage_account) | resource |
| [azurerm_storage_account.transport](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/storage_account) | resource |
| [azurerm_storage_account.utility](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/storage_account) | resource |
| [azurerm_storage_account.witness_storage](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/storage_account) | resource |
| [azurerm_storage_account_network_rules.install](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/storage_account_network_rules) | resource |
| [azurerm_storage_blob.readme](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/storage_blob) | resource |
| [azurerm_storage_blob.tfvars](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/storage_blob) | resource |
| [azurerm_storage_blob.tfvars_state](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/storage_blob) | resource |
| [azurerm_storage_container.utility](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/storage_container) | resource |
| [azurerm_storage_share.install](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/storage_share) | resource |
| [azurerm_storage_share.install_smb](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/storage_share) | resource |
| [azurerm_storage_share.transport](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/storage_share) | resource |
| [azurerm_storage_share.utility](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/storage_share) | resource |
| [azurerm_subnet.admin](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/subnet) | resource |
| [azurerm_subnet.ams](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/subnet) | resource |
| [azurerm_subnet.anf](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/subnet) | resource |
| [azurerm_subnet.app](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/subnet) | resource |
| [azurerm_subnet.db](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/subnet) | resource |
| [azurerm_subnet.iscsi](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/subnet) | resource |
| [azurerm_subnet.storage](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/subnet) | resource |
| [azurerm_subnet.web](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/subnet) | resource |
| [azurerm_subnet_nat_gateway_association.ng_subnet_assoc](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/subnet_nat_gateway_association) | resource |
| [azurerm_subnet_nat_gateway_association.ng_subnet_assoc_db](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/subnet_nat_gateway_association) | resource |
| [azurerm_subnet_nat_gateway_association.ng_subnet_assoc_web](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/subnet_nat_gateway_association) | resource |
| [azurerm_subnet_network_security_group_association.admin](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/subnet_network_security_group_association) | resource |
| [azurerm_subnet_network_security_group_association.anf](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/subnet_network_security_group_association) | resource |
| [azurerm_subnet_network_security_group_association.app](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/subnet_network_security_group_association) | resource |
| [azurerm_subnet_network_security_group_association.db](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/subnet_network_security_group_association) | resource |
| [azurerm_subnet_network_security_group_association.storage](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/subnet_network_security_group_association) | resource |
| [azurerm_subnet_network_security_group_association.web](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/subnet_network_security_group_association) | resource |
| [azurerm_subnet_route_table_association.admin](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/subnet_route_table_association) | resource |
| [azurerm_subnet_route_table_association.ams](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/subnet_route_table_association) | resource |
| [azurerm_subnet_route_table_association.app](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/subnet_route_table_association) | resource |
| [azurerm_subnet_route_table_association.db](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/subnet_route_table_association) | resource |
| [azurerm_subnet_route_table_association.iscsi](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/subnet_route_table_association) | resource |
| [azurerm_subnet_route_table_association.web](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/subnet_route_table_association) | resource |
| [azurerm_virtual_machine_extension.monitoring_defender_iscsi_lnx](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/virtual_machine_extension) | resource |
| [azurerm_virtual_machine_extension.monitoring_defender_utility_lnx](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/virtual_machine_extension) | resource |
| [azurerm_virtual_machine_extension.monitoring_defender_utility_win](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/virtual_machine_extension) | resource |
| [azurerm_virtual_machine_extension.monitoring_extension_iscsi_lnx](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/virtual_machine_extension) | resource |
| [azurerm_virtual_machine_extension.monitoring_extension_utility_lnx](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/virtual_machine_extension) | resource |
| [azurerm_virtual_machine_extension.monitoring_extension_utility_win](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/virtual_machine_extension) | resource |
| [azurerm_virtual_network.vnet_sap](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/virtual_network) | resource |
| [azurerm_virtual_network_dns_servers.vnet_sap_dns_servers](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/virtual_network_dns_servers) | resource |
| [azurerm_virtual_network_peering.peering_additional_network_sap](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/virtual_network_peering) | resource |
| [azurerm_virtual_network_peering.peering_management_sap](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/virtual_network_peering) | resource |
| [azurerm_virtual_network_peering.peering_sap_additional_network](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/virtual_network_peering) | resource |
| [azurerm_virtual_network_peering.peering_sap_management](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/virtual_network_peering) | resource |
| [azurerm_windows_virtual_machine.utility_vm](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/resources/windows_virtual_machine) | resource |
| [local_file.resource_group_md](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) | resource |
| [local_file.workload_zone_exports](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) | resource |
| [random_id.random_id](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/id) | resource |
| [random_password.created_password](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |
| [random_password.iscsi_password](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |
| [time_offset.secret_expiry_date](https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/offset) | resource |
| [time_sleep.wait_for_private_endpoints](https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/sleep) | resource |
| [time_sleep.wait_for_role_assignment](https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/sleep) | resource |
| [time_sleep.wait_for_subnets](https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/sleep) | resource |
| [tls_private_key.iscsi](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/private_key) | resource |
| [tls_private_key.sid](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/private_key) | resource |
| [azurerm_app_configuration.app_config](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/data-sources/app_configuration) | data source |
| [azurerm_app_configuration_key.deployer_network_id](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/data-sources/app_configuration_key) | data source |
| [azurerm_app_configuration_key.deployer_subnet_id](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/data-sources/app_configuration_key) | data source |
| [azurerm_client_config.current](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/data-sources/client_config) | data source |
| [azurerm_key_vault.kv_user](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/data-sources/key_vault) | data source |
| [azurerm_key_vault_secret.iscsi_password](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/data-sources/key_vault_secret) | data source |
| [azurerm_key_vault_secret.iscsi_pk](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/data-sources/key_vault_secret) | data source |
| [azurerm_key_vault_secret.iscsi_ppk](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/data-sources/key_vault_secret) | data source |
| [azurerm_key_vault_secret.iscsi_username](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/data-sources/key_vault_secret) | data source |
| [azurerm_key_vault_secret.sid_password](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/data-sources/key_vault_secret) | data source |
| [azurerm_key_vault_secret.sid_pk](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/data-sources/key_vault_secret) | data source |
| [azurerm_key_vault_secret.sid_ppk](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/data-sources/key_vault_secret) | data source |
| [azurerm_key_vault_secret.sid_username](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/data-sources/key_vault_secret) | data source |
| [azurerm_netapp_account.workload_netapp_account](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/data-sources/netapp_account) | data source |
| [azurerm_netapp_pool.workload_netapp_pool](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/data-sources/netapp_pool) | data source |
| [azurerm_netapp_volume.install](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/data-sources/netapp_volume) | data source |
| [azurerm_netapp_volume.transport](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/data-sources/netapp_volume) | data source |
| [azurerm_network_security_group.iscsi](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/data-sources/network_security_group) | data source |
| [azurerm_network_security_perimeter.perimeter](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/data-sources/network_security_perimeter) | data source |
| [azurerm_network_security_perimeter_profile.profile](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/data-sources/network_security_perimeter_profile) | data source |
| [azurerm_private_dns_a_record.install](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/data-sources/private_dns_a_record) | data source |
| [azurerm_private_dns_a_record.transport](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/data-sources/private_dns_a_record) | data source |
| [azurerm_private_dns_zone.file](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/data-sources/private_dns_zone) | data source |
| [azurerm_private_dns_zone.keyvault](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/data-sources/private_dns_zone) | data source |
| [azurerm_private_dns_zone.storage](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/data-sources/private_dns_zone) | data source |
| [azurerm_private_endpoint_connection.install](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/data-sources/private_endpoint_connection) | data source |
| [azurerm_private_endpoint_connection.kv_user](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/data-sources/private_endpoint_connection) | data source |
| [azurerm_private_endpoint_connection.transport](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/data-sources/private_endpoint_connection) | data source |
| [azurerm_resource_group.resource_group](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/data-sources/resource_group) | data source |
| [azurerm_storage_account.install](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/data-sources/storage_account) | data source |
| [azurerm_storage_account.storage_bootdiag](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/data-sources/storage_account) | data source |
| [azurerm_storage_account.transport](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/data-sources/storage_account) | data source |
| [azurerm_storage_account.witness_storage](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/data-sources/storage_account) | data source |
| [azurerm_subnet.admin](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/data-sources/subnet) | data source |
| [azurerm_subnet.ams](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/data-sources/subnet) | data source |
| [azurerm_subnet.anf](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/data-sources/subnet) | data source |
| [azurerm_subnet.app](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/data-sources/subnet) | data source |
| [azurerm_subnet.db](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/data-sources/subnet) | data source |
| [azurerm_subnet.iscsi](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/data-sources/subnet) | data source |
| [azurerm_subnet.storage](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/data-sources/subnet) | data source |
| [azurerm_subnet.web](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/data-sources/subnet) | data source |
| [azurerm_virtual_network.vnet_sap](https://registry.terraform.io/providers/hashicorp/azurerm/4.80.0/docs/data-sources/virtual_network) | data source |
| [template_cloudinit_config.config_growpart](https://registry.terraform.io/providers/hashicorp/template/latest/docs/data-sources/cloudinit_config) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_NFS_provider"></a> [NFS\_provider](#input\_NFS\_provider) | Describes the NFS solution used | `any` | n/a | yes |
| <a name="input_additional_users_to_add_to_keyvault_policies"></a> [additional\_users\_to\_add\_to\_keyvault\_policies](#input\_additional\_users\_to\_add\_to\_keyvault\_policies) | Additional users to add to the key vault policies | `any` | n/a | yes |
| <a name="input_create_transport_storage"></a> [create\_transport\_storage](#input\_create\_transport\_storage) | Boolean file indicating if storage should be created for SAP transport | `any` | n/a | yes |
| <a name="input_deployer_tfstate"></a> [deployer\_tfstate](#input\_deployer\_tfstate) | Deployer remote tfstate file | `any` | n/a | yes |
| <a name="input_dns_settings"></a> [dns\_settings](#input\_dns\_settings) | DNS namespace | `any` | n/a | yes |
| <a name="input_enable_firewall_for_keyvaults_and_storage"></a> [enable\_firewall\_for\_keyvaults\_and\_storage](#input\_enable\_firewall\_for\_keyvaults\_and\_storage) | Boolean value indicating if firewall should be enabled for key vaults and storage | `any` | n/a | yes |
| <a name="input_install_always_create_fileshares"></a> [install\_always\_create\_fileshares](#input\_install\_always\_create\_fileshares) | Value indicating if file shares are created ehen using existing storage accounts | `any` | n/a | yes |
| <a name="input_install_private_endpoint_id"></a> [install\_private\_endpoint\_id](#input\_install\_private\_endpoint\_id) | Azure Resource Identifier for an private endpoint connection | `any` | n/a | yes |
| <a name="input_install_storage_account_id"></a> [install\_storage\_account\_id](#input\_install\_storage\_account\_id) | Azure Resource Identifier for an existing storage account | `any` | n/a | yes |
| <a name="input_install_volume_size"></a> [install\_volume\_size](#input\_install\_volume\_size) | The volume size in GB for install volume | `any` | n/a | yes |
| <a name="input_keyvault_private_endpoint_id"></a> [keyvault\_private\_endpoint\_id](#input\_keyvault\_private\_endpoint\_id) | Existing private endpoint for key vault | `any` | n/a | yes |
| <a name="input_naming"></a> [naming](#input\_naming) | Defines the names for the resources | `any` | n/a | yes |
| <a name="input_options"></a> [options](#input\_options) | Configuration options | `any` | n/a | yes |
| <a name="input_peer_with_control_plane_vnet"></a> [peer\_with\_control\_plane\_vnet](#input\_peer\_with\_control\_plane\_vnet) | Defines in the SAP VNet will be peered with the controlplane VNet | `any` | n/a | yes |
| <a name="input_place_delete_lock_on_resources"></a> [place\_delete\_lock\_on\_resources](#input\_place\_delete\_lock\_on\_resources) | If defined, a delete lock will be placed on the key resources | `any` | n/a | yes |
| <a name="input_public_network_access_enabled"></a> [public\_network\_access\_enabled](#input\_public\_network\_access\_enabled) | Defines if the public access should be enabled for keyvaults and storage accounts | `any` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | List of tags to associate to all resources | `any` | n/a | yes |
| <a name="input_terraform_template_version"></a> [terraform\_template\_version](#input\_terraform\_template\_version) | The version of Terraform templates that were identified in the state file | `any` | n/a | yes |
| <a name="input_transport_private_endpoint_id"></a> [transport\_private\_endpoint\_id](#input\_transport\_private\_endpoint\_id) | Azure Resource Identifier for an private endpoint connection | `any` | n/a | yes |
| <a name="input_transport_storage_account_id"></a> [transport\_storage\_account\_id](#input\_transport\_storage\_account\_id) | Azure Resource Identifier for an existing storage account | `any` | n/a | yes |
| <a name="input_transport_volume_size"></a> [transport\_volume\_size](#input\_transport\_volume\_size) | The volume size in GB for transport volume | `any` | n/a | yes |
| <a name="input_use_deployer"></a> [use\_deployer](#input\_use\_deployer) | Use the deployer | `any` | n/a | yes |
| <a name="input_AFS_enable_encryption_in_transit"></a> [AFS\_enable\_encryption\_in\_transit](#input\_AFS\_enable\_encryption\_in\_transit) | Enable encryption in transit for Azure Files | `bool` | `false` | no |
| <a name="input_ANF_settings"></a> [ANF\_settings](#input\_ANF\_settings) | ANF settings | `map` | <pre>{<br/>  "arm_id": "",<br/>  "export_policy_client_access_list": [],<br/>  "install_volume_name": "",<br/>  "install_volume_size": 128,<br/>  "install_volume_throughput": 32,<br/>  "name": "",<br/>  "pool_name": "",<br/>  "qos_type": "Manual",<br/>  "service_level": "Standard",<br/>  "size_in_tb": 4,<br/>  "transport_volume_name": "",<br/>  "transport_volume_size": 32,<br/>  "transport_volume_throughput": 32,<br/>  "use": false,<br/>  "use_existing_install_volume": false,<br/>  "use_existing_pool": false,<br/>  "use_existing_transport_volume": false<br/>}</pre> | no |
| <a name="input_Agent_IP"></a> [Agent\_IP](#input\_Agent\_IP) | If provided, contains the IP address of the agent | `string` | `""` | no |
| <a name="input_additional_network_id"></a> [additional\_network\_id](#input\_additional\_network\_id) | Agent Network resource ID | `string` | `""` | no |
| <a name="input_authentication"></a> [authentication](#input\_authentication) | Details of ssh key pair | `map` | <pre>{<br/>  "password": "",<br/>  "path_to_private_key": "",<br/>  "path_to_public_key": "",<br/>  "username": "azureadm"<br/>}</pre> | no |
| <a name="input_data_plane_available"></a> [data\_plane\_available](#input\_data\_plane\_available) | Boolean value indicating if storage account access is via data plane | `bool` | `true` | no |
| <a name="input_deployment"></a> [deployment](#input\_deployment) | The type of deployment | `string` | `"update"` | no |
| <a name="input_diagnostics_storage_account"></a> [diagnostics\_storage\_account](#input\_diagnostics\_storage\_account) | Storage account information for diagnostics account | `map` | <pre>{<br/>  "arm_id": ""<br/>}</pre> | no |
| <a name="input_infrastructure"></a> [infrastructure](#input\_infrastructure) | Details of the Azure infrastructure to deploy the SAP landscape into | `map` | `{}` | no |
| <a name="input_install_create_smb_shares"></a> [install\_create\_smb\_shares](#input\_install\_create\_smb\_shares) | Value indicating if SMB shares should be created | `bool` | `true` | no |
| <a name="input_key_vault"></a> [key\_vault](#input\_key\_vault) | The user brings existing Azure Key Vaults | `map` | `{}` | no |
| <a name="input_private_endpoint_network_policies"></a> [private\_endpoint\_network\_policies](#input\_private\_endpoint\_network\_policies) | Controls network policy support for private endpoints on workload zone subnets | `string` | `"Enabled"` | no |
| <a name="input_storage_account_replication_type"></a> [storage\_account\_replication\_type](#input\_storage\_account\_replication\_type) | Storage account replication type | `string` | `"ZRS"` | no |
| <a name="input_use_AFS_for_shared_storage"></a> [use\_AFS\_for\_shared\_storage](#input\_use\_AFS\_for\_shared\_storage) | If true, will use AFS for installation media. | `bool` | `false` | no |
| <a name="input_use_private_endpoint"></a> [use\_private\_endpoint](#input\_use\_private\_endpoint) | Boolean value indicating if private endpoint should be used for the deployment | `bool` | `false` | no |
| <a name="input_use_service_endpoint"></a> [use\_service\_endpoint](#input\_use\_service\_endpoint) | Boolean value indicating if service endpoints should be used for the deployment | `bool` | `false` | no |
| <a name="input_utility_storage_settings"></a> [utility\_storage\_settings](#input\_utility\_storage\_settings) | List of utility storage account configurations (normalized from transform.tf) | <pre>list(object({<br/>                                                             name                       = string<br/>                                                             account_kind               = string<br/>                                                             account_tier               = string<br/>                                                             account_replication_type    = string<br/>                                                             https_traffic_only_enabled = bool<br/>                                                             file_shares = list(object({<br/>                                                               name     = string<br/>                                                               quota    = number<br/>                                                               protocol = string<br/>                                                             }))<br/>                                                             blob_containers = list(object({<br/>                                                               name = string<br/>                                                             }))<br/>                                                           }))</pre> | `[]` | no |
| <a name="input_vm_settings"></a> [vm\_settings](#input\_vm\_settings) | Details of the jumpbox to deploy | `map` | <pre>{<br/>  "count": 0<br/>}</pre> | no |
| <a name="input_witness_storage_account"></a> [witness\_storage\_account](#input\_witness\_storage\_account) | Storage account information for witness storage account | `map` | <pre>{<br/>  "arm_id": ""<br/>}</pre> | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_ANF_pool_settings"></a> [ANF\_pool\_settings](#output\_ANF\_pool\_settings) | json structure with ANF information |
| <a name="output_admin_nsg_id"></a> [admin\_nsg\_id](#output\_admin\_nsg\_id) | Azure resource identifier for the admin subnet network security group |
| <a name="output_admin_subnet_id"></a> [admin\_subnet\_id](#output\_admin\_subnet\_id) | Azure resource identifier for the admin subnet |
| <a name="output_ams_instance_created_count"></a> [ams\_instance\_created\_count](#output\_ams\_instance\_created\_count) | Number of AMS instances created by this module |
| <a name="output_ams_resource_id"></a> [ams\_resource\_id](#output\_ams\_resource\_id) | Azure resource identifier for the AMS resource |
| <a name="output_ams_subnet_id"></a> [ams\_subnet\_id](#output\_ams\_subnet\_id) | Azure resource identifier for the ams subnet |
| <a name="output_anf_subnet_id"></a> [anf\_subnet\_id](#output\_anf\_subnet\_id) | Azure resource identifier for the anf subnet |
| <a name="output_app_nsg_id"></a> [app\_nsg\_id](#output\_app\_nsg\_id) | Azure resource identifier for the app subnet network security group |
| <a name="output_app_subnet_id"></a> [app\_subnet\_id](#output\_app\_subnet\_id) | Azure resource identifier for the app subnet |
| <a name="output_created_resource_group_id"></a> [created\_resource\_group\_id](#output\_created\_resource\_group\_id) | Created resource group ID |
| <a name="output_created_resource_group_name"></a> [created\_resource\_group\_name](#output\_created\_resource\_group\_name) | Created resource group name |
| <a name="output_created_resource_group_subscription_id"></a> [created\_resource\_group\_subscription\_id](#output\_created\_resource\_group\_subscription\_id) | Created resource group' subscription ID |
| <a name="output_db_nsg_id"></a> [db\_nsg\_id](#output\_db\_nsg\_id) | Azure resource identifier for the database subnet network security group |
| <a name="output_db_subnet_id"></a> [db\_subnet\_id](#output\_db\_subnet\_id) | Azure resource identifier for the db subnet |
| <a name="output_dns_info_vms"></a> [dns\_info\_vms](#output\_dns\_info\_vms) | DNS info for the Virtual Machines |
| <a name="output_dns_link_counts"></a> [dns\_link\_counts](#output\_dns\_link\_counts) | Cardinality of Private Link DNS virtual-network links for terraform test diagnostics |
| <a name="output_iSCSI_server_ips"></a> [iSCSI\_server\_ips](#output\_iSCSI\_server\_ips) | IPs for iSCSI devices |
| <a name="output_iSCSI_server_names"></a> [iSCSI\_server\_names](#output\_iSCSI\_server\_names) | Names for iSCSI devices |
| <a name="output_iSCSI_servers"></a> [iSCSI\_servers](#output\_iSCSI\_servers) | iSCSI devices |
| <a name="output_install_path"></a> [install\_path](#output\_install\_path) | Path to the SAP installation volume |
| <a name="output_iscsi_authentication_type"></a> [iscsi\_authentication\_type](#output\_iscsi\_authentication\_type) | Authentication type for iSCSI device |
| <a name="output_iscsi_authentication_username"></a> [iscsi\_authentication\_username](#output\_iscsi\_authentication\_username) | Username for iSCSI device |
| <a name="output_iscsi_vm_count"></a> [iscsi\_vm\_count](#output\_iscsi\_vm\_count) | Number of iSCSI VMs created by this module |
| <a name="output_kv_user"></a> [kv\_user](#output\_kv\_user) | Azure resource identifier for the user credential keyvault |
| <a name="output_netapp_resource_counts"></a> [netapp\_resource\_counts](#output\_netapp\_resource\_counts) | Cardinality of NetApp account/pool resources for terraform test diagnostics |
| <a name="output_network_resource_counts"></a> [network\_resource\_counts](#output\_network\_resource\_counts) | Cardinality (creation count) of workload-zone network resources for terraform test diagnostics. 1 = created (greenfield), 0 = looked up (brownfield). |
| <a name="output_ng_resource_id"></a> [ng\_resource\_id](#output\_ng\_resource\_id) | Azure resource identifier for the NAT Gateway |
| <a name="output_nics_iscsi"></a> [nics\_iscsi](#output\_nics\_iscsi) | NICs for iSCSI devices |
| <a name="output_private_endpoint_network_policies"></a> [private\_endpoint\_network\_policies](#output\_private\_endpoint\_network\_policies) | Private endpoint network policy state for module-created workload zone subnets |
| <a name="output_privatelink_file_id"></a> [privatelink\_file\_id](#output\_privatelink\_file\_id) | Private DNS Zone ID for the file resources |
| <a name="output_privatelink_keyvault_id"></a> [privatelink\_keyvault\_id](#output\_privatelink\_keyvault\_id) | Private DNS Zone ID for the keyvault resources |
| <a name="output_privatelink_storage_id"></a> [privatelink\_storage\_id](#output\_privatelink\_storage\_id) | Private DNS Zone ID for the storage resources |
| <a name="output_random_id"></a> [random\_id](#output\_random\_id) | Random ID |
| <a name="output_resolved_iscsi_nic_ips"></a> [resolved\_iscsi\_nic\_ips](#output\_resolved\_iscsi\_nic\_ips) | Resolved iSCSI NIC IP input list for terraform test diagnostics. |
| <a name="output_route_table_id"></a> [route\_table\_id](#output\_route\_table\_id) | Azure resource identifier for the route table |
| <a name="output_saptransport_path"></a> [saptransport\_path](#output\_saptransport\_path) | Path to the SAP transport volume |
| <a name="output_sid_password_secret_name"></a> [sid\_password\_secret\_name](#output\_sid\_password\_secret\_name) | Azure Keyvault secret name for the password |
| <a name="output_sid_private_key_secret_name"></a> [sid\_private\_key\_secret\_name](#output\_sid\_private\_key\_secret\_name) | Azure Keyvault secret name for the Private key |
| <a name="output_sid_public_key_secret_name"></a> [sid\_public\_key\_secret\_name](#output\_sid\_public\_key\_secret\_name) | Azure Keyvault secret name for the Public key |
| <a name="output_sid_username_secret_name"></a> [sid\_username\_secret\_name](#output\_sid\_username\_secret\_name) | Azure Keyvault secret name for the username |
| <a name="output_storage_account_counts"></a> [storage\_account\_counts](#output\_storage\_account\_counts) | Cardinality of workload-zone storage account resources for terraform test diagnostics. |
| <a name="output_storage_bootdiag_endpoint"></a> [storage\_bootdiag\_endpoint](#output\_storage\_bootdiag\_endpoint) | Diagnostics storage account's private endpoint's Azure resource identifier |
| <a name="output_storage_nsg_id"></a> [storage\_nsg\_id](#output\_storage\_nsg\_id) | Azure resource identifier for the storage subnet network security group |
| <a name="output_storage_subnet_id"></a> [storage\_subnet\_id](#output\_storage\_subnet\_id) | Azure resource identifier for the storage subnet |
| <a name="output_storageaccount_name"></a> [storageaccount\_name](#output\_storageaccount\_name) | Diagnostics storage account name |
| <a name="output_storageaccount_resourcegroup_name"></a> [storageaccount\_resourcegroup\_name](#output\_storageaccount\_resourcegroup\_name) | Diagnostics storage account's resource group name |
| <a name="output_subnet_mgmt_id"></a> [subnet\_mgmt\_id](#output\_subnet\_mgmt\_id) | Azure resource identifier for the management subnet |
| <a name="output_transport_storage_account_id"></a> [transport\_storage\_account\_id](#output\_transport\_storage\_account\_id) | Transport storage account ID |
| <a name="output_user_credential_vault_id"></a> [user\_credential\_vault\_id](#output\_user\_credential\_vault\_id) | Azure resource identifier for the user credential keyvault |
| <a name="output_utility_storage_account_ids"></a> [utility\_storage\_account\_ids](#output\_utility\_storage\_account\_ids) | List of utility storage account IDs |
| <a name="output_utility_storage_account_names"></a> [utility\_storage\_account\_names](#output\_utility\_storage\_account\_names) | List of utility storage account names |
| <a name="output_utility_vm_computer_names"></a> [utility\_vm\_computer\_names](#output\_utility\_vm\_computer\_names) | Planned utility VM computer names |
| <a name="output_utility_vm_count"></a> [utility\_vm\_count](#output\_utility\_vm\_count) | Number of utility VMs created by this module |
| <a name="output_vnet_sap_id"></a> [vnet\_sap\_id](#output\_vnet\_sap\_id) | Azure resource identifier for the Virtual Network |
| <a name="output_vnet_tags"></a> [vnet\_tags](#output\_vnet\_tags) | Tags applied to the created workload VNet, if any |
| <a name="output_web_nsg_id"></a> [web\_nsg\_id](#output\_web\_nsg\_id) | Azure resource identifier for the web subnet network security group |
| <a name="output_web_subnet_id"></a> [web\_subnet\_id](#output\_web\_subnet\_id) | Azure resource identifier for the web subnet |
| <a name="output_witness_storage_account"></a> [witness\_storage\_account](#output\_witness\_storage\_account) | Witness storage account |
| <a name="output_witness_storage_account_key"></a> [witness\_storage\_account\_key](#output\_witness\_storage\_account\_key) | Witness storage account key |
| <a name="output_workload_zone_prefix"></a> [workload\_zone\_prefix](#output\_workload\_zone\_prefix) | Workload zone prefix |

<!-- END_TF_DOCS -->