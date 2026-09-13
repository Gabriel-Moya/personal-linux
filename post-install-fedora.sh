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
  # JetBrains Toolbox dependencies
  tar
  gzip
  libXi
  libXrender
  libXtst
  fontconfig
  gtk3
  glx-utils
  xcb-util-keysyms
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
  com.discordapp.Discord
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

# Install JetBrains Toolbox for the desktop user, who will manage its updates.
runuser -u "$TARGET_USER" -- bash -s <<'TOOLBOX_BASH'
set -euo pipefail
trap 'printf "JetBrains Toolbox: error on line %s.\n" "$LINENO" >&2' ERR

toolbox_dir="$HOME/.local/opt/jetbrains-toolbox"
desktop_file="$HOME/.local/share/applications/jetbrains-toolbox.desktop"

# Also recognize the location used by existing Toolbox installations.
if [[ -x "$HOME/.local/share/JetBrains/Toolbox/bin/jetbrains-toolbox" ]]; then
  toolbox_dir="$HOME/.local/share/JetBrains/Toolbox"
fi

if [[ -x "$toolbox_dir/bin/jetbrains-toolbox" ]]; then
  echo "JetBrains Toolbox is already installed. Keeping the existing installation."
else
  if [[ -e "$toolbox_dir" || -L "$toolbox_dir" ]]; then
    printf "JetBrains Toolbox: %s already exists without a working executable. Please review it before retrying.\n" "$toolbox_dir" >&2
    exit 1
  fi

  case "$(uname -m)" in
    x86_64) platform="linux" ;;
    aarch64) platform="linuxARM64" ;;
    *) echo "JetBrains Toolbox: unsupported architecture." >&2; exit 1 ;;
  esac

  mkdir -p "${toolbox_dir%/*}"
  toolbox_tmp="$(mktemp -d "${toolbox_dir%/*}/.jetbrains-toolbox.XXXXXX")"
  trap 'rm -rf -- "$toolbox_tmp"' EXIT

  echo "Downloading the latest stable JetBrains Toolbox..."
  archive="$toolbox_tmp/toolbox.tar.gz"
  download_url="$(curl -fsSL --retry 3 -o "$archive" -w '%{url_effective}' \
    "https://data.services.jetbrains.com/products/download?code=TBA&platform=$platform&type=release")"

  # Use the checksum for the exact downloaded version, even if a new release appears.
  checksum="$(curl -fsSL --retry 3 "$download_url.sha256")"
  read -r expected_sha _ <<< "$checksum"
  [[ "$expected_sha" =~ ^[[:xdigit:]]{64}$ ]]
  printf '%s  %s\n' "$expected_sha" "$archive" | sha256sum --check

  mkdir "$toolbox_tmp/app"
  tar -xzf "$archive" -C "$toolbox_tmp/app" --strip-components=1
  if [[ ! -x "$toolbox_tmp/app/bin/jetbrains-toolbox" ]]; then
    echo "JetBrains Toolbox: the archive does not contain the expected executable." >&2
    exit 1
  fi
  mv -T -- "$toolbox_tmp/app" "$toolbox_dir"
fi

# Toolbox may customize this entry on first launch, so preserve an existing one.
if [[ ! -e "$desktop_file" && ! -L "$desktop_file" ]]; then
  mkdir -p "${desktop_file%/*}"
  cat > "$desktop_file" <<DESKTOP
[Desktop Entry]
Type=Application
Name=JetBrains Toolbox
Exec="$toolbox_dir/bin/jetbrains-toolbox"
Icon=$toolbox_dir/bin/toolbox.svg
Terminal=false
StartupNotify=false
Categories=Development;
DESKTOP
fi

echo "JetBrains Toolbox is ready. Open it from the application menu to choose your IDEs."
TOOLBOX_BASH

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

# install video codecs
# create directories like ~/dev to store github projects
# configure zsh and oh-my-zsh
# configure gnome extensions like dash-to-dock, system tray and window tiling etc.
