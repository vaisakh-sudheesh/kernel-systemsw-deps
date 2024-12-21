set (BPFTOOL_HOST_EXECUTABLE ${CMAKE_CURRENT_SOURCE_DIR}/deps/bpftool-android/bin/bpftool CACHE STRING "Path to the Android bpftool executable")

set (BPFTOOL_EXECUTABLE /data/local/tmp/bpftool CACHE STRING "Path to the Android bpftool executable")
set (BPFTOOL_HEADERS ${CMAKE_CURRENT_SOURCE_DIR}/deps/bpftool-android/include/ CACHE STRING "Path to the bpftool headers")
set (BPFTOOL_LIBRARIES ${CMAKE_CURRENT_SOURCE_DIR}/deps/bpftool-android/libs CACHE STRING "Path to the bpftool libraries")


add_custom_target(push_bpftool 
        COMMAND adb push ${BPFTOOL_HOST_EXECUTABLE} ${BPFTOOL_EXECUTABLE}
    )

###############################################################################
### Generate vmlinux.h for BPF code compilation
###############################################################################
add_custom_command(
    OUTPUT ${CMAKE_BINARY_DIR}/vmlinux.h
    COMMAND adb shell ${BPFTOOL_EXECUTABLE} btf dump file /sys/kernel/btf/vmlinux format c > ${CMAKE_BINARY_DIR}/vmlinux.h
    DEPENDS push_bpftool
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
    get_filename_component(BPF_OBJECT_NAME ${BPF_OBJECT} NAME)
    add_custom_target(bpf_skeleton_${TARGET_NAME} ALL
        COMMAND adb push ${BPF_OBJECT} /data/local/tmp/${BPF_OBJECT_NAME}
        COMMAND adb shell ${BPFTOOL_EXECUTABLE} gen skeleton /data/local/tmp/${BPF_OBJECT_NAME} > ${CMAKE_BINARY_DIR}/${BPF_SKELETON_HEADER}
        COMMAND adb shell rm /data/local/tmp/${BPF_OBJECT_NAME}
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
    install_target(${TARGET_NAME})
endfunction(bpf_userspace_module)
