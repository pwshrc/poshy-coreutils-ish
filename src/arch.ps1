#!/usr/bin/env pwsh
using namespace System.Runtime.InteropServices
$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest


# See: https://www.gnu.org/software/coreutils/manual/html_node/arch-invocation.html
function arch {
    [Architecture] $arch = [RuntimeInformation]::ProcessArchitecture
    switch ( $arch ) {
        ([Architecture]::X64)         { return "x86_64"; }
        ([Architecture]::X86)         { return "i686"; }
        ([Architecture]::Arm)         { return "armv7l"; }
        ([Architecture]::Arm64)       { return "aarch64"; }
        ([Architecture]::Armv6)       { return "armv6l"; }
        ([Architecture]::LoongArch64) { return "loongarch64"; }
        ([Architecture]::Ppc64le)     { return "ppc64le"; }
        ([Architecture]::S390x)       { return "s390x"; }
        ([Architecture]::Wasm)        { return "wasm"; }
        default { throw [System.PlatformNotSupportedException]::new("Unknown architecture: $arch") }
    }
}
