set(sources
    amd_counters.cpp
    amd_counters.h
    amd_isa.cpp
    amd_isa.h
    amd_isa_devices.cpp
    amd_isa_devices.h
    amd_rgp.cpp
    amd_rgp.h
    official/RGP/DevDriverAPI.h)

if(WIN32)
    list(APPEND sources amd_isa_win32.cpp)
else()
    list(APPEND sources amd_isa_posix.cpp)
endif()

set(include_dirs ${RDOC_INCLUDES})

add_library(rdoc_amd OBJECT ${sources})
target_compile_definitions(rdoc_amd ${RDOC_DEFINITIONS})
target_include_directories(rdoc_amd ${include_dirs})

if(MSVC)
    rdoc_apply_precompiled_header_fi(rdoc_amd)
endif()
