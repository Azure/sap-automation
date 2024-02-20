terraform {
  required_providers {
    azurerm = {
      source                = "hashicorp/azurerm"
      configuration_aliases = [azurerm.main, azurerm.deployer, azurerm.dnsmanagement, azurerm.peering]
      version               = ">= 3.23"
    }
    
    azapi = {
      source                = "Azure/azapi"
      configuration_aliases = [azapi.api]
    }
  }
}
