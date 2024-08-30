environment = "DEV"
location = "westeurope"
deploy_monitoring_extension = true

deploy_defender_extension = false
network_logical_name = "SAP01"
network_address_space = "10.110.0.0/16"

use_private_endpoint = true

use_service_endpoint = true

peer_with_control_plane_vnet = true

enable_firewall_for_keyvaults_and_storage = false

public_network_access_enabled = true

place_delete_lock_on_resources = true
admin_subnet_address_prefix = "10.110.0.0/19"
db_subnet_address_prefix = "10.110.96.0/19"
app_subnet_address_prefix = "10.110.32.0/19"
web_subnet_address_prefix = "10.110.128.0/19"

use_custom_dns_a_registration = false
register_virtual_network_to_dns = true
register_endpoints_with_dns = true
enable_purge_control_for_keyvaults = false
enable_rbac_authorization_for_keyvault = false
soft_delete_retention_days = 14
automation_username = "azureadm"
install_volume_size = 1024
create_transport_storage = true
transport_volume_size = 128
storage_account_replication_type = "ZRS"
dns_label = "azure.weeu.sdaf.contoso.net"
NFS_provider = "AFS"
use_AFS_for_shared_storage = true
ANF_service_level = "Ultra"
ANF_qos_type = "Manual"
iscsi_count = 0
iscsi_size = "Standard_D2s_v3"
iscsi_useDHCP = true
iscsi_authentication_type = "key"
iscsi_authentication_username = "azureadm"
use_spn = false
utility_vm_count = 0
utility_vm_os_disk_size = "128"
utility_vm_os_disk_type = "Premium_LRS"
utility_vm_useDHCP = true

tags = {
  "DeployedBy" = "SDAF",
}

create_ams_instance = false