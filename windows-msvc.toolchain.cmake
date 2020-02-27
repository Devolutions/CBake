
set(WIN32 TRUE)
set(MSVC TRUE)

set(PROGRAM_FILES_X86_STR "PROGRAMFILES(X86)")
file(TO_CMAKE_PATH "$ENV{${PROGRAM_FILES_X86_STR}}" PROGRAM_FILES_X86)

set(VCToolsVersion "14.24.28314")
set(VCINSTALLDIR "${PROGRAM_FILES_X86}/Microsoft Visual Studio/2019/Community/VC/")
set(VCToolsInstallDir "${VCINSTALLDIR}Tools/MSVC/${VCToolsVersion}/")

set(VCToolsPath "${VCToolsInstallDir}bin/Host${HOST_ARCH}/${TARGET_ARCH}/")

# Detect WindowsSdkDir ("C:\Program Files (x86)\Windows Kits\10\")
# Computer\HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Windows Kits\Installed Roots;KitsRoot10
# Computer\HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Microsoft SDKs\Windows\v10.0;InstallationFolder
get_filename_component(KITS_ROOT_10
	"[HKEY_LOCAL_MACHINE\\SOFTWARE\\WOW6432Node\\Microsoft\\Microsoft SDKs\\Windows\\v10.0;InstallationFolder]" ABSOLUTE CACHE)
file(TO_CMAKE_PATH "${KITS_ROOT_10}" WindowsSdkDir)
string(APPEND WindowsSdkDir "/")

# Detect Windows SDK version (10.0.18362)
file(GLOB WINSDKVER_HEADERS LIST_DIRECTORIES TRUE "${WindowsSdkDir}include/10.*/um/winsdkver.h")
foreach(WINSDKVER_HEADER ${WINSDKVER_HEADERS})
	string(REGEX MATCH "include/(10\\.[0-9\\.]+\\.[0-9\\.]+\\.[0-9\\.]+)/um/winsdkver.h" _MATCH "${WINSDKVER_HEADER}")
	set(WINSDK_VERSION ${CMAKE_MATCH_1})
endforeach()

set(WindowsSdkVersion "${WINSDK_VERSION}/")
set(WindowsSdkLibVersion "${WINSDK_VERSION}/")
set(WindowsSdkVerBinPath "${WindowsSdkDir}bin/${WindowsSdkVersion}")
set(WindowsSdkToolsPath "${WindowsSdkVerBinPath}${HOST_ARCH}/")

# Detect NETFXSDKDir ("C:\Program Files (x86)\Windows Kits\NETFXSDK\4.8\")
# Computer\HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Microsoft SDKs\NETFXSDK\4.8
get_filename_component(NETFXSDK_KITS_INSTALLATION_FOLDER
	"[HKEY_LOCAL_MACHINE\\SOFTWARE\\WOW6432Node\\Microsoft\\Microsoft SDKs\\NETFXSDK\\4.8;KitsInstallationFolder]" ABSOLUTE CACHE)
file(TO_CMAKE_PATH "${NETFXSDK_KITS_INSTALLATION_FOLDER}" NETFXSDKDir)
string(APPEND NETFXSDKDir "/")

set(CMAKE_C_COMPILER "${VCToolsPath}cl.exe" CACHE FILEPATH "")
set(CMAKE_CXX_COMPILER "${VCToolsPath}cl.exe" CACHE FILEPATH "")
set(CMAKE_LINKER "${VCToolsPath}link.exe" CACHE FILEPATH "")
set(CMAKE_RC_COMPILER "${WindowsSdkToolsPath}rc.exe" CACHE FILEPATH "")
set(CMAKE_MT "${WindowsSdkToolsPath}mt.exe" CACHE FILEPATH "")

# LIB, LIBPATH, INCLUDE, PATH

set(LIB
	"${VCToolsInstallDir}ATLMFC/lib/${TARGET_ARCH}"
	"${VCToolsInstallDir}lib/${TARGET_ARCH}"
	"${NETFXSDKDir}lib/um/${TARGET_ARCH}"
	"${WindowsSdkDir}lib/${WindowsSdkLibVersion}ucrt/${TARGET_ARCH}"
	"${WindowsSdkDir}lib/${WindowsSdkLibVersion}um/${TARGET_ARCH}"
	)

set(LIBPATH
	"${VCToolsInstallDir}ATLMFC/lib/${TARGET_ARCH}"
	"${VCToolsInstallDir}lib/${TARGET_ARCH}"
	"${VCToolsInstallDir}lib/${TARGET_ARCH}/x86/store/references"
	"${WindowsSdkDir}UnionMetadata/${WindowsSdkLibVersion}"
	"${WindowsSdkDir}References/${WindowsSdkLibVersion}"
	)

set(INCLUDE
	"${VCToolsInstallDir}ATLMFC/include"
	"${VCToolsInstallDir}include"
	"${NETFXSDKDir}include/um"
	"${WindowsSdkDir}include/${WindowsSdkLibVersion}ucrt"
	"${WindowsSdkDir}include/${WindowsSdkLibVersion}shared"
	"${WindowsSdkDir}include/${WindowsSdkLibVersion}um"
	"${WindowsSdkDir}include/${WindowsSdkLibVersion}winrt"
	"${WindowsSdkDir}include/${WindowsSdkLibVersion}cppwinrt"
	)

set(CMAKE_C_STANDARD_INCLUDE_DIRECTORIES ${INCLUDE})
set(CMAKE_CXX_STANDARD_INCLUDE_DIRECTORIES ${INCLUDE})
set(CMAKE_RC_STANDARD_INCLUDE_DIRECTORIES ${INCLUDE})

set(CMAKE_C_IMPLICIT_LINK_DIRECTORIES ${LIB})
set(CMAKE_CXX_IMPLICIT_LINK_DIRECTORIES ${LIB})
set(CMAKE_RC_IMPLICIT_LINK_DIRECTORIES ${LIB})

set(LIB_ENV "")
foreach(_PATH ${LIB})
	file(TO_NATIVE_PATH "${_PATH}" _PATH)
	set(LIB_ENV "${LIB_ENV}${_PATH};")
endforeach()

set(LIBPATH_ENV "")
foreach(_PATH ${LIBPATH})
	file(TO_NATIVE_PATH "${_PATH}" _PATH)
	set(LIBPATH_ENV "${LIBPATH_ENV}${_PATH};")
endforeach()

set(INCLUDE_ENV "")
foreach(_PATH ${INCLUDE})
	file(TO_NATIVE_PATH "${_PATH}" _PATH)
	set(INCLUDE_ENV "${INCLUDE_ENV}${_PATH};")
endforeach()

set(ENV{LIB} "${LIB_ENV}")
set(ENV{LIBPATH} "${LIBPATH_ENV}")
set(ENV{INCLUDE} "${INCLUDE_ENV}")
