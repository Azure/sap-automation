
#######################################4#######################################8
#                                                                              #
#                                Resource Group                                #
#                                                                              #
#######################################4#######################################8

resource "azurerm_resource_group" "resource_group" {
  provider                             = azurerm.main
  count                                = local.resource_group_exists ? 0 : 1
  name                                 = local.resourcegroup_name
  location                             = var.infrastructure.region
  tags                                 = merge(var.infrastructure.tags, var.tags)

}

// Imports data of existing resource group
data "azurerm_resource_group" "resource_group" {
  provider                             = azurerm.main
  count                                = length(try(var.infrastructure.resource_group.arm_id, "")) > 0 ? 1 : 0
  name                                 = split("/", var.infrastructure.resource_group.arm_id)[4]
}

#######################################4#######################################8
#                                                                              #
#                                Resource Group                                #
#                                                                              #
#######################################4#######################################8
data "azurerm_virtual_network" "vnet_sap" {
  provider                             = azurerm.main
  name                                 = split("/", var.landscape_tfstate.vnet_sap_arm_id)[8]
  resource_group_name                  = split("/", var.landscape_tfstate.vnet_sap_arm_id)[4]
}


// Import boot diagnostics storage account from sap_landscape
data "azurerm_storage_account" "storage_bootdiag" {
  provider                             = azurerm.main
  name                                 = var.landscape_tfstate.storageaccount_name
  resource_group_name                  = var.landscape_tfstate.storageaccount_rg_name
}

// PROXIMITY PLACEMENT GROUP
resource "azurerm_proximity_placement_group" "ppg" {
  provider                             = azurerm.main
  count                                = (local.ppg_exists || var.use_scalesets_for_deployment || !local.create_ppg) ? (
                                           0) : ((
                                           local.zonal_deployment ? (
                                             max(length(local.zones), 1)) : (
                                             1)))
  name                                 = format("%s%s", local.prefix, var.naming.ppg_names[count.index])
  resource_group_name                  = local.resource_group_exists ? (
                                         data.azurerm_resource_group.resource_group[0].name) : (
                                         azurerm_resource_group.resource_group[0].name
                                       )
  location                             = local.resource_group_exists ? (
                                           data.azurerm_resource_group.resource_group[0].location) : (
                                           azurerm_resource_group.resource_group[0].location
                                         )
  tags                                 = var.tags

}

data "azurerm_proximity_placement_group" "ppg" {
  provider                             = azurerm.main
  count                                = local.ppg_exists ? max(length(local.zones), 1) : 0
  name                                 = split("/", local.ppg_arm_ids[count.index])[8]
  resource_group_name                  = split("/", local.ppg_arm_ids[count.index])[4]
}

resource "azurerm_proximity_placement_group" "app_ppg" {
  provider                             = azurerm.main
  count                                = var.infrastructure.use_app_proximityplacementgroups ? (
                                          (local.app_ppg_exists || var.use_scalesets_for_deployment ) ? (
                                             0) : ((
                                             local.zonal_deployment ? (
                                               max(length(local.zones), 1)) : (
                                               1)))) : (
                                          0
                                        )
  name                                 = format("%s%s", local.prefix, var.application_tier_ppg_names[count.index])
  resource_group_name                  = local.resource_group_exists ? (
                                         data.azurerm_resource_group.resource_group[0].name) : (
                                         azurerm_resource_group.resource_group[0].name
                                       )
  location                             = local.resource_group_exists ? (
                                           data.azurerm_resource_group.resource_group[0].location) : (
                                           azurerm_resource_group.resource_group[0].location
                                         )
  tags                                 = var.tags

}

data "azurerm_proximity_placement_group" "app_ppg" {
  provider                             = azurerm.main
  count                                = var.infrastructure.use_app_proximityplacementgroups ? (local.app_ppg_exists ? max(length(local.zones), 1) : 0) : 0
  name                                 = split("/", var.infrastructure.app_ppg.arm_ids[count.index])[8]
  resource_group_name                  = split("/", var.infrastructure.app_ppg.arm_ids[count.index])[4]
}

//ASG

resource "azurerm_application_security_group" "db" {
  provider                             = azurerm.main
  count                                = var.deploy_application_security_groups ? 1 : 0
  name                                 = format("%s%s%s%s",
                                           var.naming.resource_prefixes.db_asg,
                                           local.prefix,
                                           var.naming.separator,
                                           local.resource_suffixes.db_asg
                                         )
  resource_group_name                  = var.options.nsg_asg_with_vnet ? (
                                          data.azurerm_virtual_network.vnet_sap.resource_group_name) : (
                                          (local.resource_group_exists ? (
                                            data.azurerm_resource_group.resource_group[0].name) : (
                                            azurerm_resource_group.resource_group[0].name)
                                          )
                                        )

  location                             = var.options.nsg_asg_with_vnet ? (
                                         data.azurerm_virtual_network.vnet_sap.location) : (
                                         local.resource_group_exists ? (
                                           data.azurerm_resource_group.resource_group[0].location) : (
                                           azurerm_resource_group.resource_group[0].location
                                         )
                                       )

  tags                                = var.tags
}

// Define a cloud-init config that disables the automatic expansion
// of the root partition.
data "template_cloudinit_config" "config_growpart" {
  gzip                                 = true
  base64_encode                        = true

  # Main cloud-config configuration file.
  part {
    content_type = "text/cloud-config"
    content      = "growpart: {'mode': 'auto'}"
  }
}


resource "azurerm_orchestrated_virtual_machine_scale_set" "scale_set" {

  provider                             = azurerm.main
  count                                = var.use_scalesets_for_deployment && length(var.scaleset_id) == 0 ? 1 : 0

  name                                 = format("%s%s%s",
                                           var.naming.resource_prefixes.vmss,
                                           local.prefix,
                                           local.resource_suffixes.vmss
                                         )


  resource_group_name                  = local.resource_group_exists ? (
                                           data.azurerm_resource_group.resource_group[0].name) : (
                                           azurerm_resource_group.resource_group[0].name
                                        )

  location                             = local.resource_group_exists ? (
                                           data.azurerm_resource_group.resource_group[0].location) : (
                                           azurerm_resource_group.resource_group[0].location
                                        )

  platform_fault_domain_count          = 1

  zones                                = local.zones
  tags                                 = var.tags

  # proximity_placement_group_id         = length(local.zones) <= 1 ? (
  #                                           local.ppg_exists ? local.ppg_arm_ids[0] : azurerm_proximity_placement_group.ppg[0].id) :(
  #                                           null
  #                                         )
}

data "azurerm_orchestrated_virtual_machine_scale_set" "scale_set" {

  provider                             = azurerm.main
  count                                = var.use_scalesets_for_deployment && length(var.scaleset_id) > 0 ? 1 : 0

  name                                 = split("/", var.scaleset_id)[8]
  resource_group_name                  = split("/", var.scaleset_id)[4]
                                                                    }


