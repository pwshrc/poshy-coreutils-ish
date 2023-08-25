#!/usr/bin/env pwsh
$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest


function Import-PSGalleryModuleNested {
    [OutputType([PSModuleInfo[]])]
    [CmdletBinding(DefaultParameterSetName = 'ModulesSet')]
    param(
        [Parameter(Mandatory = $false, ParameterSetName = 'ModulesSet')]
        [switch] $RuntimeDependencies,

        [Parameter(Mandatory = $false, ParameterSetName = 'ModulesSet')]
        [switch] $DevelopmentDependencies,

        [Parameter(Mandatory = $true, Position = 0, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'ModuleSpecific')]
        [ValidateNotNullOrEmpty()]
        [string] $id,

        [Parameter(Mandatory = $false, Position = 1, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'ModuleSpecific')]
        [ValidateNotNullOrEmpty()]
        [string] $version,

        [Parameter(Mandatory = $false)]
        [switch] $SkipAlreadyLoaded
    )
    [string] $ds = [System.IO.Path]::DirectorySeparatorChar
    [PSModuleInfo[]] $modulesLoaded = @()
    if ($id -and $version) {
        if ($SkipAlreadyLoaded -and (Get-Module -Name $id -ErrorAction SilentlyContinue)) {
            [string[]] $versionsLoaded = @(Get-Module -Name $id | Select-Object -ExpandProperty Version)
            if ($version -iin $versionsLoaded) {
                Write-Information "Module '$id' at version '$version' is already loaded. Skipping."
                return $null
            } else {
                Write-Warning "Module '$id' is already loaded with different version(s) ($versionsLoaded), conflicts may occur."
            }
        }

        [string] $psd1Path = "$PSScriptRoot${ds}..${ds}..${ds}lib${ds}$($_.id).$($_.version)${ds}$($_.id).psd1"
        [string] $psm1Path = "$PSScriptRoot${ds}..${ds}..${ds}lib${ds}$($_.id).$($_.version)${ds}$($_.id).psm1"
        if (Test-Path -Path $psd1Path -PathType Leaf -ErrorAction SilentlyContinue) {
            $modulesLoaded += @(Import-Module $psd1Path -Force -DisableNameChecking -PassThru)
        } elseif (Test-Path -Path $psm1Path -PathType Leaf -ErrorAction SilentlyContinue) {
            $modulesLoaded += @(Import-Module $psm1Path -Force -DisableNameChecking -PassThru)
        } else {
            throw "Could not find a `.psd1` or `.psm1` for module '$($_.id)' at version '$($_.version)'."
        }
    } else {
        if ((-not $RuntimeDependencies) -and (-not $DevelopmentDependencies) -and (-not $id)) {
            throw "Either or both of '-RuntimeDependencies' and '-DevelopmentDependencies' must be specified when not loading a specific individual module."
        }

        [string] $projectRoot = Resolve-Path -Path "$PSScriptRoot${ds}..${ds}.."
        if (-not (Test-Path "${projectRoot}${ds}lib" -PathType Container -ErrorAction SilentlyContinue)) {
            throw "Could not find folder 'lib' at '$projectRoot'. Did you forget to 'restore'?"
        }

        . "$PSScriptRoot${ds}Get-PSGalleryModuleNested.ps1"

        if ($DevelopmentDependencies) {
            [object[]] $nestedDevelopmentPsgalleryModules = Get-PSGalleryModuleNested -DevelopmentDependencies
            $nestedDevelopmentPsgalleryModules | ForEach-Object {
                Write-Information "Importing nested development dependency module '$($_.id)'."
                $modulesLoaded += @($_ | Import-PSGalleryModuleNested -SkipAlreadyLoaded:$SkipAlreadyLoaded)
            }
        }

        if ($RuntimeDependencies) {
            [object[]] $nestedRuntimePsgalleryModules = Get-PSGalleryModuleNested -RuntimeDependencies
            $nestedRuntimePsgalleryModules | ForEach-Object {
                Write-Information "Importing nested runtime dependency module '$($_.id)'."
                $modulesLoaded += @($_ | Import-PSGalleryModuleNested -SkipAlreadyLoaded:$SkipAlreadyLoaded)
            }
        }

        if ($id) {
            [object[]] $nestedPsgalleryModules = Get-PSGalleryModuleNested -id $id
            $nestedPsgalleryModules | ForEach-Object {
                Write-Information "Importing nested module '$($_.id)'."
                $modulesLoaded += @($_ | Import-PSGalleryModuleNested -SkipAlreadyLoaded:$SkipAlreadyLoaded)
            }
        }
    }

    return $modulesLoaded
}
