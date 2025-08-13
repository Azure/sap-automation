
resource "azurerm_dev_center" "deployer" {
  count                                         = var.infrastructure.dev_center_deployment ? 1 : 0
  name                                          = lower(format("%s%s%s%s",
                                                    var.naming.resource_prefixes.dev_center,
                                                    var.infrastructure.environment,
                                                    var.naming.resource_suffixes.dev_center,
                                                    coalesce(try(var.infrastructure.custom_random_id, ""), substr(random_id.deployer.hex, 0, 3)))
                                                  )
  resource_group_name                           = var.infrastructure.resource_group.exists ? data.azurerm_resource_group.deployer[0].name : azurerm_resource_group.deployer[0].name
  location                                      = var.infrastructure.resource_group.exists ? data.azurerm_resource_group.deployer[0].location : azurerm_resource_group.deployer[0].location

  identity                                {
                                            type         = var.deployer.add_system_assigned_identity ? "SystemAssigned, UserAssigned" : "UserAssigned"
                                            identity_ids = [length(var.deployer.user_assigned_identity_id) == 0 ? azurerm_user_assigned_identity.deployer[0].id : data.azurerm_user_assigned_identity.deployer[0].id ]
                                          }
}

resource "azurerm_dev_center_project" "deployer" {
  count                                         = var.infrastructure.dev_center_deployment ? 1 : 0
  name                                          = var.infrastructure.devops.agent_ado_project
  dev_center_id                                 = azurerm_dev_center.deployer[0].id
  resource_group_name                           = var.infrastructure.resource_group.exists ? data.azurerm_resource_group.deployer[0].name : azurerm_resource_group.deployer[0].name
  location                                      = var.infrastructure.resource_group.exists ? data.azurerm_resource_group.deployer[0].location : azurerm_resource_group.deployer[0].location

  identity                                {
                                            type         = var.deployer.add_system_assigned_identity ? "SystemAssigned, UserAssigned" : "UserAssigned"
                                            identity_ids = [length(var.deployer.user_assigned_identity_id) == 0 ? azurerm_user_assigned_identity.deployer[0].id : data.azurerm_user_assigned_identity.deployer[0].id ]
                                          }
}

resource "azurerm_dev_center_network_connection" "deployer" {
  count                                         = var.infrastructure.dev_center_deployment ? 1 : 0
  name                                          = var.infrastructure.virtual_network.management.subnet_agent.exists ? (
                                                    data.azurerm_subnet.subnet_agent[0].name) : (
                                                    azurerm_subnet.subnet_agent[0].name
                                                  )
  resource_group_name                           = var.infrastructure.resource_group.exists ? data.azurerm_resource_group.deployer[0].name : azurerm_resource_group.deployer[0].name
  location                                      = var.infrastructure.resource_group.exists ? data.azurerm_resource_group.deployer[0].location : azurerm_resource_group.deployer[0].location
  domain_join_type                              = "AzureADJoin"
  subnet_id                                     = var.infrastructure.virtual_network.management.subnet_agent.exists ? (
                                                    data.azurerm_subnet.subnet_agent[0].id) : (
                                                    azurerm_subnet.subnet_agent[0].id
                                                  )

}

resource "azurerm_dev_center_dev_box_definition" "deployer" {
  name                                          = "SDAF"
  count                                         = var.infrastructure.dev_center_deployment ? 1 : 0
  location                                      = var.infrastructure.resource_group.exists ? data.azurerm_resource_group.deployer[0].location : azurerm_resource_group.deployer[0].location
  dev_center_id                                 = azurerm_dev_center.deployer[0].id
  image_reference_id                            = "${azurerm_dev_center.deployer[0].id}/galleries/default/images/microsoftvisualstudio_visualstudioplustools_vs-2022-ent-general-win10-m365-gen2"
  sku_name                                      = "general_i_8c32gb256ssd_v2"
}

# resource "azurerm_dev_center_project_pool" "deployer" {
#   count                                         = var.infrastructure.dev_center_deployment ? 1 : 0
#   name                                          = var.infrastructure.devops.agent_pool
#   location                                      = var.infrastructure.resource_group.exists ? data.azurerm_resource_group.deployer[0].location : azurerm_resource_group.deployer[0].location
#   dev_center_project_id                         = azurerm_dev_center_project.deployer[0].id
#   dev_box_definition_name                       = azurerm_dev_center_dev_box_definition.deployer[0].name
#   local_administrator_enabled                   = true
#   dev_center_attached_network_name              = azurerm_dev_center_attached_network.deployer[0].name
#   stop_on_disconnect_grace_period_minutes       = 60
# }

