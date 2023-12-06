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
            [ValidateScript({ ConvertTo-NixMode -FromOctal $_ })]
            [string] $ModeOctal
        )
        Get-Item $Path | ForEach-Object { chmod $ModeOctal $_.FullName } | Out-Null
    }
} else {
    function Set-ItemNixMode() {
        throw [System.PlatformNotSupportedException]::new()
    }
}
