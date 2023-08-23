#!/usr/bin/env pwsh
param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string] $NUGET_KEY,

    [switch] $Prerelease,

    [switch] $WhatIf
)
$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest


[string] $ds = [System.IO.Path]::DirectorySeparatorChar
[string] $out = "${PSScriptRoot}${ds}..${ds}out"
[string] $psgallery_nupkg_name = $null
[string] $psgallery_nupkg_fullname = $null
[System.IO.FileInfo[]] $psgallery_nupkg = @(Get-ChildItem -Path $out -Filter "*.nupkg" -Recurse -File -Force)
if ($psgallery_nupkg.Count -eq 0) {
    throw "No NuGet packages were found in '$out'."
} elseif ($psgallery_nupkg.Count -gt 1) {
    throw "Multiple NuGet packages were found in '$out'. Did you forget to clean?"
} else {
    $psgallery_nupkg_name = $psgallery_nupkg[0].BaseName
    $psgallery_nupkg_fullname = $psgallery_nupkg[0].FullName
    Write-Host "Using NuGet package '$psgallery_nupkg_fullname'."
}
[string] $module_location = "${out}${ds}${psgallery_nupkg_name}"
if (Test-Path $module_location -ErrorAction SilentlyContinue) {
    throw "The directory '${module_location}' already exists. Did you forget to clean?"
}
Expand-Archive -Path $psgallery_nupkg_fullname -DestinationPath $module_location -Force | Out-Null
$module_location = Resolve-Path -Path $module_location
[System.IO.FileInfo] $psd1 = Get-ChildItem -Path $module_location -Filter "*.psd1" -Recurse -File -Force | Select-Object -First 1
[hashtable] $psd1_data = Import-PowerShellDataFile -Path $psd1[0].FullName
[string] $new_module_location = Join-Path $out $psd1.BaseName
Move-Item -Path $module_location -Destination $new_module_location -Force | Out-Null
$module_location = $new_module_location


Publish-Module `
    -Path $module_location `
    -NuGetApiKey $NUGET_KEY `
    -ReleaseNotes $psd1_data.PrivateData.PSData.ReleaseNotes `
    -Tags $psd1_data.PrivateData.PSData.Tags `
    -LicenseUri $psd1_data.PrivateData.PSData.LicenseUri `
    -IconUri $psd1_data.PrivateData.PSData.IconUri `
    -ProjectUri $psd1_data.PrivateData.PSData.ProjectUri `
    -WhatIf:$WhatIf
