
resource "azapi_resource" "avg_HANA" {
  count = var.NFS_provider == "ANF" && local.use_avg ? length(local.zones) : 0
  type  = "Microsoft.NetApp/netAppAccounts/volumeGroups@2022-03-01"
  name = format("%s%s%s%s%d",
    var.naming.resource_prefixes.hana_avg,
    local.prefix,
    var.naming.separator,
    local.resource_suffixes.hana_avg, count.index + 1
  )
  location  = local.ANF_pool_settings.location
  parent_id = local.ANF_pool_settings.account_id
  body = jsonencode({
    properties = {
      groupMetaData = {
        applicationIdentifier = local.sid
        applicationType       = "SAP-HANA"
        deploymentSpecId      = "20542149-bfca-5618-1879-9863dc6767f1"
        groupDescription      = format("Application Volume %d group for %s", count.index + 1, var.sap_sid)
      }
      volumes = [
        var.hana_ANF_volumes.use_for_data ? (count.index == 0 ? local.hana_data1 : local.hana_data2) : null,
        var.hana_ANF_volumes.use_for_log ? (count.index == 0 ? local.hana_log1 : local.hana_log2) : null,
        var.hana_ANF_volumes.use_for_shared ? (count.index == 0 ? local.hana_shared1 : local.hana_shared2) : null
      ]
    }
  })
}

data "azurerm_netapp_pool" "workload_netapp_pool" {
  provider            = azurerm.main
  count               = var.NFS_provider == "ANF" && length(local.ANF_pool_settings.pool_name) > 0 ? 1 : 0
  resource_group_name = data.azurerm_netapp_account.workload_netapp_account[0].resource_group_name
  name                = try(local.ANF_pool_settings.pool_name, "")
  account_name        = data.azurerm_netapp_account.workload_netapp_account[0].name

}

data "azurerm_netapp_account" "workload_netapp_account" {
  provider            = azurerm.main
  count               = var.NFS_provider == "ANF" && length(local.ANF_pool_settings.account_id) > 0 ? 1 : 0
  name                = try(split("/", local.ANF_pool_settings.account_id)[8], "")
  resource_group_name = try(split("/", local.ANF_pool_settings.account_id)[4], "")
}


locals {
  use_avg = (
    var.hana_ANF_volumes.use_AVG_for_data) && (
    var.hana_ANF_volumes.use_for_data || var.hana_ANF_volumes.use_for_log || var.hana_ANF_volumes.use_for_shared
  )
  hana_data1 = {
    name = format("%s%s%s%s%d",
      var.naming.resource_prefixes.hanadata,
      local.prefix,
      var.naming.separator,
      local.resource_suffixes.hanadata, 1
    )
    properties = {
      capacityPoolResourceId = try(data.azurerm_netapp_pool.workload_netapp_pool[0].id, "")
      creationToken = format("%s-%s%02d",
        var.sap_sid,
        local.resource_suffixes.hanadata,
        1
      )
      exportPolicy = {
        rules = [
          {
            allowedClients      = "0.0.0.0/0"
            chownMode           = "Restricted"
            cifs                = false
            hasRootAccess       = true
            kerberos5iReadWrite = false
            kerberos5iReadOnly  = false
            kerberos5pReadWrite = false
            kerberos5pReadOnly  = false
            kerberos5ReadWrite  = false
            kerberos5ReadOnly   = false
            nfsv3               = false
            nfsv41              = true
            ruleIndex           = 1
            unixReadWrite       = true
            unixReadOnly        = false
          }
        ]
      }
      kerberosEnabled = false
      networkFeatures = "Basic"
      protocolTypes = [
        "NFSv4.1"
      ]
      proximityPlacementGroup  = var.ppg[0].id
      serviceLevel             = local.ANF_pool_settings.service_level
      snapshotDirectoryVisible = true
      subnetId                 = try(local.ANF_pool_settings.subnet_id, "")
      throughputMibps          = var.hana_ANF_volumes.data_volume_throughput
      usageThreshold           = var.hana_ANF_volumes.data_volume_size * 1024 * 1024 * 1024
      volumeSpecName           = "data"
    }
    tags = {}
  }

  hana_data2 = {
    name = format("%s%s%s%s%d",
      var.naming.resource_prefixes.hanadata,
      local.prefix,
      var.naming.separator,
      local.resource_suffixes.hanadata, 2
    )
    properties = {
      capacityPoolResourceId = try(data.azurerm_netapp_pool.workload_netapp_pool[0].id, "")
      creationToken = format("%s-%s%02d",
        var.sap_sid,
        local.resource_suffixes.hanadata,
        1
      )
      exportPolicy = {
        rules = [
          {
            allowedClients      = "0.0.0.0/0"
            chownMode           = "Restricted"
            cifs                = false
            hasRootAccess       = true
            kerberos5iReadWrite = false
            kerberos5iReadOnly  = false
            kerberos5pReadWrite = false
            kerberos5pReadOnly  = false
            kerberos5ReadWrite  = false
            kerberos5ReadOnly   = false
            nfsv3               = false
            nfsv41              = true
            ruleIndex           = 1
            unixReadWrite       = true
            unixReadOnly        = false
          }
        ]
      }
      kerberosEnabled = false
      networkFeatures = "Basic"
      protocolTypes = [
        "NFSv4.1"
      ]
      proximityPlacementGroup  = var.ppg[1].id
      serviceLevel             = local.ANF_pool_settings.service_level
      snapshotDirectoryVisible = true
      subnetId                 = try(local.ANF_pool_settings.subnet_id, "")
      throughputMibps          = var.hana_ANF_volumes.data_volume_throughput
      usageThreshold           = var.hana_ANF_volumes.data_volume_size * 1024 * 1024 * 1024
      volumeSpecName           = "data"
    }
    tags = {}
  }

  hana_log1 = {
    name = format("%s%s%s%s%d",
      var.naming.resource_prefixes.hanalog,
      local.prefix,
      var.naming.separator,
      local.resource_suffixes.hanalog, 1
    )
    properties = {
      capacityPoolResourceId = try(data.azurerm_netapp_pool.workload_netapp_pool[0].id, "")
      creationToken = format("%s-%s%02d",
        var.sap_sid,
        local.resource_suffixes.hanalog,
        1
      )
      exportPolicy = {
        rules = [
          {
            allowedClients      = "0.0.0.0/0"
            chownMode           = "Restricted"
            cifs                = false
            hasRootAccess       = true
            kerberos5iReadWrite = false
            kerberos5iReadOnly  = false
            kerberos5pReadWrite = false
            kerberos5pReadOnly  = false
            kerberos5ReadWrite  = false
            kerberos5ReadOnly   = false
            nfsv3               = false
            nfsv41              = true
            ruleIndex           = 1
            unixReadWrite       = true
            unixReadOnly        = false
          }
        ]
      }
      kerberosEnabled = false
      networkFeatures = "Basic"
      protocolTypes = [
        "NFSv4.1"
      ]
      proximityPlacementGroup  = var.ppg[0].id
      serviceLevel             = local.ANF_pool_settings.service_level
      snapshotDirectoryVisible = true
      subnetId                 = try(local.ANF_pool_settings.subnet_id, "")
      throughputMibps          = var.hana_ANF_volumes.log_volume_throughput
      usageThreshold           = var.hana_ANF_volumes.log_volume_size * 1024 * 1024 * 1024
      volumeSpecName           = "log"
    }
    tags = {}
  }

  hana_log2 = {
    name = format("%s%s%s%s%d",
      var.naming.resource_prefixes.hanalog,
      local.prefix,
      var.naming.separator,
      local.resource_suffixes.hanalog, 2
    )
    properties = {
      capacityPoolResourceId = try(data.azurerm_netapp_pool.workload_netapp_pool[0].id, "")
      creationToken = format("%s-%s%02d",
        var.sap_sid,
        local.resource_suffixes.hanalog,
        1
      )
      exportPolicy = {
        rules = [
          {
            allowedClients      = "0.0.0.0/0"
            chownMode           = "Restricted"
            cifs                = false
            hasRootAccess       = true
            kerberos5iReadWrite = false
            kerberos5iReadOnly  = false
            kerberos5pReadWrite = false
            kerberos5pReadOnly  = false
            kerberos5ReadWrite  = false
            kerberos5ReadOnly   = false
            nfsv3               = false
            nfsv41              = true
            ruleIndex           = 1
            unixReadWrite       = true
            unixReadOnly        = false
          }
        ]
      }
      kerberosEnabled = false
      networkFeatures = "Basic"
      protocolTypes = [
        "NFSv4.1"
      ]
      proximityPlacementGroup  = var.ppg[1].id
      serviceLevel             = local.ANF_pool_settings.service_level
      snapshotDirectoryVisible = true
      subnetId                 = try(local.ANF_pool_settings.subnet_id, "")
      throughputMibps          = var.hana_ANF_volumes.log_volume_throughput
      usageThreshold           = var.hana_ANF_volumes.log_volume_size * 1024 * 1024 * 1024
      volumeSpecName           = "log"
    }
    tags = {}
  }

  hana_shared1 = {
    name = format("%s%s%s%s%d",
      var.naming.resource_prefixes.hanashared,
      local.prefix,
      var.naming.separator,
      local.resource_suffixes.hanashared, 1
    )
    properties = {
      capacityPoolResourceId = try(data.azurerm_netapp_pool.workload_netapp_pool[0].id, "")
      creationToken = format("%s-%s%02d",
        var.sap_sid,
        local.resource_suffixes.hanashared,
        1
      )
      exportPolicy = {
        rules = [
          {
            allowedClients      = "0.0.0.0/0"
            chownMode           = "Restricted"
            cifs                = false
            hasRootAccess       = true
            kerberos5iReadWrite = false
            kerberos5iReadOnly  = false
            kerberos5pReadWrite = false
            kerberos5pReadOnly  = false
            kerberos5ReadWrite  = false
            kerberos5ReadOnly   = false
            nfsv3               = false
            nfsv41              = true
            ruleIndex           = 1
            unixReadWrite       = true
            unixReadOnly        = false
          }
        ]
      }
      kerberosEnabled = false
      networkFeatures = "Basic"
      protocolTypes = [
        "NFSv4.1"
      ]
      proximityPlacementGroup  = var.ppg[0].id
      serviceLevel             = local.ANF_pool_settings.service_level
      snapshotDirectoryVisible = true
      subnetId                 = try(local.ANF_pool_settings.subnet_id, "")
      throughputMibps          = var.hana_ANF_volumes.log_volume_throughput
      usageThreshold           = var.hana_ANF_volumes.log_volume_size * 1024 * 1024 * 1024
      volumeSpecName           = "shared"
    }
    tags = {}
  }

  hana_shared2 = {
    name = format("%s%s%s%s%d",
      var.naming.resource_prefixes.hanashared,
      local.prefix,
      var.naming.separator,
      local.resource_suffixes.hanashared, 2
    )
    properties = {
      capacityPoolResourceId = try(data.azurerm_netapp_pool.workload_netapp_pool[0].id, "")
      creationToken = format("%s-%s%02d",
        var.sap_sid,
        local.resource_suffixes.hanashared,
        1
      )
      exportPolicy = {
        rules = [
          {
            allowedClients      = "0.0.0.0/0"
            chownMode           = "Restricted"
            cifs                = false
            hasRootAccess       = true
            kerberos5iReadWrite = false
            kerberos5iReadOnly  = false
            kerberos5pReadWrite = false
            kerberos5pReadOnly  = false
            kerberos5ReadWrite  = false
            kerberos5ReadOnly   = false
            nfsv3               = false
            nfsv41              = true
            ruleIndex           = 1
            unixReadWrite       = true
            unixReadOnly        = false
          }
        ]
      }
      kerberosEnabled = false
      networkFeatures = "Basic"
      protocolTypes = [
        "NFSv4.1"
      ]
      proximityPlacementGroup  = var.ppg[1].id
      serviceLevel             = local.ANF_pool_settings.service_level
      snapshotDirectoryVisible = true
      subnetId                 = try(local.ANF_pool_settings.subnet_id, "")
      throughputMibps          = var.hana_ANF_volumes.log_volume_throughput
      usageThreshold           = var.hana_ANF_volumes.log_volume_size * 1024 * 1024 * 1024
      volumeSpecName           = "hanashared"
    }
    tags = {}
  }

}
