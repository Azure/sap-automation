/*
Description:

  Constraining provider versions
    =    (or no operator): exact version equality
    !=   version not equal
    >    greater than version number
    >=   greater than or equal to version number
    <    less than version number
    <=   less than or equal to version number
    ~>   pessimistic constraint operator, constraining both the oldest and newest version allowed.
           For example, ~> 0.9   is equivalent to >= 0.9,   < 1.0
                        ~> 0.8.4 is equivalent to >= 0.8.4, < 0.9
*/

data "azurerm_client_config" "current" {
  provider = azurerm.deployer
}

provider "azurerm" {
  features {
  }
  subscription_id = var.use_deployer ? local.spn.subscription_id : null
  client_id       = var.use_deployer ? local.spn.client_id : null
  client_secret   = var.use_deployer ? local.spn.client_secret : null
  tenant_id       = var.use_deployer ? local.spn.tenant_id : null
}

provider "azurerm" {
  features {
  }
  alias = "deployer"
}

provider "azurerm" {
  features {}
  alias                      = "dnsmanagement"
  subscription_id            = try(var.management_dns_subscription_id, null)
  skip_provider_registration = true
}

provider "azuread" {
  client_id     = local.spn.client_id
  client_secret = local.spn.client_secret
  tenant_id     = local.spn.tenant_id
}

terraform {
  required_version = ">= 1.0"
  required_providers {
    external = {
      source = "hashicorp/external"
    }
    local = {
      source = "hashicorp/local"
    }
    random = {
      source = "hashicorp/random"
    }
    null = {
      source = "hashicorp/null"
    }
    azuread = {
      source = "hashicorp/azuread"
      version = "~> 2.2"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.3"
    }
  }
}
