#!/bin/bash
set -ex

BOOT_PARTITION="/dev/nvme1n1p1"
SWAP_PARTITION="/dev/nvme1n1p2"
ROOT_PARTITION="/dev/nvme1n1p3"
HOME_PARTITION="/dev/nvme0n1p1"
USERNAME="jmp"
HOSTNAME="jpudar-rvbd"

# Time
ln -sf /usr/share/zoneinfo/America/Detroit /etc/localtime
hwclock --systohc

# Localization
echo 'LANG=en_US.UTF-8' >/etc/locale.conf
locale-gen

# Network configuration
echo "$HOSTNAME" >/etc/hostname
systemctl enable NetworkManager.service

# Network time sync
systemctl enable chronyd.service

# Set root password
passwd

# Boot loader
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg

# Reboot into newly installed environment
exit
