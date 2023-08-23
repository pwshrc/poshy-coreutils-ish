#!/usr/bin/env pwsh
$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest


# See: https://www.gnu.org/software/coreutils/manual/html_node/uname-invocation.html
function uname {
    throw [System.NotImplementedException]::new("TODO: Implement uname.")
}
