// Creates the resource group
resource "azurerm_resource_group" "resource_group" {
  provider = azurerm.main
  count    = local.resource_group_exists ? 0 : 1
  name     = local.rg_name
  location = var.infrastructure.region
  tags     = var.infrastructure.tags

  lifecycle {
    ignore_changes = [
      tags
    ]
  }

}

// Imports data of existing resource group
data "azurerm_resource_group" "resource_group" {
  provider = azurerm.main
  count    = length(try(var.infrastructure.resource_group.arm_id, "")) > 0 ? 1 : 0
  name     = split("/", var.infrastructure.resource_group.arm_id)[4]
}

// Imports data of Landscape SAP VNET
data "azurerm_virtual_network" "vnet_sap" {
  provider            = azurerm.main
  name                = split("/", var.landscape_tfstate.vnet_sap_arm_id)[8]
  resource_group_name = split("/", var.landscape_tfstate.vnet_sap_arm_id)[4]
}

#########################################################################################
#                                                                                       #
#  Admin Subnet variables                                                               #
#                                                                                       #
#########################################################################################

resource "azurerm_subnet" "admin" {
  provider             = azurerm.main
  count                = !local.admin_subnet_exists && local.enable_admin_subnet ? 1 : 0
  name                 = local.admin_subnet_name
  resource_group_name  = data.azurerm_virtual_network.vnet_sap.resource_group_name
  virtual_network_name = data.azurerm_virtual_network.vnet_sap.name
  address_prefixes     = [local.admin_subnet_prefix]
}

resource "azurerm_subnet_route_table_association" "admin" {
  provider = azurerm.main
  count = local.admin_subnet_defined && !local.admin_subnet_exists && local.enable_admin_subnet && length(var.landscape_tfstate.route_table_id) > 0 ? (
    1) : (
    0
  )
  subnet_id      = azurerm_subnet.admin[0].id
  route_table_id = var.landscape_tfstate.route_table_id
}


// Imports data of existing SAP admin subnet
data "azurerm_subnet" "admin" {
  provider             = azurerm.main
  count                = local.admin_subnet_exists && local.enable_admin_subnet ? 1 : 0
  name                 = split("/", local.admin_subnet_arm_id)[10]
  resource_group_name  = split("/", local.admin_subnet_arm_id)[4]
  virtual_network_name = split("/", local.admin_subnet_arm_id)[8]
}


#########################################################################################
#                                                                                       #
#  DB Subnet variables                                                               #
#                                                                                       #
#########################################################################################

resource "azurerm_subnet" "db" {
  provider             = azurerm.main
  count                = local.enable_db_deployment ? (local.database_subnet_exists ? 0 : 1) : 0
  name                 = local.database_subnet_name
  resource_group_name  = data.azurerm_virtual_network.vnet_sap.resource_group_name
  virtual_network_name = data.azurerm_virtual_network.vnet_sap.name
  address_prefixes     = [local.database_subnet_prefix]
}

// Imports data of existing db subnet
data "azurerm_subnet" "db" {
  provider             = azurerm.main
  count                = local.enable_db_deployment ? (local.database_subnet_exists ? 1 : 0) : 0
  name                 = split("/", local.database_subnet_arm_id)[10]
  resource_group_name  = split("/", local.database_subnet_arm_id)[4]
  virtual_network_name = split("/", local.database_subnet_arm_id)[8]
}


resource "azurerm_subnet_route_table_association" "db" {
  provider = azurerm.main
  count = (
    local.database_subnet_defined && !local.database_subnet_exists && length(var.landscape_tfstate.route_table_id) > 0
    ) ? (
    1) : (
    0
  )
  subnet_id      = azurerm_subnet.db[0].id
  route_table_id = var.landscape_tfstate.route_table_id
}


#########################################################################################
#                                                                                       #
#  Scaleout Subnet variables                                                            #
#                                                                                       #
#########################################################################################

resource "azurerm_subnet" "storage" {
  provider = azurerm.main
  count = local.enable_db_deployment && local.enable_storage_subnet ? (
    local.sub_storage_exists ? 0 : 1) : (
    0
  )
  name                 = local.sub_storage_name
  resource_group_name  = data.azurerm_virtual_network.vnet_sap.resource_group_name
  virtual_network_name = data.azurerm_virtual_network.vnet_sap.name
  address_prefixes     = [local.sub_storage_prefix]
}

// Imports data of existing db subnet
data "azurerm_subnet" "storage" {
  provider = azurerm.main
  count = local.enable_db_deployment && local.enable_storage_subnet ? (
    local.sub_storage_exists ? 1 : 0) : (
    0
  )
  name                 = split("/", local.sub_storage_arm_id)[10]
  resource_group_name  = split("/", local.sub_storage_arm_id)[4]
  virtual_network_name = split("/", local.sub_storage_arm_id)[8]
}

// Import boot diagnostics storage account from sap_landscape
data "azurerm_storage_account" "storage_bootdiag" {
  provider            = azurerm.main
  name                = var.landscape_tfstate.storageaccount_name
  resource_group_name = var.landscape_tfstate.storageaccount_rg_name
}

// PROXIMITY PLACEMENT GROUP
resource "azurerm_proximity_placement_group" "ppg" {
  provider = azurerm.main
  count    = local.ppg_exists ? 0 : (local.zonal_deployment ? max(length(local.zones), 1) : 1)
  name     = format("%s%s", local.prefix, var.naming.ppg_names[count.index])
  resource_group_name = local.resource_group_exists ? (
    data.azurerm_resource_group.resource_group[0].name) : (
    azurerm_resource_group.resource_group[0].name
  )
  location = local.resource_group_exists ? (
    data.azurerm_resource_group.resource_group[0].location) : (
    azurerm_resource_group.resource_group[0].location
  )

  lifecycle {
    ignore_changes = [tags]
  }
}

data "azurerm_proximity_placement_group" "ppg" {
  provider            = azurerm.main
  count               = local.ppg_exists ? max(length(local.zones), 1) : 0
  name                = split("/", local.ppg_arm_ids[count.index])[8]
  resource_group_name = split("/", local.ppg_arm_ids[count.index])[4]
}


//ASG

resource "azurerm_application_security_group" "db" {
  provider = azurerm.main
  count    = var.deploy_application_security_groups ? 1 : 0
  name = format("%s%s%s%s",
    var.naming.resource_prefixes.db_asg,
    local.prefix,
    var.naming.separator,
    local.resource_suffixes.db_asg
  )
  resource_group_name = var.options.nsg_asg_with_vnet ? (
    data.azurerm_virtual_network.vnet_sap.resource_group_name) : (
    (local.resource_group_exists ? (
      data.azurerm_resource_group.resource_group[0].name) : (
      azurerm_resource_group.resource_group[0].name)
    )
  )

  location = var.options.nsg_asg_with_vnet ? (
    data.azurerm_virtual_network.vnet_sap.location) : (
    local.resource_group_exists ? (
      data.azurerm_resource_group.resource_group[0].location) : (
      azurerm_resource_group.resource_group[0].location
    )
  )

  lifecycle {
    ignore_changes = [tags]
  }
}

// Define a cloud-init config that disables the automatic expansion
// of the root partition.
data "template_cloudinit_config" "config_growpart" {
  gzip          = true
  base64_encode = true

  # Main cloud-config configuration file.
  part {
    content_type = "text/cloud-config"
    content      = "growpart: {'mode': 'auto'}"
  }
}

