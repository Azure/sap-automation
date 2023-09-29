terraform {
  required_providers {
    azurerm = {
      source                = "hashicorp/azurerm"
      configuration_aliases = [azurerm.main, azurerm.deployer, azurerm.dnsmanagement]
      version               = ">= 3.54"
    }

    # azapi = {
    #   source                = "Azure/azapi"
    #   configuration_aliases = [azapi.api]
    # }
  }
}
