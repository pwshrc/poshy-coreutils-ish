#!/usr/bin/env pwsh
$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest


<#
.SYNOPSIS
    Gets the required version of PowerShell for the current project, which is the maximum of the versions that its source files require - and also its nested dependencies.
#>
function Get-RequiredPwshVersion {
    [OutputType([Version])]
    param(
    )

    [string] $ds = [System.IO.Path]::DirectorySeparatorChar

    [version[]] $nestedModulesRequiredPwshVersions = @()
    . "${PSScriptRoot}${ds}Import-PSGalleryModuleNested.ps1"
    [PSModuleInfo[]] $modulesToUnload = @()
    # We don't `-SkipAlreadyLoaded` because we want to make sure we get all the required Pwsh versions.
    $modulesToUnload += @(Import-PSGalleryModuleNested -RuntimeDependencies)
    try {
        $nestedModulesRequiredPwshVersions += @($modulesToUnload | Select-Object -ExpandProperty PowerShellVersion)
    } finally {
        if ($null -ne $modulesToUnload) {
            [array]::Reverse($modulesToUnload) `
                | Select-Object -ExpandProperty path -Unique `
                | Remove-Module -Force -ErrorAction SilentlyContinue
        }
    }

    # Parse all the source files for the current module and look for the `#requires -version` directive.
    [string] $thisModuleSrcDir = "${PSScriptRoot}${ds}..${ds}..${ds}src"
    [System.IO.FileInfo[]] $thisModuleSrcFiles = @(
        @('ps1', 'psm1') | ForEach-Object { Get-ChildItem -Path $thisModuleSrcDir -Filter "*.$_" -File -Recurse -Force }
    )
    if ($thisModuleSrcFiles) {
        [version[]] $thisModuleRequiredPwshVersions = @()
        foreach ($thisModuleSrcFile in $thisModuleSrcFiles) {
            # Get the ast of the file.
            [System.Management.Automation.Language.Ast] $ast = $null
            [System.Management.Automation.Language.Token[]] $tokens = @()
            [System.Management.Automation.Language.ParseError[]] $errors = @()
            $ast = [System.Management.Automation.Language.Parser]::ParseFile($thisModuleSrcFile.FullName, [ref] $tokens, [ref] $errors)

            # Look for the `#requires -version` directive.
            [string[]] $requiresVersions = $null
            $requiresVersions = $ast.FindAll({ $args[0] -is [System.Management.Automation.Language.ScriptBlockAst] }, $true) `
                | ForEach-Object {
                    if ($_.Extent.Text -match '#requires\s+-version\s+(?<version>[^\s]+)') {
                        return $matches['version']
                    }
                }
            if ($requiresVersions) {
                $thisModuleRequiredPwshVersions += @($requiresVersions | ForEach-Object { [version] $_ })
            }
        }
    }

    # Return the maximum of the required Pwsh versions.
    [version[]] $allRequiredPwshVersions = @($thisModuleRequiredPwshVersions + $nestedModulesRequiredPwshVersions)
    $allRequiredPwshVersions += @([version]"7.0")
    return ($allRequiredPwshVersions | Sort-Object -Descending | Select-Object -First 1)
}
