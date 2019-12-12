set(CMAKE_SYSTEM_PROCESSOR aarch64)
set(CMAKE_SIZEOF_VOID_P 8)

set(CROSS_TRIPLET "aarch64-linux-gnu")

include("${CMAKE_CURRENT_LIST_DIR}/linux.toolchain.cmake")
