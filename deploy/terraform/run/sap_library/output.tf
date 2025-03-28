# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

#######################################4#######################################8
#                                                                              #
#                          Resource group definitions                          #
#                                                                              #
#######################################4#######################################8

output "created_resource_group_id"               {
                                                   description = "Created resource group ID"
                                                   value       = module.sap_library.created_resource_group_id
                                                 }

output "created_resource_group_name"             {
                                                   description = "Created resource group name"
                                                   value       = module.sap_library.created_resource_group_name
                                                 }

output "created_resource_group_subscription_id"  {
                                                   description = "Created resource group' subscription ID"
                                                   value       = module.sap_library.created_resource_group_subscription_id
                                                 }

output "random_id"                               {
                                                   description = "Random ID for library"
                                                   value       = substr(coalesce(var.custom_random_id, module.sap_library.random_id), 0, 3)
                                                 }

###############################################################################
#                                                                             #
#                             Storage accounts                                #
#                                                                             #
###############################################################################

output "sapbits_storage_account_name"           {
                                                   description = "Storage account name for SAP Binaries"
                                                   value       = module.sap_library.sapbits_storage_account_name
                                                 }

output "sapbits_sa_resource_group_name"          {
                                                   description = "Resource group name for SAP Binaries"
                                                   value       = module.sap_library.sapbits_sa_resource_group_name
                                                 }

output "saplibrary_subscription_id"              {
                                                   description = "Subscription Id for SAP Binaries"
                                                   sensitive   = true
                                                   value       = local.SAPLibrary_subscription_id
                                                 }

output "tfstate_resource_id"                     {
                                                   description = "Azure Resource identifier for Terraform remote state"
                                                   value       = module.sap_library.tfstate_resource_id
                                                 }

output "remote_state_storage_account_name"       {
                                                   description = "Storage account name for Terraform remote state"
                                                   value       = module.sap_library.remote_state_storage_account_name
                                                 }

output "saplibrary_environment"                  {
                                                   description = "Name of enfironment"
                                                   value       = local.infrastructure.environment
                                                 }

output "automation_version"                      {
                                                   description = "Version of automation"
                                                   value       = local.version_label
                                                 }

output "sa_connection_string"                    {
                                                   description = "Connection string to storage account"
                                                   sensitive   = true
                                                   value       = module.sap_library.sa_connection_string
                                                 }

