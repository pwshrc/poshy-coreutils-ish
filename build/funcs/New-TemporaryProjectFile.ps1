#!/usr/bin/env pwsh
$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest


# Create a temporary project file. We'll use this for packaging.
function New-TemporaryProjectFile {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $PackageId,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $PackageVersion,

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
        [ValidateScript({ Test-Path -Path $_ -PathType Leaf })]
        [System.IO.FileInfo] $ModuleManifest,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $ModuleManifestPackageDir,

        [Parameter(Mandatory = $false)]
        [object[]] $NestedRuntimePSGalleryModules = @()
    )

    [string] $ds = [System.IO.Path]::DirectorySeparatorChar
    function Get-IconPath {
        [string] $packageIconLocalPath = "${PSScriptRoot}${ds}..${ds}..${ds}out${ds}icon.jpeg"
        Invoke-WebRequest -Uri $PackageIconUrl -OutFile $packageIconLocalPath | Out-Null
        return $packageIconLocalPath
    }
    [string] $iconPath = (Get-IconPath)
    $iconPath = Resolve-Path -Path $iconPath -Relative
    $iconFileName = [System.IO.Path]::GetFileName($iconPath)

    # Properties: https://learn.microsoft.com/en-us/nuget/create-packages/package-authoring-best-practices
    # also: https://learn.microsoft.com/en-us/nuget/reference/msbuild-targets
    # and also: https://learn.microsoft.com/en-us/dotnet/core/project-sdk/msbuild-props
    [string] $psgalleryNugetFeed = "https://www.powershellgallery.com/api/v2"
    [hashtable] $properties = @{
        "TargetFramework" = "netstandard2.0"
        "AppendTargetFrameworkToOutputPath" = "false"
        "AppendRuntimeIdentifierToOutputPath" = "false"
        "NoBuild" = "true"
        "IncludeBuildOutput" = "false"
        "PackageId" = $PackageId
        "Version" = $PackageVersion
        "PackageVersion" = $PackageVersion
        "Company" = $CompanyName
        "Authors" = ($Authors -join "; ")
        "RepositoryUrl" = $GitRepositoryUrl
        "RepositoryType" = "git"
        "RepositoryCommit" = $CommitSha
        "PackageProjectUrl" = $ProjectUrl
        "PackageLicenseFile" = $LicenseFileName
        "PackageReadmeFile" = $ReadmeFileName
        "PackageIcon" = $iconFileName
        "PackageIconUrl" = $packageIconUrl  # Deprecated to have _only_ PackageIconUrl. Use both for max compat.
        "Description" = $packageSynopsis
        "Copyright" = $PackageCopyright
        "PackageTags" = ($PackageTags -join " ")
        "PackageRequireLicenseAcceptance" = "false"
        "AdditionalRestoreSources" = "`$(AdditionalRestoreSources);${psgalleryNugetFeed}"
    }
    if (-not [string]::IsNullOrWhiteSpace($ReleaseNotes)) {
        $properties["PackageReleaseNotes"] = $ReleaseNotes
    }
    [System.Xml.XmlElement] $propertyGroupElement = ([xml]"<PropertyGroup></PropertyGroup>").ChildNodes[0]
    $properties.Keys `
    | ForEach-Object {
        [System.Xml.XmlElement] $element = $propertyGroupElement.OwnerDocument.CreateElement($_)
        [System.Xml.XmlText] $textNode = $element.OwnerDocument.CreateTextNode($properties[$_])
        $element.AppendChild($textNode) | Out-Null
        $propertyGroupElement.AppendChild($element) | Out-Null
    }
    [string] $moduleManifestFilePath = Resolve-Path -Path $ModuleManifest -Relative
    [string] $nugetizerVersion = "0.9.2" # Pin to avoid SponsorLink
    [string] $moduleManifestFilePackagePath = Join-Path -Path $ModuleManifestPackageDir -ChildPath "${PackageId}.psd1"

    [System.Xml.XmlElement[]] $itemGroupElementsForNestedRuntimePSGalleryModules = @()
    if ($NestedRuntimePSGalleryModules) {
        $itemGroupElementsForNestedRuntimePSGalleryModules += @(
            $NestedRuntimePSGalleryModules | ForEach-Object {
                [System.Xml.XmlElement] $element = $propertyGroupElement.OwnerDocument.CreateElement("None")
                $element.SetAttribute("Include", "lib${ds}$($_.id).$($_.version)${ds}**${ds}*.*")
                $element.SetAttribute("Pack", "true")
                $element.SetAttribute("PackagePath", "lib${ds}$($_.id).$($_.version)${ds}")
                $element
            }
        )
    }

    [string] $projectFile = "${PSScriptRoot}${ds}..${ds}..${ds}${PackageId}.csproj"
    New-Item -Path $projectFile -ItemType File -Force | Out-Null
    Set-Content -Path $projectFile -Value "<Project Sdk=`"Microsoft.NET.Sdk`">
    $($propertyGroupElement.OuterXml)
    <ItemGroup>
        <PackageReference Include=`"NuGetizer`" Version=`"${nugetizerVersion}`" /> <!-- Pin to avoid SponsorLink -->
    </ItemGroup>
    <ItemGroup>
        <None Include=`"src${ds}**${ds}*.*`" Pack=`"true`" />
        <None Include=`"${LicenseFileName}`" Pack=`"true`" />
        <None Include=`"${ReadmeFileName}`" Pack=`"true`" />
        <None Include=`"${iconPath}`" Pack=`"true`" PackagePath=`"${iconFileName}`" />
        <None Include=`"${moduleManifestFilePath}`" Pack=`"true`" PackagePath=`"${moduleManifestFilePackagePath}`" />
        <None Remove=`"lib${ds}**${ds}*.*`" />
        $($itemGroupElementsForNestedRuntimePSGalleryModules | ForEach-Object { $_.OuterXml })
        <None Remove=`"lib${ds}**${ds}README.*`" />
        <None Remove=`"lib${ds}**${ds}*.nupkg`" />
    </ItemGroup>
    <ItemGroup>
        <Content Remove=`"**${ds}*.*`" />
    </ItemGroup>
</Project>"
    return Get-Item -Path $projectFile
}
