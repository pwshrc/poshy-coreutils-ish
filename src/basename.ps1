#!/usr/bin/env pwsh
$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest


# See: https://www.gnu.org/software/coreutils/manual/html_node/basename-invocation.html
function basename {
    param(
        [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
        [string[]] $Name,

        [Parameter(Mandatory=$false, Position=1)]
        [string] $Suffix = $null
    )
    if ($Suffix) {
        $Name | ForEach-Object { $_.TrimEnd($Suffix) }
    } else {
        $Name | ForEach-Object { $_.TrimEnd([System.IO.Path]::GetExtension($_)) }
    }
}
