#!/usr/bin/env pwsh
#Requires -Modules "Pester"
$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

# Source this file in your `BeforeAll` blocks to set up the environment.


[bool] $UsePackageExport = [bool](Get-Variable -Name TestsUsePackageExport -Scope Global -ValueOnly -ErrorAction SilentlyContinue)
[bool] $UseSrc = -not $UsePackageExport

[string] $ds = [System.IO.Path]::DirectorySeparatorChar
[string] $moduleLocation = $null
[string] $moduleName = $null

if ($UsePackageExport) {
    . "${PSScriptRoot}${ds}..${ds}build${ds}funcs${ds}Expand-PackageExportOutput.ps1"
    [System.IO.FileInfo] $psd1 = Expand-PackageExportOutput

    $moduleLocation = Split-Path -Path $psd1.FullName -Parent
    $moduleName = $psd1.BaseName
} else {
    $moduleLocation = "${PSScriptRoot}${ds}..${ds}src"
    $moduleName = (Get-ChildItem -Path $moduleLocation -Filter *.psm1 -File -Force | Select-Object -First 1 -ExpandProperty BaseName)
    $moduleLocation = Resolve-Path $moduleLocation
}

if ($UseSrc) {
    if (-not (Get-Variable -Name AfterAll_ModulesToUnload -Scope Global -ErrorAction SilentlyContinue)) {
        Set-Variable -Name AfterAll_ModulesToUnload -Scope Global -Value @()
    }

    . "${PSScriptRoot}${ds}..${ds}build${ds}funcs${ds}Import-PSGalleryModuleNested.ps1"
    $Global:AfterAll_ModulesToUnload += @(Import-PSGalleryModuleNested -RuntimeDependencies)
}

Write-Verbose "Setting ```$Global:SubjectModuleName`` to ``$moduleName``."
Set-Variable -Name SubjectModuleName -Scope Global -Value $moduleName -Option ReadOnly

if ($UseSrc) {
    [string] $psm1Path = Resolve-Path "${moduleLocation}${ds}${moduleName}.psm1"
    Write-Verbose "Setting ```$Global:SubjectModule`` to ``$psm1Path``."
    Set-Variable -Name SubjectModule -Scope Global -Value $psm1Path -Option ReadOnly
} elseif ($UsePackageExport) {
    Write-Verbose "Setting ```$Global:SubjectModule`` to ``$moduleName``."
    Set-Variable -Name SubjectModule -Scope Global -Value $moduleName -Option ReadOnly

    [string] $moduleLocationParent = Split-Path -Path $moduleLocation -Parent
    Write-Verbose "Temporarily setting ```$env:PSModulePath`` to '$moduleLocationParent'."
    Set-Variable -Name AfterAll_Restore_PSModulePath -Scope Global -Value $env:PSModulePath -Option ReadOnly
    $env:PSModulePath = "${moduleLocationParent}"
}
