# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

#######################################4#######################################8
#                                                                              #
#                              Variable definitioms                            #
#                                                                              #
#######################################4#######################################8

variable "deployers"                   {
                                         description = "Details of the list of deployer(s)"
                                         default     = [{}]
                                       }

variable "infrastructure"              {
                                         description = "Details of the Azure infrastructure to deploy the deployer into"
                                         default     = {}

                                         validation {
                                                     condition = (
                                                       contains(keys(var.infrastructure), "region") ? (
                                                         length(trimspace(var.infrastructure.region)) != 0) : (
                                                         true
                                                       )
                                                     )
                                                     error_message = "The region must be specified in the infrastructure.region field."
                                                   }

                                         validation {
                                                      condition = (
                                                        contains(keys(var.infrastructure), "environment") ? (
                                                          length(trimspace(var.infrastructure.environment)) != 0) : (
                                                          true
                                                        )
                                                      )
                                                      error_message = "The environment must be specified in the infrastructure.environment field."
                                                    }

                                         validation {
                                                      condition = (
                                                        contains(keys(var.infrastructure), "vnets") ? (
                                                          length(trimspace(try(var.infrastructure.vnets.management.arm_id, ""))) != 0 || length(trimspace(try(var.infrastructure.vnets.management.address_space, ""))) != 0) : (
                                                          true
                                                        )
                                                      )
                                                      error_message = "Either the arm_id or address_space of the VNet must be specified in the infrastructure.vnets.management block."
                                                    }

                                         validation {
                                                      condition = (
                                                        contains(keys(var.infrastructure), "vnets") ? (
                                                          length(trimspace(try(var.infrastructure.vnets.management.subnet_mgmt.arm_id, ""))) != 0 || length(trimspace(try(var.infrastructure.vnets.management.subnet_mgmt.prefix, ""))) != 0) : (
                                                          true
                                                        )
                                                      )
                                                      error_message = "Either the arm_id or prefix of the subnet must be specified in the infrastructure.vnets.management.subnet_management block."
                                                    }

                                       }

variable "options"                     {
                                         description = "Configuration options"
                                         default     = {}
                                       }

variable "ssh-timeout"                 {
                                         description = "Timeout for connection that is used by provisioner"
                                         default     = "30s"
                                       }

variable "authentication"              {
                                         description = "Authentication details"
                                         default = {
                                                     username            = "azureadm",
                                                     path_to_public_key  = "",
                                                     path_to_private_key = ""
                                                   }

                                         validation {
                                           condition = (
                                             length(var.authentication) >= 1
                                           )
                                           error_message = "Either ssh keys or user credentials must be specified."
                                         }
                                         validation {
                                           condition = (
                                             length(trimspace(var.authentication.username)) != 0
                                           )
                                           error_message = "The default username for the Virtual machines must be specified."
                                         }
                                       }

variable "key_vault"                   {
                                         description = "Import existing Azure Key Vaults"
                                         default     = {}
                                         validation {
                                                      condition = (
                                                        contains(keys(var.key_vault), "keyvault_id_for_deployment_credentials") ? (
                                                          length(split("/", var.key_vault.keyvault_id_for_deployment_credentials)) == 9) : (
                                                          true
                                                        )
                                                      )
                                                      error_message = "If specified, the keyvault_id_for_deployment_credentials needs to be a correctly formed Azure resource ID."
                                                    }
                                       }
variable "assign_subscription_permissions" {
                                             description = "Assign permissions on the subscription"
                                             default     = true
                                           }


variable "terraform_template_version"      {
                                             description = "The version of Terraform templates that were identified in the state file"
                                             default     = ""
                                           }

variable "arm_client_id"                   {
                                             description = "The client ID of the service principal used to authenticate to Azure"
                                             default = ""
                                           }
