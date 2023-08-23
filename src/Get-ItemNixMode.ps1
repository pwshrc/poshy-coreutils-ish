#!/usr/bin/env pwsh
$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest


if ($IsLinux) {
    function Get-ItemNixMode() {
        param(
            [Parameter(Mandatory = $true)]
            [string[]]
            $Path
        )
        Get-Item $Path | ForEach-Object { $_.UnixFileMode }
    }
} else {
    function Get-ItemNixMode() {
        throw [System.PlatformNotSupportedException]::new()
    }
}
