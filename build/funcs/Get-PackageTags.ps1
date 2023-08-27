#!/usr/bin/env pwsh
$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest


# PSModule
# PSIncludes_Function
# PSFunction_*
# PSCommand_*
# PSIncludes_Cmdlet
# PSCmdlet_*
# PSIncludes_DscResource
# PSDscResource_*
# PSIncludes_RoleCapability
# PSRoleCapability_*
# PSIncludes_Workflow
# PSWorkflow_*
# *.psrc

function Get-PackageTags {
    param(
        [Parameter(Mandatory = $true, ParameterSetName = "VariantNuSpec")]
        [ValidateNotNullOrEmpty()]
        [string] $PackageId,

        [Parameter(Mandatory = $true, ParameterSetName = "VariantNuSpec")]
        [Alias("PSGalleryExtended")]
        [switch] $ForNuSpec,

        [Parameter(Mandatory = $true, ParameterSetName = "VariantPSData")]
        [switch] $ForPSData,

        [Parameter(Mandatory = $true, ParameterSetName = "VariantGitHubRepoTopics")]
        [switch] $ForGitHubRepoTopics,

        [Parameter(Mandatory = $true, ParameterSetName = "VariantNuSpec")]
        [hashtable] $ModuleExports,

        [Parameter(Mandatory = $false, ParameterSetName = "VariantNuSpec")]
        [switch] $PSEdition_Desktop,

        [Parameter(Mandatory = $false, ParameterSetName = "VariantNuSpec")]
        [switch] $PSEdition_Core,

        [switch] $AllowEmpty
    )

    [string] $ds = [System.IO.Path]::DirectorySeparatorChar
    [string] $tagsFile = "${PSScriptRoot}${ds}..${ds}..${ds}.info${ds}tags.txt"
    if (-not (Test-Path $tagsFile -ErrorAction SilentlyContinue)) {
        Write-Error "The file '${tagsFile}' does not exist."
        return
    }
    [string[]] $tags = @()
    $tags = ((Get-Content -Path $tagsFile -Encoding UTF8 | ForEach-Object { $_.Trim() } | Where-Object { -not [string]::IsNullOrEmpty($_) }))

    if ((-not $tags) -and (-not $ForNuSpec)) {
        if ($AllowEmpty) {
            return
        }
        Write-Error "The file '${tagsFile}' is empty."
        return
    }

    if ($ForNuSpec) {
        if ($PackageId) {
            $tags += @($PackageId)
        }
        $tags += @('PSModule')

        if ($ModuleExports["Functions"].Count -gt 0) {
            $tags += @("PSIncludes_Function")
            $tags += @($ModuleExports["Functions"] | ForEach-Object { "PSFunction_${_}" })
        }
        if ($ModuleExports["Cmdlets"].Count -gt 0) {
            $tags += @("PSIncludes_Cmdlet")
            $tags += @($ModuleExports["Cmdlets"] | ForEach-Object { "PSCmdlet_${_}" })
        }
        if ($ModuleExports["Commands"].Count -gt 0) {
            $tags += @("PSIncludes_Command")
            $tags += @($ModuleExports["Commands"] | ForEach-Object { "PSCommand_${_}" })
        }
        if ($ModuleExports["DscResources"].Count -gt 0) {
            $tags += @("PSIncludes_DscResource")
            $tags += @($ModuleExports["DscResources"] | ForEach-Object { "PSDscResource_${_}" })
        }
        [System.IO.FileInfo[]] $roleCapabilityFiles = @()
        $roleCapabilityFiles = @(Get-ChildItem -Path "${PSScriptRoot}${ds}..${ds}..${ds}" -Filter "*.psrc" -Recurse -File -Force -ErrorAction SilentlyContinue)
        if ($roleCapabilityFiles) {
            [string[]] $roleCapabilities = $roleCapabilityFiles | ForEach-Object { $_.Name.Replace(".psrc", "") }
            $tags += @("PSIncludes_RoleCapability")
            $tags += @($roleCapabilities | ForEach-Object { "PSRoleCapability_$_" })
        }
        # TODO: PSIncludes_Workflow
        # TODO: PSWorkflow_*
        if ($PSEdition_Desktop) {
            $tags += @("PSEdition_Desktop")
        }
        if ($PSEdition_Core) {
            $tags += @("PSEdition_Core")
        }
    }

    if ($ForGitHubRepoTopics) {
        $tags += @('powershell', 'powershell-gallery', 'powershell-module')

        $tags = $tags | ForEach-Object { $_.Replace("_", "-") -replace "\s+", "-" }

        # Find everything in PascalCase and transform it into lower-kebab-case.
        $tags = $tags | ForEach-Object {
            ($_ -creplace "[a-z][A-Z]", { $_.Value.ToLower().Insert(1, '-') }).ToLower() `
            -creplace "\d[A-Z]", { $_.Value.ToLower().Insert(1, '-') } `
            -creplace "[a-z]\d", { $_.Value.ToLower().Insert(1, '-') }
        }
    } elseif ($ForNuSpec -or $ForPSData) {
        $tags = $tags | ForEach-Object { $_ -replace "\s+", "-" }
    }

    $tags = $tags | Sort-Object -Unique

    return $tags
}
