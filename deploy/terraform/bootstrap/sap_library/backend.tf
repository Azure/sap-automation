# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

/*
    Description:
    To use local to deploy sap library(s).
    Specify the path of saplibrary.terraform.tfstate.
*/
terraform {
  backend "local" {

  }
}
