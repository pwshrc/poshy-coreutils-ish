#!/usr/bin/env pwsh
$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest


if ($IsLinux) {
    function Set-ItemNixMode() {
        param(
            [Parameter(Mandatory = $true)]
            [string[]]
            $Path,
            [Parameter(Mandatory = $true)]
            [System.IO.UnixFileMode]
            $Mode
        )
        [string] $modeInOctal = [Convert]::ToString($Mode, 8)
        Get-Item $Path | ForEach-Object { chmod $modeInOctal $_.FullName } | Out-Null
    }
} else {
    function Set-ItemNixMode() {
        throw [System.PlatformNotSupportedException]::new()
    }
}
