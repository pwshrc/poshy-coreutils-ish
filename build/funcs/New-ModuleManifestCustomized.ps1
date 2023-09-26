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
        [string] $PackageVersion,

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
        [switch] $PSEdition_Core,

        [Parameter(Mandatory = $false)]
        [object[]] $NestedRuntimePSGalleryModules = @(),

        [Parameter(Mandatory = $false)]
        [string] $PathFromPsd1ParentToPsm1Parent = "."
    )

    [string] $ds = [System.IO.Path]::DirectorySeparatorChar
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

    [hashtable] $privateData = @{
        PackageVersion = $PackageVersion
    }
    $additionNewModuleManifestArgs["PrivateData"] = $privateData

    [string[]] $nestedModules = @()
    if ($NestedRuntimePSGalleryModules) {
        $nestedModules += @(
            $NestedRuntimePSGalleryModules `
            | ForEach-Object {
                [string] $psd1Path = ".${ds}lib${ds}$($_.id).$($_.version)${ds}$($_.id).psd1"
                [string] $psm1Path = ".${ds}lib${ds}$($_.id).$($_.version)${ds}$($_.id).psm1"
                if (Test-Path -Path $psd1Path -PathType Leaf -ErrorAction SilentlyContinue) {
                    $psd1Path
                } elseif (Test-Path -Path $psm1Path -PathType Leaf -ErrorAction SilentlyContinue) {
                    $psm1Path
                } else {
                    throw "Could not find a `.psd1` or `.psm1` for module '$($_.id)' at version '$($_.version)'."
                }
            } `
        )
    }

    . "${PSScriptRoot}${ds}Get-RequiredPwshVersion.ps1"
    [version] $requiredPwshVersion = $null
    $requiredPwshVersion = Get-RequiredPwshVersion

    # This is just where we write the psd1 _for now_.
    # The project file generated later will decide where in the NuPkg it goes (and therefor where it lands when the NuPkg is expanded.)
    [string] $moduleManifestPath = "${PSScriptRoot}${ds}..${ds}..${ds}out${ds}${PackageId}.psd1"
    if (-not (Test-Path (Split-Path -Path $moduleManifestPath -Parent))) {
        New-Item -Path (Split-Path -Path $moduleManifestPath -Parent) -ItemType Directory -Force | Out-Null
    }
    [string] $pathToPsm1FromPsd1 = Join-Path -Path $PathFromPsd1ParentToPsm1Parent -ChildPath "${PackageId}.psm1"
    New-ModuleManifest `
        -Path $moduleManifestPath `
        -RootModule $pathToPsm1FromPsd1 `
        -Author ($Authors -join "; ") `
        -CompanyName $CompanyName `
        -Description $packageSynopsis `
        -Copyright $PackageCopyright `
        -ModuleVersion $PackageVersion `
        -Guid $PackageGuid `
        -Tags $PackageTags `
        -LicenseUri "${ProjectUrlAtVersion}/${LicenseFileName}" `
        -ProjectUri $ProjectUrl `
        -IconUri $PackageIconUrl `
        -PowerShellVersion $requiredPwshVersion.ToString() `
        -NestedModules $nestedModules `
        @additionNewModuleManifestArgs

    return Get-Item -Path $moduleManifestPath
}
