#!/usr/bin/env pwsh

Import-Module "$Env:CBAKE_HOME/cbake.psm1" -Force

function Invoke-TlkBuild {
    param(
        [Parameter(Mandatory=$true,Position=0)]
        [string] $Distro,
        [Parameter(Mandatory=$true,Position=1)]
        [string] $Arch
    )

    New-CBakeSysroot -Distro $Distro -Arch $Arch
}

Invoke-TlkBuild @args
