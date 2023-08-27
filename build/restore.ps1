#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Restores dependency PSGallery modules for the project.
#>
param(
)
$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest


if (-not (Get-Command nuget -ErrorAction SilentlyContinue)) {
    throw "NuGet not found. Please install the NuGet CLI."
}

[string] $ds = [System.IO.Path]::DirectorySeparatorChar
[string] $psgalleryNugetConfig = "$PSScriptRoot${ds}..${ds}NuGet.PSGallery.config"
[string] $psgalleryPackagesConfig = "$PSScriptRoot${ds}..${ds}packages.PSGallery.config"

nuget restore $psgalleryPackagesConfig -ConfigFile $psgalleryNugetConfig
