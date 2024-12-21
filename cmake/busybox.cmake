###############################################################################
##### Busybox build script #####
###############################################################################
# Author: Vaisakh P S
#
# This script contains the CMake functions to build the busybox.
# The functions are used to download, patch, configure, and build the busybox.
###############################################################################

include(FetchContent)
## Download the busybox
function (__download_busybox__ working_dir version)
    message(STATUS "Downloading busybox version ${version}")
    FetchContent_Declare(
        busybox-project-${version}
        URL https://busybox.net/downloads/busybox-${version}.tar.bz2

        DOWNLOAD_DIR ${working_dir}/downloads
        SOURCE_DIR ${working_dir}/sources
        BINARY_DIR ${working_dir}/build
        STAMP_DIR ${working_dir}/stamp
    )
    FetchContent_MakeAvailable(busybox-project-${version})
endfunction(__download_busybox__)

#Patch the busybox
function(__patch_busybox__ working_dir )
    message(STATUS "Patching busybox in ${working_dir}")
    add_custom_command(
        OUTPUT ${working_dir}/sources/.patched
        COMMAND echo "Patching busybox"
        COMMAND patch -p1 --ignore-whitespace < ${CMAKE_CURRENT_LIST_DIR}/deps/kernel-systemsw/patches/0001-E0256-Necessary-integrations.patch
        COMMAND ${CMAKE_COMMAND} -E touch ${working_dir}/sources/.patched
        COMMAND echo "Patching busybox done"
        WORKING_DIRECTORY ${working_dir}/sources
    )
    add_custom_target(patch_busybox_target ALL DEPENDS ${working_dir}/sources/.patched)
endfunction(__patch_busybox__)

### Configure the busybox
function(__configure_busybox__ working_dir )
    message(STATUS "Configuring busybox in ${working_dir}")
    list (APPEND output_config_busybox ${working_dir}/sources/.configured
                        ${working_dir}/sources/.config
                        ${working_dir}/sources/arch/x86/configs/build_defconfig
                )
    add_custom_command(
        OUTPUT ${output_config_busybox}
        COMMAND ${CMAKE_COMMAND} -E make_directory ${working_dir}/build
        COMMAND echo "Configuring busybox"
        COMMAND make O=${working_dir}/build defconfig
        COMMAND ${CMAKE_COMMAND} -E touch ${working_dir}/sources/.configured
        COMMAND echo "Configuring busybox done"
        WORKING_DIRECTORY ${working_dir}/sources
        DEPENDS patch_busybox_target
    )

    add_custom_target(config_busybox_target ALL DEPENDS ${output_config_busybox})
endfunction(__configure_busybox__)


### Build the busybox
function(__build_busybox__ working_dir)
    message(STATUS "Building busybox in ${working_dir}")
    list (APPEND output_build_busybox ${working_dir}/build/.busybox_build
                        ${working_dir}/build/busybox
                )
    add_custom_command(
        OUTPUT ${output_build_busybox}
        COMMAND make -j8 O=${working_dir}/build 
        COMMAND ${CMAKE_COMMAND} -E touch ${working_dir}/build/.busybox_build
        COMMAND echo "Building busybox done"
        WORKING_DIRECTORY ${working_dir}/sources
        DEPENDS config_busybox_target
    )
    add_custom_target(build_busybox_target ALL DEPENDS ${output_build_busybox})
endfunction(__build_busybox__)

### Install the busybox
function(__install_busybox__ working_dir)
    message(STATUS "Installing busybox in ${working_dir}")
    list (APPEND output_install_busybox ${working_dir}/build/.busybox_install
                        ${working_dir}/build/_install
                )
    add_custom_command(
        OUTPUT ${output_install_busybox}
        COMMAND make O=${working_dir}/build ARCH=x86 install
        COMMAND ${CMAKE_COMMAND} -E touch ${working_dir}/build/.busybox_install
        COMMAND echo "Installing busybox done"
        WORKING_DIRECTORY ${working_dir}/sources
        DEPENDS build_busybox_target
    )
    add_custom_target(install_busybox_target ALL DEPENDS ${output_install_busybox})
endfunction(__install_busybox__)

### Create the busybox target
function(base_busybox_build version)
    set(busybox_working_dir ${CMAKE_BINARY_DIR}/busybox-${version})
    __download_busybox__(${busybox_working_dir} ${version})
    __patch_busybox__(${busybox_working_dir})
    __configure_busybox__(${busybox_working_dir})
    __build_busybox__(${busybox_working_dir})
    __install_busybox__(${busybox_working_dir})
    add_custom_target(busybox_target ALL DEPENDS install_busybox_target)
endfunction(base_busybox_build)
