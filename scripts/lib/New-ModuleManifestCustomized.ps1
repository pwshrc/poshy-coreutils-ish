#!/usr/bin/env pwsh
$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest


function New-ModuleManifestCustomized {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $PackageId,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $CompanyName,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string[]] $Authors,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $GitRepositoryUrl,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $CommitSha,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $ProjectUrl,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $LicenseFileName,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $ReadmeFileName,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $PackageIconUrl,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $PackageSynopsis,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $PackageCopyright,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string[]] $PackageTags,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string] $ReleaseNotes,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $PackageVersionMajorMinorPatchBuild,

        [Parameter(Mandatory = $false)]
        [string] $PackageVersionPrereleaseTag,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string] $ProjectUrlAtVersion = $ProjectUrl + "/tree/${CommitSha}",

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $PackageGuid,

        [Parameter(Mandatory = $false)]
        [switch] $PSEdition_Desktop,

        [Parameter(Mandatory = $false)]
        [switch] $PSEdition_Core
    )
    [string] $moduleManifestPath = "${PSScriptRoot}${ds}..${ds}..${ds}out${ds}${PackageId}.psd1"

    [hashtable] $additionNewModuleManifestArgs = @{}
    if (-not [string]::IsNullOrWhiteSpace($PackageVersionPrereleaseTag)) {
        $additionNewModuleManifestArgs["Prerelease"] = $PackageVersionPrereleaseTag
    }
    if (-not [string]::IsNullOrWhiteSpace($ReleaseNotes)) {
        $additionNewModuleManifestArgs["ReleaseNotes"] = $ReleaseNotes
    }

    [string[]] $formatsFiles = Get-ChildItem -Path "${PSScriptRoot}${ds}..${ds}..${ds}src" -Filter "*.format.ps1xml" -Recurse -File | ForEach-Object { $_.FullName }
    if ($formatsFiles) {
        $additionNewModuleManifestArgs["FormatsToProcess"] = $formatsFiles
    }

    [string[]] $typesFiles = Get-ChildItem -Path "${PSScriptRoot}${ds}..${ds}..${ds}src" -Filter "*.types.ps1xml" -Recurse -File | ForEach-Object { $_.FullName }
    if ($typesFiles) {
        $additionNewModuleManifestArgs["TypesToProcess"] = $typesFiles
    }

    if ($PSEdition_Desktop -or $PSEdition_Core) {
        $additionNewModuleManifestArgs["CompatiblePSEditions"] = @()
        if ($PSEdition_Desktop) {
            $additionNewModuleManifestArgs["CompatiblePSEditions"] += "Desktop"
        }
        if ($PSEdition_Core) {
            $additionNewModuleManifestArgs["CompatiblePSEditions"] += "Core"
        }
    }

    if (-not (Test-Path (Split-Path -Path $moduleManifestPath -Parent))) {
        New-Item -Path (Split-Path -Path $moduleManifestPath -Parent) -ItemType Directory -Force | Out-Null
    }
    New-ModuleManifest `
        -Path $moduleManifestPath `
        -RootModule "${PackageId}.psm1" `
        -Author ($Authors -join "; ") `
        -CompanyName $CompanyName `
        -Description $packageSynopsis `
        -Copyright $PackageCopyright `
        -ModuleVersion $PackageVersionMajorMinorPatchBuild `
        -Guid $PackageGuid `
        -Tags $PackageTags `
        -LicenseUri "${ProjectUrlAtVersion}/${LicenseFileName}" `
        -ProjectUri $ProjectUrl `
        -IconUri $PackageIconUrl `
        -PowerShellVersion "7.0" `
        @additionNewModuleManifestArgs

    return Get-Item -Path $moduleManifestPath
}
