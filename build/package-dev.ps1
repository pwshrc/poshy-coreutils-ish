#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Take all the PowerShell module content in ../src and package it as a NuPkg. (But only for local development purposes.)
#>
param(
)
$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest


[string] $gitversion_bin = $null
if (Get-Command dotnet-gitversion -ErrorAction SilentlyContinue) {
    $gitversion_bin = Get-Command dotnet-gitversion
}
elseif (Get-Command gitversion -ErrorAction SilentlyContinue) {
    $gitversion_bin = Get-Command gitversion
}

if ($gitversion_bin) {
    [PSObject] $versionInfo = & $gitversion_bin | ConvertFrom-Json

    [string] $paddedNumberFormatPattern = "0000"
    [string] $prereleaseLabelShortened = ($versionInfo.PreReleaseLabel.Length -gt 16) ? $versionInfo.PreReleaseLabel.Substring(0, 16) : $versionInfo.PreReleaseLabel
    # TODO: Verify 'PreReleaseNumber' is correct suffix. Ambiguous from historical documentation found at https://github.com/GitTools/GitVersion/blob/v4.0.0/docs/more-info/variables.md.
    [Nullable[int]] $preReleaseNumber = $versionInfo.PreReleaseNumber -as [int]
    if ($preReleaseNumber -and $versionInfo.PreReleaseLabel) {
      [string] $LegacySemVer = $versionInfo.MajorMinorPatch + "-" + $versionInfo.PreReleaseLabel + $preReleaseNumber
      [string] $LegacySemVerPadded = $versionInfo.MajorMinorPatch + "-" + $prereleaseLabelShortened + $preReleaseNumber.ToString($paddedNumberFormatPattern)
    } else {
      [string] $LegacySemVer = $versionInfo.MajorMinorPatch
      [string] $LegacySemVerPadded = $versionInfo.MajorMinorPatch
    }
    [string] $PackageVersion = $LegacySemVerPadded

    [string] $PackageVersionPrereleaseTag = $versionInfo | Select-Object -ExpandProperty PreReleaseTag
    [string] $assemblySemVer = $versionInfo | Select-Object -ExpandProperty AssemblySemVer
    [string] $CommitSha = $versionInfo | Select-Object -ExpandProperty Sha
} else {
    [string] $PackageVersion = "0.0.1"
    [string] $PackageVersionPrereleaseTag = $null
    [string] $assemblySemVer = "0.0.1"
    [string] $CommitSha = (git rev-parse HEAD)
}
[string] $ReleaseNotes = "Fake Release Notes"

if (-not $PackageVersionPrereleaseTag) {
    $PackageVersion += "-dev"
    $PackageVersionPrereleaseTag = "dev"
} else {
    $PackageVersion = $PackageVersion.Replace("-" + $PackageVersionPrereleaseTag, "-dev-" + $PackageVersionPrereleaseTag)
    $PackageVersionPrereleaseTag = "dev-" + $PackageVersionPrereleaseTag
}

if (-not $PackageVersionPrereleaseTag) {
    [Version] $moduleVersion = [Version] $assemblySemVer
} else {
    [Version] $moduleVersion = [Version] ($assemblySemVer -replace "-$PackageVersionPrereleaseTag", "")
}

[string] $ds = [System.IO.Path]::DirectorySeparatorChar
& "${PSScriptRoot}${ds}package.ps1" `
    -PackageVersion $PackageVersion `
    -ModuleVersion $moduleVersion `
    -PackageVersionPrereleaseTag $PackageVersionPrereleaseTag `
    -ReleaseNotes $ReleaseNotes `
    -CommitSha $CommitSha
