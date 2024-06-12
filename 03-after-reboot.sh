#!/bin/bash
set -ex

BOOT_PARTITION="/dev/nvme1n1p1"
SWAP_PARTITION="/dev/nvme1n1p2"
ROOT_PARTITION="/dev/nvme1n1p3"
HOME_PARTITION="/dev/nvme0n1p1"
USERNAME="jmp"
HOSTNAME="jpudar-rvbd"

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
su jmp
cd /home/jmp/AUR/jetbrains-toolbox
makepkg -si
cd /home/jmp/AUR/1password
makepkg -si
cd /home/jmp/AUR/globalprotect-openconnect-git
makepkg -si
cd /home/jmp/AUR/nodejs-azurite
makepkg -si
