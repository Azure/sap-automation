# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

terraform {
  required_providers {
    azurerm = {
      source                = "hashicorp/azurerm"
      configuration_aliases = [azurerm.privatelinkdnsmanagement, azurerm.dnsmanagement, azurerm.main]
    }

    azapi = {
      source                = "azure/azapi"
      configuration_aliases = [azapi.restapi]
    }

    azuread = {
      source                = "hashicorp/azuread"
      configuration_aliases = [azuread.main]
    }
  }
}
