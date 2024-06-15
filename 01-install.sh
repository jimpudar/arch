#!/bin/bash
set -ex

# connect to wifi w/ station wlan0 scan, station wlan0 connect <SSID>
# iwctl

# Wipe root and boot partitions. Don't accidentally format your /home partition!
mkfs.ext4 "$ROOT_PARTITION"
mkfs.fat -F 32 "$BOOT_PARTITION"
mkswap "$SWAP_PARTITION"

# Mount everything under /mnt
swapon "$SWAP_PARTITION"
mount "$ROOT_PARTITION" /mnt
mount --mkdir "$BOOT_PARTITION" /mnt/boot
mount --mkdir "$HOME_PARTITION" /mnt/home

# Ensure drives are set up and mounted under /mnt
# This is MY list of stuff, make sure this all makes sense for you.
packages=(
  # Minimal package set to define a basic Arch Linux installation
  base
  # Build toolchain
  base-devel
  # Stable vanilla Linux kernel. You could also use `linux-hardened` or `linux-lts`
  linux
  # Basic firmware
  linux-firmware
  # Sound Open Firmware for audio devices
  sof-firmware
  # Microcode updates for Intel processors
  intel-ucode
  # Nonfree driver from Nvidia
  nvidia

  # Bootloader so you can boot Linux
  grub
  efibootmgr

  # Prevent Arch from eating your laptop battery
  tlp
  thermald

  # Handles network configuration and integrates well with systemd
  networkmanager
  wpa_supplicant

  # Ensures man pages work properly
  man-db
  man-pages
  texinfo

  # Network time sync
  chrony

  # Arch doesn't come with sudo by default
  sudo

  # Required to use Bluetooth devices
  bluez
  bluez-utils

  # Webcam utilities
  # v4l2-ctl
  # guvcview
  # cameractrls
  
  # Printing
  cups
  cups-pdf
  avahi
  nss-mdns

  # An alternative shell. You could use bash instead.
  zsh
  # An alternative terminal emulator. This is very fast.
  alacritty

  # Misc required dev tools
  xsel
  jq
  jwt-cli
  vim
  openssh
  docker
  git
  azure-cli
  d2
)
pacstrap -K /mnt "${packages[@]}"

genfstab -U /mnt >/mnt/etc/fstab

arch-chroot /mnt
