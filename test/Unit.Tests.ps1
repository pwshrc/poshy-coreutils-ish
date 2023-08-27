#!/usr/bin/env pwsh
#Requires -Modules "Pester"
$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest



BeforeAll {
    . "$PSScriptRoot/_BeforeAll.ps1"
}

Describe "module" {
    It "should be importable" {
        [PSModuleInfo] $module = Import-Module $Global:SubjectModule -Force -DisableNameChecking -NoClobber -PassThru

        $module | Should -Not -BeNull
    }
}

AfterAll {
    . "$PSScriptRoot/_AfterAll.ps1"
}
