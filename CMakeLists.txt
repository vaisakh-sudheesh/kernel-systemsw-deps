cmake_minimum_required(VERSION 3.20)
list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake")

project (KernelSystemSW)
include (kernel)

download_kernel(${CMAKE_BINARY_DIR}/kernel 6.12.6)
configure_kernel(${CMAKE_BINARY_DIR}/kernel ${CMAKE_CURRENT_SOURCE_DIR}/configs/kernel_x86-qemu_base-minimal_defconfig)
build_kernel(${CMAKE_BINARY_DIR}/kernel)
add_custom_target(kernel_target ALL DEPENDS build_kernel_target)