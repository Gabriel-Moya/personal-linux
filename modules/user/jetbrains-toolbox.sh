#!/bin/bash
# Runs as the desktop user; started by modules/jetbrains-toolbox.sh.

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
