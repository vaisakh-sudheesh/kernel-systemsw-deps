enable_testing()

base_kernel_build(6.12.6 ${CMAKE_CURRENT_LIST_DIR}/../configs/kernel_x86-qemu_base-minimal_defconfig )
base_busybox_build(1.37.0 ${CMAKE_CURRENT_LIST_DIR}/../patches/0001-E0256-Necessary-integrations.patch)
build_minimal_fs(   ${CMAKE_CURRENT_LIST_DIR}/../busybox
                    ${CMAKE_CURRENT_BINARY_DIR}/initrd
                    ${CMAKE_CURRENT_BINARY_DIR}/busybox-1.37.0/build/_install
                    ${CMAKE_CURRENT_BINARY_DIR}/initrd.tar.gz
                    init-noshell.ref
                )
add_custom_target(kernel_target ALL DEPENDS base_kernel_target-6.12.6 busybox_target)
add_test(NAME test_kernel_build_complete 
            COMMAND ${CMAKE_COMMAND} --build . --target kernel_target
        )
add_test(NAME test_kernel_boot_complete 
            COMMAND  qemu-system-x86_64 
                    -kernel ${CMAKE_CURRENT_BINARY_DIR}/kernel-6.12.6/build/arch/x86_64/boot/bzImage
                    -initrd ${CMAKE_CURRENT_BINARY_DIR}/initrd.tar.gz
                    -nographic
                    -append "console=ttyS0"
        )