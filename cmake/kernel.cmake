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
function (__download_kernel__ working_dir version)
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
endfunction(__download_kernel__)

#Patch the kernel
function(patch_kernel working_dir patch_lists)
    message(STATUS "Patching kernel in ${working_dir}")
endfunction(patch_kernel)

### Configure the kernel
function(__configure_kernel__ working_dir defconfig)
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
        COMMAND make O=${working_dir}/build ARCH=x86 CC=${CMAKE_C_COMPILER} build_defconfig
        COMMAND ${CMAKE_COMMAND} -E touch ${working_dir}/sources/.configured
        COMMAND echo "Configuring kernel done"
        DEPENDS ${patch_lists}
        WORKING_DIRECTORY ${working_dir}/sources
    )

    add_custom_target(configure_kernel_target ALL DEPENDS ${output_config_kernel} )
endfunction(__configure_kernel__)

### Build the kernel
function(__build_kernel__ working_dir)
    message(STATUS "Building kernel in ${working_dir}")
    
    list (APPEND output_build_kernel ${working_dir}/build/.build
                        ${working_dir}/build/vmlinux
                        ${working_dir}/build/arch/x86_64/boot/bzImage
            )
    add_custom_command(
        OUTPUT ${output_build_kernel}
        COMMAND echo "Applying extended configurations on the kernel"
        
        COMMAND scripts/config --file ${working_dir}/build/.config --disable SYSTEM_TRUSTED_KEYS
        COMMAND scripts/config --file ${working_dir}/build/.config --disable SYSTEM_REVOCATION_KEYS
        COMMAND scripts/config --file ${working_dir}/build/.config  --set-str CONFIG_SYSTEM_TRUSTED_KEYS \"\"
        COMMAND scripts/config --file ${working_dir}/build/.config  --set-str CONFIG_SYSTEM_REVOCATION_KEYS \"\"

        COMMAND scripts/config --file ${working_dir}/build/.config --enable CONFIG_DEBUG_INFO_BTF
        COMMAND scripts/config --file ${working_dir}/build/.config --enable CONFIG_DEBUG_INFO_DWARF_TOOLCHAIN_DEFAULT
        COMMAND scripts/config --file ${working_dir}/build/.config --enable CONFIG_DEBUG_INFO_COMPRESSED_ZLIB
        COMMAND scripts/config --file ${working_dir}/build/.config --enable CONFIG_PROBE_EVENTS_BTF_ARGS
        
        COMMAND scripts/config --file ${working_dir}/build/.config --disable CONFIG_DEBUG_INFO_REDUCED
        COMMAND scripts/config --file ${working_dir}/build/.config --disable CONFIG_DEBUG_INFO_SPLIT
        COMMAND scripts/config --file ${working_dir}/build/.config --disable CONFIG_GDB_SCRIPTS

        COMMAND scripts/config --file ${working_dir}/build/.config --enable CONFIG_KALLSYMS
        COMMAND scripts/config --file ${working_dir}/build/.config --enable CONFIG_SCHED_CLASS_EXT

        COMMAND echo "Building kernel"
        COMMAND make O=${working_dir}/build CC=${CMAKE_C_COMPILER} ARCH=x86 -j8
        COMMAND ${CMAKE_COMMAND} -E touch ${working_dir}/build/.build
        COMMAND echo "Building kernel done"
        DEPENDS configure_kernel_target
        WORKING_DIRECTORY ${working_dir}/sources
    )   
    add_custom_target(build_kernel_target ALL DEPENDS  ${output_build_kernel} )
endfunction(__build_kernel__)



function (add_kernel_target version base_defconfig)
    set(kernel_working_dir ${CMAKE_BINARY_DIR}/kernel-${version})
    set(   ${CMAKE_CURRENT_LIST_DIR}/)
    __download_kernel__(${kernel_working_dir} ${version})
    __configure_kernel__(${kernel_working_dir} ${base_defconfig})
    __build_kernel__(${kernel_working_dir})
    add_custom_target(kernel_target-${version} ALL DEPENDS build_kernel_target)
endfunction(add_kernel_target)