resource "azapi_resource" "deployer" {
  count                                         = var.infrastructure.dev_center_deployment ? 1 : 0
  name                                          = var.infrastructure.devops.agent_pool
  location                                      = var.infrastructure.resource_group.exists ? data.azurerm_resource_group.deployer[0].location : azurerm_resource_group.deployer[0].location
  type                                          = "microsoft.devopsinfrastructure/pools@2025-01-21"
  identity                                {
                                            type         = "UserAssigned"
                                            identity_ids = [
                                                             length(var.deployer.user_assigned_identity_id) == 0 ? azurerm_user_assigned_identity.deployer[0].id : data.azurerm_user_assigned_identity.deployer[0].id
                                                           ]
                                          }
  parent_id                                     = var.infrastructure.resource_group.exists ? data.azurerm_resource_group.deployer[0].id : azurerm_resource_group.deployer[0].id

  schema_validation_enabled                     = false
  body = {
    properties = {
      organizationProfile = {
        organizations = [
          {
            projects    = [
              var.infrastructure.devops.agent_ado_project ]
            url         = var.infrastructure.devops.agent_ado_url
            parallelism = 3
            openAccess  = false
          }
        ]
        kind = "AzureDevOps" # Currently only AzureDevOps is supported
        permissionProfile = {
          kind = "Inherit"
        }
      }

      devCenterProjectResourceId = azurerm_dev_center_project.deployer[0].id

      maximumConcurrency = 2

      agentProfile = {
        kind = "Stateful"
        maxAgentLifetime = "4.00:00:00"
      }

      fabricProfile = {
        sku = {
          name = "Standard_D2ads_v5"
        }

        images = [
          {
            aliases            = ["ubuntu-24.04"]
            buffer             = "*"
            wellKnownImageName = "ubuntu-24.04/latest"
          }
        ]

        osProfile = {
          secretsManagementSettings = {
            observedCertificates = [],
            keyExportable        = false
          },
          logonType = "Service"
        },

        networkProfile = {
          subnetId = local.subnetId
        }

        storageProfile = {
          osDiskStorageAccountType = "Premium",
          dataDisks = [
          ]
        },

        kind = "Vmss"
      }
    }
  }
}

// Create/Import agent subnet
resource "azurerm_subnet" "subnet_agent" {
  count                                = var.infrastructure.dev_center_deployment && (!var.infrastructure.virtual_network.management.subnet_agent.exists) ? 1 : 0
  name                                 = local.agent_subnet_name
  resource_group_name                  = var.infrastructure.virtual_network.management.exists ? data.azurerm_virtual_network.vnet_mgmt[0].resource_group_name : azurerm_virtual_network.vnet_mgmt[0].resource_group_name
  virtual_network_name                 = var.infrastructure.virtual_network.management.exists ? data.azurerm_virtual_network.vnet_mgmt[0].name : azurerm_virtual_network.vnet_mgmt[0].name
  address_prefixes                     = [var.infrastructure.virtual_network.management.subnet_agent.prefix]

  private_endpoint_network_policies    = !var.use_private_endpoint ? "Enabled" : "Disabled"

  service_endpoints                    = var.use_service_endpoint ? (
                                           var.app_service.use ? (
                                             ["Microsoft.Storage", "Microsoft.KeyVault", "Microsoft.Web"]) : (
                                             ["Microsoft.Storage", "Microsoft.KeyVault"]
                                           )) : (
                                         null)

  dynamic "delegation" {
                        for_each = range(var.infrastructure.dev_center_deployment ? 1 : 0)
                        content {
                          name = "delegation"
                          service_delegation {
                            actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
                            name    = "Microsoft.DevOpsInfrastructure/pools"
                          }
                        }
                      }



}

data "azurerm_subnet" "subnet_agent" {
  count                                = (var.infrastructure.virtual_network.management.subnet_agent.exists) ? 1 : 0
  name                                 = split("/", var.infrastructure.virtual_network.management.subnet_agent.id)[10]
  resource_group_name                  = split("/", var.infrastructure.virtual_network.management.subnet_agent.id)[4]
  virtual_network_name                 = split("/", var.infrastructure.virtual_network.management.subnet_agent.id)[8]
}



locals {
  subnetId = var.infrastructure.dev_center_deployment ? var.infrastructure.virtual_network.management.subnet_agent.exists ? (
                                                    data.azurerm_subnet.subnet_agent[0].id) : (
                                                    azurerm_subnet.subnet_agent[0].id
                                                  ) : ""
}


