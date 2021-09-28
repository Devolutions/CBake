
if(WINDOWS_TOOLCHAIN_INCLUDED)
    return() # avoid double-loading issue
endif()
set(WINDOWS_TOOLCHAIN_INCLUDED TRUE)

function(init_toolchain_property property)
    if(${property})
        set(ENV{_${property}} "${${property}}")
    else()
        set(${property} "$ENV{_${property}}" PARENT_SCOPE)
    endif()
endfunction()

if(CMAKE_HOST_WIN32)
    include("${CMAKE_CURRENT_LIST_DIR}/windows-msvc.cmake")
else()
    include("${CMAKE_CURRENT_LIST_DIR}/clang-cl-msvc.cmake")
endif()
