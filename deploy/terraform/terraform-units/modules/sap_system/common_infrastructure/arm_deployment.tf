
resource "azurerm_resource_group_template_deployment" "sap_system" {
  provider                             = azurerm.main
  name                                 = format("SDAF.sap.system.%s-%s-%s", var.application_tier.sid, var.database.platform,  local.deployment_type)
  resource_group_name                  = local.resource_group_exists ? (
                                           data.azurerm_resource_group.resource_group[0].name) : (
                                           azurerm_resource_group.resource_group[0].name
                                         )
  deployment_mode                      = "Incremental"

  template_content                     = jsonencode(
                                           {
                                             "$schema" : "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#",
                                             "contentVersion" : "1.0.0.0",
                                             "parameters" : {
                                               "Deployment" : {
                                                 "type" : "String",
                                                 "defaultValue" : "SAP System"
                                               }
                                             },
                                             "resources" : []
                                           }
                                         )

}
