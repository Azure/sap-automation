# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

# output "output_json" {
#   value = local_file.output_json
# }

# output "ansible_inventory" {
#   value = local_file.ansible_inventory
# }

# output "ansible_inventory_yml" {
#   value = local_file.ansible_inventory_yml
# }

###############################################################################
#                                                                             #
#                    Test-observable content outputs                           #
#                                                                             #
###############################################################################

output "hosts_file_content"            {
                                         description = "Raw content of the generated Ansible inventory hosts YAML file (for plan-time test assertions)"
                                         sensitive   = true
                                         value       = local_file.ansible_inventory_new_yml.content
                                       }

output "sap_parameters_content"        {
                                         description = "Raw content of the generated sap-parameters YAML file (for plan-time test assertions)"
                                         sensitive   = true
                                         value       = local_file.sap-parameters_yml.content
                                       }
