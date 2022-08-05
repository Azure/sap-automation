/*
Description:

  Output from sap_deployer module.
*/

output "deployer_id" {
  sensitive = true
  value     = module.sap_deployer.deployer_id
}

output "vnet_mgmt_id" {
  value = module.sap_deployer.vnet_mgmt_id
}

output "subnet_mgmt_id" {
  value = module.sap_deployer.subnet_mgmt_id
}

output "subnet_webapp_id" {
  value = module.sap_deployer.subnet_webapp_id
}

output "deployer_uai" {
  sensitive = true
  value = {
    principal_id = module.sap_deployer.deployer_uai.principal_id
    tenant_id    = module.sap_deployer.deployer_uai.tenant_id
  }
}


output "deployer_kv_user_arm_id" {
  sensitive = true
  value     = module.sap_deployer.deployer_keyvault_user_arm_id
}

output "deployer_kv_user_name" {
  value = module.sap_deployer.user_vault_name
}

output "deployer_public_key_secret_name" {
  value = module.sap_deployer.pk_secret_name
}

output "deployer_private_key_secret_name" {
  value = module.sap_deployer.ppk_secret_name
}

output "deployer_username_secret_name" {
  value = module.sap_deployer.username_secret_name
}

output "deployer_password_secret_name" {
  value = module.sap_deployer.pwd_secret_name
}

output "deployer_rg_name" {
  value = module.sap_deployer.deployer_rg_name
}

output "deployer_public_ip_address" {
  value = module.sap_deployer.deployer_public_ip_address
}

output "firewall_ip" {
  value = module.sap_deployer.firewall_ip
}

output "firewall_id" {
  value = module.sap_deployer.firewall_id
}

output "automation_version" {
  value = local.version_label
}
