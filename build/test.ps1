#!/usr/bin/env pwsh
param(
    [Parameter(Mandatory = $true, ParameterSetName = 'UseSrc')]
    [switch] $UseSrc,

    [Parameter(Mandatory = $true, ParameterSetName = 'UsePackageExport')]
    [switch] $UsePackageExport,

    [switch] $NoFail
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest


[string] $moduleLocation = $null
[string] $moduleName = $null

if ($UsePackageExport) {
    . "${PSScriptRoot}${ds}funcs${ds}Expand-PackageExportOutput.ps1"
    [System.IO.FileInfo] $psd1 = Expand-PackageExportOutput

    $moduleLocation = Split-Path -Path $psd1.FullName -Parent
    $moduleName = $psd1.BaseName
} else {
    $moduleLocation = "${PSScriptRoot}${ds}..${ds}src"
    $moduleName = (Get-ChildItem -Path $moduleLocation -Filter *.psm1 -File -Force | Select-Object -First 1 -ExpandProperty BaseName)
    $moduleLocation = Resolve-Path $moduleLocation
}

[string] $OldPSModulePath = $env:PSModulePath
try {
    . "${PSScriptRoot}${ds}funcs${ds}Import-PSGalleryModuleNested.ps1"
    Import-PSGalleryModuleNested -id 'Pester' -SkipAlreadyLoaded | Out-Null

    [PSModuleInfo[]] $modulesToUnload = @()
    try {
        if (-not (Get-Command Invoke-Pester -ErrorAction SilentlyContinue)) {
            throw "Invoke-Pester not found. Please ensure that PowerShell module 'Pester' is configured as a development dependency."
        }

        [string] $out = "${PSScriptRoot}${ds}..${ds}out"
        $pesterConfig = New-PesterConfiguration @{
            Run = @{
                Path = "${PSScriptRoot}${ds}..${ds}test"
                Throw = (-not $NoFail)
                PassThru = $true
            }
            TestResult = @{
                Enabled = $true
                OutputPath = "${out}${ds}test-results.xml"
                OutputFormat = "NUnit3"
            }
            CodeCoverage = @{
                Enabled = $true
                OutputPath = "${out}${ds}test-coverage.xml"
                OutputFormat = "JaCoCo"
                Path = $moduleLocation
                RecursePaths = $true
            }
        }

        if ($UseSrc) {
            $modulesToUnload += @(Import-PSGalleryModuleNested -RuntimeDependencies)
        }

        try {
            Write-Information "Setting ```$Global:SubjectModuleName`` to ``$moduleName``."
            New-Item -Path Variable:"Global:SubjectModuleName" -Value $moduleName -Force | Out-Null

            if ($UseSrc) {
                [string] $psm1Path = Resolve-Path "${moduleLocation}${ds}${moduleName}.psm1"
                Write-Information "Setting ```$Global:SubjectModule`` to ``$psm1Path``."
                New-Item -Path Variable:"Global:SubjectModule" -Value $psm1Path -Force | Out-Null
            } elseif ($UsePackageExport) {
                Write-Information "Setting ```$Global:SubjectModule`` to ``$moduleName``."
                New-Item -Path Variable:"Global:SubjectModule" -Value $moduleName -Force | Out-Null

                [string] $moduleLocationParent = Split-Path -Path $moduleLocation -Parent
                Write-Information "Temporarily setting ```$env:PSModulePath`` to '$moduleLocationParent'."
                $env:PSModulePath = "${moduleLocationParent}"
            }

            Invoke-Pester -Configuration $pesterConfig
        } finally {
            Remove-Module $Global:SubjectModule -Force -ErrorAction SilentlyContinue

            Remove-Item -Path Variable:"Global:SubjectModuleName" -Force -ErrorAction SilentlyContinue
            Remove-Item -Path Variable:"Global:SubjectModule" -Force -ErrorAction SilentlyContinue
        }
    } finally {
        [array]::Reverse($modulesToUnload) `
            | Select-Object -ExpandProperty path -Unique `
            | Remove-Module -Force -ErrorAction SilentlyContinue
    }
} finally {
    Write-Information "Restoring ```$env:PSModulePath`` to previous value."
    $env:PSModulePath = $OldPSModulePath
}
