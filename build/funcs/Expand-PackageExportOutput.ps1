#!/usr/bin/env pwsh
$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest


function Expand-PackageExportOutput {
    param(
    )

    [string] $ds = [System.IO.Path]::DirectorySeparatorChar
    [string] $out = "${PSScriptRoot}${ds}..${ds}..${ds}out"

    [string] $psgalleryNupkgName = $null
    [string] $psgalleryNupkgBaseName = $null
    [string] $psgalleryNupkgFullname = $null

    # Find the NuPkg.
    [System.IO.FileInfo[]] $outputPsgalleryNupkgs = @()
    $outputPsgalleryNupkgs = @(Get-ChildItem -Path $out -Filter "*.nupkg" -Recurse -File -Force)
    if ($outputPsgalleryNupkgs.Count -eq 0) {
        throw "No nupkg files were found in '$out'. Did you forgot to build?"
    } elseif ($outputPsgalleryNupkgs.Count -gt 1) {
        throw "Multiple nupkg files were found in '$out'. Did you forget to clean?"
    } else {
        $psgalleryNupkgName = $outputPsgalleryNupkgs[0].Name
        $psgalleryNupkgBaseName = $outputPsgalleryNupkgs[0].BaseName
        $psgalleryNupkgFullname = $outputPsgalleryNupkgs[0].FullName
    }

    # Expand the NuPkg.
    Write-Information "Expanding '$psgalleryNupkgFullname'."
    [string] $moduleLocation = "${out}${ds}${psgalleryNupkgBaseName}"
    if (Test-Path $moduleLocation -ErrorAction SilentlyContinue) {
        Remove-Item -Path $moduleLocation -Recurse -Force | Out-Null
    }
    Expand-Archive -Path $psgalleryNupkgFullname -DestinationPath $moduleLocation -Force | Out-Null
    $moduleLocation = Resolve-Path -Path $moduleLocation

    # Find the psd1 file that matches the NuPkg.
    Write-Information "Determining the psd1 file that matches '$psgalleryNupkgName'."
    [System.IO.FileInfo] $psd1 = $null
    $psd1 = `
        Get-ChildItem -Path $moduleLocation -Filter "*.psd1" -Recurse -File -Force `
        | Sort-Object -Property FullName `
        | Where-Object {
            [hashtable] $psd1Data = Import-PowerShellDataFile -Path $_.FullName
            [string] $moduleName = $_.BaseName
            if (-not $psd1Data.PrivateData.ContainsKey('PackageVersion')) {
                return $false
            }
            [string] $packageVersion = $psd1Data.PrivateData.PackageVersion
            return "${moduleName}.${packageVersion}" -eq $psgalleryNupkgBaseName
        } `
        | Select-Object -First 1
    if ($null -eq $psd1) {
        throw "No psd1 file was found in '$moduleLocation' that matches '$psgalleryNupkgName'."
    }

    # Move the expanded NuPkg to the psd1's name, which is a requirement before it can be imported.
    Write-Information "Renaming folder '$moduleLocation' to match the module name."
    [string] $newModuleLocation = $null
    $newModuleLocation = Join-Path -Path (Split-Path $moduleLocation -Parent) -ChildPath $psd1.BaseName
    if (Test-Path $newModuleLocation -ErrorAction SilentlyContinue) {
        Remove-Item -Path $newModuleLocation -Recurse -Force | Out-Null
    }
    $moduleLocation = (Rename-Item -Path $moduleLocation -NewName $psd1.BaseName -Force -PassThru).FullName
    $psd1 = Get-ChildItem -Path (Join-Path -Path $moduleLocation -ChildPath $psd1.Name) -File -Force | Select-Object -First 1
    return $psd1
}
