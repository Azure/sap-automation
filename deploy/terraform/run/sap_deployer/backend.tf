/*
Description:

  To use remote backend to deploy deployer(s).
*/
terraform {
  backend "azurerm" {
    use_azuread_auth     =  !var.shared_access_key_enabled
  }
}
