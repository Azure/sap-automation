// Imports data of existing AMS subnet
data "azurerm_subnet" "ams" {
  provider                             = azurerm.main
  count                                = length(local.ams_subnet_arm_id) > 0 ? 1 : 0
  name                                 = local.ams_subnet_name
  virtual_network_name                 = local.SAP_virtualnetwork_name
  resource_group_name                  = local.resourcegroup_name
}

resource "azapi_resource" "ams_instance" {
  type                                  = "Microsoft.Workloads/monitors@2023-04-01"
  count                                 = local.create_ams_instance && local.ams_subnet_defined ? 1 : 0
  name                                  = local.ams_instance_name
  location                              = local.region
  parent_id                             = azurerm_resource_group.resource_group[0].id
  depends_on                            = [
                                            azurerm_virtual_network.vnet_sap,
                                            azurerm_subnet.ams
                                          ]
  body                                  = jsonencode({
                                            properties = {
                                                            appLocation: local.region,
                                                            routingPreference: "RouteAll",
                                                            logAnalyticsWorkspaceArmId: local.ams_laws_arm_id,
                                                            managedResourceGroupConfiguration: {
                                                              name: "managedrg-ams"
                                                            },
                                                           monitorSubnet: length(local.ams_subnet_arm_id) > 0 ? local.ams_subnet_arm_id : azurerm_subnet.ams[0].id,
                                                          }
                                          })
}
