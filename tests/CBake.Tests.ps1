Describe 'CBake module' {
BeforeAll {
    $script:RepoRoot = Split-Path -Parent $PSScriptRoot
    $script:ModulePath = Join-Path $script:RepoRoot 'cbake.psm1'
    $script:CBakeEnvNames = @(
        'CBAKE_HOME',
        'CBAKE_CMAKE_DIR',
        'CBAKE_SYSROOTS_DIR',
        'CBAKE_PACKAGES_DIR',
        'CBAKE_RECIPES_DIR'
    )

    Import-Module $script:ModulePath -Force
}

BeforeEach {
    $script:SavedCBakeEnv = @{}

    foreach ($Name in $script:CBakeEnvNames) {
        $Item = Get-Item "Env:$Name" -ErrorAction 'SilentlyContinue'
        $script:SavedCBakeEnv[$Name] = if ($null -eq $Item) { $null } else { $Item.Value }
        Remove-Item "Env:$Name" -ErrorAction 'SilentlyContinue'
    }
}

AfterEach {
    foreach ($Name in $script:CBakeEnvNames) {
        if ($null -eq $script:SavedCBakeEnv[$Name]) {
            Remove-Item "Env:$Name" -ErrorAction 'SilentlyContinue'
        } else {
            Set-Item "Env:$Name" $script:SavedCBakeEnv[$Name]
        }
    }
}

Describe 'Get-CBakePath' {
    It 'returns the module root by default' {
        Get-CBakePath | Should -Be $script:RepoRoot
    }

    It 'honors CBAKE path overrides' {
        $ExpectedPaths = @{
            cmake = Join-Path $TestDrive 'custom-cmake'
            sysroots = Join-Path $TestDrive 'custom-sysroots'
            packages = Join-Path $TestDrive 'custom-packages'
            recipes = Join-Path $TestDrive 'custom-recipes'
        }

        $Env:CBAKE_CMAKE_DIR = $ExpectedPaths.cmake
        $Env:CBAKE_SYSROOTS_DIR = $ExpectedPaths.sysroots
        $Env:CBAKE_PACKAGES_DIR = $ExpectedPaths.packages
        $Env:CBAKE_RECIPES_DIR = $ExpectedPaths.recipes

        foreach ($PathName in $ExpectedPaths.Keys) {
            Get-CBakePath $PathName | Should -Be $ExpectedPaths[$PathName]
        }
    }
}

Describe 'Remove-CBakeExcludedFiles' {
    It 'removes excluded directories from the provided root path' {
        $RootPath = Join-Path $TestDrive 'sysroot'
        $ExcludedPath = Join-Path $RootPath 'usr\bin'
        $KeptPath = Join-Path $RootPath 'usr\include'
        New-Item -Path $ExcludedPath -ItemType Directory -Force | Out-Null
        New-Item -Path $KeptPath -ItemType Directory -Force | Out-Null

        Remove-CBakeExcludedFiles $RootPath

        Test-Path $ExcludedPath | Should -BeFalse
        Test-Path $KeptPath | Should -BeTrue
    }
}

Describe 'Invoke-CBakeNativeCommand' {
    It 'throws when a native command exits with a non-zero code' {
        $PwshPath = (Get-Command 'pwsh').Source

        {
            Invoke-CBakeNativeCommand -FilePath $PwshPath -ArgumentList @(
                '-NoLogo',
                '-NoProfile',
                '-Command',
                'exit 7'
            )
        } | Should -Throw '*failed with exit code 7*'
    }
}

Describe 'Import-CBakeSysroot' {
    BeforeEach {
        $script:PackagesPath = Join-Path $TestDrive 'packages'
        $script:SysrootsPath = Join-Path $TestDrive 'sysroots'
        New-Item -Path $script:PackagesPath -ItemType Directory -Force | Out-Null
        New-Item -Path $script:SysrootsPath -ItemType Directory -Force | Out-Null

        $Env:CBAKE_PACKAGES_DIR = $script:PackagesPath
        $Env:CBAKE_SYSROOTS_DIR = $script:SysrootsPath
    }

    It 'extracts packages through the checked native command wrapper' {
        $PackageFile = Join-Path $script:PackagesPath 'ubuntu-24.04-arm64-sysroot.tar.xz'
        New-Item -Path $PackageFile -ItemType File -Force | Out-Null
        Mock -ModuleName cbake Invoke-CBakeNativeCommand {}

        Import-CBakeSysroot -Distro 'ubuntu-24.04' -Arch 'arm64'

        Should -Invoke -CommandName Invoke-CBakeNativeCommand -ModuleName cbake -Exactly -Times 1 -ParameterFilter {
            $FilePath -eq 'tar' -and
                $ArgumentList[0] -eq 'xf' -and
                $ArgumentList[1] -eq $PackageFile -and
                $ArgumentList[2] -eq '-C' -and
                $ArgumentList[3] -eq $script:SysrootsPath
        }
    }
}

Describe 'New-CBakeSysroot' {
    BeforeEach {
        $script:RecipesPath = Join-Path $TestDrive 'recipes'
        $script:PackagesPath = Join-Path $TestDrive 'packages'
        New-Item -Path (Join-Path $script:RecipesPath 'ubuntu-24.04') -ItemType Directory -Force | Out-Null
        New-Item -Path $script:PackagesPath -ItemType Directory -Force | Out-Null

        $Env:CBAKE_RECIPES_DIR = $script:RecipesPath
        $Env:CBAKE_PACKAGES_DIR = $script:PackagesPath
    }

    It 'runs build, extract, optimize, and package steps without invoking external tools directly' {
        $PackageFile = Join-Path $script:PackagesPath 'ubuntu-24.04-arm64-sysroot.tar.xz'
        Mock -ModuleName cbake Invoke-CBakeNativeCommand {}
        Mock -ModuleName cbake Optimize-CBakeSysroot {}

        New-CBakeSysroot -Distro 'ubuntu-24.04' -Arch 'arm64'

        Should -Invoke -CommandName Invoke-CBakeNativeCommand -ModuleName cbake -Exactly -Times 1 -ParameterFilter {
            $FilePath -eq 'docker' -and
                $ArgumentList -contains 'buildx' -and
                $ArgumentList -contains 'linux/arm64' -and
                $ArgumentList -contains 'type=tar,dest=ubuntu-24.04-arm64.tar'
        }
        Should -Invoke -CommandName Invoke-CBakeNativeCommand -ModuleName cbake -Exactly -Times 1 -ParameterFilter {
            $FilePath -eq 'tar' -and
                $ArgumentList[0] -eq '-xf' -and
                $ArgumentList[1] -eq 'ubuntu-24.04-arm64.tar'
        }
        Should -Invoke -CommandName Invoke-CBakeNativeCommand -ModuleName cbake -Exactly -Times 1 -ParameterFilter {
            $FilePath -eq 'tar' -and
                $ArgumentList[0] -eq 'cfJ' -and
                $ArgumentList[1] -eq $PackageFile
        }
        Should -Invoke -CommandName Optimize-CBakeSysroot -ModuleName cbake -Exactly -Times 1
    }

    It 'restores the caller location when a checked native command fails' {
        $StartingLocation = (Get-Location).ProviderPath
        Mock -ModuleName cbake Invoke-CBakeNativeCommand {
            throw 'docker failed'
        } -ParameterFilter { $FilePath -eq 'docker' }

        { New-CBakeSysroot -Distro 'ubuntu-24.04' -Arch 'arm64' } | Should -Throw '*docker failed*'

        (Get-Location).ProviderPath | Should -Be $StartingLocation
    }
}
}
