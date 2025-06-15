param(
    [version]$Version = "1.0.0"
)
#Requires -Module ModuleBuilder
$params = @{
    SourcePath = "$PSScriptRoot\SDAFUtilities\SDAFUtilities.psd1"
    CopyPaths = @("$PSScriptRoot\SDAFUtilities\README.md")
    Version = $Version
    UnversionedOutputDirectory = $true
}

Remove-Module -Name SDAFUtilities -Force -ErrorAction SilentlyContinue
Build-Module @params -Verbose


