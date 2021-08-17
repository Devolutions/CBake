# CBake

CBake (cross-bake) is a project meant to simplify the creation of cross-compilation environments between major platforms using a combination of [clang+llvm](https://llvm.org/) and common developer tools.

## Prerequisites

 * [PowerShell 7](https://github.com/PowerShell/PowerShell#get-powershell)
 * [Docker buildx](https://docs.docker.com/buildx/working-with-buildx)
 * [CMake (latest)](https://cmake.org/download/)
 * [Ninja build](https://github.com/ninja-build/ninja/releases)
 * [clang+llvm (12+)](https://github.com/llvm/llvm-project/releases)

 Clone this repository anywhere you like, and then set the CBAKE_HOME environment variable to point to it.

## Linux sysroot creation

The first step is to create cross-compilation sysroots for major Linux distributions using Docker buildx. This part should be done on a Linux filesystem, so either use a Linux host or WSL2 on Windows. The recipes are nothing more than Dockerfiles installing the packages you want to be part of the target sysroot.

```powershell
Import-Module $Env:CBAKE_HOME/cbake.psm1 -Force
$distros = Get-ChildItem $(Get-CbakePath 'recipes') | Select-Object -ExpandProperty Name
$distros | ForEach-Object { New-CBakeSysroot -Distro $_ -Arch 'arm64' }
$distros | ForEach-Object { Import-CBakeSysroot -Distro $_ -Arch 'arm64' }
```

The packaged sysroots are packaged in the "packages" directory, after which they can be reused without having to rebuild them from source. The sysroots are imported under the "sysroots" directory for cross-compilation.

## Linux cross-compilation

Once you have built and imported a few sysroots, you can try cross-compiling the [Ninja build system](https://ninja-build.org/) executable to all targets using the provided Linux [CMake](https://cmake.org/) toolchain file. Clone the ninja sources and then move into the directory:

```bash
git clone git://github.com/ninja-build/ninja.git
cd "ninja"
```

In a Linux environment, one can generate makefiles for a given target (Ubuntu 18.04 arm64) using CMake:

```bash
export CMAKE_TOOLCHAIN_FILE="$CBAKE_HOME/cmake/linux.toolchain.cmake"
mkdir build-cross && cd build-cross
cmake -DCMAKE_TOOLCHAIN_FILE="$CMAKE_TOOLCHAIN_FILE" -DSYSROOT_NAME="ubuntu-18.04-arm64" ..
make
```

If the project generation and compilation succeeded, you can then verify that the `ninja` executable is indeed cross-compiled to ARM64:

```bash
$ file ninja
ninja: ELF 64-bit LSB executable, ARM aarch64, version 1 (SYSV), dynamically linked, interpreter /lib/ld-linux-aarch64.so.1, for GNU/Linux 3.7.0, not stripped
````

Congratulations! You have successfully cross-compiled your first project. The CMAKE_TOOLCHAIN_FILE command-line parameter is not required with CMake 3.21 or later if the [CMAKE_TOOLCHAIN_FILE environment variable](https://cmake.org/cmake/help/latest/envvar/CMAKE_TOOLCHAIN_FILE.html) is set - this can save a lot of typing.

You can go a step further and automate the cross-compilation of to all targets in PowerShell with this more elaborate sample:

```powershell
New-Item -Path "build" -ItemType 'Directory' -ErrorAction 'SilentlyContinue' | Out-Null
Set-Location "build"
$SysrootNames = Get-ChildItem $(Get-CbakePath 'sysroots') | Select-Object -ExpandProperty Name
foreach ($SysrootName in $SysrootNames) {
    New-Item -Path $SysrootName -ItemType 'Directory' -ErrorAction 'SilentlyContinue' | Out-Null
    Set-Location $SysrootName
    $ToolchainFile = Join-Path $(Get-CBakePath 'cmake') "linux.toolchain.cmake"
    $CMakeOptions = @("-G", "Ninja",
        "-DCMAKE_TOOLCHAIN_FILE=\"$ToolchainFile\"",
        "-DSYSROOT_NAME=$SysrootName",
        "-DCMAKE_BUILD_TYPE=Release")
    Write-Host 'cmake' $CMakeOptions "../.."
    & 'cmake' $CMakeOptions "../.."
    & 'cmake' '--build' '.'
    Set-Location ".."
}
Set-Location ".."
```
