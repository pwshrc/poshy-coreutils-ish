#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Restores dependency PSGallery modules for the project.
#>
param(
)
$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest


[string] $nuget_bin = $null
if (Get-Command nuget -ErrorAction SilentlyContinue) {
    $nuget_bin = "nuget"
} elseif (Get-Command nuget.exe -ErrorAction SilentlyContinue) {
    $nuget_bin = "nuget.exe"
} else {
    throw "``nuget.exe` not found. Please install the NuGet CLI. See: https://learn.microsoft.com/en-us/nuget/install-nuget-client-tools#nugetexe-cli."
}

[string] $ds = [System.IO.Path]::DirectorySeparatorChar
[string] $psgalleryNugetConfig = "${PSScriptRoot}${ds}..${ds}NuGet.PSGallery.config"
[string] $psgalleryPackagesConfig = "${PSScriptRoot}${ds}..${ds}packages.PSGallery.config"

&$nuget_bin restore $psgalleryPackagesConfig -ConfigFile $psgalleryNugetConfig
