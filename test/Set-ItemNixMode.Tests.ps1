#!/usr/bin/env pwsh
#Requires -Modules "Pester"
$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest


BeforeAll {
    $SutFile = Get-Item "$PSScriptRoot/../src/Set-ItemNixMode.ps1"
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

                Context "for an existing file" {
                    BeforeEach {
                        $targetFile = New-TemporaryFile

                        function ConvertTo-NixMode { $true }
                    }

                    AfterEach {
                        Remove-Item $targetFile.FullName -Force
                    }

                    Context "ModeOctal is 700" {
                        It "should set the UnixFileMode" {
                            $modeOctalParameter = '700'
                            [System.IO.UnixFileMode] $expectedMode = [System.IO.UnixFileMode]::UserRead -bor [System.IO.UnixFileMode]::UserWrite -bor [System.IO.UnixFileMode]::UserExecute

                            Set-ItemNixMode -Path $targetFile -ModeOctal $modeOctalParameter

                            $targetFile.Refresh()
                            $targetFile.UnixFileMode | Should -Be $expectedMode
                        }
                    }

                    Context "ModeOctal is 555" {
                        It "should set the UnixFileMode" {
                            $modeOctalParameter = '555'
                            [System.IO.UnixFileMode] $expectedMode = [System.IO.UnixFileMode]::GroupRead -bor [System.IO.UnixFileMode]::GroupExecute -bor [System.IO.UnixFileMode]::OtherRead -bor [System.IO.UnixFileMode]::OtherExecute -bor [System.IO.UnixFileMode]::UserRead -bor [System.IO.UnixFileMode]::UserExecute

                            Set-ItemNixMode -Path $targetFile -ModeOctal $modeOctalParameter

                            $targetFile.Refresh()
                            $targetFile.UnixFileMode | Should -Be $expectedMode
                        }
                    }

                    Context "ModeOctal is 644" {
                        It "should set the UnixFileMode" {
                            $modeOctalParameter = '644'
                            [System.IO.UnixFileMode] $expectedMode = [System.IO.UnixFileMode]::UserRead -bor [System.IO.UnixFileMode]::UserWrite -bor [System.IO.UnixFileMode]::GroupRead -bor [System.IO.UnixFileMode]::OtherRead

                            Set-ItemNixMode -Path $targetFile -ModeOctal $modeOctalParameter

                            $targetFile.Refresh()
                            $targetFile.UnixFileMode | Should -Be $expectedMode
                        }
                    }
                }
            }
        }
    }
}
