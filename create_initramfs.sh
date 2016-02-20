#!/bin/bash

cd initramfs/

find . | cpio -H newc -o > ../initramfs.cpio
cd ..
cat initramfs.cpio | gzip > initramfs.cpio.gz
mkimage -A arm -T ramdisk -C gzip -n uInitrd -d initramfs.cpio.gz uInitrd 
