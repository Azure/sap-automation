terraform {
  required_providers {
    azurerm = {
      source                = "hashicorp/azurerm"
      configuration_aliases = [azurerm.main, azurerm.deployer, azure.dnsmanagement]
      version               = "~> 3.0"
    }
  }
}
