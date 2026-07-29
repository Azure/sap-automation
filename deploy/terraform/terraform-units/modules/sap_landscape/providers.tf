# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

terraform {
  required_providers {
    azurerm = {
      source                = "hashicorp/azurerm"
      version               = "4.80.0"
      configuration_aliases = [azurerm.main, azurerm.deployer, azurerm.dnsmanagement, azurerm.privatelinkdnsmanagement, azurerm.peering]
    }

    azapi = {
      source                = "azure/azapi"
      version               = "2.7.0"
      configuration_aliases = [azapi.api]
    }
  }
}
