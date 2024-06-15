#!/bin/bash
set -ex

# Time
ln -sf /usr/share/zoneinfo/America/Detroit /etc/localtime
hwclock --systohc

# Localization
echo 'LANG=en_US.UTF-8' >/etc/locale.conf
echo 'en_US.UTF-8 UTF-8' >>/etc/locale.gen
locale-gen

# Network configuration
echo "$HOSTNAME" >/etc/hostname
systemctl enable NetworkManager.service

# Network time sync
systemctl enable chronyd.service

# Avahi Daemon for printer discovery
systemctl enable avahi-daemon.service
echo 'hosts: mymachines mdns_minimal [NOTFOUND=return] resolve [!UNAVAIL=return] files myhostname dns' >>/etc/nsswitch.conf
vim /etc/nsswitch.conf

# Set root password
passwd

# Boot loader
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg
