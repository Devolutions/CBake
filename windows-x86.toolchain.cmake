set(CMAKE_SYSTEM_NAME Windows)
set(CMAKE_SYSTEM_PROCESSOR i686)

set(HOST_ARCH "x64")
set(TARGET_ARCH "x86")

include("${CMAKE_CURRENT_LIST_DIR}/windows-msvc.toolchain.cmake")
