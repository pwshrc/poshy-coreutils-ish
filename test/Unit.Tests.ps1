#!/usr/bin/env pwsh
$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest


Describe "module" {
    It "should be importable" {
        $module = Import-Module $Global:SubjectModuleName -Force -DisableNameChecking -PassThru

        $module | Should -Not -BeNull
    }
}
