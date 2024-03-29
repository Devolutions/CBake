
function(generate_winsdk_vfs_overlay winsdk_include_dir output_path)
    set(include_dirs)
    file(GLOB_RECURSE entries LIST_DIRECTORIES true "${winsdk_include_dir}/*")
    foreach(entry ${entries})
        if(IS_DIRECTORY "${entry}")
            list(APPEND include_dirs "${entry}")
        endif()
    endforeach()

    file(WRITE "${output_path}"  "version: 0\n")
    file(APPEND "${output_path}" "case-sensitive: false\n")
    file(APPEND "${output_path}" "roots:\n")

    foreach(dir ${include_dirs})
        file(GLOB headers RELATIVE "${dir}" "${dir}/*.h")
        if(NOT headers)
            continue()
        endif()

        file(APPEND "${output_path}" "  - name: \"${dir}\"\n")
        file(APPEND "${output_path}" "    type: directory\n")
        file(APPEND "${output_path}" "    contents:\n")

        foreach(header ${headers})
            file(APPEND "${output_path}" "      - name: \"${header}\"\n")
            file(APPEND "${output_path}" "        type: file\n")
            file(APPEND "${output_path}" "        external-contents: \"${dir}/${header}\"\n")
        endforeach()
    endforeach()
endfunction()

function(generate_winsdk_lib_symlinks winsdk_um_lib_dir output_dir)
    execute_process(COMMAND "${CMAKE_COMMAND}" -E make_directory "${output_dir}")
    file(GLOB libraries RELATIVE "${winsdk_um_lib_dir}" "${winsdk_um_lib_dir}/*")
    foreach(library ${libraries})
        string(TOLOWER "${library}" symlink_name)
        execute_process(COMMAND "${CMAKE_COMMAND}"
                            -E create_symlink
                            "${winsdk_um_lib_dir}/${library}"
                            "${output_dir}/${symlink_name}")
    endforeach()
endfunction()

set(CMAKE_SYSTEM_NAME Windows)

init_toolchain_property(TARGET_ARCH)
init_toolchain_property(MSVC_BASE)
init_toolchain_property(WINSDK_BASE)
init_toolchain_property(WINSDK_VERSION)

if(NOT TARGET_ARCH)
    set(TARGET_ARCH x86_64)
endif()
if(TARGET_ARCH STREQUAL "aarch64" OR TARGET_ARCH STREQUAL "arm64")
    set(TRIPLE_ARCH "aarch64")
    set(WINSDK_ARCH "arm64")
    set(MSVC_ARCH "arm64")
    set(CMAKE_SYSTEM_PROCESSOR "ARM64")
elseif(TARGET_ARCH STREQUAL "armv7" OR TARGET_ARCH STREQUAL "arm")
    set(TRIPLE_ARCH "armv7")
    set(WINSDK_ARCH "arm")
    set(MSVC_ARCH "arm")
    set(CMAKE_SYSTEM_PROCESSOR "ARM")
elseif(TARGET_ARCH STREQUAL "i686" OR TARGET_ARCH STREQUAL "x86")
    set(TRIPLE_ARCH "i686")
    set(WINSDK_ARCH "x86")
    set(MSVC_ARCH "x86")
    set(CMAKE_SYSTEM_PROCESSOR "x86")
elseif(TARGET_ARCH STREQUAL "x86_64" OR TARGET_ARCH STREQUAL "x64")
    set(TRIPLE_ARCH "x86_64")
    set(WINSDK_ARCH "x64")
    set(MSVC_ARCH "x64")
    set(CMAKE_SYSTEM_PROCESSOR "x64")
else()
    message(SEND_ERROR "Unknown target architecture: ${TARGET_ARCH}")
endif()

# detect winsdk and vctools

get_filename_component(CBAKE_HOME ${CMAKE_CURRENT_LIST_DIR} DIRECTORY)

if(NOT WINSDK_BASE)
    if(EXISTS "${CBAKE_HOME}/packages/winsdk")
        set(WINSDK_BASE "${CBAKE_HOME}/packages/winsdk")
    endif()
endif()

if(NOT MSVC_BASE)
    if(EXISTS "${CBAKE_HOME}/packages/vctools")
        set(MSVC_BASE "${CBAKE_HOME}/packages/vctools")
    endif()
endif()

# Detect Windows SDK version
file(GLOB WINSDKVER_HEADERS LIST_DIRECTORIES TRUE "${WINSDK_BASE}/Include/10.*/um/winsdkver.h")
foreach(WINSDKVER_HEADER ${WINSDKVER_HEADERS})
	string(REGEX MATCH "Include/(10\\.[0-9\\.]+\\.[0-9\\.]+\\.[0-9\\.]+)/um/winsdkver.h" _MATCH "${WINSDKVER_HEADER}")
	set(WINSDK_VERSION_LATEST ${CMAKE_MATCH_1})
