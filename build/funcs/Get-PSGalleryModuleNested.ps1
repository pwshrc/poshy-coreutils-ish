#!/usr/bin/env pwsh
$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest


function Get-PSGalleryModuleNested {
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
        [string] $version
    )

    if ((-not $RuntimeDependencies) -and (-not $DevelopmentDependencies) -and (-not $id)) {
        throw "Either or both of '-RuntimeDependencies' and '-DevelopmentDependencies' must be specified when not getting a specific individual module."
    }

    [string] $ds = [System.IO.Path]::DirectorySeparatorChar
    [string] $packagesConfigFile = "${PSScriptRoot}${ds}..${ds}..${ds}packages.PSGallery.config"

    [xml] $packagesConfig = [xml](Get-Content -Raw -Path $packagesConfigFile -Encoding UTF8)
    [System.Xml.XmlElement[]] $results = $packagesConfig.packages.package | Where-Object {
        if ($id) {
            if ($_.id -ieq $id) {
                if ($version) {
                    if ($_.version -ieq $version) {
                        return $true
                    }
                } else {
                    return $true
                }
            } elseif (-not $id) {
                return $true
            }
        } elseif ($_ | Get-Member -Name developmentDependency -ErrorAction SilentlyContinue) {
            if ([bool] $_.developmentDependency) {
                return [bool]$DevelopmentDependencies
            } else {
                return [bool]$RuntimeDependencies
            }
        } else {
            return [bool]$RuntimeDependencies
        }
    }

    foreach ($item in $results) {
        [string] $location = "${PSScriptRoot}${ds}..${ds}..${ds}lib${ds}$($item.id).$($item.version)"
        $location = (Resolve-Path -Path $location -ErrorAction SilentlyContinue) ?? $location
        [string] $psd1Path = `
            Get-ChildItem -Path $location -Filter "$($item.id).psd1" -Recurse -File -Force `
            | Select-Object -First 1 -ExpandProperty FullName
        [string] $psm1Path = `
            Get-ChildItem -Path $location -Filter "$($item.id).psm1" -Recurse -File -Force `
            | Select-Object -First 1 -ExpandProperty FullName

        if ($psd1Path) {
            $item | Add-Member -MemberType NoteProperty -Name path -Value $psd1Path
        } elseif ($psm1Path) {
            $item | Add-Member -MemberType NoteProperty -Name path -Value $psm1Path
        } else {
            $item | Add-Member -MemberType NoteProperty -Name path -value [string]::Empty
        }
    }

    return $results
}
