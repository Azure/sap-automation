# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

terraform {
  required_providers {
    azurerm = {
      source                = "hashicorp/azurerm"
      configuration_aliases = [azurerm.privatelinkdnsmanagement, azurerm.dnsmanagement, azurerm.main]
    }

    azapi = {
      alias                 = "api"
      source                = "azure/azapi"
      configuration_aliases = [azapi.api]
    }

    azuread = {
      alias                 = "main"
      source                = "hashicorp/azuread"
      configuration_aliases = [azuread.main]
    }
  }
}
