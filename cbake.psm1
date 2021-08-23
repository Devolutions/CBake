
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

function Optimize-CBakeSysroot() {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true,Position=0)]
        [string] $RootPath
    )

    Convert-SymbolicLinks $RootPath
    Remove-ExcludedFiles $RootPath

    # remove dead symbolic links again
    Convert-SymbolicLinks $RootPath
}

function Get-CbakePath() {
    [CmdletBinding()]
	param(
        [Parameter(Position=0)]
        [ValidateSet("home","cmake","sysroots","packages","recipes")]
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
		[Parameter(Mandatory=$true)]
		[string] $Distro,
        [Parameter(Mandatory=$true)]
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
		[Parameter(Mandatory=$true)]
		[string] $Distro,
        [Parameter(Mandatory=$true)]
		[string] $Arch,
        [string] $ExportPath,
        [switch] $SkipPackaging
	)

    Push-Location
    $ImageName = "$distro-sysroot"
    Set-Location $(Join-Path $(Get-CbakePath "recipes") $distro) -ErrorAction 'Stop'

    if ([string]::IsNullOrEmpty($ExportPath)) {
        $ExportPath = Join-Path $(Get-Location) "$distro-$arch"
    }
    Remove-Item -Path $ExportPath -Recurse -Force -ErrorAction 'SilentlyContinue' | Out-Null

    Write-Host "Building $distro-$arch container"
    & 'docker' 'buildx' 'build' '.' `
        '-t' $ImageName `
        '--platform' "linux/$arch" `
        '-o' $ExportPath

    if ($LASTEXITCODE -ne 0) {
        throw "Error building $ImageName container image"
    }

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
