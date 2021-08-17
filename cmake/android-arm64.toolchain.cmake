set(CMAKE_SYSTEM_NAME "Android")
set(CMAKE_SYSTEM_VERSION 21)
set(CMAKE_ANDROID_ARCH_ABI "arm64-v8a")
set(ANDROID_PLATFORM "android-${CMAKE_SYSTEM_VERSION}")
set(ANDROID_ABI "${CMAKE_ANDROID_ARCH_ABI}")

include("${CMAKE_CURRENT_LIST_DIR}/android-common.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/android.toolchain.cmake")
