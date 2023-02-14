locals {

  location_short = upper(try(var.region_mapping[var.location], "unkn"))

  deployer_location_short = length(var.deployer_location) > 0 ? upper(try(var.region_mapping[var.deployer_location], "unkn")) : local.location_short

  // If no deployer environment provided use environment
  deployer_environment_temp = length(var.deployer_environment) > 0 ? var.deployer_environment : var.environment

  // If no landscape environment provided use environment
  landscape_environment_temp = length(var.landscape_environment) > 0 ? var.landscape_environment : var.environment

  // If no library environment provided use environment
  library_environment_temp = length(var.library_environment) > 0 ? var.library_environment : var.environment

  deployer_env_verified  = upper(substr(local.deployer_environment_temp, 0, var.sapautomation_name_limits.environment_variable_length))
  env_verified           = upper(substr(var.environment, 0, var.sapautomation_name_limits.environment_variable_length))
  landscape_env_verified = upper(substr(local.landscape_environment_temp, 0, var.sapautomation_name_limits.environment_variable_length))
  library_env_verified   = upper(substr(local.library_environment_temp, 0, var.sapautomation_name_limits.environment_variable_length))

  sap_vnet_verified = upper(trim(substr(replace(var.sap_vnet_name, "/[^A-Za-z0-9]/", ""), 0, var.sapautomation_name_limits.sap_vnet_length), "-_"))
  dep_vnet_verified = upper(trim(substr(replace(var.management_vnet_name, "/[^A-Za-z0-9]/", ""), 0, var.sapautomation_name_limits.sap_vnet_length), "-_"))

  random_id_verified    = upper(substr(var.random_id, 0, var.sapautomation_name_limits.random_id_length))
  random_id_vm_verified = lower(substr(var.random_id, 0, var.sapautomation_name_limits.random_id_length))
  random_id_virt_vm_verified = lower(substr(var.random_id, 0, var.sapautomation_name_limits.random_id_length -1))

  zones            = distinct(concat(var.db_zones, var.app_zones, var.scs_zones, var.web_zones))
  zonal_deployment = try(length(local.zones), 0) > 0 ? true : false

  //The separator to use between the prefix and resource name
  separator = "_"

}

