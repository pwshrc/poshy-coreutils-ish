#!/usr/bin/env pwsh
$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest


function Get-PackageCopyright {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateScript({ Test-Path -Path $_ -ErrorAction SilentlyContinue })]
        [string] $LicenseFilePath
    )
    if (-not (Test-Path -Path $LicenseFilePath -ErrorAction SilentlyContinue)) {
        throw "The file '${LicenseFilePath}' does not exist."
    }
    [string] $copyright = ((Get-Content -Path $LicenseFilePath -Encoding UTF8 |
        Where-Object { $_ -match "(\(c\)|©️)" } |
        ForEach-Object { $_.Trim().TrimEnd(",").TrimEnd(";").TrimEnd(".") }
    ) -join "; "+[Environment]::NewLine)
    if ([string]::IsNullOrEmpty($copyright)) {
        throw "The file '${LicenseFilePath}' does not contain a copyright indicator."
    }
    return $copyright
}
