
function Convert-CBakeSymbolicLinks() {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string] $RootPath
    )

    $ReparsePoints = Get-ChildItem -LiteralPath $RootPath -Recurse |
        Where-Object { $_.Attributes -band [IO.FileAttributes]::ReparsePoint }
    $AbsSymlinks = $ReparsePoints | Where-Object {
        -not [string]::IsNullOrEmpty($_.LinkTarget) -and $_.LinkTarget.StartsWith('/')
    }
    $AbsSymlinks | ForEach-Object {
        $Source = $_.FullName
        $Directory = [IO.Path]::GetDirectoryName($Source)
        $IsDirectory = $_.PSIsContainer
        $Target = Join-Path $RootPath $_.LinkTarget.TrimStart('/')
        if (Test-Path -LiteralPath $Target) {
            $RelativeTarget = [IO.Path]::GetRelativePath($Directory, $Target)
            if ($IsLinux) {
                Invoke-CBakeNativeCommand -FilePath 'rm' -ArgumentList @('-f', '--', $Source)
            } else {
                Remove-Item -LiteralPath $Source | Out-Null
            }
            if ($IsDirectory) {
                [IO.Directory]::CreateSymbolicLink($Source, $RelativeTarget) | Out-Null
            } else {
                [IO.File]::CreateSymbolicLink($Source, $RelativeTarget) | Out-Null
            }
        } else {
            if ($IsLinux) {
                Invoke-CBakeNativeCommand -FilePath 'rm' -ArgumentList @('-f', '--', $Source)
            } else {
                Remove-Item -LiteralPath $Source -ErrorAction 'SilentlyContinue' | Out-Null
            }
        }
    }
}

function Remove-CBakeSymbolicLinks() {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string] $RootPath
    )

    $ReparsePoints = Get-ChildItem -LiteralPath $RootPath -Recurse |
        Where-Object { $_.Attributes -band [IO.FileAttributes]::ReparsePoint }
    $ReparsePoints | ForEach-Object {
        $Source = $_.FullName
        $Target = $_.ResolveLinkTarget($true).FullName
        if (-Not (Test-Path $Target)) {
            Remove-Item -LiteralPath $Source -ErrorAction 'SilentlyContinue' | Out-Null
        }
    }
}

function Invoke-CBakeNativeCommand() {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $FilePath,
        [Parameter()]
        [string[]] $ArgumentList = @()
    )

    Write-Host "$FilePath $($ArgumentList -Join ' ')"
    & $FilePath @ArgumentList
    $ExitCode = $LASTEXITCODE

    if ($ExitCode -ne 0) {
        throw "$FilePath failed with exit code $ExitCode"
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
        $ExcludeDir = Join-Path $RootPath $_.TrimStart('/', '\')
        if ($IsLinux -and (Test-Path -LiteralPath $ExcludeDir)) {
            Invoke-CBakeNativeCommand -FilePath 'chmod' -ArgumentList @('-R', 'u+w', '--', $ExcludeDir)
        }
        Remove-Item -LiteralPath $ExcludeDir -Recurse -Force -ErrorAction 'SilentlyContinue' | Out-Null
    }
}

function Optimize-CBakeSysroot() {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string] $RootPath
    )

    if ($IsLinux) {
        Invoke-CBakeNativeCommand -FilePath 'chmod' -ArgumentList @('-R', 'u+w', '--', $RootPath)
    }

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
    Invoke-CBakeNativeCommand -FilePath 'tar' -ArgumentList @('xf', $PackageFile, '-C', $SysrootsPath)
}

function Get-CBakeDockerPlatform {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $Arch
    )

    switch ($Arch) {
        'arm' { 'linux/arm/v7' }
        default { "linux/$Arch" }
    }
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

    $ContainerTarFile = $null
    Push-Location
    try {
        Set-Location $(Join-Path $(Get-CbakePath "recipes") $distro) -ErrorAction 'Stop'

        if ([string]::IsNullOrEmpty($ExportPath)) {
            $ExportPath = Join-Path $(Get-Location) "$distro-$arch"
        }
        Remove-Item -Path $ExportPath -Recurse -Force -ErrorAction 'SilentlyContinue' | Out-Null

        Write-Host "Building $distro-$arch container"
        $ContainerTarFile = "$distro-$arch.tar"
        Remove-Item -Path $ContainerTarFile -ErrorAction 'SilentlyContinue' | Out-Null

        $params = @('buildx',
            'build', '.',
            '-t', "$distro-$arch-sysroot",
            '--platform', (Get-CBakeDockerPlatform $Arch),
            '-o', "type=tar,dest=$ContainerTarFile")
        Invoke-CBakeNativeCommand -FilePath 'docker' -ArgumentList $Params
        New-Item -Path $ExportPath -ItemType Directory -ErrorAction 'SilentlyContinue' | Out-Null
        Invoke-CBakeNativeCommand -FilePath 'tar' -ArgumentList @('-xf', $ContainerTarFile, '-C', "$ExportPath")

        Write-Host "Optimizing $distro-$arch sysroot"
        Optimize-CBakeSysroot $ExportPath

        if (-Not $SkipPackaging) {
            Write-Host "Compressing $distro-$arch sysroot"
            $PackageFile = Join-Path $(Get-CbakePath "packages") "$distro-$arch-sysroot.tar.xz"
            Remove-Item -Path $PackageFile -Force -ErrorAction 'SilentlyContinue' | Out-Null
            Invoke-CBakeNativeCommand -FilePath 'tar' -ArgumentList @('cfJ', $PackageFile, "$distro-$arch")
        }
    } finally {
        if (-Not [string]::IsNullOrEmpty($ContainerTarFile)) {
            Remove-Item -Path $ContainerTarFile -ErrorAction 'SilentlyContinue' | Out-Null
        }
        Pop-Location
    }
}
