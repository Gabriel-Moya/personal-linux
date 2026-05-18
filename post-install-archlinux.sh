#!/bin/bash

# =================================================
# Personal script for Arch Linux using KDE Plasma #
# =================================================

if [ "$EUID" -ne 0 ]; then
  echo "Please run this script as root (e.g., using sudo)."
  exit 1
fi

# ===========================
# Getting user and password #
# ===========================
read -p "Enter the username for the new system: " USER
echo ""
read -s -p "Enter the password for the new user: " PASSWORD
echo ""
read -s -p "Confirm the password: " PASSWORD_CONFIRM
echo ""

if [ "$PASSWORD" != "$PASSWORD_CONFIRM" ]; then
  echo "Error: Passwords do not match. Please run the script again and enter matching passwords."
  exit 1
fi

echo "Updating repositories and ensuring base tools are installed..."
pacman -Syu --noconfirm
pacman -S --noconfirm sudo base-devel git

# ================================================
# Configuring user and password for the new system
# ================================================
echo "Creating user '$USER' and setting password..."
useradd -m -G wheel -s /bin/bash "$USER"
echo "$USER:$PASSWORD" | chpasswd
echo "Configuring sudoers to allow '$USER' to use sudo..."
echo "$USER ALL=(ALL:ALL) ALL" >> /etc/sudoers.d/$USER
chmod 440 /etc/sudoers.d/$USER
echo "User '$USER' created and configured successfully."

# =================================================================
# Configuring general system settings and installing basic packages
# =================================================================
echo "Installing Pipewire (Audio) and NetworkManager (Network)..."
pacman -S --noconfirm pipewire wireplumber pipewire-pulse networkmanager

# Install video drivers based on your hardware (uncomment the appropriate line)
# echo "Installing basic video drivers..."
# pacman -S --noconfirm mesa xf86-video-amdgpu vulkan-radeon # For AMD
# pacman -S --noconfirm mesa xf86-video-intel vulkan-intel   # For Intel
# pacman -S --noconfirm nvidia nvidia-utils                  # For NVIDIA (Proprietary)

echo "Installing KDE Plasma and SDDM (Display Manager)..."
pacman -S --noconfirm plasma sddm xorg-xwayland

echo "Installing basic apps..."
pacman -S --noconfirm konsole dolphin kate spectacle ark

# Enable SDDM and NetworkManager to start on boot
systemctl enable sddm.service
systemctl enable NetworkManager.service

# To enable bluetooth support, uncomment the following lines:
# echo "Installing Bluetooth support..."
# pacman -S --noconfirm bluez bluez-utils
# systemctl enable bluetooth.service

# ==================
# GLOBAL VARIABLES #
# ==================
DIRECTORY_BINARIES_TO_INSTALL="$PWD/temps"

# =================================
# Packages to install with pacman #
# =================================
PACKAGES_FROM_PACMAN_TO_INSTALL=(
  firefox
  vlc
  docker
  dotnet-sdk
  curl
  wget
  fastfetch
)

echo "Installing additional packages from the Arch repositories..."
pacman -S --noconfirm "${PACKAGES_FROM_PACMAN_TO_INSTALL[@]}"

systemctl enable docker.service
usermod -aG docker "$USER"

# =============================
# Installing AUR helper (yay) #
# =============================
echo "Installing yay (AUR helper)..."
sudo -u "$USER" bash -c "
  cd /tmp
  git clone https://aur.archlinux.org/yay.git
  cd yay
  makepkg -si --noconfirm
"
