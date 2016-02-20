#!/bin/sh

#declare variables
IMG_FILE="vtr100.img"
IMG_SIZE=350	#MB

echo "Creating img file..."
dd if=/dev/zero of=${IMG_FILE} bs=1M count=${IMG_SIZE}
LOOP_DEV=`losetup -f --show ${IMG_FILE}`
LOOP_PART_BOOT="${LOOP_DEV}p1"
LOOP_PART_SYS="${LOOP_DEV}p2"

echo "Write bootloader..."
dd if=/dev/zero of=${LOOP_DEV} bs=1M count=1
dd if=bootloader/u-boot-sunxi-with-spl.bin of=${LOOP_DEV} bs=1024 seek=8

echo "Create partitions..."
sfdisk -R ${LOOP_DEV}
cat <<EOT | sfdisk --in-order -L -uM ${LOOP_DEV}
1,16,c,*
,,L
EOT

echo "Formatting boot partition..."
mkfs.vfat ${LOOP_PART_BOOT}

echo "Copying files to boot partition..."
mount ${LOOP_PART_BOOT} /mnt/
cp bootloader/uImage /mnt/
cp bootloader/uInitrd /mnt/
cp bootloader/script.bin /mnt/
cp bootloader/boot.scr /mnt/
umount /mnt/

echo "Create rootfs partition..."
cryptsetup -y --cipher aes-xts-plain --key-size 256 luksFormat ${LOOP_PART_SYS}
cryptsetup luksOpen ${LOOP_PART_SYS} rootfs

echo "Formatting rootfs partition..."
mkfs.ext4 /dev/mapper/rootfs

echo "Copying files to rootfs partition..."
mount /dev/mapper/rootfs /mnt/
cp -r rootfs/* /mnt/
umount /mnt/

echo "Add crypt key to initramfs..."
cryptsetup luksAddKey ${LOOP_PART_SYS} initramfs/etc/password
cryptsetup luksClose rootfs

losetup -d ${LOOP_DEV}

echo "Done!" 
