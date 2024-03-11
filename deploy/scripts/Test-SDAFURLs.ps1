function Show-Menu($data) {
  Write-Host "================ $Title ================"
  $i = 1
  foreach ($d in $data) {
    Write-Host "($i): Select '$i' for $($d)"
    $i++
  }

  Write-Host "q: Select 'q' for Exit"

}


$LogFileDir = $Env:LogFileDir
if ($null -eq $LogFileDir -or $LogFileDir -eq "") {

  $LogFileDir = Read-Host "Please enter the directory to save the log file"
}

if (Test-Path $LogFileDir) {
  $LogFileName = "SDAF-" + $(Get-Date -Format "yyyyMMdd-HHmm") + ".md"
  $LogFileName = Join-Path $LogFileDir -ChildPath $LogFileName
}
else {
  Write-Host "The directory does not exist"
  return
}

Add-Content -Path $LogFileName "# SDAF URL Assesment #"
Add-Content -Path $LogFileName ""
$OutputString = "Time of assessment: " + $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
Add-Content -Path $LogFileName $OutputString
$authenticationMethod = 'Service Principal (recommended)'
$Title = "Select the authentication method to use"
$data = @('Service Principal (recommended)', 'User Account')
Show-Menu($data)
$selection = Read-Host $Title
$authenticationMethod = $data[$selection - 1]

Add-Content -Path $LogFileName ""
$OutputString = "Authentication model: " + $authenticationMethod
Add-Content -Path $LogFileName $OutputString


if ($authenticationMethod -eq "User Account") {
  az logout
  az login --output none
}
else {
  $ARM_CLIENT_ID = $Env:ARM_CLIENT_ID
  $ARM_CLIENT_SECRET = $Env:ARM_CLIENT_SECRET
  $ARM_TENANT_ID = $Env:ARM_TENANT_ID

  if ($null -eq $ARM_CLIENT_ID -or $ARM_CLIENT_ID -eq "") {
    $ARM_CLIENT_ID = Read-Host "Please enter the Service Principal's Application ID"
  }

  if ($null -eq $ARM_CLIENT_SECRET -or $ARM_CLIENT_SECRET -eq "") {
    $ARM_CLIENT_SECRET = Read-Host "Please enter the Service Principals App ID Password" -AsSecureString
  }

  if ($null -eq $ARM_TENANT_ID -or $ARM_TENANT_ID -eq "") {
    $ARM_TENANT_ID = Read-Host "Please enter the Tenant ID"
  }

  if ($null -eq $ARM_SUBSCRIPTION_ID -or $ARM_SUBSCRIPTION_ID -eq "") {
    $ARM_SUBSCRIPTION_ID = Read-Host "Please enter the Subscription ID"
  }
  az logout
  az login --service-principal -u $ARM_CLIENT_ID -p $ARM_CLIENT_SECRET --tenant $ARM_TENANT_ID --output none
}

$ARM_SUBSCRIPTION_ID = $Env:ARM_SUBSCRIPTION_ID
if ($null -eq $ARM_SUBSCRIPTION_ID -or $ARM_SUBSCRIPTION_ID -eq "") {
  $ARM_SUBSCRIPTION_ID = Read-Host "Please enter the Subscription ID"
}

az account set --subscription $ARM_SUBSCRIPTION_ID

Add-Content -Path $LogFileName ""
$OutputString = "Subscription: " + $ARM_SUBSCRIPTION_ID
Add-Content -Path $LogFileName $OutputString


$resourceGroupName = $Env:ResourceGroupName
if ($null -eq $resourceGroupName -or $resourceGroupName -eq "") {
  $resourceGroupName = Read-Host "Please enter the Resource Group Name"
}

$vmName = $Env:VMName
if ($null -eq $vmName -or $vmName -eq "") {
  $vmName = Read-Host "Please enter the Virtual Machine Name"
}

$UrlsToCheck = Get-Content -Raw -Path ..\configs\sdaf_urls.json | ConvertFrom-Json

Add-Content -Path $LogFileName ""
Add-Content -Path $LogFileName "## Check URLS ##"
Add-Content -Path $LogFileName ""

Write-Host "Checking Deployer URLs" -ForegroundColor Yellow
Add-Content -Path $LogFileName "Checking Deployer URLs"

foreach ($url in $UrlsToCheck.deployer.urls) {
  Write-Host "Checking if $url is accessible from the Virtual Machine"
  $result = $(az vm run-command invoke --resource-group $resourceGroupName  --name $vmName  --command-id RunShellScript  --scripts "wget -O /tmp/foo.zip $url" --query value[0].message)
  if ($result.Contains("200 OK")) {
    $OutputString = "$url is accessible"
    Write-Host $OutputString -ForegroundColor Green
    Add-Content -Path $LogFileName $OutputString
  }
  elseif ($result.Contains("403 Forbidden")) {
    $OutputString = "$url is accessible"
    Write-Host $OutputString -ForegroundColor Green
    Add-Content -Path $LogFileName $OutputString
  }
  else {
    $OutputString = "$url is not accessible"
    Write-Host $OutputString -ForegroundColor Red
    Add-Content -Path $LogFileName $OutputString
  }
}

Write-Host "Checking Deployer IPs" -ForegroundColor Yellow
Add-Content -Path $LogFileName "Checking Deployer IPs"
Add-Content -Path $LogFileName ""

