#!/usr/bin/env pwsh

Import-Module "$Env:CBAKE_HOME/cbake.psm1" -Force

New-CBakeSysroot @args
