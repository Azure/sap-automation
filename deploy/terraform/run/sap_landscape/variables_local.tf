variable "api-version" {
  description = "IMDS API Version"
  default     = "2019-04-30"
}

variable "auto-deploy-version" {
  description = "Version for automated deployment"
  default     = "v2"
}

variable "scenario" {
  description = "Deployment Scenario"
  default     = "HANA Database"
}

variable "tfstate_resource_id" {
  description = "Resource id of tfstate storage account"
  validation {
    condition = (
      length(split("/", var.tfstate_resource_id)) == 9
    )
    error_message = "The Azure Resource ID for the storage account containing the Terraform state files must be provided and be in correct format."
  }

}

variable "deployer_tfstate_key" {
  description = "The key of deployer's remote tfstate file"
  default     = ""

}

variable "azure_files_transport_storage_account_id" {
  type    = string
  default = ""
}
variable "NFS_provider" {
  type    = string
  default = "NONE"
}

variable "azure_files_storage_account_id" {
  type    = string
  default = ""
}

variable "azurerm_private_endpoint_connection_transport_id" {
  description = "Azure Resource Identifier for an private endpoint connection"
  type        = string
  default     = ""
}

locals {

  version_label = trimspace(file("${path.module}/../../../configs/version.txt"))

  // The environment of sap landscape and sap system
  environment = upper(local.infrastructure.environment)

  vnet_logical_name = local.infrastructure.vnets.sap.logical_name


  // Locate the tfstate storage account
  saplib_subscription_id       = split("/", var.tfstate_resource_id)[2]
  saplib_resource_group_name   = split("/", var.tfstate_resource_id)[4]
  tfstate_storage_account_name = split("/", var.tfstate_resource_id)[8]
  tfstate_container_name       = module.sap_namegenerator.naming.resource_suffixes.tfstate

  // Retrieve the arm_id of deployer's Key Vault from deployer's terraform.tfstate
  spn_key_vault_arm_id = try(local.key_vault.kv_spn_id,
    try(data.terraform_remote_state.deployer[0].outputs.deployer_kv_user_arm_id,
    "")
  )

  deployer_subscription_id = length(local.spn_key_vault_arm_id) > 0 ? (
    split("/", local.spn_key_vault_arm_id)[2]) : (
    ""
  )


  spn = {
    subscription_id = data.azurerm_key_vault_secret.subscription_id.value,
    client_id       = var.use_spn ? data.azurerm_key_vault_secret.client_id[0].value : null,
    client_secret   = var.use_spn ? data.azurerm_key_vault_secret.client_secret[0].value : null,
    tenant_id       = var.use_spn ? data.azurerm_key_vault_secret.tenant_id[0].value : null
  }

  service_principal = {
    subscription_id = local.spn.subscription_id,
    tenant_id       = local.spn.tenant_id,
    object_id       = var.use_spn ? try(data.azuread_service_principal.sp[0].id, null) : null
  }

  account = {
    subscription_id = data.azurerm_key_vault_secret.subscription_id.value,
    tenant_id       = data.azurerm_client_config.current.tenant_id,
    object_id       = data.azurerm_client_config.current.object_id
  }

  ANF_settings = {
    use           = var.NFS_provider == "ANF"
    name          = var.ANF_account_name
    pool_name     = var.ANF_pool_name
    arm_id        = var.ANF_account_arm_id
    service_level = var.ANF_service_level
    size_in_tb    = var.ANF_pool_size

  }

  custom_names = length(var.name_override_file) > 0 ? (
    jsondecode(file(format("%s/%s", path.cwd, var.name_override_file)))
    ) : (
    null
  )

}
