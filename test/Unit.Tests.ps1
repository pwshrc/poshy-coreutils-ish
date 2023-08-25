#!/usr/bin/env pwsh
$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest


Describe "module" {
    It "should be importable" {
        [PSModuleInfo] $module = Import-Module $Global:SubjectModule -Force -DisableNameChecking -PassThru

        $module | Should -Not -BeNull
    }
}
