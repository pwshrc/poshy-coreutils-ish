#!/usr/bin/env pwsh
$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest


function Set-ItemNixMode() {
    [System.Runtime.Versioning.UnsupportedOSPlatform("windows")]
    [CmdletBinding(DefaultParameterSetName="ModeOctal")]
    param(
        [Parameter(Mandatory = $false, Position = 1)]
        [switch] $PassThru,

        [Parameter(Mandatory = $false, Position = 2)]
        [Alias("Recursive")]
        [switch] $Recurse,

        [Parameter(Mandatory = $false, Position = 3)]
        [Alias("f", "silent", "quiet")]
        [switch] $Force,

        [Parameter(Mandatory = $true, Position = 5, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ValueFromRemainingArguments = $true)]
        [Alias("FullName", "PSPath")]
        [string[]]
        $Path
    )
    DynamicParam {
        $RuntimeParameterDictionary = [System.Management.Automation.RuntimeDefinedParameterDictionary]::new()

        # Add the "ModeOctal" parameter.
        $ParameterAttributesCollection = [System.Collections.ObjectModel.Collection[System.Attribute]]::new()
        $ModeOctalParameterAttribute = [System.Management.Automation.ParameterAttribute]::new()
        $ModeOctalParameterAttribute.Mandatory = $true
        $ModeOctalParameterAttribute.ParameterSetName = "ModeOctal"
        $ModeOctalParameterAttribute.Position = 4
        $ModeOctalParameterAttribute.HelpMessage = "The octal mode to set on the file(s)."
        $ParameterAttributesCollection.Add($ModeOctalParameterAttribute)
        if ([Type]::GetType("System.IO.UnixFileMode")) {
            # If the UnixFileMode type is available, add validation for this parameter.
            $ParameterAttributesCollection.Add([System.Management.Automation.ValidateScriptAttribute]::new(
                [ScriptBlock]::Create("ConvertTo-NixMode -FromOctal `$_")
            ))
        }
        $ModeOctalParameter = [System.Management.Automation.RuntimeDefinedParameter]::new("ModeOctal", [string], $ParameterAttributesCollection)
        $RuntimeParameterDictionary.Add($ModeOctalParameter.Name, $ModeOctalParameter)

        if ([Type]::GetType("System.IO.UnixFileMode")) {
            # Add the "Mode" parameter.
            $ParameterAttributesCollection = [System.Collections.ObjectModel.Collection[System.Attribute]]::new()
            $ModeParameterAttribute = [System.Management.Automation.ParameterAttribute]::new()
            $ModeParameterAttribute.Mandatory = $true
            $ModeParameterAttribute.ParameterSetName = "Mode"
            $ModeParameterAttribute.Position = 4
            $ModeParameterAttribute.HelpMessage = "The mode to set on the file(s)."
            $ParameterAttributesCollection.Add($ModeParameterAttribute)
            $ModeParameter = [System.Management.Automation.RuntimeDefinedParameter]::new("Mode", [System.IO.UnixFileMode], $ParameterAttributesCollection)
            $RuntimeParameterDictionary.Add($ModeParameter.Name, $ModeParameter)
        }

        return $RuntimeParameterDictionary
    }
    Begin {
        if ($IsWindows) {
            throw [System.PlatformNotSupportedException]::new("This function is not supported on Windows.")
        }
        function do_chmod {
            param(
                [Parameter(Mandatory = $true, Position = 0)]
                [string] $LiteralMode,

                [Parameter(Mandatory = $true, Position = 1)]
                [string] $LiteralPath
            )
            [string[]] $chmodArgs = @($LiteralMode, $LiteralPath)
            if ($Recurse) {
                $chmodArgs += '-R'
            }
            if ($Force) {
                $chmodArgs += '-f'
            }

            if ($PassThru) {
                chmod @chmodArgs | Out-Null
            } else {
                chmod @chmodArgs
            }

            if ($LASTEXITCODE -ne 0) {
                throw "Failed to set mode '$ModeOctal' on '$_', chmod exited with code $LASTEXITCODE."
            }
        }
    }
    Process {
        if ($PSCmdlet.MyInvocation.BoundParameters.ContainsKey('ModeOctal')) {
            $ModeOctal = $PSCmdlet.MyInvocation.BoundParameters['ModeOctal']
        } elseif ($PSCmdlet.MyInvocation.BoundParameters.ContainsKey('Mode')) {
            $Mode = ConvertFrom-NixMode -ToOctal $PSCmdlet.MyInvocation.BoundParameters['Mode']
        } else {
            throw [System.ArgumentException]::new("Either the 'ModeOctal' or 'Mode' parameter must be specified.")
        }

        if (Get-Variable -Name Mode -ErrorAction SilentlyContinue) {
            $ModeOctal = ConvertFrom-NixMode -ToOctal $Mode
        }

        @($PSCmdlet.MyInvocation.ExpectingInput ? $PSItem : $Path) | ForEach-Object {
            $parent = Split-Path -Path $_ -Parent
            $leaf = Split-Path -Path $_ -Leaf
            Get-ChildItem -Path $parent -Filter $leaf -Recurse:$Recurse -Force:$Force | ForEach-Object {
                do_chmod -LiteralMode $ModeOctal -LiteralPath $_.FullName
                if ($PassThru) {
                    $_.Refresh()
                    $_
                }
            }
        }
    }
}