endforeach()

if(NOT WINSDK_VERSION)
    set(WINSDK_VERSION ${WINSDK_VERSION_LATEST})
endif()

message(STATUS "WINSDK_VERSION: ${WINSDK_VERSION}")

set(WINSDK_INCLUDE "${WINSDK_BASE}/Include/${WINSDK_VERSION}")
set(WINSDK_LIB "${WINSDK_BASE}/Lib/${WINSDK_VERSION}")

set(MSVC_INCLUDE "${MSVC_BASE}/include")
set(MSVC_LIB "${MSVC_BASE}/lib")

if(NOT EXISTS "${MSVC_BASE}" OR
    NOT EXISTS "${MSVC_INCLUDE}" OR
    NOT EXISTS "${MSVC_LIB}")
    message(SEND_ERROR
        "CMake variable MSVC_BASE (${MSVC_BASE}) must point to a folder containing MSVC "
        "system headers and libraries")
endif()

if(NOT EXISTS "${WINSDK_BASE}" OR
    NOT EXISTS "${WINSDK_INCLUDE}" OR
    NOT EXISTS "${WINSDK_LIB}")
    message(SEND_ERROR
        "CMake variable WINSDK_BASE and WINSDK_VERSION must resolve to a valid "
        "Windows SDK installation")
endif()

if(NOT EXISTS "${WINSDK_INCLUDE}/um/Windows.h")
    message(SEND_ERROR "Cannot find Windows.h")
endif()

if(NOT EXISTS "${WINSDK_INCLUDE}/um/WINDOWS.H")
    set(case_sensitive_filesystem TRUE)
endif()

# Attempt to find the clang-cl binary
find_program(CLANG_CL_PATH NAMES clang-cl)
if(${CLANG_CL_PATH} STREQUAL "CLANG_CL_PATH-NOTFOUND")
    message(SEND_ERROR "Unable to find clang-cl")
endif()

# Attempt to find the llvm-link binary
find_program(LLD_LINK_PATH NAMES lld-link)
if(${LLD_LINK_PATH} STREQUAL "LLD_LINK_PATH-NOTFOUND")
    message(SEND_ERROR "Unable to find lld-link")
endif()

# Attempt to find the native clang binary
find_program(CLANG_C_PATH NAMES clang)
if(${CLANG_C_PATH} STREQUAL "CLANG_C_PATH-NOTFOUND")
    message(SEND_ERROR "Unable to find clang")
endif()

# Attempt to find the native clang++ binary
find_program(CLANG_CXX_PATH NAMES clang++)
if(${CLANG_CXX_PATH} STREQUAL "CLANG_CXX_PATH-NOTFOUND")
    message(SEND_ERROR "Unable to find clang++")
endif()

set(CMAKE_C_COMPILER "${CLANG_CL_PATH}" CACHE FILEPATH "")
set(CMAKE_CXX_COMPILER "${CLANG_CL_PATH}" CACHE FILEPATH "")
set(CMAKE_LINKER "${LLD_LINK_PATH}" CACHE FILEPATH "")

# Even though we're cross-compiling, we need some native tools (e.g. llvm-tblgen), and those
# native tools have to be built before we can start doing the cross-build.  LLVM supports
# a CROSS_TOOLCHAIN_FLAGS_NATIVE argument which consists of a list of flags to pass to CMake
# when configuring the NATIVE portion of the cross-build.  By default we construct this so
# that it points to the tools in the same location as the native clang-cl that we're using.
list(APPEND _CTF_NATIVE_DEFAULT "-DCMAKE_ASM_COMPILER=${CLANG_C_PATH}")
list(APPEND _CTF_NATIVE_DEFAULT "-DCMAKE_C_COMPILER=${CLANG_C_PATH}")
list(APPEND _CTF_NATIVE_DEFAULT "-DCMAKE_CXX_COMPILER=${CLANG_CXX_PATH}")

set(CROSS_TOOLCHAIN_FLAGS_NATIVE "${_CTF_NATIVE_DEFAULT}" CACHE STRING "")

set(COMPILE_FLAGS
    -D_CRT_SECURE_NO_WARNINGS
    --target=${TRIPLE_ARCH}-windows-msvc
    -fms-compatibility-version=19.11
    -Wno-unused-command-line-argument # Needed to accept projects pushing both -Werror and /MP
    -imsvc "${MSVC_INCLUDE}"
    -imsvc "${WINSDK_INCLUDE}/ucrt"
    -imsvc "${WINSDK_INCLUDE}/shared"
    -imsvc "${WINSDK_INCLUDE}/um"
    -imsvc "${WINSDK_INCLUDE}/winrt")

