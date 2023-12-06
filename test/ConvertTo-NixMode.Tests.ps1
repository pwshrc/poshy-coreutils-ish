#!/usr/bin/env pwsh
#Requires -Modules "Pester"
$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest


BeforeAll {
    $SutFile = Get-Item "$PSScriptRoot/../src/ConvertTo-NixMode.ps1"
    $SutName = $SutFile.BaseName
}

Describe "SUT file" {
    It "should exist" {
        $SutFile | Should -Exist
    }

    It "should be sourceable" {
        { . $SutFile.FullName } | Should -Not -Throw
    }

    Context "when sourced" {
        BeforeEach {
            . $SutFile
        }

        Describe "function" {
            BeforeDiscovery {
                $FileModeSettingNotSupported = $IsWindows -or ($null -eq [Type]::GetType("System.IO.UnixFileMode"))
            }

            It "should be defined" {
                Get-Command -Name $SutName -CommandType Function | Should -Not -BeNullOrEmpty
            }

            Context "when invoked" -Skip:$FileModeSettingNotSupported {
                Context "with no arguments" {
                    It "should throw" {
                        { & $SutName } | Should -Throw
                    }
                }

                Context "via parameter" {
                    # single integer matching a UnixFileMode value
                    Context "single input is integer-equivalent [System.IO.UnixFileMode] value" {
                        It "should return the value as-is" {
                            $parameterValue = [int][Convert]::ToString([int][System.IO.UnixFileMode]::GroupExecute, 8)
                            $expectedResult = [System.IO.UnixFileMode]::GroupExecute

                            $actualResult = ConvertTo-NixMode -FromOctal $parameterValue

                            $actualResult | Should -BeOfType [System.IO.UnixFileMode]
                            $actualResult | Should -Be $expectedResult
                        }
                    }

                    # single integer that should have been parsed as base8
                    Context "single input is integer wrongly parsed as base10 instead of base8" {
                        It "should return the value converted" {
                            $parameterValue = [int]700
                            $expectedResult = [System.IO.UnixFileMode]([Convert]::ToInt32('700', 8))

                            $actualResult = ConvertTo-NixMode -FromOctal $parameterValue

                            $actualResult | Should -BeOfType [System.IO.UnixFileMode]
                            $actualResult | Should -Be $expectedResult
                        }
                    }

                    # single integer string matching a UnixFileMode value as-is
                    Context "single input is an integer string matching a [System.IO.UnixFileMode] value as-is" {
                        It "should return the value as-is" {
                            $parameterValue = [Convert]::ToString([int][System.IO.UnixFileMode]::GroupExecute, 8)
                            $expectedResult = [System.IO.UnixFileMode]::GroupExecute

                            $actualResult = ConvertTo-NixMode -FromOctal $parameterValue

                            $actualResult | Should -BeOfType [System.IO.UnixFileMode]
                            $actualResult | Should -Be $expectedResult
                        }
                    }
                }
            }
        }
    }
}
