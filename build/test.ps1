#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Runs the project's tests.
#>
param(
    [Parameter(Mandatory = $true, ParameterSetName = 'UseSrc')]
    [switch] $UseSrc,

    [Parameter(Mandatory = $true, ParameterSetName = 'UsePackageExport')]
    [switch] $UsePackageExport,

    [switch] $NoFail,

    [switch] $CI,

    [string] $OutputFilesPrefix = ''
)
$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest


Set-Variable -Name TestsUsePackageExport -Value [bool]$UsePackageExport -Scope Global -Option ReadOnly -Force
[string] $ds = [System.IO.Path]::DirectorySeparatorChar
[string] $moduleLocation = $null

if ($UsePackageExport) {
    . "${PSScriptRoot}${ds}funcs${ds}Expand-PackageExportOutput.ps1"
    [System.IO.FileInfo] $psd1 = Expand-PackageExportOutput

    $moduleLocation = Split-Path -Path $psd1.FullName -Parent
} else {
    $moduleLocation = "${PSScriptRoot}${ds}..${ds}src"
    $moduleLocation = Resolve-Path $moduleLocation
}

try {
    . "${PSScriptRoot}${ds}funcs${ds}Import-PSGalleryModuleNested.ps1"
    Import-PSGalleryModuleNested -id 'Pester' -SkipAlreadyLoaded | Out-Null

    if (-not (Get-Command Invoke-Pester -ErrorAction SilentlyContinue)) {
        throw "Invoke-Pester not found. Please ensure that PowerShell module 'Pester' is configured as a development dependency."
    }

    [string] $out = "${PSScriptRoot}${ds}..${ds}out"
    $pesterConfig = New-PesterConfiguration @{
        Run = @{
            Path = "${PSScriptRoot}${ds}..${ds}test"
            Throw = $false  # We'll handle NoFail-or-not ourselves, when we handle the results.
            PassThru = $true
        }
        TestResult = @{
            Enabled = $true
            OutputPath = "${out}${ds}${OutputFilesPrefix}test-results.xml"
            OutputFormat = "NUnit3"
        }
        CodeCoverage = @{
            Enabled = $true
            OutputPath = "${out}${ds}${OutputFilesPrefix}test-coverage.xml"
            OutputFormat = "JaCoCo"
            Path = $moduleLocation
            RecursePaths = $true
        }
        Output = @{
            CIFormat = [bool]$CI ? "GithubActions" : "Auto"
        }
    }

    $pesterResult = Invoke-Pester -Configuration $pesterConfig
    $pesterResult | Write-Output

    [string] $summaryText = "Testing encountered $($pesterResult.FailedCount) failures and $($pesterResult.SkippedCount) skipped tests, with $($pesterResult.PassedCount) tests passing out of a total of $($pesterResult.TotalCount) tests."
    if ($pesterResult.FailedCount -gt 0 -and (-not $NoFail)) {
        $summaryText = "⛔ $summaryText"
    } elseif ($pesterResult.FailedCount -gt 0) {
        $summaryText = "⚠️ $summaryText"
    } elseif ($pesterResult.SkippedCount -gt 0) {
        $summaryText = "❔ $summaryText"
    } else {
        $summaryText = "✅ $summaryText"
    }
    if ($CI) {
        $summaryText | Out-File -FilePath $Env:GITHUB_STEP_SUMMARY -Encoding utf8
    }
    if ($pesterResult.FailedCount -gt 0 -and (-not $NoFail)) {
        Write-Error $summaryText -ErrorAction Stop
    } else {
        Write-Output $summaryText
    }
} finally {
    if (Get-Variable -Name TestsUsePackageExport -Scope Global -ErrorAction SilentlyContinue) {
        Remove-Variable -Name TestsUsePackageExport -Scope Global -Force
    }
}
