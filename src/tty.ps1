#!/usr/bin/env pwsh
$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest


# See: https://www.gnu.org/software/coreutils/manual/html_node/tty-invocation.html
function tty {
    throw [System.NotImplementedException]::new("TODO: Implement tty.")
}
