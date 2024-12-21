function(download_bpftool)
    set(BPTOOL_VERSION "v7.5.0")
    set(BPTOOL_URL "https://github.com/libbpf/bpftool/archive/refs/tags/${BPTOOL_VERSION}.tar.gz")
    set(BPTOOL_SOURCE_DIR "${CMAKE_BINARY_DIR}/bpftool-${BPTOOL_VERSION}")

    file(DOWNLOAD ${BPTOOL_URL} "${CMAKE_BINARY_DIR}/bpftool-${BPTOOL_VERSION}.tar.gz")
    message(STATUS "Downloaded bpftool version ${BPTOOL_VERSION}")

    execute_process(COMMAND ${CMAKE_COMMAND} -E make_directory ${BPTOOL_SOURCE_DIR})
    execute_process(COMMAND tar xzf "${CMAKE_BINARY_DIR}/bpftool-${BPTOOL_VERSION}.tar.gz" --strip-components=1
                    WORKING_DIRECTORY ${BPTOOL_SOURCE_DIR})

    message(STATUS "Extracted bpftool to ${BPTOOL_SOURCE_DIR}")
    execute_process(COMMAND ${CMAKE_COMMAND} -E remove ${BPTOOL_SOURCE_DIR}/libbpf)
    execute_process(COMMAND git clone https://github.com/libbpf/libbpf/ libbpf 
                    WORKING_DIRECTORY ${BPTOOL_SOURCE_DIR})
    execute_process(COMMAND git reset --hard 09b9e83102eb8ab9e540d36b4559c55f3bcdb95d
                    WORKING_DIRECTORY ${BPTOOL_SOURCE_DIR}/libbpf)
    message(STATUS "Cloned libbpf to ${BPTOOL_SOURCE_DIR}/libbpf")
    execute_process(COMMAND make LLVM_VERSION=19 LLVM_CONFIG=llvm-config-19
                    WORKING_DIRECTORY ${BPTOOL_SOURCE_DIR}/src)
    message(STATUS "Built bpftool")
    
endfunction()
