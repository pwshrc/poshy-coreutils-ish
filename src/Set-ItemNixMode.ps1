#!/usr/bin/env pwsh
$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest


if ($IsLinux) {
    function Set-ItemNixMode() {
        [System.Runtime.Versioning.UnsupportedOSPlatform("windows")]
        param(
            [Parameter(Mandatory = $true)]
            [string[]]
            $Path,

            [Parameter(Mandatory = $true)]
            # [ValidateScript({ ConvertTo-NixMode -FromOctal $_ })]
            [string] $ModeOctal
        )
        DynamicParam {
            # Add the ValidateScript attribute to the ModeOctal parameter, but
            # only if the UnixFileMode type is available.
            if ([Type]::GetType("System.IO.UnixFileMode")) {
                $Attribute = [System.Management.Automation.ValidateScriptAttribute]::new(
                    [ScriptBlock]::Create("ConvertTo-NixMode -FromOctal `$_")
                )
                $RuntimeParameterDictionary = [System.Management.Automation.RuntimeDefinedParameterDictionary]::new()
                $RuntimeParameterDictionary.Add(
                    "ModeOctal",
                    [System.Management.Automation.RuntimeDefinedParameter]::new(
                        "ModeOctal",
                        [string],
                        [System.Collections.ObjectModel.Collection[System.Attribute]]::new($Attribute)
                    )
                )
                return $RuntimeParameterDictionary
            }
        }
        Process {
            Get-Item $Path | ForEach-Object { chmod $ModeOctal $_.FullName } | Out-Null
        }
    }
} else {
    function Set-ItemNixMode() {
        throw [System.PlatformNotSupportedException]::new()
    }
}
