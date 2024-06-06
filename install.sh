#!/bin/bash
set -ex

BOOT_PARTITION="/dev/nvme1n1p1"
SWAP_PARTITION="/dev/nvme1n1p2"
ROOT_PARTITION="/dev/nvme1n1p3"
HOME_PARTITION="/dev/nvme0n1p1"
USERNAME="jmp"
HOSTNAME="jpudar-rvbd"

# connect to wifi w/ station wlan0 scan, station wlan0 connect <SSID>
iwctl

# Wipe root and boot partitions. Don't accidentally format your /home partition!
mkfs.ext4 "$ROOT_PARTITION"
mkfs.fat -F 32 "$BOOT_PARTITION"

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
  v4l2-ctl
  guvcview
  cameractrls

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
systemctl enabel chronyd.service

# Set root password
passwd

# Boot loader
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg

# Reboot into newly installed environment
exit
reboot

# Reconnect to the Internet by activating WiFi
nmtui

# Set up unprivileged user
useradd -m -G wheel,docker -s /bin/zsh "$USERNAME"
passwd "$USERNAME"

# Uncomment the %wheel NOPASSWD bit
EDITOR=vim visudo

# Install KDE Plasma
pacman -S plasma-meta kde-applications-meta sddm
systemctl enable sddm

# Enable Bluetooth
systemctl enable --now bluetooth.service

# Enable TLP & thermald
systemctl enable --now tlp.service
systemctl enable --now thermald.service

# Enable Docker
systemctl enable --now docker.service

# Make Nvidia driver work with Wayland
# https://wiki.archlinux.org/title/NVIDIA#DRM_kernel_mode_setting
echo "options nvidia_drm modeset=1 fbdev=1" >/etc/modprobe.d/nvidia.conf

# https://wiki.archlinux.org/title/NVIDIA#Early_loading
echo 'MODULES=(nvidia nvidia_modeset nvidia_uvm nvidia_drm)' >>/etc/mkinitcpio.conf
vim /etc/mkinitcpio.conf

# https://wiki.archlinux.org/title/NVIDIA#pacman_hook
mkdir /etc/pacman.d/hooks
cat <<EOF >/etc/pacman.d/hooks/nvidia.hook
[Trigger]
Operation=Install
Operation=Upgrade
Operation=Remove
Type=Package
# Uncomment the installed NVIDIA package
Target=nvidia
#Target=nvidia-open
#Target=nvidia-lts
# If running a different kernel, modify below to match
Target=linux
[Action]
Description=Updating NVIDIA module in initcpio
Depends=mkinitcpio
When=PostTransaction
NeedsTargets
Exec=/bin/sh -c 'while read -r trg; do case $trg in linux*) exit 0; esac; done; /usr/bin/mkinitcpio -P'
EOF

# Install chromium and Dotnet SDK
# Don't forget to enable wayland support in chromium!
sudo pacman -S chromium dotnet-sdk dotnet-sdk-6.0 dotnet-sdk-7.0 aspnet-runtime aspnet-runtime-6.0 aspnet-runtime-7.0 python-poetry pyenv

# Install AUR stuff (git clone these first if you don't have them already)
cd ~/AUR/jetbrains-toolbox
makepkg -si
cd ~/AUR/1password
makepkg -si
cd ~/AUR/globalprotect-openconnect-git
makepkg -si
cd ~/AUR/nodejs-azurite
makepkg -si

