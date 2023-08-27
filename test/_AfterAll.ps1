#!/usr/bin/env pwsh
#Requires -Modules "Pester"
$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

# Source this file in your `AfterAll` blocks to clean up the environment.


if ($null -ne (Get-Variable -Name AfterAll_Restore_PSModulePath -Scope Global -ErrorAction SilentlyContinue)) {
    Write-Verbose "Restoring ```$env:PSModulePath`` to original value from _BeforeAll."
    $Env:PSModulePath = $Global:AfterAll_Restore_PSModulePath
    Remove-Variable -Name "AfterAll_Restore_PSModulePath" -Scope Global -Force
}

if ($null -ne (Get-Variable -Name AfterAll_ModulesToUnload -Scope Global -ErrorAction SilentlyContinue)) {
    Write-Verbose "Unloading modules previously imported during _BeforeAll."
    [array]::Reverse($Global:AfterAll_ModulesToUnload) `
        | Select-Object -ExpandProperty path -Unique `
        | ForEach-Object {
            if (Get-Module $_ -ErrorAction SilentlyContinue) {
                Remove-Module $_ -Force
                $Global:AfterAll_ModulesToUnload = @($Global:AfterAll_ModulesToUnload | Where-Object { $_.path -ne $_ })
            }
        }
    Remove-Variable -Name "AfterAll_ModulesToUnload" -Scope Global -Force
}

if ($null -ne (Get-Variable -Name SubjectModule -Scope Global -ErrorAction SilentlyContinue)) {
    Remove-Variable -Name "SubjectModule" -Scope Global -Force
}

if ($null -ne (Get-Variable -Name SubjectModuleName -Scope Global -ErrorAction SilentlyContinue)) {
    Remove-Variable -Name "SubjectModuleName" -Scope Global -Force
}
