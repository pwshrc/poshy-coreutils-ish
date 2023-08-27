#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Lints the project.
#>
param(
    [switch] $NoFail,
    [switch] $CI
)
$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest


[string] $ds = [System.IO.Path]::DirectorySeparatorChar
. "${PSScriptRoot}${ds}funcs${ds}Import-PSGalleryModuleNested.ps1"
Import-PSGalleryModuleNested -id 'PSScriptAnalyzer' -SkipAlreadyLoaded | Out-Null

if (-not (Get-Command Invoke-ScriptAnalyzer -ErrorAction SilentlyContinue)) {
    throw "Invoke-ScriptAnalyzer not found. Please ensure that PowerShell module 'PSScriptAnalyzer' is configured as a development dependency."
}
Invoke-ScriptAnalyzer -Path "${PSScriptRoot}${ds}..${ds}src${ds}**${ds}*" -Recurse -OutVariable issues
$errors   = $issues.Where({$_.Severity -eq 'Error'})
$warnings = $issues.Where({$_.Severity -eq 'Warning'})
if ($CI) {
    $warnings | ForEach-Object {
        Write-Host "::warning file=$($_.ScriptName),line=$($_.Line),col=$($_.Column)::$(@($_.Message -split "`n")[0])"
    }
    $errors | ForEach-Object {
        Write-Host "::error file=$($_.ScriptName),line=$($_.Line),col=$($_.Column)::$(@($_.Message -split "`n")[0])"
    }
}
[string] $summaryText = "Linting encountered $($errors.Count) errors and $($warnings.Count) warnings total."
if ($errors -and (-not $NoFail)) {
    $summaryText = "⛔ $summaryText"
} elseif ($errors -or $warnings) {
    $summaryText = "⚠️ $summaryText"
} else {
    $summaryText = "✅ $summaryText"
}
if ($CI) {
    $summaryText | Out-File -FilePath $Env:GITHUB_STEP_SUMMARY -Encoding utf8
}
if ($errors -and (-not $NoFail)) {
    Write-Error $summaryText -ErrorAction Stop
} else {
    Write-Output $summaryText
}
