#!/usr/bin/env pwsh
$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest


# See: https://www.gnu.org/software/coreutils/manual/html_node/shuf-invocation.html
function shuf {
    param(
        [Parameter(Mandatory = $false, Position = 0)]
        [Nullable[int]] $HeadCount = $null,

        [Parameter(Mandatory = $true, Position = 1, ParameterSetName = "InputFile")]
        [object] $File,

        [Parameter(Mandatory = $true, Position = 1, ParameterSetName = "InputArgs")]
        [switch] $Echo,

        [Parameter(Mandatory = $true, Position = 1, ParameterSetName = "InputRange")]
        [uint] $Lo,

        [Parameter(Mandatory = $true, Position = 2, ParameterSetName = "InputRange")]
        [uint] $Hi,

        [Parameter(Mandatory = $false, Position = 2, ValueFromPipeline = $true, ParameterSetName = "InputStdin")]
        [Parameter(Mandatory = $true, Position = 2, ValueFromRemainingArguments = $true, ParameterSetName = "InputArgs")]
        [object[]] $InputObject = $null
    )
    if ($Echo -or $InputObject) {
        [long] $count = $InputObject.Length
        if ($headCount -and ($headCount.Value -lt $count)) {
            $count = $headCount
        }
        if ($headCount) {
            $InputObject | Get-Random -Count $count
        } else {
            $InputObject | Get-Random
        }
    } elseif ($File) {
        if ($headCount) {
            Get-Content $File | Get-Random -Count $headCount
        } else {
            Get-Content $File | Get-Random
        }
    } elseif ($Lo -or $Hi) {
        if ($headCount) {
            $Lo..$Hi | Get-Random -Count $headCount
        } else {
            $Lo..$Hi | Get-Random
        }
    } else {
        throw "shuf: no input specified"
    }
}
