#!/usr/bin/env pwsh
param(
    [switch] $NoFail
)
$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest


[string] $ds = [System.IO.Path]::DirectorySeparatorChar
. "${PSScriptRoot}${ds}funcs${ds}Import-PSGalleryModuleNested.ps1"
Import-PSGalleryModuleNested -id 'PSScriptAnalyzer' -SkipAlreadyLoaded | Out-Null

if (-not (Get-Command Invoke-ScriptAnalyzer -ErrorAction SilentlyContinue)) {
    throw "Invoke-ScriptAnalyzer not found. Please ensure that PowerShell module 'PSScriptAnalyzer' is configured as a development dependency."
}
Invoke-ScriptAnalyzer -Path "${PSScriptRoot}${ds}..${ds}src${ds}**${ds}*" -Recurse -ReportSummary -OutVariable issues
$errors   = $issues.Where({$_.Severity -eq 'Error'})
$warnings = $issues.Where({$_.Severity -eq 'Warning'})
if ($errors -and (-not $NoFail)) {
    Write-Error "There were $($errors.Count) errors and $($warnings.Count) warnings total." -ErrorAction Stop
} else {
    Write-Output "There were $($errors.Count) errors and $($warnings.Count) warnings total."
}
