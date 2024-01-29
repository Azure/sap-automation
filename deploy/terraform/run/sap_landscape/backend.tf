/*
Description:

  To use remote backend to deploy sap landscape
*/

terraform {
  backend "azurerm" {
    use_azuread_auth           = true
  }
}
