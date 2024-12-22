function(build_minimal_fs busybox_reffiles_dir initrd_build_dir busybox_install_dir output_archive init_script)
    file(MAKE_DIRECTORY ${busybox_install_dir})
    add_custom_command(
        OUTPUT ${output_archive}
        COMMAND ${busybox_reffiles_dir}/package_initramfs.sh ${busybox_reffiles_dir} ${initrd_build_dir} ${busybox_install_dir} ${output_archive} ${init_script} 
        COMMENT "Creating Minimal Filesystem"
        USES_TERMINAL
    )
    add_custom_target(minimal_fs_build ALL DEPENDS ${output_archive} busybox_target)
endfunction(build_minimal_fs)