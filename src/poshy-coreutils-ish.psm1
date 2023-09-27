#!/usr/bin/env pwsh
$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest


foreach ($item in Get-ChildItem -Path $PSScriptRoot -Filter "*.ps1" -File) {
    [string] $scriptFileContent = Get-Content -Path $item.FullName -Raw
    if (-not ($scriptFileContent -like "*TODO: Implement*")) {
        . $item.FullName
        Export-ModuleMember -Function $item.BaseName
    }
}
