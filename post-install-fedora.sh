#!/bin/bash

set -euo pipefail
trap 'printf "Error on line %s. Installation stopped.\n" "$LINENO" >&2' ERR

# =============================================
# Personal script for Fedora 44 Gnome version #
# =============================================

# To install this script, run the following command in your terminal:
# sudo bash -c "$(curl -fsSL https://raw.githubusercontent.com/Gabriel-Moya/personal-linux/refs/heads/master/post-install-fedora.sh)"

if [ "$EUID" -ne 0 ]; then
  echo "Please run this script as root (e.g., using sudo)."
  exit 1
fi

TARGET_USER="${SUDO_USER:-}"
if [[ -z "$TARGET_USER" || "$TARGET_USER" == "root" ]]; then
  echo "Please run this script with sudo from your regular user account."
  exit 1
fi
id "$TARGET_USER" > /dev/null

DNF_PACKAGES=(
  zsh
  code
  flameshot
  vlc
  vlc-plugin-ffmpeg
  libavcodec-freeworld
  google-chrome-stable
  # Docker packages
  docker-ce
  docker-ce-cli
  containerd.io
  docker-buildx-plugin
  docker-compose-plugin
  # System tray
  libappindicator-gtk3
  gnome-shell-extension-appindicator
  gnome-extensions-app
  # Configure GNOME settings in a user D-Bus session
  dbus-daemon
)

FLATPAK_PACKAGES=(
  md.obsidian.Obsidian
  com.bitwarden.desktop
  rest.insomnia.Insomnia
)

# Enable RPM Fusion repositories for additional software
FEDORA_VERSION="$(rpm -E %fedora)"
dnf install -y "https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-${FEDORA_VERSION}.noarch.rpm"

# config-manager is provided by dnf5-plugins
dnf install -y fedora-workstation-repositories dnf5-plugins

# Prepare flatpak
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

# Setup Visual Studio Code repository
rpm --import https://packages.microsoft.com/keys/microsoft.asc
echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\nautorefresh=1\ntype=rpm-md\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" | tee /etc/yum.repos.d/vscode.repo > /dev/null

# Setup Docker Repository
dnf config-manager addrepo --overwrite --from-repofile=https://download.docker.com/linux/fedora/docker-ce.repo

# Setup Google Chrome Repository
dnf config-manager setopt google-chrome.enabled=1

# =======================
# Install brave browser #
# =======================
curl -fsS https://dl.brave.com/install.sh | sh -eu

# Flatpak Packages
for package in "${FLATPAK_PACKAGES[@]}"; do
  flatpak install -y flathub "$package"
done

# DNF Packages
dnf --refresh install -y "${DNF_PACKAGES[@]}"

# Configure Docker to start on boot and add the current user to the docker group
systemctl enable --now docker

usermod -aG docker "$TARGET_USER"

# Persist the system tray setting for the desktop user. A new GNOME session
# may be needed before the freshly installed extension becomes available.
runuser -u "$TARGET_USER" -- env -u DBUS_SESSION_BUS_ADDRESS -u XDG_RUNTIME_DIR \
  dbus-run-session -- bash -s <<'BASH'
set -euo pipefail

uuid="appindicatorsupport@rgcjonas.gmail.com"
enabled="$(gsettings get org.gnome.shell enabled-extensions)"
if [[ "$enabled" != *"'$uuid'"* ]]; then
  # gsettings prints an empty string array as "@as []".
  if [[ "$enabled" == "@as []" || "$enabled" == "[]" ]]; then
    enabled="['$uuid']"
  else
    enabled="${enabled%]}, '$uuid']"
  fi
  gsettings set org.gnome.shell enabled-extensions "$enabled"
fi

disabled="$(gsettings get org.gnome.shell disabled-extensions)"
if [[ "$disabled" == *"'$uuid'"* ]]; then
  # Remove this exact quoted UUID at the start, middle or end of the list.
  disabled="${disabled//"'$uuid', "/}"
  disabled="${disabled//", '$uuid'"/}"
  disabled="${disabled//"'$uuid'"/}"
  gsettings set org.gnome.shell disabled-extensions "$disabled"
fi

extensions_disabled="$(gsettings get org.gnome.shell disable-user-extensions)"
if [[ "$extensions_disabled" == "true" ]]; then
  gsettings set org.gnome.shell disable-user-extensions false
fi
BASH

echo "Installation complete. Log out and log back in to apply the GNOME extension and Docker group changes."

# Chrome
# Discord
# install jetbrains-toolbox
# install video codecs
# create directories like ~/dev to store github projects
# configure zsh and oh-my-zsh
# configure gnome extensions like dash-to-dock, system tray and window tiling etc.
