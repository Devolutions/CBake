set(CMAKE_SYSTEM_NAME Windows)
set(CMAKE_SYSTEM_PROCESSOR i686)

set(VSCMD_ARG_HOST_ARCH "x64")
set(VSCMD_ARG_TGT_ARCH "x86")

set(PROGRAM_FILES_X86_STR "PROGRAMFILES(X86)")
file(TO_CMAKE_PATH "$ENV{${PROGRAM_FILES_X86_STR}}" PROGRAM_FILES_X86)

set(VCToolsVersion "14.24.28314")
set(VCINSTALLDIR "${PROGRAM_FILES_X86}/Microsoft Visual Studio/2019/Community/VC/")
set(VCToolsInstallDir "${VCINSTALLDIR}Tools/MSVC/${VCToolsVersion}/")

set(VCToolsPath "${VCToolsInstallDir}bin/Host${VSCMD_ARG_HOST_ARCH}/${VSCMD_ARG_TGT_ARCH}/")

set(WindowsSdkVersion "10.0.18362.0/")
set(WindowsSdkLibVersion "10.0.18362.0/")
set(WindowsSdkDir "${PROGRAM_FILES_X86}/Windows Kits/10/")
set(WindowsSdkVerBinPath "${WindowsSdkDir}bin/${WindowsSdkVersion}")
set(WindowsSdkToolsPath "${WindowsSdkVerBinPath}${VSCMD_ARG_HOST_ARCH}/")

set(NETFXSDKDir "${PROGRAM_FILES_X86}/Windows Kits/NETFXSDK/4.8/")

set(CMAKE_C_COMPILER "${VCToolsPath}cl.exe" CACHE FILEPATH "")
set(CMAKE_CXX_COMPILER "${VCToolsPath}cl.exe" CACHE FILEPATH "")
set(CMAKE_LINKER "${VCToolsPath}link.exe" CACHE FILEPATH "")
set(CMAKE_RC_COMPILER "${WindowsSdkToolsPath}rc.exe" CACHE FILEPATH "")
set(CMAKE_MT "${WindowsSdkToolsPath}mt.exe" CACHE FILEPATH "")

# LIB, LIBPATH, INCLUDE, PATH

set(LIB
	"${VCToolsInstallDir}ATLMFC/lib/${VSCMD_ARG_TGT_ARCH}"
	"${VCToolsInstallDir}lib/${VSCMD_ARG_TGT_ARCH}"
	"${NETFXSDKDir}lib/um/${VSCMD_ARG_TGT_ARCH}"
	"${WindowsSdkDir}lib/${WindowsSdkLibVersion}ucrt/${VSCMD_ARG_TGT_ARCH}"
	"${WindowsSdkDir}lib/${WindowsSdkLibVersion}um/${VSCMD_ARG_TGT_ARCH}"
	)

set(LIBPATH
	"${VCToolsInstallDir}ATLMFC/lib/${VSCMD_ARG_TGT_ARCH}"
	"${VCToolsInstallDir}lib/${VSCMD_ARG_TGT_ARCH}"
	"${VCToolsInstallDir}lib/${VSCMD_ARG_TGT_ARCH}/x86/store/references"
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
