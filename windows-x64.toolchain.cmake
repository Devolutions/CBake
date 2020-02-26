set(CMAKE_SYSTEM_NAME Windows)
set(CMAKE_SYSTEM_PROCESSOR x86_64)

set(VSCMD_ARG_HOST_ARCH "x64")
set(VSCMD_ARG_TGT_ARCH "x64")

include("${CMAKE_CURRENT_LIST_DIR}/windows-msvc.toolchain.cmake")
