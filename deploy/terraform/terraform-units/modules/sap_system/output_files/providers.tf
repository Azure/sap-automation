# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

terraform {
  required_providers {
    azurerm = {
      source                = "hashicorp/azurerm"
      version               = "4.80.0"
      configuration_aliases = [azurerm.main, azurerm.dnsmanagement, azurerm.deployer]
    }
  }
}
