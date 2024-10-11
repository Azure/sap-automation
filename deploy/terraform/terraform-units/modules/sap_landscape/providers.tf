terraform {
  required_providers {
    azurerm = {
      source                = "hashicorp/azurerm"
      configuration_aliases = [azurerm.main, azurerm.deployer, azurerm.dnsmanagement, azurerm.peering, azurerm.privatelinkdnsmanagement]
      version               = "4.4.0"
    }

    azapi = {
      source                = "azure/azapi"
      configuration_aliases = [azapi.api]
    }
  }
}
