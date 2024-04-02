function Show-Menu($data) {
  Write-Host "================ $Title ================"
  $i = 1
  foreach ($d in $data) {
    Write-Host "($i): Select '$i' for $($d)"
    $i++
  }

  Write-Host "q: Select 'q' for Exit"

}


$rnd = $(Get-Random -Minimum 1 -Maximum 1000).ToString()

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


Add-Content -Path $LogFileName "# SDAF Assesment #"
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
  $VM_password = Read-Host "Please enter the Virtual Machine Password" -AsSecureString
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

  $VM_password = $ARM_CLIENT_SECRET

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


Add-Content -Path $LogFileName ""
$OutputString = "Microsoft.Compute Resource Provider Registration State"
Add-Content -Path $LogFileName $OutputString
Add-Content -Path $LogFileName $(az feature list --query "[?properties.state=='Registered'].{Name:name,State:properties.state}" --output table --namespace "Microsoft.Compute")
Write-Host "Microsoft.Compute Resource Provider Registration State" -ForegroundColor Green
az feature list --query "[?properties.state=='Registered'].{Name:name,State:properties.state}" --output table --namespace "Microsoft.Compute"

Write-Host
Add-Content -Path $LogFileName ""
$OutputString = "Microsoft.Storage Resource Provider Registration State"
Add-Content -Path $LogFileName $OutputString
Add-Content -Path $LogFileName $(az feature list --query "[?properties.state=='Registered'].{Name:name,State:properties.state}" --output table --namespace "Microsoft.Storage")
Write-Host "Microsoft.Storage Resource Provider Registration State" -ForegroundColor Green
az feature list --query "[?properties.state=='Registered'].{Name:name,State:properties.state}" --output table --namespace "Microsoft.Storage"

Write-Host
Add-Content -Path $LogFileName ""
$OutputString = "Microsoft.Network Resource Provider Registration State"
Add-Content -Path $LogFileName $OutputString
Add-Content -Path $LogFileName $(az feature list --query "[?properties.state=='Registered'].{Name:name,State:properties.state}" --output table --namespace "Microsoft.Network")
Write-Host "Microsoft.Storage Resource Provider Registration State" -ForegroundColor Green
az feature list --query "[?properties.state=='Registered'].{Name:name,State:properties.state}" --output table --namespace "Microsoft.Network"

Write-Host
Add-Content -Path $LogFileName ""
$OutputString = "Microsoft.Network Resource Provider Registration State"
Add-Content -Path $LogFileName $OutputString
Add-Content -Path $LogFileName $(az feature list --query "[?properties.state=='Registered'].{Name:name,State:properties.state}" --output table --namespace "Microsoft.NetApp")
Write-Host "Microsoft.NetApp Resource Provider Registration State" -ForegroundColor Green
az feature list --query "[?properties.state=='Registered'].{Name:name,State:properties.state}" --output table --namespace "Microsoft.NetApp"

Add-Content -Path $LogFileName ""


$Title = "Select the Location"
$Location = $Env:Location
if ($null -eq $Location -or $Location -eq "") {
  $locations = $(az account list-locations -o table --query "[?metadata.regionType=='Physical'].name" | Sort-Object)
  Show-Menu($locations[2..($locations.Length - 1)])
  $selection = Read-Host $Title

  $selectionOffset = [convert]::ToInt32($selection, 10) + 1
  $Location = $locations[$selectionOffset]
}

Add-Content -Path $LogFileName ""
$OutputString = "Resource group location: " + $Location
Add-Content -Path $LogFileName $OutputString


$resourceGroupName = $Env:ResourceGroupName
if ($null -eq $resourceGroupName -or $resourceGroupName -eq "") {
  $resourceGroupName = Read-Host "Please enter the Resource Group Name"
}

Write-Host "Creating Resource Group" -foregroundcolor Yellow
$OutputString = $(az group create --name $resourceGroupName --location $Location --query "properties.provisioningState")
Add-Content -Path $LogFileName $OutputString
Write-Host $OutputString
$resourceGroupId = $(az group show --name $resourceGroupName  --name $resourceGroupName --query id --output tsv)

Add-Content -Path $LogFileName ""
$OutputString = "Resource group name: " + $resourceGroupName
Add-Content -Path $LogFileName $OutputString