if(case_sensitive_filesystem)
    # Ensure all sub-configures use the top-level VFS overlay instead of generating their own.
    init_toolchain_property(winsdk_vfs_overlay_path)
    if(NOT winsdk_vfs_overlay_path)
        set(winsdk_vfs_overlay_path "${CMAKE_BINARY_DIR}/winsdk_vfs_overlay.yaml")
        generate_winsdk_vfs_overlay("${WINSDK_BASE}/Include/${WINSDK_VERSION}" "${winsdk_vfs_overlay_path}")
        init_toolchain_property(winsdk_vfs_overlay_path)
    endif()
    list(APPEND COMPILE_FLAGS
       -Xclang -ivfsoverlay -Xclang "${winsdk_vfs_overlay_path}")
endif()

string(REPLACE ";" " " COMPILE_FLAGS "${COMPILE_FLAGS}")

# We need to preserve any flags that were passed in by the user. However, we
# can't append to CMAKE_C_FLAGS and friends directly, because toolchain files
# will be re-invoked on each reconfigure and therefore need to be idempotent.
# The assignments to the _INITIAL cache variables don't use FORCE, so they'll
# only be populated on the initial configure, and their values won't change
# afterward.
set(_CMAKE_C_FLAGS_INITIAL "${CMAKE_C_FLAGS}" CACHE STRING "")
set(CMAKE_C_FLAGS "${_CMAKE_C_FLAGS_INITIAL} ${COMPILE_FLAGS}" CACHE STRING "" FORCE)

set(_CMAKE_CXX_FLAGS_INITIAL "${CMAKE_CXX_FLAGS}" CACHE STRING "")
set(CMAKE_CXX_FLAGS "${_CMAKE_CXX_FLAGS_INITIAL} ${COMPILE_FLAGS}" CACHE STRING "" FORCE)

if(MSVC_ARCH STREQUAL "")
    set(MSVC_LIB_PATH "${MSVC_LIB}")
else()
    set(MSVC_LIB_PATH "${MSVC_LIB}/${MSVC_ARCH}")
endif()

set(LINK_FLAGS
    # Prevent CMake from attempting to invoke mt.exe. It only recognizes the slashed form and not the dashed form.
    /manifest:no
    -libpath:"${MSVC_LIB_PATH}"
    -libpath:"${WINSDK_LIB}/ucrt/${WINSDK_ARCH}"
    -libpath:"${WINSDK_LIB}/um/${WINSDK_ARCH}")

if(case_sensitive_filesystem)
    # Ensure all sub-configures use the top-level symlinks dir instead of generating their own.
    init_toolchain_property(winsdk_lib_symlinks_dir)
    if(NOT winsdk_lib_symlinks_dir)
        set(winsdk_lib_symlinks_dir "${CMAKE_BINARY_DIR}/winsdk_lib_symlinks")
        generate_winsdk_lib_symlinks("${WINSDK_BASE}/Lib/${WINSDK_VERSION}/um/${WINSDK_ARCH}" "${winsdk_lib_symlinks_dir}")
        init_toolchain_property(winsdk_lib_symlinks_dir)
    endif()
    list(APPEND LINK_FLAGS
        -libpath:"${winsdk_lib_symlinks_dir}")
endif()

string(REPLACE ";" " " LINK_FLAGS "${LINK_FLAGS}")

# See explanation for compiler flags above for the _INITIAL variables.
set(_CMAKE_EXE_LINKER_FLAGS_INITIAL "${CMAKE_EXE_LINKER_FLAGS}" CACHE STRING "")
set(CMAKE_EXE_LINKER_FLAGS "${_CMAKE_EXE_LINKER_FLAGS_INITIAL} ${LINK_FLAGS}" CACHE STRING "" FORCE)

set(_CMAKE_MODULE_LINKER_FLAGS_INITIAL "${CMAKE_MODULE_LINKER_FLAGS}" CACHE STRING "")
set(CMAKE_MODULE_LINKER_FLAGS "${_CMAKE_MODULE_LINKER_FLAGS_INITIAL} ${LINK_FLAGS}" CACHE STRING "" FORCE)

set(_CMAKE_SHARED_LINKER_FLAGS_INITIAL "${CMAKE_SHARED_LINKER_FLAGS}" CACHE STRING "")
set(CMAKE_SHARED_LINKER_FLAGS "${_CMAKE_SHARED_LINKER_FLAGS_INITIAL} ${LINK_FLAGS}" CACHE STRING "" FORCE)

# CMake populates these with a bunch of unnecessary libraries, which requires
# extra case-correcting symlinks and what not. Instead, let projects explicitly
# control which libraries they require.
set(CMAKE_C_STANDARD_LIBRARIES "" CACHE STRING "" FORCE)
set(CMAKE_CXX_STANDARD_LIBRARIES "" CACHE STRING "" FORCE)
