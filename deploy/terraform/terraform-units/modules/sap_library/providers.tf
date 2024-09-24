terraform {
  required_providers {
    azurerm = {
      source                = "hashicorp/azurerm"
      configuration_aliases = [azurerm.main, azurerm.deployer, azurerm.dnsmanagement, azurerm.privatelinkdnsmanagement]
      version               = "~> 4.0"
    }
  }
}
