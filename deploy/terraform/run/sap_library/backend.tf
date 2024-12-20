# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

/*
  Description:
  To use remote backend to deploy sap library.
*/

terraform {
  backend "azurerm" {
    use_azuread_auth     = true # Use Azure AD authentication
  }
}