foreach ($IP in $UrlsToCheck.deployer.IPs) {
  Write-Host "Checking if $IP is accessible from the Virtual Machine"
  $result = $(az vm run-command invoke --resource-group $resourceGroupName  --name $vmName  --command-id RunShellScript  --scripts "nc -zv $IP 443" --query value[0].message)
  if ($result.Contains("succeeded!")) {
    $OutputString = "$IP is accessible"
    Write-Host $OutputString -ForegroundColor Green
    Add-Content -Path $LogFileName $OutputString
    Add-Content -Path $LogFileName ""
  }
  elseif ($result.Contains("Connected")) {
    $OutputString = "$IP is accessible"
    Write-Host $OutputString -ForegroundColor Green
    Add-Content -Path $LogFileName $OutputString
    Add-Content -Path $LogFileName ""
  }
  else {
    $OutputString = "$IP is not accessible"
    Write-Host $OutputString -ForegroundColor Red
    Add-Content -Path $LogFileName $OutputString
    Add-Content -Path $LogFileName ""
  }
}


Write-Host "Checking Windows URLs" -ForegroundColor Yellow
Add-Content -Path $LogFileName "Checking Windows URLs"
Add-Content -Path $LogFileName ""

foreach ($url in $UrlsToCheck.windows.urls) {
  Write-Host "Checking if $url is accessible from the Virtual Machine"
  $result = $(az vm run-command invoke --resource-group $resourceGroupName  --name $vmName  --command-id RunShellScript  --scripts "wget -O /tmp/foo.zip $url" --query value[0].message)
  if ($result.Contains("200 OK")) {
    $OutputString = "$url is accessible"
    Write-Host $OutputString -ForegroundColor Green
    Add-Content -Path $LogFileName $OutputString
  }
  elseif ($result.Contains("403 Forbidden")) {
    $OutputString = "$url is accessible"
    Write-Host $OutputString -ForegroundColor Green
    Add-Content -Path $LogFileName $OutputString
  }
  else {
    $OutputString = "$url is not accessible"
    Write-Host $OutputString -ForegroundColor Red
    Add-Content -Path $LogFileName $OutputString
  }
}

Write-Host "Checking Windows IPs" -ForegroundColor Yellow
Add-Content -Path $LogFileName "Checking Windows IPs"
Add-Content -Path $LogFileName ""

foreach ($IP in $UrlsToCheck.windows.IPs) {
  Write-Host "Checking if $IP is accessible from the Virtual Machine"
  $result = $(az vm run-command invoke --resource-group $resourceGroupName  --name $vmName  --command-id RunShellScript  --scripts "nc -zv $IP 443" --query value[0].message)
  if ($result.Contains("succeeded!")) {
    $OutputString = "$IP is accessible"
    Write-Host $OutputString -ForegroundColor Green
    Add-Content -Path $LogFileName $OutputString
  }
  elseif ($result.Contains("Connected")) {
    $OutputString = "$IP is accessible"
    Write-Host $OutputString -ForegroundColor Green
    Add-Content -Path $LogFileName $OutputString
  }
  else {
    $OutputString = "$IP is not accessible"
    Write-Host $OutputString -ForegroundColor Red
    Add-Content -Path $LogFileName $OutputString
  }
}


Write-Host "Checking 'runtime' URLs" -ForegroundColor Yellow
Add-Content -Path $LogFileName "Checking 'runtime' URLs"

foreach ($url in $UrlsToCheck.sap.urls) {
  Write-Host "Checking if $url is accessible from the Virtual Machine"
  $result = $(az vm run-command invoke --resource-group $resourceGroupName  --name $vmName  --command-id RunShellScript  --scripts "wget -O /tmp/foo.zip $url" --query value[0].message)
  if ($result.Contains("200 OK")) {
    $OutputString = "$url is accessible"
    Write-Host $OutputString -ForegroundColor Green
    Add-Content -Path $LogFileName $OutputString
  }
  elseif ($result.Contains("403 Forbidden")) {
    $OutputString = "$url is accessible"
    Write-Host $OutputString -ForegroundColor Green
    Add-Content -Path $LogFileName $OutputString
  }
  else {
    $OutputString = "$url is not accessible"
    Write-Host $OutputString -ForegroundColor Red
    Add-Content -Path $LogFileName $OutputString
  }
}

Write-Host "Checking 'runtime' IPs" -ForegroundColor Yellow
Add-Content -Path $LogFileName "Checking 'runtime' IPs"

foreach ($IP in $UrlsToCheck.sap.IPs) {
  Write-Host "Checking if $IP is accessible from the Virtual Machine"
  $result = $(az vm run-command invoke --resource-group $resourceGroupName  --name $vmName  --command-id RunShellScript  --scripts "nc -zv $IP 443" --query value[0].message)
  if ($result.Contains("succeeded!")) {
    $OutputString = "$IP is accessible"
    Write-Host $OutputString -ForegroundColor Green
    Add-Content -Path $LogFileName $OutputString
  }
  elseif ($result.Contains("Connected")) {
    $OutputString = "$IP is accessible"
    Write-Host $OutputString -ForegroundColor Green
    Add-Content -Path $LogFileName $OutputString
  }
  else {
    $OutputString = "$IP is not accessible"
    Write-Host $OutputString -ForegroundColor Red
    Add-Content -Path $LogFileName $OutputString
  }
}

