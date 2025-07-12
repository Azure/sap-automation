
resource "azurerm_resource_group_template_deployment" "sap_library" {
  provider = azurerm.main
  name     = "SDAF.core.sap_library"
  resource_group_name = var.infrastructure.resource_group.exists ? (
    data.azurerm_resource_group.library[0].name) : (
    azurerm_resource_group.library[0].name
  )
  deployment_mode = "Incremental"

  template_content = jsonencode(
    {
      "$schema" : "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#",
      "contentVersion" : "1.0.0.0",
      "parameters" : {
        "Deployment" : {
          "type" : "String",
          "defaultValue" : "SAP Deployer"
        }
      },
      "resources" : []
    }
  )

}

