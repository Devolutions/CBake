#!/usr/bin/env pwsh

function Convert-SymbolicLinks() {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true,Position=0)]
        [string] $RootPath
    )

    $ReparsePoints = Get-ChildItem $RootPath -Recurse | `
        Where-Object { $_.Attributes -band [IO.FileAttributes]::ReparsePoint }
    $AbsSymlinks = $ReparsePoints | Where-Object { $_.Target -NotLike "$RootPath/*" }
    $AbsSymlinks | ForEach-Object {
        $Source = $_.FullName
        $Target = Join-Path $RootPath $_.Target
        if (Test-Path $Target) {
            Push-Location
            Set-Location $_.Directory
            $Target = Resolve-Path -Path $Target -Relative
            Remove-Item $Source | Out-Null
            New-Item -ItemType SymbolicLink -Path $Source -Target $Target | Out-Null
            Pop-Location
        } else {
            Remove-Item -LiteralPath $Source -ErrorAction 'SilentlyContinue' | Out-Null
        }
    }
}

function Remove-ExcludedFiles() {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true,Position=0)]
        [string] $RootPath
    )

    $exclude_dirs = @(
        '/bin',
        '/boot',
        '/etc',
        '/dev',
        '/home',
        '/mnt',
        '/media',
        '/opt',
        '/proc',
        '/root',
        '/run',
        '/sbin',
        '/srv',
        '/sys',
        '/tmp',
        '/var',
        '/selinux',
        '/usr/bin',
        '/usr/sbin',
        '/usr/games',
        '/usr/share',
        '/usr/src',
        '/usr/libexec',
        '/usr/local/bin',
        '/usr/local/sbin',
        '/usr/local/games',
        '/usr/local/share',
        '/usr/local/src',
        '/usr/local')

    foreach ($exclude_dir in $exclude_dirs) {
        $exclude_dir = Join-Path $ExportPath $exclude_dir
        Remove-Item -Path $exclude_dir -Recurse -Force -ErrorAction 'SilentlyContinue' | Out-Null
    }
}

function Optimize-Sysroot() {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true,Position=0)]
        [string] $RootPath
    )

    Convert-SymbolicLinks $RootPath
    Remove-ExcludedFiles $RootPath
}

function New-Sysroot {
	param(
		[Parameter(Mandatory=$true)]
		[string] $Distro,
        [Parameter(Mandatory=$true)]
		[string] $Arch
	)

    Push-Location
    Set-Location $distro
    $ImageName = "$distro-sysroot"
    $ExportPath = Join-Path $(Get-Location) "$distro-$arch"
    Remove-Item -Path $ExportPath -Recurse -Force -ErrorAction 'SilentlyContinue' | Out-Null

    Write-Host "Building $distro-$arch container"
    & 'docker' 'buildx' 'build' '.' `
        '-t' $ImageName `
        '--platform' "linux/$arch" `
        '-o' "$distro-$arch"

    Write-Host "Optimizing $distro-arch sysroot"
    Optimize-Sysroot $ExportPath

    Write-Host "Compressing $distro-$arch sysroot"
    Remove-Item -Path "$distro-$arch-sysroot.tar.xz" -Force -ErrorAction 'SilentlyContinue' | Out-Null
    & 'tar' 'cfJ' "$distro-$arch-sysroot.tar.xz" "$distro-$arch"
    Pop-Location
}

New-Sysroot @args
