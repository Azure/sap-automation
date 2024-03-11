#######################################4#######################################8
#                                                                              #
#                           Logic for Hosts file                               #
#                                                                              #
#######################################4#######################################8

resource "local_file" "ansible_inventory_new_yml" {
  content       = templatefile(format("%s%s", path.module, "/ansible_inventory.tmpl"), {
                    ips_dbnodes         = var.database_server_ips
                    dbnodes             = var.platform == "HANA" ? var.naming.virtualmachine_names.HANA_COMPUTERNAME : var.naming.virtualmachine_names.ANYDB_COMPUTERNAME
                    db_vmnodes          = var.database_server_vm_names
                    virt_dbnodes        = var.use_secondary_ips ? (
                                            var.platform == "HANA" ? var.naming.virtualmachine_names.HANA_SECONDARY_DNSNAME : var.naming.virtualmachine_names.ANYDB_SECONDARY_DNSNAME
                                            ) : (
                                            var.platform == "HANA" ? var.naming.virtualmachine_names.HANA_COMPUTERNAME : var.naming.virtualmachine_names.ANYDB_COMPUTERNAME
                                          )
                    ips_scs             = length(var.scs_server_ips) > 0 ? (
                                            length(var.scs_server_ips) > 1 ? (
                                              slice(var.scs_server_ips, 0, 1)) : (
                                              var.scs_server_ips
                                            )) : (
                                            []
                                          )
                    ips_ers             = length(var.scs_server_ips) > 1 ? (
                                            slice(var.scs_server_ips, 1, length(var.scs_server_ips))) : (
                                            []
                                          )

                    ips_pas             = length(var.application_server_ips) > 0 ? slice(var.application_server_ips, 0, 1) : [],
                    ips_app             = length(var.application_server_ips) > 1 ? slice(var.application_server_ips, 1, length(var.application_server_ips)) : []
                    ips_web             = length(var.webdispatcher_server_ips) > 0 ? var.webdispatcher_server_ips : [],
                    sid                 = var.sap_sid,

                    pas_servers         = length(var.application_server_ips) > 0 ? (
                                            slice(var.naming.virtualmachine_names.APP_COMPUTERNAME, 0, 1)) : (
                                            []
                                          ),
                    pas_vmnodes         = length(var.application_server_ips) > 0 ? (
                                            slice(var.app_vm_names, 0, 1)) : (
                                            []
                                          ),

                    virt_pas_servers    = var.use_secondary_ips ? (
                                            length(var.application_server_ips) > 0 ? slice(var.naming.virtualmachine_names.APP_SECONDARY_DNSNAME, 0, 1) : []) : (
                                            length(var.application_server_ips) > 0 ? slice(var.naming.virtualmachine_names.APP_COMPUTERNAME, 0, 1) : []
                                          ),

                    app_servers         = length(var.application_server_ips) > 1 ? (
                                            slice(var.naming.virtualmachine_names.APP_COMPUTERNAME, 1, length(var.application_server_ips))) : (
                                            []
                                          ),

                    app_vmnodes         = length(var.application_server_ips) > 0 ? (
                                            slice(var.app_vm_names, 1, length(var.app_vm_names))) : (
                                            []
                                          ),

                    virt_app_servers    = var.use_secondary_ips ? (
                                            length(var.application_server_ips) > 1 ? slice(var.naming.virtualmachine_names.APP_SECONDARY_DNSNAME, 1, length(var.application_server_ips)) : []) : (
                                            length(var.application_server_ips) > 1 ? slice(var.naming.virtualmachine_names.APP_COMPUTERNAME, 1, length(var.application_server_ips)) : []
                                          ),

                    scs_servers         = length(var.scs_server_ips) > 0 ? (
                                            slice(var.naming.virtualmachine_names.SCS_COMPUTERNAME, 0, 1)) : (
                                            []
                                          ),
                    scs_vmnodes         = length(var.scs_server_ips) > 0 ? (
                                            slice(var.scs_vm_names, 0, 1)) : (
                                            []
                                          ),

                    virt_scs_servers    = var.use_secondary_ips ? (
                                            length(var.scs_server_ips) > 0 ? slice(var.naming.virtualmachine_names.SCS_SECONDARY_DNSNAME, 0, 1) : []) : (
                                            length(var.scs_server_ips) > 0 ? slice(var.naming.virtualmachine_names.SCS_COMPUTERNAME, 0, 1) : []
                                          ),

                    ers_servers         = length(var.scs_server_ips) > 1 ? (
                                            slice(var.naming.virtualmachine_names.SCS_COMPUTERNAME, 1, length(var.scs_server_ips))) : (
                                            []
                                          ),
                    ers_vmnodes         = length(var.scs_server_ips) > 0 ? (
                                            slice(var.scs_vm_names, 1, length(var.scs_vm_names))) : (
                                            []
                                          ),

                    virt_ers_servers    = var.use_secondary_ips ? (
                                            length(var.scs_server_ips) > 1 ? slice(var.naming.virtualmachine_names.SCS_SECONDARY_DNSNAME, 1, length(var.scs_server_ips)) : []) : (
                                            length(var.scs_server_ips) > 1 ? slice(var.naming.virtualmachine_names.SCS_COMPUTERNAME, 1, length(var.scs_server_ips)) : []
                                          ),

                    web_servers         = length(var.webdispatcher_server_ips) > 0 ? (
                                            slice(var.naming.virtualmachine_names.WEB_COMPUTERNAME, 0, length(var.webdispatcher_server_ips))) : (
                                            []
                                          ),

                    web_vmnodes         = length(var.webdispatcher_server_ips) > 0 ? (
                                            slice(var.webdispatcher_server_vm_names, 0, length(var.webdispatcher_server_ips))) : (
                                            []
                                          ),

                    virt_web_servers    = var.use_secondary_ips ? (
                                            length(var.webdispatcher_server_ips) > 0 ? slice(var.naming.virtualmachine_names.WEB_SECONDARY_DNSNAME, 0, length(var.webdispatcher_server_ips)) : []) : (
                                            length(var.webdispatcher_server_ips) > 0 ? slice(var.naming.virtualmachine_names.WEB_COMPUTERNAME, 0, length(var.webdispatcher_server_ips)) : []
                                          ),

                    prefix              = var.naming.prefix.SDU,
                    separator           = var.naming.separator,
                    platform            = var.shared_home ? format("%s-multi-sid", lower(var.platform)) : lower(var.platform),
                    db_connection       = var.platform == "SQLSERVER" ? "winrm" : "ssh"
                    db_become_user      = var.platform == "SQLSERVER" ? var.ansible_user : "root"
                    scs_connection      = upper(var.app_tier_os_types["scs"]) == "WINDOWS" ? "winrm" : "ssh"
                    scs_become_user     = upper(var.app_tier_os_types["scs"]) == "WINDOWS" ? var.ansible_user : "root"
                    ers_connection      = upper(var.app_tier_os_types["scs"]) == "WINDOWS" ? "winrm" : "ssh"
                    app_connection      = upper(var.app_tier_os_types["app"]) == "WINDOWS" ? "winrm" : "ssh"
                    app_become_user     = upper(var.app_tier_os_types["app"]) == "WINDOWS" ? var.ansible_user : "root"
                    web_connection      = upper(var.app_tier_os_types["web"]) == "WINDOWS" ? "winrm" : "ssh"
                    web_become_user     = upper(var.app_tier_os_types["web"]) == "WINDOWS" ? var.ansible_user : "root"
                    app_connectiontype  = try(var.authentication_type, "key")
                    web_connectiontype  = try(var.authentication_type, "key")
                    scs_connectiontype  = try(var.authentication_type, "key")
                    ers_connectiontype  = try(var.authentication_type, "key")
                    db_connectiontype   = try(var.database_authentication_type, "key")
                    ansible_user        = var.ansible_user
                    db_supported_tiers  = local.db_supported_tiers
                    scs_supported_tiers = local.scs_supported_tiers
                    ips_observers       = var.observer_ips
                    observers           = length(var.observer_ips) > 0 ? var.naming.virtualmachine_names.OBSERVER_COMPUTERNAME : []

                    # Only create these if the operating system is Windows
                    winrm_cert_valid    = var.platform == "SQLSERVER" ? (
                                            "ansible_winrm_server_cert_validation : ignore") : (
                                            upper(var.app_tier_os_types["scs"]) == "WINDOWS" ? "ansible_winrm_server_cert_validation : ignore" : ""
                                          )

                    winrm_timeout_sec   = var.platform == "SQLSERVER" ? (
                                            "ansible_winrm_operation_timeout_sec  : 120") : (
                                            upper(var.app_tier_os_types["scs"]) == "WINDOWS" ? "ansible_winrm_operation_timeout_sec  : 120" : ""
                                          )

                    winrm_read_timeout  = var.platform == "SQLSERVER" ? (
                                            "ansible_winrm_read_timeout_sec       : 150") : (
                                            upper(var.app_tier_os_types["scs"]) == "WINDOWS" ? "ansible_winrm_read_timeout_sec       : 150" : ""
                                          )

                    winrm_transport     = var.platform == "SQLSERVER" ? (
                                            "ansible_winrm_transport              : credssp") : (
                                            upper(var.app_tier_os_types["scs"]) == "WINDOWS" ? "ansible_winrm_transport              : credssp" : ""
                                          )

                    db_os_type          = var.platform == "SQLSERVER" ? "windows" : "linux"
                    scs_os_type         = upper(var.app_tier_os_types["scs"]) == "WINDOWS" ? "windows" : "linux"
                    app_os_type         = upper(var.app_tier_os_types["app"]) == "WINDOWS" ? "windows" : "linux"
                    web_os_type         = upper(var.app_tier_os_types["web"]) == "WINDOWS" ? "windows" : "linux"

                    upgrade_packages    = var.upgrade_packages

                    ips_ip_iscsi        = var.iSCSI_server_ips
                    iscsi_servers       = var.iSCSI_server_names
                    iscsi_server_list   = var.iSCSI_servers

    }
  )
  filename             = format("%s/%s_hosts.yaml", path.cwd, var.sap_sid)
  file_permission      = "0660"
  directory_permission = "0770"
}

