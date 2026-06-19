# CBake

CBake (cross-bake) is a lightweight toolkit for building and using cross-compilation environments. It combines Docker-built Linux sysroots, CMake toolchain files, PowerShell helpers, and LLVM/Clang so projects can target Linux distributions and common mobile or desktop platforms from a consistent workflow.

## What is included

| Area | Contents |
| --- | --- |
| Linux sysroots | Docker recipes for Ubuntu, Debian, RHEL, and Alpine, plus PowerShell commands to package and import sysroots |
| CMake toolchains | Entry points for Linux, Android, iOS, and Windows targets |
| Cargo support | CMake logic that generates Cargo environment files for Rust cross-compilation with the active CMake toolchain |
| Automation | GitHub Actions workflows for building sysroot artifacts and publishing release assets |

## Repository layout

```text
.
|-- build.ps1              # CLI wrapper for CBake commands
|-- cbake.psm1             # PowerShell module with sysroot helpers
|-- cargo/                 # Cargo environment generation for CMake builds
|-- cmake/                 # Cross-compilation toolchain files
|-- packages/              # Generated sysroot archives, ignored by git
|-- recipes/               # Docker build recipes for Linux sysroots
`-- sysroots/              # Imported sysroots, ignored by git
```

## Prerequisites

Install the tools for the workflows you plan to use:

| Workflow | Required tools |
| --- | --- |
| All CBake commands | [PowerShell 7](https://github.com/PowerShell/PowerShell#get-powershell) |
| Linux sysroot builds | Docker with [buildx](https://docs.docker.com/buildx/working-with-buildx/), QEMU/binfmt for non-native architectures, `tar`, and `xz` |
| C/C++ cross-compilation | [CMake](https://cmake.org/download/), [Ninja](https://ninja-build.org/), and [LLVM/Clang](https://llvm.org/) with `llvm-config` on `PATH` |
| Android targets | Android NDK and `ANDROID_NDK` pointing to the NDK root |
| iOS targets | Xcode command-line tools on macOS |
| Windows targets | MSVC/Windows SDK on Windows, or the provided clang-cl/MSVC wrapper flow on other hosts |
| Tests | Pester 5 for the PowerShell test suite |

Sysroot creation should run on a Linux filesystem. On Windows, use WSL2 for the Docker build and packaging steps.

## Quick start

Clone the repository and import the PowerShell module:

```powershell
$Env:CBAKE_HOME = (Get-Location).Path
Import-Module (Join-Path $Env:CBAKE_HOME 'cbake.psm1') -Force
Get-CBakePath
```

Build and import a Linux sysroot:

```powershell
New-CBakeSysroot -Distro 'ubuntu-24.04' -Arch 'arm64'
Import-CBakeSysroot -Distro 'ubuntu-24.04' -Arch 'arm64'
```

The packaged archive is written to `packages\ubuntu-24.04-arm64-sysroot.tar.xz`, and the imported sysroot is expanded under `sysroots\ubuntu-24.04-arm64`.

You can also use the command wrapper:

```powershell
.\build.ps1 sysroot -Distro 'ubuntu-24.04' -Arch 'arm64'
```

## Supported Linux sysroot recipes

The GitHub Actions matrix currently builds each recipe for `amd64` and `arm64`:

| Family | Recipes |
| --- | --- |
| Ubuntu | `ubuntu-18.04`, `ubuntu-20.04`, `ubuntu-22.04`, `ubuntu-24.04` |
| Debian | `debian-10`, `debian-11`, `debian-12` |
| RHEL | `rhel8`, `rhel9` |
| Alpine | `alpine-3.17`, `alpine-3.21` |

To add a distribution, create a new directory under `recipes\` with a Dockerfile and update the workflow matrix if CI should build it.

## Cross-compile a CMake project for Linux

After importing a sysroot, configure your project with CBake's Linux toolchain:

```powershell
$ToolchainFile = Join-Path (Join-Path $Env:CBAKE_HOME 'cmake') 'linux.toolchain.cmake'
cmake -S . -B build\ubuntu-24.04-arm64 -G Ninja `
    -DCMAKE_TOOLCHAIN_FILE="$ToolchainFile" `
    -DSYSROOT_NAME='ubuntu-24.04-arm64' `
    -DCMAKE_BUILD_TYPE=Release
cmake --build build\ubuntu-24.04-arm64
```

`SYSROOT_NAME` selects a directory under `sysroots\`. CBake infers the target architecture from the sysroot name and configures Clang, LLD, libgcc, libstdc++, and pkg-config paths from the imported sysroot.

With CMake 3.21 or newer, you can also set the `CMAKE_TOOLCHAIN_FILE` environment variable instead of passing `-DCMAKE_TOOLCHAIN_FILE` every time.

## Other CMake toolchains

Use the target-specific files in `cmake\` when building for non-Linux platforms:

| Platform | Toolchain entry points |
| --- | --- |
| Android | `android-arm.toolchain.cmake`, `android-arm64.toolchain.cmake`, `android-x86.toolchain.cmake`, `android-x86_64.toolchain.cmake` |
| iOS | `ios-arm.toolchain.cmake`, `ios-arm64.toolchain.cmake`, `ios-armv7.toolchain.cmake`, `ios-x86_64.toolchain.cmake` |
| Linux | `linux-amd64.toolchain.cmake`, `linux-arm64.toolchain.cmake`, `linux.toolchain.cmake` |
| Windows | `windows-x86.toolchain.cmake`, `windows-x64.toolchain.cmake`, `windows-arm64.toolchain.cmake` |

Example:

```powershell
$ToolchainFile = Join-Path (Join-Path $Env:CBAKE_HOME 'cmake') 'android-arm64.toolchain.cmake'
cmake -S . -B build\android-arm64 -G Ninja -DCMAKE_TOOLCHAIN_FILE="$ToolchainFile"
cmake --build build\android-arm64
```

## Cargo environment generation

The `cargo\CMakeLists.txt` helper emits Cargo-compatible environment files under `$CARGO_HOME\cbake` for the active CMake target. It prepares linker, `cc-rs`, `pkg-config-rs`, and `cmake-rs` variables so Rust crates can reuse the same sysroot and compiler settings as CMake.

Generated files include:

| File | Purpose |
| --- | --- |
| `<target>.env` | dotenv-compatible environment variables |
| `<target>-enter.sh` / `<target>-leave.sh` | shell scripts to enter and leave the Cargo environment |
| `<target>-enter.ps1` / `<target>-leave.ps1` | PowerShell scripts to enter and leave the Cargo environment |

Set `CARGO_CBAKE_DIR` or `CARGO_CBAKE_NAME` during CMake configuration to customize where these files are written and how they are named.

## Configuration

CBake resolves paths through environment variables, falling back to folders inside this repository:

| Variable | Default |
| --- | --- |
| `CBAKE_HOME` | repository root |
| `CBAKE_CMAKE_DIR` | `CBAKE_HOME\cmake` |
| `CBAKE_SYSROOTS_DIR` | `CBAKE_HOME\sysroots` |
| `CBAKE_PACKAGES_DIR` | `CBAKE_HOME\packages` |
| `CBAKE_RECIPES_DIR` | `CBAKE_HOME\recipes` |

Use these overrides when sysroot archives or imported sysroots need to live outside the checkout.

## Development

Run the focused checks before submitting PowerShell or workflow changes:

```powershell
pwsh -NoLogo -NoProfile -Command "Import-Module .\cbake.psm1 -Force; Get-CBakePath"
pwsh -NoLogo -NoProfile -Command "Invoke-Pester -Path .\tests -CI"
```

The Pester tests mock Docker and tar interactions, so they do not build sysroots or require Docker to be running.

## CI and releases

`cbake sysroots` is a manually dispatched workflow that builds every distro and architecture combination in the recipe matrix and uploads each sysroot archive as an artifact.

`cbake release` is a manually dispatched workflow that downloads artifacts from a successful sysroot workflow run, writes SHA-256 checksums, and publishes a GitHub release. If no version is supplied, it uses a date-based version in the form `yyyy.MM.dd.0`.

## Troubleshooting

| Symptom | Check |
| --- | --- |
| `SYSROOT_NAME not defined` | Pass `-DSYSROOT_NAME='<distro>-<version>-<arch>'` or set the `SYSROOT_NAME` environment variable. |
| `CMAKE_SYSROOT directory does not exist` | Run `Import-CBakeSysroot` for the selected sysroot or point `CMAKE_SYSROOT` at an existing imported sysroot. |
| `LLVM prefix could not be found` | Install LLVM/Clang and ensure `llvm-config` is on `PATH`, or pass `-DLLVM_PREFIX=<path>`. |
| Android configure fails with `ANDROID_NDK is not set` | Set `ANDROID_NDK` to the Android NDK root before running CMake. |
| Docker buildx fails for `arm64` on an `amd64` host | Install and enable QEMU/binfmt support before building non-native images. |

## License

CBake is distributed under the MIT license. See [LICENSE](LICENSE).
