#!/usr/bin/env pwsh
$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest


# See: https://www.gnu.org/software/coreutils/manual/html_node/sha2-utilities.html
function sha512sum {
    throw [System.NotImplementedException]::new("TODO: Implement sha512sum.")
}