# resource "azurerm_storage_blob" "hosts_yaml" {
#   provider               = azurerm.deployer
#   name                   = format("%s_hosts.yml", trimspace(var.sap_sid))
#   storage_account_name   = local.tfstate_storage_account_name
#   storage_container_name = lower(format("tfvars/SYSTEM/%s", var.naming.prefix.SDU))
#   type                   = "Block"
#   source                 = local_file.ansible_inventory_new_yml.filename
# }

resource "local_file" "sap-parameters_yml" {
  content = templatefile(format("%s/sap-parameters.tmpl", path.module), {
              app_instance_number         = var.app_instance_number
              bom                         = length(var.bom_name) > 0 ? var.bom_name : ""
              database_cluster_type       = var.database_cluster_type
              database_high_availability  = var.database_high_availability
              database_cluster_ip         = try(format("%s/%s", var.database_cluster_ip, var.database_subnet_netmask), "")
              db_instance_number          = try(var.database.instance.number, "00")
              database_loadbalancer_ip    = var.database_loadbalancer_ip
              db_sid                      = var.db_sid
              disks                       = var.disks
              dns                         = local.dns_label
              dns                         = var.dns
              ers_instance_number         = var.ers_instance_number
              ers_server_loadbalancer_ip  = var.ers_server_loadbalancer_ip
              hana_data                   = length(try(var.hana_data[0], "")) > 1 ? (
                                              format("hana_data_mountpoint:          %s", jsonencode(var.hana_data))) : (
                                              ""
                                            )
              hana_log                    = length(try(var.hana_log[0], "")) > 1 ? (
                                              format("hana_log_mountpoint:           %s", jsonencode(var.hana_log))) : (
                                              ""
                                            )
              hana_shared                 = length(try(var.hana_shared[0], "")) > 1 ? (
                                              format("hana_shared_mountpoint:        %s", jsonencode(var.hana_shared))) : (
                                              ""
                                            )
              install_path                = length(trimspace(var.install_path)) > 0 ? (
                                              format("usr_sap_install_mountpoint:    %s", var.install_path)) : (
                                              ""
                                            )
              is_use_simple_mount         = var.use_simple_mount
              is_use_fence_kdump          = var.is_use_fence_kdump
              iscsi_server_list           = concat(local.iscsi_scs_servers, local.iscsi_db_servers)
              kv_name                     = local.kv_name,
              NFS_provider                = var.NFS_provider
              pas_instance_number         = var.pas_instance_number
              platform                    = var.platform
              sap_mnt                     = length(var.sap_mnt) > 1 ? (
                                              format("sap_mnt:                       %s", var.sap_mnt)) : (
                                              ""
                                            )
              sap_transport               = length(trimspace(var.sap_transport)) > 0 ? (
                                              format("sap_trans:                     %s", var.sap_transport)) : (
                                              ""
                                            )
              asd_disks                   = concat(var.scs_shared_disks, var.database_shared_disks)
              scale_out                   = var.scale_out
              scs_cluster_loadbalancer_ip = try(format("%s/%s", var.scs_cluster_loadbalancer_ip, var.app_subnet_netmask), "")
              scs_cluster_type            = var.scs_cluster_type
              scs_high_availability       = var.scs_high_availability
              scs_instance_number         = (local.app_server_count + local.scs_server_count) == 0 ? (
                                              "01") : (
                                              var.scs_instance_number
                                            )
              scs_server_loadbalancer_ip  = var.scs_server_loadbalancer_ip
              secret_prefix               = local.secret_prefix,
              settings                    = local.settings
              sid                         = var.sap_sid,
              upgrade_packages            = var.upgrade_packages ? "true" : "false"
              use_msi_for_clusters        = var.use_msi_for_clusters
              usr_sap                     = length(var.usr_sap) > 1 ? (
                                              format("usr_sap_mountpoint:            %s", var.usr_sap)) : (
                                              ""
                                            )
              web_instance_number         = var.web_instance_number
              web_sid                     = var.web_sid
              ams_resource_id             = var.ams_resource_id
              enable_os_monitoring        = var.enable_os_monitoring
              enable_ha_monitoring        = var.enable_ha_monitoring

    }
  )
  filename             = format("%s/sap-parameters.yaml", path.cwd)
  file_permission      = "0660"
  directory_permission = "0770"
}

