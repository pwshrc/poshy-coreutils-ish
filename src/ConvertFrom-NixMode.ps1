#!/usr/bin/env pwsh
$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest


if ([Type]::GetType("System.IO.UnixFileMode")) {
    <#
    .SYNOPSIS
        Converts a value from a strongly-typed [System.IO.UnixFileMode] enum value into other representations.
    .DESCRIPTION
        Converts a value from a strongly-typed [System.IO.UnixFileMode] enum value into other representations.
    .EXAMPLE
        ConvertFrom-NixMode -Mode [System.IO.UnixFileMode]::UserRead -ToOctal
    #>
    function ConvertTo-NixMode() {
        [System.Runtime.Versioning.SupportedOSPlatform("net7.0")]
        [CmdletBinding(DefaultParameterSetName="ToOctal")]
        [OutputType([string])]
        param(
            [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
            [System.IO.UnixFileMode] $Mode,

            [Parameter(Mandatory = $true, Position = 1, ParameterSetName = 'ToOctal')]
            [switch] $ToOctal
        )
        Process {
            if ($ToOctal) {
                return [Convert]::ToString([int]$Mode, 8)
            } else {
                throw [System.NotImplementedException]::new("Parameter set '$($PSCmdlet.ParameterSetName)' is not implemented.")
            }
        }
    }
} else {
    <#
    .SYNOPSIS
        Converts a value from an integer value into other representations.
    .DESCRIPTION
        Converts a value from an integer value into other representations.
    .EXAMPLE
        ConvertFrom-NixMode -Mode 8 -ToOctal
    #>
    function ConvertTo-NixMode() {
        [CmdletBinding(DefaultParameterSetName="ToOctal")]
        [OutputType([string])]
        param(
            [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
            [int] $Mode,

            [Parameter(Mandatory = $true, Position = 1, ParameterSetName = 'ToOctal')]
            [switch] $ToOctal
        )
        Process {
            if ($ToOctal) {
                return [Convert]::ToString([int]$Mode, 8)
            } else {
                throw [System.NotImplementedException]::new("Parameter set '$($PSCmdlet.ParameterSetName)' is not implemented.")
            }
        }
    }
}
