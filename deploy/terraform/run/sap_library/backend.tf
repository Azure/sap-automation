/*
  Description:
  To use remote backend to deploy sap library.
*/

terraform {
  backend "azurerm" {
    use_azuread_auth           = true
    use_msi                    = var.use_spn ? false : true
  }
}