if ($authenticationMethod -ne "User Account") {
  Write-Host "Assigning the Service Principal the User Access Administrator role"
  az role assignment create --assignee $ARM_CLIENT_ID --role "User Access Administrator" --scope $resourceGroupId --query "properties.provisioningState"

  Write-Host "Checking if the Service Principal has the User Access Administrator role"
  $roleName = $(az role assignment list --assignee $ARM_CLIENT_ID --query "[?roleDefinitionName=='User Access Administrator'].roleDefinitionName" --output tsv)
  if ($null -eq $roleName -or $roleName -eq "") {
    Write-Host "The Service Principal does not have the User Access Administrator role" -ForegroundColor Red
    Write-Host "Please assign the User Access Administrator role to the Service Principal and re-run the script, alternatively configure the tfvars so that role assignmenta are not performed" -ForegroundColor Red

  }
}

$vmName="SDAF-VM"

$vnetName = "SDAF-VNet"
$anfSubnetName = "SDAF-anf"
$subnetName = "SDAF-Subnet"
$selection = Read-Host "Create Virtual network Y/N"
if ($selection.ToUpper() -eq "Y") {
  $OutputString = "Creating Virtual Network: " + $vnetName

  Write-Host $OutputString -foregroundcolor Yellow
  Add-Content -Path $LogFileName ""
  Add-Content -Path $LogFileName $OutputString

  $OutputString = $(az network vnet create --name $vnetName --resource-group $resourceGroupName --location $Location --address-prefix "10.112.0.0/16" --subnet-name $subnetName --subnet-prefix "10.112.0.0/19" --query "provisioningState")
  Write-Host $OutputString
  Add-Content -Path $LogFileName $OutputString

  $OutputString = "Creating Subnet: " + $subnetName
  Write-Host $OutputString -foregroundcolor Yellow
  Add-Content -Path $LogFileName $OutputString
  $OutputString = $(az network vnet subnet create --resource-group $resourceGroupName --vnet-name $vnetName --name $anfSubnetName --address-prefixes "10.112.64.0/27" --delegations "Microsoft.NetApp/volumes" --query "provisioningState")
  Write-Host $OutputString
  Add-Content -Path $LogFileName $OutputString
}
else {
  $vnetName = Read-Host "Please enter the Virtual Network Name"
  $subnetName = Read-Host "Please enter the Subnet Name"
  $anfSubnetName = Read-Host "Please enter the ANF Subnet Name"

  $OutputString = "Using Virtual Network: " + $vnetName

  Add-Content -Path $LogFileName ""
  Add-Content -Path $LogFileName $OutputString

  $OutputString = "Using Subnet: " + $subnetName

  Add-Content -Path $LogFileName ""
  Add-Content -Path $LogFileName $OutputString

  $OutputString = "Using ANF Subnet: " + $anfSubnetName

  Add-Content -Path $LogFileName ""
  Add-Content -Path $LogFileName $OutputString
}


$storageAccountName = "sdaftest$rnd"
$shareName = "sdaftestshare"

$selection = Read-Host "Create storage account Y/N"
if ($selection.ToUpper() -eq "Y") {
  $OutputString = "Creating Storage Account: " + $storageAccountName
  Write-Host $OutputString -foregroundcolor Yellow
  Add-Content -Path $LogFileName $OutputString
  $OutputString = $(az storage account create --name $storageAccountName --resource-group $resourceGroupName --location $Location  --kind FileStorage --sku Premium_LRS  --allow-blob-public-access false --https-only=false --query "provisioningState")
  Write-Host $OutputString
  Add-Content -Path $LogFileName $OutputString

  $storageID = $(az storage account show --resource-group $resourceGroupName --name  $storageAccountName --query "id" -o tsv)
  $OutputString = "Creating Private Endpoint for the Storage Account: " + $storageAccountName
  Write-Host $OutputString -foregroundcolor Yellow
  Add-Content -Path $LogFileName $OutputString

  $OutputString = $(az network private-endpoint create  --connection-name SDAF-connection-1   --name SDAF-private-endpoint   --private-connection-resource-id $storageID  --resource-group $resourceGroupName --subnet $subnetName  --vnet-name $vnetName --group-ids file --query "provisioningState")
  Write-Host $OutputString
  Add-Content -Path $LogFileName $OutputString

}

