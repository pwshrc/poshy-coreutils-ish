#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Publishes the project to the PowerShell Gallery.
#>
param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string] $NUGET_KEY,

    [switch] $Prerelease,

    [switch] $WhatIf
)
$ErrorActionPreference = "Stop"
$InformationPreference = "Continue"
Set-StrictMode -Version Latest


[string] $ds = [System.IO.Path]::DirectorySeparatorChar
. "${PSScriptRoot}${ds}funcs${ds}Expand-PackageExportOutput.ps1"
[System.IO.FileInfo] $psd1 = Expand-PackageExportOutput
[hashtable] $psd1Data = Import-PowerShellDataFile -Path $psd1.FullName
[string] $expandedModulePath = $psd1.Directory.FullName

Publish-Module `
    -Path $expandedModulePath `
    -NuGetApiKey $NUGET_KEY `
    -ReleaseNotes $psd1Data.PrivateData.PSData.ReleaseNotes `
    -Tags $psd1Data.PrivateData.PSData.Tags `
    -LicenseUri $psd1Data.PrivateData.PSData.LicenseUri `
    -IconUri $psd1Data.PrivateData.PSData.IconUri `
    -ProjectUri $psd1Data.PrivateData.PSData.ProjectUri `
    -WhatIf:$WhatIf
