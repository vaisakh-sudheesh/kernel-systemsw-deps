##############################################################################
## bpftool.cmake
##
## This file contains the CMake functions to build BPF code using bpftool.
## The functions are used to compile BPF code into object files, generate
## skeletons for BPF code, and push the BPF object files to the target.
##
## More of a wrapper aund android.cmake and pc.cmake
##############################################################################


# Function to generate a header file with the build directory
function(generate_build_dir_header output_file)
    file(WRITE ${output_file} "#ifndef BUILD_DIR_H\n")
    file(APPEND ${output_file} "#define BUILD_DIR_H\n\n")
    file(APPEND ${output_file} "#define BUILD_DIR \"${CMAKE_BINARY_DIR}/lib\"\n\n")
    file(APPEND ${output_file} "#define __TARGET_ARCH_x86\n\n")
    file(APPEND ${output_file} "#endif // BUILD_DIR_H\n")
endfunction()


function(generate_build_dir_header_android output_file)
    file(WRITE ${output_file} "#ifndef BUILD_DIR_H\n")
    file(APPEND ${output_file} "#define BUILD_DIR_H\n\n")
    file(APPEND ${output_file} "#define BUILD_DIR \"/data/local/tmp\"\n\n")
    file(APPEND ${output_file} "#define __TARGET_ARCH_arm64\n\n")
    file(APPEND ${output_file} "#define __ANDROID_BUILD__\n\n")
    file(APPEND ${output_file} "#endif // BUILD_DIR_H\n")
endfunction()


# Find the bpftool executable & setup the relevant build rules
if (NOT CMAKE_TOOLCHAIN_FILE)
    generate_build_dir_header(${CMAKE_BINARY_DIR}/build_info.h)
    ## Building for the host
    message(STATUS "Building for the host")
    include(${CMAKE_CURRENT_LIST_DIR}/__bpftool__/pc.cmake)
else()
    generate_build_dir_header_android(${CMAKE_BINARY_DIR}/build_info.h)
    ## Trying to build for Android
    message(STATUS "Cross-compiling for Android")
    include(${CMAKE_CURRENT_LIST_DIR}/__bpftool__/android.cmake)
endif(NOT CMAKE_TOOLCHAIN_FILE)