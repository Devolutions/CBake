#!/usr/bin/env pwsh

if (-Not (Test-Path Env:CBAKE_HOME)) {
    $Env:CBAKE_HOME = $PSScriptRoot
}

Import-Module "$Env:CBAKE_HOME/cbake.psm1" -Force

$CmdVerbs = @('sysroot')

if ($args.Count -lt 1) {
    throw "not enough arguments!"
}

$CmdVerb = $args[0]
$CmdArgs = $args[1..$args.Count]

if ($CmdVerbs -NotContains $CmdVerb) {
    throw "invalid verb $CmdVerb, use one of: [$($CmdVerbs -Join ',')]"
}

switch ($CmdVerb) {
    "sysroot" { New-CBakeSysroot @CmdArgs }
}
