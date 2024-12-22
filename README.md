# kernel-systemsw-deps
Repository to hold utility and scripts to build and run kernel related dependencies

```shell
qemu-system-x86_64 -kernel kernel-6.12.6/build/arch/x86_64/boot/bzImage -initrd initrd.tar.gz -nographic  -append "console=ttyS0" -virtfs local,path=./kernel-6.12.6/,mount_tag=host_share,security_model=passthrough,id=host_share 


qemu-system-x86_64 -kernel kernel-6.12.6/build/arch/x86_64/boot/bzImage -initrd initrd.tar.gz -nographic  -append "console=ttyS0" -virtfs local,path=/home/vaisakhps/developer/Memory/WorkingSizeEstimation/build/kernel-6.12.6/,mount_tag=host_share,security_model=mapped,id=host_share


qemu-system-x86_64 -kernel kernel-6.12.6/build/arch/x86_64/boot/bzImage -initrd initrd.tar.gz -append "console=ttyS0" -virtfs local,path=./kernel-6.12.6/,mount_tag=host_share,security_model=mapped
```