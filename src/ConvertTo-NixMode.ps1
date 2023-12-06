#!/usr/bin/env pwsh
$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest


if ([Type]::GetType("System.IO.UnixFileMode")) {
    <#
    .SYNOPSIS
        Converts a value to a strongly-typed [System.IO.UnixFileMode] enum value.
    .DESCRIPTION
        Converts a value to a strongly-typed [System.IO.UnixFileMode] enum value.
    .EXAMPLE
        ConvertTo-NixMode -FromOctal 755
    #>
    function ConvertTo-NixMode() {
        [System.Runtime.Versioning.SupportedOSPlatform("net7.0")]
        [CmdletBinding()]
        [OutputType([System.IO.UnixFileMode])]
        param(
            [Parameter(Mandatory = $true, Position = 0, ParameterSetName = 'FromOctal')]
            [ValidateNotNullOrEmpty()]
            [string] $FromOctal,

            [Parameter(Mandatory = $true, Position = 0, ParameterSetName = 'FromDecimal')]
            [ValidateNotNullOrEmpty()]
            [int] $FromDecimal
        )
        Begin {
            function Factor-EnumValue() {
                [OutputType([System.IO.UnixFileMode])]
                param(
                    [Parameter(Mandatory = $true)]
                    [int]
                    $Value
                )
                $value = [int]$Value
                $result = [System.IO.UnixFileMode]::None

                foreach ($enumValue in [System.Enum]::GetValues([System.IO.UnixFileMode])) {
                    if (($value -band $enumValue) -eq $enumValue) {
                        $result = $result -bor $enumValue
                        $value = $value -bxor $enumValue
                    }
                }

                if ($value -ne 0) {
                    throw [System.ArgumentException]::new("Unable to interpret value '$FromDecimal' as a value of [System.IO.UnixFileMode].")
                } else {
                    return $result
                }
            }

            if ($FromOctal) {
                $FromDecimal = [Convert]::ToInt32($FromOctal, 8)
            }
        }
        Process {
            return (Factor-EnumValue $FromDecimal)
        }
    }
} else {
    <#
    .SYNOPSIS
        Converts a value to a strongly-typed [System.IO.UnixFileMode] enum value.
    .DESCRIPTION
        Converts a value to a strongly-typed [System.IO.UnixFileMode] enum value.
    .EXAMPLE
        ConvertTo-NixMode -FromOctal 755
    #>
    function ConvertTo-NixMode() {
        [System.Runtime.Versioning.SupportedOSPlatform("net7.0")]
        [CmdletBinding()]
        # [OutputType([System.IO.UnixFileMode])]
        param(
            [Parameter(Mandatory = $true, Position = 0, ParameterSetName = 'FromOctal')]
            [ValidateNotNullOrEmpty()]
            [string] $FromOctal,

            [Parameter(Mandatory = $true, Position = 0, ParameterSetName = 'FromDecimal')]
            [ValidateNotNullOrEmpty()]
            [int] $FromDecimal
        )
        Begin {
            throw [System.PlatformNotSupportedException]::new()
        }
        Process {
        }
    }
}
