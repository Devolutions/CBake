set(CMAKE_SYSTEM_NAME "Android")
set(CMAKE_SYSTEM_VERSION 16)
set(CMAKE_ANDROID_ARCH_ABI "x86")
set(ANDROID_PLATFORM "android-${CMAKE_SYSTEM_VERSION}")
set(ANDROID_ABI "${CMAKE_ANDROID_ARCH_ABI}")

include("${CMAKE_CURRENT_LIST_DIR}/android-common.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/android.toolchain.cmake")
