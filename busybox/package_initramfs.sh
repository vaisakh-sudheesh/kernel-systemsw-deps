if [ "$#" -ne 5 ]; then
    echo "Usage: $0 <reffiles_dir> <fs_build_dir> <busybox_install_dir> <output_archive> <init-script>"
    exit 1
fi

reffiles_dir=$1
fs_build_dir=$2
busybox_install_dir=$3
output_archive=$4
init_script=$5

echo -e "Creating initramfs with arguments:\n \tsrc_dir=\033[1;32m${reffiles_dir}\033[0m,\n \tbuild_dir=\033[1;32m${fs_build_dir}\033[0m,\n \tbusybox_install_dir=\033[1;32m${busybox_install_dir}\033[0m,\n \toutput_archive=\033[1;32m${output_archive}\033[0m and\n \tinit_script=\033[1;32m${init_script}\033[0m"

rm -f ${output_archive}
echo "Creating Minimal Filesystem"
mkdir -p ${fs_build_dir}/busybox-x86
cd ${fs_build_dir}/busybox-x86
mkdir -pv bin sbin etc proc sys usr
echo "Copying BusyBox file"
cp -av ${busybox_install_dir}/* .

echo "Setting up init"

cp ${reffiles_dir}/${init_script} init
chmod +x init

echo "ENV=/.shinit; export ENV" > .profile

cp ${reffiles_dir}/shinit.ref .shinit
chmod +x .shinit


find . -print0 | cpio --null -ov --format=newc | gzip -9 > ${output_archive}