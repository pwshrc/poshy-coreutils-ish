#!/usr/bin/env pwsh
# Take all the PowerShell module content in ../src and package it as a NuPkg.
param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string] $PackageVersionNuGet,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string] $PackageVersionMajorMinorPatchBuild,

    [Parameter(Mandatory = $false)]
    [string] $PackageVersionPrereleaseTag,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string] $ReleaseNotes,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string] $CommitSha
)
$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest


[string] $ds = [System.IO.Path]::DirectorySeparatorChar
& "${PSScriptRoot}${ds}restore.ps1"
[string[]] $authors = @(
    "Pwshrc Maintainers"
)
[string] $companyName = "Pwshrc Maintainers"
[string] $repositoryGitUrl = (git remote get-url origin)
[string] $PackageId = $repositoryGitUrl.Split("/")[-1].Split(".")[0]
[string] $projectUrl = $repositoryGitUrl.Replace(".git", "")
[string] $readmeFileName = "README.md"
[string] $licenseFilePath = "${PSScriptRoot}${ds}..${ds}LICENSE.txt"
[string] $licenseFileName = [System.IO.Path]::GetFileName($licenseFilePath)
[string] $packageIconUrl = "https://en.gravatar.com/userimage/238766323/a23519bf4769d01f4e880ce1a538785f.jpeg?size=256"
[bool] $PSEdition_Desktop = $true
[bool] $PSEdition_Core = $true

. "${PSScriptRoot}${ds}funcs${ds}Get-PackageSynopsis.ps1"
[string] $packageSynopsis = Get-PackageSynopsis

. "${PSScriptRoot}${ds}funcs${ds}Get-ModuleExports.ps1"
[hashtable] $moduleExports = Get-ModuleExports -Psm1Path "${PSScriptRoot}${ds}..${ds}src${ds}${PackageId}.psm1"

. "${PSScriptRoot}${ds}funcs${ds}Get-PackageTags.ps1"
[string[]] $packageTagsForNuSpec = Get-PackageTags -PackageId $PackageId -ForNuSpec -ModuleExports $moduleExports -PSEdition_Desktop:$PSEdition_Desktop -PSEdition_Core:$PSEdition_Core
[string[]] $packageTagsForPSData = Get-PackageTags -ForPSData

. "${PSScriptRoot}${ds}funcs${ds}Get-PackageCopyright.ps1"
[string] $packageCopyright = Get-PackageCopyright -LicenseFilePath $licenseFilePath

. "${PSScriptRoot}${ds}funcs${ds}Get-PackageGuid.ps1"
[string] $packageGuid = Get-PackageGuid

. "${PSScriptRoot}${ds}funcs${ds}Get-PSGalleryModuleNested.ps1"
[object[]] $nestedRuntimePSGalleryModules = @(Get-PSGalleryModuleNested -RuntimeDependencies)
[string] $packageVersion = $PackageVersionNuGet

. "${PSScriptRoot}${ds}funcs${ds}New-ModuleManifestCustomized.ps1"
[System.IO.FileInfo] $moduleManifest = New-ModuleManifestCustomized `
    -PackageId $PackageId `
    -CompanyName $companyName `
    -Authors $authors `
    -GitRepositoryUrl $repositoryGitUrl `
    -CommitSha $CommitSha `
    -ProjectUrl $projectUrl `
    -LicenseFileName $licenseFileName `
    -ReadmeFileName $readmeFileName `
    -PackageIconUrl $packageIconUrl `
    -PackageSynopsis $packageSynopsis `
    -PackageCopyright $packageCopyright `
    -PackageTags $packageTagsForNuSpec `
    -ReleaseNotes $ReleaseNotes `
    -PackageVersion $packageVersion `
    -PackageVersionMajorMinorPatchBuild $PackageVersionMajorMinorPatchBuild `
    -PackageVersionPrereleaseTag $PackageVersionPrereleaseTag `
    -PackageGuid $packageGuid `
    -PSEdition_Desktop:$PSEdition_Desktop `
    -PSEdition_Core:$PSEdition_Core `
    -NestedRuntimePSGalleryModules $nestedRuntimePSGalleryModules `
    -PathFromPsd1ParentToPsm1Parent ".${ds}src" # The psd1 will go into the root of the NuPkg, but the psm1 will stay in the `src` folder.

. "${PSScriptRoot}${ds}funcs${ds}New-TemporaryProjectFile.ps1"
[System.IO.FileInfo] $projectFile = New-TemporaryProjectFile `
    -PackageId $PackageId `
    -PackageVersion $packageVersion `
    -CompanyName $companyName `
    -Authors $authors `
    -GitRepositoryUrl $repositoryGitUrl `
    -CommitSha $CommitSha `
    -ProjectUrl $projectUrl `
    -LicenseFileName $licenseFileName `
    -ReadmeFileName $readmeFileName `
    -PackageIconUrl $packageIconUrl `
    -PackageSynopsis $packageSynopsis `
    -PackageCopyright $packageCopyright `
    -PackageTags $packageTagsForPSData `
    -ReleaseNotes $ReleaseNotes `
    -ModuleManifest $moduleManifest `
    -ModuleManifestPackageDir "." `
    -NestedRuntimePSGalleryModules $nestedRuntimePSGalleryModules
try {
    dotnet pack -c Release -o "${PSScriptRoot}${ds}..${ds}out" $projectFile.FullName
    if ($LASTEXITCODE -ne 0) {
        throw "`dotnet pack` failed, exit code '$LASTEXITCODE'."
    }
}
finally {
    Remove-Item -LiteralPath $projectFile.FullName -Force
}
