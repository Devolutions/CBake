
function Convert-CBakeSymbolicLinks() {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string] $RootPath
    )

    $ReparsePoints = Get-ChildItem $RootPath -Recurse |
        Where-Object { $_.Attributes -band [IO.FileAttributes]::ReparsePoint }
    $AbsSymlinks = $ReparsePoints | Where-Object { $_.LinkTarget.StartsWith('/') }
    $AbsSymlinks | ForEach-Object {
        $Source = $_.FullName
        $Directory = $_.Directory
        $Target = Join-Path $RootPath $_.LinkTarget
        if (Test-Path $Target) {
            Push-Location
            Set-Location $Directory
            $Target = Resolve-Path -Path $Target -Relative
            Remove-Item $Source | Out-Null
            New-Item -ItemType SymbolicLink -Path $Source -Target $Target | Out-Null
            Pop-Location
        } else {
            Remove-Item -LiteralPath $Source -ErrorAction 'SilentlyContinue' | Out-Null
        }
    }
}

function Remove-CBakeSymbolicLinks() {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string] $RootPath
    )

    $ReparsePoints = Get-ChildItem $RootPath -Recurse |
        Where-Object { $_.Attributes -band [IO.FileAttributes]::ReparsePoint }
    $ReparsePoints | ForEach-Object {
        $Source = $_.FullName
        $Target = $_.ResolveLinkTarget($true).FullName
        if (-Not (Test-Path $Target)) {
            Remove-Item -LiteralPath $Source -ErrorAction 'SilentlyContinue' | Out-Null
        }
    }
}

function Remove-CBakeExcludedFiles() {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string] $RootPath
    )

    $ExcludeDirs = @(
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
        '/usr/src',
        '/usr/libexec',
        '/usr/local/bin',
        '/usr/local/sbin',
        '/usr/local/games',
        '/usr/local/share',
        '/usr/local/src',
        '/usr/local'
    )

    $ExcludeDirs | ForEach-Object {
        $ExcludeDir = Join-Path $ExportPath $_
        Remove-Item -Path $ExcludeDir -Recurse -Force -ErrorAction 'SilentlyContinue' | Out-Null
    }
}

function Optimize-CBakeSysroot() {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string] $RootPath
    )

    Convert-CBakeSymbolicLinks $RootPath
    Remove-CBakeExcludedFiles $RootPath

    # remove dead symbolic links
    Remove-CBakeSymbolicLinks $RootPath
}

function Get-CbakePath() {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [ValidateSet("home", "cmake", "sysroots", "packages", "recipes")]
        [string] $PathName = "home"
    )

    $CBakeHome = $PSScriptRoot

    if (Test-Path Env:CBAKE_HOME) {
        $CbakeHome = $Env:CBAKE_HOME
    }

    switch ($PathName) {
        "home" {
            $CBakeHome
        } "cmake" {
            if (Test-Path Env:CBAKE_CMAKE_DIR) {
                $Env:CBAKE_CMAKE_DIR
            } else {
                Join-Path $CBakeHome "cmake"
            }
        } "sysroots" {
            if (Test-Path Env:CBAKE_SYSROOTS_DIR) {
                $Env:CBAKE_SYSROOTS_DIR
            } else {
                Join-Path $CBakeHome "sysroots"
            }
        } "packages" {
            if (Test-Path Env:CBAKE_PACKAGES_DIR) {
                $Env:CBAKE_PACKAGES_DIR
            } else {
                Join-Path $CBakeHome "packages"
            }
        } "recipes" {
            if (Test-Path Env:CBAKE_RECIPES_DIR) {
                $Env:CBAKE_RECIPES_DIR
            } else {
                Join-Path $CBakeHome "recipes"
            }
        }
    }
}

function Import-CBakeSysroot {
    param(
        [Parameter(Mandatory = $true)]
        [string] $Distro,
        [Parameter(Mandatory = $true)]
        [string] $Arch
    )

    $PackageFile = Join-Path $(Get-CbakePath "packages") "$distro-$arch-sysroot.tar.xz"

    if (-Not (Test-Path $PackageFile)) {
        throw "$PackageFile cannot be found!"
    }

    $SysrootsPath = Get-CbakePath "sysroots"
    $SysrootPath = Join-Path $SysrootsPath "$distro-$arch"
    Remove-Item -Path $SysrootPath -Recurse -Force -ErrorAction 'SilentlyContinue' | Out-Null
    & 'tar' 'xf' $PackageFile '-C' $SysrootsPath
}

function New-CBakeSysroot {
    param(
        [Parameter(Mandatory = $true)]
        [Alias("Distribution")]
        [string] $Distro,
        [Parameter(Mandatory = $true)]
        [Alias("Architecture")]
        [string] $Arch,
        [string] $ExportPath,
        [switch] $SkipPackaging
    )

    Push-Location
    Set-Location $(Join-Path $(Get-CbakePath "recipes") $distro) -ErrorAction 'Stop'

    if ([string]::IsNullOrEmpty($ExportPath)) {
        $ExportPath = Join-Path $(Get-Location) "$distro-$arch"
    }
    Remove-Item -Path $ExportPath -Recurse -Force -ErrorAction 'SilentlyContinue' | Out-Null

    Write-Host "Building $distro-$arch container"
    Remove-Item -Path "$distro-$arch.tar" -ErrorAction 'SilentlyContinue' | Out-Null

    $params = @('buildx',
        'build', '.',
        '-t', "$distro-$arch-sysroot",
        '--platform', "linux/$arch",
        '-o', "`"type=tar,dest=$distro-$arch.tar`"")
    Write-Host "docker $($params -Join ' ')"
    Start-Process -FilePath 'docker' -ArgumentList $Params -Wait
    New-Item -Path $ExportPath -ItemType Directory -ErrorAction 'SilentlyContinue' | Out-Null
    & 'tar' '-xf' "$distro-$arch.tar" '-C' "$ExportPath"
    Remove-Item -Path "$distro-$arch.tar" -ErrorAction 'SilentlyContinue' | Out-Null

    Write-Host "Optimizing $distro-$arch sysroot"
    Optimize-CBakeSysroot $ExportPath

    if (-Not $SkipPackaging) {
        Write-Host "Compressing $distro-$arch sysroot"
        $PackageFile = Join-Path $(Get-CbakePath "packages") "$distro-$arch-sysroot.tar.xz"
        Remove-Item -Path $PackageFile -Force -ErrorAction 'SilentlyContinue' | Out-Null
        & 'tar' 'cfJ' $PackageFile "$distro-$arch"
        Pop-Location
    }
}
