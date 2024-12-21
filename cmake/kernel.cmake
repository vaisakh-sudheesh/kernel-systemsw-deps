###############################################################################
##### Kernel build script #####
###############################################################################
# Author: Vaisakh P S
#
# This script contains the CMake functions to build the kernel.
# The functions are used to download, patch, configure, and build the kernel.
###############################################################################
include(FetchContent)
## Download the kernel
function (download_kernel working_dir version)
    message(STATUS "Downloading kernel version ${version}")
    FetchContent_Declare(
        linux-project-${version}
        URL https://www.kernel.org/pub/linux/kernel/v6.x/linux-${version}.tar.xz

        DOWNLOAD_DIR ${working_dir}/downloads
        SOURCE_DIR ${working_dir}/sources
        BINARY_DIR ${working_dir}/build
        STAMP_DIR ${working_dir}/stamp
    )
    FetchContent_MakeAvailable(linux-project-${version})
endfunction(download_kernel)

#Patch the kernel
function(patch_kernel working_dir patch_lists)
    message(STATUS "Patching kernel in ${working_dir}")
endfunction(patch_kernel)

### Configure the kernel
function(configure_kernel working_dir defconfig)
    message(STATUS "Configuring kernel in ${working_dir}")
    list (APPEND output_config_kernel ${working_dir}/sources/.configured
                        ${working_dir}/sources/.config
                        ${working_dir}/sources/arch/x86/configs/build_defconfig
            )
    add_custom_command(
        OUTPUT ${output_config_kernel}
        COMMAND ${CMAKE_COMMAND} -E make_directory ${working_dir}/build
        COMMAND echo "Configuring kernel"
        COMMAND  stat ${working_dir}/sources/arch/x86/configs/build_defconfig > /dev/null || ln -sf ${defconfig}  ${working_dir}/sources/arch/x86/configs/build_defconfig
        COMMAND make O=${working_dir}/build ARCH=x86  build_defconfig
        COMMAND ${CMAKE_COMMAND} -E touch ${working_dir}/sources/.configured
        COMMAND echo "Configuring kernel done"
        DEPENDS ${patch_lists}
        WORKING_DIRECTORY ${working_dir}/sources
    )

    add_custom_target(configure_kernel_target ALL DEPENDS ${output_config_kernel} )
endfunction(configure_kernel)

### Build the kernel
function(build_kernel working_dir)
    message(STATUS "Building kernel in ${working_dir}")
    
    list (APPEND output_build_kernel ${working_dir}/build/.build
                        ${working_dir}/build/vmlinux
                        ${working_dir}/build/arch/x86_64/boot/bzImage
            )
    add_custom_command(
        OUTPUT ${output_build_kernel}
        COMMAND echo "Building kernel"
        COMMAND make O=${working_dir}/build ARCH=x86 -j8
        COMMAND ${CMAKE_COMMAND} -E touch ${working_dir}/build/.build
        COMMAND echo "Building kernel done"
        DEPENDS configure_kernel_target
        WORKING_DIRECTORY ${working_dir}/sources
    )   
    add_custom_target(build_kernel_target ALL DEPENDS  ${output_build_kernel} )
endfunction(build_kernel)

