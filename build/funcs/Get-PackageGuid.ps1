#!/usr/bin/env pwsh
$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest


function Get-PackageGuid {
    [string] $ds = [System.IO.Path]::DirectorySeparatorChar
    [string] $GuidFilePath = "${PSScriptRoot}${ds}..${ds}..${ds}.info${ds}guid.txt"
    if (-not (Test-Path -Path $GuidFilePath -ErrorAction SilentlyContinue)) {
        throw "The file '${GuidFilePath}' does not exist."
    }
    [string] $guid = $null
    $guid = (Get-Content -Raw -Path $GuidFilePath -Encoding UTF8).Trim()
    if ([string]::IsNullOrEmpty($guid)) {
        throw "The file '${GuidFilePath}' is empty."
    }
    return $guid
}
