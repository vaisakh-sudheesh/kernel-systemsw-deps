find_program(BPFTOOL_EXECUTABLE NAMES bpftool)
if(NOT BPFTOOL_EXECUTABLE)
    #if bpftool is not found, download and build it
    include (${CMAKE_CURRENT_LIST_DIR}/DownloadBpftool.cmake)
    download_bpftool()
    set (BPFTOOL_EXECUTABLE ${CMAKE_BINARY_DIR}/bpftool-${BPTOOL_VERSION}/src/bpftool CACHE STRING "Path to the bpftool executable")
    set (BPFTOOL_HEADERS ${CMAKE_BINARY_DIR}/bpftool-${BPTOOL_VERSION}/src/include/ CACHE STRING "Path to the bpftool headers")
    set (BPFTOOL_LIBRARIES ${CMAKE_BINARY_DIR}/bpftool-${BPTOOL_VERSION}/src/lib/ CACHE STRING "Path to the bpftool libraries")
else()
    set (BPFTOOL_EXECUTABLE ${BPFTOOL_EXECUTABLE} CACHE STRING "Path to the bpftool executable")
    set (BPFTOOL_HEADERS /usr/src/linux-headers-${KERNEL_VERSION}/tools/bpf/resolve_btfids/libbpf/include/ CACHE STRING "Path to the bpftool headers")
    set (BPFTOOL_LIBRARIES /usr/src/linux-headers-${KERNEL_VERSION}/tools/bpf/resolve_btfids/libbpf/ CACHE STRING "Path to the bpftool libraries")
endif()

execute_process(
    COMMAND uname -r
    OUTPUT_VARIABLE KERNEL_VERSION
    OUTPUT_STRIP_TRAILING_WHITESPACE
)
message(STATUS "Kernel version: ${KERNEL_VERSION}")


###############################################################################
### Generate vmlinux.h for BPF code compilation
###############################################################################
add_custom_command(
    OUTPUT ${CMAKE_BINARY_DIR}/vmlinux.h
    COMMAND ${BPFTOOL_EXECUTABLE} btf dump file /sys/kernel/btf/vmlinux format c > ${CMAKE_BINARY_DIR}/vmlinux.h
    DEPENDS ${BPFTOOL_EXECUTABLE}
    COMMENT "Generating vmlinux.h for BPF code compilation"
)

add_custom_target(generate_vmlinux_h ALL
    DEPENDS ${CMAKE_BINARY_DIR}/vmlinux.h
)

###############################################################################
### Compile BPF code into object files
###############################################################################

function(build_bpf TARGET_NAME BPF_SOURCE BPF_OBJECT BPF_EXTRA_INCLUDES )
    add_custom_command(
        OUTPUT ${BPF_OBJECT}
        COMMAND ${CMAKE_C_COMPILER} -O2 -target bpf -g
                                      -c ${BPF_SOURCE}
                                      -o ${BPF_OBJECT}
                                      -I${CMAKE_BINARY_DIR}
                                      -I${BPFTOOL_HEADERS}
                                      -I${BPF_EXTRA_INCLUDES}
        DEPENDS ${BPF_SOURCE} generate_vmlinux_h
        COMMENT "Compiling BPF code ${BPF_SOURCE} into ${BPF_OBJECT}"
    )

    add_custom_target(${TARGET_NAME} ALL
        DEPENDS ${BPF_OBJECT}
    )

endfunction(build_bpf)


###############################################################################
### Generate skeleton for BPF code
###############################################################################
function(generate_bpf_skeleton TARGET_NAME BPF_OBJECT BPF_SKELETON_HEADER)
    add_custom_target(bpf_skeleton_${TARGET_NAME} ALL
        COMMAND ${BPFTOOL_EXECUTABLE} gen skeleton ${BPF_OBJECT} > ${CMAKE_BINARY_DIR}/${BPF_SKELETON_HEADER}
        DEPENDS ${BPF_OBJECT}
        COMMENT "Generating skeleton for BPF code ${BPF_SOURCE}"
    )

endfunction(generate_bpf_skeleton)


###############################################################################
### Utility function to wrap up all the necessary bpf module tooling operations.
###############################################################################
function(bpf_module TARGET_NAME BPF_SOURCE BPF_OBJECT BPF_SKELETON BPF_EXTRA_INCLUDES)
    build_bpf(${TARGET_NAME} ${BPF_SOURCE} ${BPF_OBJECT} ${BPF_EXTRA_INCLUDES})
    generate_bpf_skeleton(${TARGET_NAME} ${BPF_OBJECT} ${BPF_SKELETON})
endfunction(bpf_module)



###############################################################################
### Build the BPF User-space module
###############################################################################
function(bpf_userspace_module TARGET_NAME USERSPACE_SOURCE BPF_SKELETON_TGTNAME)
    add_executable(${TARGET_NAME} ${USERSPACE_SOURCE})
    target_include_directories(${TARGET_NAME} PRIVATE ${CMAKE_BINARY_DIR} ${BPFTOOL_HEADERS})
    target_link_directories(${TARGET_NAME} PRIVATE ${CMAKE_BINARY_DIR} ${BPFTOOL_LIBRARIES})
    target_link_libraries(${TARGET_NAME} PRIVATE bpf elf z zstd)
    add_dependencies(${TARGET_NAME} generate_vmlinux_h bpf_skeleton_${BPF_SKELETON_TGTNAME} )
endfunction(bpf_userspace_module)