# resource "azurerm_storage_blob" "params_yaml" {
#   provider               = azurerm.deployer
#   name                   = "sap-parameters.yaml"
#   storage_account_name   = local.tfstate_storage_account_name
#   storage_container_name = lower(format("tfvars/SYSTEM/%s", var.naming.prefix.SDU))
#   type                   = "Block"
#   source                 = local_file.sap-parameters_yml.filename
# }


resource "local_file" "sap_inventory_md" {
  content = templatefile(format("%s/sap_application.tmpl", path.module), {
              sid                         = var.sap_sid,
              db_sid                      = var.db_sid
              kv_name                     = local.kv_name,
              scs_server_loadbalancer_ip  = length(var.scs_server_loadbalancer_ip) > 0 ? var.scs_server_loadbalancer_ip : try(var.scs_server_ips[0], "")
              platform                    = lower(var.platform)
              kv_pwd_secret               = format("%s-%s-sap-password", local.secret_prefix, var.sap_sid)
              }
            )
  filename             = format("%s/%s.md", path.cwd, var.sap_sid)
  file_permission      = "0660"
  directory_permission = "0770"
}

# locals {
#   fileContents     = fileexists(format("%s/sap-parameters.yaml", path.cwd)) ? file(format("%s/sap-parameters.yaml", path.cwd)) : ""
#   fileContentsList = split("\n", local.fileContents)

