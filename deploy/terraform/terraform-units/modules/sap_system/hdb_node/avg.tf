
resource "azapi_resource" "avg_HANA" {
  count = var.hana_ANF_volumes.use_AVG_for_data ? local.db_zone_count : 0
  type  = "Microsoft.NetApp/netAppAccounts/volumeGroups@2022-03-01"
  name = format("%s%s%s%s%d",
    var.naming.resource_prefixes.hana_avg,
    local.prefix,
    var.naming.separator,
    local.resource_suffixes.hana_avg, local.zones[count.index]
  )
  location  = local.ANF_pool_settings.location
  parent_id = local.ANF_pool_settings.account_name
  body = jsonencode({
    properties = {
      groupMetaData = {
        applicationIdentifier = local.sid
        applicationType       = "SAP-HANA"
        deploymentSpecId      = uuid()
        groupDescription = "Foo"
      }
      volumes = [ local.hana_data
      ]
    }
  })
}

data "azurerm_netapp_pool" "workload_netapp_pool" {
  provider = azurerm.main
  count = var.ANF_settings.use ? (
    var.ANF_settings.use_existing_pool ? (
      1) : (
      0
    )) : (
    0
  )
  resource_group_name = split("/", var.ANF_settings.arm_id)[4]
  name = length(var.ANF_settings.pool_name) > 0 ? (
    var.ANF_settings.pool_name) : (
    format("%s%s%s%s",
      var.naming.resource_prefixes.netapp_pool,
      local.prefix,
      var.naming.separator,
      local.resource_suffixes.netapp_pool
    )
  )
  account_name = var.ANF_settings.use && length(var.ANF_settings.arm_id) > 0 ? (
    data.azurerm_netapp_account.workload_netapp_account[0].name) : (
    azurerm_netapp_account.workload_netapp_account[0].name
  )

}


locals {

  hana_data = {
    name = format("%s%s%s%s%d",
      var.naming.resource_prefixes.hanadata,
      local.prefix,
      var.naming.separator,
      local.resource_suffixes.hanadata, 1
    )
    properties = {
      capacityPoolResourceId = data.azurerm_netapp_pool.workload_netapp_pool[0].id
      creationToken          = format("%s%s%s%s%d",
        var.naming.resource_prefixes.hanadata,
        local.prefix,
        var.naming.separator,
        local.resource_suffixes.hanadata, 1
      )
      exportPolicy = {
        rules = [
          {
            allowedClients      = "0.0.0.0/0"
            chownMode           = "Restricted"
            cifs                = true
            hasRootAccess       = true
            kerberos5iReadWrite = false
            kerberos5pReadWrite = false
            kerberos5ReadWrite  = false
            nfsv3               = false
            nfsv41              = true
            ruleIndex           = 1
            unixReadWrite       = true
          }
        ]
      }
      kerberosEnabled                   = false
      networkFeatures                   = "Standard"
      protocolTypes = [
        "NFSv4.1"
      ]
      proximityPlacementGroup  = var.ppg[0].id
      securityStyle            = "string"
      serviceLevel             = "string"
      snapshotDirectoryVisible = true
      subnetId                 = try(local.ANF_pool_settings.subnet_id, "")
      throughputMibps          = var.hana_ANF_volumes.sapmnt_volume_throughput
      unixPermissions          = "string"
      usageThreshold           = var.hana_ANF_volumes.sapmnt_volume_size*1024*1024*1024
      volumeSpecName           = "data"
    }
    tags = {}
  }

}

