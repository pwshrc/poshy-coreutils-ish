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


if (-not (Get-Command Invoke-Pester -ErrorAction SilentlyContinue)) {
    throw "Invoke-Pester not found. Please install the PowerShell module 'Pester'."
}
[string] $ds = [System.IO.Path]::DirectorySeparatorChar
[string] $out = "${PSScriptRoot}${ds}..${ds}out"
[string] $psgallery_nupkg_name = $null
[string] $module_location = $null
if ($UsePackageExport) {
    [string] $psgallery_nupkg_fullname = $null
    [System.IO.FileInfo[]] $psgallery_nupkg = @(Get-ChildItem -Path $out -Filter "*.nupkg" -Recurse -File -Force)
    if ($psgallery_nupkg.Count -eq 0) {
        throw "No NuGet packages were found in ``$out``."
    } elseif ($psgallery_nupkg.Count -gt 1) {
        throw "Multiple NuGet packages were found in ``$out``. Did you forget to clean?"
    } else {
        $psgallery_nupkg_name = $psgallery_nupkg[0].BaseName
        $psgallery_nupkg_fullname = $psgallery_nupkg[0].FullName
        Write-Host "Using NuGet package ``$psgallery_nupkg_fullname``."
    }
    $module_location = "${out}${ds}${psgallery_nupkg_name}"
    Expand-Archive -Path $psgallery_nupkg_fullname -DestinationPath $module_location -Force | Out-Null
    $module_location = Resolve-Path -Path $module_location
    [System.IO.FileInfo] $psd1 = Get-ChildItem -Path $module_location -Filter "*.psd1" -Recurse -File -Force
    [string] $new_module_location = Join-Path $out $psd1.BaseName
    if (Test-Path $new_module_location -ErrorAction SilentlyContinue) {
        Remove-Item -Path $new_module_location -Recurse -Force | Out-Null
    }
    Move-Item -Path $module_location -Destination $new_module_location -Force | Out-Null
    $module_location = $new_module_location
} else {
    $module_location = "${PSScriptRoot}${ds}..${ds}src"
}
[string] $moduleName = Get-ChildItem -Path $module_location -Filter *.psm1 -Recurse -File -Force | Select-Object -First 1 -ExpandProperty BaseName
Write-Host "Setting ```$Global:SubjectModuleName`` to ``$moduleName``."
New-Item -Path Variable:"Global:SubjectModuleName" -Value $moduleName -Force | Out-Null

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
        Path = $module_location
        RecursePaths = $true
    }
}

[string] $ps = [System.IO.Path]::PathSeparator
Write-Host "Setting ```$Env:PSModulePath`` to only point at ``$module_location``'s parent folder."
[string] $OldPSModulePath = $Env:PSModulePath
$Env:PSModulePath = Split-Path -Path $module_location -Parent
try {
    Invoke-Pester -Configuration $pesterConfig
} finally {
    $Env:PSModulePath = $OldPSModulePath
    Remove-Item -Path Variable:"Global:SubjectModuleName" -Force -ErrorAction SilentlyContinue
}
