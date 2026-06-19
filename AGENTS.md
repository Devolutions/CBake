# AGENTS.md

Guidance for agents and automation working in this repository.

## Project focus

CBake is a PowerShell and CMake toolkit for cross-compilation. The core responsibilities are:

- Build Linux sysroots from Docker recipes in `recipes\`.
- Package sysroots in `packages\` and import them into `sysroots\`.
- Provide CMake toolchain files in `cmake\` for Linux, Android, iOS, and Windows.
- Generate Cargo environment files through `cargo\CMakeLists.txt`.

## Important files

| Path | Purpose |
| --- | --- |
| `cbake.psm1` | PowerShell module with `Get-CBakePath`, `New-CBakeSysroot`, and `Import-CBakeSysroot`. |
| `build.ps1` | Thin command wrapper around the module. |
| `cmake\linux.toolchain.cmake` | Main Linux cross-compilation setup. |
| `cmake\*-*.toolchain.cmake` | Target-specific CMake entry points. |
| `cargo\CMakeLists.txt` | Cargo environment generation for the active CMake target. |
| `tests\CBake.Tests.ps1` | Lightweight Pester coverage for PowerShell helper behavior. |
| `.github\workflows\cbake-sysroots.yml` | Manual sysroot build workflow matrix. |
| `.github\workflows\cbake-release.yml` | Manual release workflow for sysroot artifacts. |

## Development rules

- Keep generated sysroot content out of git. `packages\` and `sysroots\` should only contain ignored build artifacts.
- Treat Docker sysroot builds as expensive and host-sensitive. Do not run full matrix builds unless explicitly requested.
- Preserve cross-platform PowerShell compatibility. Prefer PowerShell 7 syntax and avoid Windows-only path assumptions inside scripts unless guarded.
- Keep CMake toolchain changes narrowly scoped. Target-specific files should set only target identity and include the shared platform toolchain.
- Use existing path resolution through `Get-CBakePath` and the `CBAKE_*` environment variables instead of hard-coded repository paths.
- When adding a Linux recipe, update the README and the `cbake-sysroots` workflow matrix if CI should build it.

## Validation

For documentation-only changes, no build is required.

For PowerShell changes, at minimum run:

```powershell
pwsh -NoLogo -NoProfile -Command "Import-Module .\cbake.psm1 -Force; Get-CBakePath"
pwsh -NoLogo -NoProfile -Command "Invoke-Pester -Path .\tests -CI"
```

The Pester tests mock Docker and tar calls; do not replace them with full sysroot builds unless the task explicitly requires it.

For Linux toolchain changes, validate with an imported sysroot when available:

```powershell
$ToolchainFile = Join-Path (Join-Path $Env:CBAKE_HOME 'cmake') 'linux.toolchain.cmake'
cmake -S <project> -B <build-dir> -G Ninja `
    -DCMAKE_TOOLCHAIN_FILE="$ToolchainFile" `
    -DSYSROOT_NAME='<distro>-<version>-<arch>'
cmake --build <build-dir>
```

For workflow changes, inspect the target workflow and prefer a manual `workflow_dispatch` dry run or a small single-target reproduction before expanding to the full sysroot matrix.

## Common pitfalls

- `SYSROOT_NAME` must follow the `<distro>-<version>-<arch>` naming used by imported sysroot directories.
- `cmake\linux.toolchain.cmake` depends on `llvm-config`, Clang, LLD, libgcc, libstdc++, and pkg-config paths being discoverable.
- Android builds require `ANDROID_NDK`; iOS builds require macOS/Xcode tooling.
- The Cargo helper writes files under `$CARGO_HOME\cbake` by default. Override `CARGO_CBAKE_DIR` for temporary or isolated runs.
