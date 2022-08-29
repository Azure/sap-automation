terraform {
  required_providers {
    azurerm = {
      source                = "hashicorp/azurerm"
      configuration_aliases = [azurerm.dnsmanagement]
      version               = "~> 3.0"
    }
  }
}
