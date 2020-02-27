
set(WIN32 TRUE)
set(MSVC TRUE)

set(PROGRAM_FILES_X86_STR "PROGRAMFILES(X86)")
file(TO_CMAKE_PATH "$ENV{${PROGRAM_FILES_X86_STR}}" PROGRAM_FILES_X86)

set(VCToolsVersion "14.24.28314")
set(VCINSTALLDIR "${PROGRAM_FILES_X86}/Microsoft Visual Studio/2019/Community/VC/")
set(VCToolsInstallDir "${VCINSTALLDIR}Tools/MSVC/${VCToolsVersion}/")

set(VCToolsPath "${VCToolsInstallDir}bin/Host${HOST_ARCH}/${TARGET_ARCH}/")

# Computer\HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Windows Kits\Installed Roots
# Computer\HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Microsoft SDKs\Windows\v10.0
set(WindowsSdkVersion "10.0.18362.0/")
set(WindowsSdkLibVersion "10.0.18362.0/")
set(WindowsSdkDir "${PROGRAM_FILES_X86}/Windows Kits/10/")
set(WindowsSdkVerBinPath "${WindowsSdkDir}bin/${WindowsSdkVersion}")
set(WindowsSdkToolsPath "${WindowsSdkVerBinPath}${HOST_ARCH}/")

# Computer\HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Microsoft SDKs\NETFXSDK\4.8
set(NETFXSDKDir "${PROGRAM_FILES_X86}/Windows Kits/NETFXSDK/4.8/")

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
