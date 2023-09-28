#!/usr/bin/env pwsh
$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest


<#
.DESCRIPTION
    See: https://www.gnu.org/software/coreutils/manual/html_node/mkfifo-invocation.html
#>
function mkfifo {
    throw [System.NotImplementedException]::new("TODO: Implement mkfifo.")
}
