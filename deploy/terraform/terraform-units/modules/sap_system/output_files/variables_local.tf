
locals {

  tfstate_resource_id                  = try(var.tfstate_resource_id, "")
  tfstate_storage_account_name         = split("/", local.tfstate_resource_id)[8]
  ansible_container_name               = try(var.naming.resource_suffixes.ansible, "ansible")

  kv_name                              = split("/", var.sid_keyvault_user_id)[8]

  landscape_tfstate                    = var.landscape_tfstate
  ips_dbnodes_admin                    = var.database_admin_ips


  # ips_scs = [for key, value in local.ips_primary_scs : value.private_ip_address]
  # ips_app = [for key, value in local.ips_primary_app : value.private_ip_address]
  # ips_web = [for key, value in local.ips_primary_web : value.private_ip_address]

  ips_primary_db                       = var.database_server_ips
  ips_dbnodes                          = var.database_server_ips
  ## ips_dbnodes    = [for key, value in local.ips_primary_db : value.private_ip_address]

  secret_prefix                        = var.use_local_credentials ? var.naming.prefix.SDU : var.naming.prefix.WORKLOAD_ZONE
  dns_label                            = try(var.landscape_tfstate.dns_label, "")

  app_server_count                     = length(var.application_server_ips)
  scs_server_count                     = length(var.scs_server_ips)

  app_tier                             = (local.app_server_count + local.scs_server_count) > 0

  db_supported_tiers                   = local.app_tier ? lower(var.platform) : format("%s, scs, pas", lower(var.platform))
  scs_supported_tiers                  = local.app_server_count > 0 ? "scs" : "scs, pas"

  # If PAS and SCS is on same server
  pas_instance_number                  = (length(var.pas_instance_number) > 0) ? var.pas_instance_number : (
                                          (local.app_server_count + local.scs_server_count) <= 1 ? (
                                            "02") : (
                                            "00"
                                          )
                                        )

  db_secondary_dns_names               = var.platform == "HANA" ? (
                                           var.naming.virtualmachine_names.HANA_SECONDARY_DNSNAME) : (
                                           var.naming.virtualmachine_names.ANYDB_SECONDARY_DNSNAME
                                         )

  encoded_configuration                = replace(yamlencode(var.configuration_settings), "\"", "")
  settings                             = length(local.encoded_configuration) > 4 ? local.encoded_configuration : ""

  scs_iqn                              = format("iqn.2006-04.ascs%s.local:ascs%s", lower(var.sap_sid), lower(var.sap_sid))
  db_iqn                               = format("iqn.2006-04.db%s.local:db%s", lower(var.sap_sid), lower(var.sap_sid))

  iscsi_scs_servers                    = var.scs_cluster_type == "ISCSI" ? (
                                          distinct(flatten([for idx, vm in var.iSCSI_server_names : [
                                            format("{ host: '%s', ip : %s, iqn: %s, type: 'scs' }", vm, var.iSCSI_server_ips[idx],  local.scs_iqn)]]))) : (
                                          [])
  iscsi_db_servers                     = var.database_cluster_type == "ISCSI" ? (
                                           distinct(flatten([for idx, vm in var.iSCSI_server_names : [
                                              format("{ host: '%s', ip : %s, iqn: %s, type: 'db' }", vm, var.iSCSI_server_ips[idx], local.db_iqn)]]))) : (
                                          [])

}
