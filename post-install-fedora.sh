#!/bin/bash

# =============================================
# Personal script for Fedora 44 Gnome version #
# =============================================

# To install this script, run the following command in your terminal:
# sudo bash <(curl -fsSL https://raw.githubusercontent.com/Gabriel-Moya/personal-linux/refs/heads/master/post-install-fedora.sh)

if [ "$EUID" -ne 0 ]; then
  echo "Please run this script as root (e.g., using sudo)."
  exit 1
fi

# ===========================
# Getting user and password #
# ===========================
# read -p "Enter the username for the new system: " USER
# echo ""
# read -s -p "Enter the password for the new user: " PASSWORD
# echo ""
# read -s -p "Confirm the password: " PASSWORD_CONFIRM
# echo ""

# if [ "$PASSWORD" != "$PASSWORD_CONFIRM" ]; then
#   echo "Error: Passwords do not match. Please run the script again and enter matching passwords."
#   exit 1
# fi

TARGET_USER="${SUDO_USER:-$USER}"

DNF_PACKAGES=(
  zsh
  code
  flameshot
  vlc
  docker-ce
  docker-ce-cli
  containerd.io
  docker-buildx-plugin
  docker-compose-plugin
)

FLATPAK_PACKAGES=(
  md.obsidian.Obsidian
  com.bitwarden.desktop
  rest.insomnia.Insomnia
)

# Prepare flatpak
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

# Setup Visual Studio Code repository
rpm --import https://packages.microsoft.com/keys/microsoft.asc &&
echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\nautorefresh=1\ntype=rpm-md\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" | tee /etc/yum.repos.d/vscode.repo > /dev/null

# Setup Docker Repository
dnf config-manager addrepo --from-repofile=https://download.docker.com/linux/fedora/docker-ce.repo

# =======================
# Install brave browser #
# =======================
curl -fsS https://dl.brave.com/install.sh | sh

# Flatpak Packages
for package in "${FLATPAK_PACKAGES[@]}"; do
  flatpak install -y flathub "$package"
done

# DNF Packages
dnf check-update
dnf install -y --noninteractive "${DNF_PACKAGES[@]}"

# Configure Docker to start on boot and add the current user to the docker group
systemctl enable docker
systemctl start docker

usermod -aG docker $TARGET_USER

# Enable the system tray
dnf install -y libappindicator-gtk3 gnome-shell-extension-appindicator gnome-extensions-app


# install jetbrains-toolbox
# install video codecs
# create directories like ~/dev to store github projects
# configure zsh and oh-my-zsh
# configure gnome extensions like dash-to-dock, system tray and window tiling etc.
