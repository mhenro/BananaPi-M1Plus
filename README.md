# BananaPi-M1Plus
BananaPi-M1-Plus, Linux, busybox

This script I had written for creating image which may be burnt into SD-card of Banana Pi M1+ slot.
This script uses loop device for imitating a block device. It creates zero file and then formats it on two partitions. First partition is for the bootloader (U-Boot) and second partition's for rootfs.
The script encrypts rootfs partition with cryptsetup and also creates initramfs, which decrypts rootfs partition at boot time.
