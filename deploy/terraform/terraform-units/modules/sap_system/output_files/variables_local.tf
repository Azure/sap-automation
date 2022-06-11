
locals {

  tfstate_resource_id          = try(var.tfstate_resource_id, "")
  tfstate_storage_account_name = split("/", local.tfstate_resource_id)[8]
  ansible_container_name       = try(var.naming.resource_suffixes.ansible, "ansible")

  kv_name = split("/", var.sid_keyvault_user_id)[8]

  landscape_tfstate = var.landscape_tfstate
  ips_dbnodes_admin = [for key, value in var.nics_dbnodes_admin : value.private_ip_address]
  ips_dbnodes_db    = [for key, value in var.nics_dbnodes_db : value.private_ip_address]

  ips_primary_scs = var.nics_scs
  ips_primary_app = var.nics_app
  ips_primary_web = var.nics_web

  ips_scs = [for key, value in local.ips_primary_scs : value.private_ip_address]
  ips_app = [for key, value in local.ips_primary_app : value.private_ip_address]
  ips_web = [for key, value in local.ips_primary_web : value.private_ip_address]

  ips_primary_anydb = var.nics_anydb
  ips_anydbnodes    = [for key, value in local.ips_primary_anydb : value.private_ip_address]

  secret_prefix = var.use_local_credentials ? var.naming.prefix.SDU : var.naming.prefix.WORKLOAD_ZONE
  dns_label     = try(var.landscape_tfstate.dns_label, "")

  app_server_count = length(var.nics_app)
  scs_server_count = length(var.nics_scs)

  app_tier = (local.app_server_count + local.scs_server_count) > 0

  db_supported_tiers  = local.app_tier ? lower(var.platform) : format("%s, scs, pas", lower(var.platform))
  scs_supported_tiers = local.app_server_count > 0 ? "scs" : "scs, pas"

  # If PAS and SCS is on same server
  pas_instance_number = (local.app_server_count + local.scs_server_count) <= 1 ? (
    "02") : (
    "00"
  )


}
