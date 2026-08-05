# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

terraform {
  required_providers {
    azurerm = {
      source                = "hashicorp/azurerm"
      version               = "4.80.0"
      configuration_aliases = [azurerm.privatelinkdnsmanagement, azurerm.dnsmanagement, azurerm.main]
    }

    azapi = {
      source                = "azure/azapi"
      version               = "2.7.0"
      configuration_aliases = [azapi.restapi]
    }

    azuread = {
      source                = "hashicorp/azuread"
      version               = "3.8.0"
      configuration_aliases = [azuread.main]
    }
  }
}
