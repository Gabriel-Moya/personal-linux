#!/bin/bash

set -euo pipefail
trap 'printf "Error on line %s. Installation stopped.\n" "$LINENO" >&2' ERR

# =============================================
# Personal setup for Fedora 44 Gnome version  #
# =============================================

# Usage: sudo bash install.sh [module...]
# Without arguments, every module runs in the order of ALL_MODULES.

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ALL_MODULES=(repos packages jetbrains-toolbox docker gnome discord-badge)

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

os_id="$(. /etc/os-release && printf '%s' "${ID:-}")"
if [[ "$os_id" != "fedora" ]]; then
  printf 'This setup only supports Fedora (found: %s).\n' "${os_id:-unknown}" >&2
  exit 1
fi

export REPO_DIR TARGET_USER

modules=("$@")
if [[ ${#modules[@]} -eq 0 ]]; then
  modules=("${ALL_MODULES[@]}")
fi

# Check every name first, so a typo stops before anything is installed.
for module in "${modules[@]}"; do
  known=false
  for available in "${ALL_MODULES[@]}"; do
    if [[ "$module" == "$available" ]]; then
      known=true
    fi
  done
  if [[ "$known" == false ]]; then
    printf 'Unknown module: %s. Available modules: %s\n' "$module" "${ALL_MODULES[*]}" >&2
    exit 1
  fi
done

for module in "${modules[@]}"; do
  printf '==> %s\n' "$module"
  bash "$REPO_DIR/modules/$module.sh" || {
    printf 'Module %s failed. Installation stopped.\n' "$module" >&2
    exit 1
  }
done

echo "Installation complete. Log out and log back in to apply the GNOME extensions and Docker group changes."
