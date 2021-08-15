# Openwrt EFI Tools

Some scripts to manage OpenWrt EFI images on x86_64.

* `gen-efi-image.sh`
```
$ ./gen-efi-image.sh SOURCE_IMG EFI_IMG DEST_IMG
```
Generates an EFI-compatible x86-64 disk image for OpenWrt
by combining the rootfs and kernel from the latest stable release
with the EFI image available in snapshot since [@a6b7c3e](https://github.com/openwrt/openwrt/commit/a6b7c3e672764858fd294998406ae791f5964b4a).

Requires `qemu-utils` package.

Tested with versions 19.07 through 21.02.0-rc4 (r16256-2d5ee43dc6).

## Instructions

Download the latest stable release from OpenWrt:
```
$ OPENWRT_VER=19.07.5
$ wget https://downloads.openwrt.org/releases/${OPENWRT_VER}/targets/x86/64/openwrt-${OPENWRT_VER}-x86-64-combined-ext4.img.gz
```

Download the EFI snapshot image:
```
$ wget https://downloads.openwrt.org/snapshots/targets/x86/64/openwrt-x86-64-generic-ext4-combined-efi.img.gz
```

Generate the latest stable image:
```
$ ./gen-efi-image.sh \
    openwrt-${OPENWRT_VER}-x86-64-combined-ext4.img.gz \
    openwrt-x86-64-generic-ext4-combined-efi.img.gz \
    openwrt-${OPENWRT_VER}-x86-64-combined-ext4-efi.img
```

---

* `resize-image.sh`

  `[size]` and `[disk path]` is optional, defaults to 2G
  Resize to a specified size:
```
# ./resize-image.sh -i openwrt-${OPENWRT_VER}-x86-64-combined-ext4-efi.img -s 16G
```
  or to resize to a disk size:
```
# ./resize-image.sh -i openwrt-${OPENWRT_VER}-x86-64-combined-ext4-efi.img -d /dev/sda
```
Change the output file path with -o.

Generate a resized image with a larger root partition. Online resize from
within OpenWrt is not possible with such a small disk and results in errors.

* `qemu.sh`
```
$ ./qemu.sh IMAGE
```
Runs the image in QEMU in EFI mode.

On Debian / Ubuntu, the packages `qemu-kvm` and `ovmf` must be installed. The path to the OVMF
firmware on Debian / Ubuntu should be changed to `/usr/share/OVMF/OVMF_CODE.fd`.