terraform {
  required_providers {
    azurerm = {
      source                = "hashicorp/azurerm"
      configuration_aliases = [azurerm.main, azurerm.dnsmanagement]
      version               = "4.6.0"
    }
  }
}