#   items = compact([for strValue in local.fileContentsList :
#     length(trimspace(strValue)) > 0 ? (
#       length(split(":", strValue)) > 1 ? (
#         substr(trimspace(strValue), 0, 1) != "-" ? (
#           trimspace(strValue)) : (
#           ""
#         )
#         ) : (
#         ""
#       )) : (
#       ""
#     )
#     ]
#   )

#   itemvalues = tomap({ for strValue in local.items :
#     trimspace(split(":", strValue)[0]) => trimspace(substr(strValue, length(split(":", strValue)[0]) + 1, -1))
#   })

#   bom = trimspace(coalesce(var.bom_name, lookup(local.itemvalues, "bom_base_name", ""), " "))

#   token            = lookup(local.itemvalues, "sapbits_sas_token", "")
#   ora_release      = lookup(local.itemvalues, "ora_release", "")
#   ora_version      = lookup(local.itemvalues, "ora_version", "")
#   oracle_sbp_patch = lookup(local.itemvalues, "oracle_sbp_patch", "")
#   domain           = lookup(local.itemvalues, "domain", "")
#   domain_user      = lookup(local.itemvalues, "domain_user", "")
#   domain_name      = lookup(local.itemvalues, "domain_name", "")

#   oracle = (upper(var.platform) == "ORACLE" || upper(var.platform) == "ORACLE-ASM") ? (
#     format("ora_release: %s\nora_version: %s\noracle_sbp_patch: %s\n", local.ora_release, local.ora_version, local.oracle_sbp_patch)) : (
#     ""
#   )

#   domain_info = upper(var.platform) == "SQLSERVER" ? (
#     format("domain: %s\ndomain_user: %s\ndomain_name: %s\n", local.domain, local.domain_user, local.domain_name)) : (
#     ""
#   )
# }

resource "local_file" "sap_inventory_for_wiki_md" {
  content = templatefile(format("%s/sid-description.tmpl", path.module), {
    sid                 = var.sap_sid,
    db_sid              = var.db_sid
    kv_name             = local.kv_name,
    scs_server_loadbalancer_ip           = length(var.scs_server_loadbalancer_ip) > 0 ? var.scs_server_loadbalancer_ip : try(var.scs_server_ips[0], "")
    platform            = upper(var.platform)
    kv_pwd_secret       = format("%s-%s-sap-password", local.secret_prefix, var.sap_sid)
    db_servers          = var.platform == "HANA" ? join(",", var.naming.virtualmachine_names.HANA_COMPUTERNAME) : join(",", var.naming.virtualmachine_names.ANYDB_COMPUTERNAME)
    scs_servers         = join(",", var.naming.virtualmachine_names.SCS_COMPUTERNAME)
    pas_server          = try(var.naming.virtualmachine_names.APP_COMPUTERNAME[0], "")
    application_servers = join(",", var.naming.virtualmachine_names.APP_COMPUTERNAME)
    webdisp_servers     = length(var.naming.virtualmachine_names.WEB_COMPUTERNAME) > 0 ? join(",", var.naming.virtualmachine_names.WEB_COMPUTERNAME) : ""
    }
  )
  filename             = format("%s/%s_inventory.md", path.cwd, var.sap_sid)
  file_permission      = "0660"
  directory_permission = "0770"
}
