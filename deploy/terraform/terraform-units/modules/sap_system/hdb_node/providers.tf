terraform {
  required_providers {
    azurerm = {
      source                = "hashicorp/azurerm"
      configuration_aliases = [azurerm.main, azurerm.deployer, azurerm.dnsmanagement, azurerm.privatelinkdnsmanagement]
      version               = "4.7.0"
    }

    # azapi = {
    #   source                = "Azure/azapi"
    #   configuration_aliases = [azapi.api]
    # }
  }
}