$selection = Read-Host "Create file share Y/N"
if ($selection.ToUpper() -eq "Y") {
  $OutputString = "Creating File share: " + $shareName
  Write-Host $OutputString -foregroundcolor Yellow
  Add-Content -Path $LogFileName $OutputString
  az storage share-rm create  --resource-group $resourceGroupName --storage-account $storageAccountName --name $shareName --enabled-protocols NFS --access-tier "Premium"  --quota 128  --output none
}

$kvName = "sdaftestKV$rnd"

$selection = Read-Host "Create key vault Y/N"
if ($selection.ToUpper() -eq "Y") {
  $OutputString = "Creating Key vault: " + $kvName
  Write-Host $OutputString -foregroundcolor Yellow
  Add-Content -Path $LogFileName $OutputString
  az vault create --name $kvName --resource-group $resourceGroupName --location $Location --query "provisioningState" --enable-purge-protection false --retention-days 7

  az vault secret set --vault-name $kvName --name "sdaftestsecret" --value "sdaftestsecretvalue" --query "id"
}
$vmssName = "SDAF-VmssFlex"

$OutputString = "Creating flexible scale set: " + $vmssName
Write-Host $OutputString -foregroundcolor Yellow
Add-Content -Path $LogFileName $OutputString

Write-Host "" -foregroundcolor Yellow
# Create flexible scale set for deployment of SAP workload across availability zones with platform fault domain count set to 1
$OutputString = $(az vmss create --name $vmssName --resource-group $resourceGroupName --location $Location --orchestration-mode flexible --zones 1 2 3 --platform-fault-domain-count 1  --query "provisioningState")
Write-Host $OutputString
Add-Content -Path $LogFileName $OutputString

$vmssid = $(az vmss show --name $vmssName --resource-group $resourceGroupName --query id)

$selection = Read-Host "Create Virtual Machine Y/N"
if ($selection.ToUpper() -eq "Y") {
  $Title = "Select the Publisher"
  $data = @('SUSE', 'RedHat', 'Oracle', 'Windows')

  Show-Menu($data)
  $selection = Read-Host $Title
  $publisher = $data[$selection - 1]
  Add-Content -Path $LogFileName ""
  Add-Content -Path $LogFileName "## Virtual Machine ##"
  Add-Content -Path $LogFileName ""
  if ($publisher -eq "Quit") {
    return
  }

  $configPath = join-path -path (resolve-path ..) -ChildPath configs

  $AllDistros = Get-Content -Raw -Path (Join-Path -Path $configPath -ChildPath "sdaf_distros.json") | ConvertFrom-Json

  $SKUS = Get-Content -Raw -Path ..\configs\sdaf_skus.json | ConvertFrom-Json

  #$distros = $(az vm image list --location $Location --query "[].urn" --publisher $publisher --all --offer "sap" --output table | Sort-Object)
  if ($publisher -eq "SUSE") {
    $distros = $AllDistros.SUSE.DistroIds
  }
  if ($publisher -eq "RedHat") {
    $distros = $AllDistros.REDHAT.DistroIds
  }
  if ($publisher -eq "Oracle") {
    $distros = $AllDistros.ORACLE.DistroIds
  }
  if ($publisher -eq "Windows") {
    $distros = $AllDistros.WINDOWS.DistroIds
  }

  $Title = "Select the Distro"

  Show-Menu($distros)
  $selection = Read-Host "Please choose the Distro"
  $distro = $distros[$selection - 1]

  Add-Content -Path $LogFileName ""

  $OutputString = "Distro: " + $distro
  Write-Host $OutputString -foregroundcolor Yellow
  Add-Content -Path $LogFileName $OutputString
  $skus = $SKUS.vm_sku

  $Title = "Select the SKU"

  Show-Menu($skus)
  $selection = Read-Host $Title

  $vmSKU = $skus[$selection - 1]

  Add-Content -Path $LogFileName ""

  $OutputString = "Virtual Machine SKU: " + $vmSKU
  Write-Host $OutputString -foregroundcolor Yellow
  Add-Content -Path $LogFileName $OutputString


  Write-Host $$

  Write-Host "Checking if the region supports PremiumV2 disks"
  $zone = $(az vm list-skus --resource-type disks --query "[?name=='PremiumV2_LRS'].locationInfo[0].zones | [0] | [0]" --location $Location)
  $vmStatus = ""

  if ($null -eq $zone -or $zone -eq "") {
    Write-Host "Creating a Virtual Machine" -foregroundcolor Yellow
    $vmStatus = $(az vm create --resource-group $resourceGroupName --name $vmName --image $distro --admin-username "azureadm" --admin-password $ARM_CLIENT_SECRET --size $vmSKU --vnet-name $vnetName --subnet $subnetName  --vmss $vmssid --no-wait --query "provisioningState")
  }
  else {
    $diskName = "SDAFdisk"
    $logicalSectorSize = 4096

    Write-Host "Creating a Premium SSD v2 disk" -foregroundcolor Yellow
    az disk create -n $diskName -g $resourceGroupName --size-gb 100 --disk-iops-read-write 5000 --disk-mbps-read-write 150 --location $Location --zone $zone --sku PremiumV2_LRS --logical-sector-size $logicalSectorSize --query "provisioningState"
    Write-Host "Creating a Virtual Machine" -foregroundcolor Yellow
    $vmStatus = $(az vm create --resource-group $resourceGroupName --name $vmName --image $distro --admin-username "azureadm" --admin-password $VM_password --size $vmSKU --vnet-name $vnetName --subnet $subnetName  --vmss $vmssid  --zone $zone --attach-data-disks $diskName  --query "provisioningState")

  }

  Write-Host $vmStatus
  $vmStatus = "Succeeded"

  if ($vmStatus -eq "Succeeded") {

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

  }

}

