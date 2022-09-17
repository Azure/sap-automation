$Organization=$Env:ADO_ORGANIZATION

$Project=$Env:ADO_PROJECT
$YourPrefix=$Env:YourPrefix

$MgmtPrefix=$YourPrefix + "-SDAF-MGMT"
$DEVPrefix=$YourPrefix + "-SDAF-DEV"
$Name=$MgmtPrefix+"-configuration-app"
$ControlPlaneSubscriptionID=$Env:ControlPlaneSubscriptionID
$DevSubscriptionID=$Env:DevSubscriptionID

$url=( az devops project list --organization $Organization --query "value | [0].url")
$idx=$url.IndexOf("_api")
$pat_url=$url.Substring(0,$idx)+"_usersSettings/tokens"

Write-Host "The browser will now open, please create a Personal Access Token. Ensure that Read & manage is selected for Agent Pools, Read & write is selected for Code, Read & execute is selected for Build, and Read, create, & manage is selected for Variable Groups"

Start-Process $pat_url.Replace("""","")

$PAT=Read-Host -Prompt "Enter your PAT" -AsSecureString

$pat_url=$url.Substring(0,$idx)+"_settings/agentpools"

Write-Host "The browser will now open, please an Agent Pool with the name 'MGMT-POOL'. Ensure that the Agent Pool is define using the Self-hosted pool type."

Start-Process $pat_url.Replace("""","")



$GroupID=(az pipelines variable-group list  --project $Project --query "[?name=='SDAF-MGMT'].id | [0]")

Add-Content -Path manifest.json -Value '[{"resourceAppId":"00000003-0000-0000-c000-000000000000","resourceAccess":[{"id":"e1fe6dd8-ba31-4d61-89e7-88639da4683d","type":"Scope"}]}]'
$APP_REGISTRATION_ID=(az ad app create --display-name $Name --enable-id-token-issuance true --sign-in-audience AzureADMyOrg --required-resource-access .\manifest.json --query "appId").Replace('"',"")

az pipelines variable-group variable update --group-id $GroupID --project $Project --name "APP_REGISTRATION_APP_ID" --value $APP_REGISTRATION_ID
$passw=(az ad app credential reset --id $APP_REGISTRATION_ID --append --query "password")
az pipelines variable-group variable update --group-id $GroupID --project $Project --name "WEB_APP_CLIENT_SECRET" --value $passw --secret true

az pipelines variable-group variable update --group-id $GroupID --project $Project --name "ARM_SUBSCRIPTION_ID" --value $ControlPlaneSubscriptionID

del manifest.json

$app_name= $MgmtPrefix+" Deployment credential"
$scopes="/subscriptions/"+$ControlPlaneSubscriptionID
$Data=(az ad sp create-for-rbac --role="Contributor" --scopes=$scopes --name=$app_name) | ConvertFrom-Json

az pipelines variable-group variable update --group-id $GroupID --project $Project --name "ARM_CLIENT_ID" --value $Data.appId
az pipelines variable-group variable update --group-id $GroupID --project $Project --name "ARM_TENANT_ID" --value $Data.tenant
az pipelines variable-group variable update --group-id $GroupID --project $Project --name "ARM_CLIENT_SECRET" --value $Data.password --secret true
az pipelines variable-group variable update --group-id $GroupID --project $Project --name "PAT" --value $PAT --secret true

$DevGroupID=(az pipelines variable-group list  --project $Project --query "[?name=='SDAF-DEV'].id | [0]")
$dev_scopes="/subscriptions/"+$DevSubscriptionID
$dev_app_name= $DevPrefix+" Deployment credential"

$Data=(az ad sp create-for-rbac --role="Contributor" --scopes=$dev_scopes --name=$dev_app_name) | ConvertFrom-Json

az pipelines variable-group variable update --group-id $DevGroupID --project $Project --name "ARM_SUBSCRIPTION_ID" --value $DevSubscriptionID
az pipelines variable-group variable update --group-id $DevGroupID --project $Project --name "ARM_CLIENT_ID" --value $Data.appId
az pipelines variable-group variable update --group-id $DevGroupID --project $Project --name "ARM_TENANT_ID" --value $Data.tenant
az pipelines variable-group variable update --group-id $DevGroupID --project $Project --name "ARM_CLIENT_SECRET" --value $Data.password --secret true
az pipelines variable-group variable update --group-id $DevGroupID --project $Project --name "PAT" --value $PAT --secret true

