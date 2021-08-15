#!/usr/bin/env bash
set -e

usage() {
	echo "USAGE: sudo $0 -i <source image path> [options] [disk path | size]

Use this script to grow an OpenWrt rootfs partition to the desired size
If disk path nor size is specified, defaults to 2G

Options :
	-i
		Source image path

	-o
		Destination image path (optional)

	-s
		Specify the image size (eg. 16G, 300M etc...)
		Cannot be used with '-d'

	-d
		Disk path (eg. /dev/sda). This will resize the image to the exact disk size
		Cannot be used with '-s'

Examples :
	sudo $0 -i openwrt.img
		Set openwrt.img rootfs size to 2G
	
	sudo $0 -i openwrt.img -s 16G
		Set openwrt.img rootfs size to 16G
	
	sudo $0 -i openwrt.img -d /dev/sda
		Set openwrt.img rootfs size to the size of /dev/sda"
}

main() {
	cp ${SRC_IMG} ${DEST_IMG}

	echo "Resizing root partition to ${SIZE}..."
	qemu-img resize -f raw ${DEST_IMG} ${SIZE}
	sfdisk -q -d ${DEST_IMG} > ${DEST_IMG%.img}.sfdisk
	sed -i -E "/${DEST_IMG}2/ s/size=[ 0-9,]+//" ${DEST_IMG%.img}.sfdisk
	sed -i "/^last-lba/d" ${DEST_IMG%.img}.sfdisk
	sfdisk -q ${DEST_IMG} < ${DEST_IMG%.img}.sfdisk
	rm -rf ${DEST_IMG%.img}.sfdisk

	echo "Growing filesystem..."
	offset=$(sfdisk -d ${DEST_IMG} | grep "${DEST_IMG}2" | sed -E 's/.*start=\s+([0-9]+).*/\1/g')
	size=$(sfdisk -d ${DEST_IMG} | grep "${DEST_IMG}2" | sed -E 's/.*size=\s+([0-9]+).*/\1/g')
	loopdev=$(sudo losetup --offset $((512 * $offset)) --sizelimit $((512 * $size)) --find --show ${DEST_IMG})
	sudo e2fsck -yf $loopdev >/dev/null 2>&1 || true
	sudo resize2fs $loopdev > /dev/null 2>&1
	sudo losetup -d $loopdev

	echo "Done! Image path : ${DEST_IMG}"
}

# Check for root
if [[ `whoami` != 'root' ]]
  then
    echo "You must be root to execute this script..."
    exit
fi


# Parse arguments
while [[ $# -gt 0 ]]; do
	key="$1"

	case $key in
		-d)
		DISK_PATH="$2"
		shift
		shift
		;;

		-s)
		SIZE="$2"
		shift
		shift
		;;

		-i)
		SRC_IMG="$2"
		shift
		shift
		;;

		-o)
		DEST_IMG="$2"
		shift
		shift
		;;

		*)	# Unknown argument
		usage; exit 1;
		shift
		;;
	esac
done

if [[ -z "$SRC_IMG" ]]; then
	usage; exit 1;
fi

# Disk path and size cannot be set at the same time
if [[ -n "$DISK_PATH" && -n "$SIZE" ]]; then
	usage; exit 1;
fi

if [[ -n "$DISK_PATH" ]]; then
	SIZE=$(sudo qemu-img measure ${DISK_PATH} | grep "required" | awk '{ print $3 }')
fi

if [[ -z "$SIZE" ]]; then
	SIZE=2G
fi

if [[ -z "$DEST_IMG" ]]; then
	DEST_IMG=${SRC_IMG%.img}-resized.img
fi

main
