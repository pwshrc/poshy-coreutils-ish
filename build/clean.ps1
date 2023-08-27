#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Cleans the project of build artifacts.
#>
param(
)
$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest


[string] $ds = [System.IO.Path]::DirectorySeparatorChar
[string] $projectRoot = Resolve-Path "${PSScriptRoot}${ds}.." -Relative

[string[]] $foldersToDelete = @(
    'bin',
    'lib',
    'obj',
    'out'
)

foreach ($folderToDelete in $foldersToDelete) {
    if (Test-Path "${projectRoot}${ds}${folderToDelete}" -ErrorAction SilentlyContinue) {
        Remove-Item -Path "${projectRoot}${ds}${folderToDelete}" -Recurse -Force -ErrorAction Continue
    }
}
