#!/bin/bash

set -euo pipefail
trap 'printf "%s: error on line %s.\n" "$0" "$LINENO" >&2' ERR

: "${REPO_DIR:?run this module through install.sh}"

# Prints one package per line, ignoring comments, blank lines and stray whitespace.
read_list() {
  local line
  while IFS= read -r line || [[ -n "$line" ]]; do
    line="${line%%#*}"
    line="${line//[[:space:]]/}"
    if [[ -n "$line" ]]; then
      printf '%s\n' "$line"
    fi
  done < "$1"
}

mapfile -t DNF_PACKAGES < <(read_list "$REPO_DIR/packages/dnf.txt")
mapfile -t FLATPAK_PACKAGES < <(read_list "$REPO_DIR/packages/flatpak.txt")

# Process substitution hides read errors, so an empty list means the file could not be read.
if [[ ${#DNF_PACKAGES[@]} -eq 0 || ${#FLATPAK_PACKAGES[@]} -eq 0 ]]; then
  printf 'Could not read the package lists in %s/packages.\n' "$REPO_DIR" >&2
  exit 1
fi

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
