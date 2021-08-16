# CBake

```powershell
Import-Module .\cbake.psm1 -Force
$distros = Get-ChildItem $(Get-CbakePath 'recipes') | Select-Object -ExpandProperty Name
$distros | ForEach-Object { New-CBakeSysroot -Distro $_ -Arch 'arm64' }
```
