#!/usr/bin/env pwsh
$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest


# See: https://www.gnu.org/software/coreutils/manual/html_node/readlink-invocation.html
function readlink {
    throw [System.NotImplementedException]::new("TODO: Implement readlink.")
}
