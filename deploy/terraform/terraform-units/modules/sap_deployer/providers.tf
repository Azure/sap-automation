# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

terraform {
  required_providers {
    azurerm = {
      source                = "hashicorp/azurerm"
      configuration_aliases = [azurerm.privatelinkdnsmanagement, azurerm.dnsmanagement, azurerm.main]
    }
  }
}
