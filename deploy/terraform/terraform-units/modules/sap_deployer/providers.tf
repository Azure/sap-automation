terraform {
  required_providers {
    azurerm = {
      source                = "hashicorp/azurerm"
      configuration_aliases = [azurerm.dnsmanagement, azurerm.main]
      version               = "~> 3.0"
    }
  }
}
