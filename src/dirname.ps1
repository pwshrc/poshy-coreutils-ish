#!/usr/bin/env pwsh
$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest


# See: https://www.gnu.org/software/coreutils/manual/html_node/dirname-invocation.html
function dirname {
    param(
        [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
        [string[]] $Name
    )
    foreach ($item in $Name) {
        $directoryName = [System.IO.Path]::GetDirectoryName($item)
        if ($directoryName) {
            $directoryName
        } else {
            "."
        }
    }
}
