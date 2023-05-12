
resource "azapi_resource" "avg_HANA" {
  count = var.NFS_provider == "ANF" && var.hana_ANF_volumes.use_AVG_for_data ? 1 : 0
  type  = "Microsoft.NetApp/netAppAccounts/volumeGroups@2022-03-01"
  name = format("%s%s%s%s%d",
    var.naming.resource_prefixes.hana_avg,
    local.prefix,
    var.naming.separator,
    local.resource_suffixes.hana_avg, local.zones[count.index]
  )
  location  = local.ANF_pool_settings.location
  parent_id = local.ANF_pool_settings.account_id
  body = jsonencode({
    properties = {
      groupMetaData = {
        applicationIdentifier = local.sid
        applicationType       = "SAP-HANA"
        deploymentSpecId      = "20542149-bfca-5618-1879-9863dc6767f1"
        groupDescription      = "Foo"
      }
      volumes = [
        local.hana_data,
        local.hana_log,
        local.hana_shared
      ]
    }
  })
}

data "azurerm_netapp_pool" "workload_netapp_pool" {
  provider            = azurerm.main
  count               = var.NFS_provider == "ANF" && length(try(local.ANF_pool_settings.pool_name, "")) > 0 ? 1 : 1
  resource_group_name = data.azurerm_netapp_account.workload_netapp_account[0].resource_group_name
  name                = try(local.ANF_pool_settings.pool_name, "")
  account_name        = data.azurerm_netapp_account.workload_netapp_account[0].name

}

data "azurerm_netapp_account" "workload_netapp_account" {
  provider            = azurerm.main
  count               = var.NFS_provider == "ANF" && length(try(local.ANF_pool_settings.account_id, "")) > 0 ? 1 : 1
  name                = try(split("/", local.ANF_pool_settings.account_id)[8], "")
  resource_group_name = try(split("/", local.ANF_pool_settings.account_id)[4], "")
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
      creationToken = format("%s%s%s%s%d",
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
      kerberosEnabled = false
      networkFeatures = "Standard"
      protocolTypes = [
        "NFSv4.1"
      ]
      proximityPlacementGroup  = var.ppg[0].id
      securityStyle            = "string"
      serviceLevel             = "string"
      snapshotDirectoryVisible = true
      subnetId                 = try(local.ANF_pool_settings.subnet_id, "")
      throughputMibps          = var.hana_ANF_volumes.data_volume_throughput
      unixPermissions          = "string"
      usageThreshold           = var.hana_ANF_volumes.data_volume_size * 1024 * 1024 * 1024
      volumeSpecName           = "data"
    }
    tags = {}
  }

  hana_log = {
    name = format("%s%s%s%s%d",
      var.naming.resource_prefixes.hanadata,
      local.prefix,
      var.naming.separator,
      local.resource_suffixes.hanadata, 1
    )
    properties = {
      capacityPoolResourceId = data.azurerm_netapp_pool.workload_netapp_pool[0].id
      creationToken = format("%s%s%s%s%d",
        var.naming.resource_prefixes.hanalog,
        local.prefix,
        var.naming.separator,
        local.resource_suffixes.hanalog, 1
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
      kerberosEnabled = false
      networkFeatures = "Standard"
      protocolTypes = [
        "NFSv4.1"
      ]
      proximityPlacementGroup  = var.ppg[0].id
      securityStyle            = "string"
      serviceLevel             = "string"
      snapshotDirectoryVisible = true
      subnetId                 = try(local.ANF_pool_settings.subnet_id, "")
      throughputMibps          = var.hana_ANF_volumes.log_volume_throughput
      unixPermissions          = "string"
      usageThreshold           = var.hana_ANF_volumes.log_volume_size * 1024 * 1024 * 1024
      volumeSpecName           = "log"
    }
    tags = {}
  }

  hana_shared = {
    name = format("%s%s%s%s%d",
      var.naming.resource_prefixes.hanashared,
      local.prefix,
      var.naming.separator,
      local.resource_suffixes.hanashared, 1
    )
    properties = {
      capacityPoolResourceId = data.azurerm_netapp_pool.workload_netapp_pool[0].id
      creationToken = format("%s%s%s%s%d",
        var.naming.resource_prefixes.hanashared,
        local.prefix,
        var.naming.separator,
        local.resource_suffixes.hanashared, 1
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
      kerberosEnabled = false
      networkFeatures = "Standard"
      protocolTypes = [
        "NFSv4.1"
      ]
      proximityPlacementGroup  = var.ppg[0].id
      securityStyle            = "string"
      serviceLevel             = "string"
      snapshotDirectoryVisible = true
      subnetId                 = try(local.ANF_pool_settings.subnet_id, "")
      throughputMibps          = var.hana_ANF_volumes.shared_volume_throughput
      unixPermissions          = "string"
      usageThreshold           = var.hana_ANF_volumes.shared_volume_size * 1024 * 1024 * 1024
      volumeSpecName           = "shared"
    }
    tags = {}
  }

}
