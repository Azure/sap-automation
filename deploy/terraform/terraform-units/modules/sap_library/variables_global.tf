# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

variable "infrastructure"              {
                                         description = "Details of the Azure infrastructure to deploy the SAP library into"
                                         default     = {}

                                         validation {
                                                      condition = (
                                                        length(trimspace(try(var.infrastructure.region, ""))) != 0
                                                      )
                                                      error_message = "The region must be specified in the infrastructure.region field."
                                                    }

                                         validation {
                                                      condition = (
                                                        length(trimspace(try(var.infrastructure.environment, ""))) != 0
                                                      )
                                                      error_message = "The environment must be specified in the infrastructure.environment field."
                                                    }
                                       }

variable "storage_account_sapbits"     {}
variable "storage_account_tfstate"     {}
variable "dns_settings"                {
                                         description = "DNS details for the deployment"
                                         default     = {}
                                       }
variable "deployer"                    {
                                         description = "Details of deployer"
                                         default     = {}
                                       }
variable "key_vault"                   {
                                         description = "Import existing Azure Key Vaults"
                                         default     = {}

                                         validation {
                                                      condition = (
                                                        contains(keys(var.key_vault), "keyvault_id_for_deployment_credentials") ? (
                                                          length(split("/", var.key_vault.keyvault_id_for_deployment_credentials)) == 9 || length(var.key_vault.keyvault_id_for_deployment_credentials) == 0) : (
                                                          true
                                                        )
                                                      )
                                                      error_message = "If specified, the keyvault_id_for_deployment_credentials needs to be a correctly formed Azure resource ID."
                                                    }

                                         validation {
                                                      condition = (
                                                        contains(keys(var.key_vault), "kv_user_id") ? (
                                                          length(split("/", var.key_vault.kv_user_id)) == 9) || length(var.key_vault.kv_user_id) == 0 : (
                                                          true
                                                        )
                                                      )
                                                      error_message = "If specified, the kv_user_id needs to be a correctly formed Azure resource ID."
                                                    }

                                         validation {
                                                     condition = (
                                                       contains(keys(var.key_vault), "kv_prvt_id") ? (
                                                         length(split("/", var.key_vault.kv_prvt_id)) == 9) || length(var.key_vault.kv_prvt_id) == 0 : (
                                                         true
                                                       )
                                                     )
                                                     error_message = "If specified, the kv_prvt_id needs to be a correctly formed Azure resource ID."
                                                   }

                                       }

variable "naming"                     {
                                        description = "naming convention data structure"
                                      }

variable "deployer_tfstate"           {
                                        description = "terraform.tfstate of deployer"
                                        default     = {}
                                      }
variable "service_principal"          {
                                        description = "Current service principal used to authenticate to Azure"
                                      }

variable "use_private_endpoint"       {
                                        description = "Boolean value indicating if private endpoint should be used for the deployment"
                                        default     = false
                                        type        = bool
                                      }

variable "use_custom_dns_a_registration" {
                                           description = "Boolean value indicating if a custom dns a record should be created when using private endpoints"
                                           default     = false
                                           type        = bool
                                         }

variable "enable_purge_control_for_keyvaults" {
                                                description = "Allow the deployment to control the purge protection"
                                                type        = bool
                                                default     = true
                                              }

variable "use_webapp"                        {
                                               default = false
                                             }

variable "place_delete_lock_on_resources" {
                                            description = "If defined, a delete lock will be placed on the key resources"
                                          }

variable "Agent_IP"                       {
                                            description = "If provided, contains the IP address of the agent"
                                            type        = string
                                            default     = ""
                                          }

variable "bootstrap"                      {}


variable "short_named_endpoints_nics"     {
                                            description = "If defined, uses short names for private endpoints nics"
                                            default     = false
                                          }
