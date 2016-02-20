#!/bin/sh

#declare variables
SDCARD=/dev/sdb

read -p "Script will formatting SD-card on ${SDCARD}. Are you sure?" CHOICE
if [ "$CHOICE" != "Y" -a "$CHOICE" != "y" ] ; then
	exit 
fi

echo "Process starting..."
echo "Create bootable SD card..."



#===create bootable SD-card===#

#cleaning sd
echo "Cleaning sd..."
dd if=/dev/zero of=${SDCARD} bs=1M count=1

#write u-boot into boot-sector
echo "Write bootloader..."
dd if=bootloader/u-boot-sunxi-with-spl.bin of=${SDCARD} bs=1024 seek=8

#create 2 partitions
echo "Create partitions..."
sfdisk -R ${SDCARD}
cat <<EOT | sfdisk --in-order -L -uM ${SDCARD}
1,16,c,*
,,L
EOT

#formatting boot partition
echo "Formatting boot partition..."
mkfs.vfat ${SDCARD}1

#copy files to boot partition
echo "Copy files to boot partition..."
mount ${SDCARD}1 /mnt/
cp bootloader/uImage /mnt/
cp bootloader/uInitrd /mnt/
cp bootloader/script.bin /mnt/
cp bootloader/boot.scr /mnt/
umount /mnt/

#create crypt container on second partition
echo "Create rootfs partition..."
cryptsetup -y --cipher aes-xts-plain --key-size 256 luksFormat ${SDCARD}2
cryptsetup luksOpen ${SDCARD}2 rootfs

#formatting crypt partition
echo "Formatting rootfs partition..."
mkfs.ext4 /dev/mapper/rootfs

#copy files to crypt partition
echo "Copy files to rootfs partition..."
mount /dev/mapper/rootfs /mnt/
cp -r rootfs/* /mnt/
umount /mnt/

#add key-file to data partition
echo "Add crypt key to initramfs..."
cryptsetup luksAddKey ${SDCARD}2 initramfs/etc/password

#close crypt container
cryptsetup luksClose rootfs

echo "Done!" 
