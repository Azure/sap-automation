environment = "DEV"
location = "westeurope"
Description = "HANA distributed system on SUSE sles-sap-15-sp5 gen2"
save_naming_information = true
use_prefix = true
use_zonal_markers = false
use_secondary_ips = true
use_scalesets_for_deployment = false
database_use_premium_v2_storage = false
upgrade_packages = false
network_logical_name = "SAP01"
use_loadbalancers_for_standalone_deployments = true
use_private_endpoint = true

scs_cluster_type = "AFA"
scs_cluster_disk_lun = 5

scs_cluster_disk_size = 128

scs_cluster_disk_type = "Premium_ZRS"
database_cluster_type = "AFA"

database_cluster_disk_lun = 8

database_cluster_disk_size = 128

database_cluster_disk_type = "Premium_ZRS"

use_msi_for_clusters = true
use_simple_mount = false

use_fence_kdump = false

use_fence_kdump_size_gb_db = 128

use_fence_kdump_lun_db = 8

use_fence_kdump_size_gb_scs = 64

use_fence_kdump_lun_scs = 4

database_sid = "HDB"
database_platform = "HANA"
database_server_count = 1
database_high_availability = false

database_size = "E20ds_v4"

database_vm_use_DHCP = true

database_vm_image = {
  os_type = "LINUX",
  source_image_id = "",
  publisher = "SUSE",
  offer = "sles-sap-15-sp5",
  sku = "gen2",
  version = "latest",
  type = "marketplace"
}

database_vm_zones = ["1"]
database_use_ppg = true

database_use_avset = false

app_tier_sizing_dictionary_key = "Optimized"

enable_app_tier_deployment = true

app_tier_use_DHCP = true

sid = "X00"
scs_server_count = 1
scs_high_availability = false
scs_instance_number = "01"
ers_instance_number = "02"
pas_instance_number = "00"
scs_server_zones = ["1"]
scs_server_image = {
  os_type = "LINUX",
  source_image_id = "",
  publisher = "SUSE",
  offer = "sles-sap-15-sp5",
  sku = "gen2",
  version = "latest",
  type = "marketplace"
}

scs_server_use_ppg = true

# scs_server_use_avset = false
application_server_count = 2
application_server_zones = ["1"]
app_tier_dual_nics = false
application_server_use_ppg = true
application_server_use_avset = true
application_server_image = {
  os_type = "LINUX",
  source_image_id = "",
  publisher = "SUSE",
  offer = "sles-sap-15-sp5",
  sku = "gen2",
  version = "latest",
  type = "marketplace"
}

webdispatcher_server_count = 1
web_sid = "W00"
web_instance_number = "00"
webdispatcher_server_use_ppg = false
webdispatcher_server_use_avset = false
webdispatcher_server_zones = ["1"]
webdispatcher_server_image = {
  os_type = "LINUX",
  source_image_id = "",
  publisher = "SUSE",
  offer = "sles-sap-15-sp5",
  sku = "gen2",
  version = "latest",
  type = "marketplace"
}

resource_offset = 1
deploy_application_security_groups = true
deploy_v1_monitoring_extension = false
deploy_monitoring_extension = true
deploy_defender_extension = true
dns_a_records_for_secondary_names = true
register_endpoints_with_dns = true
NFS_provider = "AFS"
sapmnt_volume_size = 128
use_random_id_for_storageaccounts = true
ANF_HANA_use_AVG = false
ANF_HANA_use_Zones = true
# ANF_HANA_data_volume_count = 1
ANF_HANA_log_volume_count = 1
nsg_asg_with_vnet = false
use_app_proximityplacementgroups = false
enable_purge_control_for_keyvaults = false
use_spn = false
tags = {
  "DeployedBy" = "SDAF-SAP-SYSTEM1",
}

database_HANA_use_ANF_scaleout_scenario = false
database_HANA_no_standby_role = false
stand_by_node_count = 0
enable_ha_monitoring = false
enable_os_monitoring = false