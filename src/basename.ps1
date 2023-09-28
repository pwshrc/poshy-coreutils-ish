#!/usr/bin/env pwsh
$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest


<#
.SYNOPSIS
    Gets the last component(s) of the given path(s), optionally removing a suffix if specified.
.DESCRIPTION
    See: https://www.gnu.org/software/coreutils/manual/html_node/basename-invocation.html
#>
function basename {
    param(
        [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true, ParameterSetName="Name")]
        [ValidateNotNull()]
        [string[]] $Name,

        [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true, ParameterSetName="InputObject")]
        [ValidateNotNull()]
        [System.IO.FileSystemInfo[]] $InputObject,

        [Parameter(Mandatory=$false, Position=1)]
        [Alias("s")]
        [ValidateNotNull()]
        [string] $Suffix = $null
    )
    if ($Name) {
        if ($Suffix) {
            $Name | ForEach-Object { Split-Path -Path $_ -Leaf } | ForEach-Object { $_.TrimEnd($Suffix) }
        } else {
            $Name | ForEach-Object { Split-Path -Path $_ -Leaf }
        }
    } elseif ($InputObject) {
        if ($Suffix) {
            $InputObject | ForEach-Object { $_.Name } | ForEach-Object { $_.TrimEnd($Suffix) }
        } else {
            $InputObject | ForEach-Object { $_.Name }
        }
    }
}
