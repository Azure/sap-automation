# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

#######################################4#######################################8
#                                                                              #
#                            Local variables                                   #
#                                                                              #
#######################################4#######################################8
locals {
  version_label                        = trimspace(file("${path.module}/../../../configs/version.txt"))
  deployer_prefix                      = module.sap_namegenerator.naming.prefix.DEPLOYER

  use_spn                              = !var.use_deployer ? false : var.use_spn

  // If custom names are used for deployer, providing resource_group_name and msi_name will override the naming convention
  deployer_rg_name                     = coalesce(local.deployer.resource_group_name, format("%s-INFRASTRUCTURE", var.control_plane_name))


  custom_names                         = length(var.name_override_file) > 0 ? (
                                           jsondecode(file(format("%s/%s", path.cwd, var.name_override_file)))) : (
                                           null
                                         )

  }
