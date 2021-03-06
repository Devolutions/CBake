set(CMAKE_SYSTEM_NAME "iOS")
set(CMAKE_SYSTEM_VERSION 8.2)
set(IOS_DEPLOYMENT_TARGET "${CMAKE_SYSTEM_VERSION}")
set(CMAKE_OSX_ARCHITECTURES "arm64")

include("${CMAKE_CURRENT_LIST_DIR}/ios-common.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/ios.toolchain.cmake")