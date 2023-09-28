#!/usr/bin/env pwsh
$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest


<#
.SYNOPSIS
    Gets all but the last component of a path. If the path contains no directory separators, a dot ('.') is returned, indicating the current directory.
.DESCRIPTION
    See: https://www.gnu.org/software/coreutils/manual/html_node/dirname-invocation.html
#>
function dirname {
    param(
        [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true, ParameterSetName="Name")]
        [ValidateNotNull()]
        [string[]] $Name,

        [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true, ParameterSetName="InputObject")]
        [ValidateNotNull()]
        [System.IO.FileSystemInfo[]] $InputObject
    )
    if ($Name) {
        $Name | ForEach-Object { [System.IO.Path]::IsPathRooted($_) ? (Split-Path -Path $_ -Parent) : ((Split-Path -Path $_ -Parent) ?? ".") }
    } elseif ($InputObject) {
        $InputObject | ForEach-Object { $_.Parent }
    }
}
