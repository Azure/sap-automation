# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

#######################################4#######################################8
#                                                                              #
#                            Local variables                                   #
#                                                                              #
#######################################4#######################################8

locals {
  version_label                        = trimspace(file("${path.module}/../../../configs/version.txt"))
  ansible_version_label                = trimspace(file("${path.module}/../../../configs/ansible_version.txt"))

  // Management vnet
  vnet_mgmt_arm_id                     = try(local.infrastructure.virtual_network.management.arm_id, "")
  vnet_mgmt_exists                     = length(local.vnet_mgmt_arm_id) > 0

  //There is no default as the name is mandatory unless arm_id is specified
  vnet_mgmt_name                      = local.vnet_mgmt_exists ? (
                                          split("/", local.vnet_mgmt_arm_id)[8]) : (
                                          length(local.infrastructure.virtual_network.management.name) > 0 ? (
                                            local.infrastructure.virtual_network.management.name) : (
                                            "DEP00"
                                          )
                                        )

  // Default naming of vnet has multiple parts. Taking the second-last part as the name incase the name ends with -vnet
  vnet_mgmt_parts                      = length(split("-", local.vnet_mgmt_name))
  vnet_mgmt_name_part                  = substr(upper(local.vnet_mgmt_name), -5, 5) == "-VNET" ? (
                                           split("-", local.vnet_mgmt_name)[(local.vnet_mgmt_parts - 2)]) : (
                                           local.vnet_mgmt_name
                                         )
  custom_names                         = length(var.name_override_file) > 0 ? (
                                           jsondecode(file(format("%s/%s", path.cwd, var.name_override_file)))) : (
                                           null
                                         )

}
