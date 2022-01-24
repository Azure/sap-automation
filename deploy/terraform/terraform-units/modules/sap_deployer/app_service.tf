
# Create the Linux App Service Plan
resource "azurerm_app_service_plan" "appserviceplan" {
    name                = lower(format("%s%s%s", local.prefix, local.resource_suffixes.app_service_plan, substr(random_id.deployer.hex, 0, 3)))
    resource_group_name = local.rg_name
    location            = local.rg_appservice_location
    kind = "Linux"
    reserved = true

    sku {
        tier = "Standard"
        size = "S1"
    }
}


# Create the web app, pass in the App Service Plan ID, and deploy code from a public GitHub repo
resource "azurerm_app_service" "webapp" {
    count               = var.configure ? 1 : 0
    name                = lower(format("%s%s%s", local.prefix, local.resource_suffixes.webapp_url, substr(random_id.deployer.hex, 0, 3)))
    resource_group_name = local.rg_name
    location            = local.rg_appservice_location
    app_service_plan_id = azurerm_app_service_plan.appserviceplan.id
    
    site_config {
        linux_fx_version = "DOTNETCORE|3.1"
    }

    # source_control {
    #     repo_url = "https://azurecat-sapdeploy@dev.azure.com/azurecat-sapdeploy/sap_deployment_automation/_git/persius"
    #     branch = "main"
    # }

    auth_settings {
        enabled = true
        issuer = "https://sts.windows.net/${data.azurerm_client_config.deployer.tenant_id}/v2.0"
        active_directory {
            client_id = var.app_registration_app_id
            client_secret = var.webapp_client_secret
        }
    }

    connection_string {
        name  = "CMDB"
        type  = "Custom"
        value = var.cmdb_connection_string
    }
}
