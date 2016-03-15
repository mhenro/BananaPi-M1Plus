#!/bin/sh

#declare variables
IMG_FILE="vtr100.img"
IMG_SIZE=400	#MB
PASSWORD="Y9Jx1psL"

#function to copy files with show progress
cpStat () {
	tar c "$1" | pv -s ${IMG_SIZE}M | tar x -C "$2"
}

echo "Creating img file..."
dd if=/dev/zero bs=1M count=${IMG_SIZE} | pv -s ${IMG_SIZE}M > ${IMG_FILE}
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
pv bootloader/uImage > /mnt/uImage
pv bootloader/uInitrd > /mnt/uInitrd
pv bootloader/script.bin > /mnt/script.bin
pv bootloader/boot.scr > /mnt/boot.scr
umount /mnt/

echo "Create rootfs partition..."
cat <<EOT | cryptsetup --cipher aes-xts-plain --key-size 256 luksFormat ${LOOP_PART_SYS}
$PASSWORD
EOT
cat <<EOT | cryptsetup luksOpen ${LOOP_PART_SYS} rootfs
$PASSWORD
EOT

echo "Formatting rootfs partition..."
mkfs.ext4 /dev/mapper/rootfs

echo "Copying files to rootfs partition..."
mount /dev/mapper/rootfs /mnt/
cpStat rootfs/ /mnt/
umount /mnt/

echo "Add crypt key to initramfs..."
cat <<EOT | cryptsetup luksAddKey ${LOOP_PART_SYS} initramfs/etc/password
$PASSwORD
EOT
cryptsetup luksClose rootfs

echo "Create initramfs..."
sh create_initramfs.sh
mv uInitrd bootloader/
rm initramfs.cpio
rm initramfs.cpio.gz
mount ${LOOP_PART_BOOT} /mnt/
pv bootloader/uInitrd > /mnt/uInitrd
umount /mnt/

losetup -d ${LOOP_DEV}

echo "Done!" 
