terraform {
  required_providers {
    azurerm = {
      source                = "hashicorp/azurerm"
      configuration_aliases = [azurerm.main, azurerm.deployer, azurerm.dnsmanagement, azurerm.peering]
      version               = ">= 3.23"
    }

    azureng = {
      source  = "hashicorp/azurerm"
      configuration_aliases = [azureng.ng]
      version = ">= 3.71.0"
    }

    azapi = {
      source                = "azure/azapi"
      configuration_aliases = [azapi.api]
    }
  }
}
