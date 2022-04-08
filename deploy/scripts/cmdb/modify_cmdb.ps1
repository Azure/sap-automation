# Script to perform CRUD operations on the cosmos DB via powershell

[CmdletBinding()]
Param(
    [Parameter(Mandatory=$true)][string] $ConnStr,          # cmdb connection string
    [Parameter(Mandatory=$true)][string] $Collection,       # which collection to modify or read from
    [Parameter(Mandatory=$true)][string] $Id,               # id of the object to read, create, or modify
    [Parameter(Mandatory=$true)][string] $Crud,             # one of [ create, read, update, delete ]
    [Parameter(Mandatory=$false)][string] $Updates="{}"     # set of key value pairs to update or include in creation
)

# Convert variables to javascript
New-Item -Path $PSScriptRoot -Name "dbvars.js" -ItemType "file" -Value "var connStr = '$ConnStr'; `r`nvar collection = '$Collection'; `r`nvar id = '$Id'; `r`nvar crud = '$Crud'; `r`nvar updates = $Updates;"

# Modify or read the database
if ($Crud -eq "read") {
    mongosh --quiet --nodb -f $PSScriptRoot\dbvars.js -f $PSScriptRoot\modifyCmdb.js
}
else {
    mongosh --nodb -f $PSScriptRoot\dbvars.js -f $PSScriptRoot\modifyCmdb.js
}

if ($LASTEXITCODE -ne 0) {
    Write-Output "FAILURE"
}
else {
    if ($Crud -ne "read") {
        Write-Output "SUCCESS"
    }
}
Remove-Item -Path $PSScriptRoot\dbvars.js