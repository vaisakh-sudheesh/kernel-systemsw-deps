cmake_minimum_required(VERSION 3.20)
list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake")

project (KernelSystemSW)
include (kernel)

add_kernel_target(6.12.6 ${CMAKE_CURRENT_LIST_DIR}/configs/kernel_x86-qemu_base-minimal_defconfig )
add_custom_target(kernel_target ALL DEPENDS kernel_target-6.12.6)