$selection = Read-Host "Create Azure NetApp account Y/N"
if ($selection.ToUpper() -eq "Y") {
  $anfAccountName = "sdafanfaccount$rnd"
  $OutputString = "Creating NetApp Account: " + $anfAccountName
  Write-Host $OutputString -ForegroundColor Yellow
  Add-Content -Path $LogFileName $OutputString

  $OutputString = $(az netappfiles account create --resource-group $resourceGroupName --name $anfAccountName --location $Location --query "provisioningState")
  Write-Host $OutputString
  Add-Content -Path $LogFileName $OutputString

  $poolName = "sdafpool"
  $poolSize_TiB = 2
  $serviceLevel = "Premium" # Valid values are Standard, Premium and Ultra

  $OutputString = "Creating NetApp Capacity Pool: " + $poolName
  Write-Host $OutputString -ForegroundColor Yellow
  Add-Content -Path $LogFileName $OutputString

  $OutputString = $(az netappfiles pool create --resource-group $resourceGroupName --location $Location --account-name $anfAccountName --pool-name $poolName --size $poolSize_TiB --service-level $serviceLevel  --query "provisioningState")
  Write-Host $OutputString
  Add-Content -Path $LogFileName $OutputString

  $vnetID = $(az network vnet show --resource-group $resourceGroupName --name $vnetName --query "id" -o tsv)
  $subnetID = $(az network vnet subnet show --resource-group $resourceGroupName --vnet-name $vnetName --name $anfSubnetName --query "id" -o tsv)
  $volumeSize_GiB = 100
  $uniqueFilePath = "myfilepath2" # Please note that creation token needs to be unique within subscription and region

  $OutputString = "Creating NetApp Volume: " + "myvol1"
  Write-Host $OutputString -ForegroundColor Yellow
  Add-Content -Path $LogFileName $OutputString

  $OutputString = $(az netappfiles volume create --resource-group $resourceGroupName --location $Location  --account-name $anfAccountName --pool-name $poolName --name "myvol1" --service-level $serviceLevel --vnet $vnetID --subnet $subnetID --usage-threshold $volumeSize_GiB --file-path $uniqueFilePath --protocol-types "NFSv3"  --query "provisioningState")
  Write-Host $OutputString
  Add-Content -Path $LogFileName $OutputString

}


$selection = Read-Host "Delete resource group Y/N?"
if ($selection.ToUpper() -eq "Y") {
  az group delete --name $resourceGroupName --yes
}
